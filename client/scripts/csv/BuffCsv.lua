require("utils.StringUtil")

local BuffCsvData = {
	m_data = {},
}

function BuffCsvData:load(fileName)
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

	for index = 1, #csvData do
		local buffId = tonum(csvData[index]["id"])

		if buffId ~= 0 then
			
			local data = setmetatable({}, meta)
			data.id = buffId
			data.name = csvData[index]["名称"]
			data.desc = csvData[index]["描述"]
			data.type = tonum(csvData[index]["类型"])
			data.debuff = tonum(csvData[index]["DEBUFF"])
			data.initValue = tonum(csvData[index]["BUFF初始值"])
			data.valueGrowth = tonum(csvData[index]["效果成长"])
			data.rate = tonum(csvData[index]["BUFF机率"])
			data.rateGrowth = tonum(csvData[index]["机率成长"])
			data.initKeepTime = tonum(csvData[index]["初始持续时间"])
			data.keepTimeGrowth = tonum(csvData[index]["持续时间成长"])
			data.campModifies = string.tomap(csvData[index]["阵营覆盖"])
			data.campGrowth = tonum(csvData[index]["阵营覆盖成长"])
			data.professionModifies = string.tomap(csvData[index]["职业覆盖"])
			data.professionGrowth = tonum(csvData[index]["职业覆盖成长"])
			data.bulletId = tonum(csvData[index]["BUFF子弹"])
			data.audio = csvData[index]["BUFF音效"]
			self.m_data[buffId] = data
		end
	end
end

function BuffCsvData:canResist(buffId)
	local data = self.m_data[buffId]
	return data.type == 16 or data.type == 17 or data.type == 18
end

function BuffCsvData:getBuffById(id)
	return self.m_data[id]
end

return BuffCsvData