local NORMAL, SELECTED, DISABLE  = 1, 2, 3
local CANCELDIS = 50 --取消按钮响应的距离 
local scale = 1.1

DGBtn = {
	layer,
	item ,
	params,
	programChange,  --是否是程序改变的改果
	chosen,           -- 按钮允许选中时此变量表示已选择状态
	group,          --按钮所在的按钮组
	state,         --按钮当前状态
	textItems,
}

local scheduler = require("framework.scheduler")

--[[
	参数file必须是一个table存放按钮的效果图片名称                                              ( {"普通","选中","禁用"})   普通图片必须存在，其余任选

	额外的参数， params = {}
	callback:     单击回调函数，                                                                            (function)
	selectable:   单击后处于选中,默认false,                     (true,false)
	scale：       若无图片，则程序实现放大效果，                                               (true,false)
	hightLight:   若无图片，则程序实现高亮效果，效果可以同时叠加使用 ({r,g,b})
	front,        当有通用背景时，此参数可做按钮文字                                       (string)
	group:        是否在单选按钮组                                                                         (KNRadioGroup)
	upSelect      弹起时选中 ，只在弹起时触发选中状态                                       (true,false)
	noHide        在选中状态时，是否隐藏普通状态图 片，用于选中状态是加边框的效果
	text          程序绘制文字时添加此参数   ("string")
	disableWhenChoose,        当按钮被选中时，再次点击是否触发callback,为true时不再触发
	priority;     点击事件的优先级设置，KNMask的优先级为-129,若需要此按钮在有mask时能够点击，则将优先级设置为-130以上
	selectZOrder, 选中按钮的层级
	noTouch,     不可点击
	doubleClick, 双击
	clickFun, 双击时单击回调
	]]
