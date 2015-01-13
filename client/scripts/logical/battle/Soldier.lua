local Hero = require("datamodel.Hero")

local Soldier = class("Soldier")

Soldier.__index = function (self, key)
	local v = rawget(self, key .. "_ed")
	if v then
		return MemDecrypt(v)
	else
		return Soldier[key]
	end
end

Soldier.__newindex = function (self, key, value)
	if type(value) == "number" then
		rawset(self, key .. "_ed", MemEncrypt(value))
	else
		rawset(self, key, value)
	end
end

function Soldier:ctor(params)
	self.battle = params.battle  			--nil! set in BattleField:init
	self.battleField = params.battleField

	self.position = { x = 0 , y = 0 } -- 真实坐标
	self.anchPoint = { x = params.anchPointX or 0, y = params.anchPointY or 0,}	--	相对坐标, 武将的锚点(1, 1)
	self.camp = params.camp or "left"	-- 阵营
	self.beBoss = params.beBoss or false	-- 敌方阵营boss
	self.assistHero = params.assistHero or false 	-- 助战武将
	self.startShow = params.startShow or false

	-- 武将基本属性
	self.id = params.id or 0
	self.level = params.level or 0
	self.type = params.type or 0
	self.evolutionCount = (params.evolutionCount or 0) % 100
	self.showEvolution = not params.evolutionCount or params.evolutionCount < 100 
	self.wakeLevel = params.wakeLevel or 0
	self.star = params.star or 0

	self.unitData = unitCsv:getUnitByType(self.type)
	self.heroProfession = heroProfessionCsv:getDataByProfession(self.unitData.profession)
	
	self.name = params.name or self.unitData.name

	-- 武将技能
	if params.skillLevelJson then
		self.skillLevels = json.decode(params.skillLevelJson)
	elseif params.skillLevels then
		self.skillLevels = params.skillLevels
	end
	self.skillLevels = self.skillLevels or {}
	self.skillOrder = params.skillOrder
	-- pve敌人
	self.skillable = params.skillable or false
	self.startSkillCdTime = params.startSkillCdTime or 0
	self.skillCdTime = params.skillCdTime or 0
	self.skillWeight = params.skillWeight or 0

	-- 状态变量
	self.hasDead = false
	self.hasPaused = false
	self.canPause = true
	self.skillProgress = 0
	self.waitFrame = math.huge

	-- 武将的一些战斗属性值
	self.hp = params.hp or 0
	self.maxHp = self.hp 	-- 最大血量

	self.attack = params.attack or 0
	self.curAttack = self.attack 	-- 当前攻击力

	self.defense = params.defense or 0
	self.curDefense = self.defense

	self.attackRange = params.attackRange or 0	--攻击范围

	self.attackSpeed = params.attackSpeed or 0	--攻击间隔时间
	self.curAttackSpeed = self.attackSpeed 	-- 当前攻击间隔时间
	self.attackDetectPoint = 0	-- 检测点
	if params.atkSpeedFactor then
		self.atkSpeedFactor = self.unitData.atkSpeedFactor * (params.atkSpeedFactor - self.unitData.atkSpeedFactor + 100) / 100
	else
		self.atkSpeedFactor = self.unitData.atkSpeedFactor
	end

	self.moveSpeed = params.moveSpeed or 0		--原始移动速度
	self.curMoveSpeed = self.moveSpeed 	--目前移动速度

	-- 伤害减免
	self.derateOtherAtk = 0
	self.curDerateOtherAtk = self.derateOtherAtk

	-- 最终伤害减免
	self.hurtDerate = 0
	self.curHurtDerate = self.hurtDerate

	-- 普攻伤害加成
	self.hurtAddition = 0
	self.curHurtAddition = self.hurtAddition

	-- 技能伤害加成
	self.skillHurtAddition = 0
	self.curSkillHurtAddition = self.skillHurtAddition

	-- 被治疗加成
	self.skillCureAddition = 0
	self.curSkillCureAddition = self.skillCureAddition

	-- 暴击
	self.crit = (params.crit and params.crit ~= 0) and params.crit or self.unitData.crit
	self.curCrit = self.crit

	-- 暴伤
	self.critHurt = (params.critHurt and params.critHurt ~= 0) and params.critHurt or self.unitData.critHurt
	self.curCritHurt = self.critHurt

	-- 韧性
	self.tenacity = (params.tenacity and params.tenacity ~= 0) and params.tenacity or self.unitData.tenacity
	self.curTenacity = self.tenacity

	-- 抵抗
	self.resist = (params.resist and params.resist ~= 0) and params.resist or self.unitData.resist
	self.curResist = self.resist

	-- 闪避
	self.miss = (params.miss and params.miss ~= 0) and params.miss or self.unitData.miss
	self.curMiss = self.miss

	-- 命中
	self.hit = (params.hit and params.hit ~= 0) and params.hit or self.unitData.hit
	self.curHit = self.hit

	-- 格挡
	self.parry = (params.parry and params.parry ~= 0) and params.parry or self.unitData.parry
	self.curParry = self.parry

	-- 破击
	self.ignoreParry = (params.ignoreParry and params.ignoreParry ~= 0) and params.ignoreParry or self.unitData.ignoreParry
	self.curIgnoreParry = self.ignoreParry

	self.slowdown = false 	-- 缓速
	self.buqu = false

	-- 攻击加速
	self.attackSpeedup = 0
	self.curAttackSpeedup = self.attackSpeedup

	-- 无敌
	self.invincible = false
	self.curInvincible = self.invincible

	-- 反弹
	self.rebound = false
	self.curRebound = self.rebound

	-- 吸收伤害
	self.suckDamage = false
	self.curSuckDamage = self.suckDamage

	-- 伤害吸收护盾
	self.shieldDamage = 0

	-- 沉默
	self.silence = false
	self.curSilence = self.silence

	-- 偷取攻击
	self.stealAtk = 0 				-- 效果持续整场战斗
	self.stolenAtk = 0 				-- 效果持续整场战斗

	-- 怒气消耗增加
	self.angryExtraCost = 0 		-- 效果持续整场战斗

	-- 技能cd时间
	self.skillCd = 0
	self.firstSkillCd = true 			-- pve右侧有初始cd时间

	-- 死亡时间
	self.bedyingTime = 0

	-- 添加buff成功机率
	self.addBuffProbability = 0

	-- 具体的实现技能和buff类
	self.reflections = {
		skill = params.skillDef or "logical.battle.Skill",
		buff = params.buffDef or "logical.battle.Buff",
		passiveSkill = params.passiveSkillDef or "logical.battle.PassiveSkill"
	}

	-- 上场后, 身上携带的组合技
	self.associationSkills = {}

	-- 武将的被动技能
	self:initPassiveSkills()

	-- 修正武将基本属性
	self:initHeroAttribute(params)

	-- 被作用的buff
	self.buffs = list_newList()

	self.battleField:addSoldier(self)

	------------------------------------------------------------------
	-- 强制移动目的地坐标
	self.forceMoveTargetPos = nil

	-- 强制攻击对象
	-- self.forceAttackTarget = nil

	-- 当前攻击对象
	self.curAttackTarget = nil

	-- 当前移动目的地
	self.curMovePos = nil

	-- 武将状态机
	cc.GameObject.extend(self):addComponent("components.behavior.StateMachine"):exportMethods()
	self:initEventMap()

	local doEvent_ = self.doEvent
	self.doEvent = function (self,...)
		if self:canDoEvent(...) then
			doEvent_(self, ...)
		end
	end
