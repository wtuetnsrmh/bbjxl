-- 武将进化界面
-- by yangkun
-- 2014.6.19

local HomeRes = "resource/ui_rc/home/"
local ParticleRes = "resource/ui_rc/particle/"
local FrameActRes = "resource/skill_pic/"

local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"
local HeroInfoRes = "resource/ui_rc/hero/info/"
local HeroGrowthRes = "resource/ui_rc/hero/growth/"

local HeroEvolutionChooseLayer = import(".HeroEvolutionChooseLayer")
local HeroEvolutionMainChooseLayer = import(".HeroEvolutionMainChooseLayer")
local HeroCardLayer = import(".HeroCardLayer")
local EvolutionSuccessLayer = import(".EvolutionSuccessLayer")
local BattleSoulLayer = import(".BattleSoulLayer")

local HeroEvolutionLayer = class("HeroEvolutionLayer", function(params) return display.newLayer() end)

function HeroEvolutionLayer:ctor(params)

	params = params or {}

	self.priority = params.priority or -129
	self.heroIconPoints = {}

	self.fromChoose = params.fromChoose or false
	self.mainHeroId = params.mainHeroId
	self.parent = params.parent
	self.guideStep = params.guideStep or 1

	self.chooseHeroIds = {}
	if self.fromChoose then
		for index = 1, 5 do
			local hero
			if game.role.slots[tostring(index)] then
				local hero = game.role.heros[game.role.slots[tostring(index)].heroId]
				if hero then self.chooseHeroIds[index] = hero.id end
			end
		end
	end

	self:reloadHeroData()

	self.tipsTag = 140523
	self.fodderHeroIds = params.fodderHeroIds or {}

	self.closeCallback = params.closeCallback
	self:initUI()
end

function HeroEvolutionLayer:initUI()
	local bg = display.newSprite(GlobalRes .. "bottom_bg.png")
	local bgSize = bg:getContentSize()
	self:size(bgSize)
	self.size = bgSize
	bg:anch(0, 0):pos(0, 0):addTo(self)

	-- 遮罩层
	self:anch(0, 0):pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self , priority = self.priority,bg = HomeRes .. "home.jpg"})

	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority - 10})
	:anch(0,1):pos(0,display.height):addTo(self)

	local tabLabel = display.newSprite(GlobalRes .. "tab_selected.png")
	tabLabel:anch(0, 0.5):pos(self:getContentSize().width - 14, 480):addTo(self)
	local btnSize = tabLabel:getContentSize()

	display.newSprite(GlobalRes.."tab_arrow.png"):anch(1,0.5):pos(10, btnSize.height/2)
		:addTo(tabLabel)

	ui.newTTFLabelWithStroke({ text = "进化", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(tabLabel)
		
	self.closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority -1,
			callback = function()
				if self.parent and self.parent.__cname == "HeroChooseLayer" then
					self.parent:showMainLayer(self.parent.curIndex)
				end

				if self.parent and self.parent.__cname == "HeroInfoLayer" then
					self.parent:initContentLeft()
					self.parent:initContentRight()	
				end
				
				self:getLayer():removeSelf()
				self.closeCallback()
			end,
		}):getLayer()
	self.closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self)
end

function HeroEvolutionLayer:reloadHeroData()
	if self.mainHeroId then
		self.mainHero = game.role.heros[self.mainHeroId]
		self.mainHeroUnitData = unitCsv:getUnitByType(self.mainHero.type)
		self.evolutionData = evolutionModifyCsv:getEvolutionByEvolution(self.mainHero.evolutionCount + 1)
	end
end

function HeroEvolutionLayer:onEnter()
	self:initContentLeft()
	self:initContentRight()
	self:checkGuide()
end

function HeroEvolutionLayer:getLayer()
	return self.mask:getLayer()
end

