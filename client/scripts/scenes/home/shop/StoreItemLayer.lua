-- 升级礼包活动页面：
local ItemRes = "resource/ui_rc/shop/item/"
local NGlobalRes = "resource/ui_rc/global/" 

local StoreItemLayer = class("StoreItemLayer", function() 
	return display.newLayer() 
end)

function StoreItemLayer:ctor(params)
	params = params or {}
	self.priority = params.priority or -129

	self.size = CCSizeMake(820 ,470)
	self:setContentSize(self.size)
	self.tipsTag = 9090

	self:getDataFromServer()
end
--发送请求：
function StoreItemLayer:getDataFromServer()
	local bin = pb.encode("SimpleEvent", { roleId = game.role.id, param1 = 2 })
    game:sendData(actionCodes.StoreListItemRequest, bin, #bin)
    loadingShow()
    game:addEventListener(actionModules[actionCodes.StoreListItemResponse], function(event)
    	loadingHide()
    	local msg = pb.decode("ShopItemsResponse", event.data)
		self:initTableView({ items = msg.items })
		return "__REMOVE__"
    end)
end

--tableview
function StoreItemLayer:initTableView(params)
	--创建底层：
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end
	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.size):anch(0,0):pos(0,0):addTo(self)


	--初始化数据：
	local curTabItems = {}
	for _, item in ipairs(params.items) do
		local storeItem = clone(storeCsv:getStoreItemById(item.storeId))
		storeItem.todayBuyCount = item.todayBuyCount
		storeItem.totalBuyCount = item.totalBuyCount
		table.insert(curTabItems, storeItem)
	end
	table.sort(curTabItems, function(a, b) return a.position < b.position end)
	local itemCount = #curTabItems
	local columns = 2
	--初始化tableview：
	local handler = LuaEventHandler:create(function(fn, tbl, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.size.width, 130) --cell size
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

            local index = a1
            self:creatTableViewCell(cell, a1, curTabItems, columns)
            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(itemCount/columns)
        end
        return r
    end)

	self.tableView = LuaTableView:createWithHandler(handler, CCSizeMake(self.size.width, self.size.height - 34))
    self.tableView:setBounceable(true)
    self.tableView:setTouchPriority(self.priority - 2)
    self.tableView:setPosition(ccp(0, 33))
	self.mainLayer:addChild(self.tableView)
	if self.offset then
		self.tableView:setContentOffset(ccp(0, self.offset), false)
	end
end

