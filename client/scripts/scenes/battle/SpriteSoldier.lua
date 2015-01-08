local MovementEventType =
{
	START = 0,
	COMPLETE = 1,
	LOOP_COMPLETE = 2,
}

local SpriteSoldier = class("SpriteSoldier", require("logical.battle.Soldier"))

SpriteSoldier.zOrderConstants = {
	["bossLoop"] = -20,
	["attack2Loop"] = -10,
	["bulletLayer1"] = -5,
	["bulletLayer0"] = 40,
	["buffIcon"] = 50,
	["name"] = 60,
	["hpBar"] = 61,
	["secondAttr"] = 90,
	["hpChange"] = 100,
}

-- 定义血条的基准高度，相对角色的位置都根据这个高度加减，方便调数据
hpBaseHight = 160

function SpriteSoldier:ctor(params)
	params.skillDef = "scenes.battle.SpriteSkill"
	params.buffDef = "scenes.battle.SpriteBuff"
	params.passiveSkillDef = "scenes.battle.SpritePassiveSkill"

	SpriteSoldier.super.ctor(self, params)

	self.actionStatus = "idle"
	self.hurtOffset = 60
	self.hurtDelta = 1

	self.parentLayer = params.parentLayer

	-- 被动技能在战斗开始后刷
	self.isPassiveSkillInited = false
	self.parentLayer:addEventListener("battleStart", function (event)
			if not self.isPassiveSkillInited then
				self:initHeroAttributeByPassiveSkills()
				self.isPassiveSkillInited = true
			end
		end)

	self.scale = self.unitData.boneRatio / 100
	self.effectScale = self.unitData.boneEffectRatio / 100

	if self.beBoss then
		self.scale = self.scale * 1.2
	end

	self.animationName = ""

	-- 初始化精灵的每组动作和头像
	self:initUIResources()

	require("framework.api.EventProtocol").extend(self)
end

