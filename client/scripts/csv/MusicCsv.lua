local MusicCsvData = {
	m_data = {},
}

function MusicCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local id = tonum(csvData[index]["id"])

		if id > 0 then
			self.m_data[id] = {
				type = tonum(csvData[index]["类型"]),
				isLoop = tonum(csvData[index]["是否循环"]),
				res = csvData[index]["资源"],
			}
		end
	end
end

function MusicCsvData:getMusicData(id)
	return self.m_data[id]
end

return MusicCsvData