-- pvp战场商店
-- revised by yangkun
-- 2014.7.2

local GlobalRes = "resource/ui_rc/global/"
local ExpeditonRes = "resource/ui_rc/expedition/"
local ShopRes = "resource/ui_rc/store/"
local PvpRes = "resource/ui_rc/pvp/"
local HeroRes = "resource/ui_rc/hero/"
local DrawCardRes = "resource/ui_rc/shop/drawcard/"
local TowerRes = "resource/ui_rc/activity/tower/"

local BuyItemTipsLayer = import("..BuyItemTipsLayer")

local PvpShopLayer = class("PvpShopLayer", function()
	return display.newLayer(GlobalRes .. "middle_popup.png")
end)

local mapTables = {
	[5] = {title = PvpRes .. "title_pvp_shop.png", icon = PvpRes .. "zhangong.png", valueName = "zhangongNum", eventName = "updateZhangongNum"},
	[6] = {title = ExpeditonRes .. "title_reputation_shop.png", icon = ExpeditonRes .. "prestige.png", valueName = "reputation", eventName = "updateReputation"},
	[7] = {title = TowerRes .. "shop_title.png", icon = GlobalRes .. "starsoul.png", valueName = "starSoulNum", eventName = "updateStarSoulNum"}
}

function PvpShopLayer:ctor(params)
	params = params or {}
	self.priority = params.priority or -130
	self.closeCallback = params.closeCallback
	self.shopIndex = params.shopIndex
	self.size = self:getContentSize()

	-- 遮罩层
	self:anch(0.5, 0.5):pos(display.cx, display.cy)

	self.mask = DGMask:new({ item = self, priority = self.priority + 1,ObjSize=self:getContentSize(), opacity = params.opacity,
		clickOut=function()
			self:getLayer():removeSelf()
			if self.closeCallback then self.closeCallback() end
		end
	 })

	local bin = pb.encode("SimpleEvent", { roleId = game.role.id, param1 = self.shopIndex, param2 = self.shopIndex })
	game:sendData(actionCodes.RoleShopRequest, bin)
	showMaskLayer()
	game:addEventListener(actionModules[actionCodes.RoleShopResponse], function(event)
		hideMaskLayer()
		local msg = pb.decode("RoleShopDataResponse", event.data)

		local now = game:nowTime()
		self.shopDatas = {}
		local shopData = msg.shopDatas[1]
		self.shopDatas = {
			shopItems = json.decode(shopData.shopItemsJson),
			refreshLeftTime = shopData.refreshLeftTime,
			checkPoint = now,
		}
		self:initUI()
	end)


end

function PvpShopLayer:initUI()
	local titlebg = display.newSprite(GlobalRes .. "title_bar.png")
		:pos(self.size.width/2, self.size.height - 35):addTo(self)
	display.newSprite(mapTables[self.shopIndex].title)
	:anch(0.5,0.5):pos(self.size.width / 2, self.size.height - 35):addTo(self)

	local xBegin = 10
	
	local valueBg = display.newSprite(PvpRes .. "bar_1.png")
	valueBg:anch(0,0):pos(150, self.size.height - 98):addTo(self)

	display.newSprite(mapTables[self.shopIndex].icon)
	:anch(0.5, 0.5):pos(50, valueBg:getContentSize().height/2):addTo(valueBg)
	local valueText = ui.newTTFLabel({ text = game.role[mapTables[self.shopIndex].valueName], size = 20 })
	valueText:anch(0.5, 0.5):pos(100, valueBg:getContentSize().height/2):addTo(valueBg)
	if self.valueUpdateHandler then
		game.role:removeEventListener(mapTables[self.shopIndex].eventName, self.valueUpdateHandler)
	end
	self.valueUpdateHandler = game.role:addEventListener(mapTables[self.shopIndex].eventName, function(event)
			valueText:setString(event[mapTables[self.shopIndex].valueName])
		end)

	local nextBg = display.newSprite(GlobalRes .. "label_middle_bg.png")
	nextBg:anch(0,0):pos(valueBg:getPositionX()+valueBg:getContentSize().width+20, self.size.height - 98):addTo(self)

	local cost = shopOpenCsv:getCostValue(self.shopIndex, game.role[string.format("shop%dRefreshCount", self.shopIndex)])

	display.newSprite(GlobalRes .. "yuanbao.png"):scale(0.8,0.8):anch(0.5, 0.5):pos(230, nextBg:getContentSize().height/2):addTo(nextBg)
	local costYuanbao = ui.newTTFLabel({ text = cost, size = 20, })
	costYuanbao:anch(0.5, 0.5):pos(260, nextBg:getContentSize().height/2):addTo(nextBg)

	local refreshBtn = DGBtn:new(GlobalRes, {"topbar_normal.png", "topbar_selected.png"},
		{	
			priority = self.priority,
			text = { text = "刷新", size = 20, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_BUTTON_STROKE, strokeSize = 2},
			callback = function()
				DGMsgBox.new({ type = 2,
					text = (game.role.items[52] and game.role.items[52].count > 0) and string.format("是否使用1个商店刷新符，你当前拥有%d个商店刷新符！", game.role.items[52].count) 
								or string.format("是否使用 %d 元宝刷新道具!!", shopOpenCsv:getCostValue(self.shopIndex, game.role[string.format("shop%dRefreshCount", self.shopIndex)])),
					button2Data = { callback = function() self:refreshShopRequest() end }
				})
			end,
		}):getLayer()
	refreshBtn:anch(0, 0):pos(self.size.width / 2 + 220, self.size.height - 98):addTo(self)

	local tipLable=ui.newTTFLabel({text="下次刷新: ",size=20,color=display.COLOR_WHITE})
	tipLable:anch(0,0.5):pos(18, nextBg:getContentSize().height/2):addTo(nextBg)

	local now = game:nowTime()
	local nowTm = os.date("*t", now)
	local _, refreshTimeStr = shopOpenCsv:getNextRefreshTime(self.shopIndex, nowTm.day, now)	
	ui.newTTFLabel({ text = refreshTimeStr, size = 20, color = uihelper.hex2rgb("#7ce810")})
		:anch(0.5, 0.5):pos(tipLable:getPositionX()+tipLable:getContentSize().width*3/2, nextBg:getContentSize().height/2):addTo(nextBg)


	self:refreshItemLayer()

	game.role:addEventListener("shopRefreshTimer", function(event)
		local now = game:nowTime()
		for _, shopData in ipairs(event.data.shopDatas) do
			if self.shopIndex == shopData.shopIndex then
				self.shopDatas = {
					shopItems = json.decode(shopData.shopItemsJson),
					refreshLeftTime = shopData.refreshLeftTime,
					checkPoint = now,
				}

				local cost = shopOpenCsv:getCostValue(self.shopIndex, game.role[string.format("shop%dRefreshCount", self.shopIndex)])
				costYuanbao:setString(cost)
				self:refreshItemLayer()
				break
			end	
		end
	end)
