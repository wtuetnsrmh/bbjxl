-- 开始战斗层
-- by yangkun
-- 2014.5.27

import(".BattleConstants")
local BossAppearLayer = import(".BossAppearLayer")
local SpriteCamp = import(".SpriteCamp")
local SpriteSoldier = import(".SpriteSoldier")
local BattlePlotLayer = import(".BattlePlotLayer")
local ControlLayer = import(".ControlLayer")
local BaseBattleLayer = import(".BaseBattleLayer")
local BattleLoadingLayer = require("scenes.BattleLoadingLayer") 
local StartBottomBarController = import(".StartBottomBarController")

local sharedScheduler = CCDirector:sharedDirector():getScheduler()
local TransitionMoveSpeed = 240

local StartBattleLayer = class("StartBattleLayer", BaseBattleLayer)

function StartBattleLayer:ctor(params)
	params = params or {}
	StartBattleLayer.super.ctor(self, params)

	self.battleLogic = nil
	self.curTimeScale = 1
	self.angryCD = params.angryCD
	self.angryUnitNum = params.angryUnitNum

	-- 用于接收触摸事件
	self:setTouchEnabled(false)


	local carbonSceneCsv = require("csv.CarbonSceneCsv")
	carbonSceneCsv:load("csv/scene/first/0001.csv")
	local carbonStageData = carbonSceneCsv:getStageSceneData(1)

	local heroTypes = {}
	for _, data in pairs(carbonStageData) do
		if data.heroType > 0 and not heroTypes[data.heroType] then
			heroTypes[data.heroType] = true
		end
	end
	
	carbonSceneCsv:load("csv/scene/first/9999.csv")
	carbonStageData = carbonSceneCsv:getStageSceneData(1)

	for _, data in pairs(carbonStageData) do
		if data.heroType > 0 and not heroTypes[data.heroType] then
			heroTypes[data.heroType] = true
		end
	end

	-- loading ui
	local battleLoadingLayer
	battleLoadingLayer = BattleLoadingLayer.new({ priority = -128,
		callback = function()
			battleLoadingLayer:getLayer():removeSelf()
			self:enterBattle() 
		end,
		loadingInfo = {
			images = { "resource/bg/chibi_2.jpg" },
			heroTypes = heroTypes,
			loadRoleHeros = false,
		}
	})
	battleLoadingLayer:getLayer():addTo(display:getRunningScene())
end

function StartBattleLayer:enterBattle()
	self.bg = display.newSprite("resource/bg/chibi_2.jpg")
	self.bg:pos(display.cx, display.cy):addTo(self, BattleConstants.zOrderConstants["background"])

	local plotLayer = BattlePlotLayer.new({ carbonId = 10001, phase = 1,
			onComplete = function()
				self:initCommonUI(params)
				self:initBattleField()
				self:bossAppear()
			end 
		})
	plotLayer:addTo(self, BattleConstants.zOrderConstants["plot"])
end

function StartBattleLayer:bossAppear()
	local carbonSceneCsv = require("csv.CarbonSceneCsv")
	carbonSceneCsv:load("csv/scene/first/9999.csv")
	local bossInfo = carbonSceneCsv:getStageBoss(1)
	if bossInfo then
		sharedScheduler:setTimeScale(1)
		self.battleField:pause(true)
		self:pause()
		local currentBossAppear = BossAppearLayer.new({ bossInfo = bossInfo, onComplete = function()
			self:resume()
			self.battleField:pause(false)
			sharedScheduler:setTimeScale(self.curTimeScale)

		end})
		self:addChild(currentBossAppear:getLayer(), BattleConstants.zOrderConstants["bossAppear"])
	end
end

function StartBattleLayer:initBattleField(leftSoldiers, rightSoldiers)
	self:removeAllEventListeners()
	
	if self.leftCamp then
		self.leftCamp:reset()
	else
		self.leftCamp = SpriteCamp.new({ camp = "left" , battleType = BattleType.Start, angryCD = self.angryCD, angryUnitNum = self.angryUnitNum})
		self:refreshAngrySlot(
			{ angryUnitNum = self.leftCamp.angryUnitNum, angryAccumulateTime = self.leftCamp.angryAccumulateTime })
	end

	if self.rightCamp then
		self.rightCamp:reset()
	else
		self.rightCamp = SpriteCamp.new({ camp = "right" , battleType = BattleType.Start})
	end

	self.battleField = require("logical.battle.BattleField").new({ leftCamp = self.leftCamp, rightCamp = self.rightCamp })
	self:initLeftField(leftSoldiers)
	self:initRightField(rightSoldiers)

	self.heroBottomLayer = StartBottomBarController.new({ battle = self })
	self.heroBottomLayer:anch(0.5, 0):pos(display.cx, 0):addTo(self, BattleConstants.zOrderConstants["bottomBar"])
end


function StartBattleLayer:initLeftField(soldiers)
	-- 左边战场的武将
	if not soldiers then
		soldiers = self:getBattleSoldiers("left")
	end

	self:addBattleHeros(soldiers)
end

function StartBattleLayer:initRightField(soldiers)
	-- 右边战场的武将
	if not soldiers then
		soldiers = self:getBattleSoldiers("right")
	end

	self:addBattleHeros(soldiers)
end


