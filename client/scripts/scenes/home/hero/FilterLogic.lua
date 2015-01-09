--
-- Author: whister(zjupigeon@163.com)
-- Date: 2013-11-16 20:43:37
--
local FilterLogic = class("FilterLogic")

local HeroSortRules = {
	["default"] = function(a, b)
		local unitDataA = unitCsv:getUnitByType(a.type%2000)
		local unitDataB = unitCsv:getUnitByType(b.type%2000)

		local aStar = a.star or unitDataA.stars
		local bStar = b.star or unitDataB.stars
		if a.type < 2000 and aStar == bStar then
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
			return aStar > bStar
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
		local unitDataA = unitCsv:getUnitByType(a.type%2000)
		local unitDataB = unitCsv:getUnitByType(b.type%2000)

		local aStar = a.star or unitDataA.stars
		local bStar = b.star or unitDataB.stars
		return aStar > bStar
	end,

	["starAsc"] = function(a, b)
		local unitDataA = unitCsv:getUnitByType(a.type%2000)
		local unitDataB = unitCsv:getUnitByType(b.type%2000)

		local aStar = a.star or unitDataA.stars
		local bStar = b.star or unitDataB.stars
		return aStar < bStar
	end,
}

function FilterLogic:ctor(params)
	require("framework.api.EventProtocol").extend(self)

	self.source = params.heros
	self.result = params.heros

	self.profession = 0
	self.star = 0
	self.camp = 0
	self.sortRule = params.sortRule or "default"
end

--远征：0:全部
function FilterLogic:filterByType(params)
	self.soldierType=params.type
	self.star=params.star
	self.level=params.level
	self:filterType()
	self:dispatchEvent({ name = "filter" })
end

function FilterLogic:filterType()
	self.result = {}

	for _, hero in ipairs(self.source) do
		local type = hero.type >= 2000 and math.floor(hero.type - 2000) or hero.type
		local unitData = unitCsv:getUnitByType(type)
		if unitData then
			local professionOk =true
			if self.soldierType == 0 then
			 	professionOk =true
			else
				professionOk=unitData.profession == self.soldierType and true or false
			end

			local starOk = self.star <= (hero.star or unitData.stars)
			local levelOk = self.level <= hero.level
			if professionOk and starOk and levelOk then
				table.insert(self.result, hero)
			end	
		end
	end

	-- 排序
	if(self.sortRule ~= "noChange") then
		table.sort(self.result, HeroSortRules[self.sortRule])
	end

end

function FilterLogic:filterByStar(params)
	self.star = params.star
	self:filter()
	self:dispatchEvent({ name = "filter" })
end

function FilterLogic:filterByProfession(params)
	self.profession = params.profession
	self:filter()
	self:dispatchEvent({ name = "filter" })
end

function FilterLogic:filterByCamp(params)
	self.camp = params.camp
	self:filter()
	self:dispatchEvent({ name = "filter" })
end

function FilterLogic:showAll()
	self.profession =0
	self.camp = 0
	self.star = 0

	self:filter()
	self:dispatchEvent({ name = "filter" })
end

function FilterLogic:orderByRule(params)
	self.sortRule = params.rule
	self:filter()
	self:dispatchEvent({ name = "filter", sortRule = params.rule })
end

function FilterLogic:filter()
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
	if(self.sortRule ~= "noChange") then
		table.sort(self.result, HeroSortRules[self.sortRule])
	end
end

function FilterLogic:getResult()
	return self.result
end

return FilterLogic