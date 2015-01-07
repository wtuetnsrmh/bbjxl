local GlobalRes = "resource/ui_rc/global/"

local HealthTipsLayer = class("HealthTipsLayer", function(params)
	return display.newLayer(GlobalRes .. "tips_middle.png")
end)

function HealthTipsLayer:ctor(params)
	params = params or {}
	self.parent = params.parent
	self.priority = params.priority or -1000

	local worldPos = self.parent:convertToWorldSpace(ccp(0, 0))
	self:anch(0, 1):pos(worldPos.x, worldPos.y + 5)
	self.mask = DGMask:new({opacity = 0, item = self, priority = self.priority, click = function() self.mask:remove() end})

	self:refreshContent()
end

function HealthTipsLayer:refreshContent()

	local xPos, xOffset, yPos, yOffset = 30, 10, self:getContentSize().height - 30, 10
	local curTime, leftTime, allLeftTime
	local buyCount =  game.role:getHealthBuyCount()
	local recoverInterval = healthCsv:getDataByIndex(3).condition
	--计算回复满的时间点
	local curTimeVal = game:nowTime()
	local leftTimeVal = game.role.lastHealthTime + recoverInterval * 60 - curTimeVal
	local textTable = {
		[1] = {[1] = "当前时间：", [2] = ""},
		[2] = {[1] = "可购买体力次数：", [2] = string.format("%d/%d",  buyCount - game.role.healthBuyCount, buyCount)},
		[3] = {[1] = "下点体力回复：", [2] = ""},
		[4] = {[1] = "回复全部体力：", [2] = ""},
		[5] = {[1] = "回复时间间隔：", [2] = string.format("%d分钟", recoverInterval)}
	}
	for index = 1, #textTable do
		local text = ui.newTTFLabel({text = textTable[index][1], color = display.COLOR_YELLOW, size = 20})
			:anch(0, 1):pos(xPos, yPos):addTo(self)
		local text2 = ui.newTTFLabel({text = textTable[index][2], color = display.COLOR_YELLOW, size = 20})
			:anch(0, 1):pos(xPos + text:getContentSize().width + xOffset, yPos):addTo(self)
		yPos = yPos - yOffset - text:getContentSize().height
		if index == 1 then
			curTime = text2
		elseif index == 3 then
			leftTime = text2
		elseif index == 4 then
			allLeftTime = text2
		end
	end
	local setTime	
	setTime = function()
		local curTimeVal = game:nowTime()
		local leftTimeVal = game.role.lastHealthTime + recoverInterval * 60 - curTimeVal
		local healthCanCover = game.role:getHealthLimit() - game.role.health
		local allHealthTime = healthCanCover <= 0 and "--:--:--" or  os.date("%X", (healthCanCover - 1) * recoverInterval * 60 + leftTimeVal + 16*3600)
		leftTimeVal = (leftTimeVal < 0 or game.role:getHealthLimit() <= game.role.health) and "--:--:--" or os.date("%X", leftTimeVal + 16*3600)
		
		curTime:setString(os.date("%X", curTimeVal))
		leftTime:setString(leftTimeVal)
		allLeftTime:setString(allHealthTime)

		curTime:runAction(transition.sequence({
			CCDelayTime:create(1),
			CCCallFunc:create(setTime),
		}))
	end
	setTime()
end

function HealthTipsLayer:getLayer()
	return self.mask:getLayer()
end

return HealthTipsLayer
