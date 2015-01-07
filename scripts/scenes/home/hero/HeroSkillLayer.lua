local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"

local HeroSkillChooseLayer = import(".HeroSkillChooseLayer")

local HeroSkillLayer = class("HeroSkillLayer", function(params)
	return display.newLayer(GlobalRes .. "bottom_bg.png")
end)

function HeroSkillLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -129
	self.hero = params.hero
	self.closeCallback = params.closeCallback

	self.fromChoose = params.fromChoose or false
	self.chooseHeroIds = {}
	if self.fromChoose then
		for index = 1, 5 do
			local hero
			if game.role.slots[tostring(index)] then
				local hero = game.role.heros[game.role.slots[tostring(index)].heroId]
				if hero then self.chooseHeroIds[index] = hero end
			end
		end
	end

	self.size = self:getContentSize()

	self:anch(0, 0):pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1,bg = HomeRes .. "home.jpg"})

	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority})
	:anch(0,1):pos(0,display.height):addTo(self)

	self.closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
				if self.layer == "main" then
					self:getLayer():removeSelf()
				else
					self:showMainLayer()
				end
				self.closeCallback()
			end,
		}):getLayer()
	self.closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self, 100)

	-- 右侧按钮
	local tabLabel = display.newSprite(GlobalRes .. "tab_selected.png")
	tabLabel:anch(0, 0.5):pos(self:getContentSize().width - 14, 480):addTo(self, 100)
	local btnSize = tabLabel:getContentSize()

	display.newSprite(GlobalRes.."tab_arrow.png"):anch(1,0.5):pos(10, btnSize.height/2)
		:addTo(tabLabel)

	ui.newTTFLabelWithStroke({ text = "技能", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(tabLabel)
	self.curIndex = 1

	self:showMainLayer()
end

function HeroSkillLayer:onEnter()
	self:checkGuide()
end

function HeroSkillLayer:checkGuide(remove)
	--升级按钮
	game:addGuideNode({node = self.levelUpBtn, remove = remove,
		guideIds = {1049, 1051, 501}
	})
	--被动技能
	game:addGuideNode({node = self.passiveBtns[1], remove = remove,
		guideIds = {1050}
	})
	--关闭按钮
	game:addGuideNode({node = self.closeBtn, remove = remove,
		guideIds = {1052}
	})
end

function HeroSkillLayer:onExit()
	self:checkGuide(true)
end
	

function HeroSkillLayer:showMainLayer(lastSkillId)
	if self.mainLayer then
		self.mainLayer:removeSelf()
		self.rightBg = nil
	end

	self.layer = "main"
	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.size):addTo(self)

	self.unitData = self.hero.unitData

	self:initLeftLayer(lastSkillId)
end

function HeroSkillLayer:chooseOtherHero()
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end

	self.layer = "choose"
	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.size):addTo(self)

	local chooseLayer = HeroSkillChooseLayer.new({ priority = self.priority, parent = self })
	chooseLayer:anch(0.5, 0):pos(self.size.width / 2, 5):addTo(self.mainLayer)
end

