local BirthItemCsvData = {
	m_data = {}
}

function BirthItemCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)

	for line = 1, #csvData do
		local itemId = tonum(csvData[line]["道具ID"])
		if itemId > 0 then
			self.m_data[itemId] = {
				num = tonum(csvData[line]["数量"])
			}
		end
	end
end

return BirthItemCsvData