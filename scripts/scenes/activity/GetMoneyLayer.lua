-- 奖励内容展示：
local GiftRes = "resource/ui_rc/gift/"
local ShopRes = "resource/ui_rc/shop/"
local ParticleRes = "resource/ui_rc/particle/beauty/"
local ParRes = "resource/ui_rc/particle/"

local GetMoneyLayer = class("GetMoneyLayer", function() 
	return display.newLayer(GiftRes.."gift_frame.png") 
end)

function GetMoneyLayer:ctor(params)
	self:setNodeEventEnabled(true)
	self.params = params or {}
	self.priority = params.priority or -129
	self.size = self:getContentSize()

	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority - 1,ObjSize = self.size,
		click = function() end,
		clickOut = function()
			self:removeAllChildren()
			self:getLayer():removeFromParent()
		end,
	})

	self.bg = display.newSprite(GiftRes .. "gift_bg.png")
		:anch(0.5, 1):pos(self.size.width/2, self.size.height - 66):addTo(self, -1)

	self:initUIByData()
	pushLayerAction(self,true)
end

function GetMoneyLayer:initUIByData()

	--客户端：今天最多能够领取几次
	--服务端：今天已经领取了多少次

	self.hadgettime = game.role.moneybuytimes --今天已经领取的次数

	local vipData = vipCsv:getDataByLevel(game.role.vipLevel)
	self.maxTimes = vipData and vipData.moneyBuyLimit or 0
	self.curTimes = self.maxTimes - self.hadgettime

	if self.curTimes < 0 then self.curTimes = 0 end 

	self.gold 	= zhaoCaiCsv:getGoldByTimes(self.hadgettime + 1)
	self.money = zhaoCaiCsv:getMoneyByTimes(self.hadgettime + 1)
	--当大于19级时额外给予money
	if game.role.level > 19 then
		self.money = self.money + (game.role.level - 19) * 20
	end

	local ww,hh = self:getContentSize().width,self:getContentSize().height
	--标题文字：
	local itemBg = display.newSprite(GiftRes .. "zhaocai_title.png")
	itemBg:anch(0.5, 0.5):pos(ww * 0.5, hh - 56):addTo(self)

	self.treeBg = display.newSprite(GiftRes.."light_bg.png")
	self.treeBg:setPosition(ccp(self.size.width * 0.5, self.size.height * 0.5 - 20))
	self:addChild(self.treeBg,5)

	self.treeSp = display.newSprite(GiftRes.."yaoqianshu.png")
	self.treeSp:setPosition(ccp(self.size.width * 0.5, self.size.height * 0.5 + 20))
	self:addChild(self.treeSp,5)

	--今日剩余次数：
	ui.newTTFLabel({ text = "今日剩余", size = 25, color = display.COLOR_WHITE,dimensions = CCSizeMake(130, 50) })
		:anch(0.5, 0.5)
		:pos(self.bg:getContentSize().width * 0.16,self.bg:getContentSize().height * 0.78)
		:addTo(self.bg)
	ui.newTTFLabel({ text = "次", size = 25, color = display.COLOR_WHITE,})
		:anch(0.5, 0.5)
		:pos(self.bg:getContentSize().width * 0.18, self.bg:getContentSize().height * 0.7)
		:addTo(self.bg)

	--当前剩余多少次：
	self.timesLabel = ui.newTTFLabel({text = tostring(self.curTimes),
	 size = 25, font = ChineseFont,
	 color = display.COLOR_GREEN, 
	 strokeColor = display.COLOR_BLACK, 
	 strokeSize = 2 })
	:anch(0,0.5):pos(self.bg:getContentSize().width * 0.05, self.bg:getContentSize().height * 0.7):addTo(self.bg)

	local wordBg = display.newSprite(GiftRes.."text_bar.png")
	wordBg:setPosition(ccp(self.size.width * 0.5, self.size.height * 0.2))
	self:addChild(wordBg)
	local wordBgSize = wordBg:getContentSize()

	if self.curTimes == 0 then
		self.tipsLabel = ui.newTTFRichLabel({ text = "[color=ffff0000]招财次数已用完，请提升vip等级！[/color]",
			size = 24, color = display.COLOR_RED })
	else
		local content = string.format("消耗[color=ff00ff00] %d [/color]元宝，获得[color=ff00ff00] %d [/color]银币",
			self.gold, self.money)
		self.tipsLabel = ui.newTTFRichLabel({ text = content, size = 28 })
	end
	self.tipsLabel:pos(wordBgSize.width / 2, wordBgSize.height / 2):addTo(wordBg)

	self:buttonEffect(self.treeSp)

	self:showNTimesButton()
