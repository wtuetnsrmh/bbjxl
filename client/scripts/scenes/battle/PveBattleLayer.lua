local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"

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

local PveBattleLayer = class("PveBattleLayer", BaseBattleLayer)

function PveBattleLayer:ctor(params)
	self.params = params or {}
	PveBattleLayer.super.ctor(self, params)

	self.battleLogic = nil
	self.hasDrop = false

	-- 用于接收触摸事件
	self:setTouchEnabled(false)

	-- 如果是副本战斗, 初始化副本数据
	self:initCarbonData(params.carbonId, self.currentStage)

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
			images = { self.carbonInfo["backgroundPic" .. self.currentStage] },
			heroTypes = heroTypes,
			loadRoleHeros = true,
		}
	})
	battleLoadingLayer:getLayer():addTo(display:getRunningScene())
end

function PveBattleLayer:enterBattle()
	self.bg = display.newSprite(self.carbonInfo["backgroundPic" .. self.currentStage])
	self.bg:pos(display.cx, display.cy):addTo(self, BattleConstants.zOrderConstants["background"])

	-- 没有场景对话或者已经完成了该副本
	if self.carbonInfo.hasPlot and game.role.carbonDataset[self.params.carbonId].status ~= 1 then
		self.currentPlots = plotTalkCsv:getPlotTalkByCarbon(self.params.carbonId, self.currentStage)
	end
	game.role.leftMembers = 0
	if self.currentPlots and #self.currentPlots > 0 then
		local plotLayer = BattlePlotLayer.new({ carbonId = self.params.carbonId, phase = self.currentStage,
			onComplete = function()
				self:initCommonUI(self.params)
				self:initBattleField()
				game.role.leftMembers = table.nums(self.battleField.leftSoldierMap)
			end 
		})
		plotLayer:addTo(self, BattleConstants.zOrderConstants["plot"])
	else
		self:initCommonUI(self.params)
		self:initBattleField()
		game.role.leftMembers = table.nums(self.battleField.leftSoldierMap)
	end
end

-- 初始化副本数据
function PveBattleLayer:initCarbonData(carbonId, stage)
	if not carbonId then return {} end

	self.carbonInfo = mapBattleCsv:getCarbonById(carbonId)
	if not self.carbonInfo or self.carbonInfo.battleTotalPhase < stage then return {} end

	self.totalStage = self.carbonInfo.battleTotalPhase

	self.carbonSceneCsv = require("csv.CarbonSceneCsv")
	
	self.carbonSceneCsv:load(self.carbonInfo.battleCsv)
end

-- 初始化战场
function PveBattleLayer:initBattleField(leftSoldiers, rightSoldiers)
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

	self.totalSoldier = nil
	
	self:initLeftField(leftSoldiers)
	self:initRightField(rightSoldiers)

	-- 非第一阵，且不用暂停
	if not self.heroBottomLayer then
		self.heroBottomLayer = BottomBarController.new({ battle = self })
		self.heroBottomLayer:anch(0.5, 0):pos(display.cx, 0):addTo(self, BattleConstants.zOrderConstants["bottomBar"])
	end

	-- self:bossAppear() 
end

function PveBattleLayer:initLeftField(soldiers)
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

-- 右边战场的武将
function PveBattleLayer:initRightField(soldiers)
	local soldiers = self:getCarbonEnemys(self.currentStage)

	self:addBattleHeros(soldiers)
end

function PveBattleLayer:bossAppear()
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
	
					if game.role.pveFormation[2] then
						game:addGuideNode({rect = CCRectMake(display.cx - 120, display.cy - 110, 130, 168), checkContain = false,
							action = {from = ccp(display.cx - 56,display.cy - 84), to = ccp(display.cx - 260,display.cy - 8)},
							guideIds = {1028}
						})
					end
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

function PveBattleLayer:savePveFormation()
	game.role.pveFormation = {}
	
	for anchKey, soldier in pairs(self.battleField.leftSoldierMap) do
		local index = BattleConstants:anchToIndex(soldier.anchPoint.x, soldier.anchPoint.y)
		game.role.pveFormation[index] = soldier.id
	end
	dump(game.role.pveFormation)
	game.role:updatePveFormation()
end

