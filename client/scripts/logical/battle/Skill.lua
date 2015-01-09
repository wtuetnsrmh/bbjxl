local Skill = class("Skill")

function Skill:ctor(params)
	self.owner = params.owner	-- 技能所有者
	self.battle = self.owner.battle 	-- 战斗
	self.battleField = params.battleField	-- 战场
	self.camp = self.owner.camp
	self.startPosition = self.owner.position

	-- 技能自身属性
	self.id = params.id or 0
	self.csvData = skillCsv:getSkillById(self.id)
	-- 技能等级
	self.level = self.owner.skillLevels[tostring(params.passive and self.id + 10000 or self.id)] or 1

	self.finished = false	-- 是否结束

	self.reflections = {
		bullet = params.bulletDef or "logical.battle.Bullet",
	}

	self.bullet = require(self.reflections["bullet"]).new({ id = self.csvData.bulletId, skill = self, usage = 2 })

	self.atkTimesTable = {}
end

-- 根据作用对象和中心横坐标筛选的对象
function Skill:getEffectObjects()
	local soldiers = {}
	local ownerCamp = self.owner.camp

	-- 敌方
	if self.csvData.effectObject == 1 then
		if self.csvData.effectXPos == 0 then
			soldiers = self.battleField:getCampObjects(ownerCamp == "left" and "right" or "left")
		else
			local enemy = self.battleField:getXposEnemy(self.owner, self.csvData.effectXPos)
			if enemy and not enemy:isState("dead") then
				table.insert(soldiers, enemy)
			end
		end

	-- 自己
	elseif self.csvData.effectObject == 2 then
		table.insert(soldiers, self.owner)

	-- 己方包括自己
	elseif self.csvData.effectObject == 3 then
		if self.csvData.effectXPos == 0 then
			soldiers = self.battleField:getCampObjects(ownerCamp)
		else
			local teamer = self.battleField:getXposTeamer(self.owner, self.csvData.effectXPos)
			if teamer and not teamer:isState("dead") then
				table.insert(soldiers, teamer)
			end
		end
	end

	return soldiers
end

-- 根据作用范围类型和其他筛选条件确定的对象
function Skill:getRangeObjects()
	local soldiers = self:getEffectObjects()
	local rangeObjects = {}

	if #soldiers == 0  then return rangeObjects end

	-- 单体
	if self.csvData.effectRangeType == 1 then
		table.insert(rangeObjects, soldiers[1])

	-- x轴直线
	elseif self.csvData.effectRangeType == 2 then
		for _, soldier in ipairs(soldiers) do
			if soldier.anchPoint.y == self.owner.anchPoint.y then
				table.insert(rangeObjects, soldier)
			end
		end

	-- y轴纵向攻击
	elseif self.csvData.effectRangeType == 3 then
		-- 900像素的距离
		local distanceObjects = self.battleField:getBeforeRangeObjects(self.owner, soldiers, 900)
		if #distanceObjects > 0 then
			self.skillCenter = soldiers[1]
			rangeObjects = self.battleField:getSideObjects(soldiers[1])
		end

	-- 全体
	elseif self.csvData.effectRangeType == 4 then
		rangeObjects = soldiers

	-- 前2排（从左往右）
	elseif self.csvData.effectRangeType == 5 then
		rangeObjects = self.battleField:getNearObjects(soldiers[1])

	-- 后2排（从右往左）
	elseif self.csvData.effectRangeType == 6 then
		rangeObjects = self.battleField:getNearObjects(soldiers[1])
	end

	return self:filterEffectObjects(rangeObjects)
end

