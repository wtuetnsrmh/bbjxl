local ShopRes  = "resource/ui_rc/shop/"
local GlobalRes = "resource/ui_rc/global/"
local GiftRes = "resource/ui_rc/gift/"
local MoneyRes = "resource/ui_rc/activity/money/"
local EndRes = "resource/ui_rc/carbon/end/"
local LevelUpRes = "resource/ui_rc/carbon/levelup/"

local MoneyBattleEndLayer = class("MoneyBattleEndLayer", function()
	return display.newLayer()
end)

function MoneyBattleEndLayer:ctor(params)

	--调试假数据：
	-- params = {kill == 100 ,all = 200, money = 300}

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

	self:showLayerByOrder()

	
end

function MoneyBattleEndLayer:showLayerByOrder()
	local actions = {}
	actions[#actions + 1] = CCDelayTime:create(0.1)
	actions[#actions + 1] = CCCallFunc:create(function() self:showBoundBar() end)

	actions[#actions + 1] = CCDelayTime:create(0.1)
	actions[#actions + 1] = CCCallFunc:create(function() self:showHeros() end)
	
	actions[#actions + 1] = CCDelayTime:create(0.3)
	actions[#actions + 1] = CCCallFunc:create(function()
		self:showTip()
	end)
	
	self:runAction(transition.sequence(actions))
end 

function MoneyBattleEndLayer:showHeros()
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

function MoneyBattleEndLayer:showAwardThings(value, icon)
	local awardsBg = display.newNode()
	local ico
	if icon then ico=display.newSprite(icon):anch(0, 0.5):pos(0, 3):addTo(awardsBg) end
	local valueLabel = ui.newTTFLabel({ text = value, size = 24, color = uihelper.hex2rgb("#f4f4f4")}):anch(0, 0.5)
		:pos(ico:getContentSize().width+10,3):addTo(awardsBg)
	return awardsBg,valueLabel:getContentSize().width+ico:getContentSize().width
end

function MoneyBattleEndLayer:showBoundBar()
	local barRes = "success_line_bg.png"
	local bar=display.newSprite(EndRes..barRes):pos(self.size.width/2,400):addTo(self)
	local towerDiffData = towerDiffCsv:getDiffData(self.difficult)
	local killLabel,skillWidth = self:showAwardThings((self.params.kill or 0),EndRes .. "kill.png")
	killLabel:addTo(bar)

	local roleExp = moneyBattleCsv:getDataById(self.params.carbonId).health * globalCsv:getFieldValue("healthToExp")
	local expAward,expWidth = self:showAwardThings("+" .. (roleExp or 0),GlobalRes .. "exp.png")
	expAward:addTo(bar)

	local moneyLabel,moneyWidth = self:showAwardThings("+" .. (self.params.money or 0), GlobalRes.."yinbi.png")
	moneyLabel:addTo(bar)

	local gap=74
	local startX=(bar:getContentSize().width-skillWidth-expWidth-moneyWidth-gap*2)/2

	killLabel:pos(startX,34)
	expAward:pos(killLabel:getPositionX()+skillWidth+gap,killLabel:getPositionY())
	moneyLabel:pos(expAward:getPositionX()+expWidth+gap,killLabel:getPositionY())
	
end


function MoneyBattleEndLayer:showTip()
	--line
	local line=display.newSprite(EndRes.."success_line.png"):pos(self.size.width/2,171):addTo(self)

	local tipText="击杀数量越多,获得银币越多哦！"
	local tipLabel = ui.newTTFRichLabel({ text=tipText, size = 30, font = ChineseFont }):anch(0, 0.5):pos(130,100):addTo(self)

	local function endCallback()
		self:removeAllChildren()
		self:getLayer():removeFromParent()
		switchScene("activity")
	end

	self.mask:click(endCallback)

	local posX = 815
	self.sureBtn = DGBtn:new(EndRes, {"continue_normal.png", "continue_pressed.png"},
		{	
			priority = self.priority,
			callback = function()	
				self:getLayer():removeSelf()
				endCallback()	
			end,
		}):getLayer()
	self.sureBtn:anch(0.5, 0.5):pos(posX, 100):addTo(self)

end


function MoneyBattleEndLayer:getLayer()
	return self.mask:getLayer()
end

return MoneyBattleEndLayer