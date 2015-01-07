-- 装备强化界面
-- by yujiuhe
-- 2014.8.15

local GlobalRes = "resource/ui_rc/global/"
local EquipRes = "resource/ui_rc/equip/"
local HeroRes = "resource/ui_rc/hero/"

local EquipLevelUp = class("EquipLevelUp", function(params) return display.newLayer(EquipRes .. "bg_popup.png") end)

function EquipLevelUp:ctor(params)

	params = params or {}

	self.priority = params.priority or -129
	self.equip = params.equip
	self.callback = params.callback
	self.flag = params.flag or 0
	self.slot = params.slot or self.equip:getSlot()

	self:initUI()
	self:refreshContent()
end

function EquipLevelUp:initUI()
	-- 遮罩层
	self.size = self:getContentSize()
	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self , priority = self.priority, ObjSize = self.size, clickOut = function()
		if self.callback then 
			self.callback()
		end  
		self.mask:remove()
	end })

end

function EquipLevelUp:onEnter()
	self:checkGuide()
end

function EquipLevelUp:checkGuide(remove)
	game:addGuideNode({node = self.multiIntesifyBtn, remove = remove,
		guideIds = {1103, 1104, 1105, 1106}
	})
end

function EquipLevelUp:onExit()
	self:checkGuide(true)
end

function EquipLevelUp:getLayer()
	return self.mask:getLayer()
end

