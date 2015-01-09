local ShopCsvData = {
	m_data = {},
	m_shop1_data = {},
	m_shop2_data = {},
	m_shop3_data = {},
	m_shop4_data = {},
	m_shop5_data = {},
	m_shop6_data = {},
	m_shop7_data = {},
}

function ShopCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local id = tonum(csvData[index]["id"])
		if id > 0 then
			self.m_data[id] = self.m_data[id] or {}
			self.m_data[id].id = id
			self.m_data[id].itemType = tonum(csvData[index]["类型"])
			self.m_data[id].itemId = tonum(csvData[index]["道具id"])
			self.m_data[id].name = csvData[index]["武将名"]
			self.m_data[id].star = tonum(csvData[index]["星级"])
			self.m_data[id].numWeights = string.toTableArray(csvData[index]["数量"])
			self.m_data[id].priceTypeWeights = string.tomap(csvData[index]["货币"])
			self.m_data[id].price = string.tomap(csvData[index]["单价"])
			self.m_data[id].weight1 = tonum(csvData[index]["权值1"])
			self.m_data[id].weight2 = tonum(csvData[index]["权值2"])
			self.m_data[id].weight3 = tonum(csvData[index]["权值3"])
			self.m_data[id].slot = tonum(csvData[index]["货架"])
			self.m_data[id].desc = csvData[index]["描述"]

			if id > 0 and id <= 1000 then
				self.m_shop1_data[id] = self.m_data[id]
			elseif id >= 1001 and id <= 2000 then
				self.m_shop2_data[id] = self.m_data[id]
			elseif id >= 2001 and id <= 3000 then
				self.m_shop3_data[id] = self.m_data[id]
			elseif id >= 3001 and id <= 4000 then
				self.m_shop4_data[id] = self.m_data[id]
			elseif id >= 4001 and id <= 5000 then
				self.m_shop5_data[id] = self.m_data[id]
			elseif id >= 5001 and id <= 6000 then
				self.m_shop6_data[id] = self.m_data[id]
			elseif id >= 6001 and id <= 7000 then
				self.m_shop7_data[id] = self.m_data[id]
			end
		end
	end
end

function ShopCsvData:getShopData(shopId)
	return self.m_data[shopId]
end

function ShopCsvData:randomShopIds(shopIndex, level)
	local weightIndex = 1
	if level > 0 and level <= 50 then
		weightIndex = 1
	elseif level > 50 and level <=75 then
		weightIndex = 2
	else
		weightIndex = 3
	end

	local selectedIds = {}
	local data = self[string.format("m_shop%d_data", shopIndex)]
	local function findDataBySlot(curSlot)
		local findData={}
		local defaultData={}
		for id,shopData in pairs(data) do
			if shopData and tonumber(shopData.slot)==tonumber(curSlot) then
				findData[id]= { weight = shopData["weight" .. weightIndex]}
			end
			if shopData and tonumber(shopData.slot)==0 then
				defaultData[id]={ weight = shopData["weight" .. weightIndex]}
			end
		end
		
		if table.nums(findData)==0 then
			findData=defaultData
		end
		
		return findData
	end

	if table.nums(data) <= 6 then
		selectedIds = table.keys(data)
	else
		local slot=1
		local shopOpenData = shopOpenCsv:getDataById(shopIndex)
		local leftCount = shopOpenData.num
		local tempSelectedIds={}
		while leftCount > 0 do
			local id = randWeight(findDataBySlot(slot))
			if not tempSelectedIds[id] then
				selectedIds[slot]=id
				tempSelectedIds[id] = true
				leftCount = leftCount - 1
				slot=slot+1
			end
		end

		selectedIds = table.values(selectedIds)
	end

	local result = {}
	local sortResult={}
	for index, shopId in ipairs(selectedIds) do
		-- 数量
		local numWeights = {}
		for _, numData in ipairs(data[shopId].numWeights) do
			table.insert(numWeights, { num = numData[1], weight = numData[2]})
		end
		local randIndex = randWeight(numWeights)

		-- 货币类型
		local priceTypeWeights = {}
		for type, weight in pairs(data[shopId].priceTypeWeights) do
			table.insert(priceTypeWeights, { type = type, weight = weight })
		end
		local typeIndex = randWeight(priceTypeWeights)

		sortResult[index] = { 
			shopId = tostring(shopId), 
			num = numWeights[randIndex].num, 
			priceType = priceTypeWeights[typeIndex].type
		}
	end
	return sortResult
end

return ShopCsvData