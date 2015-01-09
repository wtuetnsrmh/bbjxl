--New Source Path 
local HeroRes = "resource/ui_rc/hero/"
local GlobalRes = "resource/ui_rc/global/"
local GrowRes = HeroRes.."growth/"
local SellRes = HeroRes.."sell/"
local MapRes = HeroRes.."map/"

local HomeRes = "resource/ui_rc/home/"
local GlobalRes = "resource/ui_rc/global/"

-- local HeroFilterBar = require("scenes.home.herocommon.HeroFilterBar")

local IntensifySubChooseLayer = class("IntensifySubChooseLayer", function()
	return display.newLayer(GlobalRes .. "inner_bg.png")
end)

function IntensifySubChooseLayer:ctor(params)
	params = params or {}

	self.mainHeroId = params.mainHeroId               ---传入主卡ID
	self.mainHero = game.role.heros[self.mainHeroId]  ---主卡信息
	self.fodderHeroIds = params.fodderHeroIds or {}   ---传入选择ID
	self.curHeros = {} --当前所有可选的hero
	self.sortType = 1  --默认1全部，2职业，3阵营，4等级；

	self.priority = params.priority - 20 or -130
	self.parent = params.parent                       ---出入父类指针

	self.chooseHeroIds = self:initChooseHeroIds()     ---选择卡牌IDs
	-- self.heros = self:filterHerosByAction()           ---所有可以上阵武将

	self.totalExp,self.totalMoney = self:getTotalWorshipExpAndMoney()   ---获取当前消耗和所得

	--设置遮罩：
	self:anch(0.5, 0):pos(display.cx, 0)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1,bg = HomeRes .. "home.jpg"})

	
	self.size = self:getContentSize()


	--底布结果显示：
	local resultLayer, resultSize = self:showResultLayer()
	resultLayer:anch(0.5, 0):pos(self.size.width / 2, 15):addTo(self)
	--单元格大小：
	self.cellSize = CCSizeMake(415, 132) 
	--tableview大小；
	self.tableSize = CCSizeMake(850, 352)

	self:showAll()
	-- self:createHeroView()

	-- 右侧按钮
	local tabLabel = display.newSprite(GlobalRes .. "tab_selected.png")
	tabLabel:anch(0, 0.5):pos(self:getContentSize().width - 14, 470):addTo(self)
	local btnSize = tabLabel:getContentSize()

	display.newSprite(GlobalRes.."tab_arrow.png"):anch(1,0.5):pos(10, btnSize.height/2)
		:addTo(tabLabel)

	ui.newTTFLabelWithStroke({ text = "升级", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(tabLabel)

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority -1,
			callback = function()
				self:getLayer():removeSelf()
			end,
		}):getLayer()
	closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self)

	self:showMyHeroNums()

	--filterbar
	local filter = require("scenes.home.hero.FilterBar")
	local filterBar = filter.new({ dataSource = self, priority = self.priority - 1})
	filterBar:anch(0, 1):pos(313, self.size.height - 17):addTo(self,100)

	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority})
	:anch(0,1):pos(0,display.height):addTo(self)
end

--拥有武将数量：
function IntensifySubChooseLayer:showMyHeroNums()
	local infoBg = display.newSprite(GlobalRes .. "label_bg.png"):anch(0, 1)
	:pos(40, self.size.height - 13)
	:addTo(self)
	local xPos, yPos = 8, infoBg:getContentSize().height/2
	local text = ui.newTTFLabel({text = "拥有武将：", size = 20})
	text:anch(0, 0.5):pos(xPos, yPos):addTo(infoBg)
	xPos = xPos + text:getContentSize().width

	local heroNums = table.nums(self.curHeros)
	text = ui.newTTFLabel({text = heroNums, size = 20, color = heroNums > 0 and uihelper.hex2rgb("#7ce810") or display.COLOR_RED })
	text:anch(0, 0.5):pos(xPos, yPos):addTo(infoBg)
	xPos = xPos + text:getContentSize().width
end

--设置选中的id为true
function IntensifySubChooseLayer:initChooseHeroIds()
	local ret = {}
	for _, heroId in ipairs(self.fodderHeroIds) do
		ret[heroId] = true
	end
	return ret
end

--计算当前选择后的消耗和获取数量；
function IntensifySubChooseLayer:getTotalWorshipExpAndMoney()
	local totalExp = 0
	local totalMoney = 0
	for heroId, value in pairs(self.chooseHeroIds) do
		local hero = game.role.heros[heroId]
		totalExp = totalExp + hero:getWorshipExp()
		totalMoney = totalMoney + hero:getWorshipMoney()
	end
	return totalExp,totalMoney
end

