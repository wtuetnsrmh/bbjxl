require "utils.init"

ShopIdMap = {
	Shop1 = 1,
	Shop2 = 2,
	Shop3 = 3,
	LegendShop = 4,
	PvpShop = 5,
}

local ShopOpenCsvData = {
	m_data = {},
}

function ShopOpenCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local id = tonum(csvData[index]["id"])
		if id > 0 then
			self.m_data[id] = self.m_data[id] or {}

			self.m_data[id].id = id
			self.m_data[id].num = tonum(csvData[index]["商品数量"])
			self.m_data[id].price = tonum(csvData[index]["刷新价格"])
			self.m_data[id].growth = string.toArray(csvData[index]["刷新价格成长"], "=", true)
			self.m_data[id].shopCsv = csvData[index]["商品表"]

			local refreshStr = string.split(csvData[index]["刷新时刻"], " ")

			self.m_data[id].refreshTimes = {}
			for _, timeStr in ipairs(refreshStr) do
				table.insert(self.m_data[id].refreshTimes, timeStr)
			end
		end
	end
end

function ShopOpenCsvData:getDataById(id)
	return self.m_data[id]
end

local function calSeconds(timeStr)
	timeStr = timeStr or "00:00"
	local timeArray = string.split(timeStr, ":")
	return tonumber(timeArray[1]) * 3600 + tonumber(timeArray[2]) * 60
end

-- timeStr = 0910, 2010
function ShopOpenCsvData:getNextRefreshTime(id, day, now)
	local shopData = self.m_data[id]

	local _, zero = diffTime({ day = day })
	for _, refreshTime in ipairs(shopData.refreshTimes) do
		local nextTime = zero + calSeconds(refreshTime)
		if nextTime > now then
			return nextTime, refreshTime
		end
	end

	return zero + 86400 + calSeconds(shopData.refreshTimes[1]), shopData.refreshTimes[1]
end

function ShopOpenCsvData:getCostValue(id, count)
	print(count, type(count))
	local data = self:getDataById(id)
	local cost = 0
	if data then
		cost = data.price
		if count >= 1 then
			cost = cost + tonum(data.growth[count] or data.growth[#data.growth])
		end
	end
	return cost
end

return ShopOpenCsvData
