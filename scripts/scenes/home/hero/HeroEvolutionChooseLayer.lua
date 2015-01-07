-- 武将选择界面(进化)
-- by yangkun
-- 2014.6.20

local HeroRes = "resource/ui_rc/hero/"
local GlobalRes = "resource/ui_rc/global/"
local HeroSellRes = "resource/ui_rc/hero/sell/"

local FilterLogic = import(".FilterLogic")
local FilterBar = import(".FilterBar")

local HeroEvolutionChooseLayer = class("HeroEvolutionChooseLayer", function()
	return display.newLayer(GlobalRes .. "bottom_bg.png")
end)

function HeroEvolutionChooseLayer:ctor(params)
	params = params or {}

	self.mainHeroId = params.mainHeroId
	self.fodderHeroIds = params.fodderHeroIds or {}
	self.parent = params.parent

	self.priority = params.priority or -130
	self.bgSize = self:getContentSize()

	self.chooseHeroIds = self:initChooseHeroIds()
	self.heros = self:filterHerosByAction()

	local innerBg = display.newSprite(GlobalRes .. "inner_bg.png")
	innerBg:anch(0.5,0.5):pos(self:getContentSize().width/2, self:getContentSize().height/2):addTo(self)

	local upBg = display.newSprite(HeroSellRes .. "up.png")
	upBg:anch(0.5, 0):pos(self:getContentSize().width/2, 130):addTo(self)

	self.heroFilter = FilterLogic.new({ heros = self.heros })
	self.heroFilter:addEventListener("filter", function(event) self.heroListView:reloadData() end)

	local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
	local numberBg = display.newSprite(HeroRes .. "total_bg.png")
	numberBg:anch(0, 1):pos(44, self:getContentSize().height - 20):addTo(self)
	ui.newTTFLabelWithStroke({ text = "拥有武将: "..table.nums(self.heros) .. " / " .. roleInfo.bagHeroLimit, size = 24, color = display.COLOR_YELLOW })
		:anch(0, 0.5):pos(5, numberBg:getContentSize().height / 2):addTo(numberBg)

	local filterBar = FilterBar.new({ dataSource = self.heroFilter, priority = self.priority - 10})
	filterBar:anch(0, 1):pos(340, self:getContentSize().height - 16):addTo(self, 100)

	local resultLayer, resultSize = self:showResultLayer()
	resultLayer:anch(0.5, 0):pos(self.bgSize.width / 2, 15):addTo(self)

	self.cellSize = CCSizeMake(448, 152)
	self.tableSize = CCSizeMake(866, 392)
	self:createHeroView()

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

	self.tabCursor = display.newSprite(GlobalRes .. "tab_arrow.png")
	self.tabCursor:anch(1, 0.5):pos(self:getContentSize().width, 470):addTo(self, 100)

	local evolutionTab = display.newSprite(GlobalRes .. "tab_selected.png"):anch(0, 0.5)
	evolutionTab:pos(self.bgSize.width - 5, 470):addTo(self)
	display.newSprite(HeroRes .. "hero_label.png")
		:pos(evolutionTab:getContentSize().width / 2 - 5, evolutionTab:getContentSize().height / 2):addTo(evolutionTab)

	self.guideStep = params.guideStep or 1
	self:checkGuide()
end

function HeroEvolutionChooseLayer:initChooseHeroIds()
	local ret = {}
	for _, heroId in ipairs(self.fodderHeroIds) do
		ret[heroId] = true
	end
	return ret
end

-- 玩家可以进化的武将
-- @return 可以出售的武将
function HeroEvolutionChooseLayer:filterHerosByAction()
	local result = {}
	local mainHeroUnitData = unitCsv:getUnitByType(game.role.heros[self.mainHeroId].type)
	for heroId, hero in pairs(game.role.heros) do
		local heroUnitData = unitCsv:getUnitByType(hero.type)
		if hero.choose == 0 and hero.master == 0 and self.mainHeroId ~= heroId 
			and mainHeroUnitData.stars == heroUnitData.stars 
			and (hero.type <= 990 or hero.type >= 1000) then
			table.insert(result, hero)
		end
	end
	table.sort(result, 
		function(a,b) 
			if self.chooseHeroIds[a.id] and not self.chooseHeroIds[b.id] then 
				return true  
			elseif not self.chooseHeroIds[a.id] and self.chooseHeroIds[b.id] then
				return false 
			else
				if a.evolutionCount < b.evolutionCount then
					return true
				elseif a.evolutionCount > b.evolutionCount then
					return false
				else
					return a.level < b.level
				end
			end 
		end)
	return result
end

