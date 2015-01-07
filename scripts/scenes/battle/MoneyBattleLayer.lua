local MoneyBattleRes = "resource/ui_rc/activity/money/"

import(".BattleConstants")
local SpriteCamp = import(".SpriteCamp")
local SpriteSoldier = import(".SpriteSoldier")
local BossAppearLayer = import(".BossAppearLayer")
local BattlePlotLayer = import(".BattlePlotLayer")
local ControlLayer = import(".ControlLayer")
local BottomBarController = import(".BottomBarController")
local BaseBattleLayer = import(".BaseBattleLayer")


local sharedScheduler = CCDirector:sharedDirector():getScheduler()
local TransitionMoveSpeed = 240

local MoneyBattleLayer = class("MoneyBattleLayer", BaseBattleLayer)

function MoneyBattleLayer:ctor(params)
	self.params = params or {}
	MoneyBattleLayer.super.ctor(self, params)

	self.battleLogic = nil     ---????
	self.killCount = 0              ---杀死对手数量；
	self.enemyCount = 0

	-- 用于接收触摸事件
	self:setTouchEnabled(false)

	-- 特殊副本：
	self.currentStage = params.round
	self:initCarbonData(params.battleindex, self.currentStage) --战斗的难度index 和 默认回合数

	-- 第一阵敌方人物骨骼动画
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
			self:enterBattle() 
		end,
		loadingInfo = {
			images = { self.carbonInfo["bgRes" .. self.currentStage]}, ---战场bg
			heroTypes = heroTypes,
		}
	})
	battleLoadingLayer:getLayer():addTo(display:getRunningScene())
end

function MoneyBattleLayer:enterBattle()
	--初始化战场背景
	self.bg = display.newSprite(self.carbonInfo["bgRes" .. self.currentStage])
	self.bg:pos(display.cx, display.cy):addTo(self, BattleConstants.zOrderConstants["background"])

	self:initCommonUI(self.params)

	self:initBattleField()
	game.role.leftMembers = table.nums(self.battleField.leftSoldierMap)
end

-- 初始化副本数据
function MoneyBattleLayer:initCarbonData(carbonId, stage)--战场index and 当前回合
	self.carbonInfo = moneyBattleCsv:getDataById(carbonId) 
	self.totalStage = tonumber(self.carbonInfo.maxround) --回合总数；
	
	local infoTable = self.carbonInfo.btres               --对应配表path
	self.carbonSceneCsv = require("csv.CarbonSceneCsv")   --配表model
	self.carbonSceneCsv:load(infoTable)                   --加载配表信息
end

-- 初始化战场
function MoneyBattleLayer:initBattleField(leftSoldiers, rightSoldiers)
	self:removeAllEventListeners()
	
	if self.leftCamp then
		self.leftCamp:reset()
	else
		local passiveSkills, beauties = game.role:getFightBeautySkills()

		self.leftCamp = SpriteCamp.new({ camp = "left", passiveSkills = passiveSkills, 
			beauties = beauties })

		self:refreshAngrySlot(
			{ angryUnitNum = self.leftCamp.angryUnitNum, angryAccumulateTime = self.leftCamp.angryAccumulateTime })
	end

	if self.rightCamp then
		self.rightCamp:reset()
	else
		self.rightCamp = SpriteCamp.new({ camp = "right", passiveSkills = {}, beauties = {} })
	end

	self.battleField = require("logical.battle.BattleField").new({ leftCamp = self.leftCamp, rightCamp = self.rightCamp })
	self:initLeftField(leftSoldiers)
	self:initRightField(rightSoldiers)

	-- 非第一阵，且不用暂停
	if self.heroBottomLayer then
		self.heroBottomLayer:removeSelf()
	end

	self.heroBottomLayer = BottomBarController.new({ battle = self })
	self.heroBottomLayer:anch(0.5, 0):pos(display.cx, 0):addTo(self, BattleConstants.zOrderConstants["bottomBar"])

	self:bossAppear() 