end

-- 武将当前的攻击力
function Soldier:getCurAttack()
	return self.curAttack + self.stealAtk - self.stolenAtk
end

function Soldier:initEventMap()
	self:setupState({
		initial = "standby",

		events = {
			{ name = "ToIdle", from = "move", to = "standby" },
			{ name = "ToIdle", from = "attack", to = "standby" },
			{ name = "ToIdle", from = "skillAttack", to = "standby" },
			{ name = "ToIdle", from = "damaged", to = "standby"},
			{ name = "ToIdle", from = "dizzy", to = "standby" },
			{ name = "ToIdle", from = "frozen", to = "standby" },
			{ name = "ToIdle", from = "hypnosis", to = "standby" },
			{ name = "ToIdle", from = "dead", to = "standby" },		-- 复生
			{ name = "ToIdle", from = "deepSleep", to = "standby" },
			{ name = "ToIdle", from = "forceMove", to = "standby" },
			{ name = "BeginAttack", from = "standby", to = "attack" },
			{ name = "BeginAttack", from = "move", to = "attack" },
			{ name = "BeginAttack", from = "dizzy", to = "attack" },
			{ name = "BeginAttack", from = "frozen", to = "attack" },
			{ name = "BeginSkillAttack", from = "standby", to = "skillAttack" },
			{ name = "BeginSkillAttack", from = "move", to = "skillAttack" },
			{ name = "BeginSkillAttack", from = "attack", to = "skillAttack" },
			{ name = "BeginSkillAttack", from = "frozen", to = "skillAttack" },
			{ name = "BeginSkillAttack", from = "dizzy", to = "skillAttack" },
			{ name = "BeginSkillAttack", from = "damaged", to = "skillAttack" },
			{ name = "BeDamaged", from = "standby", to = "damaged" },
			{ name = "BeDamaged", from = "move", to = "damaged" },
			{ name = "BeDamaged", from = "attack", to = "damaged" },
			{ name = "BeDamaged", from = "damaged", to = "damaged" },
			{ name = "Freeze", from = "standby", to = "frozen" },
			{ name = "Freeze", from = "move", to = "frozen" },
			{ name = "Freeze", from = "attack", to = "frozen" },
			{ name = "Freeze", from = "dizzy", to = "frozen" },
			{ name = "Freeze", from = "hypnosis", to = "frozen" },
			{ name = "ToDizzy", from = "standby", to = "dizzy" },
			{ name = "ToDizzy", from = "move", to = "dizzy" },
			{ name = "ToDizzy", from = "attack", to = "dizzy" },
			{ name = "ToDizzy", from = "frozen", to = "dizzy" },
			{ name = "ToDizzy", from = "hypnosis", to = "dizzy" },
			{ name = "ToHypnosis", from = "standby", to = "hypnosis" },
			{ name = "ToHypnosis", from = "move", to = "hypnosis" },
			{ name = "ToHypnosis", from = "attack", to = "hypnosis" },
			{ name = "ToHypnosis", from = "frozen", to = "hypnosis" },
			{ name = "ToHypnosis", from = "dizzy", to = "hypnosis" },
			{ name = "ToHypnosis", from = "damaged", to = "hypnosis"},
			{ name = "ToDeepSleep", from = "standby", to = "deepSleep" },
			{ name = "ToDeepSleep", from = "move", to = "deepSleep" },
			{ name = "ToDeepSleep", from = "attack", to = "deepSleep" },
			{ name = "ToDeepSleep", from = "frozen", to = "deepSleep" },
			{ name = "ToDeepSleep", from = "dizzy", to = "deepSleep" },
			{ name = "ToDeepSleep", from = "damaged", to = "deepSleep"},
			{ name = "ToDeepSleep", from = "hypnosis", to = "deepSleep" },
			{ name = "BeginMove", from = "standby", to = "move" },
			{ name = "BeginMove", from = "attack", to = "move" },
			{ name = "BeginMove", from = "frozen", to = "move" },
			{ name = "BeginMove", from = "dizzy", to = "move" },
			{ name = "BeginForceMove", from = "standby", to = "forceMove" },
			{ name = "BeginForceMove", from = "attack", to = "forceMove" },
			{ name = "BeginForceMove", from = "frozen", to = "forceMove" },
			{ name = "BeginForceMove", from = "dizzy", to = "forceMove" },
			{ name = "BeginForceMove", from = "move", to = "forceMove" },
			{ name = "BeKilled", from = "*", to = "dead" },
			{ name = "ToDreamKill", from = "*", to = "dreamKill"},
		},

		callbacks = {
			onStart = function(event) end,
			onToIdle = function(event) end,
			-- 开始攻击状态
			onBeginAttack = function(event)
				self.waitFrame = randomInt(0, 30)
			end,
			onBeginSkillAttack = function(event) 
				self.canPause = false
				self:onSkillAttack({})
			end,
			onBeginMove = function(event)
				self.waitFrame = randomInt(0, 30)
			end,
			onBeKilled = function(event) end,

			-- 离开攻击状态
			onleaveattack = function(event)
				self.attackDetectPoint = 0
				self.waitFrame = math.huge
			end,
			onleaveskillAttack = function(event) 
				self.prepareSkill = false
			end,

			onleavehypnosis = function (event)
				self.displayNode:setVisible(true)
				if self.pigNode then
					self.pigNode:removeFromParent()
					self.pigNode = nil
				end
			end,

			onleavedead = function ()
				echo("-------> 复生")
				self:playAnimation("attack4")
			end,

			-- 受击
			onenterdamaged = function(event) self:onDamaged() end,

			-- 眩晕
			onenterdizzy = function(event) self:onDizzy() end,

			enterdreamKill = function(event) self:onDreamKill() end,

			-- 冰冻
			onenterfrozen = function(event) 
				self.animation:pause()
				if self.effectAnimation then
					self.effectAnimation:pause()
				end
			end,

			-- 催眠
			onenterhypnosis = function(event) self:onHypnosis() end,
		}
	})
end

function Soldier:getAnchKey()
	return self.camp .. self.anchPoint.x .. self.anchPoint.y
end

-- 武将属性
function Soldier:initHeroAttribute(params)
	params = params or {}

	-- 战斗属性修正
	self.hp = self.hp * (100 + tonum(params.hpModify)) / 100
	--远征中用于设置初始hp
	self.maxHp = self.hp

	self.hp=params.blood and math.floor(self.hp*tonumber(params.blood)/100) or self.hp

	 -- print("maxHp",self.hp,self.maxHp,params.blood)

	self.attack = self.attack * (100 + tonum(params.atkModify)) / 100
	self.curAttack = self.attack

	self.defense = self.defense * (100 + tonum(params.defModify)) / 100
	self.curDefense = self.defense

	--self:initHeroAttributeByPassiveSkills()

	-- 战斗属性替换
	if self.moveSpeed == 0 then
		self.moveSpeed = (self.unitData.moveSpeed ~= 0 and self.unitData.moveSpeed or self.heroProfession.moveSpeed) / 1000
	end
	self.curMoveSpeed = self.moveSpeed

	if self.attackSpeed == 0 then
		self.attackSpeed = self.heroProfession.attackSpeed
	end
	self.attackSpeed = self.attackSpeed * 100 / self.atkSpeedFactor
	self.curAttackSpeed = self.attackSpeed

	if self.attackRange == 0 then
		self.attackRange = self.unitData.atcRange ~= 0 and self.unitData.atcRange or self.heroProfession.atcRange
	end