function HeroSkillLayer:initLeftLayer(lastSkillId)
	local leftBg = display.newSprite(HeroRes .. "skill/left_bg.png")
	leftBg:anch(0, 0):pos(25, 25):addTo(self.mainLayer)

	local bgSize =leftBg:getContentSize()


	local xLeftOffset = 18
	-- 头部信息
	local head = HeroHead.new({ type = self.unitData.type, wakeLevel = self.hero.wakeLevel, star = self.hero.star, evolutionCount = self.hero.evolutionCount }):getLayer()
	head:anch(0, 1):scale(0.9):pos(xLeftOffset, bgSize.height - 15):addTo(leftBg)
	local heroName = self.hero:getHeroName()
	local name = ui.newTTFLabel({ text = heroName, size = 28, color = uihelper.getEvolColor(self.hero.evolutionCount), font = ChineseFont })
	name:anch(0, 1):pos(130, bgSize.height - 23):addTo(leftBg)

	local titleBg = display.newSprite(HeroRes .. "skill/level_bar.png"):anch(0, 1):pos(130, bgSize.height - 62):addTo(leftBg)
	ui.newTTFLabel({ text = string.format("Lv.%d", self.hero.level), size = 20, })
		:anch(0.5, 0.5):pos(titleBg:getContentSize().width/2, titleBg:getContentSize().height/2):addTo(titleBg)

	-- local professionName = { [1] = "步兵", [3] = "骑兵", [4] = "弓兵", [5] = "军师" }
	-- local campName = { [1] = "群雄", [2] = "魏国", [3] = "蜀国", [4] = "吴国" }

	-- ui.newTTFLabel({ text = campName[self.unitData.camp], size = 22 })
	-- 	:anch(1, 0.5):pos(200, bgSize.height - 57):addTo(leftBg)
	-- ui.newTTFLabel({ text = professionName[self.unitData.profession], size = 22})
	-- 	:anch(0, 0.5):pos(220, bgSize.height - 57):addTo(leftBg)
	-- local changeBtn = DGBtn:new(GlobalRes, {"small_normal.png", "small_selected.png"},
	-- 	{	
	-- 		text = { text = "换将", size = 24, font = ChineseFont },
	-- 		priority = self.priority,
	-- 		callback = function()
	-- 			self:chooseOtherHero()
	-- 		end,
	-- 	}):getLayer()
	-- changeBtn:anch(0.5, 0):pos(210, bgSize.height - 125):addTo(leftBg)

	self.skillRadio = DGRadioGroup:new()
	-- 必杀技
	local titleBg = display.newSprite(HeroRes .. "title_bg.png")
	titleBg:anch(0, 1):pos(xLeftOffset, bgSize.height - 118):addTo(leftBg)
	ui.newTTFLabel({ text = "必杀技", size = 20, font = ChineseFont }):addTo(titleBg)
		:anch(0, 0.5):pos(10, titleBg:getContentSize().height / 2)

	local iconSize = 56
	if self.unitData.talentSkillId > 0 then
		local skillBtn = DGBtn:new(HeroRes, {"skill/skill_normal.png", "skill/skill_selected.png"},
			{
				id = self.unitData.talentSkillId,
				selectable = true,
				priority = self.priority-1,
				disableCallback = function() print(3298237) end,
				callback = function()
					self.curIndex = 1
					self:initRightLayer(self.unitData.talentSkillId, -1)
				end,	
			}, self.skillRadio):getLayer()
		skillBtn:anch(0.5, 1):pos(bgSize.width / 2, bgSize.height - 153):addTo(leftBg)

		local btnSize = skillBtn:getContentSize()
		local skillData = skillCsv:getSkillById(self.unitData.talentSkillId)
		local skillIcon = display.newSprite(skillData.icon)
		skillIcon:scale(iconSize/skillIcon:getContentSize().height):anch(0, 0.5):pos(26, btnSize.height / 2 + 2):addTo(skillBtn, -3)

		ui.newTTFLabel({ text = skillData.name, size = 26, font = ChineseFont, color = uihelper.hex2rgb("#7a533d") })
			:anch(0, 1):pos(100, btnSize.height - 10):addTo(skillBtn)
		local skillLevel = self.hero.skillLevels[tostring(skillData.skillId)] or 1
		ui.newTTFLabel({ text = "Lv." .. skillLevel, size = 20 })
			:anch(0, 0):pos(100, 14):addTo(skillBtn)

		if self.hero:canSkillUp({self.unitData.talentSkillId}) then
			uihelper.newMsgTag(skillBtn, ccp(-10, -10))
		end
	end

	self.passiveBtns = {}
	-- 被动技能
	local titleBg = display.newSprite(HeroRes .. "title_bg.png")
	titleBg:anch(0, 1):pos(xLeftOffset, bgSize.height - 236):addTo(leftBg)
	ui.newTTFLabel({ text = "被动技", size = 20, font = ChineseFont }):addTo(titleBg)
		:anch(0, 0.5):pos(10, titleBg:getContentSize().height / 2)
	
	for skillIndex = 1, 3 do
		local skillId = self.unitData["passiveSkill" .. skillIndex]
		local isOpen = globalCsv:getFieldValue("passiveSkillLevel" .. skillIndex) <= self.hero.evolutionCount
		if self.unitData["passiveSkill" .. skillIndex] > 0 then
			local buttonRes = isOpen and {"skill/skill_normal.png", "skill/skill_selected.png", "skill/skill_disabled.png"}
				or {"skill/skill_disabled.png", "skill/skill_halo.png", "skill/skill_disabled.png"}
			local skillBtn = DGBtn:new(HeroRes, buttonRes,
				{
					id = skillId + 10000,
					selectable = true,
					priority = self.priority-1,
					callback = function()
						self.curIndex = skillIndex + 1
						self:initRightLayer(skillId + 10000, globalCsv:getFieldValue("passiveSkillLevel" .. skillIndex))
					end,	
				}, self.skillRadio)
			skillBtn:getLayer():anch(0.5, 1):pos(bgSize.width / 2, bgSize.height - 271 - (skillIndex - 1) * 85)
				:addTo(leftBg)
			self.passiveBtns[skillIndex] = skillBtn:getLayer()

			local btnSize = skillBtn:getLayer():getContentSize()
			local skillData = skillPassiveCsv:getPassiveSkillById(skillId)

			local skillIcon = display.newSprite(skillData.icon)
			skillIcon:scale(iconSize/skillIcon:getContentSize().height):anch(0, 0.5):pos(26, btnSize.height / 2 + 2):addTo(skillBtn:getLayer(), -3)

			ui.newTTFLabel({ text = skillData.name, size = 26, font = ChineseFont, color = uihelper.hex2rgb("#3c352f") })
				:anch(0, 1):pos(100, btnSize.height - 10):addTo(skillBtn:getLayer())
			if globalCsv:getFieldValue("passiveSkillLevel" .. skillIndex) <= self.hero.evolutionCount then
				local skillLevel = self.hero.skillLevels[tostring(skillData.skillId + 10000)] or 1
				ui.newTTFLabel({ text = "Lv." .. skillLevel, size = 20 })
					:anch(0, 0):pos(100, 14):addTo(skillBtn:getLayer())
			else
				ui.newTTFLabel({ text = "未开启", size = 26 })
					:anch(0, 0.5):pos(230, btnSize.height / 2):addTo(skillBtn:getLayer())
			end

			if self.hero:canSkillUp({skillId + 10000}) then
				uihelper.newMsgTag(skillBtn:getLayer(), ccp(-10, -10))
			end
		end
	end

	local clickBtnId = lastSkillId or self.unitData.talentSkillId
	if clickBtnId > 0 then
		self.skillRadio:chooseById(clickBtnId, true)
	end

	-- 来自点将则加翻页
	if self.fromChoose then
		local prevHero, nextHero, hasFound
		for index = 1, 5 do
			local hero = self.chooseHeroIds[index]
			if hero then
				if hasFound then nextHero = hero break end
				if hero.id == self.hero.id then hasFound = true end
				if not hasFound then prevHero = hero end
			end
		end

		local layerSize = leftBg:getContentSize()

		if prevHero then
			self.leftBtn = DGBtn:new(HeroRes, {"switch_normal.png", "switch_selected.png"},
				{
					touchScale = {2, 2},
					priority = self.priority,
					callback = function()
						if prevHero then
							self.hero = prevHero
							self:showMainLayer()
						end
					end,
				}):getLayer()
			self.leftBtn:scale(1):rotation(180):anch(0.5, 0.5):pos(30, layerSize.height / 2+18):addTo(self.mainLayer,1)
		end

		if nextHero then
			self.rightBtn = DGBtn:new(HeroRes, {"switch_normal.png", "switch_selected.png"},
				{
					touchScale = {2, 2},
					priority = self.priority,
					callback = function()
						if nextHero then
							self.hero = nextHero
							self:showMainLayer()
						end
					end,
				}):getLayer()
			self.rightBtn:scale(1):anch(0.5, 0.5):pos(layerSize.width+40, layerSize.height / 2+18):addTo(self.mainLayer,1)
		end
	end

