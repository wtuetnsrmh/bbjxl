--[[

loading

** Return **
    CCLayerColor

]]

local GlobalUIRes = "resource/UI_demo/Global/"

local M = {
	view
}

local DGMask = require("uicontrol.DGMask")

function M:new(args)
	local this = {}
	setmetatable(this , self)
	self.__index = self

	
	local args = args or {}

	local click = args.click or function() end  -- 点击回调函数

	local group = display.newLayer()

	local loading_bg = display.newSprite(GlobalUIRes .. "loading_bg.png")
	display.align(loading_bg , display.CENTER , display.cx , display.cy)
	group:addChild(loading_bg)

	local loading_sprite = display.newSprite(GlobalUIRes .. "loading.png")
	display.align(loading_sprite , display.CENTER , display.cx - 100 , display.cy)

	local action = CCRepeatForever:create( CCRotateBy:create(0.5 , 180) )
	loading_sprite:runAction(action)
	group:addChild(loading_sprite)

	local text = CCLabelTTF:create("正在加载，请稍等.." , FONT , 22)
	display.align(text , display.CENTER , display.cx + 35 , display.cy)
	text:setColor( ccc3( 0xff , 0xff , 0xff ) )
	group:addChild(text)

	this.view = DGMask:new({item = group , click = click , priority = -140})

	return this
end

function M:getLayer()
	return self.view:getLayer()
end

function M:show()
	self.view:show()
end

function M:hide()
	self.view:hide()
end

function M:remove()
	self.view:remove()
end


return M
