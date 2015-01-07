local MoneyBattleRes = "resource/ui_rc/activity/money/"

import(".BattleConstants")
local SpriteCamp = import(".SpriteCamp")
local SpriteSoldier = import(".SpriteSoldier")
local BossAppearLayer = import(".BossAppearLayer")
local BattlePlotLayer = import(".BattlePlotLayer")
local ControlLayer = import(".ControlLayer")
local BottomBarController = import(".BottomBarController")
local BaseBattleLayer = import(".BaseBattleLayer")
local BattleEndLayer = import(".BattleEndNewLayer")

local sharedScheduler = CCDirector:sharedDirector():getScheduler()
local TransitionMoveSpeed = 240

local TrialBattleLayer = class("TrialBattleLayer", BaseBattleLayer)

function TrialBattleLayer:ctor(params)
	self.params = params or {}
	TrialBattleLayer.super.ctor(self, params)

	self.battleLogic = nil     ---????
	self.killCount = 0              ---杀死对手数量；
	self.enemyCount = 0
	self.dropItems = params.dropItems
	-- 用于接收触摸事件
	self:setTouchEnabled(false)

	-- 特殊副本：
	self.currentStage = 1
	self:initCarbonData(params.carbonId, self.currentStage) --战斗的难度index 和 默认回合数

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

function TrialBattleLayer:enterBattle()
	--初始化战场背景
	self.bg = display.newSprite(self.carbonInfo["bgRes" .. self.currentStage])
	self.bg:pos(display.cx, display.cy):addTo(self, BattleConstants.zOrderConstants["background"])

	self:initCommonUI(self.params)

	self:initBattleField()
	game.role.leftMembers = table.nums(self.battleField.leftSoldierMap)
end

-- 初始化副本数据
function TrialBattleLayer:initCarbonData(carbonId, stage)--战场index and 当前回合
	self.carbonInfo = trialBattleCsv:getDataById(carbonId) 
	self.totalStage = tonumber(self.carbonInfo.maxround) --回合总数；
	
	local infoTable = self.carbonInfo.btres               --对应配表path
	self.carbonSceneCsv = require("csv.CarbonSceneCsv")   --配表model
	self.carbonSceneCsv:load(infoTable)                   --加载配表信息
end

-- 初始化战场
function TrialBattleLayer:initBattleField(leftSoldiers, rightSoldiers)
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

function TrialBattleLayer:initLeftField(soldiers)
	-- 左边战场的武将
	if not soldiers then 
		soldiers = self.params.soldiers
		for _, soldier in ipairs(soldiers) do
			local col, row = BattleConstants:indexToAnch(soldier.index)
			soldier.anchPointX, soldier.anchPointY = col, row
		end
	end

	self:addBattleHeros(soldiers)
end

function TrialBattleLayer:initRightField(soldiers)
	-- 右边战场的武将
	if not soldiers then
		soldiers = self:getCarbonEnemys(self.currentStage)
	end

	self:addBattleHeros(soldiers)
end

function TrialBattleLayer:bossAppear()
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

function TrialBattleLayer:savePveFormation()
	local formation = {}
	
	for anchKey, soldier in pairs(self.battleField.leftSoldierMap) do
		local index = BattleConstants:anchToIndex(soldier.anchPoint.x, soldier.anchPoint.y)
		formation[index] = soldier.id
	end
	self.params.trialData.formation = formation

	GameState.save(GameData)
end


function TrialBattleLayer:startGame()
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

