-- 新UI 武将卡套
-- by yangkun
-- 2014.4.9
local json = require("framework.json")

local HeroCardRes = "resource/ui_rc/hero/card/"

local HeroCardLayer = class("HeroCardLayer", function(params) return display.newLayer() end)

-- 职业和姓名
local profressionResources = {
	[1] = { res = "pro_bu.png"},
	[3] = { res = "pro_qi.png"},
	[4] = { res = "pro_gong.png"},
	[5] = { res = "pro_jun.png"},
}

-- 阵营和等级
local campResources = {
	[1] = { res = "camp_qun.png"},
	[2] = { res = "camp_wei.png"},
	[3] = { res = "camp_shu.png"},
	[4] = { res = "camp_wu.png"},
}

function HeroCardLayer:ctor(params)
	params = params or {}
	self.priority = params.priority
	self.callback = params.callback
	self.attrsJson=json.decode(params.attrsJson) or nil
	self.level=params.level or 1
	self.passiveSkillAddAttrs=params.passiveSkillAddAttrs or {}

	-- heroType 和 heroId 只传一个
	-- 自己还没有的武将，传heroType
	-- 自己已经有的武将，传heroId
	if params.heroType and not params.heroId then
		self.heroType = params.heroType
	else
		self.heroId = params.heroId
		self.curHero = game.role.heros[self.heroId]
		self.heroType = self.curHero.type
	end
	self.unitData = unitCsv:getUnitByType(self.heroType)
	self.star = params.star and params.star or (self.curHero and self.curHero.star or self.unitData.stars)
	local evolutionCount = params.evolutionCount and params.evolutionCount or (self.curHero and self.curHero.evolutionCount or 0) 
	self.frameNum = uihelper.getCardFrame(evolutionCount)
	self.removeImages = {}
	self:initUI()
end

function HeroCardLayer:initUI(callback)
	self.removeImages[HeroCardRes .. string.format("frame_%d.png", self.frameNum)] = true
	local bg = DGBtn:new(HeroCardRes, {string.format("frame_%d.png", self.frameNum)},
		{	
			priority = self.priority,
			callback = self.callback,
		}):getLayer()
	self:setContentSize(bg:getContentSize())
	bg:anch(0,0):pos(0,0):addTo(self)
	local bgSize = bg:getContentSize()
	
	self.bg = bg

	-- 武将背景
	self.removeImages[self.unitData.cardRes] = true
	display.newSprite(self.unitData.cardRes)
		:scale(0.97):anch(0.5, 0):pos(bgSize.width / 2+2, 36):addTo(bg, -2)

	-- 武将名字
	local heroName = self.unitData.name
	if self.curHero and self.curHero.evolutionCount > 0 then	
		heroName = self.curHero:getHeroName()	
	end
	ui.newTTFLabelWithStroke({ text = heroName, font = ChineseFont, size = 50, color = display.COLOR_WHITE, strokeColor = DARKYELLOW, strokeSize = 2 })
		:anch(0.5, 0.5):pos(bgSize.width / 2, bgSize.height - 75):addTo(bg)

	-- star
	local interval = 2
	local startXpos = bgSize.width / 2 - (61 + interval) / 2 * (self.star - 1)
	for star = 1, self.star do
		display.newSprite(HeroCardRes .. "star.png")
			:pos(startXpos + (61 + interval) * (star - 1), bgSize.height - 135):addTo(bg)
	end

	-- 职业图标
	self.removeImages[HeroCardRes .. profressionResources[self.unitData.profession].res] = true
	display.newSprite(HeroCardRes .. profressionResources[self.unitData.profession].res)
		:pos(68, bgSize.height - 89):addTo(bg)

	-- 阵营
	self.removeImages[HeroCardRes .. campResources[self.unitData.camp].res] = true
	display.newSprite( HeroCardRes .. campResources[self.unitData.camp].res)
		:anch(0.5, 0.5):scale(0.8):pos(bgSize.width - 87, bgSize.height - 89):addTo(bg)

	-- 等级
	local level = self.heroId and self.curHero.level or self.level
	self.levelLabel = ui.newTTFLabelWithStroke({ text = level, strokeColor = uihelper.hex2rgb("#242424"), size = 46, font = ChineseFont })
	self.levelLabel:anch(0.5, 0.5):pos(bgSize.width - 69, 65):addTo(bg)


	-- 基础属性
	local attrs = { hp = self.unitData.hp, atk = self.unitData.attack
			, def = self.unitData.defense }
	if self.heroId then
		attrs = game.role.heros[self.heroId]:getTotalAttrValues()
	end

	--加成属性（玩家详情用）
	if self.attrsJson then
		attrs=self.attrsJson
	end

	self.removeImages[HeroCardRes .. string.format("attr_%d.png", self.star)] = true
	local attrBg = display.newSprite(HeroCardRes .. "attr_bg.png")
	attrBg:anch(0, 0):pos(50, 40):addTo(bg)

	self.hpLabel = ui.newTTFLabel({text = math.floor(attrs.hp+tonum(self.passiveSkillAddAttrs.hp)), size = 40 })
	self.hpLabel:anch(0, 0.5):pos(67, 147):addTo(attrBg)

	self.atkLabel = ui.newTTFLabel({text = math.floor(attrs.atk)+tonum(self.passiveSkillAddAttrs.attack), size = 40 })
	self.atkLabel:anch(0, 0.5):pos(89, 85):addTo(attrBg)

	self.defLabel = ui.newTTFLabel({text = math.floor(attrs.def+tonum(self.passiveSkillAddAttrs.defense)), size = 40 })
	self.defLabel:anch(0, 0.5):pos(127, 23):addTo(attrBg)
