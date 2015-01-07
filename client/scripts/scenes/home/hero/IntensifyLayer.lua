--New Source Path 
local HeroRes = "resource/ui_rc/hero/"
local GlobalRes = "resource/ui_rc/global/"
local GrowRes = HeroRes.."growth/"
local InfoRes = HeroRes.."info/"
local ChooseRes=HeroRes.."choose/"

local HomeRes = "resource/ui_rc/home/"
local FrameActRes = "resource/skill_pic/"
local ParticleRes = "resource/ui_rc/particle/"
local DGBtn = require("uicontrol.DGBtn")
local DGMask = require("uicontrol.DGMask")

local IntensifyHeroChooseLayer = import(".IntensifyHeroChooseLayer") -- test
local IntensifySubChooseLayer = import(".IntensifySubChooseLayer")
local HeroCardLayer = import(".HeroCardLayer")

local IntensifyLayer = class("IntensifyLayer", function(params) 
	return display.newLayer(GlobalRes .. "bottom_bg.png") 
end)

function IntensifyLayer:ctor(params)
	params = params or {}
	self.heroIconPoints = {} --记录当前材料卡得位置
	self.priority = params.priority or -129
	self.callType = 1

	self.fromChoose = params.fromChoose or false	-- 选将界面可以切换武将
	self.mainHeroId = params.mainHeroId
	self.fodderHeroIds = params.fodderHeroIds or {}

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

	self.parent = params.parent
	self.closeCallback = params.closeCallback
	self:initUI()
end

function IntensifyLayer:initUI()

	self.size = self:getContentSize()
	-- 遮罩层
	self:pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self , priority = self.priority - 1,bg = HomeRes .. "home.jpg"})

	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority - 10})
	:anch(0,1):pos(0,display.height):addTo(self)

	--标签：
	local tabLabel = display.newSprite(GlobalRes .. "tab_selected.png")
	tabLabel:anch(0, 0.5):pos(self:getContentSize().width - 14, 480):addTo(self)
	local btnSize = tabLabel:getContentSize()

	display.newSprite(GlobalRes.."tab_arrow.png"):anch(1,0.5):pos(10, btnSize.height/2)
		:addTo(tabLabel)

	ui.newTTFLabelWithStroke({ text = "升级", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(tabLabel)
	
	self.closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority - 2,
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

--*******************************左侧：*******************************
function IntensifyLayer:initContentLeft()
	if self.leftContentLayer then
		self.leftContentLayer:removeSelf()
	end
	self.leftContentLayer = display.newLayer()
	self.leftContentLayer:size(480, self:getContentSize().height):pos(0,0):addTo(self, 1)
	local leftSize = self.leftContentLayer:getContentSize()

	-- --属性：
	-- local atrrBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png", "middle_disabled.png"},
	-- {
	-- 	priority = self.priority - 2,
	-- 	text = { text = "属性", size = 26, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2 },
	-- 	callback = function()
	-- 	local hero = game.role.heros[self.mainHeroId]
	-- 		self:showAttrDetails(hero)
	-- 	end,
	-- })
	-- atrrBtn:getLayer():anch(1, 1):pos(bg:getContentSize().width / 2 - 35, -20):addTo(bg)
	--换将：
	-- local changeBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png", "middle_disabled.png"},
	-- {
	-- 	priority = self.priority - 2,
	-- 	text = { text = "换将", size = 26, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2 },
	-- 	callback = function()
	-- 		local listLayer = IntensifyHeroChooseLayer.new({ priority = self.priority - 5, parent = self })
	-- 		listLayer:getLayer():anch(0.5,0):pos(display.cx, 0):addTo(display.getRunningScene())
	-- 	end,
	-- })
	-- changeBtn:getLayer():anch(0.5, 1):pos(bg:getContentSize().width / 2, -20):addTo(bg)

	--未选素材卡
	if not self.mainHeroId then
		--LeftBg
		local bg = display.newSprite(GrowRes .. "left_bg.png")
		bg:anch(1,0):pos(370, 70):addTo(self.leftContentLayer)
		bg:setTag(111)

		local cardFrame = display.newColorLayer(ccc4(1, 1, 1, 1))
		cardFrame:size(300, 450):pos((bg:getContentSize().width - 300 )/2, ( bg:getContentSize().height - 450 )/2 + 10):addTo(bg)
		local frameSize = cardFrame:getContentSize()

		local addBtn = DGBtn:new(GrowRes, {"main_add.png"}, {
				callback = function()
					local listLayer = IntensifyHeroChooseLayer.new({ priority = self.priority - 10 ,parent = self })
					display.getRunningScene():addChild(listLayer:getLayer())
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
							self.mainHeroId = prevHeroId
							self.fodderHeroIds = {}
							self:initContentLeft()
							self:initContentRight()
						end,
					})
				self.leftBtn:getLayer():scale(1/0.55):rotation(180):anch(0.5, 0.5):pos(0, layerSize.height / 2):addTo(layer)
			end

			if nextHeroId then
				self.rightBtn = DGBtn:new(HeroRes, {"switch_normal.png", "switch_selected.png"},
					{
						touchScale = {2, 2},
						priority = self.priority - 2,
						callback = function()
							self.mainHeroId = nextHeroId
							self.fodderHeroIds = {}
							self:initContentLeft()
							self:initContentRight()
						end,
					})
				self.rightBtn:getLayer():scale(1/0.55):anch(0.5, 0.5):pos(layerSize.width, layerSize.height / 2):addTo(layer)
			end
		end
	end
