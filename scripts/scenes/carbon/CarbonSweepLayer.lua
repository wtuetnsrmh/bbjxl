-- 副本扫荡UI层
-- by yangkun
-- 2014.6.23

local CarbonSweepRes = "resource/ui_rc/carbon/sweep/"
local GlobalRes = "resource/ui_rc/global/"
local VipRes = "resource/ui_rc/shop/vip/"
local PvpRes = "resource/ui_rc/pvp/"

local AssistHeroLayer = require("scenes.carbon.AssistHeroLayer")
local ItemTipsLayer = require("scenes.home.ItemTipsLayer")
local HealthUseLayer  = require("scenes.home.HealthUseLayer")
local SellLayer = import("..home.hero.SellLayer")
local HeroDecomposeLayer = import("..home.hero.HeroDecomposeLayer")
local CarbonSweepResultLayer = import(".CarbonSweepResultLayer")
local ConfirmDialog = import("..ConfirmDialog")

local CarbonSweepLayer = class("CarbonSweepLayer", function(params) 
	return display.newLayer(GlobalRes .. "rank/rank_bg.png") 
end)

function CarbonSweepLayer:ctor(params)
	self.params = params or {}
	self.closeCallback = params.closeCallback
	self.vipData = vipCsv:getDataByLevel(game.role.vipLevel)

	self.size = self:getContentSize()
	self.priority = params.priority or -129

	self:initCarbonData()
	self:initMaskLayer()
	self:initContentLayer()
	self.tipsTag = 8989

	self.showSweepResult = false

	self.updateVipLevelHandler = game.role:addEventListener("updateVipLevel", function(event)
		self.vipData = vipCsv:getDataByLevel(game.role.vipLevel)
    	self:initRightContentLayer()
    end)
	
end

function CarbonSweepLayer:onEnter()
	self:checkGuide()
end

function CarbonSweepLayer:initCarbonData()
	self.sweepResult = pb.decode("CarbonSweepResult", game.role.sweepResult)["result"]

	self.carbonId = self.params.carbonId
	self.carbonCsvData = mapBattleCsv:getCarbonById(self.carbonId)
	self.carbonData = game.role.carbonDataset[self.carbonId]
	self.dropData = dropCsv:getDropData(self.carbonId)[1]
end

-- 遮罩层
function CarbonSweepLayer:initMaskLayer()

	-- 遮罩层
	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.maskLayer = DGMask:new({ item = self , priority = self.priority, click = function()
			-- self:getLayer():removeSelf()
		end})

	local NameBarLayer = display.newSprite(GlobalRes .. "title_bar_long.png"):anch(0.5, 1):pos(self.size.width/2, self.size.height - 13):addTo(self)
	ui.newTTFLabel({text = self.carbonCsvData.name, font = ChineseFont, size = 36, color = uihelper.hex2rgb("#fde335")})
		:anch(0.5, 0.5):pos(NameBarLayer:getContentSize().width / 2, NameBarLayer:getContentSize().height / 2):addTo(NameBarLayer)

	local closeBtn = DGBtn:new( GlobalRes, {"close_normal.png", "close_selected.png"}, {
			touchScale = 1.5,
			priority =self.priority-1,
			callback = function()
				if self.closeCallback then
					self.closeCallback()
				end
				self:purgeItemTaps()
				self:getLayer():removeSelf()
			end
		}):getLayer()
	closeBtn:anch(0.5, 0.5):pos(self.size.width, self.size.height):addTo(self)
end

-- 内容层
function CarbonSweepLayer:initContentLayer()
	if self.contentLayer then
		self.contentLayer:removeSelf()
	end

	self.contentLayer = display.newLayer()
	self.contentLayer:setContentSize(self:getContentSize())
	self.contentLayer:addTo(self)

	self:initLeftContentLayer()
	self:initRightContentLayer()
end

-- 左边层
function CarbonSweepLayer:initLeftContentLayer()
	if self.leftContentLayer then
		self.leftContentLayer:removeSelf()
	end

	self.leftContentLayer = display.newLayer()
	self.leftContentLayer:size(450, self.contentLayer:getContentSize().height):addTo(self.contentLayer)

	self:createLeftLayer()
end

