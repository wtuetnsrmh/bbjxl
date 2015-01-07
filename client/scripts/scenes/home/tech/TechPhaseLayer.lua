local TechRes = "resource/ui_rc/tech_new/"
local GlobalRes = "resource/ui_rc/global/"
local ParticleRes = "resource/ui_rc/particle/"
local FrameActRes = "resource/skill_pic/"

local ShopMainLayer = import("..shop.ShopMainLayer")
local TopBarLayer = require("scenes.TopBarLayer")

local profressionResources = {
	[1] = { name = "bu", ch = "步兵" },
	[3] = { name = "qi", ch = "骑兵" },
	[4] = { name = "gong", ch = "弓兵" },
	[5] = { name = "jun", ch = "军师" },
}

local profressionModelRes = {
	[1] = { [1] = 401, [2] = 421, [3] = 282, [4] = 176 },
	[3] = { [1] = 402, [2] = 42, [3] = 43, [4] = 14 },
	[4] = { [1] = 403, [2] = 66, [3] = 41, [4] = 5 },
	[5] = { [1] = 404, [2] = 424, [3] = 175, [4] = 60 },
}

local attrResources = {
	[1] = { field = "atkBonusDesc", desc = "攻击" },
	[2] = { field = "defBonusDesc", desc = "防御" },
	[3] = { field = "hpBonusDesc", desc = "生命" },
	[4] = { field = "restraintBonusDesc", desc = "对%s的伤害" },
}

local TechPhaseLayer = class("TechPhaseLayer", function()
	return display.newLayer(GlobalRes .. "inner_bg.png")
end)

function TechPhaseLayer:ctor(params)
	params = params or {}
	self.priority = params.priority or -130

	self.profession = params.profession

	self.mainLayer = display.newLayer()
	self.mainLayer:size(self:getContentSize()):addTo(self)

	--当前令牌
	local lingpaiBg = display.newSprite(TechRes .. "lingpai_bg.png")
	lingpaiBg:anch(0, 1):pos(20, self:getContentSize().height - 15):addTo(self)
	local lingpaiBgSize = lingpaiBg:getContentSize()
	display.newSprite(GlobalRes .. "lingpai.png")
		:anch(0, 0.5):pos(10, lingpaiBgSize.height / 2):addTo(lingpaiBg)
	local lingpaiValue = ui.newTTFLabel({text = game.role.lingpaiNum, size = 20, color = uihelper.hex2rgb("#ffffff") })
	lingpaiValue:anch(0.5, 0.5):pos(lingpaiBgSize.width/2 + 10, lingpaiBgSize.height / 2):addTo(lingpaiBg)
	self.lingpaiValueHandler = game.role:addEventListener("updateLingpaiNum", function(event)
		lingpaiValue:setString(event.lingpaiNum)
	end)

	-- 增加令牌数量，引导去商店购买
	local addLingpaiBtn = DGBtn:new(HomeRes, {"add.png"}, {
		scale = 1.05,
		priority = self.priority,
		callback = function()
			local layer = ShopMainLayer.new({priority = self.priority - 10, choosedTab = 3})
			layer:getLayer():addTo(display.getRunningScene())	
		end
	})
	addLingpaiBtn:getLayer():anch(1, 0.5):pos(lingpaiBgSize.width + 15, lingpaiBgSize.height / 2):addTo(lingpaiBg)

	self:initMainLayer()

	local layer  = TopBarLayer.new({priority = self.priority})
	layer:anch(0,1):pos(0,display.height):addTo(self)
	
end

function TechPhaseLayer:onEnter()
	self:checkGuide()
end

