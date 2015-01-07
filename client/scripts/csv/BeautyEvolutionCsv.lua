-- 美人系统美人突破（进阶）配表解析
-- by yangkun
-- 2014.2.17

local BeautyEvolutionCsvData = {
	m_data = {}
}

function BeautyEvolutionCsvData:load(fileName)
	local csvData = CsvLoader.load(fileName)

	self.m_data = {}

	for index = 1, #csvData do
		local evolutionLevel = tonum(csvData[index]["突破次数"])

		if evolutionLevel > 0 then
			self.m_data[evolutionLevel] = {
				evolutionLevel = evolutionLevel,
				nextEvolutionLevel = tonum(csvData[index]["开启阶"]),
				openBeautySkill = csvData[index]["开启美人计"],
				needYuanBao = tonum(csvData[index]["所需元宝"]),
				needItem = string.tomap(csvData[index]["所需道具"]),
			}
		end
		-- dump(self.m_data[evolutionLevel])
	end
end

function BeautyEvolutionCsvData:getBeautyEvolutionInfoByLevel(evolutionLevel)
	return self.m_data[evolutionLevel]
end

return BeautyEvolutionCsvData