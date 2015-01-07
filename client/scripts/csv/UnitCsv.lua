require("utils.StringUtil")

ProfessionName = { [1] = "bu", [3] = "qi", [4] = "gong", [5] = "jun" }
CampName = { [1] = "qun", [2] = "wei", [3] = "shu", [4] = "wu" }
EvolutionThreshold = {1, 3, 6, 11, math.huge}

local UnitCsvData = {
	m_data = {},
}

local function readRelation(str)
	local array = {}
	local tempArray = string.split(string.trim(str), " ")
	for _, value in ipairs(tempArray) do
		local trimValue = string.trim(value)
		if trimValue ~= "" then
			value = string.split(trimValue, "=")
			for index, value2 in ipairs(value) do
				if index == 6 then
					value[index] = value2
				elseif index == 1 then
					value[index] = tonum(value2)
				else
					value[index] = string.toArray(string.trim(value2), ";", true)
				end
			end
			table.insert(array, value)
		end
	end
	return array
end

function UnitCsvData:load(fileName)
	self.m_data = {}
	
	local csvData = CsvLoader.load(fileName)

	local meta = {}
	meta.__index = function (self, key)
		local v = rawget(self, key .. "_ed")
		if v then
			return MemDecrypt(v)
		else
			return meta[key]
		end
	end

	meta.__newindex = function (self, key, value)
		if type(value) == "number" then
			rawset(self, key .. "_ed", MemEncrypt(value))
		else
			rawset(self, key, value)
		end
	end

	for index = 1, #csvData do
		local type = tonum(csvData[index]["武将ID"])
		if type > 0 then
			local data = setmetatable({}, meta)
			data.type = tonum(csvData[index]["武将ID"])
			data.name = csvData[index]["武将名称"]
			data.camp = tonum(csvData[index]["阵营"])
			data.profession = tonum(csvData[index]["职业ID"])
			data.professionName = csvData[index]["职业名称"]
			data.stars = tonum(csvData[index]["星级"])
			data.skillLevelGrowth = tonum(csvData[index]["技能等级提升"])
			data.hp = tonum(csvData[index]["初始生命"])
			data.attack = tonum(csvData[index]["初始攻击"])
			data.defense = tonum(csvData[index]["初始防御"])
			data.hpGrowth = tonum(csvData[index]["生命成长"])
			data.attackGrowth = tonum(csvData[index]["攻击成长"])
			data.defenseGrowth = tonum(csvData[index]["防御成长"])
			-- begin 二级属性
			data.miss = tonum(csvData[index]["初始闪避"])
			data.hit = tonum(csvData[index]["初始命中"])
			data.parry = tonum(csvData[index]["初始格挡"])
			data.ignoreParry = tonum(csvData[index]["初始破击"])
			data.crit = tonum(csvData[index]["初始暴击"])
			data.tenacity = tonum(csvData[index]["初始韧性"])
			data.critHurt = tonum(csvData[index]["初始爆伤"])
			data.resist = tonum(csvData[index]["初始抵抗"])
			-- end
			data.moveSpeed = tonum(csvData[index]["移动速度"])
			data.atkSpeedFactor = tonum(csvData[index]["攻击速度"])
			data.atcRange = tonum(csvData[index]["攻击距离"])
			data.talentSkillId = tonum(csvData[index]["必杀技ID"])
			data.talentSkillCd = tonum(csvData[index]["必杀技CD"])
			data.desc = csvData[index]["武将简介"]
			data.headImage = csvData[index]["头像资源"]
			data.heroRes = csvData[index]["人物资源"]
			data.cardRes = csvData[index]["卡牌资源"]
			data.boneResource = csvData[index]["骨骼动画"]
			data.boneActXml = csvData[index]["骨骼动作文件"]
			data.boneRatio = tonum(csvData[index]["骨骼比例"]) == 0 and 100 or tonum(csvData[index]["骨骼比例"])
			data.skillAnimateName = csvData[index]["通用模型技能动作"]
			data.boneEffectResource = csvData[index]["骨骼特效"]
			data.boneEffectRatio = tonum(csvData[index]["骨骼特效比例"]) == 0 and 100 or tonum(csvData[index]["骨骼特效比例"])
			data.sex = tonum(csvData[index]["性别"])
			data.passiveSkill1 = tonum(csvData[index]["被动技能1"])
			data.passiveSkill2 = tonum(csvData[index]["被动技能2"])
			data.passiveSkill3 = tonum(csvData[index]["被动技能3"])
			data.firstTurn = string.split(string.trim(csvData[index]["首轮顺序"]), "=")
			data.cycleTurn = string.split(string.trim(csvData[index]["循环顺序"]), "=")
			data.atkBullteId = tonum(csvData[index]["普攻子弹ID"])
			data.skillMusicId = tonum(csvData[index]["技能配音ID"])
			data.actionTable = csvData[index]["动作配表"]
			data.scale = tonum(csvData[index]["比例"])
			data.weight = tonum(csvData[index]["权值"])
			data.dropPlace = tonum(csvData[index]["掉落区域"])
			data.fragmentId = tonum(csvData[index]["碎片ID"])
			data.exchangeSoulNum = tonum(csvData[index]["兑换所需将魂"])
			data.heroOpen = tonum(csvData[index]["图鉴开关"])
			data.relation = readRelation(csvData[index]["情缘"])
			for i=1, math.huge do
				local str = csvData[index][string.format("进化%d材料", i)]
				if str == "" then break end
				data["evolMaterial" .. tostring(i)] = string.toArray(str, " ", true)
			end
			self.m_data[type] = data
		end
	end