function SpriteSoldier:initUIResources()
	local paths = string.split(string.trim(self.unitData.boneResource), "/")
	self.armatureName = paths[#paths]
	paths = string.split(string.trim(self.unitData.boneEffectResource), "/")
	self.armatureEffectName = paths[#paths]

	if not armatureManager:hasLoaded(self.unitData.type) then
		armatureManager:load(self.unitData.type)
	end

	-- 普攻特效
	self.bulletData = bulletCsv:getBulletById(self.unitData.atkBullteId)

	-- 普攻效果子弹
	local SpriteBullet = require("scenes.battle.SpriteBullet")
	self.bullet = SpriteBullet.new({ id = self.unitData.atkBullteId, usage = 1 })

	display.addSpriteFramesWithFile("resource/ui_rc/battle/boss_low.plist", "resource/ui_rc/battle/boss_low.png")

	self.buffIconIndex = 1
end

function SpriteSoldier:initHeroDisplay()
	-- self.displayNode = display.newColorLayer(ccc4(100 ,123, 222, 100))
	self.displayNode = display.newNode()

	self.sprite = CCNodeExtend.extend(CCArmature:create(self.armatureName))
	self.sprite:scale(self.scale)

	local spriteSize = self.sprite:getContentSize()
	self.nodeSize = CCSizeMake(spriteSize.width * self.unitData.boneRatio / 100, spriteSize.height * self.unitData.boneRatio / 100)
	self.displayNode:size(self.nodeSize):anch(0.5, 0)
	self.sprite:pos(self.nodeSize.width / 2, 0):addTo(self.displayNode)

	self.animation = self.sprite:getAnimation()
	self.animation:setSpeedScale(24 / 60) -- Flash fps is 24, cocos2d-x is 60
	self.animation:setMovementEventCallFunc(function(armature, evtType, moveId) 
		self:moveEvent(armature, evtType, moveId) 
	end)

	self.animation:setFrameEventCallFunc(function(bone, frameEventName, orginFrameIndex, currentFrameIndex)
		self:frameEvent(bone, frameEventName, orginFrameIndex, currentFrameIndex)
	end)

	-- 特效
	if self.armatureEffectName and self.armatureEffectName ~= "" then
		self.spriteEffect = CCNodeExtend.extend(CCArmature:create(self.armatureEffectName))
		self.spriteEffect:scale(self.effectScale)

		self.spriteEffect:pos(self.nodeSize.width / 2, 0):addTo(self.displayNode)

		self.effectAnimation = self.spriteEffect:getAnimation()
		self.effectAnimation:setSpeedScale(24 / 60) -- Flash fps is 24, cocos2d-x is 60
	end

	local hpSlot
	if self.camp == "left" then
		self.hpProgress = display.newProgressTimer(BattleRes .. "self_hp.png", display.PROGRESS_TIMER_BAR)
		self.hpProgress:setMidpoint(ccp(0, 0))
		self.hpProgress:setBarChangeRate(ccp(1,0))
		self.hpProgress:setPercentage(self.hp * 100 / self.maxHp)
		hpSlot = display.newSprite(BattleRes .. "hp_bg.png")
		self.hpProgress:pos(hpSlot:getContentSize().width / 2, hpSlot:getContentSize().height / 2):addTo(hpSlot)
		hpSlot:pos(self.nodeSize.width / 2, hpBaseHight):addTo(self.displayNode, SpriteSoldier.zOrderConstants["hpBar"])
		-- 血条反向
		hpSlot:setRotationY(self.camp == "left" and 180 or 0)
	else
		self.hpProgress = display.newProgressTimer(BattleRes .. "enemy_hp.png", display.PROGRESS_TIMER_BAR)
		self.hpProgress:setMidpoint(ccp(1, 0))
		self.hpProgress:setBarChangeRate(ccp(1,0))
		self.hpProgress:setPercentage(self.hp * 100 / self.maxHp)
		hpSlot = display.newSprite(BattleRes .. "hp_bg.png")
		self.hpProgress:pos(hpSlot:getContentSize().width / 2 , hpSlot:getContentSize().height / 2):addTo(hpSlot)

		-- 敌方boss
		if self.beBoss then
			self.bossLowFrames = {}
			for index = 1, 3 do
				local frameId = string.format("%02d", index)
				self.bossLowFrames[#self.bossLowFrames + 1] = display.newSpriteFrame("boss_low_" .. frameId .. ".png")
			end
			self.bossLowAnimation = display.newAnimation(self.bossLowFrames, 1.0 / 10)

			local bottomLogo = display.newSprite(self.bossLowFrames[1])
			bottomLogo:pos(self.nodeSize.width / 2, 0):addTo(self.displayNode, SpriteSoldier.zOrderConstants["bossLoop"])
			bottomLogo:playAnimationForever(self.bossLowAnimation)
		end
		hpSlot:pos(self.nodeSize.width / 2, hpBaseHight):addTo(self.displayNode, SpriteSoldier.zOrderConstants["hpBar"])
	end

	-- 己方武将名字
	local evolutionCount = uihelper.getShowEvolutionCount(self.evolutionCount)
	local nameValue = self.name .. ((self.showEvolution and evolutionCount > 0) and ("+" .. evolutionCount) or "")
	if self.assistHero then nameValue = string.format("友·%s", nameValue) end
	local nameLabel = ui.newTTFLabelWithStroke({text = nameValue, size = 20, color = uihelper.getEvolColor(self.evolutionCount), strokeColor = display.COLOR_BLACK, strokeSize = 2})
	nameLabel:setRotationY(self.camp == "left" and 180 or 0)
	nameLabel:anch(0.5, 0):pos(self.nodeSize.width / 2, hpBaseHight + 5):addTo(self.displayNode, SpriteSoldier.zOrderConstants["name"])
end

function SpriteSoldier:playAnimation(name)
	self.animation:setSpeedScale(self.slowdown and 0.2 or 0.4)
	self.animation:play(name)

	if self.effectAnimation then
		if name == "attack" or name == "attack2" or name == "attack3" or name == "attack4" or name == "skill" then
			self.effectAnimation:setSpeedScale(self.slowdown and 0.2 or 0.4)
			self.effectAnimation:play(name)
		else
			self.effectAnimation:stop()
			self.effectAnimation:play("idle")
		end
	end

	self.animationName = name
end

function SpriteSoldier:moveEvent(armature, evtType, moveId)
	if evtType == MovementEventType.START then

	elseif evtType == MovementEventType.COMPLETE then
		if moveId == "attack" or moveId == "attack2" or moveId == "attack3" or moveId == "attack4" then

			self.actionStatus = nil
			
			if self.isPassiveAni then
				-- 施放下一个被动技能动作
				local origIndex = self.passiveAniIndex
				for index = origIndex + 1,3 do
					local passiveSkill = self.passiveSkills[index]
					if passiveSkill and not passiveSkill:isActiveSkill() and not passiveSkill:isDeathTrigger() then
						origIndex = index
						self:onPassiveAnimation(index)
						passiveSkill:displayPassiveSkillName()
						break
					end
				end
				if self.passiveAniIndex == origIndex then
					self.isPassiveAni = false
				end
				self.passiveAniIndex = origIndex
			elseif self.dreamKill then
				-- 自己
				self:doEvent("BeKilled")
				if self.beBoss then
					self:dispatchEvent({ name = "KilledBoss" })
				end
				-- 每击杀一个敌人触发
				if self.dreamKill_attacker then
					self.dreamKill_attacker:triggerPassiveSkill({condition = skillPassiveCsv.TRIGGER_KILL_ENEMY, effect = skillPassiveCsv.EFFECT_CRIT})

					self.dreamKill_attacker:triggerPassiveSkill({condition = skillPassiveCsv.TRIGGER_KILL_ENEMY, effect = skillPassiveCsv.EFFECT_RECOVER_HP})
				end

				self:onHurt(self.dreamKill_params)

				-- 清理
				self.dreamKill = nil
				self.dreamKill_skill = nil
				self.dreamKill_attacker = nil
				self.dreamKill_params = nil
			else
				-- 攻击状态完成，判断是否可移动
				if globalCsv:getFieldValue("battleMoveFirst") == 1 then
					if self:canMove(1) and self.battleField:beforeXTeamer(self) ~= nil then
						self:doEvent("BeginMove")
					else
						self:playAnimation("idle")
					end
				else
					self:playAnimation("idle")
				end
			end

		elseif moveId == self.unitData.skillAnimateName then
			-- self:playAnimation("idle")
			if self:getState() ~= "dead" then
				self:doEvent("ToIdle")
			end
			self.sprite:scaleTo(0.1, self.scale)

			if self.curSkill.csvData.effectRangeType ~= 2 then
				self.canPause = true
				local camp = self.battle.battleField[self.camp .. "Camp"]
				camp.skillRefCount = camp.skillRefCount - 1
				self.skillProgress = 0

				if camp.skillRefCount <= 0 then
					self.parentLayer:resume()
					self.parentLayer.effectLayer0:resume()
					self.parentLayer.effectLayer1:resume()
					self.parentLayer.heroBottomLayer:onPause(false)			--恢复CD
					transition.resumeTarget(self.parentLayer.leftTimeLabel)		--恢复计时器

					self.battle:pause(false)
				end
			end

			-- 技能CD开始计时
			-- self:dispatchEvent({ name = "releaseSkill" })
			self.skillCd = self.unitData.talentSkillCd

		elseif moveId == "damaged" then
			if self:getState() == "dizzy" then
				self:playAnimation("idle")
			elseif self:getState() == "hypnosis" then
				-- 变猪
				self.displayNode:setVisible(false)

				local pigBulletID = 326
				if bulletManager:load(pigBulletID) then
					local actions = {}
					local bulletSprite = bulletManager:getFrameSprite(pigBulletID, "progress")
					bulletSprite:setAnchorPoint(self.displayNode:getAnchorPoint())
					local x,y = self.displayNode:getPosition()
					bulletSprite:setPosition(x, y-26)
					local z = self.displayNode:getZOrder()
					bulletSprite:flipX(self.camp == "left"):addTo(self.displayNode:getParent(), z)

					local animation = bulletManager:getAnimation(pigBulletID, "progress")
					transition.playAnimationForever(bulletSprite, animation)
					self.pigNode = bulletSprite
				end
			elseif self:getState() ~= "dead" then
				self:playAnimation("idle")
				self:doEvent("ToIdle")
			end
		elseif moveId == "dead" then

			-- 有复活被动技
			local params = {
				condition = skillPassiveCsv.TRIGGER_DEAD,
				effect = skillPassiveCsv.EFFECT_RESURGENCE,
			}
			self:triggerPassiveSkill(params)

			-- 有复活buff
			local revive, buff = self:hasBuff(26)

			if params.returnValue then
				self:doEvent("ToIdle")
			elseif revive then
				self.hp = buff.buffValue
				self:doEvent("ToIdle")
			else
				self:dispatchEvent({ name = "soldierDead" })
				self.battleField:removeSoldier(self)
			end
		end

	elseif evtType == MovementEventType.LOOP_COMPLETE then
	end
end

-- 帧事件，用于控制攻击，放技能时在哪一帧开始生效
function SpriteSoldier:frameEvent(bone, frameEventName, orginFrameIndex, currentFrameIndex)
	if string.trim(bone:getName()) ~= "shadow" then return end

	if self.animationName == "attack" then
		if bulletManager:getFrameCount(self.bullet.id, "begin") ~= 0 then
			local bulletSprite = bulletManager:getFrameSprite(self.bullet.id, "begin")
			bulletSprite:pos(self.bulletData.oppositeX1 + self.nodeSize.width / 2, self.bulletData.oppositeY1)
				:addTo(self.displayNode, SpriteSoldier.zOrderConstants["bulletLayer" .. bulletManager:getZorder(self.bullet.id, "progress")])
			game:playMusic(bulletManager:getMusicId(self.bullet.id, "begin"))
			
			local actions = {}
			actions[#actions + 1] = CCAnimate:create(bulletManager:getAnimation(self.bullet.id, "begin"))
			actions[#actions + 1] = CCRemoveSelf:create()
			actions[#actions + 1] = CCCallFunc:create(function()
				game:playMusic(self.heroProfession.attackMusicId)
				self.canAttackEffect = true
			end)
			bulletSprite:runAction(transition.sequence(actions))
		else
			game:playMusic(self.heroProfession.attackMusicId)
			self.canAttackEffect = true
		end

	elseif self.animationName == "attack2" or self.animationName == "attack3" or self.animationName == "attack4" then
		if self.curPassiveSkill then
			self.curPassiveSkill:onBeginEffect()
			--self.curPassiveSkill:effect()
		end
		if self.isPassiveAni then
			self.passiveSkills[self.passiveAniIndex]:onBegin()
		end

		-- 梦中杀人
		if self.dreamKill then
			---self.dreamKill_skill:onBegin()

			-- 对方
			local hurt = self.maxHp * self.dreamKill_skill.dreamKill_hurt / 100
			local soldiers = self.battleField:getCampObjects(self.camp == "right" and "left" or "right")
			local i = randomInt(1, #soldiers)

			self.dreamKill_skill:onEnemyBegin({enemy = soldiers[i],
				callback = function ()
					soldiers[i]:beingHurt({hurtValue = hurt})
				end})
			
		end
	elseif self.animationName == self.unitData.skillAnimateName then
		-- 技能遮罩移除
		if self.curSkill.csvData.effectRangeType == 2 then
			self.canPause = true
			local camp = self.battle.battleField[self.camp .. "Camp"]
			camp.skillRefCount = camp.skillRefCount - 1
			self.skillProgress = 0
			
			if camp.skillRefCount <= 0 then
				self.parentLayer:resume()
				self.parentLayer.effectLayer0:resume()
				self.parentLayer.effectLayer1:resume()
				self.parentLayer.heroBottomLayer:onPause(false)			--恢复CD
				transition.resumeTarget(self.parentLayer.leftTimeLabel)		--恢复计时器

				self.battle:pause(false)
			end
		end

		self.parentLayer:showSkillMask(false, self)
		self.curSkill:onBeginEffect()
	end
end

-- 继承自父类
function SpriteSoldier:onMove(params)
	local moveAction = CCMoveTo:create(params.time / 1000, ccp(self.position.x, self.position.y))

	self.displayNode:setPosition(self.position.x, self.position.y)
	self.displayNode:runAction(moveAction)

	-- 动作
	if self.actionStatus == "move" then return end

	self.actionStatus = "move"
	self:playAnimation("move")
end

function SpriteSoldier:onStandby(params)
	if self.actionStatus == "idle" then return end
	self.displayNode:stopAllActions()

	self.actionStatus = "idle"
	self:playAnimation("idle")
end

function SpriteSoldier:onAttack(params)
	self.actionStatus = "attack"

	-- 每次攻击产生一个普攻特效
	if params.type == 1 then
		self.animation:setSpeedScale((self.slowdown and 0.2 or 0.4) * self.atkSpeedFactor / 100)
		self.animation:play("attack")

		if self.effectAnimation then
			self.effectAnimation:setSpeedScale((self.slowdown and 0.2 or 0.4) * self.atkSpeedFactor / 100)
			self.effectAnimation:play("attack")
		end
		self.animationName = "attack"

	else
		params.type = params.type or 2
		self:playAnimation("attack" .. params.type)

		if params.hasFootHalo == 0 then
			local attack2Effect = self.parentLayer.attack2Effect
			local attach2Halo = display.newSprite(bulletManager:getFrame(attack2Effect.id, "progress"))
			attach2Halo:pos(self.nodeSize.width / 2 + attack2Effect.csvData.oppositeX1, attack2Effect.csvData.oppositeY1)
				:addTo(self.displayNode, SpriteSoldier.zOrderConstants["attack2Loop"])
				:playAnimationOnce(bulletManager:getAnimation(attack2Effect.id, "progress"), true)
		end
	end

	if params.text and params.atk == 1 then
		local skillText = ui.newTTFLabel({ text=params.text, size=26 })
		skillText:setRotationY(self.camp == "right" and 180 or 0)
		skillText:pos(self.nodeSize.width/2, self.nodeSize.height):addTo(self.displayNode)
		skillText:runAction(transition.sequence({
			CCMoveBy:create(1.0, ccp(0,20)),
			CCRemoveSelf:create()
		}))
	end
end

function SpriteSoldier:onPassiveAnimation(skillId)
	self:playAnimation("attack" .. skillId + 1)
	--无条件触发被动效果
	SpriteSoldier.super.onPassiveAnimation(self, skillId)
end

function SpriteSoldier:checkAttackStatus(params)
	if not self.canAttackEffect then return end

	if self.actionStatus == "attackEffect" then return end
	
	self.actionStatus = "attackEffect"
	self.canAttackEffect = false

	-- 计算伤害值
	local hurtValue,restraintValue = self:calcHurtValue(self, params.enemy)
	local hurtValues = self:secondAttrEffect({ enemy = params.enemy, hurtValue = hurtValue})

	-- 根据职业, 释放攻击特效
	local professionName = ProfessionName[self.unitData.profession]
	local xCoefficient = self.camp == "left" and 1 or -1

	local function playHurtAction()
		if params.enemy.hp <= 0 then return end
		
		local enemySize = params.enemy.nodeSize
		local hurtSprite = display.newSprite(bulletManager:getFrame(self.bullet.id, "hurt"))
		hurtSprite:setScaleX(self.bullet.csvData.scaleX / 100)
		hurtSprite:setScaleY(self.bullet.csvData.scaleY / 100)
		local randomX, randomY = randomInt(-self.hurtDelta, self.hurtDelta), randomInt(-self.hurtDelta, self.hurtDelta)
		hurtSprite:flipX(true):pos(randomX + params.enemy.nodeSize.width / 2, self.hurtOffset + randomY):addTo(params.enemy.displayNode, 100)
		local hurtActions = {}
		hurtActions[#hurtActions + 1] = CCSpawn:createWithTwoActions(
			CCAnimate:create(bulletManager:getAnimation(self.bullet.id, "hurt")),
			CCCallFunc:create(function()

				self:triggerPassiveSkill({
					condition = skillPassiveCsv.TRIGGER_HURT_BY_ATK,
					effect = skillPassiveCsv.EFFECT_BLOOD_ADBSORB,
					hurtValue = hurtValues.enemy})

				params.enemy:beingHurt({ hurtValue = hurtValues.enemy , effect = hurtValues.effect, 
					restraint = restraintValue, attacker = self})
				self:beingHurt({ hurtValue = hurtValues.self, attacker = params.enemy})
				params.enemy:onEffect(hurtValues.effect)
				--params.enemy:onEffect(params.enemy.buqu and "buqu" or "normal")
			end)
		)
		hurtActions[#hurtActions + 1] = CCRemoveSelf:create()
		game:playMusic(bulletManager:getMusicId(self.bullet.id, "hurt"))
		hurtSprite:runAction(transition.sequence(hurtActions))
	end

	if self.bullet.csvData.type == 1 then
		local bulletSprite = bulletManager:getFrameSprite(self.bullet.id, "progress")
		bulletSprite:pos(self.bulletData.oppositeX1 + self.nodeSize.width / 2, self.bulletData.oppositeY1)
			:addTo(self.displayNode, SpriteSoldier.zOrderConstants["bulletLayer" .. bulletManager:getZorder(self.bullet.id, "progress")])
			
		local actions = {}
		if bulletManager:getFrameCount(self.bullet.id, "progress") ~= 0 then
			actions[#actions + 1] = CCAnimate:create(bulletManager:getAnimation(self.bullet.id, "progress"))
		end

		actions[#actions + 1] = CCRemoveSelf:create()
		actions[#actions + 1] = CCCallFunc:create(function() playHurtAction() end)
		game:playMusic(bulletManager:getMusicId(self.bullet.id, "progress"))
		bulletSprite:runAction(transition.sequence(actions))

	elseif self.bullet.csvData.type == 2 then
		local bulletSprite
		local actions = {}

		if bulletManager:getFrameCount(self.bullet.id, "progress") ~= 0 then
			if bulletSprite then
				bulletSprite:displayFrame(bulletManager:getFrame(self.bullet.id, "progress"))
			else
				bulletSprite = bulletManager:getFrameSprite(self.bullet.id, "progress")
			end
			bulletSprite:flipX(self.camp == "left")
				:pos(params.enemy.position.x + self.bulletData.oppositeX1 * xCoefficient, params.enemy.position.y + self.bulletData.oppositeY1)
			actions[#actions + 1] = CCAnimate:create(bulletManager:getAnimation(self.bullet.id, "progress"))
			actions[#actions + 1] = CCRemoveSelf:create()
		end

		if not bulletSprite then
			playHurtAction()
		else
			actions[#actions + 1] = CCCallFunc:create(function() playHurtAction() end)
			bulletSprite:addTo(self.parentLayer["effectLayer" .. bulletManager:getZorder(self.bullet.id, "progress")])
			game:playMusic(bulletManager:getMusicId(self.bullet.id, "progress"))
			bulletSprite:runAction(transition.sequence(actions))
		end

	elseif self.bullet.csvData.type == 3 then
		local time = ccpDistance(ccp(self.position.x, self.position.y + self.hurtOffset), ccp(params.enemy.position.x, params.enemy.position.y + params.enemy.hurtOffset)) / self.bulletData.speed
		local angle = ccp(params.enemy.position.x - self.position.x, params.enemy.position.y - self.position.y):getAngle()
		angle = (self.camp == "left") and (angle / math.pi * -180) or ((angle / math.pi * -180) - 180)

		local bulletSprite = bulletManager:getFrameSprite(self.bullet.id, "progress")
		bulletSprite:addTo(self.parentLayer["effectLayer" .. bulletManager:getZorder(self.bullet.id, "progress")]):rotation(angle):flipX(self.camp == "left")
			:pos(self.position.x + self.bulletData.oppositeX1 * xCoefficient, self.position.y + self.bulletData.oppositeY1 + self.hurtOffset)

		bulletSprite:playAnimationForever(bulletManager:getAnimation(self.bullet.id, "progress"))
		
		local actions = {}
		actions[#actions + 1] = CCMoveTo:create(time, ccp(params.enemy.position.x, params.enemy.position.y + params.enemy.hurtOffset))
		actions[#actions + 1] = CCRemoveSelf:create()
		actions[#actions + 1] = CCCallFunc:create(function() playHurtAction() end)

		game:playMusic(bulletManager:getMusicId(self.bullet.id, "progress"))
		bulletSprite:runAction(transition.sequence(actions))

	elseif self.bullet.csvData.type == 4 then
		for index = 1, self.bullet.csvData.playCount do
			local bezier = ccBezierConfig()
			bezier.controlPoint_1 = ccp(self.position.x + self.bulletData.oppositeX1, self.position.y + self.bulletData.oppositeY1 + self.hurtOffset)
			bezier.controlPoint_2 = ccp((self.position.x + params.enemy.position.x) / 2,
				(self.position.y + params.enemy.position.y) / 2 + 450)
			bezier.endPosition = ccp(params.enemy.position.x, params.enemy.position.y)

			local bulletSprite = bulletManager:getFrameSprite(self.bullet.id, "progress")
			bulletSprite:flipX(self.camp == "left"):rotation(self.camp == "right" and 60 or -60)
				:addTo(self.parentLayer["effectLayer" .. bulletManager:getZorder(self.bullet.id, "progress")]):flipX(self.camp == "left"):hide()
				:pos(self.position.x + self.bulletData.oppositeX1 * xCoefficient, self.position.y + self.bulletData.oppositeY1 + self.hurtOffset)

			local time = math.abs(self.position.x - params.enemy.position.x) / self.bulletData.speed

			local actions = {}
			local array = CCArray:create()
			array:addObject(CCBezierTo:create(time, bezier))
			array:addObject(CCRotateTo:create(time, self.camp == "right" and -45 or 45))
			array:addObject(CCAnimate:create(bulletManager:getAnimation(self.bullet.id, "progress")))
			if index < self.bullet.csvData.playCount then
				actions[#actions + 1] = CCDelayTime:create(self.bullet.csvData.playInterval / 1000 * (index - 1))
			end
			actions[#actions + 1] = CCShow:create()
			actions[#actions + 1] = CCSpawn:create(array)
			actions[#actions + 1] = CCRemoveSelf:create()

			if index == self.bullet.csvData.playCount then
				actions[#actions + 1] = CCCallFunc:create(function() playHurtAction() end)
			end
			
			game:playMusic(bulletManager:getMusicId(self.bullet.id, "progress"))
			bulletSprite:runAction(transition.sequence(actions))
		end
	end
end

function SpriteSoldier:onSkillAttack(params)
	self.actionStatus = "skill"

	-- 每次攻击产生一个特效
	self:playAnimation(self.unitData.skillAnimateName)
end

function SpriteSoldier:refreshHpProgress()
	self.hpProgress:setPercentage(self.hp * 100 / self.maxHp)
end

-- 冒血数字&效果美术字&二级属性冒字
function SpriteSoldier:onHurt(params)
	local origPercent = params.origHp * 100 / self.maxHp
	local nowPercent = self.hp * 100 / self.maxHp
	self.hpProgress:runAction(CCProgressFromTo:create(0.2, origPercent, nowPercent))
	
	local hurtValue = math.ceil(params.hurtValue)
	local fontRes = "num_r.fnt"
	if hurtValue < 0 then
		fontRes = "num_g.fnt"
	else
		fontRes = self.camp == "left" and "num_r.fnt" or "num_y.fnt"
	end

	if params.effect and params.effect == "crit" then
		local hurtNode = display.newNode()
		local critSprite = display.newSprite(BattleRes .. "effect/crit.png")
		local critTips = ui.newBMFontLabel({ 
			text = hurtValue >= 0 and "-" ..tostring(hurtValue) or "+" .. math.abs(hurtValue),
			font = "resource/ui_rc/battle/font/" .. fontRes, })
	
		local width, height = critSprite:getContentSize().width + critTips:getContentSize().width, critTips:getContentSize().height
		hurtNode:size(width + 5, height)
		critSprite:anch(0, 0.5):pos(0, height / 2):addTo(hurtNode)
		critTips:anch(1, 0.5):pos(width, height / 2):addTo(hurtNode)

		hurtNode:anch(0.5, 0.5):scale(1):pos(self.nodeSize.width / 2, hpBaseHight):addTo(self.displayNode, SpriteSoldier.zOrderConstants["hpChange"])
		hurtNode:setRotationY(self.camp == "left" and 180 or 0)
		hurtNode:runAction(transition.sequence({
			CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 30)), CCScaleTo:create(0.1, 1.25)),
			CCDelayTime:create(0.2),
			CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 10)), CCScaleTo:create(0.1, 1)),
			CCSpawn:createWithTwoActions(CCMoveBy:create(0.5, ccp(0, 30)), CCFadeOut:create(0.5)),
			CCRemoveSelf:create()
		}))
	else
		if params.restraint and params.restraint > 1 then
			local hurtNode = display.newNode()
			local restraintSprite = display.newSprite(BattleRes .. "effect/restraint.png")
			local restraintTips = ui.newBMFontLabel({ 
				text = hurtValue >= 0 and "-" ..tostring(hurtValue) or "+" .. math.abs(hurtValue),
				font = "resource/ui_rc/battle/font/" .. fontRes, })
		
			local width, height = restraintSprite:getContentSize().width + restraintTips:getContentSize().width, restraintTips:getContentSize().height
			hurtNode:size(width + 5, height)
			restraintSprite:anch(0, 0.5):pos(0, height / 2):addTo(hurtNode)
			restraintTips:anch(1, 0.5):pos(width, height / 2):addTo(hurtNode)

			hurtNode:anch(0.5,0.5):scale(0.5):pos(self.nodeSize.width / 2, hpBaseHight):addTo(self.displayNode, SpriteSoldier.zOrderConstants["hpChange"])
			hurtNode:setRotationY(self.camp == "left" and 180 or 0)
			hurtNode:runAction(transition.sequence({
				CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 30)), CCScaleTo:create(0.1, 1)),
				CCDelayTime:create(0.2),
				CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 10)), CCScaleTo:create(0.1, 0.75)),
				CCSpawn:createWithTwoActions(CCMoveBy:create(0.5, ccp(0, 30)), CCFadeOut:create(0.5)),
				CCRemoveSelf:create()
			}))
		else
			local hurtValueText = ui.newBMFontLabel({ 
				text = hurtValue >= 0 and "-"..tostring(hurtValue) or "+" .. math.abs(hurtValue),
				font = "resource/ui_rc/battle/font/" .. fontRes, })
			hurtValueText:scale(0.5):pos(self.nodeSize.width / 2, hpBaseHight):addTo(self.displayNode, SpriteSoldier.zOrderConstants["hpChange"])
			hurtValueText:setRotationY(self.camp == "left" and 180 or 0)
			hurtValueText:runAction(transition.sequence({
				CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 30)), CCScaleTo:create(0.1, 1)),
				CCDelayTime:create(0.2),
				CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 10)), CCScaleTo:create(0.1, 0.75)),
				CCSpawn:createWithTwoActions(CCMoveBy:create(0.5, ccp(0, 30)), CCFadeOut:create(0.5)),
				CCRemoveSelf:create()
			}))
		end
	end
	
	self:dispatchEvent({ name = "hpChangeRate", origPercent = origPercent, nowPercent = nowPercent })
end

function SpriteSoldier:onEffect(effect)
	if effect == nil then return end
	
	if effect ~= "normal" and effect ~= "crit" then
		local effectSprite = display.newSprite( BattleRes .. "effect/" .. effect .. ".png")
		effectSprite:scale(0.5):pos(self.nodeSize.width / 2, hpBaseHight + 50):addTo(self.displayNode, SpriteSoldier.zOrderConstants["secondAttr"])
		effectSprite:setRotationY(self.camp == "left" and 180 or 0)
		effectSprite:runAction(transition.sequence({
			CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 20)), CCScaleTo:create(0.1, 1)),
			CCDelayTime:create(0.2),
			CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 10)), CCScaleTo:create(0.1, 0.75)),
			CCSpawn:createWithTwoActions(CCMoveBy:create(0.5, ccp(0, 30)), CCFadeOut:create(0.5)),
			CCRemoveSelf:create()
		}))
	end
