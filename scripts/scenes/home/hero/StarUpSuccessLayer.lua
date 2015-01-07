-- 觉醒成功后界面，基本同进化成功界面
-- by yujiuhe
-- 2014.7.30

local EvolutionRes = "resource/ui_rc/hero/evolution/"
local HeroRes = "resource/ui_rc/hero/"
local BattleEndRes = "resource/ui_rc/carbon/end/"

local StarUpSuccessLayer = class("StarUpSuccessLayer", function(params)
		return display.newLayer()
	end)

function StarUpSuccessLayer:ctor(params)
	params = params or {}

	self.hero = params.hero
	self.endEffectCallback = params.endEffectCallback

	self.priority = params.priority or -130
	self:showStarUpSuccessEffect()
end

function StarUpSuccessLayer:showStarUpSuccessEffect()
	self.touchMask = DGMask:new({item = self, blackMask = false, priority = self.priority})
	self.touchMask:getLayer():addTo(display.getRunningScene())
	-- 播放成功特效
	local successSprite = display.newSprite( HeroRes .. "starup_success.png" )
	successSprite:scale(2):pos(self:getContentSize().width/2, self:getContentSize().height/2):addTo(self, 100)
	successSprite:runAction(transition.sequence({
			CCScaleTo:create(0.1, 3),
			CCScaleTo:create(0.4, 0.6),
			CCScaleTo:create(0.05, 0.7),
			CCScaleTo:create(0.05, 0.6),
			CCDelayTime:create(1),
			CCCallFunc:create(function() 
    				successSprite:removeSelf() 
    				self:initUI()
    				if self.endEffectCallback then
    					self.endEffectCallback()
    				end
				end)
	}))

	self:showAttributeEffect()
end

function StarUpSuccessLayer:showAttributeEffect()
	local hero = self.hero
	local currentValues = hero:getTotalAttrValues()
	local previousValues = hero:getTotalAttrValues(hero:getBaseAttrValues(hero.level, hero.evolutionCount, hero.wakeLevel, hero.star - 1))
	local deltaValues = { hp = math.floor(currentValues.hp - previousValues.hp), atk = math.floor(currentValues.atk - previousValues.atk), def = math.floor(currentValues.def - previousValues.def) }

	self.hpNode = display.newNode()
	local hpTextSprite = display.newSprite(HeroRes .. "hp_text.png")
	local hpTips = ui.newBMFontLabel({ text = "+" .. deltaValues.hp, font = FontRes .. "attrNum.fnt"})
	
	local width, height = hpTextSprite:getContentSize().width + hpTips:getContentSize().width, hpTips:getContentSize().height
	self.hpNode:size(width, height)
	hpTextSprite:anch(0, 0.5):pos(0, height / 2):addTo(self.hpNode)
	hpTips:anch(1, 0.5):pos(width, height / 2):addTo(self.hpNode)
	self.hpNode:anch(0.5,0.5):pos(self:getContentSize().width/2, self:getContentSize().height/2 + 80):addTo(self, 1)
	self.hpNode:setVisible(false)

	self.atkNode = display.newNode()
	local atkTextSprite = display.newSprite(HeroRes .. "atk_text.png")
	local atkTips = ui.newBMFontLabel({ text = "+" .. deltaValues.atk, font = FontRes .. "attrNum.fnt"})
	
	local width, height = atkTextSprite:getContentSize().width + atkTips:getContentSize().width, atkTips:getContentSize().height
	self.atkNode:size(width, height)
	atkTextSprite:anch(0, 0.5):pos(0, height / 2):addTo(self.atkNode)
	atkTips:anch(1, 0.5):pos(width, height / 2):addTo(self.atkNode)
	self.atkNode:anch(0.5,0.5):pos(self:getContentSize().width/2, self:getContentSize().height/2 + 80):addTo(self, 1)
	self.atkNode:setVisible(false)

	self.defNode = display.newNode()
	local defTextSprite = display.newSprite(HeroRes .. "def_text.png")
	local defTips = ui.newBMFontLabel({ text = "+" .. deltaValues.def, font = FontRes .. "attrNum.fnt"})
	
	local width, height = defTextSprite:getContentSize().width + defTips:getContentSize().width, defTips:getContentSize().height
	self.defNode:size(width, height)
	defTextSprite:anch(0, 0.5):pos(0, height / 2):addTo(self.defNode)
	defTips:anch(1, 0.5):pos(width, height / 2):addTo(self.defNode)
	self.defNode:anch(0.5,0.5):pos(self:getContentSize().width/2, self:getContentSize().height/2 + 80):addTo(self, 1)
	self.defNode:setVisible(false)
	
	self.hpNode:runAction(transition.sequence({
		CCDelayTime:create(0.5),
		CCCallFunc:create(function() self.hpNode:setVisible(true) end),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 40)), CCScaleTo:create(0.1, 1.5)),
		CCDelayTime:create(0.2),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 20)), CCScaleTo:create(0.1, 1)),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.5, ccp(0, 80)), CCFadeOut:create(0.5)),
		CCRemoveSelf:create()
	}))

	self.atkNode:runAction(transition.sequence({
		CCDelayTime:create(1.0),
		CCCallFunc:create(function() self.atkNode:setVisible(true) end),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 40)), CCScaleTo:create(0.1, 1.5)),
		CCDelayTime:create(0.2),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 20)), CCScaleTo:create(0.1, 1)),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.5, ccp(0, 80)), CCFadeOut:create(0.5)),
		CCRemoveSelf:create()
	}))

	self.defNode:runAction(transition.sequence({
		CCDelayTime:create(1.5),
		CCCallFunc:create(function() self.defNode:setVisible(true) end),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 40)), CCScaleTo:create(0.1, 1.5)),
		CCDelayTime:create(0.2),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 20)), CCScaleTo:create(0.1, 1)),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.5, ccp(0, 80)), CCFadeOut:create(0.5)),
		CCRemoveSelf:create()
	}))
