local GiftRes = "resource/ui_rc/gift/"
local GlobalRes = "resource/ui_rc/global/"

local AwardSignGotLayer = class("AwardSignGotLayer", function()
	return display.newLayer(GiftRes .. "assign_got_bg.png")
end)

function AwardSignGotLayer:ctor(params)
	params = params or {}

	self.size = self:getContentSize()
	self.priority = params.priority or -130

	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1 })

	local itemIcon = ItemIcon.new({ itemId = params.itemId }):getLayer()
	itemIcon:anch(0, 0.5):pos(30, self.size.height - 90):addTo(self)
	DGRichLabel.new({ text = params.name, size = 28, font = ChineseFont, color = display.COLOR_WHITE })
		:anch(0, 0.5):pos(155, self.size.height - 90):addTo(self)
	--vip双倍标记
	if params.doubleVipLevel > 0 then
		local itemData = itemCsv:getItemById(params.itemId)
		display.newSprite(GiftRes .. string.format("vip_%d_double.png", params.doubleVipLevel))
			:anch(0, 1):pos(itemData.type == ItemTypeId.Hero and 5 or 0, itemIcon:getContentSize().height):addTo(itemIcon)
	end

	local descBg = display.newSprite()
	descBg:size(343,127)
	descBg:anch(0.5, 0):pos(self.size.width / 2, self.size.height - 285):addTo(self)
	local descSize = descBg:getContentSize()
	ui.newTTFLabel({ text = params.desc,color=uihelper.hex2rgb("#533a27"), size = 22, dimensions = CCSizeMake(descSize.width - 20, descSize.height - 30) })
		:anch(0.5,1):pos(descSize.width / 2, descSize.height+10):addTo(descBg)

	local dayTipsBg = display.newSprite()
	dayTipsBg:size(343,45)
	dayTipsBg:anch(0.5, 0):pos(self.size.width / 2, self.size.height - 340):addTo(self)
	ui.newTTFLabel({ text = string.format("本月签到%d天", params.day), size = 22,color=uihelper.hex2rgb("#533a27")})
		:pos(dayTipsBg:getContentSize().width / 2, dayTipsBg:getContentSize().height / 2):addTo(dayTipsBg)

	local recvBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png"},
		{
			text = { text = "领取", size = 26, font = ChineseFont, strokeColor = display.COLOR_BUTTON_STROKE },
			priority = self.priority,
			callback = function()
				local signRequest = { roleId = game.role.id }
				local bin = pb.encode("SimpleEvent", signRequest)
				game:sendData(actionCodes.RoleSignRequest, bin)
				game:addEventListener(actionModules[actionCodes.RoleSignResponse], function(event)
					local result = pb.decode("SimpleEvent", event.data)
					if result.param1 == 0 then
						self:getLayer():removeSelf()
						if params.onComplete() then params.onComplete() end
					end
				end)
			end,
		}):getLayer()
	recvBtn:anch(0.5, 0):pos(self.size.width / 2, 25):addTo(self)
end

function AwardSignGotLayer:getLayer()
	return self.mask:getLayer()
end

return AwardSignGotLayer