-- 武将觉醒界面
-- by yujiuhe
-- 2014.7.29

local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"
local HeroGrowthRes = "resource/ui_rc/hero/growth/"
local HomeRes = "resource/ui_rc/home/"
local HeroInfoRes = "resource/ui_rc/hero/info/"

local HeroCardLayer = import(".HeroCardLayer")
local WakeHeroChooseLayer = import(".WakeHeroChooseLayer")
local ConfirmDialog = import("...ConfirmDialog")
local WakeSuccessLayer = import(".WakeSuccessLayer")
local ItemSourceLayer = require("scenes.home.ItemSourceLayer")


local HeroWakeLayer = class("HeroWakeLayer", function(params) return display.newLayer() end)

function HeroWakeLayer:ctor(params)

	params = params or {}

	self.fromChoose = params.fromChoose or false
	self.priority = params.priority or -129
	self.mainHeroId = params.mainHeroId
	self.parent = params.parent
	self.closeCallback = params.closeCallback
	self:reloadHeroData()

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

	self:initUI()

	self:initContentLeft()
	self:initContentRight()
end

function HeroWakeLayer:onEnter()
	self:checkGuide()
end

function HeroWakeLayer:initUI()
	local bg = display.newSprite(GlobalRes .. "bottom_bg.png")
	local bgSize = bg:getContentSize()
	self:size(bgSize)
	self.size = bgSize
	bg:anch(0, 0):pos(0, 0):addTo(self)
	-- 遮罩层
	self:anch(0, 0):pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self , priority = self.priority, bg = HomeRes .. "home.jpg"})


	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority - 10})
	:anch(0,1):pos(0,display.height):addTo(self)

	local tabLabel = display.newSprite(GlobalRes .. "tab_selected.png")
	tabLabel:anch(0, 0.5):pos(self:getContentSize().width - 14, 480):addTo(self)
	local btnSize = tabLabel:getContentSize()

	display.newSprite(GlobalRes.."tab_arrow.png"):anch(1,0.5):pos(10, btnSize.height/2)
		:addTo(tabLabel)

	ui.newTTFLabelWithStroke({ text = "觉醒", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(tabLabel)

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
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
	closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self)
end

function HeroWakeLayer:reloadHeroData()
	if self.mainHeroId then
		self.mainHero = game.role.heros[self.mainHeroId]
		self.mainHeroUnitData = unitCsv:getUnitByType(self.mainHero.type)
		self.wakeCsvData = heroWakeCsv:getByHeroStar(self.mainHeroUnitData.stars)
	end
end

function HeroWakeLayer:getLayer()
	return self.mask:getLayer()
end

--左侧
function HeroWakeLayer:initContentLeft()
	if self.leftContentLayer then
		self.leftContentLayer:removeSelf()
	end
	self.leftContentLayer = display.newLayer()
	self.leftContentLayer:size(480, self:getContentSize().height):pos(0,0):addTo(self, 1)

	local leftSize = self.leftContentLayer:getContentSize()
	
	local layer = HeroCardLayer.new({ heroId = self.mainHeroId })
	layer:scale(0.55):anch(1, 0):pos(390, 10):addTo(self.leftContentLayer)

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
end

--右侧
function HeroWakeLayer:initContentRight()
	-- self.heroIconPoints = {}
	if self.rightContentLayer then
		self.rightContentLayer:removeSelf()
	end
	self.rightContentLayer = display.newLayer(HeroInfoRes .. "detail_rightbg.png")
	self.rightContentLayer:anch(0, 0.5):pos(400, self.size.height / 2):addTo(self)

	local rightSize = self.rightContentLayer:getContentSize()
	local maxWakeLevel = self.wakeCsvData.wakeLevelMax

	--上半部分
	local upperBg = display.newSprite(HeroGrowthRes .. "wake_upper_bg.png")
	upperBg:anch(0.5, 1):pos(rightSize.width/2, rightSize.height - 23):addTo(self.rightContentLayer, 100)
	local upperBgSize = upperBg:getContentSize()

	local attrKeys = {
			{res = "attr_hp.png", key = "hp"},
			{res = "attr_atk.png", key = "atk"},
			{res = "attr_def.png", key = "def"},
	}
	local wakeNode = function(xPos, yPos, wakeLevel)
		local baseAttrs = self.mainHero:getBaseAttrValues(nil, nil, wakeLevel)
		local attrs = self.mainHero:getTotalAttrValues(baseAttrs)
		--头像
		local heroHead = HeroHead.new({type = self.mainHero.type, hideStars = true, wakeLevel = wakeLevel, star = self.mainHero.star, evolutionCount = self.mainHero.evolutionCount})
		heroHead:getLayer():scale(0.9):anch(0, 1):pos(xPos, yPos):addTo(upperBg)
		--属性
		yPos = yPos - 5
		xPos = xPos + 114
		for index = 1, 3 do
			display.newSprite(HeroRes .. attrKeys[index].res):anch(0, 1):pos(xPos, yPos):addTo(upperBg)
			ui.newTTFLabel({text = attrs[attrKeys[index].key], size = 20, color = uihelper.hex2rgb("#ffe194")})
				:anch(0, 1):pos(xPos+30, yPos):addTo(upperBg)
			yPos = yPos - 27
		end
	end

	wakeNode(100, upperBgSize.height - 56, self.mainHero.wakeLevel)
	wakeNode(100, upperBgSize.height - 202, math.min(self.mainHero.wakeLevel + 1, maxWakeLevel))


	--下半部分
	local bottomBg = display.newSprite(HeroGrowthRes .. "wake_bottom_bg.png")
	bottomBg:anch(0.5, 0):pos(rightSize.width/2, 20):addTo(self.rightContentLayer)
	local bottomBgSize = bottomBg:getContentSize()
	
	if maxWakeLevel > self.mainHero.wakeLevel then
		ui.newTTFLabel({ text = "所需材料：", size = 20, color = uihelper.hex2rgb("#533a27") }):anch(0, 0):pos(105, 114):addTo(bottomBg)
		ui.newTTFLabel({ text = self.mainHeroUnitData.name .. "碎片", size = 20, color = uihelper.hex2rgb("#a62400") }):anch(0, 0):pos(200, 114):addTo(bottomBg)	

		display.newSprite(HeroRes .. "fragment_tag.png"):anch(0, 0.5):pos(15, 88):addTo(bottomBg)

		--进度条
		local expSlot = display.newSprite(HeroGrowthRes .. "wake_progress_bg.png")
		expSlot:anch(0, 0.5):pos(58, 88):addTo(bottomBg, -1)
		self.expProgress = display.newProgressTimer(HeroGrowthRes .. "wake_progress_fg.png", display.PROGRESS_TIMER_BAR)
		self.expProgress:setMidpoint(ccp(0, 0.5))
		self.expProgress:setBarChangeRate(ccp(1,0))
		local costFragment = self.wakeCsvData.costHeroFragment[self.mainHero.wakeLevel + 1]
		local fragmentId = math.floor(self.mainHero.type + 2000)
		local curFragment = game.role.fragments[fragmentId] or 0
		self.expProgress:setPercentage( curFragment / costFragment * 100)
		self.expProgress:pos(expSlot:getContentSize().width/2, expSlot:getContentSize().height/2):addTo(expSlot)
		local expLabel = ui.newTTFLabel({text = string.format("%d/%d", curFragment, costFragment), size = 18})
		expLabel:pos(expSlot:getContentSize().width/2, expSlot:getContentSize().height/2):addTo(expSlot)
		
		--加号
		DGBtn:new(GlobalRes, {"add_normal.png", "add_selected.png"}, 
		{
			priority = self.priority - 10,
			callback = function()
				if game.role:heroExist(self.mainHero.type, 2) then
					DGMsgBox.new({
						text = "已有同名武将，是否去分解？", 
						type = 2, 
						button1Data = {
							text = "获得途径",
							callback = function()
								self:openItemSourceLayer(fragmentId)
							end
						},
						button2Data = {
							text = "去分解",
							callback = function()
								local HeroDecomposeLayer = require("scenes.home.hero.HeroDecomposeLayer")
								local layer = HeroDecomposeLayer.new({priority = self.priority - 10, closeCallback = function()
									self:initContentRight()
								end})
								layer:getLayer():addTo(display.getRunningScene())
							end
						}
					})
				else
					self:openItemSourceLayer(fragmentId)
				end
			end,
		}):getLayer():anch(0, 0.5):pos(360, 88):addTo(bottomBg)
		--觉醒按钮
		self.wakeBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png", "middle_disabled.png"}, {
			text = {text = "觉 醒", size = 28, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			priority = self.priority -1,
			callback = function()
				if curFragment < costFragment then 
					DGMsgBox.new({msgId = 302})
					return 
				end
				local addAssistDialog = ConfirmDialog.new({
					priority = self.priority - 10,
            		showText = { text = string.format("是否消耗%d[image=resource/ui_rc/global/yinbi.png][/image]觉醒？", self.wakeCsvData.costMoney[self.mainHero.wakeLevel+1]), size = 28, },
            		button2Data = {
                		callback = function()
                    		local wakeRequst = {
                       			roleId = game.role.id,
                        		mainHeroId = self.mainHeroId,
                    		}
                    		local bin = pb.encode("HeroActionData", wakeRequst)
                    		game:sendData(actionCodes.HeroWakeLevelUpRequest, bin)
    						game:addEventListener(actionModules[actionCodes.HeroWakeLevelUpResponse], function(event)
    							local msg = pb.decode("HeroActionResponse", event.data)
						    	for _, hero in ipairs(msg.heros) do
						    		if game.role.heros[hero.id] then
						    			game.role.heros[hero.id].wakeLevel = hero.wakeLevel
						    		end
						    	end
						    	
						    	if curFragment == costFragment then 
						    		game.role.fragments[fragmentId] = nil
						    	else
						    		game.role.fragments[fragmentId] = curFragment - costFragment
						    	end

						    	-- 不可点击的mask
								self:showMask()
						    	--播放成功特效
						    	self:showWakeSuccessEffect()
						    	
						    	return "__REMOVE__"
						    end)
                		end,
            		} 
        		})
        		addAssistDialog:getLayer():anch(0.5, 0.5):pos(display.cx, display.cy):addTo(display.getRunningScene())
			end,
		}):getLayer():anch(0.5, 0):pos(bottomBgSize.width / 2, 5):addTo(bottomBg)
	else
		ui.newTTFLabelWithStroke({ text = "该武将已觉醒满级，你真牛逼！", size = 22, color = display.COLOR_GREEN, shadowColor = display.COLOR_SHADOW })
				:anch(0, 0.5):pos(58, 88):addTo(bottomBg)
	end
