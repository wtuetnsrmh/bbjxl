local AwardSignGotLayer = import(".AwardSignGotLayer")

local GlobalRes = "resource/ui_rc/global/"
local GiftRes = "resource/ui_rc/gift/"

local ItemTypeData = {
	[1] = { 
		ch = "礼包",
		res = function(itemData)
			return itemData.icon
		end 
	},

	[2] = { 
		ch = "金币",
		res = function(itemData)
			return itemData.icon
		end 
	},

	[3] = { 
		ch = "元宝",
		res = function(itemData)
			return itemData.icon
		end 
	},

	[4] = { 
		ch = "体力",
		res = function(itemData) 
			return itemData.icon
		end 
	},


	[7] = { 
		ch = "卡牌", 
		res = function(itemData)
			local unitData = unitCsv:getUnitByType(itemData.heroType)
			return unitData.headImage, unitData.name
		end
	},

	[8] = { 
		ch = "碎片",
		res = function(itemData) 
			local unitData = unitCsv:getUnitByType(itemData.heroType)
			return unitData.headImage, unitData.name .. "·碎片"
		end 
	},

	[14] = {
		ch = "进阶道具",
		res = function(itemData)
			return itemData.icon, itemData.name
		end,
	},

	[15] = {
		ch = "美人道具",
		res = function(itemData)
			return itemData.icon, itemData.name
		end,
	},

	[23] = {
		ch = "技能进化工具",
		res = function(itemData)
			return itemData.icon, itemData.name
		end,
	},
	[27] = {
		ch = "经验药",
		res = function(itemData)
			return itemData.icon, itemData.name
		end,
	}
}

local CurMonthAwardLayer = class("CurMonthAwardLayer", function()
	return display.newLayer(GiftRes .. "assign_frame.png")
end)

