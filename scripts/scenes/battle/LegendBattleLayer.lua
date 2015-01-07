local SpriteCamp = import(".SpriteCamp")
local SpriteSoldier = import(".SpriteSoldier")
local ControlLayer = import(".ControlLayer")
local BaseBattleLayer = import(".BaseBattleLayer")
local BottomBarController = import(".BottomBarController")
local BattleEndLayer = import(".BattleEndNewLayer")

local sharedScheduler = CCDirector:sharedDirector():getScheduler()

local LegendBattleLayer = class("LegendBattleLayer", BaseBattleLayer)

function LegendBattleLayer:ctor(params)
	params = params or {}

	LegendBattleLayer.super.ctor(self, params)

	self.leftHeros = game.role.chooseHeros

	self.carbonId = params.carbonId
	self.carbonInfo = legendBattleCsv:getCarbonById(self.carbonId)
	self.carbonSceneCsv = require("csv.CarbonSceneCsv")
	self.carbonSceneCsv:load(self.carbonInfo["battleCsv"..params.diffIndex])
	self.diffIndex = params.diffIndex

	self.leftFormation = game.role.formationData

	self.battleLogic = nil

	-- 用于接收触摸事件
	self:setTouchEnabled(true)

	local carbonStageData = self.carbonSceneCsv:getStageSceneData(1)

	local heroTypes = {}
	for _, data in pairs(carbonStageData) do
		if data.heroType > 0 and not heroTypes[data.heroType] then
			heroTypes[data.heroType] = true
		end
	end

	-- loading ui
	local battleLoadingLayer
	battleLoadingLayer = BattleLoadingLayer.new({ priority = -128,
		callback = function()
			CCTexture2D:PVRImagesHavePremultipliedAlpha(false)
			battleLoadingLayer:getLayer():removeSelf()

			self.bg = display.newSprite(self.carbonInfo["background"..self.diffIndex])
			self.bg:pos(display.cx, display.cy):addTo(self)

			self:initCommonUI()
			self:initBattleField()
			game.role.leftMembers = 0
			game.role.leftMembers = table.nums(self.battleField.leftSoldierMap)
		end,
		loadingInfo = {
			images = { self.carbonInfo.background },
			heroTypes = heroTypes,
			loadRoleHeros = true,
		}
	})
	battleLoadingLayer:getLayer():addTo(display:getRunningScene())
end

-- 初始化战场
function LegendBattleLayer:initBattleField()
	local passiveSkills, beauties = game.role:getFightBeautySkills()

	self.leftCamp = SpriteCamp.new({ camp = "left", passiveSkills = passiveSkills, beauties = beauties})
	self.rightCamp = SpriteCamp.new({ camp = "right", passiveSkills = {}, beauties = {} })
	
	self:refreshAngrySlot(
		{ angryUnitNum = self.leftCamp.angryUnitNum, angryAccumulateTime = self.leftCamp.angryAccumulateTime })

	self.battleField = require("logical.battle.BattleField").new({ leftCamp = self.leftCamp, rightCamp = self.rightCamp })

	self:initLeftField()
	self:initRightField()

	self.heroBottomLayer = BottomBarController.new({ battle = self })
	self.heroBottomLayer:anch(0.5, 0):pos(display.cx, 0):addTo(self, BattleConstants.zOrderConstants["bottomBar"])
end

function LegendBattleLayer:initLeftField()
	-- 左边战场的武将
	local soldiers = game.role:getSelfFormationHeros()
	for _, soldier in ipairs(soldiers) do
		local col, row = BattleConstants:indexToAnch(soldier.index)
		soldier.anchPointX, soldier.anchPointY = col, row
	end

	self:addBattleHeros(soldiers)
end

function LegendBattleLayer:initRightField()
	-- 右边战场的武将
	local soldiers = self:getCarbonEnemys()
	self:addBattleHeros(soldiers)
end

function LegendBattleLayer:startGame()
	local saveLegendLimit = { roleId = game.role.id, param1 = self.carbonId,param2=1}--1：扣次数
	local bin = pb.encode("SimpleEvent", saveLegendLimit)
	game:sendData(actionCodes.LegendBattleEnterRequest, bin)
	loadingShow()
	game:addEventListener(actionModules[actionCodes.LegendBattleEnterResponse], function(event)
		loadingHide()
		
		self:setTouchEnabled(true)

		self:hideUI()
		self:showBattleUI()

		-- 阵型保存
		self:savePveFormation()

		self.battleLogic = require("logical.battle.Battle").new({ battleField =  self.battleField })
		self.battleLogic:init()

		-- 事件监听
		self.battleLogic:addEventListener("gameOver", handler(self, self.endGame))
		self.battleField:addEventListener("soldierDead", handler(self, self.onSoldierDead))

		self:showBeautyInspire(function()
				self:dispatchEvent({ name = "battleStart" })

				sharedScheduler:setTimeScale(game.role.battleSpeed)

				self.battleStatus = 1
				self.battleScheduleHandler = sharedScheduler:scheduleScriptFunc(function(diff) self.battleLogic:schedule(diff) end,
					2 / 60, false)
			end)

		return "__REMOVE__"
	end)

	
end

