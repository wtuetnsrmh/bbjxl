local DGBtn = import(".DGBtn")

--列表自动滑动方向
local NEXT = 1
local PREVIOUS = 0

DGScrollView = {
	width,
	height,
	mode,           --模式，0为列表模式，显示多个，能够自由滑动,1为切换模式，每次显示一页，且仅能翻一页
	index,          --切换模式有效，记录当前索引
	count,          --记录滑动列表中现有元素数
	dividerWidth,   --元素间隔
	nextPos,        --下一个元素起始位置
	xOffset,      	--横向偏移量
	yOffset,	  	--纵向偏移量
	active,   		--当点击到窗口中时，处于激活状态
	horizontal,  	--滑动方向,默认为纵向
	layer,        	--背景层
	contentLayer, 	--内容层，在此层中加入精灵等对象
	itemsWidth,   	--添加入元素的宽度，用来计算滑动切换的坐标
	moving,       	--翻页模式正在移动的状态，此状态下禁止操作
	items         	--添加的元素
}

--params｛｝其它参数，在翻 页模式时可添加page_callback作为翻页回调函数
function DGScrollView:new(params)
	local this= {}
	setmetatable(this,self)
	self.__index = self

	params = params or {}

	--初始化滚动窗口
	this.size = params.size
	this.dividerWidth = params.divider or 0
	this.nextPos = 0
	this.index = 1
	this.count = 0
	this.xOffset = 0
	this.yOffset = 0
	this.horizontal = params.horizontal
	this.mode = params.mode or 0
	this.priority = params.priority or -129
	this.dataSource = params.dataSource or {}
	this.cellAtIndex = params.cellAtIndex

	this.items = {}
	
	--其他参数，如回调 函数等
	this.params = params or {}
	this.itemsWidth = {}
	--内容层
	this.contentLayer = display.newLayer()

	--注册触屏监听
	local tempPos = 0  --保存上一次点击的位置，判断滑动方向
	local lastTouchPt   --最后点击的点坐标
	local lastTime     --最后点击的时间
    local selectedItem   --将选中的元素保存k

    --此函数在翻页模式时做滑动判断
	local function scrollX(x,y)
		if math.abs(x - lastTouchPt.x) > 20 then  -- 当移动超过20个像素判断滑动
			if x > lastTouchPt.x then  --上一页
				if this.index > 1 and this.index <= this.count then
					this:autoScroll(PREVIOUS, this.params)
				else
					this:autoScroll()
				end
			else
				if this.index < this.contentLayer:getChildrenCount() then
					this:autoScroll(NEXT,this.params) --下一页
				else
					this:autoScroll()
				end
			end
		else  -- 否则返回原位置
			this:autoScroll()
		end
	end

	local function inertiaScroll(x,y) -- 此函数在列表模式时做惯性滑动的判断
		local params  --跟据触摸时间判断是否要惯性滑动
		if (device.platform ~= "ios") then --非ios平台有惯性滑动,ios屏蔽
			if os.clock() - lastTime < 0.3 then
				local value
				if this.horizontal then
					value = (x - lastTouchPt.x) / (os.clock() - lastTime)
				else
					value = (y - lastTouchPt.y) / (os.clock() - lastTime)
				end
				params = {inertia = value }	--传递滑动的惯性速度
			end
		end
		
		this:autoScroll(nil,params)
	end

	function this.contentLayer:onTouch(event,x,y)
		--判断点击事件是否在点击区域内
		if uihelper.nodeContainTouchPoint(this.layer, ccp(x, y)) then
			if event == "began" then
				if this.moving then   --正在移动状态，则屏蔽点击
					return false
				end
				this.active = true
				this.contentLayer:stopAllActions()  --点击时停止所有动作
				lastTouchPt = ccp(x,y)
				lastTime = os.clock()    --保存点击的时间计算滑动的位置
				if this.horizontal then
					this.xOffset = this.contentLayer:getPositionX()
					tempPos = x
				else
					tempPos = y
					this.yOffset = this.contentLayer:getPositionY()
				end
				return true
			elseif event == "moved" then    -- 内容区域以左下角为原点，可以向右向下滑动，
				if this.active then    --若激活
					if this.horizontal then
						this.xOffset = this.xOffset + (x - tempPos)
						this.contentLayer:setPosition(ccp(this.xOffset, this.yOffset))
						tempPos = x
					else
						this.yOffset = this.yOffset + (y - tempPos)
						this.contentLayer:setPosition(ccp(this.xOffset,this.yOffset))
						tempPos = y
					end
				end
				return true
			else
				if this.active then
					if this.mode == 0 then   --列表模式，当点击结束后自动调整菜单
						if selectedItem then
							selectedItem:setEnabled(true)
							selectedItem = nil
						end
						inertiaScroll(x,y)
					else                --视图切换模式，当点击结束后换到下一个页面
						this.moving = true
						if this.horizontal then
							scrollX(x,y)
						else
							if y > lastTouchPt.y then
							else
							end
						end
					end
					this.active = false
					tempPos = 0
					lastTouchPt = nil
					lastTime = nil
				end
				return false
			end
		else --若移出有效区则检测是否要将位置重置到原点
			if this.active then
				this.active = false
				if this.mode == 0 then          --列表模式
					if selectedItem then
						selectedItem:setEnabled(true)
						selectedItem = nil
					end
					inertiaScroll(x,y) --移出后做惯性判断
				else     --翻页模式
					this.moving = true
					scrollX(x,y)
				end
			end
			lastTime = nil
			return true
		end
	end

	this.contentLayer:setPosition(ccp(0,0));
	this.contentLayer:setTouchEnabled(true)
	this.contentLayer:registerScriptTouchHandler(function(event,x,y) return this.contentLayer:onTouch(event,x,y) end, false , this.priority )

	--滚动窗口位置与大小设置，超出此窗口的部分都将隐藏	
	this.baseLayer = CCClippingLayer:create()
	this.baseLayer:setContentSize(this.size)
	this.baseLayer:addChild(this.contentLayer)

	this.layer = display.newLayer()
	this.layer:setContentSize(this.size)
	this.layer:addChild(this.baseLayer)

	return this
