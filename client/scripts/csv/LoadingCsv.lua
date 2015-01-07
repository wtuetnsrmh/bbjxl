local LoadingCsvData = {
	m_data = {}
}

function LoadingCsvData:load(fileName)
	self.m_data = {}
	
	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local id = tonum(csvData[index]["id"])
		if id > 0 then
			self.m_data[id] = {
				id = id,
				type = tonum(csvData[index]["类型"]),
				image = csvData[index]["图片路径"],
				weight = tonum(csvData[index]["权重"]),
				desc = csvData[index]["说明文字"],
				heroTypes = string.toArray(csvData[index]["武将id"], " ", true),
			}
		end
	end
end

function LoadingCsvData:randLoadingTips()
	local randomId = randWeight(self.m_data)

	return self.m_data[randomId]
end

function LoadingCsvData:randHero(id)
	local data = self.m_data[id]
	if data then
		local index = math.random(1, #data.heroTypes)
		return data.heroTypes[index]
	else
		local unitWeights = unitCsv:getUnitWeightArray( { starWeights = { ["1"] = 1, ["2"] = 1, ["3"] = 1 } })
		local randomIndex = randWeight(unitWeights)
		return unitWeights[randomIndex].itemId
	end
end

return LoadingCsvData