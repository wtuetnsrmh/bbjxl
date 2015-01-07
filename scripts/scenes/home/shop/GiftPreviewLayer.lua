-- vip礼包预览界面
-- by yangkun
-- 2014.7.1

local ShopRes = "resource/ui_rc/shop/"
local ReChargeRes = "resource/ui_rc/shop/recharge/"
local VipRes = "resource/ui_rc/shop/vip/"
local GiftRes = "resource/ui_rc/shop/gift/"
local GlobalRes = "resource/ui_rc/global/"

local GiftPreviewLayer = class("GiftPreviewLayer", function()
	return display.newLayer( GiftRes .. "preview_bg.png")
end)

GiftPreviewLayer.TYPE_VIEW = 1
GiftPreviewLayer.TYPE_USE = 2

function GiftPreviewLayer:ctor(params)
	params = params or {}

	self.size = self:getContentSize()
	self.itemId = params.itemId
	self.itemData = itemCsv:getItemById(self.itemId)
	self.parent = params.parent
	self.type = params.type or GiftPreviewLayer.TYPE_VIEW

	self.priority = params.priority or -130
	self.yOffset = 0

	self:initUI()
end

function GiftPreviewLayer:initUI()
	self:anch(0.5,0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({item = self, priority = self.priority})

	-- 关闭按钮
	self.closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"}, {
			touchScale = 1.5,
			priority = self.priority -1,
			callback = function() self:getLayer():removeSelf() end
		}):getLayer()
	self.closeBtn:anch(1,1):pos(self.size.width, self.size.height):addTo(self)

	-- title
	display.newSprite(GiftRes .. "preview_text.png")
	:anch(0.5,1):pos(self.size.width/2, self.size.height - 30):addTo(self)

	ui.newTTFLabelWithStroke({ text = string.format("%s包含以下物品", self.itemData.name), size = 25, font = ChineseFont, color = uihelper.hex2rgb("#ffda2b"), strokeColor = uihelper.hex2rgb("#880d0d"), strokeSize =2 })
	:anch(0.5,0):pos(self.size.width/2, self.size.height - 121):addTo(self)

	self:initScrollLayer()

	if self.type == GiftPreviewLayer.TYPE_USE then
		local useBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png"}, {
				text = {text = "领取", size = 22, font = ChineseFont, color = display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
				callback = function()
					local itemUseRequest = { roleId = game.role.id, param1 = self.itemData.itemId, param2 = 1 }	
					local bin = pb.encode("SimpleEvent", itemUseRequest)
					game:sendData(actionCodes.ItemUseRequest, bin)
					game:addEventListener(actionModules[actionCodes.ItemUseResponse], function(event)
						self.parent:prepareBagTableData()
						local itemTableContentOffsetY = self.parent.tableView:getContentOffset().y
						self.parent.tableView:reloadData()
						if self.parent.tableView:getContentSize().height<490 then
							itemTableContentOffsetY=490-self.parent.tableView:getContentSize().height
						end
						self.parent.tableView:setContentOffset(ccp(0,itemTableContentOffsetY), false)

						self:getLayer():removeSelf()

						return "__REMOVE__"
					end)
				end,
				priority = self.priority - 2
			})
		useBtn:getLayer():anch(0.5,0):pos(self.size.width/2, 20):addTo(self)
	end
end

function GiftPreviewLayer:initScrollLayer()
	local layer = display.newColorLayer(ccc4(100,100,100,100))
	layer:size(self.type == GiftPreviewLayer.TYPE_VIEW and CCSizeMake(710, 398) or CCSizeMake(710, 370))

	function createItemCell(itemId, count)
		local cellBg = display.newSprite(GiftRes .. "preview_cellbg.png")
		local cellSize = cellBg:getContentSize()
		local itemData = itemCsv:getItemById(itemId)

		local itemIcon = ItemIcon.new({itemId = itemId, 
			priority = self.priority -1,
			callback = function()
			end,})
		itemIcon:getLayer():scale(0.8):anch(0,0.5):pos(10, cellSize.height/2):addTo(cellBg)

		ui.newTTFLabelWithStroke({ text = itemData.name, size = 24, font = ChineseFont, color = uihelper.hex2rgb("#06ff12"), strokeColor = uihelper.hex2rgb("#4d2a1d"), strokeSize =2 })
		:anch(0,0):pos(100, cellSize.height - 36):addTo(cellBg)

		if itemData.type == ItemTypeId.GoldCoin then
			ui.newTTFLabelWithStroke({ text = "x" .. count, size = 24, font = ChineseFont, color = uihelper.hex2rgb("#06ff12"), strokeColor = uihelper.hex2rgb("#4d2a1d"), strokeSize =2 })
			:anch(0,0):pos(150, cellSize.height - 36):addTo(cellBg)
			count = 1
		end

		uihelper.createLabel({text = itemData.desc, size = 20, width = 432, color = uihelper.hex2rgb("#4d2a1d")})
		:anch(0,1):pos(99, cellSize.height - 40):addTo(cellBg)

		ui.newTTFLabelWithStroke({text = string.format("数量: %d", count), size = 25, font = ChineseFont, color = uihelper.hex2rgb("#fffefe"), strokeColor = uihelper.hex2rgb("#4d2a1d"), strokeSize =2 })
		:anch(0,0.5):pos(566, cellSize.height/2):addTo(cellBg)

		return cellBg
	end

	local itemScrollView = DGScrollView:new({ size = layer:getContentSize(), priority = self.priority -1, divider = 10})
	for itemId, count in pairs(self.itemData.itemInclude) do
		local cell = createItemCell(tonum(itemId), tonum(count))
		cell:anch(0,0)
		itemScrollView:addChild(cell)
	end
	itemScrollView:alignCenter()
	itemScrollView:getLayer():anch(0,0):pos(0,0):addTo(layer)

	if self.type == GiftPreviewLayer.TYPE_VIEW then
		layer:anch(0,0):pos(82, self.size.height - 524):addTo(self)
	else
		layer:anch(0,0):pos(82, self.size.height - 496):addTo(self)
	end
end

function GiftPreviewLayer:getLayer()
	return self.mask:getLayer()
end

return GiftPreviewLayer