end

function HeroSkillLayer:initRightLayer(skillId, needEvolution)
	if self.rightBg then
		self.rightBg:removeSelf()
	end

	self.rightBg = display.newSprite(HeroRes .. "info/detail_rightbg.png")
	self.rightBg:anch(1, 0):pos(self.size.width - 25, 25):addTo(self.mainLayer)

	local bgSize = self.rightBg:getContentSize()
	local isOpen = needEvolution <= self.hero.evolutionCount

	local skillData
	if skillId > 10000 then
		skillData = skillPassiveCsv:getPassiveSkillById(skillId - 10000)
	else
		skillData = skillCsv:getSkillById(skillId)
	end
	local skillLevel = isOpen and (self.hero.skillLevels[tostring(skillId)] or 1) or 1

	local upperBg = display.newSprite(HeroRes .. "skill/skill_desc_bg.png")
	upperBg:anch(0.5, 1):pos(bgSize.width/2, bgSize.height-12):addTo(self.rightBg)
	local xPos, yPos = 20, 307
	-- 当前技能
	local text = ui.newTTFLabel({ text = "当前技能", size = 20, color = uihelper.hex2rgb("#eeeeee")})
	text:anch(0, 1):pos(xPos, yPos):addTo(upperBg)
	yPos = yPos - text:getContentSize().height - 4
	--名称
	text = ui.newTTFLabel({ text = string.format("%s   Lv.%d", skillData.name, skillLevel), size = 20, color = uihelper.hex2rgb("#edb833") })
	text:anch(0, 1):pos(xPos, yPos):addTo(upperBg)
	yPos = yPos - text:getContentSize().height
	if not isOpen then
		ui.newTTFLabel({ text = string.format("武将进化到%s时激活", uihelper.getEvolColorDesc(needEvolution)), size = 18, color = uihelper.hex2rgb("#7ce810") })
			:anch(0, 0):pos(212, yPos):addTo(upperBg)
	end
	--间隔线
	yPos = yPos - 7
	display.newSprite(HeroRes .. "skill/splitter.png"):anch(0.5, 1):pos(upperBg:getContentSize().width/2, yPos):addTo(upperBg)
	
	--描述
	local desc, skillLevelData
	if skillId > 10000 then
		desc = skillPassiveCsv:getDescByLevel(skillId - 10000, skillLevel)
		skillLevelData = skillPassiveLevelCsv:getDataByLevel(skillId - 10000, skillLevel + 1)
	else
		desc = skillCsv:getDescByLevel(skillId, skillLevel)
		skillLevelData = skillLevelCsv:getDataByLevel(skillId, skillLevel + 1)
	end

	uihelper.createLabel({ text = desc, width = 380, size = 18, color = uihelper.hex2rgb("#eeeeee") })
		:anch(0, 1):pos(xPos, yPos - 7):addTo(upperBg)

	yPos = 153
	-- 下级技能
	local nextSkillLevel = skillLevel + 1
	text = ui.newTTFLabel({ text = "下级技能", size = 20, color = uihelper.hex2rgb("#eeeeee")})
		:anch(0, 1):pos(xPos, yPos):addTo(upperBg)
	yPos = yPos - text:getContentSize().height - 4
	if skillData.levelLimit > 1 and nextSkillLevel > skillData.levelLimit then
		ui.newTTFLabel({text = "恭喜你! 当前技能已达到最高级", size = 28, })
			:anch(0.5, 1):pos(bgSize.width / 2, yPos):addTo(upperBg)
		return
	elseif nextSkillLevel > skillData.levelLimit then
		ui.newTTFLabel({text = "当前技能不能升级", size = 28, })
			:anch(0.5, 0):pos(bgSize.width / 2, yPos):addTo(upperBg)
		return
	end
	text = ui.newTTFLabel({ text = string.format("%s   Lv.%d", skillData.name, nextSkillLevel), size = 20, color = uihelper.hex2rgb("#edb833") })
	text:anch(0, 1):pos(xPos, yPos):addTo(upperBg)
	yPos = yPos - text:getContentSize().height
	if not isOpen then
		ui.newTTFLabel({ text = string.format("武将进化到%s时激活", uihelper.getEvolColorDesc(needEvolution)), size = 18, color = uihelper.hex2rgb("#7ce810") })
			:anch(0, 0):pos(212, yPos):addTo(upperBg)
	end
	--间隔线
	yPos = yPos - 7
	display.newSprite(HeroRes .. "skill/splitter.png"):anch(0.5, 1):pos(upperBg:getContentSize().width/2, yPos):addTo(upperBg)
	
	local desc
	if skillId > 10000 then
		desc = skillPassiveCsv:getDescByLevel(skillId - 10000, nextSkillLevel)
	else
		desc = skillCsv:getDescByLevel(skillId, nextSkillLevel)
	end

	uihelper.createLabel({ text = desc, width = 380, size = 18, color = uihelper.hex2rgb("#eeeeee") })
		:anch(0, 1):pos(xPos, yPos - 7):addTo(upperBg)

	-- 消耗材料
	local materialBg = display.newSprite(HeroRes .. "skill/material_bg.png")
	materialBg:anch(0.5, 0):pos(bgSize.width/2, 16):addTo(self.rightBg)
	local matBgSize = materialBg:getContentSize()
	
	local conditionOk = true
	local index = 1
	local items = skillLevelData.items or {}
	for index, itemData in pairs(items) do
		local itemId = tonum(itemData[1])
		local num = tonum(itemData[2])
		local itemCount = game.role.items[itemId] and game.role.items[itemId].count or 0

		local btn = ItemIcon.new({ itemId = itemId,
			priority = self.priority,
			callback = function()
				local ItemTipsLayer = require("scenes.home.ItemTipsLayer")
				local itemTips = ItemTipsLayer.new({
					priority = self.priority - 10,
					itemId = itemId,
					itemNum = itemCount,
					closeCallback = function()
						self:showMainLayer()
					end,
				})
				display.getRunningScene():addChild(itemTips:getLayer())
			end
		}):getLayer()

		if itemCount < num then
			if conditionOk then conditionOk = false end
		end

		btn:anch(0, 0):scale(73 / btn:getContentSize().width)
			:pos(52 + (index - 1) * 125, 66):addTo(materialBg)
		ui.newTTFLabelWithStroke({ text = string.format("%d/%d", itemCount, num), size = 18, strokeColor = display.COLOR_FONT,
			color = itemCount >= num and display.COLOR_WHITE or display.COLOR_RED })
			:anch(1, 0):pos(123 + (index - 1) * 125, 66):addTo(materialBg)
	end		

	local costBg = display.newSprite(HeroRes .. "skill/skill_cost_bg.png")
	costBg:anch(0, 0):pos(10, 10):addTo(materialBg)

	local xPos, yPos = 10, costBg:getContentSize().height/2
	local text = ui.newTTFLabel({ text = "消耗:", size = 20 }):anch(0, 0.5):pos(xPos, yPos):addTo(costBg)
	xPos = xPos + text:getContentSize().width
	text = ui.newTTFLabel({ text = skillLevelData.money or 0, size = 20, 
		color = game.role.money < skillLevelData.money and display.COLOR_RED or display.COLOR_WHITE })
		:anch(0, 0.5):pos(xPos, yPos):addTo(costBg)
	xPos = xPos + text:getContentSize().width + 2
	local moneyIcon = display.newSprite(GlobalRes .. "yinbi.png"):anch(0, 0.5):pos(xPos, yPos):addTo(costBg)

	xPos = xPos + moneyIcon:getContentSize().width + 4
	text = ui.newTTFLabel({ text = "需求等级:", size = 20 }):anch(0, 0.5):pos(xPos, yPos):addTo(costBg)
	xPos = xPos + text:getContentSize().width
	ui.newTTFLabel({ text = skillLevelData.openLevel, size = 20, 
		color = self.hero.level < skillLevelData.openLevel and display.COLOR_RED or display.COLOR_WHITE })
		:anch(0, 0.5):pos(xPos, yPos):addTo(costBg)
	if conditionOk and self.hero.level < skillLevelData.openLevel then
		conditionOk = false
	end

	conditionOk = conditionOk and isOpen
	local levelUpBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png", "middle_disabled.png"},
		{	
			text = { text = "升 级", size = 28, font = ChineseFont, strokeColor = display.COLOR_FONT },
			priority = self.priority,
			callback = function()
				if game.role.money < skillLevelData.money then
					game.role:processErrorCode({data = pb.encode("SysErrMsg", {errCode = SYS_ERR_MONEY_NOT_ENOUGH})})
					return
				end

				local levelupRequest = pb.encode("SimpleEvent", { roleId = game.role.id,
					param1 = self.hero.id, param2 = skillId })
				game:sendData(actionCodes.HeroSkillLevelUpRequest, levelupRequest)
				loadingShow()
				game:addEventListener(actionModules[actionCodes.HeroSkillLevelUpResponse], function(event)
					loadingHide()
					local msg = pb.decode("SimpleEvent", event.data)	
					DGMsgBox.new({ msgId = 300 })

					self:showMainLayer(skillId)
					self:showSkillLevelUpEffect()
					
					game.role:dispatchEvent({ name = "notifyNewMessage", type = "heroList"})
					return "__REMOVE__"
				end)	
			end,
		})
	levelUpBtn:setEnable(conditionOk)
	levelUpBtn:getLayer():anch(0, 0):pos(285, 2):addTo(materialBg)
	self.levelUpBtn = levelUpBtn:getLayer()

	if conditionOk then 
		game:activeSpecialGuide(501)
	end

	self:checkGuide()
end

function HeroSkillLayer:showSkillLevelUpEffect()
	local mask = DGMask:new({priority = self.priority - 100, opacity = 0}):getLayer():addTo(display.getRunningScene())
	local anim = uihelper.loadAnimation(HeroRes, "skillUp", 9)
	local curBtn = self.skillRadio:getChooseBtn():getLayer()
	anim.sprite:anch(0.5, 0.5):pos(curBtn:getContentSize().width/2, curBtn:getContentSize().height/2):addTo(curBtn)
	game:playMusic(42)
	anim.sprite:runAction(transition.sequence({	
		CCAnimate:create(anim.animation),
		CCRemoveSelf:create(),
		CCCallFunc:create(function() mask:removeSelf() end),	
	}))
end

function HeroSkillLayer:getLayer()
	return self.mask:getLayer()
end


return HeroSkillLayer