-- 奖励内容展示：
local AwardRes = "resource/ui_rc/carbon/award/"
local ShopRes  = "resource/ui_rc/shop/"

local GiftShowlayer = class("GiftShowlayer", function() 
	return display.newLayer(AwardRes .. "box_small_bg.png") 
end)

function GiftShowlayer:ctor(params)

	self:setNodeEventEnabled(true)
	self.params = params or {}
	self.priority = params.priority or -129
	self.size = self:getContentSize()

	self:setMaskLayer()
	self:initUIByData()
end

function GiftShowlayer:setMaskLayer()
	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority - 2,})
end 

function GiftShowlayer:initUIByData()
	display.newSprite(AwardRes .. "gift_title.png")
		:pos(self.size.width / 2, self.size.height - 35):addTo(self)

	--头像初始化
	local record = {}
	if tostring(self.params.layertype) == "levelup" then
		record = levelGiftCsv:getDataByIndex(tonumber(self.params.index))
	elseif tostring(self.params.layertype) == "newserver" then
		record = newServerCsv:getDataByDay(tonumber(self.params.index))
	end

	local giftTable = record.itemtable or self.params.items
	local iconCount = table.nums(giftTable)

	local xBegin = 107
	local xInterval = (self.size.width - 4 * 106 - 2 * 60) / 3
	for i = 1, iconCount do
		if iconCount < 5 then
			local itemId   = giftTable[i].itemId
			local itemCount = giftTable[i].itemCount
			iData = itemCsv:getItemById(tonumber(itemId))
			local isHero = iData.type == ItemTypeId.Hero
			local icon = self:getItemIcon(itemId,itemCount)
			icon:anch(0.5, 0):pos(xBegin + (i - 1) * (106 + xInterval), isHero and 120 or 130):addTo(self)
		end
	end

	--确定button：
	self.sureBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png"},
		{	
			text = { text = "确定", size = 32, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			priority = self.priority - 5,
			callback = function() 
				if self.params.callback then self.params.callback() end
				self:getLayer():removeSelf()
			end,
		}):getLayer()
	self.sureBtn:anch(0.5, 0):pos(self.size.width / 2, 15):addTo(self)
end 


function GiftShowlayer:getSureBtn()
	return self.sureBtn
end

--头像subview
function GiftShowlayer:getItemIcon(itemId,itemCount)
	local iData = nil
	local haveNum
	local xx = self.size.width * 0.25
	local yy = self.size.height * 0.81

	iData = itemCsv:getItemById(tonumber(itemId))
	local isHero = iData.type == ItemTypeId.Hero
	local frame = ItemIcon.new({ itemId = tonumber(itemId), }):getLayer()
	frame:setColor(ccc3(100, 100, 100))

	-- --数量
	ui.newTTFLabel({ text = "x"..itemCount, size = 20, color = display.COLOR_GREEN })
		:anch(1, 0)
		:pos(frame:getContentSize().width - (isHero and 14 or 5), isHero and 14 or 5)
		:addTo(frame)

	-- --名称
	ui.newTTFLabel({ text = iData.name, size = 20, color = display.COLOR_BLACK })
		:anch(0.5, 0.5)
		:pos(frame:getContentSize().width * 0.5, isHero and -10 or -frame:getContentSize().height * 0.18)
		:addTo(frame)

	return frame
end 


function GiftShowlayer:getLayer()
	return self.mask:getLayer()
	-- return self
end

return GiftShowlayer