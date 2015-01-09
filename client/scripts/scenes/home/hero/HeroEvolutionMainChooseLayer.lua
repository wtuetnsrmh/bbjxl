-- 武将进化主将选择界面
-- by yangkun
-- 2014.6.20

local HeroRes = "resource/ui_rc/hero/"
local GlobalRes = "resource/ui_rc/global/"
local HeroSellRes = "resource/ui_rc/hero/sell/"

local FilterLogic = import(".FilterLogic")
local FilterBar = import(".FilterBar")

local HeroEvolutionMainChooseLayer = class("HeroEvolutionMainChooseLayer", function(params)
	return display.newLayer(GlobalRes .. "bottom_bg.png") 
end)

function HeroEvolutionMainChooseLayer:ctor(params)

	params = params or {}

	self.priority = params.priority or -129

	self.mainHeroId = params.mainHeroId
	self.parent = params.parent

	self.heros = {}

	self:initUI()
end

function HeroEvolutionMainChooseLayer:onEnter()
	self:initContentLayer()
end

function HeroEvolutionMainChooseLayer:getLayer()
	return self.mask:getLayer()
end

function HeroEvolutionMainChooseLayer:initUI()
	local innerBg = display.newSprite(GlobalRes .. "inner_bg.png")
	innerBg:anch(0.5,0.5):pos(self:getContentSize().width/2, self:getContentSize().height/2):addTo(self)
	
	-- 遮罩层
	self:anch(0, 0):pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1, opacity = 0 })

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
				self:getLayer():removeSelf()
			end,
		}):getLayer()
	closeBtn:anch(1, 1):pos((display.width + 960) / 2, display.height):addTo(self:getLayer())

	local tabLabel = display.newSprite(GlobalRes .. "tab_selected.png")
	tabLabel:anch(0, 0.5):pos(self:getContentSize().width - 14, 470):addTo(self)
	local btnSize = tabLabel:getContentSize()

	display.newSprite(GlobalRes.."tab_arrow.png"):anch(1,0.5):pos(10, btnSize.height/2)
		:addTo(tabLabel)

	ui.newTTFLabelWithStroke({ text = "进化", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(tabLabel)
end

function HeroEvolutionMainChooseLayer:initContentLayer()
	self:filterHeros()

	self.contentLayer = display.newLayer()
	self.contentLayer:size(self:getContentSize()):addTo(self)
	local contentSize = self.contentLayer:getContentSize()

	-- 次顶栏
	self.heroFilter = FilterLogic.new({ heros = self.heros })
	self.heroFilter:addEventListener("filter", function(event) self.heroTableView:reloadData() end)
	local infoBg = display.newSprite(GlobalRes .. "label_bg.png"):anch(0,0)
	infoBg:anch(0, 0.5):pos(30, self:getContentSize().height - 33):addTo(self.contentLayer, 100)

	local yy = infoBg:getContentSize().height/2
	local word = display.newSprite(HeroRes .. "map/title.png"):anch(0,0.5)
	:pos(10,yy)
	:addTo(infoBg)

	local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)  
	local vipInfo  = vipCsv:getDataByLevel(game.role.vipLevel)

	--斜线：
	local line = ui.newTTFLabel({text = "/",size = 20 ,color = ccc3(212, 217, 214)})
	:anch(0.5,0.5)
	:pos(infoBg:getContentSize().width * 0.75, yy)
	:addTo(infoBg)
	--分子：
	ui.newTTFLabel({text = string.format("%d",table.nums(self.heros)),size = 20,color = ccc3(39, 228, 14) })
	:anch(1,0.5)
	:pos(line:getPositionX() - 5,yy)
	:addTo(infoBg)
	--分母：
	local bagHeroLimit = ui.newTTFLabel({text = game.role:getBagHeroLimit(), size = 20 ,color = ccc3(233, 180, 16) })
	bagHeroLimit:anch(0,0.5):pos(line:getPositionX() + 5,yy):addTo(infoBg)

	local filterBar = FilterBar.new({ dataSource = self.heroFilter, priority = self.priority - 10})
	filterBar:anch(0, 1):pos(340, self:getContentSize().height - 16):addTo(self, 100)

	local columns = 2
	local cellSize = CCSizeMake(415, 132)
	local function createCellNode(parentNode, cellIndex)
		parentNode:removeAllChildren()
		parentNode:setContentSize(CCSizeMake(contentSize.width, cellSize.height + 10))

		local xBegin = 25
		local xInterval = (contentSize.width - 2 * xBegin - columns * cellSize.width) / (columns - 1)
		local rows = math.ceil( #self.heroFilter:getResult() / columns )
		for index = (rows - cellIndex - 1) * columns + 1, columns * (rows - cellIndex) do
			local hero = self.heroFilter:getResult()[index]
			local nativeIndex = index - (rows - cellIndex - 1) * columns
			local cellNode = display.newNode()
			cellNode:size(cellSize)

			local unitData = unitCsv:getUnitByType(hero and hero.type or 0)
			if unitData then
				local heroBtn = HeroListCell.new(
					{	
						priority = self.priority - 1,
						type = hero.type,
						level = hero.level,
						wakeLevel = hero.wakeLevel,
						star = hero.star,
						evolutionCount = hero.evolutionCount,
						callback = function()
							self.parent.mainHeroId = hero.id
							self.parent:reloadHeroData()
							self.parent.fodderHeroIds = {}
							self.parent:initContentLeft()
							self.parent:initContentRight()

							self:getLayer():removeSelf()
						end,
					})
				heroBtn:getLayer():addTo(cellNode)

				-- if hero.choose == 1 then
				-- 	display.newSprite(HeroRes .. "choose_tag.png"):anch(1, 1):pos(cellSize.width - 10, cellSize.height)
				-- 		:addTo(cellNode, 10)
				-- end

				-- 选择
				local blueBtn = DGBtn:new( GlobalRes, {"middle_normal.png", "middle_selected.png"}, {
						callback = function ()
							self.parent.mainHeroId = hero.id
							self.parent:reloadHeroData()
							self.parent.fodderHeroIds = {}
							self.parent:initContentLeft()
							self.parent:initContentRight()

							self:getLayer():removeSelf()
						end,
						priority = self.priority -2,
						text = { text = "选择", size = 26, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2}
					})
				blueBtn:getLayer():anch(0.5,0.5):pos(cellSize.width - 100, cellSize.height / 2 - 15):addTo(cellNode)
			end

			cellNode:anch(0, 0):pos(xBegin + (cellSize.width + xInterval) * (nativeIndex - 1), 0)
				:addTo(parentNode)
		end
	end

	local viewHandler = LuaEventHandler:create(function(fn, table, a1, a2)
		local result
		if fn == "cellSize" then
			result = CCSizeMake(contentSize.width, cellSize.height + 10)

		elseif fn == "cellAtIndex" then
			if not a2 then
				a2 = CCTableViewCell:new()
				local cell = display.newNode()
				a2:addChild(cell, 0, 1)
			end

			-- 更新cell
			local cell = tolua.cast(a2:getChildByTag(1), "CCNode")
			createCellNode(cell, a1)
			result = a2

		elseif fn == "numberOfCells" then
			result = math.ceil( #self.heroFilter:getResult() / columns )
		end

		return result
	end)

	local tableSize = CCSizeMake(contentSize.width, contentSize.height - filterBar:getContentSize().height - 40)
	self.heroTableView = LuaTableView:createWithHandler(viewHandler, tableSize)
	self.heroTableView:setBounceable(true)
	self.heroTableView:setTouchPriority(self.priority -2)
	self.heroTableView:setPosition(0, 20)

	self.contentLayer:addChild(self.heroTableView)

end

function HeroEvolutionMainChooseLayer:filterHeros()
	for id, hero in pairs(game.role.heros) do
		-- 非素材卡
		if not (hero.type >= 991 and hero.type <= 999) then
			table.insert(self.heros, hero)
		end
	end
	table.sort(self.heros, function(a, b) 
		local unitDataA = unitCsv:getUnitByType(a.type)
		local unitDataB = unitCsv:getUnitByType(b.type)
		local factorA = a.choose * 1000000 + (a.master > 0 and 1 or 0) * 100000 + a.star * 10000 + a.evolutionCount * 1000 + a.level
		local factorB = b.choose * 1000000 + (b.master > 0 and 1 or 0) * 100000 + b.star * 10000 + b.evolutionCount * 1000 + b.level
		return factorA == factorB and (a.type < b.type) or (factorA > factorB)
	end)
end

function HeroEvolutionMainChooseLayer:onCleanup()
	-- display.removeUnusedSpriteFrames()
end

return HeroEvolutionMainChooseLayer