--左侧
function EquipLevelUp:refreshContent()
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end

	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.size):addTo(self)

	self.equipIcon = ItemIcon.new({itemId = self.equip.type+Equip2ItemIndex.ItemTypeIndex}):getLayer()
	self.equipIcon:anch(0, 1):pos(88, self.size.height - 38):addTo(self.mainLayer, 100)
	local xPos = self.equipIcon:getContentSize().width + 50
	ui.newTTFLabelWithStroke({ text = self.equip:getName(), font = ChineseFont, size = 24 })
		:anch(0, 0):pos(xPos, 60):addTo(self.equipIcon)
	ui.newTTFLabel({ text = string.format("Lv:%d/%d", self.equip.level, game.role.level*2), size = 20, color = uihelper.hex2rgb("#572c09") })
		:anch(0, 0):pos(xPos, 25):addTo(self.equipIcon)

	-- 翻页
	if self.flag == 1 then
		local prevEquip, nextEquip, hasFound
		local equips = game.role.slots[tostring(self.slot)].equips or {}
		for index = 1, 6 do
			local tempEquipId = equips[index]
			if tempEquipId then
				if hasFound then nextEquip =  game.role.equips[tempEquipId] break end
				if tempEquipId == tonum(self.equip.id) then hasFound = true end
				if not hasFound then prevEquip =  game.role.equips[tempEquipId] end
			end
		end

		if prevEquip then
			self.leftBtn = DGBtn:new(HeroRes, {"switch_normal.png", "switch_selected.png"},
				{
					touchScale = {2, 2},
					priority = self.priority-1,
					callback = function()
						if prevEquip then
							self.equip = prevEquip
							self:refreshContent()
						end
					end,
				}):getLayer()
			self.leftBtn:scale(0.8):rotation(180):anch(0.5, 0.5):pos(50, 494):addTo(self.mainLayer,102)
		end

		if nextEquip then
			self.rightBtn = DGBtn:new(HeroRes, {"switch_normal.png", "switch_selected.png"},
				{
					touchScale = {2, 2},
					priority = self.priority-1,
					callback = function()
						if nextEquip then
							self.equip = nextEquip
							self:refreshContent()
						end
					end,
				}):getLayer()
			self.rightBtn:scale(0.8):anch(0.5, 0.5):pos(self.size.width-50, 494):addTo(self.mainLayer,102)
		end
	end

	--内容
	local contentBg = display.newScale9Sprite(EquipRes .. "bg_content.png", nil, nil, CCSizeMake(460, 210))
	contentBg:anch(0.5, 0):pos(self.size.width / 2, 180):addTo(self.mainLayer)
	local conBgSize = contentBg:getContentSize()
	display.newSprite(EquipRes .. "bg_title.png"):anch(0.5, 0.5):pos(conBgSize.width/2, conBgSize.height):addTo(contentBg)
	ui.newTTFLabelWithStroke({ text = "强化预览", font = ChineseFont, size = 24, strokeColor = uihelper.hex2rgb("#63402c") })
		:anch(0.5, 0.5):pos(conBgSize.width/2, conBgSize.height):addTo(contentBg)

	--当前属性
	xPos = 52
	ui.newTTFLabel({ text = "当前属性:", size = 22, font = ChineseFont, color = uihelper.hex2rgb("#572c09") })
		:anch(0, 1):pos(xPos, conBgSize.height - 44):addTo(contentBg)
	local attrs = self.equip:getBaseAttributes()
	local yPos, yInterval = 110, 20
	for key, value in pairs(EquipAttEnum) do
		if attrs[key] > 0 then
			local text = ui.newTTFLabel({ text = EquipAttName[value], size = 18, color = uihelper.hex2rgb("#444444") })
			text:anch(0, 0):pos(xPos, yPos):addTo(contentBg)
			ui.newTTFLabel({ text = string.format("+%d", attrs[key]), size = 18, color = uihelper.hex2rgb("#14a800") })
				:anch(0, 0):pos(xPos + text:getContentSize().width + 5, yPos):addTo(contentBg)
			yPos = yPos - yInterval
		end
	end

	--箭头
	display.newSprite(EquipRes .. "arrow.png"):anch(0.5, 0.5):pos(conBgSize.width/2, conBgSize.height/2):addTo(contentBg)

	--升级属性
	xPos, yPos = 304, 110
	local isLevelMax = self.equip.level >= game.role.level * 2
	local level = isLevelMax and self.equip.level or self.equip.level + 1 
	ui.newTTFLabel({ text = "升级后属性:", size = 22, font = ChineseFont, color = uihelper.hex2rgb("#572c09") })
		:anch(0, 1):pos(xPos, conBgSize.height - 44):addTo(contentBg)
	attrs = self.equip:getBaseAttributes(level)
	for key, value in pairs(EquipAttEnum) do
		if attrs[key] > 0 then
			local text = ui.newTTFLabel({ text = EquipAttName[value], size = 18, color = uihelper.hex2rgb("#444444") })
			text:anch(0, 0):pos(xPos, yPos):addTo(contentBg)
			ui.newTTFLabel({ text = string.format("+%d", attrs[key]), size = 18, color = uihelper.hex2rgb("#14a800") })
				:anch(0, 0):pos(xPos + text:getContentSize().width + 5, yPos):addTo(contentBg)
			yPos = yPos - yInterval
		end
	end

	local levelCount = 10
	--银币消耗
	if isLevelMax then
		local costBg = display.newScale9Sprite(EquipRes .. "bg_content.png", nil, nil, CCSizeMake(460, 48))
		costBg:anch(0.5, 0):pos(self.size.width / 2, 130):addTo(self.mainLayer)
		ui.newTTFLabel({ text = "已达到目前最高强化等级", size = 18, color = uihelper.hex2rgb("#14a800") })
			:anch(0.5, 0.5):pos(costBg:getContentSize().width/2, costBg:getContentSize().height/2):addTo(costBg)
	else
		for index = 1, 2 do
			local costBg = display.newSprite(GlobalRes .. "label_bg.png")
			costBg:anch(0.5, 0):pos(index==1 and 152 or 396, 116):addTo(self.mainLayer)
			
			local cost = ui.newTTFLabel({ text = "消耗：", size = 22, font = ChineseFont })
			cost:anch(0, 0.5):addTo(costBg)
			local width = cost:getContentSize().width
			local count = index == 1 and 1 or levelCount
			local costMoney = 0
			for i = 1, count do
				local level = self.equip.level + i
				if level > game.role.level * 2 then
					break
				end
				local costInfo = equipLevelCostCsv:getDataByLevel(level)
				costMoney = costMoney + ((isLevelMax or not costInfo) and 0 or costInfo.cost[self.equip.csvData.star])
			end
			local text = ui.newTTFLabel({text = costMoney, size = 18, color = costMoney <= game.role.money and uihelper.hex2rgb("#7ce810") or display.COLOR_RED})
			text:anch(0, 0):pos(width, 0):addTo(cost)
			width = width + text:getContentSize().width + 6
			local sprite = display.newSprite(GlobalRes .. "yinbi_big.png")
			sprite:anch(0, 0.5):pos(width, cost:getContentSize().height/2):addTo(cost)
			width = width + sprite:getContentSize().width
			cost:pos((costBg:getContentSize().width - width)/2, costBg:getContentSize().height/2)
		end
	end

	--强化按钮
	DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png", "middle_disabled.png"}, {
			text = {text = "强化", size = 24, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			priority = self.priority -1,
			callback = function()
				self:intensify(1)	
			end,
		}):getLayer():anch(0.5, 0):pos(152, 37):addTo(self.mainLayer)
	--自动强化按钮
	self.multiIntesifyBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png", "middle_disabled.png"}, {
			text = {text = string.format("强化%d次", levelCount), size = 24, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			priority = self.priority -1,
			callback = function()
				self:intensify(levelCount)	
			end,
		}):getLayer():anch(0.5, 0):pos(396, 37):addTo(self.mainLayer)

	self:checkGuide()
