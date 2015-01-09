-- 武将图鉴界面
-- by yangkun
-- 2014.6.18
local HeroRes = "resource/ui_rc/hero/"
local HeroMapRes = "resource/ui_rc/hero/map/"
local GlobalRes = "resource/ui_rc/global/"

local DGBtn = require("uicontrol.DGBtn")
local DGMask = require("uicontrol.DGMask")
local DGRadioGroup = require("uicontrol.DGRadioGroup")

local HeroInfoLayer = import(".HeroInfoLayer")
local ItemSourceLayer = require("scenes.home.ItemSourceLayer")

local CAMP = {}
CAMP.QUN = 1
CAMP.WEI = 2
CAMP.SHU = 3
CAMP.WU = 4

local HeroMapLayer = class("HeroMapLayer", function(params) 
	return display.newLayer() 
end)

function HeroMapLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -129
	self:size(869, 554)
	self.size = self:getContentSize()

	self.curCamp = CAMP.QUN
	self.columns = 6
	self:prepareHeroMapAllData()
	self:reloadData()
end

function HeroMapLayer:reloadData()
	local heroAllRequest = {roleId = game.role.id}
	local bin = pb.encode("SimpleEvent", heroAllRequest)

	game:sendData(actionCodes.HeroAllRequest, bin, #bin)
	loadingShow()
	game:addEventListener(actionModules[actionCodes.HeroAllResponse], function(event)
		loadingHide()
		local pbData = pb.decode("HeroAllResponse",event.data)
		self.heroTypes = {}
		for _, heroType in ipairs(pbData.types) do
			self.heroTypes[heroType] = true
		end
		self:removeAllChildren()
		self.contentLayer = nil
		self:initTabLayer()
		self:initContentLayer(self.curCamp)

		return "__REMOVE__"
	end)
end

function HeroMapLayer:initTabLayer()
	local totalBg = display.newSprite(GlobalRes .. "label_bg.png")
	totalBg:anch(0,0):pos(20, self.size.height - 30):addTo(self)
	local xPos, yPos = 10, totalBg:getContentSize().height/2
	local text = ui.newTTFLabel({text = "拥有武将：", size = 20})
	text:anch(0, 0.5):pos(xPos, yPos):addTo(totalBg)
	xPos = xPos + text:getContentSize().width

	local heroNums = table.nums(self.heroTypes)
	text = ui.newTTFLabel({text = heroNums, size = 20, color = heroNums > 0 and uihelper.hex2rgb("#7ce810") or display.COLOR_RED })
	text:anch(0, 0.5):pos(xPos, yPos):addTo(totalBg)
	xPos = xPos + text:getContentSize().width

	ui.newTTFLabel({text = "/" .. self.allHeroNums, size = 20})
		:anch(0, 0.5):pos(xPos, yPos):addTo(totalBg)

	local tabData = {
		[1] = { showName = "text_qun.png", callback = function() self:initContentLayer(CAMP.QUN) end},
		[2] = { showName = "text_wei.png", callback = function() self:initContentLayer(CAMP.WEI) end},
		[3] = { showName = "text_shu.png", callback = function() self:initContentLayer(CAMP.SHU) end},
		[4] = { showName = "text_wu.png", callback = function() self:initContentLayer(CAMP.WU) end},
	}

	-- tab按钮
	local tableRadioGrp = DGRadioGroup:new()
	for i = 1, #tabData do
		local tabBtn = DGBtn:new(HeroRes, {"filter/long_normal.png", "filter/long_selected.png", "filter/long_disabled.png"},
			{	
				id = i,
				front = HeroMapRes .. tabData[i].showName,
				priority = self.priority - 4,
				callback = tabData[i].callback
			}, tableRadioGrp)
		tabBtn:getLayer():pos(340 + 120 * (i - 1), self:getContentSize().height - 34)
			:addTo(self)
	end
end

function HeroMapLayer:prepareHeroMapAllData()
	self.allHeros = {}
	self.allHeroNums = 0
	for _,hero in pairs(unitCsv.m_data) do
		if hero.heroOpen > 0 then
			self.allHeros[hero.camp] = self.allHeros[hero.camp] or {}
			self.allHeros[hero.camp][hero.stars] = self.allHeros[hero.camp][hero.stars] or {}

			table.insert(self.allHeros[hero.camp][hero.stars], hero)
			self.allHeroNums = self.allHeroNums + 1
		end
	end
end

function HeroMapLayer:initContentLayer(camp)
	local curCamp = self.curCamp 
	self.curCamp = camp
	self.curHeroArray = self.allHeros[self.curCamp]

	if not self.contentLayer then
		self.contentLayer = display.newLayer()
		self.contentLayer:size(self:getContentSize().width,self:getContentSize().height - 60)
		self.contentLayer:addTo(self)

		self.tableLayer = display.newLayer()
		self.tableLayer:size(922, 480):pos(0, self.contentLayer:getContentSize().height - 489):addTo(self.contentLayer)

		self.tableView = self:createMapTable()
		self.tableView:setPosition(0,0)
		self.tableLayer:addChild(self.tableView)
	else
		self.tableView:reloadData()
	end

	if curCamp == camp and self.offset then
		self.tableView:setBounceable(false)
		self.tableView:setContentOffset(self.offset, false)
		self.tableView:setBounceable(true)
	end
end

function HeroMapLayer:createMapTable()
	local handler = LuaEventHandler:create(function(fn, table, a1, a2)
        local r
        if fn == "cellSize" then
        	local height = 52
        	local heroNum = self.curHeroArray[a1+1] and #self.curHeroArray[a1+1] or 0
        	height = height + (math.floor((heroNum-1)/self.columns) + 1) * 147

            r = CCSizeMake(922, height)
        elseif fn == "cellAtIndex" then
			if not a2 then
                a2 = CCTableViewCell:new()
                local cell = display.newNode()
                a2:addChild(cell, 0, 1)
            end

            local cell = tolua.cast(a2:getChildByTag(1), "CCNode")
            cell:removeAllChildren()

            local index = a1
            self:createMapCell(cell, index)
            r = a2
        elseif fn == "numberOfCells" then
            r = 5
        end

        return r
    end)
	local tableView = LuaTableView:createWithHandler(handler, self.tableLayer:getContentSize())
    tableView:setBounceable(true)
    tableView:setTouchPriority(self.priority - 3)
	return tableView
end

function HeroMapLayer:createMapCell(cellNode, index)
	local stars = index + 1
	local heros = self.curHeroArray[stars]
	local heroNum = heros and #heros or 0
	if heroNum <= 0 then return end
	local height = 52
	local row = (math.floor((heroNum-1)/self.columns) + 1)
    height = height + row * 147

    local cellSize = CCSizeMake(self.size.width, height)

    -- 星级
	local starBg = display.newSprite(HeroMapRes .. "long_bar.png")
	starBg:anch(0.5, 1):pos(self:getContentSize().width / 2, cellSize.height - 5):addTo(cellNode)

	local startX = 4
	local interval = 42
	for i = 1, stars do
		local starSprite = display.newSprite( GlobalRes .. "star/icon_big.png")
		starSprite:anch(0, 0.5):pos(startX + (i-1)*interval, starBg:getContentSize().height/2):addTo(starBg)
	end

	--拥有武将
	local hasHeros = ui.newTTFLabel({text = "拥有武将：", size = 20})
	hasHeros:anch(0, 0.5):addTo(starBg)
	local width = hasHeros:getContentSize().width
	local curNum = self:getMyHeroNumber(self.curCamp, stars)
	local text = ui.newTTFLabel({text = curNum, size = 20, color = curNum > 0 and uihelper.hex2rgb("#7ce810") or display.COLOR_RED})
	text:anch(0, 0):pos(width, 0):addTo(hasHeros)
	width = width + text:getContentSize().width
	text = ui.newTTFLabel({text = "/" .. heroNum, size = 20})
	text:anch(0, 0):pos(width, 0):addTo(hasHeros)
	width = width + text:getContentSize().width
	hasHeros:pos(starBg:getContentSize().width - width - 20, starBg:getContentSize().height/2)

	-- 英雄头像
	local startY = cellSize.height - starBg:getContentSize().height - 8
	for index = 1, row do
		local cellLayer = display.newLayer()
		cellLayer:setContentSize(CCSizeMake(cellNode:getContentSize().width, 147 ))
		cellLayer:anch(0,1):pos( 0, startY - (index - 1) * 147 ):addTo(cellNode)

		startX = 20
		interval = (cellSize.width - startX * 2 - 106 * self.columns) / (self.columns - 1)
		local last = index * self.columns > heroNum and heroNum or index * self.columns
		for j = (index-1)*self.columns +1, last do
			local headNode = self:createHeroHeadNode(heros[j])

			local column = (j-1) % self.columns + 1
			headNode:anch(0,0):pos(startX + (column-1)*(interval + 106), 0):addTo(cellLayer)
		end
	end

end

function HeroMapLayer:createHeroHeadNode(heroData)
	local node = display.newNode()
	node:size(107, 135)

	local btn = HeroHead.new({
			type = heroData.type,
			parent = self.tableLayer,
			scale = 1.1,
			priority = self.priority - 2,
			callback = function ()
				if self.heroTypes[heroData.type] then
					local layer = HeroInfoLayer.new({heroType = heroData.type, priority = self.priority - 10,})
					layer:getLayer():addTo(display.getRunningScene())
				else
					local sourceLayer = ItemSourceLayer.new({ 
						priority = self.priority - 10, 
						itemId = heroData.type + 2000,
						closeCallback = function()
							self.offset = self.tableView:getContentOffset()
							self:reloadData()
						end,
					})
					sourceLayer:getLayer():addTo(display.getRunningScene())
				end
			end
		})
	btn:getLayer():anch(0.5, 1):pos(node:getContentSize().width/2, node:getContentSize().height):addTo(node)

	-- 头像
	local headImage = display.newSprite( heroData.headImage ):pos(btn:getLayer():getContentSize().width/2, btn:getLayer():getContentSize().height/2)
	:addTo(btn:getLayer(), -1)

	if not self:isMyHero(heroData) then
		headImage:setColor(ccc3(128,128,128))
		btn.item[1]:setColor(ccc3(128,128,128))
	end
	-- 名字
	local nameLabel = ui.newTTFLabel({text = heroData.name, size = 22, font = ChineseFont, color = display.COLOR_WHITE })
	nameLabel:anch(0.5,0):pos(node:getContentSize().width/2, 0):addTo(node)
	return node
end

function HeroMapLayer:isMyHero(heroData)
	return self.heroTypes[heroData.type]
end

function HeroMapLayer:getMyHeroNumber(camp, stars)
	local ret = 0
	for heroType, _ in pairs(self.heroTypes) do
		local unitData = unitCsv:getUnitByType(heroType)
		if unitData.camp == camp and unitData.stars == stars then
			ret = ret + 1
		end
	end
	return ret
end

function HeroMapLayer:onExit()
	game:removeAllEventListenersForEvent(actionModules[actionCodes.HeroAllResponse])
end

function HeroMapLayer:onCleanup()
	display.removeUnusedSpriteFrames()
end

return HeroMapLayer