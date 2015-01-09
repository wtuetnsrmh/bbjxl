local StoreCsvData = {
	m_data = {},
	m_tab_index = {},
}

function StoreCsvData:load(fileName)
	self.m_data = {}
	self.m_tab_index = {}

	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local id = tonum(csvData[index]["id"])
		if id > 0 then
			self.m_data[id] = self.m_data[id] or {}
			self.m_data[id].id = id
			self.m_data[id].itemId = tonum(csvData[index]["道具ID"])
			self.m_data[id].num = tonum(csvData[index]["道具数量"])
			self.m_data[id].name = csvData[index]["商品名"]
			self.m_data[id].desc = csvData[index]["商品介绍"]
			self.m_data[id].yinbi = tonum(csvData[index]["银币"])
			self.m_data[id].yuanbao = tonum(csvData[index]["元宝"])
			self.m_data[id].discounts = string.toTableArray(csvData[index]["折扣"], " ")

			local dailyBuyLimit = tonum(csvData[index]["日购买次数上限"])
			self.m_data[id].dailyBuyLimit = (dailyBuyLimit == 0 and math.huge or dailyBuyLimit)
			local totalBuyLimit = tonum(csvData[index]["总购买次数上限"])
			self.m_data[id].totalBuyLimit = (totalBuyLimit == 0 and math.huge or totalBuyLimit)

			self.m_data[id].vipLevel = tonum(csvData[index]["购买vip等级"])
			self.m_data[id].tab = tonum(csvData[index]["页签"])
			self.m_data[id].position = tonum(csvData[index]["位置"])
			self.m_data[id].controlFlag = tonum(csvData[index]["时间控制"]) == 1
			self.m_data[id].openDays = toDateArray(csvData[index]["日期"])
			self.m_data[id].weekDays = string.toArray(csvData[index]["星期"])
			self.m_data[id].freeCount = tonum(csvData[index]["日免费次数"])
			self.m_data[id].freeCd = tonum(csvData[index]["免费CD"])

			self.m_tab_index[self.m_data[id].tab] = self.m_tab_index[self.m_data[id].tab] or {}
			table.insert(self.m_tab_index[self.m_data[id].tab], self.m_data[id])

		end
	end
end

function StoreCsvData:getOpenedItems(tabIndex)
	local now = game:nowTime()
	local nowTm = os.date("*t", now)
	local curTabItems = self.m_tab_index[tabIndex]

	local openedItems = {}
	for _, storeItem in ipairs(curTabItems) do
		local weekDays = {}
		for _, weekDay in ipairs(storeItem.weekDays) do
			weekDays[tonumber(weekDay)] = {}
		end

		if not storeItem.controlFlag then
			table.insert(openedItems, storeItem)
		else
			-- 检查日期
			if storeItem.openDays[1] <= now and storeItem.openDays[2] >= now then
				if #storeItem.weekDays == 0 then
					table.insert(openedItems, storeItem)
				elseif weekDays[nowTm.wday] then
					table.insert(openedItems, storeItem)
				end
			end
		end
	end

	return openedItems
end

function StoreCsvData:getPriceByCount(id, count)
	local itemData = self.m_data[id]

	if #itemData.discounts == 0 then
		return itemData.yuanbao
	end

	local discount = 0
	for _, data in ipairs(itemData.discounts) do
		if count >= tonum(data[1]) and count <= tonum(data[2]) then
			discount = tonum(data[3])
			break
		end
	end

	return  itemData.yuanbao * discount / 100
end

function StoreCsvData:getTotalPriceByCount(id, count)
	return self:getPriceByCount(id, count) * count
end

function StoreCsvData:getStoreItemById(id)
	return self.m_data[id]
end

function StoreCsvData:getTabItems(tab)
	return self.m_tab_index[tab]
end

function StoreCsvData:getDayBuyLimit(id, vipLevel)
	local specailItemIds = {34, 35, 36}
	local limit
	if table.find(specailItemIds, id) then
		limit = vipCsv:getDataByLevel(vipLevel).itemBuyCount
	else
		limit = self:getStoreItemById(id).dailyBuyLimit
	end
	return limit
end

return StoreCsvData