end

function IntensifyLayer:showAtrr(bg)
	local levelNum , expCur , expAll , percentNum = 0, 0 ,0 ,0
	local mainHero
	local afterLevel, afterExp
	if self.mainHeroId and self.mainHeroId > 0  then
		mainHero = game.role.heros[self.mainHeroId]
		afterLevel, afterExp = mainHero:getLevelAfterExp(self:getWorshipExp())
		afterLevel = afterLevel > game.role.level and game.role.level or afterLevel

		expCur = mainHero.exp
		expAll = mainHero:getLevelTotalExp()
		levelNum   =  mainHero.level
		percentNum = expCur / expAll * 100
	end
	
	--等级：
	local levelLabel = ui.newTTFLabel({text = tostring(levelNum), size = 24, color = uihelper.hex2rgb("#ffe195") }):anch(0, 0)
	:pos(54, 99):addTo(bg)

	--等级：
	local expSlot = display.newSprite(GrowRes.."exp_bg.png")
	expSlot:anch(0, 0):pos(93, 105):addTo(bg, -1)

	local expProgress = display.newProgressTimer(GrowRes.."exp_bar.png", display.PROGRESS_TIMER_BAR)
	expProgress:setMidpoint(ccp(0, 0.5))
	expProgress:setBarChangeRate(ccp(1,0))
	expProgress:setPercentage(percentNum)
	expProgress:pos(expSlot:getContentSize().width/2, expSlot:getContentSize().height/2):addTo(expSlot)

	local healthLabel = ui.newTTFLabel({ text = tostring(expCur).."/"..tostring(expAll), size = 18, color = display.COLOR_WHITE})
	healthLabel:pos(expSlot:getContentSize().width / 2, expSlot:getContentSize().height / 2):addTo(expSlot)

	if self.mainHeroId and self.mainHeroId > 0 then
		local interval = 0.6
		if afterLevel > mainHero.level then
			self:showAddtionNum(bg, afterLevel)
			
			local flag = true
			levelLabel:runAction(CCRepeatForever:create(transition.sequence({
				CCFadeOut:create(interval),
				CCCallFunc:create(function() 
						levelLabel:setString(flag and string.format("%d", afterLevel) or string.format("%d", mainHero.level))
						levelLabel:setColor(flag and uihelper.hex2rgb("#7ce810") or uihelper.hex2rgb("#ffe195"))		
						flag = not flag 
					end),
				CCFadeIn:create(interval),
			})))
		end

		if afterExp ~= mainHero.exp then
			local expProgress1 = display.newProgressTimer(GrowRes.."exp_bar.png", display.PROGRESS_TIMER_BAR)
			expProgress1:setMidpoint(ccp(0, 0.5))
			expProgress1:setBarChangeRate(ccp(1,0))
			expProgress1:setPercentage( afterExp / mainHero:getLevelExp(afterLevel) * 100)
			expProgress1:pos(expSlot:getContentSize().width/2, expSlot:getContentSize().height/2):addTo(expSlot)
			expProgress1:setOpacity(0)

			expProgress:runAction(CCRepeatForever:create(transition.sequence({
				CCFadeOut:create(interval*2),
				CCFadeIn:create(interval*2),
			})))

			expProgress1:runAction(CCRepeatForever:create(transition.sequence({
				CCFadeIn:create(interval*2),
				CCFadeOut:create(interval*2),
			})))
		end
	end