function CurMonthAwardLayer:ctor(params)
	params = params or {}

	self.size = self:getContentSize()
	self.priority = params.priority or - 130

	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1, ObjSize = self.size, clickOut = function() self.mask:remove() end })

	self.bg = display.newSprite(GiftRes .. "assign_bg.png")
		:anch(0.5, 1):pos(self.size.width/2, self.size.height - 72):addTo(self, -1)

	display.newSprite(GiftRes.."assign_title.png")
		:anch(0.5, 0.5):pos(self.size.width * 0.5, self.size.height - 56):addTo(self)

	local nowTm = os.date("*t", game:nowTime())
	-- '0' 字符值为 48; '1' 字符值为49
	local hasSign = string.byte(game.role.monthSignDay, nowTm.day) == 49
	local firstLogin = (not hasSign and not game.role.gotSignGift)

	local totalDay = 0
	for index = 1, #game.role.monthSignDay do
		if string.sub(game.role.monthSignDay, index, index) == "1" then totalDay = totalDay + 1 end
	end

	local viewSize = CCSizeMake(self.bg:getContentSize().width, self.bg:getContentSize().height - 40)
	local assignScroll = DGScrollView:new({ size = viewSize, divider = 5, priority = self.priority - 1 })

	local function tipsNode(params)
		-- self:removeChildByTag(100)
		local bg = display.newSprite(GlobalRes .. "tips_middle.png")
		local bgSize = bg:getContentSize()

		local signData = activitySignCsv:getItemId(params.day, params.month)
		local itemData = itemCsv:getItemById(signData.itemId)
		local iconRes, typeValue = ItemTypeData[itemData.type].res(itemData)

		local itemIcon = ItemIcon.new({ itemId = signData.itemId }):getLayer()
		itemIcon:anch(0, 1):pos(20, bgSize.height - 20):addTo(bg)
		local iconSize = itemIcon:getContentSize()

		-- 名字
		local awardName = ui.newTTFLabel({ text = string.format("%s  X %d", typeValue and typeValue or signData.typeName, signData.num), size = 28 ,color = display.COLOR_GREEN })
		awardName:anch(0, 1):pos(iconSize.width + 10, iconSize.height):addTo(itemIcon)
		-- 描述
		ui.newTTFLabelWithStroke({ text = itemData.desc, size = 20, strokeColor = display.COLOR_BLACK,
			dimensions = CCSizeMake(260, 80) })
			:anch(0, 0):pos(iconSize.width + 10, -10):addTo(itemIcon)
		--获取时间的提示：
		ui.newTTFLabel({ text = string.format("本月签到%d天即可获得！", params.day), size = 28, color = display.COLOR_YELLOW })
			:anch(0.5, 0):pos(bgSize.width / 2, 20):addTo(bg)

		bg:anch(0.5,0.5):pos(display.cx, display.cy)
		self.maskTips = DGMask:new({item = bg, priority = -1300, opacity = 0,
			click = function()
				self.maskTips:getLayer():removeSelf()
			end
			})
		self.maskTips:getLayer():addTo(display.getRunningScene(), 1000)
	end

	local maxDays = getDaysInMonth()

	local xBegin = 30
	local maxColumns = 5
	local xInterval = (viewSize.width - maxColumns * 104 - 2 * xBegin) / 4
	local month = os.date("*t", game:nowTime()).month
	for row = 1, math.ceil(maxDays / maxColumns) do
		local cellNode = display.newNode()
		cellNode:size(CCSizeMake(viewSize.width, 150))

		for col = 1, math.min(maxDays-(row-1) * maxColumns, maxColumns) do
			local day = (row - 1) * maxColumns + col
			local signData = activitySignCsv:getItemId(day, month)
			if signData then
				local itemData = itemCsv:getItemById(signData.itemId, month)

				local itemFrame = ItemIcon.new({ itemId = signData.itemId, priority = self.priority,
						parent = assignScroll:getLayer(),
						callback = function()
							tipsNode({day = day, month = month})
						end, 
					}):getLayer()
				local frameSize = itemFrame:getContentSize()
				itemFrame:anch(0.5, 0.5):addTo(cellNode, 0, col)
					:pos(xBegin + (col - 1) * (104 + xInterval) + 52, 52)

				ui.newTTFLabel({text = day .. "天", font = ChineseFont, size = 28, })
					:anch(0.5, 0):pos(frameSize.width / 2, frameSize.height + 5)
					:addTo(itemFrame)

				--vip双倍标记
				if signData.doubleVipLevel > 0 then
					display.newSprite(GiftRes .. string.format("vip_%d_double.png", signData.doubleVipLevel))
						:anch(0, 1):pos(itemData.type == ItemTypeId.Hero and 5 or 0, frameSize.height):addTo(itemFrame)
				end

				if day <= totalDay then
					local maskRes = (itemData.type == ItemTypeId.HeroFragment) and "got_bg_2.png" or "got_bg.png"
					display.newSprite(GiftRes .. maskRes):scale(1.05)
						:pos(frameSize.width / 2, frameSize.height / 2):addTo(itemFrame, -1)
					display.newSprite(GiftRes .. "got.png")
						:pos(frameSize.width / 2, frameSize.height / 2):addTo(itemFrame)
				end
			end
		end

		assignScroll:addChild(cellNode, cellNode)
	end

	assignScroll:alignCenter()
	assignScroll:getLayer():anch(0.5, 0):pos(self.bg:getContentSize().width / 2, 0):addTo(self.bg)

	if firstLogin then
		totalDay = totalDay + 1
		local row, col = math.floor((totalDay - 1) / 6) + 1, (totalDay - 1) % 6 + 1
		local signData = activitySignCsv:getItemId(totalDay, month)
		local itemData = itemCsv:getItemById(signData.itemId)
		local iconRes, typeValue = ItemTypeData[itemData.type].res(itemData)

		local itemId = itemData.itemId
		local name = string.format("%s  X %d", typeValue and typeValue or signData.typeName, signData.num)
		if signData.doubleVipLevel > 0 and game.role.vipLevel >= signData.doubleVipLevel then
			name = name .. "[color=00ff00]（X2）[/color]"
		end
		local awardGotLayer = AwardSignGotLayer.new({ priority = self.priority - 10, name = name, 
			desc = itemData.desc, itemTypeId = itemData.type, itemId = itemId, day = totalDay, doubleVipLevel = signData.doubleVipLevel,
			onComplete = function()
				game.role.gotSignGift = true

				local cell = assignScroll.items[row]:getChildByTag(col)
				local cellSize = cell:getContentSize()
				local gotIcon = display.newSprite(GiftRes .. "got.png")
				gotIcon:pos(cellSize.width / 2 + 10, cellSize.height / 2 + 10):addTo(cell, 1):scale(2)

				local spawnAction = CCArray:create()
				spawnAction:addObject(CCMoveTo:create(0.5, ccp(cellSize.width / 2, cellSize.height / 2)))	
				spawnAction:addObject(CCScaleTo:create(0.5, 1))

				local action = transition.sequence({
					CCSpawn:create(spawnAction),
					CCCallFunc:create(function()
						local maskRes = (itemData.type == ItemTypeId.HeroFragment) and "got_bg_2.png" or "got_bg.png"
						display.newSprite(GiftRes .. maskRes):scale(1.05)
							:pos(cellSize.width / 2, cellSize.height / 2):addTo(cell, -1)
						uihelper.shake({x = 5, y = 5, count = 2 }, self)
					end)
				})
				gotIcon:runAction(action)
				game.role:dispatchEvent({ name = "notifyNewMessage", type = "sign" })
				game.role.monthSignDay = game.role.monthSignDay .. 1
			end})

		uihelper.popupNode(awardGotLayer)
		awardGotLayer:getLayer():addTo(self:getLayer())
	end

	pushLayerAction(self,true)
end

function CurMonthAwardLayer:getLayer()
	return self.mask:getLayer()
end

return CurMonthAwardLayer