end

function HeroWakeLayer:openItemSourceLayer(fragmentId)
	local sourceLayer = ItemSourceLayer.new({ 
		priority = self.priority - 10, 
		itemId = fragmentId,
		closeCallback = function()
			self:initContentRight()
		end,
	})
	sourceLayer:getLayer():addTo(display.getRunningScene())
end

function HeroWakeLayer:showWakeSuccessEffect()
	local showNextEffect = function()
		-- 播放成功特效
    	local successSprite = display.newSprite( HeroRes .. "wake_success.png" )
    	successSprite:scale(2):pos(self:getContentSize().width/2, self:getContentSize().height/2):addTo(self, 100)
    	successSprite:runAction(transition.sequence({
    			CCScaleTo:create(0.1, 3),
    			CCScaleTo:create(0.4, 0.6),
    			CCScaleTo:create(0.05, 0.7),
    			CCScaleTo:create(0.05, 0.6),
    			CCDelayTime:create(1),
    			CCCallFunc:create(function() 
	    				successSprite:removeSelf() 
	    				self:showSuccessLayer()
    				end)
		}))

		self:showAttributeEffect()
	end

	local xPos = {0, 138, 233}
	for index = 1, 3 do
		local flash = uihelper.loadAnimation(HeroGrowthRes, "sg", 4, 4*2)
		flash.sprite:anch(0.5, 0.5):pos(xPos[index] + 481, 136)
		flash.sprite:addTo(self, 98)
		flash.sprite:runAction(transition.sequence({
			CCHide:create(),
			CCDelayTime:create((index-1)*0.3),
			CCShow:create(),
			CCAnimate:create(flash.animation),
			CCRemoveSelf:create(),
		}))
	end
	local particle = uihelper.loadAnimation(HeroGrowthRes, "lz", 19, 19/1.5)
	particle.sprite:scale(1):anch(0, 1):pos(490, 296):addTo(self, 100)
	particle.sprite:runAction(transition.sequence({
		CCHide:create(),
		CCDelayTime:create(0.2),
		CCShow:create(),
		CCAnimate:create(particle.animation),
		CCRemoveSelf:create(),
		}))
	local wakeEffect = uihelper.loadAnimation(HeroGrowthRes, "jxlz", 15, 15/2)
	wakeEffect.sprite:anch(0.5, 0.5):pos(565, 276 + 60)
	wakeEffect.sprite:scale(2.5):addTo(self, 99)
	wakeEffect.sprite:runAction(transition.sequence({
		CCHide:create(),
		CCDelayTime:create(0.7),
		CCShow:create(),
		CCSpawn:createWithTwoActions(CCAnimate:create(wakeEffect.animation), 
			CCSequence:createWithTwoActions(CCDelayTime:create(1.5), 
				CCCallFunc:create(function() 
					uihelper.shake()
					--爆炸的那个时刻刷新界面
					self:initContentLeft()
					self:initContentRight() 
				end))),
		CCRemoveSelf:create(),
		CCCallFunc:create(showNextEffect),
		}))

