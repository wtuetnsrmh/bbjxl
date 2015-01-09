local ActivityTipsCsvData = {
	m_data = {},
}

function ActivityTipsCsvData:load(fileName)
	self.m_data = {}
	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local id = tonum(csvData[index]["id"])

		if id ~= 0 then
			self.m_data[id] = {
				id = id,
				title = csvData[index]["副本名"],
				awardItems = string.toArray(csvData[index]["奖励"], " ", true),
				desc = csvData[index]["阵容"],
			}
		end
	end
end

function ActivityTipsCsvData:getDataById(id)
	return self.m_data[id]
end

return ActivityTipsCsvData