end 

function IntensifyLayer:calculateAttr()
	local currentValues = {}
	local deltaValues = {}
	if self.fodderHeroIds and table.nums(self.fodderHeroIds) > 0 then
		local curHero = game.role.heros[self.mainHeroId]
		currentValues = curHero:getTotalAttrValues() 
		local nextValues = curHero:getTotalAttrValues(curHero:getBaseAttrValues(level, curHero.evolutionCount))
		deltaValues = { hp = nextValues.hp - currentValues.hp, atk = nextValues.atk - currentValues.atk, def = nextValues.def - currentValues.def }
	end
	return deltaValues
end 

----**********************************  右侧  **********************************
function IntensifyLayer:initContentRight()
	if self.rightContentLayer then
		self.rightContentLayer:removeSelf()
	end
	self.rightContentLayer = display.newLayer(InfoRes .. "detail_rightbg.png")
	self.rightContentLayer:anch(0, 0.5):pos(400, self.size.height / 2):addTo(self)

	local rightSize = self.rightContentLayer:getContentSize()

	--卡牌属性；
	local attrBg = display.newSprite(GrowRes .. "levelup_attr_bg.png")
	attrBg:anch(0, 1):pos(30, rightSize.height-25):addTo(self.rightContentLayer)
	local attrBgSize = attrBg:getContentSize()
	local attrs = {}
	if self.mainHeroId and self.mainHeroId > 0  then
		local curHero = game.role.heros[self.mainHeroId]
		attrs = curHero:getTotalAttrValues() or {}
	end
	

	display.newSprite(GrowRes .. "lv_label.png"):anch(0, 1):pos(22, attrBgSize.height - 12):addTo(attrBg)
	self:showAtrr(attrBg)

	local iamges = {"attr_hp.png","attr_atk.png","attr_def.png"}
	local atts = {"hp","atk","def"}
	local yPos, num = 90, 0
	for i=1, 3 do
		local xPos = 92
		--icon
		local icon = display.newSprite(HeroRes .. iamges[i]):anch(0, 1):pos(xPos, yPos):addTo(attrBg)
		xPos = xPos + icon:getContentSize().width + 15
		if self.mainHeroId and self.mainHeroId > 0 then
			num = math.floor(attrs[atts[i]])
		end
		--numlabel
		ui.newTTFLabel({ text = tostring(num), size = 20, color = uihelper.hex2rgb("#ffe195") })
			:anch(0, 1):pos(xPos,yPos):addTo(attrBg)

		yPos = yPos - 27
	end

	--材料
	local materialLayer = self:createHeroFodderLayer()
	materialLayer:anch(0, 0):pos(30, 135):addTo(self.rightContentLayer)

	--消耗
	local costBg = display.newSprite(GrowRes .. "levelup_cost_bg.png")
	costBg:anch(0.5, 0):pos(rightSize.width/2, 86):addTo(self.rightContentLayer)

	
	local costLabel = ui.newTTFLabel({ text = string.format("消耗：%d", self:getWorshipMoney()), size = 22, color = uihelper.hex2rgb("#533a22")})
	costLabel:anch(0, 0.5):addTo(costBg)
	local xPos, yPos = 0, costLabel:getContentSize().height/2
	xPos = xPos + costLabel:getContentSize().width + 6
	local moneyIcon = display.newSprite(GlobalRes .. "yinbi.png"):anch(0, 0.5):pos(xPos, yPos):addTo(costLabel)

	xPos = xPos + moneyIcon:getContentSize().width + 15
	local text = ui.newTTFLabel({text = string.format("获得经验：%d", self:getWorshipExp()), size = 22, color = uihelper.hex2rgb("#533a22")})
		:anch(0, 0.5):pos(xPos, yPos):addTo(costLabel)
	xPos = xPos + text:getContentSize().width
	xPos = (costBg:getContentSize().width - xPos)/2
	costLabel:pos(xPos, costBg:getContentSize().height/2)


	-- 升级按钮
	local fontSize = 26
	local intensifyBtn = DGBtn:new(GlobalRes,{"middle_normal.png", "middle_selected.png", "middle_disabled.png"},
		{
			priority = self.priority -2,
			callback = function()
				local hasHigh = false
				for heroId in pairs(self.fodderHeroIds) do
					local hero = game.role.heros[heroId]
					if hero.unitData.stars >= 4 and not unitCsv:isExpCard(hero.type) then
						hasHigh = true
						break
					end
				end

				if hasHigh then
					DGMsgBox.new({ msgId = SYS_ERR_HERO_STAR, 
						button1Data = {
							callback = function()
								return
							end
						},
						button2Data = {
							callback = function()
								self:intensifyAction()
							end
					}})
				else
					self:intensifyAction()
				end	
			end,
			text = { text = "升 级", size = fontSize, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2}
		})
	intensifyBtn:setEnable(self.mainHeroId and table.nums(self.fodderHeroIds) > 0)
	intensifyBtn:getLayer():anch(0.5,0):pos(rightSize.width / 2 + 110, 10):addTo(self.rightContentLayer)

	-- 自动添加按钮
	local autoAddBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png", "middle_disabled.png"}, {
			priority = self.priority -2,
			callback = function()
				self:autoChooseWorshipHeros()
				self:initContentLeft()
				self:initContentRight()

				if game.role.guideStep == 11 or game.role.guideStep == 12 or game.role.guideStep == 13 then
					self.guideStep = self.guideStep + 1
					self:checkGuide()
				end
			end,
			text = { text = "自动添加", size = fontSize, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2}
		})
	autoAddBtn:setEnable(self.mainHeroId and not game.role.heros[self.mainHeroId]:isLevelAndExpFull())
	autoAddBtn:getLayer():anch(0.5,0):pos(rightSize.width / 2 - 110, 10):addTo(self.rightContentLayer)

