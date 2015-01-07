local GlobalRes = "resource/ui_rc/global/"
local MailRes = "resource/ui_rc/mail/"
local GiftRes = "resource/ui_rc/gift/"

local GrowRes = "resource/ui_rc/hero/growth/"


local DailyTaskLayer = class("DailyTaskLayer", function()
	return display.newLayer(GiftRes .. "gift_frame.png")
end)

function DailyTaskLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -130
	self.parent = params.parent

	self.DailyTaskField = {
		[1] = { name = "commonCarbonCount", goto = function() switchScene("carbon", { tag = 1 }) end },
		[2] = { name = "specialCarbonCount",goto = function() switchScene("carbon", { tag = 2 }) end },
		[3] = { name = "heroIntensifyCount",goto = function()
				self:getLayer():removeSelf()
				self.parent:autoPopupLayer({ layer = "item", tag = 2 })
			end },
		[4] = { name = "pvpBattleCount", goto = function()
				local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
				if roleInfo.pvpOpen < 0 then
					DGMsgBox.new({ msgId = 173 })
					return
				end
		 		switchScene("pvp") 
		 	end },
		[5] = { name = "techLevelUpCount", goto = function()
				local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
				if roleInfo.techOpen < 0 then
					DGMsgBox.new({ msgId = 174 })
					return
				end
				self.parent:autoPopupLayer({ layer = "tech" })
				self:getLayer():removeSelf()
			end },
		[6] = { name = "beautyTrainCount", goto = function()
				local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
				if roleInfo.beautyOpen < 0 then
					DGMsgBox.new({ msgId = 175 })
					return
				end
				self.parent:autoPopupLayer({ layer = "beauty" })
				self:getLayer():removeSelf()
			end },
		[7] = { name = "towerBattleCount", goto = function() 
				local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
				if roleInfo.towerOpen < 0 then
					DGMsgBox.new({ msgId = 177 })
					return
				end
				local bin = pb.encode("SimpleEvent", { roleId = game.role.id })
				game:sendData(actionCodes.TowerDataRequest, bin, #bin)
				loadingShow()
				game:addEventListener(actionModules[actionCodes.TowerDataResponse], function(event)
					loadingHide()
					local msg = pb.decode("TowerData", event.data)
					local towerPbFields = { "count", "carbonId", "totalStarNum", "preTotalStarNum", 
						"maxTotalStarNum", "curStarNum", "hpModify", "atkModify", "defModify", "sceneId1",
						"sceneId2", "sceneId3", }

					game.role.towerData = game.role.towerData or {}
					for _, field in pairs(towerPbFields) do
						game.role.towerData[field] = msg[field]
					end

					switchScene("tower")	
					return "__REMOVE__"
				end)
			end },
		[8] = { name = "heroStarCount", goto = function()
				local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
				if roleInfo.heroStarOpen < 0 then
					DGMsgBox.new({ msgId = 176 })
					return
				end
				self.parent:autoPopupLayer({ layer = "herostar" })
				self:getLayer():removeSelf()
			end },
		[9] = { name = "legendBattleCount", goto = function() 
				local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
				if roleInfo.legendOpen < 0 then
					DGMsgBox.new({ msgId = 178 })
					return
				end
				switchScene("legend") 
			end },
		[10] = { name = "zhaoCaiCount", goto = function() 
				self.parent:autoPopupLayer({ layer = "zhaoCai" })
				self:getLayer():removeSelf()
			end },
		[11] = { name = "yuekaCount", goto = function()
				if game.role:isYuekaExpired() then
					local ReChargeLayer = require("scenes.home.shop.ReChargeLayer")
					local layer = ReChargeLayer.new({priority = self.priority - 10})
					layer:getLayer():addTo(display.getRunningScene())
					self:getLayer():removeSelf()
				end
			end },
		[13] = { name = "equipIntensifyCount", goto = function()
					self.parent:autoPopupLayer({ layer = "equip" })
					self:getLayer():removeSelf()
				end },
		[14] = { name = "drawCardCount", goto = function()
					self.parent:autoPopupLayer({ layer = "shop", chooseIndex = 1, })
					self:getLayer():removeSelf()
				end },
		[15] = { name = "trainCarbonCount", goto = function()
					switchScene("activity")
				end },
		[16] = { name = "expeditionCount", goto = function()
					switchScene("expedition")
				end },
	}

	self.priority = params.priority or -130
	self.size = self:getContentSize()

	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1, ObjSize = self.size, clickOut = function() self.mask:remove() end })
	self.bg = display.newSprite(GiftRes .. "gift_bg.png")
		:anch(0.5, 1):pos(self.size.width/2, self.size.height - 66):addTo(self, -1)
end

