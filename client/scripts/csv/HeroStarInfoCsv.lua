local HeroStarInfoCsvData = {
	m_data = {}
}

function HeroStarInfoCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)
	for line = 1, #csvData do
		local type = tonum(csvData[line]["将星图ID"])
		if type > 0 then
			self.m_data[type] = {
				type = type,
				name = csvData[line]["将星图名称"],
				nameRes = csvData[line]["将星图名资源"],
				numberRes = csvData[line]["将星图名资源2"],
				bgRes = csvData[line]["将星图资源"],
			}
		end
	end
end

function HeroStarInfoCsvData:getDataByType(type)
	return self.m_data[type]
end

return HeroStarInfoCsvData