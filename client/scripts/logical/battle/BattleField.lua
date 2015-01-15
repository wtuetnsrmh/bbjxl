local Camp = require("logical.battle.Camp")

local BattleField = class("BattleField")

function BattleField:ctor(params)
	require("framework.api.EventProtocol").extend(self)
	params = params or {}

	self.leftCamp = params.leftCamp
	self.rightCamp = params.rightCamp

	self.battle = params.battle
	self.gridWidth = params.gridWidth or 14 -- 移动最好距离
	self.column, self.row = params.column or 3, params.row or 2
	self.xPosOffset = 70

	-- 当前选择的英雄
	self.curSelectedSoldier = nil

	self.collisionPixel = 20 	-- 碰撞误差检测

	self.leftSoldierMap = {}	-- 武将描点和武将的映射表 "11" -> 貂蝉
	self.rightSoldierMap = {}	-- 武将描点和武将的映射表 "11" -> 貂蝉
end

function BattleField:init(params)
	for anchKey, soldier in pairs(self.leftSoldierMap) do
		soldier.battle = params.battle
	end
	self.leftCamp.battle = params.battle
	self.leftSoldierNum = table.nums(self.leftSoldierMap)

	for anchKey, soldier in pairs(self.rightSoldierMap) do
		soldier.battle = params.battle
	end
	self.rightCamp.battle = params.battle
	self.rightSoldierNum = table.nums(self.rightSoldierMap)

	self:reCalcAttrByPassiveSkills()
end

-- 根据被动技能重新计算己方和敌方武将的属性
function BattleField:reCalcAttrByPassiveSkills()
	for _, soldier in pairs(self.leftSoldierMap) do
		soldier:reCalcAttrByPassiveSkills(self.leftSoldierMap)
	end

	for _, soldier in pairs(self.rightSoldierMap) do
		soldier:reCalcAttrByPassiveSkills(self.rightSoldierMap)
	end
end

-- 清空某一战场的所有士兵
function BattleField:clearCampSoldierMap(camp)
	for anchKey, soldier in pairs(self[camp .. "SoldierMap"]) do
		soldier.associationSkills = {}
		for _, buff in ipairs(soldier.buffs) do
			buff:dispose()
		end
		soldier.buffs = {}

		soldier:clearStatus()
	end

	self[camp .. "SoldierMap"] = {}
end

function BattleField:pause(pause)
	self.hasPaused = pause
	for anchKey, soldier in pairs(self.leftSoldierMap) do
		soldier:pause(pause)
	end

	for anchKey, soldier in pairs(self.rightSoldierMap) do
		soldier:pause(pause)
	end
end

-- 更新士兵和大本营状态
function BattleField:update(diff)
	-- 先大本营更新, 对武将的属性进行修正
	if not self.hasPaused then
		self.leftCamp:updateFrame(diff)
	end
	-- 左边士兵从右上优先
	local leftSoldiers = table.values(self.leftSoldierMap)
	table.sort(leftSoldiers, function(a, b) 
			if a.position.x == b.position.x then
				return a.position.y > b.position.y
			else
				return a.position.x > b.position.x
			end
		end)
	for _, soldier in ipairs(leftSoldiers) do
		soldier:updateFrame(diff)
		-- 判断战斗结束, 避免平局
		if self:gameOver() then return end
	end

	if not self.hasPaused then
		self.rightCamp:updateFrame(diff)
	end
	-- 右边士兵从左上优先
	local rightSoldiers = table.values(self.rightSoldierMap)
	table.sort(rightSoldiers, function(a, b) 
			if a.position.x == b.position.x then
				return a.position.y > b.position.y
			else
				return a.position.x < b.position.x
			end
		end)
	for _, soldier in ipairs(rightSoldiers) do
		soldier:updateFrame(diff)
		-- 判断战斗结束, 避免平局
		if self:gameOver() then return end
	end
end

-- 士兵闲置
function BattleField:standbyAllSoldiers()
	for anchKey, soldier in pairs(self.leftSoldierMap) do
		soldier:onStandby()
	end

	for anchKey, soldier in pairs(self.rightSoldierMap) do
		soldier:onStandby()
	end
end

-- 得到自己正前方的队友
function BattleField:beforeXTeamer(soldier)
	if not soldier then return nil end

	local teamer = nil

	if soldier.camp == "left"  then
		-- 同一行
		for anchX = soldier.anchPoint.x + 1, self.column do
			local anchKey = "left" .. anchX .. soldier.anchPoint.y
			if self.leftSoldierMap[anchKey] then
				teamer = self.leftSoldierMap[anchKey]
				break
			end
		end
	else
		for anchX = soldier.anchPoint.x - 1, 1, -1 do
			local anchKey = "right" .. anchX .. soldier.anchPoint.y
			if self.rightSoldierMap[anchKey] then
				teamer = self.rightSoldierMap[anchKey]
				break
			end
		end
	end


	return teamer
