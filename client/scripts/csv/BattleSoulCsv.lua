local BattleSoulCsvData = {
	m_data = {}
}

function BattleSoulCsvData:load(fileName)
	self.m_data = {}
	self.toItemIndex = 6000
	local csvData = CsvLoader.load(fileName)
	for line = 1, #csvData do
		local id = tonum(csvData[line]["id"])
		if id > 0 then
			self.m_data[id] = {
				id = id,
				name = csvData[line]["名称"],
				requireLevel = tonum(csvData[line]["需求等级"]),
				flag = tonum(csvData[line]["碎片标识"]),
				material = string.toArray(csvData[line]["合成所需"]),
				money = tonum(csvData[line]["合成价格"]),
				hp = tonum(csvData[line]["生命"]),
				atk = tonum(csvData[line]["攻击"]),
				def = tonum(csvData[line]["防御"]),
			}
		end
	end
end

function BattleSoulCsvData:getDataById(id)
	return self.m_data[id]
end

function BattleSoulCsvData:canCompose(id)
	local csvData = self:getDataById(id)
	local itemEnough = table.nums(csvData.material) > 0
	for index, strData in ipairs(csvData.material) do
		local data = string.toArray(strData, "=")
		local soulId, num = tonum(data[1]), tonum(data[2])
		local itemId = soulId + battleSoulCsv.toItemIndex
		local item = game.role.items[itemId]
		local itemNum = item and item.count or 0
		if itemEnough then
			itemEnough = itemNum >= num
		end

		if not itemEnough then
			itemEnough = self:canCompose(soulId)
		end

		if not itemEnough then
			break
		end
	end

	return itemEnough
end

function BattleSoulCsvData:isFragment(itemId)
	local id = tonum(itemId) - battleSoulCsv.toItemIndex
	local csvData = self:getDataById(id)
	if csvData then
		return csvData.flag == 1
	end
	return false
end

return BattleSoulCsvData