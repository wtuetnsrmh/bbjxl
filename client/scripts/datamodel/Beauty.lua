-- 美人
-- by yangkun
-- 2014.2.18

local Beauty = class("Beauty")

Beauty.pbField = { "beautyId", "level", "exp", "evolutionCount", "status", "potentialHp", "potentialAtk", "potentialDef"}

Beauty.STATUS_INACTIVE = 0 	-- 未激活
Beauty.STATUS_NON_EMPLOY = 1 	-- 未招募
Beauty.STATUS_REST = 2 			-- 休息
Beauty.STATUS_FIGHT = 3     	-- 战斗

Beauty.__index = function (self, key)
	local v = rawget(self, key .. "_ed")
	if v then
		return MemDecrypt(v)
	else
		return Beauty[key]
	end
end

Beauty.__newindex = function (self, key, value)
	if type(value) == "number" then
		rawset(self, key .. "_ed", MemEncrypt(value))
	else
		rawset(self, key, value)
	end
end

function Beauty:ctor(pbSource)
	require("framework.api.EventProtocol").extend(self)
	self:reloadWithPBData(pbSource)
end

function Beauty:reloadWithPBData(pbData)
	for _,property in pairs(self.class.pbField) do
		self[property] = pbData[property]
	end
end

function Beauty:getCurrentLevel()
	local beautyData = beautyListCsv:getBeautyById(self.beautyId)
	return self.level + (self.evolutionCount - 1) * beautyData.evolutionLevel
end

return Beauty