local DGCardTurnOver = class("DGCardTurnOver", function()
	return display.newLayer()
end)

function DGCardTurnOver:ctor(params)
	params = params or {}

	self.duration = params.duration or 1
	self.inAngleZ = params.inAngleZ or 270
	self.inDeltaZ = params.inDeltaZ or 90
	self.outAngleZ = params.outAngleZ or 0
	self.outDeltaZ = params.outDeltaZ or 90

	local cardSize = params.inCard:getContentSize()
	self:size(cardSize)

	self.inCard = params.inCard
	self.inCard:anch(0.5, 0.5):pos(cardSize.width / 2, cardSize.height / 2):addTo(self):hide()

	self.outCard = params.outCard
	self.outCard:anch(0.5, 0.5):pos(cardSize.width / 2, cardSize.height / 2):addTo(self)

	self.inCardAction = transition.sequence({
		CCCallFunc:create(function() self.inTurning = true end),
		CCDelayTime:create(0.5 * self.duration),
		CCShow:create(),
		CCOrbitCamera:create(self.duration * 0.5, 1, 0, self.inAngleZ, self.inDeltaZ, 0, 0),
		CCCallFunc:create(function() self.inTurning = false end),
	})
	self.inCardAction:retain()

	self.outCardAction = transition.sequence({
		CCCallFunc:create(function() self.outTurning = true end),
		CCOrbitCamera:create(self.duration * 0.5, 1, 0, self.outAngleZ, self.outDeltaZ, 0, 0),
		CCHide:create(),
		CCDelayTime:create(self.duration * 0.5),
		CCCallFunc:create(function() self.outTurning = false end),
	})
	self.outCardAction:retain()
end

function DGCardTurnOver:turnOver()
	if self.inTurning or self.outTurning then return end

	if not self.hasReversed then
		self.inCard:runAction(self.inCardAction)
		self.outCard:runAction(self.outCardAction)
		self.hasReversed = true
	else
		self.inCard:runAction(self.outCardAction)
		self.outCard:runAction(self.inCardAction)
		self.hasReversed = false
	end
end

function DGCardTurnOver:onExit()
	self.inCardAction:release()
	self.outCardAction:release()
end

return DGCardTurnOver