end


function HeroWakeLayer:showMask()
	self.touchMask = DGMask:new({blackMask = false, priority = -1000})
	self.touchMask:getLayer():addTo(display.getRunningScene(), 1000)
end

function HeroWakeLayer:removeMask()
	self.touchMask:getLayer():removeSelf()
end

function HeroWakeLayer:showSuccessLayer()
	local layer = WakeSuccessLayer.new({priority = -1100, heroId = self.mainHeroId, parent = self})
    layer:getLayer():addTo(display.getRunningScene())
end

function HeroWakeLayer:createAttrNode(isAfterWake)
	local attBg = display.newSprite(HeroGrowthRes .. "wake_att_bg.png")
	local attBgSize = attBg:getContentSize()

	local maxWakeLevel = self.wakeCsvData.wakeLevelMax
	local wakeLevel = (isAfterWake and self.mainHero.wakeLevel + 1 <= maxWakeLevel) and self.mainHero.wakeLevel + 1 or self.mainHero.wakeLevel
	local currentValues = self.mainHero:getBaseAttrValues(self.mainHero.level, self.mainHero.evolution, wakeLevel)
	local fontColor = isAfterWake and display.COLOR_GREEN or display.COLOR_WHITE

	display.newSprite(HeroRes .. "attr_hp.png"):anch(0, 1):pos(20, attBgSize.height - 10):addTo(attBg)
	ui.newTTFLabel({ text = math.floor(currentValues.hp), size = 20, color = fontColor }):anch(0, 1):pos(60, attBgSize.height - 10):addTo(attBg)

	display.newSprite(HeroRes .. "attr_atk.png"):anch(0, 1):pos(20, attBgSize.height - 45):addTo(attBg)
	ui.newTTFLabel({ text = math.floor(currentValues.atk), size = 20, color = fontColor }):anch(0, 1):pos(60, attBgSize.height - 45):addTo(attBg)

	display.newSprite(HeroRes .. "attr_def.png"):anch(0, 1):pos(20, attBgSize.height - 80):addTo(attBg)
	ui.newTTFLabel({ text = math.floor(currentValues.def), size = 20, color = fontColor }):anch(0, 1):pos(60, attBgSize.height - 80):addTo(attBg)
	
	return attBg
end

function HeroWakeLayer:showAttributeEffect()
	local mainHero = game.role.heros[self.mainHeroId]
	local currentValues = mainHero:getTotalAttrValues()
	local previousValues = mainHero:getTotalAttrValues(mainHero:getBaseAttrValues(mainHero.level, mainHero.evolutionCount, mainHero.wakeLevel - 1))
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

function HeroWakeLayer:checkGuide()
	
end

return HeroWakeLayer