function StartBattleLayer:getBattleSoldiers(leftOrRight)
	local carbonSceneCsv = require("csv.CarbonSceneCsv")
	if leftOrRight == "left" then
		carbonSceneCsv:load("csv/scene/first/0001.csv")
	else
		carbonSceneCsv:load("csv/scene/first/9999.csv")
	end

	local enemys = {}
	for id, data in pairs(carbonSceneCsv:getStageSceneData(1)) do
		local unitData = unitCsv:getUnitByType(data.heroType)
		local heroProfessionInfo = heroProfessionCsv:getDataByProfession(unitData and unitData.profession or 0)
		if heroProfessionInfo then
			local Hero = require("datamodel.Hero")
			local attrValues = Hero.sGetBaseAttrValues(data.heroType, 100, data.evolutionCount)

			local enemy = {}
			enemy.camp = leftOrRight 
			enemy.anchPointX = data.x
			enemy.anchPointY = data.y
			enemy.type = data.heroType
			enemy.name = data.heroName
			enemy.star = HERO_MAX_STAR
			-- 战斗属性修正
			enemy.hp = attrValues.hp * (data.hp > 0 and data.hp or 100) / 100
			enemy.attack = attrValues.atk * (data.attack > 0 and data.attack or 100)/ 100
			enemy.defense = attrValues.def * (data.defense > 0 and data.defense or 100)/ 100
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
			enemy.skillable = data.hasSkill
			enemy.startSkillCdTime = data.startSkillCdTime
			enemy.skillCdTime = data.skillCdTime
			enemy.skillWeight = data.skillWeight
			enemy.beBoss = data.boss == 1	-- 敌方boss

			enemy.startShow = true	-- 展示性的武将

			table.insert(enemys, enemy)
		end
	end

	return enemys
end


function StartBattleLayer:startGame()
	self:hideBattleUI()
		
	game:playMusic(3)

	self.battleLogic = require("logical.battle.Battle").new({ battleField =  self.battleField, randomSeed = 17278738292 })
	self.battleLogic:init()

	-- 事件监听
	self.battleLogic:addEventListener("gameOver", handler(self, self.endPhaseGame))
	self.battleField:addEventListener("soldierDead", handler(self, self.onSoldierDead))

	self:dispatchEvent({ name = "battleStart" })

	sharedScheduler:setTimeScale(self.curTimeScale)

	self.battleStatus = 1
	self.battleScheduleHandler = sharedScheduler:scheduleScriptFunc(function(diff) self.battleLogic:schedule(diff) end,
		2 / 60, false)
end

function StartBattleLayer:endPhaseGame(event)
	self:setTouchEnabled(false)
	if self.battleScheduleHandler then
		sharedScheduler:unscheduleScriptEntry(self.battleScheduleHandler)
		self.battleScheduleHandler = nil
	end
	
	self.effectLayer0:removeAllChildren()
	self.effectLayer1:removeAllChildren()

	local plotLayer = BattlePlotLayer.new({ carbonId = 10001, phase = 4,
			onComplete = function()
				local bin = pb.encode("RoleCreate", { uid = game.platform_uid, uname = game.platform_uname,
					packageName = PACKAGE_NAME, deviceId = game.device })
				game:sendData(actionCodes.RoleCreate, bin)
				loadingShow(true)
				game:addEventListener(actionModules[actionCodes.RoleCreateResponse], function(event)
					loadingHide()
					local msg = pb.decode("RoleCreateResponse", event.data)

					if msg.result == "DB_ERROR" then
					elseif msg.result == "EXIST" then
						DGMsgBox.new({ type = 1, text = "名字已存在！请换个名字吧~" })
					elseif msg.result == "ILLEGAL_NAME" then
						DGMsgBox.new({ type = 1, text = "名字中含有敏感字！请换个名字吧~" })
					else
						GameState.save(GameData)
						-- 登录玩家
						local bin = pb.encode("RoleLoginData", { name = msg.roleName, packageName = PACKAGE_NAME,
							deviceId = game.device })
						game:sendData(actionCodes.RoleLoginRequest, bin)
						loadingShow()
						game:addEventListener(actionModules[actionCodes.RoleLoginResponse], function(event)
							socketActions:roleLoginResponse(event, { create = true })
						end)
						print("成功创建角色。。。")
					end
				end)
			end 
		})
	plotLayer:addTo(self, BattleConstants.zOrderConstants["plot"])
end

-- 隐藏战斗显示的UI
function StartBattleLayer:hideBattleUI()
	StartBattleLayer.super.hideUI(self)
end

-- 战场武将挂掉
function StartBattleLayer:onSoldierDead(event)
	local soldier = self.battleField[event.camp .. "SoldierMap"][event.anchKey]

	if soldier then
		self[event.camp .. "FormationPositions"][soldier.anchPoint.x][soldier.anchPoint.y].hero = nil
		if soldier:getState() == "skillAttack" then
			self:showSkillMask(false, soldier)
		end
		
		soldier.sprite:runAction(transition.sequence({
			CCFadeOut:create(1),
			CCCallFunc:create(function() soldier:dispose() end)
		}))	
	end
end

function StartBattleLayer:onExit()
	if self.battleScheduleHandler then
		sharedScheduler:unscheduleScriptEntry(self.battleScheduleHandler)
		self.battleScheduleHandler = nil
	end
end


return StartBattleLayer