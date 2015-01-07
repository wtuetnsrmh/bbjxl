require("utils.StringUtil")

local DropCsvData = {
	m_data = {},
}

function DropCsvData:load( fileName )
	local csvData = CsvLoader.load(fileName)

	self.m_data = {}

	for index = 1, #csvData do
		local carbonId = tonum(csvData[index]["副本ID"])
		self.m_data[carbonId] = self.m_data[carbonId] or {}
		if carbonId > 0 then
			local data = {}
			data.carbonId = carbonId
			data.enemyId = tonum(csvData[index]["怪物ID"])
			data.desc = csvData[index]["掉落描述"]
			data.itemName = csvData[index]["掉落物品名称"]
			data.commonDropProbability = tonum(csvData[index]["普掉概率"])
			data.commonDropStarProbality = string.tomap(csvData[index]["普掉品质"], " ")
			data.commonDropTime = tonum(csvData[index]["普掉次数"])
			for count = 1, 3 do
				data["specialDropTime" .. count] = tonum(csvData[index]["特掉" .. count .. "次数"])
				data["specialDropProbability" .. count] = tonum(csvData[index]["特掉" .. count .. "概率"])
				data["specialDrop" .. count] = string.toTableArray(csvData[index]["特掉" .. count], " ")
			end
			data.specialDrop = string.toTableArray(csvData[index]["道具掉落"], " ")

			table.insert(self.m_data[carbonId], data)
		end
	end
end

function DropCsvData:getDropData( carbonId )
	return self.m_data[carbonId]
end

return DropCsvData