function DGBtn:new(path, file, params, group)
	local this = {}
	setmetatable(this,self)
	self.__index = self

	this.params = params or {}
	this.params.multiClick = this.params.multiClick == nil and true or this.params.multiClick
	this.params.checkContain = this.params.checkContain == nil and true or this.params.checkContain
	this.item = {}
	this.textItems = {}
	this.group = group
	this.layer = display.newLayer()
	this.layer:ignoreAnchorPointForPosition(false)
	this.layer:anch(0, 0)
	this.isDoubleClick = false
	if params.swallowsTouches==nil then
		this.swallowsTouches=true
	else
		this.swallowsTouches=params.swallowsTouches
	end
	

	if path and string.sub(path,string.len(path)) ~= "/" then
		path = path .. "/"
	end

	local anchor = this.params["selectAnchor"] or { 0.5, 0.5 }

	--跟据参数初始化按钮状态图片
	for i = 1, table.nums(file)	do
		local z = 0
		if file[i] ~= "nil" then
			if not path then 
				path = "" 
			end
			this.item[i] = display.newSprite(path .. file[i])
			if this.params["flipX"] then  --水平翻转
				this.item[i]:setFlipX(true)
			end 

			if i == 1 then
				this.size = this.item[1]:getContentSize()
				this.layer:size(this.size)
			end

			this.layer:anch(anchor[1], anchor[2])
			local anchorPointInPoints = this.layer:getAnchorPointInPoints()

			this.item[i]:anch(anchor[1], anchor[2])
				:pos(anchorPointInPoints.x, anchorPointInPoints.y)
			
			if i == SELECTED then  --默认1，普通，2：选中，3：禁用
				z = this.params["selectZOrder"] or -1
			else
				z = 0
			end
			this.item[i]:setVisible(false)
			this.layer:addChild(this.item[i],z)
		else
			this.item[i] = "nil"
		end
	end
	this.layer:anch(0, 0)

	if this.params["front"] then
		if type(this.params["front"]) == "string" then
			this.item["front"] = display.newSprite(this.params["front"])
			this.item["front"]:pos(this.size.width / 2, this.size.height / 2)
				:addTo(this.layer, this.params["frontZOrder"] or 10)
			
			--若front是单张图片
			if this.params["frontScale"] then
				this.item["front"]:setScale(this.params["frontScale"][1])
				if this.params["frontScale"][2] then  --x轴偏移
					this.item["front"]:setPositionX(this.params["frontScale"][2] + this.item["front"]:getPositionX())
				end
				if this.params["frontScale"][3] then  --y轴偏移
					this.item["front"]:setPositionY(this.params["frontScale"][3] + this.item["front"]:getPositionY())
				end
			end
			elseif type(this.params["front"]) == "table" then
				this.item["front"] = {}
				this.item["front"][1] = display.newSprite(this.params["front"][1])
				this.item["front"][1]:pos(this.size.width / 2, this.size.height / 2)
					:addTo(this.layer, 10)
				
				this.item["front"][2] = display.newSprite(this.params["front"][2])
				this.item["front"][2]:pos(this.size.width / 2, this.size.height / 2):hide()
					:addTo(this.layer, 10)
				
			--若front有多个
			if this.params["frontScale"] then
				for i, v in pairs(this.item["front"]) do
					v:setScale(this.params["frontScale"][1])
					if this.params["frontScale"][2] then  --x轴偏移
						v:setPositionX(this.params["frontScale"][2] + v:getPositionX())
					end
					if this.params["frontScale"][3] then  --y轴偏移
						v:setPositionY(this.params["frontScale"][3] + v:getPositionY())
					end
				end
			end
		end
		
	end

	if this.params["text"] then
		local text
		if this.params["text"]["bmf"] then
			text = ui.newBMFontLabel(this.params["text"])
		elseif this.params["text"]["strokeColor"] then
			text = ui.newTTFLabelWithStroke(this.params["text"])
		elseif this.params["text"]["shadowColor"] then
			text = ui.newTTFLabelWithShadow(this.params["text"])
		else
			text = ui.newTTFLabel(this.params["text"])
		end

		text:anch(0.5, 0.5):pos(this.size.width / 2, this.size.height / 2):addTo(this.layer, 10)
		table.insert(this.textItems, text)
	end

	local press , moveOn   --press为是否按下，moveOn 为按钮按下后是否有移动 j
	local lastX = 0  -- lastX 最后点击的坐标
	local lastY = 0  --lastY 最后点击的坐标
	local lastClickTime = 0 	-- 最后一次点击时间
	local lastStatus = 0
	
	local touchScale = this.params["touchScale"] or { 1, 1}
	if type(touchScale) == "number" then
		touchScale = { this.params["touchScale"], this.params["touchScale"] }
	end

	function this.layer:onTouch(type, x, y)
		if this.state == DISABLE then  --禁 用状态直接返回
			return false
		end

		if this.params["parent"] and not uihelper.nodeContainTouchPoint(this.params["parent"], ccp(x, y)) then
			press = false
			moveOn = false
			lastX = 0
			lastY = 0
			lastClickTime = 0
			lastStatus = 0
			self.lastStatus=0
			this.isDoubleClick = false
			return false
		else
			if type ==  "began" then
				if not params.doubleClick and not params.multiClick and os.time() - lastClickTime <= 1 then
					 return
				end
				this.isDoubleClick = false
				-- 双击
				if params.doubleClick and os.time() - lastClickTime >= 0.4 then
					-- print("lastClickTime :",os.time() - lastClickTime)
					if uihelper.nodeContainTouchPoint(this.layer, ccp(x, y), touchScale) then

						lastClickTime = os.time()
						if params.clickFun then
							self:performWithDelay(function()
								if not this.isDoubleClick then
									params.clickFun()
								end
								
							end, 0.4)
							
						end
					end
					return
				end
				this.isDoubleClick = true

				if uihelper.nodeContainTouchPoint(this.layer, ccp(x, y), touchScale) then
					press = true
					moveOn = true
					local rect = this.layer:getCascadeBoundingBox()
					lastX = rect:getMinX()
					lastY = rect:getMinY()
					lastClickTime = os.time()
					lastStatus = this.state
					self.lastStatus=this.stated

					if not this.params["upSelect"] then  --抬起选中效果时不触发选中状态
						this:setState(SELECTED)
						if not this.params["soundOff"] then
							if not this.params["musicId"] then
								if game then 
									if game.soundOn then
										audio.playEffect("music/sound/clickButton.mp3", false)
									end
								else
									audio.playEffect("music/sound/clickButton.mp3", false)
								end
							else
								game:playMusic(this.params["musicId"])
							end
						end
					end

					if this.params["scheduleCallback"] then
						self.scheduleHandler = scheduler.scheduleGlobal(function ()
							this.params["scheduleCallback"]()
						end, 1)
					end
				else
					-- 不能响应点击
					return false
				end
			elseif type == "moved" then
				if this.params["upSelect"] then
					local rect = this.layer:getCascadeBoundingBox()
					if math.abs(rect:getMinX() - lastX) > CANCELDIS or math.abs(rect:getMinY() - lastY) > CANCELDIS or
						not rect:containsPoint(ccp(x,y)) then
						press = false
						moveOn = false
						return false
					end
				else
					local rect = this.layer:getCascadeBoundingBox()
					if math.abs(rect:getMinX() - lastX) > CANCELDIS or math.abs(rect:getMinY() - lastY) > CANCELDIS or
						not rect:containsPoint(ccp(x,y)) then
						press = not this.params["checkContain"] and true or false
						moveOn = not this.params["checkContain"] and true or false
						this:setState(NORMAL)
						return false
					end
					
					if rect:containsPoint(ccp(x,y)) then
						if press then
							moveOn = true
							this:setState(SELECTED)
						end
					else
						if press then
							moveOn = false
							if group or this.params["selectable"] then  --若按钮有选中状态
								if group then     --在单选按钮组中时优先设置
									if group:getChooseBtn()	~= this then
										this:setState(NORMAL)
									end
								else
									if not this.chosen then
										this:setState(NORMAL)
									end
								end
							else                                  --普通按钮
								this:setState(NORMAL)
							end
						end
					end
				end
			elseif type == "ended" then
				if not this.params["checkContain"] or uihelper.nodeContainTouchPoint(this.layer, ccp(x, y), touchScale) then
					if press and moveOn then
						--发送点击成功
						if game and not this.params["notSendClickEvent"] then
							game:dispatchEvent({name = "btnClicked", data = this.layer})
						end
						--放开后执行回调
						local result --callback执行的结果，默认返回nil 如果是反回false则不触发单选组的选中效果
						if this.params["callback"] then
							if not this.params["disableWhenChoose"] then
								result = this.params["callback"]()
							else
								if not this.chosen then
									result = this.params["callback"]()
								end
							end
						end

						if result ~= false then	
							--设置是否选中
							if not this.params["selectable"] then
								this:setState(NORMAL)
							else
								this:select(not this.chosen)
							end
							if group then
								group:chooseBtn(this)
							end	
						else
							this:setState(NORMAL)
						end

					end
				else
					this:setState(lastStatus,true)
				end

				if self.scheduleHandler then
					scheduler.unscheduleGlobal(self.scheduleHandler)
				end

				press = false
				moveOn = false
				lastX = 0
			end
		end
		return true
	end
	--设置按钮的优先级
	local priority = -28
	if this.params["priority"] then
		priority = this.params["priority"]
	end

	this.layer:addTouchEventListener(function(type,x,y) return this.layer:onTouch(type,x,y) end,false,priority,this.swallowsTouches)
	
	if this.params["disable"] then
		this:setEnable(false)
	else
		this:setEnable(true)
	end
	
	if this.params["noTouch"] then  --仅禁止点击
		this.layer:setTouchEnabled(false)
	end
	
	if group then
		group:addItem(this)
		if not group:getChooseBtn() then
			group:chooseBtn(this,true)
		end
	end

	function this.layer:setOpacity(opacity)
		this:setOpacity(opacity)
	end

	return this
