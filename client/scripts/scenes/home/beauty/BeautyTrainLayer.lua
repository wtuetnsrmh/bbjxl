-- 美人宠幸显示层
-- by yangkun
-- 2014.7.2

local GlobalRes = "resource/ui_rc/global/"
local BeautyRes = "resource/ui_rc/beauty/"
local HeroRes = "resource/ui_rc/hero/"

local ParticleRes = "resource/ui_rc/particle/beauty/"

local Beauty = require("datamodel.Beauty")

local BeautyTrainLayer = class("BeautyTrainLayer", function(params) 
	return display.newLayer(GlobalRes .. "inner_bg.png") 
end)

function BeautyTrainLayer:ctor(params)

	params = params or {}

	self.priority = params.priority or -129
	self.beauty = params.beauty or {}
	self.beautyData = self.beauty and beautyListCsv:getBeautyById(self.beauty.beautyId) or nil
	self.parent = params.parent
	self.infoEnough = false
	self.closeCallback = params.closeCallback 
	self.useCount = 0

	self:initUI()

	self.lastLevel = self.beauty:getCurrentLevel()
	self.lastEvolutionCount = self.beauty.evolutionCount
	self.getResponse = true
end

function BeautyTrainLayer:initUI()

	self.size = self:getContentSize()

	self.innerBg = display.newSprite()
	self.innerBg:size(self.size)
	self.innerBg:anch(0.5,0.5):pos(self:getContentSize().width/2, self:getContentSize().height/2):addTo(self)

	-- 遮罩层
	self:anch(0, 0):pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1, bg = HomeRes .. "home.jpg" })

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
				if self.closeCallback then
					self.closeCallback()
				end
				self:getLayer():removeSelf()
			end,
		}):getLayer()
	closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self,100)

	self.tabCursor = display.newSprite(GlobalRes .. "tab_arrow.png")
	self.tabCursor:anch(0, 0.5):pos(self.size.width - 25, 470):addTo(self, 100)

	local tabRadio = DGRadioGroup:new()
	local beautyBtn = DGBtn:new(GlobalRes, {"tab_normal.png", "tab_selected.png"},
		{	
			--front = BeautyRes .. "text_train.png",
			priority = self.priority,
			callback = function()
			end
		}, tabRadio)
	beautyBtn:getLayer():anch(0, 0.5):pos(self.size.width - 14, 470):addTo(self)
	local tabSize = beautyBtn:getLayer():getContentSize()
	ui.newTTFLabelWithStroke({ text = "培养", dimensions = CCSizeMake(tabSize.width / 2, tabSize.height), size = 26, font = ChineseFont,
		color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(tabSize.width / 2, tabSize.height / 2):addTo(beautyBtn:getLayer())

	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority})
	:anch(0,1):pos(0,display.height):addTo(self)
end

function BeautyTrainLayer:getLayer()
	return self.mask:getLayer()
end

function BeautyTrainLayer:onEnter()
	self:initContentLayer()
	self:checkGuide()
end

function BeautyTrainLayer:checkGuide(remove)
	if game.guideId == 1216 and self.guideBtn then
		local worldPos = self.guideBtn:convertToWorldSpace(ccp(0, 0))
		local size = self.guideBtn:getContentSize()
		game:addGuideNode({rect = CCRectMake(worldPos.x, worldPos.y, size.width, size.height), remove = remove, 
			guideIds = {1216}
		})
	end
end

function BeautyTrainLayer:onExit()
	self:checkGuide(true)
end

