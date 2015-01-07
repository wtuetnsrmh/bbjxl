local Hero = class("Hero")

Hero.pbField = { "id", "roleId", "type", "level", "exp", "choose", "createTime", "evolutionCount", "master", "skillLevelJson", "wakeLevel", "star", "battleSoulJson" }
-- 职业名常数
Hero.ProfessionName = { [1] = "步兵", [3] = "骑兵", [4] = "弓兵", [5] = "军师" }
-- 阵营常数
Hero.CampName = { [1] = "群", [2] = "魏", [3] = "蜀", [4] = "吴" }

Hero.__index = function (self, key)
	local v = rawget(self, key .. "_ed")
	if v then
		return MemDecrypt(v)
	else
		return Hero[key]
	end
end

Hero.__newindex = function (self, key, value)
	if type(value) == "number" then
		rawset(self, key .. "_ed", MemEncrypt(value))
	else
		rawset(self, key, value)
	end
end

function Hero:ctor(pbSource)
	require("framework.api.EventProtocol").extend(self)
	
	self:loadFromPbData(pbSource)
	self.skillLevels = json.decode(self.skillLevelJson)
	self.battleSoul = json.decode(self.battleSoulJson) or {}
	self.attrsJson=pbSource.attrsJson or {}

	-- 配表数据
	self.unitData = unitCsv:getUnitByType(self.type)
end

function Hero:loadFromPbData(pbData)
	for _,property in pairs(self.class.pbField) do
		self[property] = pbData[property]
	end
end

-- 根据强化等级和进化次数计算的基础值
-- @params level 	强化等级
-- @params evolutionCount 进化次数
-- @params wakeLevel 觉醒等级
function Hero:getBaseAttrValues(level, evolutionCount, wakeLevel, star)
	local level = level and level or self.level
	local evolutionCount = evolutionCount and evolutionCount or self.evolutionCount
	local wakeLevel = wakeLevel and wakeLevel or self.wakeLevel
	local star = star and star or self.star

	return Hero.sGetBaseAttrValues(self.type, level, evolutionCount, wakeLevel, star)
end

function Hero.sGetBaseAttrValues(type, level, evolutionCount, wakeLevel, star)
	local unitData = unitCsv:getUnitByType(type)

	local hpBase = unitData.hp + (level - 1) * unitData.hpGrowth
	local atkBase = unitData.attack + (level - 1) * unitData.attackGrowth
	local defBase = unitData.defense + (level - 1) * unitData.defenseGrowth

	local hpFactor, atkFactor, defFactor = evolutionModifyCsv:getModifies(evolutionCount)
	local starFactor = globalCsv:getFieldValue("starFactor")[star or 1]
	local attrs = { hp = hpBase * (hpFactor + starFactor - 1), atk = atkBase * (atkFactor + starFactor - 1), def = defBase * (defFactor + starFactor - 1) }
	for key, value in pairs(EquipAttEnum) do
		if not attrs[key] then
			attrs[key] = unitData[key] or 0
		end
	end
	return attrs
end

-- 得到武将的总属性 chooseHeros:选中的武将
function Hero:getTotalAttrValues(baseValues, chooseHeros)
	local assistantBonus = {}		-- 副将加成
	local techBonus = {}			-- 科技加成
	local starBonus = {}			-- 星魂加成
	local beautyBonus = {}			-- 美人加成
	local equipAttrs = {}			-- 装备加成
	local relationAttrs = {}		-- 情缘加成

	local basicValues = baseValues or self:getBaseAttrValues()

	local slot
	if chooseHeros then
		slot = table.keyOfItem(chooseHeros, self.id)
	end

	techBonus = Hero.sGetProfessionBonusValues(basicValues, self.type)
	techBonus.hp = techBonus.hpBonus
	techBonus.atk = techBonus.atkBonus
	techBonus.def = techBonus.defBonus

	starBonus = Hero.sGetStarSoulBonusValues(self.type)
	starBonus.hp = starBonus.hpBonus
	starBonus.atk = starBonus.atkBonus
	starBonus.def = starBonus.defBonus

	beautyBonus = Hero.sGetBeautyBonusValues()
	beautyBonus.hp = beautyBonus.hpBonus
	beautyBonus.atk = beautyBonus.atkBonus
	beautyBonus.def = beautyBonus.defBonus
	

	--装备
	equipAttrs = slot and Hero.sGetEquipAttrs(slot) or self:getEquipAttrs(basicValues)
	--情缘
	relationAttrs = slot and Hero.sGetRelationBonusValues(slot, chooseHeros, basicValues) or self:getRelationBonusValues(basicValues)
	--战魂
	local battleSoulAttrs = self:getBattleSoulAttrs()

	attrs = {}
	for key, value in pairs(EquipAttEnum) do
		attrs[key] = math.floor((basicValues[key] or 0) + (assistantBonus[key] or 0) + (techBonus[key] or 0) 
					+ (starBonus[key] or 0) + (beautyBonus[key] or 0) + (equipAttrs[key] or 0) + (relationAttrs[key] or 0) + (battleSoulAttrs[key] or 0))
	end

	return attrs