function TechPhaseLayer:initMainLayer(params)

	params = params or {}

	self.mainLayer:stopAllActions()
	self.mainLayer:removeAllChildren()

	local bgSize = self:getContentSize()

	local professionData = game.role.professionBonuses[self.profession]
	local phaseData = professionPhaseCsv:getDataByPhase(self.profession, professionData[1])
	local professionBonuses = game.role:getProfessionBonus(self.profession)

	local techBg = display.newSprite(TechRes .. "tech_bg.png")
	techBg:anch(0.5, 0):pos(bgSize.width / 2, 25):addTo(self.mainLayer)	
	local techBgSize = techBg:getContentSize()

	local levelSum = professionData[2] + professionData[3] + professionData[4] + professionData[5]
	local canPromote = (levelSum == 16)

	--已加总量
	local attAllBg = display.newSprite(TechRes .. "att_all_bg.png")
	attAllBg:anch(1, 1):pos(bgSize.width - 40, bgSize.height - 15):addTo(self.mainLayer)
	local attAllBgSize = attAllBg:getContentSize()
	local xBegin, xInterval = 12, 155
	for index = 1, 3 do
		local xPos = xBegin + (index - 1) * xInterval
		ui.newTTFLabel({text = string.format("%s:", attrResources[index].desc), size = 20 })
			:anch(0, 0.5):pos(xPos, attAllBgSize.height / 2):addTo(attAllBg)
		ui.newTTFLabel({text = string.format("+%0.2f%%", professionBonuses[index]), size = 20, color = uihelper.hex2rgb("#43ff01") })
			:anch(0, 0.5):pos(xPos + 52, attAllBgSize.height / 2):addTo(attAllBg)
	end

	local xPos = 190

	--兵模
	local heroType = profressionModelRes[self.profession][professionData[1]]
	local heroUnitData = unitCsv:getUnitByType(heroType)
	local sprite	
	local paths = string.split(heroUnitData.boneResource, "/")

	armatureManager:load(heroType)
	sprite = CCNodeExtend.extend(CCArmature:create(paths[#paths]))
	sprite:getAnimation():setSpeedScale(24 / 60)
	sprite:getAnimation():play("idle")
	local scale = heroUnitData.boneRatio / 100 * (self.profession == 3 and 1.2 or 1.2)
	sprite:scale(scale)
	local layer = display.newLayer()
	layer:size(cc.size(sprite:getContentSize().width * scale, sprite:getContentSize().height * scale))
	layer:anch(0.5, 0):pos(xPos, techBgSize.height - 290):addTo(techBg)
	sprite:pos(layer:getContentSize().width / 2, 0):addTo(layer)

	-- 特效
	local effectSprite
	if armatureManager:hasEffectLoaded(heroType) then
		local paths = string.split(heroUnitData.boneEffectResource, "/")
		effectSprite = CCNodeExtend.extend(CCArmature:create(paths[#paths]))
		effectSprite:getAnimation():setSpeedScale(24 / 60)
		local scale = heroUnitData.boneEffectRatio / 100 * (self.profession == 3 and 1.2 or 1.2)
		effectSprite:scale(scale)
		effectSprite:pos(layer:getContentSize().width / 2, 0):addTo(layer)
	end

	layer:setTouchEnabled(true)
	local press = false
	layer:addTouchEventListener(
		function(event, x, y) 
			if event == "began" then
				if uihelper.nodeContainTouchPoint(layer, ccp(x, y)) then			
                   press = true
				else
					return false
				end
			elseif event == "ended" then
				if uihelper.nodeContainTouchPoint(layer, ccp(x, y))  and press then
					press = false
					local animationNames
					animationNames = { "move", "idle", "attack", "attack2", "attack3", "attack4"}
				
					if heroUnitData.skillAnimateName ~= "0" then
						table.insert(animationNames, heroUnitData.skillAnimateName)
					end
					local index = math.random(1, #animationNames)
					if #animationNames[index] > 0 then
						sprite:getAnimation():play(animationNames[index])
						
						if effectSprite and (animationNames[index] == "attack" or animationNames[index] == "attack2"
							or animationNames[index] == "attack3" or animationNames[index] == "attack4"
							or animationNames[index] == heroUnitData.skillAnimateName) then
							effectSprite:getAnimation():play(animationNames[index])
						end
					end
				end	
			end
			return true
		end, false, self.priority - 10, true)

	local toMoveUp = false
	if canPromote and professionData[1] < 4 then
		toMoveUp = true
		local promoteBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png"},
			{	
				priority = self.priority,
				text = { text = "进阶", size = 30, font = ChineseFont,  color = display.COLOR_WTHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
				callback = function() 
					local phaseData = professionPhaseCsv:getDataByPhase(self.profession, professionData[1])
					if game.role.lingpaiNum < phaseData.lingpaiNum then
						DGMsgBox.new({msgId = SYS_ERR_LINGPAI_NOT_ENOUGH, 
							button1Data = { text = "关闭"},
							button2Data = { text = "去商城",
								callback = function()
									local layer = ShopMainLayer.new({ priority = self.priority - 10, chooseIndex = 2 })
									layer:getLayer():addTo(display.getRunningScene())	
								end
							}
						 })
						return
					end
					local bin = pb.encode("SimpleEvent", { roleId = game.role.id, param1 = self.profession })
					game:sendData(actionCodes.TechPhasePromoteRequest, bin)
					loadingShow()
					game:addEventListener(actionModules[actionCodes.TechPhasePromoteResponse], function(event)
						loadingHide()

						game:playMusic(41)
						local msg = pb.decode("SimpleEvent", event.data)
						self:initMainLayer({ phase = msg.param2 })
						return "__REMOVE__"
					end)
				end,
			}):getLayer()
		promoteBtn:anch(0.5, 0):pos(xPos, 40):addTo(techBg)

		-- 令牌消耗数
		local lingpaiIcon = display.newSprite(GlobalRes .. "lingpai.png")
			:scale(0.7):anch(0, 0):pos(270, 50):addTo(techBg)
		ui.newTTFLabel({ text = string.format("x%d", phaseData.lingpaiNum), font = ChineseFont, size = 24, color = display.COLOR_WHITE })
			:anch(0, 0.5):pos(310, 65):addTo(techBg)
	elseif canPromote then
		ui.newTTFLabelWithStroke({ text = "已进阶到最高级", size = 20, color = uihelper.hex2rgb("#7ce800"), strokeColor = uihelper.hex2rgb("#242424")})
			:anch(0.5, 0):pos(xPos, 56):addTo(techBg)
	end

	local yOffset = toMoveUp and 35 or 0
	--科技名称
	ui.newTTFLabelWithStroke({ text = phaseData.name,font=ChineseFont , size = 24, color = uihelper.hex2rgb("#ffd200"), strokeColor = uihelper.hex2rgb("#242424") })
			:anch(0.5, 0):pos(xPos, 120 + yOffset):addTo(techBg)

	local xBegin = 90
	local xInterval = 49
	for index = 1, 4 do
		local res = index <= professionData[1] and "large_promote_active.png" or "large_promote_inactive.png"
		local levelBg = display.newSprite(TechRes .. res)
		levelBg:anch(0, 0):pos(xBegin + (index - 1) * xInterval, 90 + yOffset):addTo(techBg)
		local levelBgSize = levelBg:getContentSize()
		
		if index == params.phase then
			layer:stopAllActions()
			local s = layer:getScale()
			layer:setScale(s * 0.1)
			layer:setVisible(false)
			--效果
			local x = 220
			local y = 300
			local tName = {"card_change_test","card_change_test1","card_change_test2","card_change_test3","card_change_test4"}
			local particle = CCNodeExtend.extend(CCParticleSystemQuad:create(ParticleRes .. tName[5]..".plist"))
			particle:addTo(self.mainLayer, 10):pos(x, y)
			--法阵：
			self:bootActionShow()
			self.mainLayer:performWithDelay(function()
				layer:setVisible(true)
				layer:runAction(CCScaleTo:create(0.5, s))
				particle:removeFromParent()
				self:bootActionPurge()

			end, 2)

		end
	end

	-- 右边攻防血
	local xPos = 375
	local yBegin, yInterval = techBgSize.height - 15, 120
	for index = 1, 4 do
		local yPos = yBegin - (index - 1) * yInterval

		local attItemBg = display.newSprite(TechRes .. "att_item_bg.png")
		attItemBg:anch(0, 1):pos(xPos, yPos):addTo(techBg)
		local attItemBgSize = attItemBg:getContentSize()

		local yLeftUpPos = attItemBgSize.height - 50
		ui.newTTFLabel({ text = phaseData[attrResources[index].field],font=ChineseFont , size = 26, font = ChineseFont, color = uihelper.hex2rgb("#ffffff")})
			:anch(0, 0):pos(14, yLeftUpPos):addTo(attItemBg)

		if professionData[index + 1] < 4 then
			-- 令牌消耗数
			local lingpaiIcon = display.newSprite(GlobalRes .. "lingpai.png")
			lingpaiIcon:scale(0.7):anch(0, 0):pos(157, yLeftUpPos):addTo(attItemBg)
			local levelData = professionLevelCsv:getDataByLevel(self.profession, professionData[1], professionData[index + 1] + 1)
			ui.newTTFLabel({ text = string.format("x%d", levelData.lingpaiNum), font = ChineseFont, size = 22 })
				:anch(0, 0):pos(195, yLeftUpPos):addTo(attItemBg)

			-- 不同部位不同属性的加成描述
			-- 属性加成读取配表每一级的加成数值：levelData.restraintBonus，而不是加成总和：professionBonuses[index]
			if index == 4 then
				desc = string.format(attrResources[index].desc, profressionResources[phaseData.restraintProfression].ch)
			else
				desc = attrResources[index].desc
			end

			local yLeftBottomPos = 20
			local text = ui.newTTFLabel({ text = desc, size = 18, color = display.COLOR_WHITE })
				:anch(0, 0):pos(28, yLeftBottomPos):addTo(attItemBg)
			--	加成百分比描述
			local strFmt = "+%0.2f%%"
			if index == 4 then
				desc = string.format(strFmt, levelData.restraintBonus ) 
			elseif index == 3 then
				desc = string.format(strFmt, levelData.hpBonus)
			elseif index == 2 then
				desc = string.format(strFmt, levelData.defBonus)
			elseif index == 1 then
				desc = string.format(strFmt, levelData.atkBonus)
			end
			ui.newTTFLabel({ text = desc, size = 18, color = uihelper.hex2rgb("#7ce800")})
				:anch(0, 0):pos(text:getPositionX() + text:getContentSize().width, yLeftBottomPos):addTo(attItemBg)

			-- 升级按钮
			local levelUpBtn = DGBtn:new(TechRes, {"levelup_normal.png", "levelup_selected.png" },
				{
					priority = self.priority,
					callback = function() 
						if game.role.lingpaiNum < levelData.lingpaiNum then
							DGMsgBox.new({msgId = SYS_ERR_LINGPAI_NOT_ENOUGH, 
								button1Data = { text = "关闭"},
								button2Data = { text = "去商城",
									callback = function()
									local layer = ShopMainLayer.new({priority = self.priority - 10, choosedTab = 3})
										layer:getLayer():addTo(display.getRunningScene())	
									end
								}
							 })
						else
							local bin = pb.encode("SimpleEvent", { roleId = game.role.id, param1 = self.profession, param2 = index })
							game:sendData(actionCodes.TechLeveupRequest, bin)
							loadingShow()
							game:addEventListener(actionModules[actionCodes.TechLeveupResponse], function(event)
								loadingHide()
								local msg = pb.decode("SimpleEvent", event.data)

								game:playMusic(40)
								self:initMainLayer({ attrIndex = msg.param1, level = msg.param2 })
								return "__REMOVE__"
							end)
						end
					end,	
				})
			levelUpBtn:getLayer():anch(1, 0.5):pos(attItemBgSize.width - 10, attItemBgSize.height / 2):addTo(attItemBg)
			if index == 1 then self.guideBtn = levelUpBtn:getLayer() end
		else
			ui.newTTFLabel({ text = "升级完成", size = 18, color = uihelper.hex2rgb("#ffd200")})
				:anch(0, 0):pos(28, 20):addTo(attItemBg)
		end

		local xBegin, xInterval = 225, 34
		for levelIndex = 1, 4 do
			local res = levelIndex <= professionData[index + 1] and "level_active.png" or "level_inactive.png"
			local levelBg = display.newSprite(TechRes .. res)
			levelBg:anch(0, 0.5):pos(xBegin + (levelIndex - 1) * xInterval, attItemBgSize.height / 2):addTo(attItemBg)
			local levelBgSize = levelBg:getContentSize()
		
			if index == params.attrIndex and levelIndex == params.level then
				local particle = CCNodeExtend.extend(CCParticleSystemQuad:create(ParticleRes .. "tech_levelup.plist"))
				particle:addTo(levelBg, 10):pos(levelBgSize.width / 2, levelBgSize.height / 2)
				-- particle:setDuration(1)
			end
		end
	end
end

function TechPhaseLayer:actionByType(objNode,typeNum)
	-- print("职业类型 == ",typeNum)
	if objNode ~= nil then

		local x = objNode:getPositionX()
		local y = objNode:getPositionY()
		if tonumber(typeNum) == 3 then
			objNode:runAction(CCRepeatForever:create(transition.sequence({
				CCScaleTo:create(1.5, 1.1),
				CCScaleTo:create(1.5, 1.2),
			})))
		else
			objNode:runAction(CCRepeatForever:create(transition.sequence({
				CCMoveBy:create(1.5, ccp(0, 10)),
				CCMoveBy:create(1.5, ccp(0, -10))
			})))
		end
	end
end

function TechPhaseLayer:bootActionShow()
	if device.platform ~= "ios" then
		display.TEXTURES_PIXEL_FORMAT[FrameActRes .. "sunquan_skill.pvr.ccz"] = kCCTexture2DPixelFormat_RGBA4444
	else
		display.TEXTURES_PIXEL_FORMAT[FrameActRes .. "sunquan_skill.pvr.ccz"] = kCCTexture2DPixelFormat_PVRTC4
	end
	display.addSpriteFramesWithFile(FrameActRes .. "sunquan_skill.plist", FrameActRes .. "sunquan_skill.pvr.ccz")

	local framesTable = {}
	for index = 1, 5 do
		local frameId = string.format("%02d", index)
		framesTable[#framesTable + 1] = display.newSpriteFrame("sunquan_skill_" .. frameId .. ".png")
	end
	local panimate = display.newAnimation(framesTable, 1.0/20)

	local sprite = display.newSprite(framesTable[1])
	sprite:addTo(self.mainLayer):pos(225, 190)
	sprite:playAnimationForever(panimate)
	sprite:setScale(0.8)
	sprite:setScaleY(0.6)
	sprite:setTag(333)

end

function TechPhaseLayer:bootActionPurge()
	local sp = self.mainLayer:getChildByTag(333)
	if sp ~= nil then
		sp:removeFromParent()
	end
end 

function TechPhaseLayer:checkGuide(remove)
	game:addGuideNode({node = self.guideBtn, remove = remove,
		guideIds = {1204}
	})
end

function TechPhaseLayer:onExit()
	self:checkGuide(true)
	game:removeAllEventListenersForEvent(actionModules[actionCodes.TechLeveupResponse])
	game:removeAllEventListenersForEvent(actionModules[actionCodes.TechPhasePromoteResponse])
	game.role:removeEventListener("updateLingpaiNum", self.lingpaiValueHandler)
end

function TechPhaseLayer:onCleanup()
	armatureManager:dispose()
	display.removeUnusedSpriteFrames()
end

return TechPhaseLayer