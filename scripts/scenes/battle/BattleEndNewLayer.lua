local CarbonSweepRes = "resource/ui_rc/carbon/sweep/"
local ParticleRes = "resource/ui_rc/particle/"
local PvpRes = "resource/ui_rc/pvp/"
local EndRes = "resource/ui_rc/carbon/end/"
local GlobalRes = "resource/ui_rc/global/"
local CarbonRes = "resource/ui_rc/carbon/"
local VipRes = "resource/ui_rc/shop/vip/" 


local failureTips = {
	[1] = { --升级
		icon = "intensify.png",
		res  = "resource/ui_rc/carbon/failure/",
		levelLimit = 1,
		callback = function() 
			switchScene("home", { layer = "item", tag = 2 })
		end
	},

	[2] = { --进化
		icon = "evolution.png",
		res  = "resource/ui_rc/carbon/failure/",
		levelLimit = 1,
		callback = function() switchScene("home", { layer = "chooseHero" }) end
	},
	[3] = { --装备
		icon = "equip.png",
		res  = "resource/ui_rc/carbon/failure/",
		levelLimit = 13,
		callback = function() switchScene("home", { layer = "equip" }) end
	},

	[4] = { --抽卡
		icon = "drawcard.png",
		res  = "resource/ui_rc/carbon/failure/",
		levelLimit = 1,
		callback = function() 
			switchScene("home", { layer = "shop" ,chooseIndex=1}) 

		end
	},
}

--最后bg
local BattleEndNewLayer = class("BattleEndNewLayer", function(params)
	return display.newLayer()
end)

function BattleEndNewLayer:ctor(params)
	-- base data 
	self.params = params or {}
	self.priority = -200
	self.contentLayer=display.newSprite()
	self.contentLayer:setContentSize(CCSizeMake(960, 640))
	self.joinHeros = self.params.joinHeros or {}
	if #self.joinHeros == 0 then
		for index,hero in pairs(game.role.slots) do
			if game.role.heros[hero.heroId] then
				table.insert(self.joinHeros,{id = hero.heroId})
			end
		end
	end

	if self.params.bgImg then
		local bg=CCSprite:createWithTexture(self.params.bgImg)
		bg:setPosition(CCPoint(display.cx,display.cy-25))
		self:addChild(bg)
		display.newColorLayer(ccc4(0, 0, 0, 150)):pos(0,-25):addTo(self)	
	end
	
	self.contentLayer:pos(display.cx,display.cy):addTo(self)

	
	self.size = self.contentLayer:getContentSize()
	self.tipsTag = 2901
	self.canRemove = false
	--music
	game:playMusic(params.starNum > 0 and 4 or 5)
	--mask
	self:anch(0.5, 0.5):pos(display.cx, display.cy + 25)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1, click = function()end})

	local function endCallback(isAgain)
		if params.battleType == BattleType.PvP then
			switchScene("pvp")
		elseif params.battleType == BattleType.PvE then
			local mapBattleInfo = mapBattleCsv:getCarbonById(params.carbonId)
			local currentMap = math.floor(params.carbonId / 100) % 100
			if self.params.openNewCarbon ~= 0 then
				currentMap = math.floor(self.params.openNewCarbon / 100) % 100
			end

			self:getLayer():removeSelf()
			switchScene("carbon", { starNum = params.starNum, 
					assistInfo = params.starNum > 0 and  self.params.assistInfo or nil, 
					tag = mapBattleInfo.type, 
					initPageIndex = currentMap,
					showBoxGuide = self.showBoxGuide,
					showEntry = isAgain,
					carbonId = isAgain and params.carbonId or nil
				})
		elseif params.battleType == BattleType.Legend then
			switchScene("legend")
		elseif params.battleType == BattleType.Exped then
			switchScene("expedition")
		elseif params.battleType == BattleType.Trial then
			switchScene("activity")
		end
		
	end
	--sure btn
	local posX = 815
	local oldLevel, curLevel = params.origLevel or game.role.level, game.role.level

	--again btn
	
	self.sureBtn = DGBtn:new(CarbonRes.."end/", {"continue_normal.png", "continue_pressed.png"},
		{	
			priority = self.priority,
			callback = function()	
				endCallback()		
			end,
		})
	self.sureBtn:getLayer():anch(0.5, 0.5):pos(posX, 100):addTo(self.contentLayer)

	if params.battleType == BattleType.PvE  then

		self.againBtn = DGBtn:new(CarbonRes.."end/", {"again_normal.png", "again_pressed.png"},
		{	
			priority = self.priority,
			callback = function()
				local carbonData = game.role.carbonDataset[params.carbonId]
				local carbonCsvData = mapBattleCsv:getCarbonById(params.carbonId)
				local leftPlayCount = carbonCsvData.playCount - carbonData.playCnt
				if not game.role:isHeroBagFull() then
					if game.role.health < carbonCsvData.consumeValue then
						local HealthUseLayer = require("scenes.home.HealthUseLayer")
						local layer = HealthUseLayer.new({ priority = self.priority -10})
						layer:getLayer():addTo(display.getRunningScene())
					else
						if leftPlayCount > 0 then
							endCallback(true)	
						else
							DGMsgBox.new({text = "挑战次数不足", type = 1})
						end
					end
				else
					DGMsgBox.new({text = "背包卡牌已满！", type = 1})
				end
			end,
		})
		self.againBtn:getLayer():anch(0.5, 0.5):pos(posX, 270):addTo(self.contentLayer)
		self.disableGuideStep = {7, 8, 9, 10, 13, 14, 15, 19, 20, 21,}
		self.againBtn:setEnable(not table.find(self.disableGuideStep, game.role.guideStep))

		--出战英雄经验
		if params.starNum > 0 then
			local carbonData = mapBattleCsv:getCarbonById(params.carbonId)
			-- self.params.exp = math.ceil(carbonData.passExp * tonumber(carbonData.starExpBonus[tostring(params.starNum)]) / 100)
		end
		
	end

	if self.params.starNum > 0 then
		self.sureBtn:setEnable(false)
		self.sureBtn:getLayer():setVisible(false)
		if self.againBtn then
			self.againBtn:setEnable(false)
			self.againBtn:getLayer():setVisible(false)
		end
		
	end

	--show win or lose
	if self.params.starNum > 0 then

		self:createWinLayer()

		self.dropBg = display.newSprite()
		self.dropSize = CCSize(642,114)
		self.dropBg:setContentSize(CCSize(605,114))
		self.dropBg:anch(0.5,0.5):pos(self.size.width/2-68, 104):addTo(self.contentLayer)
		
	else
		self:createLoseLayer()
	end
	
	self:checkGuide()

	
