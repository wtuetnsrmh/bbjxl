local EquipRes = "resource/ui_rc/equip/"
local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"

local EquipEvolutionLayer = class("EquipEvolutionLayer", function(params)
	return display.newLayer(GlobalRes .. "rule/rule_bg.png")
end)

function EquipEvolutionLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -132
	self.equip = params.equip
	self.size = self:getContentSize()
	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self , priority = self.priority, ObjSize = self.size, clickOut = function()
		if params.callback then 
			params.callback(1)
		end  
		self.mask:remove()
	end })

	self:prepareData()
	self:initMaterialNode()
	self:initUI()
end

function EquipEvolutionLayer:prepareData()
	self.nextEvolCount = math.min(self.equip.evolCount + 1, EQUIP_MAX_EVOL)
	self.addExp = 0
	self.costMoney = 0
	self.returnMoney = 0
	self.maxExp = self.equip:getEvolMaxExp()
	self.selectMaterial = {}
	--获得数据
	self.material = {}
	for id, equip in pairs(game.role.equips) do
		if id ~= self.equip.id and equip.masterId == 0 then
			local data = {}
			data.id = id
			data.isFrag = false
			data.itemId = equip.type + Equip2ItemIndex.ItemTypeIndex
			data.level = equip.level
			data.exp = equip:getOfferExp()
			data.evolCount = equip.evolCount
			data.returnMoney = equip:getLevelReturnMoney()
			data.isSelected = false
			data.costMoney = data.exp * globalCsv:getFieldValue("equipEvolPerCost")
			table.insert(self.material, data)
		end
	end

	for id, num in pairs(game.role.equipFragments) do
		local data = {}
		local csvData = equipCsv:getDataByType(id - Equip2ItemIndex.FragmentTypeIndex)
		data.id = id
		data.isFrag = true
		data.itemId = id
		data.exp = csvData.offerExp / csvData.composeNum * num
		data.evolCount = 0
		data.level = num
		data.returnMoney = 0
		data.isSelected = false
		data.costMoney = data.exp * globalCsv:getFieldValue("equipEvolPerCost")
		table.insert(self.material, data)
	end

	table.sort(self.material, function(a, b)
		local itemDataA = itemCsv:getItemById(a.itemId)
		local itemDataB = itemCsv:getItemById(b.itemId)
		local factorA = itemDataA.stars * 1000000 + a.itemId - a.exp
		local factorB = itemDataB.stars * 1000000 + b.itemId - b.exp
		return factorA < factorB
	end)
end

