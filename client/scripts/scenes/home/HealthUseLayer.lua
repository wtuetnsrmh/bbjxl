-- 新UI 美人列表
-- by yangkun
-- 2014.4.15

local GlobalRes = "resource/ui_rc/global/"
local BattleRes = "resource/ui_rc/battle/"
local AwardRes = "resource/ui_rc/carbon/award/"

local HeroPartnerLayer = class("HeroPartnerLayer", function(params) 
	return display.newLayer(AwardRes .. "box_small_bg.png") 
end)

function HeroPartnerLayer:ctor(params)

	params = params or {}

	self.priority = params.priority or -129
	self.parent = params.parent
	self.callback = params.callback or nil

	self:initUI()
	self:initContentLayer()

end

function HeroPartnerLayer:initUI()
	self.size = self:getContentSize()
	self:anch(0.5,0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self , priority = self.priority, click = function() 
			if self.callback then
				self.callback()
			end
			self.mask:remove()
		end})

	-- title
	display.newSprite(BattleRes .. "text_health.png")
	:anch(0.5,1):pos(self.size.width/2, self.size.height - 8):addTo(self)
end

function HeroPartnerLayer:initContentLayer()
	if self.contentLayer then
		self.contentLayer:removeSelf()
	end

	self.contentLayer = display.newLayer()
	self.contentLayer:size(self:getContentSize())
	self.contentLayer:addTo(self)
	local contentSize = self:getContentSize()

	-- local itemFrame = ItemIcon.new({ itemId = 701, 
	-- 	callback = function() 
	-- 		self:showItemTaps(701,1)
	-- 	end,
	-- 	priority = self.priority - 2,
	-- }):getLayer()
	-- itemFrame:anch(0,0):pos(65, contentSize.height - 200):addTo(self.contentLayer)

	-- local intro = ui.newTTFLabel({text = "体力 +20", size = 22, color = display.COLOR_DARKYELLOW})
	-- intro:anch(0.5,1):pos(itemFrame:getContentSize().width/2, -5):addTo(itemFrame)

	-- 294 112
	local costYuanbao = functionCostCsv:getCostValue("health", game.role.healthBuyCount)
	
	uihelper.createLabel({text = string.format("主公，体力不足啦，回复体力再来战吧！花费%d元宝购买50点体力(今天已购买%d次)",costYuanbao,game.role.healthBuyCount), 
		width = 520, color = display.COLOR_DARKYELLOW, font = ChineseFont, size = 28})
		:anch(0,0):pos(60, contentSize.height - 195):addTo(self.contentLayer)


	-- 购买
	local buyBtn = DGBtn:new(GlobalRes , {"middle_normal.png", "middle_selected.png", "middle_disabled.png"}, {
			text = { text = "购买", size = 32, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
					local itemUseRequest = { roleId = game.role.id, param1 = 701 }	
					local bin = pb.encode("SimpleEvent", itemUseRequest)
					game:sendData(actionCodes.RoleBuyItemAndUseRequest, bin)
					loadingShow()
					game:addEventListener(actionModules[actionCodes.RoleBuyItemAndUseResponse], function(event)
						loadingHide()
						DGMsgBox.new({ type = 1, text = "购买成功！恭喜获得50点体力"})
						self:initContentLayer()

						if self.parent and self.parent.__cname == "CarbonSweepLayer" then
							self.parent:initRightContentLayer()
						end
					return "__REMOVE__"
				end)
			end,
			priority = self.priority - 2
		})
	buyBtn:getLayer():anch(0.5,0):pos(contentSize.width/2 - 140, 27):addTo(self.contentLayer)
	buyBtn:setEnable(false)

	

	display.newSprite(GlobalRes .. "yuanbao.png"):anch(0.5, 0):pos(contentSize.width/2 - 40, 35):addTo(self.contentLayer)
	ui.newTTFLabel({text = " x" .. costYuanbao, size = 22 }):anch(0.5, 0):pos(contentSize.width/2, 35):addTo(self.contentLayer)
	
	local buyCount = game.role:getHealthBuyCount() - game.role.healthBuyCount
	buyBtn:setEnable(buyCount > 0)
	ui.newTTFLabel({text = string.format("今日还可购买 %d 次", buyCount), size = 22, color = (buyCount == 0 and display.COLOR_RED or display.COLOR_GREEN)})
		:anch(0.5,0):pos(contentSize.width/2 - 120,2):addTo(self.contentLayer)

	-- 使用
	local useBtn = DGBtn:new(GlobalRes , {"middle_normal.png", "middle_selected.png", "middle_disabled.png"}, {
			text = { text = "吃鸡腿", size = 32, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
				local itemUseRequest = { roleId = game.role.id, param1 = 701, param2 = 1 }	
				local bin = pb.encode("SimpleEvent", itemUseRequest)
				game:sendData(actionCodes.ItemUseRequest, bin)
				loadingShow()
				game:addEventListener(actionModules[actionCodes.ItemUseResponse], function(event)
					loadingHide()
					local msg = pb.decode("SimpleEvent", event.data)
					if msg.param1 == 1 then
						DGMsgBox.new({ type = 1, text = string.format("恭喜获得%d点体力", game.role.health - game.role.oldHealth)})
						self:initContentLayer()

						if self.parent and self.parent.__cname == "CarbonSweepLayer" then
							self.parent:initRightContentLayer()
						end
					end
					return "__REMOVE__"
				end)
			end,
			priority = self.priority - 2
		})
	useBtn:getLayer():anch(0.5,0):pos(contentSize.width/2 + 140, 27):addTo(self.contentLayer)

	local itemCount = game.role.items[701] and game.role.items[701].count or 0
	ui.newTTFLabel({text = string.format("已拥有 %d 个", itemCount), size = 22, color = (itemCount == 0 and display.COLOR_RED or display.COLOR_GREEN) })
	:anch(0.5,0):pos(contentSize.width/2 + 140, 2):addTo(self.contentLayer)
	useBtn:setEnable(itemCount > 0)
end

function HeroPartnerLayer:getLayer()
	return self.mask:getLayer()
end

function HeroPartnerLayer:showItemTaps(itemId,itemNum,itemType)
	self:purgeItemTaps()
	local itemTipsView = require("scenes.home.ItemTipsLayer")
	local itemTips = itemTipsView.new({
		itemId = itemId,
		itemNum = itemNum,
		itemType = itemType,
		})
	display.getRunningScene():addChild(itemTips:getLayer())
	itemTips:setTag(1000)
end

function HeroPartnerLayer:purgeItemTaps()
	if display.getRunningScene():getChildByTag(1000) then
		display.getRunningScene():getChildByTag(1000):removeFromParent()
	end
end



return HeroPartnerLayer