local NORMAL, CHOOSE, LOCK = 1, 2, 3

DGCheckBox = {
	layer,
	choose,
	lock,
	params,
	state,  --复选框状态
}
	
--[[
	params参数说明：
	path: 目录
	file={"背景","选中","锁定"}
	state:初始化时的状态，默认为普通
	callback:  选择复选框时的操作 
]]
function DGCheckBox:new(params)
	local this = {}
	setmetatable(this,self)
	self.__index = self
	
	this.layer = display.newLayer()
	this.params = params or {}
	this.state = params["state"] or NORMAL

	
	if string.sub(params["path"],string.len(params["path"])) == "/" then  --去掉末尾的分隔符
		params["path"] = string.sub(params["path"],0,string.len(params["path"]) - 1)
	end
	
	--复选框背景，必需
	local bg = display.newSprite(params["path"].."/"..params["file"][1])
	bg:anch(0, 0):pos(0, 0):addTo(this.layer)
	local bgSize = bg:getContentSize()
	
	--复选框选中状态，必须
	this.choose = display.newSprite(params["path"].."/"..params["file"][2])
	this.choose:pos(bgSize.width / 2, bgSize.height / 2):addTo(this.layer)
	
	--复选框锁定，可选
	if params["file"][3] then
		this.lock = display.newSprite(params["path"].."/"..params["file"][3])
		this.lock:pos(bgSize.width / 2, bgSize.height / 2):addTo(this.layer)
	end
	
	this:setState(this.state)	
	this.layer:setContentSize(bgSize)
	
	this.layer:setTouchEnabled(true)
	this.layer:registerScriptTouchHandler(function(event, x, y)
		if this.params["parent"] and not uihelper.nodeContainTouchPoint(this.params["parent"], ccp(x, y)) then
			return false
		end
			
		if event == "began" and uihelper.nodeContainTouchPoint(this.layer, ccp(x, y)) then
			if this.state ~= LOCK then
				if this.state == NORMAL then
					this:setState(CHOOSE)
				elseif this.state == CHOOSE then
					this:setState(NORMAL)
				end
				
				if this.params["callback"] then
					local result = this.params["callback"]()
					if result == false then
						this:setState(NORMAL)
					end
				end
			end
		end
		return false
	end, false, params.priority or -128, false)
	return this
end

function DGCheckBox:getLayer()
	return self.layer
end

function DGCheckBox:setState(state)
	if state == NORMAL then
		self.choose:setVisible(false)
		if self.lock then
			self.lock:setVisible(false)
		end
	elseif state == CHOOSE then
		self.choose:setVisible(true)	
		if self.lock then
			self.lock:setVisible(false)
		end
	else
		self.choose:setVisible(false)
		if self.lock then
			self.lock:setVisible(true)
		end
	end
	self.state = state
end

function DGCheckBox:check(bool)
	if bool then
		self:setState(CHOOSE)
	else
		self:setState(NORMAL)
	end
end

function DGCheckBox:show(bool)
	self.layer:setVisible(bool)
end

function DGCheckBox:isSelect()
	return self.state == CHOOSE
end

return DGCheckBox
