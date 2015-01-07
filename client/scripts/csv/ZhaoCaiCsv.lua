local ZhaoCaiCsvData = {
	m_data = {},
}

function ZhaoCaiCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local times = tonum(csvData[index]["招财次数"])
		if times > 0 then
			self.m_data[times] = {
				times = times,
				gold = tonum(csvData[index]["消耗元宝"]),
				money= tonum(csvData[index]["获得银币"]),
			}
		end
	end
end

function ZhaoCaiCsvData:getAllData(level)
	return self.m_data
end

--消耗元宝
function ZhaoCaiCsvData:getGoldByTimes(times)
	return self.m_data[tonumber(times)].gold
end
--获取银币
function ZhaoCaiCsvData:getMoneyByTimes(times)
	return self.m_data[tonumber(times)].money
end

return ZhaoCaiCsvData