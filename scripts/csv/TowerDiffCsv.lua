local TowerDiffCsvData = {
	m_data = {}
}

function TowerDiffCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local difficult = tonum(csvData[index]["难度ID"])
		if difficult > 0 then
			self.m_data[difficult] = {
				difficult = difficult,
				name = csvData[index]["难度"],
				hpModify = tonum(csvData[index]["生命修正"]),
				atkModify = tonum(csvData[index]["攻击修正"]),
				defModify = tonum(csvData[index]["防御修正"]),
				starModify = tonum(csvData[index]["星级修正"]),
				scene1Ids = string.toArray(csvData[index]["场景ID1"]),
				scene2Ids = string.toArray(csvData[index]["场景ID2"]),
				scene3Ids = string.toArray(csvData[index]["场景ID3"]),
				scene4Ids = string.toArray(csvData[index]["场景ID4"]),
				scene5Ids = string.toArray(csvData[index]["场景ID5"]),
				scene6Ids = string.toArray(csvData[index]["场景ID6"]),
			}
		end
	end
end

function TowerDiffCsvData:getDiffData(difficult)
	return self.m_data[difficult]
end

return TowerDiffCsvData