local HeroRes = "resource/ui_rc/hero/"

local professionName = { [1] = "bu", [3] = "qi", [4] = "gong", [5] = "jun" }
local campName = { [1] = "qun", [2] = "wei", [3] = "shu", [4] = "wu" }


local FilterBar = class("FilterBar", function(params)
	return display.newLayer()
end)

function FilterBar:ctor(params)
	params = params or {}

	self.priority = params.priority or -130
	self.dataSource = params.dataSource

	self.size = CCSizeMake(510, 33)
	self:setContentSize(self.size)
	self.iconListTag = 99
	self.filterTag = 125

	local xPos, interval = 0, 20
	self.professionBtn = DGBtn:new(HeroRes, {"filter/long_normal.png", "filter/long_selected.png", "filter/long_disabled.png"},
		{	
			touchScale = {1, 1.5},
			selectable = true,
			front = HeroRes .. "filter/text_profession.png",
			priority = self.priority,
			callback = function()
				if self.professionBtn:isSelect() then
					self:removeList()
				else
					self:professionFilter()

					self.campBtn:select(false)
					self.starBtn:select(false)
				end
			end,
		})
	self.professionBtn:getLayer():pos(xPos, 0):addTo(self)
	xPos = xPos + self.professionBtn:getLayer():getContentSize().width + interval

	self.campBtn = DGBtn:new(HeroRes, {"filter/long_normal.png", "filter/long_selected.png", "filter/long_disabled.png"},
		{	
			touchScale = {1, 1.5},
			selectable = true,
			front = HeroRes .. "filter/text_camp.png",
			priority = self.priority,
			callback = function()
				if self.campBtn:isSelect() then
					self:removeList()
				else
					self:campFilter()
					self.professionBtn:select(false)
					self.starBtn:select(false)
				end
			end,
		})
	self.campBtn:getLayer():pos(xPos, 0):addTo(self)
	xPos = xPos + self.campBtn:getLayer():getContentSize().width + interval

	self.starBtn = DGBtn:new(HeroRes, {"filter/long_normal.png", "filter/long_selected.png", "filter/long_disabled.png"},
		{	
			touchScale = {1, 1.5},
			selectable = true,
			front = HeroRes .. "filter/text_star.png",
			priority = self.priority,
			callback = function()
				if self.starBtn:isSelect() then
					self:removeList()
				else
					self:starFilter()
					self.professionBtn:select(false)
					self.campBtn:select(false)
				end
			end,
		})
	self.starBtn:getLayer():pos(xPos, 0):addTo(self)
	xPos = xPos + self.starBtn:getLayer():getContentSize().width + interval

	local allBtn = DGBtn:new(HeroRes, {"filter/long_normal.png", "filter/long_selected.png", "filter/long_disabled.png"},
		{	
			front = HeroRes .. "filter/text_all.png",
			priority = self.priority,
			callback = function()
				self:removeList()
				self.dataSource:showAll()
				self.professionBtn:getLayer():removeChildByTag(self.filterTag)
				self.campBtn:getLayer():removeChildByTag(self.filterTag)
				self.starBtn:getLayer():removeChildByTag(self.filterTag)

				self.professionBtn:select(false)
				self.campBtn:select(false)
				self.starBtn:select(false)
			end,
		})
	allBtn:getLayer():pos(xPos, 0):addTo(self)
end

function FilterBar:removeList()
	local layer = self:getChildByTag(self.iconListTag)
	print(layer)
	local node = layer and layer:getChildByTag(1)
	if node then
		node:runAction(transition.sequence{
			CCMoveBy:create(0.2, ccp(0, layer:getContentSize().height)),
			CCCallFunc:create(function() layer:removeSelf() end)
		})
	end
end

function FilterBar:professionFilter()
	self:removeChildByTag(self.iconListTag)

	local iconSize = CCSizeMake(87, 87)

	
	local layer = CCNodeExtend.extend(CCClippingLayer:create())
	
	local professionContainer = display.newScale9Sprite(HeroRes .. "filter/select_bg.png", nil, nil, CCSizeMake(95, 368))
	local layerSize = professionContainer:getContentSize()

	layer:setContentSize(layerSize)	

	local clickable = false
	
	local professionIds = { 5, 4, 3, 1}
	local interval = layerSize.height / 4
	for index, profession in ipairs(professionIds) do
		local res = HeroRes .. string.format("card/pro_%s.png", professionName[profession])
		local btn = DGBtn:new(HeroRes, {},
			{	
				priority = self.priority,
				callback = function()
					if not clickable then return end
					self.professionBtn:getLayer():removeChildByTag(self.filterTag)
					display.newSprite(res):scale(0.3):anch(1, 0)
						:pos(self.professionBtn:getLayer():getContentSize().width-5, 5)
						:addTo(self.professionBtn:getLayer(), 1, self.filterTag)
					
					self.professionBtn:select(false)
					self.dataSource:filterByProfession({ profession = profession })
					layer:removeSelf()
				end,
			})
		if index ~= 4 then
			display.newSprite(HeroRes .. "filter/splitter.png")
			:anch(0.5, 0):pos(layerSize.width / 2, index * interval):addTo(professionContainer)
		end
		local xPos, yPos = layerSize.width / 2, interval/2 + (index-1)*interval
		display.newSprite(res):scale(0.75):anch(0.5, 0.5):pos(xPos, yPos):addTo(professionContainer) 
		btn:getLayer():size(layerSize.width, interval):anch(0.5, 0.5):pos(xPos, yPos):addTo(professionContainer)
	end

	professionContainer:anch(0, 0):pos(0, layerSize.height):addTo(layer, 0, 1)
	professionContainer:runAction(transition.sequence({
		CCMoveBy:create(0.2, ccp(0, -layer:getContentSize().height)),
		CCCallFunc:create(function() clickable = true end)
	}))

	layer:anch(0.5, 1):pos(self.professionBtn:getX() + self.professionBtn:getWidth() / 2, 0)
		:addTo(self, 0, self.iconListTag)
