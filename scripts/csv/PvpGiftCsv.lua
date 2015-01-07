local PvpGiftCsvData = {
	m_data = {},
}

function PvpGiftCsvData:load( fileName )
	self.m_data = {}
	
	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local id = tonum(csvData[index]["段位id"])
		local floorRank = tonum(csvData[index]["排名下限"])
		local ceilRank = tonum(csvData[index]["排名上限"])

		if id > 0 then
			self.m_data[ceilRank] = {
				name = csvData[index]["称号"],
				desc = csvData[index]["奖励描述"],
				floorRank = floorRank,
				ceilRank = ceilRank == 0 and math.huge or ceilRank,
				cardGiftId = tonum(csvData[index]["卡包ID"]),
				money = tonum(csvData[index]["金钱"]),
				yuanbao = tonum(csvData[index]["元宝"]),
				zhangong = tonum(csvData[index]["战功"]),
				otherItemId = tonum(csvData[index]["其它道具ID"]),
				emailId = tonum(csvData[index]["邮件id"]),
			}
		end
	end
end

function PvpGiftCsvData:getGiftData(rank)
	return lowerBoundSeach(self.m_data, rank)
end

return PvpGiftCsvData