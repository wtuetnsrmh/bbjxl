
local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"

local HeroSubChooseLayer = import(".HeroSubChooseLayer")
local HeroSkillLayer = import(".HeroSkillLayer")
local HeroInfoLayer = import(".HeroInfoLayer")
local HeroEvolutionLayer = import(".HeroEvolutionLayer")
local HeroCardLayer = import(".HeroCardLayer")
local EquipChooseLayer = require("scenes.home.equip.EquipChooseLayer")
local ConfirmDialog = import("...ConfirmDialog")
local HeroRelationLayer = import(".HeroRelationLayer")
local HeroPartnerLayer = import(".HeroPartnerLayer")
local StarUpSuccessLayer = import(".StarUpSuccessLayer") 

local HeroChooseLayer = class("HeroChooseLayer", function(params)
	return display.newLayer(GlobalRes .. "bottom_bg.png")
end)

function HeroChooseLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -130
	self.size = self:getContentSize()
	self.guideStep = params.guideStep or 1
	self.parent = params.parent

	self:pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1,bg = HomeRes .. "home.jpg"})

	self.closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
				if self.layer == "main" then
					self:getLayer():removeSelf()
				else
					self:showMainLayer(self.curIndex)
				end
			end,
		}):getLayer()
	self.closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self)

	self.curIndex = 1
	self:showMainLayer(self.curIndex)

	self.afterIntensifyHandler = game.role:addEventListener("after_intensify", function(event)
		self:showMainLayer(self.curIndex)
	end)


	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority})
	:anch(0,1):pos(0,display.height):addTo(self)
end

function HeroChooseLayer:onEnter()
	self:checkGuide()
	if self.curhero then
		armatureManager:load(self.curhero.unitData.type)
	end

	self.parent:hide()
end

