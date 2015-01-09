local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"
local HeroChooseRes = "resource/ui_rc/hero/choose/"
local BattleSoulRes = "resource/ui_rc/hero/battle_soul/"

local ItemSourceLayer = require("scenes.home.ItemSourceLayer")

local BattleSoulLayer = class("BattleSoulLayer", function(params) 
	return display.newLayer() 
end)

function BattleSoulLayer:ctor(params)
	self.params = params or {}

	self.itemId = params.itemId
	self.csvData = battleSoulCsv:getDataById(self.itemId - battleSoulCsv.toItemIndex)
	self.hero = params.hero
	self.slot = params.slot
	self.isInlay = self.hero.battleSoul[tostring(self.slot)]
	self.priority = params.priority or -129
	self:size(display.width, display.height)

	self.mainLayer = display.newSprite(BattleSoulRes .. "battle_soul_bg.png"):anch(0.5, 0.5):pos(display.cx, display.cy):addTo(self)
	self.size = self.mainLayer:getContentSize()
	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority, ObjSize = self.size, clickOut = function()
		if params.closeCallback then
			params.closeCallback()
		end 
		self.mask:remove() 
	end})

	self:initMainLayer()
end

function BattleSoulLayer:onEnter()
	self:checkGuide()
end

function BattleSoulLayer:checkGuide(remove)
	game:addGuideNode({node = self.btn, remove = remove,
		guideIds = {1044}
	})
end

function BattleSoulLayer:onExit()
	self:checkGuide(true)
end

