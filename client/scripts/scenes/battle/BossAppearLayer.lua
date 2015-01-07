local BattleRes = "resource/ui_rc/battle/"

local BossAppearLayer = class("BossAppearLayer", function(params)
    return display.newLayer()
end)

local TextPosition = {
	[1] = ccp(display.cx - 385, 360),
	[2] = ccp(display.cx - 240, 395),
	[3] = ccp(display.cx - 95, 355),
	[4] = ccp(display.cx + 55, 355),
	[5] = ccp(display.cx + 210, 360),
	[6] = ccp(display.cx + 380, 365),
}

function BossAppearLayer:ctor(params)
	params = params or {}

	self.mask = require("uicontrol.DGMask"):new({ item = self, opacity = 0 })
	self.removeImages = {}

	display.TEXTURES_PIXEL_FORMAT[BattleRes .. "boss_text.png"] = kCCTexture2DPixelFormat_RGBA4444
	display.addSpriteFramesWithFile(BattleRes .. "boss_text.plist", BattleRes .. "boss_text.png")
	
	--boss头像裁剪
	local headStencil = display.newSprite(BattleRes .. "boss_stencil.png")
	self.removeImages[BattleRes .. "boss_stencil.png"] = true

	local bossUnitData = unitCsv:getUnitByType(params.bossInfo.heroType)
	-- local bossImage = display.newSprite(bossUnitData.heroRes)
	-- self.removeImages[bossUnitData.heroRes] = true
	local bossImage=uihelper.createMaskSprite(bossUnitData.cardRes,bossUnitData.heroRes)

	local bossBg = display.newSprite(BattleRes .. "boss_stencil.png")
	bossBg:hide():pos(display.cx, display.cy):addTo(self):setScaleX(1 / 2)
	self.removeImages[BattleRes .. "boss_stencil.png"] = true

	local headClipper = CCClippingNode:create()
	headClipper:setStencil(headStencil)
	headClipper:setInverted(false)
	headClipper:setAlphaThreshold(0)
	headClipper:setPosition(display.cx, display.cy)
	headClipper:setScale(1 / 2)
	headClipper:setVisible(false)
	bossImage:scale(0.75):addTo(headClipper)
	self:addChild(headClipper)

	local bossFrame = display.newSprite(BattleRes .. "frame.png")
	self.removeImages[BattleRes .. "frame.png"] = true
	bossFrame:hide():pos(display.cx, display.cy):addTo(self):setScaleX(1 / 2)

	local textLight = display.newSprite(BattleRes .. "text_light.png")
	self.removeImages[BattleRes .. "text_light.png"] = true
	textLight:pos(0, 0):hide():addTo(self, 1)

	--boss名字
	local bossNameBG = display.newSprite(BattleRes .. "boss_name.png")
	self.removeImages[BattleRes .. "boss_name.png"] = true
	local bossNameTTF = ui.newTTFLabel({text = params.bossInfo.heroName, x = 0, y = 0, size = 48, color = display.COLOR_WHITE})
	bossNameTTF:pos(bossNameBG:getContentSize().width / 2, bossNameBG:getContentSize().height / 2):addTo(bossNameBG)
	bossNameBG:pos(display.width + 300, display.top / 6):addTo(self)

	local function appearEnd()
		local actions = {}
		actions[#actions + 1] = CCDelayTime:create(1)
		actions[#actions + 1] = CCCallFunc:create(function()
			self.mask:remove()
			if params.onComplete then params.onComplete() end
		end)	

		self.mask:getLayer():runAction(transition.sequence(actions))
	end

	--boss动画
	for index = 1, 6 do
		local textSprite = display.newSprite("#text_" .. index .. ".png")
		textSprite:pos(TextPosition[index].x, TextPosition[index].y):addTo(self):hide()

		local actions = transition.sequence({
			CCDelayTime:create(0.1 + 0.1 * index),
			CCCallFunc:create(function() 
				textLight:pos(TextPosition[index].x, TextPosition[index].y):show()

				if index == 5 then
					bossBg:show()
					bossBg:runAction(CCScaleTo:create(0.5, 1, 1))
					bossFrame:show()
					bossFrame:runAction(CCScaleTo:create(0.5, 1, 1))
					headClipper:setVisible(true)
					headClipper:runAction(CCScaleTo:create(0.5, 1))
					--boss名字动画
					bossNameBG:moveTo(0.5, display.cx, display.height / 6)
				end
			end),
			CCShow:create(),
			CCCallFunc:create(function()
				if index == 6 then textLight:removeSelf() appearEnd() end
			end),
		})

		textSprite:runAction(actions)
	end
end

function BossAppearLayer:getLayer()
	return self.mask:getLayer()
end

function BossAppearLayer:onExit()
	for name, bool in pairs(self.removeImages) do
		display.removeSpriteFrameByImageName(name)
	end

	display.removeSpriteFramesWithFile(BattleRes .. "boss_text.plist", BattleRes .. "boss_text.png")
end

return BossAppearLayer