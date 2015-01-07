--
-- Author: yzm
-- Date: 2014-10-15 13:46:51
--奖励显示层

local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"
local ExpeditonRes = "resource/ui_rc/expedition/"

local ExpeditionAwardLayer = class("ExpeditionAwardLayer", function(params) 
	return display.newLayer(ExpeditonRes .. "bg_award.png") 
end)

function ExpeditionAwardLayer:ctor(params)

	params = params or {}

	self.priority = params.priority or -129
	self.parent = params.parent
	self.items=params.items or {}

	self.mapId = params.mapId
	-- self.boxIndex = params.boxIndex
	-- self.totalStarNum = params.totalStarNum

	self.callback = params.callback
	self.dismissCallback = self.callback

	-- self.tipsTag = 7878

	self:initUI()
	self:initContentLayer()

end

function ExpeditionAwardLayer:initUI()
	self.size = self:getContentSize()

	ui.newTTFLabel({text="你将得到以下奖励",size=24,font=ChineseFont,color = uihelper.hex2rgb("#ffd200")}):anch(0.5,1)
		:pos(self.size.width/2,self.size.height-23):addTo(self)

	self:anch(0.5,0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self , priority = self.priority, 
		click = function() 
			self.mask:remove() 
			self.dismissCallback()
		end})
end

function ExpeditionAwardLayer:initContentLayer()
	if self.contentLayer then
		self.contentLayer:removeSelf()
	end

	self.contentLayer = display.newLayer()
	self.contentLayer:size(self:getContentSize())
	self.contentLayer:addTo(self)
	local contentSize = self:getContentSize()

	-- 灰色底板
	local itemBg = display.newLayer()
	itemBg:size(CCSizeMake(554, 164))
	itemBg:anch(0.5, 0):pos(contentSize.width / 2, contentSize.height - 233):addTo(self.contentLayer)

	local awardItems = {}
	for _, pbItem in ipairs(self.items) do
		awardItems[#awardItems + 1] = {
    		id = pbItem.id,
    		itemId = pbItem.itemId,
    		itemTypeId = pbItem.itemTypeId,
    		num = pbItem.num
    	}
	end
	local startX = 40
	local index = -1
	for _, itemInfo in pairs(awardItems) do
		local itemId = tonumber(itemInfo.itemId)--itemCsv:calItemId(itemInfo) 
		
		local itemData = itemCsv:getItemById(itemId)

		local itemFrame = ItemIcon.new({ itemId = itemId, 
					callback = function() 
						self:showItemTaps(itemId,itemInfo.num,itemData.type)
					end,
					priority = self.priority - 2,
				}):getLayer()
		itemFrame:anch(0.5,0.5):pos(itemBg:getContentSize().width/2 + index * 140, itemBg:getContentSize().height/2 + 30):addTo(itemBg)

		local itemNumLabel=ui.newTTFLabelWithShadow({text = "x"..itemInfo.num, size = 24, color = display.COLOR_WHITE,strokeSize=2
		,strokeColor=uihelper.hex2rgb("#242424")})
		:anch(0,0):pos(itemFrame:getContentSize().width - 30, 10):addTo(itemFrame)
		itemNumLabel:pos(itemFrame:getContentSize().width-itemNumLabel:getContentSize().width,10)

		index = index + 1
	end

	local useBtn = DGBtn:new(ExpeditonRes , {"btn_normal.png", "btn_pressed.png"}, {
			scale=0.8,
			text = { text = "确定", size = 28, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
				self.callback()
				self.mask:remove() 
			end,
			priority = self.priority - 2
		})
	useBtn:getLayer():anch(0.5,0):pos(contentSize.width/2, 30):addTo(self.contentLayer)
	
end

function ExpeditionAwardLayer:getLayer()
	return self.mask:getLayer()
end

function ExpeditionAwardLayer:showItemTaps(itemId,itemNum,itemType)
	self:purgeItemTaps()
	local itemTipsView = require("scenes.home.ItemTipsLayer")
	local itemTips = itemTipsView.new({
		itemId = itemId,
		itemNum = itemNum,
		itemType = itemType,
		})
	display.getRunningScene():addChild(itemTips:getLayer())
	itemTips:setTag(1000)
end

function ExpeditionAwardLayer:purgeItemTaps()
	if display.getRunningScene():getChildByTag(1000) then
		display.getRunningScene():getChildByTag(1000):removeFromParent()
	end
end

return ExpeditionAwardLayer