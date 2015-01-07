local Buff = class("Buff")

Buff.__index = function (self, key)
	local v = rawget(self, key .. "_ed")
	if v then
		return MemDecrypt(v)
	else
		return Buff[key]
	end
end

Buff.__newindex = function (self, key, value)
	if type(value) == "number" then
		rawset(self, key .. "_ed", MemEncrypt(value))
	else
		rawset(self, key, value)
	end
end

function Buff:ctor(params)
	self.primaryKey = params.primaryKey or 0

	self.id = params.buffId or 0
	self.level = params.level or 1
	self.skill = params.skill
	self.owner = params.owner		

	self.inBegining = true

	self.csvData = buffCsv:getBuffById(self.id)

	self:initAttribute()
end

function Buff:initAttribute()
	if not self.csvData then return end

	-- 技能等级修正
	self.buffValue = self.csvData.initValue + (self.level - 1) * self.csvData.valueGrowth
	self.effectKeepTime = self.csvData.initKeepTime + (self.level - 1) * self.csvData.keepTimeGrowth

	-- 阵营覆盖
	local camp = tostring(self.owner.unitData.camp)
	if self.csvData.campModifies[camp] then
		self.buffValue = self.csvData.campModifies[camp] + (self.level - 1) * self.csvData.campGrowth
	end
	-- 职业覆盖
	local profession = tostring(self.owner.unitData.profession)
	if self.csvData.professionModifies[profession] then
		self.buffValue = self.csvData.professionModifies[profession] + (self.level - 1) * self.csvData.professionGrowth
	end

	-- 加血和中毒
	if self.csvData.type == 1 or self.csvData.type == 4 then
		-- 技能等级修正
		local buffCoefficient = self.skill.csvData.buffCoefficient + (self.level - 1) * self.skill.csvData.buffCoeffGrowth
		local buffConstant = self.skill.csvData.buffConstant + (self.level - 1) * self.skill.csvData.buffConstantGrowth
		local keepTime = self.skill.csvData.keepTime

		-- 阵营覆盖
		local camp = tostring(self.owner.unitData.camp)
		if self.skill.csvData.campModifies[camp] then
			buffCoefficient = self.skill.csvData.campModifies[camp] + (self.level - 1) * self.skill.csvData.campGrowth
		end
		-- 职业覆盖
		local profession = tostring(self.owner.unitData.profession)
		if self.skill.csvData.professionModifies[profession] then
			buffCoefficient = self.skill.csvData.professionModifies[profession] + (self.level - 1) * self.skill.csvData.professionGrowth
		end

		self.buffValue = globalCsv:getFieldValue("k1") * buffCoefficient * self.skill.owner:getCurAttack() + buffConstant
		self.effectKeepTime = keepTime

		self.hurtCount = self.skill.csvData.hurtCount

		self.hasHurtCount = 0
		self.effectDetectPoint = 0
	end
	self.leftKeepTime = self.effectKeepTime
end

function Buff:beginEffect(soldier)
	local typeAttriteMap = {
		[2] = { name = "Attack", value = soldier.curAttack * self.buffValue / 100 },
		[3] = { name = "Defense", value = soldier.curDefense * self.buffValue / 100},
		[5] = { name = "Attack", value = -soldier.curAttack * self.buffValue / 100},
		[6] = { name = "Defense", value = -soldier.curDefense * self.buffValue / 100},
		[8] = { name = "Hit", value = self.buffValue },
		[9] = { name = "Miss", value = self.buffValue },
		[10] = { name = "Parry", value = self.buffValue},
		[11] = { name = "IgnoreParry", value = self.buffValue},
		[12] = { name = "Crit", value = self.buffValue},
		[13] = { name = "Tenacity", value = self.buffValue},
		[14] = { name = "CritHurt", value = self.buffValue},
		[15] = { name = "CritResist", value = self.buffValue},
	}
	-- BUFF导致属性变化
	if typeAttriteMap[self.csvData.type] then
		soldier:onChangeAttribute(typeAttriteMap[self.csvData.type])
	end
	self:onBegin(soldier)
end

-- BUFF作用
-- @return 0->结束 1->正常 2->跳出正常状态判定
function Buff:effect(soldier)
	local result = 1

	-- 持续时间结束
	if(self.effectKeepTime == 0 and not self.inProgress) 
		or (self.effectKeepTime > 0 and self.leftKeepTime <= 0) then

		self:dispose(soldier)

		-- 眩晕结束
		if self.csvData.type == 16 then
			if soldier:getState() == "dizzy" then
				soldier:doEvent("ToIdle")
			end

		-- 冰冻结束
		elseif self.csvData.type == 17 then
			if soldier:getState() == "frozen" then
				soldier.animation:resume()
				-- 恢复冰冻之前的状态
				soldier:doEvent("ToIdle")
			end
		--伤害吸收护盾
		elseif self.csvData.type == 25 then
			soldier.shieldDamage = 0
		end

		return 0
	end

	-- 加血和中毒
	if self.csvData.type == 1 or self.csvData.type == 4 then
		if self.hasHurtCount < self.hurtCount and self.effectDetectPoint <= 0 then
			result = self["effect" .. self.csvData.type](self, soldier)
			self.effectDetectPoint = self.effectKeepTime / self.hurtCount
			self.hasHurtCount = self.hasHurtCount + 1

		elseif self.hasHurtCount < self.hurtCount and self.effectDetectPoint > 0 then
			self.effectDetectPoint = self.effectDetectPoint - soldier.battle.frame
		end
	else
		-- 数值效果
		result = self["effect" .. self.csvData.type](self, soldier)
	end

	-- 加buff失败
	if result == 0 then return result end

	self:onProgress(soldier)
	self.leftKeepTime = self.leftKeepTime - soldier.battle.frame

	return result