--刷新除了原料以外的界面
function EquipEvolutionLayer:initUI()
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end
	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.size):addTo(self)
	--武器icon
	local iconBg = display.newSprite(EquipRes .. "icon_bg.png")
	iconBg:anch(0, 1):pos(44, self.size.height - 13):addTo(self.mainLayer)
	self.icon = ItemIcon.new({itemId = self.equip.type + Equip2ItemIndex.ItemTypeIndex}):getLayer()
	self.icon:scale(1):anch(0.5, 0):pos(iconBg:getContentSize().width/2, 24):addTo(iconBg)
	--属性
	local attrBg = display.newSprite(EquipRes .. "evol_attr_bg.png")
	attrBg:anch(1, 1):pos(self.size.width - 10, self.size.height - 33):addTo(self.mainLayer)
	local xPos1, xPos2, xPos3 = 145, 340, 420
	local yPos, yInterval = 106, 44
	
	--武器属性
	local curAttrs = self.equip:getBaseAttributes()
	local nextAttrs = self.equip:getBaseAttributes(nil, self.nextEvolCount)
	local count = 1
	for key, value in pairs(EquipAttEnum) do
		if count > 2 then break end
		if curAttrs[key] > 0 then		
			local yPos = yPos - yInterval * count
			--属性名称
			ui.newTTFLabelWithStroke({text = EquipAttName[value], size = 20, color = uihelper.hex2rgb("#ffd200"), strokeColor = display.COLOR_FONT, font = ChineseFont})
				:anch(0, 0.5):pos(xPos1, yPos):addTo(attrBg)
			--当前属性
			ui.newTTFLabel({text = curAttrs[key], size = 20})
				:anch(0, 0.5):pos(xPos1 + 83, yPos):addTo(attrBg)
			--升阶后属性
			ui.newTTFLabel({text = nextAttrs[key], size = 20, color = uihelper.hex2rgb("#62f619")})
				:anch(0, 0.5):pos(xPos3, yPos):addTo(attrBg)
			count = count + 1
		end
	end
	for index = 1, count do
		--箭头
		display.newSprite(GlobalRes .. "number_arrow.png")
			:pos(xPos2, yPos - yInterval * (index - 1)):addTo(attrBg)
		--名称
		if index == 1 then
			local name = ui.newTTFLabelWithStroke({text = self.equip.csvData.name, size = 24, strokeColor = display.COLOR_FONT, font = ChineseFont})
				:anch(0, 0.5):pos(xPos1, yPos):addTo(attrBg)

			ui.newTTFLabel({text = "+" .. self.equip.evolCount, size = 26, color = uihelper.hex2rgb("#62f619"), font = ChineseFont})
				:anch(0, 0.5):pos(name:getContentSize().width + 5, name:getContentSize().height/2):addTo(name)

			ui.newTTFLabel({text = "+" .. self.nextEvolCount, size = 26, color = uihelper.hex2rgb("#62f619"), font = ChineseFont})
				:anch(0, 0.5):pos(xPos3, yPos):addTo(attrBg)
		end
	end
	
	--升阶进度条
	local expSlot = display.newSprite( EquipRes .. "evol_exp_bg.png")
	expSlot:anch(0.5, 0):pos(self.size.width/2, self.size.height - 200):addTo(self.mainLayer)
	local expProgress = display.newProgressTimer(EquipRes .. "evol_exp_fg.png", display.PROGRESS_TIMER_BAR)
	expProgress:setMidpoint(ccp(0, 0.5))
	expProgress:setBarChangeRate(ccp(1,0))
	local needExp = self.equip.csvData.evolExp[self.nextEvolCount]
	local curExp = self.addExp + self.equip.evolExp
	local isMaxEvolCount = self.equip.evolCount >= EQUIP_MAX_EVOL 
	expProgress:setPercentage( isMaxEvolCount and 100 or curExp / needExp * 100)
	
	expProgress:pos(expSlot:getContentSize().width/2, expSlot:getContentSize().height/2):addTo(expSlot)
	
	ui.newTTFLabel({text = isMaxEvolCount and "100%" or string.format("%d / %d", curExp, needExp), size = 18})
		:anch(0.5,0.5):pos(expSlot:getContentSize().width/2, expSlot:getContentSize().height/2):addTo(expSlot)

	
	local yPos = 98
	--银币消耗
	ui.newTTFLabelWithStroke({text = "银币消耗", size = 20, color = uihelper.hex2rgb("#15e6e4"), strokeColor = display.COLOR_FONT, font = ChineseFont})
		:anch(0, 0.5):pos(88, yPos):addTo(self.mainLayer)
	local text = ui.newTTFLabel({text = self.costMoney, size = 22, color = (self.costMoney - self.returnMoney) > game.role.money and display.COLOR_RED or display.COLOR_WHITE})
		:anch(0, 0.5):pos(198, yPos):addTo(self.mainLayer)
	display.newSprite(GlobalRes .. "yinbi.png"):anch(0, 0.5):pos(text:getContentSize().width, text:getContentSize().height/2):addTo(text)
	--银币补偿
	ui.newTTFLabelWithStroke({text = "强化补偿", size = 20, color = uihelper.hex2rgb("#15e6e4"), strokeColor = display.COLOR_FONT, font = ChineseFont})
		:anch(0, 0.5):pos(345, yPos):addTo(self.mainLayer)
	text = ui.newTTFLabel({text = self.returnMoney, size = 22})
		:anch(0, 0.5):pos(455, yPos):addTo(self.mainLayer)
	display.newSprite(GlobalRes .. "yinbi.png"):anch(0, 0.5):pos(text:getContentSize().width, text:getContentSize().height/2):addTo(text)
	--炼化按钮
	DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png"}, {
		priority = self.priority - 1,
		text = { text = "炼化", font = ChineseFont, size = 26, strokeColor = display.COLOR_FONT, strokeSize = 2},
		callback = function()
			self:sendEvolRequest()
		end
	}):getLayer():anch(0.5, 0):pos(self.size.width/2, 20):addTo(self.mainLayer)
end