end

function SpriteSoldier:onTextEffect(params)
	if params.effect ~= nil then
		if params.value ~= nil then
			local value = params.value
			if params.effect ~= "anger" then
				value = params.value - params.value % 1
			end
			local hurtNode = display.newNode()
			local critSprite = display.newSprite(BattleRes .. "effect/" .. params.effect .. ".png")
			local font = "resource/ui_rc/battle/font/num_b.fnt"
			if params.fontColor and params.fontColor == "green" then
				font = "resource/ui_rc/battle/font/num_g.fnt"
			end
			local critTips = ui.newBMFontLabel({ 
				text = value > 0 and "+" .. math.abs(value) or "-" .. math.abs(value),
				font = font, })
		
			local width, height = critSprite:getContentSize().width + critTips:getContentSize().width, critTips:getContentSize().height
			hurtNode:size(width + 5, height)
			if params.fontColor and params.fontColor == "green" then
				critTips:anch(0.5, 0.5):pos(width/2, height / 2 - 4):addTo(hurtNode)
			else
				critSprite:anch(0, 0.5):pos(0, height / 2):addTo(hurtNode)
				critTips:anch(1, 0.5):pos(width, height / 2 - 4):addTo(hurtNode)
			end

			hurtNode:anch(0.5, 0.5):scale(1):pos(self.nodeSize.width / 2, hpBaseHight):addTo(self.displayNode, SpriteSoldier.zOrderConstants["hpChange"])
			hurtNode:setRotationY(self.camp == "left" and 180 or 0)
			hurtNode:runAction(transition.sequence({
				CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 30)), CCScaleTo:create(0.1, 1.25)),
				CCDelayTime:create(0.2),
				CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 10)), CCScaleTo:create(0.1, 1)),
				CCSpawn:createWithTwoActions(CCMoveBy:create(0.5, ccp(0, 30)), CCFadeOut:create(0.5)),
				CCRemoveSelf:create()
			}))
			return
		end
	end
