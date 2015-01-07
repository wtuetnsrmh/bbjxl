local HeroStarAttrCsvData = {
	m_data = {}
}

function HeroStarAttrCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)
	for line = 1, #csvData do
		local starId = tonum(csvData[line]["将星点ID"])
		if starId > 0 then
			self.m_data[starId] = {
				starId = starId,
				type = tonum(csvData[line]["类型ID"]),
				camp = tonum(csvData[line]["阵营ID"]),
				attrId = tonum(csvData[line]["属性ID"]),
				attrValue = tonum(csvData[line]["属性值"]),
				starSoulNum = tonum(csvData[line]["消耗"]),
				moneyNum = tonum(csvData[line]["银币消耗"]),
				xPos = tonum(csvData[line]["x坐标"]),
				yPos = tonum(csvData[line]["y坐标"]),
			}
		end
	end
end

function HeroStarAttrCsvData:getDataById(starId)
	return self.m_data[starId]
end

return HeroStarAttrCsvData