function HeroChooseLayer:showMainLayer(index)
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end

	self.layer = "main"
	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.size):addTo(self)

	self.chooseBg = display.newLayer()
	self.chooseBg:size(869,549)
	self.chooseBg:anch(0.5, 0.5):pos(self.size.width / 2, self.size.height / 2):addTo(self.mainLayer)
	self.bgSize = self.chooseBg:getContentSize()

	local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)

	-- 头像按钮
	self.headRadios = DGRadioGroup:new()

	local headScale = 0.9
	local cursorXpos, yBegin = 138, 52
	local yInterval = 98

	self.heroCursor = display.newSprite(HeroRes .. "choose/chosen.png")
	self.heroCursor:anch(1, 0.5):pos(cursorXpos, self.bgSize.height - yBegin - yInterval * (self.curIndex - 1)):addTo(self.chooseBg, 1)

	self.headBtns = {}
	for index = 1, 5 do
		local hero
		if game.role.slots[tostring(index)] then
			hero = game.role.heros[game.role.slots[tostring(index)].heroId]
		end
		
		if hero then
			local heroBtn = HeroHead.new( 
				{
					type = hero and hero.type or 0,
					wakeLevel = hero.wakeLevel,
					star = hero.star,
					evolutionCount = hero.evolutionCount,
					heroLevel = hero.level,
					hideStars = true,
					id = index,
					priority = self.priority,
					callback = function()
						self.heroCursor:pos(cursorXpos, self.bgSize.height - yBegin - yInterval * (index - 1))
						
						self:showCurrentHero(hero, index)
						self.curIndex = index
					end,
					group = self.headRadios
				})
			heroBtn:getLayer():scale(headScale):anch(0.5, 0.5):addTo(self.chooseBg, 1)
				:pos(60, self.bgSize.height - yBegin - yInterval * (index - 1))
			if hero:canEvolution() or hero:canStarUp() or hero:canSkillUp() or hero:canBattleSoul() then
				uihelper.newMsgTag(heroBtn:getLayer())
			end

			self.headBtns[index] = heroBtn:getLayer()

		elseif index <= roleInfo.chooseHeroNum then
			local addBtn = DGBtn:new(GlobalRes, {"frame_empty.png"},
				{	
					id = index,
					priority = self.priority,
					callback = function()
						self.heroCursor:pos(cursorXpos, self.bgSize.height - yBegin - yInterval * (index - 1))
						
						self:showCurrentHero(nil, index)
						self.curIndex = index
					end,
				}, self.headRadios):getLayer()
			addBtn:scale(headScale):anch(0.5, 0.5):addTo(self.chooseBg, 1)
				:pos(60, self.bgSize.height - yBegin - yInterval * (index - 1))
			display.newSprite(GlobalRes .. "frame_bottom.png"):addTo(addBtn, -1)
				:pos(addBtn:getContentSize().width / 2, addBtn:getContentSize().height / 2)
			local addSprite = display.newSprite(HeroRes .. "choose/add.png"):addTo(addBtn):pos(addBtn:getContentSize().width / 2, addBtn:getContentSize().height / 2)
			addSprite:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(CCFadeTo:create(0.5, 64), CCFadeTo:create(0.5, 255))))

			self.headBtns[index] = addBtn
			--红点提示
			if table.nums(game.role.heros) > table.nums(game.role.chooseHeros) then
				uihelper.newMsgTag(addBtn)
			end

		else
			local openLevel = roleInfoCsv:getLevelByChooseNum(index)

			local cell = display.newSprite(GlobalRes .. "frame_empty.png")
			local btnSize = cell:getContentSize()
			display.newSprite(HeroRes .. "choose/lock.png"):pos(btnSize.width/2, btnSize.height/2)
				:addTo(cell)	

			ui.newTTFLabelWithStroke({ text = openLevel .. "级开启", size = 20, font = ChineseFont, color = uihelper.hex2rgb("#fff1e0"), strokeColor = display.COLOR_BROWNSTROKE, strokeSize =2 })
				:anch(0.5, 0):pos(btnSize.width / 2, 15):addTo(cell)

			cell:scale(headScale):anch(0.5, 0.5):addTo(self.chooseBg)
				:pos(60, self.bgSize.height - yBegin - yInterval * (index - 1))
			display.newSprite(GlobalRes .. "frame_bottom.png"):addTo(cell, -1)
				:scale(headScale):pos(btnSize.width / 2, btnSize.height / 2)

		end
	end

	self.partnerBtn = DGBtn:new(HeroRes .. "choose/", {"btn_partner_normal.png", "btn_partner_selected.png"}, {
		priority = self.priority - 1,
		callback = function()
			local layer = HeroPartnerLayer.new({priority = self.priority - 1000, closeCallback = function() self:showMainLayer(self.curIndex) end})
			layer:getLayer():addTo(display.getRunningScene())
		end
	}):getLayer():anch(0.5, 0):pos(60, 0):addTo(self.chooseBg, 1)

	-- 右侧按钮
	local chooseTab = display.newSprite(GlobalRes .. "tab_selected.png"):anch(0, 0.5)
	chooseTab:pos(self.size.width - 14, 480):addTo(self.mainLayer)
	local btnSize = chooseTab:getContentSize()

	--指向标：
	display.newSprite(GlobalRes.."tab_arrow.png"):anch(1,0.5)
		:pos(10, btnSize.height/2):addTo(chooseTab)
	ui.newTTFLabelWithStroke({ text = "点将", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(chooseTab)

	self.evolutionBtnThis = DGBtn:new(GlobalRes, {"vertical_normal.png", "vertical_selected.png", "vertical_disabled.png"},
		{	
			priority = self.priority,
			touchScale = { 2, 1 },
			callback = function()
				if not self.curHero then return end
				if self.curHero.type >= 900 and self.curHero.type <= 999 then return end

				local layer = HeroEvolutionLayer.new({mainHeroId = self.curHero.id, 
					priority = self. priority - 10, parent = self, fromChoose = true,
					closeCallback = function ()
						self:setVisible(true)
					end})
				layer:getLayer():addTo(display.getRunningScene())
				self:setVisible(false)
			end,
		})
	self.evolutionBtn=self.evolutionBtnThis:getLayer()
	local btnSize = self.evolutionBtn:getContentSize()
	self.evolutionBtn:anch(0, 0.5):pos(self.size.width - 13, 380):addTo(self.mainLayer)
	ui.newTTFLabelWithStroke({ text = "进化", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(self.evolutionBtn)


	self.skillBtn = DGBtn:new(GlobalRes, {"vertical_normal.png", "vertical_selected.png", "vertical_disabled.png"},
		{	
			priority = self.priority,
			touchScale = { 2, 1 },
			callback = function()
				if not self.curHero then return end
				if self.curHero.type >= 900 and self.curHero.type <= 999 then return end

				local skillLayer = HeroSkillLayer.new({ priority = self.priority - 10, hero = self.curHero,fromChoose = true,
					closeCallback = function ()
						self:setVisible(true)
						--刷新卡的属性值，用于升级被动技时属性变化及时
						self.heroCard.passiveSkillAddAttrs=HeroChooseLayer.heroAttributeByPassiveSkills(self.curHero)
						self.heroCard:initUI()
						self:showMainLayer(self.curIndex)
					end})
				skillLayer:getLayer():addTo(display.getRunningScene())
				self:setVisible(false)
			end,
		})
	self.skillBtn:getLayer():anch(0, 0.5):pos(self.size.width - 13, 280):addTo(self.mainLayer)
	ui.newTTFLabelWithStroke({ text = "技能", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(self.skillBtn:getLayer())

	-- 默认选择主将
	self.headRadios:chooseById(index or 1, true)
end

function HeroChooseLayer:showCurrentHero(hero, index)
	if self.rightBg and not tolua.isnull(self.rightBg) then
		self.rightBg:removeSelf()
	end

	self.mainLayer:removeChildByTag(999)

	self.rightBg = display.newSprite(HeroRes .. "choose/right_bg.png")
	self.rightBg:anch(0, 0.5):pos(131, self.bgSize.height / 2):addTo(self.chooseBg)

	self.curHero = hero

	self.evolutionBtn:removeChildByTag(9999)
	self.skillBtn:getLayer():removeChildByTag(9999)
	if self.curHero then
		if self.curHero:canEvolution() or hero:canBattleSoul() then
			uihelper.newMsgTag(self.evolutionBtn, ccp(-10, -10))
		end

		if self.curHero:canSkillUp() then
			uihelper.newMsgTag(self.skillBtn:getLayer(), ccp(-10, -10))
		end
	end

	-- 中间
	if hero then
		local tempPassiveSkillsAddAttrs=HeroChooseLayer.heroAttributeByPassiveSkills(hero)
		self.heroCard = HeroCardLayer.new({ heroId = hero.id, 
			passiveSkillAddAttrs=tempPassiveSkillsAddAttrs,
			priority = self.priority,
			callback = function()
				local infoLayer = HeroInfoLayer.new({ passiveSkillAddAttrs=tempPassiveSkillsAddAttrs,
					heroId = hero.id, priority = self.priority - 10, 
					parent = self, keepRes = true,
					closeCallback = function ()
						self:showMainLayer(index)
						self:setVisible(true)
					end})
				infoLayer:getLayer():addTo(display.getRunningScene())
				self:setVisible(false)
			end,
		})
		self.heroCard:scale(300 / 650):anch(0.5, 0):pos(170, 70):addTo(self.rightBg)
	else
		local cardFrame = display.newSprite(HeroRes .. "growth/left_bg.png")
		cardFrame:anch(0.5, 0):pos(170, 70):addTo(self.rightBg)

		local cardClickLayer = DGBtn:new(HeroRes, {"empty_placehold.png"}, 
			{
				priority = self.priority,
				callback = function()
					local action
					if not hero then
						action = "add"
					else
						action = "change"
					end
					self:chooseHeroList({ action = action, priority = self.priority - 20, 
						hero = hero, parent = self, slot = index})
				end,
			}):getLayer()
		cardClickLayer:anch(0.5, 0):pos(170, 70):addTo(self.rightBg)
		self.chooseHeroBtn = cardClickLayer

		local cardSize = cardFrame:getContentSize()
		self.addIcon = display.newSprite(HeroRes .. "growth/main_add.png")
		self.addIcon:pos(cardSize.width / 2, cardSize.height / 2):addTo(cardFrame)
			:runAction(CCRepeatForever:create(transition.sequence({
				CCFadeIn:create(0.6),
				CCFadeOut:create(0.6)
			})))
	end

	local detailBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png", "middle_disabled.png"},
		{
			priority = self.priority,
			text = { text = "属性", size = 26, font = ChineseFont, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424"), strokeSize = 2 },
			callback = function()
				HeroChooseLayer.sShowAttrDetails(hero)
			end,
		})
	detailBtn:setEnable(hero ~= nil)
	detailBtn:getLayer():anch(0, 0):pos(22, 10):addTo(self.rightBg)

	local changeBtn = DGBtn:new(GlobalRes, { "middle_normal.png", "middle_selected.png" },
		{	
			text = { text = hero and "换将" or "上阵", size = 28, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			priority = self.priority,
			callback = function()
				self:chooseHeroList({ action = hero and "change" or "add", priority = self.priority - 20, 
					hero = hero, parent = self, lastIndex = index , slot = index})
			end,
		})
	changeBtn:getLayer():anch(0, 0):pos(177, 10):addTo(self.rightBg)

	self:showHeroInfo(hero, index)
end

function HeroChooseLayer.sShowAttrDetails(hero, heroType)
	local attrBg = display.newSprite(HeroRes .. "choose/attr_bg.png")
	local bgSize = attrBg:getContentSize()

	heroType = heroType or hero.type
	local unitData = unitCsv:getUnitByType(heroType)
	local baseAttrs = {hp = 0, atk = 0, def = 0}
	local equipAttrs = hero and hero:getEquipAttrs() or baseAttrs

	--被动技能加成
	local passiveSkillAddAttrs=HeroChooseLayer.heroAttributeByPassiveSkills(hero)

	ui.newTTFLabel({text = "详细属性", font = ChineseFont, size = 24, color = display.COLOR_WHITE })
		:pos(bgSize.width / 2, bgSize.height - 25):addTo(attrBg)

	ui.newTTFLabel({text = "爆伤：", size = 20, }):anch(0, 0.5):pos(36, 30):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", unitData.critHurt + tonum(equipAttrs.critHurt)+tonum(passiveSkillAddAttrs.critHurt)), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(96, 30):addTo(attrBg)
	ui.newTTFLabel({text = "命中：", size = 20, }):anch(0, 0.5):pos(206, 30):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", unitData.hit + tonum(equipAttrs.hit)+tonum(passiveSkillAddAttrs.hit)), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(266, 30):addTo(attrBg)

	ui.newTTFLabel({text = "韧性：", size = 20, }):anch(0, 0.5):pos(36, 60):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", unitData.tenacity + tonum(equipAttrs.tenacity)+tonum(passiveSkillAddAttrs.tenacity)), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(96, 60):addTo(attrBg)
	ui.newTTFLabel({text = "闪避：", size = 20, }):anch(0, 0.5):pos(206, 60):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", unitData.miss + tonum(equipAttrs.miss)+tonum(passiveSkillAddAttrs.miss)), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(266, 60):addTo(attrBg)
	ui.newTTFLabel({text = "抵抗：", size = 20, }):anch(0, 0.5):pos(376, 60):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", unitData.resist + tonum(equipAttrs.resist)+tonum(passiveSkillAddAttrs.resist)), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(436, 60):addTo(attrBg)

	ui.newTTFLabel({text = "暴击：", size = 20, }):anch(0, 0.5):pos(36, 90):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", unitData.crit + tonum(equipAttrs.crit)+tonum(passiveSkillAddAttrs.crit)), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(96, 90):addTo(attrBg)
	ui.newTTFLabel({text = "破击：", size = 20, }):anch(0, 0.5):pos(206, 90):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", unitData.ignoreParry + tonum(equipAttrs.ignoreParry)+tonum(passiveSkillAddAttrs.ignoreParry)), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(266, 90):addTo(attrBg)
	ui.newTTFLabel({text = "格挡：", size = 20, }):anch(0, 0.5):pos(376, 90):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", unitData.parry + tonum(equipAttrs.parry)+tonum(passiveSkillAddAttrs.parry)), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(436, 90):addTo(attrBg)

	local evolFactor = evolutionModifyCsv:getModifies(hero and hero.evolutionCount or 0) 
	local starFactor = globalCsv:getFieldValue("starFactor")[hero and hero.star or unitData.stars]
	local factor = evolFactor + starFactor - 1
	ui.newTTFLabel({text = "生命成长：", size = 20, }):anch(0, 0.5):pos(36, 120):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", math.floor(factor * unitData.hpGrowth)), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(136, 120):addTo(attrBg)
	ui.newTTFLabel({text = "攻击成长：", size = 20, }):anch(0, 0.5):pos(206, 120):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", math.floor(factor * unitData.attackGrowth)), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(306, 120):addTo(attrBg)
	ui.newTTFLabel({text = "防御成长：", size = 20, }):anch(0, 0.5):pos(376, 120):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", math.floor(factor * unitData.defenseGrowth)), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(476, 120):addTo(attrBg)


	local Hero = require("datamodel.Hero")
	local basicValues = hero and hero:getBaseAttrValues() or Hero.sGetBaseAttrValues(heroType, 1, 0, 0)
	local techBonus = Hero.sGetProfessionBonusValues(basicValues, heroType)
	local starBonus = Hero.sGetStarSoulBonusValues(heroType)
	local beautyBonus = Hero.sGetBeautyBonusValues()
	local relationAttrs = hero and hero:getRelationBonusValues(basicValues) or baseAttrs

	--local stringFormat = "%d  %d(副将) %d(科技) %d(美人)%d(装备) %d(情缘)"
	local stringFormat = "%d [color=ff00ff00]+ %d[/color][color=fffee11d](科技)[/color] [color=ff00ff00]+ %d[/color][color=fffee11d](美人)[/color] [color=ff00ff00]+ %d[/color][color=fffee11d](装备)[/color] [color=ff00ff00]+ %d[/color][color=fffee11d](情缘)[/color]"
	local dimensions = CCSizeMake(438, 54)
	ui.newTTFLabel({text = "防御：", size = 20, }):anch(0, 1):pos(36, bgSize.height-146):addTo(attrBg)
	ui.newTTFRichLabel({text = string.format(stringFormat, basicValues.def+tonum(passiveSkillAddAttrs.defense), techBonus.defBonus, beautyBonus.defBonus, tonum(equipAttrs.def), tonum(relationAttrs.def)), 
		size=20, dimensions = dimensions}):anch(0, 1):pos(96, bgSize.height-146):addTo(attrBg)

	ui.newTTFLabel({text = "攻击：", size = 20, }):anch(0, 1):pos(36, bgSize.height-95):addTo(attrBg)
	ui.newTTFRichLabel({text = string.format(stringFormat, basicValues.atk+tonum(passiveSkillAddAttrs.attack), techBonus.atkBonus, beautyBonus.atkBonus, tonum(equipAttrs.atk), tonum(relationAttrs.atk)), 
		size=20, dimensions = dimensions}):anch(0, 1):pos(96, bgSize.height-95):addTo(attrBg)

	ui.newTTFLabel({text = "生命：", size = 20, }):anch(0, 1):pos(36, bgSize.height-43):addTo(attrBg)
	ui.newTTFRichLabel({text = string.format(stringFormat, basicValues.hp+tonum(passiveSkillAddAttrs.hp), techBonus.hpBonus, beautyBonus.hpBonus, tonum(equipAttrs.hp), tonum(relationAttrs.hp)), 
		size=20, dimensions = dimensions}):anch(0, 1):pos(96, bgSize.height-43):addTo(attrBg)

	attrBg:anch(0.5,0.5):pos(display.cx, display.cy)
	local mask
	mask = DGMask:new({item = attrBg, priority = -5000, click = function()
			mask:remove()
		end})
	mask:getLayer():addTo(display.getRunningScene(), 100)
end

--无条件触发的被动技能属性加成
function HeroChooseLayer.heroAttributeByPassiveSkills(hero)
	local addAttrs={}
	if not hero then return addAttrs end
	local passiveSkills = {}
	for skillIndex = 1, 3 do
		local skillId = hero.unitData["passiveSkill" .. skillIndex]
		local isOpen = globalCsv:getFieldValue("passiveSkillLevel" .. skillIndex) <= hero.evolutionCount
		if hero.unitData["passiveSkill" .. skillIndex] > 0 and isOpen then
			table.insert(passiveSkills,skillId)
		end
	end

	--计算出战美人的被动技
	local beautyPassiveSkills, beauties = game.role:getFightBeautySkills()
	for _,skillId in ipairs(beautyPassiveSkills) do
		table.insert(passiveSkills,skillId)
	end

	local Hero = require("datamodel.Hero")
	local basicAttrValues =hero:getBaseAttrValues()
	-- 没有触发条件的被动技能去更新属性值
	for _,value in ipairs(passiveSkills) do
		local passiveSkill = skillPassiveCsv:getPassiveSkillById(value)

		if not passiveSkill then
			return
		end

		-- 技能等级
		local skillLevel = hero.skillLevels[tostring(value + 10000)] or 1
		local growth = {}
		for k,v in pairs(passiveSkill.effectGrowth) do
			growth[tonum(k)] = tonum(v) * (skillLevel - 1)
		end

		-- 效果类型ID=数值
		local thisEffectValue = {}
		for k, v in pairs(passiveSkill.effectMap) do
			thisEffectValue[tostring(k)] = tonum(v) + (growth[tonum(k)] or 0)
		end

		-- 没有触发条件的被动技能
		if passiveSkill.triggerMap[tostring(skillPassiveCsv.TRIGGER_NONE)] then
			if passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_ATK)] then
				local effectValue = tonum(thisEffectValue[tostring(skillPassiveCsv.EFFECT_ATK)])
				addAttrs.attack = math.floor(basicAttrValues.atk * effectValue / 100)
			elseif passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_DEFENSE)] then
				local effectValue = tonum(thisEffectValue[tostring(skillPassiveCsv.EFFECT_DEFENSE)])
				addAttrs.defense = math.floor(basicAttrValues.def * effectValue / 100)
			elseif passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_HP)] then
				local effectValue = tonum(thisEffectValue[tostring(skillPassiveCsv.EFFECT_HP)])
				addAttrs.hp = math.floor(basicAttrValues.hp * effectValue / 100)
			elseif passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_CRIT)] then
				local effectValue = tonum(thisEffectValue[tostring(skillPassiveCsv.EFFECT_CRIT)])
				addAttrs.crit =effectValue
			elseif passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_TENACITY)] then
				local effectValue = tonum(thisEffectValue[tostring(skillPassiveCsv.EFFECT_TENACITY)])
				addAttrs.tenacity = effectValue
			elseif passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_CRIT_HURT)] then
				local effectValue = tonum(thisEffectValue[tostring(skillPassiveCsv.EFFECT_CRIT_HURT)])
				addAttrs.critHurt =  effectValue
			elseif passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_MISS)] then
				local effectValue = tonum(thisEffectValue[tostring(skillPassiveCsv.EFFECT_MISS)])
				addAttrs.miss =  effectValue
			elseif passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_HIT)] then
				local effectValue = tonum(thisEffectValue[tostring(skillPassiveCsv.EFFECT_HIT)])
				addAttrs.hit =  effectValue
			elseif passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_PARRY)] then
				local effectValue = tonum(thisEffectValue[tostring(skillPassiveCsv.EFFECT_PARRY)])
				addAttrs.parry =  effectValue
			elseif passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_IGNORE_PARRY)] then
				local effectValue = tonum(thisEffectValue[tostring(skillPassiveCsv.EFFECT_IGNORE_PARRY)])
				addAttrs.ignoreParry =  effectValue
			elseif passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_RESIST)] then
				local effectValue = tonum(thisEffectValue[tostring(skillPassiveCsv.EFFECT_RESIST)])
				addAttrs.resist =  effectValue
			end
		end
	end

	return addAttrs
