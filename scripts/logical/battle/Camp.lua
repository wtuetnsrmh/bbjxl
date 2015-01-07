local Camp = class("Camp")

function Camp:ctor(params)
	self.battle = params.battle

	-- 大本营自身属性
	self.camp = params.camp
	self.battleType = params.battleType

	-- 本方技能豆属性
	-- self.angryUnitNum = globalCsv:getFieldValue("initAngerValue")	-- 战斗一开始，奖励敌我双方各1格怒气
	self.angryUnitNum = params.angryUnitNum or 2
	self.angryMaxUnits = 15
	self.angryAccumulateTime = params.angryAccumulateTime or 0
	self.origAngryCD = params.angryCD or globalCsv:getFieldValue("angryCD")
	self.angryCD = self.origAngryCD

	self.skillIndex = 1
	self.activeSkills = {}

	self.isAutoFight = params.isAutoFight or false
	self.skillSoldier = nil

	self.eveSkillCount = 0

	self.passiveSkills = params.passiveSkills or {}
	self.beauties = params.beauties or {}

	self.skillRefCount = 0
	self.skillOrder = 1
end

function Camp:reset()
	-- 不继承怒气
	if globalCsv:getFieldValue("inheritAnger") == 0 then
		self.angryUnitNum = globalCsv:getFieldValue("initAngerValue")
		self.angryAccumulateTime = 0
	end

	for key, skill in pairs(self.activeSkills) do
		skill:dispose()
	end
	self.activeSkills = {}
	self.autoPveSkillSoldierAnchKey = nil
end

function Camp:updateFrame(diff)
	self:addAngryTime(self.battle.frame)

	local deleteSkill = {}
	for key, skill in pairs(self.activeSkills) do
		if not skill.finished then 
			skill:update(diff)
		else
			table.insert(deleteSkill, key)
		end
	end
	for _, deleteKey in ipairs(deleteSkill) do
		self.activeSkills[deleteKey] = nil
	end

	self:autoPlayerSkill()

	if self.battleType == BattleType.PvP then
		self:autoPvpSkill()
	elseif self.battleType == BattleType.Start then
		self:autoEveSkill()
	else
		self:autoPveSkill()
	end
end

function Camp:addSkill(skill)
	skill.primaryKey = self.skillIndex
	self.activeSkills[skill.primaryKey] = skill

	self.skillIndex = self.skillIndex + 1
end

