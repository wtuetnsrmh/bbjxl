local NameNonCsvData = {
	m_data = {},
}

function NameNonCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local id = tonum(csvData[index]["敏感字ID"])
		local level = tonumber(csvData[index]["级别"])
		if id > 0 and (level == 4 or level == 5) then
			self.m_data[id] = {
				id = id ,
				name = tostring(csvData[index]["敏感字"]),
			}
		end
	end
end

function NameNonCsvData:getNameByID(id)

	return self.m_data[tonumber(id)].name
end

function NameNonCsvData:getAllData()
	return self.m_data
end




return NameNonCsvData