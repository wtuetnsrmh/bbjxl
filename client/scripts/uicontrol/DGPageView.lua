--列表自动滑动方向
local NEXT = 1
local PREVIOUS = 0
local SpeedLimit = 800

DGPageView = class("DGPageView")

function DGPageView:ctor(params)
	require("framework.api.EventProtocol").extend(self)

	params = params or {}
	self.size = params.size
	self.priority = params.priority or -129
	self.dataSource = params.dataSource
	self.newCellHandler = params.cellAtIndex
	self.curPageIndex = params.initPageIndex or 1
	self.lastPageIndex = params.lastPageIndex or table.nums(self.dataSource)

	self.layer = CCLayerExtend.extend(CCClippingLayer:create())
	self.layer:setContentSize(self.size)
	self.layer:setTouchEnabled(true)
	self.layer:registerScriptTouchHandler(function(event,x,y) return self:onTouch(event,x,y) end, false, self.priority)

	self:initPageContent(self.curPageIndex)
	self.drag = {}
end

function DGPageView:initPageContent(pageIndex)
	if pageIndex < 1 then pageIndex = 1 end
	if pageIndex > self.lastPageIndex then pageIndex = self.lastPageIndex end

	if self.curPage then 
		self.curPage:removeSelf() 
	end

	self.curPage = self.newCellHandler(pageIndex)
	self.layer:addChild(self.curPage)

	self.curPageIndex = pageIndex
	self:dispatchEvent({name = "changePageIndex", pageIndex = self.curPageIndex})
end

function DGPageView:refresh()
	if self.curPageIndex > 0 and self.curPageIndex <= self.lastPageIndex then
		self:initPageContent(self.curPageIndex)
	else
		self:initPageContent(1)
		self.curPageIndex = pageIndex
		self:dispatchEvent({name = "changePageIndex", pageIndex = self.curPageIndex })
	end
end

function DGPageView:onTouch(event, x, y)
	if uihelper.nodeContainTouchPoint(self.layer, ccp(x, y)) then
		if event == "began" then
			-- 正在移动状态，则屏蔽点击
			if self.drag.active then return false end

			self.drag.active = true
			self.drag.lastTouchPt = ccp(x, y)
			self.drag.lastTime = os.clock()

			return true

		elseif event == "moved" then
		else
			local speed = (x - self.drag.lastTouchPt.x) / (os.clock() - self.drag.lastTime)

			-- 往前翻
			if speed > SpeedLimit then
				self:autoScroll(PREVIOUS)
			-- 往后翻
			elseif speed < -SpeedLimit then
				self:autoScroll(NEXT)
			else
				self.drag = {}
			end
		end
	else
		-- 点击超出范围
		if event == "ended" and self.drag.lastTouchPt then
			local speed = (x - self.drag.lastTouchPt.x) / (os.clock() - self.drag.lastTime)

			-- 往前翻
			if speed > SpeedLimit then
				self:autoScroll(PREVIOUS)
			-- 往后翻
			elseif speed < -SpeedLimit then
				self:autoScroll(NEXT)
			end
		end
	end
end

function DGPageView:autoScroll(direction)
	if direction == PREVIOUS then
		-- 第一页
		if self.curPageIndex == 1 then self.drag = {} return end

		local prePage = self.newCellHandler(self.curPageIndex - 1)
		if not prePage then return end

		prePage:pos(prePage:getPositionX() - self.size.width, prePage:getPositionY()):addTo(self.layer)
			:moveBy(0.5, self.size.width)
		self.isScroll = true
		self.curPage:runAction(transition.sequence({
			CCMoveBy:create(0.5, ccp(self.size.width , 0)),
			CCRemoveSelf:create(),
			CCCallFunc:create(function() 
				self.curPage = prePage 
				self.curPageIndex = self.curPageIndex - 1
				self.drag = {}
				self.isScroll = false
				display.removeUnusedSpriteFrames()
			end)
		}))
	else
		if self.curPageIndex == self.lastPageIndex then self.drag = {} return end

		local nextPage = self.newCellHandler(self.curPageIndex + 1)
		if not nextPage then return end
		
		nextPage:pos(nextPage:getPositionX() + self.size.width, nextPage:getPositionY()):addTo(self.layer)
			:moveBy(0.5, -self.size.width)
		self.isScroll = true
		self.curPage:runAction(transition.sequence({
			CCMoveBy:create(0.5, ccp(-self.size.width , 0)),
			CCRemoveSelf:create(),
			CCCallFunc:create(function() 
				self.curPage = nextPage 
				self.curPageIndex = self.curPageIndex + 1
				self.drag = {}
				self.isScroll = false
				display.removeUnusedSpriteFrames()
			end)
		}))
	end

	self:dispatchEvent({name = "changePageIndex", 
		pageIndex = direction == PREVIOUS and self.curPageIndex - 1 or self.curPageIndex + 1 })
end

function DGPageView:setEnable(enable)
	self.canScroll = enable
	self.layer:setTouchEnabled(enable)
end

function DGPageView:getCurPageIndex()
	return self.curPageIndex
end

function DGPageView:getLayer()
	return self.layer
end

return DGPageView