--左侧
function HeroEvolutionLayer:initContentLeft()
	if self.leftContentLayer then
		self.leftContentLayer:removeSelf()
	end
	self.leftContentLayer = display.newLayer()
	self.leftContentLayer:size(480, self:getContentSize().height):pos(0,0):addTo(self, 1)

	local leftSize = self.leftContentLayer:getContentSize()
	
	if not self.mainHeroId then
		local bg = display.newSprite( HeroGrowthRes .. "left_bg.png" )
		bg:anch(1,0):pos(370, 70):addTo(self.leftContentLayer)
		bg:setTag(111)

		local bgSize = bg:getContentSize()

		-- 中间
		local cardFrame = display.newColorLayer(ccc4(0, 0, 0, 0))
		cardFrame:size(300, 450):pos((bg:getContentSize().width - 300 )/2, ( bg:getContentSize().height - 450 )/2):addTo(bg)
		local frameSize = cardFrame:getContentSize()

		local addBtn = DGBtn:new(HeroGrowthRes, {"main_add.png"}, {
				callback = function()
					local layer = HeroEvolutionMainChooseLayer.new({priority = self.priority - 10, mainHeroId = self.mainHeroId, parent = self})
					display.getRunningScene():addChild(layer:getLayer())
				end,
				priority = self.priority -2
			})
		addBtn:getLayer():anch(0.5,0.5):pos(frameSize.width/2, frameSize.height/2):addTo(cardFrame)
		addBtn.item[1]:runAction(CCRepeatForever:create(transition.sequence({
				CCFadeIn:create(0.6),
				CCFadeOut:create(0.6)
			})))
	else
		local layer = HeroCardLayer.new({heroId = self.mainHeroId})
		layer:scale(0.55):anch(1, 0):pos(395, 10):addTo(self.leftContentLayer)
		layer:setTag(222)

		if self.fromChoose then
			local prevHeroId, nextHeroId, hasFound
			for index = 1, 5 do
				local heroId = self.chooseHeroIds[index]
				if heroId then
					if hasFound then nextHeroId = heroId break end
					if heroId == self.mainHeroId then hasFound = true end
					if not hasFound then prevHeroId = heroId end
				end
			end

			local layerSize = layer:getContentSize()

			if prevHeroId then
				self.leftBtn = DGBtn:new(HeroRes, {"switch_normal.png", "switch_selected.png"},
					{
						touchScale = {2, 2},
						priority = self.priority - 2,
						callback = function()
							if prevHeroId then
								self.mainHeroId = prevHeroId
								self.fodderHeroIds = {}

								self:reloadHeroData()
								self:initContentLeft()
								self:initContentRight()
							end
						end,
					}):getLayer()
				self.leftBtn:scale(1/0.55):rotation(180):anch(0.5, 0.5):pos(0, layerSize.height / 2):addTo(layer)
			end

			if nextHeroId then
				self.rightBtn = DGBtn:new(HeroRes, {"switch_normal.png", "switch_selected.png"},
					{
						touchScale = {2, 2},
						priority = self.priority - 2,
						callback = function()
							if nextHeroId then
								self.mainHeroId = nextHeroId
								self.fodderHeroIds = {}

								self:reloadHeroData()
								self:initContentLeft()
								self:initContentRight()
							end
						end,
					}):getLayer()
				self.rightBtn:scale(1/0.55):anch(0.5, 0.5):pos(layerSize.width, layerSize.height / 2):addTo(layer)
			end
		end

		if table.nums(self.fodderHeroIds) > 0 then
			layer:flash(HeroCardLayer.FLASH_TYPE_EVOLUTION)
		end
	end

	-- local attrBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png", "middle_disabled.png"}, {
	-- 		text = { text = "属性", size = 28, font = ChineseFont, color = display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2 },
	-- 		priority = self.priority -1,
	-- 		callback = function()
	-- 			self:showAttrDetails(self.mainHero)
	-- 		end,
	-- 	})
	-- attrBtn:getLayer():anch(1, 1):pos(bgSize.width / 2 - 35, -20):addTo(bg)

	-- local changeBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png", "middle_disabled.png"}, {
	-- 		text = {text = "换将", size = 28, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
	-- 		priority = self.priority -1,
	-- 		callback = function()
	-- 			local layer = HeroEvolutionMainChooseLayer.new({priority = self.priority - 10, mainHeroId = self.mainHeroId, parent = self})
	-- 			display.getRunningScene():addChild(layer:getLayer())
	-- 		end,
	-- 	})
	-- changeBtn:getLayer():anch(0.5, 1):pos(bgSize.width / 2, -20):addTo(bg)
end

