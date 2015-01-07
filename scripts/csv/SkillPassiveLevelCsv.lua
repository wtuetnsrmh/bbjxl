local SkillPassiveLevelCsvData = {
	m_data = {}
}

function SkillPassiveLevelCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local skillId = tonum(csvData[index]["技能id"])
		local level = tonum(csvData[index]["等级"])
		if skillId > 0 then
			self.m_data[skillId] = self.m_data[skillId] or {}
			self.m_data[skillId][level] = self.m_data[skillId][level] or {}

			self.m_data[skillId][level].items = string.toTableArray(csvData[index]["需要材料"])
			self.m_data[skillId][level].money = tonum(csvData[index]["需要银币"])
			self.m_data[skillId][level].openLevel = tonum(csvData[index]["需求等级"])
		end
	end	
end

function SkillPassiveLevelCsvData:getDataByLevel(skillId, level)
	if not self.m_data[skillId] then return nil end

	return self.m_data[skillId][level]
end

return SkillPassiveLevelCsvData