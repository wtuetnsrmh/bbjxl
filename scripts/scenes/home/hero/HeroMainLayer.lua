local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"

local HeroListLayer = import(".HeroListLayer")
local HeroMapLayer = import(".HeroMapLayer")
local SellLayer = import(".SellLayer")
local FragmentListLayer = import(".FragmentListLayer")
local HeroDecomposeLayer = import(".HeroDecomposeLayer")
local StoreMainLayer = import("..StoreMainLayer")

local HeroMainLayer = class("HeroMainLayer", function(params)
	return display.newLayer(GlobalRes .. "inner_bg.png")
end)

function HeroMainLayer:ctor(params)
	params = params or {}
	self.priority = params.priority or -140

	self.size = self:getContentSize()
	self.parent = params.parent

	self:anch(0, 0):pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1, bg = HomeRes .. "home.jpg" })

	self.closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
				if self.fragmentTag then
					game.role:removeEventListener("notifyNewMessage", self.fragmentTag)
				end	
				
				self:getLayer():removeSelf()
			end,
		}):getLayer()
	self.closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self)

	self.tabCursor = display.newSprite(GlobalRes .. "tab_arrow.png")
	self.tabCursor:anch(1, 0.5):pos(self.size.width, 480):addTo(self, 100)

	local tabRadio = DGRadioGroup:new()
	local heroListBtn = DGBtn:new(GlobalRes, {"tab_normal.png", "tab_selected.png"},
		{	
			priority = self.priority,
			callback = function()
				self:initHeroList()
			end
		}, tabRadio)
	heroListBtn:getLayer():anch(0, 0.5):pos(self.size.width - 14, 480):addTo(self)
	local btnSize = heroListBtn:getLayer():getContentSize()
	ui.newTTFLabelWithStroke({ text = "武将", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(heroListBtn:getLayer(), 10)

	local fragmentBtn = DGBtn:new(GlobalRes, {"tab_normal.png", "tab_selected.png"},
		{	
			priority = self.priority,
			callback = function()
				self:initFragmentList()
			end,
		}, tabRadio)
	fragmentBtn:getLayer():anch(0, 0.5):pos(self.size.width - 14, 380):addTo(self)
	ui.newTTFLabelWithStroke({ text = "碎片", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(fragmentBtn:getLayer(), 10)
	self.fragmentBtn = fragmentBtn:getLayer()

	-- local mapBtn = DGBtn:new(GlobalRes, {"tab_normal.png", "tab_selected.png"},
	-- 	{	
	-- 		priority = self.priority,
	-- 		callback = function()
	-- 			self:initMapLayer()
	-- 		end,
	-- 	}, tabRadio)
	-- mapBtn:getLayer():anch(0, 0.5):pos(self.size.width - 14, 280):addTo(self)
	-- ui.newTTFLabelWithStroke({ text = "图鉴", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
	-- 	size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
	-- 	:pos(btnSize.width / 2, btnSize.height / 2):addTo(mapBtn:getLayer(), 10)

	self.fragmentTag = game.role:addEventListener("notifyNewMessage", function(event)
		if event.type == "composeFragment" then
			fragmentBtn:getLayer():removeChildByTag(9999)
			if event.action == "add" then
				uihelper.newMsgTag(fragmentBtn:getLayer(), ccp(-5, -5))
			end
		end
	end)


	tabRadio:chooseByIndex(1, true)

	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority})
	:anch(0,1):pos(0,display.height):addTo(self)
end

function HeroMainLayer:checkGuide(remove)
	game:addGuideNode({node = self.fragmentBtn, remove = remove,
		guideIds = {1070}
	})
	game:addGuideNode({node = self.closeBtn, remove = remove,
		guideIds = {1072}
	})
end

function HeroMainLayer:initHeroList()
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end

	self.layer = "main"

	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.size):addTo(self)

	self.tabCursor:pos(self.size.width, 480)

	local listLayer = HeroListLayer.new({ priority = self.priority - 10 })
	listLayer:anch(0.5, 0):pos(self.size.width / 2, 5):addTo(self.mainLayer)
end

function HeroMainLayer:initFragmentList()
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end

	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.size):addTo(self)

	self.tabCursor:pos(self.size.width, 380)

	-- 化魂
	local heroMapBtn = DGBtn:new(GlobalRes, {"vertical_normal.png", "vertical_selected.png"},
		{	
			priority = self.priority,
			touchScale = { 2, 1 },
			callback = function()
				self:initHuahunLayer()
			end
		}):getLayer()
	heroMapBtn:anch(0, 0.5):pos(self.size.width - 13, 175):addTo(self.mainLayer)
	local btnSize = heroMapBtn:getContentSize()
	ui.newTTFLabelWithStroke({ text = "化魂", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(heroMapBtn)

	--商店
	local shopBt = DGBtn:new(GlobalRes, {"vertical_normal.png", "vertical_selected.png"},
		{	
			priority = self.priority,
			touchScale = { 2, 1 },
			callback = function()
				local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
				if roleInfo.huahunOpen < 0 then
					DGMsgBox.new({text = string.format("将魂商店%s级开放！", math.abs(roleInfo.huahunOpen)), type = 1})
					return
				end
				local bin = pb.encode("SimpleEvent", { roleId = game.role.id, param1 = 1, param2 = 4 })
				game:sendData(actionCodes.RoleShopRequest, bin)
				loadingShow()
				game:addEventListener(actionModules[actionCodes.RoleShopResponse], function(event)
					loadingHide()
					local msg = pb.decode("RoleShopDataResponse", event.data)

					local now = game:nowTime()
					local shopDatas = {}
					for _, shopData in ipairs(msg.shopDatas) do
						shopDatas[shopData.shopIndex] = {
							shopItems = json.decode(shopData.shopItemsJson),
							refreshLeftTime = shopData.refreshLeftTime,
							checkPoint = now,
						}
					end

					local storeMainLayer = StoreMainLayer.new({ 
						shopDatas = shopDatas,
						parent = self, 
						priority = self.priority - 100,
						curIndex = 4})
					storeMainLayer:getLayer():addTo(display.getRunningScene())

				end)
			end,
		}):getLayer()
	shopBt:anch(0, 0.5):pos(self.size.width - 13, 80):addTo(self.mainLayer)
	ui.newTTFLabelWithStroke({ text = "商店", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), size = 26, font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(shopBt)

	local mapLayer = FragmentListLayer.new({priority = self.priority - 10})
	mapLayer:anch(0.5, 0):pos(self.size.width / 2, 5):addTo(self.mainLayer)
end


function HeroMainLayer:initMapLayer()
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end

	self.layer = "main"

	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.size):addTo(self)

	local mapLayer = HeroMapLayer.new({priority = self.priority - 10})
	mapLayer:anch(0.5, 0):pos(self.size.width / 2, 5):addTo(self.mainLayer)

	self.tabCursor:pos(self.size.width, 280)
end

function HeroMainLayer:initDecomposeLayer()
	if self.mainLayer then
		self.mainLayer:removeSelf()
		self.mainLayer = nil
	end

	local Layer = HeroDecomposeLayer.new({priority = self.priority - 10, closeCallback = function() self:initHeroList() end})
	Layer:getLayer():addTo(display.getRunningScene())
end

function HeroMainLayer:initSellLayer()
	if self.mainLayer then
		self.mainLayer:removeSelf()
		self.mainLayer = nil
	end

	local mapLayer = SellLayer.new({priority = self.priority - 10, closeCallback = function() self:initHeroList() end})
	mapLayer:getLayer():addTo(display.getRunningScene())
end

function HeroMainLayer:initHuahunLayer()
	local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
	if roleInfo.huahunOpen < 0 then
		DGMsgBox.new({text = string.format("化魂功能%s级开放！", math.abs(roleInfo.huahunOpen)), type = 1})
		return
	end
	
	if self.mainLayer then
		self.mainLayer:removeSelf()
		self.mainLayer = nil
	end

	local FragmentDecomposeLayer = require("scenes.home.FragmentDecomposeLayer")
	local decomposeLayer = FragmentDecomposeLayer.new({ priority = self.priority - 10, closeCallback = function() self:initFragmentList() end })
	decomposeLayer:getLayer():addTo(display.getRunningScene())
end

function HeroMainLayer:getLayer()
	return self.mask:getLayer()
end

function HeroMainLayer:onEnter()
	if self.parent then self.parent:hide() end
	self:checkGuide()
end

function HeroMainLayer:onExit(  )
	if self.parent then self.parent:show() end
	self:checkGuide(true)
end

function HeroMainLayer:onCleanup()
	display.removeUnusedSpriteFrames()
end

return HeroMainLayer
