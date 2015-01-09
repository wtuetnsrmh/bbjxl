-- 开始战斗底部武将头像层
-- by yangkun
-- 2014.6.13

local GuideTipsLayer  = require("scenes.GuideTipsLayer")
require("scenes.home.hero.Components")

local HeroRes = "resource/ui_rc/hero/"
local BattleRes = "resource/ui_rc/battle/"

local StartBottomBarController = class("StartBottomBarController", function()
	return display.newSprite(BattleRes .. "bottom_bar.png")
end)

function StartBottomBarController:ctor(params)
	self.battle = params.battle
	self.battleField = params.battle.battleField
	self.size = self:getContentSize()

	self:loadHeros()
end

function StartBottomBarController:loadHeros()
	local heroNum = table.nums(self.battleField.leftSoldierMap)
	local xInterval = 40  --(self.size.width - heroNum * 120 ) / heroNum + 1
	local xBegin = (self.size.width - (heroNum - 1) * xInterval - heroNum * 106) / 2  --xInterval

	self.headCells = {}
	local index = 1
	for _, soldier in pairs(self.battleField.leftSoldierMap) do
		local headCell = self:createHeroUnit(soldier, false)
		headCell:scale(1.0):anch(0, 1):pos(xBegin + (index - 1) * (106 + xInterval), self.size.height - 15)
			:addTo(self)
		-- 武将的名字
		local evolutionCount = uihelper.getShowEvolutionCount(soldier.evolutionCount)
		ui.newTTFLabel({ text = soldier.name .. (evolutionCount > 0 and "+" .. evolutionCount or ""), size = 22, font = ChineseFont, color = uihelper.getEvolColor(soldier.evolutionCount) })
			:anch(0.5, 1):pos(headCell:getContentSize().width/2, 4):addTo(headCell)

		index = index + 1
		self.headCells[#self.headCells + 1] = headCell
	end
end

function StartBottomBarController:createHeroUnit(soldier, dead, assist)
	local headBtn
	headBtn = HeroHead.new(
		{
			type = soldier.type,
			wakeLevel = soldier.wakeLevel,
			star = soldier.star,
			evolutionCount = soldier.evolutionCount,
			callback = function() 
				game:resume()
				soldier:releaseSkill(true)

				headBtn:setEnable(false)
				-- 技能CD
				local headSize = headBtn:getLayer():getContentSize()
				local skillCdTimer = display.newProgressTimer(BattleRes .. "skillcd_mask.png", display.PROGRESS_TIMER_RADIAL)
				skillCdTimer:setReverseProgress(true)
				skillCdTimer:anch(0.5, 0.5):scale(1.0):pos(headSize.width / 2, headSize.height / 2):addTo(headBtn:getLayer())
				skillCdTimer:runAction(transition.sequence({
					CCProgressFromTo:create(soldier.unitData.talentSkillCd / 1000, 100, 0),
					CCRemoveSelf:create(),
					CCCallFunc:create(function() 
						-- headBtn:setEnable(true)
						soldier.skillCd = 0
					end),
				}))	
			end,
		})
	headBtn:setEnable(false)
	
	local btnSize = headBtn:getLayer():getContentSize()
	local unitData = unitCsv:getUnitByType(soldier.type)
	local skillData = skillCsv:getSkillById(unitData and unitData.talentSkillId or 0)

	if dead then
		headBtn.heroImage:setColor(ccc3(64,64,64))
	end

	-- 技能检测
	local skillable = false
	local scale1,scale2,scale3= 0.95 , 1.0, 1.0
	local angryUpdateHandle = self.battleField.leftCamp:addEventListener("updateAngryValue", function(event)
		if not skillData or dead then return end

		-- 检查是否可以释放技能
		local releasable = soldier:canReleaseSkill()	

		if releasable and not skillable then
			-- 可以释放技能
			skillable = true

			-- local sp = self:frameActionOnSprite()
			-- 	:scale(1)
			-- 	:pos(btnSize.width / 2, btnSize.height / 2)
			-- 	:addTo(headBtn:getLayer(), 1, 200)
		local actions = {}
		actions[#actions + 1] = CCScaleTo:create(0.5,scale1)
		actions[#actions + 1] = CCScaleTo:create(0.5,scale2)
		display.newSprite(BattleRes .. "yellow_frame1.png"):scale(scale1):pos(btnSize.width / 2, btnSize.height / 2)
			:addTo(headBtn:getLayer(), -10, 200)
			:runAction(CCRepeatForever:create(transition.sequence(actions)))

		elseif not releasable and skillable then
			-- 技能豆不够
			headBtn:getLayer():removeChildByTag(200)
			skillable = false
			headBtn:setEnable(false)
		end
	end)

	-- 开始战斗
	self.battle:addEventListener("battleStart", function(event)
		if dead then return end	

		if soldier.hp * 100 / soldier.maxHp <= 20 then
			-- 已经危险
			display.newSprite(BattleRes .. "red_frame4.png"):scale(1.0):pos(btnSize.width / 2, btnSize.height / 2)
				:addTo(headBtn:getLayer(), 1, 100)
		end

		-- 血量检测
		soldier:addEventListener("hpChangeRate", function(event)
			if event.origPercent > 20 and event.nowPercent <= 20 then
				-- 危险
				display.newSprite(BattleRes .. "red_frame4.png"):scale(1.0):pos(btnSize.width / 2, btnSize.height / 2)
					:addTo(headBtn:getLayer(), -1, 100)
			elseif event.origPercent <= 20 and event.nowPercent > 20 then
				-- 安全
				headBtn:getLayer():removeChildByTag(100)
			end
		end)

		soldier:addEventListener("startEveSkill", function(event) 
				game:pause()

				headBtn:setEnable(true)
				local guideTips = GuideTipsLayer.new({ node = headBtn:getLayer(), guideId = 1000, degree = 0, distance = 30, notDelay = true, opacity = 100 })
				guideTips:addTo(display.getRunningScene())
			end)

		-- 武将死亡
		soldier:addEventListener("soldierDead", function(event)
			headBtn:getLayer():removeChildByTag(100)
			headBtn:getLayer():removeChildByTag(200)

			headBtn.heroImage:setColor(ccc3(64,64,64))

			headBtn:setEnable(false)

			soldier:removeAllEventListenersForEvent("hpChangeRate")
			self.battleField.leftCamp:removeEventListener("updateAngryValue", angryUpdateHandle)

			return "__REMOVE__"
		end)
	end)

	-- 战斗阶段结束
	self.battle:addEventListener("battlePhaseEnd", function(event)
		headBtn:getLayer():removeChildByTag(100)
		headBtn:getLayer():removeChildByTag(200)
		self.battleField.leftCamp:removeEventListener("updateAngryValue", angryUpdateHandle)

		if soldier then
			soldier:removeAllEventListenersForEvent("hpChangeRate")
			soldier:removeAllEventListenersForEvent("soldierDead")
		end

		skillable = false	-- 技能标签去掉
		headBtn:setEnable(false)
	end)

	-- 战斗结束
	self.battle:addEventListener("battleEnd", function(event)
		headBtn:getLayer():removeChildByTag(100)
		headBtn:getLayer():removeChildByTag(200)
		
		headBtn:setEnable(false)
	end)

	return headBtn:getLayer()
end

function StartBottomBarController:onPause(bool)
	if bool then
		for id,headCell in pairs(self.headCells) do
			local children = headCell:getChildren()
			local childsNum = headCell:getChildrenCount()
			for index = 0, childsNum - 1 do
				local child = tolua.cast(children:objectAtIndex(index), "CCNode")
				transition.pauseTarget(child)
			end
		end
	else
		for id,headCell in pairs(self.headCells) do
			local children = headCell:getChildren()
			local childsNum = headCell:getChildrenCount()
			for index = 0, childsNum - 1 do
				local child = tolua.cast(children:objectAtIndex(index), "CCNode")
				transition.resumeTarget(child)
			end
		end
	end
end

function StartBottomBarController:frameActionOnSprite()

	display.addSpriteFramesWithFile(BattleRes.."kill_ready.plist", BattleRes.."kill_ready.png")
	local framesTable = {}
	for index = 1, 10 do
		local frameId = string.format("%02d", index)
		framesTable[#framesTable + 1] = display.newSpriteFrame("kill_ready_" .. frameId .. ".png")
	end
	local panimate = display.newAnimation(framesTable, 1.0/10)
	local sprite = display.newSprite(framesTable[1])
	sprite:playAnimationForever(panimate)
	return sprite
end

return StartBottomBarController