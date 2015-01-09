import(".BattleConstants")

local SpriteSoldier = import(".SpriteSoldier")

local SpriteBullet = class("SpriteBullet", require("logical.battle.Bullet"))

function SpriteBullet:ctor(params)
	SpriteBullet.super.ctor(self, params)

	-- 技能展示层
	if self.skill then self.parentLayer = self.skill.owner.parentLayer end

	self.hasDispose = false

	self.hasAnimation = bulletManager:load(self.csvData.id)
end

function SpriteBullet:suckHpFromHurt(hurt)
	-- 释放者有可能已经被干掉
	if self.skill.owner then
		local growth = self.skill.csvData.suckHpGrowth or 0
		local suckHpValue = hurt * (self.skill.csvData.suckHpPercent + (self.skill.level - 1) * growth) / 100
		self.skill.owner:beingHurt({ hurtValue = -suckHpValue })
	end
end

-- 瞬时
function SpriteBullet:onEffect1(params)
	if self.inButtleAction then return end
	self.inButtleAction = true

	local function hurtEffect()
		self:onProgressEffectOver(params.enemy)

		params.enemy:onEffect(params.hurtValues.effect)
		params.enemy:beingHurt({ hurtValue = params.hurtValues.enemy, attacker = self.skill.owner, hurtFrom = 2 })
		if self.skill.owner then
			self.skill.owner:beingHurt({ hurtValue = params.hurtValues.self, attacker = params.enemy })
		end
		self:onHurtEnemy({ enemy = params.enemy })

		if params.last then
			self:onEffectLastSoldier()

			self.inEffectProgress = false
			
			-- 吸血
			self:suckHpFromHurt(params.totalHurtValue)

			self.hasHurtCount = self.hasHurtCount + 1
		end
	end

	local yOffset = self.skill.owner.hurtOffset

	game:playMusic(bulletManager:getMusicId(self.csvData.id, "progress"))

	if bulletManager:getFrameCount(self.csvData.id, "progress") <= 0 then hurtEffect() return end
	-- 持续特效
	local actions = {}

	local bulletSprite = bulletManager:getFrameSprite(self.csvData.id, "progress")
	bulletSprite:pos(self.csvData.oppositeX1 + self.skill.owner.nodeSize.width / 2, self.csvData.oppositeY1 + yOffset)
	bulletSprite:addTo(self.skill.owner.displayNode, SpriteSoldier.zOrderConstants["bulletLayer" .. bulletManager:getZorder(self.csvData.id, "progress")])

	actions[#actions + 1] = CCAnimate:create(bulletManager:getAnimation(self.csvData.id, "progress"))
	actions[#actions + 1] = CCCallFunc:create(function() hurtEffect() end)
	actions[#actions + 1] = CCRemoveSelf:create()
	bulletSprite:runAction(transition.sequence(actions))
end

-- 单体
function SpriteBullet:onEffect2(params)
	params = params or {}
	params.soldiers = params.soldiers or {}

	local totalHurtValue = 0
	local yOffset = self.skill.owner.hurtOffset
	for index, soldier in ipairs(params.soldiers) do
		local hurtValues = self.skill:calcHurtValue(soldier)
		if hurtValues.enemy > 0 then
			totalHurtValue = totalHurtValue + hurtValues.enemy
		end

		local function hurtEffect()
			self:onProgressEffectOver(soldier)

			soldier:onEffect(hurtValues.effect)
			soldier:beingHurt({ hurtValue = hurtValues.enemy, effect = hurtValues.effect, attacker = self.skill.owner, hurtFrom = 2 })
			
			if index == #params.soldiers then
				self:onEffectLastSoldier()
				
				self.inEffectProgress = false
				-- 吸血
				self:suckHpFromHurt(totalHurtValue)
			end
			if self.skill.owner then
				self.skill.owner:beingHurt({ hurtValue = hurtValues.self, attacker = soldier })
			end

			self:onHurtEnemy({ enemy = soldier })
		end

		-- 浮空
		if self.csvData.jump == 1 and not soldier.curInvincible then
			local jumpAction = CCJumpBy:create(0.5, ccp(0, 100), 100, 1)
			soldier.sprite:runAction(transition.sequence{
				CCEaseOut:create(jumpAction, 0.1), jumpAction:reverse()
			})
		end
		
		-- 持续特效
		game:playMusic(bulletManager:getMusicId(self.csvData.id, "progress"))
		if bulletManager:getFrameCount(self.csvData.id, "progress") <= 0 then
			hurtEffect()
		else
			local actions = {}
			local bulletSprite = bulletManager:getFrameSprite(self.csvData.id, "progress")
			bulletSprite:pos(self.csvData.oppositeX1 + soldier.nodeSize.width / 2, self.csvData.oppositeY1 + yOffset)
			bulletSprite:flipX(true):addTo(soldier.displayNode, SpriteSoldier.zOrderConstants["bulletLayer" .. bulletManager:getZorder(self.csvData.id, "progress")])

			actions[#actions + 1] = CCAnimate:create(bulletManager:getAnimation(self.csvData.id, "progress"))

			-- 结束特效
			if self.hasHurtCount == self.skill.csvData.hurtCount - 1 and bulletManager:getFrameCount(self.csvData.id, "end") > 0 then
				actions[#actions + 1] = CCCallFunc:create(function()
					bulletSprite:zorder(SpriteSoldier.zOrderConstants["bulletLayer" .. bulletManager:getZorder(self.csvData.id, "end")])
					bulletSprite:displayFrame(bulletManager:getFrame(self.csvData.id, "end"))
					bulletSprite:pos(self.csvData.oppositeX1, self.csvData.oppositeY1 + yOffset)
				end)
				actions[#actions + 1] = CCAnimate:create(bulletManager:getAnimation(self.csvData.id, "end"))
			end
			actions[#actions + 1] = CCCallFunc:create(function() hurtEffect() end)
			actions[#actions + 1] = CCRemoveSelf:create()
			bulletSprite:runAction(transition.sequence(actions))
		end
	end

	self:postEffect(params)

	-- 伤害次数
	self.hasHurtCount = self.hasHurtCount + 1
end

-- 直线
function SpriteBullet:onEffect3(params)
	local yOffset = self.skill.owner.hurtOffset
	local xCoefficient = self.skill.owner.camp == "left" and 1 or -1

	-- x轴直线飞行
	if self.skill.csvData.effectRangeType == 2 then
		if not params.time then
			--	增加到显示层
			self.bulletSprite = bulletManager:getFrameSprite(self.csvData.id, "progress")
			self.bulletSprite:addTo(self.parentLayer["effectLayer" .. bulletManager:getZorder(self.csvData.id, "progress")])
				:pos(self.skill.startPosition.x + self.csvData.oppositeX1 * xCoefficient, self.skill.startPosition.y + self.csvData.oppositeY1 + yOffset)
				:flipX(self.skill.owner.camp == "left")
			-- 移动
			
			game:playMusic(bulletManager:getMusicId(self.csvData.id, "progress"))
			self.bulletSprite:playAnimationForever(bulletManager:getAnimation(self.csvData.id, "progress"))

			return false
		end

		if self.curPosition.x <= 0 or self.curPosition.x >= display.width then
			self.bulletSprite:removeSelf()
			return true
		end

		self.bulletSprite:moveTo(params.time / 1000, self.curPosition.x + self.csvData.oppositeX1, self.curPosition.y + self.csvData.oppositeY1 + yOffset)
		return false
	else -- 单体
		local actions = {}

		-- 持续特效
		game:playMusic(bulletManager:getMusicId(self.csvData.id, "progress"))
		if bulletManager:getFrameCount(self.csvData.id, "progress") <= 0 then return end

		local angle = ccp(params.enemy.position.x - self.skill.owner.position.x, params.enemy.position.y - self.skill.owner.position.y):getAngle()
		angle = (self.skill.owner.camp == "left") and (angle / math.pi * -180) or ((angle / math.pi * -180) - 180)

		local bulletSprite = bulletManager:getFrameSprite(self.csvData.id, "progress")
		bulletSprite:pos(self.skill.startPosition.x + self.csvData.oppositeX1 * xCoefficient, self.skill.startPosition.y + self.csvData.oppositeY1 + yOffset)
			:rotation(angle):flipX(self.skill.owner.camp == "left")
		bulletSprite:playAnimationForever(bulletManager:getAnimation(self.csvData.id, "progress"))
		bulletSprite:addTo(self.parentLayer["effectLayer" .. bulletManager:getZorder(self.csvData.id, "progress")])

		local time = math.abs(self.skill.startPosition.x - params.enemy.position.x) / self.csvData.speed
		actions[#actions + 1] = CCMoveTo:create(time, ccp(params.enemy.position.x, params.enemy.position.y + yOffset))
		actions[#actions + 1] = CCRemoveSelf:create()
		actions[#actions + 1] = CCCallFunc:create(function() 
			self:onProgressEffectOver(params.enemy)
			
			params.enemy:onEffect(params.hurtValues.effect)
			params.enemy:beingHurt({ hurtValue = params.hurtValues.enemy, attacker = self.skill.owner, hurtFrom = 2 })
			self:onHurtEnemy({ enemy = params.enemy })
			if self.skill.owner then
				self.skill.owner:beingHurt({ hurtValue = params.hurtValues.self, attacker = params.enemy })
			end

			if params.last then
				self:onEffectLastSoldier()

				self.inEffectProgress = false
				-- 吸血
				self:suckHpFromHurt(params.totalHurtValue)
			end

			self.hasHurtCount = self.hasHurtCount + 1
		end)
		bulletSprite:runAction(transition.sequence(actions))
	end

	self:postEffect(params)
end

-- 抛物线
function SpriteBullet:onEffect4(params)
	local xCoefficient = self.skill.owner.camp == "left" and 1 or -1
	local yOffset = self.skill.owner.hurtOffset
	for index = 1, self.csvData.playCount do
		local bezier = ccBezierConfig()
		bezier.controlPoint_1 = ccp(self.skill.startPosition.x + self.csvData.oppositeX1, self.skill.startPosition.y + self.csvData.oppositeY1 + yOffset)
		bezier.controlPoint_2 = ccp((self.skill.startPosition.x + params.enemy.position.x) / 2,
			(self.skill.startPosition.y + params.enemy.position.y) / 2 + 450)
		bezier.endPosition = ccp(params.enemy.position.x, params.enemy.position.y + yOffset)

		-- 持续特效
		game:playMusic(bulletManager:getAnimation(self.csvData.id, "progress"))
		if bulletManager:getFrameCount(self.csvData.id, "progress") > 0 then
			local bulletSprite = bulletManager:getFrameSprite(self.csvData.id, "progress")
			bulletSprite:pos(self.skill.startPosition.x + self.csvData.oppositeX1 * xCoefficient, self.skill.startPosition.y + self.csvData.oppositeY1 + yOffset)

			bulletSprite:playAnimationForever(bulletManager:getAnimation(self.csvData.id, "progress"))
			bulletSprite:flipX(params.enemy.camp == "right"):rotation(params.enemy.camp == "right" and -60 or 60)
				:addTo(self.parentLayer["effectLayer" .. bulletManager:getZorder(self.csvData.id, "progress")]):hide()

			local time = math.abs(self.skill.startPosition.x - params.enemy.position.x) / self.csvData.speed

			local actions = {}
			local array = CCArray:create()
			array:addObject(CCBezierTo:create(time, bezier))
			array:addObject(CCRotateBy:create(time, params.enemy.camp == "right" and 120 or -120))

			actions[#actions + 1] = CCDelayTime:create(self.csvData.playInterval / 1000 * (index - 1))
			actions[#actions + 1] = CCShow:create()
			actions[#actions + 1] = CCSpawn:create(array)
			actions[#actions + 1] = CCRemoveSelf:create()
			actions[#actions + 1] = CCCallFunc:create(function()
				self:onProgressEffectOver(params.enemy)--持续特效完后增加相应的BUFF

				params.enemy:beingHurt({ hurtValue = params.hurtValues.enemy / self.csvData.playCount, attacker = self.skill.owner, hurtFrom = 2 })
				if params.last then
					params.enemy:onEffect(params.hurtValues.effect)
					self.inEffectProgress = false
					-- 吸血
					self:suckHpFromHurt(params.totalHurtValue)

					self.skill.owner:beingHurt({ hurtValue = params.hurtValues.self, attacker = params.enemy })
				end

				self:onHurtEnemy({ enemy = params.enemy })
				self.hasHurtCount = self.hasHurtCount + 1
			end)
			bulletSprite:runAction(transition.sequence(actions))
		end
	end

	self:postEffect(params)
end

-- 已经不用
function SpriteBullet:onEffect5(params)
	local xPos = self.skill.camp == "left" and self.skill.startPosition.x + 120 or self.skill.startPosition.x - 120
	if self.skill.skillCenter then xPos = self.skill.skillCenter.position.x + self.csvData.oppositeX1 end

	local yPos = (260 + 350) / 2 + 50
	local xCoefficient = self.skill.owner.camp == "left" and 1 or -1

	-- 持续特效
	game:playMusic(bulletManager:getMusicId(self.csvData.id, "progress"))
	if bulletManager:getFrameCount(self.csvData.id, "progress") <= 0 then return end

	local actions = {}
	local bulletSprite = bulletManager:getFrameSprite(self.csvData.id, "progress")
	bulletSprite:pos(xPos + self.csvData.oppositeX1 * xCoefficient, yPos + self.csvData.oppositeY1)
	bulletSprite:addTo(self.parentLayer["effectLayer" .. bulletManager:getZorder(self.csvData.id, "progress")])

	actions[#actions + 1] = CCAnimate:create(bulletManager:getAnimation(self.csvData.id, "progress"))

	-- 伤害, 新的时间线
	actions[#actions + 1] = CCCallFunc:create(function() 
		self.inEffectProgress = false

		local totalHurtValue = 0
		for index, soldier in ipairs(params.soldiers) do
			local hurtValues = self.skill:calcHurtValue(soldier)
			if hurtValues.enemy > 0 then
				totalHurtValue = totalHurtValue + hurtValues.enemy
			end
			soldier:onEffect(hurtValues.effect)
			soldier:beingHurt({ hurtValue = hurtValues.enemy, attacker = self.skill.owner, hurtFrom = 2})
			if index == #params.soldiers then
				self:onEffectLastSoldier()
				-- 吸血
				self:suckHpFromHurt(totalHurtValue)
			end
			if self.skill.owner then
				self.skill.owner:beingHurt({ hurtValue = hurtValues.self, attacker = soldier })
			end
			self:onHurtEnemy({ enemy = soldier })
		end
	end)

	-- 结束特效
	if self.hasHurtCount == self.skill.csvData.hurtCount - 1 and bulletManager:getFrameCount(self.csvData.id, "end") > 0 then
		actions[#actions + 1] = CCCallFunc:create(function()
			bulletSprite:displayFrame(bulletManager:getFrame(self.csvData.id, "end"))
			bulletSprite:zorder(SpriteSoldier.zOrderConstants["bulletLayer" .. bulletManager:getZorder(self.csvData.id, "end")])
		end)
		actions[#actions + 1] = CCAnimate:create(bulletManager:getAnimation(self.csvData.id, "end"))
	end

	-- 伤害次数
	actions[#actions + 1] = CCCallFunc:create(function() self.hasHurtCount = self.hasHurtCount + 1 end)
	actions[#actions + 1] = CCRemoveSelf:create()

	bulletSprite:runAction(transition.sequence(actions))

	self:postEffect(params)
end

-- y轴飞行
function SpriteBullet:onEffect6(params)
	local xPos = self.skill.startPosition.x
	local yPos = (260 + 350) / 2 + 50
	local xCoefficient = self.skill.owner.camp == "left" and 1 or -1

	-- 持续特效
	game:playMusic(bulletManager:getMusicId(self.csvData.id, "progress"))
	if bulletManager:getFrameCount(self.csvData.id, "progress") <= 0 then return end

	local actions = {}
	local bulletSprite = bulletManager:getFrameSprite(self.csvData.id, "progress")
	bulletSprite:pos(xPos + self.csvData.oppositeX1 * xCoefficient, yPos + self.csvData.oppositeY1)
	bulletSprite:flipX(self.skill.owner.camp == "left")
		:addTo(self.parentLayer["effectLayer" .. bulletManager:getZorder(self.csvData.id, "progress")])

	-- 选到了人 
	if #params.soldiers > 0 then
		local time = math.abs(self.skill.startPosition.x - params.soldiers[1].position.x) / self.csvData.speed
		
		local array = CCArray:create()
		array:addObject(CCMoveTo:create(time, ccp(params.soldiers[1].position.x, yPos)))
		array:addObject(CCAnimate:create(bulletManager:getAnimation(self.csvData.id, "progress")))

		actions[#actions + 1] = CCSpawn:create(array)
		actions[#actions + 1] = CCRemoveSelf:create()
		actions[#actions + 1] = CCCallFunc:create(function() 
			self.inEffectProgress = false

			for _,soldier in pairs(params.soldiers) do 
				self:onProgressEffectOver(soldier)

				local hurtValues = self.skill:calcHurtValue(soldier)
				soldier:beingHurt({ hurtValue = hurtValues.enemy, attacker = self.skill.owner, hurtFrom = 2 })
				soldier:onEffect(hurtValues.effect)

				-- 己方受格挡伤害
				if self.skill.owner then
					self.skill.owner:beingHurt({ hurtValue = hurtValues.self, attacker = soldier })
				end
				self:onHurtEnemy({ enemy = soldier })
			end

			self.hasHurtCount = self.hasHurtCount + 1
		end)
	else
		local time = 200 / self.csvData.speed

		local array = CCArray:create()
		local desX = self.skill.owner.camp == "left" and self.skill.startPosition.x + 200 or self.skill.startPosition.x - 200
		array:addObject(CCMoveTo:create(time, ccp(desX, yPos)))
		array:addObject(CCAnimate:create(bulletManager:getAnimation(self.csvData.id, "progress")))

		actions[#actions + 1] = CCSpawn:create(array)
		actions[#actions + 1] = CCRemoveSelf:create()
		actions[#actions + 1] = CCCallFunc:create(function() 
			self.inEffectProgress = false
			self.hasHurtCount = self.hasHurtCount + 1
		end)
	end

	bulletSprite:runAction(transition.sequence(actions))

	self:postEffect(params)
end

-- 全屏技能
function SpriteBullet:onEffect7(params)
	if #params.soldiers == 0 then return end

	-- 去所有受击者的中心点
	local xMax,xMin = -1, 100000
	for _,soldier in pairs(params.soldiers) do
		if soldier.position.x > xMax then
			xMax = soldier.position.x
		end

		if soldier.position.x < xMin then
			xMin = soldier.position.x
		end
	end

	local xPos = (xMax + xMin) / 2
	local yPos = (260 + 350) / 2 + 50
	local xCoefficient = self.skill.owner.camp == "left" and 1 or -1

	game:playMusic(bulletManager:getMusicId(self.csvData.id, "progress"))
	if bulletManager:getFrameCount(self.csvData.id, "progress") <= 0 then return end

	local progressSprite = bulletManager:getFrameSprite(self.csvData.id, "progress")
	progressSprite:flipX(self.skill.owner.camp == "left")
		:anch(0.5,0.5):pos(xPos + self.csvData.oppositeX1 * xCoefficient, yPos + self.csvData.oppositeY1)
		:addTo(self.parentLayer["effectLayer" .. bulletManager:getZorder(self.csvData.id, "progress")])

	local actions = {}
	actions[#actions + 1] = CCAnimate:create(bulletManager:getAnimation(self.csvData.id, "progress"))

	-- 伤害, 新的时间线
	actions[#actions + 1] = CCCallFunc:create(function() 
		self.inEffectProgress = false
	end)

	local bulletActionData = require("csv.BulletActCsv")
	bulletActionData:load(self.csvData.actCsv)
	local actionData = bulletActionData:getActDataById(BulletActionId["progress"])
	local progressTime = #actionData.frameIDs / actionData.fps

	local totalHurtValue = 0
	for index, soldier in ipairs(params.soldiers) do
		local r = randomInt(1, 100)
		local scheduler = require("framework.scheduler")
		scheduler.performWithDelayGlobal(function()
			self:onProgressEffectOver(soldier)

			local hurtValues = self.skill:calcHurtValue(soldier)
			if hurtValues.enemy > 0 then
				totalHurtValue = totalHurtValue + hurtValues.enemy
			end
			soldier:onEffect(hurtValues.effect)
			soldier:beingHurt({ hurtValue = hurtValues.enemy, attacker = self.skill.owner, hurtFrom = 2 })
			if index == #params.soldiers then
				self:onEffectLastSoldier()
				-- 吸血
				self:suckHpFromHurt(totalHurtValue)
			end
			if self.skill.owner then
				self.skill.owner:beingHurt({ hurtValue = hurtValues.self, attacker = soldier })
			end

			-- 伤害表现
			self:onHurtEnemy({ enemy = soldier })
		end, progressTime * r / 100)

	end

	-- 结束特效
	if self.hasHurtCount == self.skill.csvData.hurtCount - 1 and bulletManager:getFrameCount(self.csvData.id, "end") > 0 then
		actions[#actions + 1] = CCCallFunc:create(function()
			progressSprite:displayFrame(bulletManager:getFrame(self.csvData.id, "end"))
			progressSprite:zorder(SpriteSoldier.zOrderConstants["bulletLayer" .. bulletManager:getZorder(self.csvData.id, "end")])
		end)
		actions[#actions + 1] = CCAnimate:create(bulletManager:getAnimation(self.csvData.id, "end"))
	end

	-- 伤害次数
	actions[#actions + 1] = CCCallFunc:create(function() 
		self.hasHurtCount = self.hasHurtCount + 1 
		self:onHurtOverGlobal(params.soldiers)
	end)
	actions[#actions + 1] = CCRemoveSelf:create()

	progressSprite:runAction(transition.sequence(actions))

	self:postEffect(params)
end

function SpriteBullet:onEffect8(params)
	params = params or {}
	params.soldiers = params.soldiers or {}

	local totalHurtValue = 0
	local yOffset = self.skill.owner.hurtOffset

	--记录技术施放者的Z order用于技能结束后还原
	local oldZ = self.skill.owner.displayNode:getZOrder()

	for index, soldier in ipairs(params.soldiers) do
		local hurtValues = self.skill:calcHurtValue(soldier)
		if hurtValues.enemy > 0 then
			totalHurtValue = totalHurtValue + hurtValues.enemy
		end

		local function hurtEffect()
			self:onProgressEffectOver(soldier)

			soldier:onEffect(hurtValues.effect)
			soldier:beingHurt({ hurtValue = hurtValues.enemy, effect = hurtValues.effect, attacker = self.skill.owner, hurtFrom = 2 })
			
			if index == #params.soldiers then
				self:onEffectLastSoldier()

				self.inEffectProgress = false
				-- 吸血
				self:suckHpFromHurt(totalHurtValue)
			end
			if self.skill.owner then
				self.skill.owner:beingHurt({ hurtValue = hurtValues.self, attacker = soldier })
			end

			self:onHurtEnemy({ enemy = soldier })
		end

		-- 浮空
		if self.csvData.jump == 1 and not soldier.curInvincible then
			local jumpAction = CCJumpBy:create(0.5, ccp(0, 100), 100, 1)
			soldier.sprite:runAction(transition.sequence{
				CCEaseOut:create(jumpAction, 0.1), jumpAction:reverse()
			})
		end
		
		-- 持续特效
		game:playMusic(bulletManager:getMusicId(self.csvData.id, "progress"))
		if bulletManager:getFrameCount(self.csvData.id, "progress") <= 0 then
			hurtEffect()
		else
			local actions = {}
			local x1,y1 = self.skill.owner.displayNode:getPosition()
			x1 = x1 + self.csvData.oppositeX1
			y1 = y1 + self.csvData.oppositeY1
			local x2,y2 = soldier.displayNode:getPosition()
			x2 = x2 + self.csvData.oppositeX2
			y2 = y2 + self.csvData.oppositeY2
			local t = (y2 - y1) / math.abs(x2 - x1)
			local r = math.deg(math.atan(t))

			if self.skill.owner.camp == "left" then
				if x1 > x2 then r = 180 - r end
			else
				if x2 > x1 then r = 180 - r end
			end
			
			local l = math.sqrt( (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1))
			local bulletSprite = bulletManager:getFrameSprite(self.csvData.id, "progress")
			local texRect = bulletSprite:getTextureRect()
			bulletSprite:anch(1,0.5)
				:pos(self.skill.owner.nodeSize.width / 2 + self.csvData.oppositeX1, yOffset + self.csvData.oppositeY1)
				:rotation(r)
				:setScaleX(l/texRect.size.width)
			bulletSprite:addTo(self.skill.owner.displayNode, SpriteSoldier.zOrderConstants["bulletLayer" .. bulletManager:getZorder(self.csvData.id, "progress")])
			
			-- 使子弹特效显示在最上层
			self.skill.owner.displayNode:setZOrder(18)

			actions[#actions + 1] = CCAnimate:create(bulletManager:getAnimation(self.csvData.id, "progress"))
			actions[#actions + 1] = CCCallFunc:create(function() 
				hurtEffect() 
				self.skill.owner.displayNode:setZOrder(oldZ)
			end)
			actions[#actions + 1] = CCRemoveSelf:create()
			bulletSprite:runAction(transition.sequence(actions))
		end
	end

	-- 如果子弹有屏震效果, 产生屏震
	if self.csvData.screenShake == 1 then
		display.getRunningScene():runAction(transition.sequence({
			CCDelayTime:create(self.csvData.shakeDelay / 1000),
			CCCallFunc:create(function() uihelper.shake({ x = 0, y = 3, count = 20 }) end)			
		}))
	end

	-- 伤害次数
	self.hasHurtCount = self.hasHurtCount + 1
end

-- 抛物线
function SpriteBullet:onEffect9(params)
	if #params.soldiers == 0 then return end
	
	local xCoefficient = self.skill.owner.camp == "left" and 1 or -1
	local yOffset = self.skill.owner.hurtOffset

	local function findMaxByPro(pro,flag)
		local tempMaxOrMin=-100
		for _,soldier in ipairs(params.soldiers) do
			if flag=="<" then
				if tempMaxOrMin<soldier.position[pro] then
					tempMaxOrMin=soldier.position[pro]
				end
			else
				if tempMaxOrMin==-100 then tempMaxOrMin=soldier.position[pro] end
				if tempMaxOrMin>soldier.position[pro] then
					tempMaxOrMin=soldier.position[pro]
				end
			end
		end
		return tempMaxOrMin
	end

	local tempMaxX=findMaxByPro("x","<")
	local tempMinX=findMaxByPro("x",">")
	local tempMaxY=findMaxByPro("y","<")
	local tempMinY=findMaxByPro("y",">")

	endPositionX=(tempMaxX+tempMinX)/2+self.csvData.oppositeX2* xCoefficient
	endPositionY=(tempMaxY+tempMinY)/2+self.csvData.oppositeY2 + yOffset

	for index = 1, self.csvData.playCount do
		local bezier = ccBezierConfig()
		bezier.controlPoint_1 = ccp(self.skill.startPosition.x + self.csvData.oppositeX1* xCoefficient, self.skill.startPosition.y + self.csvData.oppositeY1 + yOffset)
		bezier.controlPoint_2 = ccp((self.skill.startPosition.x + endPositionX) / 2,
			(self.skill.startPosition.y + endPositionY) / 2 + 450)
		bezier.endPosition = ccp(endPositionX, endPositionY)

		-- 持续特效
		game:playMusic(bulletManager:getMusicId(self.csvData.id, "progress"))
		if bulletManager:getFrameCount(self.csvData.id, "progress") > 0 then
			local bulletSprite = bulletManager:getFrameSprite(self.csvData.id, "progress")
			bulletSprite:pos(self.skill.startPosition.x + self.csvData.oppositeX1 * xCoefficient, self.skill.startPosition.y + self.csvData.oppositeY1 + yOffset)

			local tempAni=bulletSprite:playAnimationForever(bulletManager:getAnimation(self.csvData.id, "progress"))
			bulletSprite:flipX(params.soldiers[1].camp == "right"):rotation(params.soldiers[1].camp == "right" and -60 or 60)
				:addTo(self.parentLayer["effectLayer" .. bulletManager:getZorder(self.csvData.id, "progress")]):hide()

			local time = math.abs(self.skill.startPosition.x - endPositionX) / self.csvData.speed

			local actions = {}
			local array = CCArray:create()
			array:addObject(CCBezierTo:create(time, bezier))
			array:addObject(CCRotateBy:create(time, params.soldiers[1].camp == "right" and 120 or -120))

			actions[#actions + 1] = CCDelayTime:create(self.csvData.playInterval / 1000 * (index - 1))
			actions[#actions + 1] = CCShow:create()
			actions[#actions + 1] = CCSpawn:create(array)
			--actions[#actions + 1] = CCRemoveSelf:create()
			actions[#actions + 1] = CCCallFunc:create(function()
				--self:onProgressEffectOver(params.enemy)--增加buff

				local totalHurtValue = 0
				for index, soldier in ipairs(params.soldiers) do
					self:onProgressEffectOver(soldier)

					local hurtValues = self.skill:calcHurtValue(soldier)
					if hurtValues.enemy > 0 then
						totalHurtValue = totalHurtValue + hurtValues.enemy
					end
					soldier:onEffect(hurtValues.effect)
					self.inEffectProgress = false
					soldier:beingHurt({ hurtValue = hurtValues.enemy, attacker = self.skill.owner, hurtFrom = 2 })
					if index == #params.soldiers then
						self:onEffectLastSoldier()

						-- 吸血
						self:suckHpFromHurt(totalHurtValue)
					end
					if self.skill.owner then
						self.skill.owner:beingHurt({ hurtValue = hurtValues.self, attacker = soldier })
					end

					-- 伤害表现
					self:onHurtEnemy({ enemy = soldier })	
					self.hasHurtCount = self.hasHurtCount + 1
				end

			end)

			-- 结束特效
			if  bulletManager:getFrameCount(self.csvData.id, "end") > 0 then
				actions[#actions + 1] = CCCallFunc:create(function()
					transition.removeAction(tempAni)
					bulletSprite:setRotation(0)
					bulletSprite:displayFrame(bulletManager:getFrame(self.csvData.id, "end"))
					bulletSprite:zorder(SpriteSoldier.zOrderConstants["bulletLayer" .. bulletManager:getZorder(self.csvData.id, "end")])
				end)
				actions[#actions + 1] = CCAnimate:create(bulletManager:getAnimation(self.csvData.id, "end"))
			end

			-- 伤害次数
			actions[#actions + 1] = CCCallFunc:create(function() self.hasHurtCount = self.hasHurtCount + 1 end)
			actions[#actions + 1] = CCRemoveSelf:create()

			bulletSprite:runAction(transition.sequence(actions))
		end
	end

	self:postEffect(params)
end

-- 直线全体
function SpriteBullet:onEffect10(params)
	if #params.soldiers == 0 then return end
	
	local xCoefficient = self.skill.owner.camp == "left" and 1 or -1
	local yOffset = self.skill.owner.hurtOffset

	local function findMaxByPro(pro,flag)
		local tempMaxOrMin=-1000
		for _,soldier in ipairs(params.soldiers) do
			if flag=="<" then
				if tempMaxOrMin<soldier.position[pro] then
					tempMaxOrMin=soldier.position[pro]
				end
			else
				if tempMaxOrMin==-1000 then tempMaxOrMin=soldier.position[pro] end
				if tempMaxOrMin>soldier.position[pro] then
					tempMaxOrMin=soldier.position[pro]
				end
			end
		end
		return tempMaxOrMin
	end

	local tempMaxX=findMaxByPro("x","<")
	local tempMinX=findMaxByPro("x",">")
	local tempMaxY=findMaxByPro("y","<")
	local tempMinY=findMaxByPro("y",">")

	endPositionX=(tempMaxX+tempMinX)/2+self.csvData.oppositeX2* xCoefficient
	endPositionY=(tempMaxY+tempMinY)/2+self.csvData.oppositeY2 + yOffset

	for index = 1, self.csvData.playCount do
		local bezier = ccBezierConfig()
		bezier.controlPoint_1 = ccp(self.skill.startPosition.x + self.csvData.oppositeX1* xCoefficient, self.skill.startPosition.y + self.csvData.oppositeY1 + yOffset)
		bezier.controlPoint_2 = ccp((self.skill.startPosition.x + endPositionX) / 2,
			(self.skill.startPosition.y + endPositionY) / 2 + 450)
		bezier.endPosition = ccp(endPositionX, endPositionY)

		-- 持续特效
		game:playMusic(bulletManager:getMusicId(self.csvData.id, "progress"))
		if bulletManager:getFrameCount(self.csvData.id, "progress") > 0 then
			local bulletSprite = bulletManager:getFrameSprite(self.csvData.id, "progress")
			bulletSprite:pos(self.skill.startPosition.x + self.csvData.oppositeX1 * xCoefficient, self.skill.startPosition.y + self.csvData.oppositeY1 + yOffset)

			local tempAni=bulletSprite:playAnimationForever(bulletManager:getAnimation(self.csvData.id, "progress"))
			bulletSprite:flipX(params.soldiers[1].camp == "right"):rotation(params.soldiers[1].camp == "right" and 0 or 0)
				:addTo(self.parentLayer["effectLayer" .. bulletManager:getZorder(self.csvData.id, "progress")]):hide()

			local time = math.abs(self.skill.startPosition.x - endPositionX) / self.csvData.speed

			local actions = {}
			-- local array = CCArray:create()
			-- array:addObject(CCBezierTo:create(time, bezier))
			-- array:addObject(CCRotateBy:create(time, params.soldiers[1].camp == "right" and 120 or -120))

			actions[#actions + 1] = CCDelayTime:create(self.csvData.playInterval / 1000 * (index - 1))
			actions[#actions + 1] = CCShow:create()
			actions[#actions + 1]= CCMoveTo:create(time,ccp(endPositionX,endPositionY))
			--actions[#actions + 1] = CCSpawn:create(array)
			actions[#actions + 1] = CCCallFunc:create(function()
				--self:onProgressEffectOver(params.enemy)--增加buff

				local totalHurtValue = 0
				for index, soldier in ipairs(params.soldiers) do
					self:onProgressEffectOver(soldier)

					local hurtValues = self.skill:calcHurtValue(soldier)
					if hurtValues.enemy > 0 then
						totalHurtValue = totalHurtValue + hurtValues.enemy
					end
					soldier:onEffect(hurtValues.effect)
					self.inEffectProgress = false
					soldier:beingHurt({ hurtValue = hurtValues.enemy, attacker = self.skill.owner, hurtFrom = 2 })
					if index == #params.soldiers then
						self:onEffectLastSoldier()
						-- 吸血
						self:suckHpFromHurt(totalHurtValue)
					end
					if self.skill.owner then
						self.skill.owner:beingHurt({ hurtValue = hurtValues.self, attacker = soldier })
					end

					-- 伤害表现
					self:onHurtEnemy({ enemy = soldier })	
					self.hasHurtCount = self.hasHurtCount + 1
				end

			end)

			-- 结束特效
			if  bulletManager:getFrameCount(self.csvData.id, "end") > 0 then
				actions[#actions + 1] = CCCallFunc:create(function()
					transition.removeAction(tempAni)
					bulletSprite:setRotation(0)
					bulletSprite:displayFrame(bulletManager:getFrame(self.csvData.id, "end"))
					bulletSprite:zorder(SpriteSoldier.zOrderConstants["bulletLayer" .. bulletManager:getZorder(self.csvData.id, "end")])
				end)
				actions[#actions + 1] = CCAnimate:create(bulletManager:getAnimation(self.csvData.id, "end"))
			end

			-- 伤害次数
			actions[#actions + 1] = CCCallFunc:create(function() self.hasHurtCount = self.hasHurtCount + 1 end)
			actions[#actions + 1] = CCRemoveSelf:create()

			bulletSprite:runAction(transition.sequence(actions))
		end
	end

	self:postEffect(params)
end

-- 子弹传递
function SpriteBullet:onEffect11(params)
	local targets = params.soldiers
	table.sort(targets, function(a, b) return a.displayNode:getPositionX() < b.displayNode:getPositionX() end)
	local totalHurtValue = 0

	local i = 1
	local enemy = targets[i]
	local hurtValues = self.skill:calcHurtValue(enemy)
	totalHurtValue = totalHurtValue + hurtValues.enemy

	local yOffset = self.skill.owner.hurtOffset
	local xCoefficient = self.skill.owner.camp == "left" and 1 or -1

	local actions = {}

	-- 持续特效
	game:playMusic(bulletManager:getMusicId(self.csvData.id, "progress"))
	if bulletManager:getFrameCount(self.csvData.id, "progress") <= 0 then return end

	local bulletSprite = bulletManager:getFrameSprite(self.csvData.id, "progress")

	local function lastEvent()
		self:onEffectLastSoldier()

		self.inEffectProgress = false
		-- 吸血
		self:suckHpFromHurt(totalHurtValue)
	end

	local function getDistanceBetweenAB(a,b)
		return math.sqrt( (b.x-a.x)*(b.x-a.x) + (b.y-a.y)*(b.y-a.y))
	end

	local onebyone
	onebyone = function (soldierA, soldierB)
		local hurtValues = self.skill:calcHurtValue(soldierB)
		totalHurtValue = totalHurtValue + hurtValues.enemy
		local angle = ccp(soldierB.position.x - soldierA.position.x, soldierB.position.y - soldierA.position.y):getAngle()
		angle = (self.skill.owner.camp == "left") and (angle / math.pi * -180) or ((angle / math.pi * -180) - 180)
		bulletSprite:rotation(angle):flipX(self.skill.owner.camp == "left")
		local time = getDistanceBetweenAB(soldierB.position, soldierA.position) / self.csvData.speed
		local actions = {}
		actions[#actions + 1] = CCMoveTo:create(time, ccp(soldierB.position.x, soldierB.position.y + yOffset))
		actions[#actions + 1] = CCCallFunc:create(function() 
			self:onProgressEffectOver(soldierB)
			
			soldierB:onEffect(hurtValues.effect)
			soldierB:beingHurt({ hurtValue = hurtValues.enemy, attacker = self.skill.owner, hurtFrom = 2 })
			self:onHurtEnemy({ enemy = soldierB })
			if self.skill.owner then
				self.skill.owner:beingHurt({ hurtValue = hurtValues.self, attacker = soldierB })
			end

			self.hasHurtCount = self.hasHurtCount + 1

			i = i + 1
			if i <= #targets then
				local newEnemy = targets[i]
				onebyone(soldierB, newEnemy)
			else
				lastEvent()
			end
		end)
		if i == #targets then
			actions[#actions + 1] = CCRemoveSelf:create()
		end
		bulletSprite:runAction(transition.sequence(actions))
	end

	local angle = ccp(enemy.position.x - self.skill.owner.position.x, enemy.position.y - self.skill.owner.position.y):getAngle()
	angle = (self.skill.owner.camp == "left") and (angle / math.pi * -180) or ((angle / math.pi * -180) - 180)

	bulletSprite:pos(self.skill.startPosition.x + self.csvData.oppositeX1 * xCoefficient, self.skill.startPosition.y + self.csvData.oppositeY1 + yOffset)
		:rotation(angle):flipX(self.skill.owner.camp == "left")
	bulletSprite:playAnimationForever(bulletManager:getAnimation(self.csvData.id, "progress"))
	bulletSprite:addTo(self.parentLayer["effectLayer" .. bulletManager:getZorder(self.csvData.id, "progress")])

	local time =  getDistanceBetweenAB(self.skill.startPosition, enemy.position) / self.csvData.speed
	actions[#actions + 1] = CCMoveTo:create(time, ccp(enemy.position.x, enemy.position.y + yOffset))
	actions[#actions + 1] = CCCallFunc:create(function() 
		self:onProgressEffectOver(enemy)
		
		enemy:onEffect(hurtValues.effect)
		enemy:beingHurt({ hurtValue = hurtValues.enemy, attacker = self.skill.owner, hurtFrom = 2 })
		self:onHurtEnemy({ enemy = enemy })
		if self.skill.owner then
			self.skill.owner:beingHurt({ hurtValue = hurtValues.self, attacker = enemy })
		end

		self.hasHurtCount = self.hasHurtCount + 1

		i = i + 1
		if i <= #targets then
			local newEnemy = targets[i]
			onebyone(enemy, newEnemy)
		else
			lastEvent()
		end
		
	end)
	if i == #targets then
		actions[#actions + 1] = CCRemoveSelf:create()
	end
	bulletSprite:runAction(transition.sequence(actions))

	self:postEffect(params)
end

function SpriteBullet:postEffect(params)
	-- 如果子弹有屏震效果, 产生屏震
	if self.csvData.screenShake == 1 then
		display.getRunningScene():runAction(transition.sequence({
			CCDelayTime:create(self.csvData.shakeDelay / 1000),
			CCCallFunc:create(function() uihelper.shake({ x = 0, y = 3, count = 20 }) end)			
		}))
	end

	-- 打断
	if self.csvData.breakAttack == 1 then
		if params.enemy then
			if params.enemy:getState() == "attack" then
				params.enemy:doEvent("ToIdle")
			end
		end

		if params.soldiers then
			for index, enemy in ipairs(params.soldiers) do
				if enemy:getState() == "attack" then
					enemy:doEvent("ToIdle")
				end
			end
		end
	end
end

function SpriteBullet:onHurtEnemy(params)
	-- 到达敌人时，敌人可能已经挂
	--if params.enemy:getState() == "dead" then return end
	if params.enemy.displayNode == nil then return end 

	local hurtSprite = bulletManager:getFrameSprite(self.csvData.id, "hurt")
	hurtSprite:flipX(true)
	local randomX, randomY = randomInt(-9, 9), randomInt(-9, 9)
	hurtSprite:pos(randomX + params.enemy.nodeSize.width / 2, params.enemy.hurtOffset + randomY)
		:addTo(params.enemy.displayNode, 100)

	game:playMusic(bulletManager:getMusicId(self.csvData.id, "hurt"))
	hurtSprite:playAnimationOnce(bulletManager:getAnimation(self.csvData.id, "hurt"), true,
		function ()
			-- 打直接的不存在多次攻击，否则会bug
			if self.skill.csvData.effectRangeType ~= 2 
				and self.csvData.type ~= 7 then		-- 全屏技能不在这里处理
				self:onHurtOver(params.enemy)
			end
		end)
end

function SpriteBullet:onFinished(params)
end

function SpriteBullet:onEnd(params)
end

function SpriteBullet:dispose()
end

return SpriteBullet