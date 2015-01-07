local HeroStarRes = "resource/ui_rc/herostar/"
local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"
local ParticleRes = "resource/ui_rc/particle/"

local DGPageView = require("uicontrol.DGPageView")
local RuleTipsLayer = import("..RuleTipsLayer")

local campRes = {
	[1] = { res = "qun_icon.png", ch = "群"}, 
	[2] = { res = "wei_icon.png", ch = "魏"}, 
	[3] = { res = "shu_icon.png", ch = "蜀"}, 
	[4] = { res = "wu_icon.png", ch = "吴" }, 
}

local attrNameDefine = { [1] = "生命", [2] = "攻击", [3] = "防御", }

local HeroStarLayer = class("HeroStarLayer", function()
	return display.newLayer()
end)

function HeroStarLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -130
	self.closeCB = params.closeCB

	self.mask = DGMask:new({ item = self, priority = self.priority + 1 })

	--bg particle
	local particle = CCNodeExtend.extend(CCParticleSystemQuad:create(ParticleRes .. "p_star_bg.plist"))
	particle:addTo(self, 10):pos(display.cx,  display.cy)

	local index = math.floor(game.role.starPoint % 100)
	local nextStarAttrId = game.role:getNextStarAttrId(game.role.starPoint)

	self.typeIds = {}
	for typeId = 1, 31 do
		table.insert(self.typeIds, typeId)
	end

	local maxTypeId
	if nextStarAttrId then
		maxTypeId = (index == 12 and math.floor(nextStarAttrId / 100) or math.floor(game.role.starPoint / 100))
	else
		maxTypeId = self.typeIds[#self.typeIds]
	end

	self.starPageView = DGPageView.new({
		priority = self.priority - 1,
		size = CCSizeMake(display.width, display.height),
		dataSource = self.typeIds,
		initPageIndex = maxTypeId,
		cellAtIndex = function(index) 
			return self:initStarInfo(self.typeIds[index])
		end
	})
	self.starPageView:setEnable(false)
	self.starPageView:getLayer():anch(0.5, 0.5):pos(display.cx, display.cy):addTo(self)

	-- 
	local numberBg = display.newSprite(HeroStarRes .. "health_bg.png")
	numberBg:anch(0, 0.5):pos(20, display.height - 40):addTo(self)
	local numBgSize = numberBg:getContentSize()
	display.newSprite(GlobalRes .. "starsoul.png"):anch(0, 0.5):pos(5, numBgSize.height / 2):addTo(numberBg)
	local starSoulValue = ui.newTTFLabel({ text = game.role.starSoulNum, size = 24})
	starSoulValue:anch(0, 0.5):pos(50, numBgSize.height / 2):addTo(numberBg)
	self.starSoulHandle = game.role:addEventListener("updateStarSoulNum", function(event)
		starSoulValue:setString(event.starSoulNum)
	end)

	local ruleBtn = DGBtn:new(GlobalRes, {"btn_decomp_normal.png", "btn_decomp_selected.png"},
		{	
			text = { text = "规则", size = 28, font = ChineseFont, strokeColor = display.COLOR_FONT },
			priority = self.priority,
			callback = function()
				local tipsLayer = RuleTipsLayer.new({ priority = self.priority - 100, file = "txt/function/herostar.txt" })
				tipsLayer:getLayer():addTo(display.getRunningScene())
			end,
		}):getLayer()
	ruleBtn:anch(1, 1):pos(display.width - 150, display.height - 20):addTo(self)

	-- 关闭按钮
	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"}, 
		{
			touchScale = 1.5,
			priority = self.priority,
			callback = function() 
				self:getLayer():removeSelf() 
				if self.closeCB then self.closeCB() end
			end
		}):getLayer()
	closeBtn:anch(1, 1):pos(display.width - 10, display.height - 10):addTo(self, 2)

	self.starPointHandle = game.role:addEventListener("updateStarPoint", handler(self, self.onUpdateStarPoint))

	self:initCampIcons()
end

