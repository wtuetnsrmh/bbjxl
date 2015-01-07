local ShopRes = "resource/ui_rc/shop/"
local GlobalRes = "resource/ui_rc/global/"
local HomeRes = "resource/ui_rc/home/"

local DrawCardLayer = import(".DrawCardLayer")
local GiftItemLayer = import(".GiftItemLayer")
local StoreItemLayer = import(".StoreItemLayer")
local json = require("framework.json")

local ShopMainLayer = class("ShopMainLayer", function()
	return display.newLayer(ShopRes .. "shop_bg.png")
end)

local ReChargeLayer = import(".ReChargeLayer")

function ShopMainLayer:ctor(params)
	params = params or {}
	display.newSprite(HomeRes .. "home.jpg"):pos(display.cx - 8, display.cy):addTo(self, -10)

	self.priority = params.priority or -140
	self.size = self:getContentSize()

	self:anch(0.5, 0):pos(display.cx, 0)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1 })

	self.parent = params.parent

	display.newSprite(ShopRes .. "shop_text.png")
		:pos(self.size.width / 2, self.size.height - 125):addTo(self)

	self.closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
				self:getLayer():removeSelf()

				if params.closeCallback then params.closeCallback() end
			end,
		}):getLayer()
	self.closeBtn:anch(1, 1):pos((display.width + 960) / 2, display.height):addTo(self:getLayer())

	local noticeBg = display.newSprite(ShopRes .. "notice_bg.png")
	noticeBg:anch(0, 0.5):pos(220, self.size.height - 195):addTo(self)

	local rechargeBtn = DGBtn:new(ShopRes, {"recharge_normal.png", "recharge_selected.png", "recharge_disabled.png"},
		{
			priority = self.priority - 1,
			callback = function()
				local layer = ReChargeLayer.new({priority = self.priority - 10})
				layer:getLayer():addTo(display.getRunningScene())
			end	
		})
	rechargeBtn:getLayer():anch(0, 0.5):pos(120, self.size.height - 195):addTo(self)
	self:ShowStar(rechargeBtn)

	self.mainSize = CCSizeMake(820 ,470)
	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.mainSize):pos(100, 0):addTo(self)

	self.lightThings = display.newSprite(ShopRes .. "light_things.png")
	local thingSize = self.lightThings:getContentSize()
	self.lightThings:anch(0.5, 1):pos(self.size.width - 150, self.size.height - 160):addTo(self)



	--抽卡选项：
	self.btns = {}
	self.tags = {800,801,802}
	local shopRadioGrp = DGRadioGroup:new()
	local drawCardBtn = DGBtn:new(ShopRes, {"shop_btn_normal.png", "shop_btn_light.png"},
		{	
			front={ShopRes.."draw_text.png",ShopRes.."draw_text_selected.png"},
			priority = self.priority,
			callback = function()
				self:showDrawLayer()
				self:refreshLightAction(1)
			end,
		}, shopRadioGrp):getLayer()
	drawCardBtn:anch(0.5, 1):pos(thingSize.width / 2 - 2, thingSize.height + 5):addTo(self.lightThings,3)
	local btnSize = drawCardBtn:getContentSize()
	self.btns[#self.btns +1] = drawCardBtn

	self.drawCardListener = game.role:addEventListener("notifyNewMessage", function(event)
		if event.type == "freeDrawCard" then
			drawCardBtn:removeChildByTag(9999)
			if event.action == "add" then
				uihelper.newMsgTag(drawCardBtn)
			end
		end
	end)

	--道具选项：
	local itemBtn = DGBtn:new(ShopRes, {"shop_btn_normal.png", "shop_btn_light.png"},
		{	
			front={ShopRes.."item_text.png",ShopRes.."item_text_selected.png"},
			priority = self.priority,
			callback = function()
				self:showItemLayer()
				self:refreshLightAction(2)
			end,
		}, shopRadioGrp):getLayer()
	itemBtn:anch(0.5, 1):pos(thingSize.width / 2 - 2, thingSize.height - 140):addTo(self.lightThings,2)
	self.btns[#self.btns +1] = itemBtn

	--礼包选项：
	local giftBtn = DGBtn:new(ShopRes, {"shop_btn_normal.png", "shop_btn_light.png"},
		{	
			front={ShopRes.."gift_text.png",ShopRes.."gift_text_selected.png"},
			priority = self.priority,
			callback = function()
				self:showGiftLayer()
				self:refreshLightAction(3)
			end,
		}, shopRadioGrp):getLayer()
	giftBtn:anch(0.5, 1):pos(thingSize.width / 2 - 2, thingSize.height - 285):addTo(self.lightThings,1)
	self.btns[#self.btns +1] = giftBtn

	self.vipGiftListener = game.role:addEventListener("notifyNewMessage", function(event)
		if event.type == "vip0Gift" then
			giftBtn:removeChildByTag(9999)
			if event.action == "add" then
				uihelper.newMsgTag(giftBtn)
			end
		end
	end)

	shopRadioGrp:chooseByIndex(params.chooseIndex or 2, true)


	local barXX1 , barXX2 ,barYY = 110, 270 , 575
	--元宝bg：
	local yuanbaoBg = display.newSprite(HomeRes.."bar_common_short.png" )
		:anch(0,0.5):scale(0.9):pos(barXX1, barYY):addTo(self)

	--元宝label：
	local yuanbaoLabel = ui.newTTFLabel({ text = game.role.yuanbao, size = 22, font = ChineseFont })
		:anch(0, 0.5):pos(10, yuanbaoBg:getContentSize().height/2):addTo(yuanbaoBg, 9)
	--元宝图标
	display.newSprite(GlobalRes .. "yuanbao.png")
		:scale(0.9):anch(1, 0.5):pos(yuanbaoBg:getContentSize().width-5, yuanbaoBg:getContentSize().height/2):addTo(yuanbaoBg)

	--银币bg
	local moneyBg = display.newSprite(HomeRes.."bar_common_short.png" )
		:anch(0,0.5):scale(0.9):pos(barXX2, barYY):addTo(self)

	--银币label：
	local moneyLabel = ui.newTTFLabel({ text = game.role.money, size = 22, font = ChineseFont })
		:anch(0, 0.5):pos(10, moneyBg:getContentSize().height/2):addTo(moneyBg, 9)
	--银币图标
	display.newSprite(GlobalRes .. "yinbi.png")
		:anch(1, 0.5):pos(moneyBg:getContentSize().width-5, moneyBg:getContentSize().height/2):addTo(moneyBg)

	--元宝监听
	self.updateYuanbaoHandler = game.role:addEventListener("updateYuanbao", function(event)
			yuanbaoLabel:setString(event.yuanbao) 
		end)
	--银币监听
	self.updateFriendValueHandler = game.role:addEventListener("updateMoney", function(event)
			moneyLabel:setString(event.money) 
		end)

	--test
	-- self:refreshLightAction(2)
end

--test
function ShopMainLayer:refreshLightAction(index)
	if #self.tags > 0 then
		for i=1,#self.tags do
			self.lightThings:removeChildByTag(self.tags[i])
		end
	end
	local file
	local offset , scale , time
	for i=1,#self.btns do
		if i == index then
			offset = 78 
			scale = 1.08
			time = 1
			file = "shop_eff_light.png"
		else
			scale = 1.2
			offset = 90
			time = math.random(2,9) * 0.1
			file = "shop_eff_normal.png"
		end
		local view = display.newSprite(ShopRes..file)
		:pos(self.btns[i]:getPositionX(),self.btns[i]:getPositionY() - offset)
		:addTo(self.lightThings,-1,self.tags[i])
		:runAction(CCRepeatForever:create(transition.sequence({
			CCScaleTo:create(time, scale),
			CCScaleTo:create(time, 0.96),
		})))
	end
end

--附加：test
function ShopMainLayer:ShowStar(parent)
	local xx,yy = parent:getLayer():getContentSize().width,parent:getLayer():getContentSize().height
	local posX , posY = 0 , 0 
	local pTable = {
		{x = 10, y = 25},
		{x = 30, y = 25},
		{x = 40, y = 30},
		{x = 20, y = 50},
		{x = 50, y = 40},
		{x = 10, y = 15},
		{x = 50, y = 55},
	}
	local star
	for i=1,3 do
		star = display.newSprite(ShopRes.."shop_star.png")
	:pos(20,50):addTo(parent:getLayer())
					star:runAction(CCRepeatForever:create(transition.sequence({
					CCSpawn:createWithTwoActions(CCFadeIn:create(0.2), CCRotateBy:create(0.5, 40)),
					CCSpawn:createWithTwoActions(CCRotateBy:create(0.2, 40), CCFadeOut:create(0.2)),
					CCDelayTime:create(0.8 - i * 0.2),
					CCCallFunc:create(function() 
						local index = math.random(1,5)
						star:pos(pTable[index].x, pTable[index].y)
					end),
				})))
	end
end 

function ShopMainLayer:showDrawLayer()
	self.mainLayer:removeAllChildren()

	if not game.role.shopThreshold then

		local useRequest = { roleId = game.role.id}
		local bin = pb.encode("SimpleEvent", useRequest)
		game:sendData(actionCodes.StoreGetShopThrosholdRequest, bin, #bin)
		loadingShow()
		game:addEventListener(actionModules[actionCodes.StoreGetShopThrosholdResponse], function(event)
			loadingHide()
			local msg = pb.decode("SimpleEvent", event.data)
			game.role.shopThreshold = {[1] = msg.param1,[3] = msg.param2}
			game.role.isfirstDraw = msg.param3

			local drawCardLayer = DrawCardLayer.new({ priority = self.priority, closeBtn = self.closeBtn})
			self.mainLayer:addChild(drawCardLayer)

			return "__REMOVE__"
		end)
	else
		local drawCardLayer = DrawCardLayer.new({ priority = self.priority, closeBtn = self.closeBtn })
		self.mainLayer:addChild(drawCardLayer)
	end
	
end

function ShopMainLayer:showItemLayer()
	self.mainLayer:removeAllChildren()
	local storeLayer = StoreItemLayer.new({ priority = self.priority})
	storeLayer:addTo(self.mainLayer)
end

function ShopMainLayer:showGiftLayer()
	self.mainLayer:removeAllChildren()

	local layer = GiftItemLayer.new({priority = self.priority -10, })	
	layer:anch(0,0):pos(50,30):addTo(self.mainLayer)
end

function ShopMainLayer:getLayer()
	return self.mask:getLayer()
end

function ShopMainLayer:onEnter()
	if self.parent then self.parent:hide() end
end

function ShopMainLayer:onExit()
	if game.role then
		game.role:removeEventListener("updateYuanbao", self.updateYuanbaoHandler)
		game.role:removeEventListener("updateMoney", self.updateFriendValueHandler)
		game.role:removeEventListener("notifyNewMessage", self.vipGiftListener)
		game.role:removeEventListener("notifyNewMessage", self.drawCardListener)
    end

    if self.parent then self.parent:show() end
end 

return ShopMainLayer