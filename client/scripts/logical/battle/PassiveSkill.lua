local PassiveSkill = class("PassiveSkill")

PassiveSkill.__index = function (self, key)
	local v = rawget(self, key .. "_ed")
	if v then
		return MemDecrypt(v)
	else
		return PassiveSkill[key]
	end
end

PassiveSkill.__newindex = function (self, key, value)
	if type(value) == "number" then
		rawset(self, key .. "_ed", MemEncrypt(value))
	else
		rawset(self, key, value)
	end
end

function PassiveSkill:ctor(params)
	self.owner = params.owner	-- 技能所有者
	-- self.battle = self.owner.battle 	-- 战斗
	-- self.battleField = params.battleField	-- 战场
	-- self.camp = self.owner.camp
	-- self.startPosition = self.owner.position

	-- 技能自身属性
	self.id = params.id or 0
	self.csvData = skillPassiveCsv:getPassiveSkillById(self.id)
	-- 技能等级
	local skillLevel = self.owner.skillLevels[tostring(self.id + 10000)] or 1
	local growth = {}
	for k,v in pairs(self.csvData.effectGrowth) do
		growth[tonum(k)] = tonum(v) * (skillLevel - 1)
	end

	-- 效果类型ID=数值
	self.effectValue = {}
	for k, v in pairs(self.csvData.effectMap) do
		self.effectValue[tonum(k)] = tonum(v) + (growth[tonum(k)] or 0)
	end

	self.reflections = {
		bullet = params.bulletDef or "logical.battle.Bullet",
	}

	if self.csvData.bulletId > 0 then
		self.bullet = require(self.reflections["bullet"]).new({ id = self.csvData.bulletId, passiveSkill = self, usage = 4 })
	end
end

-- 1 提升百分比攻击
function PassiveSkill:effect1(params)
	local isTemp = params.temp or false
	local incre = 0
	if isTemp then
		incre = self.owner.curAttack * self.effectValue[params.effect] / 100
		self.owner.curAttack = self.owner.curAttack + incre
	else
		incre = self.owner.attack * self.effectValue[params.effect]  / 100
		self.owner.attack = self.owner.attack + incre
		self.owner.curAttack = self.owner.attack
	end

	self:onTextEffect({effect = "attr_Attack", value = incre})
end

-- 2 提升百分比防御
function PassiveSkill:effect2(params)
	local isTemp = params.temp or false
	local incre = 0
	if isTemp then
		incre = self.owner.curDefense * self.effectValue[params.effect]  / 100
		self.owner.curDefense = self.owner.curDefense + incre
	else
		incre = self.owner.defense * self.effectValue[params.effect]  / 100
		self.owner.defense = self.owner.defense + incre
		self.owner.curDefense = self.owner.defense
	end

	self:onTextEffect({effect = "attr_Defense", value = incre})
end

-- 3 提升百分比生命
function PassiveSkill:effect3(params)
	local maxHp = self.owner.maxHp
	self.owner.maxHp = self.owner.maxHp * ( 100 + self.effectValue[params.effect]  ) / 100
	self.owner.hp = self.owner.hp + (self.owner.maxHp - maxHp)
	local incre = self.owner.maxHp - maxHp

	self:onTextEffect({effect = "attr_HP", value = incre})
end

-- 4 提升暴击值
function PassiveSkill:effect4(params)
	self.owner.crit = self.owner.crit + self.effectValue[params.effect] 
	self.owner.curCrit = self.owner.crit

	self:onTextEffect({effect = "attr_Crit", value = self.effectValue[params.effect] })
end

-- 5 提升韧性值
function PassiveSkill:effect5(params)
	self.owner.tenacity = self.owner.tenacity + self.effectValue[params.effect] 
	self.owner.curTenacity = self.owner.tenacity

	self:onTextEffect({effect = "attr_Tenacity", value = self.effectValue[params.effect] })
end

-- 6 提升爆伤
function PassiveSkill:effect6(params)
	self.owner.critHurt = self.owner.critHurt + self.effectValue[params.effect] 
	self.owner.curCritHurt = self.owner.critHurt

	self:onTextEffect({effect = "attr_CritHurt", value = self.effectValue[params.effect] })
end

-- 7 提升闪避
function PassiveSkill:effect7(params)
	local isTemp = params.temp or false
	if isTemp then
		if not self.owner.buqu then
			self.owner.miss = self.owner.miss + self.effectValue[params.effect] 
			params.returnValue = true
			self:onTextEffect({effect = "buqu"})
			self:onTextEffect({effect = "attr_Miss", value = self.effectValue[params.effect] })
		end
	else
		self.owner.miss = self.owner.miss + self.effectValue[params.effect] 
		self.owner.curMiss = self.owner.miss
		self:onTextEffect({effect = "attr_Miss", value = self.effectValue[params.effect] })
	end
