-- 被动技能配表解析
-- by yangkun
-- 2014.2.8

require("utils.StringUtil")

local SkillPassiveCsvData = {
	m_data = {}
}

-- 触发条件
SkillPassiveCsvData.TRIGGER_NONE = 1
SkillPassiveCsvData.TRIGGER_ATK_BY_PROFESSION = 2
SkillPassiveCsvData.TRIGGER_ATK_BY_CAMP = 3
SkillPassiveCsvData.TRIGGER_ATK_PROFESSION = 4
SkillPassiveCsvData.TRIGGER_ATK_CAMP = 5
SkillPassiveCsvData.TRIGGER_RELEASE_SKILL = 6
SkillPassiveCsvData.TRIGGER_RELEASE_HURT_SKILL = 7
SkillPassiveCsvData.TRIGGER_HURT_BY_SKILL = 8
SkillPassiveCsvData.TRIGGER_HP_BUFF = 9
SkillPassiveCsvData.TRIGGER_DEBUFF = 10
SkillPassiveCsvData.TRIGGER_ATK_SEX = 11
SkillPassiveCsvData.TRIGGER_HP_LESS = 12
SkillPassiveCsvData.TRIGGER_PROFESSION = 13
SkillPassiveCsvData.TRIGGER_CAMP = 14
SkillPassiveCsvData.TRIGGER_SKILL = 50
SkillPassiveCsvData.TRIGGER_MISS = 16
SkillPassiveCsvData.TRIGGER_PARRY = 17
SkillPassiveCsvData.TRIGGER_BEFORE_ATK = 18
SkillPassiveCsvData.TRIGGER_KILL_ENEMY = 19
SkillPassiveCsvData.TRIGGER_HP_LESS_SKILL = 20
SkillPassiveCsvData.TRIGGER_ANY_HURT = 21
SkillPassiveCsvData.TRIGGER_ENEMY_HP_LESS = 22
SkillPassiveCsvData.TRIGGER_SKILL_HEAL = 23
SkillPassiveCsvData.TRIGGER_CRIT = 24
SkillPassiveCsvData.TRIGGER_DEAD = 25
SkillPassiveCsvData.TRIGGER_HURT_BY_ATK = 27
SkillPassiveCsvData.TRIGGER_OUR_DEAD = 28
SkillPassiveCsvData.TRIGGER_AREA_OF_BUFF = 29
SkillPassiveCsvData.TRIGGER_HURT_IN_PROTECT_BUFF = 31
SkillPassiveCsvData.TRIGGER_SPECIFIC_SKILL = 80

-- 技能效果
SkillPassiveCsvData.EFFECT_ATK = 1
SkillPassiveCsvData.EFFECT_DEFENSE = 2
SkillPassiveCsvData.EFFECT_HP = 3
SkillPassiveCsvData.EFFECT_CRIT = 4
SkillPassiveCsvData.EFFECT_TENACITY = 5
SkillPassiveCsvData.EFFECT_CRIT_HURT = 6
SkillPassiveCsvData.EFFECT_MISS = 7
SkillPassiveCsvData.EFFECT_HIT = 8
SkillPassiveCsvData.EFFECT_PARRY = 9
SkillPassiveCsvData.EFFECT_IGNORE_PARRY = 10
SkillPassiveCsvData.EFFECT_RESIST = 11
SkillPassiveCsvData.EFFECT_HURT_LESS = 12
SkillPassiveCsvData.EFFECT_IMMUNITY = 13
SkillPassiveCsvData.EFFECT_ANGRY_LESS = 14
SkillPassiveCsvData.EFFECT_HEAL_MORE = 15
SkillPassiveCsvData.EFFECT_SKILL = 16
SkillPassiveCsvData.EFFECT_HURT_INCRE = 17
SkillPassiveCsvData.EFFECT_DOUBLE_HURT = 18
SkillPassiveCsvData.EFFECT_ANGER_SPEEDUP = 19
SkillPassiveCsvData.EFFECT_GLOBAL_HEAL = 20
SkillPassiveCsvData.EFFECT_ANGER_INCRE = 21
SkillPassiveCsvData.EFFECT_DEADLY_KILL = 22
SkillPassiveCsvData.EFFECT_RANDOM_HURT = 23
SkillPassiveCsvData.EFFECT_BOUNCE_HURT = 24
SkillPassiveCsvData.EFFECT_ABSORB_HURT = 25
SkillPassiveCsvData.EFFECT_ATK_SPEEDUP = 26
SkillPassiveCsvData.EFFECT_SKILL_HURT_INCRE = 27
SkillPassiveCsvData.EFFECT_BLOOD_ADBSORB = 28
SkillPassiveCsvData.EFFECT_CHUI_SI = 29
SkillPassiveCsvData.EFFECT_RESURGENCE = 30
SkillPassiveCsvData.EFFECT_RECOVER_HP = 31
SkillPassiveCsvData.EFFECT_ATK_TIMES = 32
SkillPassiveCsvData.EFFECT_STEAL_BUFF = 33
SkillPassiveCsvData.EFFECT_BUFF_PROBABILITY = 34
SkillPassiveCsvData.EFFECT_ADD_ANGER = 35
SkillPassiveCsvData.EFFECT_BOUNCE_PROTECT_HURT = 36


function SkillPassiveCsvData:load(fileName) 
	local csvData = CsvLoader.load(fileName)

	self.m_data = {}

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
		local passiveSkillId = tonum(csvData[index]["被动技能ID"])

		if passiveSkillId > 0 then 
			
			local data = setmetatable({}, meta)
				-- 基本信息
			data.skillId = passiveSkillId
			data.name = csvData[index]["被动技能名称"]
			data.desc = csvData[index]["被动技能描述"]
			data.secondDesc = string.toTableArray(csvData[index]["辅助描述"], " ")
			data.levelLimit = tonum(csvData[index]["可升等级"])

			data.triggerMap = string.tomap(csvData[index]["触发条件"], " ")
			data.effectMap = string.tomap(csvData[index]["技能效果"], " ")
			data.effectGrowth = string.tomap(csvData[index]["效果成长"], " ")
			data.bulletId = tonum(csvData[index]["子弹"])
			data.icon = csvData[index]["技能icon"]
			data.nameRes = csvData[index]["技能名显示"]
			data.musicId = tonum(csvData[index]["音效id"])
			data.hasFootHalo = tonum(csvData[index]["是否取消脚底光圈"])
			self.m_data[passiveSkillId] = data
		end
	end
end

function SkillPassiveCsvData:getPassiveSkillById(passiveSkillId)
	return self.m_data[passiveSkillId]
end

function SkillPassiveCsvData:getDescByLevel(passiveSkillId, level)
	if not self.m_data[passiveSkillId] then return "" end

	local formatArgs = {}
	for _, array in ipairs(self.m_data[passiveSkillId].secondDesc) do
		formatArgs[tonum(array[1])] = tonum(array[2]) + (level - 1) * tonum(array[3])
	end

	return string.format(self.m_data[passiveSkillId].desc, unpack(formatArgs))
end

return SkillPassiveCsvData
