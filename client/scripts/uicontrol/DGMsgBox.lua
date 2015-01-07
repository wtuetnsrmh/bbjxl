local GlobalRes = "resource/ui_rc/global/"
local NGlobalRes = "resource/ui_rc/global/"

DGMsgBox = class("DGMsgBox", function() return display.newLayer() end)

function DGMsgBox:ctor(params)
	params = params or {}
	local msgId = params.msgId or 0
	local msgData = sysMsgCsv:getMsgbyId(msgId)
	self.color = params.color or display.COLOR_WHITE
	self.text = msgData and msgData.text or params.text
	self.type = msgData and msgData.type or params.type

	if self.type == 1 then
		self:flashMsg()
	elseif self.type == 2 then
		self.button1Data = params.button1Data or {}
		self.button2Data = params.button2Data or {}
		self:showBox()
	end
end

function DGMsgBox:flashMsg()
	display.getRunningScene():removeChildByTag(100)

	local msgBg = display.newSprite(GlobalRes .. "flash_msg_bg.png")
	local bgSize = msgBg:getContentSize()
	self:size(bgSize)
	msgBg:anch(0, 0):pos(0, 0):addTo(self)

	--更改为RichLabel:
	local descLabel = ui.newTTFRichLabel({ 
		text = self.text, 
		align = ui.TEXT_ALIGN_CENTER, 
		dimensions = CCSizeMake(bgSize.width - 20, bgSize.height - 20), 
		size = 24,
		color = self.color,
	})
	descLabel:pos(bgSize.width / 2, bgSize.height / 2):addTo(msgBg)

	self:anch(0.5, 0.5):pos(display.cx, display.cy):addTo(display.getRunningScene(),99999, 100)
	self:runAction(transition.sequence({
		CCDelayTime:create(1),
		CCFadeOut:create(1),
		CCRemoveSelf:create(),
	}))
end

--需要更换：
function DGMsgBox:showBox()
	local msgBg = display.newSprite(GlobalRes .. "confirm_bg.png")
	local bgSize = msgBg:getContentSize()
	self:size(bgSize):anch(0.5, 0.5):pos(display.cx, display.cy)
	msgBg:anch(0, 0):pos(0, 0):addTo(self)

	local mask = DGMask:new({ item = self, priority = -9000 })
	mask:getLayer():addTo(display.getRunningScene(), 99999)

	--更改为RichLabel:
	local descLabel = ui.newTTFRichLabel({ 
		text = self.text, 
		align = ui.TEXT_ALIGN_CENTER, 
		dimensions = CCSizeMake(500, 80), 
		color = self.color,
		size = 24,
		 })
	descLabel:anch(0.5, 1):pos(bgSize.width / 2, 180):addTo(self)

	local btnNum = table.nums(self.button2Data) > 0 and 2 or 1
	if btnNum == 1 then
		local button1 = DGBtn:new(NGlobalRes, {"middle_normal.png", "middle_selected.png"},
			{	
				priority = self.button1Data.priority or -9001,
				text = { text = self.button1Data.text or "确定", size = 28, font = ChineseFont, strokeColor = display.COLOR_BLACK, strokeSize = 2},
				callback = function()
					mask:getLayer():removeSelf()
					if self.button1Data.callback then
						self.button1Data.callback()
					end
				end,
			}):getLayer()
		button1:anch(0.5, 0):pos(bgSize.width / 2, 30):addTo(self)
	else
		local button1 = DGBtn:new(NGlobalRes, {"middle_normal.png", "middle_selected.png"},
			{	
				priority = self.button1Data.priority or -9001,
				text = { text = self.button1Data.text or "取消", size = 28, font = ChineseFont, strokeColor = display.COLOR_BLACK, strokeSize = 2},
				callback = function()
					mask:getLayer():removeSelf()
					if self.button1Data.callback then
						self.button1Data.callback()
					end
				end,
			}):getLayer()
		button1:anch(1, 0):pos(bgSize.width / 2 - 40, 25):addTo(self)

		local button2 = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png"},
			{	
				priority = self.button2Data.priority or -9001,
				text = { text = self.button2Data.text or "确定", size = 28, font = ChineseFont, strokeColor = display.COLOR_BLACK, strokeSize = 2},
				callback = function()
					mask:getLayer():removeSelf()
					if self.button2Data.callback then
						self.button2Data.callback()
					end
				end,
			}):getLayer()
		button2:anch(0, 0):pos(bgSize.width / 2 + 40, 25):addTo(self)
	end
end

return DGMsgBox