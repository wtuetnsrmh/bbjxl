-- 新UI 副本Scene
-- by yangkun
-- 2014.3.24

local LegendHeroLayer = import(".LegendHeroLayer")

local LegendScene = class("LegendScene", function (params)
    return display.newScene("LegendScene")
end)

function LegendScene:ctor(params)
	self.params = params or {}
end

function LegendScene:onEnter()
	display.newSprite("resource/ui_rc/home/home.jpg"):center():addTo(self)

    self.mainLayer = LegendHeroLayer.new(self.params)
    self.mainLayer:getLayer():addTo(self)

    -- avoid unmeant back
	self:performWithDelay(function()
		-- keypad layer, for android
		local layer = display.newLayer()
		layer:addKeypadEventListener(function(event)
			if event == "back" then switchScene("home") end
		end)
		self:addChild(layer)

		layer:setKeypadEnabled(true)
	end, 0.5)
end

function LegendScene:onExit()
	display.removeUnusedSpriteFrames()
end

function LegendScene:onCleanup()
end

return LegendScene