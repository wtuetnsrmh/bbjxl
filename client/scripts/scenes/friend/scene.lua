local FriendLayer = import(".FriendLayer")

local FriendScene = class("FriendScene", function(params)
    return display.newScene("FriendScene")
end)

function FriendScene:ctor(params)
    self.params = params

    display.newSprite("resource/ui_rc/home/home.jpg"):center():addTo(self)
end

function FriendScene:onEnter()

    if not self.mainLayer then
    	self.mainLayer = FriendLayer.new(self.params):getLayer()
   		self.mainLayer:addTo(self)
   	end

	if not audio.isMusicPlaying() then
		game:playMusic(1)
	end

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

return FriendScene