-- 内容层
function BeautyTrainLayer:initContentLayer()
	if self.contentLayer then
		self.contentLayer:removeSelf()
		self.rightContentLayer = nil
	end

	self.contentLayer = display.newLayer()
	self.contentLayer:size(self:getContentSize()):addTo(self)

	display.newSprite( GlobalRes .. "front_bg.png")
	:anch(0.5,0):pos(self.size.width/2, self.size.height - 558):addTo(self.contentLayer)

	-- 美人前景
	local heroBg = display.newLayer():size(CCSizeMake(352,498))
	:anch(0,0):pos(34, self.size.height - 556):addTo(self.contentLayer)

	-- 美人图片
	--local beautyPic = display.newSprite( self.beautyData.heroRes )
	local beautyPic=uihelper.createMaskSprite(self.beautyData.heroRes,self.beautyData.heroMaskRes)
	local scale = 1.1/2
	beautyPic:scale(scale):anch(0.5,0.5):pos(heroBg:getContentSize().width/2, heroBg:getContentSize().height/2):addTo(heroBg)

	local time = 1.7
	local dtime = 0.3
	beautyPic:runAction(CCRepeatForever:create(transition.sequence({
			CCDelayTime:create(dtime),
			CCScaleTo:create(time, scale + 0.015),
			CCDelayTime:create(dtime),
			CCScaleTo:create(time, scale),
		})))
	local d1 = CCDelayTime:create(dtime)
	local moveBy = CCMoveBy:create(time, ccp(0, 3))
	local d2 = CCDelayTime:create(dtime)
	local rev=moveBy:reverse()
	local actionArr1 = CCArray:create()
	actionArr1:addObject(d1)
	actionArr1:addObject(moveBy)
	actionArr1:addObject(d2)
	actionArr1:addObject(rev)
	local seq  = CCSequence:create(actionArr1)
	local repeatForever =CCRepeatForever:create(seq);
	beautyPic:runAction(repeatForever)

	-- 名字
	local nameBg = display.newSprite(BeautyRes .. "name_bg.png")
	nameBg:anch(0.5,0.5):pos(heroBg:getContentSize().width/2, heroBg:getContentSize().height):addTo(heroBg,1)

	if self.beauty.evolutionCount - 1 > 0 then

		local nameLable=ui.newTTFLabel({ text = string.format("%s ",self.beautyData.beautyName)
			, size = 28,font=ChineseFont , color = display.COLOR_WHITE})
		:anch(0,0.5):pos(nameBg:getContentSize().width/2, nameBg:getContentSize().height/2):addTo(nameBg)
		local levelLabel=ui.newTTFLabel({ text = string.format("%d阶",self.beauty.evolutionCount)
			, size = 28,font=ChineseFont , color = uihelper.hex2rgb("#ffd200")})
		:anch(0,0.5):pos(nameBg:getContentSize().width/2, nameBg:getContentSize().height/2):addTo(nameBg)
		nameLable:setPositionX((nameBg:getContentSize().width-nameLable:getContentSize().width-levelLabel:getContentSize().width)/2)
		levelLabel:setPositionX(nameLable:getPositionX()+nameLable:getContentSize().width)

	else
		ui.newTTFLabel({ text = string.format("%s",self.beautyData.beautyName ), size = 28, color = display.COLOR_WHITE, strokeColor = display.COLOR_BROWNSTROKE, strokeSize = 2 })
		:pos(nameBg:getContentSize().width/2, nameBg:getContentSize().height/2):addTo(nameBg)
	end

	-- 星级
	local startY = heroBg:getContentSize().height - 98
	for index = 1, self.beautyData.star do
		local x = 36
		local y = startY - (index - 1) * 46
		display.newSprite(GlobalRes .. "star/icon_big.png"):pos(x,y):addTo(heroBg, 2)
	end

	-- 技能框
	local skillBg = display.newSprite( BeautyRes .. "skill_bg.png")
	skillBg:anch(0.5,0):pos(heroBg:getContentSize().width/2, 15):addTo(heroBg, 1)

	local startX = 20
	for index = 1, 3 do
		local skillId = tonum(self.beautyData["beautySkill" .. index])
		local passiveSkillData = skillPassiveCsv:getPassiveSkillById(skillId)

		local skillBtn = DGBtn:new(GlobalRes, {"item_2.png"}, {
				callback = function()
					if self.descBg then
						self.descBg:removeSelf()
						self.descBg = nil
					end

					self.descBg = display.newSprite(HeroRes .. "choose/assist_bg.png")
					self.descBg:anch(0.5,0):pos(heroBg:getContentSize().width/2, skillBg:getContentSize().height+5):addTo(heroBg,3)
					:runAction(transition.sequence({
							CCDelayTime:create(2),
							CCRemoveSelf:create(),
							CCCallFunc:create(function() self.descBg = nil end)
						}))

					-- 技能名
					ui.newTTFLabel({text = string.format("【%s】", passiveSkillData.name), size = 22, color = display.COLOR_GREEN })
					:anch(0,0):pos(15, 85):addTo(self.descBg)

					if self.beauty.evolutionCount < index then
						ui.newTTFLabel({text = string.format("(%d阶激活)", index), size = 22, color = display.COLOR_GREEN })
						:anch(0,0):pos(130, 85):addTo(self.descBg)
					end

					ui.newTTFLabel({text = passiveSkillData.desc, size = 18, 
						dimensions = CCSizeMake(self.descBg:getContentSize().width - 40, 40)})
						:anch(0,0):pos(20, 30):addTo(self.descBg)
				end,
				priority = self.priority -1
			}):getLayer()
		local x = startX + (index - 1) * 110
		skillBtn:scale(0.8):anch(0,0.5):pos(x, skillBg:getContentSize().height/2):addTo(skillBg)

		local skillImage = display.newSprite(passiveSkillData.icon):pos(skillBtn:getContentSize().width/2, skillBtn:getContentSize().height/2)
		:addTo(skillBtn, -1)

		if self.beauty.evolutionCount < index then
			skillImage:setColor(ccc3(64,64,64))
		end
	end

	self:initContentRight()
end

function BeautyTrainLayer:initContentRight()
	self.rightLayer = display.newLayer()

	self.rightLayer:size(self.size.width-392-30, self.size.height)
	self.rightLayer:pos(392, 0):addTo(self.contentLayer)

	self.rightSize = self.rightLayer:getContentSize()

	display.newSprite(BeautyRes .. "train_right.png")
	:anch(0.5,0):pos(self.rightSize.width/2, self.rightSize.height - 540):addTo(self.rightLayer)

	local xInterval = (self.rightLayer:getContentSize().width - 2 * 157) / 3

	local tabData = {
		[1] = { 
			name = "beautyTrain", 
			showName = {BeautyRes .. "text_chongxing_normal.png", BeautyRes .. "text_chongxing_selected.png"},
			callback = function() self:createTrainItemTable() self:createTrainTab() end
		},
		[2] = { 
			name = "beautyPotential", 
			showName = {BeautyRes .. "text_canwu_normal.png", BeautyRes .. "text_canwu_selected.png"}, 
			callback = function() self:createPotentialTab("normal") end
		},
	}

	-- tab按钮
	local tableRadioGrp = DGRadioGroup:new()
	for i = 1, #tabData do
		local tabBtn = DGBtn:new(BeautyRes, { "button_normal.png", "button_selected.png" },
			{	
				id = i,
				front = tabData[i].showName,
				priority = self.priority -2,
				callback = tabData[i].callback
			}, tableRadioGrp)
		tabBtn:getLayer():pos(85 + 170 * (i - 1), self.size.height - 121)
			:addTo(self.rightLayer, 2)
	end

	
	self:createTrainItemTable()
	self:createTrainTab()
	

end

function BeautyTrainLayer:createTrainItemTable()
	if self.rightItemContentLayer then
		self.rightItemContentLayer:removeSelf()
		self.rightItemContentLayer = nil
	end

	self.rightItemContentLayer = display.newLayer()
	self.rightItemContentLayer:size(self.rightLayer:getContentSize()):addTo(self.rightLayer)

	self.items = {}
	for itemId, item in pairs(game.role.items) do
		local itemData = itemCsv:getItemById(itemId)
		if itemData.type == 15 then
			table.insert(self.items, item)
		end
	end

	local rightSize = self.rightLayer:getContentSize()
	self.itemTableLayer = display.newLayer()
	self.itemTableLayer:size(rightSize.width - 90, 140):pos(60, 50):addTo(self.rightItemContentLayer)

	self.itemTableView = self:createItemTable()
	self.itemTableView:setPosition(0,0)
	self.itemTableLayer:addChild(self.itemTableView)
end

