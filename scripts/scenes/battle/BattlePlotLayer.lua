local BattleRes = "resource/ui_rc/battle/"

local BattlePlotLayer = class("BattlePlotLayer", function()
	return display.newLayer()
end)

function BattlePlotLayer:ctor(params)
	params = params or {}
	self.onComplete = params.onComplete
	self.removeImages = {}

	self.currentPlotId = 0
	self.currentPlots = nil
	self.currentPlotIndex = 1

	self.leftSprite = nil
	self.rightSprite = nil

	-- 注册touch事件处理函数
	self:addTouchEventListener(function(event, x, y) return self:onTouch(event, x, y) end, false, -100)
	self:setTouchEnabled(true)

	if params.carbonId ~= 10000 and params.carbonId ~= 10001 and params.carbonId ~= 20001 then
		self.roleHero = game.role.heros[game.role.mainHeroId]
	end 

	self:initLayer(params.carbonId, params.phase)

end

function BattlePlotLayer:initLayer(carbonId, phase)
	self.currentPlots = plotTalkCsv:getPlotTalkByCarbon(carbonId, phase)
	if #self.currentPlots == 0 then return end

	table.sort(self.currentPlots, function(a, b) return a.plotId < b.plotId end)

	self.talkContentFrame = display.newSprite(BattleRes .. "dialog_plot.png")
	self.removeImages[BattleRes .. "dialog_plot.png"] = true
	local talkContentFrameSize = self.talkContentFrame:getContentSize()

	local scaleValue = display.width / talkContentFrameSize.width
	self.talkContentFrame:setScaleX(scaleValue)
	self.talkContentFrame:anch(0.5, 0):pos(display.cx, 0):addTo(self)

	self.talkContent = ui.newTTFLabel({text = "", size = 32, color = display.COLOR_BLACK,
		dimensions = CCSizeMake(talkContentFrameSize.width * scaleValue - 200, talkContentFrameSize.height - 20) })
	self.talkContent:anch(0, 0.5):pos(100, talkContentFrameSize.height / 2 ):addTo(self)

	self.removeImages[BattleRes .. "name_plot.png"] = true
	self.leftNameFrame = display.newSprite(BattleRes .. "name_plot.png")
	self.leftNameFrame:scale(scaleValue):anch(0, 0.5):pos(50, self.talkContentFrame:getContentSize().height):addTo(self)
	self.rightNameFrame = display.newSprite(BattleRes .. "name_plot.png")
	self.rightNameFrame:scale(scaleValue):anch(1, 0.5):addTo(self)
		:pos(display.width - 50, self.talkContentFrame:getContentSize().height)

	self:playPlot(self.currentPlotIndex)
end

function BattlePlotLayer:onTouch(event, x, y)
	if event == "began" then
		self.currentPlotIndex = self.currentPlotIndex + 1
		return self:playPlot(self.currentPlotIndex)
	end
end

function BattlePlotLayer:playPlot(plotIndex)
	local currentTalk = self.currentPlots[plotIndex]
	if currentTalk == nil and type(self.onComplete) == "function" then
		--剧情结束
		self:removeSelf()
		self.onComplete()
		return false
	end
	local nameFrameSize = self.leftNameFrame:getContentSize()
	-- 不说话的一个人暗下去
	if currentTalk.type == 1 then
		if self.rightSprite then self.rightSprite:setColor(ccc3(90, 90, 90)) end
		self.rightNameFrame:hide()
		if self.leftSprite then self.leftSprite:removeSelf() end
		self.leftNameFrame:show()
		self.leftNameFrame:removeAllChildren()

		local heroType = self.roleHero and self.roleHero.type
		if currentTalk.roleTalk == 0 then
			heroType = currentTalk.heroType
		end

		local unitData = unitCsv:getUnitByType(heroType)
		-- local talkData = talkCsv:
		if unitData then
			ui.newTTFLabelWithStroke({ text = currentTalk.roleTalk == 1 and game.role.name or self.currentPlots[plotIndex].heroName, size = 36, font = ChineseFont })
				:anch(0.5, 0.5):pos(nameFrameSize.width / 2, nameFrameSize.height / 2):addTo(self.leftNameFrame)
			--[[self.leftSprite = display.newSprite(unitData.heroRes)
			self.removeImages[unitData.heroRes] = true
			self.leftSprite:scale((640 - self.talkContentFrame:getContentSize().height) / 425)
				:anch(0, 0):pos(0, self.talkContentFrame:getContentSize().height - 10):addTo(self, -1)]]
			self.leftSprite=uihelper.createMaskSprite(unitData.cardRes,unitData.heroRes)
			self.leftSprite:scale((640 - self.talkContentFrame:getContentSize().height) / 850)
				:anch(0, 0):pos(0, self.talkContentFrame:getContentSize().height - 10):addTo(self, -1)

		end

	-- 不说话的一个人暗下去
	elseif currentTalk.type == 2 then
		if self.leftSprite then self.leftSprite:setColor(ccc3(90, 90, 90)) end
		self.leftNameFrame:hide()
		if self.rightSprite then self.rightSprite:removeSelf() end
		self.rightNameFrame:show()
		self.rightNameFrame:removeAllChildren()

		local heroType = self.roleHero and self.roleHero.type
		if currentTalk.roleTalk == 0 then
			heroType = currentTalk.heroType
		end

		local unitData = unitCsv:getUnitByType(heroType)
		if unitData then
			ui.newTTFLabelWithStroke({ text = currentTalk.roleTalk == 1 and game.role.name or self.currentPlots[plotIndex].heroName, size = 36, font = ChineseFont })
				:anch(0.5, 0.5):pos(nameFrameSize.width / 2, nameFrameSize.height / 2):addTo(self.rightNameFrame)
			--[[self.rightSprite = display.newSprite(unitData.heroRes)
			self.removeImages[unitData.heroRes] = true
			self.rightSprite:scale((640 - self.talkContentFrame:getContentSize().height) / 425)
				:anch(1, 0):pos(self:getContentSize().width, self.talkContentFrame:getContentSize().height - 10):addTo(self, -1)]]
			self.rightSprite=uihelper.createMaskSprite(unitData.cardRes,unitData.heroRes)
			self.rightSprite:scale((640 - self.talkContentFrame:getContentSize().height) / 850)
				:anch(1, 0):pos(self:getContentSize().width, self.talkContentFrame:getContentSize().height - 10):addTo(self, -1)
		end
	end
	self.talkContent:setString(currentTalk.content)

	return true
end

function BattlePlotLayer:onExit()
	for name, bool in pairs(self.removeImages) do
		display.removeSpriteFrameByImageName(name)
	end
end

return BattlePlotLayer