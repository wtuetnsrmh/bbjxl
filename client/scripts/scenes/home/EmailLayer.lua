local GlobalRes = "resource/ui_rc/global/"
local EmailRes = "resource/ui_rc/mail/"
local HeroRes = "resource/ui_rc/hero/"
local FriendRes = "resource/ui_rc/friend/"
local BeautyRes = "resource/ui_rc/beauty/"

local EmailLayer = class("EmailLayer", function()
	return display.newLayer()
end)

function EmailLayer:ctor(params)
	params = params or {}

	self.size = CCSizeMake(960, 532)
	self.priority = params.priority or -130

	self:setContentSize(self.size)
	self:anch(0.5, 0):pos(display.cx, 0)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1 })
	self.closeCB = params.closeCB

	self:initTabBtns()

	-- pushLayerAction(self,true)
end

function EmailLayer:initTabBtns()
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end

	self.mainLayer = display.newLayer(GlobalRes .. "inner_bg.png")
	self.mainLayer:pos(0, 0):addTo(self)
	self.size = self.mainLayer:getContentSize()

	-- 关闭按钮
	if self.closeBtn then
		self.closeBtn:removeSelf()
	end 

	self.closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"}, 
		{
			touchScale = 1.5,
			priority = self.priority,
			callback = function()		
				self:getLayer():removeSelf()
				if self.closeCB then self.closeCB() end
			end,
		}):getLayer()
	self.closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self)

	display.newSprite(GlobalRes .. "inner_bg.png")
	:pos(self.mainLayer:getContentSize().width/2,self.mainLayer:getContentSize().height/2)
	:addTo(self.mainLayer)

	--指向标：
	local arrowSp = display.newSprite(GlobalRes.."tab_arrow.png"):anch(1,0.5):pos(self.mainLayer:getContentSize().width,470)
	:addTo(self.mainLayer)

	local tabData = {
		[1] = { showName = "邮件", callback = function()
			arrowSp:pos(self.mainLayer:getContentSize().width, 470)
			-- email request
			local bin = pb.encode("SimpleEvent", { roleId = game.role.id })
			game:sendData(actionCodes.EmailListRequest, bin)
			loadingShow()
			game:addEventListener(actionModules[actionCodes.EmailListResponse], function(event)
				loadingHide()
				local msg = pb.decode("EmailList", event.data)
				self:listSysMail(msg.emails)

				return "__REMOVE__"
			end)
		end },
		[2] = { showName = "战报", callback = function() 
			arrowSp:pos(self.mainLayer:getContentSize().width, 370)
			local bin = pb.encode("SimpleEvent", { roleId = game.role.id })
			game:sendData(actionCodes.PvpBattleReportRequest, bin)
			loadingShow()
			game:addEventListener(actionModules[actionCodes.PvpBattleReportResponse], function(event)
				loadingHide()
				local msg = pb.decode("BattleReportList", event.data)
				self:listPvpReport(msg.reports)

				return "__REMOVE__"
			end)
		end },
	}

	self.scrollSize = CCSizeMake(self.size.width, self.size.height - 80)

	-- tab按钮
	local tabRadioGrp = DGRadioGroup:new()
	local startY = 420
	local offset = 101
	for index = 1, #tabData do
		local tabBtn = DGBtn:new(GlobalRes, { "tab_normal.png", "tab_selected.png" },
			{	
				id = index,
				priority = self.priority,
				callback = tabData[index].callback
			}, tabRadioGrp)
		tabBtn:getLayer():pos(self.size.width - 14, startY - (index - 1) * offset):addTo(self.mainLayer,-1)
		local tabSize = tabBtn:getLayer():getContentSize()
		ui.newTTFLabelWithStroke({ text = tabData[index].showName, dimensions = CCSizeMake(tabSize.width / 2, tabSize.height), size = 26, font = ChineseFont,
			color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
			:pos(tabSize.width / 2, tabSize.height / 2):addTo(tabBtn:getLayer(), 10)

		-- display.newSprite(EmailRes..tabData[index].showName):anch(0.5,0.5)
		-- :pos(tabBtn:getLayer():getContentSize().width/2 - 5,tabBtn:getLayer():getContentSize().height/2)
		-- :addTo(tabBtn:getLayer())
	end
	tabRadioGrp:chooseById(1, true)
end

--系统邮件：
function EmailLayer:listSysMail(mails)
	if self.scrollView then 
		self.scrollView:getLayer():removeSelf()
		self.scrollView = nil
	end

	self.layer = "sysMail"

	local function createEmailItem(item)
		local cellBtn = DGBtn:new(FriendRes, { "friend_cell_bg.png" }, 
			{	
				priority = self.priority,
				parent = self.scrollView:getLayer(),
				callback = function()
					if item.status == 0 then
						-- email request
						local bin = pb.encode("SimpleEvent", { roleId = game.role.id, param1 = item.id })
						game:sendData(actionCodes.EmailCheckRequest, bin)
						game:addEventListener(actionModules[actionCodes.EmailCheckResponse], function(event)
							local msg = pb.decode("SimpleEvent", event.data)
							item.status = msg.param1

							if self.scrollView then 
								self.scrollView:getLayer():removeSelf()
								self.scrollView = nil
							end

							-- 刷新红点
							game.role:dispatchEvent({ name = "notifyNewMessage", type = "email" })

							return "__REMOVE__"
						end)
					end
					self.scrollOffset = self.scrollView:getOffset()
					if self.scrollView then 
						self.scrollView:getLayer():removeSelf()
						self.scrollView = nil
					end
					self:showMailContent(item)
				end,
			}):getLayer()
		local cellSize = cellBtn:getContentSize()

		local attachments = string.toTableArray(item.attachments)

		local statusRes = item.status == 0 and "unread.png" or "read.png"
		display.newSprite(EmailRes .. statusRes):anch(0, 0.5):pos(30, cellSize.height / 2):addTo(cellBtn)
		-- 存在附件, 并没有提取
		if #attachments > 0 and item.status ~= 2 then
			display.newSprite(EmailRes .. "attachment.png")
				:anch(1, 1):pos(cellSize.width - 10, cellSize.height):addTo(cellBtn)
		end

		local cellTitleBg=display.newSprite(GlobalRes .. "label_long_bg.png"):anch(0,0.5):pos(150,cellSize.height/2):addTo(cellBtn)

		ui.newTTFLabel({text = item.title,size = 26,color = uihelper.hex2rgb("#ffd200")})
		:anch(0.5,0.5)
		:pos(cellTitleBg:getContentSize().width/2, cellTitleBg:getContentSize().height/2)
		:addTo(cellTitleBg)

		ui.newTTFLabel({text = os.date("%Y/%m/%d %H:%M", item.createtime),size = 20,color = uihelper.hex2rgb("#533a27")})
		:anch(1,0.5)
		:pos(cellSize.width-80, cellSize.height / 2)
		:addTo(cellBtn)


		return cellBtn
	end

	self.scrollView = DGScrollView:new({ priority = self.priority - 1, size = self.scrollSize, divider = 5,
		dataSource = mails,
		size = CCSizeMake(self.size.width, 500), 
		cellAtIndex = function(item)
			return createEmailItem(item)
		end
	})

	self.scrollView:reloadData()
	self.scrollView:setOffset(self.scrollOffset or 0)
	self.scrollView:getLayer():anch(0, 1):pos(5, self.size.height - 55)
		:addTo(self.mainLayer)
end

--邮件详情：
function EmailLayer:showMailContent(emailInfo)
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end

	self.layer = "emailContent"

	self.mainLayer = display.newLayer(GlobalRes .. "middle_popup.png")
	:anch(0.5,0.5):pos(display.cx, display.cy):addTo(self:getLayer())
	display.newSprite(EmailRes.."unread.png"):pos(35,491):addTo(self.mainLayer)
	display.newSprite(EmailRes .. "content_down.png"):anch(0.5,0):pos(self.mainLayer:getContentSize().width/2, 25):addTo(self.mainLayer)
	display.newSprite(EmailRes .. "content_up.png"):anch(0.5,0):pos(self.mainLayer:getContentSize().width/2, 155):addTo(self.mainLayer)

	if self.closeBtn then
		self.closeBtn:removeSelf()
		self.closeBtn = nil
	end

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"}, 
		{
			touchScale = 1.5,
			priority = self.priority,
			callback = function()	
				self:initTabBtns()	
			end,
		}):getLayer()
	local size = self.mainLayer:getContentSize()
	closeBtn:anch(0.5, 0.5):pos(size.width, size.height):addTo(self.mainLayer)

	local topBg = display.newSprite(GlobalRes .. "title_bar_long.png")
	topBg:anch(0.5,1):pos(self.mainLayer:getContentSize().width/2, self.size.height - 74):addTo(self.mainLayer)

	ui.newTTFLabelWithStroke({ text = emailInfo.title, size = 38,color=uihelper.hex2rgb("#fde335"),strokeColor=display.COLOR_BUTTON_STROKE }):addTo(topBg)
		:pos(topBg:getContentSize().width / 2, topBg:getContentSize().height / 2)

	local showSize = CCSizeMake(702, 285)

	local contentScroll = CCScrollView:create()
    local function scrollView1DidScroll()
    end
    local function scrollView1DidZoom()
    end
    contentScroll:setViewSize(showSize)
	local contentLabel = ui.newTTFRichLabel({text = emailInfo.content, size = 22, dimensions = showSize,})
    contentScroll:setContainer(contentLabel)
    contentScroll:updateInset()
    contentScroll:setContentOffset(ccp(0, showSize.height - contentLabel:getContentSize().height))
    contentScroll:setDirection(kCCScrollViewDirectionVertical)
    contentScroll:setClippingToBounds(true)
    contentScroll:setTouchPriority(self.priority - 1)
    contentScroll:registerScriptHandler(scrollView1DidScroll,CCScrollView.kScrollViewScroll)
    contentScroll:registerScriptHandler(scrollView1DidZoom,CCScrollView.kScrollViewZoom)
    contentScroll:setPosition(ccp((self.mainLayer:getContentSize().width - showSize.width) / 2+5 ,160))
	self.mainLayer:addChild(contentScroll)

	local attachments = string.toTableArray(emailInfo.attachments)
	if #attachments == 0 then return end

	local attachBg
	local function initAttachmentLayer()
		if attachBg then attachBg:removeSelf() end

		attachBg = display.newNode():anch(0.5,0.5):size(self.size.width-250,80):pos(self.mainLayer:getContentSize().width/2,80):addTo(self.mainLayer)
		local attachSize = attachBg:getContentSize()

		local xPos, xInterval = -10, 10
		local containHero = false
		for index, attachment in ipairs(attachments) do
			local itemId = tonum(attachment[1])
			local num = tonum(attachment[2])

			local itemData = itemCsv:getItemById(itemId)
			if (itemData.type == ItemTypeId.Hero) 
				and not containHero then
				containHero = true
			end

			local frame, frameSize
			
			if emailInfo.status == 2 then
				frame = ItemIcon.new({ itemId = itemId, color = ccc3(100, 100, 100), priority = self.priority -1, callback = function()
					display.getRunningScene():removeChildByTag(1000)
					local itemTipsView = require("scenes.home.ItemTipsLayer")
					local itemTips = itemTipsView.new({ itemId = itemId, itemNum= num, priority = self.priority - 10 })
					display.getRunningScene():addChild(itemTips:getLayer(), 0, 1000)
					itemTips:getLayer():runAction(transition.sequence({
							CCDelayTime:create(2),
							CCRemoveSelf:create()
						}))
				end }):getLayer()
				frameSize = frame:getContentSize()
			else
				frame = ItemIcon.new({ itemId = itemId ,priority = self.priority -1, callback = function()
						display.getRunningScene():removeChildByTag(1000)
						local itemTipsView = require("scenes.home.ItemTipsLayer")
						local itemTips = itemTipsView.new({ itemId = itemId, itemNum= num, priority = self.priority - 10 })
						display.getRunningScene():addChild(itemTips:getLayer(), 0, 1000)
						itemTips:getLayer():runAction(transition.sequence({
								CCDelayTime:create(2),
								CCRemoveSelf:create()
							}))
					end}):getLayer()
				frameSize = frame:getContentSize()

			end

			ui.newTTFLabelWithStroke({ text = "X " .. num, size = 24,strokeColor=uihelper.hex2rgb("#242424") }):addTo(frame)
				:anch(1, 0):pos(frameSize.width - 5, 0)
			frame:anch(0, 0.5):pos(xPos + (index - 1) * (frameSize.width + xInterval), attachSize.height / 2+5):addTo(attachBg)
		end

		local recvBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png", "middle_disabled.png"},
			{	
				text = { text = emailInfo.status ~= 2 and "领取" or "已领取", size = 26, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
				priority = self.priority,
				callback = function()
					-- 武将碎片背包已满
					if containHero and game.role:isHeroBagFull() then
						DGMsgBox.new({ msgId = 111 })
						return
					end

					-- email request
					local bin = pb.encode("SimpleEvent", { roleId = game.role.id, param1 = emailInfo.id })
					game:sendData(actionCodes.EmailRecvAttachmentRequest, bin)
					game:addEventListener(actionModules[actionCodes.EmailRecvAttachmentResponse], function(event)
						local msg = pb.decode("SimpleEvent", event.data)
						emailInfo.status = msg.param1

						self:initTabBtns()	
						return "__REMOVE__"
					end)
				end,
			})
		recvBtn:getLayer():anch(1, 0.5):pos(attachSize.width+15, attachSize.height / 2+5):addTo(attachBg)
		recvBtn:setEnable(emailInfo.status ~= 2)
	end

	initAttachmentLayer()
end

--显示战报：
function EmailLayer:listPvpReport(pvpReports)
	if self.scrollView then 
		self.scrollView:getLayer():removeSelf()
		self.scrollView = nil
	end

	local function createPvpReport(battleReport)
		local itemLayer = display.newLayer(FriendRes.."friend_cell_bg.png")
		itemLayer:anch(0,0)
		local itemSize = itemLayer:getContentSize()

		local decBg=display.newSprite(EmailRes.."bg_content.png"):anch(0,0):pos(23,16):addTo(itemLayer)

		ui.newTTFLabel({ text = os.date("%Y/%m/%d %H:%M", battleReport.createTime), size = 20, color = uihelper.hex2rgb("#533a27")})
			:anch(0, 0):pos(333, 88):addTo(itemLayer)

		-- 1. 防守成功
		-- 2. 防守失败
		-- 3. 进攻成功
		-- 4. 进攻失败
		local result, text
		local attack = game.role.id == battleReport.roleId
		if attack then
			if battleReport.deltaRank == 0 then -- 进攻失败
				result = 4
			elseif battleReport.deltaRank < 0 then
				result = 5
			else
				result = 3
			end
		else
			if battleReport.deltaRank == 0 then
				result = 1
			elseif battleReport.deltaRank > 0 then
				result = 2
			else
				result = 6
			end
		end

		local resultText = {
			[1] = { 
				content = "[color=FFFFFFFF][color=FFFFD200][%s][/color]在竞技场挑战[color=FFFFD200]你[/color]，你战胜了他，守住了排名[/color]", 
				label = "label_1.png",
				btnText = "固若金汤",
				titleBg="titel_bg_1.png",
			},
			[2] = { 
				content = "[color=FFFFFFFF][color=FFFFD200][%s][/color]在竞技场挑战[color=FFFFD200]你[/color]，你战败了，排名下降 [color=FFE83410]%d[/color] 名[/color]",
				label = "label_2.png",
				btnText = "纸老虎",
				titleBg="titel_bg_2.png",
			},
			[3] = { 
				content = "[color=FFFFFFFF]你在战场挑战[color=FFFFD200][%s][/color]，你战胜了他，排名上升 [color=FFFFD200]%d[/color] 名，获得了 [color=FFFFD200]%d[/color] 战功[/color]", 
				label = "label_3.png",
				btnText = "势不可挡",
				titleBg="titel_bg_1.png",
			},
			[4] = { 
				content = "[color=FFFFFFFF][color=FFFFD200]你[/color]在战场挑战[color=FFFFD200][%s][/color]，你战败了，排名不变，获得了 [color=FFFFD200]%d[/color] 战功[/color]",
				label = "label_4.png",
				btnText = "无语",
				titleBg="titel_bg_1.png",
			},
			[5] = { 
				content = "[color=FFFFFFFF][color=FFFFD200]你[/color]在战场挑战[color=FFFFD200][%s][/color]，你战胜了他，排名不变，获得了 [color=FFFFD200]%d[/color] 战功[/color]",
				label = "label_3.png",
				btnText = "无语",
				titleBg="titel_bg_1.png",
			},
			[6] = { 
				content = "[color=FFFFFFFF][color=FFFFD200][%s][/color]在竞技场挑战[color=FFFFD200]你[/color]，你战败了，排名不变[/color]",
				label = "label_2.png",
				btnText = "无语",
				titleBg="titel_bg_1.png",
			},
		}

		local content
		if attack then
			if result == 3 then
				content = string.format(resultText[result].content, battleReport.opponentRoleName, battleReport.deltaRank, battleReport.zhangong)
			else
				content = string.format(resultText[result].content, battleReport.opponentRoleName, battleReport.zhangong)
			end
		else
			content = string.format(resultText[result].content, battleReport.roleName, battleReport.deltaRank)
		end
		ui.newTTFRichLabel({text = "[color=FF533B22]坚守时间越久，获得更多的经验卡[/color]", size = 20 })
		ui.newTTFRichLabel({ text = content, dimensions = CCSizeMake(516, itemSize.height - 40), size = 20})
			:anch(0, 0.5):pos(10, decBg:getContentSize().height/2):addTo(decBg)
		-- ui.newTTFLabel({ text = resultText[result].label, size = 24, color = display.COLOR_RED })
		-- 	:anch(1, 1):pos(self.size.width - 130, 115):addTo(itemLayer)
		local titleLabel=display.newSprite(EmailRes..resultText[result].label):anch(0,0):pos(25,87):addTo(itemLayer)

		-- local revengeBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png","middle_disabled.png"},
		-- 	{	
		-- 		text = { text = resultText[result].btnText, size = 28,font = ChineseFont, strokeColor = display.COLOR_FONT },
		-- 		callback = function()
		-- 		end,
		-- 	})
		-- revengeBtn:getLayer():anch(1, 0.5):pos(itemSize.width - 30, itemSize.height / 2 )
		-- 	:addTo(itemLayer)

		local revengeBg=display.newSprite(EmailRes..resultText[result].titleBg):anch(1,0.5)
		:pos(itemSize.width-10,itemSize.height/2):addTo(itemLayer)
		local revengeText=ui.newTTFLabelWithStroke({text=resultText[result].btnText,size=26,
			font=ChineseFont,color=uihelper.hex2rgb("#ffd200"),strokeColor=display.COLOR_BUTTON_STROKE })
		revengeText:pos(revengeBg:getContentSize().width/2,revengeBg:getContentSize().height/2):addTo(revengeBg)

		return itemLayer
	end

	self.scrollView = DGScrollView:new({ 
		priority = self.priority - 1, 
		size = CCSizeMake(self.size.width, 500), 
		divider = 5,
		dataSource = pvpReports,
		cellAtIndex = function(battleReport)
			return createPvpReport(battleReport)
		end
	})

	self.scrollView:reloadData()
	self.scrollView:getLayer():anch(0, 1):pos(5, self.size.height - 55)
		:addTo(self.mainLayer)
end

function EmailLayer:getLayer()
	return self.mask:getLayer()
end

function EmailLayer:onCleanup()
	display.removeUnusedSpriteFrames()
end

return EmailLayer