function BattleSoulLayer:initMainLayer()
	self.mainLayer:removeAllChildren()
	--图标
	ItemIcon.new({itemId = self.itemId}):getLayer()
		:scale(0.9):anch(0, 1):pos(32, self.size.height - 18):addTo(self.mainLayer)
	--名称
	local xPos = 136
	ui.newTTFLabelWithStroke({text = self.csvData.name, font = ChineseFont, size = 24, color = uihelper.hex2rgb("#f2960c"), strokeColor = display.COLOR_FONT})
		:anch(0, 1):pos(xPos, self.size.height - 31):addTo(self.mainLayer)
	--拥有数量
	local item = game.role.items[self.itemId]
	local itemNum = item and item.count or 0
	ui.newTTFLabelWithStroke({text = string.format("拥有%d件", itemNum), font = ChineseFont, size = 20, color = uihelper.hex2rgb("#ffdc7d"), strokeColor = display.COLOR_FONT})
		:anch(0, 1):pos(xPos, self.size.height - 73):addTo(self.mainLayer)
	--属性
	local bg = display.newSprite(BattleSoulRes .. "attr_bg.png")
	bg:anch(0.5, 0):pos(self.size.width/2, 140):addTo(self.mainLayer)
	local xPos, yPos, yInterval = 28, bg:getContentSize().height - 23, 32
	-- 生命
	local text = ui.newTTFLabel({text = "生命：", size = 20, color = uihelper.hex2rgb("#ffdc7d")})
	text:anch(0, 1):pos(xPos, yPos):addTo(bg)
	ui.newTTFLabel({text = "+" .. self.csvData.hp, size = 20, color = uihelper.hex2rgb("#7ce810")})
		:anch(0, 0):pos(text:getContentSize().width, 0):addTo(text)
	yPos = yPos - yInterval
	-- 攻击
	local text = ui.newTTFLabel({text = "攻击：", size = 20, color = uihelper.hex2rgb("#ffdc7d")})
	text:anch(0, 1):pos(xPos, yPos):addTo(bg)
	ui.newTTFLabel({text = "+" .. self.csvData.atk, size = 20, color = uihelper.hex2rgb("#7ce810")})
		:anch(0, 0):pos(text:getContentSize().width, 0):addTo(text)
	yPos = yPos - yInterval
	-- 防御
	local text = ui.newTTFLabel({text = "防御：", size = 20, color = uihelper.hex2rgb("#ffdc7d")})
	text:anch(0, 1):pos(xPos, yPos):addTo(bg)
	ui.newTTFLabel({text = "+" .. self.csvData.def, size = 20, color = uihelper.hex2rgb("#7ce810")})
		:anch(0, 0):pos(text:getContentSize().width, 0):addTo(text)

	if not self.isInlay then
		ui.newTTFLabel({text = "镶嵌后会与该武将绑定", size = 18, color = uihelper.hex2rgb("#f4f4f4")})
			:anch(0.5, 0):pos(self.size.width/2, 110):addTo(self.mainLayer)
	end
	--需求等级
	ui.newTTFLabel({text = string.format("需求等级：%d", self.csvData.requireLevel), size = 18, color = uihelper.hex2rgb(self.hero.level >= self.csvData.requireLevel and "#ffdc7d" or "#ff0000")})
		:anch(0.5, 0):pos(self.size.width/2, 80):addTo(self.mainLayer)
	--按钮
	local callback, text, action
	if self.isInlay then
		text = "确定"
		callback = function()
			self.mask:remove()
		end
	else
		--可以镶嵌
		if itemNum > 0 then
			action = self.csvData.requireLevel <= self.hero.level
			text = "镶嵌"
			callback = function()
				if self.csvData.requireLevel > self.hero.level then
					DGMsgBox.new({text = "武将等级不足！", type = 1})
					return
				end

				--发送镶嵌
				local bin = pb.encode("SimpleEvent", {roleId = game.role.id, param1 = self.slot, param2 = self.hero.id})
        		game:sendData(actionCodes.HeroBattleSoulRequest, bin)
				game:addEventListener(actionModules[actionCodes.HeroBattleSoulRequest], function(event)
					game:dispatchEvent({name = "btnClicked", data = self.btn})
					if self.params.closeCallback then
						self.params.closeCallback(true)
					end
					self.mask:remove()

					game.role:dispatchEvent({ name = "notifyNewMessage", type = "heroList"})
					return "__REMOVE__"
				end)
			end
		else
			--可以合成
			if table.nums(self.csvData.material) > 0 then
				text = "合成公式"
				callback = function()
					--打开次级界面
					self.itemList = {self.csvData.id}
					self:initSecondLayer(self.csvData.id)
				end
			else
				text = "获得途径"
				callback = function()
					local sourceLayer = ItemSourceLayer.new({ priority = self.priority - 300, itemId = self.itemId,
						closeCallback = function()
							self:initMainLayer()
						end })
					sourceLayer:getLayer():addTo(display.getRunningScene())
				end
			end
		end
	end

	self.btn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png", "middle_disabled.png"}, {
		priority = self.priority - 1,
		text = {text = text, size = 26, font = ChineseFont, strokeColor = display.COLOR_FONT},
		notSendClickEvent = true,
		callback = callback,
	}):getLayer():anch(0.5, 0):pos(self.size.width/2, 17):addTo(self.mainLayer)

	if action then
		local anim = uihelper.loadAnimation(HeroRes .. "evolution/", "evo", 7)
		anim.sprite:anch(0.5, 0.5):pos(self.btn:getContentSize().width/2, self.btn:getContentSize().height/2 + 5):addTo(self.btn)
		anim.sprite:runAction(CCRepeatForever:create(CCAnimate:create(anim.animation)))
	end
end
	
