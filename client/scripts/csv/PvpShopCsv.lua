local PvpShopCsv = {
	m_data = {}
}

function PvpShopCsv:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)

	for line = 1, #csvData do
		local id = tonum(csvData[line]["id"])
		if id > 0 then
			self.m_data[id] = {
				id = id,
				itemTypeId = tonum(csvData[line]["类型"]),
				itemType = tonum(csvData[line]["武将id"]),
				numWeights = string.toTableArray(csvData[line]["数量"]),
				soulPrice = tonum(csvData[line]["战功单价"]),
				weight = tonum(csvData[line]["权值"]),
				desc = csvData[line]["描述"],
			}
		end
	end
end

function PvpShopCsv:getShopData(id)
	return self.m_data[id]
end

function PvpShopCsv:randomShopIds()
	local selectedIds = {}
	if table.nums(self.m_data) <= 6 then
		selectedIds = table.keys(self.m_data)
	else
		local leftCount = 6
		while leftCount > 0 do
			local id = randWeight(self.m_data)
			if not selectedIds[id] then
				selectedIds[id] = true
				leftCount = leftCount - 1
			end
		end
		selectedIds = table.keys(selectedIds)
	end

	local result = {}
	for index, shopId in ipairs(selectedIds) do
		local numWeights = {}
		for _, numData in ipairs(self.m_data[shopId].numWeights) do
			table.insert(numWeights, { num = numData[1], weight = numData[2]})
		end
		local randIndex = randWeight(numWeights)
		result[tostring(shopId)] = numWeights[randIndex].num
	end	

	return result
end

return PvpShopCsv