function TrialBattleLayer:showLeftTime()
	self.leftTime = globalCsv:getFieldValue("battleMaxTime")

	if self.leftTimeLabel then	
		self.leftTimeLabel:setString(self:getLeftTimeString(self.leftTime))
		self.leftTimeLabel:setVisible(true)
	else
		local countDownBg = display.newSprite(BattleRes .. "countdown_bg.png")
		countDownBg:anch(0.5,0.5):pos(200,display.height - 45):addTo(self)
		local bgSize = countDownBg:getContentSize()

		self.leftTimeLabel = ui.newTTFLabelWithStroke({text = "00:00", size = 26 })
		self.leftTimeLabel:anch(0, 0.5):pos(90, bgSize.height / 2):addTo(countDownBg)

		display.newSprite(BattleRes .. "hourglass.png")
			:anch(0, 0.5):pos(10, bgSize.height / 2):addTo(countDownBg)
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
			self.leftTimeLabel:setString("00:00")
			self:setTouchEnabled(false)
			sharedScheduler:unscheduleScriptEntry(self.battleScheduleHandler)

			local joinHeros = {}
			local soldiers = self.params.soldiers
			for _,soldier in ipairs(soldiers) do
				table.insert(joinHeros,{ id = soldier.id })
			end

			local endGameRequest = {
				roleId = game.role.id,
				carbonId = self.carbonInfo.id,
				starNum = event.starNum,
				joinHeros = joinHeros,
			}

			local bin = pb.encode("BattleEndResult", endGameRequest)
			game:rpcRequest({
				requestCode = actionCodes.TrialBattleEndRequest,
				requestData = bin,
				responseCode = actionCodes.TrialBattleEndRequest,
				callback = function(event)
					sharedScheduler:setTimeScale(1) 

					local msg = pb.decode("BattleEndResult", event.data)
					local battleEndLayer = BattleEndLayer.new({ 
						battleType = BattleType.Trial, carbonId = msg.carbonId, starNum = msg.starNum, 
						dropItems = msg.dropItems or {},bgImg = self.bg:getTexture(), joinHeros = joinHeros,
					})
					display.getRunningScene():addChild(battleEndLayer:getLayer())
				end,
			})
		end
	end
	setLeftTime()
end

function TrialBattleLayer:getLeftTimeString(time)
	local minute = math.floor(time / 60)
	local second = time % 60
	return string.format("%02d:%02d", minute, second)
end

