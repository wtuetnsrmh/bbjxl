HomeRes = "resource/ui_rc/home/"
FontRes = "resource/ui_rc/font/"
GlobalRes = "resource/ui_rc/global/"
GiftRes = "resource/ui_rc/gift/"
ParticleRes = "resource/ui_rc/particle/"
local CarbonRes = "resource/ui_rc/carbon/"
local ChatRes = "resource/ui_rc/chat/"
local AssignRes = "resource/ui_rc/assign/"

local scheduler = require("framework.scheduler")
local HeroChooseLayer = import(".hero.HeroChooseLayer")
local HeroMainLayer = import(".hero.HeroMainLayer")
local ItemMainLayer = import(".ItemMainLayer")
local BeautyListLayer = import(".beauty.BeautyListLayer")
local TechHomeLayer = import(".tech.TechHomeLayer")
local HeroStarLayer = import(".HeroStarLayer")
local EmailLayer = import(".EmailLayer")
local ShopMainLayer = import(".shop.ShopMainLayer")
local ReChargeLayer = import(".shop.ReChargeLayer")
local CurMonthAwardLayer = import(".assign.CurMonthAwardLayer")
local DailyTaskLayer = import(".DailyTaskLayer")
local ActiveMainLayer = import("..activity.ActiveMainLayer")
local IntensifyLayer = import(".hero.IntensifyLayer")
local HeroEvolutionLayer = import(".hero.HeroEvolutionLayer")
local EquipMainLayer = import(".equip.EquipMainLayer")
local StoreMainLayer = import(".StoreMainLayer")
local ReChargeLayer = import(".shop.ReChargeLayer")
local RankMainLayer = import(".rank.RankMainLayer")
local FirstRechargeLayer=import("..activity.FirstRechargeLayer")

GuideTipsLayer = import("..GuideTipsLayer")
GuidePlotLayer = import("..GuidePlotLayer")
ConfirmDialog = import("..ConfirmDialog")
BattleLoadingLayer = import("..BattleLoadingLayer")

import(".hero.Components")

local NewMainLayer = class("NewMainLayer", function()
	return display.newLayer()
end)

function NewMainLayer.addGmListener(gm_cmd)
	if gm_cmd == "employ" then
		game:addEventListener(actionModules[actionCodes.BeautyEmployResponse], function(event)
			local beauty = pb.decode("BeautyDetail", event.data)
			local newBeauty = require("datamodel.Beauty").new(beauty)
			game.role.beauties[beauty.beautyId] = newBeauty	
		end)
	elseif gm_cmd == "wake" then
		game:addEventListener(actionModules[actionCodes.HeroWakeLevelUpResponse], function(event)
			local msg = pb.decode("HeroActionResponse", event.data)
	    	for _, hero in ipairs(msg.heros) do
	    		if game.role.heros[hero.id] then
	    			game.role.heros[hero.id].wakeLevel = hero.wakeLevel
	    		end
	    	end
	    end)
	elseif gm_cmd == "evol" then
		game:addEventListener(actionModules[actionCodes.HeroEvolutionResponse], function(event)
			local msg = pb.decode("HeroActionResponse", event.data)
			for _, hero in ipairs(msg.heros) do
    			if game.role.heros[hero.id] then
    				game.role.heros[hero.id].evolutionCount = hero.evolutionCount
    			end
    		end
		end)
	end
end

function NewMainLayer:ctor(params)
	self.offset = 315
	self.expansion = true
	self.params = params or {}
	self.roleInfo = roleInfoCsv:getDataByLevel(game.role.level)

	self.priority = -129

	self.hasInit = false
	-- game.role.guideStep = 1000
	local guideCsvData = guideCsv:getStepStartGuide(game.role.guideStep)
	print(guideCsvData, game.role.guideStep)
	if guideCsvData then
		game:activeGuide(guideCsvData.guideId)
	end
	self:createKeypadLayer()

	
end

function NewMainLayer:createKeypadLayer()
	-- avoid unmeant back
	self:performWithDelay(function()
		-- keypad layer, for android
		local layer = display.newLayer()
		layer:addKeypadEventListener(function(event)
			if event == "back" then game:exit() end
		end)
		self:addChild(layer)

		layer:setKeypadEnabled(true)
		self.keyPadLayer = layer
	end, 0.1)
end

function NewMainLayer:setKeypadLayerEnable(enable)
	self.keyPadLayer:setKeypadEnabled(enable)
end

function NewMainLayer:removeKeypadLyaer()
	self.keyPadLayer:removeFromParent()
	self.keyPadLayer = nil
end

function NewMainLayer:onEnter()	
	
end

function NewMainLayer:onEnterTransitionFinish()
	display.addSpriteFramesWithFile(HomeRes.."homePics.plist", HomeRes.."homePics.png")

	self:initHomeUI()
	self:checkGuide()
end

