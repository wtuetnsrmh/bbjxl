local LoadingRes = "resource/ui_rc/loading/"

local LoadingLayer = class("LoadingLayer", function()
	return display.newLayer(LoadingRes.."small_bg.png")
end)

function LoadingLayer:ctor(params)
	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = -9999 })

	self:loadingActionShow()
end

function LoadingLayer:loadingActionShow()
	local fileName = "modao" --3
	display.addSpriteFramesWithFile(LoadingRes .. fileName .. ".plist", LoadingRes .. fileName .. ".png")

	local framesTable = {}
	for index = 1, 3 do
		local frameId = string.format("%d", index)
		framesTable[#framesTable + 1] = display.newSpriteFrame(fileName .. "_" .. frameId .. ".png")
	end
	local animation = display.newAnimation(framesTable, 1.0 / 12)
	local sprite = display.newSprite(framesTable[1])
	sprite:addTo(self):pos(self:getContentSize().width / 2, self:getContentSize().height / 2)
	sprite:playAnimationForever(animation)
end

function LoadingLayer:getLayer()
	return self.mask:getLayer()
end

return LoadingLayer