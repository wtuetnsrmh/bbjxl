-- 装备
-- by yujiuhe
-- 2014.8.13

local Equip = class("Equip")

Equip.pbField = { "id", "type", "level", "evolCount", "evolExp"}


Equip.__index = function (self, key)
	local v = rawget(self, key .. "_ed")
	if v then
		return MemDecrypt(v)
	else
		return Equip[key]
	end
end

Equip.__newindex = function (self, key, value)
	if type(value) == "number" then
		rawset(self, key .. "_ed", MemEncrypt(value))
	else
		rawset(self, key, value)
	end
end

function Equip:ctor(pbSource)
	require("framework.api.EventProtocol").extend(self)
	self:reloadWithPBData(pbSource)
	self.csvData = equipCsv:getDataByType(self.type)
	self.masterId = 0
end

function Equip:reloadWithPBData(pbData)
	for _,property in pairs(self.class.pbField) do
		self[property] = pbData[property]
	end
end

function Equip:getBaseAttributes(level, evolCount)
	level = level or self.level
	evolCount = evolCount or self.evolCount
	local attrs = {}
	for key, value in pairs(EquipAttEnum) do
		attrs[key] = math.floor(self.csvData.attrs[value] and 
			(self.csvData.attrs[value][1] + self.csvData.attrs[value][2] * level) * (globalCsv:getFieldValue("equipEvolFactor")[evolCount] or 1) or 0)
	end
	return attrs
end

function Equip:getSlot()
    for slot, data in pairs(game.role.slots) do
        if data.equips and data.equips[self.csvData.equipSlot] == self.id then
            return tonum(slot)
        end
    end
    return 0
end

function Equip:updateProperty(property, value)
	if self[property] then
		self[property] = value
	end
end

--装备名称
function Equip:getName()
	return self.csvData.name .. (self.evolCount > 0 and "+" .. self.evolCount or "")
end

--装备作为原材料提供的exp
function Equip:getOfferExp()
	local exp = self.evolExp + self.csvData.offerExp
	for index = 1, self.evolCount do
		exp = exp + self.csvData.evolExp[index]
	end
	return exp
end

--装备出售的钱
function Equip:getSellMoney()
	local sellMoney = self:getLevelReturnMoney()
	local itemData = itemCsv:getItemById(self.type + Equip2ItemIndex.ItemTypeIndex)
	if itemData then
		sellMoney = sellMoney + itemData.sellMoney  
	end
	return sellMoney
end

--得到装备等级补偿的钱
function Equip:getLevelReturnMoney()
 	local sellData = equipLevelCostCsv:getDataByLevel(self.level)
 	return sellData.sellMoney[self.csvData.star] or 0
end

--得到目前等级到最高等级的总经验
function Equip:getEvolMaxExp()
	local maxExp = 0
	for evolCount = self.evolCount + 1, EQUIP_MAX_EVOL do
		maxExp = maxExp + self.csvData.evolExp[evolCount]
	end
	maxExp = math.max(maxExp - self.evolExp, 0)
	return maxExp
end

--装备获得addExp后可达到的进化等级
function Equip:getNextEvolCount(addExp)
	addExp = addExp + self.evolExp
	for evolCount = self.evolCount + 1, EQUIP_MAX_EVOL do
		local needExp = self.csvData.evolExp[evolCount]
		if addExp >= needExp then
			addExp = addExp - needExp
		else
			return evolCount - 1
		end
	end
	return EQUIP_MAX_EVOL
end

return Equip