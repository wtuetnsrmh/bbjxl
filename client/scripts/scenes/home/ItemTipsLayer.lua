local GlobalRes = "resource/ui_rc/global/"

local ItemSourceLayer = import(".ItemSourceLayer")

local ItemTipsLayer = class("ItemTipsLayer", function()
	return display.newLayer(GlobalRes .. "tips_small.png")
end)

function ItemTipsLayer:ctor(params)
	--参数：itemId   itemNum  itemType

	self.params = params or {}
	self.priority = params.priority or -1300 	--优先级设最高
	self.size = nil

	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.size = self:getContentSize()
	self.mask = DGMask:new({ item = self, priority = self.priority + 1 , click = function()
			self:getLayer():removeSelf()
		end})
	self:initUI()

	self:setScale(0.05)
	self:runAction(CCEaseBackOut:create(CCScaleTo:create(0.2, 1)))
end 

function ItemTipsLayer:initUI()
	local itemId = itemCsv:calItemId({ itemTypeId = self.params.itemType, itemId = self.params.itemId })
	local record = itemCsv:getItemById(itemId)

	local itemFrame = ItemIcon.new({ itemId = itemId, priority = self.priority,}):getLayer()
	itemFrame:anch(0, 0.5):setColor(ccc3(100, 100, 100))
	itemFrame:pos(30, self.size.height / 2):addTo(self)

	-- --名称及数量
	local xPos, yPos = 157, 100
	local showNum = tonum(self.params.itemNum)
	local text = ui.newTTFLabel({ text = record.name, size = 26, font = ChineseFont, color = uihelper.hex2rgb("#ffdc7d") })
		:anch(0, 0):pos(xPos, yPos):addTo(self)
	ui.newTTFLabel({ text = "X" .. showNum, size = 26, font = ChineseFont, color = showNum > 0 and uihelper.hex2rgb("#7ce810") or display.COLOR_RED })
		:anch(0, 0):pos(xPos + text:getContentSize().width, yPos):addTo(self)
	-- --描述：
	local content = record.desc
	uihelper.createLabel({ text = record.desc, size = 18, color = display.COLOR_WHITE, width = 226 })
		:anch(0, 1):pos(xPos, self.size.height - 80):addTo(self)

	self.params.showSource = self.params.showSource == nil and true or self.params.showSource
	if self.params.showSource then
		local gotoBtn = DGBtn:new(GlobalRes, {"btn_small_green_nol.png", "btn_small_green_sel.png", "btn_small_dis.png"},
			{
				priority = self.priority,
				text = { text = "获得途径", size = 22, font = ChineseFont },
				callback = function()
					local sourceLayer = ItemSourceLayer.new({ priority = self.priority - 10, itemId = itemId, closeCallback = self.params.closeCallback })
					sourceLayer:getLayer():addTo(display.getRunningScene())
					self:getLayer():removeSelf()
				end,
			})
		if record and record.source and #record.source > 0 then
			gotoBtn:setEnable(true)
		else
			gotoBtn:setEnable(false)
		end
		gotoBtn:getLayer():anch(1, 0.5):pos(self.size.width - 25, self.size.height/2):addTo(self)
	end
end


function ItemTipsLayer:getLayer()
	return self.mask:getLayer()
end

return ItemTipsLayer