end

-- 得到自己同一行前面的盟友
function BattleField:beforeLineTeamer(soldier)
	if not soldier then return nil end

	local teamer = nil

	local otherAnchY = soldier.anchPoint.y == 1 and 2 or 1
	if soldier.camp == "left"  then
		-- 同一行
		for anchX = soldier.anchPoint.x + 1, self.column do
			local anchKey = "left" .. anchX .. soldier.anchPoint.y
			if self.leftSoldierMap[anchKey] and self.leftSoldierMap[anchKey].hp > 0 then
				teamer = self.leftSoldierMap[anchKey]
				break
			end
		end
	else
		for anchX = soldier.anchPoint.x - 1, 1, -1 do
			local anchKey = "right" .. anchX .. soldier.anchPoint.y
			if self.rightSoldierMap[anchKey] and self.rightSoldierMap[anchKey].hp > 0 then
				teamer = self.rightSoldierMap[anchKey]
				break
			end
		end
	end


	return teamer
end

-- 得到自己前面的盟友
function BattleField:beforeTeamer(soldier)
	if not soldier then return nil end

	local teamer = nil

	local otherAnchY = soldier.anchPoint.y == 1 and 2 or 1
	if soldier.camp == "left"  then
		-- 同一行
		for anchX = soldier.anchPoint.x + 1, self.column do
			local anchKey = "left" .. anchX .. soldier.anchPoint.y
			if self.leftSoldierMap[anchKey] and self.leftSoldierMap[anchKey].hp > 0 then
				teamer = self.leftSoldierMap[anchKey]
				break
			end
		end
		-- 另一行
		for anchX = 1, self.column do
			local anchKey = "left" .. anchX .. otherAnchY
			if self.leftSoldierMap[anchKey] and self.leftSoldierMap[anchKey].hp > 0 then
				local xPos = self.leftSoldierMap[anchKey].position.x
				xPos = soldier.anchPoint.y == 1 and xPos + self.xPosOffset or xPos - self.xPosOffset
				if xPos > soldier.position.x then
					if not teamer or xPos < teamer.position.x then
						teamer = self.leftSoldierMap[anchKey]
						break
					end
				end
			end
		end
	else
		for anchX = soldier.anchPoint.x - 1, 1, -1 do
			local anchKey = "right" .. anchX .. soldier.anchPoint.y
			if self.rightSoldierMap[anchKey] and self.rightSoldierMap[anchKey].hp > 0 then
				teamer = self.rightSoldierMap[anchKey]
				break
			end
		end

		-- 另一行
		local otherAnchY = soldier.anchPoint.y == 1 and 2 or 1
		for anchX = self.column, 1, -1 do
			local anchKey = "right" .. anchX .. otherAnchY
			if self.rightSoldierMap[anchKey] and self.rightSoldierMap[anchKey].hp > 0 then
				local xPos = self.rightSoldierMap[anchKey].position.x
				xPos = soldier.anchPoint.y == 1 and xPos + self.xPosOffset or xPos - self.xPosOffset
				if xPos < soldier.position.x then
					if not teamer or xPos > teamer.position.x then
						teamer = self.rightSoldierMap[anchKey]
						break
					end
				end
			end
		end
	end


	return teamer
end

-- 得到自己后面的盟友
function BattleField:afterTeamer(soldier)
	if not soldier then return nil end

	local teamer = nil

	if soldier.camp == "left"  then
		for anchX = soldier.anchPoint.x - 1, 1, -1 do
			local anchKey = "left" .. anchX .. soldier.anchPoint.y
			if self.leftSoldierMap[anchKey] and self.leftSoldierMap[anchKey].hp > 0 then
				teamer = self.leftSoldierMap[anchKey]
				break
			end
		end

		-- 另一行
		local otherAnchY = soldier.anchPoint.y == 1 and 2 or 1
		for anchX = self.column, 1, -1 do
			local anchKey = "left" .. anchX .. otherAnchY
			if self.leftSoldierMap[anchKey] and self.leftSoldierMap[anchKey].hp > 0 then
				local xPos = self.leftSoldierMap[anchKey].position.x
				xPos = soldier.anchPoint.y == 1 and xPos + self.xPosOffset or xPos - self.xPosOffset
				if xPos < soldier.position.x then
					if not teamer or xPos > teamer.position.x then
						teamer = self.leftSoldierMap[anchKey]
						break
					end
				end
			end
		end
	else
		for anchX = soldier.anchPoint.x + 1, 4 do
			local anchKey = "right" .. anchX .. soldier.anchPoint.y
			if self.rightSoldierMap[anchKey] and self.rightSoldierMap[anchKey].hp > 0 then
				teamer = self.rightSoldierMap[anchKey]
				break
			end
		end

		-- 另一行
		local otherAnchY = soldier.anchPoint.y == 1 and 2 or 1
		for anchX = 1, self.column do
			local anchKey = "right" .. anchX .. otherAnchY
			if self.rightSoldierMap[anchKey] and self.rightSoldierMap[anchKey].hp > 0 then
				local xPos = self.rightSoldierMap[anchKey].position.x
				xPos = soldier.anchPoint.y == 1 and xPos + self.xPosOffset or xPos - self.xPosOffset
				if xPos > soldier.position.x then
					if not teamer or xPos < teamer.position.x then
						teamer = self.rightSoldierMap[anchKey]
						break
					end
				end
			end
		end
	end

	return teamer
