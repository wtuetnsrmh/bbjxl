local SkillShowLayer = class("SkillShowLayer", function()
	return display.newLayer()
end)

function SkillShowLayer:ctor(params)
	params = params or {}

	self.camp = params.camp or "left"
	self.mask = DGMask:new({ item = self, priority = params.priority, 
		opacity = 0 })

	self.removeImages = {}

	self.removeImages[BattleRes .. "skill_orange_bar.png"] = true
	self.orangeTopOne = display.newSprite(BattleRes .. "skill_orange_bar.png")
	self.orangeTopOne:anch(0, 1):pos(self.camp == "left" and -display.width or display.width, display.height):addTo(self, 1)
	self.orangeTopOne:moveTo(0.2, 0, display.height)
	
	self.removeImages[BattleRes .. "skill_orange_bar.png"] = true
	self.orangeBottomOne = display.newSprite(BattleRes .. "skill_orange_bar.png")
	self.orangeBottomOne:anch(0, 0):pos(self.camp == "left" and display.width or -display.width, 0):addTo(self, 1)
	self.orangeBottomOne:moveTo(0.2, 0, 0)

	-- local heroImage = display.newSprite(params.unitData.heroRes)
	-- self.removeImages[params.unitData.heroRes] = true
	local heroImage=uihelper.createMaskSprite(params.unitData.cardRes,params.unitData.heroRes)
	heroImage:flipX(self.camp == "right"):anch(self.camp == "left" and 1 or 0, 0):scale(0.75)
		:pos(self.camp == "left" and -display.width or display.width, 0):addTo(self, 2)
	heroImage:moveTo(0.2, self.camp == "left" and display.width or 0, 0)

	self.removeImages[BattleRes .. "skill_blue_bar.png"] = true
	local blueBar = display.newSprite(BattleRes .. "skill_blue_bar.png")
	blueBar:anch(0, 0):pos(self.camp == "left" and -display.width or display.width, 100):addTo(self, 3)
	blueBar:moveTo(0.2, 0, 100)

	self.removeImages[params.skillNameRes] = true
	local skillNamePic = display.newSprite(params.skillNameRes)
	skillNamePic:pos(self.camp == "left" and display.width + 300 or -300, 100 + blueBar:getContentSize().height / 2):addTo(self, 3)
	skillNamePic:moveTo(0.2, display.width / 2, 100 + blueBar:getContentSize().height / 2)

	local actions = {}
	actions[#actions + 1] = CCCallFunc:create(function()
		self.orangeTopTwo = display.newSprite(BattleRes .. "skill_orange_bar.png")
		self.orangeTopTwo:anch(0, 1):pos(self.camp =="left" and -display.width or display.width, display.height):addTo(self, 1)

		self.orangeBottomTwo = display.newSprite(BattleRes .. "skill_orange_bar.png")
		self.orangeBottomTwo:anch(0, 0):pos(self.camp == "left" and display.width or -display.width, 0):addTo(self, 1)

		self:addScriptEventListener(cc.Event.ENTER_FRAME, handler(self, self.tick))
	end)
	actions[#actions + 1] = CCDelayTime:create(0.5)
	actions[#actions + 1] = CCCallFunc:create(function() self.mask:remove() end)

	self:runAction(transition.sequence(actions))
end

function SkillShowLayer:tick(diff)
	if self.camp == "left" then
		if self.orangeTopOne:getPositionX() >= display.width then
			self.orangeTopOne:pos(-display.width, display.height)
		end

		if self.orangeTopTwo:getPositionX() >= display.width then
			self.orangeTopTwo:pos(-display.width, display.height)
		end

		self.orangeTopOne:moveBy(diff, diff * 480)
		self.orangeTopTwo:moveBy(diff, diff * 480)

		if self.orangeBottomOne:getPositionX() <= -display.width then
			self.orangeBottomOne:pos(display.width, 0)
		end

		if self.orangeBottomTwo:getPositionX() <= -display.width then
			self.orangeBottomTwo:pos(display.width, 0)
		end

		self.orangeBottomOne:moveBy(diff, -diff * 480)
		self.orangeBottomTwo:moveBy(diff, -diff * 480)
	else
		if self.orangeTopOne:getPositionX() <= -display.width then
			self.orangeTopOne:pos(display.width, display.height)
		end

		if self.orangeTopTwo:getPositionX() <= -display.width then
			self.orangeTopTwo:pos(display.width, display.height)
		end

		self.orangeTopOne:moveBy(diff, -diff * 480)
		self.orangeTopTwo:moveBy(diff, -diff * 480)

		if self.orangeBottomOne:getPositionX() >= display.width then
			self.orangeBottomOne:pos(-display.width, 0)
		end

		if self.orangeBottomTwo:getPositionX() >= display.width then
			self.orangeBottomTwo:pos(-display.width, 0)
		end

		self.orangeBottomOne:moveBy(diff, diff * 480)
		self.orangeBottomTwo:moveBy(diff, diff * 480)
	end
end

function SkillShowLayer:getLayer()
	return self.mask:getLayer()
end

function SkillShowLayer:onCleanup()
	for name, bool in pairs(self.removeImages) do
		display.removeSpriteFrameByImageName(name)
	end
end

return SkillShowLayer