end

--向view中添加元素，自行调 整位置,添加按钮时将按钮元素加入表中
function DGScrollView:addChild(content,item)
	if item then
		table.insert(self.items,item)
	end
	
	content:ignoreAnchorPointForPosition(false)
	local anchPoints = content:getAnchorPointInPoints()
	local noChild = self.contentLayer:getChildrenCount() == 0
	if self.horizontal then
		content:setPosition(ccp((noChild and 0 or self.dividerWidth) + self.nextPos + anchPoints.x, anchPoints.y))
		self.nextPos = content:getPositionX() + content:getContentSize().width * content:getScaleX()

		table.insert(self.itemsWidth, content:getContentSize().width * content:getScaleX())
	else
		if noChild then
			self.nextPos = self.size.height - content:getContentSize().height + anchPoints.y
		else
			self.nextPos = self.nextPos - content:getContentSize().height * content:getScaleY() - self.dividerWidth
		end

		content:setPosition(ccp(anchPoints.x, self.nextPos))

		table.insert(self.itemsWidth, content:getContentSize().height * content:getScaleY())
	end
	self.count = self.count + 1
	self.contentLayer:addChild(content)
end

function DGScrollView:reloadData(dataSource)
	self.contentLayer:removeAllChildren()
	self:removeAll()

	self.dataSource = dataSource or self.dataSource
	for index, data in ipairs(self.dataSource) do
		local cell = self.cellAtIndex(data)
		self:addChild(cell)
	end
	self:alignCenter()
end

--设置元素居中显示
function DGScrollView:alignCenter()
	local group = self.contentLayer:getChildren()
	local item
	if group then
		for i = 0,group:count()-1 do
			item = group:objectAtIndex(i)		
			tolua.cast(item,"CCLayer")
			local anchPoints = item:getAnchorPointInPoints()
			if self.horizontal then
				item:setPositionY((self.size.height - item:getContentSize().height) / 2 + anchPoints.y)
			else
				item:setPositionX((self.size.width - item:getContentSize().width) / 2 + anchPoints.x)
			end
		end
	end
end