end

function Soldier:onPassiveAnimation(skillId)
	local states = {
		skillPassiveCsv.EFFECT_ATK,
		skillPassiveCsv.EFFECT_DEFENSE,
		skillPassiveCsv.EFFECT_HP,
		skillPassiveCsv.EFFECT_CRIT,
		skillPassiveCsv.EFFECT_TENACITY,
		skillPassiveCsv.EFFECT_CRIT_HURT,
		skillPassiveCsv.EFFECT_MISS,
		skillPassiveCsv.EFFECT_HIT,
		skillPassiveCsv.EFFECT_PARRY,
		skillPassiveCsv.EFFECT_IGNORE_PARRY,
		skillPassiveCsv.EFFECT_RESIST,
		skillPassiveCsv.EFFECT_ANGER_SPEEDUP,
		skillPassiveCsv.EFFECT_ATK_SPEEDUP,
		skillPassiveCsv.EFFECT_BUFF_PROBABILITY,
		skillPassiveCsv.EFFECT_ADD_ANGER,
	}

	local passiveSkill = self.passiveSkills[skillId]
	for _,v in ipairs(states) do
		passiveSkill:handleSkill({condition = skillPassiveCsv.TRIGGER_NONE, effect = v})
	end

	game:playMusic(passiveSkill.csvData.musicId)
end

function Soldier:initHeroAttributeByPassiveSkills()

	local states = {
		skillPassiveCsv.EFFECT_ATK,
		skillPassiveCsv.EFFECT_DEFENSE,
		skillPassiveCsv.EFFECT_HP,
		skillPassiveCsv.EFFECT_CRIT,
		skillPassiveCsv.EFFECT_TENACITY,
		skillPassiveCsv.EFFECT_CRIT_HURT,
		skillPassiveCsv.EFFECT_MISS,
		skillPassiveCsv.EFFECT_HIT,
		skillPassiveCsv.EFFECT_PARRY,
		skillPassiveCsv.EFFECT_IGNORE_PARRY,
		skillPassiveCsv.EFFECT_RESIST,
		skillPassiveCsv.EFFECT_ANGER_SPEEDUP,
		skillPassiveCsv.EFFECT_ATK_SPEEDUP,
		skillPassiveCsv.EFFECT_BUFF_PROBABILITY,
		skillPassiveCsv.EFFECT_ADD_ANGER,
	}
--[[
	for _,v in ipairs(states) do
		self:triggerPassiveSkill({condition = skillPassiveCsv.TRIGGER_NONE, effect = v})
		self:triggerBeautySkill({condition = skillPassiveCsv.TRIGGER_NONE, effect = v})
	end
--]]	
	
	self.isPassiveAni = self.isPassiveAni or true
	for index, passiveSkill in ipairs(self.passiveSkills) do
		if not passiveSkill:isActiveSkill() and not passiveSkill:isDeathTrigger() then
			self.passiveAniIndex = index
			self:onPassiveAnimation(index)
			passiveSkill:displayPassiveSkillName()
			break
		end
	end

	if not self.passiveAniIndex then
		self.isPassiveAni = false
	end

	-- 美人被动技能
	-- 开场隐藏美人被动技能冒字
	for _,passiveSkill in ipairs(self.beautySkills) do
		passiveSkill.hideText = true
	end
	for _,v in ipairs(states) do
		self:triggerBeautySkill({condition = skillPassiveCsv.TRIGGER_NONE, effect = v})
	end
	for _,passiveSkill in ipairs(self.beautySkills) do
		passiveSkill.hideText = nil
	end
end

-- 根据职业和阵营重新计算武将属性的加成
function Soldier:reCalcAttrByPassiveSkills(soldiers)
	--[[ 已经被砍，找策划
	for _,skillId in pairs(self.passiveSkills) do
		local passiveSkill = skillPassiveCsv:getPassiveSkillById(skillId)

		-- 职业加成
		if passiveSkill and passiveSkill.triggerMap[tostring(skillPassiveCsv.TRIGGER_PROFESSION)] then
			local skillLevel = self.skillLevels[tostring(skillId + 10000)] or 1
			local growthValue = (skillLevel - 1) * passiveSkill.effectGrowth	

			local profession = tonum(passiveSkill.triggerMap[tostring(skillPassiveCsv.TRIGGER_PROFESSION)])
			for _,soldier in pairs(soldiers) do
				if soldier.unitData.profession == profession then
					if passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_ATK)] then
						local effectValue = tonum(passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_ATK)])
						soldier.attack = soldier.attack * ( 100 + effectValue + growthValue ) / 100
						soldier.curAttack = soldier.attack
					elseif passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_DEFENSE)] then
						local effectValue = tonum(passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_DEFENSE)])
						soldier.defense = soldier.defense * ( 100 + effectValue + growthValue ) / 100
						soldier.curDefense = soldier.defense
					elseif passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_HP)] then
						local effectValue = tonum(passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_HP)])
						soldier.hp = soldier.hp * ( 100 + effectValue + growthValue ) / 100
						soldier.maxHp = soldier.hp
					end
				end
			end
		end

		-- 阵营加成
		if passiveSkill and passiveSkill.triggerMap[tostring(skillPassiveCsv.TRIGGER_CAMP)] then
			local skillLevel = self.skillLevels[tostring(skillId + 10000)] or 1
			local growthValue = (skillLevel - 1) * passiveSkill.effectGrowth

			local camp = tonum(passiveSkill.triggerMap[tostring(skillPassiveCsv.TRIGGER_CAMP)])
			for _,soldier in pairs(soldiers) do
				if soldier.unitData.camp == camp then
					if passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_ATK)] then
						local effectValue = tonum(passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_ATK)])
						soldier.attack = soldier.attack * ( 100 + effectValue + growthValue ) / 100
						soldier.curAttack = soldier.attack
					elseif passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_DEFENSE)] then
						local effectValue = tonum(passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_DEFENSE)])
						soldier.defense = soldier.defense * ( 100 + effectValue + growthValue ) / 100
						soldier.curDefense = soldier.defense
					elseif passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_HP)] then
						local effectValue = tonum(passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_HP)])
						soldier.hp = soldier.hp * ( 100 + effectValue + growthValue ) / 100
						soldier.maxHp = soldier.hp
					end
				end
			end
		end
	end
	]]
end

-- 阶段性恢复生命
function Soldier:recoverHp()
	local deltaValue = self.maxHp * globalCsv:getFieldValue("phaseRecoverHp") / 100
	if self.hp + deltaValue > self.maxHp then 
		deltaValue = self.maxHp - self.hp
	end

	self:beingHurt({ hurtValue = -deltaValue})
end

function Soldier:resetAttribute()
	self.curAttack = self.attack
	self.curDefense = self.defense
	self.curMoveSpeed = self.moveSpeed
	self.curAttackSpeed = self.attackSpeed
	self.curDerateOtherAtk = self.derateOtherAtk
	self.curHurtDerate = self.hurtDerate
	self.curHurtAddition = self.hurtAddition
	self.curSkillHurtAddition = self.skillHurtAddition
	self.curSkillCureAddition = self.skillCureAddition
	-- 二级属性
	self.curCrit = self.crit
	self.curTenacity = self.tenacity
	self.curCritHurt = self.critHurt
	self.curResist = self.resist
	self.curMiss = self:calMissValue()
	self.curHit = self.hit
	self.curParry = self.parry
	self.curIgnoreParry = self.ignoreParry

	self.slowdown = false
	self.curAttackSpeedup = self.attackSpeedup
	self.curInvincible = self.invincible
	self.curRebound = self.rebound
	self.curSuckDamage = self.suckDamage
	self.curSilence = self.silence

	if self.bedyingTime > 0 then
		self.bedyingTime = self.bedyingTime - self.battle.frame
	end
