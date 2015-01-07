-- 充值界面
-- by yangkun
-- 2014.6.30

local ShopRes = "resource/ui_rc/shop/"
local ReChargeRes = "resource/ui_rc/shop/recharge/"
local VipRes = "resource/ui_rc/shop/vip/"
local GlobalRes = "resource/ui_rc/global/"
local EvolutionRes = "resource/ui_rc/hero/evolution/"
local ActivityRes = "resource/ui_rc/activity/"

local VipLayer = import(".VipLayer")

local ReChargeLayer = class("ReChargeLayer", function()
	return display.newLayer(ActivityRes .. "bg.jpg")
end)

function ReChargeLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -130
	self.size = self:getContentSize()
	self.yOffset = params.yOffset or 0

	self.lastVipLevel = game.role.vipLevel

	self:anch(0.5, 0):pos(display.cx, 20)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1 })

	local frame = display.newSprite(ActivityRes .. "bg_frame.png")
	frame:anch(0.5, 0):pos(self.size.width / 2, -10):addTo(self, 10)
	-- title
	display.newSprite(ReChargeRes .. "recharge_text.png"):anch(0.5,1)
		:pos(frame:getContentSize().width / 2, frame:getContentSize().height - 20)
		:addTo(frame)

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
				if params.callback then params.callback() end
				self:getLayer():removeSelf()
			end,
		}):getLayer()
	closeBtn:anch(1, 1):pos((display.width + 960) / 2, display.height):addTo(self:getLayer())

	self:initContentLayer()
end

function ReChargeLayer:initContentLayer()
	if self.contentLayer then
		self.contentLayer:removeSelf()
	end

	self.contentLayer = display.newLayer()
	self.contentLayer:size(self.size)
	self.contentLayer:anch(0.5,0.5):pos(self.size.width/2, self.size.height/2):addTo(self)

	local yPos = self.size.height - 80

	-- 查看特权
	local lookBtn = DGBtn:new(ReChargeRes, {"btn_vip_normal.png", "btn_vip_pressed.png"}, {
		priority = self.priority -1,
		callback = function()
			local vipLayer = VipLayer.new({ priority = self.priority - 10})
			vipLayer:getLayer():addTo(display.getRunningScene())
		end,
	})
	lookBtn:getLayer():anch(0, 0.5):pos(40, yPos):addTo(self.contentLayer)

	if game.role.vipLevel > 0 then
		display.newSprite(ReChargeRes .. "vip_text_" .. game.role.vipLevel .. ".png")
			:anch(0, 0.5):pos(210, yPos):addTo(self.contentLayer)
	else
		display.newSprite(ReChargeRes.."vip_text_0.png")
			:anch(0,0.5):pos(210,yPos):addTo(self.contentLayer)
	end

	-- 充值进度条
	local moneySlot = display.newSprite(GlobalRes .. "exp_slot.png")
	moneySlot:anch(0, 0.5):pos(300, yPos):addTo(self.contentLayer)

	local vipData = vipCsv:getDataByRechargeRMB(game.role.rechargeRMB)
	vipData = vipData or vipCsv:getDataByLevel(vipCsv.vipLevelMax)
	local ratio = (game.role.rechargeRMB > vipData.rechargeRMB) and 100 or (game.role.rechargeRMB / vipData.rechargeRMB * 100)
	local moneyProgress = display.newProgressTimer(GlobalRes .. "exp_bar.png", display.PROGRESS_TIMER_BAR)
	moneyProgress:setMidpoint(ccp(0, 0))
	moneyProgress:setBarChangeRate(ccp(1,0))
	moneyProgress:setPercentage(ratio)
	moneyProgress:pos(moneySlot:getContentSize().width / 2, moneySlot:getContentSize().height / 2):addTo(moneySlot)

	local textBg = display.newSprite(ReChargeRes .. "text_bg.png"):anch(0, 0.5):pos(540, yPos):addTo(self.contentLayer, -1)
	if game.role.rechargeRMB < vipData.rechargeRMB then
		ui.newTTFLabelWithStroke({ text = string.format("再充值%d元, 您将成为", vipData.rechargeRMB - game.role.rechargeRMB), size = 22,
			color = uihelper.hex2rgb("#ffd200"), strokeColor = uihelper.hex2rgb("#242424")})
			:anch(0.5, 0.5):pos(textBg:getContentSize().width/2, textBg:getContentSize().height/2):addTo(textBg)
		display.newSprite(ReChargeRes .. "vip_text_" .. vipData.vipLevel .. ".png")
			:anch(0, 0.5):pos(820, yPos):addTo(self.contentLayer)
	end

	self:createRechargeScrollLayer()

	if game.role.vipLevel > self.lastVipLevel then --是否升级：
		self:showVipLevelUp()
		self.lastVipLevel = game.role.vipLevel
	end
end

