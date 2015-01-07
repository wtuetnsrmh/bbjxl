 -- 升级礼包奖励页面：
local GiftRes = "resource/ui_rc/gift/"
local ButRes  = "resource/ui_rc/global/"
local ShopRes  = "resource/ui_rc/shop/"
local HeroRes  = "resource/ui_rc/hero/"
local GlobalRes = "resource/ui_rc/global/"

local GiftMainLayer = class("GiftMainLayer", function() 
	return display.newLayer(GiftRes.."gift_frame.png") 
end)

local giftFlag = {
	levelUp = 1,
	newServer = 2,
	exchange = 3,
}

function GiftMainLayer:ctor(params)
	params = params or {}
	self.priority = params.priority or -129
	self.size = self:getContentSize()
	self.tipsTag = 7878
	self.curOffSetY = 0
	self.VScrollView = nil
	self.closeCallback = params.closeCallback
	self.curFlag = params.flag

	self.bg = display.newSprite(GiftRes .. "gift_bg.png")
		:anch(0.5, 1):pos(self.size.width/2, self.size.height - 66):addTo(self, -1)
	self.hasGuide = game.guideId == 1192
	self:setMaskLayer()
	self:initUIByData()

	if not self.hasGuide then
		pushLayerAction(self,true)
	end
end

function GiftMainLayer:onEnter()
	self:checkGuide()
end

function GiftMainLayer:checkGuide(remove)
	
	--领取
	game:addGuideNode({node = self.guideBtn, remove = remove,
		guideIds = {1192}
	})
	--关闭
	game:addGuideNode({rect = CCRectMake(display.cx + self.size.width/2 + 30, display.height/2, 130, 130), remove = remove,
		guideIds = {1194}
	})
	--领取确定按钮
	game:addGuideNode({node = self.sureBtn, remove = remove,
		guideIds = {1193}
	})
end

function GiftMainLayer:setMaskLayer()

	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1,ObjSize = self.size,
		click = function()
		end,
		clickOut = function()
			self:purgeItemTaps()
			self:removeAllChildren()
			if self.closeCallback then
				self.closeCallback()
			end
			self:getLayer():removeFromParent()
		end,})
end 

function GiftMainLayer:initUIByData()

	--文字：gift_title.png
	local wordSp = display.newSprite(GiftRes.."reward_title.png")
	wordSp:anch(0.5, 0.5):pos(self.size.width * 0.5, self.size.height - 56):addTo(self)

	self.tableLayer = display.newSprite(GiftRes .. "view_bg.png")
	self.tableLayer:anch(0.5, 0):pos(self.bg:getContentSize().width/2, 16):addTo(self.bg)
	self.tableSize = self.tableLayer:getContentSize()

	local tabData = {
		[1] = { 
			showName = {GiftRes .. "text_level_normal.png", GiftRes .. "text_level_selected.png"},
			tag = "levelGift",
			callback = function()
				self.giftDatas = table.values(levelGiftCsv:getAllData())
				self:refreshContent(giftFlag.levelUp) 
			end
		},
		[2] = { 
			showName = {GiftRes .. "text_sever_normal.png", GiftRes .. "text_sever_selected.png"}, 
			tag = "serverGift",
			callback = function() 
				self.giftDatas = table.values(newServerCsv:getAllData())
				self:refreshContent(giftFlag.newServer)
			end
		},
		[3] = { 
			showName = {GiftRes .. "text_exchange_normal.png", GiftRes .. "text_exchange_selected.png"}, 
			tag = "",
			callback = function() 
				self:refreshContent(giftFlag.exchange)
			end
		},
	}

	-- tab按钮
	local tableRadioGrp = DGRadioGroup:new()
	self.tag = {}
	for i = 1, #tabData do
		local tabBtn = DGBtn:new(GiftRes, { "tab_normal.png", "tab_selected.png" },
			{	
				id = i,
				front = tabData[i].showName,
				priority = self.priority -2,
				callback = tabData[i].callback
			}, tableRadioGrp)
		tabBtn:getLayer():anch(0.5, 0):pos(115 + 180 * (i - 1), self.tableLayer:getContentSize().height - 2)
			:addTo(self.tableLayer, 2)

		self.tag[i] = game.role:addEventListener("notifyNewMessage", function(event)
			if event.type == tabData[i].tag then
				tabBtn:getLayer():removeChildByTag(9999)
				if event.action == "add" then
					uihelper.newMsgTag(tabBtn:getLayer())
				end
			end
		end)
	end
	tableRadioGrp:chooseById(self.curFlag or 1, true)
end

