--其他玩家点将界面
local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"

local HeroSubChooseLayer = import(".HeroSubChooseLayer")
local HeroSkillLayer = import(".HeroSkillLayer")
local HeroInfoLayer = import(".HeroInfoLayer")
local HeroEvolutionLayer = import(".HeroEvolutionLayer")
local HeroCardLayer = import(".HeroCardLayer")
local HeroRelationLayer = import(".HeroRelationLayer")
local EquipChooseLayer = require("scenes.home.equip.EquipChooseLayer")
local HeroPartnerLayer = import(".HeroPartnerLayer")
local json = require("framework.json")

local OtherPlayerHeroChooseLayer = class("OtherPlayerHeroChooseLayer", function(params)
	return display.newLayer(GlobalRes .. "bottom_bg.png")
end)

function OtherPlayerHeroChooseLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -130
	self.size = self:getContentSize()
	
	self.parent = params.parent
	self.playerInfo=params.roleInfo
	self.beauty = params.roleInfo.beauty

	self.assisSlodier={}
	for _,soldier in ipairs(self.playerInfo.assisoldier) do
		self.assisSlodier[soldier.id]=soldier
	end

	self.partners = {}
	for i,hero in ipairs(self.playerInfo.partners) do
		local newHero = require("datamodel.Hero").new(hero)

		self.partners[i] = newHero
	end

	self.slots=json.decode(self.playerInfo.roleInfo.slotsJson) or {}
	self.equips={}
	for _,equip in ipairs(self.playerInfo.equips) do
		self.equips[equip.id] = require("datamodel.Equip").new(equip)
	end
	self.heros={}
	for _, hero in ipairs(self.playerInfo.heros) do
		local newHero = require("datamodel.Hero").new(hero)
		self.heros[newHero.id] = newHero

	end
	

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

	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority})
	:anch(0,1):pos(0,display.height):addTo(self)
end

function OtherPlayerHeroChooseLayer:onEnter()
	if self.curhero then
		armatureManager:load(self.curhero.unitData.type)
	end

	self.parent:hide()
end

function OtherPlayerHeroChooseLayer:showMainLayer(index)
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

	local roleInfo = roleInfoCsv:getDataByLevel(self.playerInfo.roleInfo.level)

	-- 头像按钮
	self.headRadios = DGRadioGroup:new()

	local headScale = 0.9
	local cursorXpos, yBegin = 138, 52
	local yInterval = 98

	self.heroCursor = display.newSprite(HeroRes .. "choose/chosen.png")
	self.heroCursor:anch(1, 0.5):pos(cursorXpos, self.bgSize.height - yBegin - yInterval * (self.curIndex - 1)):addTo(self.chooseBg, 1)

	self:refreshHeroRelation(self.playerInfo)

	for index = 1, 5 do
		local hero
		if self.slots[tostring(index)] then
			hero = self.heros[tonum(self.slots[tostring(index)].heroId)]
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
			
		elseif index <= roleInfo.chooseHeroNum then
			local addBtn = DGBtn:new(GlobalRes, {"frame_empty.png"},
				{	
					id = index,
					priority = self.priority,
					callback = function()
						
					end,
				}, self.headRadios):getLayer()
			addBtn:scale(headScale):anch(0.5, 0.5):addTo(self.chooseBg, 1)
				:pos(60, self.bgSize.height - yBegin - yInterval * (index - 1))
			display.newSprite(GlobalRes .. "frame_bottom.png"):addTo(addBtn, -1)
				:pos(addBtn:getContentSize().width / 2, addBtn:getContentSize().height / 2)
			local addSprite = display.newSprite(HeroRes .. "choose/add.png"):addTo(addBtn):pos(addBtn:getContentSize().width / 2, addBtn:getContentSize().height / 2)
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

	DGBtn:new(HeroRes .. "choose/", {"btn_partner_normal.png", "btn_partner_selected.png"}, {
		priority = self.priority - 1,
		callback = function()
			--打开小伙伴界面
			local layer = HeroPartnerLayer.new({priority = self.priority - 1000,
				heros = self.heros, partners = self.partners or {},level = tonum(self.playerInfo.roleInfo.level),
				slots = self.slots,
				 closeCallback = function() 
				 	self:showMainLayer(self.curIndex) 
				 end
				 })
				
			layer:getLayer():addTo(display.getRunningScene())
		end
	}):getLayer():anch(0.5, 0):pos(60, 0):addTo(self.chooseBg, 1)

	-- 默认选择主将
	self.headRadios:chooseById(index or 1, true)
