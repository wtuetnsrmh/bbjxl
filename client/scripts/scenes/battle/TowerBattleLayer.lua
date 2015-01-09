local SpriteCamp = import(".SpriteCamp")
local SpriteSoldier = import(".SpriteSoldier")
local ControlLayer = import(".ControlLayer")
local BaseBattleLayer = import(".BaseBattleLayer")
local BottomBarController = import(".BottomBarController")
local TowerBattleEndLayer = import("..tower.TowerBattleEndLayer")
local Hero = require("datamodel.Hero")

local sharedScheduler = CCDirector:sharedDirector():getScheduler()

local TowerBattleLayer = class("TowerBattleLayer", BaseBattleLayer)

function TowerBattleLayer:ctor(params)
	params = params or {}

	TowerBattleLayer.super.ctor(self, params)

	self.leftHeros = game.role.chooseHeros

	self.carbonId = params.carbonId
	self.difficult = params.difficult
	self.sceneId = params.sceneId

	self.carbonInfo = towerBattleCsv:getCarbonData(self.carbonId)
	self.towerDiffData = towerDiffCsv:getDiffData(self.difficult)
	self.towerSceneData = towerSceneCsv:getSceneData(self.sceneId)

	self.leftFormation = game.role.formationData

	self.battleLogic = nil

	-- 用于接收触摸事件
	self:setTouchEnabled(false)
	self.size = self:getContentSize()

	local heroTypes = {}
	local carbonSceneCsv = require("csv.CarbonSceneCsv")
	carbonSceneCsv:load(self.towerSceneData.sceneCsv)
	for id, data in pairs(carbonSceneCsv:getStageSceneData(1)) do
		if data.heroType > 0 then heroTypes[data.heroType] = true end
	end

	-- loading ui
	local battleLoadingLayer
	battleLoadingLayer = BattleLoadingLayer.new({ priority = -128,
		callback = function()
			CCTexture2D:PVRImagesHavePremultipliedAlpha(false)
			battleLoadingLayer:getLayer():removeSelf()

			self.bg = display.newSprite(self.towerSceneData.sceneBg)
			self.bg:pos(display.cx, display.cy):addTo(self)

			self:initCommonUI()
			self:initBattleField()
			game.role.leftMembers = table.nums(self.battleField.leftSoldierMap)
		end,
		loadingInfo = {
			images = { self.towerSceneData.sceneBg },
			heroTypes = heroTypes,
			loadRoleHeros = true,
		}
	})
	battleLoadingLayer:getLayer():addTo(display:getRunningScene())
end

-- 初始化战场
function TowerBattleLayer:initBattleField()
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

function TowerBattleLayer:initLeftField()
	-- 左边战场的武将
	local soldiers = game.role:getSelfFormationHeros()
	for _, soldier in ipairs(soldiers) do
		local col, row = BattleConstants:indexToAnch(soldier.index)

		soldier.camp = "left"
		soldier.anchPointX, soldier.anchPointY = col, row

		-- 属性加成
		soldier.atkModify = game.role.towerData.atkModify
		soldier.hpModify = game.role.towerData.hpModify
		soldier.defModify = game.role.towerData.defModify
	end

	self:addBattleHeros(soldiers)
end

function TowerBattleLayer:initRightField()
	-- 右边战场的武将
	local soldiers = self:getCarbonEnemys()
	self:addBattleHeros(soldiers)
end

function TowerBattleLayer:savePveFormation()
	game.role.pveFormation = {}
	for anchKey, soldier in pairs(self.battleField.leftSoldierMap) do
		local index = BattleConstants:anchToIndex(soldier.anchPoint.x, soldier.anchPoint.y)
		game.role.pveFormation[index] = soldier.id
	end
	game.role:updatePveFormation()

	-- 保存pvp战斗记录, 用于回放
end

function TowerBattleLayer:startGame()
	self:setTouchEnabled(true)

	self:hideUI()
	self:showBattleUI()

	-- 阵型保存
	self:savePveFormation()

	self.startTime = game:nowTime()

	self.battleLogic = require("logical.battle.Battle").new({ battleField =  self.battleField })
	self.battleLogic:init()

	-- 事件监听
	self.battleLogic:addEventListener("gameOver", handler(self, self.endGame))
	self.battleField:addEventListener("soldierDead", handler(self, self.onSoldierDead))

	self:showBeautyInspire(function()
		self:dispatchEvent({ name = "battleStart" })

		game:playMusic(3)

		sharedScheduler:setTimeScale(game.role.battleSpeed)

		self.battleStatus = 1
		self.battleScheduleHandler = sharedScheduler:scheduleScriptFunc(function(diff) self.battleLogic:schedule(diff) end,
			2 / 60, false)
	end)
end

