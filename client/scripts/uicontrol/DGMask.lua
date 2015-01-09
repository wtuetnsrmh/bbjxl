--[[

遮挡层 (模态框)

** Return **
	CCLayerColor

	]]

DGMask = {
	layer,
	clickFunc,
	clickOut,
	ObjSize,
}


function DGMask:new(args)

	local this = {}
	setmetatable(this , self)
	self.__index = self

	local args = args or {}

	local r = args.r or 0
	local g = args.g or 0
	local b = args.b or 0
	local opacity = args.opacity or 150         -- 透明度
	local priority = args.priority or -129      -- 优先级
	local item = args.item or nil               -- 额外 addChild 上去的元素
	local blackMask = true 						-- 是否显示黑色蒙板
	this.clickFunc = args.click or function() end  -- 点击回调函数

	if args.blackMask ~= nil then
		blackMask = args.blackMask
	end

	--touch in out
	this.ObjSize = args.ObjSize or nil
	this.clickOut  = args.clickOut or function() end

	-- 创建层
	this.layer = display.newLayer()
	if args.bg then
		display.newSprite(args.bg):pos(this.layer:getContentSize().width / 2, this.layer:getContentSize().height / 2)
			:addTo(this.layer, -2)
	end
	if blackMask then
		display.newColorLayer(ccc4(r, g, b, opacity)):addTo(this.layer, -1)	
	end

	--is touch inside 
	local function isTouchIn(x,y)
		local minX,maxX = item:getPositionX() - this.ObjSize.width/2 , item:getPositionX() + this.ObjSize.width/2
		local minY,maxY = item:getPositionY() - this.ObjSize.height/2 , item:getPositionY() + this.ObjSize.height/2
		if x <  minX or x > maxX or y < minY or y > maxY or minX == maxX or minY == maxY then
			return false 
		else
			return true
		end
	end 
	
	local outPressed = false
	local function onTouch(eventType , x , y)
		if eventType == "began" then 
			if this.ObjSize ~= nil then
				if not isTouchIn(x,y) then
					outPressed = true
				end
			end
			return true
		end
		if eventType == "moved" then return true end
		if eventType == "ended" then
			if this.ObjSize ~= nil then
				if isTouchIn(x,y) then
					this.clickFunc(x , y)
				elseif outPressed then
					this.clickOut(x , y)
					outPressed = false
				end
			else
				this.clickFunc(x , y)
			end

			return true
		end
		return false
	end

	-- 屏蔽点击
	this.layer:setTouchEnabled(true)
	this.layer:registerScriptTouchHandler(onTouch, false, priority, true)

	if item ~= nil then
		this.layer:addChild(item)
	end

	return this
end

function DGMask:show()
	local cur_scene = display.getRunningScene().name
	if cur_scene == display.getRunningScene().name then
		self.layer:setVisible(true)
	end
end

function DGMask:hide()
	local cur_scene = display.getRunningScene().name
	if cur_scene == display.getRunningScene().name then
		self.layer:setVisible(false)
	end
end

function DGMask:remove()
	xpcall(function()
		local cur_scene = display.getRunningScene().name
		if cur_scene == display.getRunningScene().name then
			self.layer:removeFromParentAndCleanup(true)
		end
		end, __G__TRACKBACK__)
end

-- 设置点击回调函数
function DGMask:click(func)
	self.clickFunc = func
end


function DGMask:clickOut(func)
	self.clickOut = func
end

function DGMask:getLayer()
	return self.layer
end

return DGMask