end

-- 属性flash
HeroCardLayer.FLASH_TYPE_EVOLUTION = 1
HeroCardLayer.FLASH_TYPE_INTENSIFY = 2

function HeroCardLayer:flash(type, level)
	local interval = 0.6

	local currentValues = self.curHero:getTotalAttrValues()
	local nextValues
	local deltaValues
	if type == HeroCardLayer.FLASH_TYPE_EVOLUTION then
		nextValues = self.curHero:getTotalAttrValues(self.curHero:getBaseAttrValues(self.curHero.level, self.curHero.evolutionCount +1))
	elseif type == HeroCardLayer.FLASH_TYPE_INTENSIFY then
		nextValues = self.curHero:getTotalAttrValues(self.curHero:getBaseAttrValues(level, self.curHero.evolutionCount))
		
		local flag = true
		self.levelLabel:runAction(CCRepeatForever:create(transition.sequence({
				CCFadeOut:create(interval),
				CCCallFunc:create(function() 
						self.levelLabel:setString(flag and level or self.curHero.level)
						self.levelLabel:setColor(flag and display.COLOR_GREEN or display.COLOR_WHITE)		
						flag = not flag 
					end),
				CCFadeIn:create(interval),
			})))
	end

	deltaValues = { hp = nextValues.hp - currentValues.hp, atk = nextValues.atk - currentValues.atk, def = nextValues.def - currentValues.def }

	self.hpLabel:removeSelf()
	self.atkLabel:removeSelf()
	self.defLabel:removeSelf()

	self.hpLabel1 = ui.newTTFLabel({text = math.floor(currentValues.hp), size = 46, color = display.COLOR_YELLOW}):anch(0,0):pos(140, 180):addTo(self.bg)
	self.atkLabel1 = ui.newTTFLabel({text = math.floor(currentValues.atk), size = 46, color = display.COLOR_YELLOW}):anch(0,0):pos(140, 100):addTo(self.bg)
	self.defLabel1 = ui.newTTFLabel({text = math.floor(currentValues.def), size = 46, color = display.COLOR_YELLOW}):anch(0,0):pos(140, 42):addTo(self.bg)

	self.hpLabel2 = ui.newTTFLabel({text = string.format("+%d", deltaValues.hp), size = 46, color = display.COLOR_GREEN}):anch(0,0):pos(260, 180):addTo(self.bg)
	self.atkLabel2 = ui.newTTFLabel({text = string.format("+%d", deltaValues.atk), size = 46, color = display.COLOR_GREEN}):anch(0,0):pos(260, 100):addTo(self.bg)
	self.defLabel2 = ui.newTTFLabel({text = string.format("+%d", deltaValues.def), size = 46, color = display.COLOR_GREEN}):anch(0,0):pos(260, 42):addTo(self.bg)

	self.hpLabel2:runAction(CCRepeatForever:create(transition.sequence({
				CCFadeOut:create(interval),
				CCFadeIn:create(interval),
			})))
	self.atkLabel2:runAction(CCRepeatForever:create(transition.sequence({
				CCFadeOut:create(interval),
				CCFadeIn:create(interval),
			})))
	self.defLabel2:runAction(CCRepeatForever:create(transition.sequence({
				CCFadeOut:create(interval),
				CCFadeIn:create(interval),
			})))
end

function HeroCardLayer:onCleanup()
	for name, bool in pairs(self.removeImages) do
		display.removeSpriteFrameByImageName(name)
	end
end

return HeroCardLayer