-- 根据附加条件筛选的对象
function Skill:filterEffectObjects(rangeObjects)
	if table.nums(rangeObjects) == 0 then return {} end

	-- 职业过滤
	local professionObjects = {}
	for _, soldier in ipairs(rangeObjects) do
		if self.csvData.effectObjProfession == 0 then
			table.insert(professionObjects, soldier)
		elseif self.csvData.effectObjProfession == soldier.unitData.profession then
			table.insert(professionObjects, soldier)
		end
	end

	if table.nums(professionObjects) == 0 then return {} end

	-- 阵营过滤
	local campObjects = {}
	for _, soldier in ipairs(professionObjects) do
		if self.csvData.effectObjCamp == 0 then
			table.insert(campObjects, soldier)
		elseif self.csvData.effectObjCamp == soldier.unitData.camp then
			table.insert(campObjects, soldier)
		end
	end

	if table.nums(campObjects) == 0 then return {} end

	-- 属性过滤
	local attrObjects = {}
	if self.csvData.effectObjAttr == 0  then
		attrObjects = campObjects
	-- 攻击力最高
	elseif self.csvData.effectObjAttr == 1 then
		table.sort(campObjects, function(a, b) return a.curAttack > b.curAttack end )
		table.insert(attrObjects, campObjects[1])
	-- 生命值最低
	elseif self.csvData.effectObjAttr == 2 then
		table.sort(campObjects, function(a, b) return a.hp / a.maxHp < b.hp / b.maxHp end )
		table.insert(attrObjects, campObjects[1])
	-- 防御力最高
	elseif self.csvData.effectObjAttr == 3 then
		table.sort(campObjects, function(a, b) return a.curDefense > b.curDefense end )
		table.insert(attrObjects, campObjects[1])
	-- 随机一个
	elseif self.csvData.effectObjAttr == 4 then
		local index = randomInt(1, #campObjects)
		table.insert(attrObjects, campObjects[index])
	end

	return attrObjects
end

--  技能对应的BUFF
function Skill:addBuffs(soldier)
	local buffSkill = false
	for _, buffId in ipairs(self.csvData.buffIds) do
		local ret = soldier:addBuff({ buffId = tonum(buffId), level = self.level, skill = self, addBuffProbability = self.owner.addBuffProbability })
		if ret then
			buffSkill = true
		end
	end

	return buffSkill
end

function Skill:onEffectLastSoldier()
	-- 攻击全体
	if self.csvData.effectRangeType == 4 then
		for k, buffId in ipairs(self.csvData.buffIds) do
			local buffCsvData = buffCsv:getBuffById(tonum(buffId))
			if buffCsvData then
				-- 增益buff
				if buffCsvData.debuff ~= 1 then
					-- 对方
					local opponents = self.battleField[self.owner.camp == "left" and "right" or "left" .. "SoldierMap"]
					opponents = opponents or {}
					for _, soldier in pairs(opponents) do
						local params = {condition = skillPassiveCsv.TRIGGER_AREA_OF_BUFF, effect = skillPassiveCsv.EFFECT_STEAL_BUFF}
	 					soldier:triggerPassiveSkill(params)
	 					if params.returnValue then
	 						soldier:addBuff({ buffId = tonum(buffId), level = self.level, skill = self })
	 					end
	 				end
				end
			end
		end
	end
end

function Skill:attackAgain(soldier)
	if self.atkTimesTable[soldier] > 0 then
		self.atkTimesTable[soldier] = self.atkTimesTable[soldier] - 1
		local bullet = require(self.reflections["bullet"]).new({ id = self.csvData.bulletId, skill = self, usage = 2 })
		bullet:effect({soldier})
	end
end

function Skill:attackAgainGlobal(soldiers)
	if self.atkTimes > 0 then
		self.atkTimes = self.atkTimes - 1
		local bullet = require(self.reflections["bullet"]).new({ id = self.csvData.bulletId, skill = self, usage = 2 })
		bullet:effect(soldiers)
	end
end

function Skill:effect()
	local targets = self:getRangeObjects()

	-- 对于BUFF技能，持续时间和伤害次数，只针对BUFF生效，不针对技能子弹，技能子弹只播放一次
	local shouldAdd = false
	
	-- 横向技能不能立即作用buff, 需要伤害到对象, 再随机BUFF
	if self.csvData.effectRangeType == 2 then
		self.bullet:effect(targets)
		shouldAdd = true
	else
		-- 产生子弹并作用
		if self.csvData.bulletId ~= 0 then
			local atkTimes = self.csvData.atkTimes > 1 and self.csvData.atkTimes or 1
			atkTimes = atkTimes - 1
			if self.id == 109 or self.id == 1265 then
				local params = {condition = skillPassiveCsv.TRIGGER_SPECIFIC_SKILL, effect = skillPassiveCsv.EFFECT_ATK_TIMES,}
				self.owner:triggerPassiveSkill(params)
				if params.returnValue then
					atkTimes = atkTimes + 1
				end
			end
			self.atkTimes = atkTimes
			self.targets = targets
			for _, soldier in ipairs(targets) do
				--soldier.atkTimes = atkTimes
				self.atkTimesTable[soldier] = atkTimes
			end
			self.bullet:effect(targets)
		end

		-- 随机生成BUFF
		-- for _, soldier in ipairs(targets) do
		-- 	shouldAdd = not self:addBuffs(soldier)
		-- end

		-- 催眠
		if self.csvData.hypnosisPercent > 0 then
			local rate = self.csvData.hypnosisPercent + (self.level - 1) * self.csvData.hypnosisGrowth
			rate = rate * 10

			for _, soldier in ipairs(targets) do
				if randomInt(0, 1000) <= rate and not soldier:isState("hypnosis") then
					soldier:doEvent("ToHypnosis")
				end
			end
		end

		-- 控制技: 偷取攻击
		if self.csvData.stealAtkPercent > 0 then
			local perValue = self.csvData.stealAtkPercent + (self.level - 1) * self.csvData.stealAtkGrowth
			for _, soldier in ipairs(targets) do
				local stealAtk = (soldier.curAttack + soldier.stealAtk - soldier.stolenAtk) * perValue / 100
				soldier.stolenAtk = soldier.stolenAtk + stealAtk
				if soldier.stolenAtk > soldier.attack then soldier.stolenAtk = soldier.attack end

				soldier:onTextEffect({effect = "attr_Attack", value = - stealAtk})

				local maxAtk = self.owner.attack * 3
				local cc = self.owner:getCurAttack() + stealAtk - maxAtk
				if cc > 0 then
					self.owner.stealAtk = self.owner.stealAtk + stealAtk - cc
				else
					self.owner.stealAtk = self.owner.stealAtk + stealAtk
				end

				self.owner:onTextEffect({effect = "attr_Attack", value = stealAtk})
			end
		end

		-- 怒气消耗增加效果
		if self.csvData.angryCostPercent > 0 then
			local rate = self.csvData.angryCostPercent + (self.level - 1) * self.csvData.angryCostGrowth
			rate = rate * 10

			for _, soldier in ipairs(targets) do
				if randomInt(0, 1000) <= rate then
					soldier.angryExtraCost = soldier.angryExtraCost + 1
				end
			end
		end


		-- 驱散debuff
		if self.csvData.dispelDebuff == 1 then
			for _, soldier in ipairs(targets) do
				soldier:removeDebuff()
			end
		end
		
		-- 增加怒气
		if self.csvData.angryIncres > 0 then
			local incres = self.csvData.angryIncres + (self.level - 1) * self.csvData.angryIncresGrowth
			local campInstance = self.battleField[(self.camp == "left" and "left" or "right") .. "Camp"]
			campInstance:addAngryUnit(incres/100)
			self.owner:onTextEffect({effect = "anger", value = incres})
		end

	end
	if shouldAdd then
		self.battleField[self.camp .. "Camp"]:addSkill(self)
	end

	return true
end

-- 计算技能造成的伤害值
function Skill:calcHurtValue(soldier)
	-- 被动技能 释放伤害技能 加攻
	self.owner:triggerPassiveSkill({
		condition = skillPassiveCsv.TRIGGER_RELEASE_HURT_SKILL,
		effect = skillPassiveCsv.EFFECT_ATK,
		temp = true})

	soldier:triggerPassiveSkill({
		condition = skillPassiveCsv.TRIGGER_HURT_BY_SKILL,
		effect = skillPassiveCsv.EFFECT_DEFENSE,
		temp = true})

	if self.csvData.atkCoefficient > 0 then
		self.owner:triggerPassiveSkill({condition = skillPassiveCsv.TRIGGER_RELEASE_HURT_SKILL, effect = skillPassiveCsv.EFFECT_SKILL_HURT_INCRE})
	end

	-- 技能等级修正
	local atkCoefficient = self.csvData.atkCoefficient + (self.level - 1) * self.csvData.atkCoeffGrowth
	-- 阵营覆盖
	local camp = tostring(soldier.unitData.camp)
	if self.csvData.campModifies[camp] then
		atkCoefficient = tonum(self.csvData.campModifies[camp]) + (self.level - 1) * self.csvData.campGrowth
	end
	-- 职业覆盖
	local profession = tostring(soldier.unitData.profession)
	if self.csvData.professionModifies[profession] then
		atkCoefficient = tonum(self.csvData.professionModifies[profession]) + (self.level - 1) * self.csvData.professionGrowth
	end

	-- 治疗技能
	if atkCoefficient < 0 or self.csvData.buffCoefficient < 0 then
		self.owner:triggerPassiveSkill({condition = skillPassiveCsv.TRIGGER_SKILL_HEAL, effect = skillPassiveCsv.EFFECT_SKILL_HURT_INCRE})

		soldier:triggerPassiveSkill({
			condition = skillPassiveCsv.TRIGGER_HP_BUFF,
			effect = skillPassiveCsv.EFFECT_HEAL_MORE,
		})

		local hurtValue = self.owner:getCurAttack() * atkCoefficient * (1 + self.owner.curSkillHurtAddition) * ( 1 + soldier.curSkillCureAddition)
		return { enemy = hurtValue, self = 0, effect = "normal" }
	end

	-- 敌人可能有减免BUFF
	local attackValue = self.owner:getCurAttack() * (100 - soldier.curDerateOtherAtk) / 100
	local defense = soldier.curDefense
	local enemyDefense = defense / (attackValue * globalCsv:getFieldValue("k2") + defense * globalCsv:getFieldValue("k3"))

	-- 无视防御
	enemyDefense = self.csvData.ignoreDef and 0 or enemyDefense

	local atkConstant = self.csvData.atkConstant + (self.level - 1) * self.csvData.atkConstantGrowth
	local hurtValue = (attackValue * atkCoefficient * globalCsv:getFieldValue("k1") + atkConstant) * (1 - enemyDefense)
	-- 技能伤害加成计算
	hurtValue = hurtValue * (1 + self.owner.curSkillHurtAddition)

	if self.csvData.hurtTypeMap["1"] then
		local condition = tonumber(self.csvData.hurtTypeMap["1"])
		condition = condition + (self.level - 1) * self.csvData.hurtConGrowth
		if (soldier.hp / soldier.maxHp) < (condition / 100 ) then
			hurtValue = hurtValue * 5
		else
			hurtValue = hurtValue * 0.5
		end
	elseif self.csvData.hurtTypeMap["2"] then
		local condition = tonumber(self.csvData.hurtTypeMap["2"])
		condition = condition + (self.level - 1) * self.csvData.hurtConGrowth
		hurtValue = (self.owner.maxHp - self.owner.hp) * condition / 100
	end

	if self.id == 1232 and soldier:isBleeding() then
		hurtValue = hurtValue * 1.25
	end

	if self.id == 1234 and soldier:isBleeding() then
		soldier:addBuff({ buffId = 1237, level = self.level, skill = self })
	end

	return self:secondAttrEffect({ enemy = soldier, hurtValue = hurtValue })
end

-- 通过二次属性计算新的伤害值
function Skill:secondAttrEffect(params)
	params = params or {}

	local function triggerHurt(hurtValue)
		-- 施放者打出了伤害，触发嗜血
		self.owner:triggerPassiveSkill({
			condition = skillPassiveCsv.TRIGGER_HURT_BY_ATK,
			effect = skillPassiveCsv.EFFECT_BLOOD_ADBSORB,
			hurtValue = hurtValue})
	end

	-- 无敌判定
	if params.enemy.curInvincible and params.hurtValue > 0 then
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
	self.owner:triggerPassiveSkill(skillEvent)
	if skillEvent.returnValue then
		triggerHurt(params.enemy.hp)
		return { enemy = params.enemy.hp, self = 0 , effect = "deadly"}
	end

	local growthValue = (self.level - 1) * self.csvData.secondAttrGrowth

	local skillSecondAttrModifies = self.csvData.secondAttrModifies
	local hitBonus = skillSecondAttrModifies["1"] and (tonumber(skillSecondAttrModifies["1"]) + growthValue) or 0
	local ignoreParryBonus = skillSecondAttrModifies["2"] and (tonumber(skillSecondAttrModifies["2"]) + growthValue) or 0
	local critBonus = skillSecondAttrModifies["3"] and (tonumber(skillSecondAttrModifies["3"]) + growthValue) or 0
	local critHurtBonus = skillSecondAttrModifies["4"] and (tonumber(skillSecondAttrModifies["4"]) + growthValue) or 0

	local effect = "normal"
	local miss = math.min(math.max(globalCsv:getFieldValue("missFloor"), params.enemy.curMiss - self.owner.curHit - hitBonus), globalCsv:getFieldValue("missCeil"))
	if randomInt(0, 1000) <= miss then

		-- 闪避成功触发被动技能
		params.enemy:triggerPassiveSkill({condition = skillPassiveCsv.TRIGGER_MISS, effect = skillPassiveCsv.EFFECT_ATK})

		-- 闪避成功
		return { enemy = 0, self = 0, effect = "miss" }
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
	if self.owner.curRebound then
		return { enemy = 0, self = params.hurtValue , effect = "rebound"}
	end

	local enemyHurtValue, selfHurtValue = 0, 0
	local parry = math.min(math.max(globalCsv:getFieldValue("parryFloor"), params.enemy.curParry - self.owner.curIgnoreParry - ignoreParryBonus), globalCsv:getFieldValue("parryCeil"))	
	if randomInt(0, 1000) <= parry then
		-- 格挡成功
		enemyHurtValue = params.hurtValue * 0.6
		selfHurtValue = params.hurtValue * 0.4
		effect = "parry"

		-- 格挡成功触发被动技能
		params.enemy:triggerPassiveSkill({condition = skillPassiveCsv.TRIGGER_PARRY, effect = skillPassiveCsv.EFFECT_ABSORB_HURT,
			enemyHurtValue = enemyHurtValue})

	else
		local crit = math.min(math.max(globalCsv:getFieldValue("critFloor"), self.owner.curCrit + critBonus - params.enemy.curTenacity), globalCsv:getFieldValue("critCeil"))	
		if randomInt(0, 1000) <= crit then
			enemyHurtValue = params.hurtValue * (150 + self.owner.curCritHurt + critHurtBonus) / 100
			effect = "crit"

			-- 暴击触发
			self.owner:triggerPassiveSkill({condition = skillPassiveCsv.TRIGGER_CRIT, effect = skillPassiveCsv.EFFECT_CRIT})
		else
			enemyHurtValue = params.hurtValue
		end
	end

	triggerHurt(enemyHurtValue)
	return { enemy = enemyHurtValue, self = selfHurtValue, effect = effect }
end

-- 技能更新
function Skill:update(diff)
	if not self.bullet then return end

	local targets = self:getRangeObjects()
	self.finished = self.bullet:effect(targets)
end

function Skill:onShow(params)
end

function Skill:onBeginEffect(params)
end

function Skill:dispose()
end

return Skill