end

--胜利
function BattleEndNewLayer:createWinLayer()
	--灰色星底部：
	if self.params.battleType == BattleType.PvE then
		self:showGreayStars()
	end
	

	--胜利字体
	self:showLightAndWordLayer()
	
	if self.params.battleType == BattleType.PvE then
		--星级评价
		self:showStarsAction(1)
	else
		self:showLayerByOrder()
	end

end

--失败：
function BattleEndNewLayer:createLoseLayer()
	self:showLightAndWordLayer()

	if self.params.battleType == BattleType.PvP then
		self:showLayerByOrder()
	else
		--变强提示
		local tipsBar=display.newSprite(EndRes.."fail_line_bg.png"):pos(self.size.width/2,370):addTo(self.contentLayer)
		local tipsLable=ui.newTTFLabel({align=ui.TEXT_ALIGN_CENTER,text="胜败乃兵家常事，你可以选择以下方式提升自己！",size=24,color=uihelper.hex2rgb("#dfba3a"),font=ChineseFont })
			:anch(0.5,0.5):pos(tipsBar:getContentSize().width/2,tipsBar:getContentSize().height/2):addTo(tipsBar)
		local tipsBg=display.newSprite(EndRes.."fail_box.png"):pos(self.size.width/2,180):addTo(self.contentLayer,100)
		
		local gap = (tipsBg:getContentSize().width-#failureTips*95-2*28)/(#failureTips-1)
		
		for index, tipData in ipairs(failureTips) do
			local posX = 68+gap*(index-1)+(index-1)*95
			local posY = tipsBg:getContentSize().height/2-20
			local tipsBtn = DGBtn:new(tipData.res, {tipData.icon},
				{	
					scale = 1.05,
					priority = self.priority - 1,
					callback = function()
						if game.role.level < tipData.levelLimit then
							if index == 3 then
								DGMsgBox.new({type = 1, text = "13级开启装备"})
								return
							else
								DGMsgBox.new({ msgId = 172 })
								return
							end
							
						end

						tipData.callback()
					end,
				})
			tipsBtn:getLayer():anch(0.5, 0):pos(posX + 0, posY):addTo(tipsBg)

		end

	end
end

--win light and word
function BattleEndNewLayer:showLightAndWordLayer()
	--light
	local isWin=self.params.starNum>0
	local lightBg = display.newSprite(EndRes .. "light.png")
	if not isWin then
		local shadeProgram = UIUtil:shaderForKey("ShaderPositionTextureGray")
		lightBg:setShaderProgram(shadeProgram)

		--字
		display.newSprite(EndRes.."lose_bg.png"):pos(self.size.width/2,500):addTo(self.contentLayer)
	end
	lightBg:pos(self.size.width / 2, self.size.height - 150):addTo(self.contentLayer,-1)
	lightBg:runAction(CCRepeatForever:create(CCRotateBy:create(1, 80)))

	if isWin and self.params.battleType ~= BattleType.PvE then
		display.newSprite(EndRes.."win.png"):pos(self.size.width/2,500):addTo(self.contentLayer)
	end

end


function BattleEndNewLayer:showAwardThings(value, icon)
	local awardsBg = display.newNode()
	local ico
	if icon then ico=display.newSprite(icon):anch(0, 0.5):pos(0, 3):addTo(awardsBg) end
	local valueLabel = ui.newTTFLabel({ text = value, size = 24, color = uihelper.hex2rgb("#f4f4f4")}):anch(0, 0.5)
		:pos(55,3):addTo(awardsBg)
	return awardsBg,valueLabel:getContentSize().width+ico:getContentSize().width
end

function BattleEndNewLayer:showDropItems()
	--line
	local line=display.newSprite(EndRes.."success_line.png"):pos(self.size.width/2,171):addTo(self.contentLayer)

	local dropCount = table.nums(self.params.dropItems)
	if self.params.battleType == BattleType.Legend then
		dropCount = 0
		for index, dropItem in ipairs(self.params.dropItems) do
			if dropItem.num and dropItem.num > 0 then
				dropCount = dropCount + dropItem.num
			end
		end 
	end

	if dropCount > 5 then
		display.newSprite(VipRes.."arrow_left.png")
			:anch(0, 0.5):pos(0, self.dropSize.height / 2):addTo(self.dropBg)
		display.newSprite(VipRes.."arrow_right.png")
			:anch(1, 0.5):pos(self.dropSize.width, self.dropSize.height / 2):addTo(self.dropBg)
	end

	local dataTable = {}
	for index, dropItem in ipairs(self.params.dropItems) do
		if dropItem.num > 1 and dropItem.itemTypeId == ItemTypeId.Hero then
			for i=1,dropItem.num do
				dataTable[#dataTable + 1] = dropItem
			end
		else
			dataTable[#dataTable + 1] = dropItem
		end
	end 

	local cellHeight = 100
	local itemsView = DGScrollView:new({ size = CCSizeMake(self.dropSize.width - 62, 
		self.dropSize.height), divider = 20, horizontal = true, priority = self.priority })
	for index, dropItem in ipairs(dataTable) do
		local itemId = itemCsv:calItemId(dropItem)
		local itemData = itemCsv:getItemById(itemId)

		local icon = ItemIcon.new({
			itemId = itemId,
			priority = self.priority,
			parent = itemsView:getLayer(),
			callback = function()
				self:showItemTaps(itemId, dropItem.num)
			end,
		}):getLayer()
		icon:scale(0.8)
		local iconSize = icon:getContentSize()

		local cell = display.newNode()
		cell:size(iconSize.width*0.8, cellHeight)

		icon:anch(0, 1):pos(0, cellHeight):addTo(cell)
		--name
		ui.newTTFLabel({ text = itemData.name, size = 20, color = display.COLOR_DARKYELLOW })
			:anch(0.5, 0):pos(iconSize.width / 2, -30):addTo(cell)
		--数量
		if  dropItem.num > 1 and dropItem.itemTypeId ~= ItemTypeId.Hero then
			ui.newTTFLabelWithStroke({text = "X " .. dropItem.num, size = 18, color = display.COLOR_GREEN })
				:anch(1, 0):pos(iconSize.width - 15, 8):addTo(icon)
		end
		itemsView:addChild(cell)
	end

	itemsView:alignCenter()
	itemsView:getLayer():anch(0.5, 0.5):pos(self.dropSize.width/2,53)
		:addTo(self.dropBg)
end

--初始化灰色星星：
function BattleEndNewLayer:showGreayStars()
	self.views = {}
	for num = 1, 3 do
		local view = display.newSprite(CarbonRes .."end/star_gray.png")
			:pos(self.size.width/2 + (num -2) * 114, self.size.height-(num%2)*43-102):addTo(self.contentLayer)
		self.views[#self.views + 1] = view
	end
end

--stars aciton
function BattleEndNewLayer:showStarsAction(index)
	if index <= tonumber(self.params.starNum) then
		local x = self.views[index]:getPositionX()
		local y = self.views[index]:getPositionY()
		local view = display.newSprite(CarbonRes .. "end/star_normal.png")
				:pos(x,y):addTo(self.contentLayer)
		view:setScale(1.5)
		local s1 = CCScaleTo:create(0.2,1.7)
		local s2 = CCScaleTo:create(0.1, 1.0)
		local e = CCEaseIn:create(s2, 80)
		local c1 = CCCallFunc:create(function()

				local particle = CCNodeExtend.extend(CCParticleSystemQuad:create(ParticleRes .. "battlewin.plist"))
				particle:addTo(self, 10):pos(x, y)
				particle:setScale(0.5)

			end)
		local d = CCDelayTime:create(0.1)
		local c2 = CCCallFunc:create(function()
				self:showStarsAction(index+1)
			end)
		local a = CCArray:create()
		a:addObject(s1)
		a:addObject(e)
		a:addObject(c1)
		a:addObject(d)
		a:addObject(c2)
		local sq = CCSequence:create(a)
		view:runAction(sq)
	else
		self:showLayerByOrder()
	end
end

--
function BattleEndNewLayer:showLayerByOrder()
	local actions = {}
	actions[#actions + 1] = CCDelayTime:create(0.1)
	actions[#actions + 1] = CCCallFunc:create(function() self:showBoundBar() end)

	actions[#actions + 1] = CCDelayTime:create(0.1)
	actions[#actions + 1] = CCCallFunc:create(function() self:showHeros() end)
	
	if self.params.battleType == BattleType.PvE or self.params.battleType == BattleType.Legend or self.params.battleType == BattleType.Trial then

		actions[#actions + 1] = CCDelayTime:create(0.3)
		actions[#actions + 1] = CCCallFunc:create(function()
			self:showDropItems()
		end)
		actions[#actions + 1] = CCDelayTime:create(0.3)
		actions[#actions + 1] = CCCallFunc:create(function()
			if self.sureBtn then
				self.sureBtn:setEnable(true)
				self.sureBtn:getLayer():setVisible(true)
				if self.againBtn then 
					self.againBtn:setEnable(not table.find(self.disableGuideStep, game.role.guideStep))
					self.againBtn:getLayer():setVisible(true)
				end
			end
		end)
	end

	if self.params.battleType == BattleType.PvP or self.params.battleType == BattleType.Exped then
		actions[#actions + 1] = CCDelayTime:create(0.3)
		actions[#actions + 1] = CCCallFunc:create(function()
			if self.sureBtn then
				self.sureBtn:setEnable(true)
				self.sureBtn:getLayer():setVisible(true)
				if self.againBtn then 
					self.againBtn:getLayer():setVisible(true)
				end
			end
		end)
	end

	self:runAction(transition.sequence(actions))
end 

function BattleEndNewLayer:showHeros()
	local herosContent=display.newNode()
	herosContent:setContentSize(CCSizeMake(572, 166))
	herosContent:pos(0,0.5):pos(130,227):addTo(self.contentLayer)

	local index=1

	local function creaHead()
		local hero
		if self.joinHeros[index] then
			hero = game.role.heros[self.joinHeros[index].id]
		end
		
		if hero then
			local heroBtn = HeroHead.new( 
			{
				type = hero.type and hero.type or 0,
				wakeLevel = hero.wakeLevel,
				star = hero.star,
				evolutionCount = hero.evolutionCount,
				heroLevel = hero.level,
				
			})
			heroBtn:getLayer():pos((index-1)*102+(index-1)*16,0):addTo(herosContent)

			local isAddExp = tonum(self.params.exp) > 0

			local hpProgress = display.newProgressTimer(EndRes .. "main_exp.png", display.PROGRESS_TIMER_BAR)
			hpProgress:setMidpoint(ccp(0, 0))
			hpProgress:setBarChangeRate(ccp(1,0))
			hpProgress:setPercentage(isAddExp and hero.oldExpPercentage or hero.exp/hero:getLevelTotalExp()*100)
			local hpSlot = display.newSprite(EndRes .. "bottom_exp.png")
			hpProgress:pos(hpSlot:getContentSize().width / 2, hpSlot:getContentSize().height / 2):addTo(hpSlot)
			hpSlot:pos(heroBtn:getLayer():getContentSize().width/2,-14):addTo(heroBtn:getLayer())

			local expLabel=ui.newTTFLabel({text = "EXP +0", size=18,color=uihelper.hex2rgb("#f4f4f4")})
				:pos(heroBtn:getLayer():getContentSize().width/2,-36):addTo(heroBtn:getLayer())

			if isAddExp then
				--进度条特效
				local seq, time = {}, 0.5
				--升级特效
				if hero.exp - self.params.exp < 0 then
					local HeroRes = "resource/ui_rc/hero/"
					local anim = uihelper.loadAnimation(HeroRes .. "growth/", "LevelUp", 12)
					anim.sprite:anch(0.5, 0.5):pos(heroBtn:getLayer():getContentSize().width/2, heroBtn:getLayer():getContentSize().height/2):addTo(heroBtn:getLayer(), 999)
					anim.sprite:runAction(transition.sequence({
						CCAnimate:create(anim.animation),
						CCRemoveSelf:create(),
					}))

					time = time / 2
					table.insert(seq, CCProgressTo:create(time, 100)) 			
				end
				table.insert(seq, CCProgressTo:create(time, hero.exp / hero:getLevelTotalExp() * 100))
				hpProgress:runAction(transition.sequence(seq))

				uihelper.numVaryEffect({node = expLabel, repeatTimes = 10, stringFormat = "EXP +%d", num = self.params.exp, effectTime = 0.5})
			end

			local actions={}
			actions[#actions+1]=CCFadeIn:create(0.1)
			actions[#actions+1]=CCDelayTime:create(0.1)
			actions[#actions+1]=CCCallFunc:create(function()
				index=index+1
				creaHead()
				end)
			heroBtn:getLayer():runAction(transition.sequence(actions))
		end
		
	end

	creaHead()
end

function BattleEndNewLayer:showBoundBar()
	local barRes = self.params.starNum>0 and "success_line_bg.png" or "fail_line_bg.png"
	local bar=display.newSprite(EndRes..barRes):pos(self.size.width/2,400):addTo(self.contentLayer)

	local gap=74
	local startX
	local expAward,expWidth,moneyAward,moneyWidth
	if self.params.battleType == BattleType.PvP then
		local zhangongAward
		zhangongAward,zgWidth = self:showAwardThings("+" .. (self.params.zhangong or 0), PvpRes .. "zhangong.png")
		zhangongAward:addTo(bar)

		moneyAward,moneyWidth = self:showAwardThings("+" .. (self.params.money or 0), GlobalRes .. "yinbi.png")
		moneyAward:addTo(bar)

		startX=(bar:getContentSize().width-zgWidth-moneyWidth-gap*2)/2

		zhangongAward:pos(startX,34)
		moneyAward:pos(zhangongAward:getPositionX()+zgWidth+gap,zhangongAward:getPositionY())
	else
		local exp = self.params.roleExp or 0
		expAward,expWidth = self:showAwardThings("+" .. exp,GlobalRes .. "exp.png")
		expAward:addTo(bar)

		moneyAward,moneyWidth = self:showAwardThings("+" .. (self.params.money or 0), GlobalRes .. "yinbi.png")
		moneyAward:addTo(bar)

		startX=(bar:getContentSize().width-expWidth-moneyWidth-gap)/2

		expAward:pos(startX,34)
		moneyAward:pos(expAward:getPositionX()+expWidth+gap,expAward:getPositionY())
	end
	
end

-- function BattleEndNewLayer:showExp()
-- 	local yPos = self.params.starNum > 0 and (self.size.height - 265) or (self.size.height - 300)
-- 	local expAward = self:showAwardThings("获得经验", "+" .. (self.params.exp or 0),GlobalRes .. "exp.png")
-- 	expAward:anch(0.5, 0.5):pos(self.size.width / 2, yPos):addTo(self.contentLayer)
-- 	local fi = CCFadeIn:create(0.5)
-- 	expAward:runAction(fi)
-- end

-- function BattleEndNewLayer:showMoney()
-- 	local yPos = self.params.starNum > 0 and (self.size.height - 310) or (self.size.height - 345)
-- 	local moneyAward = self:showAwardThings("获得银币", "+" .. (self.params.money or 0), GlobalRes .. "yinbi.png")
-- 	moneyAward:anch(0.5, 0.5):pos(self.size.width / 2, yPos):addTo(self.contentLayer)
-- 	local fi = CCFadeIn:create(0.5)
-- 	moneyAward:runAction(fi)
-- end

-- function BattleEndNewLayer:showZhangong()
-- 	local yPos = self.params.starNum > 0 and (self.size.height - 350) or (self.size.height - 385)
-- 	if self.params.battleType == BattleType.PvP then
-- 		local zhangongAward = self:showAwardThings("获得战功", "+" .. (self.params.zhangong or 0), PvpRes .. "zhangong.png")
-- 		zhangongAward:anch(0.5, 0.5):pos(self.size.width / 2, yPos):addTo(self.contentLayer)
-- 		local fi = CCFadeIn:create(0.5)
-- 		zhangongAward:runAction(fi)
-- 	end
-- end

-- function BattleEndNewLayer:showFriendCount()
-- 	if true or self.params.battleType ~= BattleType.PvE then return end

-- 	local function getFriendValue()
-- 		local friendValue = 0
-- 		if not self.params.assistInfo then return friendValue end

-- 		if self.params.starNum == 0 then return friendValue end

-- 		local assistInfo = self.params.assistInfo
-- 		if assistInfo.first == 0 then return friendValue end

-- 		if assistInfo.source == 1 then
-- 			friendValue = globalCsv:getFieldValue("friendAwardPoint")
-- 		else
-- 			friendValue = globalCsv:getFieldValue("strangeAwardPoint")
-- 		end
-- 		return friendValue
-- 	end

-- 	local friendAward = self:showAwardThings("获得友情值", "+" .. getFriendValue(), GlobalRes .. "fp_icon.png")
-- 	friendAward:anch(0.5, 0.5):pos(self.size.width / 2, self.size.height - 350):addTo(self.contentLayer)
-- 	friendAward:setVisible(false)
-- 	friendAward:setTag(666)
-- 	self:getChildByTag(666):setVisible(true)
-- 	local fi = CCFadeIn:create(0.5)
-- 	self:getChildByTag(666):runAction(fi)
-- end

function BattleEndNewLayer:checkGuide()
	
end

function BattleEndNewLayer:showParticles()
	local particle = CCNodeExtend.extend(CCParticleSystemQuad:create(ParticleRes .. "result_last.plist"))
	particle:addTo(self, 10):pos(display.cx - 200,display.cy * 1.5)
	particle:setScale(1.2)

	self:performWithDelay(function()
		local particle = CCNodeExtend.extend(CCParticleSystemQuad:create(ParticleRes .. "result_last.plist"))
		particle:addTo(self, 10):pos(display.cx + 100,display.cy * 1.2)
		particle:setScale(1)

		self.canRemove = true
	end, 0.3)
end

function BattleEndNewLayer:purgeItemTaps()
	if display.getRunningScene():getChildByTag(self.tipsTag) then
		display.getRunningScene():getChildByTag(self.tipsTag):removeFromParent()
	end
end

function BattleEndNewLayer:showItemTaps(itemID,itemCount,itemType)

	self:purgeItemTaps()
	local itemTipsView = require("scenes.home.ItemTipsLayer")
	local itemTips = itemTipsView.new({
		itemId = itemID,
		itemNum= itemCount,
		itemType = itemType,
		showSource = false,
		})
	display.getRunningScene():addChild(itemTips:getLayer())
	itemTips:setTag(self.tipsTag)

end


function BattleEndNewLayer:getLayer()
	return self.mask:getLayer()
end

return BattleEndNewLayer