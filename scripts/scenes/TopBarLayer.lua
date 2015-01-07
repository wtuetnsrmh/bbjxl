local HomeRes = "resource/ui_rc/home/"
local DGBtn = require("uicontrol.DGBtn")
local HealthTipsLayer = import(".HealthTipsLayer")

local TopBarLayer = class("TopBarLayer", function(params) return display.newLayer() end)

function TopBarLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -130
	self.closeCallback = params.closeCallback

	self:setContentSize(CCSizeMake(960, 65))
	local wsize = self:getContentSize()

	local yy = 10
	local offset = 200

	--体力bg：
	-- local healthBg = display.newSprite(HomeRes.."bar_common.png" )
	-- :anch(0,0.5):scale(1.0):pos(10, yy):addTo(self)
	local healthBg
	healthBg = DGBtn:new(HomeRes, {"bar_common.png", "bar_common.png"},
		{	
			priority = self.priority,
			callback = function()
				--self:healthAddtion()
				local healthTips = HealthTipsLayer.new({parent = healthBg})
				healthTips:getLayer():addTo(display.getRunningScene())
			end,
		}):getLayer()
	healthBg:anch(0, 0):pos(10, yy):addTo(self)

	--体力label：
	local healthLabel = DGRichLabel.new({ size = 22, font = ChineseFont })
	:anch(0.5, 0.5):pos(healthBg:getContentSize().width/2, healthBg:getContentSize().height/2):addTo(healthBg)
	
	--鸡腿图标
	display.newSprite(GlobalRes .. "chicken.png")
		:anch(1, 0.5):pos(healthBg:getContentSize().width-5, healthBg:getContentSize().height/2):addTo(healthBg)

	--增加：
	local healthAdd = DGBtn:new(HomeRes, {"add_normal.png", "add_selected.png"},
		{	
			priority = self.priority - 1,
			touchScale = {1.5, 1.5},
			callback = function()
				self:healthAddtion()
			end,
		}):getLayer()
	healthAdd:anch(0, 0.5):pos(5, healthBg:getContentSize().height/2):addTo(healthBg)

	local function setHealth(event)
		local limit = game.role:getHealthLimit()
		local text = game.role.health
		if game.role.health >= limit then
			text = "[color=12f0f3]" .. game.role.health .. "[/color]"
		end
		text = text .. "/" .. limit
		healthLabel:setString(text)
	end
	setHealth()

	--体力监听
	self.updateHealthHandler = game.role:addEventListener("updateHealth", setHealth)
	self.updateLevelHandler = game.role:addEventListener("updateLevel", setHealth)
	self.updateVipLevelHandler = game.role:addEventListener("updateVipLevel", setHealth)


	--银币bg：
	-- local moneyBg = display.newSprite(HomeRes.."bar_common.png" )
	-- :anch(0,0.5):scale(1.0):pos(healthBg:getPositionX() + offset, yy):addTo(self)

	local moneyBg = DGBtn:new(HomeRes, {"bar_common.png", "bar_common.png"},
		{	
			priority = self.priority,
			callback = function()
				--self:moneyAddtion()
			end,
		}):getLayer()
	moneyBg:anch(0, 0):pos(healthBg:getPositionX() + offset, yy):addTo(self)

	--银币label：
	local moneyLabel = ui.newTTFLabel({ text = game.role.money, size = 22, font = ChineseFont })
		:anch(0.5, 0.5):pos(moneyBg:getContentSize().width/2, moneyBg:getContentSize().height/2):addTo(moneyBg, 9)
	--银币图标
	display.newSprite(GlobalRes .. "yinbi.png")
		:anch(1, 0.5):pos(moneyBg:getContentSize().width-5, moneyBg:getContentSize().height/2):addTo(moneyBg)

	local moneyAdd = DGBtn:new(HomeRes, {"add_normal.png", "add_selected.png"},
		{	
			priority = self.priority - 1,
			-- touchScale = {1.5, 1.5},
			callback = function()
				self:moneyAddtion()
			end,
		}):getLayer()
	moneyAdd:size(moneyBg:getContentSize().width, moneyAdd:getContentSize().height):anch(0, 0.5):pos(5, moneyBg:getContentSize().height/2):addTo(moneyBg)

	--银币监听
	self.updateMoneyHandler = game.role:addEventListener("updateMoney", function(event)
			moneyLabel:setString(event.money) 
		end)


	--元宝bg：
	-- local yuanbaoBg = display.newSprite(HomeRes.."bar_common.png" )
	-- :anch(0,0.5):scale(1.0):pos(moneyBg:getPositionX() + offset, yy):addTo(self)

	local yuanbaoBg = DGBtn:new(HomeRes, {"bar_common.png", "bar_common.png"},
		{	
			priority = self.priority,
			callback = function()
				--self:yuanbaoAddtion()
			end,
		}):getLayer()
	yuanbaoBg:anch(0, 0):pos(moneyBg:getPositionX() + offset, yy):addTo(self)

	--元宝label：
	local yuanbaoLabel = ui.newTTFLabel({ text = game.role.yuanbao, size = 22, font = ChineseFont })
		:anch(0.5, 0.5):pos(yuanbaoBg:getContentSize().width/2, yuanbaoBg:getContentSize().height/2):addTo(yuanbaoBg, 9)
	--元宝图标
	display.newSprite(GlobalRes .. "yuanbao.png")
		:scale(0.9):anch(1, 0.5):pos(yuanbaoBg:getContentSize().width-5, yuanbaoBg:getContentSize().height/2):addTo(yuanbaoBg)

	--增加：
	local yuanbaoAdd = DGBtn:new(HomeRes, {"add_normal.png", "add_selected.png"},
		{	
			priority = self.priority - 1,
			-- touchScale = {1.5, 1.5},
			callback = function()
				self:yuanbaoAddtion()
			end,
		}):getLayer()
	yuanbaoAdd:size(yuanbaoBg:getContentSize().width, yuanbaoAdd:getContentSize().height):anch(0, 0.5):pos(5, yuanbaoBg:getContentSize().height/2):addTo(yuanbaoBg)

	--元宝监听
	self.updateYuanbaoHandler = game.role:addEventListener("updateYuanbao", function(event)
			yuanbaoLabel:setString(event.yuanbao) 
		end)
end

--商城道具
function TopBarLayer:healthAddtion()
	local HealthUseLayer = require("scenes.home.HealthUseLayer")
	local layer = HealthUseLayer.new({ priority = self.priority -10})
	layer:getLayer():addTo(display.getRunningScene())
end
--银币
function TopBarLayer:moneyAddtion()
	local getMoney = require("scenes.activity.GetMoneyLayer")
	local giftView = getMoney.new({ priority = self.priority - 10 })
	giftView:getLayer():addTo(display.getRunningScene())
end
--充值：
function TopBarLayer:yuanbaoAddtion()
	local ReChargeLayer = require("scenes.home.shop.ReChargeLayer")
	local layer = ReChargeLayer.new({priority = self.priority - 10})
	layer:getLayer():addTo(display.getRunningScene())
end

function TopBarLayer:onCleanup()
	if game.role then
		game.role:removeEventListener("updateYuanbao", self.updateYuanbaoHandler)
	    game.role:removeEventListener("updateMoney", self.updateMoneyHandler)
	    game.role:removeEventListener("updateHealth", self.updateHealthHandler)
	    game.role:removeEventListener("updateLevel", self.updateLevelHandler)
	    game.role:removeEventListener("updateVipLevel", self.updateVipLevelHandler)
	end
end

return TopBarLayer