--右侧
function HeroEvolutionLayer:initContentRight()
	if self.rightContentLayer then
		self.rightContentLayer:removeSelf()
	end

	self.rightContentLayer = display.newLayer(HeroInfoRes .. "detail_rightbg.png")
	self.rightContentLayer:anch(0, 0.5):pos(400, self.size.height / 2):addTo(self)
	local rightSize = self.rightContentLayer:getContentSize()

	local attrNode = self:createAttrNode()
	attrNode:anch(0.5, 1):pos(rightSize.width/2, rightSize.height - 24):addTo(self.rightContentLayer)

	self:createResourceNode()

	local isMax = self.mainHero.evolutionCount >= evolutionModifyCsv:getEvolMaxCount()
	local canEvolution = self.mainHero:canEvolution()
	-- -- 进化按钮
	self.evolutionBtn = DGBtn:new( GlobalRes, {"btn_green_nol.png", "btn_green_sel.png", "middle_disabled.png"}, {
			text = { text = canEvolution and "进 化" or "一键镶嵌", size = 28, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			notSendClickEvent = true,
			callback = function()
				-- 检查素材卡数目是否已经足够
				if not self.mainHeroId then
					return
				end

				if not canEvolution then
					if not self.canInlay then
						DGMsgBox.new({text = "无可镶嵌材料", type = 1})
					else
						local oldAttrs = self.mainHero:getTotalAttrValues()
						--发送镶嵌
						local bin = pb.encode("SimpleEvent", {roleId = game.role.id, param1 = 0, param2 = self.mainHero.id})
		        		game:sendData(actionCodes.HeroBattleSoulRequest, bin)
						game:addEventListener(actionModules[actionCodes.HeroBattleSoulRequest], function(event)
							local msg = pb.decode("SimpleEvent", event.data)
							local slots = json.decode(msg.param5)
							self:initContentLeft()
							self:initContentRight()
							local curAttrs = self.mainHero:getTotalAttrValues()
							--特效
							self:showAttributeEffect({hp = curAttrs.hp - oldAttrs.hp, atk = curAttrs.atk - oldAttrs.atk, def = curAttrs.def - oldAttrs.def})
							
							for _, slot in pairs(slots) do
								self:playBattleSoulEffect(slot)
							end

							--检查新手引导
							if self.mainHero:canEvolution() and game:activeSpecialGuide(500) then
								self:checkGuide()
							end

							game.role:dispatchEvent({ name = "notifyNewMessage", type = "heroList"})
							return "__REMOVE__"
						end)
					end
					return
				end
				
				self:evolutionRequest(false)
			end,
			priority = self.priority -2
		})
	self.evolutionBtn:setEnable(self.mainHeroId and self.mainHero.evolutionCount < evolutionModifyCsv:getEvolMaxCount())
	self.evolutionBtn:getLayer():anch(0.5, 0):pos(rightSize.width/2, 30):addTo(self.rightContentLayer)
	if self.mainHero:canEvolution() then
		local anim = uihelper.loadAnimation(HeroRes .. "evolution/", "evo", 7)
		anim.sprite:anch(0.5, 0.5):pos(self.evolutionBtn:getLayer():getContentSize().width/2, self.evolutionBtn:getLayer():getContentSize().height/2 + 5):addTo(self.evolutionBtn:getLayer())
		anim.sprite:runAction(CCRepeatForever:create(CCAnimate:create(anim.animation)))
	end
end

function HeroEvolutionLayer:showAttrDetails(hero)
	local attrBg = display.newSprite(HeroRes .. "choose/attr_bg.png")
	local bgSize = attrBg:getContentSize()

	ui.newTTFLabel({text = "详细属性", font = ChineseFont, size = 24, color = display.COLOR_WHITE })
		:pos(bgSize.width / 2, bgSize.height - 25):addTo(attrBg)

	ui.newTTFLabel({text = "爆伤:", size = 22, }):anch(0, 0.5):pos(20, 30):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", hero.unitData.critHurt), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(80, 30):addTo(attrBg)
	ui.newTTFLabel({text = "命中:", size = 22, }):anch(0, 0.5):pos(220, 30):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", hero.unitData.hit), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(280, 30):addTo(attrBg)

	ui.newTTFLabel({text = "韧性:", size = 22, }):anch(0, 0.5):pos(20, 65):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", hero.unitData.tenacity), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(80, 65):addTo(attrBg)
	ui.newTTFLabel({text = "闪避:", size = 22, }):anch(0, 0.5):pos(220, 65):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", hero.unitData.miss), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(280, 65):addTo(attrBg)
	ui.newTTFLabel({text = "抵抗:", size = 22, }):anch(0, 0.5):pos(410, 65):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", hero.unitData.resist), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(470, 65):addTo(attrBg)

	ui.newTTFLabel({text = "暴击:", size = 22, }):anch(0, 0.5):pos(20, 100):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", hero.unitData.crit), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(80, 100):addTo(attrBg)
	ui.newTTFLabel({text = "破击:", size = 22, }):anch(0, 0.5):pos(220, 100):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", hero.unitData.ignoreParry), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(280, 100):addTo(attrBg)
	ui.newTTFLabel({text = "格挡:", size = 22, }):anch(0, 0.5):pos(410, 100):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", hero.unitData.parry), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(470, 100):addTo(attrBg)

	local hpFactor, atkFactor, defFactor = evolutionModifyCsv:getModifies(hero.evolutionCount)
	ui.newTTFLabel({text = "生命成长:", size = 22, }):anch(0, 0.5):pos(20, 135):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", math.floor(hpFactor * hero.unitData.hpGrowth)), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(120, 135):addTo(attrBg)
	ui.newTTFLabel({text = "攻击成长:", size = 22, }):anch(0, 0.5):pos(220, 135):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", math.floor(atkFactor * hero.unitData.attackGrowth)), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(320, 135):addTo(attrBg)
	ui.newTTFLabel({text = "防御成长:", size = 22, }):anch(0, 0.5):pos(410, 135):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d", math.floor(defFactor * hero.unitData.defenseGrowth)), size = 20, color = display.COLOR_GREEN})
		:anch(0, 0.5):pos(510, 135):addTo(attrBg)

	local basicValues = hero:getBaseAttrValues()

	local Hero = require("datamodel.Hero")
	local techBonus = Hero.sGetProfessionBonusValues(basicValues, hero.type)
	local starBonus = Hero.sGetStarSoulBonusValues(hero.type)
	local beautyBonus = Hero.sGetBeautyBonusValues()

	ui.newTTFLabel({text = "防御:", size = 22, }):anch(0, 0.5):pos(20, 170):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d + %d(科技) + %d(将星) + %d(美人)", basicValues.def, techBonus.defBonus, starBonus.defBonus, beautyBonus.defBonus), 
		size=20, color = display.COLOR_GREEN }):anch(0, 0.5):pos(80, 170):addTo(attrBg)

	ui.newTTFLabel({text = "攻击:", size = 22, }):anch(0, 0.5):pos(20, 205):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d + %d(科技) + %d(将星) + %d(美人)", basicValues.atk, techBonus.atkBonus, starBonus.atkBonus, beautyBonus.atkBonus), 
		size=20, color = display.COLOR_GREEN }):anch(0, 0.5):pos(80, 205):addTo(attrBg)

	ui.newTTFLabel({text = "生命:", size = 22, }):anch(0, 0.5):pos(20, 240):addTo(attrBg)
	ui.newTTFLabelWithStroke({text = string.format("%d + %d(科技) + %d(将星) + %d(美人)", basicValues.hp, techBonus.hpBonus, starBonus.hpBonus, beautyBonus.hpBonus), 
		size=20, color = display.COLOR_GREEN }):anch(0, 0.5):pos(80, 240):addTo(attrBg)

	attrBg:anch(0.5,0.5):pos(display.cx, display.cy)
	self.maskDetail = DGMask:new({item = attrBg, priority = self.priority - 10, click = function()
			self.maskDetail:getLayer():removeSelf()
		end})
	self.maskDetail:getLayer():addTo(display.getRunningScene(), 100)
