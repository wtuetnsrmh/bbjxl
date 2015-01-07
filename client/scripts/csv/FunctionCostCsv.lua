local FunctionCostCsvData = {
	m_data = {},
}

local FieldNameMap = {
	["health"] = "体力购买",
	["pvpCount"] = "战场次数购买",
	["legendBattleCnt"] = "传奇副本次数购买",
	["legendRefreshCnt"] = "传奇副本刷新",
	["eraseCdTime"] = "清除战场CD",
	["beautyTrain"] = "美人宠幸突破",
	["eraseSweepCdTime"] = "清除扫荡CD",
	["legendShopRefresh"] = "名将商店刷新",
	["addHeroBag"] = "购买背包",
	["cNameCost"] = "改名",
}

function FunctionCostCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local name = csvData[index]["name"]
		if name ~= "" then
			self.m_data[name] = self.m_data[name] or {}
			self.m_data[name].initValue = tonum(csvData[index]["初始值"])
			self.m_data[name].growth = tonum(csvData[index]["成长值"])
			self.m_data[name].phaseGrowth = string.toArray(csvData[index]["阶段成长值"], "=", true)
		end
	end
end

-- 返回给定的域的值
-- @param field 	变量名, 对应于FieldNameMap中的key
-- @return 返回该域对应的值
function FunctionCostCsvData:getFieldValue(field)
	if FieldNameMap[field] == nil then return nil end

	return self.m_data[FieldNameMap[field]]
end

function FunctionCostCsvData:getCostValue(field, count)
	count = count or 0
	local func = self:getFieldValue(field)
	local cost = 0
	if func then
		cost = cost + func.initValue
		if func.growth ~= 0 then
			cost = cost + count * func.growth
		elseif count >= 1 then
			cost = cost + tonum(func.phaseGrowth[count] or func.phaseGrowth[#func.phaseGrowth])
		end
	end
	return cost
end

return FunctionCostCsvData