end

function myPrint(args)
	-- print(args)
end

function Soldier:updateFrame(diff)
	if self.hasPaused then return end

	-- BUFF都是在原始属性上修改
	self:resetAttribute()

	-- 身上的buff全部走一遍
	local breakUpdate = false
	local deleteBuffs = {}
	for i=1, self.buffs.size() do
		local buff = self.buffs.indexAt(i)
		-- 技能攻击状态下, 中毒和加血BUFF暂停
		if self:getState() ~= "skillAttack" or not (buff.csvData.type == 1 or buff.csvData.type == 4) then
			local result = buff:effect(self,diff)
			if result == 0 then deleteBuffs[#deleteBuffs + 1] = buff end
			if result == 2 and not breakUpdate then breakUpdate = true end
		end
	end
	-- 删除结束的BUFF
	for _, buff in ipairs(deleteBuffs) do
		for i=1, self.buffs.size() do
			local buff1 = self.buffs.indexAt(i)
			if buff == buff1 then
				self.buffs.remove(i)
				break
			end
		end
	end

	-- 眩晕或者冰冻
	if breakUpdate then return end

	if self:getState() == "hypnosis" then return end

	if self.dreamKill then
		self:onDreamKill()
		return
	end

	while true do
		while self:getState() == "standby" do
			local enemy = self.battleField:getAttackObject(self)
			if not enemy then
				myPrint("1")
				self.curAttackTarget = nil
				self:onStandby({})
				return
			else
				myPrint("2")
				self.curAttackTarget = enemy
			end

			-- 判定移动优先还是攻击优先
			if globalCsv:getFieldValue("battleMoveFirst") == 1 then
				myPrint("3")
				if self:canMove(1) then
					myPrint("4")
					self:doEvent("BeginMove")
					break
				end

				-- 有可以攻击的敌人
				if self:canAttack(enemy) == true then
					myPrint("5")
					self:doEvent("BeginAttack")
					break
				end
			else
				-- 有可以攻击的敌人
				if self:canAttack(enemy) == true then
					self:doEvent("BeginAttack")
					break
				end

				if self:canMove(1) then
					self:doEvent("BeginMove")
					break
				end
			end

			self:onStandby({})
			return
		end

		while self:getState() == "move" do
			myPrint("move,1")
			if self.waitFrame ~= math.huge and self.waitFrame > 0 then
				self:onStandby()
				self.waitFrame = self.waitFrame - 1
				return
			end
			local enemy = self.curAttackTarget
			if not self:checkCurEnemy(enemy) then
				myPrint("move,2")
				self:doEvent("ToIdle")
				break
			end
			myPrint("move,3")

			-- 有可以攻击的敌人
			if globalCsv:getFieldValue("battleMoveFirst") == 1 then
				if self:canAttack(enemy) then
					self:doEvent("BeginAttack")
					break
				end
			end

			local curMoveSpeed = self:modifyMoveSpeed()
			local elapseTime = self.battle.frame
			-- 是否降速
			local moveDistance = curMoveSpeed * elapseTime / (self.slowdown and 2 or 1)
			local continueMove, canMovePoint = self:canMove(moveDistance)

			if not continueMove then
				self:beingMove({ beginX = self.position.x, beginY = self.position.y, offset = canMovePoint, time = elapseTime })
				self:doEvent("ToIdle")
				return
			end

			self:beingMove({ beginX = self.position.x, beginY = self.position.y, offset = canMovePoint, time = elapseTime })

			if globalCsv:getFieldValue("battleMoveFirst") == 0 or not self:canMove(1) then
				-- 有可以攻击的敌人
				if enemy and self:canAttack(enemy) then
					self:doEvent("BeginAttack")
					break
				end
			end

			return
		end

		-- 强制移动
		while self:getState() == "forceMove" do
			local moveTargetPos = self.forceMoveTargetPos
			if not moveTargetPos then
				self:doEvent("ToIdle")
				break
			end
			local curMoveSpeed = self:modifyMoveSpeed()
			local elapseTime = self.battle.frame
			-- 是否降速
			local moveDistance = curMoveSpeed * elapseTime / (self.slowdown and 2 or 1)
			local continueMove, canMovePoint = self:canForceMove(moveDistance)
			print("canMovePoint",canMovePoint.x,canMovePoint.y)
			if not continueMove then
				print("cont continueMove",canMovePoint.x,canMovePoint.y)
				self:beingMove({ beginX = self.position.x, beginY = self.position.y, offset = canMovePoint, time = elapseTime })
				self:doEvent("ToIdle")
				return
			end

			self:beingMove({ beginX = self.position.x, beginY = self.position.y, offset = canMovePoint, time = elapseTime })

			return
		end

		-- 冰冻
		while self:getState() == "frozen" do
			self:onFrozen()
			return
		end

		-- 眩晕
		while self:getState() == "damaged" do
			return
		end

		-- 普攻
		while self:getState() == "attack" do
			if self.waitFrame ~= math.huge and self.waitFrame > 0 then
				self:onStandby()
				self.waitFrame = self.waitFrame - 1
				return
			end

			-- 当前要攻击的敌人
			local enemy = self.curAttackTarget
			if not self:checkCurEnemy(enemy) then
				-- 攻击动作没做完就结束了
				if self.actionStatus == "attack" then
					return
				end
				
				self:doEvent("BeginMove")
				break
			end

			-- 如果还在攻击cd范围内
			local inAttackCd = self.attackDetectPoint > 0
			if inAttackCd and self:canAttack(enemy) then
				self:checkAttackStatus({ enemy = enemy})
				local elapseTime = self.slowdown and (self.battle.frame / 2) or self.battle.frame
				self.attackDetectPoint = self.attackDetectPoint - self.battle.frame
				return

			elseif self:canAttack(enemy) then
				-- if not self:releasePassiveSkill() then
				-- 	self:onAttack({ enemy = enemy , text = text, atk = atk, type = 1})
				-- else
				-- 	self:onAttack({ enemy = enemy , text = text, atk = atk, type = 2})
				-- end
				self:attackByTurns({enemy = enemy , text = text, atk = atk})
				self.attackDetectPoint = self.curAttackSpeed / (1 + self.curAttackSpeedup)
				return

			else
				-- 最近敌人已经被消灭
				if self.actionStatus == nil then
					self:doEvent("BeginMove")
				end

				break
			end
		end

		while self:getState() == "skillAttack" do
			return
		end

		if self:getState() == "dead" then
			-- 如果死掉, 需要从战场上移掉
			self:onDeath({})
			break
		else
			echo("invalid state", self:getState())
			break	
		end
	end
end

-- 处理被动技能
function Soldier:handlePassiveSkill(atkSoldier, defSoldier)
	if self.startShow then return end

	-- 攻击相关
	atkSoldier:triggerPassiveSkill({
		condition = skillPassiveCsv.TRIGGER_ATK_PROFESSION,		-- 攻击职业
		effect = skillPassiveCsv.EFFECT_ATK,
		triggerEvent = function (value)
			return value == defSoldier.unitData.profession
		end,
		temp = true})

	atkSoldier:triggerPassiveSkill({
		condition = skillPassiveCsv.TRIGGER_ATK_CAMP,			-- 攻击阵营
		effect = skillPassiveCsv.EFFECT_ATK,
		triggerEvent = function (value)
			return value == defSoldier.unitData.camp
		end,
		temp = true})

	atkSoldier:triggerPassiveSkill({
		condition = skillPassiveCsv.TRIGGER_ATK_SEX,			-- 攻击性别
		effect = skillPassiveCsv.EFFECT_ATK,
		triggerEvent = function (value)
			return tonum(value) == defSoldier.unitData.sex
		end,
		temp = true})

	atkSoldier:triggerPassiveSkill({
		condition = skillPassiveCsv.TRIGGER_ATK_SEX,			-- 攻击性别
		effect = skillPassiveCsv.EFFECT_HURT_INCRE,
		triggerEvent = function (value)
			return tonum(value) == defSoldier.unitData.sex
		end,
		temp = true})


	-- 被攻击相关
	defSoldier:triggerPassiveSkill({
		condition = skillPassiveCsv.TRIGGER_ATK_BY_PROFESSION,			-- 被职业攻击
		effect = skillPassiveCsv.EFFECT_HURT_LESS,
		triggerEvent = function (value)
			return value == atkSoldier.unitData.profession
		end,
		temp = true})

	defSoldier:triggerPassiveSkill({
		condition = skillPassiveCsv.TRIGGER_ATK_BY_CAMP,				-- 被阵营攻击
		effect = skillPassiveCsv.EFFECT_HURT_LESS,
		triggerEvent = function (value)
			return value == atkSoldier.unitData.camp
		end,
		temp = true})


	-- 被攻击美人计相关
	self:triggerBeautySkill({
		condition = skillPassiveCsv.TRIGGER_ATK_BY_PROFESSION,			-- 被职业攻击
		effect = skillPassiveCsv.EFFECT_HURT_LESS,
		triggerEvent = function (value)
			return value == atkSoldier.unitData.profession
		end,
		temp = true})

	self:triggerBeautySkill({
		condition = skillPassiveCsv.TRIGGER_ATK_BY_CAMP,				-- 被阵营攻击
		effect = skillPassiveCsv.EFFECT_HURT_LESS,
		triggerEvent = function (value)
			return value == atkSoldier.unitData.camp
		end,
		temp = true})
end

-- 计算伤害值
function Soldier:calcHurtValue(atkSoldier, defSoldier)
	self:handlePassiveSkill(atkSoldier, defSoldier)
	-- 敌人可能有减免BUFF
	local restraintValue = restraintCsv:getValue(atkSoldier.unitData.profession, defSoldier.unitData.profession) / 100
	local attackValue = (atkSoldier.curAttack + atkSoldier.stealAtk - atkSoldier.stolenAtk) * (100 - defSoldier.curDerateOtherAtk) / 100
	local enemyDefense = defSoldier.curDefense / (attackValue * globalCsv:getFieldValue("k2") + defSoldier.curDefense * globalCsv:getFieldValue("k3"))
	local hurtValue = globalCsv:getFieldValue("k1") * attackValue * restraintValue * (1 - enemyDefense)
	-- 普攻伤害加成、减免计算
	hurtValue = hurtValue * (1 + atkSoldier.curHurtAddition - defSoldier.curHurtDerate)

	if defSoldier.curInvincible then
		restraintValue = 0
	end

	return hurtValue,restraintValue
end

-- 通过二次属性计算新的伤害值
function Soldier:secondAttrEffect(params)
	params = params or {}

	-- 无敌判定
	if params.enemy.curInvincible then
		return { enemy = 0, self = 0, effect = "invincible" }
	end

	-- 致命一击判定
	local skillEvent = {
		condition = skillPassiveCsv.TRIGGER_ENEMY_HP_LESS,
		effect = skillPassiveCsv.EFFECT_DEADLY_KILL,
		triggerEvent = function (value)
			return params.enemy.hp < params.enemy.maxHp * value / 100
		end,
	}
	self:triggerPassiveSkill(skillEvent)
	if skillEvent.returnValue then
		return { enemy = params.enemy.hp, self = 0 , effect = "deadly"}
	end

	local effect = "normal"
	local miss = math.min(math.max(globalCsv:getFieldValue("missFloor"), params.enemy.curMiss - self.curHit), globalCsv:getFieldValue("missCeil"))
	if randomInt(0, 1000) <= miss then

		-- 闪避成功触发被动技能
		params.enemy:triggerPassiveSkill({condition = skillPassiveCsv.TRIGGER_MISS, effect = skillPassiveCsv.EFFECT_ATK})

		-- 闪避成功
		return { enemy = 0, self = 0 , effect = "miss"}
	end

	--反弹判定
	local skillEvent = {
		condition = skillPassiveCsv.TRIGGER_BEFORE_ATK,
		effect = skillPassiveCsv.EFFECT_BOUNCE_HURT,
	}
	params.enemy:triggerPassiveSkill(skillEvent)
	if skillEvent.returnValue then
		return { enemy = 0, self = params.hurtValue , effect = "rebound"}
	end

	-- 反弹BUFF
	if self.curRebound then
		return { enemy = 0, self = params.hurtValue , effect = "rebound"}
	end

	local enemyHurtValue, selfHurtValue = 0, 0
	local parry = math.min(math.max(globalCsv:getFieldValue("parryFloor"), params.enemy.curParry - self.curIgnoreParry), globalCsv:getFieldValue("parryCeil"))	
	if randomInt(0, 1000) <= parry then
		-- 格挡成功
		enemyHurtValue = params.hurtValue * 0.6
		selfHurtValue = params.hurtValue * 0.4
		effect = "parry"

		-- 格挡成功触发被动技能
		params.enemy:triggerPassiveSkill({condition = skillPassiveCsv.TRIGGER_PARRY, effect = skillPassiveCsv.EFFECT_ABSORB_HURT,
			enemyHurtValue = enemyHurtValue})

	else
		local crit = math.min(math.max(globalCsv:getFieldValue("critFloor"), self.curCrit - params.enemy.curTenacity), globalCsv:getFieldValue("critCeil"))	
		if randomInt(0, 1000) <= crit then	
			enemyHurtValue = params.hurtValue * (100 + self.curCritHurt) / 100
			effect = "crit"

			-- 暴击触发
			self:triggerPassiveSkill({condition = skillPassiveCsv.TRIGGER_CRIT, effect = skillPassiveCsv.EFFECT_CRIT})

		else
			enemyHurtValue = params.hurtValue
		end
	end

	return { enemy = enemyHurtValue, self = selfHurtValue , effect = effect}
end

-- 是否触发被动技能
-- @param {condition=触发条件, effect=触发效果}
function Soldier:triggerPassiveSkill(params)
	for _,passiveSkill in ipairs(self.passiveSkills) do
		passiveSkill:handleSkill(params)
	end
end

function Soldier:triggerBeautySkill(params)
	for _,passiveSkill in ipairs(self.beautySkills) do
		passiveSkill:handleSkill(params)
	end
end

-- 检测当前攻击的敌人是否存在和活着
function Soldier:checkCurEnemy(enemy)
	if not enemy or enemy:getState() == "dead" then
		self.curAttackTarget = nil
		return false
	end
	return true
end

-- 是否可以攻击
-- @param enemy 	被攻击方
-- @return 能攻击返回true, 否则false
function Soldier:canAttack(enemy)
	if not self:checkCurEnemy(enemy) then
		return false
	end

	local enemyPosX,enemyPosY = enemy.position.x,enemy.position.y
	
	local distance = pGetDistance(self.position,CCPoint(enemyPosX,enemyPosY))

	-- 左边优先一个像素的距离
	if self.camp == "left" then
		distance = distance - 1
	end

	local atkRange = self.attackRange > 0 and self.attackRange or self.heroProfession.frontAtcRange
	
	if distance > atkRange then return false end

	-- 距离允许
	return true
end

-- 检查技能释放者的基础状态
function Soldier:canReleaseSkillOne()
	if self.hp <= 0 then return false end
	-- if self.hasPaused then return false end

	if self.curSilence then return false end
	if self.prepareSkill then return false end

	-- 如果左方有技能存在
	if self.camp == "right" and self.battleField.leftCamp.skillRefCount > 0 then
		return false
	end

	local state = self:getState()
	if state == "skillAttack" or state == "dizzy" or state == "frozen" or state == "hypnosis" then
		return false
	end

	local skillData = skillCsv:getSkillById(self.unitData and self.unitData.talentSkillId or 0)
	if not skillData then return false end

	return true
end

-- 检查技能释放者的技能豆
function Soldier:canReleaseSkillTow()
	local skillData = skillCsv:getSkillById(self.unitData.talentSkillId)
	if not skillData then return false end

	-- 技能等级修正技能豆
	local skillLevel = self.skillLevels[tostring(self.unitData.talentSkillId)] or 1

	-- 被动技能，技能豆消耗减少
	local params = {
		condition = skillPassiveCsv.TRIGGER_RELEASE_SKILL,
		effect = skillPassiveCsv.EFFECT_ANGRY_LESS,
	}
	self:triggerPassiveSkill(params)
	local lessAngry = params.returnValue or 0

	-- 被动技能
	local releaseAngry = skillData.angryUnitNum - lessAngry < 1 and 1 or skillData.angryUnitNum - lessAngry

	releaseAngry = releaseAngry + self.angryExtraCost

	-- 技能豆不够
	if self.skillCd > 0 or not skillData or releaseAngry > self.battleField[self.camp .. "Camp"].angryUnitNum then
		return false, releaseAngry
	end

	return true, releaseAngry
end

function Soldier:canReleaseSkill()
	if not self:canReleaseSkillOne() then return false end

	return self:canReleaseSkillTow()
end

function Soldier:releaseSkill(checkAngry)
	if not self:canReleaseSkillOne() then return false end

	local campInstance = self.battleField[self.camp .. "Camp"]
	-- PvE敌方不需要消耗技能豆
	if checkAngry == nil then checkAngry = true end
	if checkAngry then
		local releasable, releaseAngry = self:canReleaseSkillTow()
		if not releasable then return false end

		-- 消耗技能豆
		campInstance:consumeAngryValue(releaseAngry)
	end
	
	local skillData = skillCsv:getSkillById(self.unitData and self.unitData.talentSkillId or 0)
	self.curSkill = require(self.reflections["skill"]).new({ id = skillData.skillId, owner = self, battleField = self.battleField })
	self.curSkill:onShow()

	campInstance.skillRefCount = campInstance.skillRefCount + 1
	self.skillProgress = 1
	self.prepareSkill = true

	return true
end

-- 释放被动触发主动计
function Soldier:releasePassiveSkill()
	if self.hp <= 0 then return false end

	if self:getState() == "skillAttack" then return false end

	if self.hasPaused then return false end

	local params = {
		condition = skillPassiveCsv.TRIGGER_SKILL,
		effect = skillPassiveCsv.EFFECT_SKILL,
		triggerEvent = function (value)
			return randomInt(0,100) <= value
		end,
		}
	self:triggerPassiveSkill(params)

	local skillId = params.returnValue
	if not skillId then return false end

	-- 被动技能直接作用
	self.curPassiveSkill = require(self.reflections["skill"]).new({ id = skillId, owner = self, battleField = self.battleField, passive = true })
	return true
end

-- 按秩序攻击
function Soldier:attackByTurns(params)

	local attack = {
		[0] = function ()
			--self:onAttack({ enemy = enemy , text = text, atk = atk, type = 1})
			params.type = 1
			return self:onAttack(params)
		end,

		[1] = function ()
			local passiveSkill = self.passiveSkills[1]
			if passiveSkill and passiveSkill:isActiveSkill() and not self.curSilence then
				local _,skillId = passiveSkill:isActiveSkill()
				self.curPassiveSkill = nil
				self.curPassiveSkill = require(self.reflections["skill"]).new({ id = skillId, owner = self, 
					battleField = self.battleField, passive = true })
				params.type = 2
				params.hasFootHalo = passiveSkill.csvData.hasFootHalo
			else
				params.type = 1
			end
			return self:onAttack(params)
		end,

		[2] = function ()
			local passiveSkill = self.passiveSkills[2]
			if passiveSkill and passiveSkill:isActiveSkill() and not self.curSilence then
				local _,skillId = passiveSkill:isActiveSkill()
				self.curPassiveSkill = nil
				self.curPassiveSkill = require(self.reflections["skill"]).new({ id = skillId, owner = self, 
					battleField = self.battleField, passive = true })
				params.type = 3
				params.hasFootHalo = passiveSkill.csvData.hasFootHalo
			else
				params.type = 1
			end
			return self:onAttack(params)
		end,

		[3] = function ()
			local passiveSkill = self.passiveSkills[3]
			if passiveSkill and passiveSkill:isActiveSkill() and not self.curSilence then
				local _,skillId = passiveSkill:isActiveSkill()
				self.curPassiveSkill = nil
				self.curPassiveSkill = require(self.reflections["skill"]).new({ id = skillId, owner = self, 
					battleField = self.battleField, passive = true })
				params.type = 4
				params.hasFootHalo = passiveSkill.csvData.hasFootHalo
			else
				params.type = 1
			end
			return self:onAttack(params)
		end,
	}

	self.turnIndex = self.turnIndex or 1

	if self.turnIndex <= #self.unitData.firstTurn then
		local id = self.unitData.firstTurn[self.turnIndex]
		self.turnIndex = self.turnIndex + 1
		return attack[tonum(id)]()
	end

	local n = self.turnIndex - #self.unitData.firstTurn - 1
	local id = self.unitData.cycleTurn[(n % #self.unitData.cycleTurn) + 1]
	self.turnIndex = self.turnIndex + 1
	return attack[tonum(id)]()
end

function Soldier:addBuff(params)
	if self.hp <= 0 then return false end
	params.owner = self

	local buffCsvData = buffCsv:getBuffById(params.buffId)
	if not buffCsvData or buffCsvData.type <= 0 then
		-- buff数据不存在
		return false
	end

	local buff = require(self.reflections["buff"]).new(params)

	-- 免疫
	local skillEvent = {
		condition = skillPassiveCsv.TRIGGER_DEBUFF,
		effect = skillPassiveCsv.EFFECT_IMMUNITY,
		triggerEvent = function (value)
			return buff.csvData.debuff == 1
		end,
		}
	self:triggerPassiveSkill(skillEvent)
	if skillEvent.returnValue then
		return false
	end

	-- 机率触发
	local rate = buffCsvData.rate + (params.level - 1) * buffCsvData.rateGrowth
	rate = rate + (params.addBuffProbability or 0 )

	-- 抵抗
	if buffCsv:canResist(params.buffId) then
		if randomInt(0, 1000) > (rate - self.curResist) then
			self:onEffect("dikang")
			return false
		end
	elseif randomInt(0, 1000) > rate then 
		return false
	end
	
	if self.curInvincible then
		local negativeBuffs = {4,5,6,16,17,18,22}
		for _,v in ipairs(negativeBuffs) do
			if buff.csvData.type == v then
				return true
			end
		end
	end

	if buff.csvData.type == 19 then
		self.buffs.insert(buff, 1)
	else
		self.buffs.insert(buff)	
	end

	buff:beginEffect(self)

	return true
end

-- 是否有相应的被动技能
-- @param 被动技能id
-- @return boolean 是否有被动技能
function Soldier:hasPassiveSkill(skill)
	for _, value in ipairs(self.passiveSkills) do 
		if value == skill then
			return true
		end
	end

	return false
end

-- 得到闪避值
function Soldier:calMissValue()
	self.curMiss = self.miss

	if self.startShow then return self.curMiss end

	local params = {
		condition = skillPassiveCsv.TRIGGER_HP_LESS,
		effect = skillPassiveCsv.EFFECT_MISS,
		triggerEvent = function (value)
			return self.hp < self.maxHp * value / 100
		end,
		temp = true}
	self:triggerPassiveSkill(params)
	if params.returnValue then
		self.buqu = true
	end

	return self.curMiss
end

-- 初始化被动技能列表
function Soldier:initPassiveSkills()
	self.passiveSkills = {}

	local function createPassiveSkill(id, skillId)
		self.passiveSkills[id] = require(self.reflections["passiveSkill"]).new({owner = self, 
				id = skillId})
	end

	if self.evolutionCount >= globalCsv:getFieldValue("passiveSkillLevel1") and
		self.evolutionCount < globalCsv:getFieldValue("passiveSkillLevel2") then
		if self.unitData.passiveSkill1 > 0 then
			createPassiveSkill(1, self.unitData.passiveSkill1)
		end
	elseif self.evolutionCount >= globalCsv:getFieldValue("passiveSkillLevel2") and
		self.evolutionCount < globalCsv:getFieldValue("passiveSkillLevel3") then
		if self.unitData.passiveSkill1 > 0 then
			createPassiveSkill(1, self.unitData.passiveSkill1)
		end
		if self.unitData.passiveSkill2 > 0 then
			createPassiveSkill(2, self.unitData.passiveSkill2)
		end
	elseif self.evolutionCount >= globalCsv:getFieldValue("passiveSkillLevel3") then
		if self.unitData.passiveSkill1 > 0 then
			createPassiveSkill(1, self.unitData.passiveSkill1)
		end
		if self.unitData.passiveSkill2 > 0 then
			createPassiveSkill(2, self.unitData.passiveSkill2)
		end
		if self.unitData.passiveSkill3 > 0 then
			createPassiveSkill(3, self.unitData.passiveSkill3)
		end
	end

	-- 美人技能
	self.beautySkills = {}

	local beautySkills = self.battleField[self.camp .. "Camp"].passiveSkills

	for _,skillId in ipairs(beautySkills) do
		self.beautySkills[#self.beautySkills + 1] = require(self.reflections["passiveSkill"]).new({owner = self, 
				id = skillId})
	end
end

-- 根据前面的兵来修正自己的移动速度
function Soldier:modifyMoveSpeed()
	-- local beforeTeamer = self.battleField:beforeXTeamer(self)
	-- if not beforeTeamer then
	-- 	self.curMoveSpeed = self.moveSpeed
	-- else
	-- 	self.curMoveSpeed = beforeTeamer.curMoveSpeed <= self.moveSpeed and beforeTeamer.curMoveSpeed or self.moveSpeed	
	-- end

	self.curMoveSpeed = self.moveSpeed

	return self.curMoveSpeed
end

-- 强制移动判断
function Soldier:canForceMove(moveDistance)
	if not self.forceMoveTargetPos then
		return false,ccp(0,0)
	end

	self.curMovePos = self.forceMoveTargetPos

	local distance = pGetDistance(self.position, self.curMovePos)
	if distance <= self.battleField.gridWidth then
		-- print("canForceMove,1",distance)
		return false,ccp(0,0)
	end

	local angle = math.atan2(self.curMovePos.y- self.position.y ,self.curMovePos.x-self.position.x)--pGetAngle(self.position, self.curMovePos)

	-- 根据斜边计算移动的坐标
	local calPosByDistance = function(l)
		return math.cos(angle) * l,math.sin(angle) * l
	end

	if distance - self.battleField.gridWidth <= moveDistance then
		local tempDisX,tempDisY = calPosByDistance(distance - self.battleField.gridWidth)
		-- print("1ccp(tempDisX, tempDisY)",tempDisX,tempDisY)
		return false, ccp(tempDisX, tempDisY)
	else
		local tempDisX,tempDisY = calPosByDistance(moveDistance)
		-- print("2ccp(tempDisX, tempDisY)",tempDisX,tempDisY)
		return true, ccp(tempDisX, tempDisY)
	end
end

-- 判断武将能否移动给定的距离
-- @param moveDistance	需要移动的距离
-- @return 可移动的距离
function Soldier:canMove(moveDistance)
	if not self:checkCurEnemy(self.curAttackTarget) then
		return false,ccp(0,0)
	end

	self.curMovePos = self.curAttackTarget.position

	local distance = pGetDistance(self.position, self.curMovePos)
	if distance <= self.battleField.gridWidth then
		return false,ccp(0,0)
	end

	local angle = pGetAngle(self.position, self.curMovePos)
	-- 根据斜边计算移动的坐标
	local calPosByDistance = function(l)
		return math.cos(angle) * l,math.sin(angle) * l
	end

	if distance - self.battleField.gridWidth <= moveDistance then
		local tempDisX,tempDisY = calPosByDistance(distance - self.battleField.gridWidth)
		return false, ccp(tempDisX, tempDisY)
	else
		local tempDisX,tempDisY = calPosByDistance(moveDistance)
		return true, ccp(tempDisX, tempDisY)
	end

end

-- 如果是扣血，params.attacker必填
-- 标记伤害来源，params.hurtFrom，1：来自普攻，2：来自技能，3：来自BUFF
function Soldier:beingHurt(params)
	if params.hurtValue == 0 then return end
	if self.curInvincible and params.hurtValue > 0 then return end

	if self.dreamKill then return end

	local origHp = self.hp

	-- 已经被杀死
	if origHp <= 0 then return true end

	local hurtValue = params.hurtValue 
	if self.curSuckDamage and hurtValue > 0 then
		hurtValue = - hurtValue
	end

	-- 垂死时不受伤害
	if self.bedyingTime <= 0 then
		if hurtValue > 0 then

			-- 唤醒催眠
			if self:isState("hypnosis") then
				self:doEvent("ToIdle")
			end

			-- 唤醒深度睡眠
			if self:isState("deepSleep") then
				self:removeDeepSleepDebuff()
			end

			-- 伤害吸收护盾
			if self.shieldDamage > 0 then
				local tempHurtValue = tonum(hurtValue)

				if self.shieldDamage > hurtValue then
					self.shieldDamage = self.shieldDamage - hurtValue
					hurtValue = 0
				else
					hurtValue = hurtValue - self.shieldDamage
					self.shieldDamage = 0

					tempHurtValue = self.shieldDamage
				end

				local event = {
					condition = skillPassiveCsv.TRIGGER_HURT_IN_PROTECT_BUFF,
					effect = skillPassiveCsv.EFFECT_BOUNCE_PROTECT_HURT,
					hurtValue = tempHurtValue,
				}
				self:triggerPassiveSkill(event)
				if params.attacker then
					params.attacker:beingHurt({hurtValue = tonum(event.returnValue) })
				end
			end

			if self.hp <= hurtValue then
				self.hp = 0

				-- 自身死亡时触发
				self:triggerPassiveSkill({condition = skillPassiveCsv.TRIGGER_DEAD, effect = skillPassiveCsv.EFFECT_RANDOM_HURT})

				-- 队友死亡时触发
				local teammates = self.battleField[self.camp .. "SoldierMap"]
				for _, soldier in pairs(teammates) do
					soldier:triggerPassiveSkill({condition = skillPassiveCsv.TRIGGER_OUR_DEAD, effect = skillPassiveCsv.EFFECT_ATK})
				end

				local event = {condition = skillPassiveCsv.TRIGGER_DEAD, effect = skillPassiveCsv.EFFECT_CHUI_SI}
				self:triggerPassiveSkill(event)
				if event.returnValue then
					self.hp = 1
					self:onHurt({ origHp = origHp, hurtValue = hurtValue , effect = params.effect, restraint = params.restraint})
					return false
				end

				if self.dreamKill then
					self:doEvent("ToDreamKill")

					-- 保存值
					self.dreamKill_attacker = params.attacker
					self.dreamKill_params = { origHp = origHp, hurtValue = hurtValue , effect = params.effect, restraint = params.restraint}
					return true
				end
				
				if self:isState("skillAttack") then
					self:onLeaveSkillAttack()
				end
				self:doEvent("BeKilled")

				-- 每击杀一个敌人触发
				if params.attacker then
					params.attacker:triggerPassiveSkill({condition = skillPassiveCsv.TRIGGER_KILL_ENEMY, effect = skillPassiveCsv.EFFECT_CRIT})

					params.attacker:triggerPassiveSkill({condition = skillPassiveCsv.TRIGGER_KILL_ENEMY, effect = skillPassiveCsv.EFFECT_RECOVER_HP})
				end
			else
				self.hp = origHp - hurtValue

				-- 僵直状态
				if hurtValue / self.maxHp >= globalCsv:getFieldValue("damagedFloor") / 100 and self:getState() ~= "frozen" and self:getState() ~= "dizzy" then
					self:doEvent("BeDamaged")
				end

				local hurtFrom = params.hurtFrom or 1

				-- 受到技能攻击时
				if hurtFrom == 2 then
					-- 剩余血量低于25%触发
					self:triggerPassiveSkill({
						condition = skillPassiveCsv.TRIGGER_HP_LESS_SKILL, 
						effect = skillPassiveCsv.EFFECT_GLOBAL_HEAL,
						triggerEvent = function (value)
							return self.hp < self.maxHp * value / 100
						end,
						hurtValue = hurtValue})
				end

				-- 受到伤害时
				self:triggerPassiveSkill({condition = skillPassiveCsv.TRIGGER_ANY_HURT, effect = skillPassiveCsv.EFFECT_ANGER_INCRE})
			end
		else
			if self.hp - hurtValue >= self.maxHp then
				self.hp = self.maxHp
			else
				self.hp = origHp - hurtValue
			end
		end
	end

	self:onHurt({ origHp = origHp, hurtValue = hurtValue , effect = params.effect, restraint = params.restraint})

	return self.hp <= 0	-- true表示已经被杀死
end

function Soldier:changeAttribute(params)
	local attrName = "cur" .. params.name
	self[attrName] = self[attrName] + params.value
end

function Soldier:beingMove(params)
	self.position.x = params.beginX + params.offset.x
	self.position.y = params.beginY + params.offset.y

	self:onMove(params)
end

function Soldier:beingForceMove(params)
	self.forceMoveTargetPos = self.displayNode:getParent():convertToNodeSpace(params.targetPos)
	self:doEvent("BeginForceMove")
end

function Soldier:pause(bool)
	self.hasPaused = bool
	if self.canPause then self:onPause(bool) end
end

-- onXXX() 都是子类需要实现的, 比如客户端的特效释放等

function Soldier:onMove(params)
end

function Soldier:onStandby(params)
end

function Soldier:onAttack(params)
end

function Soldier:checkAttackStatus(params)
end

function Soldier:onSkillAttack(params)
end

function Soldier:onHurt(params)
end

function Soldier:onDeath(params)
end

function Soldier:onFrozen(params)
end

function Soldier:onDizzy(params)
end

function Soldier:onHypnosis(params)
end

function Soldier:onDamaged(params)
end

function Soldier:onFoceMove(params)
end

function Soldier:onFoceAttack(params)
end

function Soldier:onPause(bool)
end

function Soldier:onEffect(effect)
end

function Soldier:onChangeAttribute(params)
end

function Soldier:onLeaveSkillAttack(params)
end

-- 清除武将的一些特效
function Soldier:clearStatus()
	if not self:isState("standby") and not self:isState("dead") then
		self:doEvent("ToIdle")
	end

	-- 上场后, 身上携带的组合技
	self.associationSkills = {}

	-- 被作用的buff
	for i=1, self.buffs.size() do
		local buff = self.buffs.indexAt(i)
		buff:dispose(self)
	end
	self.buffs = list_newList()

	self.skillCd = 0
	self.hasPaused = false

	self.shieldDamage = 0
end

-- 是否在流血（中毒）
function Soldier:isBleeding()
	for i=1, self.buffs.size() do
		local buff = self.buffs.indexAt(i)
		if buff.csvData.type == 4 then
			return true
		end
	end
	return false
end

function Soldier:hasBuff(buffType)
	for i=1, self.buffs.size() do
		local buff = self.buffs.indexAt(i)
		if buff.csvData.type == buffType then
			return true, buff
		end
	end
	return false
end

-- 删除debuff
function Soldier:removeDebuff()
	local i = 1
	while i <= self.buffs.size() do
		local buff = self.buffs.indexAt(i)
		if buff.csvData.debuff == 1 then
			buff:dispose(self)
			
			-- 眩晕结束
			if buff.csvData.type == 16 then
				if self:getState() == "dizzy" then
					self:doEvent("ToIdle")
				end
			-- 冰冻结束
			elseif buff.csvData.type == 17 then
				if self:getState() == "frozen" then
					self.animation:resume()
					-- 恢复冰冻之前的状态
					self:doEvent("ToIdle")
				end
			elseif buff.csvData.type == 27 then
				if self:getState() == "deepSleep" then
					self:doEvent("ToIdle")
				end
			end

			self.buffs.remove(i)
		else
			i = i + 1
		end
	end
end

-- 删除深度睡眠debuff
function Soldier:removeDeepSleepDebuff()
	local i = 1
	while i <= self.buffs.size() do
		local buff = self.buffs.indexAt(i)
		if buff.csvData.type == 27 then
			buff:dispose(self)

			if self:getState() == "deepSleep" then
				self:doEvent("ToIdle")
			end

			self.buffs.remove(i)
		else
			i = i + 1
		end
	end
end


function Soldier:dispose()
	for i=1, self.buffs.size() do
		local buff = self.buffs.indexAt(i)
		buff:dispose(self)
	end
	self.buffs = list_newList()
end

return Soldier