end

function HeroEvolutionLayer:evolutionRequest(useYuanbao)
	local use = useYuanbao and 1 or 0

	local evolutionRequestBody = {
		roleId = game.role.id,
		mainHeroId = self.mainHeroId,
		otherHeroIds = self.fodderHeroIds,
		useYuanbao = use
	}

	local bin = pb.encode("HeroActionData", evolutionRequestBody)
    game:sendData(actionCodes.HeroEvolution, bin)
    loadingShow()
    game:addEventListener(actionModules[actionCodes.HeroEvolutionResponse], function(event)
    	loadingHide()
    	game:dispatchEvent({name = "btnClicked", data = self.evolutionBtn:getLayer()})
		local msg = pb.decode("HeroActionResponse", event.data)
		
		game:playMusic(34)

		-- 增加进化等级
    	for _, hero in ipairs(msg.heros) do
    		if game.role.heros[hero.id] then
    			game.role.heros[hero.id].evolutionCount = hero.evolutionCount
    		end
    	end

    	-- 删除素材卡
    	for _, heroId in pairs(self.fodderHeroIds) do
    		game.role.heros[heroId] = nil
    	end

    	--test
    	self:successOfRightAction()
    	self.fodderHeroIds = {}
    	self:reloadHeroData()
    	self:initContentLeft()
		self:initContentRight()

		-- 不可点击的mask
		self:showMask()

		-- 播放成功特效
    	local successSprite = display.newSprite( HeroRes .. "evolution_success.png" )
    	successSprite:scale(2):pos(self:getContentSize().width/2, self:getContentSize().height/2):addTo(self, 100)
    	successSprite:runAction(transition.sequence({
    			CCScaleTo:create(0.1, 3),
    			CCScaleTo:create(0.4, 0.6),
    			CCScaleTo:create(0.05, 0.7),
    			CCScaleTo:create(0.05, 0.6),
    			CCDelayTime:create(1),
    			CCFadeOut:create(0.5),
    			CCCallFunc:create(function() 
	    				successSprite:removeSelf() 
	    				self:showSuccessLayer()
    				end)
    		}))

    	self:showAttributeEffect()

    	game.role:dispatchEvent({ name = "notifyNewMessage", type = "heroList"})

    	return "__REMOVE__"
    end)