end

function FilterBar:campFilter()
	self:removeChildByTag(self.iconListTag)

	local iconSize = CCSizeMake(80, 80)

	local layer = CCNodeExtend.extend(CCClippingLayer:create())
	local campContainer = display.newScale9Sprite(HeroRes .. "filter/select_bg.png", nil, nil, CCSizeMake(95, 368))
	local layerSize = campContainer:getContentSize()

	layer:setContentSize(layerSize)	


	local clickable = false
	local campIds = { 4, 3, 2, 1 }
	local interval = layerSize.height / 4
	for index, camp in ipairs(campIds) do
		local res = HeroRes .. string.format("filter/camp_%s.png", campName[camp])
		local btn = DGBtn:new(HeroRes, {},
			{	
				priority = self.priority-10,
				callback = function()
					if not clickable then return end
					self.campBtn:getLayer():removeChildByTag(self.filterTag)
					display.newSprite(res):scale(0.5):anch(1, 0)
						:pos(self.campBtn:getLayer():getContentSize().width-5, 5)
						:addTo(self.campBtn:getLayer(), 1, self.filterTag)

					self.campBtn:select(false)
					self.dataSource:filterByCamp({ camp = camp })
					layer:removeSelf()
				end,
			})
		if index ~= 4 then
			display.newSprite(HeroRes .. "filter/splitter.png")
			:anch(0.5, 0):pos(layerSize.width / 2, index * interval):addTo(campContainer)
		end
		local xPos, yPos = layerSize.width / 2, interval/2 + (index-1)*interval
		display.newSprite(res):anch(0.5, 0.5):pos(xPos, yPos):addTo(campContainer) 
		btn:getLayer():size(layerSize.width, interval):anch(0.5, 0.5):pos(xPos, yPos):addTo(campContainer)
	end

	campContainer:anch(0, 0):pos(0, layer:getContentSize().height):addTo(layer, 0, 1)
	campContainer:runAction(transition.sequence({
		CCMoveBy:create(0.2, ccp(0, -layer:getContentSize().height)),
		CCCallFunc:create(function() clickable = true end)
	}))

	layer:anch(0.5, 1):pos(self.campBtn:getX() + self.campBtn:getWidth() / 2, 0)
		:addTo(self, 0, self.iconListTag)
end

function FilterBar:starFilter()
	self:removeChildByTag(self.iconListTag)

	local iconSize = CCSizeMake(80, 80)

	local layer = CCNodeExtend.extend(CCClippingLayer:create())
	local starContainer = display.newScale9Sprite(HeroRes .. "filter/select_bg.png", nil, nil, CCSizeMake(95, 458))
	local layerSize = starContainer:getContentSize()

	layer:setContentSize(layerSize)	

	local clickable = false
	local starNums = { 5, 4, 3, 2, 1}
	local interval = layerSize.height / 5
	for index, starNum in ipairs(starNums) do
		local res = GlobalRes .. "star/icon_small.png"
		local btn = DGBtn:new(HeroRes, {},
			{	
				priority = self.priority-10,
				callback = function()
					if not clickable then return end
					self.starBtn:getLayer():removeChildByTag(self.filterTag)
					local btnSize = self.starBtn:getLayer():getContentSize()
					local text = ui.newTTFLabel({text = starNums[index], size = 18, font = ChineseFont})
					text:anch(1, 0):pos(btnSize.width-21, 8):addTo(self.starBtn:getLayer(), 1, self.filterTag)
					display.newSprite(res):scale(0.7):anch(0, 0)
						:pos(text:getContentSize().width, 3)
						:addTo(text)

					self.starBtn:select(false)
					self.dataSource:filterByStar({ star = starNum })
					layer:removeSelf()
				end,
			})
		if index ~= 5 then
			display.newSprite(HeroRes .. "filter/splitter.png")
			:anch(0.5, 0):pos(layerSize.width / 2, index * interval):addTo(starContainer)
		end
		local xPos, yPos = layerSize.width / 2, interval/2 + (index-1)*interval
		ui.newTTFLabel({text = starNums[index], size = 38, font = ChineseFont}):anch(1, 0.5):pos(xPos, yPos):addTo(starContainer)
		display.newSprite(res):anch(0, 0.65):pos(xPos, yPos):addTo(starContainer) 
		btn:getLayer():size(layerSize.width, interval):anch(0.5, 0.5):pos(xPos, yPos)
			:addTo(starContainer)
	end

	starContainer:anch(0, 0):pos(0, layer:getContentSize().height):addTo(layer, 0, 1)
	starContainer:runAction(transition.sequence({
		CCMoveBy:create(0.2, ccp(0, -layer:getContentSize().height)),
		CCCallFunc:create(function() clickable = true end)
	}))

	layer:anch(0.5, 1):pos(self.starBtn:getX() + self.starBtn:getWidth() / 2, 0)
		:addTo(self, 0, self.iconListTag)
end

return FilterBar

