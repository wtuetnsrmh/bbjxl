local SkillShowLayer = import(".SkillShowLayer")
local SpriteSoldier = import(".SpriteSoldier")

local SpriteSkill = class("SpriteSkill", require("logical.battle.Skill"))

function SpriteSkill:ctor(params)
	params.bulletDef = "scenes.battle.SpriteBullet"
	
	SpriteSkill.super.ctor(self, params)

	self.parentLayer = self.owner.parentLayer
end

function SpriteSkill:onShow()
	game:playMusic(self.owner.unitData.skillMusicId)
	
	-- 技能阴影遮盖
	self.parentLayer:showSkillMask(true, self.owner)

	-- 技能展示条
	-- local skillShowLayer = SkillShowLayer.new({ camp = self.camp, priority = -140,
		-- skillNameRes = self.csvData.showPic, unitData = self.owner.unitData })
	-- self.parentLayer:add(skillShowLayer:getLayer(), 100)

	-- 暂停所有的动作
	self.parentLayer:pause()
	self.parentLayer.effectLayer0:pause()
	self.parentLayer.effectLayer1:pause()
	self.parentLayer.heroBottomLayer:onPause(true)						-- 暂停CD
	transition.pauseTarget(self.parentLayer.leftTimeLabel)				-- 暂停计时器
	self.battle:pause(true)

	-- 释放者待机
	--self.owner:onPause(false)
	self.owner:onStandby({})
	self.owner.sprite:scaleTo(0.1, 1.2 * self.owner.scale)

	-- 停顿 + 技能攻击动作
	local actions = transition.sequence({
		CCDelayTime:create(0.1),
		CCCallFunc:create(function()
			if not self.owner:isState("skillAttack") and not self.owner:isState("dead") then
				self.owner:doEvent("BeginSkillAttack")
			end
		end)
	})
	self.parentLayer:runAction(actions)
end

function SpriteSkill:onBeginEffect(params)
	local actions = {}

	if bulletManager:getFrameCount(self.bullet.id, "begin") == 0 then
		self:effect()
	else	
		local beginSprite = display.newSprite(bulletManager:getFrame(self.bullet.id, "begin"))
		local scaleX = self.bullet.csvData and self.bullet.csvData.scaleX or 100
		local scaleY = self.bullet.csvData and self.bullet.csvData.scaleY or 100
		beginSprite:setScaleX(scaleX / 100)
		beginSprite:setScaleY(scaleY / 100)
		beginSprite:pos(self.bullet.csvData.beginXOffset, self.bullet.csvData.beginYOffset)
			:addTo(self.owner.displayNode, 
				SpriteSoldier.zOrderConstants["bulletLayer" .. bulletManager:getZorder(self.bullet.id, "begin")] )

		actions[#actions + 1] = CCAnimate:create(bulletManager:getAnimation(self.bullet.id, "begin"))
		actions[#actions + 1] = CCRemoveSelf:create()
		actions[#actions + 1] = CCCallFunc:create(function() self:effect() end)
		beginSprite:runAction(transition.sequence(actions))
	end
end

function SpriteSkill:onHurtEnemy(params)
	local soldier = params.enemy
	local hurtSprite = display.newSprite(bulletManager:getFrame(self.bullet.id, "hurt"))
	
	local scaleX = self.bullet.csvData and self.bullet.csvData.scaleX or 100
	local scaleY = self.bullet.csvData and self.bullet.csvData.scaleY or 100
	hurtSprite:setScaleX(scaleX / 100)
	hurtSprite:setScaleY(scaleY / 100)
	hurtSprite:pos(soldier.nodeSize.width / 2, 60):addTo(soldier.displayNode)

	local actions = {}
	actions[#actions + 1] = CCAnimate:create(self.bullet:getAnimation("hurt"))
	actions[#actions + 1] = CCRemoveSelf:create(),
	hurtSprite:runAction(transition.sequence(actions))
end

function SpriteSkill:dispose()
	self.bullet:dispose()

	game:unloadMusic(self.owner.unitData.skillMusicId)
end

return SpriteSkill