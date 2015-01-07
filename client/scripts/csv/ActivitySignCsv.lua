local ActivitySignCsvData = {
	m_data = {},
}

function ActivitySignCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local time = string.toArray(csvData[index]["开放日期"], "=")
		local year, month = tonum(time[1]), tonum(time[2])
		local day = tonum(csvData[index]["签到天数"])
		if day ~= 0 and year ~= 0 and month ~= 0 then
			self.m_data[year] = self.m_data[year] or {}
			self.m_data[year][month] = self.m_data[year][month] or {}
			self.m_data[year][month][day] = {
				day = day,
				name = csvData[index]["奖励名称"],
				typeName = csvData[index]["奖励类型"],
				itemId = tonum(csvData[index]["道具ID"]),
				num = tonum(csvData[index]["道具数量"]),
				doubleVipLevel = tonum(csvData[index]["双倍vip等级"]),
			}
		end
	end
end

function ActivitySignCsvData:getItemId(day, month, year)
	local curTime = os.date("*t", game:nowTime()) 
	year = year or tonum(curTime.year)
	month = month or tonum(curTime.month)
	return self.m_data[year][month][day]
end

return ActivitySignCsvData