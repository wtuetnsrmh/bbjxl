--
-- Author: whister(zjupigeon@163.com)
-- Date: 2013-11-16 20:43:37
--
local HeroFilterLogic = class("HeroFilterLogic")

local HeroSortRules = {
	["default"] = function(a, b)
		if a.type >= 10000 or b.type >= 10000 then
			return false
		end
		
		local unitDataA = unitCsv:getUnitByType(a.type)
		local unitDataB = unitCsv:getUnitByType(b.type)

		if a.star == b.star then
			if a.evolutionCount == b.evolutionCount then
				if a.level == b.level then
					return a.createTime > b.createTime
				else
					return a.level > b.level
				end
			else
				return a.evolutionCount > b.evolutionCount
			end
		else
			return a.star > b.star
		end
	end,

	["createTimeDesc"] = function(a, b)
		return a.createTime > b.createTime
	end,

	["levelDesc"] = function(a, b)
		return a.level > b.level
	end,

	["levelAsc"] = function(a, b)
		return a.level < b.level
	end,

	["evolutionDesc"] = function(a, b)
		return a.evolutionCount > b.evolutionCount
	end,

	["evolutionAsc"] = function(a, b)
		return a.evolutionCount < b.evolutionCount
	end,

	["starDesc"] = function(a, b)
		return a.star > b.star
	end,

	["starAsc"] = function(a, b)
		return a.star < b.star
	end,
}

function HeroFilterLogic:ctor(params)
	require("framework.api.EventProtocol").extend(self)

	self.source = params.heros
	self.result = params.heros

	self.profession = 0
	self.star = 0
	self.camp = 0
	self.sortRule = "default"
end

function HeroFilterLogic:filterByStar(params)
	self.star = params.star
	self:filter()
	self:dispatchEvent({ name = "filter" })
end

function HeroFilterLogic:filterByProfession(params)
	self.profession = params.profession
	self:filter()
	self:dispatchEvent({ name = "filter" })
end

function HeroFilterLogic:filterByCamp(params)
	self.camp = params.camp
	self:filter()
	self:dispatchEvent({ name = "filter" })
end

function HeroFilterLogic:orderByRule(params)
	self.sortRule = params.rule
	self:filter()
	self:dispatchEvent({ name = "filter", sortRule = params.rule })
end

function HeroFilterLogic:filter()
	self.result = {}

	for _, hero in ipairs(self.source) do
		local type = hero.type >= 2000 and math.floor(hero.type - 2000) or hero.type
		local unitData = unitCsv:getUnitByType(type)
		if unitData then
			local professionOk = self.profession == 0 and true or self.profession == unitData.profession
			local starOk = self.star == 0 and true or self.star == (hero.star or unitData.stars)
			local campOK = self.camp == 0 and true or self.camp == unitData.camp
			if professionOk and starOk and campOK then
				table.insert(self.result, hero)
			end	
		end
	end

	-- 排序
	table.sort(self.result, HeroSortRules[self.sortRule])
end

function HeroFilterLogic:getResult()
	return self.result
end

return HeroFilterLogic