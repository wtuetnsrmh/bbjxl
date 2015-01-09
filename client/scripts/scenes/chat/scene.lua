local ChatLayer = import(".ChatLayer")

local ChatScene = class("ChatScene", function(params)
    return display.newScene("ChatScene")
end)

function ChatScene:ctor(params)
    self.params = params
end

function ChatScene:onEnter()
	display.newSprite("resource/ui_rc/home/home.jpg"):center():addTo(self)
	
	self.mainLayer = ChatLayer.new(self.params)
    self.mainLayer:addTo(self)
    
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

function ChatScene:onExit()
end

function ChatScene:onCleanup()
    display.removeUnusedSpriteFrames()
end

return ChatScene