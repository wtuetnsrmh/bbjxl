-- 新UI 副本Scene
-- by yangkun
-- 2014.3.24

local TowerCarbonLayer = import(".TowerCarbonLayer")

local TowerScene = class("TowerScene", function (params)
    return display.newScene("TowerScene")
end)

function TowerScene:ctor(params)
	self.params = params or {}
end

function TowerScene:onEnter()
	display.newSprite("resource/ui_rc/home/home.jpg"):center():addTo(self)

    self.mainLayer = TowerCarbonLayer.new()
    self.mainLayer:getLayer():addTo(self)
end

function TowerScene:onCleanup()
    display.removeUnusedSpriteFrames()
end

return TowerScene