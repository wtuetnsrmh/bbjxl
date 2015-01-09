local TechRes = "resource/ui_rc/tech_new/"
local GlobalRes = "resource/ui_rc/global/"
local ParticleRes = "resource/ui_rc/particle/"
local HomeRes = "resource/ui_rc/home/"
local PvpRes = "resource/ui_rc/pvp/"

local TechPhaseLayer = import(".TechPhaseLayer")
local ShopMainLayer = import("..shop.ShopMainLayer")
local TopBarLayer = require("scenes.TopBarLayer")
local ConfirmDialog = require("scenes.ConfirmDialog")

local profressionResources = {
	[1] = { name = "bu", ch = "步兵" },
	[3] = { name = "qi", ch = "骑兵" },
	[4] = { name = "gong", ch = "弓兵" },
	[5] = { name = "jun", ch = "军师" },
}

local attrResources = {
	[1] = { name = "攻击", res = "atk_slot.png" },
	[2] = { name = "防御", res = "def_slot.png" },
	[3] = { name = "生命", res = "hp_slot.png" },
}

local TechHomeLayer = class("TechHomeLayer", function()
	return display.newLayer(GlobalRes .. "inner_bg.png")
end)

function TechHomeLayer:ctor(params)
	params = params or {}
	self.priority = params.priority or -130
	self.closeCB = params.closeCB

	self.size = self:getContentSize()
	self.parent = params.parent
	
	self:pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1, bg = HomeRes .. "home.jpg" })


    -- 右侧按钮
	local chooseTab = display.newSprite(GlobalRes .. "tab_selected.png"):anch(0, 0.5)
	chooseTab:pos(self.size.width - 14, 470):addTo(self)
	display.newSprite(GlobalRes .. "tab_arrow.png")
		:anch(0, 0.5):pos(self.size.width - 25, 470):addTo(self,100)
	local tabSize = chooseTab:getContentSize()
	ui.newTTFLabelWithStroke({ text = "科技", dimensions = CCSizeMake(tabSize.width / 2, tabSize.height), size = 26, font = ChineseFont,
		color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(tabSize.width / 2, tabSize.height / 2):addTo(chooseTab)

	-- 右侧按钮
	local washBtn = DGBtn:new(GlobalRes, {"vertical_normal.png", "vertical_selected.png", "vertical_disabled.png"},
		{	
			priority = self.priority,
			touchScale = { 2, 1 },
			callback = function()
				local confirmDialog = ConfirmDialog.new({
					priority = self.priority - 10,
					showText = { text = string.format("是否消耗%d元宝洗点", globalCsv:getFieldValue("washTechNeedYuanbao")), size = 24, font = ChineseFont, color = display.COLOR_YELLOW },
					button2Data = {
						callback = function()
							local bin = pb.encode("SimpleEvent", { roleId = game.role.id })
							game:sendData(actionCodes.TechWashPointRequest, bin)
							game:addEventListener(actionModules[actionCodes.TechWashPointResponse], function(event)
								self:refresh()
								return "__REMOVE__"
							end)
						end,
					}
				})
				confirmDialog:getLayer():addTo(display.getRunningScene())
			end,
		}):getLayer()
	washBtn:anch(0, 0.5):pos(self.size.width - 13, 360):addTo(self)
	local tabSize = washBtn:getContentSize()
	ui.newTTFLabelWithStroke({ text = "洗点", dimensions = CCSizeMake(tabSize.width / 2, tabSize.height), size = 26, font = ChineseFont,
		color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(tabSize.width / 2, tabSize.height / 2):addTo(washBtn)

	-- 关闭按钮
	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"}, {
		touchScale = 1.5,
		priority = self.priority,
		callback = function()
			if self.closeCB then self.closeCB() end
			if self.layer == "home" then
				self:getLayer():removeSelf()
			elseif self.layer == "phase" then
				self.guideBtn = nil
				self:initHomeLayer()
			end
		end,
	}):getLayer()
	closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self,100)

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

    self:initHomeLayer()

    local layer  = TopBarLayer.new({priority = self.priority})
	layer:anch(0,1):pos(0,display.height):addTo(self)
end

function TechHomeLayer:checkGuide(remove)
	game:addGuideNode({node = self.guideBtn, remove = remove,
		guideIds = {1203}
	})
end

function TechHomeLayer:initHomeLayer(params)
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end

	self.layer = "home"
	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.size)

	local bgSize = self.mainLayer:getContentSize()
	self.mainLayer:anch(0.5, 0.5):pos(self.size.width / 2, self.size.height / 2):addTo(self)

	local xBegin = 28
	local xInterval = (bgSize.width - 2 * xBegin - 4 * 209) / 3
	local professionIds = { 1, 3, 4, 5 }
	for index, profession in ipairs(professionIds) do
		local professionItem = self:createProfessionItem(profession, params, index)
		professionItem:anch(0, 0):pos(xBegin + (index - 1) * (xInterval + 209), 22):addTo(self.mainLayer)
	end 