end

-- buff修改状态
function SpriteSoldier:onChangeAttribute(params)
	local changeNode = display.newNode()

	local nameText = display.newSprite(BattleRes .. "effect/" .. string.format("attr_%s" .. ".png", params.name))

	local value = params.value - params.value % 1
	local attrString 
	if params.value > 0 then
		attrString = "+" .. value
	else
		attrString = tostring(value)
	end

	local attrLabel = ui.newBMFontLabel({ text = attrString, font = "resource/ui_rc/battle/font/num_b.fnt" })
	local nodeSize = CCSizeMake(nameText:getContentSize().width + 5 + attrLabel:getContentSize().width, nameText:getContentSize().height)
	changeNode:size(nodeSize)

	nameText:anch(0, 0.5):pos(0, nodeSize.height / 2):addTo(changeNode)
	attrLabel:anch(1, 0.5):pos(nodeSize.width, nodeSize.height / 2):addTo(changeNode)

	local delay = self.displayNode:getChildByTag(101) and 0.5 or 0
	changeNode:anch(0.5, 0):scale(0.5):pos(self.nodeSize.width / 2, hpBaseHight - 50)
		:addTo(self.displayNode, SpriteSoldier.zOrderConstants["hpChange"], 101)
	changeNode:setVisible(false)
	changeNode:setRotationY(self.camp == "left" and 180 or 0)
	changeNode:runAction(transition.sequence({
		CCDelayTime:create(delay),
		CCCallFunc:create(function() changeNode:setVisible(true) end),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.2, ccp(0, 20)), CCScaleTo:create(0.1, 1)),
		CCDelayTime:create(0.4),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.3, ccp(0, 20)), CCScaleTo:create(0.3, 0.75)),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.5, ccp(0, 40)), CCFadeOut:create(0.5)),
		CCRemoveSelf:create()
	}))