function StoreItemLayer:creatTableViewCell(cellNode, cellIndex, curTabItems, columns)
	local xBegin = 40
	local cellWidth = 364
	local xInterval = (self.size.width - 2 * xBegin - columns * cellWidth) / (columns - 1)
	local rows = math.ceil(#curTabItems/ columns)
	for index = (rows - cellIndex - 1) * columns + 1, columns * (rows - cellIndex) do
		local item = curTabItems[index]
		local nativeIndex = index - (rows - cellIndex - 1) * columns
		if item then
			local itemNode = self:initScrollviewCell(item)
			itemNode:anch(0, 0) :pos(xBegin + (cellWidth + xInterval) * (nativeIndex - 1), 5)
			cellNode:addChild(itemNode)
		end
	end
end

function StoreItemLayer:initScrollviewCell(item)
	local packageData = itemCsv:getItemById(item and item.itemId or 0)
	local itemBg = display.newSprite(ItemRes.."cell_bg.png")
	local posY = itemBg:getContentSize().height/2
	if packageData then
		local itemBtn = ItemIcon.new({
			itemId = item.itemId,
			priority = self.priority - 1,
			parent = self.mainLayer,
			callback = function()
				-- self:showItemTaps(item.itemId, item.num,2)
			end,
		}):getLayer()
		itemBtn:scale(0.8):anch(0, 0.5):pos(10, posY):addTo(itemBg)
		local bgSize = itemBg:getContentSize()

		local xPos = 97
		--item name 
		local text = ui.newTTFLabelWithStroke({ text = item.name, size = 22, font = ChineseFont, color = uihelper.hex2rgb("#f71ffa"), strokeColor = display.COLOR_FONT })
		text:anch(0, 0):pos(xPos, 65):addTo(itemBg)
		if item.num > 1 then
			ui.newTTFLabelWithStroke({ text = "X"..item.num, size = 22, font = ChineseFont, color = uihelper.hex2rgb("#ffd200"), strokeColor = display.COLOR_FONT })
				:anch(0, 0):pos(text:getContentSize().width, 0):addTo(text)
		end
		--item desc
		uihelper.createLabel({ text = item.desc, size = 18, color = uihelper.hex2rgb("#261d16"), width = 160 })
			:anch(0, 1):pos(xPos, bgSize.height - 50):addTo(itemBg)

		local canBuy = true
		local function getBuyCountTips(packageData)
			local buyCountTips
			dailyBuyLimit = storeCsv:getDayBuyLimit(packageData.id, game.role.vipLevel)
			if dailyBuyLimit ~= math.huge then
				if dailyBuyLimit > packageData.todayBuyCount then
					buyCountTips = string.format("今日限购%d次", dailyBuyLimit - packageData.todayBuyCount)
				else
					buyCountTips = "已售罄"
					canBuy = false
				end
			elseif packageData.totalBuyLimit ~= math.huge then
				if packageData.totalBuyLimit > item.totalBuyCount then
					buyCountTips = string.format("限购%d次", packageData.totalBuyLimit - packageData.totalBuyCount)
				else
					buyCountTips = "已售罄"
					canBuy = false
				end
			else
				buyCountTips = "不限购"
			end

			return buyCountTips
		end

		local buyBtn = DGBtn:new(ItemRes, {"item_normal.png", "item_selected.png", "item_disabled.png"},
			{	
				parent = self.mainLayer,
				priority = self.priority,
				callback = function()
					if (packageData.itemId - 5000) > game.role.vipLevel then
						DGMsgBox.new({ msgId = SYS_ERR_VIP_GIFT_LEVEL_NOT_ENOUGH })
						return
					end

					self.offset = self.tableView:getContentOffset().y 

					local bin = pb.encode("SimpleEvent", 
						{ roleId = game.role.id, param1 = item.id, param2 = 3 })
					game:sendData(actionCodes.StoreBuyItemRequest, bin, #bin)
					loadingShow()
					game:addEventListener(actionModules[actionCodes.StoreBuyItemResponse], function(event)
						loadingHide()
						item.todayBuyCount = item.todayBuyCount + 1
						item.totalBuyCount = item.totalBuyCount + 1
		
						DGMsgBox.new({ text = string.format("购买成功！获得道具 %s", item.name, item.num), type = 1})
						local price = storeCsv:getPriceByCount(item.id, item.totalBuyCount + 1)
							
						self:getDataFromServer()

						return "__REMOVE__"
					end)
				end,
			})
		buyBtn:getLayer():anch(1, 0.5):pos(bgSize.width - 5, posY):addTo(itemBg)
		local tips = getBuyCountTips(item)
		local btnSize = buyBtn:getLayer():getContentSize()
		if canBuy then
			local yPos = btnSize.height/2
			--item price 
			display.newSprite(NGlobalRes .. "yuanbao.png"):scale(0.8):anch(0, 0.5):pos(10, yPos):addTo(buyBtn:getLayer())
			--gold count
			local price = storeCsv:getPriceByCount(item.id, item.totalBuyCount + 1)
			local priceLabel = ui.newTTFLabelWithStroke({text = price, size = 22, color = display.COLOR_WHITE,
				strokeColor = display.COLOR_FONT, strokeSize = 2 })
			priceLabel:anch(0, 0.5):pos(46, yPos):addTo(buyBtn:getLayer())
			--item state tips
			ui.newTTFLabel({ text = tips, size = 18, color = uihelper.hex2rgb("#dd1f5e") })
				:anch(0.5, 1):pos(btnSize.width/2, 0):addTo(buyBtn:getLayer())
		else
			ui.newTTFLabelWithStroke({text = tips, size = 22, strokeColor = display.COLOR_FONT })
				:anch(0.5, 0.5):pos(btnSize.width/2, btnSize.height/2):addTo(buyBtn:getLayer())
		end

		buyBtn:setEnable(canBuy)
	end

	return itemBg
end 

function StoreItemLayer:showItemTaps(itemID,itemHave,itemType)
	self:purgeItemTaps()
	local itemTipsView = require("scenes.home.ItemTipsLayer")
	local itemTips = itemTipsView.new({
		itemId = itemID,
		itemNum = itemHave,
		itemType = itemType,
		showSource = false,
	})
	display.getRunningScene():addChild(itemTips:getLayer(),999)
	itemTips:setTag(self.tipsTag)
end

function StoreItemLayer:purgeItemTaps()
	if display.getRunningScene():getChildByTag(self.tipsTag) then
		display.getRunningScene():getChildByTag(self.tipsTag):removeFromParent()
	end
end

return StoreItemLayer