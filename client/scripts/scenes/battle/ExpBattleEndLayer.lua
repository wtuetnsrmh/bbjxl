local ShopRes  = "resource/ui_rc/shop/"
local GlobalRes = "resource/ui_rc/global/"
local GiftRes = "resource/ui_rc/gift/"
local MoneyRes = "resource/ui_rc/activity/money/"
local EndRes = "resource/ui_rc/carbon/end/"
local LevelUpRes = "resource/ui_rc/carbon/levelup/"
local VipRes = "resource/ui_rc/shop/vip/" 

local ExpBattleEndLayer = class("ExpBattleEndLayer", function()
	return display.newLayer()
end)

function ExpBattleEndLayer:ctor(params)

	-- 测试时假数据：
	-- params = {time = 18,index = 1,dropItems = {
	-- 	{itemTypeId = 7,itemId = 83},
	-- 	{itemTypeId = 7,itemId = 83},
	-- 	{itemTypeId = 7,itemId = 83},
	-- 	{itemTypeId = 7,itemId = 83},
	-- 	{itemTypeId = 7,itemId = 83},
	-- 	{itemTypeId = 7,itemId = 83},
	-- 	{itemTypeId = 7,itemId = 83},
	-- 	{itemTypeId = 7,itemId = 83},
	-- 	{itemTypeId = 7,itemId = 83},
	-- 	{itemTypeId = 7,itemId = 83}
	-- },
	-- dropOthers = {}
	-- }

	--没有胜负之分：
	self.params = params or {}
	self.views = {}
	self.priority = self.params.priority or - 130

	if self.params.bgImg then
		local bg=CCSprite:createWithTexture(self.params.bgImg)
		bg:setPosition(CCPoint(480,display.cy-25))
		self:addChild(bg)
		display.newColorLayer(ccc4(0, 0, 0, 150)):pos((-display.width+960)/2,-25):addTo(self)
	end

	self.mask = DGMask:new({ item = self, priority = self.priority + 1,ObjSize = self:getContentSize(),
		click = function()
		end,
		clickOut = function()
			print(" touch close layer")
			self:removeAllChildren()
			self:getLayer():removeFromParent()
			switchScene("activity")
		end,})

	self.size = CCSizeMake(960, 640)
	self:setContentSize(self.size)
	self:anch(0.5, 0.5):pos(display.cx, display.cy + 25)
	--light
	local lightBg = display.newSprite(EndRes .. "light.png")
	lightBg:pos(self.size.width / 2, self.size.height - 150):addTo(self)
	lightBg:runAction(CCRepeatForever:create(CCRotateBy:create(1, 80)))

	--字体
	display.newSprite(EndRes.."win.png"):pos(self.size.width/2,500):addTo(self)

	local r = expBattleCsv:getDataById(self.params.index)
	local itemsData = {}
	for k,v in ipairs(self.params.dropOthers) do
		table.insert(self.params.dropItems, 1, v)
	end

	self:showLayerByOrder()

end