end

-- 得到自己阵营的第一个(最前面做肉盾的那个), 如果自己是第一个, 返回nil
function BattleField:frontestTeamer(soldier)
	local teamer = soldier
	local preTeamer = teamer

	while teamer do
		teamer = self:beforeTeamer(preTeamer)
		if teamer then
			preTeamer = teamer
		else
			break
		end
	end

	return preTeamer == soldier and nil or preTeamer
end

-- 得到当前第一个敌人, 优先x距离,
function BattleField:beforeEnemy(soldier)
	local enemy,nearBest = nil,math.huge

	if soldier.camp == "left" then
		for anchKey,targetEnemy in pairs(self.rightSoldierMap) do
			if not enemy then enemy = targetEnemy end
			local tempDis = pGetDistance(soldier.position, targetEnemy.position)
			if nearBest > tempDis then
				nearBest = tempDis
				enemy = targetEnemy
			end

		end
		
	else
		for anchKey,targetEnemy in pairs(self.leftSoldierMap) do
			if not enemy then enemy = targetEnemy end
			local tempDis = pGetDistance(soldier.position, targetEnemy.position)
			if nearBest > tempDis then
				nearBest = tempDis
				enemy = targetEnemy
			end

		end

	end

	return enemy
end

-- 己方的第n个, 
function BattleField:getXposTeamer(soldier, xNo)
	local xPosOne = self:frontestTeamer(soldier)
	if xPosOne == soldier then return soldier end

	local teamer = xPosOne
	local preTeamer = teamer

	for no = 2, xNo do
		teamer = self:afterTeamer(preTeamer)
		if teamer then
			preTeamer = teamer 
		else
			break
		end
	end

	return teamer
end

function BattleField:getXposEnemy(soldier, xNo)
	local enemy = self:beforeEnemy(soldier)
	local preEnemy = enemy
	for no = 2, xNo do
		enemy = self:afterTeamer(preEnemy)
		if enemy then
			preEnemy = enemy
		else
			break
		end
	end

	-- 倒数第一个
	if xNo == 4 then
		return preEnemy
	else
		return enemy
	end
end

-- 得到当前行的所有敌人
function BattleField:getBeforeXEnemy(soldier)
	local enemies = {}

	if not soldier then return enemies end

	if soldier.camp == "left" then
		for anchX = 1, self.column do
			local anchKey = "right" .. anchX .. soldier.anchPoint.y
			if self.rightSoldierMap[anchKey] and self.rightSoldierMap[anchKey].hp > 0 then
				table.insert(enemies, self.rightSoldierMap[anchKey])
			end
		end
	else
		for anchX = 1, self.column do
			local anchKey = "left" .. anchX .. soldier.anchPoint.y
			if self.leftSoldierMap[anchKey] and self.leftSoldierMap[anchKey].hp > 0 then
				table.insert(enemies, self.rightSoldierMap[anchKey])
			end
		end
	end

	return enemies
end

-- 得到自己正前方的兵, 不分敌我
function BattleField:getBeforeObject(soldier)
	local before = self:beforeXTeamer(soldier)

	if not before then
		before = self:beforeEnemy(soldier)
	end

	return before
end

-- 获得某一纵列内的武将(不分敌我)
-- 对方的x中心在目标的[-60, 60]范围内
function BattleField:getSideObjects(centerSoldier)
	local objects = {}

	if not centerSoldier then return objects end

	table.insert(objects, centerSoldier)

	for anchKey, soldier in pairs(self[centerSoldier.camp .. "SoldierMap"]) do
		if centerSoldier:getAnchKey() ~= soldier:getAnchKey() then
			local xPos = soldier.position.x
			if soldier.anchPoint.y ~= centerSoldier.anchPoint.y then
				xPos = centerSoldier.anchPoint.y == 1 and xPos + self.xPosOffset or xPos - self.xPosOffset
			end

			if math.abs(xPos - centerSoldier.position.x) <= self.gridWidth / 2 and not soldier:isState("dead") then
				table.insert(objects, soldier)
			end
		end
	end

	return objects
end

