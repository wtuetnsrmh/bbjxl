local GlobalRes = "resource/ui_rc/global/"
local GiftRes = "resource/ui_rc/gift/"

local PriceMap = {
	["1"] = { field = "yuanbao", res = "resource/ui_rc/global/yuanbao.png" },
	["2"] = { field = "money", res = "resource/ui_rc/global/yinbi.png" },
	["3"] = { field = "zhangongNum", res = "resource/ui_rc/pvp/zhangong.png" },
	["4"] = { field = "heroSoulNum", res = "resource/ui_rc/global/herosoul.png" },
	["5"] = { field = "reputation", res = "resource/ui_rc/expedition/prestige.png" },
	["6"] = { field = "starSoulNum", res = "resource/ui_rc/global/starsoul.png" },
}

local BuyItemTipsLayer = class("BuyItemTipsLayer", function()
	return display.newLayer(GiftRes .. "assign_got_bg.png")
end)

BuyItemTipsLayer.ItemLegend = 1
BuyItemTipsLayer.ItemPvp = 2

function BuyItemTipsLayer:ctor(params)
	self.params = params or {}
	self.priority = params.priority or -130

	self.shopIndex = params.shopIndex
	self.shopId = params.shopId
	self.priceType = params.priceType

	self.size = self:getContentSize()
	self:initUI()
end 

function BuyItemTipsLayer:initUI()
	local shopItem, haveResource 

	local shopItemData = shopCsv:getShopData(tonumber(self.shopId))
	local priceData = PriceMap[tostring(self.priceType)]

	local haveResource = game.role[priceData.field]

	--遮罩层：
	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1,ObjSize = self.size,
		click = function() end,
		clickOut = function() self.mask:remove() end,
	})

	local itemData = itemCsv:getItemById(shopItemData.itemId)
	local frame = ItemIcon.new({ itemId = shopItemData.itemId }):getLayer():anch(0,1)
	frame:setColor(ccc3(100, 100, 100))
	frame:pos(30, self.size.height - 40):addTo(self)

	local haveNum
	if shopItemData.itemTypeId == ItemTypeId.HeroFragment then              --武将卡牌
		haveNum = game.role.fragments[shopItemData.itemId]
	elseif shopItemData.itemTypeId == ItemTypeId.Hero then
		haveNum = 0
		for _, hero in pairs(game.role.heros) do
			if hero.type == shopItemData.itemId - 1000 then
				haveNum = haveNum + 1
			end
		end
	elseif shopItemData.itemTypeId == ItemTypeId.EquipFragment then
		haveNum = game.role.equipFragments[shopItemData.itemId]
	elseif shopItemData.itemTypeId == ItemTypeId.Equip then
		haveNum = 0
		for _, equip in pairs(game.role.equips) do
			if equip.type == shopItemData.itemId - Equip2ItemIndex.ItemTypeIndex then
				haveNum = haveNum + 1
			end
		end
	else
		haveNum = game.role.items[shopItemData.itemId] and game.role.items[shopItemData.itemId].count or 0
	end

	local xPos = 143
	local text = ui.newTTFLabel({ text = itemData.name, size = 28, font = ChineseFont })
		:anch(0, 1):pos(xPos, self.size.height - 50)
		:addTo(self)
	-- --数量
	local itemCount = "X"..tostring(self.params.itemNum)
	ui.newTTFLabel({ text = itemCount, size = 28, font = ChineseFont, color = uihelper.hex2rgb("#7ce810") })
		:anch(0, 1):pos(xPos + text:getContentSize().width, self.size.height - 50)
		:addTo(self)
	-- --拥有数量
	ui.newTTFLabel({ text = string.format("拥有%d个", haveNum or 0), size = 20 })
		:anch(0, 1):pos(xPos, self.size.height - 94)
		:addTo(self)

	uihelper.createLabel({ text = shopItemData.desc, size = 22, width = self.size.width - 80, color = uihelper.hex2rgb("#533a27") })
		:anch(0.5, 0.5):pos(self.size.width / 2, 211):addTo(self)

	local buyNum = tostring(self.params.itemNum)
	ui.newTTFLabel({ text = "购买: "..buyNum.."件", size = 22, color = uihelper.hex2rgb("#533a27")})
		:anch(1, 0.5):pos(self.size.width / 2 - 20, 113):addTo(self)

	display.newSprite(priceData.res)
		:scale(0.8):anch(0, 0.5):pos(self.size.width / 2 + 20, 113):addTo(self)

	local needMoney = tonumber(shopItemData.price[tostring(self.priceType)]) * tonumber(self.params.itemNum)
	local canBuy = needMoney <= haveResource

	ui.newTTFLabelWithStroke({ text = needMoney, size = 22, color = canBuy and display.COLOR_GREEN or display.COLOR_RED })
		:anch(0, 0.5):pos(270, 113):addTo(self)
	--购买btn
	local buyBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png", "middle_disabled.png"},
		{	
			priority = self.priority,
			text = { text = "购买", size = 26, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
				self.params.callback()
				self:getLayer():removeSelf()
			end,
		})
	buyBtn:setEnable(canBuy)
	buyBtn:getLayer():anch(0.5, 0):pos(self.size.width * 0.5, 20)
		:addTo(self)
end

function BuyItemTipsLayer:getLayer()
	return self.mask:getLayer()
end

return BuyItemTipsLayer