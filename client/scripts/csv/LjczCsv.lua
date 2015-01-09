local LjczCsvData = {
	m_data = {},
}

function LjczCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local id = tonum(csvData[index]["阶段"])
		if id > 0 then
			self.m_data[id] = {
				id = id,
				accumulatedRech = tonum(csvData[index]["累计充值量"]),
				awardItems = self:getItemsTable(tostring(csvData[index]["奖励"])),
			}
		end
	end
end


function LjczCsvData:getDataById(id)
	local t = {}

	for k,v in pairs(self.m_data) do
		if tonumber(v.id) == tonumber(id) then
		 	t = v
		 	break
		end 
	end

	return t
end

function LjczCsvData:getItemsTable(itemsStr)
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

function LjczCsvData:getAllData()
	return self.m_data
end


return LjczCsvData