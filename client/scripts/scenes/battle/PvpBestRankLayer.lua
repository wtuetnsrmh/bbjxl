local HeroEvolRes = "resource/ui_rc/hero/evolution/"
local PvpRes = "resource/ui_rc/pvp/"

local PvpBestRankLayer = class("PvpBestRankLayer", function() 
	return display.newLayer(HeroEvolRes .. "evolution_bg.png") 
end)


function PvpBestRankLayer:ctor(params)
	self.params = params or {}
	self.priority = params.priority or -1000
	self.size = self:getContentSize()
	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority, ObjSize = self.size, clickOut = function()
		-- self.mask:remove() 
	end})

	self.oldBestRank = params.oldBestRank
	self.bestRank = params.bestRank
	self.yuanbao = params.yuanbao
	self:initUI()
end

function PvpBestRankLayer:initUI()
	local EndRes = "resource/ui_rc/carbon/end/"
	local lightBg = display.newSprite(EndRes .. "light.png")
	lightBg:pos(self.size.width / 2, self.size.height - 20):addTo(self, -1)
	lightBg:runAction(CCRepeatForever:create(CCRotateBy:create(1, 80)))
	--标题
	display.newSprite(PvpRes .. "best_text.png")
		:anch(0.5, 0.5):pos(self.size.width/2, self.size.height - 20):addTo(self)
	--历史最高排名
	local xPos, yPos = 187, 335
	display.newSprite(PvpRes .. "best_item_bg.png")
		:anch(0.5, 0.5):pos(self.size.width/2, yPos):addTo(self)

	local text = ui.newTTFLabel({text = "历史最高排名：", font = ChineseFont, size = 20, color = uihelper.hex2rgb("#ffdc7d")})
	text:anch(0, 0.5):pos(xPos, yPos):addTo(self)
	ui.newTTFLabel({text = self.oldBestRank, font = ChineseFont, size = 36, color = uihelper.hex2rgb("#00fffc")})
		:anch(0, 0):pos(text:getContentSize().width, -5):addTo(text)
	yPos = yPos - 65
	--当前排名	
	text = ui.newTTFLabel({text = "当前排名：", font = ChineseFont, size = 20, color = uihelper.hex2rgb("#ffdc7d")})
	text:anch(0, 0.5):pos(xPos, yPos):addTo(self)
	text = ui.newTTFLabel({text = self.bestRank, font = ChineseFont, size = 36, color = uihelper.hex2rgb("#00fffc")})
			:anch(0, 0):pos(text:getContentSize().width, -5):addTo(text)
	ui.newTTFLabel({text = "(        " .. (self.oldBestRank - self.bestRank) .. "  )", font = ChineseFont, size = 20, color = uihelper.hex2rgb("#ffdc7d")})
		:anch(0, 0):pos(text:getContentSize().width + 3, 5):addTo(text)
	display.newSprite(PvpRes .. "up_arrow.png"):anch(0, 0):pos(text:getContentSize().width + 13, 5):addTo(text)
	yPos = yPos - 65
	--可获奖励
	display.newSprite(PvpRes .. "best_item_bg.png")
		:anch(0.5, 0.5):pos(self.size.width/2, yPos):addTo(self)

	text = ui.newTTFLabel({text = "可获奖励：", font = ChineseFont, size = 20, color = uihelper.hex2rgb("#ffdc7d")})
	text:anch(0, 0.5):pos(xPos, yPos):addTo(self)
	display.newSprite(GlobalRes .. "yuanbao.png"):anch(0, 0):pos(text:getContentSize().width, -4):addTo(text)
	ui.newTTFLabel({text = self.yuanbao, font = ChineseFont, size = 22, color = uihelper.hex2rgb("#f4f4f4")})
		:anch(0, 0):pos(text:getContentSize().width + 55, -3):addTo(text)
	--奖励发放提示
	ui.newTTFLabel({text = "奖励将通过邮箱发放", size = 24, color = uihelper.hex2rgb("#7ce810")})
		:anch(0.5, 0):pos(self.size.width/2, 120):addTo(self)

	--按钮
	DGBtn:new(GlobalRes, {"btn_ellipse_normal.png", "btn_ellipse_selected.png"}, {
		priority = self.priority - 1,
		text = {text = "确定", font = ChineseFont, size = 26, strokeColor = display.COLOR_FONT},
		callback = function()
			self.mask:remove()
		end
	}):getLayer():anch(0.5, 0):pos(self.size.width/2, 50):addTo(self)
end

function PvpBestRankLayer:getLayer()
	return self.mask:getLayer()
end

return PvpBestRankLayer