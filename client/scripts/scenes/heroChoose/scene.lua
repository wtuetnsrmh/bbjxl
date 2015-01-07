local HeroChooseLayer = require("scenes.home.hero.HeroChooseLayer")

local HeroChooseScene = class("HeroChooseScene", function(params)
    return display.newScene("HeroChooseScene")
end)

function HeroChooseScene:ctor(params)
	self.params = params or {}
   
end

function HeroChooseScene:onEnter()
	if not self.mainLayer then
		self.mainLayer = HeroChooseLayer.new(self.params)
	    self.mainLayer:getLayer():addTo(self)
	end
end

function HeroChooseScene:onExit()
end

function HeroChooseScene:onCleanup()
    --display.removeUnusedSpriteFrames()
end

return HeroChooseScene