end

-- 根据职业加成计算属性加成值
function Hero.sGetProfessionBonusValues(baseValues, type)
	local unitData = unitCsv:getUnitByType(type)
	local bonuses = game.role:getProfessionBonus(unitData.profession)

	return { hpBonus = baseValues.hp * bonuses[3] / 100, atkBonus = baseValues.atk * bonuses[1] / 100, 
		defBonus = baseValues.def * bonuses[2] / 100 }
end

-- 根据星魂计算阵营加成值
function Hero.sGetStarSoulBonusValues(type)
	local allBonuses = game.role:calStarAttrBonuses()

	local unitData = unitCsv:getUnitByType(type)
	local professionBonuses = allBonuses[unitData.camp]

	return { hpBonus = professionBonuses.hpBonus or 0, atkBonus = professionBonuses.atkBonus or 0, 
		defBonus = professionBonuses.defBonus or 0 }
end

-- 武将作为副将，某个属性的贡献值
function Hero:assistantContribution(master, attrName)
	local techBonus = {}			-- 科技加成
	local starBonus = {}			-- 星魂加成
	local beautyBonus = {}			-- 美人加成

	local basicValues = self:getBaseAttrValues()
	techBonus = Hero.sGetProfessionBonusValues(basicValues, self.type)
	techBonus.hp = techBonus.hpBonus
	techBonus.atk = techBonus.atkBonus
	techBonus.def = techBonus.defBonus

	starBonus = Hero.sGetStarSoulBonusValues(self.type)
	starBonus.hp = starBonus.hpBonus
	starBonus.atk = starBonus.atkBonus
	starBonus.def = starBonus.defBonus

	beautyBonus = Hero.sGetBeautyBonusValues()
	beautyBonus.hp = beautyBonus.hpBonus
	beautyBonus.atk = beautyBonus.atkBonus
	beautyBonus.def = beautyBonus.defBonus

	local totalValue = {}
	totalValue.hp = basicValues.hp + techBonus.hp + starBonus.hp + beautyBonus.hp
	totalValue.atk = basicValues.atk + techBonus.atk + starBonus.atk + beautyBonus.atk
	totalValue.def = basicValues.def + techBonus.def + starBonus.def + beautyBonus.def

	local attrIds = { ["atk"] = 1, ["def"] = 2, ["hp"] = 3}
	local assistantAttr = assistantHeroCsv:getAssistantHeroInfoById(attrIds[attrName])
	local bonusFactor = assistantAttr["evolutionMap" .. self.evolutionCount][tostring(self.unitData.stars)]
	local attrBonus = totalValue[attrName] * tonumber(bonusFactor) / 100

	local skillFactor = master.unitData.assistantSkill_index[self.unitData.type]
	local skillBonus = 0
	-- 存在组合技
	if skillFactor then
		skillBonus = skillFactor * attrBonus / 100
	end

	return attrBonus, skillBonus
end

-- 装备属性加成
function Hero:getEquipAttrs(baseValues, equips)
	local slot = game.role:getHeroSlot(self.id) 
	return Hero.sGetEquipAttrs(slot, equips)
end

-- 装备属性加成
function Hero.sGetEquipAttrs(slot, equips)
	equips = equips or totable(game.role.slots[tostring(slot)]).equips or {}
	
	local attrs = {}
	local sets = {}

	for _, equipId in pairs(equips) do
		local equip = game.role.equips[equipId]
		local equipAttrs = equip:getBaseAttributes()
		--基础属性
		for key, value in pairs(EquipAttEnum) do
			attrs[key] = (attrs[key] or 0) + equipAttrs[key]
		end
		--套装
		if equip.csvData.setId ~= 0 then		
			sets[equip.csvData.setId] = (sets[equip.csvData.setId] or 0) + 1
		end
	end

	--套装效果
	for setId, count in pairs(sets) do
		if count >= 2 then
			count = math.min(count, 4)
			local setCsv = equipSetCsv:getDataById(setId)
			for effectCnt = 2, count do
				for key, value in pairs(EquipAttEnum) do
					attrs[key] = (attrs[key] or 0) + (setCsv["effect" .. effectCnt][value] or 0)
				end
			end
		end
	end 

	return attrs
