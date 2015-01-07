DGRadioGroup = {
	curBtn,   --记录选中的按钮
	items,
	cursor,    --当前选中的游标
	offset   --游标偏移
}
	
function DGRadioGroup:new(layer,cursor,offset)
	local this = {}
	setmetatable(this,self)
	self.__index = self
	this.items = {}
	
	if layer and cursor then
		this.cursor = display.newSprite(cursor)
		this.cursor:anch(0, 0):pos(0, 0):hide(true):addTo(layer, -1)
		this.offset = offset or 0
	end
	
	return this	
end

function DGRadioGroup:chooseBtn(btn,noani,callback)
	if self.curBtn then
		self.curBtn:select(false)
	end
	self.curBtn = btn
	btn:select(true,callback)
	if self.cursor then
		self.cursor:setVisible(true)
		local x = btn:getRange():getMinX() - (self.cursor:getContentSize().width -  btn:getWidth()) /2 + self.offset
		local y = btn:getRange():getMinY() - (self.cursor:getContentSize().height - btn:getHeight()) / 2
		
		if noani then
			self.cursor:anch(0, 0):pos(x, y)
		else
			self.cursor:runAction(CCMoveTo:create(0.2,ccp(x,y)))		
		end
	end
end

function DGRadioGroup:cancelChoose()
	if self.curBtn then
		self.curBtn:select(false)
		self.curBtn = nil
	end
end

function DGRadioGroup:getChooseBtn()
	return self.curBtn
end

function DGRadioGroup:getId()
	return self.curBtn:getId()
end

function DGRadioGroup:addItem(btn)
	table.insert(self.items, btn)
end

function DGRadioGroup:chooseByIndex(index, callback, ani)
	self:chooseBtn(self.items[index], ani, callback)
end

function DGRadioGroup:chooseById(id, callback)
	for k,v in pairs(self.items) do
		if v:getId() == id then
			self:chooseBtn(v, nil, callback)
			break
		end
	end
end
return DGRadioGroup