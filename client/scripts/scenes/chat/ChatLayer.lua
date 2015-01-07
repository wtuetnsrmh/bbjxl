-- 新UI聊天系统
-- by yangkun
-- 2014.3.28

local ChatRes = "resource/ui_rc/chat/"
local HeroRes = "resource/ui_rc/hero/"
local HomeRes = "resource/ui_rc/home/"
local GlobalRes = "resource/ui_rc/global/"
local LoginRes = "resource/ui_rc/login_rc/"
local ReChargeRes = "resource/ui_rc/shop/recharge/"

local TopBarLayer = require("scenes.TopBarLayer")
local DGBtn = require("uicontrol.DGBtn")
local DGRadioGroup = require("uicontrol.DGRadioGroup")

local ChatLayer = class("ChatLayer", function(params)
		return display.newLayer(GlobalRes .. "inner_bg.png") 
	end)

function ChatLayer:ctor(params)

	params = params or {}

	self.priority = params.priority or -129

	-- 测试数据
	-- for i=1,10 do
	-- 	local msg1 = {
	-- 		player = { 
	-- 			name = "test"..i,
	-- 			vipLevel = 5,
	-- 			mainId = i,
	-- 			level = i,
	-- 		},
	-- 		chatType = 1,
	-- 		content = "我是系统消息我是系统消息我是系统消息我是系统消息我是系统消息"..i,
	-- 		tstamp = game:nowTime(),
	-- 	}
	-- 	table.insert(game.role.chats, msg1)
	-- end
	-- local msg1 = {
	-- 	player = { 
	-- 		name = "内向的秦琮",
	-- 		vipLevel = 10,
	-- 		mainId = 1,
	-- 		level = 10,
	-- 	},
	-- 	chatType = 1,
	-- 	content = "我是系统系统消息我是系统消息我是系统消息",
	-- 	tstamp = game:nowTime(),
	-- }
	-- table.insert(game.role.chats, msg1)


	-- local msg2 = {
	-- 	chatType = 3,
	-- 	chatMsg = "私聊私聊",
	-- 	from = "宾宾",
	-- 	fromRoleId = 1,
	-- }
	-- table.insert(game.role.chats, msg2)

	self.curChannel = "world"

	self.curPrivateToName = ""
	self.curPrivateToRoleId = 0

	self.hasNewPrivate = false

	self:prepareChats()

	self:initBaseLayer()
	self:initContentLayer()

	if not game.role.lastChatTime then game.role.lastChatTime = 0 end

	self.updateChatHandler = game.role:addEventListener("updateChat", handler(self, self.onUpdateChat))
end

-- 重构聊天消息
function ChatLayer:prepareChats()
	self.chatUnion = {}
	self.chatPrivate = {}
	for _,value in ipairs(game.role.chats) do
		if value.chatType == 2 then
			table.insert(self.chatUnion, value)
		elseif value.chatType == 3 then
			table.insert(self.chatPrivate, value)
		end
	end
end

function ChatLayer:initBaseLayer()
	-- 遮罩层
	self:anch(0.5, 0):pos(display.cx, 0)
	self.size = self:getContentSize()
	self:anch(0, 0):pos((display.width - 960) / 2, 0)

	self.chatContentBg = display.newSprite( ChatRes .. "bg.jpg")
	self.chatContentBg:anch(0,0):pos(18, 9):addTo(self)

	-- 关闭
	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"}, 
		{
			touchScale = 1.5,
			callback = function()
				popScene()
			end,
			priority = self.priority -2
		})
	closeBtn:getLayer():anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self,2)
	-- pushLayerAction(self,true)

	local layer  = TopBarLayer.new({priority = self.priority})
	layer:anch(0,1):pos(0, display.height):addTo(self)
end

function ChatLayer:getLayer()
	return self.mask:getLayer()
end