end

function Hero:getRelationBonusValues(baseValues)
	local relationAttrs = {}
	if not self.relation then
		return relationAttrs
	end

	if not baseValues then
		baseValues = self:getBaseAttrValues()
	end

	
	for _, relation in pairs(self.relation) do
		for index = 1, #relation[3] do			
			local key = table.keyOfItem(EquipAttEnum, relation[3][index])
			if key then
				relationAttrs[key] = (relationAttrs[key] or 0) + (baseValues[key] or 0) * relation[4][index] / 100 + relation[5][index]
			end
		end
	end
	return relationAttrs
end

--slot为必须
function Hero.sGetRelationBonusValues(slot, chooseHeros, basicValues)
	local relationAttrs = {}
	local slotData = totable(game.role.slots[tostring(slot)])
	local heroId = slotData.heroId
	if not heroId then
		return relationAttrs
	end

	local hero = game.role.heros[heroId]
	if not hero or not hero.unitData.relation then
		return relationAttrs
	end
	
	if not baseValues then
		baseValues = hero:getBaseAttrValues()
	end

	--herotype集合
	local heroTypes = {}
	if chooseHeros then
		for _, heroId in pairs(chooseHeros) do
			local hero = game.role.heros[heroId]
			if hero then 
				table.insert(heroTypes, hero.type)
			end
		end
	else
		for _, value in pairs(game.role.slots) do
			local hero = game.role.heros[value.heroId]
			if hero then 
				table.insert(heroTypes, hero.type)
			end
		end
	end

	for _, heroType in pairs(game.role.partners) do
		if not heroType or heroType ~= 0 then
			table.insert(heroTypes, heroType)
		end
	end

	--equiptype集合
	local equips = slotData.equips or {}
	local equipTypes = {}
	for _, equipId in pairs(equips) do
		table.insert(equipTypes, game.role.equips[equipId].type)
	end

	--得到激活的情缘
	local activeRelation = {}
	for _, relation in pairs(hero.unitData.relation) do
		if relation[1] == 1 and table.contain(heroTypes, relation[2]) then
			table.insert(activeRelation, relation)
		elseif relation[1] == 2 and table.contain(equipTypes, relation[2]) then
			table.insert(activeRelation, relation)
		end
	end

	--计算情缘加成
	for _, relation in pairs(activeRelation) do
		for index = 1, #relation[3] do			
			local key = table.keyOfItem(EquipAttEnum, relation[3][index])
			if key then
				relationAttrs[key] = (relationAttrs[key] or 0) + (baseValues[key] or 0) * relation[4][index] / 100 + relation[5][index]
			end
		end
	end
	return relationAttrs
end

function Hero.sGetBeautyBonusValues(beauties)
	local beauties = (beauties or game.role.beauties) or {}

	local STATUS_INACTIVE = 0 		-- 未激活
	local STATUS_NON_EMPLOY = 1 	-- 未招募
	local STATUS_REST = 2 			-- 休息
	local STATUS_FIGHT = 3     	-- 战斗

	-- 出战美人
	local hpBonus,atkBonus,defBonus = 0,0,0
	for _,beauty in pairs(beauties) do
		if beauty.status == STATUS_FIGHT or beauty.status == STATUS_REST then --beauty.class.STATUS_FIGHT
			local beautyData = beautyListCsv:getBeautyById(beauty.beautyId)
			local curBeautyLevel = beauty.level + (beauty.evolutionCount - 1) * beautyData.evolutionLevel

			local hpAdd = ( beautyData.hpInit + beautyData.hpGrow * (curBeautyLevel - 1 ) + beauty.potentialHp ) * globalCsv:getFieldValue("beautyHpFactor")
			local atkAdd = ( beautyData.atkInit + beautyData.atkGrow * (curBeautyLevel - 1 ) + beauty.potentialAtk ) * globalCsv:getFieldValue("beautyAtkFactor")
			local defAdd = ( beautyData.defInit + beautyData.defGrow * (curBeautyLevel - 1 ) + beauty.potentialDef ) * globalCsv:getFieldValue("beautyDefFactor")

			hpBonus  = math.floor(hpBonus + hpAdd)
			atkBonus = math.floor(atkBonus + atkAdd)
			defBonus = math.floor(defBonus + defAdd)
		end
	end
	return {hpBonus = hpBonus, atkBonus = atkBonus, defBonus = defBonus}
