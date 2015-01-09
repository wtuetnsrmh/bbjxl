local PlotRes = "resource/ui_rc/battle/"

local GuidePlotLayer = class("GuidePlotLayer", function()
	return display.newLayer()
end)

function GuidePlotLayer:ctor(params)
	params = params or {}

	self.onComplete = params.onComplete
	self.priority = params.priority or -9999

	self.currentPlotId = 0
	self.currentPlots = nil
	self.currentPlotIndex = 1

	self.leftSprite = nil
	self.rightSprite = nil

	-- 注册touch事件处理函数
	self:addTouchEventListener(function(event, x, y) return self:onTouch(event, x, y) end, false, self.priority)
	self:setTouchEnabled(true)

	self.roleHero = game.role and game.role.heros[game.role.mainHeroId] or nil

	local guideData = guideCsv:getGuideById(params.guideId)
	self:initLayer(guideData.talkId, params.phase)

	self:anch(0.5, 0):pos(display.cx, 0)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1, opacity = 100 })
end

function GuidePlotLayer:initLayer(talkId)
	self.currentPlots = plotTalkCsv:getPlotTalkByCarbon(talkId, 1)
	if #self.currentPlots == 0 then return end

	table.sort(self.currentPlots, function(a, b) return a.plotId < b.plotId end)

	self.talkContentFrame = display.newSprite(PlotRes .. "dialog_plot.png")
	local talkContentFrameSize = self.talkContentFrame:getContentSize()

	local scaleValue = display.width / talkContentFrameSize.width
	self.talkContentFrame:setScaleX(scaleValue)
	self.talkContentFrame:anch(0.5, 0):pos(display.cx, 0):addTo(self)

	self.talkContent = ui.newTTFLabel({text = "", size = 32, color = display.COLOR_BLACK,
		dimensions = CCSizeMake(talkContentFrameSize.width * scaleValue - 200, talkContentFrameSize.height - 20) })
	self.talkContent:anch(0, 0.5):pos(100, talkContentFrameSize.height / 2 ):addTo(self)

	self.leftNameFrame = display.newSprite(PlotRes .. "name_plot.png")
	self.leftNameFrame:scale(scaleValue):anch(0, 0.5):pos(50, self.talkContentFrame:getContentSize().height):addTo(self)
	self.rightNameFrame = display.newSprite(PlotRes .. "name_plot.png")
	self.rightNameFrame:scale(scaleValue):anch(1, 0.5):addTo(self)
		:pos(display.width - 50, self.talkContentFrame:getContentSize().height)

	self:playPlot(self.currentPlotIndex)
end

function GuidePlotLayer:onTouch(event, x, y)
	if event == "began" then
		self.currentPlotIndex = self.currentPlotIndex + 1
		return self:playPlot(self.currentPlotIndex)
	end
end

function GuidePlotLayer:playPlot(plotIndex)
	local currentTalk = self.currentPlots[plotIndex]
	if currentTalk == nil and type(self.onComplete) == "function" then
		--剧情结束
		self:getLayer():removeSelf()
		self.onComplete()
		return false
	end

	local nameFrameSize = self.leftNameFrame:getContentSize()

	-- 不说话的一个人暗下去
	if currentTalk.type == 1 then
		if self.rightSprite then self.rightSprite:setColor(ccc3(90, 90, 90)) end
		self.rightNameFrame:hide()
		if self.leftSprite then self.leftSprite:removeSelf() self.leftSprite = nil end
		self.leftNameFrame:show()
		self.leftNameFrame:removeAllChildren()

		local heroType = self.roleHero and self.roleHero.type
		if currentTalk.roleTalk == 0 then
			heroType = currentTalk.heroType
		end

		local unitData = unitCsv:getUnitByType(heroType)
		if unitData then
			ui.newTTFLabelWithStroke({ text = unitData.name, size = 36, font = ChineseFont })
				:anch(0.5, 0.5):pos(nameFrameSize.width / 2, nameFrameSize.height / 2):addTo(self.leftNameFrame)
			--self.leftSprite = display.newSprite(unitData.heroRes)
			self.leftSprite=uihelper.createMaskSprite(unitData.cardRes,unitData.heroRes)
			self.leftSprite:scale((640 - self.talkContentFrame:getContentSize().height) / 850)
				:anch(0, 0):pos(0, self.talkContentFrame:getContentSize().height):addTo(self, -1)
		end

	-- 不说话的一个人暗下去
	elseif currentTalk.type == 2 then
		if self.leftSprite then self.leftSprite:setColor(ccc3(90, 90, 90)) end
		self.leftNameFrame:hide()
		if self.rightSprite then self.rightSprite:removeSelf() self.rightSprite = nil end
		self.rightNameFrame:show()
		self.rightNameFrame:removeAllChildren()

		local heroType = self.roleHero and self.roleHero.type
		if currentTalk.roleTalk == 0 then
			heroType = currentTalk.heroType
		end

		local unitData = unitCsv:getUnitByType(heroType)
		if unitData then
			ui.newTTFLabelWithStroke({ text = unitData.name, size = 36, font = ChineseFont })
				:anch(0.5, 0.5):pos(nameFrameSize.width / 2, nameFrameSize.height / 2):addTo(self.rightNameFrame)
			--self.rightSprite = display.newSprite(unitData.heroRes)
			self.rightSprite=uihelper.createMaskSprite(unitData.cardRes,unitData.heroRes)
			self.rightSprite:scale((640 - self.talkContentFrame:getContentSize().height) / 850)
				:anch(1, 0):pos(self:getContentSize().width, self.talkContentFrame:getContentSize().height):addTo(self, -1)
		end
	end
	self.talkContent:setString(currentTalk.content)

	return true
end

function GuidePlotLayer:getLayer()
	return self.mask:getLayer()
end

return GuidePlotLayer