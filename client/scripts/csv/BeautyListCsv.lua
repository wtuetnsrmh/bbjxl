-- 美人系统美人列表配表解析
-- by yangkun
-- 2014.2.17

local BeautyListCsvData = {
	m_data = {}
}

function BeautyListCsvData:load(fileName) 
	local csvData = CsvLoader.load(fileName)
	self.m_data = {}

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
		local beautyId = tonum(csvData[index]["美人ID"])

		if beautyId > 0 then
			
			local data = setmetatable({}, meta)
			data.beautyId = beautyId
			data.beautyName = csvData[index]["美人名称"]
			data.star = tonum(csvData[index]["星级"])
			data.evolutionMax = tonum(csvData[index]["进阶上限"])
			data.evolutionLevel = tonum(csvData[index]["每阶等级上限"])

			data.hpInit = tonum(csvData[index]["品德初始值"])
			data.atkInit = tonum(csvData[index]["才艺初始值"])
			data.defInit = tonum(csvData[index]["美色初始值"])
			data.hpGrow = tonum(csvData[index]["品德成长值"])
			data.atkGrow = tonum(csvData[index]["才艺成长值"])
			data.defGrow = tonum(csvData[index]["美色成长值"])

			data.potential = tonum(csvData[index]["参悟潜力"])
			data.potentialDesc = csvData[index]["潜力评价"]

			-- 美人计
			data.beautySkill1 = tonum(csvData[index]["美人计1ID"])
			data.beautySkill2 = tonum(csvData[index]["美人计2ID"])
			data.beautySkill3 = tonum(csvData[index]["美人计3ID"])

			data.activeLevel = tonum(csvData[index]["激活等级"])
			data.preBeautyId = tonum(csvData[index]["前提美人ID"])
			data.preChallengeId = tonum(csvData[index]["前提精英关卡ID"])
			data.employMoney = string.split(string.trim((csvData[index]["招募金币"])), "=")

			data.headImage = csvData[index]["头像"]
			data.heroRes = csvData[index]["全身像"]
			data.heroMaskRes = csvData[index]["全身像遮罩"]
			self.m_data[beautyId] = data
		end
		-- dump(self:getBeautyById(beautyId))
	end
end

function BeautyListCsvData:getBeautyById(beautyId) 
	return self.m_data[beautyId]
end

function BeautyListCsvData:getAllData()
	return self.m_data
end

return BeautyListCsvData