end

function Hero:getBattleSoulAttrs()
	local attrs = {hp = 0, atk = 0, def = 0}
	--先加上以前累积的
	for evolCount = 1, self.evolutionCount do
		local resources = self.unitData["evolMaterial" .. evolCount]
		for _, itemId in ipairs(resources) do
			local id = itemId - battleSoulCsv.toItemIndex
			local data = battleSoulCsv:getDataById(id)
			if data then
				attrs.hp = attrs.hp + data.hp
				attrs.atk = attrs.atk + data.atk
				attrs.def = attrs.def + data.def
			end
		end
	end

	local resources = self.unitData["evolMaterial" .. (self.evolutionCount + 1)]
	if resources then
		--再加上现在镶嵌的
		for slot in pairs(self.battleSoul) do
			local itemId = resources[tonum(slot)]
			local id = tonum(itemId) - battleSoulCsv.toItemIndex
			local data = battleSoulCsv:getDataById(id)
			if data then
				attrs.hp = attrs.hp + data.hp
				attrs.atk = attrs.atk + data.atk
				attrs.def = attrs.def + data.def
			end
		end
	end
	return attrs
end

-- 等级升级所需总经验
function Hero:getLevelExp(level)
	return heroExpCsv:getLevelUpExp(level)
end

-- 等级升级所需总经验
function Hero:getLevelTotalExp()
	return self:getLevelExp(self.level)
end

-- 得到升级所需剩余经验
function Hero:getLevelUpExp()
	return self:getLevelExp(self.level) - self.exp
end

-- 得到升到角色满级的所需总经验
function Hero:getLevelMaxExp()
	local roleLevel = game.role.level
	local heroLevel = self.level

	if roleLevel >= heroLevel then
		local totalExp = self:getLevelUpExp()
		for index = heroLevel, roleLevel-1 do
			totalExp = totalExp + self:getLevelExp(index)
		end
		return totalExp
	end
end

-- 得到出售武将所得钱
function Hero:getSellMoney(onlyExp)
	local totalExp = 0
	for level = 1, self.level - 1 do
		totalExp = totalExp + self:getLevelExp(level)
	end
	totalExp = totalExp + self.exp
	local money = totalExp * globalCsv:getFieldValue("moneyPerExp")
	return onlyExp and money or money + self.unitData.sellMoney
end

-- 得到吃掉经验后的卡等级和经验
function Hero:getLevelAfterExp(exp)
	if not exp or exp <= self:getLevelUpExp() then return self.level, self.exp + exp end

	local ret = 0
	exp = exp - self:getLevelUpExp()
	while exp > 0 do
		ret = ret + 1
		exp = exp - self:getLevelExp(self.level + ret)
	end

	local retExp = self.exp + exp
	if ret > 0 then
		retExp = exp + self:getLevelExp(self.level + ret)
	else
		retExp = exp + self:getLevelUpExp()
	end

	local retLevel = self.level + ret
	if retLevel > game.role.level then
		retLevel = game.role.level
		retExp = self:getLevelExp(retLevel)
	end
	return retLevel, retExp
end

-- 判断武将的等级和经验是否已满
function Hero:isLevelAndExpFull()
	if self.level == game.role.level and self.exp == self:getLevelTotalExp() then
		return true
	end
	return false
end

function Hero:canEvolution()
	local evolutionData = evolutionModifyCsv:getEvolutionByEvolution(self.evolutionCount + 1)

	if self.evolutionCount >= evolutionModifyCsv:getEvolMaxCount() then return false end

	return table.nums(self.battleSoul) >= 6
end

function Hero:canBattleSoul()
	if self:canEvolution() then
		return false
	end

	local resources = self.unitData["evolMaterial" .. (self.evolutionCount + 1)]
	if resources then
		for slot, itemId in ipairs(resources) do
			local soulId = itemId - battleSoulCsv.toItemIndex
			local csvData = battleSoulCsv:getDataById(soulId)
			if not self.battleSoul[tostring(slot)] and csvData and csvData.requireLevel <= self.level then
				local item = game.role.items[itemId]
				local itemNum = item and item.count or 0
				if itemNum > 0  or battleSoulCsv:canCompose(soulId) then
					return true
				end
			end
		end
	end

	return false
