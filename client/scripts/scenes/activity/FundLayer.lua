local FundRes = "resource/ui_rc/activity/fund/"
local FirstReChargeRes = "resource/ui_rc/activity/recharge/"
local DrawCardRes = "resource/ui_rc/shop/drawcard/"
local ReChargeRes = "resource/ui_rc/shop/recharge/"

local FundLayer = class("FundLayer", function() 
	return display.newLayer(FirstReChargeRes.."accu_rech_bg.jpg") 
end)

local index = 1

function FundLayer:ctor(params)
	self.params = params or {}
	self.priority = params.priority or -129
	self.size = self:getContentSize()
	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.size):addTo(self)
	self:initUI()
end

function FundLayer:initUI()
	self.mainLayer:removeAllChildren()
	--上面背景
	local upperBg = display.newSprite(FundRes .. "upper_bg.png")
	upperBg:anch(0.5, 1):pos(self.size.width/2, self.size.height - 45):addTo(self.mainLayer)
	local upperBgSize = upperBg:getContentSize()
	--标语
	display.newSprite(FundRes .. "slogan_text.png")
		:anch(0, 1):pos(0, upperBgSize.height - 10):addTo(upperBg)
	--收益
	display.newSprite(FundRes .. "profit_text.png")
		:anch(1, 1):pos(upperBgSize.width - 5, upperBgSize.height - 20):addTo(upperBg)
	--文字
	local textBg = display.newSprite(FundRes .. "text_bg.png")
	textBg:anch(0, 0):pos(37, 20):addTo(upperBg)
	uihelper.createLabel({text = string.format("成长基金保送[color=ff82f516]%d级[/color]!等级达到[color=ff82f516]%d级[/color]可购买，每达到领取需求等级，即可领取相应元宝回报，元宝多多，收益多多。", fundCsv.maxLevel, globalCsv:getFieldValue("fundLevel")),
		size = 18, isRichLabel = true, width = 505}):anch(0.5, 0.5):pos(textBg:getContentSize().width/2, textBg:getContentSize().height/2):addTo(textBg)
	--购买按钮
	local buyBtn = DGBtn:new(DrawCardRes, {"drawBtn_normal.png", "drawBtn_pressed.png"},
		{	
			priority = self.priority - 1,
			callback = function()
				if not game.role.fund["isBought"] then
					self:sendRequest(0)
				end
			end,
	}):getLayer()
	buyBtn:anch(1, 0):pos(upperBg:getContentSize().width - 20, 20):addTo(upperBg)
	if game.role.fund["isBought"] then
		ui.newTTFLabelWithStroke({text = "已购买", size = 24, font = ChineseFont})
			:anch(0.5, 0.5):pos(buyBtn:getContentSize().width/2, buyBtn:getContentSize().height/2):addTo(buyBtn)
	else
		display.newSprite(GlobalRes .. "yuanbao.png")
			:anch(0, 0.5):pos(24, buyBtn:getContentSize().height/2):addTo(buyBtn)

		ui.newTTFLabelWithStroke({text = globalCsv:getFieldValue("fundCost"), size = 24, font = ChineseFont})
			:anch(0, 0.5):pos(65, buyBtn:getContentSize().height/2):addTo(buyBtn)
	end
	--下面背景
	local lowerBg = display.newSprite(FundRes .. "lower_bg.png")
	lowerBg:anch(0.5, 0):pos(self.size.width/2, 20):addTo(self.mainLayer)

	local xBegin, xInterval = 116, 170
	local yPos1, yPos2 = 264, 110
	local levels = table.keys(fundCsv.m_data)
	table.sort(levels)
	for index = 1, 8 do
		local level = tonum(levels[index])
		local data = fundCsv:getDataByLevel(level)
		if data then
			local xPos, yPos = xBegin + (index - 1)%4 * xInterval, index > 4 and yPos2 or yPos1
			local bg = display.newSprite(FundRes .. "item_icon_bg.png")
			bg:anch(0.5, 0.5):pos(xPos, yPos):addTo(lowerBg)
			local bgSize = bg:getContentSize()
			--图标
			display.newSprite(ReChargeRes .. data.res)
				:anch(0.5, 0.5):pos(bgSize.width/2, bgSize.height/2):addTo(bg)
			--等级
			local text = ui.newTTFLabelWithStroke({text = level, size = 30, font = ChineseFont, color = uihelper.hex2rgb("#83fe13")})
			text:anch(1, 1):pos(bgSize.width - 10, bgSize.height + 5):addTo(bg)
			ui.newTTFLabelWithStroke({text = "级", size = 16, font = ChineseFont, color = uihelper.hex2rgb("#ffdc38")})
				:anch(0, 0):pos(text:getContentSize().width, 0):addTo(text)
			--数量
			ui.newTTFLabelWithStroke({text = "X" .. data.yuanbao, size = 18, color = uihelper.hex2rgb("#82f516")})
				:anch(1, 0):pos(bgSize.width - 5, 0):addTo(bg)
			--领取按钮
			local btn = DGBtn:new(FundRes, {"btn_receive_normal.png", "btn_receive_selected.png", "btn_receive_disabled.png"}, {
					priority = self.priority - 1,
					callback = function()
						if not game.role.fund[tostring(level)] then
							self:sendRequest(level)
						end
					end,
				})
			btn:getLayer():anch(0.5, 1):pos(bgSize.width/2, 4):addTo(bg)
			btn:setEnable(not game.role.fund[tostring(level)])
			btn:setGray(not game.role.fund["isBought"] or level > game.role.level)
		end
	end
end

function FundLayer:sendRequest(level)
	local tips
	--0表示购买
	if level == 0 then
		if globalCsv:getFieldValue("fundLevel") > game.role.level then
			tips = "15级才能购买成长基金！"
		end
	else		
		if not game.role.fund["isBought"] then
			tips = "未购买基金"
		elseif level > game.role.level then
			tips = "人物等级不足！"
		end
	end

	if tips then
		DGMsgBox.new({text = tips, type = 1})
		return
	end

	local bin = pb.encode("SimpleEvent", {roleId = game.role.id, param1 = level})
	game:sendData(actionCodes.RoleGetFundRequest, bin)
	game:addEventListener(actionModules[actionCodes.RoleGetFundRequest], function(event)
		if level ~= 0 then
			local data = fundCsv:getDataByLevel(level)
			DGMsgBox.new({text = string.format("恭喜你获得%d元宝！", data.yuanbao), type = 1})
			game.role:dispatchEvent({ name = "notifyNewMessage", type = "fund" })
		end
		self:initUI()
		return "__REMOVE__"
    end)
end

return FundLayer