--战斗结束：
function TrialBattleLayer:endPhaseGame(event)
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

	local joinHeros = {}
	local soldiers = self.params.soldiers
	for _,soldier in ipairs(soldiers) do
		table.insert(joinHeros,{ id = soldier.id })
	end

	if self.currentStage > self.totalStage or event.starNum == 0 then
		local function sendGameEndRequest()
			-- 将战斗结果发往服务端
			local endGameRequest = {
				roleId = game.role.id,
				carbonId = self.carbonInfo.id,
				starNum = event.starNum,
				joinHeros = joinHeros,
			}

			local bin = pb.encode("BattleEndResult", endGameRequest)
			game:rpcRequest({
				requestCode = actionCodes.TrialBattleEndRequest,
				requestData = bin,
				responseCode = actionCodes.TrialBattleEndRequest,
				callback = function(event)
					bulletManager:dispose()
					armatureManager:dispose()

					local msg = pb.decode("BattleEndResult", event.data)

					local battleEndLayer = BattleEndLayer.new({ 
						battleType = BattleType.Trial, carbonId = msg.carbonId, starNum = msg.starNum,
						 dropItems = msg.dropItems or {}, exp = msg.exp,bgImg = self.bg:getTexture(),
						 joinHeros = joinHeros, roleExp = self.carbonInfo.health * globalCsv:getFieldValue("healthToExp")
					})
					display.getRunningScene():addChild(battleEndLayer:getLayer())
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
			self.curStageTips:anch(0.5,0.5):pos(display.cx+30, display.height - 35)

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
function TrialBattleLayer:onSoldierDead(event)
	local soldier = self.battleField[event.camp .. "SoldierMap"][event.anchKey]

	if not soldier then return end

	-- 最后一关BOSS, 掉落
	if self.currentStage == self.totalStage and event.camp == "right" then
		local leftNum = 0
		for anchKey, soldier in pairs(self.battleField.rightSoldierMap) do
			if soldier.hp > 0 then leftNum = leftNum + 1 end
		end

		local canDrop = (soldier.beBoss or (leftNum == 0)) and not self.hasDrop
		if canDrop then
			self.hasDrop = true

			local xBegin = soldier.position.x - (#self.dropItems -1) * 50
			-- 超出屏幕
			if xBegin + (#self.dropItems - 1) * 100 + 100 > display.width then
				xBegin = display.width - (#self.dropItems - 1) * 100 - 100
			end

			for index, item in ipairs(self.dropItems) do
				-- 箱子掉落
				local treasurebox, changed
				treasurebox = DGBtn:new(BattleRes, {"treasurebox.png"},
					{	
						touchScale = { 1.5, 1.5 },
						callback = function()
							if changed then return end

							local itemIcon
							if item.itemTypeId == ItemTypeId.Hero then
								local unitData = unitCsv:getUnitByType(item.itemId - 1000)
								local frameRes = string.format("frame_%d.png", unitData.stars)
								itemIcon = display.newSprite(GlobalRes .. frameRes)
								local frameSize = itemIcon:getContentSize()
								display.newSprite(GlobalRes .. "frame_bottom.png")
									:pos(frameSize.width / 2, frameSize.height / 2):addTo(itemIcon, -3)
								display.newSprite(unitData.headImage)
									:pos(frameSize.width / 2, frameSize.height / 2):addTo(itemIcon, -2) 
							elseif item.itemTypeId == ItemTypeId.HeroFragment then
								local unitData = unitCsv:getUnitByType(item.itemId - 2000)
								local frameRes = string.format("frame_%d.png", unitData.stars)
								itemIcon = display.newSprite(GlobalRes .. frameRes)
								local frameSize = itemIcon:getContentSize()
								display.newSprite(GlobalRes .. "frame_bottom.png")
									:pos(frameSize.width / 2, frameSize.height / 2):addTo(itemIcon, -3)
								display.newSprite(unitData.headImage)
									:pos(frameSize.width / 2, frameSize.height / 2):addTo(itemIcon, -2)
								display.newSprite(HeroRes.."fragment_tag.png")
									:anch(0, 1):pos(65, 50):addTo(itemIcon)
							else
								local itemData = itemCsv:getItemById(item.itemId)
								local frameRes = itemData and string.format("item_%d.png", itemData.stars) or "item_1.png"
								itemIcon = display.newSprite(GlobalRes .. frameRes)
								local frameSize = itemIcon:getContentSize()
								display.newSprite(GlobalRes .. "frame_bottom.png"):pos(frameSize.width / 2, frameSize.height / 2)
									:addTo(itemIcon, -2)
								display.newSprite(itemData.icon)
									:pos(frameSize.width / 2, frameSize.height / 2):addTo(itemIcon, -1)
							end

							if itemIcon then
								local size = treasurebox:getLayer():getContentSize()
								itemIcon:scale(0.7):pos(size.width / 2, size.height / 2)
									:addTo(treasurebox:getLayer())
							end

							changed = true
						end
					})
				treasurebox:getLayer():anch(0.5, 0.5):hide()
					:pos(soldier.position.x, soldier.position.y):addTo(self, 99)

				local boxSize = treasurebox:getLayer():getContentSize()
				-- 光圈
				display.newSprite(BattleRes .. "treasurebox_light.png")
					:pos(boxSize.width / 2, boxSize.height / 2):addTo(treasurebox:getLayer(), -1)
					:runAction(CCRepeatForever:create(CCRotateBy:create(0.2, 20)))

				treasurebox:getLayer():runAction(transition.sequence{
					CCDelayTime:create(0.1),
					CCShow:create(),
					CCMoveTo:create(randomFloat(0.2, 0.3), ccp(xBegin + (index - 1) * 100, 220)),
					CCDelayTime:create(2.6),
					CCSpawn:createWithTwoActions(
						CCMoveTo:create(0.6, ccp(350,display.height - 45)),
						CCFadeOut:create(0.6)),
					CCRemoveSelf:create(),
					CCCallFunc:create(function()
						local num = tonumber(self.dropItemCount:getString())
						self.dropItemCount:setString(num + 1)
					end)
				})
			end
		end
	end

	self[event.camp .. "FormationPositions"][soldier.anchPoint.x][soldier.anchPoint.y].hero = nil
	if soldier:getState() == "skillAttack" then
		self:showSkillMask(false, soldier)
	end
	
	soldier.sprite:runAction(transition.sequence({
		CCFadeOut:create(1),
		CCCallFunc:create(function() soldier:dispose() end)
	}))	
end

function TrialBattleLayer:createBattleUI()
	TrialBattleLayer.super.showBattleUI(self)

	-- 当前阶段
	self.curStageTips = ui.newTTFLabelWithStroke({ text = self.currentStage .. "/" .. self.totalStage,
		 size = 24 ,strokeColor= uihelper.hex2rgb("#242424"), strokeSize =2, font = ChineseFont })
	self.curStageTips:anch(0.5,0.5):pos(display.cx+30, display.height - 35)
		:addTo(self)

	local countDownBg = display.newSprite(BattleRes .. "countdown_bg.png")
	countDownBg:anch(0.5,0.5):pos(380,display.height - 45):addTo(self)
	local bgSize = countDownBg:getContentSize()

	self.dropItemCount = ui.newTTFLabel({align=ui.TEXT_ALIGN_RIGHT,text = "0", size = 20 })
	self.dropItemCount:anch(1, 0.5):pos(bgSize.width-20, bgSize.height / 2):addTo(countDownBg)

	display.newSprite(BattleRes .. "treasurebox.png")
		:anch(0, 0.5):pos(0, bgSize.height / 2):addTo(countDownBg)
end

-- 隐藏战斗显示的UI
function TrialBattleLayer:hideBattleUI()
	TrialBattleLayer.super.hideUI(self)
end

-- 得到当前副本给定阶段的所有敌人信息
-- @param carbonId 	副本ID
-- @param stage 	阶段
-- @return 	敌人的详细信息
function TrialBattleLayer:getCarbonEnemys(stage)
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

			enemy.skillLevels = self:initSkillLevel(unitData, data.skillLevel, data.evolutionCount)
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

function TrialBattleLayer:initSkillLevel(unitData, levelLimit, evolutionCount)
	local skillLevels = {}

	if unitData.talentSkillId > 0 then
		local skillData = skillCsv:getSkillById(unitData.talentSkillId)
		print(levelLimit, skillData.levelLimit)
		skillLevels[tostring(unitData.talentSkillId)] = 
			levelLimit > skillData.levelLimit and skillData.levelLimit or levelLimit
	end

	if evolutionCount >= globalCsv:getFieldValue("passiveSkillLevel1") and
		evolutionCount < globalCsv:getFieldValue("passiveSkillLevel2") then
		if unitData.passiveSkill1 > 0 then
			local skillData = skillPassiveCsv:getPassiveSkillById(unitData.passiveSkill1)
			skillLevels[tostring(10000 + unitData.passiveSkill1)] = 
				levelLimit > skillData.levelLimit and skillData.levelLimit or levelLimit
		end
	elseif evolutionCount >= globalCsv:getFieldValue("passiveSkillLevel2") and
		evolutionCount < globalCsv:getFieldValue("passiveSkillLevel3") then
		if unitData.passiveSkill1 > 0 then
			local skillData = skillPassiveCsv:getPassiveSkillById(unitData.passiveSkill1)
			skillLevels[tostring(10000 + unitData.passiveSkill1)] = 
				levelLimit > skillData.levelLimit and skillData.levelLimit or levelLimit
		end
		if unitData.passiveSkill2 > 0 then
			local skillData = skillPassiveCsv:getPassiveSkillById(unitData.passiveSkill2)
			skillLevels[tostring(10000 + unitData.passiveSkill2)] = 
				levelLimit > skillData.levelLimit and skillData.levelLimit or levelLimit
		end
	elseif evolutionCount >= globalCsv:getFieldValue("passiveSkillLevel3") then
		if unitData.passiveSkill1 > 0 then
			local skillData = skillPassiveCsv:getPassiveSkillById(unitData.passiveSkill1)
			skillLevels[tostring(10000 + unitData.passiveSkill1)] = 
				levelLimit > skillData.levelLimit and skillData.levelLimit or levelLimit
		end
		if unitData.passiveSkill2 > 0 then
			local skillData = skillPassiveCsv:getPassiveSkillById(unitData.passiveSkill2)
			skillLevels[tostring(10000 + unitData.passiveSkill2)] = 
				levelLimit > skillData.levelLimit and skillData.levelLimit or levelLimit
		end
		if unitData.passiveSkill3 > 0 then
			local skillData = skillPassiveCsv:getPassiveSkillById(unitData.passiveSkill3)
			skillLevels[tostring(10000 + unitData.passiveSkill3)] = 
				levelLimit > skillData.levelLimit and skillData.levelLimit or levelLimit
		end
	end

	return skillLevels
end

function TrialBattleLayer:onExit()
	if self.battleScheduleHandler then
		sharedScheduler:unscheduleScriptEntry(self.battleScheduleHandler)
		self.battleScheduleHandler = nil
	end
	game.role.leftMembers = 0
end

return TrialBattleLayer