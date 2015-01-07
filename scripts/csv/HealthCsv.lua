local HealthCsvData = {
	m_data = {},
}

function HealthCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local id = tonum(csvData[index]["id"])
		if id > 0 then
			self.m_data[id] = {
				id = id,
				name = tostring(csvData[index]["名称"]),
				ttype = tostring(csvData[index]["道具类型"]),
				time = tostring(csvData[index]["时间"]),
				condition = tostring(csvData[index]["条件参数"]),
				givenum = tostring(csvData[index]["体力赠送"]),
			}
		end
	end
end

function HealthCsvData:getDataByIndex(index)
	return self.m_data[tonumber(index)]
end

return HealthCsvData