-- 武将详情界面
-- by yangkun
-- 2014.6.18

local HeroRes = "resource/ui_rc/hero/"
local HeroInfoRes = "resource/ui_rc/hero/info/"
local HeroGrowthRes = "resource/ui_rc/hero/growth/"
local HeroMapRes = "resource/ui_rc/hero/map/"
local GlobalRes = "resource/ui_rc/global/"

-- local HeroIntensifyLayer = require("scenes.home.HeroIntensifyLayer")
local HeroEvolutionLayer = import(".HeroEvolutionLayer")
local HeroCardLayer = import(".HeroCardLayer")
local HeroSkillLayer = import(".HeroSkillLayer")
local StarUpSuccessLayer = import(".StarUpSuccessLayer")

local Hero = require("datamodel.Hero")

local HeroInfoLayer = class("HeroInfoLayer", function(params) 
	return display.newLayer(GlobalRes .. "bottom_bg.png") 
end)

function HeroInfoLayer:ctor(params)
	params = params or {}

	self.keepRes = params.keepRes
	self.priority = params.priority or -129
	self.parent = params.parent
	self.lastIndex = params.lastIndex
	self.closeCallback = params.closeCallback
	self.hideMoreBt=params.hideMoreBt or false
	self.attrsJson=params.attrsJson
	self.level=params.level or 1
	self.passiveSkillAddAttrs=params.passiveSkillAddAttrs or {}

	self.removeImages = {}

	self.isNormalScale = true
	self.duringAction = false 
	-- heroType 和 heroId 只传一个
	-- 自己还没有的武将，传heroType
	-- 自己已经有的武将，传heroId
	self.selfHero = false
	if params.heroType and not params.heroId then
		self.heroType = params.heroType
	else
		self.heroId = params.heroId
		self.curHero = game.role.heros[self.heroId]
		self.heroType = self.curHero.type
		self.selfHero = true

		print(self.heroId)
	end
	self.unitData = unitCsv:getUnitByType(self.heroType)
	self.star = self.curHero and self.curHero.star or self.unitData.stars

	self.detailOpen = params.detailOpen or false

	self:initUI()

	self.afterIntensifyHandler = game.role:addEventListener("after_intensify", function(event)
		self:initContentRight()
		self:initContentLeft()
	end)
end

function HeroInfoLayer:getHeroIdByType(heroType)
	for key, hero in pairs( game.role.heros) do
		if hero.unitData.type == heroType then
			return key
		end
	end
	return nil
end

function HeroInfoLayer:getAttrValues()
	if self.heroId then
		return self.curHero:getTotalAttrValues()
	else
		return {hp = self.unitData.hp, atk = self.unitData.attack, def = self.unitData.defense}
	end
end

