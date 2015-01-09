local ProfessionPhaseCsvData = {
	m_data = {}
}

function ProfessionPhaseCsvData:load(fileName)
	self.m_data = {}

	local csvData = CsvLoader.load(fileName)

	local meta = {}
	meta.__index = function (self, key)
		local v = rawget(self, key .. "_ed")
		if v then
			return MemDecrypt(v)
		else
			return meta[key]
		end
	end

	meta.__newindex = function (self, key, value)
		if type(value) == "number" then
			rawset(self, key .. "_ed", MemEncrypt(value))
		else
			rawset(self, key, value)
		end
	end

	for line = 1, #csvData do
		local profession = tonum(csvData[line]["职业ID"])
		local phase = tonum(csvData[line]["阶级"])
		if profession > 0 and phase > 0 then
			self.m_data[profession] = self.m_data[profession] or {}
			
			local data = setmetatable({}, meta)
			data.name = csvData[line]["职业"]
			data.atkBonus = tonum(csvData[line]["攻击加成"])
			data.defBonus = tonum(csvData[line]["防御加成"])
			data.hpBonus = tonum(csvData[line]["攻击加成"])
			data.restraintBonus = tonum(csvData[line]["克制伤害加成"])
			data.lingpaiNum = tonum(csvData[line]["进阶需要令牌"])
			data.atkBonusDesc = csvData[line]["攻击加成描述"]
			data.defBonusDesc = csvData[line]["防御加成描述"]
			data.hpBonusDesc = csvData[line]["生命加成描述"]
			data.restraintBonusDesc = csvData[line]["克制伤害加成描述"]
			data.restraintProfression = tonum(csvData[line]["克制职业ID"])
			data.helpInfo = csvData[line]["帮助信息"]
			data.phaseName = csvData[line]["阶级名称"]
			self.m_data[profession][phase] = data
		end
	end
end

function ProfessionPhaseCsvData:getDataByPhase(profession, phase)
	return self.m_data[profession][phase]
end

return ProfessionPhaseCsvData