end

function MoneyBattleLayer:initLeftField(soldiers)
	-- 左边战场的武将
	if not soldiers then 
		soldiers = game.role:getSelfFormationHeros()
		for _, soldier in ipairs(soldiers) do
			local col, row = BattleConstants:indexToAnch(soldier.index)
			soldier.anchPointX, soldier.anchPointY = col, row
		end
	end

	self:addBattleHeros(soldiers)
end

function MoneyBattleLayer:initRightField(soldiers)
	-- 右边战场的武将
	if not soldiers then
		soldiers = self:getCarbonEnemys(self.currentStage)
	end

	self:addBattleHeros(soldiers)
end

function MoneyBattleLayer:bossAppear()
	local stageBg = display.newSprite(BattleRes .. "stage_bg.png")
	local stageBgSize = stageBg:getContentSize()

	stageBg:pos(display.cx, display.cy):addTo(self, BattleConstants.zOrderConstants["stage"]):setScaleY(0.1)

	local function stageEnd()
		local endSprite = display.newSprite(BattleRes .. "stage.png")
		endSprite:pos(stageBgSize.width / 2 + 160, stageBgSize.height / 2):addTo(stageBg, 0, 3)

		local actions = {}
		actions[#actions + 1] = CCDelayTime:create(0.5)
		actions[#actions + 1] = CCCallFunc:create(function()
			for tag = 1, 3 do stageBg:removeChildByTag(tag) end
		end)
		actions[#actions + 1] = CCScaleTo:create(0.3, 1, 0)
		actions[#actions + 1] = CCDelayTime:create(0.2)
		actions[#actions + 1] = CCRemoveSelf:create()
		actions[#actions + 1] = CCCallFunc:create(function()
			local bossInfo = self.carbonSceneCsv:getStageBoss(self.currentStage)
			if bossInfo then
				sharedScheduler:setTimeScale(1)
				self.battleField:pause(true)
				self:pause()
				local currentBossAppear = BossAppearLayer.new({ bossInfo = bossInfo, onComplete = function()
					self:resume()
					self.battleField:pause(false)
					sharedScheduler:setTimeScale(game.role.battleSpeed)

				end})
				self:addChild(currentBossAppear:getLayer(), BattleConstants.zOrderConstants["bossAppear"])
			end
		end)

		stageBg:runAction(transition.sequence(actions))
	end
	
	local function stageNumber()
		local numberBg = display.newSprite(BattleRes .. self.currentStage .."_stage.png")
		numberBg:pos(stageBgSize.width / 2, stageBgSize.height / 2):addTo(stageBg, 0, 2):hide()

		numberBg:runAction(transition.sequence({
			CCShow:create(),
			CCDelayTime:create(0.1),
			CCCallFunc:create(function() stageEnd() end)
		}))
	end

	local function stageBegin()
		local begin = display.newSprite(BattleRes .. "stage_number.png")
		begin:pos(stageBgSize.width / 2 - 160, stageBgSize.height / 2):addTo(stageBg, 0, 1):hide()

		begin:runAction(transition.sequence({
			CCShow:create(),
			CCDelayTime:create(0.1),
			CCCallFunc:create(function() stageNumber() end)
		}))
	end

	local actions = {}
	actions[#actions + 1] = transition.newEasing(CCScaleTo:create(0.3, 1, 1), "OUT")
	actions[#actions + 1] = CCCallFunc:create(function() stageBegin() end)
	stageBg:runAction(transition.sequence(actions))
end

function MoneyBattleLayer:startGame()
	if self.currentStage == 1 then
		self:hideBattleUI()
		self:createBattleUI()
		-- 阵型保存
		self:savePveFormation()

		game:playMusic(3)

		self:showBattleUI()
		self:showLeftTime()
		self.speedUpBtn:setBg(nil, {BattleRes .. game.role.battleSpeed .. "_speed.png"})

		self.battleLogic = require("logical.battle.Battle").new({ battleField =  self.battleField })
		self.battleLogic:init()

		-- 事件监听
		self.battleLogic:addEventListener("gameOver", handler(self, self.endPhaseGame))
		self.battleField:addEventListener("soldierDead", handler(self, self.onSoldierDead))

		-- 美人鼓舞
		self:showBeautyInspire(function()
			self:dispatchEvent({ name = "battleStart" })

			sharedScheduler:setTimeScale(game.role.battleSpeed)

			self.battleStatus = 1
			self.battleScheduleHandler = sharedScheduler:scheduleScriptFunc(function(diff) self.battleLogic:schedule(diff) end,
				2 / 60, false)
		end)
	else
		self:showBattleUI()
		self:showLeftTime()
		self.speedUpBtn:setBg(nil, {BattleRes .. game.role.battleSpeed .. "_speed.png"})

		self.battleLogic = require("logical.battle.Battle").new({ battleField =  self.battleField })
		self.battleLogic:init()

		-- 事件监听
		self.battleLogic:addEventListener("gameOver", handler(self, self.endPhaseGame))
		self.battleField:addEventListener("soldierDead", handler(self, self.onSoldierDead))

		self:dispatchEvent({ name = "battleStart" })

		sharedScheduler:setTimeScale(game.role.battleSpeed)

		self.battleStatus = 1
		self.battleScheduleHandler = sharedScheduler:scheduleScriptFunc(function(diff) self.battleLogic:schedule(diff) end,
			2 / 60, false)
	end	
end

function MoneyBattleLayer:showLeftTime()
	self.leftTime = 60--globalCsv:getFieldValue("battleMaxTime")
	if self.leftTimeLabel then	
		self.leftTimeLabel:setString(self:getLeftTimeString(self.leftTime))
		self.leftTimeLabel:setVisible(true)
	else
		self.leftTimeLabel = ui.newTTFLabelWithStroke({text = self:getLeftTimeString(self.leftTime), size = 26, color = display.COLOR_GREEN })
		self.leftTimeLabel:pos(display.cx - 320,display.height - 45):addTo(self)
	end

	local setLeftTime
	setLeftTime = function()
		if self.leftTime > 0 then
			self.leftTimeLabel:setString(self:getLeftTimeString(self.leftTime))
			self.leftTime = self.leftTime - 1

			self.leftTimeLabel:runAction(transition.sequence({
				CCDelayTime:create(1),
				CCCallFunc:create(setLeftTime),
			}))
		else
			self.leftTimeLabel:setString(self:getLeftTimeString(self.leftTime))
			self:setTouchEnabled(false)
			
			sharedScheduler:unscheduleScriptEntry(self.battleScheduleHandler)
			sharedScheduler:setTimeScale(1) 

			local endGameRequest = {
				roleId = game.role.id,
				param1 = self.carbonInfo.id,
				param2 = self.killCount,
				param3 = self.currentStage - 1,
			}

			local bin = pb.encode("SimpleEvent", endGameRequest)
			game:rpcRequest({
				requestCode = actionCodes.MoneyBattleEndRequest,
				requestData = bin,
				responseCode = actionCodes.MoneyBattleEndRequest,
				callback = function(event)
					local msg = pb.decode("SimpleEvent", event.data)
					--战斗结算：
					local param = {carbonId = self.carbonInfo.id,all = self.enemyCount, kill = self.killCount, money = msg.param1,exp=msg.param2,bgImg = self.bg:getTexture()}
					local endlayer = require("scenes.battle.MoneyBattleEndLayer")
					local showRewardLayer = endlayer.new(param)
					display.getRunningScene():addChild(showRewardLayer:getLayer())
				end,
			})
		end
	end
	setLeftTime()
end

function MoneyBattleLayer:getLeftTimeString(time)
	local minute = math.floor(time / 60)
	local second = time % 60
	return string.format("%02d:%02d", minute, second)
end

--战斗结束：
function MoneyBattleLayer:endPhaseGame(event)
	self:setTouchEnabled(false)
	if self.battleScheduleHandler then
		sharedScheduler:unscheduleScriptEntry(self.battleScheduleHandler)
		self.battleScheduleHandler = nil
	end
	
	self.effectLayer0:removeAllChildren()
	self.effectLayer1:removeAllChildren()
	self.currentStage = (event.starNum == 0 and self.currentStage or self.currentStage + 1)

	if self.leftTimeLabel then
		self.leftTimeLabel:stopAllActions()
		self.leftTimeLabel:setVisible(false)
	end
	if self.currentStage > self.totalStage or event.starNum == 0 then
		local function sendGameEndRequest()
			-- 将战斗结果发往服务端
			local endGameRequest = {
				roleId = game.role.id,
				param1 = self.carbonInfo.id,
				param2 = self.killCount,
				param3 = self.currentStage - 1,
			}
			local bin = pb.encode("SimpleEvent", endGameRequest)
			game:rpcRequest({
				requestCode = actionCodes.MoneyBattleEndRequest,
				requestData = bin,
				responseCode = actionCodes.MoneyBattleEndRequest,
				callback = function(event)
					bulletManager:dispose()
					armatureManager:dispose()

					local msg = pb.decode("SimpleEvent", event.data)
					--战斗结算
					local param = {carbonId = self.carbonInfo.id,all = self.enemyCount, kill = self.killCount,exp=msg.param2, money = msg.param1,bgImg = self.bg:getTexture()}
					local endlayer = require("scenes.battle.MoneyBattleEndLayer")
					local showRewardLayer = endlayer.new(param)
					display.getRunningScene():addChild(showRewardLayer:getLayer())
				end,
			})
		end

		self:dispatchEvent({ name = "battleEnd" })
		self.battleStatus = 2
		
		showMaskLayer()
		self:runAction(transition.sequence({
			CCDelayTime:create(1),
			CCCallFunc:create(function()
				hideMaskLayer()

				sharedScheduler:setTimeScale(1) 
				sendGameEndRequest()
			end)
		}))
	else
		local aliveSoldiers = {}

		-- 下一阵
		local function nextPhaseBattle()
			-- 移除上场的背景资源
			if self.bg then self.bg:removeSelf() end
			display.removeSpriteFrameByImageName(self.carbonInfo["bgRes" .. (self.currentStage - 1)])	
			
			self.bg = display.newSprite(self.carbonInfo["bgRes" .. self.currentStage])
			self.bg:pos(display.cx, display.cy):addTo(self, BattleConstants.zOrderConstants["background"])

			self.curStageTips:setString(self.currentStage .. "/" .. self.totalStage)

			-- 多阵暂停
			if globalCsv:getFieldValue("pauseBattle") == 1 then
				-- 左侧占位符
				for col = 1, self.colCount do
					for row = 1, self.rowCount do
						self.leftFormationPositions[col][row].placeHolder:show()
					end
				end

				for col = 1, self.colCount do
					for row = 1, self.rowCount do
						self.rightFormationPositions[col][row].placeHolder:show()
					end
				end
				self.speedUpBtn:showBtn(false)
				self.autoGameBtn:showBtn(false)
			end

			self:initBattleField(aliveSoldiers)
		end

		-- 呐喊音效
		-- game:playMusic(23)
		self:dispatchEvent({ name = "battleEnd" })

		-- 左侧士兵
		-- 左边士兵从右上优先
		local leftSoldiers = table.values(self.battleField.leftSoldierMap)
		table.sort(leftSoldiers, function(a, b) return a.position.x > b.position.x end)

		-- 剔除死亡士兵
		for i,soldier in ipairs(leftSoldiers) do
			if not soldier:isState("dead") then
				table.insert(aliveSoldiers, soldier)
			else
				soldier:dispatchEvent({ name = "soldierDead" })
				soldier.battleField:removeSoldier(soldier)
			end
		end
		
		--恢复怒气
		self.battleField.leftCamp:addAngryUnit(globalCsv:getFieldValue("phaseAnger"))
		
		for index, soldier in ipairs(aliveSoldiers) do
			soldier:recoverHp()
			soldier.animation:setSpeedScale(0.4)
			soldier.animation:play("move") 

			soldier.displayNode:runAction(transition.sequence({
				CCMoveBy:create((display.width + 100 - soldier.position.x) / TransitionMoveSpeed, 
					ccp(display.width - soldier.position.x + 100, 0)),
				CCCallFunc:create(function() 
					soldier:clearStatus()
					-- 最后一个士兵
					if index == #aliveSoldiers then
						-- 清理上一场的资源
						local reservedHeros = {}
						for _, soldier in pairs(self.battleField.leftSoldierMap) do
							reservedHeros[soldier.type] = true
						end

						-- 加载下一场景资源, 合并不需要加载的资源
						local heroTypes = {}
						for _, data in pairs(self.carbonSceneCsv:getStageSceneData(self.currentStage)) do
							local hasLoaded = armatureManager:hasLoaded(data.heroType)
							if data.heroType > 0 and hasLoaded then
								reservedHeros[data.heroType] = true
							elseif data.heroType > 0 and not hasLoaded then
								heroTypes[data.heroType] = true
							end
						end

						armatureManager:reserveTypes(reservedHeros)

						if table.nums(heroTypes) == 0 then
							nextPhaseBattle()
							CCTexture2D:PVRImagesHavePremultipliedAlpha(false)
						else
							local function boneLoaded(percent)
								if percent < 1 then return end
								
								CCTexture2D:PVRImagesHavePremultipliedAlpha(false)
								nextPhaseBattle()
							end

							for type, _ in pairs(heroTypes) do
								armatureManager:asyncLoad(type, boneLoaded)
							end		
						end
					end
				end),
			}))
		end
	end
end

-- 战场武将挂掉
function MoneyBattleLayer:onSoldierDead(event)
	local soldier = self.battleField[event.camp .. "SoldierMap"][event.anchKey]

	if event.camp == "right" then
		self.killCount = self.killCount + 1

		local path = "resource/ui_rc/battle/font/time.fnt"
		local killCount = ui.newBMFontLabel({ text = self.killCount, font = path})
		local killLabel = display.newSprite(MoneyBattleRes .. "kill_text.png")

		local showNode = display.newNode()
		showNode:size(killCount:getContentSize().width + killLabel:getContentSize().width,
			killLabel:getContentSize().height)
		killCount:anch(0, 0):pos(0, showNode:getContentSize().height / 2):addTo(showNode)
		killLabel:anch(1, 0):pos(showNode:getContentSize().width, 0):addTo(showNode)

		showNode:anch(0.5, 0.5):pos(soldier.position.x, soldier.position.y + 100)
			:scale(0.2):addTo(self, BattleConstants.zOrderConstants["effect0"])
			:runAction(transition.sequence{
				CCScaleTo:create(0.3, 1),
				CCMoveBy:create(0.2, ccp(0, 100)),
				CCDelayTime:create(0.5),
				CCRemoveSelf:create()
			})

		local moneyIcon = display.newSprite(MoneyBattleRes .. "ic_money_big.png")
		moneyIcon:pos(soldier.position.x, soldier.position.y):addTo(self)
			:runAction(transition.sequence{
				CCMoveBy:create(0.2, ccp(0, -50)),
				CCDelayTime:create(1),
				CCSpawn:createWithTwoActions(
					CCMoveTo:create(0.5, ccp(display.cx, display.height - 45)),
					CCFadeOut:create(0.5)),
				CCRemoveSelf:create(),
				CCCallFunc:create(function() 
					local num = tonumber(self.moneyNum:getString())
					self.moneyNum:setString(num + self.carbonInfo.killMoney)
				end)
			})
		-- 光圈
		display.newSprite(MoneyBattleRes .. "money_light.png"):addTo(moneyIcon, -1)
			:pos(moneyIcon:getContentSize().width / 2, moneyIcon:getContentSize().height / 2)
			:runAction(CCRepeatForever:create(CCRotateBy:create(0.2, 20)))

		-- 过关奖励
		if table.nums(self.battleField.rightSoldierMap) == 1 then
			local moneyIcon = display.newSprite(MoneyBattleRes .. "ic_money_big.png")
			moneyIcon:pos(soldier.position.x + 100, soldier.position.y):addTo(self)
				:runAction(transition.sequence{
					CCMoveBy:create(0.2, ccp(0, -50)),
					CCDelayTime:create(1),
					CCSpawn:createWithTwoActions(
						CCMoveTo:create(0.5, ccp(display.cx, display.height - 45)),
						CCFadeOut:create(0.5)),
					CCRemoveSelf:create(),
					CCCallFunc:create(function() 
						local num = tonumber(self.moneyNum:getString())
						local delta = self.carbonInfo.passAward + (self.currentStage - 2) * self.carbonInfo.passGrowth
						self.moneyNum:setString(num + delta)
					end)
				})
			-- 光圈
			display.newSprite(MoneyBattleRes .. "money_light.png"):addTo(moneyIcon, -1)
				:pos(moneyIcon:getContentSize().width / 2, moneyIcon:getContentSize().height / 2)
				:runAction(CCRepeatForever:create(CCRotateBy:create(0.2, 20)))
		end
	end

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

function MoneyBattleLayer:createBattleUI()
	MoneyBattleLayer.super.showBattleUI(self)

	-- 当前阶段
	self.curStageTips = ui.newTTFLabelWithStroke({ text = self.currentStage .. "/" .. self.totalStage, size = 40 })
	self.curStageTips:pos(display.cx - 240, display.height - 45):addTo(self)

	-- 金钱数目
	local moneyBg = display.newSprite(MoneyBattleRes .. "bg_money.png")
	local moneyBgSize = moneyBg:getContentSize()
	moneyBg:pos(display.cx, display.height - 45):addTo(self)

	display.newSprite(MoneyBattleRes .. "ic_money.png"):anch(0, 0.5)
		:pos(10, moneyBgSize.height / 2):addTo(moneyBg)
	self.moneyNum = ui.newTTFLabelWithStroke({ text = "0", size = 26 })
	self.moneyNum:pos(moneyBgSize.width / 2 + 25, moneyBgSize.height / 2):addTo(moneyBg)
end

-- 隐藏战斗显示的UI
function MoneyBattleLayer:hideBattleUI()
	MoneyBattleLayer.super.hideUI(self)
end

-- 得到当前副本给定阶段的所有敌人信息
-- @param carbonId 	副本ID
-- @param stage 	阶段
-- @return 	敌人的详细信息
function MoneyBattleLayer:getCarbonEnemys(stage)
	local enemys = {}
	self.enemyCount = self.enemyCount + table.nums(self.carbonSceneCsv:getStageSceneData(stage))
	for id, data in pairs(self.carbonSceneCsv:getStageSceneData(stage)) do
		local unitData = unitCsv:getUnitByType(data.heroType)
		local heroProfessionInfo = heroProfessionCsv:getDataByProfession(unitData and unitData.profession or 0)
		if heroProfessionInfo then
			local Hero = require("datamodel.Hero")
			--全哥要求士兵写死为1级
			local level = 1
			local attrValues = Hero.sGetBaseAttrValues(data.heroType, level, data.evolutionCount%100)

			local enemy = {}
			enemy.camp = "right"
			enemy.anchPointX = data.x
			enemy.anchPointY = data.y
			enemy.type = data.heroType
			enemy.name = data.heroName
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

			table.insert(enemys, enemy)
		end
	end

	return enemys
end

function MoneyBattleLayer:onExit()
	if self.battleScheduleHandler then
		sharedScheduler:unscheduleScriptEntry(self.battleScheduleHandler)
		self.battleScheduleHandler = nil
	end
	game.role.leftMembers = 0
end

return MoneyBattleLayer