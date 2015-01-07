local ShopRes = "resource/ui_rc/shop/"
local DrawCardRes = "resource/ui_rc/shop/drawcard/"

local CardResMap = {
	[1] = "drawcard/card_1.png",
	[2] = "drawcard/card_2.png",
	[3] = "drawcard/card_3.png",
	[4] = "drawcard/card_4.png",

}

local DrawCardResultLayer = import(".DrawCardResultLayer")

local DrawCardLayer = class("DrawCardLayer", function()
	return display.newLayer()
end)

function DrawCardLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -129
	self.size = params.size	or CCSizeMake(820, 470)
	self:setContentSize(self.size)
	self.initPageIndex = params.initPageIndex or 1
	self.curClickIndex = 1
	self.closeBtn = params.closeBtn
	self.isfirstDraw = game.role.isfirstDraw or 1

	self.openedCards = storeCsv:getOpenedItems(1)
	local pageCount = math.ceil(#self.openedCards / 4)
	
	self.scrollView = DGPageView.new({
		priority = self.priority - 1,
		size = CCSizeMake(self.size.width - 20, self.size.height),
		initPageIndex = self.initPageIndex,
		lastPageIndex = pageCount,
		cellAtIndex = function(index) 
			return self:createCellIndex(index)
		end
	})
	self.scrollView:getLayer():anch(0.5, 0):pos(self.size.width / 2, 40):addTo(self)

	if pageCount > 1 then
		local leftArrowBtn = DGBtn:new(ShopRes, {"drawcard/arrow_left.png"},
			{	
				priority = self.priority - 20,
				scale = 0.9,
				callback = function()
					if self.scrollView:getCurPageIndex() == 1 then return end

					if not self.scrollView.isScroll then
						self.scrollView:autoScroll(0)
					end
				end,
			})
		leftArrowBtn:getLayer():anch(0, 0.5):pos(5, self.size.height / 2 + 30):addTo(self)

		local rightArrowBtn = DGBtn:new(ShopRes, {"drawcard/arrow_right.png"},
			{	
				priority = self.priority - 20,
				scale = 0.9,
				callback = function()
					if self.scrollView:getCurPageIndex() == pageCount then return end

					if not self.scrollView.isScroll then
						self.scrollView:autoScroll(1)
					end		
				end,
			})
		rightArrowBtn:getLayer():anch(1, 0.5):pos(self.size.width - 5, self.size.height / 2 + 30):addTo(self)

		-- page index tips
		local xBegin = self.size.width / 2 - (pageCount - 1) * 40 / 2
		for index = 1, pageCount do
			display.newSprite(ShopRes .. "drawcard/page_control_bg.png")
				:pos(xBegin + (index - 1) * 40, 30):addTo(self)
		end
		local tipsNode = display.newSprite(ShopRes .. "drawcard/page_control.png")
		tipsNode:pos(xBegin + (self.initPageIndex - 1) * 40, 30):addTo(self)

		self.scrollView:addEventListener("changePageIndex", function(event)
			tipsNode:moveTo(0.2, xBegin + (event.pageIndex - 1) * 40, 30)
		end)
	end

	
end

function DrawCardLayer:onEnter()
	self:checkGuide()
end

function DrawCardLayer:createCardNode(storeItem)
	local function sendBuyCardRequest(btn)
		local buyRequest
		if game.role.guideStep == 3 or game.role.guideStep == 4 then
			buyRequest = { roleId = game.role.id, packageId = storeItem.id, drawCard = 1, guide = 1}
		else
			buyRequest = { roleId = game.role.id, packageId = storeItem.id, drawCard = 1 }
		end
		self.curClickIndex = storeItem.id
			
		local bin = pb.encode("BuyCardPackageRequest", buyRequest)
		game:sendData(actionCodes.StoreDrawCardRequest, bin, #bin)
		loadingShow()
		game:addEventListener(actionModules[actionCodes.StoreDrawCardResponse], function(event)
			loadingHide()
			game:dispatchEvent({name = "btnClicked", data = btn:getLayer()})
			local msg = pb.decode("BuyCardPackageResponse", event.data)
			if game.role.shopThreshold[self.curClickIndex] then 
				game.role.shopThreshold[self.curClickIndex] = msg.threshold
			end
			if msg.isfirstDraw == 1000 then
				self.isfirstDraw = 1
				game.role.isfirstDraw = 1
			end

			local awardItems = {}
			for _, pbItem in ipairs(msg.awardItems) do
				awardItems[#awardItems + 1] = {
		    		id = pbItem.id,
		    		itemId = pbItem.itemId,
		    		itemTypeId = pbItem.itemTypeId,
		    		num = pbItem.num,
		    		heroTrunFrag = pbItem.heroTrunFrag,
		    	}
			end
			
			if #awardItems == 0 then return end

			local resultLayer = DrawCardResultLayer.new({ awardItems = awardItems, 
				priority = self.priority - 10, parent = self, 
				index = self.curClickIndex })
			display.getRunningScene():addChild(resultLayer:getLayer())

			-- 刷新本页
			self.scrollView:refresh()

			game.role:dispatchEvent({ name = "notifyNewMessage", type = "freeDrawCard" })

			return "__REMOVE__"
		end)
	end

	local drawBtnRes
	if storeItem.id == 4 then
		drawBtnRes = (tonum(self.isfirstDraw) == 0) and ShopRes .. "drawcard/card_4_f.png" or ShopRes .. CardResMap[storeItem.id]
	else
		drawBtnRes = ShopRes .. CardResMap[storeItem.id]
	end
	local drawBtn = display.newSprite(drawBtnRes)
	local btnSize = drawBtn:getContentSize()

	local freeCount = storeItem.freeCount - (game.role["card" .. storeItem.id .. "DrawFreeCount"] or 0)

	local function getLeftTime()
		local leftTime = game.role["store" .. storeItem.id .. "LeftTime"]
		if leftTime and leftTime > 0 then
			leftTime = game.role["store" .. storeItem.id .. "StartTime"] + leftTime - game:nowTime()
		end

		if storeItem.freeCount == 1 then
			return leftTime
		elseif storeItem.freeCount > 1 and freeCount > 0 then
			return leftTime
		end

		return nil
	end

	local leftTime = getLeftTime()
	local upTextLabel
	if leftTime and leftTime > 0 then
		local hours, minutes, second = timeConvert(leftTime)
		local content
		if hours > 0 then
			content = string.format("[color=ff7ce810]%02d:%02d:%02d[/color] 后免费", hours, minutes, second)
		else
			content = string.format("[color=ff7ce810]%02d:%02d[/color] 后免费", minutes, second)
		end
		upTextLabel = ui.newTTFRichLabel({ text = content, size = 18 })
		upTextLabel:pos(btnSize.width / 2, 97):addTo(drawBtn)
	elseif storeItem.dailyBuyLimit ~= math.huge then
		local limitText = string.format("每日限购%d次", storeItem.dailyBuyLimit)
		upTextLabel = ui.newTTFRichLabel({ text = limitText, size = 18, color = display.COLOR_RED })
		upTextLabel:pos(btnSize.width / 2,  97):addTo(drawBtn)	
	elseif ( not (leftTime and leftTime > 0) and freeCount > 0 )then
		upTextLabel = ui.newTTFRichLabel({ text = string.format("本日可免费抽 %d 次", freeCount), size = 18 })
		upTextLabel:pos(btnSize.width / 2, 97):addTo(drawBtn)
	elseif storeItem.freeCd > 0 then
		upTextLabel = ui.newTTFRichLabel({ text = string.format("本日可免费抽 %d 次", freeCount), size = 18 })
		upTextLabel:pos(btnSize.width / 2,  97):addTo(drawBtn)	
	
	end

	local thresholdLable
	local offsetX={[1]=97,[3]=97}
	if storeItem.id == 1 or storeItem.id == 3 then
		thresholdLable=ui.newTTFLabelWithShadow({align=display.CENTER,text=game.role.shopThreshold[storeItem.id],size=34,color=uihelper.hex2rgb("#00ffc2")
			,strokeSize=2,strokeColor=uihelper.hex2rgb("#023831"),font=ChineseFont }):pos(offsetX[storeItem.id],163):addTo(drawBtn)
		thresholdLable:setSkewX(10)
	end

	local buyBtn
	buyBtn = DGBtn:new(DrawCardRes, {"drawBtn_normal.png", "drawBtn_pressed.png"},
		{	
			priority = self.priority - 1,
			notSendClickEvent = true,
			callback = function()
				sendBuyCardRequest(buyBtn)
			end,
		})
	buyBtn:getLayer():anch(0.5, 0):pos(btnSize.width / 2, 20):addTo(drawBtn)
	local buyBtnSize = buyBtn:getLayer():getContentSize()
	table.insert(self.guideBtns, buyBtn:getLayer())


	if leftTime and leftTime <= 0 and freeCount > 0 then
		ui.newTTFLabelWithStroke({text = "免费", font = ChineseFont, size = 24, strokeColor = display.COLOR_FONT, strokeSize = 2 })
			:pos(buyBtnSize.width / 2, buyBtnSize.height / 2):addTo(buyBtn:getLayer(), 0, 1):setSkewX(10)
		uihelper.newMsgTag(buyBtn:getLayer(), ccp(-10, -10))
	else
		display.newSprite(GlobalRes .. (storeItem.yinbi > 0 and "yinbi_big.png" or "yuanbao.png"))
			:anch(0, 0.5):scale(0.8):pos(20, buyBtnSize.height / 2):addTo(buyBtn:getLayer(), 0, 2)
		ui.newTTFLabelWithStroke({ text = storeItem.yinbi > 0 and storeItem.yinbi or storeItem.yuanbao, font = ChineseFont, size = 24, color = display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2})
			:anch(0, 0.5):pos(buyBtnSize.width / 2 - 12, buyBtnSize.height / 2):addTo(buyBtn:getLayer(), 0, 3):setSkewX(10)
	end

	-- CD 倒计时
	if leftTime and leftTime > 0 then
		local setCdTime
		setCdTime = function()
			if leftTime > 0 then
				leftTime = leftTime - 1

				local hours, minutes, second = timeConvert(leftTime)
				local content
				if hours > 0 then
					content = string.format("[color=ff7ce810]%02d:%02d:%02d 后免费[/color]", hours, minutes, second)
				else
					content = string.format("[color=ff7ce810]%02d:%02d[/color] 后免费", minutes, second)
				end
				upTextLabel:setString(content)
				upTextLabel:runAction(transition.sequence({
					CCDelayTime:create(1),
					CCCallFunc:create(setCdTime),
				}))
			elseif leftTime == 0 then
				upTextLabel:setString("免费")
				self.scrollView:refresh()
			end
		end
		setCdTime()		
	end

	return drawBtn
end


function DrawCardLayer:checkGuide(remove)
	game:addGuideNode({node = self.guideBtns[1], remove = remove, 
		guideIds = {1012, }
	})

	game:addGuideNode({node = self.guideBtns[3], remove = remove,
		guideIds = {1014, }
	})

	game:addGuideNode({node = self.closeBtn, remove = remove,
		guideIds = {904, }
	})
end

function DrawCardLayer:refreshThreshold()
	self.scrollView:refresh()
	self:checkGuide()
end

function DrawCardLayer:onExit()
	self:checkGuide(true)
end

function DrawCardLayer:createCellIndex(index)
	local cellNode = display.newNode()
	local cellSize = CCSizeMake(self.size.width - 20, self.size.height)

	local xBegin = 30
	local xInterval = (self.size.width - 20 - 2 * xBegin - 4 * 173) / 3

	self.guideBtns = {}
	for cardIndex = 4 * (index - 1) + 1, math.min(4 * index, #self.openedCards) do
		local cardNode = self:createCardNode(self.openedCards[cardIndex])
		local nativeIndex = cardIndex - 4 * (index - 1)
		cardNode:anch(0, 0):pos(xBegin + (nativeIndex - 1) * (173 + xInterval), 0):addTo(cellNode)
	end
	self:checkGuide()
	return cellNode
end

return DrawCardLayer