end

function IntensifyLayer:getWorshipExp()
	local heroIds = table.keys(self.fodderHeroIds)
	local ret = 0
	for _,heroId in pairs(heroIds) do
		local hero = game.role.heros[heroId]
		ret = ret + hero:getWorshipExp()
	end
	return ret
end

function IntensifyLayer:getWorshipMoney()
	local heroIds = table.keys(self.fodderHeroIds)
	local ret = 0
	for _,heroId in pairs(heroIds) do
		local hero = game.role.heros[heroId]
		ret = ret + hero:getWorshipMoney()
	end
	return ret
end

function IntensifyLayer:autoChooseWorshipHeros()
	self.fodderHeroIds = {}
	local allHeros = {}

	for heroId, hero in pairs(game.role.heros) do
		local heroUnitData = unitCsv:getUnitByType(hero.type)
		if heroId ~= self.mainHeroId 
			and hero.master == 0 
			and hero.choose == 0 
			and ( heroUnitData.stars < 3 
			and hero.level == 1
			and hero.evolutionCount == 0
			or unitCsv:isExpCard(hero.type) ) then
			table.insert(allHeros, hero)
		end
	end
	table.sort(allHeros, function(a,b) 
			local unitA = unitCsv:getUnitByType(a.type)
			local unitB = unitCsv:getUnitByType(b.type)

			local factorA = (unitCsv:isExpCard(a.type) and 1 or 0) * 100000 - unitA.stars * 10000 
			local factorB = (unitCsv:isExpCard(b.type) and 1 or 0) * 100000 - unitB.stars * 10000 
			return factorA > factorB
		end)

	local count = 0
	local maxExp = game.role.heros[self.mainHeroId]:getLevelMaxExp()
	local totalExp = 0
	for _, hero in ipairs(allHeros) do
		self.fodderHeroIds[hero.id] = table.nums(self.fodderHeroIds) + 1

		totalExp = totalExp + hero:getWorshipExp()
		count = count + 1

		if count >= 9 or totalExp > maxExp then
			break
		end
	end