function BeautyTrainLayer:createTrainTab()
	if self.rightContentLayer then
		self.rightContentLayer:removeSelf()
		self.rightContentLayer = nil
	end

	self.rightContentLayer = display.newLayer()
	self.rightContentLayer:size(self.rightLayer:getContentSize()):addTo(self.rightLayer)

	local rightSize = self.rightContentLayer:getContentSize()
	self.beautyTrainData = beautyTrainCsv:getBeautyTrainInfoByEvolutionAndLevel(self.beauty.evolutionCount, self.beauty.level)

	local attrBg = display.newSprite(BeautyRes .. "train_line.png"):anch(0.5,0.5):pos(rightSize.width/2, rightSize.height - 149):addTo(self.rightContentLayer)
	display.newSprite(BeautyRes .. "text_normalattr.png"):anch(0.5,0.5):pos(rightSize.width/2, rightSize.height - 149):addTo(self.rightContentLayer)

	local attr1_bg = display.newSprite(HeroRes .. "growth/evol_attr_bg.png"):anch(0,0):pos(50, rightSize.height - 312):addTo(self.rightContentLayer)
	ui.newTTFLabel({text = "当前", size = 24,font=ChineseFont }):anch(0.5,1):pos(58, 130):addTo(attr1_bg)

	ui.newTTFLabel({text = "下一级", size = 24,font=ChineseFont }):anch(0.5,1):pos(304, 130):addTo(attr1_bg)

	-- 属性
	local levelPerEvolution = self.beautyData.evolutionLevel
	local curLevel = (self.beauty.evolutionCount - 1) * levelPerEvolution + self.beauty.level
	local curHp = self.beautyData.hpGrow * (curLevel - 1) + self.beautyData.hpInit
	local curAtk = self.beautyData.atkGrow * (curLevel - 1) + self.beautyData.atkInit
	local curDef = self.beautyData.defGrow * (curLevel - 1) + self.beautyData.defInit

	-- 当前
	ui.newTTFLabel({text = string.format("美色 : %d", curHp), size = 20, color = uihelper.hex2rgb("#ffe194")})
	:anch(0,0): pos(84, rightSize.height - 239):addTo(self.rightContentLayer)

	ui.newTTFLabel({text = string.format("才艺 : %d", curAtk), size = 20, color = uihelper.hex2rgb("#ffe194")})
	:anch(0,0): pos(84, rightSize.height - 271):addTo(self.rightContentLayer)

	ui.newTTFLabel({text = string.format("品德 : %d", curDef), size = 20, color = uihelper.hex2rgb("#ffe194")})
	:anch(0,0): pos(84, rightSize.height - 300):addTo(self.rightContentLayer)

	local f =  display.newSprite( HeroRes .. "growth/arrow.png")
	:pos(238, rightSize.height - 240):addTo(self.rightContentLayer)
	f:runAction(CCRepeatForever:create(transition.sequence({
										CCMoveBy:create(1, ccp(10, 0)),
										CCMoveBy:create(1, ccp(-10, 0))
									})))

	-- 下一级
	ui.newTTFLabel({text = string.format("美色 : %d", self:isBeautyLevelExpFull() and curHp or curHp + self.beautyData.hpGrow), size = 20, color = uihelper.hex2rgb("#7ce810")})
	:anch(0,0): pos(316, rightSize.height - 239):addTo(self.rightContentLayer)

	ui.newTTFLabel({text = string.format("才艺 : %d", self:isBeautyLevelExpFull() and curAtk or curAtk + self.beautyData.atkGrow), size = 20, color = uihelper.hex2rgb("#7ce810")})
	:anch(0,0): pos(316, rightSize.height - 271):addTo(self.rightContentLayer)

	ui.newTTFLabel({text = string.format("品德 : %d", self:isBeautyLevelExpFull() and curDef or curDef + self.beautyData.defGrow), size = 20, color = uihelper.hex2rgb("#7ce810")})
	:anch(0,0): pos(316, rightSize.height - 300):addTo(self.rightContentLayer)

	-- 等级
	local evolutionString = { "一阶" ,"二阶" ,"三阶" }
	ui.newTTFLabelWithStroke({text = evolutionString[self.beauty.evolutionCount],font=ChineseFont , size = 22, color = display.COLOR_WHITE})
	:pos(75, rightSize.height - 331-5):addTo(self.rightContentLayer)

	local startX = 105
	for index = 1 , levelPerEvolution do
		local slotBg = display.newSprite(BeautyRes .. "lv_slot.png")
		slotBg:anch(0,0.5):pos(startX + (index - 1) * 30, rightSize.height - 331-5):addTo(self.rightContentLayer)

		if index <= self.beauty.level then
			display.newSprite(BeautyRes .. "lv_bar.png")
			:pos(slotBg:getContentSize().width/2, slotBg:getContentSize().height/2):addTo(slotBg)
		end
	end

	-- 升级特效
	local currentLevel = self.beauty:getCurrentLevel()
	local startX = 117
	if currentLevel > self.lastLevel then
		local particle = CCParticleSystemQuad:create( ParticleRes .. "meirenjinjie.plist")
		particle:setPosition(startX + (self.beauty.level - 1) * 30, rightSize.height - 333)
		self.rightContentLayer:addChild(particle,1)
	end
	self.lastLevel = currentLevel

    -- 好感度
	ui.newTTFLabelWithStroke({ text = "好感",font=ChineseFont , size = 22, color = display.COLOR_WHITE})
		:pos(75, rightSize.height - 365-5):addTo(self.rightContentLayer)

	local expSlot = display.newSprite(GlobalRes .. "exp_slot.png")
	expSlot:anch(0,0.5):pos(100, rightSize.height-365-5):addTo(self.rightContentLayer)
	local expProgress = display.newProgressTimer(GlobalRes .. "exp_bar.png", display.PROGRESS_TIMER_BAR)
	expProgress:setMidpoint(ccp(0, 0.5))
	expProgress:setBarChangeRate(ccp(1,0))
	expProgress:setPercentage( self.beauty.exp / self.beautyTrainData.upgradeExp * 100)
	expProgress:pos(expSlot:getContentSize().width/2, expSlot:getContentSize().height/2):addTo(expSlot)
	local expLabel = ui.newTTFLabel({text = string.format("%d/%d", self.beauty.exp, self.beautyTrainData.upgradeExp), size = 18})
	expLabel:pos(expSlot:getContentSize().width/2, expSlot:getContentSize().height/2):addTo(expSlot)
	expSlot:setVisible(not self:isBeautyLevelExpFull())

	-- 突破特效
	local currentEvolutionCount = self.beauty.evolutionCount
	if currentEvolutionCount > self.lastEvolutionCount then
		local particle = CCParticleSystemQuad:create( ParticleRes .. "meiren_huaban.plist")
		particle:setPosition(display.cx, display.cy + 200)
		particle:setDuration(4)
		self:addChild(particle,1)
	end
	self.lastEvolutionCount = currentEvolutionCount

	-- 经验满,需要突破
	if self.beauty.exp == self.beautyTrainData.upgradeExp and self.beauty.level == self.beautyData.evolutionLevel and self.beauty.evolutionCount < 3 then
		
		ui.newTTFLabel({text = "美人当前已满级，请突破!", size = 18, color = display.COLOR_DARKYELLOW})
		:anch(0, 0):pos(25, rightSize.height - 420):addTo(self.rightContentLayer)

		ui.newTTFLabel({text = "突破开启新的等级上限，同时触发美人计", size = 18, color = display.COLOR_DARKYELLOW})
		:anch(0, 0):pos(25, rightSize.height - 440):addTo(self.rightContentLayer)

		-- 突破道具
		self.beautyEvolutionData = beautyEvolutionCsv:getBeautyEvolutionInfoByLevel(self.beauty.evolutionCount)
		local itemId = tonum(table.keys(self.beautyEvolutionData.needItem)[1])
		local itemNeedNum = tonum(table.values(self.beautyEvolutionData.needItem)[1])
		local itemData = itemCsv:getItemById(itemId)
		local storeData=storeCsv:getStoreItemById(33)
		local itemNum = game.role.items[itemId] and game.role.items[itemId].count or 0

		local evolutionBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png", "middle_disabled.png"},
			{
				priority = self.priority - 2,
				text = { text = "突破" , font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
				callback = function()
					if itemNum < itemNeedNum then
						--local sysMsg = sysMsgCsv:getMsgbyId(560)
						--local text = string.format(sysMsg.text, (itemNeedNum - itemNum) * storeData.yuanbao )
						DGMsgBox.new({type = 1, text = "糟糕，道具不足！"})
					else
						self:evolutionRequest(false)
					end
				end
			})
		evolutionBtn:getLayer():anch(0.5,0):pos(rightSize.width/2, rightSize.height - 515)
		self.rightContentLayer:addChild(evolutionBtn:getLayer())

		evolutionBtn:setEnable(self.beautyEvolutionData.needYuanBao <= game.role.yuanbao)

		local itemFrame = ItemIcon.new({ itemId = itemId , callback = function() 
				self:showItemTaps(itemId, itemNum)
			end,
			priority = self.priority - 2}):getLayer()
		itemFrame:anch(0,0):pos(360,60):addTo(self.rightContentLayer)
		
		local itemLabel = ui.newTTFLabel({text = string.format("%d/%d", itemNum, itemNeedNum), size = 16, color = display.COLOR_GREEN })
		:anch(1, 0):pos(itemFrame:getContentSize().width - 5, 5):addTo(itemFrame)

		itemLabel:setColor(itemNum < itemNeedNum and display.COLOR_RED or display.COLOR_GREEN)

		local nameLabel = ui.newTTFLabel({text = itemData.name, size = 20, color = display.COLOR_DARKYELLOW})
		nameLabel:anch(0.5, 0.5):pos(itemFrame:getContentSize().width/2, -10):addTo(itemFrame)

		--移除下面的道具
		if self.rightItemContentLayer then
			self.rightItemContentLayer:removeSelf()
			self.rightItemContentLayer = nil
			self.touch = false
		end
	elseif self:isBeautyLevelExpFull() then
		ui.newTTFLabelWithStroke({ text = "该美人已培养至最高等级", size = 30 })
			:anch(0.5, 0):pos(rightSize.width / 2, rightSize.height - 450):addTo(self.rightContentLayer)

		--移除下面的道具
		if self.rightItemContentLayer then
			self.rightItemContentLayer:removeSelf()
			self.rightItemContentLayer = nil
			self.touch = false
		end
	end

