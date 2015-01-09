local VipCsvData = {
	m_data = {},
	vipLevelMax = 15
}

function VipCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local vipLevel = csvData[index]["VIP等级"]
		if tonum(vipLeve) >= 0 and string.utf8len(tostring(vipLevel)) > 0 then
			self.m_data[vipLevel] = {
				vipLevel = vipLevel,
				rechargeRMB = tonum(csvData[index]["充值RMB"]),
				healthLimit = tonum(csvData[index]["体力上限增加"]),
				healthBuyCount = tonum(csvData[index]["体力购买次数"]),
				pvpCount = tonum(csvData[index]["战场次数增加"]),
				pvpBuyCount = tonum(csvData[index]["购买战场次数"]),
				legendCount = tonum(csvData[index]["传奇副本次数增加"]),
				legendBuyCount = tonum(csvData[index]["购买传奇副本次数"]),
				friendCount = tonum(csvData[index]["好友数量增加"]),
				pvpCd = tonum(csvData[index]["战场无CD"]) == 1,
				battleSpeedup = tonum(csvData[index]["加速战斗"]) == 1,
				autoBattle = tonum(csvData[index]["自动战斗"]) == 1,
				buyVipGift = tonum(csvData[index]["购买VIP礼包"]),
				moneyBuyLimit = tonum(csvData[index]["招财次数"]),
				bagHeroLimit = tonum(csvData[index]["武将包上限"]),
				challengeCount = tonum(csvData[index]["精英可购买挑战次数"]),
				sweepCount = tonum(csvData[index]["扫荡次数"]),
				equipIntensify = tonum(csvData[index]["强化暴击区间"]),
				itemBuyCount = tonum(csvData[index]["宝箱购买次数"]),
				storeLevel = tonum(csvData[index]["商店开启"]),
				expeditionResetCount = tonum(csvData[index]["远征挑战次数"]),
				expeditionMoneyGrowth = tonum(csvData[index]["远征银币收益提升"]),
				multiSweep = tonum(csvData[index]["副本多次扫荡功能"]),
			}
		end
	end
end

function VipCsvData:getDataByLevel(level)
	return self.m_data[tostring(level)]
end

function VipCsvData:getLevelByCurMoney(curRecharge)
 	local level = 0
	for i=1,(table.nums(self.m_data)-1) do
		if self.m_data[tostring(i)].rechargeRMB <= curRecharge then
			level = i
		else
			return level
		end
	end
	return level
end

function VipCsvData:getDataByRechargeRMB(rechargedRMB)
	local vipData

    local levels = table.keys(self.m_data)
    table.sort(levels, function(a, b) return tonum(a) < tonum(b) end)
	for _, level in ipairs(levels) do
		if self.m_data[level].rechargeRMB > rechargedRMB then
			vipData = self.m_data[level]
			break
		end		
	end

    return vipData
end

function VipCsvData:getCanBuyVipLevel(buyType)
	local canBuyLevel
    local levels = table.keys(self.m_data)
    table.sort(levels, function(a, b) return tonum(a) < tonum(b) end)
	for _, level in ipairs(levels) do
		if self.m_data[level][buyType] > 0 then
			canBuyLevel = tonum(level)
			break
		end
	end
	return canBuyLevel
end


return VipCsvData