end

-- 具体BUFF的作用

-- 增加己方武将生命值
function Buff:effect1(soldier)
	-- 检查被动技能 加血buff
	local params = {
		condition = skillPassiveCsv.TRIGGER_HP_BUFF,
		effect = skillPassiveCsv.EFFECT_HEAL_MORE,
	}
	soldier:triggerPassiveSkill(params)

	self.skill.owner:triggerPassiveSkill({condition = skillPassiveCsv.TRIGGER_SKILL_HEAL, effect = skillPassiveCsv.EFFECT_SKILL_HURT_INCRE})

	if soldier.camp == "left" and not soldier.startShow then
		soldier:triggerBeautySkill(params)
	end

	soldier:beingHurt({ hurtValue = self.buffValue * ( 1 + soldier.curSkillCureAddition) * (1 + self.skill.owner.curSkillHurtAddition)})

	return 1
end

-- 提升己方武将x%的攻击力
function Buff:effect2(soldier)
	soldier:changeAttribute({ name = "Attack", value = soldier.curAttack * self.buffValue / 100})

	return 1
end

-- 提升己方武将x%的防御
function Buff:effect3(soldier)
	soldier:changeAttribute({ name = "Defense", value = soldier.curDefense * self.buffValue / 100})

	return 1
end

-- 使敌方中毒见血
function Buff:effect4(soldier)
	if not soldier.curInvincible then
		soldier:beingHurt({ hurtValue = self.buffValue })
	else
		soldier:onEffect("invincible")
	end
	return 1
end

-- 降低敌方武将20%的攻击力
function Buff:effect5(soldier)
	soldier:changeAttribute({ name = "Attack", value = -soldier.curAttack * self.buffValue / 100})

	return 1
end

-- 降低敌方武将x%的防御
function Buff:effect6(soldier)
	soldier:changeAttribute({ name = "Defense", value = -soldier.curDefense * self.buffValue / 100})

	return 1
end

-- 解除负面状态
function Buff:effect7(soldier)
	for id, buff in pairs(soldier.buffs) do
		if buff.csvData.debuff == 1 then
			soldier.buffs[id] = nil
		end
	end

	return 1
end

-- 加命中
function Buff:effect8(soldier)
	soldier:changeAttribute({ name = "Hit", value = self.buffValue })
	return 1
end

-- 加闪避
function Buff:effect9(soldier)
	soldier:changeAttribute({ name = "Miss", value = self.buffValue })
	return 1
end

-- 加格挡
function Buff:effect10(soldier)
	soldier:changeAttribute({ name = "Parry", value = self.buffValue })
	return 1
end

-- 加破击
function Buff:effect11(soldier)
	soldier:changeAttribute({ name = "IgnoreParry", value = self.buffValue })
	return 1
end

-- 加暴击
function Buff:effect12(soldier)
	soldier:changeAttribute({ name = "Crit", value = self.buffValue })
	return 1
end

-- 加韧性
function Buff:effect13(soldier)
	soldier:changeAttribute({ name = "Tenacity", value = self.buffValue })

	return 1
end

-- 加暴伤
function Buff:effect14(soldier)
	soldier:changeAttribute({ name = "CritHurt", value = self.buffValue })
	return 1
end

-- 加抵抗
function Buff:effect15(soldier)
	soldier:changeAttribute({ name = "Resist", value = self.buffValue })
	return 1
end

-- 眩晕
function Buff:effect16(soldier)
	if soldier:getState() == "dizzy" then
		return 2
	end

	if soldier:canDoEvent("ToDizzy") and soldier:getState() ~= "dead" then
		soldier:doEvent("ToDizzy")
		return 2
	end

	return 1
end

-- 冰冻
function Buff:effect17(soldier)
	if soldier:getState() == "frozen" then
		return 2
	end

	if soldier:canDoEvent("Freeze") then
		soldier:doEvent("Freeze")
		return 2
	end

	return 1
end

-- 缓速
function Buff:effect18(soldier)
	soldier.slowdown = true
	return 1
end

-- 无敌
function Buff:effect19(soldier)
	soldier.curInvincible = true
	return 1
end

-- 反伤（反弹）
function Buff:effect20(soldier)
	soldier.curRebound = true
	return 1
end

-- 伤害吸收
function Buff:effect21(soldier)
	soldier.curSuckDamage = true
	return 1
end

-- 沉默
function Buff:effect22(soldier)
	soldier.curSilence = true
	return 1
end

-- 增加攻速
function Buff:effect23(soldier)
	soldier:changeAttribute({ name = "AttackSpeedup", value = self.buffValue / 100 })
	return 1
end

-- 伤害吸收护盾
function Buff:effect25(soldier)
	if not self.shield then
		soldier.shieldDamage = self.buffValue
		self.shield = true
	end
	if soldier.shieldDamage == 0 then
		return 0
	end
	return 1
end

-- 死亡后复活
function Buff:effect26(soldier)
	-- do nothing
end

-- 深度睡眠
function Buff:effect27(soldier)
	if soldier:getState() == "deepSleep" then
		return 2
	end

	if soldier:canDoEvent("ToDeepSleep") and soldier:getState() ~= "dead" then
		soldier:doEvent("ToDeepSleep")
		return 2
	end

	return 1
end

function Buff:onBegin(soldier)
end

function Buff:onProgress(soldier)
end

function Buff:dispose()
end

return Buff