end

function TechHomeLayer:initPromoteLayer(params)
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end

	self.layer = "phase"
	self.curProfession = params.refresh and self.curProfession or params.profession

	self.mainLayer = TechPhaseLayer.new({ profession = self.curProfession, priority = self.priority })
	self.mainLayer:anch(0.5, 0.5):pos(self.size.width / 2, self.size.height / 2):addTo(self)
end

function TechHomeLayer:refresh()
	if self.layer == "home" then
		self:initHomeLayer()
	elseif self.layer == "phase" then
		self:initPromoteLayer({ refresh = true, priority = self.priority })
	end
end

function TechHomeLayer:createProfessionItem(profession, params, index)
	params = params or {}

	local professionBg = display.newSprite(TechRes .. "profession_bg.png")
	local bgSize = professionBg:getContentSize()

	local professionRes = profressionResources[profession]
	local professionData = game.role.professionBonuses[profession]
	local professionBonuses = game.role:getProfessionBonus(profession)
	local phaseData = professionPhaseCsv:getDataByPhase(profession, professionData[1])

	local levelSum = professionData[2] + professionData[3] + professionData[4] + professionData[5]
	local canPromote = (levelSum == 16) and game.role.lingpaiNum >= phaseData.lingpaiNum

	--武器：
	local professionIconRes = string.format("%s_lv%d.png", professionRes.name, professionData[1])
	local icon = display.newSprite(TechRes .. professionIconRes):scale(1):pos(bgSize.width / 2, bgSize.height - 100):addTo(professionBg)
	self:actionByType(icon,profession)
	if canPromote and professionData[1] < 4 then
		local promoteBtn = DGBtn:new(TechRes, {"levelup_normal.png", "levelup_selected.png"},
			{
				priority = self.priority,
				callback = function() 
					local bin = pb.encode("SimpleEvent", { roleId = game.role.id, param1 = profession })
					game:sendData(actionCodes.TechPhasePromoteRequest, bin)
					game:addEventListener(actionModules[actionCodes.TechPhasePromoteResponse], function(event)
						local msg = pb.decode("SimpleEvent", event.data)
						game:playMusic(41)
						self:initHomeLayer({ profession = msg.param1, phase = msg.param2 })

						return "__REMOVE__"
					end)

				end,	
			}):getLayer()
		promoteBtn:pos(0, bgSize.height - promoteBtn:getContentSize().height):addTo(professionBg)
	end

	display.newSprite(TechRes.."bg_type.png"):anch(0,0.5):pos(15,bgSize.height - 205):addTo(professionBg)
	ui.newTTFLabel({ text = professionRes.ch,font=ChineseFont , size = 22, color = uihelper.hex2rgb("#ffffff") })
		:anch(0, 0):pos(25, bgSize.height - 220):addTo(professionBg)
	ui.newTTFLabel({ text = string.format("lv.%d", professionData[1]), size = 20, color = uihelper.hex2rgb("#ffd200") })
		:anch(0, 0):pos(78, bgSize.height - 220):addTo(professionBg)

	local helpBtn = DGBtn:new(TechRes, {"help_normal.png", "help_selected.png"},
		{	
			priority = self.priority,
			touchScale = {3, 3},
			callback = function() 
				-- 弹出框
				local layer = ConfirmDialog.new({
					priority = self.priority - 10,
					showText = { text = phaseData.helpInfo, size = 22,},
				})
				layer:getLayer():addTo(display.getRunningScene())
			end,
		}):getLayer()
	helpBtn:anch(0, 0):pos(162, bgSize.height - 220):addTo(professionBg)

	local yBegin, yInterval = bgSize.height - 260, 32
	for index, resData in ipairs(attrResources) do
		local nameLabel = ui.newTTFLabelWithStroke({ text = resData.name, size = 18,color=display.COLOR_WHITE, strokeColor = display.COLOR_BUTTON_STROKE})
		nameLabel:anch(0, 0.5):pos(14, yBegin - (index - 1) * yInterval):addTo(professionBg)

		local bonusValue = ui.newTTFLabelWithStroke({ text = string.format("%d%%", professionBonuses[index]), 
			size = 18,color=uihelper.hex2rgb("#7ce810"), strokeColor = display.COLOR_BUTTON_STROKE})
		bonusValue:anch(0, 0.5):pos(61, yBegin - (index - 1) * yInterval):addTo(professionBg)

		local xPos = 110
		for i = 1, math.floor(professionBonuses[index] / 6.25) do
			display.newSprite(TechRes .. resData.res)
				:anch(0, 0.5):pos(xPos + (i - 1) * 10, yBegin - (index - 1) * yInterval):addTo(professionBg)
		end
	end

	local nameLabel = ui.newTTFLabelWithStroke({ text = "克制伤害加成", size = 18,color=display.COLOR_WHITE,
	 strokeColor = display.COLOR_BUTTON_STROKE})
	nameLabel:anch(0, 0.5):pos(14, yBegin - 3 * yInterval):addTo(professionBg)

	local bonusValue = ui.newTTFLabelWithStroke({ text = string.format("+%d%%", professionBonuses[4]), 
		size = 18, color = uihelper.hex2rgb("#7ce810"), strokeColor = display.COLOR_BUTTON_STROKE })
	bonusValue:anch(0, 0.5):pos(136, yBegin - 3 * yInterval):addTo(professionBg)

	local xBegin = 18
	local xInterval = 39
	for index = 1, 4 do 
		local res = index <= professionData[1] and "promote_active.png" or "promote_inactive.png"
		local levelBg = display.newSprite(TechRes .. res)
		levelBg:anch(0, 0.5):pos(xBegin + (index - 1) * xInterval, 95):addTo(professionBg)
		local levelBgSize = levelBg:getContentSize()
		
		if profession == params.profession and index == params.phase then
			local particle = CCNodeExtend.extend(CCParticleSystemQuad:create(ParticleRes .. "tech_phase.plist"))
			particle:addTo(levelBg, 10):pos(levelBgSize.width / 2, levelBgSize.height / 2)
			-- particle:setDuration(1)
		end
	end

	local enterPhaseBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png"},
		{	
			text = { text = "进入", size = 26, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT },
			priority = self.priority,
			callback = function() 
				self:initPromoteLayer({ profession = profession })
			end,
		}):getLayer()
	enterPhaseBtn:anch(0.5, 0):pos(bgSize.width / 2, 15):addTo(professionBg)
	if index == 1 then
		self.guideBtn = enterPhaseBtn
	end

	return professionBg
end

function TechHomeLayer:actionByType(objNode,typeNum)
	if objNode ~= nil then

		local x = objNode:getPositionX()
		local y = objNode:getPositionY()
		if tonumber(typeNum) == 3 then
			objNode:runAction(CCRepeatForever:create(transition.sequence({
				CCScaleTo:create(1.5, 1),
				CCScaleTo:create(1.5, 0.95),
			})))
		else
			objNode:runAction(CCRepeatForever:create(transition.sequence({
				CCMoveBy:create(1.5, ccp(0, 10)),
				CCMoveBy:create(1.5, ccp(0, -10))
			})))
		end
	end
end


function TechHomeLayer:getLayer()
	return self.mask:getLayer()
end

function TechHomeLayer:onEnter()
	self.parent:hide()
	self:checkGuide()
end

function TechHomeLayer:onExit()
	self.parent:show()
	self:checkGuide(true)
end

function TechHomeLayer:onCleanup()
    display.removeUnusedSpriteFrames()
    game.role:removeEventListener("updateLingpaiNum", self.lingpaiValueHandler)
end

return TechHomeLayer