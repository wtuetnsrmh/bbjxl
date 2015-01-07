-- vip礼包界面
-- by yangkun
-- 2014.7.1

local ShopRes = "resource/ui_rc/shop/"
local ReChargeRes = "resource/ui_rc/shop/recharge/"
local VipRes = "resource/ui_rc/shop/vip/"
local GiftRes = "resource/ui_rc/shop/gift/"
local GlobalRes = "resource/ui_rc/global/"

local GiftItemLayer = class("GiftItemLayer", function()
	return display.newLayer()
end)


function GiftItemLayer:ctor(params)
	params = params or {}

	self:size(CCSizeMake(745, 435))
	self.size = self:getContentSize()

	self.priority = params.priority or -130
	self.yOffset = 0
	self.itemDatas = {}

	local bin = pb.encode("SimpleEvent", { roleId = game.role.id, param1 = 3 })
    game:sendData(actionCodes.StoreListItemRequest, bin, #bin)
    loadingShow()
    game:addEventListener(actionModules[actionCodes.StoreListItemResponse], function(event)
    	loadingHide()
    	local msg = pb.decode("ShopItemsResponse", event.data)
    	self.items = msg.items
    	self:prepareData()
		self:initScrollLayer()
		self:checkGuide()

		return "__REMOVE__"
    end)

end

function GiftItemLayer:onEnter()
	
end

function GiftItemLayer:checkGuide(remove)
	game:addGuideNode({node = self.buyBtn, remove = remove,
		guideIds = {504}
	})
end

function GiftItemLayer:onExit()
	self:checkGuide(true)
end

function GiftItemLayer:prepareData()
	for _, item in ipairs(self.items) do
		local storeItem = clone(storeCsv:getStoreItemById(item.storeId))
		storeItem.todayBuyCount = item.todayBuyCount
		storeItem.totalBuyCount = item.totalBuyCount

		table.insert(self.itemDatas, storeItem)
	end
	table.sort(self.itemDatas, function(a, b) return a.position < b.position end)
end

function GiftItemLayer:initScrollLayer()
	self:removeAllChildren()
	local layer = display.newLayer()
	local layerSize = CCSizeMake(self.size.width , 410)
	layer:size(layerSize):anch(0.5, 0):pos(self.size.width / 2, 30):addTo(self)

	local giftScroll = DGScrollView:new({priority = self.priority - 1, size = layerSize, divider = 5 })

	local function createScrollNode(giftData, index)
		local cellBg = display.newSprite(GiftRes .. "cell_bg.png")
		local cellSize = cellBg:getContentSize()

		-- name
		local tempName=giftData.name
		local nameImgUrl=string.split(tempName, "礼包")
		display.newSprite(GiftRes..nameImgUrl[1]..".png"):anch(0,0.5):pos(85,84):addTo(cellBg)

		local itemIco=DGBtn:new(GiftRes,{"ic_vip.png"},{
			priority=self.priority-1,
			callback=function()
				local GiftPreviewLayer = require("scenes.home.shop.GiftPreviewLayer")
				local layer = GiftPreviewLayer.new({priority = self.priority - 10, itemId = giftData.itemId})
				layer:getLayer():addTo(display.getRunningScene()) 
			end
			})
		itemIco:getLayer():anch(0,0.5):pos(7,53):addTo(cellBg)

		-- desc
		uihelper.createLabel({text = giftData.desc, size = 18, width = 175, color = uihelper.hex2rgb("#261d16")})
		:anch(0,1):pos(82, cellSize.height - 44):addTo(cellBg)


		local enabled = false
		if giftData.totalBuyLimit ~= math.huge then
			if giftData.totalBuyLimit > giftData.totalBuyCount then
				local buyCountTips = string.format("还可购%d次", giftData.totalBuyLimit - giftData.totalBuyCount)
				ui.newTTFLabel({text = buyCountTips, size = 18, color = uihelper.hex2rgb("#dd1f5e")})
				:anch(0,1):pos(262, cellSize.height - 76):addTo(cellBg)

				enabled = true
			else
				enabled = false
			end
		end

		local buyBtn = DGBtn:new(ShopRes.."item/", {"item_normal.png", "item_selected.png", "item_disabled.png"}, {
			priority = self.priority -1,
			size = 22, font = ChineseFont, strokeColor = display.COLOR_FONT, strokeSize = 2,
			callback = function()
				if (giftData.itemId - 5000) > game.role.vipLevel then
					DGMsgBox.new({ msgId = SYS_ERR_VIP_GIFT_LEVEL_NOT_ENOUGH })
					return
				end

				local bin = pb.encode("SimpleEvent", { roleId = game.role.id, param1 = giftData.id, param2 = 3 })
					game:sendData(actionCodes.StoreBuyItemRequest, bin, #bin)
					loadingShow()
					game:addEventListener(actionModules[actionCodes.StoreBuyItemResponse], function(event)
						loadingHide()
						giftData.todayBuyCount = giftData.todayBuyCount + 1
						giftData.totalBuyCount = giftData.totalBuyCount + 1

						self.yOffset = giftScroll:getOffsetY()
						self:initScrollLayer()
						DGMsgBox.new({ text = string.format("购买成功！获得道具 %s", giftData.name, giftData.num), type = 1})

						if index == 1 then
							game.role:dispatchEvent({ name = "notifyNewMessage", type = "vip0Gift" })
						end
						return "__REMOVE__"
					end)
				end,
			})
		buyBtn:setEnable(enabled)
		buyBtn:getLayer():anch(1, 0.5):pos(cellSize.width - 10, cellSize.height / 2 +15):addTo(cellBg)
		if enabled and index == 1 then
			self.buyBtn = buyBtn:getLayer()
			uihelper.newMsgTag(self.buyBtn, ccp(-10, -10))
			game:activeSpecialGuide(504)
		end

		if enabled then
			local priceIco=display.newSprite(GlobalRes.."yuanbao.png"):anch(0,0.5):pos(10,buyBtn:getLayer():getContentSize().height/2):scale(0.8,0.5):addTo(buyBtn:getLayer())
		end
		
		local price=ui.newTTFLabelWithStroke({text = enabled and storeCsv:getPriceByCount(giftData.id, giftData.totalBuyCount + 1) or "已购买",
			size=22,color=display.COLOR_WHITE,strokeColor=uihelper.hex2rgb("#242424")
			}):anch(0,0.5):pos(enabled and 42 or 20,buyBtn:getLayer():getContentSize().height/2):addTo(buyBtn:getLayer())

		return cellBg:anch(0,0)
	end

	local keys = table.keys(self.itemDatas)
	table.sort(keys)

	local cellSize = CCSizeMake(layerSize.width, 130)
	local xBegin = 0
	local xInterval = cellSize.width - 10 - 2 * 364

	for index = 1, keys[#keys], 2 do
		local cellNode = display.newNode()
		cellNode:size(cellSize)

		local leftNode = createScrollNode(self.itemDatas[index], index)
		leftNode:anch(0, 0):pos(xBegin, 0):addTo(cellNode)

		local rightgiftData = self.itemDatas[index+1]
		if rightgiftData then
			local rightNode = createScrollNode(rightgiftData, index + 1)
			rightNode:anch(0, 0):pos(xBegin + 370	 + xInterval, 0):addTo(cellNode)
		end

		giftScroll:addChild(cellNode)
	end

	giftScroll:alignCenter()
	giftScroll:setOffset(self.yOffset)
	giftScroll:getLayer():pos(0, 0):addTo(layer)
end


return GiftItemLayer