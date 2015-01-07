--
-- Author: whister(zjupigeon@163.com)
-- Date: 2013-11-16 15:14:13
--

local EvolutionModifyCsvData = {
	m_data = {},
}

function EvolutionModifyCsvData:load(fileName)
    self.m_data = {}
	
	local csvData = CsvLoader.load(fileName)

	for line = 1, #csvData do
		local evolution = tonum(csvData[line]["进化等级"])
		if evolution > 0 then
			self.m_data[evolution] = {
				growthFactor = tonum(csvData[line]["实力系数"]),
				requireLevel = tonum(csvData[line]["需求等级"]),
				cost = tonum(csvData[line]["进化价格"]),
			}
		end
	end
	self.evolutionMax = #self.m_data
end

function EvolutionModifyCsvData:getModifies(evolutionCount)
	local data = self.m_data[evolutionCount] or {}
	local hpFactor = data.growthFactor or 1
	local atkFactor = data.growthFactor or 1
	local defFactor = data.growthFactor or 1

	return tonum(hpFactor), tonum(atkFactor), tonum(defFactor)
end

function EvolutionModifyCsvData:getEvolutionByEvolution(evolution)
	return self.m_data[evolution]
end

function EvolutionModifyCsvData:getEvolMaxCount()
	return self.evolutionMax
end

return EvolutionModifyCsvData