end

function DGBtn:getLayer()
	return self.layer
end

--[[设置透明度]]
function DGBtn:setOpacity(opacity)
	for i = 1 , #self.item do
		self.item[i]:setOpacity(opacity)
	end
end

function DGBtn:setState(state,groupClick)
	self.state = state
	local done = false
	for i = 1, table.getn(self.item) do
		if self.item[i] ~= "nil" then
			if i == state then
				done = true
				self.item[i]:setVisible(true)
				
				if self.item["front"] and type(self.item["front"]) == "table" then  --若按钮前景有设置普通与选中状态，则根据当前状态来设置前景状态
					if i == NORMAL then 
						self.item["front"][1]:setVisible(true)
						self.item["front"][2]:setVisible(false)
					else
						self.item["front"][1]:setVisible(false)
						self.item["front"][2]:setVisible(true)
					end
				end

				if i == NORMAL and self.programChange then --当设置回普通状态时,若是程序改变的效果则回复原状态
					if self.params["scale"] then
						self:getLayer():setScale(1)
					end
					if self.params["highLight"] then
						transition.tintTo(self.item[1])
					end
				end
			else
				if #self.item > 1 then
					self.item[i]:setVisible(false)
				end
				if state == SELECTED and self.params["noHide"] then
					self.item[i]:setVisible(true)
				end
			end
		end
	end

	--强制点击缩放
	if self.params["forceScale"] then self:getLayer():setScale(1) end
	if self.params["forceScale"] and not groupClick then
		local temp=(self.group.curBtn and self.group:getId()==self:getId()) and 2 or 1
		if state==SELECTED then
			for i = 1, table.getn(self.item) do
				if i== temp then
					if self.item[i] ~= "nil" then
						self.item[i]:setVisible(true)
						self:getLayer():setScale(self.params["forceScale"])
					end
				else
					self.item[i]:setVisible(false)
				end
				
			end
		else
			self:getLayer():setScale(1)
		end

		done=true
	end

	--若设置失败，说明图片不存在则使用程序的方式进行改变
	if not done then
		if state == SELECTED then
			if self.params["scale"] then
				--若传进来的是比例则优先使用，否则默认为1.2
				if type(self.params["scale"]) == "number" then 
					scale = self.params["scale"]
				end
				self.item[1]:setVisible(true)
				self:getLayer():setScale(scale)
			end
			if self.params["highLight"] then
				self.item[1]:setVisible(true)
				transition.tintTo(self.item[1],{time = 0,r = self.params["highLight"][1],g = self.params["highLight"][2],b = self.params["highLight"][3]})
			end
			self.programChange = true
		else
		end
	end
