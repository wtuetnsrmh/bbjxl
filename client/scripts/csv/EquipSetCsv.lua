local EquipSetCsvData = {
	m_data = {},
}

function EquipSetCsvData:load(fileName)
	self.m_data = {}
	
	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local setId = tonum(csvData[index]["套装id"])

		if setId ~= 0 then
			self.m_data[setId] = {
				id = setId,
				name = csvData[index]["套装名"],
				equipIds = string.toArray(csvData[index]["套装部件"], "=", true),
				effect2 = string.toNumMap(csvData[index]["2件效果"]),
				effect3 = string.toNumMap(csvData[index]["3件效果"]),
				effect4 = string.toNumMap(csvData[index]["4件效果"]),
			}
		end
	end
end

function EquipSetCsvData:getDataById(id)
	return self.m_data[id]
end

return EquipSetCsvData