function ExpBattleEndLayer:showLayerByOrder()
	local actions = {}
	actions[#actions + 1] = CCDelayTime:create(0.1)
	actions[#actions + 1] = CCCallFunc:create(function() self:showBoundBar() end)

	actions[#actions + 1] = CCDelayTime:create(0.1)
	actions[#actions + 1] = CCCallFunc:create(function() self:showHeros() end)
	
	actions[#actions + 1] = CCDelayTime:create(0.3)
	actions[#actions + 1] = CCCallFunc:create(function()
		self:showDropItems()
	end)
	
	self:runAction(transition.sequence(actions))
end 

function ExpBattleEndLayer:showItemTaps(itemID,itemCount,itemType)

	local itemTipsView = require("scenes.home.ItemTipsLayer")
	local itemTips = itemTipsView.new({
		itemId = itemID,
		itemNum= itemCount,
		itemType = itemType,
		showSource = false,
		})
	display.getRunningScene():addChild(itemTips:getLayer())
end

function ExpBattleEndLayer:showDropItems()
	--line
	local line=display.newSprite(EndRes.."success_line.png"):pos(self.size.width/2,171):addTo(self)

	self.dropBg = display.newSprite()
	self.dropSize = CCSize(642,114)
	self.dropBg:setContentSize(CCSize(605,114))
	self.dropBg:anch(0.5,0.5):pos(self.size.width/2-68, 104):addTo(self)

	local dropCount = table.nums(self.params.dropItems)

	if dropCount > 5 then
		display.newSprite(VipRes.."arrow_left.png")
			:anch(0, 0.5):pos(0, self.dropSize.height / 2):addTo(self.dropBg)
		display.newSprite(VipRes.."arrow_right.png")
			:anch(1, 0.5):pos(self.dropSize.width, self.dropSize.height / 2):addTo(self.dropBg)
	end

	local dataTable = {}

	for index, dropItem in ipairs(self.params.dropItems) do
		dataTable[#dataTable + 1] = dropItem
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
		if dropItem.num and dropItem.num > 1 and dropItem.itemTypeId ~= ItemTypeId.Hero then
			ui.newTTFLabelWithStroke({text = "X " .. dropItem.num, size = 18, color = display.COLOR_GREEN })
				:anch(1, 0):pos(iconSize.width - 15, 8):addTo(icon)
		end
		itemsView:addChild(cell)
	end

	itemsView:alignCenter()
	itemsView:getLayer():anch(0.5, 0.5):pos(self.dropSize.width/2,53)
		:addTo(self.dropBg)

	local posX = 815
	self.sureBtn = DGBtn:new(EndRes, {"continue_normal.png", "continue_pressed.png"},
		{	
			priority = self.priority,
			callback = function()
				self:getLayer():removeFromParent()
				switchScene("activity")
			end,
		}):getLayer()
	self.sureBtn:anch(0.5, 0.5):pos(posX, 100):addTo(self)
end

function ExpBattleEndLayer:showHeros()
	local herosContent=display.newNode()
	herosContent:setContentSize(CCSizeMake(572, 166))
	herosContent:pos(0,0.5):pos(130,227):addTo(self)

	local index=1
	local function creaHead()
		local hero
		if game.role.slots[tostring(index)] then
			hero = game.role.heros[game.role.slots[tostring(index)].heroId]
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

			local expLabel=ui.newTTFLabel({text="EXP +0",size=18,color=uihelper.hex2rgb("#f4f4f4")})
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

function ExpBattleEndLayer:showAwardThings(value, icon)
	local awardsBg = display.newNode()
	local ico
	if icon then ico=display.newSprite(icon):anch(0, 0.5):pos(0, 3):addTo(awardsBg) end
	local valueLabel = ui.newTTFLabel({ text = value, size = 24, color = uihelper.hex2rgb("#f4f4f4")}):anch(0, 0.5)
		:pos(ico:getContentSize().width+10,3):addTo(awardsBg)
	return awardsBg,valueLabel:getContentSize().width+ico:getContentSize().width
end

function ExpBattleEndLayer:showBoundBar()
	local barRes = "success_line_bg.png"
	local bar=display.newSprite(EndRes..barRes):pos(self.size.width/2,400):addTo(self)
	local towerDiffData = towerDiffCsv:getDiffData(self.difficult)
	local time,timeWidth = self:showAwardThings(tostring(self.params.time).." 秒",EndRes .. "time.png")
	time:addTo(bar)

	local roleExp = tonum(expBattleCsv:getDataById(self.params.index).health * globalCsv:getFieldValue("healthToExp"))
	local expAward,expWidth = self:showAwardThings("+" ..roleExp ,GlobalRes .. "exp.png")
	expAward:addTo(bar)

	
	local gap=74
	local startX=(bar:getContentSize().width-timeWidth-expWidth-gap)/2

	time:pos(startX,34)
	expAward:pos(time:getPositionX()+timeWidth+gap,time:getPositionY())
	
end


function ExpBattleEndLayer:getLayer()
	return self.mask:getLayer()
end

return ExpBattleEndLayer