-- 新UI 副本Scene
-- by yangkun
-- 2014.3.24

local ActivityHomeLayer = import(".ActivityHomeLayer")

local ActivityScene = class("ActivityScene", function (params)
    return display.newScene("ActivityScene")
end)

function ActivityScene:ctor(params)
	self.params = params or {}
	self.params.layer = self.params.layer or "home"
end

function ActivityScene:onEnter()
	display.newSprite("resource/ui_rc/home/home.jpg"):center():addTo(self)

    self.mainLayer = ActivityHomeLayer.new()
    self.mainLayer:getLayer():addTo(self)
end

function ActivityScene:onCleanup()
    display.removeUnusedSpriteFrames()
end

return ActivityScene