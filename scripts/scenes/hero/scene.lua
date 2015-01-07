local HeroMainLayer = require("scenes.home.hero.HeroMainLayer")

local HeroMainScene = class("HeroMainScene", function(params)
    return display.newScene("HeroMainScene")
end)

function HeroMainScene:ctor(params)

    local mainLayer = HeroMainLayer.new(params)
    mainLayer:getLayer():addTo(self)
end

function HeroMainScene:onEnter()

end

function HeroMainScene:onExit()
end

function HeroMainScene:onCleanup()
    display.removeUnusedSpriteFrames()
end

return HeroMainScene