function DailyTaskLayer:onEnter()

	local wordSp = display.newSprite(GiftRes.."task_title.png")
	wordSp:anch(0.5, 0.5):pos(self.size.width * 0.5, self.size.height - 56):addTo(self)

	self.taskScroll = DGScrollView:new({ 
		priority = self.priority - 1,
		size = CCSizeMake(self.bg:getContentSize().width, self.bg:getContentSize().height - 40), 
		divider = 5,
	})
	self.taskScroll:getLayer():pos(0, 0):addTo(self.bg)

	self:initTaskList()	
end

function DailyTaskLayer:initTaskList()
	if self.taskScroll then
		self.taskScroll:removeAll()
	end

	local temp = {}
	for taskId, data in pairs(dailyTaskCsv.m_data) do
		local finishCount = game.role[self.DailyTaskField[taskId].name]
		if finishCount >= 0 and game.role.level >= data.openLevel then
			temp[taskId] = finishCount >= data.count and 10 or 0
			if taskId == 11 and game.role:isYuekaExpired() then
				temp[taskId] = temp[taskId] - 1
			end
		end
	end

	local taskIds = table.keys(temp)
	table.sort(taskIds, function(a, b) return temp[a] > temp[b] end)
	if #taskIds == 0 then
		ui.newTTFLabel({text = "主公霸气侧漏，每日任务全部完成！\n请明日再战~", size = 28})
			:anch(0.5, 0.5):pos(self.bg:getContentSize().width/2, self.bg:getContentSize().height/2):addTo(self.bg)
	end

	for _, taskId in ipairs(taskIds) do
		local taskNode = self:createTaskNode(taskId)
		self.taskScroll:addChild(taskNode)
	end

	self.taskScroll:alignCenter()
	self.taskScroll:effectIn()
end

