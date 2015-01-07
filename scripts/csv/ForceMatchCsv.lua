local CsvData = {
	m_data = {},
	m_match = {}
}

function CsvData:load(fileName)
	self.m_data = {}
	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local id = tonum(csvData[index]["关卡"])
		if id > 0 then
			self.m_data[id] = {
				id = id,
				type = tostring(csvData[index]["宝箱图标"]),
				money = tonum(csvData[index]["银币"]),
				items = string.tomap(csvData[index]["奖励"]),
				exp = tonum(csvData[index]["武将经验"]),
			}
			self.m_match[id] = {
				min = tonum(csvData[index]["匹配下限"]),
				max = tonum(csvData[index]["匹配上限"]),
			}
		end
	end
end

function CsvData:getAwardById(id)
	return self.m_data[id]
end

function CsvData:getMatchData()
	return self.m_match
end

-- 具体值=银币*（1+0.01*（玩家等级-30））
function CsvData:getAward(id, lvl)
	local money = math.floor(self.m_data[id].money * (1+0.01*(lvl-30)))
	return money, self.m_data[id].items
end

return CsvData