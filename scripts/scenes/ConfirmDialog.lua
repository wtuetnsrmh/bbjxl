local GlobalRes = "resource/ui_rc/global/"

local ConfirmDialog = class("ConfirmDialog", function()
	return display.newLayer("resource/ui_rc/global/confirm_bg.png")
end)

function ConfirmDialog:ctor(params)
	params = params or {}

	self.size = self:getContentSize()
	self.priority = params.priority or -130

	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1 })

	self.tips = ui.newTTFRichLabel(params.showText):anch(0.5, 1):pos(self.size.width / 2, 160):addTo(self)

	params.button1Data = params.button1Data or {}
	params.button2Data = params.button2Data or {}
	local btnNum = table.nums(params.button2Data) > 0 and 2 or 1
	if btnNum == 1 then
		self.button1 = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png"},
			{	
				priority = self.priority,
				text = { text = params.button1Data.text or "确定", size = 28, font = ChineseFont, strokeColor = display.COLOR_FONT, strokeSize = 2},
				callback = function()
					local canRemove = true
					if params.button1Data.callback then
						canRemove = params.button1Data.callback()
					end
					
					if canRemove == nil or canRemove == true then
						self:getLayer():removeSelf()
					end
				end,
			}):getLayer()
		self.button1:anch(0.5, 0):pos(self.size.width / 2, 30):addTo(self)
	else
		self.button1 = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png"},
			{	
				priority = self.priority,
				text = { text = params.button1Data.text or "取消", size = 28, font = ChineseFont, strokeColor = display.COLOR_FONT, strokeSize = 2},
				callback = function()
					local canRemove = true
					if params.button1Data.callback then
						canRemove = params.button1Data.callback()
					end
					
					if canRemove == nil or canRemove == true then
						self:getLayer():removeSelf()
					end
				end,
			}):getLayer()
		self.button1:anch(1, 0):pos(self.size.width / 2 - 40, 30):addTo(self)

		self.button2 = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png"},
			{	
				priority = self.priority,
				text = { text = params.button2Data.text or "确定", size = 28, font = ChineseFont, strokeColor = display.COLOR_FONT, strokeSize = 2},
				callback = function()
					local canRemove = true
					if params.button2Data.callback then
						canRemove = params.button2Data.callback()
					end
					
					if canRemove == nil or canRemove == true then
						self:getLayer():removeSelf()
					end
				end,
			}):getLayer()
		self.button2:anch(0, 0):pos(self.size.width / 2 + 40, 30):addTo(self)
	end
end

function ConfirmDialog:getButton(index)
	return self["button" .. index]
end

function ConfirmDialog:getLayer()
	return self.mask:getLayer()
end

return ConfirmDialog