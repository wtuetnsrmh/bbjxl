-- 装备强化界面
-- by yujiuhe
-- 2014.8.15

local GlobalRes = "resource/ui_rc/global/"
local EquipRes = "resource/ui_rc/equip/"
local HeroRes = "resource/ui_rc/hero/"

local EquipLevelUp = import(".EquipLevelUp")
local EquipChooseLayer = import(".EquipChooseLayer")
local EquipEvolutionLayer = import(".EquipEvolutionLayer")

local EquipPopLayer = class("EquipPopLayer", function(params) return display.newLayer(EquipRes .. "bg_popup.png") end)

function EquipPopLayer:ctor(params)

	params = params or {}

	self.priority = params.priority or -129
	self.equip = params.equip or require("datamodel.Equip").new({id = 0, type = params.type, level = 1, evolCount = 0, evolExp = 0})
	self.slot = params.slot or self.equip:getSlot()
	self.callback = params.callback
	self.flag = params.flag or 1
	self.hero = params.hero
	self.disable=params.disable or false
	self.playerLevel = params.playerLevel or game.role.level

	self:initUI()
	self:refreshContent()
end

function EquipPopLayer:initUI()
	-- 遮罩层
	self.size = self:getContentSize()
	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ 
		item = self, 
		priority = self.priority, 
		ObjSize = self.size, 
		clickOut = function() 
			self.mask:remove()
			self:purgeItemTaps()
		end })

end


function EquipPopLayer:getLayer()
	return self.mask:getLayer()
end

function EquipPopLayer:onEnter()
	self:checkGuide()
end

function EquipPopLayer:checkGuide()
	game:addGuideNode({node = self.intesifyBtn,
		guideIds = {1279}
	})
end

