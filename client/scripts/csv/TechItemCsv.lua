local TechItemCsvData = {
	m_data = {},
}

function TechItemCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local mapId = tonum(csvData[index]["地图ID"])
		if mapId > 0 then
			self.m_data[mapId] = {
				mapId = mapId,
				awardStarNums = string.tomap(csvData[index]["星星数"]),
				award1 = string.tomap(csvData[index]["奖励1"]),
				award2 = string.tomap(csvData[index]["奖励2"]),
				award3 = string.tomap(csvData[index]["奖励3"]),
			}
		end
	end
end

function TechItemCsvData:getDataByMap(mapId)
	return self.m_data[mapId]
end

return TechItemCsvData