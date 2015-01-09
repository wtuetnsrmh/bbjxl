local HeroRes = "resource/ui_rc/hero/"
local EquipRes = "resource/ui_rc/equip/"

local TopBarLayer = require("scenes.TopBarLayer")
local EquipListLayer = import(".EquipListLayer")
local EquipFragmentsLayer = import(".EquipFragmentsLayer")
local EquipSellLayer = import(".EquipSellLayer")

local EquipMainLayer = class("EquipMainLayer", function()
	return display.newLayer(GlobalRes .. "inner_bg.png") 
end)

function EquipMainLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -129
	self.size = self:getContentSize()
	self.parent = params.parent
	
	self.equips = {}

	self:initUI()
end

function EquipMainLayer:initUI()
	-- 遮罩层
	self:anch(0, 0):pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1,bg = HomeRes .. "home.jpg"})

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
				self:getLayer():removeSelf()
			end,
		}):getLayer()
	closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self)

	self.tabCursor = display.newSprite(GlobalRes .. "tab_arrow.png")
	self.tabCursor:anch(1, 0.5):pos(self.size.width, 470):addTo(self, 100)

	local tabRadio = DGRadioGroup:new()
	--装备
	local equipBtn = DGBtn:new(GlobalRes, {"tab_normal.png", "tab_selected.png"},
		{	
			priority = self.priority,
			callback = function()
				self:initEquipList()
			end,
		}, tabRadio)
	equipBtn:getLayer():anch(0, 0.5):pos(self.size.width - 14, 470):addTo(self)
	local tabSize = equipBtn:getLayer():getContentSize()
	ui.newTTFLabelWithStroke({ text = "装备", dimensions = CCSizeMake(tabSize.width / 2, tabSize.height), size = 26, font = ChineseFont,
		color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(tabSize.width / 2, tabSize.height / 2):addTo(equipBtn:getLayer(), 10)

	--碎片
	local fragmentBtn = DGBtn:new(GlobalRes, {"tab_normal.png", "tab_selected.png"},
	{	
		priority = self.priority,
		callback = function()
			self:initFragmentList()
		end,
	}, tabRadio)
	fragmentBtn:getLayer():anch(0, 0.5):pos(self.size.width - 14, 360):addTo(self)
	ui.newTTFLabelWithStroke({ text = "碎片", dimensions = CCSizeMake(tabSize.width / 2, tabSize.height), size = 26, font = ChineseFont,
		color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(tabSize.width / 2, tabSize.height / 2):addTo(fragmentBtn:getLayer(), 10)


	tabRadio:chooseByIndex(1, true)

	self.fragmentTag = game.role:addEventListener("notifyNewMessage", function(event)
		if event.type == "composeEquipFragment" then
			fragmentBtn:getLayer():removeChildByTag(9999)
			if event.action == "add" then
				uihelper.newMsgTag(fragmentBtn:getLayer(), ccp(-5, -5))
			end
		end
	end)

	local layer  = TopBarLayer.new({priority = self.priority})
	layer:anch(0,1):pos(0, display.height):addTo(self)
end

function EquipMainLayer:initEquipList()
	if self.contentLayer then
		self.contentLayer:removeSelf()
	end
	self.layer = "equip"
	self.tabCursor:pos(self.size.width, 470)

	self.contentLayer = display.newLayer()
	self.contentLayer:size(self.size):addTo(self)

	-- 出售
	local sellEquipBtn = DGBtn:new(GlobalRes, {"vertical_normal.png", "vertical_selected.png"},
		{	
			--front = HeroRes .. "text_sell.png",
			priority = self.priority,
			touchScale = { 2, 1 },
			callback = function()
				self:initSellLayer()
			end
		}):getLayer()
	sellEquipBtn:anch(0, 0.5):pos(self.size.width - 13, 180):addTo(self.contentLayer)
	local tabSize = sellEquipBtn:getContentSize()
	ui.newTTFLabelWithStroke({ text = "出售", dimensions = CCSizeMake(tabSize.width / 2, tabSize.height), size = 26, font = ChineseFont,
		color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(tabSize.width / 2, tabSize.height / 2):addTo(sellEquipBtn)

	local layer = EquipListLayer.new({priority = self.priority})
	layer:anch(0.5, 0):pos(self.size.width / 2, 5):addTo(self.contentLayer)
end

function EquipMainLayer:initFragmentList()
	if self.contentLayer then
		self.contentLayer:removeSelf()
	end

	self.layer = "fragment"
	self.tabCursor:pos(self.size.width, 360)

	self.contentLayer = display.newLayer()
	self.contentLayer:size(self.size):addTo(self)

	local layer = EquipFragmentsLayer.new({priority = self.priority})
	layer:anch(0.5, 0):pos(self.size.width / 2, 5):addTo(self.contentLayer)
end

function EquipMainLayer:initSellLayer()
	params = params or {priority = self.priority - 10}
	if self.layer == "equip" then
		params.callback = function()
			self:initEquipList()
		end
	end
	local layer = EquipSellLayer.new(params)
	layer:getLayer():addTo(display.getRunningScene())
end

function EquipMainLayer:getLayer()
	return self.mask:getLayer()
end

function EquipMainLayer:onEnter()
	self.parent:hide()
end

function EquipMainLayer:onExit()
	self.parent:show()
	if self.fragmentTag then
		game.role:removeEventListener("notifyNewMessage", self.fragmentTag )
	end
end

return EquipMainLayer