--左侧
function EquipPopLayer:refreshContent()
	if self.mainLayer then
		self.mainLayer:removeSelf()
		self.mainLayer = nil
	end
	self.mainLayer = display.newLayer()
		:addTo(self)

	local detailLayer = display.newLayer()
	local nHeight = 0
	detailLayer:size(self.size.width, 38)

	local width = 460
	local itemId = self.equip.type+Equip2ItemIndex.ItemTypeIndex
	local equipIcon = ItemIcon.new({itemId = itemId}):getLayer()
	equipIcon:anch(0, 1):pos(88, nHeight):addTo(detailLayer)
	local xPos = equipIcon:getContentSize().width + 50
	ui.newTTFLabelWithStroke({ text = self.equip:getName(), font = ChineseFont, size = 24, strokeColor = uihelper.hex2rgb("#1a1a1a") })
		:anch(0, 0):pos(xPos, 60):addTo(equipIcon)
	ui.newTTFLabelWithStroke({ text = string.format("Lv:%d/%d", self.equip.level, self.playerLevel*2), size = 20, strokeColor = uihelper.hex2rgb("#1a1a1a") })
		:anch(0, 0):pos(xPos, 25):addTo(equipIcon)

	-- 翻页
	if self.flag == 1 then
		local prevEquip, nextEquip, hasFound
		local equips = game.role.slots[tostring(self.slot)].equips or {}
		for index = 1, 6 do
			local tempEquipId = equips[index]
			if tempEquipId then
				if hasFound then print("nextEquip",tempEquipId) nextEquip =  game.role.equips[tempEquipId] break end
				if tempEquipId == tonum(self.equip.id) then hasFound = true end
				if not hasFound then print("prevEquip",tempEquipId) prevEquip =  game.role.equips[tempEquipId] end
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
			self.leftBtn:scale(0.8):rotation(180):anch(0.5, 0.5):pos(50, -40):addTo(detailLayer,2)
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
			self.rightBtn:scale(0.8):anch(0.5, 0.5):pos(self.size.width-50, -40):addTo(detailLayer,2)
		end
	end
	

	--属性
	local attBg = display.newScale9Sprite(EquipRes .. "bg_content.png", nil, nil, CCSizeMake(width, 106))
	attBg:anch(0.5, 1):pos(self.size.width / 2, nHeight-126):addTo(detailLayer)
	local attBgSize = attBg:getContentSize()
	display.newSprite(EquipRes .. "bg_title.png"):anch(0.5, 0.5):pos(attBgSize.width/2, attBgSize.height):addTo(attBg)
	ui.newTTFLabelWithStroke({ text = "当前属性", font = ChineseFont, size = 24, strokeColor = uihelper.hex2rgb("#63402c") })
		:anch(0.5, 0.5):pos(attBgSize.width/2, attBgSize.height):addTo(attBg)
	xPos = 39
	local attrs = self.equip:getBaseAttributes()
	local yPos, yInterval, count = attBgSize.height - 17, 22, 1
	for key, value in pairs(EquipAttEnum) do
		if count > 3 then break end
		if attrs[key] > 0 then
			count = count + 1
			local text = ui.newTTFLabel({ text = EquipAttName[value], size = 18, color = uihelper.hex2rgb("#000000") })
			text:anch(0, 1):pos(xPos, yPos):addTo(attBg)
			ui.newTTFLabel({ text = string.format("+%d", attrs[key]), size = 18, color = uihelper.hex2rgb("#14a800") })
				:anch(0, 1):pos(xPos + text:getContentSize().width + 5, yPos):addTo(attBg)
			yPos = yPos - yInterval
		end
	end

	--属性成长
	local attBg = display.newScale9Sprite(EquipRes .. "bg_content.png", nil, nil, CCSizeMake(width, 106))
	attBg:anch(0.5, 1):pos(self.size.width / 2, nHeight-258):addTo(detailLayer)
	local attBgSize = attBg:getContentSize()
	display.newSprite(EquipRes .. "bg_title.png"):anch(0.5, 0.5):pos(attBgSize.width/2, attBgSize.height):addTo(attBg)
	ui.newTTFLabelWithStroke({ text = "属性成长", font = ChineseFont, size = 24, strokeColor = uihelper.hex2rgb("#63402c") })
		:anch(0.5, 0.5):pos(attBgSize.width/2, attBgSize.height):addTo(attBg)
	xPos = 39
	local attrs = self.equip.csvData.attrs
	local yPos, yInterval, count = attBgSize.height - 17, 20, 1
	for key, value in pairs(EquipAttEnum) do
		if count > 3 then break end
		if attrs[value] then
			count = count + 1
			local text = ui.newTTFLabel({ text = EquipAttName[value], size = 18, color = uihelper.hex2rgb("#000000") })
			text:anch(0, 1):pos(xPos, yPos):addTo(attBg)
			ui.newTTFLabel({ text = string.format("+%d", attrs[value][2]), size = 18, color = uihelper.hex2rgb("#14a800") })
				:anch(0, 1):pos(xPos + text:getContentSize().width + 5, yPos):addTo(attBg)
			yPos = yPos - yInterval
		end
	end

	nHeight = -365

	--套装
	local setId = self.equip.csvData.setId
	if setId ~= 0 then
		local equipTypes = {}
		if self.slot and self.slot > 0 then
			local equips = game.role.slots[tostring(self.slot)].equips or {}
			for _, equipId in pairs(equips) do
				local equip = game.role.equips[equipId]
				table.insert(equipTypes, equip.type)
			end
		end

		local setData = equipSetCsv:getDataById(setId)
		local contentBg = display.newScale9Sprite(EquipRes .. "bg_content.png", nil, nil, CCSizeMake(width, 240))
		contentBg:anch(0.5, 1):pos(self.size.width / 2, nHeight-24):addTo(detailLayer)
		local conBgSize = contentBg:getContentSize()
		display.newSprite(EquipRes .. "bg_title.png"):anch(0.5, 0.5):pos(conBgSize.width/2, conBgSize.height):addTo(contentBg)
		ui.newTTFLabelWithStroke({ text = setData.name, font = ChineseFont, size = 24, strokeColor = uihelper.hex2rgb("#63402c") })
			:anch(0.5, 0.5):pos(conBgSize.width/2, conBgSize.height):addTo(contentBg)

		local equipCount = 0
		--详细罗列
		local xPos, xInterval = 36, 100
		for index=1, #(setData.equipIds) do
			local equipType = setData.equipIds[index]
			local hasEquip = table.find(equipTypes, equipType)
			if hasEquip then
				equipCount = equipCount + 1
			end
			local equipIcon = ItemIcon.new({
				itemId = equipType + Equip2ItemIndex.ItemTypeIndex, 
				gray = not hasEquip,
				priority = self.priority - 1,
				callback = function()
					self:showItemTaps(equipType + Equip2ItemIndex.ItemTypeIndex, hasEquip and 1 or 0)
				end}):getLayer()
			equipIcon:scale(0.8):anch(0, 1):pos(xPos, conBgSize.height - 26):addTo(contentBg)
		
			
			ui.newTTFLabel({ text = equipCsv:getDataByType(equipType).name, size = 18, color = uihelper.hex2rgb("#572c09") })
				:anch(0.5, 1):pos(xPos + 42, conBgSize.height - 113):addTo(contentBg)
			xPos = xPos + xInterval
		end

		--间隔线
		display.newSprite(EquipRes .. "interval_line.png")
			:anch(0.5, 0.5):pos(conBgSize.width/2, 96):addTo(contentBg)

		--详细描述
		local yPos, yInterval = 88, 25
		for row = 1, 3 do
			local actived = equipCount >= row + 1
			ui.newTTFLabel({ text = string.format("装备%d件：", row+1), size = 18, color = actived and uihelper.hex2rgb("#00a800") or uihelper.hex2rgb("##000000") })
				:anch(0, 1):pos(36, yPos):addTo(contentBg)
			local xPos, xInterval, count = 124, 102, 1
			local attrs = setData["effect" .. tostring(row+1)]
	
			for key, value in pairs(EquipAttEnum) do
				if count > 3 then break end
				if tonum(attrs[value]) > 0 then
					count = count + 1
					local text = ui.newTTFLabel({ text = string.format("%s+%d", EquipAttName[value], attrs[value]), size = 18, color = actived and uihelper.hex2rgb("#852d10") or uihelper.hex2rgb("#444444") })
					text:anch(0, 1):pos(xPos, yPos):addTo(contentBg)
					xPos = xPos + xInterval
				end
			end
			yPos = yPos - yInterval
		end
		nHeight = -620
	end

	--情缘
	if #self.equip.csvData.relationHeros > 0 then
		local bg = display.newSprite(EquipRes .. "bg_title.png"):anch(0.5, 1):pos(self.size.width / 2, nHeight - 20):addTo(detailLayer)
		ui.newTTFLabelWithStroke({ text = "情缘", font = ChineseFont, size = 24, strokeColor = uihelper.hex2rgb("#63402c") })
		:anch(0.5, 0.5):pos(bg:getContentSize().width/2, bg:getContentSize().height/2):addTo(bg)
		for index, heroType in ipairs(self.equip.csvData.relationHeros) do
			nHeight = nHeight - (index == 1 and 68 or 105)
			local relBg = display.newScale9Sprite(EquipRes .. "bg_content.png", nil, nil, CCSizeMake(width, 98))
			relBg:anch(0.5, 1):pos(self.size.width/2, nHeight):addTo(detailLayer)
			local relBgSize = relBg:getContentSize()
			HeroHead.new({type = heroType, hideStars = true}):getLayer()
				:scale(0.8):anch(0, 0.5):pos(15, relBgSize.height/2):addTo(relBg) 
			--找到对应的情缘
			local unitData = unitCsv:getUnitByType(heroType)
			local curRelaiton
			for _, relation in pairs(unitData.relation) do
				if relation[1] == 2 and table.find(relation[2], self.equip.type) then
					curRelaiton = relation
					break
				end
			end
			--情缘描述
			if curRelaiton then
				ui.newTTFLabel({text = unitData.name, size = 24, font = ChineseFont, color = uihelper.hex2rgb("#8a4908")})
					:anch(0, 0):pos(122, 52):addTo(relBg)
				ui.newTTFLabel({text = unitCsv:formatRelationDesc(curRelaiton), size = 18, color = uihelper.hex2rgb("#444444")})
					:anch(0, 0):pos(122, 19):addTo(relBg)
			end
		end
		nHeight = nHeight - 98
	end


	--描述
	nHeight = nHeight - 35
	local descBg = display.newScale9Sprite(EquipRes .. "bg_content.png", nil, nil, CCSizeMake(width, 106))
	descBg:anch(0.5, 1):pos(self.size.width / 2, nHeight):addTo(detailLayer)
	local descBgSize = descBg:getContentSize()
	display.newSprite(EquipRes .. "bg_title.png"):anch(0.5, 0.5):pos(descBgSize.width/2, descBgSize.height):addTo(descBg)
	ui.newTTFLabelWithStroke({ text = "简介", font = ChineseFont, size = 24, strokeColor = uihelper.hex2rgb("#63402c") })
		:anch(0.5, 0.5):pos(descBgSize.width/2, descBgSize.height):addTo(descBg)
	local itemData = itemCsv:getItemById(itemId)
	uihelper.createLabel({ text = itemData.desc, size = 18, color = uihelper.hex2rgb("#444444"), width = width - 40 })
		:anch(0, 1):pos(20, descBgSize.height - 25):addTo(descBg)
	nHeight = nHeight - 156

	local tempLayer = display.newLayer()
	tempLayer:size(CCSizeMake(width, math.abs(nHeight)))
	detailLayer:anch(0, 1):pos(0, math.abs(nHeight)):addTo(tempLayer)

	local detailScrollView = CCScrollView:create()

	detailScrollView:setViewSize(CCSizeMake(self.size.width, 455))
	detailScrollView:setContainer(tempLayer)
	detailScrollView:updateInset()
	detailScrollView:setContentOffset(ccp(0, 480 - math.abs(nHeight)))
	detailScrollView:setPosition(ccp(0, 90))
	detailScrollView:ignoreAnchorPointForPosition(true)
	detailScrollView:setDirection(kCCScrollViewDirectionVertical)
	detailScrollView:setBounceable(true)
	detailScrollView:setTouchPriority(self.priority - 2)

	self.mainLayer:addChild(detailScrollView)
	
	if self.equip.id ~= 0 then
		local evolRes = self.flag == 1 and {"btn_green_nol.png", "btn_green_sel.png", "middle_disabled.png"} or {"middle_normal.png", "middle_selected.png", "middle_disabled.png"}
		--强化按钮
		local intesifyBtn =	DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png", "middle_disabled.png"}, 
				{
					text = {text = "强化", size = 24, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
					priority = self.priority -1,
					disable=self.disable,
					callback = function()
						local layer = EquipLevelUp.new({equip = self.equip, priority = self.priority,flag = self.flag, slot = self.slot, callback = self.callback})
						layer:getLayer():addTo(display.getRunningScene())
						self.mask:remove()		
					end,
				}):getLayer()
		self.intesifyBtn = intesifyBtn
		--炼化按钮
		local evolBtn = DGBtn:new(GlobalRes, evolRes, 
				{
					text = {text = "炼化", size = 24, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
					priority = self.priority -1,
					disable=self.disable,
					callback = function()
						local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
						if roleInfo.equipEvolOpen < 0 then
							DGMsgBox.new({text = string.format("玩家%d级开放装备炼化", math.abs(roleInfo.equipEvolOpen)), type = 1})
							return
						end
						local layer = EquipEvolutionLayer.new({equip = self.equip, priority = self.priority - 1, callback = self.callback})
						layer:getLayer():addTo(display.getRunningScene())
						self.mask:remove()		
					end,
				}):getLayer()
		if self.flag == 1 then
			--更换按钮
			DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png", "middle_disabled.png"}, {
					text = {text = "更换",size = 24, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
					priority = self.priority - 1,
					disable=self.disable,
					callback = function()
						local layer = EquipChooseLayer.new({priority = self.priority - 10, slot = self.slot, hero = self.hero,
							equipSlot = self.equip.csvData.equipSlot, equipId = self.equip.id, callback = self.callback})
						layer:getLayer():addTo(display.getRunningScene())

						self.mask:remove()	
					end,
				}):getLayer():anch(0.5, 0):pos(self.size.width/4 - 15, 20):addTo(self.mainLayer)

			evolBtn:anch(0.5, 0):pos(self.size.width/4 * 2, 20):addTo(self.mainLayer)
			intesifyBtn:anch(0.5, 0):pos(self.size.width/4 * 3 + 15, 20):addTo(self.mainLayer)
		else
			evolBtn:anch(0.5, 0):pos(self.size.width/3, 20):addTo(self.mainLayer)
			intesifyBtn:anch(0.5, 0):pos(self.size.width/3 * 2, 20):addTo(self.mainLayer)
		end
	end
end

function EquipPopLayer:showItemTaps(itemId, itemNum)

	self:purgeItemTaps()
	local itemTipsView = require("scenes.home.ItemTipsLayer")
	local itemTips = itemTipsView.new({
		itemId = itemId,
		itemNum = itemNum,
		itemType = ItemTypeId.Equip,
		})
	display.getRunningScene():addChild(itemTips:getLayer())
	itemTips:setTag(1000)

end

function EquipPopLayer:purgeItemTaps()
	if display.getRunningScene():getChildByTag(1000) then
		display.getRunningScene():getChildByTag(1000):removeFromParent()
	end
end


return EquipPopLayer