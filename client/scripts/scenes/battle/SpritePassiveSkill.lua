local SpriteSoldier = import(".SpriteSoldier")

local SpritePassiveSkill = class("SpritePassiveSkill", require("logical.battle.PassiveSkill"))

function SpritePassiveSkill:ctor(params)
	params.bulletDef = "scenes.battle.SpriteBullet"
	
	SpritePassiveSkill.super.ctor(self, params)

	self.parentLayer = self.owner.parentLayer
end

function SpritePassiveSkill:onTextEffect(params)
	if self.hideText then return end
	
	if params.effect ~= nil then
		if params.value ~= nil then
			self.owner:onTextEffect(params)
			return
		end

		self.owner:onEffect(params.effect)
	end
end

function SpritePassiveSkill:displayPassiveSkillName()
	if self.csvData.nameRes == "" then return end

	local effectSprite = display.newSprite(self.csvData.nameRes)
	effectSprite:scale(0.5):pos(self.owner.nodeSize.width / 2, 60):addTo(self.owner.displayNode, SpriteSoldier.zOrderConstants["secondAttr"])
	effectSprite:setRotationY(self.owner.camp == "left" and 180 or 0)
	effectSprite:runAction(transition.sequence({
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 20)), CCScaleTo:create(0.1, 1)),
		CCDelayTime:create(0.2),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 10)), CCScaleTo:create(0.1, 0.75)),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.5, ccp(0, 30)), CCFadeOut:create(0.5)),
		CCRemoveSelf:create()
	}))
end

-- 子弹作用自己
function SpritePassiveSkill:onBegin(params)
	if not self.bullet or not self.bullet.hasAnimation then return end

	if bulletManager:getFrameCount(self.bullet.id, "begin") == 0 then
		return
	end

	local beginSprite = display.newSprite(bulletManager:getFrame(self.bullet.id, "begin"))
	beginSprite:setScaleX(self.bullet.csvData.scaleX / 100)
	beginSprite:setScaleY(self.bullet.csvData.scaleY / 100)
	beginSprite:anch(0.5, 0.5)--:flipX(self.owner.camp == "left")
		:pos(self.bullet.csvData.beginXOffset + self.owner.nodeSize.width / 2, self.bullet.csvData.beginYOffset)
		:addTo(self.owner.displayNode, 
				SpriteSoldier.zOrderConstants["bulletLayer" .. bulletManager:getZorder(self.bullet.id, "begin")])

	-- 固定开始特效特效1s开播持续特效
	beginSprite:runAction(transition.sequence({
		CCAnimate:create(bulletManager:getAnimation(self.bullet.id, "begin")),
		CCRemoveSelf:create(),
		CCCallFunc:create(function() 
			self.inProgress = false 
			self:effect() 
		end)
	}))
end

-- 子弹作用于对方
function SpritePassiveSkill:onEnemyBegin(params)
	if not self.bullet or not self.bullet.hasAnimation then return end

	if bulletManager:getFrameCount(self.bullet.id, "begin") == 0 then
		return
	end

	local beginSprite = display.newSprite(bulletManager:getFrame(self.bullet.id, "begin"))
	beginSprite:setScaleX(self.bullet.csvData.scaleX / 100)
	beginSprite:setScaleY(self.bullet.csvData.scaleY / 100)
	beginSprite:anch(0.5, 0.5)--:flipX(self.owner.camp == "left")
		:pos(self.bullet.csvData.beginXOffset + params.enemy.nodeSize.width / 2, self.bullet.csvData.beginYOffset)
		:addTo(params.enemy.displayNode, 
				SpriteSoldier.zOrderConstants["bulletLayer" .. bulletManager:getZorder(self.bullet.id, "begin")])

	-- 固定开始特效特效1s开播持续特效
	beginSprite:runAction(transition.sequence({
		CCAnimate:create(bulletManager:getAnimation(self.bullet.id, "begin")),
		CCRemoveSelf:create(),
		CCCallFunc:create(function() 
			--self.inProgress = false 
			--self:effect() 
			if params.callback and type(params.callback) == "function" then
				params.callback()
			end
		end)
	}))
end

function SpritePassiveSkill:onProgress(params)
	if not self.bullet or not self.bullet.hasAnimation then return end

	if self.inProgress then return end

	self.inProgress = true

	if bulletManager:getFrameCount(self.bullet.id, "progress") == 0 then end

	local progressSprite = display.newSprite(bulletManager:getFrame(self.bullet.id, "progress"))
	progressSprite:setScaleX(self.bullet.csvData.scaleX / 100)
	progressSprite:setScaleY(self.bullet.csvData.scaleY / 100)
	progressSprite:flipX(self.owner.camp == "left")
		:addTo(self.owner.displayNode, SpriteSoldier.zOrderConstants["bulletLayer" .. bulletManager:getZorder(self.bullet.id, "progress")])
		:pos(self.bullet.csvData.oppositeX1 + self.owner.nodeSize.width / 2, self.bullet.csvData.oppositeY1)

	progressSprite:playAnimationOnce(bulletManager:getAnimation(self.bullet.id, "progress"), true, 
		function() self.inProgress = false end)
end

function SpritePassiveSkill:dispose()
	--self.bullet:dispose()

	--game:unloadMusic(self.owner.unitData.skillMusicId)
end

return SpritePassiveSkill