local BottomBarController = class("BottomBarController", function()
	return display.newSprite(BattleRes .. "bottom_bar.png")
end)

function BottomBarController:ctor(params)
	self.battle = params.battle
	self.battleField = params.battle.battleField
	self.size = self:getContentSize()

	self:loadHeros()
end

function BottomBarController:loadHeros()
	local heroNum = table.nums(self.battleField.leftSoldierMap)
	local xInterval = 40
	local xBegin = (self.size.width - (heroNum - 1) * xInterval - heroNum * 106) / 2

	local soldiers = table.values(self.battleField.leftSoldierMap)
	table.sort(soldiers, function(a, b)
		local aValue = (a.assistHero and 1 or 0) * 100 + game.role:getHeroSlot(a.id)
		local bValue = (b.assistHero and 1 or 0) * 100 + game.role:getHeroSlot(b.id)

		return aValue < bValue
	end)

	self.headCells = {}
	for index, soldier in ipairs(soldiers) do
		local headCell = self:createHeroUnit(soldier)
		headCell:scale(1.0):anch(0, 1):pos(xBegin + (index - 1) * (106 + xInterval), self.size.height - 15)
			:addTo(self)
		-- 武将的名字
		local unitData = unitCsv:getUnitByType(soldier.type)

		local name = unitData.name
		if soldier.assistHero then name = string.format("友·%s", unitData.name) end

		local evolutionCount = uihelper.getShowEvolutionCount(soldier.evolutionCount)
		name = name .. (evolutionCount > 0 and "+" .. evolutionCount or "")
		ui.newTTFLabel({ text = name, size = 22, font = ChineseFont, color = uihelper.getEvolColor(soldier.evolutionCount) })
			:anch(0.5, 1):pos(headCell:getContentSize().width / 2, 4):addTo(headCell)

		self.headCells[#self.headCells + 1] = headCell
	end
end

function BottomBarController:createHeroUnit(soldier)
	local headBtn 
	headBtn = HeroHead.new(
		{
			type = soldier.type,
			wakeLevel = soldier.wakeLevel,
			star = soldier.star,
			evolutionCount = soldier.evolutionCount,
			doubleClick = true,
			swallowsTouches = true,
			clickFun = function()
				self.battleField.curSelectedSoldier = soldier
				print("clickFun")
			end,
			callback = function() 
				if soldier:releaseSkill() then
					headBtn:getLayer():removeChildByTag(200)
					soldier:dispatchEvent({ name = "releaseSkill" })
				end
			end,
		})
	headBtn:setEnable(false)
	
	local btnSize = headBtn:getLayer():getContentSize()
	local unitData = unitCsv:getUnitByType(soldier.type)
	local skillData = skillCsv:getSkillById(unitData and unitData.talentSkillId or 0)

	-- 技能检测
	local skillable = false
	local angryUpdateHandle

	-- 开始战斗
	self.battle:addEventListener("battleStart", function(event)
		local scale1,scale2,scale3= 1.0, 0.95, 1.0
		angryUpdateHandle = self.battleField.leftCamp:addEventListener("updateAngryValue", function(event)
			if not skillData or soldier.hp <= 0 then return end

			-- 检查是否可以释放技能
			local releasable = soldier:canReleaseSkill()	

			if releasable and not skillable then
				-- 可以释放技能
				skillable = true

				headBtn:setEnable(not (self.battle.battleType==BattleType.PvP))

				local actions = {}
				actions[#actions + 1] = CCScaleTo:create(0.5,scale1)
				actions[#actions + 1] = CCScaleTo:create(0.5,scale2)
				display.newSprite(BattleRes .. "yellow_frame1.png"):scale(scale1):pos(btnSize.width / 2-1, btnSize.height / 2-3)
					:addTo(headBtn:getLayer(), 0, 200)
					:runAction(CCRepeatForever:create(transition.sequence(actions)))

				-- 释放技能提示, 自己人才提示
				if game.guideId == 1008 then
					game:addGuideNode({node = headBtn:getLayer(), notDelay = true,
						beginFunc = function() game:pause() end,
						endFunc = function() game:resume() end,
						guideIds = {1008, }
					})
				end
			elseif not releasable and skillable then
				-- 技能豆不够
				headBtn:getLayer():removeChildByTag(200)
				skillable = false
				headBtn:setEnable(false)
			end
		end)
	
		local hpLightCount = 40
		if soldier.hp > 0 and soldier.hp * 100 / soldier.maxHp <= hpLightCount then
			-- 已经危险
			display.newSprite(BattleRes .. "red_frame4.png"):scale(scale3):pos(btnSize.width / 2 -1, btnSize.height / 2)
				:addTo(headBtn:getLayer(), -1, 100)
		end

		-- 血量检测
		soldier:addEventListener("hpChangeRate", function(event)
			if event.origPercent > hpLightCount and event.nowPercent <= hpLightCount then
				-- 危险
				display.newSprite(BattleRes .. "red_frame4.png"):scale(scale3):pos(btnSize.width / 2 -1, btnSize.height / 2)
					:addTo(headBtn:getLayer(), -1, 100)
			elseif event.origPercent <= hpLightCount and event.nowPercent > hpLightCount then
				-- 安全
				headBtn:getLayer():removeChildByTag(100)
			end
		end)

		-- 释放技能
		soldier:addEventListener("releaseSkill", function(event)
			headBtn:setEnable(false)
			-- 技能CD
			local headSize = headBtn:getLayer():getContentSize()
			local skillCdTimer = display.newProgressTimer(BattleRes .. "skillcd_mask.png", display.PROGRESS_TIMER_RADIAL)
			skillCdTimer:setReverseProgress(true)
			skillCdTimer:anch(0.5, 0.5):scale(1.0):pos(headSize.width / 2, headSize.height / 2):addTo(headBtn:getLayer(), -1, 300)
			skillCdTimer:runAction(transition.sequence({
				CCProgressFromTo:create(soldier.unitData.talentSkillCd / 1000, 100, 0),
				CCRemoveSelf:create(),
				CCCallFunc:create(function() 
					headBtn:setEnable(not (self.battle.battleType==BattleType.PvP))
					soldier.skillCd = 0
				end),
			}))	
		end)

		-- 武将死亡
		soldier:addEventListener("soldierDead", function(event)
			headBtn:getLayer():removeChildByTag(100)
			headBtn:getLayer():removeChildByTag(200)
			headBtn:getLayer():removeChildByTag(300)

			local frameSize=headBtn:getLayer():getContentSize()
			display.newSprite("resource/ui_rc/expedition/mask_dead.png"):anch(0.5, 0.5):pos(frameSize.width/2,frameSize.height/2)
				:addTo(headBtn:getLayer())
			-- headBtn.heroImage:setColor(ccc3(64,64,64))

			headBtn:setEnable(false)

			soldier:removeAllEventListenersForEvent("hpChangeRate")
			soldier:removeAllEventListenersForEvent("releaseSkill")
			self.battleField.leftCamp:removeEventListener("updateAngryValue", angryUpdateHandle)

			-- 清空当前选择的武将
			self.battleField:checkCurSelectedSoldierAlive()

			return "__REMOVE__"
		end)
	end)

	-- 战斗结束
	self.battle:addEventListener("battleEnd", function(event)
		headBtn:getLayer():removeChildByTag(100)
		headBtn:getLayer():removeChildByTag(200)
		headBtn:getLayer():removeChildByTag(300)

		self.battleField.leftCamp:removeEventListener("updateAngryValue", angryUpdateHandle)

		if soldier.hp > 0 then
			soldier:removeAllEventListenersForEvent("hpChangeRate")
			soldier:removeAllEventListenersForEvent("soldierDead")
			soldier:removeAllEventListenersForEvent("releaseSkill")
		end

		skillable = false	-- 技能标签去掉
		headBtn:setEnable(false)
	end)

	return headBtn:getLayer()
end

function BottomBarController:onPause(bool)
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

function BottomBarController:frameActionOnSprite()

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

return BottomBarController