function BattleSoulLayer:initSecondLayer(id)
	self.mainLayer:anch(1.02, 0.5)
	self.mask.ObjSize = CCSizeMake(self.size.width * 2.04, self.size.height)
	if not self.secondLayer then
		self.secondLayer = display.newSprite(BattleSoulRes .. "battle_soul_bg.png"):anch(-0.02, 0.5):pos(display.cx, display.cy):addTo(self)
	end
	self.secondLayer:removeAllChildren()
	self.icon = nil
	
	--上面一排
	local xBegin, xInterval = 64, 78
	local scale
	for index, soulId in ipairs(self.itemList) do
		local xPos, yPos = xBegin + (index - 1) * xInterval, self.size.height - 64
		local icon = ItemIcon.new({
			itemId = soulId + battleSoulCsv.toItemIndex, 
			priority = self.priority - 1,
			callback = function()
				if soulId ~= id then
					while index ~= #self.itemList do
						table.remove(self.itemList)
					end
					self:initSecondLayer(soulId)
				end
			end,
		}):getLayer():anch(0.5, 0.5):pos(xPos, yPos):addTo(self.secondLayer)
		if not scale then scale = 58 / icon:getContentSize().width end
		icon:scale(scale)

		--箭头
		if index > 1 then
			display.newSprite(BattleSoulRes .. "arrow.png")
				:anch(1, 0.5):pos(xPos - 29, yPos):addTo(self.secondLayer)
		end
		--选中态
		if soulId == id then
			display.newSprite(BattleSoulRes .. "icon_selected.png")
				:anch(0.5, 0.5):pos(xPos, yPos - 5):addTo(self.secondLayer)
		end
	end

	--具体合成信息
	local bg = display.newSprite(BattleSoulRes .. "material_bg.png")
	bg:anch(0.5, 0):pos(self.size.width/2, 113):addTo(self.secondLayer)
	local bgSize = bg:getContentSize()
	local csvData = battleSoulCsv:getDataById(id)
	-- 名称
	ui.newTTFLabel({text = csvData.name, size = 20, color = uihelper.hex2rgb("#f4f4f4")})
		:anch(0.5, 1):pos(bgSize.width/2, bgSize.height - 7):addTo(bg)
	-- 图标
	local icon = ItemIcon.new({itemId = id + battleSoulCsv.toItemIndex})
		:getLayer():anch(0.5, 0.5):pos(bgSize.width/2, bgSize.height - 68):addTo(bg)
	local scale = 68 / icon:getContentSize().width
	icon:scale(scale)
	-- 线条
	local materialCount = table.nums(csvData.material)
	local line = display.newSprite(BattleSoulRes .. string.format("line_%d.png", materialCount))
	line:anch(0.5, 1):pos(bgSize.width/2, bgSize.height - 109):addTo(bg)
	
	-- 材料icon
	local pos
	if materialCount == 1 then
		pos = {line:getContentSize().width / 2}
	elseif materialCount == 2 then
		pos = {0, line:getContentSize().width}
	else
		pos = {0, line:getContentSize().width / 2, line:getContentSize().width}
	end

	local itemEnough = table.nums(csvData.material) > 0
	for index, strData in ipairs(csvData.material) do
		local data = string.toArray(strData, "=")
		local soulId, num = tonum(data[1]), tonum(data[2])
		local itemId = soulId + battleSoulCsv.toItemIndex
		local itemData = itemCsv:getItemById(itemId)
		local soulCsvData = battleSoulCsv:getDataById(soulId)
		local xPos = pos[index]
		--数量
		local item = game.role.items[itemId]
		local itemNum = item and item.count or 0
		ui.newTTFLabel({text = itemNum .. "/" .. num, size = 18, color = uihelper.hex2rgb(itemNum >= num and "#a6a6a6" or "#ff0000")})
			:anch(0.5, 1):pos(xPos, -63):addTo(line)
		if itemEnough then
			itemEnough = itemNum >= num
		end
		
		--图标
		local icon = ItemIcon.new({
			itemId = itemId, 
			priority = self.priority - 1,
			callback = function()
				--有原来进入下一级，否则打开获得途径界面
				if table.nums(soulCsvData.material) > 0 then
					table.insert(self.itemList, soulId)
					self:initSecondLayer(soulId)
				else
					local itemTipsView = require("scenes.home.ItemTipsLayer")
					local itemTips = itemTipsView.new({ itemId = itemId, itemNum = itemNum, itemType = itemData.type, showSource = true, priority = self.priority - 10,
						closeCallback = function()
							self:initSecondLayer(id)
						end})
					display.getRunningScene():addChild(itemTips:getLayer())
				end
			end,
		}):getLayer():scale(scale):anch(0.5, 1):pos(xPos, 3):addTo(line)

		if not itemEnough and not self.icon then
			self.icon = icon
		end
	end

	--合成花费
	local text = ui.newTTFLabel({text = "合成花费：", size = 20, color = uihelper.hex2rgb("#ffdc7d")})
	text:anch(0, 0):pos(82, 79):addTo(self.secondLayer)

	text = ui.newTTFLabel({text = csvData.money, size = 20, color = uihelper.hex2rgb(game.role.money >= csvData.money and "#f4f4f4" or "#ff0000")})
		:anch(0, 0):pos(text:getContentSize().width, 0):addTo(text)

	display.newSprite(GlobalRes .. "yinbi.png"):anch(0, 0.5):pos(text:getContentSize().width + 3, text:getContentSize().height / 2):addTo(text)
	
	--合成按钮
	local btn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png", "middle_disabled.png"}, {
		priority = self.priority - 1,
		text = {text = "合成", size = 26, font = ChineseFont, strokeColor = display.COLOR_FONT},
		callback = function()
			if not itemEnough then
				if battleSoulCsv:canCompose(id) then
					local tag = 6897
					display.getRunningScene():removeChildByTag(tag)
					local tips = display.newSprite(BattleSoulRes .. "pop_tips.png")
					local worldPos = self.icon:convertToWorldSpace(ccp(0, 0))
					tips:anch(0.5, 0):pos(worldPos.x + 34, worldPos.y + 68):addTo(display.getRunningScene(), 99, tag)
					ui.newTTFLabel({text = "请先合成这件材料", size = 20, color = uihelper.hex2rgb("#f4f4f4")})
						:anch(0.5, 0.5):pos(tips:getContentSize().width/2, tips:getContentSize().height/2 + 7):addTo(tips)
					tips:runAction(transition.sequence({
						CCDelayTime:create(2),
						CCFadeOut:create(0.3),
						CCRemoveSelf:create(),
					}))
					return
				else
					DGMsgBox.new({text = "材料不足，无法合成！", type = 1})
					return
				end
			end

			if game.role.money < csvData.money then
				game.role:processErrorCode({data = pb.encode("SysErrMsg", {errCode = SYS_ERR_MONEY_NOT_ENOUGH})})
				return
			end

			--合成道具
			local bin = pb.encode("SimpleEvent", {roleId = game.role.id, param1 = id})
    		game:sendData(actionCodes.RoleComposeBattleSoul, bin)
			game:addEventListener(actionModules[actionCodes.RoleComposeBattleSoul], function(event)
				DGMsgBox.new({text = "合成成功", type = 1})
				--特效
				for index, strData in ipairs(csvData.material) do
					local data = string.toArray(strData, "=")
					local soulId, num = tonum(data[1]), tonum(data[2])
					local itemId = soulId + battleSoulCsv.toItemIndex
					local xPos = pos[index]
					local itemIcon = ItemIcon.new({itemId = itemId}):getLayer()
					itemIcon:scale(scale):anch(0.5, 1):pos(xPos, 3):addTo(line)
					itemIcon:runAction(transition.sequence({
						CCSpawn:createWithTwoActions(CCScaleTo:create(0.1, scale * 0.8), CCMoveTo:create(0.2, ccp(line:getContentSize().width / 2, line:getContentSize().height + 50))),
						CCRemoveSelf:create(),
						CCCallFunc:create(function()
							self:initMainLayer()
							if #self.itemList > 1 then
								table.remove(self.itemList)
							end
							self:initSecondLayer(self.itemList[#self.itemList])
						end),
					}))
				end

				return "__REMOVE__"
			end)

		end,
	})
	btn:getLayer():anch(0.5, 0):pos(self.size.width/2, 17):addTo(self.secondLayer)
end

function BattleSoulLayer:getLayer()
	return self.mask:getLayer()
end


return BattleSoulLayer