function HeroEvolutionChooseLayer:createHeroView()
	if self.tableLayer then
		self.tableLayer:removeSelf()
	end

	self.tableLayer = display.newLayer()
	self.tableLayer:size(self.tableSize):anch(0, 0):pos((self:getContentSize().width - self.tableSize.width)/2 + 10, 130):addTo(self)

	local columns = 2

	local function createCellNode(parentNode, cellIndex)
		parentNode:removeAllChildren()
		parentNode:setContentSize(CCSizeMake(self.bgSize.width, self.cellSize.height + 10))

		local xBegin = 0
		local xInterval = (self.tableSize.width - 2 * xBegin - columns * self.cellSize.width) / (columns - 1)
		local rows = math.ceil(#self.heroFilter:getResult() / columns)
		for index = (rows - cellIndex - 1) * columns + 1, columns * (rows - cellIndex) do
			local hero = self.heroFilter:getResult()[index]
			local nativeIndex = index - (rows - cellIndex - 1) * columns

			local unitData = unitCsv:getUnitByType(hero and hero.type or 0)
			if unitData then
				local heroNode = display.newNode()
				heroNode:size(self.cellSize):anch(0, 0) :pos(xBegin + (self.cellSize.width + xInterval) * (nativeIndex - 1), 10)
					:addTo(parentNode)

				local checkFrame = display.newSprite(HeroRes .. "check_frame.png"):anch(0.5, 0.5)
				local itemBtn = HeroListCell.new({	
						parent = self.tableLayer,
						priority = self.priority -1,
						type = hero.type,
						wakeLevel = hero.wakeLevel,
						star = hero.star,
						level = hero.level,
						evolutionCount = hero.evolutionCount,
						callback = function()
							if not self.chooseHeroIds[hero.id] then
								if table.nums(self.chooseHeroIds) >= game.role.heros[self.mainHeroId]:getEvolutionCardNeedNum() then
									errorMsgBox = DGMsgBox.new({ text = "素材卡已满，无法继续选择", type = 1 })
									return
								end

								self.chooseHeroIds[hero.id] = true
								display.newSprite(HeroRes .. "checked.png"):addTo(checkFrame, 0, 100)
									:pos(checkFrame:getContentSize().width / 2, checkFrame:getContentSize().height / 2)
							else
								self.chooseHeroIds[hero.id] = nil
								checkFrame:removeChildByTag(100)
							end
							self:updateResultLabel()

						end,
					})
				itemBtn:getLayer():anch(0, 0):pos(0, 0):addTo(heroNode)
				checkFrame:pos(self.cellSize.width - 70, 60):addTo(heroNode)

				if self.chooseHeroIds[hero.id] then
					display.newSprite(HeroRes .. "checked.png"):addTo(checkFrame, 0, 100)
						:pos(checkFrame:getContentSize().width / 2, checkFrame:getContentSize().height / 2)
				end
			end
		end
	end

	local viewHandler = LuaEventHandler:create(function(fn, table, a1, a2)
		local result
		if fn == "cellSize" then
			result = CCSizeMake(self.bgSize.width, self.cellSize.height + 10)

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
			result = math.ceil(#self.heroFilter:getResult() / columns)
		end

		return result
	end)

	self.heroListView = LuaTableView:createWithHandler(viewHandler, self.tableSize)
	self.heroListView:setBounceable(true)
	self.heroListView:setTouchPriority(self.priority -3)
	self.tableLayer:addChild(self.heroListView)

end

function HeroEvolutionChooseLayer:updateResultLabel()
	local total = 0
	for heroId, value in pairs(self.chooseHeroIds) do
		local hero = game.role.heros[heroId]
		total = total + hero:getEvolutionCardNum()
	end
	self.heroChooseNum:setString(string.format("需要素材 : %d", game.role.heros[self.mainHeroId]:getEvolutionCardNeedNum()))
	self.moneyValue:setString(string.format("已选素材 : %d", self:getEvolutionAllNum()))
end

function HeroEvolutionChooseLayer:getEvolutionAllNum()
	local total = 0
	for heroId, value in pairs(self.chooseHeroIds) do
		total = total + game.role.heros[heroId]:getEvolutionCardNum()
	end
	return total
end

function HeroEvolutionChooseLayer:showResultLayer()
	local resultLayer = display.newLayer(HeroSellRes .. "bottom.png")
	local bgSize = resultLayer:getContentSize()

	self.heroChooseNum = ui.newTTFLabel({ text = "需要素材 : 0", size = 24, color = display.COLOR_WHITE })
	self.heroChooseNum:anch(0, 0):pos(220, 60):addTo(resultLayer)

	self.moneyValue = ui.newTTFLabel({ text = "已选素材 : 0", size = 24, color = display.COLOR_WHITE })
	self.moneyValue:anch(0, 0):pos(530, 60):addTo(resultLayer)
	
	self:updateResultLabel()

	local cancelBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png"},
		{	
			priority = self.priority -2,
			text = { text = "取消", size = 24, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
				self.chooseHeroIds = {}
				self:createHeroView()
				self:updateResultLabel()
			end,
		}):getLayer()
	cancelBtn:anch(0, 0):pos(110, 10):addTo(resultLayer)

	self.confirmBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png"},
		{	
			priority = self.priority -2,
			text = { text = "确认", size = 24, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
				self.parent.fodderHeroIds = table.keys(self.chooseHeroIds)
				self.parent:initContentLeft()
				self.parent:initContentRight()

				self.parent.guideStep = self.parent.guideStep + 1
				self.parent:checkGuide()

				self:getLayer():removeSelf()
			end,
		}):getLayer()
	self.confirmBtn:anch(0, 0):pos(682, 10):addTo(resultLayer)

	return resultLayer, bgSize
end

function HeroEvolutionChooseLayer:checkGuide()
	
end

function HeroEvolutionChooseLayer:getLayer()
	return self.mask:getLayer()
end

function HeroEvolutionChooseLayer:onCleanup()
	-- display.removeUnusedSpriteFrames()
end

return HeroEvolutionChooseLayer