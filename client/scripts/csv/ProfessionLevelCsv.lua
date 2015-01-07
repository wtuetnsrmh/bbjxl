local ProfessionLevelCsvData = {
	m_data = {}
}

function ProfessionLevelCsvData:load(fileName)
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
		local level = tonum(csvData[line]["等级"])
		if profession > 0 and phase > 0 and level > 0 then
			self.m_data[profession] = self.m_data[profession] or {}
			self.m_data[profession][phase] = self.m_data[profession][phase] or {}
			
			local data = setmetatable({}, meta)
			data.name = csvData[line]["name"]
			data.atkBonus = tonum(csvData[line]["攻击加成"])
			data.defBonus = tonum(csvData[line]["防御加成"])
			data.hpBonus = tonum(csvData[line]["生命加成"])
			data.restraintBonus = tonum(csvData[line]["克制伤害加成"])
			data.lingpaiNum = tonum(csvData[line]["升级消耗"])
			self.m_data[profession][phase][level] = data
		end
	end
end

function ProfessionLevelCsvData:getDataByLevel(profession, phase, level)
	return self.m_data[profession][phase][level]
end

return ProfessionLevelCsvData