end 

function GetMoneyLayer:refreshViewByData()
	self.hadgettime = game.role.moneybuytimes 

	local vipData = vipCsv:getDataByLevel(game.role.vipLevel)
	self.maxTimes = vipData and vipData.moneyBuyLimit or 0

	self.curTimes = self.maxTimes - self.hadgettime
	if self.curTimes < 0 then self.curTimes = 0 end 

	self.gold 	= zhaoCaiCsv:getGoldByTimes(self.hadgettime + 1)
	self.money = zhaoCaiCsv:getMoneyByTimes(self.hadgettime + 1)
	if game.role.level > 19 then
		self.money = self.money + (game.role.level - 19) * 20
	end

	if self.curTimes == 0 then
		self.tipsLabel:setString("[color=ffff0000]招财次数已用完，请提升vip等级！[/color]")
	else
		local content = string.format("消耗[color=ff00ff00] %d [/color]元宝，获得[color=ff00ff00] %d [/color]银币",
			self.gold, self.money)
		self.tipsLabel:setString(content)
	end

	self.timesLabel:setString(tostring(self.curTimes))
	self:showNTimesButton()
end

function GetMoneyLayer:showNTimesButton()
	self:removeChildByTag(99)
	self:removeChildByTag(999)

	if self.curTimes > 0 and game.role.vipLevel >= 2 then
		--确定button：
		local sureBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png","middle_disabled.png"},
			{	
				text = { text = "招财", size = 32, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
				priority = self.priority - 5,
				callback = function() 
					self:buttonEffect(self.treeSp)
					if self.gold > game.role.yuanbao then
						DGMsgBox.new({ text = "元宝不够, 请捐赠票子", type = 2, button2Data = {
							text = "请充值",
							callback = function() 
								local rechargeLayer = require("scenes.home.shop.ReChargeLayer").new({ priority = -200,callback = function() self:refreshViewByData() end })
								rechargeLayer:getLayer():addTo(display.getRunningScene())
							end
						}})
					else
						self:prepairdForRequest({ roleId = game.role.id , param1 = 1})
					end
				end,
			}):getLayer()
		sureBtn:anch(1, 0):pos(self.size.width / 2 - 40, 30):addTo(self, 0, 99)

		local times = self.curTimes <= 10 and self.curTimes or 10
		local NTimesBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png","middle_disabled.png"},
		{	
			text = { text = string.format("招财%d次",times), size = 28, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			priority = self.priority - 5,
			callback = function() 

				self:buttonEffect(self.treeSp)

				if self.curTimes > 0 then
					if self.gold > game.role.yuanbao then
						DGMsgBox.new({ text = "元宝不够, 请捐赠票子", type = 2, button2Data = {
							text = "请充值",
							callback = function() 
								local rechargeLayer = require("scenes.home.shop.ReChargeLayer").new({ priority = -200 ,callback = function() self:refreshViewByData() end})
								rechargeLayer:getLayer():addTo(display.getRunningScene())
							end
						}})
					else
						self:prepairdForRequest({ roleId = game.role.id , param1 = times})
					end
					
				else
					DGMsgBox.new({ type = 1, text = "今日招财次数不足！"})
				end 
			end,
		}):getLayer()
		NTimesBtn:anch(0, 0):pos(self.size.width / 2 + 40, 30):addTo(self, 0, 999)

	elseif self.curTimes > 0 then
		--确定button：
		local sureBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png","middle_disabled.png"},
			{	
				text = { text = "招财", size = 32, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
				priority = self.priority - 5,
				callback = function() 
					self:buttonEffect(self.treeSp)
					if self.gold > game.role.yuanbao then
						DGMsgBox.new({ text = "元宝不够, 请捐赠票子", type = 2, button2Data = {
							text = "请充值",
							callback = function() 
								local rechargeLayer = require("scenes.home.shop.ReChargeLayer").new({ priority = -200,callback = function() self:refreshViewByData() end })
								rechargeLayer:getLayer():addTo(display.getRunningScene())
							end
						}})
					else
						self:prepairdForRequest({ roleId = game.role.id , param1 = 1})
					end
				end,
			}):getLayer()
		sureBtn:anch(0.5, 0):pos(self.size.width / 2, 30):addTo(self, 0, 99)
	else
		--确定button：
		local queryVipBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png","middle_disabled.png"},
			{	
				text = { text = "充值", size = 32, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
				priority = self.priority - 5,
				callback = function() 
					local vipLayer = require("scenes.home.shop.ReChargeLayer").new({ priority = self.priority - 10,callback = function() self:refreshViewByData() end })
					vipLayer:getLayer():addTo(display.getRunningScene())
				end,
			}):getLayer()
		queryVipBtn:anch(0.5, 0):pos(self.size.width / 2, 30):addTo(self, 0, 99)
	end	
