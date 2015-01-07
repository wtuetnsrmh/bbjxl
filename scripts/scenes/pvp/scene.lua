-- 新UI 副本Scene
-- by yangkun
-- 2014.3.24

local PvpHomeLayer = import(".PvpHomeLayer")

local PvpScene = class("PvpScene", function (params)
    return display.newScene("PvpScene")
end)

function PvpScene:ctor(params)
	self.params = params or {}
end

function PvpScene:onEnter()
	display.newSprite("resource/ui_rc/home/home.jpg"):center():addTo(self)

    self.mainLayer = PvpHomeLayer.new(self.params)
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

function PvpScene:onExit()
    display.removeUnusedSpriteFrames()
end

function PvpScene:onCleanup()
end

return PvpScene