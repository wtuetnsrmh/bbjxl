local ShopData = {
	[1] = { 
		res = { "shop1_normal.png", "shop1_selected.png", }, 
	},

	[2] = { 
		res = { "shop2_normal.png", "shop2_selected.png", "shop2_disabled.png" },
	},

	[3] = { 
		res = { "shop3_normal.png", "shop3_selected.png", "shop2_disabled.png" },
	},

	[4] = { 
		res = {"herosoul_normal.png", "herosoul_selected.png" },
	}
}

local PriceMap = {
	["1"] = { field = "yuanbao", res = "resource/ui_rc/global/yuanbao.png" },
	["2"] = { field = "money", res = "resource/ui_rc/global/yinbi.png" },
	["3"] = { field = "zhangongNum", res = "resource/ui_rc/pvp/zhangong.png" },
	["4"] = { field = "heroSoulNum", res = "resource/ui_rc/global/herosoul.png" },
}

local TopBarLayer = import("..TopBarLayer")
local BuyItemTipsLayer = import("..BuyItemTipsLayer")
local ShopRes = "resource/ui_rc/store/"

local StoreMainLayer = class("StoreMainLayer", function()
	return display.newLayer(ShopRes .. "bg.png")
end)

function StoreMainLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -130
	self.size = self:getContentSize()
	self.parent = params.parent
	self.shopDatas = params.shopDatas
	self.curIndex = params.curIndex

	-- 遮罩层
	self:anch(0, 0):pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1, bg = HomeRes .. "home.jpg" })

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
				self:getLayer():removeSelf()
			end,
		}):getLayer()
	closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self,100)

	--标签：
	local tabLabel = display.newSprite(GlobalRes .. "tab_selected.png")
	tabLabel:anch(0, 0.5):pos(self:getContentSize().width - 14, 480):addTo(self)
	local btnSize = tabLabel:getContentSize()

	display.newSprite(GlobalRes.."tab_arrow.png"):anch(1,0.5):pos(10, btnSize.height/2)
		:addTo(tabLabel)

	ui.newTTFLabelWithStroke({ text = "商店", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(tabLabel)

	self.viewBg = display.newSprite(ShopRes .. "inner_bg.png")
	self.viewSize = self.viewBg:getContentSize()
	self.viewBg:anch(0.5, 0):pos(self.size.width / 2, 30):addTo(self)

	self:createTabs()

	local layer  = TopBarLayer.new({priority = self.priority})
	layer:anch(0,1):pos(0,display.height):addTo(self)

	game.role:addEventListener("shopRefreshTimer", function(event)
		local now = game:nowTime()
		for _, shopData in ipairs(event.data.shopDatas) do
			self.shopDatas[shopData.shopIndex] = {
				shopItems = json.decode(shopData.shopItemsJson),
				refreshLeftTime = shopData.refreshLeftTime,
				checkPoint = now,
			}
		end

		self:createItemView({ shopIndex = self.curIndex })
	end)
end

function StoreMainLayer:createTabs()
	if self.tabLayer then
		self.tabLayer:removeSelf()
	end

	self.tabLayer = display.newLayer()
	self.tabLayer:size(self.viewSize):addTo(self.viewBg)

	local xPos = 25
	local xInterval = (self.viewSize.width - 2 * xPos - (217 + 138) * 2) / 3

	local btnRadio = DGRadioGroup:new()
	local vipInfo = vipCsv:getDataByLevel(game.role.vipLevel)
	local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
	for index = 1, 4 do
		if index == 1 or (index == 4 and roleInfo.huahunOpen >= 0) or ((index == 2 or index == 3) and (vipInfo.storeLevel >= index or game.role[string.format("specialStore%dEndTime", index)] > game:nowTime())) then
			local shopBtn = DGBtn:new(ShopRes, ShopData[index].res, {
				id = index,
				selectAnchor = { 0.5, 0},
				priority = self.priority,
				callback = function()
					self.curIndex = index
					self:createItemView({ shopIndex = index })
				end,
			}, btnRadio)
			shopBtn:getLayer():pos(xPos, self.viewSize.height - 8):addTo(self.tabLayer)
			xPos = xPos + xInterval + shopBtn:getLayer():getContentSize().width
		end
	end

	btnRadio:chooseById(self.curIndex or 1, true)
end

function StoreMainLayer:createItemView(params)
	if self.viewLayer then
		self.viewLayer:removeSelf()
	end

	self.viewLayer = display.newLayer()
	self.viewLayer:size(self.viewSize):addTo(self.viewBg)

	local shopItems = self.shopDatas[params.shopIndex].shopItems

	if table.nums(shopItems) <= 6 then
		local xBegin, yInterval = 40, 15
		local xInterval = (self.viewSize.width - 2 * xBegin - 3 * 230) / 2

		local index = 1
		for _, shopData in pairs(shopItems) do
			local shopId=shopData.shopId
			local col, row = math.ceil(index /2), index % 2==0 and 1 or 2 
			local shopItem = self:initShopItem({ shopIndex = params.shopIndex, 
				shopId = shopId, num=shopData.num, priceType = shopData.priceType 
			})
			shopItem:pos(xBegin + (col - 1) * (xInterval + 230), (row -1) * (15 + 188) + 70):addTo(self.viewLayer)
			index = index + 1
		end
	else
		local xBegin, xInterval, yInterval = 20, 15, 15
		local itemScroll = DGScrollView:new({
			size = CCSizeMake(self.viewSize.width - 2 * xBegin, 188 * 2 + yInterval),
			divider = xInterval, horizontal = true, priority = self.priority - 1,
		})

		local shopIds={}
		for _,v in ipairs(shopItems) do
			shopIds[#shopIds+1]=v.shopId
		end
		
		for index = 1, #shopIds , 2 do
			local cellNode = display.newNode()
			cellNode:size(230, 188 * 2 + 15)

			local upItem = self:initShopItem({ shopIndex = params.shopIndex, 
				shopId = shopIds[index], num=shopItems[index].num, priceType = shopItems[index].priceType })
			upItem:pos(0, 188 + 15):addTo(cellNode)

			if shopIds[index + 1] then
				local downItem = self:initShopItem({ shopIndex = params.shopIndex, 
					shopId = shopIds[index + 1], num=shopItems[index+1].num, 
					priceType = shopItems[index+1].priceType 
				})
				downItem:pos(0, 0):addTo(cellNode)
			end

			itemScroll:addChild(cellNode)
		end

		itemScroll:alignCenter()
		itemScroll:getLayer():pos(xBegin, 70):addTo(self.viewLayer)

	end

	-- 刷新bar
	local bottomNode = display.newNode()

	local refreshBar = display.newSprite(ShopRes .. "refresh_bar.png")
	local barSize = refreshBar:getContentSize()

	local vipInfo = vipCsv:getDataByLevel(game.role.vipLevel)
	if (params.shopIndex ~= 2 and params.shopIndex ~= 3) or vipInfo.storeLevel >= params.shopIndex then
		local nowTm = os.date("*t", game:nowTime())
		local _, refreshTimeStr = shopOpenCsv:getNextRefreshTime(params.shopIndex, nowTm.day, game:nowTime())	
		local text = ui.newTTFLabel({ text = "下次刷新：", size = 20 }):anch(0, 0.5):pos(20, barSize.height / 2):addTo(refreshBar)
		ui.newTTFLabel({ text = refreshTimeStr, size = 20, color = uihelper.hex2rgb("#7ce810") })
			:anch(0, 0.5):pos(text:getContentSize().width, text:getContentSize().height / 2):addTo(text)
	else
		local text = ui.newTTFLabel({ text = "剩余时间：", size = 20 }):anch(0, 0.5):pos(20, barSize.height / 2):addTo(refreshBar)
		local setLeftTime
		setLeftTime = function()
			local leftTime = game.role[string.format("specialStore%dEndTime", params.shopIndex)] - game:nowTime() 
			text:removeAllChildren()
			ui.newTTFLabel({ text = string.format("%02d:%02d", math.floor(leftTime/60),leftTime%60), size = 20, color = uihelper.hex2rgb("#7ce810") })
				:anch(0, 0.5):pos(text:getContentSize().width, text:getContentSize().height / 2):addTo(text)
			if leftTime <= 0 then
				self:createTabs()
			else
				text:runAction(transition.sequence({
 					CCDelayTime:create(1),
 					CCCallFunc:create(setLeftTime)
					}))
			end
		end
		setLeftTime()
	end


	display.newSprite(GlobalRes .. "yuanbao.png"):anch(0, 0.5)
		:pos(180, barSize.height / 2):addTo(refreshBar)

	local costValue = shopOpenCsv:getCostValue(params.shopIndex, game.role[string.format("shop%dRefreshCount", params.shopIndex)])
	
	ui.newTTFLabel({ text = costValue, size = 20 }):anch(0, 0.5)
		:pos(230, barSize.height / 2):addTo(refreshBar)

	local refreshBtn = DGBtn:new(GlobalRes, {"topbar_normal.png", "topbar_selected.png"},
		{	
			priority = self.priority,
			text = { text = "刷新", size = 20, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_BUTTON_STROKE, strokeSize = 2},
			callback = function()
				local cost = shopOpenCsv:getCostValue(params.shopIndex, game.role[string.format("shop%dRefreshCount", params.shopIndex)])

				DGMsgBox.new({ type = 2,
					text = (game.role.items[52] and game.role.items[52].count > 0) and string.format("是否使用1个商店刷新符，你当前拥有%d个商店刷新符！", game.role.items[52].count) 
								or string.format("是否使用 %d 元宝刷新道具!!", cost),
					button2Data = { callback = 
						function() 
							local bin = pb.encode("SimpleEvent", { param1 = params.shopIndex })
							game:sendData(actionCodes.RoleShopRefresRequest, bin, #bin)
							game:addEventListener(actionModules[actionCodes.RoleShopRefresResponse], function(event)
								local msg = pb.decode("RoleShopDataResponse", event.data)
								local shopData = msg.shopDatas[1]
								self.shopDatas[shopData.shopIndex] = {
									shopItems = json.decode(shopData.shopItemsJson),
									refreshLeftTime = shopData.refreshLeftTime,
									checkPoint = game:nowTime(),
								}
								self:createItemView({ shopIndex = params.shopIndex })

								return "__REMOVE__"
							end)
						end 
					}
				})
			end,
		}):getLayer()
	refreshBtn:anch(0, 0.5):pos(barSize.width - 30, barSize.height / 2):addTo(refreshBar)


	bottomNode:size(barSize)
	-- 将魂
	if params.shopIndex == 4 then
		local costBar = display.newSprite(ShopRes .. "cost_bar.png")
		local costSize = costBar:getContentSize()
		display.newSprite(PriceMap[tostring(params.shopIndex)].res)
			:anch(0, 0.5):pos(0, costSize.height / 2 + 5):addTo(costBar)
		self.valueText = ui.newTTFLabel({ text = game.role.heroSoulNum, size = 20})
			:anch(0, 0.5):pos(50, costSize.height / 2):addTo(costBar)

		if not self.valueUpdateHandler then
			self.valueUpdateHandler = game.role:addEventListener("updateHeroSoulNum", function(event)
				self.valueText:setString(tostring(event.heroSoulNum))
			end)
		end
		

		bottomNode:size(costSize.width + 40 + barSize.width, barSize.height)
		costBar:anch(0, 0.5):pos(0, barSize.height / 2):addTo(bottomNode)
	end

	refreshBar:anch(1, 0.5):pos(bottomNode:getContentSize().width, barSize.height / 2):addTo(bottomNode)
	bottomNode:anch(0.5, 0):pos(self.viewSize.width / 2, 20):addTo(self.viewLayer)
end

function StoreMainLayer:initShopItem(params)
	local shopItems = self.shopDatas[params.shopIndex].shopItems
	local itemNum = tonum(params.num)
	local shopItem = shopCsv:getShopData(tonum(params.shopId))
	local sellOut = itemNum <= 0

	local cellBtn 
	cellBtn = DGBtn:new(ShopRes, {"item_cell.png"},
		{	
			parent = self.viewBg,
			priority = self.priority,
			callback = function()
				if itemNum <= 0 then
					DGMsgBox.new({type =1, text = "已售完"})
					return
				end
				--魂不足给出提示：
				local buy = BuyItemTipsLayer.new({
					priority = self.priority - 10,
					shopIndex = params.shopIndex,
					shopId = params.shopId,
					priceType = params.priceType,
					itemNum = itemNum,
					callback = function()
						local shopBuyRequest = { param1 = params.shopIndex, param2 = tonumber(params.shopId), param3 = tonum(itemNum) }
						local bin = pb.encode("SimpleEvent", shopBuyRequest)
						game:sendData(actionCodes.RoleShopBuyRequest, bin, #bin)
						game:addEventListener(actionModules[actionCodes.RoleShopBuyResponse], function(event)
							for _,item in ipairs(shopItems) do
								if item.shopId==tostring(params.shopId) then
									item.num=tostring(-tonum(itemNum))
								end
							end
							
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
	local tempName=ui.newTTFLabelWithStroke({ text = itemData.name, font = ChineseFont , size = 22 })
		:anch(0, 1):pos(cellSize.width / 2, cellSize.height - 8):addTo(cellBtn:getLayer())
	local tempNum=ui.newTTFLabelWithStroke({ text = " X " .. math.abs(tonum(itemNum)),font=ChineseFont , size = 22,color=uihelper.hex2rgb("#7ce810") })
		:anch(0, 1):pos(cellSize.width / 2, cellSize.height - 8):addTo(cellBtn:getLayer())
	tempName:setPositionX((cellSize.width-(tempName:getContentSize().width+tempNum:getContentSize().width))/2)
	tempNum:setPositionX(tempName:getPositionX()+tempName:getContentSize().width)

	local priceData = PriceMap[params.priceType]
	display.newSprite(priceData.res):scale(0.8,0.8):anch(0, 0.5):pos(60, 25):addTo(cellBtn:getLayer())

	local totalPrice = tonum(shopItem.price[params.priceType]) * math.abs(itemNum)
	local canBuy = game.role[priceData.field] >= totalPrice
	ui.newTTFLabel({ text = totalPrice, text = 20, color = canBuy and uihelper.hex2rgb("#533b22") or display.COLOR_RED })
		:pos(cellSize.width / 2+5, 23):addTo(cellBtn:getLayer())

	return cellBtn:getLayer()
end

function StoreMainLayer:getLayer()
	return self.mask:getLayer()
end

function StoreMainLayer:onEnter()
	self.parent:hide()
end

function StoreMainLayer:onExit()
	self.parent:show()

	game.role:removeAllEventListenersForEvent("shopRefreshTimer")
	game.role:removeEventListener("updateHeroSoulNum", self.valueUpdateHandler)
end

return StoreMainLayer