end

function DGBtn:select(selecte,callback)
	if self.group or self.params["selectable"] then
		if selecte then
			self:setState(SELECTED,true)
			if callback then  --若选中时需要要执行按钮的回调 ，则将callback置为true
				self.params["callback"]()
			end
		else
			self:setState(NORMAL)
		end
		self.chosen = selecte
	end
end

function DGBtn:showBtn(bool)
	self.layer:setVisible(bool)
end
--当前显示状态
function DGBtn:getShow()
	self.layer:isVisible()
end

function DGBtn:setBg(state,path)
	if type(path) == "string" then
		self.item[state]:setTexture(display.newSprite(path):getTexture())
	elseif type(path) == "userdata" then
		self.item[state]:setTexture(path:getTexture())
	else
		for i = 1, #path do
			self.item[i]:setTexture(display.newSprite(path[i]):getTexture())
		end
	end
end


function DGBtn:setFront(path)
	self.item["front"]:setTexture(display.newSprite(path):getTexture())
end
function DGBtn:getFront()
	return self.item["front"]
end
function DGBtn:setEnable(bool)
	self.layer:setTouchEnabled(bool)
	if not bool then
		self:setState(DISABLE)
	else
		self:setState(NORMAL)
	end
end

function DGBtn:getWidth()
	return self.layer:getContentSize().width
end

function DGBtn:getHeight()
	return self.layer:getContentSize().height
end

function DGBtn:setPosition(x,y)
	self.layer:setPosition(ccp(x,y))
end

function DGBtn:getX()
	return self.layer:getPositionX()
end

function DGBtn:getY()
	return self.layer:getPositionY()
end
function DGBtn:setFlip(horizontal)
	if horizontal then
		for i = 1, #self.item do
			self.item[i]:setFlipX(true)
		end
	else
		for i = 1, #self.item do
			self.item[i]:setFlipY(true)
		end
	end
end

function DGBtn:getId()
	return self.params["id"]
end

function DGBtn:call()
	if self.params["callback"] then
		self.params["callback"]()
	end
end

function DGBtn:getCallback()
	return self.params["callback"]
end

function DGBtn:setCallback(callback)
	self.params["callback"] = callback
end

function DGBtn:getState()
	return self.state == NORMAL
end

function DGBtn:isSelect()
	return self.chosen
end

function DGBtn:setText(str, index)
	if self.textItems then
		self.textItems[index or 1]:setString(str)
	end
end

-- 设置字体大小
function DGBtn:setTextFontSize(size, index)
	if self.textItems then
		self.textItems[index or 1]:setFontSize(size)
	end
end

function DGBtn:setParent(parent)
	self.params["parent"] = parent
end

local setNodeGray
setNodeGray = function(isGray, node)
	local shadeProgram = UIUtil:shaderForKey(isGray and "ShaderPositionTextureGray" or "ShaderPositionTextureColor") 
	node:setShaderProgram(shadeProgram)
	local children = node:getChildren()
	local childsNum = node:getChildrenCount()
	for index = 0, childsNum - 1 do
		local child = tolua.cast(children:objectAtIndex(index), "CCNode")
		setNodeGray(isGray, child)
	end
end

function DGBtn:setGray(isGray)
	setNodeGray(isGray, self:getLayer())
end

return DGBtn
