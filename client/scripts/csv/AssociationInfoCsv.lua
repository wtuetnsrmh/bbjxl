local AssociationInfoCsvData = {
	m_data = {},
	m_heroType_index = {},
}

function AssociationInfoCsvData:load( fileName )
	self.m_data = {}
	self.m_heroType_index = {}
	
	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local id = tonum(csvData[index]["组合技ID"])

		if id ~= 0 then
			self.m_data[id] = {
				id = id,
				name = csvData[index]["组合技名称"],
				desc = csvData[index]["组合技描述"],
				heroName = csvData[index]["技能武将名称"],
				heroType = tonum(csvData[index]["技能武将ID"]),
				associationType = tonum(csvData[index]["类型"]),
				otherHeroTypes = string.split(csvData[index]["武将组合"], " "),
				hpBonus1 = tonum(csvData[index]["生命加成"]),
				attackBonus1 = tonum(csvData[index]["攻击加成"]),
				derateBonus1 = tonum(csvData[index]["伤害减免"]),
				attackSpeedBonus1 = tonum(csvData[index]["攻速加成"]),
				defenseBonus1 = tonum(csvData[index]["防御加成"]),
				side = tonum(csvData[index]["我方敌方"]),
				camp = tonum(csvData[index]["阵营"]),
				profession = tonum(csvData[index]["职业"]),
				hpBonus2 = tonum(csvData[index]["生命加成"]),
				attackBonus2 = tonum(csvData[index]["攻击加成"]),
				derateBonus2 = tonum(csvData[index]["伤害减免"]),
				attackSpeedBonus2 = tonum(csvData[index]["攻速加成"]),
			}

			-- 武将对应的组合技
			self.m_heroType_index[self.m_data[id].heroType] = self.m_heroType_index[self.m_data[id].heroType] or {}
			table.insert(self.m_heroType_index[self.m_data[id].heroType], self.m_data[id])
		end
	end
end

function AssociationInfoCsvData:getAssociationById(id)
	return self.m_data[id]
end

function AssociationInfoCsvData:getAssociationByHeroType(heroType)
	return self.m_heroType_index[heroType] or {}
end

return AssociationInfoCsvData