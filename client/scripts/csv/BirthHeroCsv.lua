local BirthHeroCsvData = {
	m_data = {}
}

function BirthHeroCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)

	for line = 1, #csvData do
		local id = tonum(csvData[line]["id"])
		if id > 0 then
			self.m_data[id] = {
				id = id,
				type = tonum(csvData[line]["武将ID"]),
				initLevel = tonum(csvData[line]["初始等级"]),
				heroDesc = csvData[line]["武将描述"],
				skillName = csvData[line]["技能名称"],
				skillDesc = csvData[line]["技能描述"],
			}
		end
	end
end

function BirthHeroCsvData:getHeroById(id)
	return self.m_data[id]	
end

return BirthHeroCsvData