end

-- 8 提升命中
function PassiveSkill:effect8(params)
	self.owner.hit = self.owner.hit + self.effectValue[params.effect] 
	self.owner.curHit = self.owner.hit

	self:onTextEffect({effect = "attr_Hit", value = self.effectValue[params.effect] })
end

-- 9 提升格挡
function PassiveSkill:effect9(params)
	self.owner.parry = self.owner.parry + self.effectValue[params.effect] 
	self.owner.curParry = self.owner.parry

	self:onTextEffect({effect = "attr_Parry", value = self.effectValue[params.effect] })
end

-- 10 提升破击
function PassiveSkill:effect10(params)
	self.owner.ignoreParry = self.owner.ignoreParry + self.effectValue[params.effect] 
	self.owner.curIgnoreParry = self.owner.ignoreParry

	self:onTextEffect({effect = "attr_IgnoreParry", value = self.effectValue[params.effect] })
end

-- 11 提升抵抗
function PassiveSkill:effect11(params)
	self.owner.resist = self.owner.resist + self.effectValue[params.effect] 
	self.owner.curResist = self.owner.resist

	self:onTextEffect({effect = "attr_CritResist", value = self.effectValue[params.effect] })
end

-- 12 普通伤害减免
function PassiveSkill:effect12(params)
	self.owner.curHurtDerate = self.effectValue[params.effect]  / 100
end

-- 13 免疫
function PassiveSkill:effect13(params)
	self.owner:onEffect("mianyi")
	params.returnValue = true
end

-- 14 士气消耗降低
function PassiveSkill:effect14(params)
	params.returnValue = self.effectValue[params.effect] 
end

-- 15 被治疗加成
function PassiveSkill:effect15(params)
	self.owner.curSkillCureAddition =  self.owner.curSkillCureAddition + self.effectValue[params.effect] / 100
end

-- 16 触发技能
function PassiveSkill:effect16(params)
	params.returnValue = self.effectValue[params.effect]
end

-- 17 普攻伤害加成
function PassiveSkill:effect17(params)
	self.owner.curHurtAddition = self.effectValue[params.effect] / 100
end

-- 18 触发两次伤害
function PassiveSkill:effect18(params)

end

-- 19 怒气回复速度提升
function PassiveSkill:effect19(params)
	local campInstance = self.owner.battleField[self.owner.camp  .. "Camp"]
	campInstance.angryCD = campInstance.angryCD - campInstance.origAngryCD * self.effectValue[params.effect] / 100
	if campInstance.angryCD < 0 then campInstance.angryCD = 0 end
end

-- 20 己方全体治疗
function PassiveSkill:effect20(params)
	local recover = params.hurtValue * self.effectValue[params.effect] / 100

	self.owner.displayNode:runAction(transition.sequence({
		CCDelayTime:create(self.owner.battle.frame / 1000),
		CCCallFunc:create(function()
				local soldiers = self.owner.battleField:getCampObjects(self.owner.camp)
				for _, soldier in ipairs(soldiers) do
					soldier:beingHurt({hurtValue = -recover})
				end
			end),
	}))
end

-- 21 概率怒气值+0.5
function PassiveSkill:effect21(params)
	local rate = self.effectValue[params.effect] * 100

	if randomInt(0, 10000) <= rate then
		local campInstance = self.owner.battleField[self.owner.camp  .. "Camp"]
		campInstance:addAngryUnit(0.5)

		self:onTextEffect({effect = "anger", value = 0.5})
	end
end

-- 22 杀死对手
function PassiveSkill:effect22(params)
	local rate = self.effectValue[params.effect] * 100

	if randomInt(0, 10000) <= rate then
		params.returnValue = true
	end
end