function PveBattleLayer:startGame()
	if self.currentStage == 1 then
		local endGameRequest = {
			roleId = game.role.id,
			carbonId = self.carbonInfo.carbonId,
			starNum = 1,
		}

		self.dropItems = {}
		local bin = pb.encode("BattleEndResult", endGameRequest)
		--@remark 防止双击两次按钮，发两次请求，导致宝箱与结算面板结果不一致
		game:sendData(actionCodes.CarbonKillBossRequest, bin, #bin)
		showMaskLayer()
		game:addEventListener(actionModules[actionCodes.CarbonKillBossResponse], function(event)
			local data = pb.decode("BattleEndResult", event.data)
			hideMaskLayer()
			for index, item in ipairs(data.dropItems) do
				table.insert(self.dropItems, {
					itemId = item.itemId,
					itemTypeId = item.itemTypeId,
					num = item.num,
				})
			end

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
			return "__REMOVE__"
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

function PveBattleLayer:showLeftTime()
	self.leftTime = globalCsv:getFieldValue("battleMaxTime")

	if self.leftTimeLabel then	
		self.leftTimeLabel:setString(self:getLeftTimeString(self.leftTime))
		self.leftTimeLabel:setVisible(true)
	else
		local countDownBg = display.newSprite(BattleRes .. "countdown_bg.png")
		countDownBg:anch(0.5,0.5):pos(200,display.height - 45):addTo(self)
		local bgSize = countDownBg:getContentSize()

		self.leftTimeLabel = ui.newTTFLabel({align=ui.TEXT_ALIGN_RIGHT,text = "00:00", size = 20 })
		self.leftTimeLabel:anch(1, 0.5):pos(bgSize.width-10, bgSize.height / 2):addTo(countDownBg)

		display.newSprite(BattleRes .. "hourglass.png")
			:anch(0, 0.5):pos(0, bgSize.height / 2):addTo(countDownBg)
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

			local endGameRequest = {
				roleId = game.role.id,
				carbonId = self.carbonInfo.carbonId,
				starNum = 0,
			}

			local bin = pb.encode("BattleEndResult", endGameRequest)
			game:rpcRequest({
				requestCode = actionCodes.CarbonEndGameRequest,
				requestData = bin,
				responseCode = actionCodes.CarbonEndGameResponse,
				callback = function(event)
					sharedScheduler:setTimeScale(1) 
					local msg = pb.decode("BattleEndResult", event.data)
					local battleEndLayer = BattleEndLayer.new({ 
						battleType = BattleType.PvE, carbonId = msg.carbonId, starNum = msg.starNum, exp = msg.exp,
						money = msg.money, dropItems = msg.dropItems or {}, openNewCarbon = msg.openNewCarbon or 0,
						assistInfo = msg.assistInfo, origLevel = msg.origLevel,bgImg = self.bg:getTexture()
					})
					display.getRunningScene():addChild(battleEndLayer:getLayer())
				end,
			})
		end
	end
	setLeftTime()
end

function PveBattleLayer:getLeftTimeString(time)
	local minute = math.floor(time / 60)
	local second = time % 60
	return string.format("%02d:%02d", minute, second)
end

function PveBattleLayer:judgestOpenNewCarbon(newCarbonId)
	if newCarbonId == 0 then return end
	local mapId = math.floor(newCarbonId/100)
	local key
	local infoData = mapInfoCsv:getMapById(mapId)
	if mapId < 200 then
		key =100
		elseif mapId >200 and mapId <300 then
			key = 200
			elseif mapId > 300 then
				key = 300
	end
	game.role.currentLastOpenCarbonIds = game.role.currentLastOpenCarbonIds or {}
	if game.role.currentLastOpenCarbonIds[key] then
		if game.role.currentLastOpenCarbonIds[key] ~= mapId then
			game.role.currentLastOpenCarbonIds[key] = mapId
			local mapData = mapInfoCsv:getMapById(mapId)
			return string.format("恭喜解锁第%d章，%s",mapId%100,mapData.name)
		end
	else
		game.role.currentLastOpenCarbonIds[key] = mapId
		local mapData = mapInfoCsv:getMapById(mapId)
		return string.format("恭喜解锁第%d章，%s",mapId%100,mapData.name)
	end
	return nil
end

function PveBattleLayer:endPhaseGame(event)
	self:setTouchEnabled(false)
	if self.battleScheduleHandler then
		sharedScheduler:unscheduleScriptEntry(self.battleScheduleHandler)
		self.battleScheduleHandler = nil
	end

	self.effectLayer0:removeAllChildren()
	self.effectLayer1:removeAllChildren()
	self.currentStage = self.currentStage + 1

	if self.leftTimeLabel then
		self.leftTimeLabel:stopAllActions()
	end

	-- local camp="right"
	-- local col, row = BattleConstants:indexToAnch(2)
	-- local soldier=self.battleField.leftSoldierMap[camp..col..row]
	-- print("math.floor(soldier.hp*100/soldier.maxHp)==",math.floor(soldier.hp*100/soldier.maxHp))

	
	if self.currentStage > self.totalStage or event.starNum == 0 then
		local function sendGameEndRequest()
			-- 将战斗结果发往服务端
			local endGameRequest = {
				roleId = game.role.id,
				carbonId = self.carbonInfo.carbonId,
				starNum = event.starNum,
			}

			local bin = pb.encode("BattleEndResult", endGameRequest)
			game:rpcRequest({
				requestCode = actionCodes.CarbonEndGameRequest,
				requestData = bin,
				responseCode = actionCodes.CarbonEndGameResponse,
				callback = function(event)
					bulletManager:dispose()
					armatureManager:dispose()

					local msg = pb.decode("BattleEndResult", event.data)
					local unlockTip = self:judgestOpenNewCarbon(msg.openNewCarbon)
					if unlockTip then
						DGMsgBox.new({text = unlockTip, type = 1})
					end
					
					local battleEndLayer = BattleEndLayer.new({ 
						battleType = BattleType.PvE, carbonId = msg.carbonId, starNum = msg.starNum, exp = msg.exp,
						money = msg.money, dropItems = msg.dropItems or {}, openNewCarbon = msg.openNewCarbon or 0,
						origLevel = msg.origLevel,bgImg = self.bg:getTexture(), roleExp = self.carbonInfo.consumeValue * globalCsv:getFieldValue("healthToExp")
					})
					display.getRunningScene():addChild(battleEndLayer:getLayer())
					if msg.starNum > 0 then
						game:dispatchEvent({name = "battleWin" })
					end
				end,
			})
		end

		self:dispatchEvent({ name = "battleEnd" })
		self.battleStatus = 2

		self:runAction(transition.sequence({
			CCDelayTime:create(2.5),
			CCCallFunc:create(function()
				sharedScheduler:setTimeScale(1) 
				-- 只有胜利了才有结束对话
				-- 没有场景对话或者已经完成了该副本
				if game.role.carbonDataset[self.carbonInfo.carbonId].status ~= 1 then
					self.currentPlots = plotTalkCsv:getPlotTalkByCarbon(self.carbonInfo.carbonId, 4)
				end
				if event.starNum > 0 and self.currentPlots and #self.currentPlots > 0 then
					local plotLayer = BattlePlotLayer.new({ carbonId = self.carbonInfo.carbonId,
						phase = 4, onComplete = function() sendGameEndRequest() end })
					plotLayer:addTo(self, BattleConstants.zOrderConstants["plot"])
				else
					sendGameEndRequest()
				end
			end)
		}))
	else
		local aliveSoldiers = {}

		-- 下一阵
		local function nextPhaseBattle()
			
			if self.currentStage > self.totalStage then return end

			-- 移除上场的背景资源
			if self.bg then self.bg:removeSelf() end
			display.removeSpriteFrameByImageName(self.carbonInfo["backgroundPic" .. (self.currentStage - 1)])	
			
			self.bg = display.newSprite(self.carbonInfo["backgroundPic" .. self.currentStage])
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
			self.leftTimeLabel:setString(self:getLeftTimeString(globalCsv:getFieldValue("battleMaxTime")))

			self:setTouchEnabled(true)
		end

		-- 呐喊音效
		-- game:playMusic(23)
		self:dispatchEvent({ name = "battleEnd" })

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
							CCTexture2D:PVRImagesHavePremultipliedAlpha(false)

							if game.role.carbonDataset[self.carbonInfo.carbonId].status ~= 1 then
								self.currentPlots = plotTalkCsv:getPlotTalkByCarbon(self.carbonInfo.carbonId, self.currentStage)
							end
							if self.currentPlots and #self.currentPlots > 0 then
								local plotLayer = BattlePlotLayer.new({ carbonId = self.carbonInfo.carbonId,
									phase = self.currentStage, onComplete = function() nextPhaseBattle() end })
								plotLayer:addTo(self, BattleConstants.zOrderConstants["plot"])
							else
								nextPhaseBattle()
							end
						else
							local function boneLoaded(percent)
								if percent < 1 then return end

								CCTexture2D:PVRImagesHavePremultipliedAlpha(false)
								
								if game.role.carbonDataset[self.carbonInfo.carbonId].status ~= 1 then
									self.currentPlots = plotTalkCsv:getPlotTalkByCarbon(self.carbonInfo.carbonId, self.currentStage)
								end

								if self.currentPlots and #self.currentPlots > 0 then
									local plotLayer = BattlePlotLayer.new({ carbonId = self.carbonInfo.carbonId,
										phase = self.currentStage, onComplete = function() nextPhaseBattle() end })
									plotLayer:addTo(self, BattleConstants.zOrderConstants["plot"])
								else
									nextPhaseBattle()
								end
							end

							for type, _ in pairs(heroTypes) do
								armatureManager:asyncLoad(type, boneLoaded)
							end		
						end
					end
				end),
			}))
		end
		-- 右侧士兵
		-- 应该全部死亡
	end
