-- 滑块
-- by yujiuhe
-- 2014.10.08

DGSlider = {
	
}

function DGSlider:new(bgRes, sliderRes, params)
	local this = {}
	setmetatable(this,self)
	self.__index = self

	this.horizontal = params.horizontal or true
	this.segments = params.segments == nil and 2 or math.max(2, params.segments)
	this.curSeg = params.curSeg or 1
	this.callback = params.callback or function() end
	this.priority = params.priority or -140

	--映射
	local mapX = this.horizontal and "x" or "y"
	local mapY = this.horizontal and "y" or "x"
	local mapWidth = this.horizontal and "width" or "height"
	local mapHeight = this.horizontal and "height" or "width"

	--滑块背景
	this.layer = display.newLayer(bgRes)
	local layerSize = this.layer:getContentSize()
	
	--滑块
	local mapYPos = layerSize[mapHeight] / 2
	this.slider = display.newSprite(sliderRes):addTo(this.layer)
	local threshold = this.slider:getContentSize()[mapWidth] / 2

	--预先计算出滑块的固定位置
	local sliderPos = {}
	sliderPos[1] = threshold
	sliderPos[this.segments] = layerSize[mapWidth] - threshold
	for index = 2, this.segments - 1 do
		local segWidth = layerSize[mapWidth] / (this.segments - 1)
		sliderPos[index] = segWidth * (index - 1)
	end

	local pos = ccp(0, 0)
	pos[mapX] = sliderPos[this.curSeg]
	pos[mapY] = mapYPos
	this.slider:setPosition(pos)

	local touch = false
	local isSlidering  = false
	this.layer:addTouchEventListener(
		function(event, x, y)
			if event == "began" then
				local touchPoint = ccp(x, y)
				if uihelper.nodeContainTouchPoint(this.layer, touchPoint) and not isSlidering then
					touch = true
					isSlidering = true
					local pointTarget = this.layer:convertToNodeSpace(touchPoint)
					pointTarget[mapX] = math.min(math.max(threshold, pointTarget[mapX]), layerSize[mapWidth] - threshold)
					pointTarget[mapY] = mapYPos
					this.slider:runAction(CCMoveTo:create(0.1, pointTarget))
				else
					return false
				end
			elseif event == "moved" then
				local touchPoint = ccp(x, y)
				if touch then
					local pointTarget = this.layer:convertToNodeSpace(touchPoint)
					pointTarget[mapX] = math.min(math.max(threshold, pointTarget[mapX]), layerSize[mapWidth] - threshold)
					pointTarget[mapY] = mapYPos
					this.slider:stopAllActions()
					this.slider:setPosition(pointTarget)	
				end 
			elseif event == "ended" then
				local touchPoint = ccp(x, y)
				if touch then
					touch = false
					local pointTarget = this.layer:convertToNodeSpace(touchPoint)
					local seg = math.ceil(pointTarget[mapX] * this.segments / layerSize[mapWidth])
					seg = math.max(math.min(seg, this.segments), 1)
					pointTarget[mapX] = sliderPos[seg]
					pointTarget[mapY] = mapYPos
					local seq = {
						CCMoveTo:create(0.1, pointTarget),
						CCCallFunc:create(function() isSlidering = false end)
					}
					if seg ~= this.curSeg then
						this.curSeg = seg
						table.insert(seq, CCCallFunc:create(function()
							this.callback(seg)
						end))
					end
					this.slider:stopAllActions()
					this.slider:runAction(transition.sequence(seq))
				end
			end

			return true
		end, false, this.priority, true)

	this.layer:setTouchEnabled(true)
	
	return this
end

function DGSlider:getLayer()
	return self.layer
end

function DGSlider:getSlider()
	return self.slider
end

return DGSlider