end

function OtherPlayerHeroChooseLayer:calcBeautyAttrs(hero)
	local beautyData = beautyListCsv:getBeautyById(self.beauty.beautyId)
	if not beautyData then return {} end
	local skills = {}
	if self.beauty.evolutionCount == 1 then
		table.insert(skills, beautyData.beautySkill1)
	elseif self.beauty.evolutionCount == 2 then
		table.insertTo(skills, {beautyData.beautySkill1, beautyData.beautySkill2})
	else
		table.insertTo(skills, {beautyData.beautySkill1, beautyData.beautySkill2, beautyData.beautySkill3})
	end

	return OtherPlayerHeroChooseLayer.heroAttributeByPassiveSkills(hero,skills)
end

function OtherPlayerHeroChooseLayer:showCurrentHero(hero, index)
	if self.rightBg and not tolua.isnull(self.rightBg) then
		self.rightBg:removeSelf()
	end

	self.mainLayer:removeChildByTag(999)

	self.rightBg = display.newSprite(HeroRes .. "choose/right_bg.png")
	self.rightBg:anch(0, 0.5):pos(131, self.bgSize.height / 2):addTo(self.chooseBg)

	self.curHero = hero

	-- 中间
	if hero then
		local tempPassiveSkillsAddAttrs=self:calcBeautyAttrs(hero)
		local heroCard = HeroCardLayer.new({ heroType = hero.type, attrsJson=hero.attrsJson,level=hero.level,
			evolutionCount = hero.evolutionCount,
			passiveSkillAddAttrs=tempPassiveSkillsAddAttrs,
			priority = self.priority,
			callback = function()
				-- local infoLayer = HeroInfoLayer.new({ heroType = hero.type, priority = self.priority - 10, 
				-- 	attrsJson=hero.attrsJson,level=hero.level,
				-- 	parent = self, keepRes = true,hideMoreBt=true,
				-- 	closeCallback = function ()
				-- 		self:setVisible(true)
				-- 	end})
				-- infoLayer:getLayer():addTo(display.getRunningScene())
				-- self:setVisible(false)
			end,
		})
		heroCard:scale(300 / 650):anch(0.5, 0):pos(170, 70):addTo(self.rightBg)
	else
		local cardFrame = display.newSprite(HeroRes .. "growth/left_bg.png")
		cardFrame:anch(0.5, 0):pos(170, 70):addTo(self.rightBg)
	end

	local detailBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png", "middle_disabled.png"},
		{
			priority = self.priority,
			text = { text = "属性", size = 26, font = ChineseFont, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424"), strokeSize = 2 },
			callback = function()
			end,
		})
	detailBtn:setEnable(false)
	detailBtn:getLayer():anch(0, 0):pos(22, 10):addTo(self.rightBg)

	local changeBtn = DGBtn:new(GlobalRes, { "middle_normal.png", "middle_selected.png", "middle_disabled.png" },
		{	
			text = { text = hero and "换将" or "上阵", size = 28, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			priority = self.priority,
			callback = function()
				
			end,
		})
	changeBtn:setEnable(false)
	changeBtn:getLayer():anch(0, 0):pos(177, 10):addTo(self.rightBg)

	self:showHeroInfo(hero, index)
end

--无条件触发的被动技能属性加成
function OtherPlayerHeroChooseLayer.heroAttributeByPassiveSkills(hero,skills)
	local addAttrs={}
	if not hero then return addAttrs end
	local passiveSkills = skills
	

	local Hero = require("datamodel.Hero")
	local basicAttrValues =hero:getBaseAttrValues()
	-- 没有触发条件的被动技能去更新属性值
	for _,value in ipairs(passiveSkills) do
		local passiveSkill = skillPassiveCsv:getPassiveSkillById(value)

		if not passiveSkill then
			return
		end

		-- 效果类型ID=数值
		local thisEffectValue = {}
		for k, v in pairs(passiveSkill.effectMap) do
			thisEffectValue[tostring(k)] = tonum(v)
		end

		-- 没有触发条件的被动技能
		if passiveSkill.triggerMap[tostring(skillPassiveCsv.TRIGGER_NONE)] then
			if passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_ATK)] then
				local effectValue = tonum(thisEffectValue[tostring(skillPassiveCsv.EFFECT_ATK)])
				addAttrs.attack = basicAttrValues.atk * effectValue / 100
			elseif passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_DEFENSE)] then
				local effectValue = tonum(thisEffectValue[tostring(skillPassiveCsv.EFFECT_DEFENSE)])
				addAttrs.defense = basicAttrValues.def * effectValue / 100
			elseif passiveSkill.effectMap[tostring(skillPassiveCsv.EFFECT_HP)] then
				local effectValue = tonum(thisEffectValue[tostring(skillPassiveCsv.EFFECT_HP)])
				addAttrs.hp = basicAttrValues.hp * effectValue / 100
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

