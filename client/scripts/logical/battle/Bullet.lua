local Bullet = class("Bullet")

function Bullet:ctor(params)
	self.id = params.id 	-- 子弹ID
	self.csvData = bulletCsv:getBulletById(params.id)

	self.usage = params.usage	-- 子弹用途(普攻---1, 技能---2, buff---3)
	self.hasHurtCount = 0
	self.hurtLimit = params.skill and params.skill.csvData.hurtCount or 1

	self.skill = params.skill	-- 子弹所属技能
	if self.skill then
		self.hasEffectSoldiers = {}	-- 子弹已经作用过的武将, 直线分型
		self.curPosition = {x = self.skill.startPosition.x, y = self.skill.startPosition.y}	-- 记录横向子弹的轨迹

		self.lastTime = os.clock() * 1000 	-- 子弹上一次作用时间

		-- 技能等级修正持续时间
		local skillLevel = self.skill.level
		local keepTime = self.skill.csvData.keepTime
		self.effectInterval = keepTime / self.hurtLimit
		self.inEffectProgress = false
	end
end

-- 子弹持续特效播完后
function Bullet:onProgressEffectOver(target)
	if self.skill then
		self.skill:addBuffs(target)
		--self.skill:attackAgain(target)
	end
end

function Bullet:onEffectLastSoldier()
	if self.skill then
		self.skill:onEffectLastSoldier()
	end
end

function Bullet:onHurtOver(target)
	if self.skill then
		self.skill:attackAgain(target)
	end
end

function Bullet:onHurtOverGlobal(targets)
	if self.skill then
		self.skill:attackAgainGlobal(targets)
	end
end

-- 对外统一接口
function Bullet:effect(targets)
	local result = self["effect" .. self.csvData.type](self, targets)
	return result
end