end

function UnitCsvData:getUnitByType( type )
	return self.m_data[type]
end

-- 用修正权重取出所有的武将权重信息
function UnitCsvData:getUnitWeightArray(params)
	local result = {}

	local defaultProfessionWeights = { ["1"] = 1, ["3"] = 1, ["4"] = 1, ["5"] = 1 }
	local defaultCampWeights = { ["1"] = 1, ["2"] = 1, ["3"] = 1, ["4"] = 1 }
	local defaultStarWeights = { ["1"] = 1, ["2"] = 1, ["3"] = 1, ["4"] = 1, ["5"] = 1}
	local dropPlace = params.dropPlace or 0

	local function reCalWeight(inputWeights, default)
		if not inputWeights or table.nums(inputWeights) == 0 then return default end

		local weights = {}
		for key, value in pairs(inputWeights) do
			if tonum(value) > 0 then
				table.insert(weights, { key = key, weight = tonum(value) })
			end
		end

		local randomIndex = randWeight(weights)
		return { [weights[randomIndex].key] = weights[randomIndex].weight }
	end

	local professionWeights = reCalWeight(params.professionWeights, defaultProfessionWeights)
	local campWeights = reCalWeight(params.campWeights, defaultCampWeights)
	local starWeights = reCalWeight(params.starWeights, defaultStarWeights)
	for type, value in pairs(self.m_data) do
		if dropPlace == 0 or value.dropPlace == 0 or value.dropPlace == dropPlace then
			local weight = value.weight * tonum(starWeights[tostring(value.stars)])
					* tonum(professionWeights[tostring(value.profession)])
					* tonum(campWeights[tostring(value.camp)])
			if weight > 0 then
				result[#result + 1] = {itemId = type, weight = weight}
			end
		end
	end

	return result
end

function UnitCsvData:formatRelationDesc(relation)
	local desc
	if relation[1] == 1 then
		local name = ""
		for index2, heroType in ipairs(relation[2]) do
			if index2 ~= 1 then name = name .. "，" end
			local heroUnitData = self:getUnitByType(heroType)
			name = name .. heroUnitData.name
		end
		desc = string.format("与%s同时上阵", name)
	elseif relation[1] == 2 then
		local name = ""
		for index2, equipType in ipairs(relation[2]) do
			if index2 ~= 1 then name = name .. "，" end
			local equipData = equipCsv:getDataByType(equipType)
			name = name .. equipData.name
		end
		desc = string.format("装备%s时", name)
	end

	local attrDesc = ""
	for index = 1, #relation[3] do
		attrDesc = attrDesc .. "，"
		attrDesc = attrDesc .. EquipAttName[relation[3][index]] .. "提升"
		if relation[4][index] ~= 0 then
			attrDesc = attrDesc .. relation[4][index] .. "%"
		else
			attrDesc = attrDesc .. relation[5][index] .. "点"
		end
	end
		
	desc = desc .. attrDesc
	return desc
end

function UnitCsvData:isExpCard(type)
	return type >= 991 and type <= 994 
end

function UnitCsvData:isMoneyCard(type)
	return type >= 995 and type <= 999 
end

return UnitCsvData