end

function PvpShopLayer:refreshShopRequest()
	local bin = pb.encode("SimpleEvent", { param1 = self.shopIndex })
	game:sendData(actionCodes.RoleShopRefresRequest, bin, #bin)	
	showMaskLayer()
	game:addEventListener(actionModules[actionCodes.RoleShopRefresResponse], function(event)
		hideMaskLayer()
		local msg = pb.decode("RoleShopDataResponse", event.data)

		local now = game:nowTime()
		self.shopDatas = {}
		local shopData = msg.shopDatas[1]
		self.shopDatas = {
			shopItems = json.decode(shopData.shopItemsJson),
			refreshLeftTime = shopData.refreshLeftTime,
			checkPoint = now,
		}
		self:initUI()

		return "__REMOVE__"
	end)
end

function PvpShopLayer:refreshItemLayer()
	
	if self.itemLayer then self.itemLayer:removeSelf() end

	self.itemLayer = display.newLayer()
	self.itemLayer:size(self.size.width, 198 * 2 + 15):pos(0, 20):addTo(self)


	local shopItems = self.shopDatas.shopItems

	if table.nums(shopItems) <= 6 then
		local xBegin = 28
		local xInterval = (self.size.width - 2 * xBegin - 3 * 236) / 2

		local index = 1
		for _, shopData in pairs(self.shopDatas.shopItems) do
			local shopId=shopData.shopId
			local num=shopData.num
			local col, row = math.ceil(index /2), index % 2==0 and 1 or 2 
			local shopItem = self:initShopItem({shopId=shopId,num=num, priceType = shopData.priceType })
			shopItem:pos(xBegin + (col - 1) * (xInterval + 236), (row - 1) * (15 + 180)):addTo(self.itemLayer)
			index = index + 1
		end
	else
		local xBegin, xInterval, yInterval = 28, 15, 15
		local itemScroll = DGScrollView:new({
			size = CCSizeMake(self.itemLayer:getContentSize().width - 2 * xBegin, 188 * 2 + yInterval),
			divider = xInterval, horizontal = true, priority = self.priority - 1,
		})

		local shopIds={}
		for _,v in ipairs(shopItems) do
			shopIds[#shopIds+1]=v.shopId
		end

		for index = 1, #shopIds , 2 do
			local cellNode = display.newNode()
			cellNode:size(236, 188 * 2 + 15)

			local upItem = self:initShopItem({shopId=shopIds[index],num=shopItems[index].num, 
				priceType = shopItems[index].priceType})
			upItem:pos(0, 188 + 15):addTo(cellNode)

			if shopIds[index + 1] then
				local downItem = self:initShopItem({shopId=shopIds[index+1],
					num=shopItems[index+1].num, priceType = shopItems[index].priceType})
				downItem:pos(0, 0):addTo(cellNode)
			end

			itemScroll:addChild(cellNode)
		end

		itemScroll:alignCenter()
		itemScroll:getLayer():pos(xBegin, 0):addTo(self.itemLayer)

		display.newSprite(DrawCardRes .. "arrow_left.png"):anch(0, 0.5):pos(0, self.itemLayer:getContentSize().height/2):addTo(self.itemLayer)
		display.newSprite(DrawCardRes .. "arrow_right.png"):anch(1, 0.5):pos(self.itemLayer:getContentSize().width, self.itemLayer:getContentSize().height/2):addTo(self.itemLayer)
	end
end

function PvpShopLayer:initShopItem(shopData)
	local shopId=shopData.shopId
	local shopItems = self.shopDatas.shopItems
	local itemNum = tonum(shopData.num)
	local shopItem = shopCsv:getShopData(tonum(shopId))
	local cellBtn
	cellBtn = DGBtn:new(PvpRes, {"bg_itemPvpstore.png"},
		{	
			parent = self.itemLayer,
			priority = self.priority,
			callback = function()
				-- 背包已满
				-- if game.role:isHeroBagFull() then
				-- 	DGMsgBox.new({ msgId = 111 })
				-- 	return
				-- end

				if itemNum <= 0 then
					DGMsgBox.new({type =1, text = "已售完"})
					return
				end
				--魂不足给出提示：
				local buy = BuyItemTipsLayer.new({
					priority = self.priority - 10,
					shopId = shopId,
					itemNum = itemNum,
					shopIndex = self.shopIndex,
					priceType = shopData.priceType,
					callback = function()
						local shopBuyRequest = { param1 = self.shopIndex, param2 = tonumber(shopId), param3 = itemNum }
						local bin = pb.encode("SimpleEvent", shopBuyRequest)
						game:sendData(actionCodes.RoleShopBuyRequest, bin, #bin)
						game:addEventListener(actionModules[actionCodes.RoleShopBuyResponse], function(event)
							shopItems[tostring(shopId)] = tostring(-itemNum)
							
							display.newSprite(ShopRes .. "item_mask.png")
								:anch(0, 0):pos(3, 3):addTo(cellBtn:getLayer(), 100)
							display.newSprite(ShopRes .. "sell_out.png")
								:anch(0, 0.55):pos(20, cellBtn:getLayer():getContentSize().height/2):addTo(cellBtn:getLayer(), 100)

							sellOut = true
							cellBtn:setEnable(not sellOut)

							return "__REMOVE__"
						end)
					end,
				})
				display.getRunningScene():addChild(buy:getLayer())
				
			end,
		})
	local cellSize = cellBtn:getLayer():getContentSize()
	if not shopItem then
		return cellBtn:getLayer()
	end
	local sellOut = itemNum <= 0
	cellBtn:setEnable(not sellOut)
	if sellOut then
		display.newSprite(ShopRes .. "item_mask.png")
			:anch(0, 0):pos(3, 3):addTo(cellBtn:getLayer(), 100)
		display.newSprite(ShopRes .. "sell_out.png")
			:anch(0, 0.55):pos(20, cellBtn:getLayer():getContentSize().height/2):addTo(cellBtn:getLayer(), 100)
	end

	local itemData = itemCsv:getItemById(shopItem.itemId)
	local frame = ItemIcon.new({ itemId = shopItem.itemId }):getLayer()
	frame:setColor(ccc3(100, 100, 100))
	frame:anch(0.5,0.5):pos(cellSize.width / 2, cellSize.height / 2+5):addTo(cellBtn:getLayer())
	local tempName=ui.newTTFLabelWithStroke({ text = itemData.name,font=ChineseFont , size = 22 })
		:anch(0, 1):pos(cellSize.width / 2, cellSize.height - 8):addTo(cellBtn:getLayer())
	local tempNum=ui.newTTFLabelWithStroke({ text = "x" .. math.abs(tonum(itemNum)),font=ChineseFont , size = 22,color=uihelper.hex2rgb("#7ce810") })
		:anch(0, 1):pos(cellSize.width / 2, cellSize.height - 8):addTo(cellBtn:getLayer())
	tempName:setPositionX((cellSize.width-(tempName:getContentSize().width+tempNum:getContentSize().width))/2)
	tempNum:setPositionX(tempName:getPositionX()+tempName:getContentSize().width)

	
	local priceKey = table.keys(shopItem.price)[1]
	display.newSprite(mapTables[self.shopIndex].icon):scale(0.8,0.8):anch(0, 0.5):pos(60, 25):addTo(cellBtn:getLayer())

	local totalPrice = tonum(shopItem.price[priceKey]) * math.abs(itemNum)
	local canBuy = game.role[mapTables[self.shopIndex].valueName] >= totalPrice
	ui.newTTFLabel({ text = totalPrice, text = 20, color = canBuy and uihelper.hex2rgb("#533b22") or display.COLOR_RED })
		:pos(cellSize.width / 2+5, 23):addTo(cellBtn:getLayer())

	return cellBtn:getLayer()
end

function PvpShopLayer:getLayer()
	return self.mask:getLayer()
end

function PvpShopLayer:onExit()
	game.role:removeAllEventListenersForEvent("shopRefreshTimer")
	game.role:removeEventListener(mapTables[self.shopIndex].eventName, self.valueUpdateHandler)
end

return PvpShopLayer