--返回并排序可以上阵的所有武将；
function IntensifySubChooseLayer:filterHerosByAction()
	local result = {}
	for heroId, hero in pairs(game.role.heros) do --不是副将，没有上阵
		if hero.choose == 0 and hero.master == 0 and self.mainHeroId ~= heroId then
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
				local factorA = a:getWorshipExp() + (unitCsv:isExpCard(a.type) and 1 or 0) * 1000000
				local factorB = b:getWorshipExp() + (unitCsv:isExpCard(b.type) and 1 or 0) * 1000000
				return factorA == factorB and (a.type < b.type) or (factorA > factorB)
			end 
		end)
	return result
end

--初始化tableview:
function IntensifySubChooseLayer:createHeroView()
	if self.tableLayer then
		self.tableLayer:removeSelf()
	end

	self.tableLayer = display.newLayer()
	self.tableLayer:size(self.tableSize):anch(0.5, 0):pos(self.size.width/2, 160):addTo(self)

	local columns = 2

	local function createCellNode(parentNode, cellIndex)
		parentNode:removeAllChildren()
		parentNode:setContentSize(CCSizeMake(self.size.width, self.cellSize.height + 10))

		local xBegin = 10
		local xInterval = (self.tableSize.width - 2 * xBegin - columns * self.cellSize.width) / (columns - 1)
		local rows = math.ceil(#self.curHeros/ columns)
		for index = (rows - cellIndex - 1) * columns + 1, columns * (rows - cellIndex) do
			local hero = self.curHeros[index]
			local nativeIndex = index - (rows - cellIndex - 1) * columns

			local unitData = unitCsv:getUnitByType(hero and hero.type or 0)

			if unitData then
				local heroNode = display.newNode()
				heroNode:size(self.cellSize):anch(0, 0) :pos(xBegin + (self.cellSize.width + xInterval) * (nativeIndex - 1), 5)
					:addTo(parentNode)
				
				--公用cell
				if hero then
					-- --复选框bg
					local checkFrame = display.newSprite(HeroRes .. "check_frame.png"):anch(1, 0)
					local heroCell = HeroListCell.new({ type = unitData.type, level = hero.level, wakeLevel = hero.wakeLevel, star = hero.star,
					evolutionCount = hero.evolutionCount, priority = self.priority,
					parent = self.tableLayer,
					callback = function()

							if not self.chooseHeroIds[hero.id] then
								if table.nums(self.chooseHeroIds) >= 8 then
									DGMsgBox.new({ type = 1, text = "素材卡已满，无法继续选择" })
									return
								end

								-- 经验溢出
								if table.nums(self.chooseHeroIds) >=1 and self.totalExp > self.mainHero:getLevelMaxExp() then
									DGMsgBox.new({ msgId = SYS_ERR_HERO_EXP_LIMIT})
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
				
						end})
					heroCell:getLayer():anch(0, 0):addTo(heroNode)
					checkFrame:pos(self.cellSize.width - 25, 12):addTo(heroNode)

					-- --expSp
					local posY = 35
					local expSp = display.newSprite(GlobalRes .."exp.png"):anch(0, 0.5):pos(145,posY):addTo(heroNode)
					--expNum
					ui.newTTFLabelWithStroke({text = hero:getWorshipExp(), size = 28, font = ChineseFont, strokeColor = display.COLOR_FONT })
					:anch(0, 0.5):pos(expSp:getContentSize().width + expSp:getPositionX() + 7 ,posY):addTo(heroNode)

					if self.chooseHeroIds[hero.id] then
						display.newSprite(HeroRes .. "checked.png"):addTo(checkFrame, 0, 100)
							:pos(checkFrame:getContentSize().width / 2, checkFrame:getContentSize().height / 2)
					end

					-- local nameStarBar = NameStarBar.new(hero)
					-- nameStarBar:anch(0.5, 1):pos(self.cellSize.width / 2, self.cellSize.height):addTo(heroNode)

					-- local xPos, yPos = 5, 60
					-- local headFrame = HeadFrame.new({ type = unitData.type }):getLayer()
					-- headFrame:anch(0, 0.5):pos(10, yPos):addTo(heroNode)
					-- xPos = xPos + headFrame:getContentSize().width + 15

					-- local professionIcon = display.newSprite(HeroRes .. ProfessionName[unitData.profession] .. ".png")
					-- professionIcon:anch(0, 0.5):pos(xPos, yPos):addTo(heroNode)
					-- xPos = xPos + professionIcon:getContentSize().width + 15

					-- ui.newTTFLabel({ text = string.format("Lv.%d", hero.level), size = 28, color = display.COLOR_DARKYELLOW })
					-- 	:anch(0, 0.5):pos(xPos, yPos):addTo(heroNode)
				end
			end
		end
	end

	local viewHandler = LuaEventHandler:create(function(fn, table, a1, a2)
		local result
		if fn == "cellSize" then
			result = CCSizeMake(self.size.width, self.cellSize.height + 10)

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
			result = math.ceil(#self.curHeros / columns)
		end

		return result
	end)

	self.heroListView = LuaTableView:createWithHandler(viewHandler, self.tableSize)
	self.heroListView:setBounceable(true)
	self.heroListView:setTouchPriority(self.priority -3)
	self.tableLayer:addChild(self.heroListView)
end

--刷新消耗和获取label
function IntensifySubChooseLayer:updateResultLabel()
	local totalExp,totalMoney = self:getTotalWorshipExpAndMoney()

	self.heroChooseNum:setString(totalExp)
	self.moneyValue:setString(totalMoney)

	self.totalExp = totalExp
	self.totalMoney = totalMoney
end

function IntensifySubChooseLayer:showResultLayer()
	--背景框
	local resultLayer = display.newLayer(SellRes.."bottom.png")
	local bgSize = resultLayer:getContentSize()


	--已选武将
	local posY = 105
	local word_Hero = ui.newTTFLabel({text = "获得经验：",size = 24, font = ChineseFont, color = display.COLOR_WHITE })
	:anch(0,0.5)
	:pos(174,posY)
	:addTo(resultLayer)

	self.heroChooseNum = ui.newTTFLabel({ text = "0", size = 24, font = ChineseFont, color = uihelper.hex2rgb("#7ce810")})
	self.heroChooseNum:anch(0, 0.5):pos(294, posY):addTo(resultLayer)
	
	--获得银币：
	local word_money = ui.newTTFLabel({text = "消耗银币：", size = 24, font = ChineseFont, color = display.COLOR_WHITE })
	:anch(0,0.5)
	:pos(464,posY)
	:addTo(resultLayer)

	self.moneyValue = ui.newTTFLabel({ text = "0", size = 24, font = ChineseFont, color = uihelper.hex2rgb("#7ce810")})
	self.moneyValue:anch(0, 0.5):pos(0, 0.5):pos(580, posY)
		:addTo(resultLayer)

	--银币sp
	local money = display.newSprite(GlobalRes .. "yinbi_big.png"):anch(0, 0.5):pos(660, posY)
		:addTo(resultLayer)


	--仅仅是取消当前选择并不退出；
	local cancelBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png","middle_disabled.png"},
		{	
			priority = self.priority -2,
			text = { text = "取消", size = 32, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
				self.chooseHeroIds = {}
				self:createHeroView()
				self:updateResultLabel()
			end,
		}):getLayer()
	cancelBtn:anch(0.5, 0):pos(bgSize.width/3, 10):addTo(resultLayer)

	--将选择后的id传入到parent，初始化左右两部分并删除
	local confirmBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png","middle_disabled.png"},
		{	
			priority = self.priority -2,
			text = { text = "确认", size = 32, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
				local fodderHeroIds = {}
				for heroId, value in pairs(self.chooseHeroIds) do
					fodderHeroIds[heroId] = #fodderHeroIds + 1
				end
				
				self.parent.fodderHeroIds = fodderHeroIds
				self.parent:initContentLeft()
				self.parent:initContentRight()

				self:getLayer():removeSelf()
			end,
		}):getLayer()
	confirmBtn:anch(0.5, 0):pos(bgSize.width/3*2, 10):addTo(resultLayer)

	return resultLayer, bgSize
end

--全部显示
function IntensifySubChooseLayer:showAll()
	self.curHeros = {}
	self.curHeros = self:filterHerosByAction()
	self:createHeroView()
end

--职业 profession
function IntensifySubChooseLayer:filterByProfession(params)
	self.curHeros = {}
	for _, hero in pairs(self:filterHerosByAction()) do
		if tonumber(hero.unitData.profession) == tonumber(params.profession) then
			table.insert(self.curHeros,hero)
		end
	end
	self:createHeroView()
end 
--阵营 camp
function IntensifySubChooseLayer:filterByCamp(params)
	self.curHeros = {}
	for _, hero in pairs(self:filterHerosByAction()) do
		if tonumber(hero.unitData.camp) == tonumber(params.camp) then
			table.insert(self.curHeros,hero)
		end
	end
	self:createHeroView()
end
--星级 star
function IntensifySubChooseLayer:filterByStar(params)
	self.curHeros = {}
	for _, hero in pairs(self:filterHerosByAction()) do
		if tonumber(hero.unitData.stars) == tonumber(params.star) then
			table.insert(self.curHeros,hero)
		end
	end
	self:createHeroView()
end

function IntensifySubChooseLayer:getLayer()
	return self.mask:getLayer()
end

function IntensifySubChooseLayer:onCleanup()
	-- display.removeUnusedSpriteFrames()
end

return IntensifySubChooseLayer