-- 美人系统美人宠幸(培养)配表解析
-- by yangkun
-- 2014.2.17

local BeautyTrainCsvData = {
	m_data = {},
	m_evolution_level_index = {}
}

function BeautyTrainCsvData:load(fileName) 
	local csvData = CsvLoader.load(fileName)

	self.m_data = {}
	self.m_evolution_level_index = {}

	for index = 1, #csvData do
		local trainId = tonum(csvData[index]["id"])

		if trainId > 0 then
			self.m_data[trainId] = {
				trainId = trainId,

				beautyEvolution = tonum(csvData[index]["阶ID"]),
				beautyLevel = tonum(csvData[index]["等级"]),
				upgradeExp = tonum(csvData[index]["升级经验"]),
			}

			self.m_evolution_level_index[self.m_data[trainId].beautyEvolution .. self.m_data[trainId].beautyLevel] = self.m_data[trainId]
		end
		-- dump(self.m_data[trainId])
	end
end

function BeautyTrainCsvData:getBeautyTrainInfoById(trainId) 
	return self.m_data[trainId]
end

function BeautyTrainCsvData:getBeautyTrainInfoByEvolutionAndLevel(evolutionCount, level)
	return self.m_evolution_level_index[evolutionCount .. level]
end

return BeautyTrainCsvData