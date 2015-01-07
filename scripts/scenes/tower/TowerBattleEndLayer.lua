local GlobalRes = "resource/ui_rc/global/"
local TowerRes = "resource/ui_rc/activity/tower/"
local ParticleRes = "resource/ui_rc/particle/"
local EndRes = "resource/ui_rc/carbon/end/"
local AwardRes = "resource/ui_rc/carbon/award/"

local TowerAwardLayer = import(".TowerAwardLayer")
local TowerAttrModifyLayer = import(".TowerAttrModifyLayer")

local TowerBattleEndLayer = class("TowerBattleEndLayer", function()
	return display.newLayer()
end)

function TowerBattleEndLayer:ctor(params)
	self.params = params or {}

	self.dropItems = params.dropItems or {}
	self.priority = params.priority or -130
	self.difficult = params.difficult
	self.carbonId = params.carbonId
	self.starNum = params.starNum

	if self.params.bgImg then
		local bg=CCSprite:createWithTexture(self.params.bgImg)
		bg:setPosition(CCPoint(480,display.cy-25))
		self:addChild(bg)
		display.newColorLayer(ccc4(0, 0, 0, 150)):pos((-display.width+960)/2,-25):addTo(self)
	end

	self.mask = DGMask:new({ item = self, priority = self.priority + 1 })

	-- 重置刷塔场景ID --暂时屏蔽
	game.role:updateTowerData({ sceneId1 = 0, sceneId2 = 0, sceneId3 = 0 })
	
	if params.starNum > 0 then
		self:winPopup()
	else
		self:failurePopup()
	end
end

function TowerBattleEndLayer:winPopup()
	game:playMusic(4)

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

function TowerBattleEndLayer:showLayerByOrder()
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

function TowerBattleEndLayer:showHeros()
	local herosContent=display.newNode()
	herosContent:setContentSize(CCSizeMake(572, 166))
	herosContent:pos(0,0.5):pos(130,227):addTo(self)

	local index=1
	local posIndex = 1
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
			heroBtn:getLayer():pos((posIndex-1)*102+(posIndex-1)*16,0):addTo(herosContent)

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
				posIndex = posIndex + 1
				creaHead()
				end)
			heroBtn:getLayer():runAction(transition.sequence(actions))
		else
			if index < 5 then
				index=index+1
				creaHead()
			end
			
		end
		
	end

	creaHead()
end

function TowerBattleEndLayer:showAwardThings(value, icon)
	local awardsBg = display.newNode()
	local ico
	if icon then ico=display.newSprite(icon):anch(0, 0.5):pos(0, 3):addTo(awardsBg) end
	local valueLabel = ui.newTTFLabel({ text = value, size = 24, color = uihelper.hex2rgb("#f4f4f4")}):anch(0, 0.5)
		:pos(55,3):addTo(awardsBg)
	return awardsBg,valueLabel:getContentSize().width+ico:getContentSize().width
end

function TowerBattleEndLayer:showBoundBar()
	local barRes = "success_line_bg.png"
	local bar=display.newSprite(EndRes..barRes):pos(self.size.width/2,400):addTo(self)
	local towerDiffData = towerDiffCsv:getDiffData(self.difficult)
	local starAward,starWidth = self:showAwardThings(string.format("%d x %d", self.starNum, towerDiffData.starModify),GlobalRes .. "star/icon_big.png")
	starAward:addTo(bar)

	local starSoulNum = #self.dropItems == 0 and 0 or self.dropItems[1].num
	local starSoulAward,starSoulWidth = self:showAwardThings("+" .. starSoulNum, GlobalRes .. "starsoul.png")
	starSoulAward:addTo(bar)

	
	local gap=74
	local startX=(bar:getContentSize().width-starWidth-starSoulWidth-gap)/2

	starAward:pos(startX,34)
	starSoulAward:pos(starAward:getPositionX()+starWidth+gap,starAward:getPositionY())
	
end


