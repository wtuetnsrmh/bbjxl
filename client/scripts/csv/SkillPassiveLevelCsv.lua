local SkillPassiveLevelCsvData = {
	m_data = {}
}

function SkillPassiveLevelCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local level = tonum(csvData[index]["等级"])
		if level > 0 then
			self.m_data[level] = self.m_data[level] or {}

			self.m_data[level].items = string.toTableArray(csvData[index]["需要材料"])
			self.m_data[level].money = tonum(csvData[index]["需要银币"])
			self.m_data[level].openLevel = tonum(csvData[index]["需求等级"])
		end
	end	
end

function SkillPassiveLevelCsvData:getDataByLevel(skillId, level)
	return self.m_data[level]
end

return SkillPassiveLevelCsvData