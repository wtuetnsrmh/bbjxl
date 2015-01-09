local FieldNameMap = {
	["healthBuyCount"] = { name = "体力购买" },
	["pvpBuyCount"] = { name = "战场次数购买" },
	["legendBuyCount"] = { name = "传奇副本次数购买" },
	["legendRefreshCount"] = { name = "传奇副本刷新" },
	["pvpCdYuanbao"] = { name = "清除战场CD" },
	[""] = { name = "美人宠幸突破" },
}


local VipCostCsvData = {
	m_data = {},
}

function VipCostCsvData:load(fileName)
	local csvData = CsvLoader.load(fileName)
	self.m_data = {}

	for index = 1, #csvData do
		self.m_data[csvData[index]["name"]] = {
			init = tonum(csvData[index]["初始值"]),
			growth = tonum(csvData[index]["成长值"]),
		}
	end
end

function VipCostCsvData:getFieldValue(field)
	if FieldNameMap[field] == nil then return {0, 0} end

	local value = self.m_data[FieldNameMap[field].name]
	return value
end

return VipCostCsvData