function OtherPlayerHeroChooseLayer.sShowAttrDetails(hero, heroType)
	local attrBg = display.newSprite(HeroRes .. "choose/attr_bg.png")
	local bgSize = attrBg:getContentSize()

	heroType = heroType or hero.type
	local unitData = unitCsv:getUnitByType(heroType)
	local baseAttrs = {hp = 0, atk = 0, def = 0}
	local equipAttrs = hero and hero:getEquipAttrs() or baseAttrs

	ui.newTTFLabel({text = "详细属性", font = ChineseFont, size = 24, color = display.COLOR_WHITE })
		:pos(bgSize.width / 2, bgSize.height - 25):addTo(attrBg)

	ui.newTTFLabel({text = "爆伤：", size = 20, }):anch(0, 0.5):pos(36, 30):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", unitData.critHurt + tonum(equipAttrs.critHurt)), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(96, 30):addTo(attrBg)
	ui.newTTFLabel({text = "命中：", size = 20, }):anch(0, 0.5):pos(206, 30):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", unitData.hit + tonum(equipAttrs.hit)), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(266, 30):addTo(attrBg)

	ui.newTTFLabel({text = "韧性：", size = 20, }):anch(0, 0.5):pos(36, 60):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", unitData.tenacity + tonum(equipAttrs.tenacity)), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(96, 60):addTo(attrBg)
	ui.newTTFLabel({text = "闪避：", size = 20, }):anch(0, 0.5):pos(206, 60):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", unitData.miss + tonum(equipAttrs.miss)), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(266, 60):addTo(attrBg)
	ui.newTTFLabel({text = "抵抗：", size = 20, }):anch(0, 0.5):pos(376, 60):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", unitData.resist + tonum(equipAttrs.resist)), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(436, 60):addTo(attrBg)

	ui.newTTFLabel({text = "暴击：", size = 20, }):anch(0, 0.5):pos(36, 90):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", unitData.crit + tonum(equipAttrs.crit)), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(96, 90):addTo(attrBg)
	ui.newTTFLabel({text = "破击：", size = 20, }):anch(0, 0.5):pos(206, 90):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", unitData.ignoreParry + tonum(equipAttrs.ignoreParry)), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(266, 90):addTo(attrBg)
	ui.newTTFLabel({text = "格挡：", size = 20, }):anch(0, 0.5):pos(376, 90):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", unitData.parry + tonum(equipAttrs.parry)), size = 20, color = display.COLOR_GREEN})
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

	local stringFormat = "%d [color=ff00ff00]+ %d[/color][color=fffee11d](科技)[/color] [color=ff00ff00]+ %d[/color][color=fffee11d](将星)[/color] [color=ff00ff00]+ %d[/color][color=fffee11d](美人)[/color] [color=ff00ff00]+ %d[/color][color=fffee11d](装备)[/color] [color=ff00ff00]+ %d[/color][color=fffee11d](情缘)[/color]"
	local dimensions = CCSizeMake(438, 54)
	ui.newTTFLabel({text = "防御：", size = 20, }):anch(0, 1):pos(36, bgSize.height-146):addTo(attrBg)
	ui.newTTFRichLabel({text = string.format(stringFormat, basicValues.def, techBonus.defBonus, starBonus.defBonus, beautyBonus.defBonus, tonum(equipAttrs.def), tonum(relationAttrs.def)), 
		size=20, dimensions = dimensions}):anch(0, 1):pos(96, bgSize.height-146):addTo(attrBg)

	ui.newTTFLabel({text = "攻击：", size = 20, }):anch(0, 1):pos(36, bgSize.height-95):addTo(attrBg)
	ui.newTTFRichLabel({text = string.format(stringFormat, basicValues.atk, techBonus.atkBonus, starBonus.atkBonus, beautyBonus.atkBonus, tonum(equipAttrs.atk), tonum(relationAttrs.atk)), 
		size=20, dimensions = dimensions}):anch(0, 1):pos(96, bgSize.height-95):addTo(attrBg)

	ui.newTTFLabel({text = "生命：", size = 20, }):anch(0, 1):pos(36, bgSize.height-43):addTo(attrBg)
	ui.newTTFRichLabel({text = string.format(stringFormat, basicValues.hp, techBonus.hpBonus, starBonus.hpBonus, beautyBonus.hpBonus, tonum(equipAttrs.hp), tonum(relationAttrs.hp)), 
		size=20, dimensions = dimensions}):anch(0, 1):pos(96, bgSize.height-43):addTo(attrBg)


	attrBg:anch(0.5,0.5):pos(display.cx, display.cy)
	local mask
	mask = DGMask:new({item = attrBg, priority = -5000, click = function()
			mask:remove()
		end})
	mask:getLayer():addTo(display.getRunningScene(), 100)