-- 对方的x中心在目标的[-210, 210]范围内
function BattleField:getNearObjects(centerSoldier)
	local objects = {}

	if not centerSoldier then return objects end

	table.insert(objects, centerSoldier)

	for anchKey, soldier in pairs(self[centerSoldier.camp .. "SoldierMap"]) do
		if centerSoldier:getAnchKey() ~= soldier:getAnchKey() then
			local xPos = soldier.position.x
			if soldier.anchPoint.y ~= centerSoldier.anchPoint.y then
				xPos = centerSoldier.anchPoint.y == 1 and xPos + self.xPosOffset or xPos - self.xPosOffset
			end

			if math.abs(xPos - centerSoldier.position.x) <= self.gridWidth * 3 / 2 and not soldier:isState("dead") then
				table.insert(objects, soldier)
			end
		end
	end

	return objects
end

function BattleField:getBeforeRangeObjects(center, soldiers, distance)
	local objects = {}

	if not center then return objects end

	for _, soldier in ipairs(soldiers) do
		local xPos = (center.anchPoint.y == soldier.anchPoint.y) and soldier.position.x 
			or (center.anchPoint.y == 1 and soldier.position.x + self.xPosOffset or soldier.position.x - self.xPosOffset)
		if center.camp == "left" then
			if xPos - center.position.x <= distance then
				objects[#objects + 1] = soldier
			end
		else
			if center.position.x - xPos <= distance then
				objects[#objects + 1] = soldier
			end
		end
	end

	return objects
end

-- 得到当前点的对应的武将, 误差范围
function BattleField:getPointObjects(point)
	local fakeSoldier = { position = { x = point.x, y = point.y} }

	local objects = {}
	for anchKey, soldier in pairs(self.leftSoldierMap) do
		if self:getDistance(soldier, fakeSoldier) <= self.collisionPixel then
			table.insert(objects, soldier)
		end
	end

	for anchKey, soldier in pairs(self.rightSoldierMap) do
		if self:getDistance(soldier, fakeSoldier) <= self.collisionPixel then
			table.insert(objects, soldier)
		end
	end

	return objects
end

-- 得到某一边阵营所有的武将
function BattleField:getCampObjects(camp)
	local soldiers = table.values(self[camp .. "SoldierMap"])
	local alive = {}
	for i,soldier in ipairs(soldiers) do
		if not soldier:isState("dead") then
			table.insert(alive,soldier)
		end
	end
	return alive
end

-- 得到离自己最近的敌人
-- NOTE: 治疗兵的敌人是盟友
function BattleField:getAttackObject(soldier)
	-- 攻击类的兵
	return self:beforeEnemy(soldier)
end

function BattleField:gameOver()
	return table.nums(self.leftSoldierMap) == 0 or table.nums(self.rightSoldierMap) == 0
end

-- 计算结果星级
function BattleField:calculateGameResult()
	if table.nums(self.leftSoldierMap) == 0 then
		return 0
	end
	local starNum = 3
	--初始化时的总人数：game.role.leftMembers
	--当前回合中人数：table.nums(self.leftSoldierMap)
	local diedCount = game.role.leftMembers - table.nums(self.leftSoldierMap)
	local n = 1.0 * diedCount/game.role.leftMembers
	if n == 0 then
	elseif n > 0.5 then
		starNum = 1
	else
		starNum = 2
	end
	return starNum
end

function BattleField:getDistance(a, b)
	if not a or not b then return nil end

	local distancePower = math.pow(a.position.x - b.position.x, 2) + math.pow(a.position.y - b.position.y, 2)
	return math.sqrt(distancePower)
end

function BattleField:addSoldier(soldier)
	soldier.battleField = self
	self[soldier.camp .. "SoldierMap"][soldier:getAnchKey()] = soldier
	if soldier.skillOrder then
		checkTable(self, soldier.camp .. "SkillOrder")[soldier.skillOrder] = soldier
	end
end

function BattleField:removeSoldier(soldier)
	self:dispatchEvent({ name = "soldierDead", anchKey = soldier:getAnchKey(), camp = soldier.camp })
	
	self[soldier.camp .. "SoldierMap"][soldier:getAnchKey()] = nil
	if soldier.skillOrder then
		checkTable(self, soldier.camp .. "SkillOrder")[soldier.skillOrder] = nil
	end
end

function BattleField:checkCurSelectedSoldierAlive()
	if self.curSelectedSoldier:getState() == "dead" then
		self.curSelectedSoldier = nil
	end
end

function BattleField:dispose()
	if self.leftCamp then self.leftCamp:dispose() end
	if self.rightCamp then self.rightCamp:dispose() end

	for anchKey, soldier in pairs(self.leftSoldierMap) do
		soldier:dispose()
	end

	for anchKey, soldier in pairs(self.rightSoldierMap) do
		soldier:dispose()
	end
end

return BattleField