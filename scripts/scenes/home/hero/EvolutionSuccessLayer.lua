-- 进化成功后界面
-- by yangkun
-- 2014.7.14

local EvolutionRes = "resource/ui_rc/hero/evolution/"
local BattleEndRes = "resource/ui_rc/carbon/end/"

local EvolutionSuccessLayer = class("EvolutionSuccessLayer", function(params)
		return display.newLayer(EvolutionRes .. "evolution_bg.png")
	end)

function EvolutionSuccessLayer:ctor(params)
	params = params or {}

	self.heroId = params.heroId
	self.parent = params.parent

	self.priority = params.priority or -130
	self:initUI()
end

function EvolutionSuccessLayer:initUI()
	self.size = self:getContentSize()
	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self , 
		priority = self.priority, 
		click = function()
			self.mask:remove()
			if self.parent and self.parent.__cname == "HeroEvolutionLayer" then
				self.parent:removeMask()
			end
		end})

	local shine = display.newSprite(EvolutionRes .. "light_halo.png")
	shine:anch(0.5,0.5):pos(self.size.width/2, self.size.height):addTo(self)
	shine:runAction(CCRepeatForever:create(CCRotateBy:create(0.1, 10)))

	display.newSprite(EvolutionRes .. "evolution_text.png")
	:anch(0.5,0.5):pos(self.size.width/2, self.size.height):addTo(self)

	local mainHero = game.role.heros[self.heroId]

	local preHeroHead = HeroHead.new({type = mainHero.type, hideStars = true, wakeLevel = mainHero.wakeLevel, star = mainHero.star, evolutionCount = mainHero.evolutionCount - 1})
	preHeroHead:getLayer():anch(0, 0.5):pos(150, self.size.height - 100):addTo(self)
	ui.newTTFLabel({text = mainHero:getHeroName(mainHero.evolutionCount - 1), size = 22, font = ChineseFont, color = uihelper.getEvolColor(mainHero.evolutionCount - 1)})
		:anch(0.5, 1):pos(preHeroHead:getLayer():getContentSize().width/2, 0):addTo(preHeroHead:getLayer())

	display.newSprite(GlobalRes .. "number_arrow.png")
		:anch(0.5,0.5):pos(self.size.width/2, self.size.height - 100):addTo(self)

	local curHeroHead = HeroHead.new({type = mainHero.type, hideStars = true, wakeLevel = mainHero.wakeLevel, star = mainHero.star, evolutionCount = mainHero.evolutionCount})
	curHeroHead:getLayer():anch(0, 0.5):pos(355, self.size.height - 100):addTo(self)
	ui.newTTFLabel({text = mainHero:getHeroName(), size = 22, font = ChineseFont, color = uihelper.getEvolColor(mainHero.evolutionCount)})
		:anch(0.5, 1):pos(curHeroHead:getLayer():getContentSize().width/2, 0):addTo(curHeroHead:getLayer())


	local currentValues = mainHero:getTotalAttrValues()
	local previousValues = mainHero:getTotalAttrValues(mainHero:getBaseAttrValues(mainHero.level, mainHero.evolutionCount -1))

	local preEvlFactor = evolutionModifyCsv:getModifies(mainHero.evolutionCount -1) 
	local curEvlFactor = evolutionModifyCsv:getModifies(mainHero.evolutionCount)
	local curStarFactor = globalCsv:getFieldValue("starFactor")[mainHero.star]
	local preFactor = preEvlFactor + curStarFactor - 1
	local curFactor = curEvlFactor + curStarFactor - 1

	-- hp
	local hpBg = display.newSprite(EvolutionRes .. "attr_bg_2.png")
	hpBg:anch(0.5,0):pos(self.size.width/2, 205):addTo(self)

	local xPos, xPos2, xPos3, xPos4 = 76, 190, 308, 368
	local yPos = hpBg:getContentSize().height/2
	ui.newTTFLabel({text = "生命成长", size = 22, color = uihelper.hex2rgb("#ffdc7d"), font = ChineseFont})
		:anch(0,0.5):pos(xPos, yPos):addTo(hpBg)
	ui.newTTFLabel({text = math.floor(mainHero.unitData.hpGrowth * preFactor), size = 22, font = ChineseFont})
		:anch(0,0.5):pos(xPos2, yPos):addTo(hpBg)
	display.newSprite(GlobalRes .. "number_arrow.png")
		:anch(0.5,0.5):pos(hpBg:getContentSize().width/2, hpBg:getContentSize().height/2):addTo(hpBg)

	ui.newTTFLabel({text = math.floor(mainHero.unitData.hpGrowth * curFactor), size = 22, font = ChineseFont})
		:anch(0, 0.5):pos(xPos3, yPos):addTo(hpBg)
	ui.newTTFLabel({text = string.format("(生命+%d)", math.floor(currentValues.hp - previousValues.hp)), size = 22, color = uihelper.hex2rgb("#7ce810")})
		:anch(0, 0.5):pos(xPos4, yPos):addTo(hpBg)

	-- atk
	local atkBg = display.newLayer()
	atkBg:setContentSize(hpBg:getContentSize())
	atkBg:anch(0.5,0):pos(self.size.width/2, 165):addTo(self)

	ui.newTTFLabel({text = "攻击成长", size = 22, color = uihelper.hex2rgb("#ffdc7d"), font = ChineseFont})
		:anch(0,0.5):pos(xPos, yPos):addTo(atkBg)
	ui.newTTFLabel({text = math.floor(mainHero.unitData.attackGrowth * preFactor), size = 22, font = ChineseFont})
		:anch(0,0.5):pos(xPos2, yPos):addTo(atkBg)
	display.newSprite(GlobalRes .. "number_arrow.png")
		:anch(0.5,0.5):pos(atkBg:getContentSize().width/2, atkBg:getContentSize().height/2):addTo(atkBg)

	ui.newTTFLabel({text = math.floor(mainHero.unitData.attackGrowth * curFactor), size = 22, font = ChineseFont})
		:anch(0, 0.5):pos(xPos3, yPos):addTo(atkBg)
	ui.newTTFLabel({text = string.format("(攻击+%d)", math.floor(currentValues.atk - previousValues.atk)), size = 22, color = uihelper.hex2rgb("#7ce810")})
		:anch(0, 0.5):pos(xPos4, yPos):addTo(atkBg)


	-- def
	local defBg = display.newSprite(EvolutionRes .. "attr_bg_2.png")
	defBg:anch(0.5,0):pos(self.size.width/2, 125):addTo(self)

	ui.newTTFLabel({text = "防御成长", size = 22, color = uihelper.hex2rgb("#ffdc7d"), font = ChineseFont})
		:anch(0,0.5):pos(xPos, yPos):addTo(defBg)
	ui.newTTFLabel({text = math.floor(mainHero.unitData.defenseGrowth * preFactor), size = 22, font = ChineseFont})
		:anch(0,0.5):pos(xPos2, yPos):addTo(defBg)
	display.newSprite(GlobalRes .. "number_arrow.png")
		:anch(0.5,0.5):pos(defBg:getContentSize().width/2, defBg:getContentSize().height/2):addTo(defBg)

	ui.newTTFLabel({text = math.floor(mainHero.unitData.defenseGrowth * curFactor), size = 22, font = ChineseFont})
		:anch(0, 0.5):pos(xPos3, yPos):addTo(defBg)
	ui.newTTFLabel({text = string.format("(防御+%d)", math.floor(currentValues.def - previousValues.def)), size = 22, color = uihelper.hex2rgb("#7ce810")})
		:anch(0, 0.5):pos(xPos4, yPos):addTo(defBg)

	-- 激活技能
	local yPos = 70
	local hasAllActived = true
	for passiveIndex = 1, 3 do
		local needEvlLevel = globalCsv:getFieldValue("passiveSkillLevel" .. passiveIndex)
		if mainHero.evolutionCount == needEvlLevel then
			local skillId = mainHero.unitData["passiveSkill" .. passiveIndex]
			local passiveSkillData = skillPassiveCsv:getPassiveSkillById(skillId)
			
			if passiveSkillData then
				display.newSprite(passiveSkillData.icon):scale(0.8):anch(0, 0.5):pos(230, yPos):addTo(self)

				ui.newTTFLabel({text = passiveSkillData.name, size = 22, color = display.COLOR_WHITE, font = ChineseFont})
				:anch(0,0.5):pos(325, yPos):addTo(self)
			end

			hasAllActived = false
			break
		elseif mainHero.evolutionCount < needEvlLevel then
			ui.newTTFLabel({text = string.format("再进化%d次可激活被动技", needEvlLevel - mainHero.evolutionCount), size = 22, color = display.COLOR_WHITE, font = ChineseFont})
			:anch(0,0.5):pos(230, yPos):addTo(self)

			hasAllActived = false
			break
		end
	end
	
	if not hasAllActived then		
		ui.newTTFLabel({text = "激活技能", size = 22, color = uihelper.hex2rgb("#ffdc7d"), font = ChineseFont})
		:anch(0,0.5):pos(108, yPos):addTo(self)
	end

	--新手引导
	game:addGuideNode({rect = CCRectMake(0, 0, display.width, display.height), opacity = 0,
		guideIds = {912},
		onClick = function()
			self.mask:remove()
			if self.parent and self.parent.__cname == "HeroEvolutionLayer" then
				self.parent:removeMask()
			end
		end
	})
end

function EvolutionSuccessLayer:getLayer()
	return self.mask:getLayer()
end

return EvolutionSuccessLayer