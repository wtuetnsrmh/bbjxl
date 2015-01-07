local CarbonSceneCsvData = {
	m_data = {},
	m_stage_index = {},
	m_bosses = {},	-- 各个阶段有boss
}

function CarbonSceneCsvData:load(fileName)
    self.m_data = {}
	self.m_stage_index = {}
	self.m_bosses = {}

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
	
	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local id = tonum(csvData[index]["id"])

		local stage = tonum(csvData[index]["阶段"])
		if id ~= 0 then
			local data = setmetatable({}, meta)
			data.id = id
			data.x = tonum(csvData[index]["x"])
			data.y = tonum(csvData[index]["y"])
			data.heroType = tonum(csvData[index]["武将ID"])
			data.heroName = csvData[index]["武将名称"]
			data.professionName = csvData[index]["职业名称"]
			data.multGrid = tonum(csvData[index]["多格"])
			data.boss = tonum(csvData[index]["BOSS"])
			data.hasSkill = tonum(csvData[index]["是否放技能"]) == 1
			data.skillLevel = tonum(csvData[index]["技能等级"])
			data.startSkillCdTime = tonum(csvData[index]["技能初始CD"])
			data.skillCdTime = tonum(csvData[index]["技能CD"])
			data.skillWeight = tonum(csvData[index]["技能权值"])
			data.evolutionCount = tonum(csvData[index]["进化等级"])
			data.stage = stage == 0 and 1 or stage	-- 默认值为1
			data.hp = tonum(csvData[index]["生命"])
			data.attack = tonum(csvData[index]["攻击"])
			data.defense = tonum(csvData[index]["防御"])
			data.moveSpeed = tonum(csvData[index]["移动速度"])
			data.atkSpeedFactor = tonum(csvData[index]["攻击速度"])
			data.atcRange = tonum(csvData[index]["攻击距离"])
			-- 二级属性
			data.hit = tonum(csvData[index]["命中"])
			data.miss = tonum(csvData[index]["闪避"])
			data.parry = tonum(csvData[index]["格挡"])
			data.ignoreParry = tonum(csvData[index]["破击"])
			data.crit = tonum(csvData[index]["暴击"])
			data.critHurt = tonum(csvData[index]["爆伤"])
			data.resist = tonum(csvData[index]["抵抗"])
			data.tenacity = tonum(csvData[index]["韧性"])
			
			data.skillId = tonum(csvData[index]["技能ID"])
			data.flix = tonum(csvData[index]["面向"])
			data.scale = tonum(csvData[index]["比例"])
			self.m_data[id] = data

			if self.m_data[id].boss == 1 then
				self.m_bosses[self.m_data[id].stage] = self.m_data[id]
			end

			self.m_stage_index[self.m_data[id].stage] = self.m_stage_index[self.m_data[id].stage] or {}
			table.insert(self.m_stage_index[self.m_data[id].stage], self.m_data[id])
		end
	end
end

function CarbonSceneCsvData:getStageSceneData(stage)
	return self.m_stage_index[stage]
end

function CarbonSceneCsvData:getStageBoss(stage)
	return self.m_bosses[stage]
end

function CarbonSceneCsvData:getSceneDataById(id)
	return self.m_data[id]
end

return CarbonSceneCsvData