end

--头像
function IntensifyLayer:createHeroFodderLayer()
	self.heroIconPoints = {}
	local tempLayer = display.newLayer(GrowRes .. "levelup_material_bg.png")
	
	local fodderHeroIds = table.keys(self.fodderHeroIds)
	local columns = 4
	for index = 1, 8 do
		local x = 60 + (index - 1) % columns * 98
		local y = index > columns and 52 or 146
		local headBtn = self:createHeadBtn(fodderHeroIds[index])
		if fodderHeroIds[index] then
			self.heroIconPoints[#self.heroIconPoints + 1] = CCPointMake(x, y)
		end
		headBtn:setScale(0.7)
		headBtn:anch(0.5, 0.5):pos(x,y):addTo(tempLayer)
	end

	return tempLayer
end

--创建头像
function IntensifyLayer:createHeadBtn(heroId)
	local headBtn
	if not heroId then  --空
		headBtn = DGBtn:new(GlobalRes, {"frame_bottom.png"}, 
			{
				-- scale = 0.7,
				priority = self.priority -2,
				callback = function()
					local mainHero = game.role.heros[self.mainHeroId]
					if mainHero:isLevelAndExpFull() then
						DGMsgBox.new({msgId = SYS_ERR_HERO_MAIN_LEVEL_LIMIT})
					else
						-- local layer = HeroIntensifyChooseLayer.new({mainHeroId = self.mainHeroId, fodderHeroIds = table.keys(self.fodderHeroIds), priority = self.priority -10, parent = self})
						-- display.getRunningScene():addChild(layer:getLayer(),99999)
						local layer = IntensifySubChooseLayer.new({mainHeroId = self.mainHeroId, fodderHeroIds = table.keys(self.fodderHeroIds), priority = self.priority -10, parent = self})
						layer:anch(0.5,0):pos(display.cx - 30,0)
						display.getRunningScene():addChild(layer:getLayer(),99999)
						
					end
				end
			})
		--外框
		display.newSprite(GlobalRes.."frame_empty.png")
		:anch(0.5,0.5)
		:pos(headBtn:getLayer():getContentSize().width/2,headBtn:getLayer():getContentSize().height/2)
		:addTo(headBtn:getLayer())

		--加号
		local addIcon = display.newSprite(ChooseRes.. "add.png" )
		addIcon:pos(headBtn:getLayer():getContentSize().width/2, headBtn:getLayer():getContentSize().height/2):addTo(headBtn:getLayer())

		if self.mainHeroId then
			addIcon:runAction(CCRepeatForever:create(
				transition.sequence({
					CCFadeIn:create(0.6),
					CCFadeOut:create(0.6)
				})))
		else
			headBtn:setEnable(false)
		end

	else --hero
		local hero = game.role.heros[heroId]
		local heroUnitData = unitCsv:getUnitByType(hero.type)
		headBtn = HeroHead.new({ type = hero.type,
			wakleLevel = hero.wakeLevel,
			star = hero.star,
			evolutionCount = hero.evolutionCount,
			priority = self.priority -2,
			callback = function()
				-- local layer = HeroIntensifyChooseLayer.new({mainHeroId = self.mainHeroId, fodderHeroIds = table.keys(self.fodderHeroIds), priority = self.priority -10, parent = self})
				-- display.getRunningScene():addChild(layer:getLayer(),99999)
				self.fodderHeroIds[heroId] = nil
				self:initContentRight()

			end })
		-- local headIcon = display.newSprite(heroUnitData.headImage)
		-- headIcon:pos(headBtn:getLayer():getContentSize().width/2, headBtn:getLayer():getContentSize().height/2):addTo(headBtn:getLayer(), -1)
	end
	return headBtn:getLayer()
end

-- 发送强化请求到服务端处理
function IntensifyLayer:intensifyAction()
	local fodderHeroIds = table.keys(self.fodderHeroIds)
	if not self.mainHeroId or #fodderHeroIds == 0 then
		return
	end

	self.mainHeroLevel = game.role.heros[self.mainHeroId].level
	self.mainHeroExp = game.role.heros[self.mainHeroId].exp
	
	local intensifyRequest = {
		roleId = game.role.id,
		mainHeroId = self.mainHeroId,
		otherHeroIds = fodderHeroIds
	}
	self.previousLevel = game.role.heros[self.mainHeroId].level

	local bin = pb.encode("HeroActionData", intensifyRequest)
    game:sendData(actionCodes.HeroIntensify, bin, #bin)
    loadingShow()
    game:addEventListener(actionModules[actionCodes.HeroIntensifyResponse], function(event)
    	loadingHide()
    	game:playMusic(34)

    	local msg = pb.decode("HeroActionResponse", event.data)
    	if msg.result ~= 0 then print("fail") return "__REMOVE__" end

    	-- 强化成功
    	self.fodderHeroIds = self.fodderHeroIds or {}
    	for heroId, value in pairs(self.fodderHeroIds) do
    		game.role.heros[heroId] = nil
    	end

    	self.fodderHeroIds = {}

    	--初始化前
		self:successOfRightAction()
    	--intensify
    	self:initContentLeft()
    	self:initContentRight()

    	--注册刷新事件：
    	game.role:dispatchEvent({name = "after_intensify"})

    	-- 播放成功特效
    	local successSprite = display.newSprite( HeroRes .. "intensify_success.png" )
    	successSprite:scale(2):pos(self:getContentSize().width/2, self:getContentSize().height/2):addTo(self, 100)
    	successSprite:runAction(transition.sequence({
    			CCScaleTo:create(0.1, 3),
    			CCScaleTo:create(0.4, 0.6),
    			CCScaleTo:create(0.05, 0.7),
				CCScaleTo:create(0.05, 0.6),
    			CCDelayTime:create(0.5),
    			CCCallFunc:create(function() successSprite:removeSelf() end)
    		}))

    	if self.previousLevel and game.role.heros[self.mainHeroId].level > self.previousLevel then
			self:showAttributeEffect(self.previousLevel)		
		end

    	return "__REMOVE__"
    end)

end

function IntensifyLayer:showAttributeEffect(previousLevel, callback)
	callback = callback or function() end
	local mainHero = game.role.heros[self.mainHeroId]
	local currentValues = mainHero:getTotalAttrValues()
	local previousValues = mainHero:getTotalAttrValues(mainHero:getBaseAttrValues(previousLevel, mainHero.evolutionCount))
	local deltaValues = { hp = math.floor(currentValues.hp - previousValues.hp), atk = math.floor(currentValues.atk - previousValues.atk), def = math.floor(currentValues.def - previousValues.def) , level = mainHero.level - previousLevel}

	self.levelNode = display.newNode()
	local levelTextSprite = display.newSprite(HeroRes .. "level_text.png")
	local levelTips = ui.newBMFontLabel({ text = "+" .. deltaValues.level, font = FontRes .. "attrNum.fnt"})
	
	local width, height = levelTextSprite:getContentSize().width + levelTips:getContentSize().width, levelTips:getContentSize().height
	self.levelNode:size(width, height)
	levelTextSprite:anch(0, 0.5):pos(0, height / 2):addTo(self.levelNode)
	levelTips:anch(1, 0.5):pos(width, height / 2):addTo(self.levelNode)
	self.levelNode:anch(0.5,0.5):pos(self:getContentSize().width/2, self:getContentSize().height/2 + 80):addTo(self, 1)
	self.levelNode:setVisible(false)

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

	self.levelNode:runAction(transition.sequence({
		CCDelayTime:create(0.5),
		CCCallFunc:create(function() self.levelNode:setVisible(true) end),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 40)), CCScaleTo:create(0.1, 1.5)),
		CCDelayTime:create(0.2),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 20)), CCScaleTo:create(0.1, 1)),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.5, ccp(0, 80)), CCFadeOut:create(0.5)),
		CCRemoveSelf:create()
	}))
	
	self.hpNode:runAction(transition.sequence({
		CCDelayTime:create(1.0),
		CCCallFunc:create(function() self.hpNode:setVisible(true) end),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 40)), CCScaleTo:create(0.1, 1.5)),
		CCDelayTime:create(0.2),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 20)), CCScaleTo:create(0.1, 1)),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.5, ccp(0, 80)), CCFadeOut:create(0.5)),
		CCRemoveSelf:create()
	}))

	self.atkNode:runAction(transition.sequence({
		CCDelayTime:create(1.5),
		CCCallFunc:create(function() self.atkNode:setVisible(true) end),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 40)), CCScaleTo:create(0.1, 1.5)),
		CCDelayTime:create(0.2),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 20)), CCScaleTo:create(0.1, 1)),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.5, ccp(0, 80)), CCFadeOut:create(0.5)),
		CCRemoveSelf:create()
	}))

	self.defNode:runAction(transition.sequence({
		CCDelayTime:create(2.0),
		CCCallFunc:create(function() self.defNode:setVisible(true) end),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 40)), CCScaleTo:create(0.1, 1.5)),
		CCDelayTime:create(0.2),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 20)), CCScaleTo:create(0.1, 1)),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.5, ccp(0, 80)), CCFadeOut:create(0.5)),
		CCRemoveSelf:create(),
		CCCallFunc:create(callback)
	}))

