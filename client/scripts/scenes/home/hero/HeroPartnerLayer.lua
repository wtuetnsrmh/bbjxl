local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"
local HeroChooseRes = "resource/ui_rc/hero/choose/"
local HeroRelationLayer = import(".HeroRelationLayer")
local HeroPartnerChooseLayer = import(".HeroPartnerChooseLayer")

local HeroPartnerLayer = class("HeroPartnerLayer", function(params) 
	return display.newLayer(HeroChooseRes .. "partner_popup.png") 
end)

function HeroPartnerLayer:ctor(params)

	params = params or {}

	self.heros = params.heros or game.role.heros
	self.partners = params.partners
	self.level = params.level or game.role.level
	self.slots = params.slots or game.role.slots
	self.priority = params.priority or -129
	self.size = self:getContentSize()
	self:anch(0.5,0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority, ObjSize = self.size, clickOut = function()
		if params.closeCallback then
			params.closeCallback()
		end 
		self.mask:remove() 
	end})

	self.xBegin, self.xInterval = 187, 114
	self:initUI()
end

function HeroPartnerLayer:initUI()
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end
	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.size):addTo(self)
	self:initChoosedHeros()
	self:initPartnerHeros()
end

function HeroPartnerLayer:initChoosedHeros()
	-- title
	local bg = display.newSprite(HeroChooseRes .. "partner_item_bg.png")
	bg:anch(0.5, 1):pos(self.size.width/2, self.size.height - 22):addTo(self.mainLayer)
	ui.newTTFLabel({text = "战斗阵容", size = 24, color = uihelper.hex2rgb("#d8f8ff"), font = ChineseFont})
		:anch(0.5, 0.5):pos(bg:getContentSize().width/2, bg:getContentSize().height/2):addTo(bg)

	--武将
	local count = 1
	for index = 1, 5 do
		local hero = self.heros[checkTable(self.slots, tostring(index)).heroId]
		if hero then
			local xPos, yPos = self.xBegin + (count - 1) * self.xInterval, 262
			local heroBtn = HeroHead.new( 
				{
					type = hero.type,
					wakeLevel = hero.wakeLevel,
					star = hero.star,
					evolutionCount = hero.evolutionCount,
					heroLevel = hero.level,
					hideStars = true,
					priority = self.priority - 1,
					callback = function()
						HeroRelationLayer.new({hero = hero, priority = self.priority - 100})
					end,
					group = self.headRadios
				})
			heroBtn:getLayer():anch(0.5, 0):pos(xPos, yPos):addTo(self.mainLayer)
				
			ui.newTTFLabel({text = string.format("情缘x%d", hero.relation and #hero.relation or 0), size = 20, color = uihelper.hex2rgb("#e9e8af"), font = ChineseFont})
				:anch(0.5, 1):pos(xPos, yPos):addTo(self.mainLayer)


			count = count + 1
		end
	end
end

function HeroPartnerLayer:initPartnerHeros()
	local showOtherFlag = self.partners and true or false
	-- title
	local bg = display.newSprite(HeroChooseRes .. "partner_item_bg.png")
	bg:anch(0.5, 0):pos(self.size.width/2, 186):addTo(self.mainLayer)
	ui.newTTFLabel({text = "小伙伴阵容", size = 24, color = uihelper.hex2rgb("#d8f8ff"), font = ChineseFont})
		:anch(0.5, 0.5):pos(bg:getContentSize().width/2, bg:getContentSize().height/2):addTo(bg)

	local roleInfo = roleInfoCsv:getDataByLevel(self.level)
	--武将
	for index = 1, 5 do
		local hero = self.partners and self.partners[index] or self.heros[game.role.partners[index]]
		local xPos, yPos = self.xBegin + (index - 1) * self.xInterval, 42
		if hero then
			
			local heroBtn = HeroHead.new( 
				{
					type = hero.type,
					wakeLevel = hero.wakeLevel or 1,
					star = hero.star,
					evolutionCount = hero.evolutionCount,
					heroLevel = hero.level,
					hideStars = true,
					priority = self.priority - 1,
					callback = function()
						if not showOtherFlag then
							local layer = HeroPartnerChooseLayer.new({priority = self.priority - 10, closeCallback = function() self:initUI() end, index = index})
							layer:getLayer():addTo(display.getRunningScene())
						end
					end,
					group = self.headRadios
				})
			heroBtn:getLayer():anch(0.5, 0):pos(xPos, yPos):addTo(self.mainLayer)
		elseif index <= roleInfo.partnerHeroNum then
			local btn = DGBtn:new(GlobalRes, {"frame_empty.png"},
				{
					front = HeroRes .. "choose/add.png",
					priority = self.priority - 1,
					callback = function() 
						if not showOtherFlag then
							local layer = HeroPartnerChooseLayer.new({priority = self.priority - 10, closeCallback = function() self:initUI() end, index = index})
							layer:getLayer():addTo(display.getRunningScene())
						end
					end,
				}):getLayer()
			local btnSize = btn:getContentSize()
			btn:anch(0.5, 0):pos(xPos, yPos):addTo(self.mainLayer)
			display.newSprite(GlobalRes .. "frame_bottom.png"):addTo(btn, -1)
				:pos(btnSize.width / 2, btnSize.height / 2)
		else
			local openLevel = roleInfoCsv:getLevelByPartnerChooseNum(index)

			local cell = display.newSprite(GlobalRes .. "frame_empty.png")
			local btnSize = cell:getContentSize()
			display.newSprite(HeroRes .. "choose/lock.png"):pos(btnSize.width/2, btnSize.height/2)
				:addTo(cell)	

			ui.newTTFLabelWithStroke({ text = openLevel .. "级开启", size = 20, font = ChineseFont, color = uihelper.hex2rgb("#fff1e0"), strokeColor = display.COLOR_BROWNSTROKE, strokeSize =2 })
				:anch(0.5, 0):pos(btnSize.width / 2, 15):addTo(cell)

			cell:anch(0.5, 0):pos(xPos, yPos):addTo(self.mainLayer)
			display.newSprite(GlobalRes .. "frame_bottom.png"):addTo(cell, -1)
				:pos(btnSize.width / 2, btnSize.height / 2)

		end
	end
end

function HeroPartnerLayer:getLayer()
	return self.mask:getLayer()
end


return HeroPartnerLayer