function TowerBattleLayer:endGame(event)
	if self.battleScheduleHandler then
		sharedScheduler:unscheduleScriptEntry(self.battleScheduleHandler)
		self.battleScheduleHandler = nil
	end
	sharedScheduler:setTimeScale(1)

	self:dispatchEvent({ name = "battleEnd" })
	self.battleStatus = 2

	self.effectLayer0:removeAllChildren()
	self.effectLayer1:removeAllChildren()

	local startTm = os.date("*t", self.startTime)
	local nowTm = os.date("*t", game:nowTime())
	-- 早上4点，刷塔数据已经被重置
	if startTm.hour < 4 and nowTm.hour >= 4 then
		local dialog = ConfirmDialog.new({
			priority = -200,
			showText = { text = "过关斩将已重置，请开启新征程", size = 28, },
			button1Data = {
				callback = function()
					switchScene("tower")
				end,
			} 
		})
		dialog:getLayer():anch(0.5, 0.5):pos(display.cx, display.cy):addTo(display.getRunningScene(), 100)

		return
	end

	showMaskLayer()
	self:runAction(transition.sequence{
		CCDelayTime:create(1),
		CCCallFunc:create(function()
			hideMaskLayer()

			local towerEndData = {
				roleId = game.role.id,
				carbonId = self.carbonId,
				starNum = event.starNum,
				difficult = self.difficult,
			}

			local bin = pb.encode("TowerEndData", towerEndData)
			game:rpcRequest({
				requestCode = actionCodes.TowerBattleEnd,
				requestData = bin,
				responseCode = actionCodes.TowerDataResponse,
				callback = function(netEvent)
					bulletManager:dispose()
					armatureManager:dispose()
					
					local msg = pb.decode("TowerData", netEvent.data)
					local towerPbFields = { "count", "carbonId", "totalStarNum", "preTotalStarNum", 
						"maxTotalStarNum", "curStarNum", "hpModify", "atkModify", "defModify" }
					for _, field in pairs(towerPbFields) do
						game.role.towerData[field] = msg[field]
					end

					local dropItems = {}
					if self.carbonInfo.starSoulNum > 0 then
						table.insert(dropItems, { itemTypeId = ItemTypeId.StarSoul, itemId = 0, num = self.carbonInfo.starSoulNum })
					end

					local battleEndLayer = TowerBattleEndLayer.new({ 
						battleType = BattleType.Tower, starNum = event.starNum, 
						difficult = self.difficult, carbonId = self.carbonId, dropItems = dropItems,bgImg = self.bg:getTexture()
					})
					display.getRunningScene():addChild(battleEndLayer:getLayer())
				end,
			})
		end)
	})
end

-- 战场武将挂掉
function TowerBattleLayer:onSoldierDead(event)
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
-- @param carbonId 	副本ID
-- @param stage 	阶段
-- @return 	敌人的详细信息
function TowerBattleLayer:getCarbonEnemys()
	local stage = 1

	local carbonSceneCsv = require("csv.CarbonSceneCsv")
	carbonSceneCsv:load(self.towerSceneData.sceneCsv)

	local enemys = {}
	for id, data in pairs(carbonSceneCsv:getStageSceneData(stage)) do
		local unitData = unitCsv:getUnitByType(data.heroType)
		local heroProfessionInfo = heroProfessionCsv:getDataByProfession(unitData and unitData.profession or 0)
		
		if heroProfessionInfo then
			local evolutionCount = self.carbonInfo.evolutionCount + data.evolutionCount
			local attrValues = Hero.sGetBaseAttrValues(data.heroType, self.carbonInfo.level, evolutionCount%100)

			local enemy = {}
			
			enemy.camp = "right"
			enemy.name = data.heroName
			enemy.anchPointX = data.x
			enemy.anchPointY = data.y
			enemy.type = data.heroType

			enemy.hp = (self.towerDiffData.hpModify / 100) * (self.carbonInfo.attrModify / 100) * attrValues.hp * (data.hp > 0 and data.hp or 100) / 100
			enemy.attack = (self.towerDiffData.atkModify / 100) * (self.carbonInfo.attrModify / 100) * attrValues.atk * (data.attack > 0 and data.attack or 100)/ 100
			enemy.defense = (self.towerDiffData.defModify / 100) * (self.carbonInfo.attrModify / 100) * attrValues.def * (data.defense > 0 and data.defense or 100)/ 100
			enemy.level = self.carbonInfo.level
			enemy.evolutionCount = evolutionCount

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

			enemy.passiveSkills = {}

			enemy.skillable = data.hasSkill
			enemy.startSkillCdTime = data.startSkillCdTime
			enemy.skillCdTime = data.skillCdTime
			enemy.skillWeight = data.skillWeight

			enemy.beBoss = data.boss == 1

			table.insert(enemys, enemy)
		end
	end

	return enemys
end

function TowerBattleLayer:onExit()
	if self.battleScheduleHandler then
		sharedScheduler:unscheduleScriptEntry(self.battleScheduleHandler)
		self.battleScheduleHandler = nil
	end
	game.role.leftMembers = 0
	game:removeAllEventListenersForEvent(actionModules[actionCodes.TowerDataResponse])
end

return TowerBattleLayer