end

--左侧动作有待调试
function IntensifyLayer:successOfLeftAction()

	if self.leftContentLayer ~= nil then
		local layer = self.leftContentLayer:getChildByTag(111)
		if layer ~= nil then
			if layer:getChildByTag(222) ~= nil then
				uihelper.shake({x = 5, y = 5, count = 26 }, layer:getChildByTag(222))
			end
		end
	end
end

--右侧action
function IntensifyLayer:successOfRightAction()

	local curHeroCount = table.nums(self.heroIconPoints)
	local endPoint = CCPointMake(220, 290)
	if curHeroCount > 0 then

		if self.rightContentLayer ~= nil then
			local views = {}
			for i=1,curHeroCount do
				local eff = CCNodeExtend.extend(CCParticleSystemQuad:create(ParticleRes .. "p_star_item.plist"))
				eff:addTo(self, 50):pos(self.heroIconPoints[i].x+433,  self.heroIconPoints[i].y+167)
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
				local moveto_bezier = CCBezierTo:create(1.0, bezier)
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

--位置随机：
function IntensifyLayer:randomBezier(sx, sy, ex, ey, arcx, arcy)
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

function IntensifyLayer:bootActionShow()
	local xPos, yPos = 220, 285
	local effect1 = CCNodeExtend.extend(CCParticleSystemQuad:create(ParticleRes .. "intensify_effect_1.plist"))
	effect1:scale(0.5):pos(xPos, yPos):addTo(self, 999)
	effect1:runAction(CCScaleTo:create(0.13, 1.2))

	CCNodeExtend.extend(CCParticleSystemQuad:create(ParticleRes .. "intensify_effect_2.plist"))
		:pos(xPos, yPos):addTo(self, 999)
	self:performWithDelay(function()
    		CCNodeExtend.extend(CCParticleSystemQuad:create(ParticleRes .. "intensify_effect_3.plist"))
				:scale(1.3):pos(xPos, yPos):addTo(self, 999)
		end, 0.37)	

	-- local anim = uihelper.loadAnimation(HeroRes .. "evolution/", "evolusion", 16)
	-- anim.sprite:scale(2.5):anch(0.5, 0.5):pos(220, 310):addTo(self, 999)
	-- anim.sprite:runAction(transition.sequence({
	-- 	CCAnimate:create(anim.animation),
	-- 	CCRemoveSelf:create(),
	-- 	})) 