end

function BeautyTrainLayer:showItemTaps(itemID,itemHave)

	self:purgeItemTaps()
	local itemTipsView = require("scenes.home.ItemTipsLayer")
	local itemTips = itemTipsView.new({
		itemId = itemID,
		showNum = itemHave,
		})
	display.getRunningScene():addChild(itemTips:getLayer())
	itemTips:setTag(1111)

end

function BeautyTrainLayer:purgeItemTaps()
	if display.getRunningScene():getChildByTag(1111) then
		display.getRunningScene():getChildByTag(self.tipsTag):removeFromParent()
	end
end

function BeautyTrainLayer:evolutionRequest(useYuanbao)
	local use = useYuanbao and 1 or 0
	local evolutionRequest = { roleId = game.role.id, param1 = self.beauty.beautyId , param2 = use }
	local bin = pb.encode("SimpleEvent", evolutionRequest)

	game:sendData(actionCodes.BeautyEvolutionRequest, bin, #bin)
	game:addEventListener(actionModules[actionCodes.BeautyEvolutionResponse], function(event)
		local beautyData = pb.decode("BeautyDetail", event.data)

		self.beauty:reloadWithPBData(beautyData)
		self:initContentLayer()

		game.role:dispatchEvent({name="updataBeautyLevel"})
		
		return "__REMOVE__"
	end)
end

function BeautyTrainLayer:isBeautyLevelExpFull()
	return self.beauty.exp == self.beautyTrainData.upgradeExp and self.beauty.level == self.beautyData.evolutionLevel and self.beauty.evolutionCount >= 3
end

function BeautyTrainLayer:createItemTable()
	local cellSize = CCSizeMake(114, 140)

	local handler = LuaEventHandler:create(function(fn, table, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(cellSize.width, cellSize.height)
        elseif fn == "cellAtIndex" then
			if not a2 then
                a2 = CCTableViewCell:new()
                local cell = display.newNode()
                a2:addChild(cell, 0, 1)
            end

            -- 更新cell
			local cell = tolua.cast(a2:getChildByTag(1), "CCNode")
			self:createItemTableCell(cell, a1)
			r = a2
        elseif fn == "numberOfCells" then
            r = #self.items
        end

        return r
    end)

	local itemTableView = LuaTableView:createWithHandler(handler, self.itemTableLayer:getContentSize())
    itemTableView:setBounceable(true)
    itemTableView:setDirection(kCCScrollViewDirectionHorizontal)
    itemTableView:reloadData()
    itemTableView:setTouchPriority(self.priority - 5)
    itemTableView:setContentOffset(ccp(self.itemTableContentOffsetX and self.itemTableContentOffsetX or 0, 0), false)
	return itemTableView

end

function BeautyTrainLayer:createItemTableCell(parentNode, index)

	local cellNode = display.newLayer():addTo(parentNode)
	cellNode:removeAllChildren()

	cellNode:size(CCSize(95,95))
	local item = self.items[index+1]

	if item then
		local itemData = itemCsv:getItemById(item.id)

		local function refresh()
			if self.getResponse then
				local normalTrainRequest = { roleId = game.role.id, param1 = self.beauty.beautyId , param2 = item.id}
				local bin = pb.encode("SimpleEvent", normalTrainRequest)
				self.getResponse = false
				game:sendData(actionCodes.BeautyNormalTrainRequest, bin, #bin)
				game:addEventListener(actionModules[actionCodes.BeautyNormalTrainResponse], function(event)
					self.getResponse = true
					local beautyData = pb.decode("BeautyTrain", event.data)
					self.itemTableContentOffsetX = self.itemTableView:getContentOffset().x

					self.beauty:reloadWithPBData(beautyData.detail)

					if item.count == 0 then
						self.touch = false
			
						cellNode:stopAllActions()
						self.useCount = 0

						self:createTrainItemTable()
						
					end

					self.items = {}
					for itemId, item in pairs(game.role.items) do
						local itemData = itemCsv:getItemById(itemId)
						if itemData.type == 15 then
							table.insert(self.items, item)
						end
					end

					if item.count > 0 then
						self:createItemTableCell(parentNode, index)
					end

					self:createTrainTab()
					self:showEffect(beautyData.expAdd, beautyData.multiple)

					game.role:dispatchEvent({name="updataBeautyLevel"})

					return "__REMOVE__"


				end)
			end
		end

		local function endFunc(toRefresh)
			self.touch = false
			
			cellNode:stopAllActions()
			self.useCount = 0

			if toRefresh then
				refresh()
			end
		end

		local normalBtn = ItemIcon.new({
			itemId = item.id,
			
			priority = self.priority - 1
		}):getLayer()
		normalBtn:anch(0.5,0.5):pos(normalBtn:getContentSize().width/2, 30+normalBtn:getContentSize().height/2):addTo(cellNode)
		if index == 0 then
			self.guideBtn = normalBtn
		end

		local numLabel = ui.newTTFLabel({text = string.format(item.count), size = 18, color = display.COLOR_WHITE})
		numLabel:anch(0.5,0):pos(normalBtn:getContentSize().width / 2, 0):addTo(normalBtn)

		local itemData = itemCsv:getItemById(item.id)
		local tempBg=display.newSprite(BeautyRes.."bg_costBeauty.png"):pos(normalBtn:getContentSize().width / 2, 10):addTo(cellNode)
		local favorLabel = ui.newTTFLabel({text = string.format("好感+%d",itemData.favor), size = 18, color = display.COLOR_WHITE})
		favorLabel:anch(0.5, 0.5):pos(tempBg:getContentSize().width/2, tempBg:getContentSize().height/2):addTo(cellNode)

		
		local CANCELDIS = 50
		cellNode:addTouchEventListener(
		function(event, x, y)
			if event == "began" then
				if not self.touch and uihelper.nodeContainTouchPoint(cellNode, ccp(x, y)) then
					local useItem
					useItem = function(timeInterval)
						cellNode:performWithDelay(function()
							if self.touch and item.count>0 then
								self.useCount = self.useCount + 1
								refresh()
								useItem(0.4)
							end
						end, timeInterval)
					end
					useItem(0.5)
					self.touch = true
					self.lastX = x
					self.lastY = y
				else
					return false
				end
			elseif event == "moved" then
				if math.abs(self.lastX - x) > CANCELDIS or math.abs(self.lastY - y) > CANCELDIS or
					not uihelper.nodeContainTouchPoint(cellNode, ccp(x, y)) then
					self.touch = false
					return false
				end
			elseif event == "ended" then
				if self.touch then
					local refresh = false
					if self.useCount == 0 and event == "ended" then 
						self.useCount = 1
						refresh = true 
					end
					endFunc(refresh)
					lastX = 0
				end
			end

			return true
		end, false, self.priority - 1, true)

		cellNode:setTouchEnabled(true)
	else
		cellNode:removeSelf()
	end
	
end

function BeautyTrainLayer:showEffect(exp, multiple)
	if multiple > 1 then
		self.critNode = display.newNode()
		local critTextSprite = display.newSprite(BeautyRes .. "crit.png")
		local critNumberSprite
		if multiple == 2 then
			critNumberSprite = display.newSprite(BeautyRes .. "x2.png")
		elseif multiple == 5 then
			critNumberSprite = display.newSprite(BeautyRes .. "x5.png")
		elseif multiple == 10 then
			critNumberSprite = display.newSprite(BeautyRes .. "x10.png")
		end
		
		local width, height = critTextSprite:getContentSize().width + critNumberSprite:getContentSize().width, critTextSprite:getContentSize().height
		self.critNode:size(width, height)
		critTextSprite:anch(0, 0.5):pos(0, height / 2):addTo(self.critNode)
		critNumberSprite:anch(1, 0.5):pos(width, height / 2):addTo(self.critNode)
		self.critNode:anch(0.5,0.5):pos(self:getContentSize().width/2, self:getContentSize().height/2 + 80):addTo(self, 1)
		self.critNode:setVisible(false)

		self.critNode:runAction(transition.sequence({
			CCDelayTime:create(0.5),
			CCCallFunc:create(function() self.critNode:setVisible(true) end),
			CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 20)), CCScaleTo:create(0.1, 1.5)),
			CCDelayTime:create(0.2),
			CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 5)), CCScaleTo:create(0.1, 1)),
			CCSpawn:createWithTwoActions(CCMoveBy:create(0.5, ccp(0, 20)), CCFadeOut:create(0.5)),
			CCRemoveSelf:create()
		}))
	end

	self.expNode = display.newNode()
	local favorTextSprite = display.newSprite(BeautyRes .. "favor.png")
	local favorTips = ui.newBMFontLabel({ text = "+" .. exp, font = FontRes .. "attrNum.fnt"})
	
	local width, height = favorTextSprite:getContentSize().width + favorTips:getContentSize().width, favorTips:getContentSize().height
	self.expNode:size(width, height)
	favorTextSprite:anch(0, 0.5):pos(0, height / 2):addTo(self.expNode)
	favorTips:anch(1, 0.5):pos(width, height / 2):addTo(self.expNode)
	self.expNode:anch(0.5,0.5):pos(self:getContentSize().width/2, self:getContentSize().height/2 + 80):addTo(self, 1)
	self.expNode:setVisible(false)

	self.expNode:runAction(transition.sequence({
		CCDelayTime:create(multiple > 1 and 1.0 or 0.5),
		CCCallFunc:create(function() self.expNode:setVisible(true) end),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 30)), CCScaleTo:create(0.1, 1.5)),
		CCDelayTime:create(0.2),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 10)), CCScaleTo:create(0.1, 1)),
		CCSpawn:createWithTwoActions(CCMoveBy:create(0.5, ccp(0, 20)), CCFadeOut:create(0.5)),
		CCRemoveSelf:create()
	}))