function GiftMainLayer:refreshAwardTips()
	if self.awardTips then
		self.awardTips:removeSelf()
		self.awardTips = nil
	end

	if self.curFlag ~= giftFlag.newServer then return false end

	local firstDay, secondDay = 2, 2
	local loginDays = game.role.loginDays
	if loginDays > secondDay then return false end

	
	self.awardTips = display.newSprite(GiftRes .. "award_tips_bg.png")
	self.awardTips:anch(0.5, 1):pos(self.tableSize.width * 0.5, self.tableSize.height - 10):addTo(self.tableLayer)
		
	if loginDays <= firstDay and game.role.serverGifts[firstDay] ~= 1 then
		local tempNode = ui.newTTFLabelWithStroke({text = "登录两天，送", size = 24, font = ChineseFont, strokeColor = display.COLOR_FONT})
		tempNode:anch(0, 0.5):pos(150, self.awardTips:getContentSize().height/2):addTo(self.awardTips)
		ui.newTTFLabelWithStroke({text = "绝世美女-小乔！", size = 24, font = ChineseFont, color = uihelper.hex2rgb("#ffd200"), strokeColor = display.COLOR_FONT})
			:anch(0, 0):pos(tempNode:getContentSize().width, 0):addTo(tempNode)
	-- elseif loginDays <= secondDay and game.role.serverGifts[secondDay] ~= 1 then
		-- local tempNode = ui.newTTFLabelWithStroke({text = "登录七天，送", size = 24, font = ChineseFont, strokeColor = display.COLOR_FONT})
		-- tempNode:anch(0, 0.5):pos(150, self.awardTips:getContentSize().height/2):addTo(self.awardTips)
		-- ui.newTTFLabelWithStroke({text = "五星神将诸葛亮！", size = 24, font = ChineseFont, color = uihelper.hex2rgb("#ffd200"), strokeColor = display.COLOR_FONT})
		-- 	:anch(0, 0):pos(tempNode:getContentSize().width, 0):addTo(tempNode)
	else
		self.awardTips:removeSelf()
		self.awardTips = nil
		return false
	end

	return true
end 

function GiftMainLayer:refreshContent(flag)
	if self.tableView then
		self.tableView:removeSelf()
		self.tableView = nil
	end
	self.curFlag = flag

	local offset = 10
	offset = self:refreshAwardTips() and 52 or offset

	--兑换码页面
	if flag == giftFlag.exchange then
		self.tableView = display.newSprite(GiftRes .. "exchange_bg.png")
		self.tableView:anch(0.5, 0.5):pos(self.tableSize.width/2, self.tableSize.height/2):addTo(self.tableLayer)

		local inputBg = display.newSprite(GiftRes .. "input_bg.png")
		inputBg:anch(0.5, 0):pos(self.tableView:getContentSize().width/2, 108):addTo(self.tableView)

		local inputBox
		self:performWithDelay(function()
			inputBox = ui.newEditBox({
				image = "resource/ui_rc/login_rc/" .. "input_null.png",
				size = CCSize(460, 67),
				listener = function(event, editbox)
					if event == "began" then
					elseif event == "ended" then
					elseif event == "return" then
					elseif event == "changed" then
					end
				end
			})
			CCDirector:sharedDirector():getRunningScene():setTouchPriority(self.priority - 1)
			inputBox:setFontColor(uihelper.hex2rgb("#eee8ca"))
			inputBox:setFontSize(36)
			inputBox:setMaxLength(10)	
			inputBox:setReturnType(kKeyboardReturnTypeSend)
			inputBox:anch(0.5, 0.5):pos(inputBg:getContentSize().width/2, inputBg:getContentSize().height/2 - 5):addTo(inputBg)
		end, 0.2)

		DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png"}, {
			priority = self.priority - 1,
			text = {text = "确定", size = 26, font = ChineseFont, color = display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2 },
			callback = function()
				local bin = pb.encode("KeyValuePair", {key = string.upper(inputBox:getText())})
				game:sendData(actionCodes.RoleExchangeRequest, bin, #bin)
				game:addEventListener(actionModules[actionCodes.RoleExchangeResponse], function(event)
					local msg = pb.decode("SimpleEvent", event.data)
					if msg.param1 ~= 0 then
						local tips
						print(msg.param1) 
						if msg.param1 == 1 then
							tips = "无效的礼包码"
						elseif msg.param1 == 2 then
							tips = "你已领取过该类型的礼包"
						elseif msg.param1 == 3 then
							tips = "礼包码已被使用"
						elseif msg.param1 == 4 then
							tips = "只能领取对应渠道的礼包码"
						end
							
						DGMsgBox.new({text = tips, type = 1})
						return
					end

					local giftShow = require("scenes.activity.GiftShowLayer")
					local showView = giftShow.new({
						priority = self.priority - 10 , 
						items = {
							{itemId = msg.param2, itemCount = 1},
						},
					})
					showView:getLayer():addTo(display.getRunningScene())
				end)
			end
		}):getLayer():anch(0.5, 0):pos(self.tableView:getContentSize().width/2, 30):addTo(self.tableView)
		return
	end
	
	local handler = LuaEventHandler:create(function(fn, tbl, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self:getContentSize().width, 119) --cell size
        elseif fn == "cellAtIndex" then
			if not a2 then
                a2 = CCTableViewCell:new()
                local cell = display.newNode()
                a2:addChild(cell, 0, 1)
            end
            local cell = nil
            if a2:getChildByTag(1) then
            	cell = tolua.cast(a2:getChildByTag(1), "CCNode")
            	cell:removeAllChildren()
            end

            self:creatGiftCell(cell, a1, flag)
            r = a2
        elseif fn == "numberOfCells" then
            r = table.nums(self.giftDatas)
        end
        return r
    end)

	local viewSize = CCSizeMake(self.tableSize.width, self.tableSize.height - offset)
	self.tableView = CCNodeExtend.extend(LuaTableView:createWithHandler(handler, viewSize))
    self.tableView:setBounceable(true)
    self.tableView:setTouchPriority(self.priority - 2)
	self.tableLayer:addChild(self.tableView)

	-- 偏移
	local usedCount = 0
	local itemCount = #self.giftDatas
	if self.hasGuide then
		usedCount = 1
	else
	    for i=1, itemCount do
	    	local record = self.giftDatas[i]
	    	if flag == giftFlag.newServer then
		    	if game.role.serverGifts[record.day] == 1 then
					usedCount = usedCount + 1
				else
					break
				end
			else
				if game.role.levelGifts[tostring(record.level)] == 1 then
					usedCount = usedCount + 1
				else
					break
				end
			end
	    end
	end

    local offset = -119 * (itemCount - usedCount + 0.5) + viewSize.height
   	self.tableView:setBounceable(false)
	self.tableView:setContentOffset(ccp(0, offset), false)
	self.tableView:setBounceable(true)
	self.tableView:setTouchEnabled(not self.hasGuide)