end

function OtherPlayerHeroChooseLayer:refreshHeroRelation(info)
	--清除以前的情缘
	for _, hero in pairs(info.heros) do
		hero.relation = nil
	end
	--清除以前的装备到英雄的索引
	for _, equip in pairs(self.equips) do	
		equip.masterId = 0
	end
	-- 设置现在的激活的情缘
	--记录当前出战英雄的types集合
	local heroTypes = {}
	for _, value in pairs(self.slots) do
		local hero = self.heros[value.heroId]
		if hero then 
			table.insert(heroTypes, hero.type)
		end
	end

	for _, hero in pairs(self.partners) do
		if hero.type ~= 0 then
			table.insert(heroTypes, hero.type)
		end
	end

	for slot, value in pairs(self.slots) do
		local hero = self.heros[value.heroId]
		local equipTypes = {}
		value.equips = value.equips or {}
		for _, equipId in pairs(value.equips) do
			table.insert(equipTypes, self.equips[equipId].type)
			self.equips[equipId].masterId = hero and hero.type or -1
		end
		if hero then
			hero.relation = {}
			if hero.unitData.relation then
				for _, relation in pairs(hero.unitData.relation) do
					if relation[1] == 1 and table.contain(heroTypes, relation[2]) then
						table.insert(hero.relation, relation)
					elseif relation[1] == 2 and table.contain(equipTypes, relation[2]) then
						table.insert(hero.relation, relation)
					end
				end
			end
		end
	end