end

function HeroChooseLayer:showHeroInfo(hero, index)
	local rightBgSize = self.rightBg:getContentSize()

	local sprite
	local effectSprite

	local function playAnimation(index)
		if hero then
			local animationNames
			animationNames = { "move", "idle", "attack", "attack2", "attack3", "attack4"}
			if hero.unitData.skillAnimateName ~= "0" then
				table.insert(animationNames, hero.unitData.skillAnimateName)
			end
			index = math.random(index or 1, #animationNames)
			if #animationNames[index] > 0 then
				sprite:getAnimation():play(animationNames[index])

				if effectSprite and (animationNames[index] == "attack" or animationNames[index] == "attack2"
					or animationNames[index] == "attack3" or animationNames[index] == "attack4"
					or animationNames[index] == hero.unitData.skillAnimateName) then
					effectSprite:getAnimation():play(animationNames[index])
				end
			end
		end
	end
	-- 模型属性
	local modelFrame = DGBtn:new(HeroRes, {"model_frame.png"},
		{
			priority = self.priority,
			callback = function()
				if hero then	
					playAnimation()
				end
			end,
		}):getLayer()
	modelFrame:size(194, 187):anch(0, 0):pos(329, 300):addTo(self.rightBg)

	if hero then
		local paths = string.split(hero.unitData.boneResource, "/")

		self.curhero = hero
		armatureManager:load(hero.unitData.type)
		sprite = CCNodeExtend.extend(CCArmature:create(paths[#paths]))
		sprite:getAnimation():setSpeedScale(24 / 60)
		sprite:getAnimation():play("idle")

		sprite:scale(hero.unitData.boneRatio / 100)
		sprite:pos(modelFrame:getContentSize().width / 2, 50):addTo(modelFrame)

		-- 特效
		if armatureManager:hasEffectLoaded(hero.unitData.type) then
			local paths = string.split(hero.unitData.boneEffectResource, "/")
			effectSprite = CCNodeExtend.extend(CCArmature:create(paths[#paths]))
			effectSprite:getAnimation():setSpeedScale(24 / 60)

			effectSprite:scale(hero.unitData.boneEffectRatio / 100)
			effectSprite:pos(modelFrame:getContentSize().width / 2, 35):addTo(modelFrame)
		end
	end

	-- -- 属性
	-- local baseAttrs = hero and hero:getBaseAttrValues() or { hp = 0, atk = 0, def = 0 }
	-- local totalAttrs = hero and hero:getTotalAttrValues(baseAttrs) or { hp = 0, atk = 0, def = 0 }
	-- local attrNames = { "hp", "atk", "def" }
	-- for index, name in ipairs(attrNames) do
	-- 	-- atk
	-- 	display.newSprite(HeroRes .. string.format("attr_%s.png", name))
	-- 		:anch(0, 0.5):pos(350, 300 - (index - 1) * 30):addTo(self.rightBg)
	-- 	ui.newTTFLabelWithStroke({text = math.floor(baseAttrs[name]), size = 20 })
	-- 		:anch(0, 0.5):pos(390, 300 - (index - 1) * 30):addTo(self.rightBg)
	-- 	if totalAttrs[name] > baseAttrs[name] then
	-- 		ui.newTTFLabelWithStroke({text = "+" .. math.floor(totalAttrs[name] - baseAttrs[name]), size = 20, color = display.COLOR_GREEN })
	-- 			:anch(0, 0.5):pos(450, 300 - (index - 1) * 30):addTo(self.rightBg)
	-- 	end
	-- end

	--觉醒和名称
	if hero then
		local xPos, yPos = 322, 253
		local res = string.format("name_bg_%d.png", hero.evolutionCount)
		if hero.wakeLevel > 0 then
			local sprite = display.newSprite(HeroRes .. string.format("wake_%d.png", hero.wakeLevel))
				:anch(0, 0):pos(xPos, yPos):addTo(self.rightBg)
			xPos = xPos + sprite:getContentSize().width + 10
			res = "name_bg.png"
		end
		local nameBg = display.newSprite(HeroRes .. res)
		nameBg:anch(0, 0):pos(xPos, yPos):addTo(self.rightBg)
		local name = hero:getHeroName()
		ui.newTTFLabelWithStroke({text = name, size = 22, font = ChineseFont, strokeColor = display.COLOR_FONT})
			:anch(0.5, 0.5):pos(nameBg:getContentSize().width/2, nameBg:getContentSize().height/2 - 5):addTo(nameBg)

		local xPos, yPos = 332, 217
		local isStarMax = hero:isStarMax()
		--碎片
		local tempNode = display.newSprite(HeroRes .. "fragment_tag.png"):anch(0, 0.5):pos(xPos, yPos):addTo(self.rightBg)
		xPos = xPos + tempNode:getContentSize().width + 2
		--进度条
		local expSlot = display.newSprite(HeroRes .. "growth/star_progress_bg.png")
		expSlot:anch(0, 0.5):pos(xPos, yPos):addTo(self.rightBg)
		local expProgress = display.newProgressTimer(HeroRes .. "growth/star_progress_fg.png", display.PROGRESS_TIMER_BAR)
		expProgress:setMidpoint(ccp(0, 0.5))
		expProgress:setBarChangeRate(ccp(1,0))
		local costFragment = globalCsv:getFieldValue("starUpFragment")[hero.star + 1]
		local fragmentId = math.floor(hero.type + 2000)
		local curFragment = game.role.fragments[fragmentId] or 0
		expProgress:setPercentage( isStarMax and 100 or curFragment / costFragment * 100)
		expProgress:pos(expSlot:getContentSize().width/2, expSlot:getContentSize().height/2):addTo(expSlot)
		local expLabel = ui.newTTFLabel({text = isStarMax and "已升至最高星" or string.format("%d/%d", curFragment, costFragment), size = 18})
		expLabel:pos(expSlot:getContentSize().width/2, expSlot:getContentSize().height/2):addTo(expSlot)
		
		xPos = xPos + expSlot:getContentSize().width - 5
		--加号
		tempNode = DGBtn:new(GlobalRes, {"add_normal.png", "add_selected.png"}, 
		{
			priority = self.priority - 10,
			callback = function()
				local ItemSourceLayer = require("scenes.home.ItemSourceLayer")	
				local sourceLayer = ItemSourceLayer.new({ 
					priority = self.priority - 10, 
					itemId = fragmentId,
					closeCallback = function()
						self:showMainLayer(index)
					end,
				})
				sourceLayer:getLayer():addTo(display.getRunningScene())
			end,
		}):getLayer():anch(0, 0.5):pos(xPos, yPos):addTo(self.rightBg)

		if not isStarMax then
			xPos = xPos + tempNode:getContentSize().width - 2
			--升星
			local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
			self.starUpBtn = DGBtn:new(HeroRes .. "growth/", {"btn_star_normal.png", "btn_star_selected.png"}, 
			{
				priority = self.priority - 10,
				callback = function()
					
					if roleInfo.heroStarUpOpen < 0 then
						DGMsgBox.new({text = "8级开放升星", type = 1})
						return
					end
					if curFragment < costFragment then
						DGMsgBox.new({text = "升星所需碎片不足", type = 1})
						return
					end
					local addAssistDialog = ConfirmDialog.new({
						priority = self.priority - 20,
	            		showText = { text = string.format("是否消耗%d[image=resource/ui_rc/global/yinbi.png][/image]升星？", globalCsv:getFieldValue("starUpCost")[hero.star + 1]), size = 28, },
	            		button2Data = {
	                		callback = function()
	                    		local starRequst = {
	                       			roleId = game.role.id,
	                        		param1 = hero.id,
	                    		}
	                    		local bin = pb.encode("SimpleEvent", starRequst)
	                    		game:sendData(actionCodes.HeroStarUpRequest, bin)
	    						game:addEventListener(actionModules[actionCodes.HeroStarUpRequest], function(event)
	    							game.role:dispatchEvent({ name = "notifyNewMessage", type = "heroList"})
							    	--播放成功特效
							    	StarUpSuccessLayer.new({priority = self.priority - 200, hero = hero, endEffectCallback = function() self:showMainLayer(index) end})
							    	playAnimation(3)
							    	game:playMusic(33)
							    	return "__REMOVE__"
							    end)
	                		end,
	            		} 
	        		})
	        		addAssistDialog:getLayer():anch(0.5, 0.5):pos(display.cx, display.cy):addTo(display.getRunningScene()) 
	        		--升星确定按钮
					game:addGuideNode({node = addAssistDialog:getButton(2),
						guideIds = {1080}
					})
				end,
			}):getLayer():anch(0, 0.5):pos(xPos, yPos):addTo(self.rightBg)
			if hero:canStarUp() and roleInfo.heroStarUpOpen >= 0 then
				uihelper.newMsgTag(self.starUpBtn, ccp(-10, -10))

				game:activeSpecialGuide(503)
			end
		end
	end

	self.equipBtns = {}
	-- 装备
	local xPos, xInterval = 573, 83
	local yPos, yInterval = 454, 81
	local columns = 2
	local equipIds = game.role.slots[tostring(index)] and game.role.slots[tostring(index)].equips or {}
	local scale = 0.7
	local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
	for row = 1, 3 do
		for col = 1, columns do
			local equipSlot = (row-1)*columns+col
			local btn
			if not equipIds[equipSlot] then
				btn = DGBtn:new(HeroRes.."choose/", {string.format("equip_%d.png", equipSlot)}, 
				{
					priority = self.priority - 1,
					callback = function()
						
						if roleInfo.equipOpen < 0 then
							DGMsgBox.new({text = string.format("玩家%d级开放装备", math.abs(roleInfo.equipOpen)), type = 1})
							return
						end
						local hasEquips = false
						for _, equip in pairs(game.role.equips) do
							if equip.csvData.equipSlot == equipSlot and equip.id ~= equipIds[equipSlot] then
								hasEquips = true
								break
							end
						end

						if not hasEquips then
							DGMsgBox.new({text = "无可用装备！", type = 1})
							return
						end

						local layer = EquipChooseLayer.new({priority = self.priority - 10, slot = index, hero = hero,
							equipSlot = equipSlot, equipId = equipIds[equipSlot], callback = function() self:showMainLayer(index) end })
						layer:getLayer():addTo(display.getRunningScene())
					end				
				}):getLayer()
				btn:anch(0.5, 0.5):pos(xPos+(col-1)*xInterval, yPos):addTo(self.rightBg)
				
				--可用装备提示
				local hasEquips = false
				for _, equip in pairs(game.role.equips) do
					if equip.csvData.equipSlot == equipSlot and (not equip.masterId or equip.masterId <= 0) then
						hasEquips = true
						break
					end
				end
				if hasEquips and roleInfo.equipOpen > 0 then
					local addSprite = display.newSprite(HeroRes .. "choose/can_equip.png")
					addSprite:pos(btn:getContentSize().width/2, btn:getContentSize().height/2):addTo(btn)
					addSprite:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(CCFadeTo:create(0.5, 64), CCFadeTo:create(0.5, 255))))
				-- else
				-- 	display.newSprite("resource/ui_rc/equip/add.png"):scale(1/scale):anch(1,1):pos(btn:getContentSize().width-10, btn:getContentSize().height-10):addTo(btn)
				end
			else
				local equip = game.role.equips[equipIds[equipSlot]]
				btn = ItemIcon.new({
					itemId = equip.type + Equip2ItemIndex.ItemTypeIndex,
					level = equip.level,
					priority = self.priority - 1,
					callback = function()
						local equipPopLayer = require("scenes.home.equip.EquipPopLayer").new({ priority = self.priority-10, equip = equip, hero = hero,
							slot = index, callback = function() self:showMainLayer(index) end })
						equipPopLayer:getLayer():addTo(display.getRunningScene())
					end	 
				}):getLayer():scale(scale):anch(0.5, 0.5):pos(xPos+(col-1)*xInterval, yPos):addTo(self.rightBg)
				if equip.evolCount > 0 then
					ui.newTTFLabelWithStroke({text = "+" .. equip.evolCount, color = uihelper.hex2rgb("#62f619"), size = 32, font = ChineseFont, strokeColor = display.COLOR_FONT})
						:anch(1, 1):pos(btn:getContentSize().width - 8, btn:getContentSize().height - 5):addTo(btn)
				end
			end
			self.equipBtns[equipSlot] = btn
		end
		yPos = yPos - yInterval
	end

	local relationBg = display.newLayer(HeroRes .. "choose/assit_rel_bg.png")
	relationBg:anch(0, 0):pos(332, 19):addTo(self.rightBg)

	-- 情缘
	if hero then
		local rows, columns = 3, 2
		for count, relation in ipairs(hero.unitData.relation) do
			local color = (hero.relation and table.find(hero.relation, relation)) and "#fa0404" or "#555555"
			ui.newTTFLabel({text = relation[6], size = 20, color = uihelper.hex2rgb(color)})
				:anch(0.5, 0):pos(84 + (count-1)%columns*176, 88 - (math.ceil(count/columns) - 1) * 35):addTo(relationBg)
		end
		local touch = false
		relationBg:addTouchEventListener(
			function(event, x, y)
				if event == "began" then
					if uihelper.nodeContainTouchPoint(relationBg, ccp(x, y)) then

						touch = true 
					else
						return false
					end
				elseif event == "ended" then
					if uihelper.nodeContainTouchPoint(relationBg, ccp(x, y)) and touch then
						touch = false
						self:showRelationDetail(hero)
					end
				end

				return true
			end, false, self.priority - 1, true)
		relationBg:setTouchEnabled(true)
	end

	self:checkGuide()
end

function HeroChooseLayer:showRelationDetail(hero)	
	HeroRelationLayer.new({hero = hero, priority = self.priority - 1000})
end
 

function HeroChooseLayer:chooseAssistantLayer(params)
	
	-- local assistantChooseLayer = HeroAssistantChooseLayer.new(params)
	-- assistantChooseLayer:getLayer():addTo(display.getRunningScene())
end

function HeroChooseLayer:chooseHeroList(params)

	local subChooseLayer = HeroSubChooseLayer.new(params)
	subChooseLayer:getLayer():addTo(display.getRunningScene())
end

function HeroChooseLayer:checkGuide(remove)
	--选武将头像第二个
	game:addGuideNode({node = self.headBtns[2], remove = remove,
		guideIds = {1016, 1047}
	})
	--选武将头像第三个
	game:addGuideNode({node = self.headBtns[3], remove = remove,
		guideIds = {1020}
	})
	--选武将头像第四个
	game:addGuideNode({node = self.headBtns[4], remove = remove,
		guideIds = {1074, 1078, 1196}
	})
	--选择武将
	game:addGuideNode({node = self.chooseHeroBtn, remove = remove,
		guideIds = {1017, 1021, 1075}
	})

	--关闭按钮
	game:addGuideNode({node = self.closeBtn, remove = remove,
		guideIds = {1023, 1046, 1081, 1107, 1108}
	})

	--进化按钮
	game:addGuideNode({node = self.evolutionBtn, remove = remove,
		guideIds = {1042}
	})
	--升级按钮
	game:addGuideNode({node = self.skillBtn:getLayer(), remove = remove,
		guideIds = {601}
	})
	--升星按钮
	game:addGuideNode({node = self.starUpBtn, remove = remove,
		guideIds = {503}
	})
	
	--装备按钮
	game:addGuideNode({node = self.equipBtns[1], remove = remove,
		guideIds = {1098, 1101, 1276, 1278}
	})

	--小伙伴按钮
	game:addGuideNode({node = self.partnerBtn, remove = remove,
		guideIds = {1273}
	})
end

function HeroChooseLayer:getLayer()
	return self.mask:getLayer()
end

function HeroChooseLayer:onExit()
	armatureManager:dispose()
	self.parent:show()
	self:checkGuide(true)
end

function HeroChooseLayer:onCleanup()
	display.removeUnusedSpriteFrames()
	game.role:removeEventListener("after_intensify", self.afterIntensifyHandler)
end

return HeroChooseLayer