end

function GiftMainLayer:creatGiftCell(parentNode, cellIndex, flag)
	parentNode:removeAllChildren()

	local record = self.giftDatas[#self.giftDatas - cellIndex]
	

	local cellsp = display.newSprite(GiftRes.."gift_sub_bg.png")
	cellsp:anch(0.5, 0):pos(self.tableSize.width/2, 0):addTo(parentNode)
	local ww = cellsp:getContentSize().width
	local hh = cellsp:getContentSize().height
		
	--领取button
	local used = false
	if flag == giftFlag.levelUp then
		used = game.role.levelGifts[tostring(record.level)] == 1
	elseif flag == giftFlag.newServer then
		used = game.role.serverGifts[record.day] == 1
	end

	if used then
		display.newSprite(GiftRes .. "get_state.png"):pos(ww - 82, hh * 0.5):addTo(cellsp)
	else
		if flag == giftFlag.levelUp then
			--达到n级别可领取：
			local needlevel = record.level
			local tempNode = ui.newTTFLabel({ text = needlevel, size = 20, color = uihelper.hex2rgb("#126cb8") })
			tempNode:anch(0, 0):pos(ww - 135, 76):addTo(cellsp)
			ui.newTTFLabel({ text = "级可领取", size = 20, color = uihelper.hex2rgb("#533a27") })
				:anch(0, 0):pos(tempNode:getContentSize().width, 0):addTo(tempNode)

			local useBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png","middle_disabled.png"}, 
			{
				text = {text = "领取", size = 26, font = ChineseFont, color = display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2 },
				parent = self.tableView,
				callback = function()
					self.curOffSetY  = self.tableView:getContentOffset().y
					local useRequest = { roleId = game.role.id, param1 = record.level }
					local bin = pb.encode("SimpleEvent", useRequest)

					game:sendData(actionCodes.RoleGetLevelGiftRequest, bin, #bin)
					game:addEventListener(actionModules[actionCodes.RoleGetLevelGiftResponse], function(event)
						self.tableView:reloadData()
						self.tableView:setContentOffset(ccp(0, self.curOffSetY), false)

						-- TODO 添加领取成功后的界面
						local giftShow = require("scenes.activity.GiftShowLayer")
						local showView = giftShow.new({ 
							priority = self.priority - 10 , 
							index = record.index,
							layertype = "levelup"
						})
						showView:getLayer():addTo(display.getRunningScene())
						self.sureBtn = showView:getSureBtn()
						self:checkGuide()

						game.role:dispatchEvent({ name = "notifyNewMessage", type = "levelGift" })
						
						return "__REMOVE__"
					end)
				end,
				priority = self.priority - 2
			})
			useBtn:getLayer():anch(0.5, 0):pos(ww - 82, 19):addTo(cellsp)
			useBtn:setEnable(game.role.level >= record.level and not used)
			useBtn:getLayer():setTag(999)
			if record.level == 8 then
				self.guideBtn = useBtn:getLayer()
			end
		elseif flag == giftFlag.newServer then
			local needlevel = record.level
			local tempNode = ui.newTTFLabel({ text = "登陆", size = 20, color = uihelper.hex2rgb("#533a27") })
			tempNode:anch(0, 0):pos(ww - 150, 76):addTo(cellsp)
			tempNode = ui.newTTFLabel({ text = record.day, size = 20, color = uihelper.hex2rgb("#126cb8") })
				:anch(0, 0):pos(tempNode:getContentSize().width, 0):addTo(tempNode)
			ui.newTTFLabel({ text = "天可领取", size = 20, color = uihelper.hex2rgb("#533a27") })
				:anch(0, 0):pos(tempNode:getContentSize().width, 0):addTo(tempNode)

			local useBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png","middle_disabled.png"}, 
			{
				text = {text = "领取", size = 26, font = ChineseFont, color = display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2 },
				parent = self.tableView,
				callback = function()
					self.curOffSetY  = self.tableView:getContentOffset().y
					local useRequest = { roleId = game.role.id, param1 = record.day }
					local bin = pb.encode("SimpleEvent", useRequest)

					game:sendData(actionCodes.RoleGetServerGiftRequest, bin, #bin)
					game:addEventListener(actionModules[actionCodes.RoleGetServerGiftResponse], function(event)
						local offset = self:refreshAwardTips() and 52 or 10
						self.tableView:size(self.tableSize.width, self.tableSize.height - offset)
						self.tableView:reloadData()
						self.tableView:setContentOffset(ccp(0, self.curOffSetY), false)
						-- TODO 添加领取成功后的界面
						local giftShow = require("scenes.activity.GiftShowLayer")
						local showView = giftShow.new({
							priority = self.priority - 10 , 
							index = record.day,
							layertype = "newserver"
						})
						showView:getLayer():addTo(display.getRunningScene())

						game.role:dispatchEvent({ name = "notifyNewMessage", type = "serverGift"})
						
						return "__REMOVE__"
					end)
				end,
				priority = self.priority - 2
			})
 	
			useBtn:getLayer():anch(0.5,0):pos(ww - 82, 19):addTo(cellsp)
			useBtn:getLayer():setTag(999)
			useBtn:setEnable(game.role.loginDays >= record.day)
		end
	end

	--头像初始化：
	local itemTable = record.itemtable
	local iconCount = table.nums(itemTable)
	for i=1, iconCount do
		if iconCount < 5 then
			local itemId     = itemTable[i].itemId
			local itemCount  = itemTable[i].itemCount
			local icon = self:getItemIcon(itemId, itemCount, 2)
			icon:scale(0.85):anch(0.5, 0.5):pos(65 + (i - 1) * 95, hh * 0.5):addTo(cellsp)
		end
	end
end

--头像subview
function GiftMainLayer:getItemIcon(itemId,itemCount,itemType)
	local iData = nil
	local haveNum
	local xx = self.size.width * 0.25
	local yy = self.size.height * 0.81

	iData = itemCsv:getItemById(tonumber(itemId))
	local frame = ItemIcon.new({ itemId = tonumber(itemId),
		parent = self.tableLayer, 
		priority = self.priority -1,
		callback = function()
			self:showItemTaps(itemId,itemCount,iData.type)
		end,
	}):getLayer()
	frame:setColor(ccc3(100, 100, 100))

	--数量
	local isHero = iData.type == ItemTypeId.Hero
	ui.newTTFLabel({ text = "x"..itemCount, size = 20, color = display.COLOR_GREEN })
		:anch(1, 0):pos(frame:getContentSize().width - (isHero and 14 or 5), isHero and 14 or 5)
		:addTo(frame)

	return frame
end 

function GiftMainLayer:showItemTaps(itemId,itemNum,itemType)
	self:purgeItemTaps()
	local itemTipsView = require("scenes.home.ItemTipsLayer")
	local itemTips = itemTipsView.new({ itemId = itemId, itemNum = itemNum, itemType = itemType })
	display.getRunningScene():addChild(itemTips:getLayer())
	itemTips:setTag(self.tipsTag)
end

function GiftMainLayer:purgeItemTaps()
	if display.getRunningScene():getChildByTag(self.tipsTag) then
		display.getRunningScene():getChildByTag(self.tipsTag):removeFromParent()
	end
end


function GiftMainLayer:getLayer()
	return self.mask:getLayer()
end

function GiftMainLayer:onExit()
	self:checkGuide(true)
end

function GiftMainLayer:onCleanup()
	for index = 1, #self.tag do
		game.role:removeEventListener("notifyNewMessage", self.tag[index])
	end
end


return GiftMainLayer