end

function OtherPlayerHeroChooseLayer:showHeroInfo(hero, index)
	local rightBgSize = self.rightBg:getContentSize()

	local sprite
	local effectSprite
	-- 模型属性
	local modelFrame = DGBtn:new(HeroRes, {"model_frame.png"},
		{
			priority = self.priority,
			callback = function()
				if hero then
					local animationNames
					animationNames = { "move", "idle", "attack", "attack2", "attack3", "attack4"}
					
					if hero.unitData.skillAnimateName ~= "0" then
						table.insert(animationNames, hero.unitData.skillAnimateName)
					end
					local index = math.random(1, #animationNames)
					if #animationNames[index] > 0 then
						sprite:getAnimation():play(animationNames[index])

						if effectSprite and (animationNames[index] == "attack" or animationNames[index] == "attack2"
							or animationNames[index] == "attack3" or animationNames[index] == "attack4"
							or animationNames[index] == hero.unitData.skillAnimateName) then
							effectSprite:getAnimation():play(animationNames[index])
						end
					end
				end
			end,
		}):getLayer()
	modelFrame:size(194, 187):anch(0, 0):pos(329, 305):addTo(self.rightBg)

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

	--觉醒和名称
	if hero then
		local xPos, yPos = 322, 270
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
		ui.newTTFLabel({text = name, size = 22, font = ChineseFont})
			:anch(0.5, 0.5):pos(nameBg:getContentSize().width/2, nameBg:getContentSize().height/2 - 4):addTo(nameBg)
	end

	-- 装备
	local xPos, xInterval = 573, 83
	local yPos, yInterval = 467, 81
	local columns = 2
	local equipIds = self.slots[tostring(index)] and self.slots[tostring(index)].equips or {}
	local scale = 0.7
	for row = 1, 3 do
		for col = 1, columns do
			local equipSlot = (row-1)*columns+col
			if not equipIds[equipSlot] then
			local btn = DGBtn:new(HeroRes.."choose/", {string.format("equip_%d.png", equipSlot)}, 
				{
					priority = self.priority - 1,
					callback = function()
						
					end				
				}):getLayer()
				btn:anch(0.5, 0.5):pos(xPos+(col-1)*xInterval, yPos):addTo(self.rightBg)

			else
				local equip = self.equips[equipIds[equipSlot]]
				ItemIcon.new({
					itemId = equip.type + Equip2ItemIndex.ItemTypeIndex,
					level = equip.level,
					priority = self.priority - 1,
					callback = function()
						local equipPopLayer = require("scenes.home.equip.EquipPopLayer").new({ priority = self.priority-10,
							 equip = equip, hero = hero,disable=true,playerLevel = self.playerInfo.roleInfo.level,
							slot = index, callback = function() self:showMainLayer(index) end })
						equipPopLayer:getLayer():addTo(display.getRunningScene())
					end	 
				}):getLayer():scale(scale):anch(0.5, 0.5):pos(xPos+(col-1)*xInterval, yPos):addTo(self.rightBg)
			end
		end
		yPos = yPos - yInterval
	end

	local bg = display.newSprite(HeroRes .. "choose/assit_rel_bg.png")
	bg:anch(0, 0):pos(332, 19):addTo(self.rightBg)

	-- 情缘
	local relationBg = display.newLayer()
	relationBg:size(350, 70):addTo(bg)
	if hero then
		local columns = 2
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

end

function OtherPlayerHeroChooseLayer:showRelationDetail(hero)
	HeroRelationLayer.new({hero = hero, priority = self.priority - 1000})
end
 

function OtherPlayerHeroChooseLayer:showAssistInfo(hero, idx, bg)
	local rightBgSize = self.rightBg:getContentSize()

	-- 副将
	local bgSize = bg:getContentSize()

	local xInterval = 30
	local xBegin = (bgSize.width - 90 * 3 - 2 * xInterval) / 2
	local attrIds = { assistantHeroCsv.ATK, assistantHeroCsv.DEF, assistantHeroCsv.HP }
	local attrDatas = {
		[1] = { name = "atk", chName = "攻击", },
		[2] = { name = "def", chName = "防御", },
		[3] = { name = "hp", chName = "生命",  },
	}

	if not hero then
		for index, attrId in ipairs(attrIds) do
			local emptyFrame = display.newSprite(GlobalRes .. "frame_empty.png")
			local scale = 85 / emptyFrame:getContentSize().width
			emptyFrame:anch(0, 0):scale(scale):pos(xBegin + (90 + xInterval) * (index - 1), 110):addTo(bg)
			display.newSprite(GlobalRes .. "frame_bottom.png"):addTo(emptyFrame, -1)
				:pos(emptyFrame:getContentSize().width / 2, emptyFrame:getContentSize().height / 2)
		end

		return
	end

	self.assistBtn = {}
	for index, attrId in ipairs(attrIds) do
		local btnSize = CCSizeMake(90, 90)
		local assistantData = assistantHeroCsv:getAssistantHeroInfoById(attrId)
		if hero.level < assistantData.openLevel then
			local lockBtn = DGBtn:new(GlobalRes, {"frame_empty.png"},
				{
					front = HeroRes .. "choose/lock.png",
					priority = self.priority,
					callback = function() 
					end,
				}):getLayer()
			local scale = 85 / lockBtn:getContentSize().width
			lockBtn:scale(scale):pos(xBegin + (90 + xInterval) * (index - 1), 110):addTo(bg)
			display.newSprite(GlobalRes .. "frame_bottom.png"):addTo(lockBtn, -1)
				:pos(lockBtn:getContentSize().width / 2, lockBtn:getContentSize().height / 2)
			ui.newTTFLabelWithStroke({text = string.format("%d级开启", assistantData.openLevel), size = 20 })
				:anch(0.5, 0):pos(lockBtn:getContentSize().width / 2, 0):addTo(lockBtn)

		-- 当前格存在副将
		elseif hero.level >= assistantData.openLevel and self.slots[tostring(idx)].assistants 
			and self.slots[tostring(idx)].assistants[tostring(attrId)] then
			local assistantHeroId = self.slots[tostring(idx)].assistants[tostring(attrId)]
			local assistantHero = self.assisSlodier[assistantHeroId]
			local unitData = unitCsv:getUnitByType(assistantHero.type)

			self.assistBtn[index] = HeroHead.new({
				priority = self.priority,
				type = unitData.type,
				callback = function()
					
				end	
			}):getLayer()

			local scale = 85 / self.assistBtn[index]:getContentSize().width
			self.assistBtn[index]:scale(scale):pos(xBegin + (90 + xInterval) * (index - 1), 110):addTo(bg)
		-- 当前格不存在副将
		else
			self.assistBtn[index] = DGBtn:new(GlobalRes, {"frame_empty.png"},
				{
					front = HeroRes .. "choose/add.png",
					priority = self.priority,
					callback = function() 
						
					end,
				}):getLayer()
			local btnSize = self.assistBtn[index]:getContentSize()
			local scale = 85 / btnSize.width
			self.assistBtn[index]:scale(scale):pos(xBegin + (90 + xInterval) * (index - 1), 110):addTo(bg)
			display.newSprite(GlobalRes .. "frame_bottom.png"):addTo(self.assistBtn[index], -1)
				:pos(btnSize.width / 2, btnSize.height / 2)
		end
	end
end


function OtherPlayerHeroChooseLayer:getLayer()
	return self.mask:getLayer()
end

function OtherPlayerHeroChooseLayer:onExit()
	armatureManager:dispose()
	self.parent:show()
	
end

function OtherPlayerHeroChooseLayer:onCleanup()
	display.removeUnusedSpriteFrames()
end

return OtherPlayerHeroChooseLayer