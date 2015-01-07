--[[挨个播放一组图片，带渐入效果]]
local KNShowbylist = {
	layer,
	items,
	params
}
	
function KNShowbylist:new()
	local this = {}
	setmetatable(this,self)
	self.__index = self

	this.items = {}
	this.layer = display.newLayer()
	this.params = {
		delay = 0,
		init_y = 300,
		time = 0.2,
		interval = 0.05,
	}

	return this	
end

--[[添加元素]]
function KNShowbylist:addItem(item)
	self.items[ #self.items + 1 ] = item
	self.layer:addChild( self.items[ #self.items ] )
end

--[[设置参数]]
function KNShowbylist:setParams(params)
	for key , v in pairs(params) do
		self.params[key] = v
	end
end

--[[开始播放]]
function KNShowbylist:play()
	local function play()
		local items = self.items
		for i = 1 , #items do
			local item = items[i]
			item:setPosition(item.x , item.y + self.params.init_y)

			transition.fadeIn(item , {
				delay = (i - 1) * self.params.interval,
				time = self.params.time,
			})

			transition.moveBy(item , {
				delay = (i - 1) * self.params.interval,
				time = self.params.time,
				y = 0 - self.params.init_y
			})
		end
	end

	if self.params.delay > 0 then
		self.layer:setVisible(false)

		local handle

		-- 触发定时器
		handle = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
			CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(handle)
			handle = nil

			self.layer:setVisible(true)

			play()
		end , self.params.delay , false)
	else
		self.layer:setVisible(true)
		play()
	end
end

function KNShowbylist:getLayer()
	return self.layer
end


return KNShowbylist