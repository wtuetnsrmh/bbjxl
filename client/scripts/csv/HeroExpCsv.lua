local HeroExpCsvData = {
	m_data = {},
}

function HeroExpCsvData:load(fileName)
	self.m_data = {}
	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local heroLevel = tonum(csvData[index]["等级"])

		if heroLevel ~= 0 then
			self.m_data[heroLevel] = {
				level = heroLevel,
				exp = tonum(csvData[index]["所需经验"])
			}
		end
	end
end

function HeroExpCsvData:getLevelUpExp(curLevel, nextLevel)
	curLevel = curLevel or 1
	nextLevel = nextLevel or curLevel + 1
	local exp = 0
	for level = curLevel + 1, nextLevel do
		local data = self.m_data[level]
		if data then
			exp = exp + data.exp
		end
	end
	return exp
end

return HeroExpCsvData