function LegendBattleLayer:endGame(event)
	if self.battleScheduleHandler then
		sharedScheduler:unscheduleScriptEntry(self.battleScheduleHandler)
		self.battleScheduleHandler = nil
	end
	sharedScheduler:setTimeScale(1)

	self:dispatchEvent({ name = "battleEnd" })

	self.effectLayer0:removeAllChildren()
	self.effectLayer1:removeAllChildren()

	showMaskLayer()
	self:runAction(transition.sequence{
		CCDelayTime:create(2),
		CCCallFunc:create(function()
			hideMaskLayer()
			-- 将战斗结果发往服务端
			local endGameRequest = {
				roleId = game.role.id,
				carbonId = self.carbonInfo.carbonId,
				starNum = event.starNum,
				diffIndex = self.diffIndex,
			}

			local bin = pb.encode("BattleEndResult", endGameRequest)

			game:rpcRequest({
				requestCode = actionCodes.LegendBattleEndRequest,
				requestData = bin,
				responseCode = actionCodes.LegendBattleEndResponse,
				callback = function(event)
					bulletManager:dispose()
					armatureManager:dispose()

					local msg = pb.decode("BattleEndResult", event.data)

					if msg.starNum > 0 then
						for _, dropItem in ipairs(msg.dropItems) do
							print("dropItem.num",dropItem.num)
							print(game.role.fragments[dropItem.itemId])
							if game.role.fragments[dropItem.itemId] then
								game.role.fragments[dropItem.itemId] = game.role.fragments[dropItem.itemId] + dropItem.num
							else
								game.role.fragments[dropItem.itemId] = dropItem.num
							end
						end
					end

					local battleEndLayer = BattleEndLayer.new({ 
						battleType = BattleType.Legend, carbonId = msg.carbonId, starNum = msg.starNum,
						money = msg.money, exp = msg.exp, dropItems = msg.dropItems or {},bgImg = self.bg:getTexture()
					})
					display.getRunningScene():addChild(battleEndLayer:getLayer())
				end,
			})
		end)
	})
end

-- 战场武将挂掉
function LegendBattleLayer:onSoldierDead(event)
	local soldier = self.battleField[event.camp .. "SoldierMap"][event.anchKey]

	if not soldier then return end
	
	self[event.camp .. "FormationPositions"][soldier.anchPoint.x][soldier.anchPoint.y].hero = nil
	if soldier:getState() == "skillAttack" then
		self:showSkillMask(false, soldier)
	end

	soldier.sprite:runAction(transition.sequence({
		CCFadeOut:create(1),
		CCCallFunc:create(function() soldier:dispose() end)
	}))	
end

-- 得到当前副本给定阶段的所有敌人信息
-- @return 	敌人的详细信息
function LegendBattleLayer:getCarbonEnemys()
	local function randLevel(array)
		local levelWeightArray = {}
		for level, weight in pairs(array) do
			table.insert(levelWeightArray, { level = level, weight = weight })
		end

		local randIndex = randWeight(levelWeightArray)

		return tonumber(levelWeightArray[randIndex].level)
	end

	local enemys = {}
	local bossLevel = randLevel(self.carbonInfo.heroLevels) + game.role.level
	bossLevel = bossLevel <= 0 and 1 or bossLevel
	local heroLevel = randLevel(self.carbonInfo.otherHeroLevels) + game.role.level
	heroLevel = heroLevel <= 0 and 1 or heroLevel
	
	local levelParam = game.role.level > 19 and game.role.level - 19 or 0
	local modify =1-- ( 0.8 + math.pow(levelParam, 1.2) * 0.02 + levelParam * 0.02 )

	for id, data in pairs(self.carbonSceneCsv:getStageSceneData(1)) do
		local unitData = unitCsv:getUnitByType(data.heroType)
		local heroProfessionInfo = heroProfessionCsv:getDataByProfession(unitData and unitData.profession or 0)
		if heroProfessionInfo then
			local Hero = require("datamodel.Hero")
			local level = data.boss == 1 and bossLevel or heroLevel
			local attrValues = Hero.sGetBaseAttrValues(data.heroType, level, data.evolutionCount%100)

			local enemy = {}
			enemy.camp = "right"
			enemy.anchPointX = data.x
			enemy.anchPointY = data.y
			enemy.type = data.heroType
			enemy.name = data.heroName
			-- 战斗属性修正
			enemy.hp = modify * attrValues.hp * (data.hp > 0 and data.hp or 100) / 100
			enemy.attack = modify * attrValues.atk * (data.attack > 0 and data.attack or 100)/ 100
			enemy.defense = modify * attrValues.def * (data.defense > 0 and data.defense or 100)/ 100

			enemy.level = level
			enemy.evolutionCount = data.evolutionCount

			-- 战斗属性替换
			enemy.moveSpeed = (data.moveSpeed ~= 0 and data.moveSpeed or (unitData.moveSpeed ~= 0 and unitData.moveSpeed or heroProfessionInfo.moveSpeed)) / 1000
			enemy.atkSpeedFactor = data.atkSpeedFactor + unitData.atkSpeedFactor
			enemy.attackRange = data.atcRange ~= 0 and data.atcRange or (unitData.atcRange ~= 0 and unitData.atcRange or heroProfessionInfo.atcRange)

			-- 二级属性
			enemy.hit = data.hit
			enemy.miss = data.miss
			enemy.parry = data.parry
			enemy.ignoreParry = data.ignoreParry
			enemy.crit = data.crit
			enemy.resist = data.resist
			enemy.critHurt = data.critHurt
			enemy.tenacity = data.tenacity

			-- 技能
			enemy.passiveSkills = {}

			enemy.skillable = data.hasSkill
			enemy.startSkillCdTime = data.startSkillCdTime
			enemy.skillCdTime = data.skillCdTime
			enemy.skillWeight = data.skillWeight
			enemy.beBoss = data.boss == 1	-- 敌方boss

			table.insert(enemys, enemy)
		end
	end

	return enemys
end

function LegendBattleLayer:onExit()
	if self.battleScheduleHandler then
		sharedScheduler:unscheduleScriptEntry(self.battleScheduleHandler)
		self.battleScheduleHandler = nil
	end
	game.role.leftMembers = 0
end

return LegendBattleLayer
