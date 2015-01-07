local TowerBattleCsvData = {
	m_data = {}
}

function TowerBattleCsvData:load(fileName)
	self.m_data = {}
	
	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local carbonId = tonum(csvData[index]["副本ID"])
		if carbonId > 0 then
			self.m_data[carbonId] = {
				carbonId = carbonId,
				type = tonum(csvData[index]["副本类型"]),
				name = csvData[index]["副本名"],
				prevCarbonId = tonum(csvData[index]["前置副本"]),
				level = tonum(csvData[index]["战斗等级"]),
				attrModify = tonum(csvData[index]["实力修正系数"]),
				evolutionCount = tonum(csvData[index]["进化等级"]),
				attrBonus = tonum(csvData[index]["属性加成"]) == 1,
				moneyAward = tonum(csvData[index]["金币奖励"]) == 1,
				moneyStarUnit = tonum(csvData[index]["星级单价"]),
				yuanbaoAward = tonum(csvData[index]["元宝奖励"]) == 1,
				yuanbaoAwardStarNeed = tonum(csvData[index]["元宝奖励星级要求"]),
				yuanbaoNum = tonum(csvData[index]["元宝奖励数量"]),
				starSoulNum = tonum(csvData[index]["星魂奖励"]),
				mustItems = string.toTableArray(csvData[index]["必掉道具"]),
				otherItems = string.toTableArray(csvData[index]["填充道具"]),
			}
		end
	end
end

function TowerBattleCsvData:getCarbonData(carbonId)
	return self.m_data[carbonId]
end


function TowerBattleCsvData:getCarbonAwardData(carbonId)

	local function getDropItem(itemMap)
		local array = {}
		for _, itemData in pairs(itemMap) do
			table.insert(array, { itemId = itemData[1], weight=itemData[2],itemNum = itemData[3] })
		end

		local randIndex = randWeight(array)
		if randIndex then
			return tonumber(array[randIndex].itemId),array[randIndex].itemNum
		end

		return nil
	end

	local awardData = {}
	while #awardData == 0 do
		local item, itemNum = getDropItem(self.m_data[carbonId].mustItems)
		if item then
			table.insert(awardData,{ itemId = item, num = itemNum })
		end
	end
	
	while #awardData < 4 do
		for i = 1,3 do
			local item, itemNum = getDropItem(self.m_data[carbonId].otherItems)
			if item then
				table.insert(awardData,{ itemId = item, num = itemNum })
			end
		end
	end

	return awardData
end

return TowerBattleCsvData