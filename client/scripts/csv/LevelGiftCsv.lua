local LevelGiftCsvData = {
	m_data = {},
}

function LevelGiftCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)

	local n = 1
	for index = 1, #csvData do
		local level = tonum(csvData[index]["等级"])
		if level > 0 then
			self.m_data[level] = {
				level = level,
				name = tostring(csvData[index]["道具名称"]),
				itemtable= self:getItemsTable(tostring(csvData[index]["道具掉落"])),
				index = n
			}
			n = n + 1
		end
	end
end

function LevelGiftCsvData:getDataByIndex(index)
	local t = {}

	for k,v in pairs(self.m_data) do
		if tonumber(v.index) == tonumber(index) then
		 	t = v
		 	break
		end 
	end

	return t
end

function LevelGiftCsvData:getAllData()
	return self.m_data
end

function LevelGiftCsvData:getItemsTable(itemsStr)
	local t = {}
	if itemsStr ~= nil then
		local temp = string.split(itemsStr, " ")
		for i=1,table.nums(temp) do
			local st = string.split(tostring(temp[i]), "=") 
			t[i] = {}
			t[i]["itemId"]    = st[1]
			t[i]["itemCount"] = st[2]
		end
	end
	return t
end



return LevelGiftCsvData