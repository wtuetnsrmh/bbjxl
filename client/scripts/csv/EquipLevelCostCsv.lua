local EquipLevelCostCsvData = {
	m_data = {},
}

function EquipLevelCostCsvData:load(fileName)
	self.m_data = {}
	
	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local level = tonum(csvData[index]["等级"])

		if level ~= 0 then
			self.m_data[level] = {
				level = level,
				cost = string.toNumMap(csvData[index]["升级价格"]),
				sellMoney = string.toNumMap(csvData[index]["累计价格"]),
			}
		end
	end
end

function EquipLevelCostCsvData:getDataByLevel(level)
	return self.m_data[level]
end

return EquipLevelCostCsvData