function HeroInfoLayer:initUI()
	local bgSize = self:getContentSize()

	-- 遮罩层
	self:anch(0, 0):pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self , priority = self.priority,bg = HomeRes .. "home.jpg"})

	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority - 10})
	:anch(0,1):pos(0,display.height):addTo(self)

	-- 右侧按钮
	local tabLabel = display.newSprite(GlobalRes .. "tab_selected.png")
	tabLabel:anch(0, 0.5):pos(self:getContentSize().width - 14, 480):addTo(self)
	local btnSize = tabLabel:getContentSize()

	display.newSprite(GlobalRes.."tab_arrow.png"):anch(1,0.5):pos(10, btnSize.height/2)
		:addTo(tabLabel)

	ui.newTTFLabelWithStroke({ text = "详情", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(tabLabel)

	self.closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority -1,
			callback = function()
				if self.parent and self.parent.__cname == "HeroListLayer" then
					-- self.parent:reloadData()
					-- self.parent:listHeros()
				end
				self:getLayer():removeSelf()
				if self.closeCallback then self.closeCallback() end
			end,
		}):getLayer()
	self.closeBtn:anch(0.7, 0.5):pos(bgSize.width, bgSize.height):addTo(self)

	if not self.selfHero then return end
	if self.unitData.type >= 900 and self.unitData.type <= 999 then return end

	self.evolutionBtn = DGBtn:new( GlobalRes, {"vertical_normal.png", "vertical_selected.png", "vertical_disabled.png"}, {
		priority = self.priority -2,
		touchScale = { 2, 1 },
		callback = function()
			local layer = HeroEvolutionLayer.new({mainHeroId = self.heroId, priority = self. priority - 10, parent = self,
				closeCallback = function ()
					self:setVisible(true)
				end})
			layer:getLayer():addTo(display.getRunningScene())
			self:setVisible(false)
		end
	})
	local btnSize = self.evolutionBtn:getLayer():getContentSize()
	self.evolutionBtn:getLayer():anch(0,0.5):pos(self:getContentSize().width - 13, 380):addTo(self)
	self.evolutionBtn:setEnable(self.heroId ~= nil)
	ui.newTTFLabelWithStroke({ text = "进化", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(self.evolutionBtn:getLayer())

	-- 技能升级按钮
	self.skillUpBtn = DGBtn:new( GlobalRes, {"vertical_normal.png", "vertical_selected.png", "vertical_disabled.png"}, {
		priority = self.priority -2,
		touchScale = { 2, 1 },
		callback = function()
			local skillLayer = HeroSkillLayer.new({ priority = self.priority - 10, hero = self.curHero,
				closeCallback = function ()
					self:setVisible(true)
					self:initContentLeft()
					self:initContentRight()
				end})
			skillLayer:getLayer():addTo(display.getRunningScene())
			self:setVisible(false)
		end
	})
	self.skillUpBtn:getLayer():anch(0,0.5):pos(self:getContentSize().width - 13, 280):addTo(self)
	self.skillUpBtn:setEnable(self.heroId ~= nil)
	ui.newTTFLabelWithStroke({ text = "技能", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(self.skillUpBtn:getLayer())
end

function HeroInfoLayer:onEnter()
	self:initContentRight()
	self:initContentLeft()
	self:checkGuide()
end

function HeroInfoLayer:checkGuide(remove)
	--升星按钮
	game:addGuideNode({node = self.starupBtn, remove = remove,
		guideIds = {503}
	})
end


function HeroInfoLayer:getLayer()
	return self.mask:getLayer()
end

function HeroInfoLayer:getParent()
	return self:getLayer():getParent()
end


function HeroInfoLayer:initContentLeft()	
	if self.leftContentLayer then
		self.leftContentLayer:removeSelf()
	end
	self.leftContentLayer = display.newLayer()
	self.leftContentLayer:size(417, self:getContentSize().height):pos(0,0):addTo(self,99)

	if self.curHero then
		if self.curHero:canEvolution() or self.curHero:canBattleSoul() then
			uihelper.newMsgTag(self.evolutionBtn:getLayer(), ccp(-10, -10))
		else
			self.evolutionBtn:getLayer():removeChildByTag(9999)
		end

		if self.curHero:canSkillUp() then
			uihelper.newMsgTag(self.skillUpBtn:getLayer(), ccp(-10, -10))
		else
			self.skillUpBtn:getLayer():removeChildByTag(9999)
		end
	end

	local leftSize = self.leftContentLayer:getContentSize()
	local scale1,scale2 = 0.55, 0.95
	local posX , posY = leftSize.width/2, leftSize.height/2
	local time = 0.3
	local corverTag = 3939
	local layer
	function rotateFunc()
		
		self:unableBtn()
		local wide = 960
		local offset = 0
		if display.width > wide then
			offset = (display.width - wide)/2
		end
		if self.isNormalScale then
			posX , posY = display.cx - offset, display.cy
		else
			posX , posY = leftSize.width/2, leftSize.height/2
		end
		self.closeBtn:setVisible(not self.isNormalScale)
		local array = CCArray:create()
		array:addObject(CCRotateTo:create(time, self.isNormalScale and -90 or 0))
		array:addObject(CCScaleTo:create(time, self.isNormalScale and scale2 or scale1))
		array:addObject(CCMoveTo:create(time,ccp(posX,posY)))
		layer:runAction(transition.sequence({
			CCCallFunc:create(function()
					if not self.isNormalScale then
						self:getChildByTag(corverTag):removeFromParent()
					end
				end),
			CCSpawn:create(array),
			CCCallFunc:create(function()
				if self.isNormalScale then
					display.newColorLayer(ccc4(0, 0, 0, 200)):pos(0 - offset,0):addTo(self,1,corverTag)
				end
				self.isNormalScale = not self.isNormalScale
				self.duringAction = false
			end)
			}))
	end 
	if self.heroId then
		layer = HeroCardLayer.new({passiveSkillAddAttrs=self.passiveSkillAddAttrs,heroId = self.heroId,priority = self.priority - 1, callback = function()
				if not self.duringAction then
					self.duringAction = true
					rotateFunc()
				end
			end})
		layer:scale(scale1):anch(0.5,0.5):pos(leftSize.width/2, leftSize.height/2):addTo(self.leftContentLayer)
	else
		layer = HeroCardLayer.new({heroType = self.heroType,attrsJson=self.attrsJson,level=self.level
				,priority = self.priority - 1,callback = function()
				if not self.duringAction then
					self.duringAction = true
					rotateFunc()
				end
			end})
		layer:scale(scale1):anch(0.5,0.5):pos(leftSize.width/2, leftSize.height/2):addTo(self.leftContentLayer)
	end
end

function HeroInfoLayer:initContentRight()
	if self.rightContentLayer then
		self.rightContentLayer:removeSelf()
	end
	self.rightContentLayer = display.newLayer()
	self.rightContentLayer:size(543, self:getContentSize().height):pos(400,0):addTo(self)

	local rightSize = self.rightContentLayer:getContentSize()

	local bg = display.newSprite( HeroInfoRes .. "detail_rightbg.png" )
	bg:anch(0,0):pos(0, rightSize.height - 552):addTo(self.rightContentLayer)           


	local nHeight = 0
	local detailLayer = display.newLayer()
	detailLayer:size(CCSizeMake(460,128))
	local detailWidth = 460

	nHeight = nHeight - 20

	self.modelFrame = display.newSprite(HeroRes .. "model_frame.png")
	self.modelFrame:size(194, 187):anch(0, 1):pos(10, nHeight - 25):addTo(detailLayer, 1)

	self.modelFrame:removeAllChildren()

	local paths = string.split(self.unitData.boneResource, "/")
	armatureManager:load(self.unitData.type)
		
	local sprite = CCNodeExtend.extend(CCArmature:create(paths[#paths]))
	sprite:pos(self.modelFrame:getContentSize().width / 2, 50):addTo(self.modelFrame)
	sprite:scale(self.unitData.boneRatio / 100)
	sprite:getAnimation():setSpeedScale(0.4)
	sprite:getAnimation():play("idle")

	--特效
	local effectSprite
	if armatureManager:hasEffectLoaded(self.unitData.type) then
		local paths = string.split(self.unitData.boneEffectResource, "/")
		effectSprite = CCNodeExtend.extend(CCArmature:create(paths[#paths]))
		effectSprite:pos(self.modelFrame:getContentSize().width / 2, 35):addTo(self.modelFrame)
		effectSprite:scale(self.unitData.boneEffectRatio / 100)
		effectSprite:getAnimation():setSpeedScale(0.4)
	end

	local function playAnimation(index)
		local animationNames
		animationNames = { "move", "idle", "attack", "attack2", "attack3", "attack4"}
	
		if self.unitData.skillAnimateName ~= "0" then
			table.insert(animationNames, self.unitData.skillAnimateName)
		end
		index = math.random(index or 1, #animationNames)
		if #animationNames[index] > 0 then
			sprite:getAnimation():play(animationNames[index])

			if effectSprite and (animationNames[index] == "attack" or animationNames[index] == "attack2"
				or animationNames[index] == "attack3" or animationNames[index] == "attack4"
				or animationNames[index] == self.unitData.skillAnimateName) then
				effectSprite:getAnimation():play(animationNames[index])
			end
		end
	end

	local cardLayer = display.newLayer()
	local modeSize = self.modelFrame:getContentSize()
	cardLayer:size(modeSize):addTo(self.modelFrame)
	cardLayer:setTouchEnabled(true)
	cardLayer:addTouchEventListener(function(event, x, y)
		if event == "began" then
			if uihelper.nodeContainTouchPoint(cardLayer, ccp(x, y)) then
				playAnimation()
			end

			return false
		end
	end, false, self.priority - 3)

	local xLeftOffset = 30
	--觉醒和名称
	local evolutionCount = self.curHero and self.curHero.evolutionCount or 0	
	local xPos, yPos = xLeftOffset - 10, nHeight - 245
	local res = string.format("name_bg_%d.png", evolutionCount)
	if self.curHero and self.curHero.wakeLevel > 0 then
		local sprite = display.newSprite(HeroRes .. string.format("wake_%d.png", self.curHero.wakeLevel))
			:anch(0, 0):pos(xPos, yPos):addTo(detailLayer)
		xPos = xPos + sprite:getContentSize().width + 10
		res = "name_bg.png"
	end
	local nameBg = display.newSprite(HeroRes .. res)
	nameBg:anch(0, 0):pos(xPos, yPos):addTo(detailLayer)
	local name = self.curHero and self.curHero:getHeroName() or self.unitData.name
	ui.newTTFLabel({text = name, size = 22, font = ChineseFont})
		:anch(0.5, 0.5):pos(nameBg:getContentSize().width/2, nameBg:getContentSize().height/2 - 4):addTo(nameBg)

	-- 基本属性
	local baseBg = display.newSprite(HeroInfoRes .. "base_info_bg.png")
	baseBg:anch(0, 0):pos(234, nHeight - 240):addTo(detailLayer)
	local baseLeftXOffset = 18
	--星级
	for index = 1, self.star do
		display.newSprite(HeroMapRes .. "map_star.png"):anch(0, 0):pos(baseLeftXOffset + (index - 1) * 24, 190):addTo(baseBg)
	end
	--国家
	local campResources = {
		[1] = { name = "群雄"},
		[2] = { name = "魏国"},
		[3] = { name = "蜀国"},
		[4] = { name = "吴国"},
	}

	ui.newTTFLabel({ text = string.format("国家：%s", campResources[self.unitData.camp].name), size = 20, color = uihelper.hex2rgb("#734416")})
	:anch(0, 0):pos(baseLeftXOffset, 155):addTo(baseBg)
	--职业
	local profressionResources = {
		[1] = { name = "步兵"},
		[3] = { name = "骑兵"},
		[4] = { name = "弓兵"},
		[5] = { name = "军师"},
	}
	ui.newTTFLabel({ text = string.format("职业: %s", profressionResources[self.unitData.profession].name), size = 20, color = uihelper.hex2rgb("#734416")})
	:anch(0, 0):pos(baseLeftXOffset, 120):addTo(baseBg)
	--等级
	ui.newTTFLabel({ text = string.format("等级: Lv %d", self.curHero and self.curHero.level or self.level), size = 20, color = uihelper.hex2rgb("#734416") })
	:anch(0, 0):pos(baseLeftXOffset, 85):addTo(baseBg)

	-- 经验条
	local expSlot = display.newSprite( HeroInfoRes .. "exp_bg.png")
	expSlot:anch(0, 0):pos(baseLeftXOffset, 55):addTo(baseBg)
	local expProgress = display.newProgressTimer(HeroInfoRes .. "exp_bar.png", display.PROGRESS_TIMER_BAR)
	expProgress:setMidpoint(ccp(0, 0.5))
	expProgress:setBarChangeRate(ccp(1,0))
	if self.curHero then
		expProgress:setPercentage( self.curHero.exp / self.curHero:getLevelTotalExp() * 100)
	else
		expProgress:setPercentage(0)
	end
	expProgress:pos(expSlot:getContentSize().width/2, expSlot:getContentSize().height/2):addTo(expSlot)
	if self.curHero then
		ui.newTTFLabel({text = string.format("%d / %d", self.curHero.exp, self.curHero:getLevelTotalExp()), size = 18})
		:anch(0.5,0.5):pos(expSlot:getContentSize().width/2, expSlot:getContentSize().height/2):addTo(expProgress)
	end
	--更多属性	
	local openBtn = DGBtn:new(HeroInfoRes, {"more_detail_normal.png", "more_detail_selected.png"}, 
		{
			priority = self.priority -1,
			callback = function()
				if not self.hideMoreBt then
					local HeroChooseLayer = require("scenes.home.hero.HeroChooseLayer")
					HeroChooseLayer.sShowAttrDetails(self.curHero, self.heroType)
				end
			end,
		})
	openBtn:getLayer():anch(0, 0):pos(baseLeftXOffset, 13):addTo(baseBg)

	nHeight = nHeight - 240

	if self.curHero then
		local xPos, yPos = xLeftOffset, nHeight - 30
		local isStarMax = self.curHero:isStarMax()
		--碎片
		local tempNode = display.newSprite(HeroRes .. "fragment_tag.png"):anch(0, 0.5):pos(xPos, yPos):addTo(detailLayer)
		xPos = xPos + tempNode:getContentSize().width + 2
		--进度条
		local expSlot = display.newSprite(HeroRes .. "growth/star_progress_bg.png")
		expSlot:anch(0, 0.5):pos(xPos, yPos):addTo(detailLayer)
		local expProgress = display.newProgressTimer(HeroRes .. "growth/star_progress_fg.png", display.PROGRESS_TIMER_BAR)
		expProgress:setMidpoint(ccp(0, 0.5))
		expProgress:setBarChangeRate(ccp(1,0))
		local costFragment = globalCsv:getFieldValue("starUpFragment")[self.curHero.star + 1]
		local fragmentId = math.floor(self.curHero.type + 2000)
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
						self:initContentRight()
					end,
				})
				sourceLayer:getLayer():addTo(display.getRunningScene())
			end,
		}):getLayer():anch(0, 0.5):pos(xPos, yPos):addTo(detailLayer)

		if not isStarMax then
			local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
			xPos = xPos + tempNode:getContentSize().width - 2
			--升星
			self.starupBtn = DGBtn:new(HeroRes .. "growth/", {"btn_star_normal.png", "btn_star_selected.png"}, 
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
	            		showText = { text = string.format("是否消耗%d[image=resource/ui_rc/global/yinbi.png][/image]升星？", globalCsv:getFieldValue("starUpCost")[self.curHero.star + 1]), size = 28, },
	            		button2Data = {
	                		callback = function()
	                    		local starRequst = {
	                       			roleId = game.role.id,
	                        		param1 = self.curHero.id,
	                    		}
	                    		local bin = pb.encode("SimpleEvent", starRequst)
	                    		game:sendData(actionCodes.HeroStarUpRequest, bin)
	    						game:addEventListener(actionModules[actionCodes.HeroStarUpRequest], function(event)
	    							game.role:dispatchEvent({ name = "notifyNewMessage", type = "heroList"})
							    	--播放成功特效
							    	StarUpSuccessLayer.new({priority = self.priority - 200, hero = self.curHero, endEffectCallback = function()
							    		self:initContentLeft() 
							    		self:initContentRight() 
							    	end})

							    	playAnimation(3)
							    	game:playMusic(33)
							    	self.star = self.curHero.star
							    	
							    	return "__REMOVE__"
							    end)
	                		end,
	            		} 
	        		})
	        		addAssistDialog:getLayer():anch(0.5, 0.5):pos(display.cx, display.cy):addTo(display.getRunningScene())
				end,
			}):getLayer():anch(0, 0.5):pos(xPos, yPos):addTo(detailLayer)

			if self.curHero:canStarUp() then
				uihelper.newMsgTag(self.starupBtn, ccp(-10, -10))
				if game:activeSpecialGuide(503) then
					self:checkGuide()
				end
			end
		end
		nHeight = nHeight - 40
	end


	-- 必杀技描述
	nHeight = nHeight - 20
	local skillData = skillCsv:getSkillById(self.unitData.talentSkillId)
	if skillData then
		local titleBg = display.newSprite(HeroRes .. "title_bg.png"):anch(0,1):pos(xLeftOffset, nHeight):addTo(detailLayer)
		-- 必杀技
		local skillLabel = ui.newTTFLabel({ text = "必杀技", font = ChineseFont, size = 20, color=display.COLOR_WHITE })
		skillLabel:anch(0,0.5):pos(10, titleBg:getContentSize().height/2):addTo(titleBg)
		local xPos, yPos = xLeftOffset, nHeight - 38
		local skillIcon = display.newSprite(skillData.icon):anch(0,1):scale(0.9):pos(xPos, yPos):addTo(detailLayer)
		self.removeImages[skillData.icon] = true

		xPos = xPos + skillIcon:getContentSize().width + 14
		local name = ui.newTTFLabel({ text = skillData.name, size = 22, color = uihelper.hex2rgb("#734416")})
		name:anch(0, 1):pos(xPos, yPos):addTo(detailLayer)

		xPos = xPos + name:getContentSize().width + 10
		local skillLevel = self.heroId and self.curHero.skillLevels[tostring(skillData.skillId)] or 1
		ui.newTTFLabel({ text = "Lv." .. skillLevel, size = 22, color = uihelper.hex2rgb("#1396e1")})
			:anch(0, 1):pos(xPos, yPos):addTo(detailLayer)
		
		ui.newTTFLabel({ text = string.format("消耗怒气: %d", skillData.angryUnitNum), size = 22, color = uihelper.hex2rgb("#1396e1")})
			:anch(0, 1):pos(320, yPos):addTo(detailLayer)
		
		local text, line = uihelper.createLabel({ text = skillCsv:getDescByLevel(skillData.skillId, skillLevel), color = uihelper.hex2rgb("#444444"), size = 18, width = 312 })
		text:anch(0, 1):pos(xLeftOffset + skillIcon:getContentSize().width + 14, nHeight - 70):addTo(detailLayer)

	
		nHeight = nHeight - 126 - math.max((line - 2), 0)*22
		display.newSprite(HeroGrowthRes .. "splitter.png"):anch(0.5,1):pos(detailWidth/2, nHeight):addTo(detailLayer)
	end
	
	
	-- 被动技能
	if self:hasPassiveSkill() then

		nHeight = nHeight - 10
		local titleBg = display.newSprite(HeroRes .. "title_bg.png"):anch(0,1):pos(xLeftOffset, nHeight):addTo(detailLayer)

		ui.newTTFLabel({ text = "被动技", size = 20, font = ChineseFont, color=display.COLOR_WHITE })
		:anch(0,0.5):pos(10, titleBg:getContentSize().height/2):addTo(titleBg)

		
		nHeight = nHeight - 38
		for index = 1, 3 do
			local xPos, yPos = xLeftOffset, nHeight 
			local skillId = self.unitData["passiveSkill" .. index]
			local passiveSkillData = skillPassiveCsv:getPassiveSkillById(skillId)

			local level = globalCsv:getFieldValue("passiveSkillLevel" .. index)

			if passiveSkillData then
				local skillImage = display.newSprite(passiveSkillData.icon):scale(0.9):anch(0,1):pos(xPos, yPos):addTo(detailLayer)
				self.removeImages[passiveSkillData.icon] = true

				-- 技能名
				xPos = xPos + skillImage:getContentSize().width + 14
				local name = ui.newTTFLabel({text = passiveSkillData.name, size = 22, color = uihelper.hex2rgb("#734416")})
				name:anch(0,1):pos(xPos, yPos):addTo(detailLayer)

				xPos = xPos + name:getContentSize().width + 10
				local skillLevel = self.heroId and (self.curHero.skillLevels[tostring(skillId + 10000)] or 1) or 1
				if not (self.heroId and self.curHero.evolutionCount >= level) then
					ui.newTTFLabel({text = string.format("未激活(进化到%s激活)", uihelper.getEvolColorDesc(level)), size = 22, color = uihelper.hex2rgb("#e43616")})
					:anch(0, 1):pos(225, yPos):addTo(detailLayer)
				else
					ui.newTTFLabel({ text = "Lv." .. skillLevel, size = 22, color = uihelper.hex2rgb("#1396e1")})
						:anch(0, 1):pos(xPos, yPos):addTo(detailLayer)
				end

				local text, line = uihelper.createLabel({ text = skillPassiveCsv:getDescByLevel(skillId, skillLevel), color = uihelper.hex2rgb("#444444"), size = 18, width = 312 })
				text:anch(0, 1):pos(xLeftOffset + skillImage:getContentSize().width + 14, nHeight - 27):addTo(detailLayer)

				display.newSprite(HeroGrowthRes .. "splitter.png"):anch(0.5,1):pos(detailWidth/2, nHeight - 90):addTo(detailLayer)
				nHeight = nHeight - 108 - math.max((line - 2), 0)*22
			end
		end
	end

	if table.nums(self.unitData.relation) > 0 then
		-- 情缘
		nHeight = nHeight - 10
		local titleBg = display.newSprite(HeroRes .. "title_bg.png"):anch(0,1):pos(xLeftOffset, nHeight):addTo(detailLayer)

		ui.newTTFLabel({ text = "情缘", size = 20, font = ChineseFont, color=display.COLOR_WHITE })
		:anch(0,0.5):pos(10, titleBg:getContentSize().height/2):addTo(titleBg)

		nHeight = nHeight - 38 

		for index = 1, table.nums(self.unitData.relation) do
			local relation = self.unitData.relation[index]
			--名称
			local name = ui.newTTFLabel({ text = relation[6], size = 22, color = uihelper.hex2rgb("#734416") })
				:anch(0, 1):pos(xLeftOffset, nHeight):addTo(detailLayer)

			nHeight = nHeight - name:getContentSize().height - 5
			--描述
			local desc = unitCsv:formatRelationDesc(relation)
									
			local descLabel = uihelper.createLabel({text = desc, size = 18, color = uihelper.hex2rgb("#444444"), width = 435})
			descLabel:anch(0, 1):pos(xLeftOffset, nHeight):addTo(detailLayer)

			nHeight = nHeight - 10 - descLabel:getContentSize().height
		end
		display.newSprite(HeroGrowthRes .. "splitter.png"):anch(0.5,1):pos(detailWidth/2, nHeight):addTo(detailLayer)
	end

	-- 简介
	nHeight = nHeight - 10
	local titleBg = display.newSprite(HeroRes .. "title_bg.png"):anch(0,1):pos(xLeftOffset, nHeight):addTo(detailLayer)

	ui.newTTFLabel({ text = "简介", size = 20, font = ChineseFont, color=display.COLOR_WHITE })
	:anch(0,0.5):pos(10, titleBg:getContentSize().height/2):addTo(titleBg)

	nHeight = nHeight - 38 
	local heroDesc = uihelper.createLabel({ text = self.unitData.desc, size = 18, color = uihelper.hex2rgb("#444444"), width = 400})
	heroDesc:anch(0,1):pos(xLeftOffset, nHeight):addTo(detailLayer)

	nHeight = nHeight - heroDesc:getContentSize().height - 10 


	local function scrollViewDidScroll()
	end

	local function scrollViewDidZoom()
	end

	local tempLayer = display.newLayer()
	tempLayer:size(CCSizeMake(460, math.abs(nHeight)))
	detailLayer:pos(0, math.abs(nHeight)):addTo(tempLayer)

	local detailScrollView = CCScrollView:create()
	detailScrollView:setViewSize(CCSizeMake(460,520))
	detailScrollView:setContainer(tempLayer)
	detailScrollView:updateInset()
	detailScrollView:setContentOffset(ccp(0, 536 - math.abs(nHeight)))
	detailScrollView:setPosition(ccp(0, 30))
	detailScrollView:ignoreAnchorPointForPosition(true)
	detailScrollView:setDirection(kCCScrollViewDirectionVertical)
	detailScrollView:setBounceable(true)
	detailScrollView:setTouchPriority(self.priority - 2)
	detailScrollView:registerScriptHandler(scrollViewDidScroll,CCScrollView.kScrollViewScroll)
	detailScrollView:registerScriptHandler(scrollViewDidZoom,CCScrollView.kScrollViewZoom)
	self.rightContentLayer:addChild(detailScrollView)

end

function HeroInfoLayer:hasPassiveSkill()
	for index = 1, 3 do
		local skillId = self.unitData["passiveSkill" .. index]
		local passiveSkillData = skillPassiveCsv:getPassiveSkillById(skillId)

		if passiveSkillData then
			return true
		end
	end
	return false
end

function HeroInfoLayer:prepareBonusData()
	self.basicValues = {hp = 0, atk = 0, def = 0}			-- 基础值
	self.techBonus = {hp = 0, atk = 0, def = 0}			-- 科技加成
	self.starBonus = {hp = 0, atk = 0, def = 0}			-- 星魂加成
	self.beautyBonus = {hp = 0, atk = 0, def = 0}			-- 美人加成

	if not self.heroId then
		self.basicValues.hp = self.unitData.hp
		self.basicValues.atk = self.unitData.attack
		self.basicValues.def = self.unitData.defense
	else
		local hero = game.role.heros[self.heroId]

		local basicValues = hero:getBaseAttrValues()
		self.basicValues.hp = basicValues.hp
		self.basicValues.atk = basicValues.atk
		self.basicValues.def = basicValues.def

		local techBonus = Hero.sGetProfessionBonusValues(basicValues, hero.type)
		self.techBonus.hp = techBonus.hpBonus
		self.techBonus.atk = techBonus.atkBonus
		self.techBonus.def = techBonus.defBonus

		local starBonus = Hero.sGetStarSoulBonusValues(hero.type)
		self.starBonus.hp = starBonus.hpBonus
		self.starBonus.atk = starBonus.atkBonus
		self.starBonus.def = starBonus.defBonus

		local beautyBonus = Hero.sGetBeautyBonusValues()
		self.beautyBonus.hp = beautyBonus.hpBonus
		self.beautyBonus.atk = beautyBonus.atkBonus
		self.beautyBonus.def = beautyBonus.defBonus
	end
end


function HeroInfoLayer:unableBtn()
	if self.skillUpBtn then
		self.evolutionBtn:setEnable(not self.isNormalScale)
		self.skillUpBtn:setEnable(not self.isNormalScale)
	end
end

function HeroInfoLayer:onExit()
	game.role:removeEventListener("after_intensify", self.afterIntensifyHandler)

	-- 如果武将是点将武将, 不卸载
	if not self.keepRes then
		armatureManager:unload(self.heroType)
	end	

	for name, bool in pairs(self.removeImages) do
		display.removeSpriteFrameByImageName(name)
	end

	self:checkGuide(true)
end

return HeroInfoLayer