end

function EquipLevelUp:intensify(flag)
	if self.equip.level >= game.role.level * 2 then 
		DGMsgBox.new({type = 1, text = "已达到目前最高强化等级"})
		self.intensifyNum=0
		return 
	end

	local bin = pb.encode("SimpleEvent", {roleId = game.role.id, param1 = self.equip.id, param2 = flag})
	game:sendData(actionCodes.EquipIntensifyRequest, bin)
	showMaskLayer()
    game:addEventListener(actionModules[actionCodes.EquipIntensifyResponse], function(event)
    	hideMaskLayer()
    	local msg = pb.decode("EquipLevelUpData", event.data)  	
    	if self.equip.level ~= msg.level then
    		local mask = showMaskLayer({delay = 30, click = function()
    			self.equip.level = msg.level
		    	self:refreshContent() 
    			hideMaskLayer() 
    		end})
    			
    		local count = 0

    		local onEffectEnd 
    		onEffectEnd = function()
	    		count = count + 1
	    		if count <= msg.count then
	    			self:showEffect(msg.crit[count], onEffectEnd, mask)
	    		else
	    			hideMaskLayer()
	    		end 
	    	end
		    onEffectEnd()
	    end
	    
    	return "__REMOVE__"
    end)
end

function EquipLevelUp:showEffect(crit, onEffectEnd, mask)
	local worldPos = self.equipIcon:convertToWorldSpace(ccp(0, 0))


	local showIntsifyText = function()
		local seq = {
			CCScaleTo:create(0, 15),
			CCScaleTo:create(0.2, 0.7),
			CCScaleTo:create(0.1, 1.2),
			CCScaleTo:create(0.1, 0.8),
			CCScaleTo:create(0.1, 1),
			CCScaleTo:create(0.1, 0.9),
			CCDelayTime:create(0.4),
			CCRemoveSelf:create(),
			CCCallFunc:create(function()
				onEffectEnd()
			end),
		}
		if crit > 1 then
			local critSprite = display.newSprite(EquipRes .. "intensify_crit.png")
			critSprite:pos(display.cx, display.cy + 190):addTo(mask)
			local levelUpSprite = display.newSprite(EquipRes .. "levelup.png")
			display.newSprite(EquipRes .. string.format("levelup_text_%d.png", crit))
				:pos(150, levelUpSprite:getContentSize().height/2):addTo(levelUpSprite)
			levelUpSprite:pos(critSprite:getContentSize().width/2, -50):addTo(critSprite)
			critSprite:runAction(transition.sequence(seq))
		else
			local successSprite = display.newSprite(EquipRes .. "intensify_success.png")
			successSprite:pos(display.cx, display.cy + 100):addTo(mask)
			successSprite:runAction(transition.sequence(seq))
		end
		local oldAttrs = self.equip:getBaseAttributes()
		self.equip.level = self.equip.level + crit
		self:refreshContent()
		uihelper.sShowAttrsChange({curAttrs = self.equip:getBaseAttributes(), oldAttrs = oldAttrs, fontSize = 48})
	end

	local showHammerEffet = function()
		local anim = uihelper.loadAnimation(EquipRes, "qhtx", 8,16)
		anim.sprite:scale(2):anch(0.5, 0.5):pos(worldPos.x + self.equipIcon:getContentSize().width/2 + 15, worldPos.y + self.equipIcon:getContentSize().height/2 - 80):addTo(mask)
		anim.sprite:runAction(transition.sequence({
			CCAnimate:create(anim.animation),
			CCRemoveSelf:create(),
			CCCallFunc:create(showIntsifyText)
			}))
		game:playMusic(44)
	end
	
	local hammer = display.newSprite(EquipRes .. "hammer.png")
	hammer:anch(0.15, 0):rotation(-70):pos(worldPos.x+150, worldPos.y+20):addTo(mask)
	hammer:runAction(transition.sequence({
		CCRotateTo:create(0.1, 20),
		CCRotateTo:create(0.1, -70),
		CCRemoveSelf:create(),
		CCCallFunc:create(showHammerEffet)
		}))
end

return EquipLevelUp