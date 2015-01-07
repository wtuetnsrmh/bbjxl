-- 美人系统美人参悟（洗练）配表解析
-- by yangkun
-- 2014.2.17

local BeautyPotentialCsvData = {
	m_data = {}
}

function BeautyPotentialCsvData:load(fileName)
	local csvData = CsvLoader.load(fileName)

	self.m_data = {}

	for index = 1, #csvData do
		local beautyLevel = tonum(csvData[index]["等级"])
		if beautyLevel > 0 then
			self.m_data[beautyLevel] = {
				beautyLevel = beautyLevel,

				-- 参悟消耗
				moneyCost = tonum(csvData[index]["金币消耗"]),
				yuanbaoCost = tonum(csvData[index]["元宝消耗"]),
			}
		end
		-- dump(self.m_data[beautyLevel])
	end
end

function BeautyPotentialCsvData:getBeautyPotentialByLevel(beautyLevel)
	return self.m_data[beautyLevel]
end

return BeautyPotentialCsvData