end

function HeroEvolutionLayer:showMask()
	self.touchMask = DGMask:new({blackMask = false, priority = -1000})
	self.touchMask:getLayer():addTo(display.getRunningScene(), 1000)
end

function HeroEvolutionLayer:removeMask()
	self.touchMask:getLayer():removeSelf()
end

function HeroEvolutionLayer:showSuccessLayer()
	local layer = EvolutionSuccessLayer.new({priority = -1100, heroId = self.mainHeroId, parent = self})
    layer:getLayer():addTo(display.getRunningScene())
end

function HeroEvolutionLayer:createAttrNode()
	local tempNode = display.newSprite(HeroGrowthRes .. "evol_attr_bg.png")
	local nodeSize = tempNode:getContentSize()

	display.newSprite(HeroGrowthRes .. "arrow.png"):anch(0.5,0.5):pos(nodeSize.width/2 - 15, nodeSize.height/2):addTo(tempNode)

	local attrKeys = {
			{res = "attr_hp.png", key = "hp"},
			{res = "attr_atk.png", key = "atk"},
			{res = "attr_def.png", key = "def"},
	}
	local attrNode = function(xPos, yPos, isNext, attrs)
		if isNext then
			local nextEvolCount = math.min(self.mainHero.evolutionCount+1, evolutionModifyCsv:getEvolMaxCount())
			local name = ui.newTTFLabel({text = self.mainHero:getHeroName(nextEvolCount), size = 24, font = ChineseFont, color = uihelper.getEvolColor(nextEvolCount)})
			name:anch(0, 1):pos(xPos, yPos):addTo(tempNode)
		else
			local nameString = self.mainHero:getHeroName()
			ui.newTTFLabel({ text = nameString , size = 24, font = ChineseFont, color = uihelper.getEvolColor(self.mainHero.evolutionCount) }):anch(0, 1):pos(xPos, yPos):addTo(tempNode)
		end

		yPos = yPos - 40
		for index = 1, 3 do
			display.newSprite(HeroRes .. attrKeys[index].res):anch(0, 1):pos(xPos, yPos):addTo(tempNode)
			ui.newTTFLabel({text = attrs[attrKeys[index].key], size = 20, color = uihelper.hex2rgb("#ffe194")})
				:anch(0, 1):pos(xPos+30, yPos):addTo(tempNode)
			yPos = yPos - 27
		end
	end

	if self.mainHeroId then
		local currentValues = self.mainHero:getTotalAttrValues()
		local nextValues = self.mainHero.evolutionCount >= evolutionModifyCsv:getEvolMaxCount() and currentValues or self.mainHero:getTotalAttrValues(self.mainHero:getBaseAttrValues(self.mainHero.level, self.mainHero.evolutionCount +1))
		
		attrNode(30, 130, false, currentValues)
		attrNode(263, 130, true, nextValues)
	end

	return tempNode
end