function ReChargeLayer:createRechargeScrollLayer()
	local layer = display.newLayer()
	local layerSize = CCSizeMake(self.size.width - 10, 410)
	layer:size(layerSize):anch(0.5, 0):pos(self.size.width / 2, 30):addTo(self.contentLayer)

	local rechargeScroll = DGScrollView:new({priority = self.priority - 1, size = layerSize, divider = 5 })

	local function createScrollNode(rechargeData)
		local isYueka = rechargeData.yuekaFlag == 1

		local cellBg = DGBtn:new(ReChargeRes, {"cell_bg.png"}, {
				parent = rechargeScroll:getLayer(),
				priority = self.priority,
				callback = function()
				if isYueka and math.ceil((game.role.yuekaDeadline - game:nowTime()) / (24 * 3600)) > 3 then
					DGMsgBox.new({text = "月卡使用中，月卡剩余天数小于3天可续费", type = 1})
					return
				end

				local rechargeRequest = { roleId = game.role.id, param1 = rechargeData.id, param2 = 1 }
				local bin = pb.encode("SimpleEvent", rechargeRequest)
				game:sendData(actionCodes.StoreRechargeRequest, bin, #bin)
				game:addEventListener(actionModules[actionCodes.StoreRechargeResponse], function(event)
					local msg = pb.decode("RechargeResponse", event.data)

					self.yOffset = rechargeScroll:getOffsetY()
					self:initContentLayer()
					return "__REMOVE__"
				end)
			end,
			}):getLayer()
		local cellSize = cellBg:getContentSize()

		ui.newTTFLabel({ text = rechargeData.title, size = 20})
			:pos(cellSize.width / 2 - 10, cellSize.height - 30):addTo(cellBg)

		display.newSprite(ReChargeRes .. rechargeData.res)
			:anch(0, 0.5):pos(0, cellSize.height / 2):addTo(cellBg)

		local toRecommend = false
		if isYueka then
			local nowTime = game:nowTime()
			if nowTime >= game.role.yuekaDeadline then
				local placeholde = ui.newTTFLabel({ text = "连续30天每天可领取120元宝", size = 18, color = uihelper.hex2rgb("#261d16") })
				placeholde:pos(cellSize.width / 2, cellSize.height / 2):addTo(cellBg)
			else
				local leftDays = math.ceil((game.role.yuekaDeadline - nowTime) / (24 * 3600))
				ui.newTTFLabel({ text = string.format("月卡使用中，剩余时间%d天", leftDays), size = 18, color = uihelper.hex2rgb("#261d16") })
					:pos(cellSize.width / 2, cellSize.height / 2):addTo(cellBg)
			end
			toRecommend = true
		else
			local giveYuanbao
			local limit = false
			if rechargeData.firstYuanbao == 0 or game.role.firstRecharge[tostring(rechargeData.id)] == 1 then
				giveYuanbao = rechargeData.freeYuanbao
			else
				toRecommend = true
				limit = true
				giveYuanbao = rechargeData.firstYuanbao
			end
			local text = ui.newTTFLabel({ text = string.format("另外赠送%d元宝", giveYuanbao), size = 18, color = uihelper.hex2rgb("#261d16") })
				:pos(cellSize.width / 2, cellSize.height / 2):addTo(cellBg)

			if limit then
				ui.newTTFLabel({text = "（限购1次）", size = 18, color = uihelper.hex2rgb("#dd1f5e")})
					:anch(0, 0):pos(text:getContentSize().width, 0):addTo(text)
			end
		end

		--推荐标记
		if toRecommend then
			display.newSprite(ReChargeRes .. "recommend_tag.png")
				:anch(1, 1):pos(cellSize.width, cellSize.height):addTo(cellBg)
		end

		display.newSprite(ReChargeRes .. "price_title.png"):pos(180, 25):addTo(cellBg)
		ui.newTTFLabelWithStroke({ text = "￥" .. rechargeData.rmbValue, size = 26, strokeColor = uihelper.hex2rgb("#242424")})
			:pos(260, 25):addTo(cellBg)


		return cellBg:anch(0,0)
	end

	local keys = table.keys(rechargeCsv.m_data)
	table.sort(keys, function(a, b) return a > b end)

	local cellSize = CCSizeMake(layerSize.width, 130)
	local xBegin = 5
	local xInterval = cellSize.width - 2 * xBegin - 2 * 440

	for index = 1, #keys, 2 do
		local cellNode = display.newNode()
		cellNode:size(cellSize)

		local leftNode = createScrollNode(rechargeCsv:getRechargeDataById(keys[index]))
		leftNode:anch(0, 0):pos(xBegin, 0):addTo(cellNode)

		local rightRechargeData = rechargeCsv:getRechargeDataById(keys[index + 1])
		if rightRechargeData then
			local rightNode = createScrollNode(rightRechargeData)
			rightNode:anch(0, 0):pos(xBegin + 440 + xInterval, 0):addTo(cellNode)
		end

		rechargeScroll:addChild(cellNode)
	end

	rechargeScroll:alignCenter()
	rechargeScroll:setOffset(self.yOffset)
	rechargeScroll:getLayer():pos(0, 0):addTo(layer)
end

function ReChargeLayer:showVipLevelUp()
	local node = display.newNode():pos(display.cx/2,display.cy/2):addTo(self,10)
	local light = display.newSprite(EvolutionRes.."light_halo.png"):pos(display.cx/2,display.cy/2):addTo(node)
	light:runAction(CCRepeatForever:create(CCRotateBy:create(1, 80)))
	local word = display.newSprite(ReChargeRes.."word_levelup.png")
	:pos(display.cx/2,display.cy/2):scale(0.01)
	:addTo(node):runAction(transition.sequence({
		   CCScaleTo:create(0.2, 1.1),	
		   CCScaleTo:create(0.2, 0.9),
		   CCScaleTo:create(0.2,1),
		   CCDelayTime:create(0.5),
		   CCCallFunc:create(function()
		   		node:removeAllChildren()
		   		node:removeFromParent()
		   	end)
		}))
end

function ReChargeLayer:getLayer()
	return self.mask:getLayer()
end

return ReChargeLayer