end

function StarUpSuccessLayer:removeMask()
	self.touchMask:getLayer():removeSelf()
end

function StarUpSuccessLayer:initUI()
	local bg = display.newSprite(HeroRes .. "growth/starup_bg.png")
	self.size = bg:getContentSize()
	bg:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = bg , 
		priority = self.priority - 10, 
		click = function()
			self:removeMask()
			self.mask:remove()
		end})

	self.mask:getLayer():addTo(display.getRunningScene())

	local shine = display.newSprite(EvolutionRes .. "light_halo.png")
	shine:anch(0.5,0.5):pos(self.size.width/2, self.size.height):addTo(bg)
	shine:runAction(CCRepeatForever:create(CCRotateBy:create(0.1, 10)))

	display.newSprite(HeroRes .. "starup_text.png")
	:anch(0.5,0.5):pos(self.size.width/2, self.size.height):addTo(bg)

	local preHeroHead = HeroHead.new({type = self.hero.type, hideStars = true, wakeLevel = self.hero.wakeLevel, star = self.hero.star - 1, evolutionCount = self.hero.evolutionCount})
	preHeroHead:getLayer():anch(0, 0.5):pos(150, self.size.height - 100):addTo(bg)
	display.newSprite(GlobalRes .. "number_arrow.png")
	:anch(0.5,0.5):pos(self.size.width/2, self.size.height - 100):addTo(bg)
	local curHeroHead = HeroHead.new({type = self.hero.type, hideStars = true, wakeLevel = self.hero.wakeLevel, star = self.hero.star, evolutionCount = self.hero.evolutionCount})
	curHeroHead:getLayer():anch(0, 0.5):pos(355, self.size.height - 100):addTo(bg)

	
	local currentValues = self.hero:getTotalAttrValues()
	local previousValues = self.hero:getTotalAttrValues(self.hero:getBaseAttrValues(self.hero.level, self.hero.evolutionCount, self.hero.wakeLevel, self.hero.star - 1))

	local preStarFactor = globalCsv:getFieldValue("starFactor")[self.hero.star - 1]
	local curEvlHpFactor, curEvlAtkFactor, curEvlDefFactor = evolutionModifyCsv:getModifies(self.hero.evolutionCount)
	local curStarFactor = globalCsv:getFieldValue("starFactor")[self.hero.star]
	local preHpFactor, preAtkFactor, preDefFactor = curEvlHpFactor + preStarFactor - 1, curEvlAtkFactor + preStarFactor - 1, curEvlDefFactor + preStarFactor - 1
	local curHpFactor, curAtkFactor, curDefFactor = curEvlHpFactor + curStarFactor - 1, curEvlAtkFactor + curStarFactor -1 , curEvlDefFactor + curStarFactor - 1 

	-- hp
	local hpBg = display.newSprite(EvolutionRes .. "attr_bg.png")
	hpBg:anch(0.5,0):pos(self.size.width/2, 110):addTo(bg)

	local xPos, xPos2, xPos3, xPos4 = 76, 190, 308, 368
	local yPos = hpBg:getContentSize().height/2
	ui.newTTFLabel({text = "生命成长", size = 22, color = uihelper.hex2rgb("#ffdc7d"), font = ChineseFont})
		:anch(0,0.5):pos(xPos, yPos):addTo(hpBg)
	ui.newTTFLabel({text = math.floor(self.hero.unitData.hpGrowth * preHpFactor), size = 22, font = ChineseFont})
		:anch(0,0.5):pos(xPos2, yPos):addTo(hpBg)
	display.newSprite(GlobalRes .. "number_arrow.png")
		:anch(0.5,0.5):pos(hpBg:getContentSize().width/2, hpBg:getContentSize().height/2):addTo(hpBg)

	ui.newTTFLabel({text = math.floor(self.hero.unitData.hpGrowth * curHpFactor), size = 22, font = ChineseFont})
		:anch(0, 0.5):pos(xPos3, yPos):addTo(hpBg)
	ui.newTTFLabel({text = string.format("(生命+%d)", math.floor(currentValues.hp - previousValues.hp)), size = 22, color = uihelper.hex2rgb("#7ce810")})
		:anch(0, 0.5):pos(xPos4, yPos):addTo(hpBg)

	-- atk
	local atkBg = display.newLayer()
	atkBg:setContentSize(hpBg:getContentSize())
	atkBg:anch(0.5,0):pos(self.size.width/2, 70):addTo(bg)

	ui.newTTFLabel({text = "攻击成长", size = 22, color = uihelper.hex2rgb("#ffdc7d"), font = ChineseFont})
		:anch(0,0.5):pos(xPos, yPos):addTo(atkBg)
	ui.newTTFLabel({text = math.floor(self.hero.unitData.attackGrowth * preAtkFactor), size = 22, font = ChineseFont})
		:anch(0,0.5):pos(xPos2, yPos):addTo(atkBg)
	display.newSprite(GlobalRes .. "number_arrow.png")
		:anch(0.5,0.5):pos(atkBg:getContentSize().width/2, atkBg:getContentSize().height/2):addTo(atkBg)

	ui.newTTFLabel({text = math.floor(self.hero.unitData.attackGrowth * curAtkFactor), size = 22, font = ChineseFont})
		:anch(0, 0.5):pos(xPos3, yPos):addTo(atkBg)
	ui.newTTFLabel({text = string.format("(攻击+%d)", math.floor(currentValues.atk - previousValues.atk)), size = 22, color = uihelper.hex2rgb("#7ce810")})
		:anch(0, 0.5):pos(xPos4, yPos):addTo(atkBg)


	-- def
	local defBg = display.newSprite(EvolutionRes .. "attr_bg.png")
	defBg:anch(0.5,0):pos(self.size.width/2, 30):addTo(bg)

	ui.newTTFLabel({text = "防御成长", size = 22, color = uihelper.hex2rgb("#ffdc7d"), font = ChineseFont})
		:anch(0,0.5):pos(xPos, yPos):addTo(defBg)
	ui.newTTFLabel({text = math.floor(self.hero.unitData.defenseGrowth * preDefFactor), size = 22, font = ChineseFont})
		:anch(0,0.5):pos(xPos2, yPos):addTo(defBg)
	display.newSprite(GlobalRes .. "number_arrow.png")
		:anch(0.5,0.5):pos(defBg:getContentSize().width/2, defBg:getContentSize().height/2):addTo(defBg)

	ui.newTTFLabel({text = math.floor(self.hero.unitData.defenseGrowth * curDefFactor), size = 22, font = ChineseFont})
		:anch(0, 0.5):pos(xPos3, yPos):addTo(defBg)
	ui.newTTFLabel({text = string.format("(防御+%d)", math.floor(currentValues.def - previousValues.def)), size = 22, color = uihelper.hex2rgb("#7ce810")})
		:anch(0, 0.5):pos(xPos4, yPos):addTo(defBg)

	--新手引导
	game:addGuideNode({rect = CCRectMake(0, 0, display.width, display.height), opacity = 0,
		guideIds = {911},
		onClick = function()
			self:removeMask()
			self.mask:remove()
		end
	})
end

return StarUpSuccessLayer