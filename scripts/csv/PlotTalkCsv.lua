local PlotTalkCsvData = {
	m_data = {},
}

function PlotTalkCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)
	
	for index = 1, #csvData do
		local carbonId = tonum(csvData[index]["副本ID"])
		local phase = tonum(csvData[index]["阶段"])
		if carbonId ~= 0 and phase ~= 0 then
			self.m_data[carbonId] = self.m_data[carbonId] or {}
			self.m_data[carbonId][phase] = self.m_data[carbonId][phase] or {}
			table.insert(self.m_data[carbonId][phase], {
				plotId = tonum(csvData[index]["剧情ID"]),
				type = tonum(csvData[index]["类型"]),
				roleTalk = tonum(csvData[index]["玩家对话"]),
				heroType = tonum(csvData[index]["武将ID"]),
				heroName = csvData[index]["武将名"],
				content = csvData[index]["剧情"],
			})
		end
	end
end

function PlotTalkCsvData:getPlotTalkByCarbon(carbonId, phase)
	self.m_data[carbonId] = self.m_data[carbonId] or {}
	return self.m_data[carbonId][phase] or {}
end

return PlotTalkCsvData