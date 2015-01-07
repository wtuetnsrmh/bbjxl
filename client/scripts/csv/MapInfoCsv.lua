local MapInfoCsvData = {
	m_data = {},
	m_type_index = {},
	m_prevMapId_index = {},
}

function MapInfoCsvData:load(files)
	if type(files) ~= "table" then
		return
	end

	self.m_data = {}
	self.m_type_index = {}
	self.m_prevMapId_index = {}

	for _, fileName in pairs(files) do
		local csvData = CsvLoader.load(fileName)

		for index = 1, #csvData do
			local mapId = tonum(csvData[index]["地图ID"])
			if mapId ~= 0 then
				self.m_data[mapId] = {
					mapId = mapId,
					type = tonum(csvData[index]["地图类型"]),
					name = csvData[index]["地图名"],
					carbonNum = tonum(csvData[index]["副本个数"]),
					openLevel = tonum(csvData[index]["开启等级"]),
					bgRes = csvData[index]["地图"],
				}
				local type = self.m_data[mapId].type
				self.m_type_index[type] = self.m_type_index[type] or {}
				self.m_type_index[type][#self.m_type_index[type] + 1] = mapId
			end
		end
	end
end

function MapInfoCsvData:getMapById(mapId)
	return self.m_data[mapId]
end

function MapInfoCsvData:getMapsByType(type)
	local mapIds = self.m_type_index[type]
	local ret = {}
	if mapIds == nil then
		return ret
	end

	for _, mapId in ipairs(mapIds) do
		local mapInfo = self.m_data[mapId]
		if mapInfo then
			ret[#ret + 1] = mapInfo
		end
	end

	return ret
end

function MapInfoCsvData:getMapsByTypeLevel(type, roleLevel)
	local maps = self:getMapsByType(type)
	local ret = {}
	for _, mapInfo in pairs(maps) do
		if roleLevel >= mapInfo.openLevel then
			ret[#ret + 1] = mapInfo
		end
	end

	return ret
end

return MapInfoCsvData