-- 初始化内容层
function ChatLayer:initContentLayer()

	if self.contentLayer then
		self.contentLayer:removeSelf()
	end

	self.contentLayer = display.newLayer()
	self.contentLayer:size(self:getContentSize()):anch(0,0):pos(0,0):addTo(self)
	local contentSize = self.contentLayer:getContentSize()

	-- 左侧聊天内容层
	self:initChatLayer()

	if self.curChannel == "world" then
		self:createWorldUILayer()
	elseif self.curChannel == "private" then
		self:createPrivateUILayer()
	end

	local tabData = {
		[1] = { name = "worldChat", showName = "世界", callback = function() self:createWorldTab() end},
		-- [2] = { name = "unionChat", showName = "公会", callback = function() self:createunionTab() end},
		-- [3] = { name = "privateChat", showName = "私聊", callback = function() self:createPrivateTab() end},
	}

	-- tab按钮
	self.tableRadioGrp = DGRadioGroup:new()
	for i = 1, #tabData do
		local tabBtn = DGBtn:new(GlobalRes, {"tab_normal.png", "tab_selected.png"},
			{	
				id = i,
				priority = self.priority - 2,
				callback = tabData[i].callback
			}, self.tableRadioGrp)
		tabBtn:getLayer():pos(self.size.width - 14, contentSize.height - (150 + (i-1)*100))
			:addTo(self.contentLayer)
		local tabSize = tabBtn:getLayer():getContentSize()
		ui.newTTFLabelWithStroke({ text = tabData[i].showName,dimensions = CCSizeMake(tabSize.width / 2,tabSize.height), size = 26, font = ChineseFont
				, color=display.COLOR_WHITE, strokeColor = display.COLOR_BLACK, strokeSize = 2 })
			:pos(tabSize.width / 2, tabSize.height / 2):addTo(tabBtn:getLayer(), 10)
	end

	local chatBtn = DGBtn:new(ChatRes, {"send_normal.png", "send_press.png"},
		{
			multiClick =true,
			priority = self.priority - 2,
			callback = function()
				

				-- 5秒间隔
				if game:nowTime() - game.role.lastChatTime < 5 then
					DGMsgBox.new({text = "你说话太快了，歇一歇吧!", type = 1})
					return
				end

				-- 空判断
				if self.chatWorldInputBox:getText() == "" then
					DGMsgBox.new({text = "请输入您的聊天内容!", type = 1})
					return
				end

				-- 检测是否为GM命令
				if not ServerConf[ServerIndex].public and self:checkGM() then return end

				-- 等级限制
				if game.role.level < tonum(globalCsv:getFieldValue("chatLevelLimit")) then
					DGMsgBox.new({ type = 1, text = tonum(globalCsv:getFieldValue("chatLevelLimit")).."级才开放聊天功能!" })
					return
				end

				local msg
				if self.curChannel == "world" then
					local useYb = tonum(game.role.worldChatCount) >= 20 and true or false
					if useYb then
						if game.role.yuanbao < 5 then
							DGMsgBox.new({ text = "元宝不够, 请捐赠票子", type = 2, button2Data = {
								text = "请充值",
								priority = -9000,
								callback = function() 
									local rechargeLayer = require("scenes.home.shop.ReChargeLayer").new({ priority = -9000 })
									rechargeLayer:getLayer():addTo(display.getRunningScene())
								end
							}})

							return
						end
					end

					msg = {
						gold = useYb and 1 or 0,
						chatType = 1,
						content =string.rtrim(string.ltrim(self.chatWorldInputBox:getText()))
					}
					
				elseif self.curChannel == "private" then
					if self.curPrivateToName == "" or self.curPrivateToRoleId == 0 or self.chatPrivateInputBox:getText() == "" then
						return 
					end
					
					msg = {
						roleId = game.role.id,
						chatType = 3,
						chatMsg = self.chatPrivateInputBox:getText(),
						from = game.role.name,
						fromRoleId = game.role.id,
						to = self.curPrivateToName,
						toRoleId = self.curPrivateToRoleId
					}
					self.chatPrivateInputBox:setText("")
					game.role:addChat(msg)
				end

				local bin = pb.encode("ChatMsg", msg)
				game:sendData(actionCodes.ChatSendRequest, bin, #bin)

				game.role.lastChatTime = game:nowTime() 
			end,
		})
	
	chatBtn:getLayer():anch(0.5,0.5):pos(809, 52):addTo(self.contentLayer)

	self:refreshFreeNum()
end

function ChatLayer:checkGM()
	local inputStr = self.chatWorldInputBox:getText()
	if string.sub(string.lower(inputStr),1,3) == "gm:" then
		local msg = string.mySplit(string.sub(string.lower(inputStr),4))
		local bin = pb.encode("GmEvent", { cmd = msg[1], pm1 = tonum(msg[2]), pm2 = tonum(msg[3]), pm3 = tonum(msg[4]) })
		game:sendData(actionCodes.GmSendRequest, bin, #bin)
		require("scenes.home.NewMainLayer").addGmListener(msg[1])
		game:addEventListener(actionModules[actionCodes.GmReceiveResponse], function(event)
			local msg = pb.decode("GmEvent", event.data)
			-- local tips = msg.cmd == "success" and "指令生效" or "指令错误"
			DGMsgBox.new({text = msg.cmd, type = 1})
		end)
		return true
	end

	return false
end

function ChatLayer:refreshFreeNum()
	if self.freeContenLayer then
		self.freeContenLayer:removeSelf()
		self.freeContenLayer = nil
	end

	self.freeContenLayer = display.newLayer()
	self.freeContenLayer:size(CCSize(114,52))

	-- 免费次数
	local useYb = tonum(game.role.worldChatCount) >= 20

	display.newSprite((useYb and GlobalRes.."yuanbao.png" or ChatRes.."free.png")):pos(650,50):addTo(self.freeContenLayer)
	local freeLabel = DGRichLabel.new({ size = 18, font = ChineseFont, color=uihelper.hex2rgb("#ffcf5b") })
		:pos(671,40):addTo(self.freeContenLayer)
	local freeTip =  useYb and "  5" or "([color=60ff00]" .. (20 - tonum(game.role.worldChatCount)) .. "[/color]".."/20)"
	freeLabel:setString(freeTip)

	self.freeContenLayer:addTo(self.contentLayer)
end

function ChatLayer:initChatLayer()
	if self.chatContentLayer then
		self.chatContentLayer:removeSelf()
	end

	self.chatContentLayer = display.newLayer()
	self.chatContentLayer:size(self.chatContentBg:getContentSize()):anch(0,0)
	:pos(18, 84 ):addTo(self.contentLayer)

	local tableSize = CCSizeMake(865, 473)
	self.chatTableLayer = display.newLayer()
	self.chatTableLayer:size(tableSize):pos(10,10):addTo(self.chatContentLayer)

	self.chatTable = self:createChatTable()
	self.chatTable:setContentOffset(self.chatTable:maxContainerOffset(), false)
	self.chatTable:setPosition(0,0)
	self.chatTableLayer:addChild(self.chatTable)
end

function ChatLayer:createChatTable()
	local cellSize = CCSizeMake(865, 94)

	local handler = LuaEventHandler:create(function(fn, tbl, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(cellSize.width, cellSize.height)
        elseif fn == "cellAtIndex" then
			if not a2 then
                a2 = CCTableViewCell:new()
                local cell = display.newNode()
                a2:addChild(cell, 0, 1)
            end

            local cell = tolua.cast(a2:getChildByTag(1), "CCNode")
            cell:removeAllChildren()

            local index = a1
            self:createChatCell(cell, index)
            r = a2
        elseif fn == "numberOfCells" then
        	if self.curChannel == "world" then
        		r = table.nums(game.role.chats)
        	elseif self.curChannel == "union" then
        		r = table.nums(self.chatUnion)
        	elseif self.curChannel == "private" then
        		r = table.nums(self.chatPrivate)
        	end
        end

        return r
    end)

	local chatTableView = CCNodeExtend.extend(LuaTableView:createWithHandler(handler, self.chatTableLayer:getContentSize()))
    chatTableView:setBounceable(true)
    chatTableView:setTouchPriority(self.priority -2)
	return chatTableView
end

function ChatLayer:createChatCell(cellNode, index)
	local cellSize = CCSizeMake(865, 94)

	local curChatArray = {}
	if self.curChannel == "world" then
		curChatArray = game.role.chats
	elseif self.curChannel == "union" then
		curChatArray = self.chatUnion
	elseif self.curChannel == "private" then
		curChatArray = self.chatPrivate
	end
	local chat = curChatArray[table.nums(curChatArray) - index]

	local xPos = 120
	if chat.chatType == 1 then

		-- local nameMenuItem = ui.newTTFLabelMenuItem({ text = string.format("[%s]", chat.player.name), tag = 1, size = 24, color = display.COLOR_GREEN,
		-- 	listener = function(tag)
		-- 		self.curPrivateToName = chat.from
		-- 		self.curPrivateToRoleId = chat.fromRoleId
		-- 		self:createPrivateTab()
		-- 		self.tableRadioGrp:chooseById(3)
		-- 	end})
		-- nameMenuItem:anch(0, 0):pos(0, 0)
		-- local menu = ui.newMenu({ nameMenuItem })
		-- menu:size(nameMenuItem:getContentSize()):anch(0, 0.5):pos(xPos, cellSize.height / 2):addTo(cellNode)
		-- menu:setTouchPriority(self.priority)
		-- xPos = xPos + menu:getContentSize().width

		local mySelf = game.role.name == chat.player.name

		--头像
		local heroBtn = HeroHead.new( 
			{
				type = chat.player.mainId,
				hideStar = true,
				evolutionCount = 0,
				heroLevel = chat.player.level,
			})
		heroBtn:getLayer():scale(0.8):anch(0, 0.5):pos(mySelf and cellSize.width-100 or 0,cellSize.height / 2):addTo(cellNode)
		if chat.player.vipLevel > 0 then
			display.newSprite(ReChargeRes .. "vip_text_" .. chat.player.vipLevel .. ".png")
				:anch(0,0):scale(0.4):pos((mySelf and cellSize.width-100 or 0),0):addTo(cellNode)
		end

		-- 名字
		local nameLabel = ui.newTTFLabelWithStroke({text = chat.player.name,color=uihelper.hex2rgb("#ffcf5b"),
			strokeSize=3,strokeColor=uihelper.hex2rgb("#1f0b00"),font = ChineseFont ,size = 18})
			:anch(mySelf and 1 or 0,0.5):pos((mySelf and 740 or 110),72):addTo(cellNode)

		-- 内容
		local contentLabel = ui.newTTFLabel({ text = chat.content, size = 18, color = display.COLOR_BLACK})
			:anch(0, 0.5):pos(xPos, cellSize.height / 2-10)
			:addTo(cellNode,1)
		local cotentW = contentLabel:getContentSize().width+30 > 50 and contentLabel:getContentSize().width+30 or 50 
		contentLabel:pos(mySelf and 730-cotentW+30 or xPos,cellSize.height / 2-13)

		local res = mySelf and ChatRes .. "talkbg2.png" or ChatRes .. "talkbg1.png"
		local contentBg
		if mySelf then
			contentBg = display.newScale9Sprite(res, 21.5,6.35, CCSizeMake(79,35))
			:anch(0,0):pos(contentLabel:getPositionX()-5, 10):addTo(cellNode)
		else
			contentBg = display.newScale9Sprite(res, 6.5,6.35, CCSizeMake(85.5,35))
			:anch(0,0):pos(97, 10):addTo(cellNode)
		end 
		

		contentBg:setContentSize(CCSize(cotentW,48))
		
		-- 时间
		local time = os.date("%H:%M", chat.tstamp)
		ui.newTTFLabel({text = time, size = 18,color=uihelper.hex2rgb("#ac8e6e")}):pos(mySelf and 30 or 810 ,15):addTo(cellNode)
		
	elseif chat.chatType == 2 then -- 公会消息
		ui.newTTFLabel({ text = chat.chatMsg, size = 24, })
			:anch(0, 0.5):pos(xPos, cellSize.height / 2):addTo(cellNode)
	
	elseif chat.chatType == 3 then -- 私聊
		-- 我发送的
		if chat.fromRoleId == game.role.id then 
			local prefix = ui.newTTFLabel({ text = "[私聊] 你对", size = 24 })
			prefix:anch(0, 0.5):pos(xPos, cellSize.height / 2):addTo(cellNode)
			xPos = xPos + prefix:getContentSize().width
			local nameMenuItem = ui.newTTFLabelMenuItem({ text = string.format("[%s]", chat.to), tag = 1, size = 24, color = display.COLOR_GREEN,
				listener = function(tag)
					if self.curChannel ~= "private" then
						self.tableRadioGrp:chooseById(3)
					end
					self.curPrivateToName = chat.to
					self.curPrivateToRoleId = chat.toRoleId
					self:createPrivateTab()
				end})
			nameMenuItem:anch(0, 0):pos(0, 0)
			local menu = ui.newMenu({ nameMenuItem })
			menu:size(nameMenuItem:getContentSize()):anch(0, 0.5):pos(xPos, cellSize.height / 2):addTo(cellNode)
			menu:setTouchPriority(self.priority)
			xPos = xPos + menu:getContentSize().width

			ui.newTTFLabel({ text = ": " .. chat.chatMsg, size = 24 }):anch(0, 0.5):pos(xPos, cellSize.height / 2):addTo(cellNode)
		else
			local prefix = ui.newTTFLabel({ text = "[私聊] ", size = 24 })
			prefix:anch(0, 0.5):pos(xPos, cellSize.height / 2):addTo(cellNode)
			xPos = xPos + prefix:getContentSize().width

			local nameMenuItem = ui.newTTFLabelMenuItem({ text = string.format("[%s]", chat.from), tag = 1, size = 24, color = display.COLOR_GREEN,
				listener = function(tag)
					if self.curChannel ~= "private" then
						self.tableRadioGrp:chooseById(3)
					end

					self.curPrivateToName = chat.from
					self.curPrivateToRoleId = chat.fromRoleId
					self:createPrivateTab()
				end})
			nameMenuItem:anch(0, 0):pos(0, 0)
			local menu = ui.newMenu({ nameMenuItem })
			menu:size(nameMenuItem:getContentSize()):anch(0, 0.5):pos(xPos, cellSize.height / 2):addTo(cellNode)
			menu:setTouchPriority(self.priority)
			xPos = xPos + menu:getContentSize().width

			local toSelf = ui.newTTFLabel({ text = "对你说：", size = 24,})
			toSelf:anch(0, 0.5):pos(xPos, cellSize.height / 2):addTo(cellNode)
			xPos = xPos + toSelf:getContentSize().width

			ui.newTTFLabel({ text = chat.chatMsg, size = 24 }):anch(0, 0.5):pos(xPos, cellSize.height / 2):addTo(cellNode)
		end
	end

	-- 分隔线
	display.newSprite( ChatRes .. "line.png"):anch(0.5,0):pos(cellSize.width/2-10,0):addTo(cellNode)
end

function ChatLayer:createWorldTab()
	self.curChannel = "world"
	self:createWorldUILayer()
	self.chatTable:reloadData()
	self.chatTable:setContentOffset(self.chatTable:maxContainerOffset(), false)
end

function ChatLayer:createunionTab()
	self.curChannel = "union"
	self:createunionUILayer()
	self.chatTable:reloadData()
end

function ChatLayer:createPrivateTab()
	self.curChannel = "private"
	self:createPrivateUILayer()
	self.chatTable:reloadData()

	if self.hasNewPrivate and self.newIcon then
		self.hasNewPrivate = false
		self.newIcon:removeSelf()
		self.newIcon = nil
	end
end

-- 世界聊天
function ChatLayer:createWorldUILayer()
	if self.chatUILayer then
		self.chatUILayer:removeSelf()
	end

	local contentSize = self.contentLayer:getContentSize()
	self.chatUILayer = display.newLayer()
	self.chatUILayer:size(contentSize):addTo(self.contentLayer)

	display.newSprite(ChatRes.."inputBg.png"):anch(0,0):pos(30,17):addTo(self.chatUILayer)

	self:performWithDelay(function()
		self.chatWorldInputBox = ui.newEditBox({
			image = LoginRes .. "input_null.png",
			size = CCSize(572, 35),
			listener = function(event, editbox)
				if event == "began" then
				elseif event == "ended" then
				elseif event == "return" then
				elseif event == "changed" then
				end
			end
		})
		CCDirector:sharedDirector():getRunningScene():setTouchPriority(self.priority - 1)

		self.chatWorldInputBox:setReturnType(kKeyboardReturnTypeDefault)
		self.chatWorldInputBox:setFontColor(display.COLOR_BLACK)
		self.chatWorldInputBox:setMaxLength(30)
		self.chatWorldInputBox:setFontSize(18)
		-- self.chatWorldInputBox:setInputMode(EditBoxInputMode.kEditBoxInputModeSingleLine)
		
		self.chatWorldInputBox:setTouchPriority(self.priority - 10)
		-- self.chatWorldInputBox:setPlaceHolder("请输入")
		self.chatWorldInputBox:anch(0, 0):pos(45, 32):addTo(self.chatUILayer)
	end, 0.1)
end

-- 公会聊天
function ChatLayer:createunionUILayer()

end

-- 私聊
function ChatLayer:createPrivateUILayer()
	if self.chatUILayer then
		self.chatUILayer:removeSelf()
	end

	local contentSize = self.contentLayer:getContentSize()
	self.chatUILayer = display.newLayer()
	self.chatUILayer:size(contentSize):addTo(self.contentLayer)

	self.privateToLabel = ui.newTTFLabel({ text = string.format("对 %s", self.curPrivateToName), size = 26, color = display.COLOR_BLACK})
	:pos(80, contentSize.height - 570):addTo(self.chatUILayer)

	self.chatPrivateInputBox = ui.newEditBox({
		image = ChatRes .. "text_bg.png", size = CCSize(513, 61),
		listener = function(event, editbox)
			if event == "began" then
			elseif event == "ended" then
			elseif event == "return" then
			elseif event == "changed" then
			end
		end
	})
	self.chatPrivateInputBox:setReturnType(kKeyboardReturnTypeDefault)
	self.chatPrivateInputBox:setFontColor(display.COLOR_BLACK)
	self.chatPrivateInputBox:anch(0, 0):pos(228, contentSize.height - 604):addTo(self.chatUILayer)
end

function ChatLayer:onUpdateChat(event)

	if event.msg.err == 0 then
		self:prepareChats()
		self.chatTable:reloadData()
		-- self.chatTable:setBounceable(false)
		self.chatTable:setContentOffset(self.chatTable:maxContainerOffset(), false)
		-- self.chatTable:setBounceable(true)
		self:refreshFreeNum()
		if event.msg.player.name == game.role.name then
			self.chatWorldInputBox:setText("")
		end
		
	elseif event.msg.err == SYS_ERR_CHAT_ILL_WORD then
		DGMsgBox.new({ type = 1, text = "你所发送的消息包含屏蔽信息,无法发送!" })
	elseif event.msg.err == SYS_ERR_CHAT_LVL_LIMIT then
		DGMsgBox.new({ type = 1, text = tonum(globalCsv:getFieldValue("chatLevelLimit")).."级才开放聊天功能!" })
	elseif event.msg.err == SYS_ERR_CHAT_W_CNT_LIMIT then
		DGMsgBox.new({ type = 1, text = "免费次数已用完!" })
	elseif event.msg.err == SYS_ERR_CHAT_SILENT then
		DGMsgBox.new({ type = 1, text = "您已被禁言!" })
	elseif event.msg.err == SYS_ERR_CHAT_TOO_FAST then
		DGMsgBox.new({ type = 1, text = "你说话太快了，歇一歇吧!" })
	end
	
	-- local chat = event.msg
	-- if chat.chatType == 3 and self.curChannel ~= "private" and chat.fromRoleId ~= game.role.id then
	-- 	self.hasNewPrivate = true

	-- 	self.newIcon = display.newSprite( ChatRes .. "tip.png" )
	-- 	self.newIcon:anch(0,0):pos(933, self.contentLayer:getContentSize().height - 316 ):addTo(self.contentLayer, 1)
	-- end
end

function ChatLayer:onExit()
	game.role:removeEventListener("updateChat", self.updateChatHandler)
end

return ChatLayer