function HeroEvolutionLayer:createCardNode()
	local tempNode = display.newNode()
	tempNode:size(CCSizeMake(454, 160))
	local nodeSize = tempNode:getContentSize()

	if self.mainHeroId then
		if self.mainHero.evolutionCount < 5 then
			local nextEvolution = self.mainHero.evolutionCount + 1
			local cardNeed = self.mainHero:getEvolutionCardNeedNum()
			ui.newTTFLabel({text = string.format("吞噬%d张同星级卡牌，进化到+%d", cardNeed, nextEvolution), size = 20, color = display.COLOR_DARKYELLOW})
			:anch(0,0):pos(10, 5):addTo(tempNode)

			local startX = 26
			if cardNeed <= 4 then
				for index = 1, cardNeed do 
					local btn = self:createHeadBtn(self.fodderHeroIds[index])
					btn:anch(0,0):pos(startX + (index -1)*106, nodeSize.height - 125):addTo(tempNode)
					-- self.heroIconPoints[#self.heroIconPoints + 1] = CCPointMake(startX + (index -1)*113, nodeSize.height - 182)
				end
				
			else
				-- scroll
				self.cardScrollView = DGScrollView:new({ size = CCSizeMake(nodeSize.width - 44,106), horizontal = true, priority = self.priority - 2, divider = 12})
				for index = 1, cardNeed do 
					local cell = self:createHeadBtn(self.fodderHeroIds[index])
					cell:anch(0,0)
					self.cardScrollView:addChild(cell)
				end
				self.cardScrollView:alignCenter()
				self.cardScrollView:getLayer():anch(0,0):pos(26, nodeSize.height - 125):addTo(tempNode)

				local arrowLeft = display.newSprite(HeroGrowthRes .. "right_arrow.png")
				arrowLeft:setRotationY(180)
				arrowLeft:anch(0.5,0.5):pos(20, nodeSize.height - 90):addTo(tempNode)
				arrowLeft:runAction(CCRepeatForever:create(
					transition.sequence({
						CCFadeIn:create(0.6),
						CCFadeOut:create(0.6)
					})))

				local arrowRight = display.newSprite(HeroGrowthRes .. "right_arrow.png")
				arrowRight:anch(0.5,0.5):pos(nodeSize.width-12, nodeSize.height - 90):addTo(tempNode)
				arrowRight:runAction(CCRepeatForever:create(
					transition.sequence({
						CCFadeIn:create(0.6),
						CCFadeOut:create(0.6)
					})))
			end
		end

		if self.mainHero.evolutionCount < evolutionModifyCsv:getEvolMaxCount() then
			local cardNeed = self.mainHero:getEvolutionCardNeedNum()
			local labelSelect = ui.newTTFLabel({text = string.format("已选择 %d/%d", self:getCurrentCardNum(), cardNeed), size = 22})
			:anch(0,0):pos(320, 130):addTo(tempNode)

			labelSelect:setColor( self:getCurrentCardNum() < cardNeed and display.COLOR_RED or display.COLOR_GREEN)
		else
			local labelSelect = ui.newTTFLabel({text = "恭喜你，该武将已进化到最高阶，你真牛逼！", size = 20, color = display.COLOR_GREEN})
			:anch(0.5,0.5):pos(tempNode:getContentSize().width/2, tempNode:getContentSize().height/2 - 10):addTo(tempNode)
		end

	else
		local btn = self:createHeadBtn()
		btn:anch(0,0):pos(26, nodeSize.height - 125):addTo(tempNode)
	end

	return tempNode

end

function HeroEvolutionLayer:getCurrentCardNum()
	local num = 0
	for _, heroId in ipairs(self.fodderHeroIds) do
		local hero = game.role.heros[heroId]
		num = num + hero:getEvolutionCardNum()
	end
	return num
end


--icon
function HeroEvolutionLayer:createResourceNode()
	self.resourceNode = display.newSprite(HeroGrowthRes .. "bg_evol_material.png")
	self.resourceNode:anch(0.5, 0):pos(self.rightContentLayer:getContentSize().width/2, 112):addTo(self.rightContentLayer)
	local nodeSize = self.resourceNode:getContentSize()

	if self.mainHeroId then

		if self.mainHero.evolutionCount >= evolutionModifyCsv:getEvolMaxCount() then	
			local labelSelect = ui.newTTFLabel({text = "恭喜你，该武将已进化到最高阶，你真牛逼！", size = 20, color = display.COLOR_GREEN})
				:anch(0.5,0.5):pos(nodeSize.width/2, nodeSize.height/2 - 10):addTo(self.resourceNode)
			return
		end

		local nextEvolution = self.mainHero.evolutionCount + 1
		local resources = self.mainHero.unitData["evolMaterial" .. nextEvolution]

		local count, columns = 1, 3
		self.canInlay = false
		self.icons = {}
		for slot, itemId in ipairs(resources) do
			local itemData = itemCsv:getItemById(itemId)
			local item = game.role.items[itemId]
			local csvData = battleSoulCsv:getDataById(itemId - battleSoulCsv.toItemIndex)

			local isInlay = self.mainHero.battleSoul[tostring(slot)]
			local xPos, yPos = 77 + (count-1)%columns*128, count > columns and 54 or 148
			local itemFrame = ItemIcon.new({
				 itemId = tonum(itemId),
				 priority = self.priority - 5,
				 gray = not isInlay,
				 callback = function() 	
					local layer = BattleSoulLayer.new({
						priority = self.priority - 30, 
						hero = self.mainHero, 
						itemId = itemId,
						isInlay = isInlay,
						slot = slot,
						closeCallback = function(inlay)
							self:initContentLeft()
							self:initContentRight()
							if inlay then
								--特效
								self:showAttributeEffect(csvData)
								
								self:playBattleSoulEffect(slot)

								--检查新手引导
								if self.mainHero:canEvolution() and game:activeSpecialGuide(500) then
									self:checkGuide()
								end
							end 
						end}):getLayer()
					layer:addTo(display.getRunningScene())
				end,
			 }):getLayer()
			local scale = 0.75
			itemFrame:scale(0.75):anch(0.5, 0.5):pos(xPos, yPos):addTo(self.resourceNode)
			self.heroIconPoints[count] = CCPointMake(xPos, yPos)
			table.insert(self.icons, itemFrame)
			local itemNum = item and item.count or 0
			if not isInlay then
				display.newSprite(HeroRes .. "evolution/frame_none.png")
					:anch(0.5, 0.5):pos(itemFrame:getContentSize().width/2, itemFrame:getContentSize().height/2):addTo(itemFrame)
			end

			
			local text, res, color, action
			if not isInlay then
				if itemNum > 0 then
					if self.mainHero.level < csvData.requireLevel then
						text = "未镶嵌"
						color = "#eeb72f"
						res = "add_yellow.png"
					else
						text = "可镶嵌"
						color = "#69ff1f"
						res = "add_green.png"
						action = true
						self.canInlay = true
					end
				else
					if battleSoulCsv:canCompose(csvData.id) then
						if self.mainHero.level < csvData.requireLevel then
							text = "可合成"
							color = "#69ff1f"
							res = "add_yellow.png"
						else
							text = "可合成"
							color = "#69ff1f"
							res = "add_green.png"
						end
						
					else
						text = "无战魂"
						color = "#f4f4f4"
						res = nil
					end
				end
				--文字
				ui.newTTFLabelWithStroke({text = text, size = 18, color = uihelper.hex2rgb(color)})
					:anch(0.5, 1):pos(xPos, yPos - 5):addTo(self.resourceNode)
				--加号
				if res then
					display.newSprite(HeroRes .. "evolution/" .. res)
						:anch(0.5, 0):pos(xPos, yPos - 5):addTo(self.resourceNode)
				end
				if action then
					itemFrame:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(CCScaleTo:create(0.5, scale * 1.05), CCScaleTo:create(0.5, scale))))
				end
			end

			count = count + 1
		end
	end
