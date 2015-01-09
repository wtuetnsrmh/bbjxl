local RoleInfoCsvData = {
	m_data = {},
	m_level_index = {},
	m_choose_level = {},
}

function RoleInfoCsvData:load(fileName)
	self.m_data = {}
	self.m_level_index = {}
	self.m_choose_level = {}

	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local id = tonum(csvData[index]["id"])
		
		if id ~= 0 then
			self.m_data[id] = self.m_data[id] or {}
			self.m_data[id].id = tonum(csvData[index]["id"])
			self.m_data[id].level = tonum(csvData[index]["玩家等级"])
			self.m_data[id].upLevelExp = tonum(csvData[index]["升级经验"])
			self.m_data[id].bagHeroLimit = tonum(csvData[index]["包裹武将上限"])
			self.m_data[id].chooseHeroNum = tonum(csvData[index]["点将上限"])
			self.m_data[id].healthLimit = tonum(csvData[index]["体力上限"])
			self.m_data[id].friendLimit = tonum(csvData[index]["好友上限"])
			self.m_data[id].functionOpen = string.tomap(csvData[index]["功能开放"])
			self.m_data[id].pvpOpen = tonum(csvData[index]["战场"])
			self.m_data[id].techOpen = tonum(csvData[index]["科技"])
			self.m_data[id].heroStarOpen = tonum(csvData[index]["将星"])
			self.m_data[id].towerOpen = tonum(csvData[index]["过关斩将"])
			self.m_data[id].legendOpen = tonum(csvData[index]["名将"])
			self.m_data[id].beautyOpen = tonum(csvData[index]["美人"])
			self.m_data[id].sweepOpen = tonum(csvData[index]["扫荡"])
			self.m_data[id].speedOpen = tonum(csvData[index]["加速战斗"])
			self.m_data[id].autoOpen = tonum(csvData[index]["自动战斗"])
			self.m_data[id].expBattleOpen = tonum(csvData[index]["经验活动本"])
			self.m_data[id].moneyBattleOpen = tonum(csvData[index]["金钱活动本"])
			self.m_data[id].heroStarUpOpen = tonum(csvData[index]["升星开放"])
			self.m_data[id].expeditionOpen = tonum(csvData[index]["出塞开放"])
			self.m_data[id].partnerHeroNum = tonum(csvData[index]["小伙伴"])
			self.m_data[id].equipOpen = tonum(csvData[index]["装备开放"])
			self.m_data[id].equipEvolOpen = tonum(csvData[index]["装备炼化开放"])
			self.m_data[id].huahunOpen = tonum(csvData[index]["化魂开放"])
			self.m_data[id].dailyTaskOpen = tonum(csvData[index]["每日任务开放"])
			self.m_data[id].guideId = tonum(csvData[index]["引导id"])

			if self.m_data[id].functionOpen["1"] then
				self.m_choose_level[tonum(self.m_data[id].functionOpen["1"])] = self.m_data[id].level
			end
			self.m_level_index[self.m_data[id].level] = self.m_data[id]
		end
	end

	self.m_partnerChooseLevel = {}
	self.m_partnerChooseLevel[self.m_level_index[1].partnerHeroNum] = 1
	for index = 2, #self.m_level_index do
		local num = self.m_level_index[index].partnerHeroNum
		if num > self.m_level_index[index - 1].partnerHeroNum then
			self.m_partnerChooseLevel[num] = index
		end
	end
end

function RoleInfoCsvData:getLevelByChooseNum(chooseLimit)
	return self.m_choose_level[chooseLimit]
end

function RoleInfoCsvData:getDataByLevel(level)
	return self.m_level_index[level]
end

function RoleInfoCsvData:getLevelByPartnerChooseNum(num)
	return self.m_partnerChooseLevel[num]
end

return RoleInfoCsvData