function HeroStarLayer:onEnter()
	self:checkGuide()
end

function HeroStarLayer:checkGuide(remove)
	game:addGuideNode({node = self.guideBtn, remove = remove,
		guideIds = {1224}
	})
end

function HeroStarLayer:onExit()
	self:checkGuide(true)
end

-- 顶栏属性总和
function HeroStarLayer:initCampIcons(camp)
	self:removeChildByTag(999)

	local campLayer = display.newLayer(HeroStarRes .. "camp_bg.png")
	local bgSize = campLayer:getContentSize()

	local function createCampNode(campIndex)
		local node = display.newLayer()
		node:size(CCSizeMake(bgSize.width / 2, 60))

		local campSprite = display.newSprite(HeroStarRes .. campRes[campIndex].res)
		campSprite:anch(0, 0.5):pos(20, 30):addTo(node)

		local starAttrBonuses = game.role:calStarAttrBonuses(game.role.starPoint)
		-- hp
		display.newSprite(HeroRes .. "attr_hp.png")
			:pos(100, 30):addTo(node)
		ui.newTTFLabel({text = "+" .. (starAttrBonuses[campIndex].hpBonus or 0), size = 18, color = display.COLOR_GREEN })
			:pos(130, 30):addTo(node)
		-- atk
		display.newSprite(HeroRes .. "attr_atk.png")
			:pos(200, 30):addTo(node)
		ui.newTTFLabel({text = "+" .. (starAttrBonuses[campIndex].atkBonus or 0), size = 18, color = display.COLOR_GREEN })
			:pos(230, 30):addTo(node)
		-- def
		display.newSprite(HeroRes .. "attr_def.png")
			:pos(300, 30):addTo(node)
		ui.newTTFLabel({text = "+" .. (starAttrBonuses[campIndex].defBonus or 0), size = 18, color = display.COLOR_GREEN })
			:pos(330, 30):addTo(node)

		if camp and camp == campIndex then
			display.newSprite(HeroStarRes .. "halo.png"):addTo(campSprite)
				:pos(campSprite:getContentSize().width / 2, campSprite:getContentSize().height / 2)
		end

		return node
	end

	local qunCamp = createCampNode(1)
	qunCamp:anch(0, 0.5):pos(60, bgSize.height * 3 / 4):addTo(campLayer)

	local weiCamp = createCampNode(2)
	weiCamp:anch(0, 0.5):pos(bgSize.width / 2, bgSize.height * 3 / 4):addTo(campLayer)

	local shuCamp = createCampNode(3)
	shuCamp:anch(0, 0.5):pos(60, bgSize.height / 4):addTo(campLayer)

	local wuCamp = createCampNode(4)
	wuCamp:anch(0, 0.5):pos(bgSize.width / 2, bgSize.height/ 4):addTo(campLayer)

	campLayer:anch(0.5, 0):pos(display.cx, 5):addTo(self, 0, 999)
end