end

function Hero:canWakeup()
	-- local wakeCsvData = heroWakeCsv:getByHeroStar(self.unitData.stars)
	-- if wakeCsvData.wakeLevelMax <= self.wakeLevel then return false end

	-- if unitCsv:getUnitByType(self.type).stars<3 then return false end

	-- local costFragment = wakeCsvData.costHeroFragment[self.wakeLevel + 1]
	-- local fragmentId = math.floor(self.type + 2000)
	-- local curFragment = game.role.fragments[fragmentId] or 0

	-- return curFragment >= costFragment
	return false
end

function Hero:canStarUp()
	if self:isStarMax() then
		return false
	end
	local costFragment = globalCsv:getFieldValue("starUpFragment")[self.star + 1]
	local fragmentId = math.floor(self.type + 2000)
	local curFragment = game.role.fragments[fragmentId] or 0
	return curFragment >= costFragment
end

function Hero:canSkillUp(skillIds)
	if not skillIds then
		skillIds = {self.unitData.talentSkillId}
		for index = 1, 3 do
			table.insert(skillIds, self.unitData["passiveSkill" .. index] + 10000)
		end
	end

	for _, skillId in pairs(skillIds) do
		local skillLevel = tonum(self.skillLevels[tostring(skillId)])
		if skillLevel > 0 then		
			local skillData, skillLevelData
			if skillId > 10000 then
				skillData = skillPassiveCsv:getPassiveSkillById(skillId - 10000)
				skillLevelData = skillPassiveLevelCsv:getDataByLevel(skillId - 10000, skillLevel + 1)
			else
				skillData = skillCsv:getSkillById(skillId)
				skillLevelData = skillLevelCsv:getDataByLevel(skillId, skillLevel + 1)
			end

			local conditionOk = true
			if skillLevel < skillData.levelLimit then
				local items = skillLevelData.items or {}
				for index, itemData in pairs(items) do
					local itemId = tonum(itemData[1])
					local num = tonum(itemData[2])
					local itemCount = game.role.items[itemId] and game.role.items[itemId].count or 0

					if itemCount < num then
						conditionOk = false
						break
					end
				end
			end

			if conditionOk and self.level < skillLevelData.openLevel then
				conditionOk = false
			end

			if conditionOk then
				return true
			end
		end
	end

	return false
end


-- 得到此卡的祭司经验
function Hero:getWorshipExp()
	local level = self.level
	local totalExp = self.unitData.worshipExp - tonum(self.unitData.worshipExpGrowth[1][3])
	for _,value in ipairs(self.unitData.worshipExpGrowth) do 
		local min = tonum(value[1])
		local max = tonum(value[2])
		local add = tonum(value[3])

		if level >= min and level <= max then
			totalExp = totalExp + (level - (min-1)) * add
		elseif level > max then
			totalExp = totalExp + (max - (min-1)) * add
		end
	end
	return totalExp
end

-- 得到此卡的祭司金币
function Hero:getWorshipMoney()
	return self:getWorshipExp() * globalCsv:getFieldValue("intensifyGoldNum")
end

-- 得到此卡作为进化材料时作为资源卡的个数
function Hero:getEvolutionCardNum()
	local evolutionData = evolutionModifyCsv:getEvolutionByEvolution(self.evolutionCount)

	local i = 1
	for j = 1, self.evolutionCount do
		i = i + tonum(evolutionData.cardNeed[""..j])
	end
	return i
end

-- 进化到下一个等级时所需的资源卡
function Hero:getEvolutionCardNeedNum()
	if self.evolutionCount >= evolutionModifyCsv:getEvolMaxCount() then return 0 end

	local nextEvolution = self.evolutionCount + 1
	local evolutionData = evolutionModifyCsv:getEvolutionByEvolution(self.evolutionCount)
	local cardNeed = tonum(evolutionData.cardNeed[""..nextEvolution])

	return cardNeed
end

function Hero:getAssistantSkillName(assistantHeroId)
	for index = 1, 3 do
		if assistantHeroId == tonum(self.unitData["assistant" .. index][1]) then
			return self.unitData["assistantSkillName" .. index]
		end
	end
	return nil
end

function Hero:initSkillData()
end