function TowerBattleEndLayer:showTip()
	--line
	local line=display.newSprite(EndRes.."success_line.png"):pos(self.size.width/2,171):addTo(self)
	
	local carbonNum = self.carbonId % 100
	local addAttr,addBound=((3 - carbonNum % 3) % 3),((5 - carbonNum % 5) % 5)
	local tipText="[color=FFFFFFFF]再过[color=FF7CE810]" .. addAttr .. "[/color]关可加强属性  再过 [color=FF7CE810]" .. addBound .. "[/color] 关可结算奖励[/color]"
	local tipLabel = ui.newTTFRichLabel({ text=tipText, size = 30, font = ChineseFont }):anch(0, 0.5):pos(130,128):addTo(self)

	local carbonData = towerBattleCsv:getCarbonData(self.carbonId)
	local function endCallback()
		self.mask:getLayer():removeSelf()
		-- 有奖励 
		if carbonData.moneyAward then
			local towerEndData = { roleId = game.role.id, carbonId = self.carbonId }	
			local bin = pb.encode("TowerEndData", towerEndData)
			game:sendData(actionCodes.TowerAwardGotRequest, bin)
			loadingShow()
			local params = { carbonId = self.carbonId, priority = self.priority - 10 }
			game:addEventListener(actionModules[actionCodes.TowerAwardGotResponse], function(event)
				loadingHide()
				local msg = pb.decode("TowerAwardData", event.data)
				params.msg=msg
				local awardLayer = TowerAwardLayer.new(params)
				display.getRunningScene():addChild(awardLayer:getLayer())
				return "__REMOVE__"
			end)
		-- 有属性加成
		elseif carbonData.attrBonus then
			local attrModifyLayer = TowerAttrModifyLayer.new({ priority = self.priority - 10 })
			display.getRunningScene():addChild(attrModifyLayer:getLayer())

		-- 啥都木有
		else
			switchScene("tower")
		end
	end

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

function TowerBattleEndLayer:failurePopup()
	game:playMusic(5)

	local bg = display.newSprite(AwardRes .. "box_small_bg.png")
	local bgSize = bg:getContentSize()
	
	self.size = CCSizeMake(960, 640)
	self:setContentSize(self.size)
	self:anch(0.5, 0.5):pos(display.cx, display.cy + 25)

	bg:anch(0.5, 0.5):pos(self.size.width/2,self.size.height/2):addTo(self)

	local towerData = game.role.towerData

	local titlebg = display.newSprite(GlobalRes .. "title_bar_long.png")
		:pos(bgSize.width/2, bgSize.height - 35):addTo(bg)

	display.newSprite(TowerRes .. "gameover.png")
		:pos(titlebg:getContentSize().width/2, titlebg:getContentSize().height/2):addTo(titlebg)

	local textBg = display.newSprite(GlobalRes .. "label_long_bg.png")
	local textSize = textBg:getContentSize()
	textBg:pos(bgSize.width / 2, 200):addTo(bg)
	ui.newTTFLabel({ text = "累计闯关： ", size = 24, }):anch(0, 0.5)
		:pos(100, textSize.height / 2):addTo(textBg)
	ui.newTTFLabel({ text = (towerData.carbonId % 100 - 1) .. "次", size = 24, color = uihelper.hex2rgb("#7ce810") })
		:anch(0, 0.5):pos(230, textSize.height / 2):addTo(textBg)

	local textBg = display.newSprite(GlobalRes .. "label_long_bg.png")
	textBg:pos(bgSize.width / 2, 130):addTo(bg)
	ui.newTTFLabel({ text = "累计得星： ", size = 24 })
		:anch(0, 0.5):pos(100, textSize.height / 2):addTo(textBg)
	ui.newTTFLabel({ text = towerData.totalStarNum, size = 24, color = display.COLOR_GREEN })
		:anch(0, 0.5):pos(230, textSize.height / 2):addTo(textBg)
	display.newSprite(GlobalRes .. "star/icon_big.png"):anch(1, 0.5):pos(340, textSize.height / 2):addTo(textBg)

	local againBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png"},
		{
			priority = self.priority,
			text = { text = "继续闯关", size = 28, font = ChineseFont, color = display.COLOR_WHITE , strokeColor = display.COLOR_FONT },
			callback = function()
				switchScene("tower")
			end,
		}):getLayer()
	againBtn:anch(0.5, 0):pos(bgSize.width / 2, 20):addTo(bg)
end

function TowerBattleEndLayer:getLayer()
	return self.mask:getLayer()
end

return TowerBattleEndLayer