function NewMainLayer:initHomeUI()
	game.loadWorldMapflag=game.loadWorldMapflag or true
	if game.loadWorldMapflag then
		local carbonWorldTexture1=sharedTextureCache:addImage(CarbonRes.."worldMap1.jpg")
		-- local carbonWorldTexture2=sharedTextureCache:addImage(CarbonRes.."worldMap2.jpg")--预留功能
		carbonWorldTexture1:retain()
		-- carbonWorldTexture2:retain()
		game.loadWorldMapflag=false
	end
	

	if self.hasInit then return end
	self.hasInit = true

	local x = game.backX or display.cx + self.offset
	self.backBg = display.newSprite(HomeRes .. "yuanjing.png")
	self.backBg:anch(0.5, 1):pos(x, display.height):addTo(self)

	self.middleBg = display.newSprite(HomeRes .. "zhongjing.png")
	x = game.middleX or display.cx + self.offset
	self.initOffsetY=10
	self.middleBg:anch(0.5, 1):pos(x, display.height-self.initOffsetY):addTo(self)

	self:initFrontLayer()

	-- fly birds
	local birdData = {
		[1] = { startXPos = 500, endXpos = 1000, delay = 0 }, 
		[2] = { startXPos = 400, endXpos = 1300, delay = 1 }, 
		[3] = { startXPos = 530, endXpos = 1100, delay = 2 }, 
		[4] = { startXPos = 550, endXpos = 1000, delay = 3 }, 
		[5] = { startXPos = 500, endXpos = 1400, delay = 3.5 },
	}
	local speed = 100 / 1.25
	local middleBgSize = self.middleBg:getContentSize()

	local birdAction
	birdAction = function(index)
		local startXPos = birdData[index].startXPos
		local endXpos = birdData[index].endXpos

		local bird = self:getIconActionSprite("bird", 12)
		bird:scale(0.3):pos(startXPos, 200):hide():addTo(self.middleBg)

		local spawnAction = CCArray:create()
		spawnAction:addObject(CCMoveTo:create((endXpos - startXPos) / speed, 
			ccp(endXpos, middleBgSize.height + 50)))
		if index < 5 then
			spawnAction:addObject(CCCallFunc:create(function() birdAction(index + 1) end))
		end

		bird:playAnimationForever(display.getAnimationCache("bird"))
		bird:runAction(transition.sequence{
			CCDelayTime:create(birdData[index].delay),
			CCShow:create(),
			CCSpawn:create(spawnAction),
			CCDelayTime:create(1),
			CCRemoveSelf:create(),
			CCCallFunc:create(function()
				if index == 5 then
					birdAction(1)
				end
			end)
		})
	end

	birdAction(1)

	x = game.frontX or display.cx + self.offset
	self.frontBg:anch(0.5, 0):pos(x, 0):addTo(self)

	self:setTouchEnabled(true)
	self:addTouchEventListener(function(event, x, y) return self:onTouch(event, x, y) end, false, self.priority)

	self:initRoleInfo()

	-- 加入gm命令输入框

	-- if not ServerConf[ServerIndex].public then
	-- 	local commandInputBox = ui.newEditBox({
	-- 		image = "resource/ui_rc/login_rc/" .. "server_cell.png",
	-- 		size = CCSize(200, 28),
	-- 		listener = function(event, editbox)
	-- 			if event == "began" then
	-- 			elseif event == "ended" then
	-- 			elseif event == "return" then
	-- 			elseif event == "changed" then
	-- 			end
	-- 		end
	-- 	})

	-- 	commandInputBox:setFontColor(display.COLOR_GREEN)	
	-- 	commandInputBox:setReturnType(kKeyboardReturnTypeSend)
	-- 	commandInputBox:anch(0, 0):pos(70, 110):addTo(self, 0)
	-- 	DGBtn:new(GlobalRes, {"xs_normal.png", "xs_selected.png"}, 
	-- 	{
	-- 		multiClick = true,
	-- 		text = { text = "send", size = 28, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
	-- 		callback = function()
	-- 			local msg = string.mySplit(commandInputBox:getText())
	-- 			local bin = pb.encode("GmEvent", { cmd = msg[1], pm1 = tonum(msg[2]), pm2 = tonum(msg[3]), pm3 = tonum(msg[4]) })
	-- 			game:sendData(actionCodes.GmSendRequest, bin, #bin)
	-- 			self:addGmListener(msg[1])
	-- 			game:addEventListener(actionModules[actionCodes.GmReceiveResponse], function(event)
	-- 				local msg = pb.decode("GmEvent", event.data)
	-- 				-- local tips = msg.cmd == "success" and "指令生效" or "指令错误"
	-- 				DGMsgBox.new({text = msg.cmd, type = 1})
	-- 			end)
	-- 		end,
	-- 	}):getLayer():anch(0, 0):pos(commandInputBox:getContentSize().width, 0):addTo(commandInputBox)
	-- 	commandInputBox:setVisible(false)
	-- 	commandInputBox:setTouchEnabled(false)

	-- 	DGBtn:new(GlobalRes, {"xs_normal.png", "xs_selected.png"}, 
	-- 	{
	-- 		text = { text = "GM", size = 28, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
	-- 		callback = function()
	-- 			local toShowCommand = not commandInputBox:isVisible()
	-- 			commandInputBox:setVisible(toShowCommand)
	-- 			commandInputBox:setTouchEnabled(toShowCommand)
	-- 		end,
	-- 	}):getLayer():anch(0, 0):pos(0, 110):addTo(self, 0)
	-- end

	--聊天
	self:createChatBtn()

	-- 水平按钮
	local horizontalBtns = {
		[1] = { res = {"#dailytask_normal.png", "#dailytask_selected.png"}, tag = 11,
			func = function()
				if self.roleInfo.dailyTaskOpen < 0 then
					DGMsgBox.new({text = string.format("玩家%d级开放每日任务", math.abs(self.roleInfo.dailyTaskOpen)), type = 1})
					return
				end 
				local layer = DailyTaskLayer.new({ parent = self, priority = self.priority - 10 })
				layer:getLayer():addTo(self, 100)
			end,
			notifyType = "dailyTask" , 
		},

		[2] = { res = {"#bag_normal.png", "#bag_selected.png"}, tag = 13,
			func = function() 
				local layer = ItemMainLayer.new({ parent = self, priority = self.priority - 10 })
				layer:getLayer():addTo(display.getRunningScene())
			end,
			notifyType = "" ,
		},

		[3] = { res = {"#equip_normal.png", "#equip_selected.png"}, tag = 16,
			func = function()
				local layer = EquipMainLayer.new({ parent = self, priority = self.priority - 10 })
				layer:getLayer():addTo(display.getRunningScene())
			end,
			notifyType = "composeEquipFragment",
		},

		[4] = { res = {"#hero_normal.png", "#hero_selected.png"}, tag = 15,
			func = function() 
				local layer = HeroMainLayer.new({ parent = self, priority = self.priority - 10, closemode = 1 })
				layer:getLayer():addTo(display.getRunningScene())
			end,
			notifyType = {"composeFragment", "heroList"} 
		},
	
		[5] = { res = {"#choose_normal.png", "#choose_selected.png"}, tag = 14,
			func = function()
				-- switchScene("heroChoose", {parent = self})
				local layer = HeroChooseLayer.new({parent = self, closemode = 1, priority = self.priority - 10})
				layer:getLayer():addTo(display.getRunningScene())
			end,
			notifyType = "chooseHero" 
		},
	}

	local xPos, yPos, xInterval = 60, 5, 100
	for index, btnData in ipairs(horizontalBtns) do
		local btn = DGBtn:new(nil, btnData.res,
			{	
				callback = btnData.func,
			})
		local btnSize = btn:getLayer():getContentSize()
		btn:getLayer():anch(0.5, 0):pos(display.width - xPos - index * xInterval - 5, yPos)
			:addTo(self, 0, btnData.tag)
		btnData.instance = btn

		game.role:addEventListener("notifyNewMessage", function(event)
			if (type(btnData.notifyType)=="table" and table.find(btnData.notifyType, event.type)) or event.type == btnData.notifyType then
				btn:getLayer():removeChildByTag(9999)
				if event.action == "add" then
					uihelper.newMsgTag(btn:getLayer())
				end
			end
		end)
	end

	-- 垂直按钮
	local verticalBtns = {
		-- [1] = { res = {"#dailytask_normal.png", "#dailytask_selected.png"}, tag = 101,
		-- 	func = function() 
		-- 		local layer = DailyTaskLayer.new({ parent = self, priority = self.priority - 10 })
		-- 		layer:getLayer():addTo(self, 100)
		-- 	end,
		-- 	notifyType = "dailyTask"
		-- },
	}

	local yInterval = 100
	for index, btnData in ipairs(verticalBtns) do
		local btn = DGBtn:new(nil, btnData.res,
			{	
				callback = btnData.func,
			})
		local btnSize = btn:getLayer():getContentSize()
		btn:getLayer():anch(0.5, 0):pos(display.width - xPos - 6, yPos + index * yInterval )
			:addTo(self, 0, btnData.tag)
		btnData.instance = btn

		game.role:addEventListener("notifyNewMessage", function(event)
			if (type(btnData.notifyType)=="table" and table.find(btnData.notifyType, event.type)) or event.type == btnData.notifyType then
				btn:getLayer():removeChildByTag(9999)
				if event.action == "add" then
					uihelper.newMsgTag(btn:getLayer())
				end
			end
		end)
	end

	-- 展开收缩控制按钮
	local controlBtn
	controlBtn = DGBtn:new(nil, {"#state_open.png", "#state_open_selected.png"},
		{	
			callback = function() 
				local time = 0.1
				if self.expansion then
					-- 收缩
					for index, btnData in ipairs(horizontalBtns) do
						btnData.instance:getLayer():runAction(transition.sequence({
							CCMoveTo:create(time, ccp(display.width - xPos, yPos)),
							CCHide:create(),
							CCCallFunc:create(function() btnData.instance:setEnable(false) end)
						}))
					end

					for index, btnData in ipairs(verticalBtns) do
						btnData.instance:getLayer():runAction(transition.sequence({
							CCMoveTo:create(time, ccp(display.width - xPos, yPos)),
							CCHide:create(),
							CCCallFunc:create(function() btnData.instance:setEnable(false) end)
						}))
					end

					self.expansion = false
					controlBtn:rotateBy(time, 90)
				else
					-- 展开
					for index, btnData in ipairs(horizontalBtns) do
						btnData.instance:getLayer():runAction(transition.sequence({
							CCShow:create(),
							CCMoveTo:create(time, ccp(display.width - xPos - index * xInterval - 5, yPos)),
							CCCallFunc:create(function() btnData.instance:setEnable(true) end)
						}))
					end

					for index, btnData in ipairs(verticalBtns) do
						btnData.instance:getLayer():runAction(transition.sequence({
							CCShow:create(),
							CCMoveTo:create(time, ccp(display.width - xPos - 6, yPos + index * yInterval)),
							CCCallFunc:create(function() btnData.instance:setEnable(true) end)
						}))
					end

					self.expansion = true
					controlBtn:rotateBy(time, -90)
				end
			end,
		}):getLayer()
	controlBtn:anch(0.5, 0.5):pos(display.width - xPos - 6, yPos + controlBtn:getContentSize().height/2):addTo(self)


	self:initRightTopBtns()

	self:autoPopupLayer(self.params)

	self:popNotice(self.params)

	game.role:updateNewMsgTag()
	self.newMsgUpdate = scheduler.scheduleGlobal(function()
		game.role:updateNewMsgTag() 
	end, 1)

	-- 创建角色第一次加载需要通知服务端记录日志
	if self.params.activesuccess then
		local bin = pb.encode("SimpleEvent", { roleId = game.role.id })
		game:sendData(actionCodes.RoleActiveSuccess, bin)	
	end

	--注册特殊副本开启事件
	self.specialStoreOpenedHandle = game.role:addEventListener("specialStoreOpened", function(event)
		self:refreshStoreBubble()
	end)
end

function NewMainLayer:createChatBtn()

	local chatBtn = DGBtn:new(ChatRes,{"chat_normal.png","chat_press.png"},
	{
		callback = function() 
			pushScene("chat",{})
		end

	})
	chatBtn:getLayer():anch(0,0):pos(5,10):addTo(self,1)
	
	local chatBg = display.newSprite(ChatRes.."g_talkbg.png"):anch(0,0)
		:pos(chatBtn:getLayer():getContentSize().width/2+5,20):addTo(self)

	self.chatTableView = DGScrollView:new({ 
		priority = self.priority - 1,
		size = CCSizeMake(259, 77), 
		divider = 1,
	})
	self.chatTableView:getLayer():pos(50, 0):addTo(chatBg)
	-- self.chatTableView:setEnable(false)

	self:refreshChat()

	self.updateChatHandler = game.role:addEventListener("updateChat", handler(self, self.refreshChat))
end

function NewMainLayer:refreshChat(event)
	if self.chatTableView then
		self.chatTableView:removeAll()
	end

	local curChatArray = {}
	if table.nums(game.role.chats) > 10 then
		local starIndex = table.nums(game.role.chats) - 10 + 1
		for i=starIndex,table.nums(game.role.chats) do
			table.insert(curChatArray,game.role.chats[i])
		end
	else
		curChatArray = game.role.chats
	end
	
	local totalHeight = 0
	for index,chat in ipairs(curChatArray) do
		local text = self:createChatCell(chat)
		totalHeight = totalHeight + text:getContentSize().height + 1
		text:anch(0, 0)
		-- row:setPositionY(row:getContentSize().height/2)
		self.chatTableView:addChild(text)
	end

	self.chatTableView:setOffset(totalHeight - 75)

end


function NewMainLayer:createChatCell(chat)
	-- local tempLable = ui.newTTFLabel({text = chat.player.name..":"..chat.content,size=18  })
	-- local rowNum = math.ceil((tempLable:getContentSize().width + 13.5) / 235)*23 --9为防止正好两行时再加一个字母计算有误  mac:字母为9 汉字 为18像素
	-- print("math.ceil(tempLable:getContentSize().width / 235)",math.ceil((tempLable:getContentSize().width + 10) / 235))
	-- local contentLabel = ui.newTTFRichLabel({text = "[color=FFFFFFFF][color=FFFFDA22]"..chat.player.name.."[/color]: "..chat.content.."[/color]",
	-- 	color = display.COLOR_WHITE, dimensions = CCSizeMake(235, rowNum),size=18  })

	-- local contentLabel = ui.newTTFLabel({text = chat.player.name..":"..chat.content,
	-- 	color = display.COLOR_WHITE, dimensions = CCSizeMake(235, 10),size=18  })
	-- print("rowNum",rowNum)

	local contentText
	if chat.chatType == 4 then
		contentText = chat.content
	else
		contentText = "[color=FFDA22]" .. chat.player.name .. ":[/color]"..chat.content
	end
	local contentLabel = DGRichLabel.new({ text = contentText, size = 18,  color=uihelper.hex2rgb("#ffffff"), width = 310})
		
	return contentLabel
end

function NewMainLayer:initRoleInfo()
	--头像背景
	local headbg = display.newSprite(HomeRes .. "head_cut.png")
	headbg:anch(0, 1):pos(15, display.height - 10):addTo(self)

	--总背景
	local infoBg = display.newSprite("#head_box.png")
	infoBg:anch(0, 1):pos(5, display.height - 5):addTo(self)

	local roleBtn = DGBtn:new(HomeRes, {"head_cut.png", "head_cut.png"},
	{	
		priority = self.priority + 1,
		callback = function()
			local endlayer = require("scenes.home.RoleContentInfoLayer")
			local showRewardLayer = endlayer.new({priority = self.priority - 10})
			display.getRunningScene():addChild(showRewardLayer:getLayer(),900)
		end,
	}):getLayer()
	roleBtn:size(infoBg:getContentSize()):anch(0, 0):pos(0, 0):addTo(headbg)

	--头像：
	local mainHero = game.role.heros[game.role.slots["1"].heroId]
	local heroData = unitCsv:getUnitByType(mainHero.type)

	local headIcon = getShaderNode({steRes = HomeRes.."head_cut.png",clipRes = heroData.headImage})
	headIcon:setPosition(ccp(48, 40 ))
	headbg:addChild(headIcon, 0, 5)

	self.slotsUpdateHandle = game.role:addEventListener("updateSlots", function(event)
		headbg:removeChildByTag(5)

		local mainHero = game.role.heros[game.role.slots["1"].heroId]
		local heroData = unitCsv:getUnitByType(mainHero.type)
		local headIcon = getShaderNode({steRes = HomeRes.."head_cut.png",clipRes = heroData.headImage})
		headIcon:setPosition(ccp(48, 40 ))
		headbg:addChild(headIcon, 0, 5)
	end)

	--vipbtn
	local xOffset = game.role.vipLevel >= 10 and 0 or 7
	local vipBtn = DGBtn:new(HomeRes, {"vip_img.png"},
	{	
		priority = self.priority,
		touchScale = {2.0, 1.5},
		callback = function()
			local rechageLayer = ReChargeLayer.new({ priority = self.priority - 10})
			rechageLayer:getLayer():addTo(display.getRunningScene())
		end,
	}):getLayer()
	vipBtn:anch(0, 1):pos(165 + xOffset, infoBg:getContentSize().height - 37):addTo(infoBg)

	local vipValue = ui.newBMFontLabel({ text = game.role.vipLevel, font = "resource/ui_rc/home/vip_lv.fnt" }):addTo(vipBtn)
	vipValue:scale(0.9):anch(0, 0.5):pos(vipBtn:getContentSize().width, vipBtn:getContentSize().height / 2)
	self.updateVipLevelHandler = game.role:addEventListener("updateVipLevel", function(event)
    	vipValue:setString(event.vipLevel)
    end)

	-- 玩家名
	--TODO:字体需要修改
	local nameLabel = ui.newTTFLabel({ text = game.role.name, size = 22, color=uihelper.hex2rgb("#4a3318"), font = ChineseFont })
		:anch(0, 0):pos(100, 8):addTo(infoBg)
	-- 等级
	local levelLabel = ui.newTTFLabel({ text = game.role.level, size = 20, color=uihelper.hex2rgb("#fac62d"), font = ChineseFont })
		:anch(0.5, 1):pos(125, infoBg:getContentSize().height - 38):addTo(infoBg)
	self.updateLevelHandler = game.role:addEventListener("updateLevel", function(event)
		levelLabel:setString(event.level) --等级：
		self.roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
		self:initFrontLayer()
		self:checkGuide()
	end)

	-- name update
	self.updateNameHandler = game.role:addEventListener("updateName", function(event)
								nameLabel:setString(event.rolename) 
							end)
	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority - 10})
	:anch(0, 1):pos(245, display.height):addTo(self)
end

function NewMainLayer:onTouch(event, x, y)
	if event == "began" then
		return self:onTouchBegan(x, y)
	elseif event == "moved" then
		self:onTouchMove(x, y)
	elseif event == "ended" then
		self:onTouchEnd(x, y)
	end
end

function NewMainLayer:onTouchBegan(x, y)
	if game:hasGuide() or self.drag then
		return false
	end
	
	self.drag = {
		beganTime = os.clock(),
		beginX = x,
		frontX = self.frontBg:getPositionX(),
		middleX = self.middleBg:getPositionX(),
		backX = self.backBg:getPositionX(),
	}	

	return true
end

function NewMainLayer:onTouchMove(x, y)
	if self.drag then
		self:moveOffset(x - self.drag.beginX)
	end
end

function NewMainLayer:onTouchEnd(x, y)
	self.drag = nil
end

function NewMainLayer:moveOffset(xOffset, animation)
	local frontX = self.drag.frontX + xOffset
	if frontX > self.frontSize.width / 2 then
		-- 左侧上限
		frontX = self.frontSize.width / 2
	elseif frontX <= display.width - self.frontSize.width / 2 then
		-- 右侧上限
		frontX = display.width - self.frontSize.width / 2
	end
	if animation then
		self.frontBg:moveTo(1, frontX, 0)
	else
		self.frontBg:pos(frontX, 0)
	end
	game.frontX = frontX

	if frontX < self.frontSize.width / 2 and frontX > display.width - self.frontSize.width / 2 then
		local middleX = self.drag.middleX + math.floor(xOffset * 0.7)
		if middleX > self.frontSize.width / 2 then
			middleX = self.frontSize.width / 2
		elseif middleX <= display.width - self.frontSize.width / 2 then
			middleX = display.width - self.frontSize.width / 2
		end
		self.middleBg:pos(middleX, 0)
		if animation then
			self.middleBg:moveTo(1, middleX, display.height-self.initOffsetY)
		else
			self.middleBg:pos(middleX, display.height-self.initOffsetY)
		end
		game.middleX = middleX

		local backX = self.drag.backX + math.floor(xOffset * 0.4)
		if backX > self.frontSize.width / 2 then
			backX = self.frontSize.width / 2
		elseif backX <= display.width - self.frontSize.width / 2 then
			backX = display.width - self.frontSize.width / 2
		end
		self.backBg:pos(backX, display.height)

		if animation then
			self.backBg:moveTo(1, backX, display.height)
		else
			self.backBg:pos(backX, display.height)
		end
		game.backX = backX
	end
end

function NewMainLayer:setOffset(offset, animation)
	if animation then
		self.frontBg:moveTo(1, offset + self.frontSize.width / 2, 0)
		self.middleBg:moveTo(1, offset + self.frontSize.width / 2, display.height-self.initOffsetY)
		self.backBg:moveTo(1, offset + self.frontSize.width / 2, display.height)
	else
		self.frontBg:pos(offset + self.frontSize.width / 2, 0)
		self.middleBg:pos(offset + self.frontSize.width / 2, display.height-self.initOffsetY)
		self.backBg:pos(offset + self.frontSize.width / 2, display.height)
	end
end

function NewMainLayer:initRightTopBtns()

	--首充（未领取显示）
	local firstRechargeShow = false
	if game.role.firstRechargeAwardState ~= 2 then
		firstRechargeShow = true
		local firstRechargeBtn = DGBtn:new(HomeRes, {"first_recharge_normal.png", "first_recharge_press.png"},
			{	
				callback = function()
					local giftView = FirstRechargeLayer.new({ priority = self.priority - 10,
					callback=function()
						self:getChildByTag(201412):removeSelf()
						if self:getChildByTag(201413) then
							self:getChildByTag(201413):setPositionY(display.height-220)
						end
					end })
					giftView:getLayer():addTo(display.getRunningScene())
				end,
			}):getLayer()
		firstRechargeBtn:anch(0, 0):pos(20,display.height-120-firstRechargeBtn:getContentSize().height):addTo(self, 2,201412)
		self.firstRechargeBtn = firstRechargeBtn

		local s = firstRechargeBtn:getContentSize()
		showParticleEffect({
			position = ccp(s.width * 0.5,s.height * 0.5),
			tag = 998,
			parent = firstRechargeBtn,
			zorder = 100,
			scale = 0.6,
			res = "resource/ui_rc/particle/FirstRechargeIco.plist",
		})

		game.role:addEventListener("notifyNewMessage", function(event)
			if event.type == "firstRechargeAwardState" then
				firstRechargeBtn:removeChildByTag(9999)
				if event.action == "add" then
					uihelper.newMsgTag(firstRechargeBtn, ccp(firstRechargeBtn:getContentSize().width - 25, 6))
				end
			end
		end)
	end

	-- 充值按钮
	local rechargeBtn = DGBtn:new(HomeRes, {"rechargeBtn_normal.png", "rechargeBtn_press.png"},
		{	
			priority = self.priority - 1,
			callback = function() 
				local ReChargeLayer = require("scenes.home.shop.ReChargeLayer")
				local layer = ReChargeLayer.new({priority = self.priority - 10})
				layer:getLayer():addTo(display.getRunningScene())
			end,
		}):getLayer()
	local posY= firstRechargeShow and self.firstRechargeBtn:getPositionY()-rechargeBtn:getContentSize().height or display.height-220
	rechargeBtn:anch(0, 0):pos(20, posY):addTo(self, 2, 201413)


	-- 抽卡
	-- local storeBtn = DGBtn:new(HomeRes, {"drawcard_normal.png", "drawcard_selected.png"},
	-- 	{	
	-- 		callback = function() 
	-- 			local layer = ShopMainLayer.new({ chooseIndex = 1, parent = self})
	-- 			layer:getLayer():addTo(display.getRunningScene())
	-- 		end,
	-- 	}):getLayer()
	-- storeBtn:anch(0.5, 0):pos(display.width - 70, display.height - 200):addTo(self, 2, 40)
	

	local xPos, xInterval, yPos, index = 695, 110, display.height - 120, 1

	-- 商城
	local storeBtn = DGBtn:new(nil, {"#store_normal.png", "#store_selected.png"},
		{	
			priority = self.priority - 1,
			callback = function() 
				local layer = ShopMainLayer.new({ chooseIndex = 1, parent = self, priority = self.priority - 10 })
				layer:getLayer():addTo(display.getRunningScene())
			end,
		}):getLayer()
	storeBtn:anch(0, 1):pos(display.width - 112, display.height - 5):addTo(self, 2, 30)
	self.storeBtn = storeBtn

	local s = storeBtn:getContentSize()
	showParticleEffect({
		position = ccp(s.width * 0.5,s.height * 0.6),
		tag = 998,
		parent = storeBtn,
		zorder = 100,
		scale = 0.65,
		res = "resource/ui_rc/particle/kaifu_icon.plist",
	})

	game.role:addEventListener("notifyNewMessage", function(event)
		if event.type == "freeDrawCard" or event.type == "vip0Gift" then
			storeBtn:removeChildByTag(9999)
			if event.action == "add" then
				uihelper.newMsgTag(storeBtn)
			end
		end
	end)

	--排行榜
	local rankBtn = DGBtn:new(nil, {"#rank_normal.png", "#rank_selected.png"},
		{	
			priority = self.priority - 1,
			callback = function()
				local layer = RankMainLayer.new({ parent = self, priority = self.priority - 10 })
				layer:getLayer():addTo(display.getRunningScene())
			end,
		}):getLayer()
	rankBtn:anch(0, 0):pos(xPos - xInterval * (index - 1), yPos):addTo(self, 2)
	index = index + 1


	-- 活动
	local eatChickenBtn = DGBtn:new(nil, {"#activity_normal.png", "#activity_selected.png"},
		{
			priority = self.priority - 1,	
			callback = function()
				local giftView = ActiveMainLayer.new({ priority = self.priority - 10 })
				giftView:getLayer():addTo(display.getRunningScene())
			end,
		}):getLayer()
	eatChickenBtn:anch(0, 0):pos(xPos - xInterval * (index - 1), yPos):addTo(self, 2)
	game.role:addEventListener("notifyNewMessage", function(event)
		if event.type == "eatChicken" or event.type == "accumulatedRechargeState" or event.type == "fund" or event.type == "godHero" then
			if event.type ~= "eatChicken" or (event.action ~= "add" and self.addByChicken) then
				eatChickenBtn:removeChildByTag(9999)
			end
			if event.action == "add" then
				uihelper.newMsgTag(eatChickenBtn, ccp(eatChickenBtn:getContentSize().width - 25, 6))
				self.addByChicken = self.addByChicken or event.type == "eatChicken"
			end
		end
	end)
	index = index + 1

	--升级礼包
	local levelGiftBtn = DGBtn:new(nil, {"#reward_normal.png", "#reward_selected.png"},
		{	
			scale = 1.0,
			priority = self.priority - 1,
			callback = function()
				local giftMainLayer = require("scenes.activity.GiftMainLayer")
				local levelGiftView = giftMainLayer.new({ priority = self.priority - 10, closeCallback = function() self:checkGuide() end })
				levelGiftView:getLayer():addTo(display.getRunningScene())
			end,
		}):getLayer()
	levelGiftBtn:anch(0, 0):pos(xPos - xInterval * (index - 1), yPos):addTo(self, 2)
	levelGiftBtn:setTag(31)
	game.role:addEventListener("notifyNewMessage", function(event)
		if event.type == "levelGift" or event.type == "serverGift" then
			levelGiftBtn:removeChildByTag(9999)
			if event.action == "add" then
				uihelper.newMsgTag(levelGiftBtn, ccp(levelGiftBtn:getContentSize().width - 25, 6))
			end
		end
	end)

	index = index + 1

	-- 好土的招财进宝  --哪里土了-_-#
	local zhaocaiBtn = DGBtn:new(nil, {"#zhaocai_normal.png", "#zhaocai_selected.png"},
		{
			priority = self.priority - 1,	
			callback = function()
				local getMoney = require("scenes.activity.GetMoneyLayer")
				local giftView = getMoney.new({ priority = self.priority - 10 })
				giftView:getLayer():addTo(display.getRunningScene())
			end,
		}):getLayer()
	zhaocaiBtn:anch(0, 0):pos(xPos - xInterval * (index - 1), yPos):addTo(self)
	index = index + 1

	-- 签到
	local assignBtn = DGBtn:new(nil, {"#assign_normal.png", "#assign_selected.png"},
		{
			priority = self.priority - 1,	
			scale = 1.0,
			callback = function()
				local layer = CurMonthAwardLayer.new({ priority = self.priority - 10 })
				layer:getLayer():addTo(display.getRunningScene())
			end,
		}):getLayer()
	assignBtn:anch(0, 0):pos(xPos - xInterval * (index - 1), yPos):addTo(self)
	
	game.role:addEventListener("notifyNewMessage", function(event)
		if event.type == "sign" then
			assignBtn:removeChildByTag(9999)
			if event.action == "add" then
				game.role.gotSignGift = false
				uihelper.newMsgTag(assignBtn, ccp(assignBtn:getContentSize().width - 30, 5))
			end
		end
	end)
	index = index + 1
end

function NewMainLayer:refreshStoreBubble()
	local tag = 15635
	self.soulShopBtn:getLayer():removeChildByTag(tag)
	local vipInfo = vipCsv:getDataByLevel(game.role.vipLevel)
	for storeLevel = 3, 2, -1 do
		if vipInfo.storeLevel >= storeLevel then break end
		local ShopRes = "resource/ui_rc/store/"
		local leftTime = game.role[string.format("specialStore%dEndTime", storeLevel)] - game:nowTime()
		if leftTime > 0 then	
			local bubble = display.newSprite(ShopRes .. string.format("bubble_shop%d.png", storeLevel))
			bubble:anch(0, 1):pos(self.soulShopBtn:getLayer():getContentSize().width - 20, self.soulShopBtn:getLayer():getContentSize().height-10):addTo(self.soulShopBtn:getLayer(), 0, tag)
			bubble:runAction(CCRepeatForever:create(transition.sequence({
				CCMoveBy:create(1, ccp(-5, 0)),
				CCMoveBy:create(1, ccp(5, 0))
				})))
			bubble:performWithDelay(function() bubble:removeSelf() end, leftTime)
			break
		end
	end
end

function NewMainLayer:initFrontLayer()
	display.addSpriteFramesWithFile(HomeRes.."homePics.plist", HomeRes.."homePics.png")
	if not self.frontBg then
		self.frontBg = display.newSprite(HomeRes .. "jinjing.png")
	end
	
	self.frontBg:removeAllChildren()
	self.frontSize = self.frontBg:getContentSize()

	self.buildingNotify = self.buildingNotify or {}
	for _, notify in ipairs(self.buildingNotify) do
		game.role:removeEventListener("notifyNewMessage", notify)
	end


	-- 叶子
	local particle = CCNodeExtend.extend(CCParticleSystemQuad:create(ParticleRes .. "leaf_stars.plist"))
	particle:setPositionType(kCCPositionTypeRelative)
	particle:anch(0.5, 0.5):pos(self.frontSize.width - 400, 450):addTo(self.frontBg)

	-- 瀑布
	local water = self:getIconActionSprite("water", 5)
	water:pos(490, 380):addTo(self.frontBg):playAnimationForever(display.getAnimationCache("water"))

	local waterFall = self:getIconActionSprite("waterfall", 10)
	waterFall:pos(260, 480):addTo(self.frontBg):playAnimationForever(display.getAnimationCache("waterfall"))

	-- 美人
	local beautyBtn = DGBtn:new(nil, {"#beauty_touch.png", "#beauty_normal.png"},
		{	
			swallowsTouches=false,
			selectAnchor = { 0.5, 0 },	
			callback = function()
				if self.roleInfo.beautyOpen < 0 then
					DGMsgBox.new({ msgId = 175 })
					return
				end
				local layer = BeautyListLayer.new({closeCB = function () self:setKeypadLayerEnable(true) end, priority = self.priority - 10})
				layer:getLayer():addTo(self, 100) 

				self:setKeypadLayerEnable(false)
			end,
		})
	beautyBtn:getLayer():anch(0.5, 0):pos(700, display.height - 310):addTo(self.frontBg, 0, 23)
	self:buildingIcon({ button = beautyBtn, name = "beauty", lightScale = 1, lightX = 140,
		titleX = beautyBtn:getLayer():getContentSize().width/2 + 20, titleY = -15, effectName = "beauty_eff", effectNum = 7, effectFps = 7,
		effectX = 100, effectY = 85, disable = self.roleInfo.beautyOpen < 0
	})
	
	-- 副本
	local carbonBtn = DGBtn:new(nil, {"#carbon_touch.png", "#carbon_normal.png"},
		{	
			swallowsTouches=false,
			selectAnchor = { 0.5, 0 },
			callback = function()
				switchScene("carbon", { layer = "map"})
			end,
		})
	carbonBtn:getLayer():anch(0.5, 0):pos(780, 110):addTo(self.frontBg, 0, 50) 
	self:buildingIcon({ button = carbonBtn, name = "carbon", lightScale = 1, lightX = 125,
		titleX = carbonBtn:getLayer():getContentSize().width/2 + 20, titleY = 0,
		effectX = 110, effectY = 150,
	})
	local fakeNormal = carbonBtn.item[1]:getChildByTag(100)
	local tempNode = display.newSprite("#carbon_eff2.png"):pos(105, 135):addTo(fakeNormal)
	tempNode:runAction(CCRepeatForever:create(transition.sequence({
		CCMoveBy:create(1, ccp(0, 15)),
		CCMoveBy:create(1, ccp(0, -15))
	})))
	display.newSprite("#carbon_eff.png"):pos(tempNode:getContentSize().width/2, tempNode:getContentSize().height/2):addTo(tempNode, -1)
		:runAction(CCRepeatForever:create(CCRotateBy:create(1, 20)))

	tempNode = display.newSprite("#carbon_eff2.png"):pos(105, 135):addTo(carbonBtn.item[2])
	tempNode:runAction(CCRepeatForever:create(transition.sequence({
		CCMoveBy:create(1, ccp(0, 15)),
		CCMoveBy:create(1, ccp(0, -15))
	})))
	display.newSprite("#carbon_eff.png"):pos(tempNode:getContentSize().width/2, tempNode:getContentSize().height/2):addTo(tempNode, -1)
		:runAction(CCRepeatForever:create(CCRotateBy:create(1, 20)))
	self.carbonNode = carbonBtn:getLayer()

	-- PVP战场
	local pvpBtn = DGBtn:new(nil, {"#pvp_touch.png", "#pvp_normal.png" },
		{	
			swallowsTouches=false,
			selectAnchor = { 0.5, 0},	
			callback = function()
				if self.roleInfo.pvpOpen < 0  then
					DGMsgBox.new({ msgId = 173 })
					return
				end
				switchScene("pvp", {})
			end,
		})
	pvpBtn:getLayer():anch(0.5, 0):pos(990, display.height - 390):addTo(self.frontBg, 0, 60)
	self:buildingIcon({ button = pvpBtn, name = "pvp", lightScale = 1, lightX = 125,
		titleX = pvpBtn:getLayer():getContentSize().width/2 - 10, titleY = -10, effectName = "pvp_eff2", effectNum = 20, effectFps = 10, 
		effectX = 86, effectY = 123, disable = self.roleInfo.pvpOpen < 0,
	})
	-- 鼓面
	local fakeNormal = pvpBtn.item[1]:getChildByTag(100)
	local sprite = self:getIconActionSprite("pvp_eff", 7)
	sprite:pos(33, 135):addTo(fakeNormal)
		:playAnimationForever(display.getAnimationCache("pvp_eff"))
	local sprite = self:getIconActionSprite("pvp_eff", 7)
	sprite:pos(33, 135):addTo(pvpBtn.item[2])
		:playAnimationForever(display.getAnimationCache("pvp_eff"))

	-- 科技
	local techBtn = DGBtn:new(nil, { "#tech_touch.png", "#tech_normal.png" },
		{	
			swallowsTouches=false,
			selectAnchor = { 0.5, 0},	
			callback = function()
				if self.roleInfo.techOpen < 0 then
					DGMsgBox.new({ msgId = 174 })
					return
				end
				local techLayer = TechHomeLayer.new({ parent = self, priority = self.priority - 10,
					closeCB = function ()
						self:setKeypadLayerEnable(true)
					end})
				techLayer:getLayer():addTo(display.getRunningScene())

				self:setKeypadLayerEnable(false)
			end,
		})
	techBtn:getLayer():anch(0.5, 0):pos(1180, 150):addTo(self.frontBg, 0, 22)
	self:buildingIcon({ button = techBtn, name = "tech", lightScale = 1, lightX = 100,
		titleX = techBtn:getLayer():getContentSize().width/2 + 20, titleY = -10, effectName = "tech_eff", effectNum = 8, effectFps = 8,
		effectX = 20, effectY = 30, disable = self.roleInfo.techOpen < 0,
	})

	-- 名将
	local legendBtn = DGBtn:new(nil, {"#legend_touch.png", "#legend_normal.png"},
		{	
			swallowsTouches=false,
			selectAnchor = { 0.5, 0},	
			callback = function()
				if self.roleInfo.legendOpen < 0 then
					DGMsgBox.new({ msgId = 178 })
					return
				end
				switchScene("legend")
			end,
		})
	legendBtn:getLayer():anch(0.5, 0):pos(1390, display.height - 370):addTo(self.frontBg, 0, 25)
	self:buildingIcon({ button = legendBtn, name = "legend", lightScale = 0.8, lightX = 70,
		titleX = legendBtn:getLayer():getContentSize().width/2 + 20, titleY = -10, effectName = "legend_eff", effectNum = 16, effectFps = 8,
		effectX = 88, effectY = 140, disable = self.roleInfo.legendOpen < 0,
	})

	-- 将魂商店
	self.soulShopBtn = DGBtn:new(nil, {"#soulshop_touch.png", "#soulshop_normal.png"},
		{
			swallowsTouches=false,
			selectAnchor = { 0.5, 0},	
			callback = function()
				local bin = pb.encode("SimpleEvent", { roleId = game.role.id, param1 = 1, param2 = 4 })
				game:sendData(actionCodes.RoleShopRequest, bin)
				showMaskLayer()
				game:addEventListener(actionModules[actionCodes.RoleShopResponse], function(event)
					hideMaskLayer()
					local msg = pb.decode("RoleShopDataResponse", event.data)

					local now = game:nowTime()
					local shopDatas = {}
					for _, shopData in ipairs(msg.shopDatas) do
						shopDatas[shopData.shopIndex] = {
							shopItems = json.decode(shopData.shopItemsJson),
							refreshLeftTime = shopData.refreshLeftTime,
							checkPoint = now,
						}
					end

					local storeMainLayer = StoreMainLayer.new({ 
						shopDatas = shopDatas,
						parent = self, 
						priority = self.priority - 10,
						closeCB = function () self:setKeypadLayerEnable(true) end})
					storeMainLayer:getLayer():addTo(display.getRunningScene())

					self:setKeypadLayerEnable(false)
				end)
			end,
		})
	self.soulShopBtn:getLayer():anch(0.5, 0):pos(1600, display.height - 510):addTo(self.frontBg)
	self:buildingIcon({ button = self.soulShopBtn, name = "soulshop", lightScale = 0.8, lightX = 100,
		titleX = self.soulShopBtn:getLayer():getContentSize().width/2 + 10, titleY = -10, effectName = "soulshop_eff", effectNum = 4, effectFps = 4,
		effectX = 163, effectY = 135,
	})

	self:refreshStoreBubble()

	-- 将星
	-- 注释掉
	-- local heroStarBtn = DGBtn:new(nil, {"#herostar_touch.png", "#herostar_normal.png" },
	-- 	{	
	-- 		swallowsTouches=false,
	-- 		selectAnchor = { 0.5, 0},	
	-- 		callback = function()
	-- 			if self.roleInfo.heroStarOpen < 0 then
	-- 				DGMsgBox.new({ msgId = 176 })
	-- 				return
	-- 			end
	-- 			local heroStarLayer = HeroStarLayer.new({priority = self.priority - 10, closeCB = function ()
	-- 					self:setKeypadLayerEnable(true)
	-- 				end})
	-- 			heroStarLayer:getLayer():addTo(display.getRunningScene())

	-- 			self:setKeypadLayerEnable(false)
	-- 		end,
	-- 	})
	-- heroStarBtn:getLayer():anch(0.5, 0):pos(1500, 125):addTo(self.frontBg, 0, 21)
	-- self:buildingIcon({ button = heroStarBtn, name = "herostar", lightScale = 0.7, lightX = 100,
	-- 	titleX = heroStarBtn:getLayer():getContentSize().width/2 + 30, titleY = -10, effectName = "herostar_eff", effectNum = 7, effectFps = 8, 
	-- 	effectX = 90, effectY = 130, disable = self.roleInfo.heroStarOpen < 0,
	-- })
	-- local fakeNormal = heroStarBtn.item[1]:getChildByTag(100)
	-- display.newSprite("#herostar_star.png"):pos(100, 100):addTo(fakeNormal)
	-- 	:runAction(CCRepeatForever:create(transition.sequence({
	-- 			CCMoveBy:create(1, ccp(0, 15)),
	-- 			CCMoveBy:create(1, ccp(0, -15))
	-- 		})))
	-- display.newSprite("#herostar_star.png"):pos(100, 100):addTo(heroStarBtn.item[2])
	-- 	:runAction(CCRepeatForever:create(transition.sequence({
	-- 			CCMoveBy:create(1, ccp(0, 15)),
	-- 			CCMoveBy:create(1, ccp(0, -15))
	-- 		})))

	-- 试练塔
	local trainBtn = DGBtn:new(nil, {"#tower_touch.png", "#tower_normal.png" },
		{	
			swallowsTouches=false,
			selectAnchor = { 0.5, 0},	
			callback = function()
				if self.roleInfo.expBattleOpen < 0 and self.roleInfo.moneyBattleOpen < 0 then
					DGMsgBox.new({ msgId = 170 })
					return
				end

				switchScene("activity")
			end,
		})
	trainBtn:getLayer():anch(0.5, 0):pos(360, display.height - 300):addTo(self.frontBg, 0, 24)
	self:buildingIcon({ button = trainBtn, name = "tower", lightScale = 0.7, lightX = 105,
		titleX = trainBtn:getLayer():getContentSize().width/2 + 30, titleY = -10, effectName = "tower_eff", effectNum = 16, effectFps = 12,
		effectX = 100, effectY = 170, disable = self.roleInfo.expBattleOpen < 0 and self.roleInfo.moneyBattleOpen < 0,
	})
	-- 灯笼效果
	local fakeNormal = trainBtn.item[1]:getChildByTag(100)
	local sprite = self:getIconActionSprite("tower_eff2", 9)
	sprite:pos(95, 50):addTo(fakeNormal)
		:playAnimationForever(display.getAnimationCache("tower_eff2"))
	local sprite = self:getIconActionSprite("tower_eff2", 9)
	sprite:pos(95, 50):addTo(trainBtn.item[2])
		:playAnimationForever(display.getAnimationCache("tower_eff2"))

	-- 过关斩将
	local towerBtn = DGBtn:new(nil, {"#guoguan_touch.png", "#guoguan_normal.png" },
		{	
			swallowsTouches=false,
			selectAnchor = { 0.5, 0},	
			callback = function()
				if self.roleInfo.towerOpen < 0 then
					DGMsgBox.new({ msgId = 177 })
					return
				end

				local bin = pb.encode("SimpleEvent", { roleId = game.role.id })
				game:sendData(actionCodes.TowerDataRequest, bin, #bin)
				loadingShow()
				game:addEventListener(actionModules[actionCodes.TowerDataResponse], function(event)
					loadingHide()
					local msg = pb.decode("TowerData", event.data)
					local towerPbFields = { "count", "carbonId", "totalStarNum", "preTotalStarNum", 
						"maxTotalStarNum", "curStarNum", "hpModify", "atkModify", "defModify", "sceneId1",
						"sceneId2", "sceneId3", }

					game.role.towerData = game.role.towerData or {}
					for _, field in pairs(towerPbFields) do
						game.role.towerData[field] = msg[field]
					end

					switchScene("tower")	
					return "__REMOVE__"
				end)

			end,
		})
	towerBtn:getLayer():anch(0.5, 0):pos(225, 120):addTo(self.frontBg, 0, 65)
	self:buildingIcon({ button = towerBtn, name = "guoguan", lightScale = 0.8, lightX = 95, 
		titleX = towerBtn:getLayer():getContentSize().width/2 + 15, titleY = 0, effectName = "guoguan_eff", effectNum = 10, 
		effectX = 75, effectY = 85, disable = self.roleInfo.towerOpen < 0,
	})

	-- 邮箱
	local mailBtn = DGBtn:new(nil, {"#mail_touch.png", "#mail_normal.png"},
		{	
			swallowsTouches=false,
			selectAnchor = { 0.5, 0},	
			callback = function()
				local layer = EmailLayer.new({ priority = self.priority - 10, closeCB = function ()
					self:setKeypadLayerEnable(true)
				end })
				layer:getLayer():addTo(self, 100)

				self:setKeypadLayerEnable(false)
			end,
		})
	mailBtn:getLayer():anch(0.5, 0):pos(530, 150):addTo(self.frontBg)

	table.insert(self.buildingNotify, game.role:addEventListener("notifyNewMessage", function(event)
		if event.type == "email" then
			mailBtn:getLayer():removeChildByTag(9999)
			if event.action == "add" then
				uihelper.newMsgTag(mailBtn:getLayer())
			end
		end
	end))
	self:buildingIcon({ button = mailBtn, name = "mail", lightScale = 0.5, lightX = 40,
		titleX = mailBtn:getLayer():getContentSize().width/2-15, titleY = -10, effectName = "mail_eff", effectNum = 9, effectFps = 6,
		effectX = 15, effectY = 85,
	})

	-- 工会/联盟
	local leagueBtn = DGBtn:new(nil, {"#league_touch.png", "#league_normal.png"},
		{	
			swallowsTouches=false,
			selectAnchor = { 0.5, 0 },	
			callback = function()
			end,
		})
	leagueBtn:getLayer():anch(0.5, 0):pos(1850, display.height - 440):addTo(self.frontBg, 0)
	self:buildingIcon({ button = leagueBtn, name = "league", lightScale = 1, lightX = 140,
		titleX = leagueBtn:getLayer():getContentSize().width/2 + 20, titleY = -10, hideTitle = true
	})
	-- 左侧旗子
	local fakeNormal = leagueBtn.item[1]:getChildByTag(100)
	local sprite = self:getIconActionSprite("league_effL", 7, 5)
	sprite:pos(55, 175):addTo(fakeNormal, -1)
		:playAnimationForever(display.getAnimationCache("league_effL"))
	local sprite = self:getIconActionSprite("league_effL", 7, 5)
	sprite:pos(55, 175):addTo(leagueBtn.item[2], -1)
		:playAnimationForever(display.getAnimationCache("league_effL"))
	-- 右侧旗子
	local sprite = self:getIconActionSprite("league_effR", 5)
	sprite:pos(210, 160):addTo(fakeNormal, -1)
		:playAnimationForever(display.getAnimationCache("league_effR"))
	local sprite = self:getIconActionSprite("league_effR", 5)
	sprite:pos(210, 160):addTo(leagueBtn.item[2], -1)
		:playAnimationForever(display.getAnimationCache("league_effR"))

	-- 左下角荧光乱舞
	local particle = CCNodeExtend.extend(CCParticleSystemQuad:create(ParticleRes .. "home_angle_star.plist"))
	particle:setPositionType(kCCPositionTypeRelative)
	particle:anch(0.5, 0.5):pos(100, 100):addTo(self.frontBg)

	-- 右下角荧光乱舞
	local particle = CCNodeExtend.extend(CCParticleSystemQuad:create(ParticleRes .. "home_angle_star.plist"))
	particle:setPositionType(kCCPositionTypeRelative)
	particle:anch(0.5, 0.5):pos(self.frontSize.width - 100, 100):addTo(self.frontBg)

	local expeditionTag, guideId = 66, 1261
	local hasGuide = game.guideId == 1261 or game.guideId == 1262
	self.backBg:removeChildByTag(expeditionTag)
	--远征 @remark 加到远景层了
	local expeditionBtn = DGBtn:new(nil, {"#expedition_touch.png", "#expedition_normal.png"},
		{	
			swallowsTouches = hasGuide,
			priority = hasGuide and self.priority - 2 or nil,	
			selectAnchor = { 0.5, 0 },
			callback = function()
				if self.roleInfo.expeditionOpen < 0 then
					DGMsgBox.new({ msgId = 181 })
					return
				end

				local bin=pb.encode("SimpleEvent",{})
				game:sendData(actionCodes.ExpeditionRequest, bin)
				loadingShow()
				game:addEventListener(actionModules[actionCodes.ExpeditionResponse], function(event)
					local msg=pb.decode("ExpeditionResponse",event.data)
					loadingHide()

					local expeditionPbFields = { "fightList", "drawStatus", "leftCnt"}

					game.role.expeditionData = game.role.expeditionData or {}
					for _, field in pairs(expeditionPbFields) do
						game.role.expeditionData[field] = msg[field]
					end

					switchScene("expedition", {parent=self,battleEnd=false})
					self:setKeypadLayerEnable(false)

					return "__REMOVE__"
				end)

				
			end,
		})
	expeditionBtn:getLayer():anch(0.5, 0):pos(888, 112):addTo(self.backBg, 0, expeditionTag)
	self:buildingIcon({ button = expeditionBtn, name = "expedition", lightScale = 0.8, lightX = 95, 
		titleX = expeditionBtn:getLayer():getContentSize().width/2 , titleY = 4, effectNum = 10, 
		effectX = 75, effectY = 85, disable = self.roleInfo.expeditionOpen < 0,
	})
end

-- TAG:{ 美人:23, 名将:25, 科技:22, 试炼:24, 刷塔:65, 将星:21, pvp:60, carbon:50, 商城:30 , 抽卡: 40, 点将: 14, 出塞：66}
function NewMainLayer:checkGuide(remove)
	-- game.role.guideStep = 2
	
	if true then return end
	--副本
	game:addGuideNode({node = self.carbonNode, remove = remove,
		beginFunc = function()
			self:setOffset(0, false)
		end,
		guideIds = {1002, 1003, 1024, 1030, 1033, 1036, 1054, 1055, 1059, 1063, 1082, 1083, 1087, 1091, 1110}
	})
	--商城
	game:addGuideNode({node = self.storeBtn, remove = remove,
		guideIds = {1010, 1011, 1013}
	})
	--点将
	game:addGuideNode({node = self:getChildByTag(14), remove = remove,
		guideIds = {600, 1015, 1019, 1040, 1041, 1046, 1073, 1077, 1096, 1097, 1100, 1109, 1195, 1271, 1272, 1273, 1275}
	})
	--武将
	game:addGuideNode({node = self:getChildByTag(15), remove = remove,
		guideIds = {1068, 1069}
	})
	--战场
	game:addGuideNode({node = self.frontBg:getChildByTag(60), remove = remove,
		beginFunc = function()
			self:setOffset(-500, false)
		end,
		guideIds = {1181, 1182}
	})
	--礼包
	game:addGuideNode({node = self:getChildByTag(31), remove = remove,
		guideIds = {1191}
	})
	--每日任务
	game:addGuideNode({node = self:getChildByTag(11), remove = remove,
		guideIds = {1282}
	})
	--科技
	game:addGuideNode({node = self.frontBg:getChildByTag(22), remove = remove,
		beginFunc = function()
			self:setOffset(-900, false)
		end,
		guideIds = {1201, 1202}
	})
	--美人
	game:addGuideNode({node = self.frontBg:getChildByTag(23), remove = remove,
		beginFunc = function()
			self:setOffset(-200, false)
		end,
		guideIds = {1211, 1212}
	})
	--过关斩将
	game:addGuideNode({node = self.frontBg:getChildByTag(65), remove = remove,
		beginFunc = function()
			self:setOffset(0, false)
		end,
		guideIds = {1221, 1222}
	})
	--将星
	game:addGuideNode({node = self.frontBg:getChildByTag(21), remove = remove,
		beginFunc = function()
			self:setOffset(-900, false)
		end,
		guideIds = {913, 1223}
	})
	--名将
	game:addGuideNode({node = self.frontBg:getChildByTag(25), remove = remove,
		beginFunc = function()
			self:setOffset(-500, false)
		end,
		guideIds = {1231, 1232}
	})
	--试炼
	game:addGuideNode({node = self.frontBg:getChildByTag(24), remove = remove,
		beginFunc = function()
			self:setOffset(0, false)
		end,
		guideIds = {1241, 1242, 1251, 1252}
	})
	--出塞
	game:addGuideNode({node = self.backBg:getChildByTag(66), remove = remove,
		beginFunc = function()
			self:setOffset(-200, false)
		end,
		guideIds = {1261, 1262}
	})
end

function NewMainLayer:popNotice(params)
	if not params.toPopNotice or game.guideId ~= 0 or not game.role.notices or #game.role.notices == 0 then return end

	local bg = display.newSprite(HomeRes .. "notice_bg.png")
	bg:pos(display.cx, display.cy)
	local bgSize = bg:getContentSize()
	local priority = self.priority - 1000
	local mask = DGMask:new({item = bg, priority = priority })
	mask:getLayer():addTo(self, 1000)

	display.newSprite(HomeRes .. "notice_text.png")
		:anch(0.5, 0.5):pos(bgSize.width/2, bgSize.height - 55):addTo(bg, 100)

	local width = 647

	local function createNoticeNode(notice)
		local cellSize = CCSizeMake(width, 5)
		local cellNode = display.newNode()

		--标题背景
		local titlebg = display.newSprite(HomeRes .. "notice_title_bg.png")
		titlebg:anch(0.5, 1):addTo(cellNode)
		cellSize.height = titlebg:getContentSize().height
		--标题文字
		local text = ui.newTTFLabel({text = notice.order, font = ChineseFont, size = 24, color = uihelper.hex2rgb("#f8d23a"), strokeColor = display.COLOR_FONT})
		text:anch(0, 0):pos(20, 0):addTo(titlebg)
		ui.newTTFLabel({text = notice.title, size = 24, font = ChineseFont, color = uihelper.hex2rgb("#f8d23a"), strokeColor = display.COLOR_FONT})
			:anch(0, 0):pos(text:getContentSize().width + 10, 0):addTo(text)
		--正文
		text = uihelper.createLabel({text = notice.content, size = 18, color = uihelper.hex2rgb("#533a27"), width = 575, isRichLabel = true })
		text:anch(0.5, 1):pos(titlebg:getContentSize().width/2, -18):addTo(titlebg)
		cellSize.height = cellSize.height + 16 + text:getContentSize().height

		cellNode:size(cellSize)
		titlebg:pos(cellSize.width/2, cellSize.height)
		return cellNode
	end

	local resultScroll = DGScrollView:new({ size = CCSizeMake(width, 450) , divider = 10, priority = priority - 1})
	resultScroll:getLayer():anch(0.5, 0):pos(bgSize.width/2, 62):addTo(bg)
	for _, notice in ipairs(game.role.notices) do
		resultScroll:addChild(createNoticeNode(notice))
	end
	resultScroll:alignCenter()

	--按钮
	local LoginResRc = "resource/ui_rc/login_rc/"
	local enterBtn = DGBtn:new(LoginResRc, {"btn_start_normal.png", "btn_start_selected.png"},
		{	
			musicId = 32,
			priority = priority - 10,
			callback = function()
				mask:remove()
			end
		}):getLayer()
	enterBtn:anch(0.5, 0):pos(bgSize.width/2, 0):addTo(bg)
end

function NewMainLayer:autoPopupLayer(params)
	if game.role.guideStep ~= 1000 then
		return
	end

	params = params or {}
	params.priority = self.priority - 1
	params.parent = self
	local layer
	if params.layer == "chooseHero" then
		layer = HeroChooseLayer.new(params)
	elseif params.layer == "intensify" then
		layer = IntensifyLayer.new(params)
	elseif params.layer == "evolution" then
		layer = HeroEvolutionLayer.new(params)
	elseif params.layer == "beauty" then
		layer = BeautyListLayer.new(params)
	elseif params.layer == "tech" then
		layer = TechHomeLayer.new(params)
	elseif params.layer == "herostar" then
		layer = HeroStarLayer.new(params)
	elseif params.layer == "shop" then
		layer = ShopMainLayer.new(params)
		
	elseif params.layer == "zhaoCai" then
		local getMoney = require("scenes.activity.GetMoneyLayer")
		layer = getMoney.new({ priority = self.priority - 10 })
	elseif params.layer == "equip" then
		layer = EquipMainLayer.new(params)
	elseif params.layer == "item" then
		layer = ItemMainLayer.new(params)
	end

	if layer then layer:getLayer():addTo(display.getRunningScene()) end
	

end

function NewMainLayer:buildingIcon(params)
	params = params or {}

	local normalBg = params.button.item[1]
	local selectedBg = params.button.item[2]
	local normalSize = normalBg:getContentSize()
	
	local fakeNormal = display.newSprite(string.format("#%s_normal.png", params.name))
	fakeNormal:anch(0.5, 0):pos(normalSize.width / 2, 0):addTo(normalBg, 0, 100)
	
	if params.effectName then
		local sprite = self:getIconActionSprite(params.effectName, params.effectNum, params.effectFps)
		sprite:pos(params.effectX, params.effectY):addTo(fakeNormal)
			:playAnimationForever(display.getAnimationCache(params.effectName))

		local sprite = self:getIconActionSprite(params.effectName, params.effectNum, params.effectFps)
		sprite:pos(params.effectX, params.effectY):addTo(selectedBg)
			:playAnimationForever(display.getAnimationCache(params.effectName))
	end

	-- title
	if not params.hideTitle then
		if params.disable then
			display.newSprite(string.format("#title_%s_disabled.png", params.name))
				:pos(params.titleX, params.titleY):addTo(fakeNormal)
			display.newSprite(string.format("#title_%s_disabled.png", params.name))
				:pos(params.titleX, params.titleY):addTo(selectedBg)
		else
			display.newSprite(string.format("#title_%s_normal.png", params.name))
				:pos(params.titleX, params.titleY):addTo(fakeNormal)
			display.newSprite(string.format("#title_%s_selected.png", params.name))
				:pos(params.titleX, params.titleY):addTo(selectedBg)
		end
	end

	-- light
	local lightX = params.lightX or normalSize.width / 2
	local lightY = params.lightY or normalSize.height / 2
	display.newSprite("#light.png")
		:scale(params.lightScale):pos(lightX, lightY):addTo(selectedBg, -1)
end

function NewMainLayer:getIconActionSprite(fileName, frameNum, fps)
	self.spriteFrames = self.spriteFrames or {}

	if not self.spriteFrames[fileName] then
		display.addSpriteFramesWithFile(HomeRes..fileName..".plist", HomeRes..fileName..".png")

		local frames = {}
		for index = 1, frameNum do
			local frameId = string.format("%02d", index)
			frames[#frames + 1] = display.newSpriteFrame(fileName.."_" .. frameId .. ".png")
		end

		fps = fps or frameNum
		local animation = display.newAnimation(frames, 1.0 / fps)
		display.setAnimationCache(fileName, animation)

		self.spriteFrames[fileName] = frames[1]
	end

	return display.newSprite(self.spriteFrames[fileName])
end

function NewMainLayer:onExit()
	
end

function NewMainLayer:onCleanup()
	self:checkGuide(true)
	scheduler.unscheduleGlobal(self.newMsgUpdate)
	CCAnimationCache:purgeSharedAnimationCache()
	
	if game.role then
		game.role:removeAllEventListenersForEvent("notifyNewMessage")
		game.role:removeEventListener("updateYuanbao", self.updateYuanbaoHandler)
		game.role:removeEventListener("updateName", self.updateNameHandler)
    	game.role:removeEventListener("updateMoney", self.updateMoneyHandler)
    	game.role:removeEventListener("updateHealth", self.updateHealthHandler)
    	game.role:removeEventListener("updateLevel", self.updateLevelHandler)
    	game.role:removeEventListener("updateExp", self.updateExpHandler)
    	game.role:removeEventListener("updateVipLevel", self.updateVipLevelHandler)
    	game.role:removeEventListener("specialStoreOpened", self.specialStoreOpenedHandle)
    	game.role:removeEventListener("updateChat", self.updateChatHandler)
    	game.role:removeEventListener("updateSlots", self.slotsUpdateHandle)
    end
end

return NewMainLayer