end

function BeautyTrainLayer:createPotentialTab(status)
	--移除下面的道具
	if self.rightItemContentLayer then
		self.rightItemContentLayer:removeSelf()
		self.rightItemContentLayer = nil
		self.touch = false
	end

	if self.rightContentLayer then
		self.rightContentLayer:removeSelf()
	end

	self.rightContentLayer = display.newLayer()
	self.rightContentLayer:size(self.rightLayer:getContentSize()):addTo(self.rightLayer)

	local rightSize = self.rightContentLayer:getContentSize()

	local titleLine = display.newSprite(BeautyRes .. "train_line.png"):anch(0.5,0.5):pos(rightSize.width/2, rightSize.height - 149):addTo(self.rightContentLayer)
	display.newSprite(BeautyRes .. "text_pingjia.png"):anch(0.5,0.5):pos(titleLine:getContentSize().width/2, titleLine:getContentSize().height/2):addTo(titleLine)

	-- 潜力评价
	local temp={
		["十里挑一"]="title_1.png",
		["百里挑一"]="title_2.png",
		["千里挑一"]="title_3.png",
		["万里挑一"]="title_4.png",
		["天下无双"]="title_5.png"
	}

	local potentialBg = display.newSprite(BeautyRes .. "potential_bg.png")
	:anch(0.5,0.5):pos(rightSize.width/2, rightSize.height - 194):addTo(self.rightContentLayer)
	display.newSprite(BeautyRes .. temp[self.beautyData.potentialDesc])
		:anch(0.5,.5):pos(potentialBg:getContentSize().width/2, potentialBg:getContentSize().height/2):addTo(potentialBg)

	titleLine = display.newSprite(BeautyRes .. "train_line.png"):anch(0.5,0.5):pos(rightSize.width/2, rightSize.height - 252):addTo(self.rightContentLayer)
	display.newSprite(BeautyRes .. "text_attr.png"):anch(0.5,0.5):pos(titleLine:getContentSize().width/2, titleLine:getContentSize().height/2):addTo(titleLine)

	-- 潜力属性
	if status == "normal" then
		self.attrDetailLayer = self:createAttrDetailLayer("normal")
		self.attrDetailLayer:anch(0,0):pos(11, rightSize.height-378):addTo(self.rightContentLayer)

		--test
		local normalBtn,highBtn
		function isAttributeFull()
			if self.infoEnough then
				normalBtn:setEnable(false)
				highBtn:setEnable(false)
			end
		end 
		-- 参悟按钮
		normalBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png", "middle_disabled.png"},
			{
				priority = self.priority - 2,
				text = { text = "普通参悟",size=26, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2 },
				callback = function()
					local normalPotentialRequest = {roleId = game.role.id, param1 = self.beauty.beautyId}
					local bin = pb.encode("SimpleEvent", normalPotentialRequest)

					game:sendData(actionCodes.BeautyNormalPotentialRequest, bin, #bin)
					loadingShow()
					game:addEventListener(actionModules[actionCodes.BeautyNormalPotentialResponse], function(event)
						loadingHide()
						local pbData = pb.decode("SimpleEvent",event.data)
						isAttributeFull()
						self.randomHp = pbData["param1"]
						self.randomAtk = pbData["param2"]
						self.randomDef = pbData["param3"]
						self:createPotentialTab("random")

						return "__REMOVE__"
					end)
				end
			})
		normalBtn:getLayer():anch(0,0):pos(80, rightSize.height - 485)
		self.rightContentLayer:addChild(normalBtn:getLayer())

		highBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png", "middle_disabled.png"},
			{
				priority = self.priority - 2,
				text = { text = "高级参悟", size=26,font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2 },
				callback = function()
					local highPotentialRequest = {roleId = game.role.id, param1 = self.beauty.beautyId}
					local bin = pb.encode("SimpleEvent", highPotentialRequest)

					game:sendData(actionCodes.BeautyHighPotentialRequest, bin, #bin)
					loadingShow()
					game:addEventListener(actionModules[actionCodes.BeautyHighPotentialResponse], function(event)
						loadingHide()
						local pbData = pb.decode("SimpleEvent",event.data)
						isAttributeFull()
						self.randomHp = pbData["param1"]
						self.randomAtk = pbData["param2"]
						self.randomDef = pbData["param3"]
						self:createPotentialTab("random")

						return "__REMOVE__"
					end)
				end
			})
		highBtn:getLayer():anch(0,0):pos(281, rightSize.height - 485)
		self.rightContentLayer:addChild(highBtn:getLayer())


		isAttributeFull()

		-- 参悟花费
		local levelPerEvolution = self.beautyData.evolutionLevel
		local curLevel = (self.beauty.evolutionCount - 1) * levelPerEvolution + self.beauty.level

		self.beautyPotentialData = beautyPotentialCsv:getBeautyPotentialByLevel(curLevel)

		local costBg = display.newSprite(BeautyRes .. "bg_costBeauty.png"):anch(0,0):pos(99, rightSize.height - 517):addTo(self.rightContentLayer)
		-- 金币
		display.newSprite(GlobalRes .. "yinbi.png")
			:anch(0.5,0.5):pos(20, costBg:getContentSize().height/2):addTo(costBg)
		ui.newTTFLabel({ text = self.beautyPotentialData.moneyCost, size = 20 })
			:anch(0, 0.5):pos(40, costBg:getContentSize().height/2):addTo(costBg)

		costBg = display.newSprite(BeautyRes .. "bg_costBeauty.png"):anch(0,0):pos(301, rightSize.height - 517):addTo(self.rightContentLayer)
		-- 元宝
		display.newSprite(GlobalRes .. "yuanbao.png")
			:anch(0.5,0.5):scale(0.8,0.8):pos(20, costBg:getContentSize().height/2):addTo(costBg)
		ui.newTTFLabel({ text = self.beautyPotentialData.yuanbaoCost, size = 20 })
			:anch(0, 0.5):pos(45, costBg:getContentSize().height/2):addTo(costBg)
		
	elseif status == "random" then
		self.attrDetailLayer = self:createAttrDetailLayer("random")
		self.attrDetailLayer:pos(11, rightSize.height-378):addTo(self.rightContentLayer)

		-- 参悟按钮
		local normalBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png", "middle_disabled.png"},
			{
				priority = self.priority - 2,
				text = { text = "还原", font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2 },
				callback = function()
					self:createPotentialTab("normal")
				end
			})
		normalBtn:getLayer():anch(0,0):pos(80, rightSize.height - 485)
		self.rightContentLayer:addChild(normalBtn:getLayer())

		local highBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png", "middle_disabled.png"},
			{
				priority = self.priority - 2,
				text = { text = "保存", font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2 },
				callback = function()
					local potentialSaveRequest = {roleId = game.role.id, param1 = self.beauty.beautyId}
					local bin = pb.encode("SimpleEvent", potentialSaveRequest)

					game:sendData(actionCodes.BeautyPotentialSaveRequest, bin, #bin)
					loadingShow()
					game:addEventListener(actionModules[actionCodes.BeautyPotentialSaveResponse], function(event)
						loadingHide()
						local beautyData = pb.decode("BeautyDetail", event.data)

						self.beauty:reloadWithPBData(beautyData)
						self:createPotentialTab("normal")

						return "__REMOVE__"
					end)
				end
			})
		highBtn:getLayer():anch(0,0):pos(281, rightSize.height - 485)
		self.rightContentLayer:addChild(highBtn:getLayer())
	end

	ui.newTTFLabelWithStroke({text = "高级参悟有更高几率成长率提升!", size = 18, color = display.COLOR_WHITE})
	:anch(0.5, 0):pos(rightSize.width / 2, rightSize.height - 415):addTo(self.rightContentLayer)
