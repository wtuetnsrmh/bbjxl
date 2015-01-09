local SpriteCamp = import(".SpriteCamp")
local SpriteSoldier = import(".SpriteSoldier")
local BattlePlotLayer = import(".BattlePlotLayer")
local ControlLayer = import(".ControlLayer")
local BaseBattleLayer = import(".BaseBattleLayer")
local BottomBarController = import(".BottomBarController")
local BattleEndLayer = import(".BattleEndNewLayer")
local PvpBestRankLayer = import(".PvpBestRankLayer")

local BgRes = "resource/bg/"

local DGBtn = require("uicontrol.DGBtn")

local sharedScheduler = CCDirector:sharedDirector():getScheduler()

local PvpBattleLayer = class("PvpBattleLayer", BaseBattleLayer)

function PvpBattleLayer:ctor(params)
	params = params or {}

	PvpBattleLayer.super.ctor(self, params)

	self.opponentRoleId = params.opponentRoleId

	self.rightHeros = params.rightHeros
	self.rightPassiveSkills = params.rightPassiveSkills or {}
	self.rightBeauties = params.rightBeauties or {}

	self.battleLogic = nil

	-- 用于接收触摸事件
	self:setTouchEnabled(false)

	local heroTypes = {}
	for _, hero in pairs(self.rightHeros) do
		if hero.type > 0 then heroTypes[hero.type] = true end
	end

	-- loading ui
	local battleLoadingLayer
	battleLoadingLayer = BattleLoadingLayer.new({ priority = -128,
		callback = function()
			CCTexture2D:PVRImagesHavePremultipliedAlpha(false)
			
			battleLoadingLayer:getLayer():removeSelf()

			self.bg = display.newSprite(BgRes .. "pvp.jpg")
			self.bg:pos(display.cx, display.cy):addTo(self)

			self:initCommonUI(params)
			self:initBattleField()
			game.role.leftMembers = 0
			game.role.leftMembers = table.nums(self.battleField.leftSoldierMap)
		end,
		loadingInfo = {
			images = { BgRes .. "pvp.jpg" },
			heroTypes = heroTypes,
			loadRoleHeros = true,
		}
	})
	battleLoadingLayer:getLayer():addTo(display:getRunningScene())
end

-- 初始化战场
function PvpBattleLayer:initBattleField()
	local passiveSkills, beauties = game.role:getFightBeautySkills()

	self.leftCamp = SpriteCamp.new({ camp = "left", passiveSkills = passiveSkills, beauties = beauties})
	self.rightCamp = SpriteCamp.new({ camp = "right", battleType = BattleType.PvP, 
		passiveSkills = self.rightPassiveSkills, beauties = self.rightBeauties })
	
	self:refreshAngrySlot(
		{ angryUnitNum = self.leftCamp.angryUnitNum, angryAccumulateTime = self.leftCamp.angryAccumulateTime })

	self.battleField = require("logical.battle.BattleField").new({ leftCamp = self.leftCamp, rightCamp = self.rightCamp })

	self:initLeftField()
	self:initRightField()

	self.heroBottomLayer = BottomBarController.new({ battle = self })
	self.heroBottomLayer:anch(0.5, 0):pos(display.cx, 0):addTo(self, BattleConstants.zOrderConstants["bottomBar"])
end

function PvpBattleLayer:initLeftField()
	-- 左边战场的武将
	local soldiers = game.role:getSelfFormationHeros()
	for _, soldier in ipairs(soldiers) do
		local col, row = BattleConstants:indexToAnch(soldier.index)
		soldier.anchPointX, soldier.anchPointY = col, row
	end

	self:addBattleHeros(soldiers)
end

function PvpBattleLayer:initRightField()
	local soldiers = {}

	-- 左边战场的武将
	for _, soldier in ipairs(self.rightHeros) do
		local col, row = BattleConstants:indexToAnch(soldier.index, "right")
		soldier.camp = "right"
		soldier.anchPointX, soldier.anchPointY = col, row

		table.insert(soldiers, soldier)
	end

	self:addBattleHeros(soldiers)
end

function PvpBattleLayer:startGame()
	local tempData = { roleId = game.role.id}
	local bin = pb.encode("SimpleEvent", tempData)
	game:sendData(actionCodes.PvpBattleEnterRequest, bin)
	loadingShow()
	game:addEventListener(actionModules[actionCodes.PvpBattleEnterResponse], function(event)
		loadingHide()
		
		self:setTouchEnabled(true)

		self:hideUI()
		self:showBattleUI()
		self:showLeftTime()

		-- 阵型保存
		self:savePveFormation()

		game:playMusic(6)

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

function PvpBattleLayer:getLeftTimeString(time)
	local minute = math.floor(time / 60)
	local second = time % 60
	return string.format("%02d:%02d", minute, second)
end

function PvpBattleLayer:showLeftTime()
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

			self:endGame({starNum = 0})	
		end
	end
	setLeftTime()
end

function PvpBattleLayer:endGame(event)
	if self.battleScheduleHandler then
		sharedScheduler:unscheduleScriptEntry(self.battleScheduleHandler)
		self.battleScheduleHandler = nil
	end
	sharedScheduler:setTimeScale(1)

	if self.leftTimeLabel then
		self.leftTimeLabel:stopAllActions()
	end

	self:dispatchEvent({ name = "battleEnd" })
	self.battleStatus = 2

	showMaskLayer()
	self:runAction(transition.sequence{
		CCDelayTime:create(1),
		CCCallFunc:create(function()
			hideMaskLayer()
			
			-- 将战斗结果发往服务端
			local endGameRequest = { 
				roleId = game.role.id, 
				opponentRoleId = self.opponentRoleId, 
				starNum = event.starNum, 
			}
			local bin = pb.encode("PvpBattleEndResult",endGameRequest)

			game:rpcRequest({
				requestCode = actionCodes.PvpEndGameNotify,
				requestData = bin,
				responseCode = actionCodes.PvpEndGameResponse,
				callback = function(event)
			    	bulletManager:dispose()
					armatureManager:dispose()
					
			    	local msg = pb.decode("PvpBattleEndResult", event.data)

			    	local battleEndLayer = BattleEndLayer.new({ battleType = BattleType.PvP, starNum = msg.starNum, exp = msg.exp,
			    		money = msg.money, zhangong = msg.zhangong, dropItems = {}, origLevel = msg.origLevel,bgImg = self.bg:getTexture() })
					display.getRunningScene():addChild(battleEndLayer:getLayer())

					if msg.bestRank > 0 then
						local layer = PvpBestRankLayer.new({oldBestRank = msg.oldBestRank, bestRank = msg.bestRank, yuanbao = msg.yuanbao}):getLayer()
						layer:addTo(display.getRunningScene())
					end
				end,
			})
		end)
	})
end

-- 战场武将挂掉
function PvpBattleLayer:onSoldierDead(event)
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

function PvpBattleLayer:onCleanup()
	game:removeAllEventListenersForEvent(actionModules[actionCodes.PvpEndGameResponse])
	if self.battleScheduleHandler then
		sharedScheduler:unscheduleScriptEntry(self.battleScheduleHandler)
		self.battleScheduleHandler = nil
	end
end

return PvpBattleLayer