end

function SpriteSoldier:onLeaveSkillAttack(params)
	if self.skillProgress == 0 then return end

	-- 如果还在放技能的途中被干掉, 很难重现
	local camp = self.battle.battleField[self.camp .. "Camp"]
	camp.skillRefCount = camp.skillRefCount - 1
	self.skillProgress = 0

	if camp.skillRefCount == 0 then
		self.parentLayer:resume()
		self.parentLayer.effectLayer0:resume()
		self.parentLayer.effectLayer1:resume()
		self.parentLayer.heroBottomLayer:onPause(false)			--恢复CD
		self.parentLayer:showSkillMask(false, self)

		transition.resumeTarget(self.parentLayer.leftTimeLabel)		--恢复计时器
		self.battle:pause(false)
	end
end

function SpriteSoldier:onDeath(params)
	if self.actionStatus == "dead" then return end

	self.actionStatus = "dead"
	self:playAnimation("dead")

	

	if self.camp == "right" and self.parentLayer.battleType ~= BattleType.Start then

		--骷髅：
		-- local deathSoul = display.newSprite(BattleRes .. "skillnum_bg.png")
		-- deathSoul:pos(self.position.x, self.position.y):addTo(self.parentLayer, 100)

		--火球：
		CCTextureCache:sharedTextureCache():addImage(BattleRes.."fire_source.png")
		local hurtEffect = CCParticleSystemQuad:new()
		hurtEffect:autorelease()
		hurtEffect:initWithFile(BattleRes.."SimpleSoul.plist")
		self.parentLayer:addChild(hurtEffect, 100)
		hurtEffect:setPosition(ccp(self.position.x, self.position.y))
		hurtEffect:setScale(1)

		local angryFrame = self.parentLayer:getChildByTag(1001)
		local xPos = (display.cx - 200) + self.battleField.leftCamp.angryUnitNum / 8 * 450
		local arcx = randomInt(0, 2)
		local arcy = randomInt(1, 2)
		local bezier = self:randomBezier(self.position.x, self.position.y,display.cx - 160, 210, arcx, arcy)
		hurtEffect:runAction(transition.sequence{
			CCDelayTime:create(0.4),
			CCBezierTo:create(1.2, bezier),
			CCRemoveSelf:create(),
			CCCallFunc:create(function()
				--怒火：
				self.parentLayer:fireForDead()
				-- 对方加怒气
				angryFrame:runAction(transition.sequence{
					CCScaleTo:create(0.1, 1.05),
					CCScaleTo:create(0.1, 1),
				})
				self.battleField.leftCamp:addAngryUnit(globalCsv:getFieldValue("killEnemyAnger"))
			end)
		})
	else
		local campInstance = self.battleField[(self.camp == "right" and "left" or "right") .. "Camp"]
		campInstance:addAngryUnit(globalCsv:getFieldValue("killEnemyAnger"))
	end

	-- self:dispatchEvent({ name = "soldierDead" })
	-- self.battleField:removeSoldier(self)