function HeroStarLayer:initStarInfo(typeId)
	local starInfo = heroStarInfoCsv:getDataByType(typeId)
	local showLayer = display.newLayer()
	display.newSprite(starInfo.bgRes):center():addTo(showLayer)

	local currentStarType = math.floor(game.role.starPoint / 100)
	local grayIndex = typeId < currentStarType and 13 or (game.role.starPoint % 100 + 1)

	if typeId > currentStarType and typeId <= #self.typeIds then 
		grayIndex = 1 
	end

	ui.newTTFLabelWithStroke({text = starInfo.name, size = 36, color = display.COLOR_YELLOW,
		strokeColor = uihelper.hex2rgb("#451905"), font = ChineseFont })
		:pos(display.cx, display.height - 50):addTo(showLayer)
	
	local starAttrDataArray = {}
	for index = 1, 12 do
		local starAttrData = heroStarAttrCsv:getDataById(typeId * 100 + index)
		starAttrDataArray[index] = starAttrData
	end

	-- Tips弹框
	local function showTips(index)
		local starAttrData = starAttrDataArray[index]

		local attrBg = display.newSprite(HeroStarRes .. "attr_every.png")
		local attrBgSize = attrBg:getContentSize()
		attrBg:pos(starAttrData.xPos + display.cx, display.cy - starAttrData.yPos + 65)
			:addTo(showLayer, 10, 10)

		if index >= grayIndex then
			ui.newTTFLabelWithStroke({ text = string.format("%sの%s+%d", campRes[starAttrData.camp].ch, attrNameDefine[starAttrData.attrId], starAttrData.attrValue), 
				size = 22, strokeColor = display.COLOR_DARKYELLOW })
				:anch(0, 0.5):pos(10, attrBgSize.height / 2 + 15):addTo(attrBg)
			local consumeLable = ui.newTTFLabelWithStroke({ text = "消耗", size = 22, strokeColor = display.COLOR_DARKYELLOW})
			consumeLable:anch(0, 0.5):pos(10, attrBgSize.height / 2 - 15):addTo(attrBg)
			-- 星魂
			display.newSprite(GlobalRes .. "starsoul.png"):scale(0.9):anch(0, 0.5):addTo(attrBg)
				:pos(consumeLable:getContentSize().width + 12, attrBgSize.height / 2 - 15)
			ui.newTTFLabelWithStroke({ text = "x" .. starAttrData.starSoulNum, size = 20, strokeColor = display.COLOR_DARKYELLOW })
				:anch(0, 0.5):pos(consumeLable:getContentSize().width + 50, attrBgSize.height / 2 - 15):addTo(attrBg)
			-- 银币
			display.newSprite(GlobalRes .. "yinbi.png"):scale(0.9):anch(0, 0.5):addTo(attrBg)
				:pos(consumeLable:getContentSize().width + 110, attrBgSize.height / 2 - 15)
			ui.newTTFLabelWithStroke({ text = "x" .. starAttrData.moneyNum, size = 20, strokeColor = display.COLOR_DARKYELLOW })
				:anch(0, 0.5):pos(consumeLable:getContentSize().width + 150, attrBgSize.height / 2 - 15):addTo(attrBg)
		else
			ui.newTTFLabelWithStroke({ text = string.format("%sの%s+%d", campRes[starAttrData.camp].ch, attrNameDefine[starAttrData.attrId], starAttrData.attrValue), 
				size = 20, strokeColor = display.COLOR_DARKYELLOW })
				:anch(0,0.5):pos(10, attrBgSize.height / 2):addTo(attrBg)
		end
	end

	-- 点击将星点
	local function starClick(index)
		local starAttrData = starAttrDataArray[index]
		
		if self.lastClickNode then
			if self.lastClickNode == index then
				local clickAttrId = typeId * 100 + index
				if game.role:getNextStarAttrId(game.role.starPoint) ~= clickAttrId then
					return
				end
				if game.role.starSoulNum < starAttrData.starSoulNum then
					DGMsgBox.new({ msgId = 180 })
					return
				end
				local bin = pb.encode("SimpleEvent", { roleId = game.role.id, param1 = typeId * 100 + index })
				game:sendData(actionCodes.StarHeroPromoteRequest, bin)
				game:addEventListener(actionModules[actionCodes.StarHeroPromoteResponse], function(event)
					local msg = pb.decode("SimpleEvent", event.data)

					self:flyParticleShow(ccp(starAttrData.xPos + display.cx, display.cy - starAttrData.yPos))

					-- self:showCampTips(starAttrData.camp)
					self:initCampIcons(starAttrData.camp)

					game:playMusic(42)							
					-- 数值
					local attrNameRes = { [1] = "hp_text.png", [2] = "atk_text.png", [3] = "def_text.png"}
					local tipsNode = display.newNode()
					local attrTextSprite = display.newSprite(HeroRes .. attrNameRes[starAttrData.attrId])
					local tips = ui.newBMFontLabel({ text = "+" .. starAttrData.attrValue, font = FontRes .. "attrNum.fnt"})
					
					local width, height = attrTextSprite:getContentSize().width + tips:getContentSize().width, tips:getContentSize().height
					tipsNode:size(width, height)
					attrTextSprite:anch(0, 0.5):pos(0, height / 2):addTo(tipsNode)
					tips:anch(1, 0.5):pos(width, height / 2):addTo(tipsNode)

					tipsNode:anch(0.5, 0.5):pos(starAttrData.xPos + display.cx, display.cy - starAttrData.yPos + 60)
						:addTo(self)
					tipsNode:runAction(transition.sequence({
						CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 20)), CCScaleTo:create(0.1, 1)),
						CCDelayTime:create(0.2),
						CCSpawn:createWithTwoActions(CCMoveBy:create(0.1, ccp(0, 5)), CCScaleTo:create(0.1, 0.75)),
						CCSpawn:createWithTwoActions(CCMoveBy:create(0.5, ccp(0, 20)), CCFadeOut:create(0.5)),
						CCRemoveSelf:create()
					}))

					return "__REMOVE__"
				end)

				self.lastClickNode = nil
			else
				showLayer:removeChildByTag(10)
				showTips(index)

				self.lastClickNode = index
			end
		else
			showLayer:removeChildByTag(10)
			showTips(index)

			self.lastClickNode = index
		end
	end

	-- 摆放亮格
	for index = 1, grayIndex - 1 do
		local node = DGBtn:new(HeroStarRes, {"star_selected.png", "star_selected.png"},
			{	
				priority = self.priority,
				callback = function()
					starClick(index)
				end,
			}):getLayer()
		node:anch(0.5, 0.5):pos(starAttrDataArray[index].xPos + display.cx, display.cy - starAttrDataArray[index].yPos):addTo(showLayer, 2)

		local actions = {}
		actions[#actions + 1] = CCScaleTo:create(1, 0.85)
		actions[#actions + 1] = CCScaleTo:create(1, 1)
		display.newSprite(HeroStarRes .. "star_light.png"):addTo(node, -1)
			:pos(node:getContentSize().width / 2, node:getContentSize().height / 2)
			:runAction(CCRepeatForever:create(transition.sequence(actions)))

		if index < grayIndex - 1 then
			local lightedLine = display.newSprite(HeroStarRes .. "line_light.png")

			local angle = ccp(starAttrDataArray[index + 1].xPos - starAttrDataArray[index].xPos, -starAttrDataArray[index + 1].yPos + starAttrDataArray[index].yPos):getAngle()	
			local distance = ccpDistance(ccp(starAttrDataArray[index + 1].xPos + display.cx, display.cy - starAttrDataArray[index + 1].yPos), ccp(starAttrDataArray[index].xPos + display.cx, display.cy - starAttrDataArray[index].yPos))
			
			lightedLine:setScaleX(distance / lightedLine:getContentSize().width)
			lightedLine:anch(0, 0.5):rotation(angle / math.pi * -180):addTo(showLayer, 1)
				:pos(starAttrDataArray[index].xPos + display.cx, display.cy - starAttrDataArray[index].yPos)
		end
	end

	-- 中间节点
	if grayIndex > 1 and grayIndex <= 12 then
		local lightedLine = display.newSprite(HeroStarRes .. "line_dark.png")

		local angle = ccp(starAttrDataArray[grayIndex].xPos - starAttrDataArray[grayIndex - 1].xPos, -starAttrDataArray[grayIndex].yPos + starAttrDataArray[grayIndex - 1].yPos):getAngle()	
		local distance = ccpDistance(ccp(starAttrDataArray[grayIndex].xPos + display.cx, display.cy - starAttrDataArray[grayIndex].yPos), ccp(starAttrDataArray[grayIndex - 1].xPos + display.cx, display.cy - starAttrDataArray[grayIndex - 1].yPos))
			
		lightedLine:setScaleX(distance / lightedLine:getContentSize().width)
		lightedLine:anch(0, 0.5):rotation(angle / math.pi * -180):addTo(showLayer, 1)
			:pos(starAttrDataArray[grayIndex - 1].xPos + display.cx, display.cy - starAttrDataArray[grayIndex - 1].yPos)
	end

	-- 摆放暗格
	for index = grayIndex, 12 do
		local node = DGBtn:new(HeroStarRes, {"star_normal.png", "star_normal.png"},
			{	
				priority = self.priority,
				callback = function() 
					starClick(index)
				end,
			}):getLayer()
		node:anch(0.5, 0.5):pos(starAttrDataArray[index].xPos + display.cx, display.cy - starAttrDataArray[index].yPos):addTo(showLayer, 2)
		if index == 1 then
			self.guideBtn = node
		end

		if index == grayIndex then
			showTips(grayIndex)
			self.lastClickNode = grayIndex
		end

		if index < 12 then
			local lightedLine = display.newSprite(HeroStarRes .. "line_dark.png")

			local angle = ccp(starAttrDataArray[index + 1].xPos - starAttrDataArray[index].xPos, -starAttrDataArray[index + 1].yPos + starAttrDataArray[index].yPos):getAngle()	
			local distance = ccpDistance(ccp(starAttrDataArray[index + 1].xPos + display.cx, display.cy - starAttrDataArray[index + 1].yPos), ccp(starAttrDataArray[index].xPos + display.cx, display.cy - starAttrDataArray[index].yPos))
			
			lightedLine:setScaleX(distance / lightedLine:getContentSize().width)
			lightedLine:anch(0, 0.5):rotation(angle / math.pi * -180):addTo(showLayer, 1)
				:pos(starAttrDataArray[index].xPos + display.cx,  display.cy - starAttrDataArray[index].yPos)
		end
	end

	-- self.leftBtn:setEnable(typeId > 1)
	-- self.rightBtn:setEnable(typeId < 5)

	return showLayer
end

function HeroStarLayer:onUpdateStarSoul(event)
	self.starSoulValue:setString(event.starSoulNum)
end

function HeroStarLayer:onUpdateStarPoint(event)
	local index = math.floor(event.starPoint % 100)
	local nextStarAttrId = game.role:getNextStarAttrId(event.starPoint)

	local maxTypeId
	if nextStarAttrId then
		maxTypeId = (index == 12 and math.floor(nextStarAttrId / 100) or math.floor(event.starPoint / 100))
	else
		maxTypeId = self.typeIds[#self.typeIds]
	end
	if maxTypeId > self.typeIds[self.starPageView:getCurPageIndex()] then
		self:runAction(transition.sequence({
			CCCallFunc:create(function() self.starPageView:refresh() end),
			CCDelayTime:create(1),
			CCCallFunc:create(function() self.starPageView:autoScroll(1) end),
		}))
	else
		self.starPageView:refresh()
	end
end

--贝瑟尔路径
function HeroStarLayer:flyParticleShow(endPoint)
	local views = {}
	for i=1, 7 do

		local eff = CCNodeExtend.extend(CCParticleSystemQuad:create(ParticleRes .. "p_star_item.plist"))
		eff:addTo(self, 10):pos(display.cx,  display.cy)
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
			local burst = CCNodeExtend.extend(CCParticleSystemQuad:create(ParticleRes .. "p_star_burst.plist"))
			burst:addTo(self, 10):pos(endPoint.x,  endPoint.y)
			
		end)
		local arr = CCArray:create()
		arr:addObject(moveto_bezier)
		arr:addObject(callEnd)
		local effSeq = CCSequence:create(arr)
		eff:runAction(effSeq)
	end
	
end

function HeroStarLayer:randomBezier(sx, sy, ex, ey, arcx, arcy)
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

function HeroStarLayer:getLayer()
	return self.mask:getLayer()
end

function HeroStarLayer:onExit()
	game.role:removeEventListener("updateStarSoulNum", self.starSoulHandle)
	game.role:removeEventListener("updateStarPoint", self.starPointHandle)
end

function HeroStarLayer:onCleanup()
	display.removeUnusedSpriteFrames()
end

return HeroStarLayer