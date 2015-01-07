local NewServerCsvData = {
	m_data = {},
}

function NewServerCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local day = tonum(csvData[index]["登入天数"])
		if day > 0 then
			self.m_data[day] = {
				day = day,
				name = tostring(csvData[index]["道具名称"]),
				itemtable= self:getItemsTable(tostring(csvData[index]["道具掉落"])),
			}
		end
	end
end

function NewServerCsvData:getDataByDay(day)

	return self.m_data[day]
end

function NewServerCsvData:getAllData()

	return self.m_data
end

function NewServerCsvData:getItemsTable(itemsStr)
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



return NewServerCsvData