-- 右边层
function CarbonSweepLayer:initRightContentLayer()
	if self.rightContentLayer then
		self.rightContentLayer:removeSelf()
	end

	self.rightContentLayer = display.newLayer()
	self.rightContentLayer:size(370, self.contentLayer:getContentSize().height - 20)
		:pos(self.leftContentLayer:getContentSize().width, 0):addTo(self.contentLayer)

	self:createRightLayer()
end

function CarbonSweepLayer:getLeftTimeString()
	return os.date("%X", 16*3600 + self.sweepLeftTime)
end

function CarbonSweepLayer:updateTime()
	self.sweepLeftTime = self.sweepLeftTime - 1

	if self.sweepLeftTime > 0 then		
		self.sweepLabel:setString(self:getLeftTimeString())
	else
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.timeScheduleHandler)
		game.role.sweepStartTime = 0
		game.role.sweepCount = 0
		game.role.sweepResult = ""
		game.role.canSweep = 1
		self.sweepResult = nil

		self:initCarbonData()
		self:initLeftContentLayer()
		self:initRightContentLayer()
	end
end

function CarbonSweepLayer:createLeftLayer()
	local bossData = unitCsv:getUnitByType(self.carbonCsvData.bossId)
	local leftSize = self.leftContentLayer:getContentSize()
	--武将头像
	local heroBox = display.newLayer()
	heroBox:size(325, 304)
	heroBox:anch(0,0):pos(31, self.size.height - 423):addTo(self.leftContentLayer)
	local boxSize = heroBox:getContentSize()

	local scale = 325 / 640
	local heroCard = CCSpriteExtend.extend(CCSprite:create(bossData.cardRes, CCRectMake(0, 0, 640, 304 /scale)))
	heroCard:scale(scale):pos(boxSize.width / 2, boxSize.height / 2):addTo(heroBox)
	display.newSprite(CarbonSweepRes .. "boss_frame.png")
		:pos(boxSize.width / 2, boxSize.height / 2):addTo(heroBox)
	--boss名字
	ui.newTTFLabelWithStroke({ text = self.carbonCsvData.bossName, size = 24, font = ChineseFont, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#222222") })
		:anch(0, 0):pos(10, 8):addTo(heroBox)
	-- 副本描述
	uihelper.createLabel({text = self.carbonCsvData.desc, width = 330, color = display.COLOR_WHITE, size = 20})
		:anch(0, 1):pos(-4, -10):addTo(heroBox)
	--星级
	local carbonData = game.role.carbonDataset[self.carbonId]
	local startX = 295
	local interval = 45
	for index = 1, 3 do
		local starSprite
		if index <= carbonData.starNum then
			starSprite = display.newSprite( GlobalRes .. "star/icon_popup.png")	
		else
			starSprite = display.newSprite( GlobalRes .. "star/icon_gray.png")
		end
		starSprite:anch(0,0):pos(startX + (index -1)*interval , boxSize.height + 10):addTo(heroBox)
	end

	--体力消耗
	local healthBg = display.newSprite(CarbonSweepRes .. "health_bg.png")
	healthBg:anch(0, 0):pos(0, boxSize.height + 22):addTo(heroBox)
	local text = ui.newTTFLabelWithStroke({text = string.format("体力消耗：%d", self.carbonCsvData.consumeValue), size = 20, strokeColor = uihelper.hex2rgb("#222222")})
		:anch(0, 0.5):pos(10, healthBg:getContentSize().height/2):addTo(healthBg)
	display.newSprite(GlobalRes .. "chicken.png")
		:anch(0, 0.5):pos(text:getContentSize().width + 5, text:getContentSize().height/2):addTo(text)
	
end

function CarbonSweepLayer:createRightLayer()
	local rightSize = self.rightContentLayer:getContentSize()

	local dropBg = display.newSprite(CarbonSweepRes .. "drop_bg.png")
	local bgSize = dropBg:getContentSize()
	dropBg:anch(0.5, 0.5):pos(rightSize.width / 2 - 69, rightSize.height - 179):addTo(self.rightContentLayer)

	local cards = {}
	for index, drop in pairs(self.dropData.specialDrop) do
		if tonumber(drop[4]) > 0 then
			local itemId = tonumber(drop[1])
			local itemInfo = itemCsv:getItemById(itemId)
			cards[tonumber(drop[4])] = { itemTypeId = itemInfo.type, itemId = itemId }
		end
	end

	local startX, yPos = 5, 22
	local interval = 100
	local cards = table.values(cards)
	local nums = table.nums(cards)
	local itemsView = DGScrollView:new({ size = CCSizeMake(bgSize.width - 16, bgSize.height), divider = 4, horizontal = true, priority = self.priority-1 })
	for index = 1, nums do
		if cards[index] then
			local itemFrame = ItemIcon.new({ itemId = cards[index].itemId,
				priority = self.priority-1,
				parent = dropBg,
				callback = function()
					self:showItemTaps(tonum(cards[index].itemId),1,cards[index].itemTypeId)
				end,
				}):getLayer()
			itemFrame:scale(0.9):anch(0, 0)
			itemsView:addChild(itemFrame)
		end
	end
	itemsView:getLayer():anch(0.5, 0):pos(bgSize.width/2, 22):addTo(dropBg)

	if nums >= 4 then
		display.newSprite(VipRes.."arrow_left.png"):anch(0.5, 0):pos(-4, 47):addTo(dropBg)
		display.newSprite(VipRes.."arrow_right.png"):anch(0.5, 0):pos(bgSize.width + 6, 47):addTo(dropBg)
	end

	local leftPlayCount = self.carbonCsvData.playCount - self.carbonData.playCnt
	local perHealth = self.carbonCsvData.consumeValue
	local healthCount = math.floor( game.role.health / perHealth )
	local sweepCount = healthCount >= 5 and 5 or healthCount
	self.sweepCount = sweepCount >= leftPlayCount and leftPlayCount or sweepCount

	local hasOtherTips = false
	local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
	local tips
	if roleInfo.sweepOpen < 1 then
		local sysMsg = sysMsgCsv:getMsgbyId(554)
		tips = string.format(sysMsg.text, math.abs(roleInfo.sweepOpen))
	elseif self.carbonData.starNum < 3 then
		tips = "3星通关开启扫荡"
	end

	
	if tips then
		hasOtherTips = true
		local tipsBg = display.newSprite(CarbonSweepRes .. "tips_bg.png")
		tipsBg:anch(0, 0.5):pos(18, -32):addTo(dropBg)
		ui.newTTFLabelWithStroke({ text = tips, size = 18, color = display.COLOR_RED, strokeColor = uihelper.hex2rgb("#222222")})
			:anch(0.5, 0.5):pos(tipsBg:getContentSize().width/2, tipsBg:getContentSize().height/2):addTo(tipsBg)
	end

	local leftSweepCount = self.vipData.sweepCount - game.role.sweepCount
	leftSweepCount = leftSweepCount < 0 and 0 or leftSweepCount
	if self.vipData.sweepCount ~= 0 and not hasOtherTips and self.carbonCsvData.type ~= 3 then
		local tipsBg = display.newSprite(GlobalRes .. "label_bg.png")
		tipsBg:anch(0, 0.5):pos(18, -32):addTo(dropBg)

		local xPos, yPos = 10, tipsBg:getContentSize().height/2
		local text = ui.newTTFLabelWithStroke({ text = "扫荡剩余次数：", size = 18, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#222222")})
		text:anch(0, 0.5):pos(xPos, yPos):addTo(tipsBg)
		xPos = xPos + text:getContentSize().width
		text = ui.newTTFLabelWithStroke({ text = leftSweepCount, size = 18, color = self.vipData.sweepCount > game.role.sweepCount and display.COLOR_GREEN or display.COLOR_RED, strokeColor = uihelper.hex2rgb("#222222")})
		text:anch(0, 0.5):pos(xPos, yPos):addTo(tipsBg)
		xPos = xPos + text:getContentSize().width
		text = ui.newTTFLabelWithStroke({ text = "/" .. self.vipData.sweepCount, size = 18, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#222222")})
		text:anch(0, 0.5):pos(xPos, yPos):addTo(tipsBg)
		xPos = xPos + text:getContentSize().width + 5
		
		DGBtn:new(HomeRes, {"add.png"}, {
		priority = self.priority - 1,
		callback = function()
			local confirmDialog
			confirmDialog = ConfirmDialog.new({
				priority = self.priority - 10,
				showText = { text = "VIP等级越高，每日扫荡次数越多！\nVIP 4级扫荡无限次！", size = 24, },
				button1Data = {
					priority = self.priority - 10,
					text = "知道了", font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2,
				},
				button2Data = {
					priority = self.priority - 10,
					text = "去充值", font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2,
					callback = function()
						confirmDialog:getLayer():removeSelf()
						local ReChargeLayer = require("scenes.home.shop.ReChargeLayer")
						local layer = ReChargeLayer.new({priority = self.priority - 10})
						layer:getLayer():addTo(display.getRunningScene())
					end,
				},
			})
			confirmDialog:getLayer():addTo(display.getRunningScene())
		end,
		}):getLayer():anch(0.5, 0.5):pos(tipsBg:getContentSize().width, yPos):addTo(tipsBg)	
	end
	

	-- 已通关 可扫荡
	local sweepBtn = DGBtn:new(CarbonSweepRes, {"sweep_btn_normal.png","sweep_btn_select.png","sweep_btn_disable.png"},
	{
		priority = self.priority - 1,
		callback = function()
			-- 扫荡未开启
			local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)	
			if roleInfo.sweepOpen < 1 then
				local sysMsg = sysMsgCsv:getMsgbyId(554)
				DGMsgBox.new({text = string.format(sysMsg.text, math.abs(roleInfo.sweepOpen)), type = 1})
				return
			end

			if self.carbonData.starNum < 3 then
				DGMsgBox.new({text = "3星通关副本后可以扫荡", type = 1})
				return
			end

			if math.floor( game.role.health / perHealth ) <= 0 then
				local HealthUseLayer = require("scenes.home.HealthUseLayer")
				local layer = HealthUseLayer.new({ priority = self.priority -10})
				layer:getLayer():addTo(display.getRunningScene())
				return
			end

			if leftPlayCount <= 0 then
				DGMsgBox.new({text = "今日挑战次数不足", type = 1})
				return
			end

			-- 剩余扫荡次数不足
			if self.vipData.sweepCount ~= 0 and self.vipData.sweepCount <= game.role.sweepCount then
				DGMsgBox.new({msgId = 553})	
				return
			end

			-- 背包满
			if game.role:isHeroBagFull() then
				DGMsgBox.new({ msgId = 111,
					button1Data = { text = "去分解", priority = -9000,
						callback = function()
							local layer = HeroDecomposeLayer.new({priority = self.priority - 10})
							layer:getLayer():addTo(display.getRunningScene())
						end
					},
					button2Data = { text = "去出售", priority = -9000,
						callback = function()
							local layer = SellLayer.new({priority = self.priority - 10})
							layer:getLayer():addTo(display.getRunningScene())
						end
					}		
				 })
				return
			end

			local layer = CarbonSweepResultLayer.new({
				priority = self.priority - 10, 
				carbonId = self.carbonId, 
				callback = function()
					self:initLeftContentLayer()
					self:initRightContentLayer()
				end
				})
			layer:getLayer():addTo(display.getRunningScene())
		end,
		priority = -130
	})

	sweepBtn:getLayer():anch(0, 1):pos(51, -63):addTo(dropBg)

	self.sweepBtn = sweepBtn

	-- 挑战按钮
	self.fightBtn = DGBtn:new(CarbonSweepRes, {"fight_btn_normal.png","fight_btn_select.png","fight_btn_disable.png"},
		{
			priority = self.priority - 1,
			multiClick = false,
			callback = function()
				local perHealth = self.carbonCsvData.consumeValue
				local healthCount = math.floor(game.role.health / perHealth)
				if healthCount <= 0 then
					local layer = HealthUseLayer.new({ priority = self.priority - 10, parent = self})
					layer:getLayer():addTo(display.getRunningScene())	

					return
				end

				if leftPlayCount <= 0 and (self.carbonCsvData.type ~= 3 or self.carbonData.starNum > 0) then
					DGMsgBox.new({text = "今日挑战次数不足", type = 1})
					return
				end

				if game.role.health >= self.carbonCsvData.consumeValue then
					if game.role:isHeroBagFull() then
						DGMsgBox.new({ msgId = 111,
							button1Data = { text = "去分解", priority = -9000,
								callback = function()
									local layer = HeroDecomposeLayer.new({priority = self.priority - 10})
									layer:getLayer():addTo(display.getRunningScene())
								end
							},
							button2Data = { text = "去出售", priority = -9000,
								callback = function()
									local layer = SellLayer.new({priority = self.priority - 10})
									layer:getLayer():addTo(display.getRunningScene())
								end
							}	
						 })
						return
					end

					-- 前五关不弹好友助战
					local assistChooseAction = { roleId = game.role.id, chosenRoleId = 0, carbonId = self.carbonId }
					local bin = pb.encode("AssistChooseAction", assistChooseAction)

					game:sendData(actionCodes.CarbonAssistChooseRequest, bin, #bin)
					game:addEventListener(actionModules[actionCodes.CarbonAssistChooseResponse], function(event)
						local msg = pb.decode("CarbonEnterAction", event.data)
						switchScene("battle", { carbonId = msg.carbonId, battleType = BattleType.PvE })	
						return "__REMOVE__"
					end)
				else
					local layer = HealthUseLayer.new({ priority = self.priority - 10, parent = self})
					layer:getLayer():addTo(display.getRunningScene())	
				end
			end,
			priority = -130
		})
	
	self.fightBtn:getLayer():anch(0, 1):pos(223, -63):addTo(dropBg)

	local isRestBtnShow = leftPlayCount <= 0 and self.carbonCsvData.type == 2
	
	local xPos, yPos = 10, 0
	local leftCountBg
	if self.carbonCsvData.type ~= 1 then
		leftCountBg = display.newSprite(CarbonSweepRes .. "left_count_bg.png")
		leftCountBg:anch(0, 0.5):pos(143, bgSize.height + 29):addTo(dropBg)
		yPos = leftCountBg:getContentSize().height/2
		local maxCount = self.carbonCsvData.playCount
		local text = ui.newTTFLabelWithStroke({text = "今日挑战次数：", size = 20, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#222222")})
		text:anch(0, 0.5):pos(xPos, yPos):addTo(leftCountBg)
		xPos = xPos + text:getContentSize().width
		text = ui.newTTFLabelWithStroke({text = leftPlayCount, size = 20, color = leftPlayCount == 0 and display.COLOR_RED or display.COLOR_GREEN, strokeColor = uihelper.hex2rgb("#222222")})
		text:anch(0, 0.5):pos(xPos, yPos):addTo(leftCountBg)
		xPos = xPos + text:getContentSize().width
		text = ui.newTTFLabelWithStroke({text = "/" .. maxCount, size = 20, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#222222")})
		text:anch(0, 0.5):pos(xPos, yPos):addTo(leftCountBg)
		xPos = xPos + text:getContentSize().width + 5
	end

	--添加购买按钮
	if isRestBtnShow then
		DGBtn:new(HomeRes, {"add.png"},
		{
			priority = self.priority - 10,
			callback = function()
				canBuyLevel = vipCsv:getCanBuyVipLevel("challengeCount")
				local desc = nil
				local vipData = vipCsv:getDataByLevel(game.role.vipLevel)
				local tipsBg = display.newSprite(GlobalRes .. "confirm_bg.png")
				local bgSize = tipsBg:getContentSize()
				local tipsMask = DGMask:new({ item = tipsBg, priority = self.priority - 30 })
				tipsMask:getLayer():addTo(display.getRunningScene())
				tipsBg:anch(0.5, 0.5):pos(display.cx, display.cy)

				--vip等级不够
				if game.role.vipLevel < canBuyLevel then
					desc = string.format("VIP%d以上才可以重置精英副本", canBuyLevel)
				end

				
				if self.carbonData.buyCnt >= vipData.challengeCount then
					--vip可购买剩余次数不够
					if not desc then
						desc = string.format("今日已经重置精英关卡%d次。\n重置精英关卡次数不足，提升vip等级可获得更多的次数。", self.carbonData.buyCnt)
					end
					DGBtn:new(GlobalRes, {"middle_normal.png","middle_selected.png","middle_disabled.png"},
					{
						priority = self.priority - 40,
						text = { text = "vip特权", size = 26, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
						callback = function()
							local VipLayer = require("scenes.home.shop.VipLayer")
							local vipLayer = VipLayer.new({ priority = self.priority - 10})
							vipLayer:getLayer():addTo(display.getRunningScene(),999)
							tipsMask:getLayer():removeSelf()
						end
					}):getLayer():anch(1, 0):pos(bgSize.width - 80, 15):addTo(tipsBg)
				else
					if not desc then
						local priceTable = string.toTableArray(globalCsv:getFieldValue("priceOfHardChallenge"))
						local price
						for i=1, 3 do
							if self.carbonData.buyCnt >= tonum(priceTable[i][1]) and self.carbonData.buyCnt <= tonum(priceTable[i][2]) then
								price = tonum(priceTable[i][3])
								break
							end
						end			

						desc = string.format("您是否花费%d元宝重置1次副本挑战次数？\n今日已重置%d次", price, self.carbonData.buyCnt)
					end
					DGBtn:new(GlobalRes, {"middle_normal.png","middle_selected.png","middle_disabled.png"},
					{
						priority = self.priority - 40,
						text = { text = "确认购买", size = 26, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
						callback = function()
							
							local bin = pb.encode("SimpleEvent", { roleId = game.role.id, param1 = self.carbonId })
							game:sendData(actionCodes.CarbonResetRequest, bin, #bin)
							loadingShow()
							game:addEventListener(actionModules[actionCodes.CarbonResetResponse], function(event)
								loadingHide()
								
								self.carbonData.playCnt = 0
								self.carbonData.buyCnt = self.carbonData.buyCnt + 1
								self:initLeftContentLayer()
								self:initRightContentLayer()
								tipsMask:getLayer():removeSelf()	
							end)	
						end
					}):getLayer():anch(1, 0):pos(bgSize.width - 80, 15):addTo(tipsBg)
				end
				--统一构造取消按钮和提示内容
				DGBtn:new(GlobalRes, {"middle_normal.png","middle_selected.png","middle_disabled.png"},
				{
					priority = self.priority - 40,
					text = { text = "取消", size = 26, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
					callback = function()
						tipsMask:getLayer():removeSelf()
					end
				}):getLayer():anch(0, 0):pos(80, 15):addTo(tipsBg)

				ui.newTTFLabel({ text = desc, size = 26, color = display.COLOR_WHITE })
					:anch(0.5, 0.5):pos(bgSize.width / 2, bgSize.height / 2 + 20):addTo(tipsBg)
			end,
		}):getLayer():anch(0.6, 0.5):pos(leftCountBg:getContentSize().width, yPos):addTo(leftCountBg)
	end

end

function CarbonSweepLayer:createSweepTableLayer()
	local leftSize = self.leftContentLayer:getContentSize()

	self.tableViewLayer = display.newLayer()
	self.tableViewLayer:size(390,444):pos(20, leftSize.height - 506):addTo(self.leftContentLayer)

	self.tableView = self:createResultTable()
	self.tableView:setPosition(0,0)
	self.tableViewLayer:addChild(self.tableView)
end

function CarbonSweepLayer:createResultTable()

	local handler = LuaEventHandler:create(function(fn, tbl, a1, a2)
        local r
        if fn == "cellSize" then
        	local resultCount = table.nums(self.sweepResult)
			local result = self.sweepResult[resultCount - a1]

			if #result.dropItems >= 4 then
				r = CCSizeMake(390, 334)
			else
				r = CCSizeMake(390, 224)
			end
            
        elseif fn == "cellAtIndex" then
			if not a2 then
                a2 = CCTableViewCell:new()
                local cell = display.newNode()
                a2:addChild(cell, 0, 1)
            end

            local cell = tolua.cast(a2:getChildByTag(1), "CCNode")
            cell:removeAllChildren()

            local index = a1
            self:createResultTableCell(cell, index)
            r = a2
        elseif fn == "numberOfCells" then
            r = table.nums(self.sweepResult)
        end

        return r
    end)

	local resultTableView = LuaTableView:createWithHandler(handler, self.tableViewLayer:getContentSize())
    resultTableView:setBounceable(true)
    resultTableView:setTouchPriority(-130)
	return resultTableView
end

function CarbonSweepLayer:createResultTableCell(cell, index)
	local resultCount = table.nums(self.sweepResult)
	local result = self.sweepResult[resultCount - index]

	local cellSize
	if #result.dropItems >= 4 then
		cellSize = CCSizeMake(390, 334)
	else
		cellSize = CCSizeMake(390, 224)
	end

	local introBg = display.newSprite( CarbonSweepRes .. "sweep_title.png")
	introBg:anch(0,0):pos(0, cellSize.height - 59):addTo(cell)

	ui.newTTFLabel({text = string.format("第%d次扫荡",resultCount - index ), size = 24, color = display.COLOR_WHITE})
	:anch(0,0.5):pos(10, introBg:getContentSize().height/2):addTo(introBg)

	ui.newTTFLabel({text = string.format("经验 +%d   金币 +%d", result.exp, result.money), size = 20, color = display.COLOR_GREEN})
	:anch(0,0):pos(30, cellSize.height - 95):addTo(cell)

	local priority = -140
	for index = 1, #result.dropItems do
		local x = 30 + (index - 1) * 100
		local y = #result.dropItems >= 4 and 140 or 30

		if index == 4 then
			x = 30
			y = 30
		end

		local dropItem = result.dropItems[index]
		if dropItem.itemTypeId == ItemTypeId.Hero or dropItem.itemTypeId == ItemTypeId.HeroFragment then
			local itemId = dropItem.itemTypeId == ItemTypeId.Hero and dropItem.itemId - 1000 or dropItem.itemId - 2000
			local cardFrame = HeadFrame.new({ 
				type = dropItem.itemTypeId == ItemTypeId.Hero and itemId or itemId + 2000,
				priority = priority,
				callback = function()
					self:showItemTaps(itemId,1,dropItem.itemTypeId)
				end
				}):getLayer()
			cardFrame:scale(0.8):anch(0,0):pos(x, y):addTo(cell)

			local unitData = unitCsv:getUnitByType(itemId)
			local name = ui.newTTFLabel({text = unitData.name, size = 22, color = display.COLOR_WHITE})
			name:anch(0.5,1):pos(cardFrame:getContentSize().width/2, -5):addTo(cardFrame)
		elseif itemCsv:isItem(dropItem.itemTypeId) then
			local itemFrame = ItemFrame.new({ itemId = dropItem.itemId, 
					callback = function() 
						self:showItemTaps(dropItem.itemId,1,dropItem.itemTypeId)
					end,
					priority = priority,
				}):getLayer()
			itemFrame:scale(0.8):anch(0,0):pos(x, y):addTo(cell)

			local itemData = itemCsv:getItemById(dropItem.itemId)
			ui.newTTFLabel({text = itemData.name, size = 22, color = display.COLOR_WHITE})
				:anch(0.5,1):pos(itemFrame:getContentSize().width/2, -5):addTo(itemFrame )
		end
	end

	display.newSprite( CarbonSweepRes .. "line.png"):anch(0,0):pos(0,0):addTo(cell)
end

function CarbonSweepLayer:showItemTaps(itemId,itemNum,itemType)
	self:purgeItemTaps()
	local itemTipsView = require("scenes.home.ItemTipsLayer")
	local itemTips = itemTipsView.new({
		itemId = itemId,
		itemNum = itemNum,
		itemType = itemType,
		showSource = false,
	})
	display.getRunningScene():addChild(itemTips:getLayer())
	itemTips:setTag(self.tipsTag)

end

function CarbonSweepLayer:checkGuide(remove)
	game:addGuideNode({node = self.fightBtn:getLayer(), remove = remove,
		guideIds = {1006, 1027, 950, 951, 952, 953, 954, 955}
	})
end

function CarbonSweepLayer:onExit()
	self:checkGuide(true)
end

function CarbonSweepLayer:purgeItemTaps()
	if display.getRunningScene():getChildByTag(self.tipsTag) then
		display.getRunningScene():getChildByTag(self.tipsTag):removeFromParent()
	end
end

function CarbonSweepLayer:getLayer()
	return self.maskLayer:getLayer()
end

function CarbonSweepLayer:onExit()
	game.role:removeEventListener("updateVipLevel", self.updateVipLevelHandler)

end


return CarbonSweepLayer