-- 玩家自动战斗
function Camp:autoPlayerSkill()
	if self.camp ~= "left" or not self.isAutoFight then return end

	if not self.skillSoldier then
		if not self.battle.battleField.leftSkillOrder then
			--未设置技能顺序，随机释放
			local soldierMap = self.battle.battleField.leftSoldierMap
			local skillSoldiers = {}

			for _,soldier in pairs(soldierMap) do
				if soldier.unitData.talentSkillId > 0 then
					if soldier.skillCd > 0 then
						local releasable, releaseAngry = soldier:canReleaseSkill()

						-- 技能cd结束，还是可以释放技能
						if releaseAngry and (releaseAngry - self.angryUnitNum) *  self.angryCD <= soldier.skillCd then
							table.insert(skillSoldiers, soldier)
						end
					else
						table.insert(skillSoldiers, soldier)
					end
				end
			end

			local index = randomInt(1, #skillSoldiers)
			self.skillSoldier = skillSoldiers[index]
		else
			--设置技能顺序，按照技能顺序
			local soldierMap = self.battle.battleField.leftSkillOrder

			-- 如果左方没有武将，会死循环
			if table.nums(soldierMap) == 0 then
				return
			end

			while not self.skillSoldier do
				self.skillSoldier = soldierMap[self.skillOrder]
				self.skillOrder = self.skillOrder + 1
				if self.skillOrder > 5 then self.skillOrder = 1 end
			end
		end

	else
		-- 放技能的人已经挂了
		if self.skillSoldier:getState() == "dead" then
			self.skillSoldier = nil
		else 
			local releasable, releaseAngry = self.skillSoldier:canReleaseSkill()
			if releasable then
				self.skillSoldier:releaseSkill()
				self.skillSoldier:dispatchEvent({ name = "releaseSkill" })
				self.skillSoldier = nil
			end
		end
	end
end

-- 玩家自动战斗
function Camp:autoPvpSkill()
	if self.camp ~= "right" and self.battleType ~= BattleType.PvP or not self.battle.battleField.rightSkillOrder then return end

	if not self.skillSoldier then
		local soldierMap = self.battle.battleField.rightSkillOrder
		if table.nums(soldierMap) == 0 then
			return
		end

		while not self.skillSoldier do
			self.skillSoldier = soldierMap[self.skillOrder]
			self.skillOrder = self.skillOrder + 1
			if self.skillOrder > 5 then self.skillOrder = 1 end
		end
	else
		-- 放技能的人已经挂了
		if self.skillSoldier:getState() == "dead" then
			self.skillSoldier = nil
		else 
			local releasable, releaseAngry = self.skillSoldier:canReleaseSkill()
			if releasable then
				self.skillSoldier:releaseSkill()
				self.skillSoldier = nil
			end
		end
	end
end

function Camp:autoPveSkill()
	if self.camp ~= "right" then return end

	local soldierMap = self.battle.battleField.rightSoldierMap
	local skillSoldier = soldierMap[self.autoPveSkillSoldierAnchKey]

	-- 如果当前还没有选择武将, 或者选择的武将已经挂掉
	if not skillSoldier then
		local skillSoldiers = {}
		for key, soldier in pairs(soldierMap) do
			if soldier.skillable and soldier.skillWeight > 0 then
				table.insert(skillSoldiers, key)
			end
		end

		if table.nums(skillSoldiers) > 0 then
			table.sort(skillSoldiers, function(a,b) return soldierMap[a].skillWeight < soldierMap[b].skillWeight end)

			self.autoPveSkillSoldierAnchKey = skillSoldiers[1]
			skillSoldier = soldierMap[self.autoPveSkillSoldierAnchKey]
			skillSoldier.skillWeight = skillSoldier.skillWeight + 10
			if skillSoldier.firstSkillCd then
				skillSoldier.skillCd = skillSoldier.startSkillCdTime	
				skillSoldier.firstSkillCd = false
			else
				skillSoldier.skillCd = skillSoldier.skillCdTime
			end	
		end
	elseif skillSoldier.skillCd > 0 then
		skillSoldier.skillCd = skillSoldier.skillCd - self.battle.frame
	else
		if skillSoldier:canReleaseSkillOne() then
			skillSoldier:releaseSkill(false)
			self.autoPveSkillSoldierAnchKey = nil
		end
	end
end

-- 开始战斗放技能
function Camp:autoEveSkill()
	local soldierMap = self.battle.battleField[self.camp .. "SoldierMap"]
	local skillSoldier = soldierMap[self.autoEveSkillSoldierAnchKey]

	-- 如果当前还没有选择武将, 或者选择的武将已经挂掉
	if not skillSoldier then
		local skillSoldiers = {}
		for key, soldier in pairs(soldierMap) do
			if soldier.skillable and soldier.skillWeight > 0 then
				table.insert(skillSoldiers, key)
			end
		end

		if table.nums(skillSoldiers) > 0 then
			table.sort(skillSoldiers, function(a,b) return soldierMap[a].skillWeight < soldierMap[b].skillWeight end)

			self.autoEveSkillSoldierAnchKey = skillSoldiers[1]
			skillSoldier = soldierMap[self.autoEveSkillSoldierAnchKey]
			skillSoldier.skillWeight = skillSoldier.skillWeight + 10
			if self.eveSkillCount == 0 then
				self.skillCdDetect = skillSoldier.startSkillCdTime	
			else
				self.skillCdDetect = skillSoldier.skillCdTime
			end	
			self.eveSkillCount = self.eveSkillCount + 1
		end
	elseif self.skillCdDetect > 0 then
		self.skillCdDetect = self.skillCdDetect - self.battle.frame
	else
		if skillSoldier:canReleaseSkillOne() then
			if skillSoldier.camp == "left" then
				skillSoldier:dispatchEvent({name = "startEveSkill"})
			else
				skillSoldier:releaseSkill(false)
			end
		end
		
		self.autoEveSkillSoldierAnchKey = nil
	end
end

-- deltaUnits: 单位 格
function Camp:addAngryUnit(deltaUnits)
	local deltaTime = deltaUnits * self.angryCD

	self:addAngryTime(deltaTime)
end

function Camp:addAngryTime(deltaTime)
	if self.angryUnitNum >= self.angryMaxUnits then 
		self:updateAngryValue({ angryUnitNum = self.angryUnitNum, angryAccumulateTime = self.angryAccumulateTime })
		return 
	end

	self.angryAccumulateTime = self.angryAccumulateTime + deltaTime
	
	local skillDetectInterval = self.angryCD 
	local deltaUnits = 0
	while self.angryAccumulateTime >= skillDetectInterval do
		deltaUnits = deltaUnits + 1
		self.angryAccumulateTime = self.angryAccumulateTime - skillDetectInterval
	end

	if deltaUnits + self.angryUnitNum >= self.angryMaxUnits then
		deltaUnits = self.angryMaxUnits - self.angryUnitNum
	end

	self.angryUnitNum = self.angryUnitNum + deltaUnits
	self:updateAngryValue({ angryUnitNum = self.angryUnitNum, angryAccumulateTime = self.angryAccumulateTime })
end

-- 释放技能的时候, 消耗技能豆
function Camp:consumeAngryValue(num)
	self.angryUnitNum = self.angryUnitNum - num
	self:updateAngryValue({ angryUnitNum = self.angryUnitNum, angryAccumulateTime = self.angryAccumulateTime })
end

function Camp:updateAngryValue(params)
end

function Camp:dispose()
	for key, skill in pairs(self.activeSkills) do
		skill:dispose()
	end
	self.activeSkills = {}
end

return Camp