function EquipEvolutionLayer:sendEvolRequest()
	if self.equip.evolCount == EQUIP_MAX_EVOL then
		DGMsgBox.new({text = "已炼化到最高级！", type = 1})
		return
	end

	if table.nums(self.selectMaterial) == 0 then
		DGMsgBox.new({text = "请选择进阶材料！", type = 1})
		return
	end

	if (self.costMoney - self.returnMoney) > game.role.money then
		DGMsgBox.new({ msgId = 303, type = 2, button2Data = {
			text = "招财",
			priority = -9000,
			callback = function() 
				local getMoney = require("scenes.activity.GetMoneyLayer")
				getMoney.new({ priority = -9000 }):getLayer():addTo(display.getRunningScene())	
			end
		}})
		return
	end

	local hasHighStar = false
	local requestData = {equipId = self.equip.id, materialEquipIds = {}, materialFragmentIds = {}}
	for data, value in pairs(self.selectMaterial) do
		if value then
			local itemData = itemCsv:getItemById(data.itemId)
			if itemData.stars >= 4 then
				hasHighStar = true
			end
			if data.isFrag then
				table.insert(requestData.materialFragmentIds, data.id)
			else
				table.insert(requestData.materialEquipIds, data.id)
			end
		end
	end

	local function sendRequst()
		local oldEvolCount = self.equip.evolCount
		local oldAttrs = self.equip:getBaseAttributes()
		local bin = pb.encode("EquipEvolData", requestData)
		game:sendData(actionCodes.EquipEvolRequest, bin)
		game:addEventListener(actionModules[actionCodes.EquipEvolRequest], function(event)
			--删掉装备
			for _, equipId in ipairs(requestData.materialEquipIds) do
				game.role.equips[equipId] = nil
			end
			--删掉碎片
			for _, fragmentId in ipairs(requestData.materialFragmentIds) do
				game.role.equipFragments[fragmentId] = nil
			end

			if oldEvolCount < self.equip.evolCount then
				-- 播放成功特效
		    	local successSprite = display.newSprite( EquipRes .. "lh_success.png" )
		    	successSprite:scale(2):pos(self.size.width/2, self.size.height/2 + 100):addTo(self, 100)
		    	successSprite:runAction(transition.sequence({
		    			CCScaleTo:create(0, 15),
						CCScaleTo:create(0.2, 0.7),
						CCScaleTo:create(0.1, 1.2),
						CCScaleTo:create(0.1, 0.8),
						CCScaleTo:create(0.1, 1),
						CCScaleTo:create(0.1, 0.9),
						CCFadeOut:create(0.4),
						CCRemoveSelf:create(),
		    		}))
		    	uihelper.sShowAttrsChange({curAttrs = self.equip:getBaseAttributes(), oldAttrs = oldAttrs, fontSize = 36}) 	
		    end
	    	

		    --刷新界面
	    	self:prepareData()
			self:initMaterialNode()
			self:initUI()

			local anim = uihelper.loadAnimation(EquipRes, "LianHua", 7, 14)
			anim.sprite:anch(0.5, 0.5):pos(self.icon:getContentSize().width/2, self.icon:getContentSize().height/2):addTo(self.icon, 999)
			anim.sprite:runAction(transition.sequence({
				CCAnimate:create(anim.animation),
				CCCallFunc:create(function()
					
				end),
				CCRemoveSelf:create(),
			}))	

	    	return "__REMOVE__"
	    end)
	end
	
	if hasHighStar then
		DGMsgBox.new({ text = "材料中有4星以上装备或碎片，确定要继续炼化吗？", type = 2,
			button2Data = {
				callback = function()
					sendRequst()
				end
		}})
	else
		sendRequst()
	end	
end


