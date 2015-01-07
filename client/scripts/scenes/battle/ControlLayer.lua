local ControlLayer = class("ControlLayer", function()
	return display.newLayer()
end)

function ControlLayer:ctor(params)
	self.paused = false
end

function ControlLayer:pause()
	if self.paused then return end

	local children = self:getChildren()
	local childsNum = self:getChildrenCount()

	for index = 0, childsNum - 1 do
		local child = tolua.cast(children:objectAtIndex(index), "CCNode")
		transition.pauseTarget(child)
	end

	self.paused = true
end

function ControlLayer:resume()
	if not self.paused then return end

	local children = self:getChildren()
	local childsNum = self:getChildrenCount()

	for index = 0, childsNum - 1 do
		local child = tolua.cast(children:objectAtIndex(index), "CCNode")
		transition.resumeTarget(child)
	end

	self.paused = false
end

return ControlLayer