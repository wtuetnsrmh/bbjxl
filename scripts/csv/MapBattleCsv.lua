require("utils.StringUtil")

local MapBattleCsvData = {
	m_data = {},
	m_mapId_index = {},
	m_prevMapId_index = {}
}

function MapBattleCsvData:load(files)
	if type(files) ~= "table" then
		return
	end

	self.m_data = {}
	self.m_mapId_index = {}
	self.m_prevMapId_index = {}

	for _, fileName in pairs(files) do
		local csvData = CsvLoader.load(fileName)

		for index = 1, #csvData do
			local carbonId = tonum(csvData[index]["副本ID"])

			if carbonId ~= 0 then
				self.m_data[carbonId] = self.m_data[carbonId] or {}

				self.m_data[carbonId].carbonId = carbonId
				self.m_data[carbonId].type = tonum(csvData[index]["副本类型"])
				self.m_data[carbonId].name = csvData[index]["副本名"]
				self.m_data[carbonId].desc = csvData[index]["副本描述"]
				self.m_data[carbonId].openLevel = tonum(csvData[index]["开启等级"])
				self.m_data[carbonId].prevCarbonId = tonum(csvData[index]["前置副本"])
				self.m_data[carbonId].battleLevel = tonum(csvData[index]["战斗等级"])
				self.m_data[carbonId].battleCsv = csvData[index]["战斗配表"]
				self.m_data[carbonId].battleTotalPhase = tonum(csvData[index]["战斗阶段"])
				self.m_data[carbonId].hasPlot = tonum(csvData[index]["剧情"]) == 1
				self.m_data[carbonId].bossId = tonum(csvData[index]["BOSS ID"])
				self.m_data[carbonId].bossName = csvData[index]["BOSS名称"]
				self.m_data[carbonId].bossIcon = csvData[index]["BOSS头像框"]
				self.m_data[carbonId].consumeType = tonum(csvData[index]["消耗类型"])
				self.m_data[carbonId].campLife =  tonum(csvData[index]["大本营生命"])
				self.m_data[carbonId].hasFoggy = tonum(csvData[index]["战争迷雾"]) == 1
				self.m_data[carbonId].playCount = tonum(csvData[index]["挑战次数"])
				self.m_data[carbonId].consumeValue = tonum(csvData[index]["消耗类型值"])
				self.m_data[carbonId].passExp = tonum(csvData[index]["过关经验"])
				self.m_data[carbonId].starExpBonus = string.tomap(csvData[index]["星级经验修正"], " ")
				self.m_data[carbonId].passMoney = tonum(csvData[index]["过关金钱"])
				self.m_data[carbonId].starMoneyBonus = string.tomap(csvData[index]["星级金钱修正"], " ")
				self.m_data[carbonId].backgroundMusic = csvData[index]["背景音乐"]
				self.m_data[carbonId].firstPassAward = string.tomap(csvData[index]['首次通关奖励'], " ")
				self.m_data[carbonId].posX = tonum(csvData[index]["x坐标"])
				self.m_data[carbonId].posY = tonum(csvData[index]["y坐标"])

				for count = 1, 3 do
					self.m_data[carbonId]["backgroundPic" .. count] = csvData[index]["战斗场景" .. count]
				end

				local mapId = math.floor(carbonId / 100)
				self.m_mapId_index[mapId] = self.m_mapId_index[mapId] or {}
				table.insert(self.m_mapId_index[mapId], carbonId)

				local prevCarbonId = self.m_data[carbonId].prevCarbonId
				self.m_prevMapId_index[prevCarbonId] = self.m_prevMapId_index[prevCarbonId] or {}
				table.insert(self.m_prevMapId_index[prevCarbonId], self.m_data[carbonId])
			end
		end
	end
end

function MapBattleCsvData:getCarbonById(carbonID)
	return self.m_data[carbonID]
end

-- 根据前置ID得到可以打开的新副本
function MapBattleCsvData:getCarbonByPrev(prevCarbonId)
	return self.m_prevMapId_index[prevCarbonId] or {}
end

function MapBattleCsvData:getCarbonByMap(mapId)
	local carbonIds = self.m_mapId_index[mapId]
	local ret = {}
	if carbonIds == nil then
		logger.exitMethod("MapBattleCsvData:getCarbonByMap", { ret = ret})
		return ret
	end

	for _, carbonId in ipairs(carbonIds) do
		local carbonInfo = self.m_data[carbonId]
		if carbonInfo then
			ret[#ret + 1] = carbonInfo
		end
	end

	return ret
end

function MapBattleCsvData:getCarbonByLevelMap(level, mapId)
	local carbons = self:getCarbonByMap(mapId)
	local ret = {}
	for _, carbonInfo in pairs(carbons) do
		if carbonInfo.openLevel <= level then
			ret[#ret + 1] = carbonInfo
		end
	end

	return ret
end
return MapBattleCsvData