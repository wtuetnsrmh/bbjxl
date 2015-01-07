-- 远征

 local ExpeditionLayer = import(".ExpeditionLayer")


local Expedition = class("Expedition", function (params)
    return display.newScene("Expedition")
end)

function Expedition:ctor(params)
	self.params = params or {}
end

function Expedition:onEnter()
    self.mainLayer = ExpeditionLayer.new(self.params)
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

function Expedition:onCleanup()
    display.removeUnusedSpriteFrames()
end

return Expedition