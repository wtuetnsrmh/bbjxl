local BattleResultCsvData = {
	winBattle = 0,
	leftCampHpRatio = 0,
	deadSoldierRatio = 0,
}

function BattleResultCsvData:load(fileName)
	local csvData = CsvLoader.load(fileName)

	self.m_data = {}
	
	for index = 1, #csvData do
		local winBattle = csvData[index]["战斗胜利"]
		if winBattle ~= "" then
			self.winBattle = tonum(csvData[index]["战斗胜利"])
			self.leftCampHpRatio = tonum(csvData[index]["大本营血量"])
			self.deadSoldierRatio = tonum(csvData[index]["武将阵亡数"])
			break
		end
	end
end

return BattleResultCsvData