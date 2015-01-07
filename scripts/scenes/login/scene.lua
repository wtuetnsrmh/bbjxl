local LoginLayer = import(".LoginLayer")
local ChooseHeroLayer = import(".ChooseHeroLayer")

local LoginScene = class("LoginScene", function (params)
    return display.newScene("LoginScene")
end)

function LoginScene:ctor( params )
	local layer
	if params.layer == "login" then
    	layer = LoginLayer.new(params)
        layer:anch(0.5, 0.5):pos(display.cx, display.cy):addTo(self)
    elseif params.layer == "chooseHero" then
    	layer = ChooseHeroLayer.new(params):getLayer()
        layer:addTo(self)
    end

   
end

function LoginScene:onEnter()
	if not audio.isMusicPlaying() then
		game:playMusic(1)
	end
end

function LoginScene:onCleanup()
    display.removeUnusedSpriteFrames()
end

return LoginScene