function EquipEvolutionLayer:initMaterialNode()
	if self.viewBg then
		self.viewBg:removeSelf()
	end

	local cellSize = CCSizeMake(76, 76)
	local columns = 5

	self.viewBg = display.newLayer(EquipRes .. "evol_material_bg.png")
	self.viewBg:anch(0.5, 1):pos(self.size.width/2, self.size.height - 210):addTo(self)
	local viewSize = self.viewBg:getContentSize()
	if self.equip.evolCount >= EQUIP_MAX_EVOL then
		ui.newTTFLabelWithStroke({text = "已炼化到最高级！", size = 28, font = ChineseFont, color = display.COLOR_WHITE})
			:anch(0.5, 0.5):pos(viewSize.width/2, viewSize.height/2):addTo(self.viewBg)
		return
	end

	if #self.material == 0 then
		ui.newTTFLabelWithStroke({text = "无闲置的装备或装备碎片！", size = 28, font = ChineseFont, color = display.COLOR_WHITE})
			:anch(0.5, 0.5):pos(viewSize.width/2, viewSize.height/2):addTo(self.viewBg)
		return
	end

	local function createCellNode(parentNode, cellIndex)
		parentNode:removeAllChildren()
		parentNode:setContentSize(CCSizeMake(viewSize.width, cellSize.height + 10))

		local xBegin = 35
		local xInterval = (viewSize.width - 2 * xBegin - columns * cellSize.width) / (columns - 1)
		local rows = math.ceil(#self.material / columns)
		for index = (rows - cellIndex - 1) * columns + 1, columns * (rows - cellIndex) do
			local material = self.material[index]
			local nativeIndex = index - (rows - cellIndex - 1) * columns
			local cellNode = display.newNode()
			cellNode:size(cellSize)
			local selectTag = 121
			if material then
				--图标
				local icon = ItemIcon.new({
					itemId = material.itemId,
					level = material.level,
					priority = self.priority - 1,
					callback = function()
						if not material.isSelected and self.addExp >= self.maxExp then					
							DGMsgBox.new({text = "经验量已经超出！", type = 1})
							return
						end

						material.isSelected = not material.isSelected
						if material.isSelected then
							self.costMoney = self.costMoney + material.costMoney
							self.returnMoney = self.returnMoney + material.returnMoney
							self.addExp = self.addExp + material.exp
							self.selectMaterial[material] = true
							display.newSprite(EquipRes .. "evol_selected.png")
								:anch(0.5, 0.5):pos(cellSize.width/2, cellSize.height/2):addTo(cellNode, 10, selectTag)
						else
							self.costMoney = self.costMoney - material.costMoney
							self.returnMoney = self.returnMoney - material.returnMoney
							self.addExp = self.addExp - material.exp
							self.selectMaterial[material] = false
							cellNode:removeChildByTag(selectTag)
						end
						self.nextEvolCount = math.max(self.equip:getNextEvolCount(self.addExp), math.min(self.equip.evolCount + 1, EQUIP_MAX_EVOL))
						self:initUI()
					end
				}):getLayer()
				icon:scale(cellSize.width / icon:getContentSize().width):anch(0.5, 0.5):pos(cellSize.width/2, cellSize.height/2):addTo(cellNode)
				--炼化等级
				if material.evolCount > 0 then
					ui.newTTFLabelWithStroke({text = "+" .. material.evolCount, color = uihelper.hex2rgb("#62f619"), size = 24, font = ChineseFont, strokeColor = display.COLOR_FONT})
						:anch(1, 1):pos(cellSize.width, cellSize.height):addTo(cellNode)
				end
				if material.isSelected then
					display.newSprite(EquipRes .. "evol_selected.png")
						:anch(0.5, 0.5):pos(cellSize.width/2, cellSize.height/2):addTo(cellNode, 10, selectTag)
				end
			end

			cellNode:anch(0, 0):pos(xBegin + (cellSize.width + xInterval) * (nativeIndex - 1), 10)
				:addTo(parentNode)
		end
	end

	local viewHandler = LuaEventHandler:create(function(fn, table, a1, a2)
		local result
		if fn == "cellSize" then
			result = CCSizeMake(viewSize.width, cellSize.height + 10)

		elseif fn == "cellAtIndex" then
			if not a2 then
				a2 = CCTableViewCell:new()
				local cell = display.newNode()
				a2:addChild(cell, 0, 1)
			end

			-- 更新cell
			local cell = tolua.cast(a2:getChildByTag(1), "CCNode")
			createCellNode(cell, a1)
			result = a2

		elseif fn == "numberOfCells" then
			result = math.ceil(#self.material / columns)
		end

		return result
	end)

	equipTableView = LuaTableView:createWithHandler(viewHandler, CCSizeMake(viewSize.width, viewSize.height - 10))
	equipTableView:setBounceable(true)
	equipTableView:setTouchPriority(self.priority - 5)
	equipTableView:setPosition(ccp(0, 5))
	self.viewBg:addChild(equipTableView)
end

function EquipEvolutionLayer:getLayer()
	return self.mask:getLayer()
end

return EquipEvolutionLayer