--滑动组件进入动画效果
function DGScrollView:effectIn()
	local group = self.contentLayer:getChildren()
	local item
	local time, count = 0.10, 1
	if group then
		for i = 0, group:count() - 1 do
			item = group:objectAtIndex(i)
			local posX = item:getPositionX()
			local posY = item:getPositionY()
			if (posY + self.yOffset > -item:getContentSize().height) and (posY + self.yOffset < self.size.height) then
				item:setPositionX(-item:getContentSize().width)	
				item:runAction(CCMoveTo:create(time,ccp(posX,item:getPositionY())))
				time = time + count * 0.10
				count = count + 1
			end
		end
	end
end

--跟据视图状态自动滚动
function DGScrollView:autoScroll(direction, params, noAni) --参数在视图切换模式时使用
	local autoMove
	local cha --菜单项与显示栏的差值，若小于显示窗则自动滚动时回到原点
	local time = 0.5 
	
	if noAni then time = 0 end
	
	if self.horizontal then
		if self.mode == 0 then  -- 列表模式
			if self.xOffset + self.nextPos < self.size.width then  --若已滑动到最右端
				cha = self.size.width - self.nextPos -- 若菜单小于可显示区域
				if cha < 0 then cha = 0 end

				self.xOffset = self.size.width - self.nextPos - cha
				--时间为0的时候直接设置位置,可以避免取绝对位置的误差
				if time == 0 then
					self.contentLayer:pos(self.xOffset, self.contentLayer:getPositionY())
				else
					autoMove = CCMoveTo:create(time, ccp(self.xOffset,self.contentLayer:getPositionY()))
					self.contentLayer:runAction(autoMove)
				end

			elseif self.xOffset > 0 then 	--若已滑动到最左端
				self.xOffset = 0
				if time == 0 then
					self.contentLayer:pos(self.xOffset, self.contentLayer:getPositionY())
				else
					autoMove = CCMoveTo:create(time,ccp(self.xOffset, self.contentLayer:getPositionY()))
					self.contentLayer:runAction(autoMove)
				end

			else
				if params and params["inertia"] then    --惯性滑动条件
					self.xOffset = params["inertia"] + self.xOffset
					--当滑动的位置大超出边界，则将最终位置设置为能够启用回弹效果的位置
					if self.xOffset > 0 then
						self.xOffset = self.size.width / 8
					elseif self.xOffset + self.nextPos < self.size.width then
						self.xOffset =self.size.width / 1.2 -self.nextPos
					end
					local array = {}
					array[#array + 1] = CCEaseExponentialOut:create(CCMoveTo:create(1,ccp(self.xOffset,self.yOffset)))
					array[#array + 1] = CCCallFunc:create(function() self:autoScroll() end)
					self.contentLayer:runAction(transition.sequence(array))

				elseif params and params["scrollTo"] then --在列表模式时设置将第几个元素滑动到可见位置
					local total = 0
					for i = 1, params["scrollTo"] do
						total = total + self.itemsWidth[i]
					end
					if total + self.xOffset < self.itemsWidth[params["scrollTo"]] / 2 then
						self.xOffset = -(total - self.itemsWidth[params["scrollTo"]])
					elseif total + self.xOffset > self.size.width then
						self.xOffset = self.xOffset - self.itemsWidth[params["scrollTo"]]
					end
					if time == 0 then
						self.contentLayer:pos(self.xOffset, self.yOffset)	
					else
						self.contentLayer:runAction(CCMoveTo:create(time,ccp(self.xOffset,self.yOffset)))
					end
				end
			end

		else     -- 视图切换模式
			if direction == NEXT then   -- 下一页
				self.index = self.index + 1
			elseif direction == PREVIOUS then
				self.index = self.index - 1
			elseif params and params["index"] then    --设置滑动到第几页
				self.index = params["index"]
			end

			self.xOffset = -(self.size.width + self.dividerWidth) * (self.index - 1)
			--翻页后的callback
			local array = {}
			array[#array + 1] = CCMoveTo:create(time,ccp(self.xOffset,self.contentLayer:getPositionY()))
			array[#array + 1] = CCCallFunc:create(function() self.moving = false end)
			if params and params["page_callback"] then
				array[#array + 1] = CCCallFunc:create(params["page_callback"])
			end
			self.contentLayer:runAction(transition.sequence(array))
		end

	else     --纵向滑动
		if self.mode == 0 then   --列表模式
			if self.nextPos + self.yOffset > 0 then --已到最底部
				if self.nextPos < 0 then
					self.yOffset = math.abs(self.nextPos)
				else
					self.yOffset = 0
				end
				if time == 0 then
					self.contentLayer:pos(self.contentLayer:getPositionX(), self.yOffset)
				else
					autoMove = CCMoveTo:create(time,ccp(self.contentLayer:getPositionX(),self.yOffset))
					self.contentLayer:runAction(autoMove)
				end
			elseif self.yOffset < 0 then   -- 已到最顶部
				self.yOffset = 0
				autoMove = CCMoveTo:create(time,ccp(self.contentLayer:getPositionX(),self.yOffset))
				if time == 0 then
					self.contentLayer:pos(self.contentLayer:getPositionX(), self.yOffset)
				else
					autoMove = CCMoveTo:create(time,ccp(self.contentLayer:getPositionX(),self.yOffset))
					self.contentLayer:runAction(autoMove)
				end	
			else  --惯性滑动位置
				if params and params["inertia"] then    --惯性滑动条件
					self.yOffset = params["inertia"] + self.yOffset
					if self.yOffset < 0 then
						self.yOffset = -self.size.height / 8
					elseif self.yOffset + self.nextPos > 0  then
						self.yOffset = math.abs(self.nextPos) + self.size.height / 8
					end
					local array = {}
					array[#array + 1] = CCEaseExponentialOut:create(CCMoveTo:create(1,ccp(self.xOffset,self.yOffset)))
					array[#array + 1] = CCCallFunc:create(function() self:autoScroll() end)
					self.contentLayer:runAction(transition.sequence(array))
				end
			end
		else
			--  翻页切换模式
		end
	end
end

--返回主布局对象
function DGScrollView:getLayer()
	return self.layer
end

function DGScrollView:getCurIndex()
	return self.index
end

--返回所有元素
function DGScrollView:getItems(index)
	if index then
		return self.items[index]
	else
		return self.items
	end
end

function DGScrollView:removeAll()
	self.contentLayer:removeAllChildren()
	for k,v in pairs(self.items) do
		if v.release then
			v:release()
		end
	end
end

--设置当前的选项
function DGScrollView:setIndex(index,noAni,space)
	self.index = index
	if self.horizontal then	
		self.xOffset = -(space or self.itemsWidth[1] + self.dividerWidth) * (self.index - 1)
		if noAni then
			self.contentLayer:setPosition(ccp(self.xOffset,self.contentLayer:getPositionY()))
		end
	else
		self.yOffset = 0
		for idx = 1, index-1 do
			self.yOffset = self.yOffset + self.itemsWidth[idx] + self.dividerWidth
		end
		if noAni then
			self.contentLayer:setPosition(ccp(self.contentLayer:getPositionX(),self.yOffset))
		end
	end
	self:autoScroll(nil, { inertia = 0 }, noAni)
end

function DGScrollView:scrollTo(id, noAni)
	local index
	for k, v in pairs(self.items) do
		if v:getId() == id then
			index = k
			break
		end
	end

	if index then
		self:setIndex(index, noAni)
	end
end

function DGScrollView:getWidth()
	return self.size.width
end

function DGScrollView:getHeight()
	return self.size.height
end

function DGScrollView:getOffsetX()
	return self.contentLayer:getPositionX() --实际的偏移量
end

function DGScrollView:getOffsetY()
	return self.contentLayer:getPositionY() --实际偏移量
end

function DGScrollView:getOffset()
	if self.horizontal then
		return self:getOffsetX()
	else
		return self:getOffsetY()
	end
end

function DGScrollView:setOffset(offset)
	if self.horizontal then
		self.xOffset = offset
		self.contentLayer:setPositionX(offset)
	else
		self.yOffset = offset
		self.contentLayer:setPositionY(offset)
	end
end

function DGScrollView:setEnable(bool)
	self.contentLayer:setTouchEnabled(bool)
end

return DGScrollView