end

-- 战场武将挂掉
function PveBattleLayer:onSoldierDead(event)
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
				local function openBox()
					if changed then return end

					local itemIcon
					itemIcon = ItemIcon.new({
						itemId = item.itemId,
						parent = treasurebox:getLayer(),
						
					}):getLayer()
					if item.itemTypeId == ItemTypeId.HeroFragment then
						itemIcon:anch(0.5,0.5)
					end

					if itemIcon then
						local size = treasurebox:getLayer():getContentSize()
						itemIcon:scale(0.7):pos(size.width / 2, size.height / 2)
							:addTo(treasurebox:getLayer())
					end

					changed = true
				end
				treasurebox = DGBtn:new(BattleRes, {"treasurebox.png"},
					{	
						touchScale = { 1.5, 1.5 },
						callback = function()
							openBox()
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
					CCCallFunc:create(function()
						--打开所有的箱子
							openBox()
						end),
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

function PveBattleLayer:createBattleUI()
	PveBattleLayer.super.showBattleUI(self)

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
function PveBattleLayer:hideBattleUI()
	PveBattleLayer.super.hideUI(self)
end

function PveBattleLayer:initSkillLevel(unitData, levelLimit, evolutionCount)
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

-- 得到当前副本给定阶段的所有敌人信息
-- @param carbonId 	副本ID
-- @param stage 	阶段
-- @return 	敌人的详细信息
function PveBattleLayer:getCarbonEnemys(stage)
	local enemys = {}
	if self.carbonSceneCsv:getStageSceneData(stage) == nil then
		return enemys
	end
	for id, data in pairs(self.carbonSceneCsv:getStageSceneData(stage)) do
		local unitData = unitCsv:getUnitByType(data.heroType)
		local heroProfessionInfo = heroProfessionCsv:getDataByProfession(unitData and unitData.profession or 0)
		if heroProfessionInfo then
			local Hero = require("datamodel.Hero")
			local attrValues = Hero.sGetBaseAttrValues(data.heroType, self.carbonInfo.battleLevel, data.evolutionCount%100)

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

			enemy.level = self.carbonInfo.battleLevel
			enemy.evolutionCount = data.evolutionCount

			-- 武将技能
			local unitData = unitCsv:getUnitByType(enemy.type)
			enemy.skillLevels = self:initSkillLevel(unitData, data.skillLevel, data.evolutionCount)

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

function PveBattleLayer:onExit()
	if self.battleScheduleHandler then
		sharedScheduler:unscheduleScriptEntry(self.battleScheduleHandler)
		self.battleScheduleHandler = nil
	end
	game.role.leftMembers = 0
end

return PveBattleLayer