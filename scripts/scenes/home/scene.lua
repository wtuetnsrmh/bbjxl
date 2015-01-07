local NewMainLayer = import(".NewMainLayer")

local HomeScene = class("HomeScene", function(params)
    return display.newScene("HomeScene")
end)

function HomeScene:ctor(params)
    self.params = params

    self.mainLayer = NewMainLayer.new(self.params)
    self.mainLayer:addTo(self)
end

function HomeScene:onEnter()
	if not audio.isMusicPlaying() then
		game:playMusic(1)
	end
end

function HomeScene:onExit()
end

function HomeScene:onCleanup()
    -- display.removeUnusedSpriteFrames()
end

return HomeScene