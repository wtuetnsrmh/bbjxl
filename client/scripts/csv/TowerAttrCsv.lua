local attrName = {
	[1] = "hp",
	[2] = "atk",
	[3] = "def",
}

local TowerAttrCsvData = {
	m_data = {}
}

function TowerAttrCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)
	for index = 1, #csvData do
		local attrId = tonum(csvData[index]["属性加成ID"])
		if attrId > 0 then
			local attrOne = tonum(csvData[index]["属性1"])
			local attrTwo = tonum(csvData[index]["属性2"])
			local attrThree = tonum(csvData[index]["属性3"])

			self.m_data[attrId] = self.m_data[attrId] or {}
			self.m_data[attrId].attrId= attrId
			self.m_data[attrId][attrName[attrOne] .. "Modify"] = tonum(csvData[index]["属性1加成比"])
			self.m_data[attrId][attrName[attrTwo] .. "Modify"] = tonum(csvData[index]["属性2加成比"])
			self.m_data[attrId][attrName[attrThree] .. "Modify"] = tonum(csvData[index]["属性3加成比"])

			self.m_data[attrId][attrName[attrOne] .. "Star"] = tonum(csvData[index]["属性1消耗"])
			self.m_data[attrId][attrName[attrTwo] .. "Star"] = tonum(csvData[index]["属性2消耗"])
			self.m_data[attrId][attrName[attrThree] .. "Star"] = tonum(csvData[index]["属性3消耗"])

			self.m_data[attrId]["weight"] = tonum(csvData[index]["权值"])
		end
	end
end

function TowerAttrCsvData:getAttrModifyById(attrId)
	return self.m_data[attrId]
end

function TowerAttrCsvData:getRandAttrModify()
	local randIndex = randWeight(self.m_data)
	if not randIndex then return nil end

	return self.m_data[randIndex]
end

return TowerAttrCsvData