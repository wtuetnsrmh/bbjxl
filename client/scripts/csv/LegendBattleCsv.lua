local LegendBattleCsvData = {
	m_data = {},
}

function LegendBattleCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)

	for line = 1, #csvData do
		local carbonId = tonum(csvData[line]["副本id"])
		if carbonId > 0 then
			self.m_data[carbonId] = self.m_data[carbonId] or {}

			self.m_data[carbonId].carbonId = carbonId
			self.m_data[carbonId].openDate = toDateArray(csvData[line]["开放日期"])
			self.m_data[carbonId].heroType = tonum(csvData[line]["武将id"])
			self.m_data[carbonId].heroName = csvData[line]["武将名"]
			self.m_data[carbonId].difficult = csvData[line]["难度"]
			self.m_data[carbonId].heroLevels = string.tomap(csvData[line]["武将等级"])
			self.m_data[carbonId].otherHeroLevels = string.tomap(csvData[line]["小兵等级"])
			self.m_data[carbonId].background1 = csvData[line]["场景背景"]
			self.m_data[carbonId].battleCsv1 = csvData[line]["场景id"]
			self.m_data[carbonId].background2 = csvData[line]["场景背景2"]
			self.m_data[carbonId].battleCsv2 = csvData[line]["场景id2"]
			self.m_data[carbonId].background3 = csvData[line]["场景背景3"]
			self.m_data[carbonId].battleCsv3 = csvData[line]["场景id3"]
			self.m_data[carbonId].fragmentIds = string.toTableArray(csvData[line]["碎片掉落"])
			self.m_data[carbonId].money = tonum(csvData[line]["游戏币奖励"])
			self.m_data[carbonId].weight = tonum(csvData[line]["权值"])
		end
	end
end

function LegendBattleCsvData:getOpenCarbonId()
	local openCarbons = {}
	local now = game:nowTime()
	for carbonId, carbonData in pairs(self.m_data) do
		if carbonData.openDate[1] <= now and carbonData.openDate[2] >= now then
			table.insert(openCarbons, carbonData)
		end
	end

	local index = randWeight(openCarbons)
	if not index then return 0 end

	return openCarbons[index].carbonId
end

function LegendBattleCsvData:getCarbonById(carbonId)
	return self.m_data[carbonId]
end

return LegendBattleCsvData