end

--属性加成：
function IntensifyLayer:showAddtionNum(parent, level)

	local interval = 0.6
	local curHero = game.role.heros[self.mainHeroId]
	local currentValues = curHero:getTotalAttrValues()
	local nextValues
	local deltaValues

	nextValues = curHero:getTotalAttrValues(curHero:getBaseAttrValues(level, curHero.evolutionCount))
	deltaValues = { hp = nextValues.hp - currentValues.hp, atk = nextValues.atk - currentValues.atk, def = nextValues.def - currentValues.def }

	-- local path = "resource/ui_rc/battle/font/num_b.fnt"				
	-- self.hpLabel2 = ui.newBMFontLabel({ text =string.format("+%d", deltaValues.hp), font = path}):anch(0, 0):scale(0.6):pos(300,420):addTo(parent)
	-- self.atkLabel2 = ui.newBMFontLabel({ text = string.format("+%d", deltaValues.atk), font = path}):anch(0, 0):scale(0.6):pos(300,380):addTo(parent)
	-- self.defLabel2 = ui.newBMFontLabel({ text = string.format("+%d", deltaValues.def), font = path}):anch(0, 0):scale(0.6):pos(300,340):addTo(parent)

	self.hpLabel2 = ui.newTTFLabel({ text =string.format("+%d", deltaValues.hp),size = 20,color = uihelper.hex2rgb("#7ce810")}):anch(0, 1):pos(274, 90):addTo(parent)
	self.atkLabel2 = ui.newTTFLabel({ text = string.format("+%d", deltaValues.atk), size = 20,color = uihelper.hex2rgb("#7ce810")}):anch(0, 1):pos(274,90-27):addTo(parent)
	self.defLabel2 = ui.newTTFLabel({ text = string.format("+%d", deltaValues.def), size = 20,color = uihelper.hex2rgb("#7ce810")}):anch(0, 1):pos(274,90-27*2):addTo(parent)

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

function IntensifyLayer:showAttrDetails(hero)
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

function IntensifyLayer:checkGuide()
	
end

function IntensifyLayer:onEnter()
	self:initContentLeft()
	self:initContentRight()
	self:checkGuide()
end

function IntensifyLayer:getLayer()
	return self.mask:getLayer()
end

function IntensifyLayer:onCleanup()
	self.heroIconPoints = nil
	-- display.removeUnusedSpriteFrames()
end

return IntensifyLayer