-- 瞬发
function Bullet:effect1(targets)
	if not targets then 
		targets = self.skill:getEffectObjects()
	end	

	if self.hasHurtCount >= self.hurtLimit then
		return true 
	end

	local totalHurtValue = 0
	for index, soldier in ipairs(targets) do
		local finalValues = self.skill:calcHurtValue(soldier)

		if finalValues.enemy > 0 then
			totalHurtValue = totalHurtValue + finalValues.enemy
		end

		-- 持续特效作用到自己身上
		self:onEffect1({ enemy = soldier, hurtValues = finalValues, 
			last = (index == #targets), totalHurtValue = totalHurtValue })
	end

	return false
end

-- 单体攻击
function Bullet:effect2(targets)
	if self.hasHurtCount >= self.hurtLimit then
		return true 
	end

	-- 检查持续时间
	if self.inEffectProgress then return false end
	self.inEffectProgress = true
	self:onEffect2({ soldiers = targets })

	return false
end

-- 直线
function Bullet:effect3(targets)
	if self.hasHurtCount >= self.hurtLimit then return true end

	-- x轴直线飞行
	if self.skill.csvData.effectRangeType == 2 then
		-- 子弹出现
		if self.curPosition.x == self.skill.startPosition.x then
			-- 象征性的移动一个像素
			if self.skill.camp == "left" then
				self.curPosition.x = self.curPosition.x + 1
			else
				self.curPosition.x = self.curPosition.x - 1
			end
			self:onEffect3({ x = self.curPosition.x, y = self.curPosition.y })

			return false
		end

		local rangeSoldiers = self.skill.battleField:getPointObjects(self.curPosition)
		local soldiers = self.skill:filterEffectObjects(rangeSoldiers)
		-- 如果没有碰撞到武将, 或者已经伤害过一次, 继续前行
		local soldier = soldiers[1] 	-- 横向攻击同一时间只可能有一个目标

		local moveSpeed = self.csvData.speed / 1000
		local moveDistance = moveSpeed * self.skill.battle.frame
		-- 同行
		if self.skill.camp == "left" then
			self.curPosition.x = self.curPosition.x + moveDistance
		else
			self.curPosition.x = self.curPosition.x - moveDistance
		end

		-- 是否在技能的攻击对象中
		local containHero = false
		for _, enemy in ipairs(targets) do
			if soldier and soldier:getAnchKey() == enemy:getAnchKey() then
				containHero = true
				break
			end
		end

		if not containHero  or self.hasEffectSoldiers[soldier:getAnchKey()] or soldier == self.skill.owner then
			local result = self:onEffect3({x = self.curPosition.x, y = self.curPosition.y, time = self.skill.battle.frame})
			return result
		end

		local finalValues = self.skill:calcHurtValue(soldier)
		
		-- 对武将造成伤害
		self:onHurtEnemy({ enemy = soldier})
		soldier:beingHurt({ hurtValue = finalValues.enemy, attacker = self.skill.owner, hurtFrom = 2 })
		soldier:onEffect(finalValues.effect)

		-- 释放者有可能已经被干掉
		if self.skill.owner then
			-- 吸血
			local growth = self.skill.csvData.suckHpGrowth or 0
			local suckHpValue = finalValues.enemy * (self.skill.csvData.suckHpPercent + (self.skill.level - 1) * growth) / 100
			self.skill.owner:beingHurt({ hurtValue = -suckHpValue })

			self.skill.owner:beingHurt({ hurtValue = finalValues.self, attacker = soldier })
		end

		-- 产生BUFF作用
		self.skill:addBuffs(soldier)

		self.hasEffectSoldiers[soldier:getAnchKey()] = true
		local result = self:onEffect3({x = self.curPosition.x, y = self.curPosition.y, time = self.skill.battle.frame})
		return result
	else
		if #targets == 0 then return true end

		if self.inEffectProgress then return false end
		self.inEffectProgress = true

		local totalHurtValue = 0
		for index, enemy in ipairs(targets) do
			local finalValues = self.skill:calcHurtValue(enemy)

			totalHurtValue = totalHurtValue + finalValues.enemy
			self:onEffect3({ enemy = enemy, hurtValues = finalValues, 
				last = (index == #targets), totalHurtValue = totalHurtValue })
		end
	end
end

-- 抛物线
function Bullet:effect4(targets)
	if self.hasHurtCount >= self.hurtLimit then
		return true 
	end

	-- 检查持续时间
	if self.inEffectProgress then return false end
	self.inEffectProgress = true

	local totalHurtValue = 0
	for index, enemy in ipairs(targets) do
		local finalValues = self.skill:calcHurtValue(enemy)

		totalHurtValue = totalHurtValue + finalValues.enemy
		self:onEffect4({ enemy = enemy, hurtValues = finalValues, 
			last = (index == #targets), totalHurtValue = totalHurtValue })
	end
end

-- 竖向
function Bullet:effect5(targets)
	if self.hasHurtCount >= self.hurtLimit then
		return true 
	end

	-- 检查持续时间
	if self.inEffectProgress then return false end

	self.inEffectProgress = true

	self:onEffect5({ soldiers = targets })

	return false
end

-- 横向飞行攻击纵列
function Bullet:effect6(targets)
	if self.hasHurtCount >= self.hurtLimit then
		return true
	end

	-- 检查持续时间
	if self.inEffectProgress then return false end
	self.inEffectProgress = true

	self:onEffect6({ soldiers = targets })

	return false
end

-- 全体攻击
function Bullet:effect7(targets)
	if self.hasHurtCount >= self.hurtLimit then
		return true
	end

	-- 检查持续时间
	if self.inEffectProgress then return false end
	self.inEffectProgress = true

	self:onEffect7({ soldiers = targets })

	return false
end

function Bullet:effect8(targets)
	if self.hasHurtCount >= self.hurtLimit then
		return true
	end

	-- 检查持续时间
	if self.inEffectProgress then return false end
	self.inEffectProgress = true

	self:onEffect8({ soldiers = targets })

	return false
end

-- 抛物线
function Bullet:effect9(targets)
	if self.hasHurtCount >= self.hurtLimit then
		return true 
	end

	-- 检查持续时间
	if self.inEffectProgress then return false end
	self.inEffectProgress = true

	self:onEffect9({ soldiers = targets })
	return false
end

-- 直线全体
function Bullet:effect10(targets)
	if self.hasHurtCount >= self.hurtLimit then
		return true 
	end

	-- 检查持续时间
	if self.inEffectProgress then return false end
	self.inEffectProgress = true

	self:onEffect10({ soldiers = targets })
	return false
end

-- 子弹传递
function Bullet:effect11(targets)
	if self.hasHurtCount >= self.hurtLimit then
		return true 
	end

	if #targets == 0 then return true end

	if self.inEffectProgress then return false end
	self.inEffectProgress = true

	self:onEffect11({ soldiers = targets })
end

-- 子类实现
function Bullet:onEffect0(params)
	
end

function Bullet:onEffect1(params)
	
end

function Bullet:onEffect2(params)
	
end

function Bullet:onEffect3(params)
end

function Bullet:onEffect4(params)
	
end

function Bullet:onEffect5(params)
	
end

function Bullet:onEffect6(params)
	
end

function Bullet:onEffect7(params)
	
end

function Bullet:onEffect8(params)

end

function Bullet:onEffect9(params)

end

function Bullet:onEffect10(params)

end

function Bullet:onFinished(params)
	
end

function Bullet:onHurtEnemy(params)
	
end

function Bullet:onEnd(params)
	
end

function Bullet:dispose()
end

return Bullet