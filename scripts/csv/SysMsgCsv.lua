local SysMsgCsvData = {
	m_data = {},
}

function SysMsgCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local id = tonum(csvData[index]["id"])
		local xPos = tonum(csvData[index]["位置x"])
		local yPos = tonum(csvData[index]["位置y"])

		if id > 0 then
			self.m_data[id] = {
				type = tonum(csvData[index]["类型"]),
				text = csvData[index]["详细描述"],
				xPos = xPos == 0 and 480 or xPos,
				yPos = yPos == 0 and 320 or yPos,
			}
		end
	end
end

function SysMsgCsvData:getMsgbyId(errCode)
	return self.m_data[errCode]
end

return SysMsgCsvData