end 

function GetMoneyLayer:prepairdForRequest(attTable)
	--表现：
	local offset = 10
	local particle1 = CCParticleSystemQuad:create( ParRes .. "money_petal.plist")
	particle1:setPosition(self:getContentSize().width/2 - offset, display.cy - 80)
	particle1:setDuration(1)
	self:addChild(particle1,0)
	particle1:setAutoRemoveOnFinish(true)

	local particle2 = CCParticleSystemQuad:create( ParRes .. "money_petal.plist")
	particle2:setPosition(self:getContentSize().width/2 - offset, display.cy - 80)
	particle2:setDuration(1)
	self:addChild(particle2,6)
	particle2:setAutoRemoveOnFinish(true)

	local bin = pb.encode("SimpleEvent", attTable)
	game:sendData(actionCodes.RoleBuyMoneyRequest, bin)
	showMaskLayer()
	game:addEventListener(actionModules[actionCodes.RoleBuyMoneyRequest], function(event)
		hideMaskLayer()
		local msg = pb.decode("BuyMoneyResult", event.data)
		self:refreshViewByData()
		for index, result in ipairs(msg.results) do
			local label
			if result.critFactor > 1 then
				label = display.newSprite(GiftRes .. "text_money_2.png")
				local labelSize = label:getContentSize()
				ui.newTTFLabelWithStroke({ text = result.yuanbao, color = display.COLOR_GREEN })
					:pos(80, labelSize.height / 2):addTo(label)
				ui.newTTFLabelWithStroke({ text = result.money, color = display.COLOR_GREEN })
					:pos(265, labelSize.height / 2):addTo(label)
				ui.newTTFLabel({ text = result.critFactor, color = COLOR_RED, size = 28 })
					:anch(0, 0.5):pos(480, labelSize.height / 2):addTo(label)
			else
				label = display.newSprite(GiftRes .. "text_money.png")
				local labelSize = label:getContentSize()

				ui.newTTFLabelWithStroke({ text = result.yuanbao, color = display.COLOR_GREEN })
					:pos(80, labelSize.height / 2):addTo(label)
				ui.newTTFLabelWithStroke({ text = result.money, color = display.COLOR_GREEN })
					:pos(265, labelSize.height / 2):addTo(label)
			end

			label:scale(0.5):pos(self.size.width / 2, self.size.height / 2):hide():addTo(self, 100)

			label:runAction(transition.sequence{
				CCDelayTime:create((index - 1) * 0.4),
				CCShow:create(),
				CCScaleTo:create(0.2, 1),
				CCMoveBy:create(0.4, ccp(0, 50)),
				CCSpawn:createWithTwoActions(CCMoveBy:create(0.5, ccp(0, 50)), CCFadeOut:create(0.5)),
				CCRemoveSelf:create()
			})
		end

		return "__REMOVE__"
	end)
end

--button
function GetMoneyLayer:buttonEffect(button)
	if button then
		local function zoom1(offset, time, onComplete)
	        local x, y = button:getPosition()
	        local size = button:getContentSize()

	        local scaleX = button:getScaleX() * (size.width + offset) / size.width
	        local scaleY = button:getScaleY() * (size.height - offset) / size.height

	        transition.moveTo(button, {y = y - offset, time = time})
	        transition.scaleTo(button, {
	            scaleX     = scaleX,
	            scaleY     = scaleY,
	            time       = time,
	            onComplete = onComplete,
	        })
	    end

	    local function zoom2(offset, time, onComplete)
	        local x, y = button:getPosition()
	        local size = button:getContentSize()

	        transition.moveTo(button, {y = y + offset, time = time / 2})
	        transition.scaleTo(button, {
	            scaleX     = 1.0,
	            scaleY     = 1.0,
	            time       = time,
	            onComplete = onComplete,
	        })
	    end

	    -- button:getParent():setEnabled(false)

	    zoom1(40, 0.08, function()
	        zoom2(40, 0.09, function()
	            zoom1(20, 0.10, function()
	                zoom2(20, 0.11, function()
	                    -- button:getParent():setEnabled(true)
	                    -- listener(tag)
	                end)
	            end)
	        end)
	    end)
	end
end


function GetMoneyLayer:getLayer()
	return self.mask:getLayer()
end

return GetMoneyLayer