function Hero:set_choose(newChoose)
	self.choose = tonumber(newChoose)
	self:dispatchEvent({ name = "updateChoose", choose = self.choose })
end

function Hero:set_level(newLevel)
	self.level = tonumber(newLevel)
	self:dispatchEvent({name = "updateLevel", level = self.level})
end

function Hero:set_exp(newExp)
	self.oldExpPercentage = self.exp / self:getLevelTotalExp() * 100
	self.exp = tonumber(newExp)
	self:dispatchEvent({name = "updateExp", exp = self.exp})
end

function Hero:set_skillLevelJson(newSkillLevelJson)
	self.skillLevelJson = newSkillLevelJson
	self.skillLevels = json.decode(newSkillLevelJson)
end

function Hero:set_battleSoulJson(newBattleSoulJson)
	self.battleSoulJson = newBattleSoulJson
	self.battleSoul = json.decode(newBattleSoulJson) or {}
end

function Hero:set_master(newMaster)
	self.master = tonumber(newMaster)
	self:dispatchEvent({ name = "updateMaster", master = self.master })
end

function Hero:set_skillLevel(newSkillLevel)
	self.skillLevel = tonumber(newSkillLevel)
	self:dispatchEvent({ name = "skillLevel", skillLevel = self.skillLevel })
end

function Hero:set_star(newStar)
	self.star = tonumber(newStar)
end

-- 更新属性的接口
function Hero:updateProperty(property, value)
	local method = self["set_" .. property]
	if type(method) ~= "function" then
        print("ERROR_PROPERTY_SETTING_METHOD", property)
    end

    method(self, value)
end

-- 得到主动技和3个被动技的ID
function Hero:getAllSkillIds()
	local skillIds = {}
	if self.unitData.talentSkillId > 0 then
		skillIds["1"] = self.unitData.talentSkillId
	end

	local evolutionCount = self.evolutionCount
	if evolutionCount < globalCsv:getFieldValue("passiveSkillLevel1") then
		skillIds["2"] = -self.unitData.passiveSkill1
		skillIds["3"] = -self.unitData.passiveSkill2
		skillIds["4"] = -self.unitData.passiveSkill3
	elseif evolutionCount >= globalCsv:getFieldValue("passiveSkillLevel1") and
		evolutionCount < globalCsv:getFieldValue("passiveSkillLevel2") then
		if self.unitData.passiveSkill1 > 0 then
			skillIds["2"] = self.unitData.passiveSkill1
		end
		skillIds["3"] = -self.unitData.passiveSkill2
		skillIds["4"] = -self.unitData.passiveSkill3
	elseif evolutionCount >= globalCsv:getFieldValue("passiveSkillLevel2") and
		evolutionCount < globalCsv:getFieldValue("passiveSkillLevel3") then
		if self.unitData.passiveSkill1 > 0 then
			skillIds["2"] = self.unitData.passiveSkill1
		end
		if self.unitData.passiveSkill2 > 0 then
			skillIds["3"] = self.unitData.passiveSkill2
		end
		skillIds["4"] = -self.unitData.passiveSkill3
	elseif evolutionCount >= globalCsv:getFieldValue("passiveSkillLevel3") then
		if self.unitData.passiveSkill1 > 0 then
			skillIds["2"] = self.unitData.passiveSkill1
		end
		if self.unitData.passiveSkill2 > 0 then
			skillIds["3"] = self.unitData.passiveSkill2
		end
		if self.unitData.passiveSkill3 > 0 then
			skillIds["4"] = self.unitData.passiveSkill3
		end
	end

	return skillIds
end

function Hero:addExp(deltaValue)
    local currentExp = self.exp
    local upLevelExp = self:getLevelTotalExp()

    local nowExp = currentExp + deltaValue
    while nowExp > upLevelExp do

        if self.level == game.role.level then
            nowExp = nowExp > upLevelExp and upLevelExp or nowExp
            break
        end

        nowExp = nowExp - upLevelExp
        self.level = self.level + 1
        self.exp = 0

        upLevelExp = self:getLevelTotalExp()
    end
    self.exp = nowExp
end

--是否满星
function Hero:isStarMax()
	return self.star >= HERO_MAX_STAR
end

--名称
function Hero:getHeroName(evolutionCount) 
	evolutionCount = uihelper.getShowEvolutionCount(evolutionCount or self.evolutionCount)
	return evolutionCount > 0 and string.format("%s+%d", self.unitData.name, evolutionCount) or self.unitData.name
end

return Hero