end

function SpriteSoldier:onFrozen(params)
	if self.actionStatus == "frozen" then return end

	self.actionStatus = "frozen"
	self.animation:pause()
	if self.effectAnimation then
		self.effectAnimation:pause()
	end
end

function SpriteSoldier:onDizzy(params)
	if self.actionStatus == "dizzy" then return end

	self.actionStatus = "dizzy"
	self:playAnimation("damaged")
end

function SpriteSoldier:onHypnosis(params)
	if self.actionStatus == "hypnosis" then return end

	self.actionStatus = "hypnosis"
	self:playAnimation("damaged")
end

function SpriteSoldier:onDamaged(params)
	self.actionStatus = "damaged"
	self:playAnimation("damaged")
end

function SpriteSoldier:onDreamKill( ... )
	if self.actionStatus == "dreamKill" then return end

	self.actionStatus = "dreamKill"
	self:playAnimation("attack4")
end

function SpriteSoldier:onPause(bool)
	if bool then
		local children = self.displayNode:getChildren()
		local childsNum = self.displayNode:getChildrenCount()
		for index = 0, childsNum - 1 do
			local child = tolua.cast(children:objectAtIndex(index), "CCNode")
			transition.pauseTarget(child)
		end

		self.animation:pause()
		if self.effectAnimation then
			self.effectAnimation:pause()
		end
	else
		local children = self.displayNode:getChildren()
		local childsNum = self.displayNode:getChildrenCount()
		for index = 0, childsNum - 1 do
			local child = tolua.cast(children:objectAtIndex(index), "CCNode")
			transition.resumeTarget(child)
		end

		self.animation:resume()
		if self.effectAnimation then
			self.effectAnimation:resume()
		end
	end
end

function SpriteSoldier:clearStatus()
	SpriteSoldier.super.clearStatus(self)

	self.displayNode:removeSelf()
	self.displayNode = nil

	self.actionStatus = "idle"
	self:initHeroDisplay()
end

function SpriteSoldier:dispose()
	SpriteSoldier.super.dispose(self)

	self.displayNode:removeSelf()
	self.displayNode = nil
end

function SpriteSoldier:randomBezier(sx, sy, ex, ey, arcx, arcy)
	local  bezier = ccBezierConfig()
	local dx = ex - sx
	local dy = ey - sy

	local x1 = randomInt(sx, sx + dx *arcx)
	local y1 = randomInt(sy, sy + dy *arcy)

	local x2 = randomInt(sx, ex - dx *arcx)
	local y2 = randomInt(sy, ey - dy *arcy)

	bezier.controlPoint_1 = ccp(x1, y1)
	bezier.controlPoint_2 = ccp(x2, y2)
	bezier.endPosition = ccp(ex, ey)
	return bezier
end

return SpriteSoldier
