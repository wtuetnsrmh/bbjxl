EquipAttEnum = {
	hp = 1,
	atk = 2,
	def = 3,
	miss = 4,
	hit = 5,
	parry = 6,
	ignoreParry = 7,
	crit = 8,
	tenacity = 9,
	critHurt = 10,
	resist = 11,
	moveSpeed = 12,
	atkSpeedFactor = 13,  		
}


EquipAttName = {
	"生命",
	"攻击",
	"防御",
	"闪避",
	"命中",
	"格挡",
	"破击",
	"暴击",
	"韧性",
	"爆伤",
	"抵抗",
	"移速",
	"攻速",
}

Equip2ItemIndex = {
	ItemTypeIndex = 3000,
	FragmentTypeIndex = 4000,
}


local EquipCsvData = {
	m_data = {},
}

function EquipCsvData:load(fileName)
	self.m_data = {}
	
	local csvData = CsvLoader.load(fileName)

	for index = 1, #csvData do
		local equipId = tonum(csvData[index]["id"])

		if equipId ~= 0 then
			self.m_data[equipId] = {
				type = equipId ,
				name = csvData[index]["名称"],
				equipSlot = tonum(csvData[index]["部位"]),
				star = tonum(csvData[index]["星级"]),
				relationHeros = string.toArray(csvData[index]["情缘武将"], " ", true),
				setId = tonum(csvData[index]["套装id"]),
				attrs = string.toAttArray(csvData[index]["属性"]),
				composeNum = tonum(csvData[index]["需要碎片数量"]),
				offerExp = tonum(csvData[index]["经验"]),
				evolExp = string.toNumMap(csvData[index]["进化经验"]),
			}
		end
	end
end

function EquipCsvData:getDataByType(type)
	return self.m_data[type]
end

return EquipCsvData