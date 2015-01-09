local SpriteCamp = class("SpriteCamp", require("logical.battle.Camp"))

function SpriteCamp:ctor(params)
	SpriteCamp.super.ctor(self, params)
	require("framework.api.EventProtocol").extend(self)
end

function SpriteCamp:updateAngryValue(params)
	self:dispatchEvent({name = "updateAngryValue", angryUnitNum = params.angryUnitNum, 
		angryAccumulateTime = params.angryAccumulateTime })
end

return SpriteCamp