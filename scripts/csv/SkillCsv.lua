require("utils.StringUtil")

local SkillCsvData = {
	m_data = {},
}

function SkillCsvData:load(fileName)
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
		local skillId = tonum(csvData[index]["技能ID"])
		local hurtCount = tonum(csvData[index]["伤害次数"])
		
		if skillId > 0 then
			
			local data = setmetatable({}, meta)
			data.skillId = skillId
			data.type = tonum(csvData[index]["技能类型"])
			data.name = csvData[index]["技能名称"]
			data.desc = csvData[index]["技能描述"]
			data.secondDesc = string.toTableArray(csvData[index]["辅助描述"])
			data.levelLimit = tonum(csvData[index]["可升等级"])
			data.star = csvData[index]["技能星级"]
			data.angryUnitNum = tonum(csvData[index]["消耗"])
			data.atkTimes = tonum(csvData[index]["攻击次数"])
			data.effectRangeType = tonum(csvData[index]["作用范围类型"])
			data.effectObject = tonum(csvData[index]["作用对象"])
			data.effectXPos = tonum(csvData[index]["作用中心横坐标"])
			data.effectObjProfession = tonum(csvData[index]["作用对象职业"])
			data.effectObjCamp = tonum(csvData[index]["作用对象阵营"])
			data.effectObjAttr = tonum(csvData[index]["作用对象属性"])
			data.campModifies = string.tomap(csvData[index]["效果阵营覆盖"])
			data.campGrowth = tonum(csvData[index]["阵营覆盖成长"])
			data.professionModifies = string.tomap(csvData[index]["效果职业覆盖"])
			data.professionGrowth = tonum(csvData[index]["职业覆盖成长"])
			data.secondAttrModifies = string.tomap(csvData[index]["二级属性临时变更"])
			data.secondAttrGrowth = tonum(csvData[index]["临时变更成长"])
			data.atkCoefficient = tonum(csvData[index]["攻击系数"])
			data.atkCoeffGrowth = tonum(csvData[index]["攻击系数成长"])
			data.atkConstant = tonum(csvData[index]["攻击常数"])
			data.atkConstantGrowth = tonum(csvData[index]["攻击常数成长"])
			data.buffCoefficient = tonum(csvData[index]["中毒系数"])
			data.buffCoeffGrowth = tonum(csvData[index]["中毒系数成长"])
			data.buffConstant = tonum(csvData[index]["中毒常数"])
			data.buffConstantGrowth = tonum(csvData[index]["中毒常数成长"])
			data.keepTime = tonum(csvData[index]["持续时间"])
			data.hurtCount = hurtCount == 0 and 1 or hurtCount
			data.ignoreDef = tonum(csvData[index]["无视防御"]) == 1
			data.hypnosisPercent = tonum(csvData[index]["催眠"])
			data.hypnosisGrowth = tonum(csvData[index]["催眠成长"])
			data.suckHpPercent = tonum(csvData[index]["吸血百分比"])
			data.suckHpGrowth = tonum(csvData[index]["吸血成长"])
			data.stealAtkPercent = tonum(csvData[index]["攻击偷取"])
			data.stealAtkGrowth = tonum(csvData[index]["攻击偷取成长"])
			data.angryCostPercent = tonum(csvData[index]["增加怒气消耗"])
			data.angryCostGrowth = tonum(csvData[index]["增加怒气消耗成长"])
			data.angryIncres = tonum(csvData[index]["怒气值增加"])
			data.angryIncresGrowth = tonum(csvData[index]["怒气值增加成长"])
			data.hurtTypeMap = string.tomap(csvData[index]["伤害类型"], " ")
			data.hurtConGrowth = tonum(csvData[index]["伤害效果成长"])
			data.dispelDebuff = tonum(csvData[index]["驱散debuff"])
			data.bulletId = tonum(csvData[index]["技能子弹"])
			data.buffIds = string.split(string.trim(csvData[index]["BUFF ID"]), " ")
			data.showPic = csvData[index]["技能展示图片"]
			data.audio = csvData[index]["技能音效"]
			data.icon = csvData[index]["技能icon"]
			data.cardResource = csvData[index]["技能卡牌资源"]
			data.jump = tonum(csvData[index]["浮空"]) == 1
			self.m_data[skillId] = data
		end
	end
end

function SkillCsvData:getSkillById(skillId)
	return self.m_data[skillId]
end

function SkillCsvData:getDescByLevel(skillId, level)
	if not self.m_data[skillId] then return "" end

	local formatArgs = {}
	for _, array in ipairs(self.m_data[skillId].secondDesc) do
		formatArgs[tonum(array[1])] = tonum(array[2]) + (level - 1) * tonum(array[3])
	end

	return string.format(self.m_data[skillId].desc, unpack(formatArgs))
end

return SkillCsvData