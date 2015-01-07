-- 新UI 礼包详情层
-- by yangkun
-- 2014.4.30

local HomeRes = "resource/ui_rc/home/"
local HeroRes = "resource/ui_rc/hero/"
local GlobalRes = "resource/ui_rc/global/"
local ShopRes = "resource/ui_rc/shop/"

local GiftBagLayer = class("GiftBagLayer", function() return display.newLayer() end)

GiftBagLayer.TYPE_VIEW = 1
GiftBagLayer.TYPE_USE = 2

function GiftBagLayer:ctor(params)
	params = params or {}
	self.priority = params.priority or -129
	self.itemId = params.itemId
	self.type = params.type or GiftBagLayer.TYPE_VIEW
	self.parent = params.parent

	self:initUI()

	pushLayerAction(self,true)
end

function GiftBagLayer:initUI()

	local bg = display.newSprite( ShopRes .. "gift_bg.png")
	bg:anch(0,0):pos(0,0):addTo(self)
	self:size(bg:getContentSize())
	local contentSize = self:getContentSize()

	self:anch(0.5,0.5):pos(display.cx, display.cy - 20)
	self.mask = DGMask:new({item = self, priority = self.priority})

	-- 关闭按钮
	self.closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"}, {
			touchScale = 1.5,
			priority = self.priority -1,
			callback = function() self:getLayer():removeSelf() end
		}):getLayer()
	self.closeBtn:anch(1,0):pos(contentSize.width, contentSize.height):addTo(self)

	-- 标题
	if self.type == GiftBagLayer.TYPE_VIEW then
		local title = display.newSprite( ShopRes .. "gift_title.png")
		title:anch(0.5,1):scale(0.8):pos(contentSize.width/2, contentSize.height + 30):addTo(self)
	else
		-- local titleLabel = ui.newTTFLabelWithStroke({ text = "礼包领取", size = 34, font = ChineseFont, color = display.COLOR_WHITE, strokeColor = display.COLOR_BLACK })
		-- :anch(0.5, 1):pos(contentSize.width/2, contentSize.height - 14):addTo(self)
		-- 红色底图
		local titleSp = display.newSprite(ShopRes .. "recharge_titlebg.png")
			:anch(0.5, 0.5):pos(contentSize.width/2, contentSize.height - 33):addTo(self)
		local title = display.newSprite( ShopRes .. "got_title.png")
			:anch(0.5, 0.5):pos(titleSp:getContentSize().width * 0.5, titleSp:getContentSize().height * 0.5 + 15):addTo(titleSp)
		
		--title:anch(0.5,0.5):pos(contentSize.width/2, contentSize.height ):addTo(self)
	end

	local itemData = itemCsv:getItemById(self.itemId)

	local scrollSize = self.type == GiftBagLayer.TYPE_VIEW and CCSizeMake(460, 420) or CCSizeMake(460, 340)

	self.itemScrollView = DGScrollView:new({ size = scrollSize, priority = self.priority -1, divider = 8})
	for itemId, count in pairs(itemData.itemInclude) do
		local cell = self:createItemCell(itemId, count)
		cell:anch(0,0)
		self.itemScrollView:addChild(cell)
	end
	self.itemScrollView:alignCenter()
	local y = self.type == GiftBagLayer.TYPE_VIEW and 10 or 90
	self.itemScrollView:getLayer():anch(0.5,0):pos(contentSize.width/2,y):addTo(self)
	self.itemScrollView:effectIn(0.2)

	if self.type == GiftBagLayer.TYPE_USE then
		local useBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png"}, {
				text = {text = "确定", size = 22, font = ChineseFont, color = display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
				callback = function()
					local itemUseRequest = { roleId = game.role.id, param1 = itemData.itemId, param2 = 1 }	
					local bin = pb.encode("SimpleEvent", itemUseRequest)
					game:sendData(actionCodes.ItemUseRequest, bin)
					game:addEventListener(actionModules[actionCodes.ItemUseResponse], function(event)
						self.parent:prepareBagTableData()
						local itemTableContentOffsetY = self.parent.tableView:getContentOffset().y

						self.parent.tableView:reloadData()
						self.parent.tableView:setContentOffset(ccp(0,itemTableContentOffsetY), false)

						self:getLayer():removeSelf()

						return "__REMOVE__"
					end)
				end,
				priority = self.priority - 2
			})
		useBtn:getLayer():anch(0.5,0.5):pos(contentSize.width/2, 46):addTo(self)
	end
end

function GiftBagLayer:createItemCell(itemId, count)
	local itemData = itemCsv:getItemById(tonum(itemId))

	local bg = display.newSprite( HeroRes .. "choose_bg.png" )
		
	local iconBg = ItemFrame.new({itemId = tonum(itemId)})
	iconBg:getLayer():anch(0,0):pos(10, 10):addTo(bg)

	-- 数量
	ui.newTTFLabelWithStroke({text = string.format("数量:%d", tonum(count)), size = 24, color = display.COLOR_GREEN, strokerColor = display.COLOR_BLACK, strokeSize = 2 })
	:anch(0,0.5):pos(330, bg:getContentSize().height - 22):addTo(bg)

	-- 名字
	ui.newTTFLabelWithStroke({text = itemData.name, size = 26, color = display.COLOR_WHITE, font = ChineseFont, strokeColor = display.COLOR_BLACK, strokeSize = 2 })
		:anch(0,0.5):pos(30, bg:getContentSize().height - 24):addTo(bg)

	-- 描述
	ui.newTTFLabel({text = itemData.desc, width = 200, size = 20, color = display.COLOR_DARKYELLOW, dimensions = CCSizeMake(260, 95)})
		:anch(0,0):pos(120, 10):addTo(bg)

	return bg
end

function GiftBagLayer:getLayer()
	return self.mask:getLayer()
end

return GiftBagLayer