end

function HeroEvolutionLayer:playBattleSoulEffect(slot)
	local pos = self.heroIconPoints[slot]
	local anim = uihelper.loadAnimation(HeroRes .. "battle_soul/", "xiangqian", 10)
	anim.sprite:anch(0.5, 0.5):pos(pos.x + 2, pos.y - 2):addTo(self.resourceNode)
	anim.sprite:runAction(transition.sequence({
		CCAnimate:create(anim.animation),
		CCRemoveSelf:create()
	}))
end

function HeroEvolutionLayer:createHeadBtn(heroId)
	local headBtn
	if not heroId then
		headBtn = DGBtn:new( GlobalRes, {"frame_empty.png"}, {
				priority = self.priority -2,
				callback = function()
					local layer = HeroEvolutionChooseLayer.new({priority = self.priority - 10, mainHeroId = self.mainHeroId, fodderHeroIds = self.fodderHeroIds, parent = self})
					display.getRunningScene():addChild(layer:getLayer())
				end
			})

		local addIcon = display.newSprite( HeroGrowthRes .. "fodder_add.png" )
		addIcon:pos(headBtn:getLayer():getContentSize().width/2, headBtn:getLayer():getContentSize().height/2):addTo(headBtn:getLayer())

		display.newSprite(GlobalRes .. "frame_bottom.png"):anch(0.5,0.5)
		:pos(headBtn:getLayer():getContentSize().width/2, headBtn:getLayer():getContentSize().height/2):addTo(headBtn:getLayer(), -1)

		if self.mainHeroId then
			addIcon:runAction(CCRepeatForever:create(
				transition.sequence({
					CCFadeIn:create(0.6),
					CCFadeOut:create(0.6)
				})))
		else
			headBtn:setEnable(self.mainHeroId)
		end
	else
		local hero = game.role.heros[heroId]
		local heroUnitData = unitCsv:getUnitByType(hero.type)
		headBtn = HeroHead.new({
				type = hero.type,
				wakeLevel = hero.wakeLevel,
				star = hero.star,
				evolutionCount = hero.evolutionCount,
				priority = self.priority -2,
				callback = function()
					local layer = HeroEvolutionChooseLayer.new({priority = self.priority - 10, mainHeroId = self.mainHeroId, fodderHeroIds = self.fodderHeroIds, parent = self})
					display.getRunningScene():addChild(layer:getLayer())
				end
			})
	end

	return headBtn:getLayer():scale(0.75)
end

function HeroEvolutionLayer:showAttributeEffect(deltaValues)
	if not deltaValues then
		local mainHero = game.role.heros[self.mainHeroId]
		local currentValues = mainHero:getTotalAttrValues()
		local previousValues = mainHero:getTotalAttrValues(mainHero:getBaseAttrValues(mainHero.level, mainHero.evolutionCount -1))
		deltaValues = { hp = math.floor(currentValues.hp - previousValues.hp), atk = math.floor(currentValues.atk - previousValues.atk), def = math.floor(currentValues.def - previousValues.def) }
	end

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

