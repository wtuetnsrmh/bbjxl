local GlobalRes = "resource/ui_rc/global/"
local ActivityRes = "resource/ui_rc/activity/"
local MoneyRes = "resource/ui_rc/activity/money/"
local HeroRes = "resource/ui_rc/hero/"

local MoneyCarbonLayer = import(".MoneyCarbonLayer")
local ExpCarbonLayer = import(".ExpCarbonLayer")
local TrialCarbonLayer = import(".TrialCarbonLayer")

local ActivityHomeLayer = class("ActivityHomeLayer", function()
	return display.newLayer()
end)

local activities = {
	[1] = {
		name = "exp", 
		desc = "南蛮入侵！万箭齐发！是男人就坚持100秒！", --请主公坚守阵地等候丞相支援！
		fontSize = 22,
		dimensions = CCSizeMake(220, 100),
		index = 0,
		tipsId = 1,
		callback = function(self)
			showMaskLayer()
			local bin = pb.encode("SimpleEvent", { roleId = game.role.id})
			game:sendData(actionCodes.ExpBattleEnterRequest, bin)
			game:addEventListener(actionModules[actionCodes.ExpBattleEnterRequest], handler(self, self.initExpCarbonLayer))
		end
	},
	[2] = {
		name = "money", 
		desc = "五大财团，富可敌国！抢钱！抢粮！抢...", --听说挑战他们，可以获得巨额财富！ 
		fontSize = 22,
		dimensions = CCSizeMake(220, 100),
		index = -1,
		tipsId = 2,
		callback = function(self)
			showMaskLayer()
			local bin = pb.encode("SimpleEvent", { roleId = game.role.id})
			game:sendData(actionCodes.MoneyBattleEnterRequest, bin)
			game:addEventListener(actionModules[actionCodes.MoneyBattleEnterRequest], handler(self, self.initMoneyCarbonLayer))
		end
	},
	[3] = {
		index = math.huge,
	},
	-- [3] = {
	-- 	name = "shu", 
	-- 	desc = "每周三、六开放",
	-- 	fontSize = 22,
	-- 	index = 3,
	-- 	tipsId = 5,
	-- 	isOpen = function(index)
	-- 		return trialBattleCsv:isOpen(index)
	-- 	end,
	-- },
	-- [4] = {
	-- 	name = "wei", 
	-- 	desc = "每周二、日开放",
	-- 	index = 2,
	-- 	tipsId = 4,
	-- 	fontSize = 22,
	-- 	isOpen = function(index)
	-- 		return trialBattleCsv:isOpen(index)
	-- 	end, 
	-- },
	-- [5] = {
	-- 	name = "wu", 
	-- 	desc = "每周四、日开放",
	-- 	index = 4,
	-- 	tipsId = 6,
	-- 	fontSize = 22,
	-- 	isOpen = function(index)
	-- 		return trialBattleCsv:isOpen(index)
	-- 	end,
	-- },
	-- [6] = {
	-- 	name = "qun", 
	-- 	desc = "每周一、六开放",
	-- 	index = 1,
	-- 	tipsId = 3,
	-- 	fontSize = 22,
	-- 	isOpen = function(index)
	-- 		return trialBattleCsv:isOpen(index)
	-- 	end,
	-- },
	-- [7] = {
	-- 	name = "beauty", 
	-- 	desc = "每周五、日开放",
	-- 	index = 5,
	-- 	tipsId = 7,
	-- 	fontSize = 22,
	-- 	isOpen = function(index)
	-- 		return trialBattleCsv:isOpen(index)
	-- 	end,
	-- },
}

function ActivityHomeLayer:ctor(params)
	params = params or {}
	self.priority = params.priority or -130

	self:anch(0, 0):pos(0, 0)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1 })

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
				if params.closemode == 2 or gPushFlag then
					popScene()
					gPushFlag = false
				else
					switchScene("home")
				end
			end,
		}):getLayer()
	closeBtn:anch(0.5, 0.5):pos(display.width/2 + 847/2-10, display.height/2+498/2+10):addTo(self,100)

	-- 活动副本
	self:initActivityItems()

	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority})
	:anch(0,1):pos((display.width - 960) / 2, display.height):addTo(self)
end

function ActivityHomeLayer:onEnter(remove)
	self:checkGuide(remove)
end

--银币副本；
function ActivityHomeLayer:initMoneyCarbonLayer(event)
	hideMaskLayer()
	local msg = pb.decode("SimpleEvent", event.data)
	local state = tonumber( msg.param1)
	if state == 1 then
		DGMsgBox.new({ type = 1, text = "未到开放日期！"})
	elseif state == 2 then
		DGMsgBox.new({ type = 1, text = "今天次数不足！"})
	elseif state == 0 then
		local seconds = tonumber(msg.param2)
		local mBattleLayer = MoneyCarbonLayer.new({seconds = seconds, priority = self.priority }):getLayer()
		self:addChild(mBattleLayer,101)
	end
end