function DailyTaskLayer:createTaskNode(taskId)
	local itemBg = display.newSprite(GiftRes .. "gift_sub_bg.png")
	itemBg:anch(0.5, 0)
	local cellSize = itemBg:getContentSize()

	local taskData = dailyTaskCsv:getTaskById(taskId)
	local finishCount = game.role[self.DailyTaskField[taskId].name]

	local iconFrame = display.newSprite(GlobalRes .. "item_1.png")
	iconFrame:anch(0, 0):pos(8, 8):addTo(itemBg)
	display.newSprite(taskData.icon):addTo(iconFrame, -1)
		:pos(iconFrame:getContentSize().width / 2, iconFrame:getContentSize().height / 2)

	local xPos = 125
	--名称：
	ui.newTTFLabelWithStroke({ text = taskData.name, size = 24, font = ChineseFont, color = display.COLOR_WHITE, strokeColor = display.COLOR_FONT })
		:anch(0, 1):pos(xPos, cellSize.height - 12):addTo(itemBg)

	--描述
	ui.newTTFLabel({ text = taskData.desc, size = 20, color = uihelper.hex2rgb("#533a27") })
		:anch(0, 0):pos(xPos, 42):addTo(itemBg)

	--进度：
	local desc = nil 
	local isYueka = taskId == 11
	if isYueka then
		if game.role:isYuekaExpired() then
			desc = "[color=126CB8]未购买[/color]"
		else
			local leftDays = math.ceil((game.role.yuekaDeadline - game:nowTime()) / (24 * 3600))
			desc = string.format("[color=533A27]已购买，还剩[/color][color=126CB8]%d[/color][color=533A27]天[/color]", leftDays)
		end
	end

	if finishCount < taskData.count then
		desc = string.format("进度：[color=126CB8]%d[/color]/%d", finishCount, taskData.count)
	end

	if desc then
		DGRichLabel.new({ text = desc, size = 20, color = uihelper.hex2rgb("#533a27") })
			:anch(0.5, 0.5):pos(itemBg:getContentSize().width - 84, itemBg:getContentSize().height - 28):addTo(itemBg)
	end

	--奖励字体：
	local yPos = 22
	local awardLabel = ui.newTTFLabel({ text = "奖励：", font = ChineseFont, size = 20, color = uihelper.hex2rgb("#742a0f") })
	awardLabel:anch(0, 0.5):pos(xPos, yPos):addTo(itemBg)
	xPos = xPos + awardLabel:getContentSize().width

	--经验图片：
	local expSp = display.newSprite(GlobalRes.."exp.png"):anch(0, 0.5)
	:pos(awardLabel:getPositionX() + awardLabel:getContentSize().width, yPos):addTo(itemBg)

	--经验
	local expValue = taskData.exp
	local expLabel = ui.newTTFLabel({ text = string.format("X%d", expValue), size = 20, color = uihelper.hex2rgb("#742a0f") })
	expLabel:anch(0, 0.5):pos(expSp:getPositionX() + expSp:getContentSize().width, yPos):addTo(itemBg)

	local resultText = "获得奖励: 经验 +" .. expValue


	--银币奖励：
	if taskData.money > 0 then
		local moneyIcon = display.newSprite(GlobalRes .. "yinbi_big.png")
		moneyIcon:anch(0, 0.5)
		:pos(expLabel:getPositionX() + expLabel:getContentSize().width + 10, yPos):addTo(itemBg)
		
		ui.newTTFLabel({ text = string.format("X%d", taskData.money), size = 20, color = uihelper.hex2rgb("#742a0f") })
			:anch(0, 0.5):pos(moneyIcon:getPositionX() + moneyIcon:getContentSize().width, yPos):addTo(itemBg)

		resultText = resultText .. "  银币 +" .. taskData.money
	end

	--元宝奖励：
	if taskData.yuanbao > 0 then
		local icon = display.newSprite(GlobalRes .. "yuanbao.png")
		icon:anch(0, 0.5):pos(expLabel:getPositionX() + expLabel:getContentSize().width + 10, yPos):addTo(itemBg)

		ui.newTTFLabel({ text = string.format("X%d", taskData.yuanbao), size = 20, color = uihelper.hex2rgb("#742a0f") })
			:anch(0, 0.5):pos(icon:getPositionX() + icon:getContentSize().width, yPos):addTo(itemBg)
		resultText = resultText .. "  元宝 +" .. taskData.yuanbao
	end

	--战功奖励：
	if taskData.zhangong > 0 then
		local icon = display.newSprite("resource/ui_rc/pvp/zhangong.png")
		icon:anch(0, 0.5):pos(expLabel:getPositionX() + expLabel:getContentSize().width + 10, yPos):addTo(itemBg)

		ui.newTTFLabel({ text = string.format("X%d", taskData.zhangong), size = 20, color = uihelper.hex2rgb("#742a0f") })
			:anch(0, 0.5):pos(icon:getPositionX() + icon:getContentSize().width, yPos):addTo(itemBg)
		resultText = resultText .. "  战功 +" .. taskData.zhangong
	end

	--星魂奖励：
	if taskData.starSoul > 0 then
		local icon = display.newSprite(GlobalRes .. "starsoul.png")
		icon:anch(0, 0.3):pos(expLabel:getPositionX() + expLabel:getContentSize().width + 10, yPos):addTo(itemBg)

		ui.newTTFLabel({ text = string.format("X%d", taskData.starSoul), size = 20, color = uihelper.hex2rgb("#742a0f") })
			:anch(0, 0.5):pos(icon:getPositionX() + icon:getContentSize().width, yPos):addTo(itemBg)
		resultText = resultText .. "  星魂 +" .. taskData.starSoul
	end

	--魂奖励
	if taskData.heroSoul > 0 then
		local icon = display.newSprite(GlobalRes .. "herosoul.png")
		icon:anch(0, 0.3):pos(expLabel:getPositionX() + expLabel:getContentSize().width + 10, yPos):addTo(itemBg)

		ui.newTTFLabel({ text = string.format("X%d", taskData.heroSoul), size = 20, color = uihelper.hex2rgb("#742a0f") }) 
			:anch(0, 0.5):pos(icon:getPositionX() + icon:getContentSize().width, yPos):addTo(itemBg)
		resultText = resultText .. "  将魂 +" .. taskData.heroSoul
	end

	if finishCount < taskData.count or (isYueka and game.role:isYuekaExpired()) then
		local recvBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png"},
			{	
				parent = self.taskScroll:getLayer(),
				text = { text = "前往", font = ChineseFont, size = 32, strokeColor = display.COLOR_FONT, strokeSize = 2 },
				priority = self.priority,
				callback = function()
					self.DailyTaskField[taskId].goto()
				end,
			}):getLayer()
		recvBtn:anch(1, 0):pos(cellSize.width - 10, 16):addTo(itemBg)
	else
		local recvBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png"},
			{	
				parent = self.taskScroll:getLayer(),
				text = { text = "领取", font = ChineseFont, size = 32, strokeColor = display.COLOR_FONTGREEN, strokeSize = 2 },
				priority = self.priority,
				callback = function()
					local bin = pb.encode("SimpleEvent", { roleId = game.role.id, param1 = taskId })
					game:sendData(actionCodes.RoleRecvTaskAwardRequest, bin)
					loadingShow()

					local origLevel = game.role.level
					game:addEventListener(actionModules[actionCodes.RoleRecvTaskAwardResponse], function(event)
						loadingHide()
						self:initTaskList()
						--需要修改：
						DGMsgBox.new({ type = 1, text = resultText })

						game.role:dispatchEvent({ name = "notifyNewMessage", type = "dailyTask" })
					end)
				end,
			}):getLayer()
		if isYueka then
			recvBtn:anch(1, 0):pos(cellSize.width - 10, 16):addTo(itemBg)
		else
			recvBtn:anch(1, 0.5):pos(cellSize.width - 10, cellSize.height/2):addTo(itemBg)
		end
	end

	return itemBg
end

function DailyTaskLayer:getLayer()
	return self.mask:getLayer()
end

return DailyTaskLayer