end

function BeautyTrainLayer:createAttrDetailLayer(status)
	local tempLayer = display.newLayer()

	local attrSize = CCSizeMake(452, 132)
	tempLayer:size(attrSize)

	local levelPerEvolution = self.beautyData.evolutionLevel
	local curLevel = (self.beauty.evolutionCount - 1) * levelPerEvolution + self.beauty.level
	local totalHp = (self.beautyData.hpGrow * (curLevel - 1) + self.beautyData.hpInit) * self.beautyData.potential / 100
	local totalAtk = (self.beautyData.atkGrow * (curLevel - 1) + self.beautyData.atkInit) * self.beautyData.potential / 100
	local totalDef = (self.beautyData.defGrow * (curLevel - 1) + self.beautyData.defInit) * self.beautyData.potential / 100

	totalHp = math.floor(totalHp)
	totalAtk = math.floor(totalAtk)
	totalDef = math.floor(totalDef)

	-- 生命
	ui.newTTFLabelWithStroke({ text = "美色",font=ChineseFont , size = 22, color = display.COLOR_WHITE }):anch(0.5,0)
	:pos(69, tempLayer:getContentSize().height-60):addTo(tempLayer)

	local hpSlot = display.newSprite(GlobalRes .. "exp_slot.png")
	hpSlot:anch(0,0):pos(106, tempLayer:getContentSize().height-61):addTo(tempLayer)
	local hpProgress = display.newProgressTimer(GlobalRes .. "exp_bar.png", display.PROGRESS_TIMER_BAR)
	hpProgress:setMidpoint(ccp(0, 0.5))
	hpProgress:setBarChangeRate(ccp(1,0))
	hpProgress:setPercentage( self.beauty.potentialHp / totalHp * 100)
	hpProgress:pos(hpSlot:getContentSize().width/2, hpSlot:getContentSize().height/2):addTo(hpSlot)

	local hpLabel = ui.newTTFLabel({text = string.format("%d/%d", self.beauty.potentialHp, totalHp), size = 16, color = display.COLOR_WHITE})
	hpLabel:pos(hpSlot:getContentSize().width/2, hpSlot:getContentSize().height/2):addTo(hpSlot)

	-- 攻击
	ui.newTTFLabelWithStroke({ text = "才艺",font=ChineseFont , size = 22, color = display.COLOR_WHITE }):anch(0.5,0)
	:pos(69, tempLayer:getContentSize().height-98):addTo(tempLayer)

	local atkSlot = display.newSprite(GlobalRes .. "exp_slot.png")
	atkSlot:anch(0,0):pos(106, tempLayer:getContentSize().height-98):addTo(tempLayer)
	local atkProgress = display.newProgressTimer(GlobalRes .. "exp_bar.png", display.PROGRESS_TIMER_BAR)
	atkProgress:setMidpoint(ccp(0, 0.5))
	atkProgress:setBarChangeRate(ccp(1,0))
	atkProgress:setPercentage( self.beauty.potentialAtk / totalAtk * 100)
	atkProgress:pos(atkSlot:getContentSize().width/2, atkSlot:getContentSize().height/2):addTo(atkSlot)

	local atkLabel = ui.newTTFLabel({text = string.format("%d/%d", self.beauty.potentialAtk, totalAtk), size = 16, color = display.COLOR_WHITE})
	atkLabel:pos(atkSlot:getContentSize().width/2, atkSlot:getContentSize().height/2):addTo(atkSlot)

	-- 防御
	ui.newTTFLabelWithStroke({ text = "品德",font=ChineseFont , size = 22, color = display.COLOR_WHITE }):anch(0.5,0)
	:pos(69, tempLayer:getContentSize().height-135):addTo(tempLayer)

	local defSlot = display.newSprite(GlobalRes .. "exp_slot.png")
	defSlot:anch(0,0):pos(106, tempLayer:getContentSize().height-135):addTo(tempLayer)
	local defProgress = display.newProgressTimer(GlobalRes .. "exp_bar.png", display.PROGRESS_TIMER_BAR)
	defProgress:setMidpoint(ccp(0, 0.5))
	defProgress:setBarChangeRate(ccp(1,0))
	defProgress:setPercentage( self.beauty.potentialDef / totalDef * 100)
	defProgress:pos(defSlot:getContentSize().width/2, hpSlot:getContentSize().height/2):addTo(defSlot)

	local defLabel = ui.newTTFLabel({text = string.format("%d/%d", self.beauty.potentialDef, totalDef), size = 16, color = display.COLOR_WHITE})
	defLabel:pos(defSlot:getContentSize().width/2, defSlot:getContentSize().height/2):addTo(defSlot)

	print("self.beauty.potentialHp ====== ",self.beauty.potentialHp)
	print("totalHp ====== ",totalHp)
	print("self.beauty.potentialAtk ====== ",self.beauty.potentialAtk)
	print("totalAtk ====== ",totalAtk)
	print("self.beauty.potentialDef ====== ",self.beauty.potentialDef)
	print("totalDef ====== ",totalDef)

	if self.beauty.potentialHp >= totalHp and self.beauty.potentialAtk >= totalAtk and self.beauty.potentialDef >= totalDef then
		self.infoEnough = true
	else
		self.infoEnough = false
	end

	if status == "random" then
		-- 生命
		if self.randomHp > 0 then
			ui.newTTFLabelWithStroke({text = string.format("+%d", self.randomHp), size = 20, color = uihelper.hex2rgb("#7dfe41")})
			:anch(0,0):pos(385, tempLayer:getContentSize().height-55):addTo(tempLayer)

			display.newSprite(BeautyRes .. "up.png")
			:pos(430, tempLayer:getContentSize().height-43):addTo(tempLayer)
		elseif self.randomHp == 0 then
			ui.newTTFLabelWithStroke({text = string.format("+%d", self.randomHp), size = 20, color = uihelper.hex2rgb("#f9de36")})
			:anch(0,0):pos(385, tempLayer:getContentSize().height-55):addTo(tempLayer)

			display.newSprite(BeautyRes .. "horizontal.png")
			:pos(430, tempLayer:getContentSize().height-43):addTo(tempLayer)
		elseif self.randomHp < 0 then
			ui.newTTFLabelWithStroke({text = string.format("%d", self.randomHp), size = 20, color = uihelper.hex2rgb("#ff1212")})
			:anch(0,0):pos(385, tempLayer:getContentSize().height-55):addTo(tempLayer)

			display.newSprite(BeautyRes .. "down.png")
			:pos(430, tempLayer:getContentSize().height-43):addTo(tempLayer)
		end

		-- 攻击
		if self.randomAtk > 0 then
			ui.newTTFLabelWithStroke({text = string.format("+%d", self.randomAtk), size = 20, color = uihelper.hex2rgb("#7dfe41")})
			:anch(0,0):pos(385, tempLayer:getContentSize().height-93):addTo(tempLayer)

			display.newSprite(BeautyRes .. "up.png")
			:pos(430, tempLayer:getContentSize().height-80):addTo(tempLayer)
		elseif self.randomAtk == 0 then
			ui.newTTFLabelWithStroke({text = string.format("+%d", self.randomAtk), size = 20, color = uihelper.hex2rgb("#f9de36")})
			:anch(0,0):pos(385, tempLayer:getContentSize().height-93):addTo(tempLayer)

			display.newSprite(BeautyRes .. "horizontal.png")
			:pos(430, tempLayer:getContentSize().height-80):addTo(tempLayer)
		elseif self.randomAtk < 0 then
			ui.newTTFLabelWithStroke({text = string.format("%d", self.randomAtk), size = 20, color = uihelper.hex2rgb("#ff1212")})
			:anch(0,0):pos(385, tempLayer:getContentSize().height-93):addTo(tempLayer)

			display.newSprite(BeautyRes .. "down.png")
			:pos(430, tempLayer:getContentSize().height-80):addTo(tempLayer)
		end

		-- 防御
		if self.randomDef > 0 then
			ui.newTTFLabelWithStroke({text = string.format("+%d", self.randomDef), size = 20, color = uihelper.hex2rgb("#7dfe41")})
			:anch(0,0):pos(385, tempLayer:getContentSize().height-132):addTo(tempLayer)

			display.newSprite(BeautyRes .. "up.png")
			:pos(430, tempLayer:getContentSize().height-119):addTo(tempLayer)
		elseif self.randomDef == 0 then
			ui.newTTFLabelWithStroke({text = string.format("+%d", self.randomDef), size = 20, color = uihelper.hex2rgb("#f9de36")})
			:anch(0,0):pos(385, tempLayer:getContentSize().height-132):addTo(tempLayer)

			display.newSprite(BeautyRes .. "horizontal.png")
			:pos(430, tempLayer:getContentSize().height-119):addTo(tempLayer)
		elseif self.randomDef < 0 then
			ui.newTTFLabelWithStroke({text = string.format("%d", self.randomDef), size = 20, color = uihelper.hex2rgb("#ff1212")})
			:anch(0,0):pos(385, tempLayer:getContentSize().height-132):addTo(tempLayer)

			display.newSprite(BeautyRes .. "down.png")
			:pos(430, tempLayer:getContentSize().height-119):addTo(tempLayer)
		end
	end

	return tempLayer
end


function BeautyTrainLayer:onCleanup()
	display.removeUnusedSpriteFrames()
end

return BeautyTrainLayer