--经验副本：
function ActivityHomeLayer:initExpCarbonLayer(event)
	hideMaskLayer()
	local msg = pb.decode("SimpleEvent", event.data)
	local state = tonumber( msg.param1)
	if state == 1 then
		DGMsgBox.new({ type = 1, text = "未到开放日期！"})
	elseif state == 2 then
		DGMsgBox.new({ type = 1, text = "今天次数不足！"})
	elseif state == 0 then
		local seconds = tonumber(msg.param2)
		local eBattleLayer = ExpCarbonLayer.new({seconds = seconds, priority = self.priority }):getLayer()
		self:addChild(eBattleLayer,101)
	end
end

function ActivityHomeLayer:initActivityItems()
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end

	self.layer = "home"
	self.mainLayer = display.newLayer(GlobalRes .. "inner_bg.png")
	self.mainLayer:anch(0, 0):pos((display.width - 960) / 2, 0):addTo(self)

	local innerLayer = display.newLayer()
	innerLayer:size(self.mainLayer:getContentSize())
	local innerSize = innerLayer:getContentSize()
	innerLayer:anch(0.5, 0.5):addTo(self.mainLayer)
		:pos(self.mainLayer:getContentSize().width / 2, self.mainLayer:getContentSize().height / 2)

	local rightTab = display.newSprite(GlobalRes .. "tab_selected.png"):anch(0, 0.5)
	local mainlayerWidth = self.mainLayer:getContentSize().width
	rightTab:pos(mainlayerWidth - 14, 470):addTo(self.mainLayer)
	local tabSize = rightTab:getContentSize()
	ui.newTTFLabelWithStroke({ text = "试炼", dimensions = CCSizeMake(tabSize.width / 2, tabSize.height), size = 26, font = ChineseFont,
		color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(tabSize.width / 2, tabSize.height / 2):addTo(rightTab)

	display.newSprite(GlobalRes .. "tab_arrow.png")
		:anch(0.5, 0):pos(innerLayer:getPositionX()+innerSize.width/2-15, innerLayer:getPositionY()+innerSize.height / 2 - 120):addTo(self.mainLayer)


	self.bg = display.newSprite(GlobalRes .. "front_bg.png")
	local bgSize = self.bg:getContentSize()
	self.bg:anch(0.5, 0):pos(innerSize.width / 2, 20):addTo(innerLayer)
	

	local xBegin = 16
	display.newSprite(ActivityRes .. "home/edge.png")
		:anch(1, 0.5):pos(bgSize.width - xBegin, bgSize.height/2):addTo(self.bg, 100)
	local activityScroll = DGScrollView:new({
		size = CCSizeMake(bgSize.width - 2 * xBegin, bgSize.height),
		divider = #activities > 3 and 10 or 30, horizontal = true, priority = self.priority - 1,
	})

	table.sort(activities, function(a, b)
			local factorA = ((a.isOpen and not a.isOpen(a.index)) and 0 or 1) * 1000 - a.index
			local factorB = ((b.isOpen and not b.isOpen(b.index)) and 0 or 1) * 1000 - b.index
			return factorA > factorB
		end)
	self.trialBtns = {}
	for index = 1, #activities do
		local cellNode = self:initCellNode(index)
		activityScroll:addChild(cellNode)
		self.trialBtns[index] = cellNode
	end

	activityScroll:alignCenter()
	activityScroll:getLayer():pos(xBegin, 0):addTo(self.bg)

	if #activities > 3 then
		display.newSprite(HeroRes .. "switch_normal.png")
			:rotation(180):anch(0.5, 0.5):pos(0, bgSize.height / 2):addTo(self.bg)
		display.newSprite(HeroRes.."switch_normal.png")
			:anch(0.5, 0.5):pos(bgSize.width + 15, bgSize.height / 2):addTo(self.bg)
	end
end

function ActivityHomeLayer:initTrialCarbonLayer(activity)
	local carbonLayer = TrialCarbonLayer.new({priority = self.priority - 10, activity = activity }):getLayer()
	self:addChild(carbonLayer, 101)
end

function ActivityHomeLayer:initCellNode(index)
	local activity = activities[index]
	local isOpen, errTips = not activity.isOpen or activity.isOpen(activity.index)

	local leftCount = tonum(globalCsv:getFieldValue(string.format("%sBattleTimes", activity.name)) or 2) - tonum(game.role[string.format("%sBattleCount", activity.name)])
	local cellNode = DGBtn:new(ActivityRes, {activity.name and string.format("home/hero_%s.png", activity.name) or "home/closed.png"},
		{	
			priority = self.priority,
			parent = self.bg,
			callback = function()
				if not activity.name then return end
				local isOpen, errTips = not activity.isOpen or activity.isOpen(activity.index)
				if not isOpen then
					errTips = errTips or activity.desc
					DGMsgBox.new({text = errTips, type = 1})
					return 
				end
				if leftCount <= 0 then
					DGMsgBox.new({text = "今天次数不足！", type = 1})
					return
				end
				if activity.callback then
					activity.callback(self) 
				else
					self:initTrialCarbonLayer(activity)
				end
			end,
		})
	if activity.name then
		local cellSize = cellNode:getLayer():getContentSize()
		
		if isOpen then
			ui.newTTFLabel({ text = string.format("今日剩余次数%d次", leftCount), size = 18, font = ChineseFont, color = uihelper.hex2rgb("#ffd200")})
				:anch(0.5, 0):pos(cellSize.width / 2, 16):addTo(cellNode:getLayer())
		end

		--标题bg
		display.newSprite(ActivityRes .. string.format("home/%s_title.png", activity.name)):anch(0.5, 0):pos(cellSize.width / 2, 110):addTo(cellNode:getLayer())
		
		--描述文字lable
		ui.newTTFLabel({ text = activity.desc, 
			dimensions = activity.dimensions,font=ChineseFont , size = activity.fontSize or 18, color = display.COLOR_WHITE })
			:anch(0.5, 0.5):pos(cellSize.width / 2, cellSize.height - 390):addTo(cellNode:getLayer())
		--tips提示按钮
		if activity.tipsId then
			DGBtn:new(GlobalRes, {"btn_tips_normal.png", "btn_tips_selected.png"}, {
				priority = self.priority - 1,
				callback = function()
					self:openTipsLayer(activity)
				end
			}):getLayer():anch(0, 1):pos(18, cellSize.height - 16):addTo(cellNode:getLayer())
		end

		cellNode:setGray(not isOpen)
	end

	return cellNode:getLayer()
end

function ActivityHomeLayer:openTipsLayer(activity)
	local bg = display.newSprite(ActivityRes .. "home/tips_bg.png")
	bg:anch(0.5, 0.5):pos(display.cx, display.cy)
	local bgSize = bg:getContentSize()
	local mask
	local priority = self.priority - 200
	mask = DGMask:new({ item = bg, priority = priority, ObjSize = bgSize, clickOut = function() mask:remove() end })
	mask:getLayer():addTo(display.getRunningScene())

	local titleBg = display.newSprite(ActivityRes .. "home/tips_title_bg.png")
	titleBg:anch(0.5, 1):pos(bgSize.width/2, bgSize.height - 7):addTo(bg)

	--标题
	local csvData = activityTipsCsv:getDataById(activity.tipsId)
	ui.newTTFLabel({text = csvData.title, size = 24, color = uihelper.hex2rgb("d8f8ff"), font = ChineseFont})
		:anch(0.5, 0.5):pos(titleBg:getContentSize().width/2, titleBg:getContentSize().height/2):addTo(titleBg)
	--奖励	
	ui.newTTFLabel({text = "奖励", size = 24, color = uihelper.hex2rgb("f7dba5"), font = ChineseFont})
		:anch(0.5, 0):pos(bgSize.width/2, 173):addTo(bg)

	local function createItemIcon(itemId)
		
		local itemData = itemCsv:getItemById(itemId)
		local icon = ItemIcon.new({
			itemId = itemId,
			priority = priority - 1,
			callback = function()
				local itemTipsView = require("scenes.home.ItemTipsLayer")
				local itemTips = itemTipsView.new({ itemId = itemId, itemNum = 1, itemType = itemData.type, showSource = false, priority = priority - 10 })
				display.getRunningScene():addChild(itemTips:getLayer())
			end,
		}):getLayer()
		return icon
	end

	local awardItemCount = #csvData.awardItems
	if awardItemCount > 5 then
		local scrollView = DGScrollView:new({ 
			size = CCSizeMake(430, 88), divider = 5,
			priority = priority - 1,
			dataSource = csvData.awardItems,
			cellAtIndex = function(itemId)
				return createItemIcon(itemId)
			end
		})

		scrollView:reloadData()
		scrollView:alignCenter()
		scrollView:getLayer():anch(0.5, 0):pos(bgSize.width/2, 81):addTo(bg)
	else
		local iconWidth = 85
		local xBegin = (bgSize.width - awardItemCount * iconWidth)/2

		for index = 1, awardItemCount do
			local itemId = csvData.awardItems[index]
			local icon = createItemIcon(itemId)
			icon:scale(0.8):anch(0, 0):pos(xBegin + (index - 1) * iconWidth, 81):addTo(bg)
		end
	end
	--描述
	ui.newTTFLabel({text = csvData.desc, size = 24, color = uihelper.hex2rgb("f7dba5"), font = ChineseFont})
		:anch(0.5, 0):pos(bgSize.width/2, 30):addTo(bg)
end

function ActivityHomeLayer:checkGuide(remove)
	--金钱本
	game:addGuideNode({node = self.trialBtns[1], remove = remove, 
		guideIds = {1243}
	})
	--经验本
	game:addGuideNode({node = self.trialBtns[2], remove = remove,
		guideIds = {1253}
	})
end

function ActivityHomeLayer:onExit()
	self:checkGuide(true)
end

--附加条件像灰掉啥滴
function ActivityHomeLayer:isMoneyBattleOpne()
	local isOpen = false
	if game.role.level > 0 then
		isOpen = true
	end
	return isOpen
end

function ActivityHomeLayer:isExpBattleOpne()
	local isOpen = false
	if game.role.level > 0 then
		isOpen = true
	end
	return isOpen
end

function ActivityHomeLayer:getLayer()
	return self.mask:getLayer()
end

return ActivityHomeLayer