-- 23 对随机一个敌方角色造成自身X%最大生命的伤害
function PassiveSkill:effect23(params)
	-- local hurt = self.owner.maxHp * self.effectValue / 100

	-- local soldiers = self.owner.battleField:getCampObjects(self.owner.camp == "right" and "left" or "right")
	-- local i = randomInt(1, #soldiers)
	-- soldiers[i]:beingHurt({hurtValue = hurt})

	-- 特殊处理
	self.owner.dreamKill = true
	self.owner.dreamKill_skill = self
	self.dreamKill_hurt = self.effectValue[params.effect]
end

-- 24 机率触发反弹
function PassiveSkill:effect24(params)
	local rate = self.effectValue[params.effect] * 100
	if randomInt(0, 10000) <= rate then
		params.returnValue = true
	end
end

-- 25 回复百分比伤害值的血量
function PassiveSkill:effect25(params)
	self.owner.hp = self.owner.hp + params.enemyHurtValue * self.effectValue[params.effect] / 100

	self:onTextEffect({effect = "hurtAbsorb", value = params.enemyHurtValue * self.effectValue[params.effect] / 100})
end

-- 26 提升攻速
function PassiveSkill:effect26(params)
	self.owner.attackSpeedup = self.owner.attackSpeedup + self.effectValue[params.effect] / 100
	local incre = self.owner.curAttackSpeed * self.effectValue[params.effect] / 100

	self:onTextEffect({effect = "speedup", value = incre})
end

-- 27 技能伤害加成
function PassiveSkill:effect27(params)
	self.owner.curSkillHurtAddition = self.effectValue[params.effect] / 100
end

-- 28 产生吸血效果，效果值为伤害值*吸血系数，当伤害<=0时，不吸血
function PassiveSkill:effect28(params)
	local hp = params.hurtValue * self.effectValue[params.effect] / 100

	self.owner.displayNode:runAction(transition.sequence({
		CCDelayTime:create(self.owner.battle.frame / 1000),
		CCCallFunc:create(function()
				self.owner:beingHurt({hurtValue = -hp})
			end),
	}))
end

-- 29 弥留一段时间，该时间内可攻击可被攻击，不死亡
function PassiveSkill:effect29(params)
	if not self.bedying then
		self.owner.bedyingTime = self.effectValue[params.effect] * 1000   -- ms
		self.bedying = true
		params.returnValue = true
		self.owner:playAnimation("attack4")
	end
end

-- 30 复活，保留生命上限%d%%
function PassiveSkill:effect30(params)
	if not self.resurgence then
		self.resurgence = true
		params.returnValue = true
		self.owner.hp = self.owner.maxHp * self.effectValue[params.effect] / 100
		self.owner:refreshHpProgress()
	end
end

-- 31 回复百分比自身血量上限的生命
function PassiveSkill:effect31(params)
	local incre = self.owner.maxHp * self.effectValue[params.effect] / 100
	self.owner.hp = self.owner.hp + incre
	if self.owner.hp > self.owner.maxHp then
		self.owner.hp = self.owner.maxHp
	end

	self:onTextEffect({effect = "attr_HP", value = incre, fontColor = "green"})
end

-- 32 增加技能攻击次数
function PassiveSkill:effect32(params)
	local rate = self.effectValue[params.effect] * 100
	
	if randomInt(0, 10000) <= rate then
		params.returnValue = true
	end
end

-- 33 偷取对方增益buff
function PassiveSkill:effect33(params)
	local rate = self.effectValue[params.effect] * 100
	
	if randomInt(0, 10000) <= rate then
		params.returnValue = true
	end
end

-- 34 添加状态buff成功率
function PassiveSkill:effect34(params)
	self.owner.addBuffProbability = self.effectValue[params.effect]
end

-- 35 增加所在方怒气值
function PassiveSkill:effect35(params)
	local addAngryValue = tonum(self.effectValue[params.effect])
	local campInstance = self.owner.battleField[self.owner.camp  .. "Camp"]
	campInstance:addAngryUnit(addAngryValue/100)

	self:onTextEffect({effect = "anger", value = addAngryValue})
end

-- 36 百分比反弹护盾所减免的伤害
function PassiveSkill:effect36(params)
	params.returnValue = params.hurtValue * tonum(self.effectValue[params.effect])/100
end

function PassiveSkill:handleSkill(params)

	local function doit()
		self["effect" .. params.effect](self, params)
		self:beginEffect()
	end

	if self.csvData.triggerMap[tostring(params.condition)] and
		self.csvData.effectMap[tostring(params.effect)] then
		if params.triggerEvent and type(params.triggerEvent) == "function" then
			if params.triggerEvent(self.csvData.triggerMap[tostring(params.condition)]) then
				doit()
			end
		else
			doit()
		end
	end
end

function PassiveSkill:isActiveSkill()
	if self.csvData.triggerMap[tostring(skillPassiveCsv.TRIGGER_SKILL)] then
		return true, tonum(self.csvData.effectMap[tostring(skillPassiveCsv.EFFECT_SKILL)])
	end
	return false
end

function PassiveSkill:isDeathTrigger()
	if self.csvData.triggerMap[tostring(skillPassiveCsv.TRIGGER_DEAD)] then
		return true
	end
	return false
end

function PassiveSkill:beginEffect(params)

	--self:onBegin()
end

function PassiveSkill:effect(params)
	if not self.bullet then return end

	--self:onProgress(params)
end

function PassiveSkill:onBegin(params)
end

function PassiveSkill:onProgress(params)
end

function PassiveSkill:dispose()
end

return PassiveSkill