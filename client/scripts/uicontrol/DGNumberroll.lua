--[[数字滚动]]
local KNNumberroll = {
	params
}
	
function KNNumberroll:new(num , params)
	local this = {}
	setmetatable(this,self)
	self.__index = self

	this.params = {
		num = num,
		delay = params.delay or 0,
		prefix = params.prefix or "",
		color = params.color or ccc3( 0xff , 0xff , 0xff ),
		size = params.size or 20,
		time = params.time or 0.8,
	}

	return this
end

--[[设置参数]]
function KNNumberroll:setParams(params)
	for key , v in pairs(params) do
		self.params[key] = v
	end
end

--[[开始播放]]
function KNNumberroll:play()
	local label = CCLabelTTF:create(self.params.prefix .. self.params.num , FONT , self.params.size)
	label:setColor(self.params.color)
	label:setVisible(false)

	local function play()
		local times = 50	-- 变化次数
		local interval = self.params.time / times		-- 每次变化数字的时间
		local interval_num = math.ceil(self.params.num / 50)
		local handle

		local cur_num = 0
		local cur_times = times
		handle = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
			xpcall(function()
				if cur_times <= 0 then
					CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(handle)
					handle = nil

					label:setString( self.params.prefix .. self.params.num )

					return
				end

				label:setString( self.params.prefix .. cur_num )
				cur_num = cur_num + interval_num
				if cur_num > self.params.num then
					cur_num = self.params.num
				end

				cur_times = cur_times - 1
			end , function()
				CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(handle)
				handle = nil
			end)
		end , interval , false)
	end

	if self.params.delay > 0 then
		local handle

		-- 触发定时器
		handle = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
			CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(handle)
			handle = nil

			label:setVisible(true)

			play()
		end , self.params.delay , false)
	else
		label:setVisible(true)
		play()
	end


	return label
end


return KNNumberroll