--右侧action
function HeroEvolutionLayer:successOfRightAction()

	local curHeroCount = table.nums(self.heroIconPoints)
	local endPoint = CCPointMake(220, 290)
	if curHeroCount > 0 then

		if self.rightContentLayer ~= nil then
			local views = {}
			for i=1,curHeroCount do
				local eff = CCNodeExtend.extend(CCParticleSystemQuad:create(ParticleRes .. "p_star_item.plist"))
				eff:addTo(self, 50):pos(self.heroIconPoints[i].x+450,  self.heroIconPoints[i].y+195)
				eff:setScale(1.5)
				views[#views + 1] = eff
				local bezier = ccBezierConfig()
				local sx = 96 * math.random(0,10)
				local sy = 64 * math.random(0,10)
				local ex = endPoint.x
				local ey = endPoint.y
				local arcx = math.random(0, 2)
				local arcy = math.random(1, 2)
				local bezier = self:randomBezier(sx, sy, ex, ey, arcx, arcy)
				local moveto_bezier = CCBezierTo:create(1, bezier)
				local callEnd = CCCallFunc:create(function()
					for i=1,#views do
						views[i]:removeFromParent()
					end
					-- local burst = CCNodeExtend.extend(CCParticleSystemQuad:create(ParticleRes .. "p_star_burst.plist"))
					-- burst:addTo(self, 10):pos(endPoint.x,  endPoint.y)
					self:successOfLeftAction()
					self:bootActionShow()
				
				end)
				local arr = CCArray:create()
				arr:addObject(moveto_bezier)
				arr:addObject(callEnd)
				local effSeq = CCSequence:create(arr)
				eff:runAction(effSeq)
			end
		end
	end
end

--左侧动作有待调试
function HeroEvolutionLayer:successOfLeftAction()

	if self.leftContentLayer ~= nil then
		local layer = self.leftContentLayer:getChildByTag(111)
		if layer ~= nil then
			if layer:getChildByTag(222) ~= nil then
				uihelper.shake({x = 5, y = 5, count = 26 }, layer:getChildByTag(222))
			end
		end
	end
end

--位置随机：
function HeroEvolutionLayer:randomBezier(sx, sy, ex, ey, arcx, arcy)
	local  bezier = ccBezierConfig()

	local dx = ex - sx
	local dy = ey - sy

	local x1 = math.random(sx, sx + dx *arcx)
	local y1 = math.random(sy, sy + dy *arcy)

	local x2 = math.random(sx, ex - dx *arcx)
	local y2 = math.random(sy, ey - dy *arcy)

	bezier.controlPoint_1 = ccp(x1, y1)
	bezier.controlPoint_2 = ccp(x2, y2)
	bezier.endPosition = ccp(ex, ey)
	return bezier
end

function HeroEvolutionLayer:bootActionShow()
	local anim = uihelper.loadAnimation(HeroRes .. "evolution/", "evolusion", 12)
	anim.sprite:scale(2.5):anch(0.5, 0.5):pos(220, 310):addTo(self, 999)
	anim.sprite:runAction(transition.sequence({
		CCAnimate:create(anim.animation),
		CCRemoveSelf:create(),
		})) 
end

function HeroEvolutionLayer:checkGuide(remove)
	--材料按钮
	game:addGuideNode({node = self.icons[1], remove = remove,
		guideIds = {1043}
	})
	--进化按钮
	game:addGuideNode({node = self.evolutionBtn:getLayer(), remove = remove,
		guideIds = {500}
	})
	--关闭按钮
	game:addGuideNode({node = self.closeBtn, remove = remove,
		guideIds = {1045}
	})
end

function HeroEvolutionLayer:onExit()
	self:checkGuide(true)
end


function HeroEvolutionLayer:showItemTaps(itemID,itemHave,itemType)
	self:purgeItemTaps()
	local itemTipsView = require("scenes.home.ItemTipsLayer")
	local itemTips = itemTipsView.new({
		itemId = itemID,
		itemNum = itemHave,
		itemType = itemType,
		showSource = true,
		priority = self.priority - 10,
		closeCallback = function()
			self:initContentRight()
		end,
	})
	display.getRunningScene():addChild(itemTips:getLayer())
	itemTips:setTag(self.tipsTag)
end

function HeroEvolutionLayer:purgeItemTaps()
	if display.getRunningScene():getChildByTag(self.tipsTag) then
		display.getRunningScene():getChildByTag(self.tipsTag):removeFromParent()
	end
end

return HeroEvolutionLayer