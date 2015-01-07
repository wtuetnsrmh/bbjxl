local HomeRes = "resource/ui_rc/home/"

--New Source Path 
local HeroRes = "resource/ui_rc/hero/"
local GlobalRes = "resource/ui_rc/global/"
local SellRes = HeroRes.."sell/"
local MapRes  = HeroRes.."map/"

local FilterBar = import(".FilterBar")
local ConfirmDialog = require("scenes.ConfirmDialog")

local SellLayer = class("SellLayer", function()
	return display.newLayer(GlobalRes.."inner_bg.png")
end)

function SellLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -130
	self.bgSize = self:getContentSize()

	self.closeCallback = params.closeCallback
	self.size = self:getContentSize()

	-- 遮罩层
	self:anch(0, 0):pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self , priority = self.priority + 1, bg = HomeRes .. "home.jpg"})

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
				if self.closeCallback then
					self.closeCallback()
				end
				self:getLayer():removeSelf()
			end,
		}):getLayer()
	closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self)

	-- 右侧按钮
	local tabLabel = display.newSprite(GlobalRes .. "tab_selected.png")
	tabLabel:anch(0, 0.5):pos(self:getContentSize().width - 14, 470):addTo(self)
	local btnSize = tabLabel:getContentSize()

	display.newSprite(GlobalRes.."tab_arrow.png"):anch(1,0.5):pos(10, btnSize.height/2)
		:addTo(tabLabel)

	ui.newTTFLabelWithStroke({ text = "出售", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(tabLabel)
	--filterbar
	local filterBar = FilterBar.new({ dataSource = self, priority = self.priority - 1})
	filterBar:anch(0, 1):pos(313, self.size.height - 17):addTo(self, 10)

	self.curHeros = {} --当前所有可选的hero
	self.profType = 0
	self.campType = 0
	self.starType = 0

	self:filterHerosByAction() 
	self:initMainLayer()
	self:showMyHeroNums()           --上面进将领比例刷新；

	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority})
	:anch(0,1):pos(0,display.height):addTo(self)
end

--初始化武将数据
function SellLayer:filterHerosByAction()
	self.curHeros = {}
	for heroId, hero in pairs(game.role.heros) do
		if hero.choose == 0 and hero.master == 0 then
			table.insert(self.curHeros, hero)
		end
	end
	--职业
	self:sortByType(1)
	--阵营
	self:sortByType(2)
	--星级
	self:sortByType(3)
	table.sort(self.curHeros, function(a, b)
		local unitDataA = unitCsv:getUnitByType(a.type)
		local unitDataB = unitCsv:getUnitByType(b.type)
		local factorA = (unitCsv:isMoneyCard(a.type) and 1 or 0) * 1000000+(unitCsv:isExpCard(a.type) and 0 or 1)*100000 + (6 - unitDataA.stars) * 10000 + a.evolutionCount * 1000 + a.level + a.type
		local factorB = (unitCsv:isMoneyCard(b.type) and 1 or 0) * 1000000+(unitCsv:isExpCard(b.type) and 0 or 1)*100000 + (6 - unitDataB.stars) * 10000 + b.evolutionCount * 1000 + b.level + b.type
		return factorA > factorB
	end)
end

--1.职业 2.阵营 3.星级
function SellLayer:sortByType(type)
	local objType = {[1] = "profession",[2] = "camp",[3] = "stars"}
	local selfType = {[1] = "profType",[2] = "campType",[3] = "starType"}

	if self[selfType[type]] > 0 then
		local t = {}
		for _, hero in pairs(self.curHeros) do
			if hero and tonumber(hero.unitData[objType[type]]) == tonumber(self[selfType[type]]) then
				table.insert(t,hero)
			end
		end
		self.curHeros = t
	end
end 

function SellLayer:initMainLayer(params)
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end
	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.bgSize):addTo(self)

	if params and params.isAuto then
	else
		self.sellHeroIds = {}
	end


	--底部结果view
	local resultLayer, resultSize = self:showResultLayer()
	resultLayer:anch(0.5, 0):pos(self.bgSize.width / 2, 10):addTo(self.mainLayer)

	local cellSize = CCSizeMake(415, 132)

	local upBg = display.newLayer()
	upBg:size(850, 372)
	upBg:anch(0.5, 0):pos(self.bgSize.width / 2, 150):addTo(self.mainLayer)
	local upSize = upBg:getContentSize()

	local columns = 2

	local function createCellNode(parentNode, cellIndex)
		parentNode:removeAllChildren()
		parentNode:setContentSize(CCSizeMake(upSize.width, cellSize.height + 10))

		local xBegin = 5
		local xInterval = (upSize.width - 2 * xBegin - columns * cellSize.width) / (columns - 1)
		local rows = math.ceil(table.nums(self.curHeros) / columns)
		for index = (rows - cellIndex - 1) * columns + 1, columns * (rows - cellIndex) do
			local hero = self.curHeros[index]
			local nativeIndex = index - (rows - cellIndex - 1) * columns

			local unitData = unitCsv:getUnitByType(hero and hero.type or 0)
			if unitData then
				local heroNode = display.newNode()
				heroNode:size(cellSize):anch(0, 0):pos(xBegin + (cellSize.width + xInterval) * (nativeIndex - 1), 5)
					:addTo(parentNode)

				local checkFrame = display.newSprite(HeroRes .. "check_frame.png"):anch(1, 0)

				local heroCell = HeroListCell.new({ type = unitData.type, level = hero.level, wakeLevel = hero.wakeLevel, star = hero.star,
					evolutionCount = hero.evolutionCount, priority = self.priority,
					parent = upBg,
					callback = function()
							if not self.sellHeroIds[hero.id] then
								self.sellHeroIds[hero.id] = true
								display.newSprite(HeroRes .. "checked.png"):addTo(checkFrame, 0, 100)
									:pos(checkFrame:getContentSize().width / 2, checkFrame:getContentSize().height / 2)
							else
								self.sellHeroIds[hero.id] = nil
								checkFrame:removeChildByTag(100)
							end
							self:updateResultLabel()
					end})
				heroCell:getLayer():anch(0, 0):addTo(heroNode)
				checkFrame:pos(cellSize.width - 25, 12):addTo(heroNode)

				--银币：
				local posY = 35
				local money = display.newSprite(GlobalRes .. "yinbi_big.png"):anch(0, 0.5):pos(145,posY)
				:addTo(heroNode)

				--银币Num
				ui.newTTFLabelWithStroke({text = hero:getSellMoney(), size = 28, font = ChineseFont, strokeColor = display.COLOR_FONT })
					:anch(0, 0.5):pos(money:getContentSize().width + money:getPositionX() + 7 ,posY):addTo(heroNode)

				if self.sellHeroIds[hero.id] then
					display.newSprite(HeroRes .. "checked.png"):addTo(checkFrame, 0, 100)
						:pos(checkFrame:getContentSize().width / 2, checkFrame:getContentSize().height / 2)
				end
			end
		end
	end

	local viewHandler = LuaEventHandler:create(function(fn, table, a1, a2)
		local result
		if fn == "cellSize" then
			result = CCSizeMake(upSize.width, cellSize.height + 10)

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

	self.heroListView = LuaTableView:createWithHandler(viewHandler, 
		CCSizeMake(upSize.width, upSize.height - 20))
	self.heroListView:setBounceable(true)
	self.heroListView:setTouchPriority(self.priority - 1)
	self.heroListView:setPosition(ccp(0, 5))
	upBg:addChild(self.heroListView)
end

function SellLayer:updateResultLabel()
	local sellMoney = 0
	for heroId, value in pairs(self.sellHeroIds) do
		local hero = game.role.heros[heroId]
		if value and hero then
			sellMoney = sellMoney + hero:getSellMoney()
		end
	end
	self.heroChooseNum:setString(string.format("%d", table.nums(self.sellHeroIds)))
	self.moneyValue:setString(string.format("%d", sellMoney))
end

function SellLayer:showResultLayer()
	--背景框
	local resultLayer = display.newLayer(SellRes .. "bottom.png")
	local bgSize = resultLayer:getContentSize()

	--已选武将
	local posY = 105
	local word_Hero = ui.newTTFLabel({text = "已选武将：",size = 24, font = ChineseFont, color = display.COLOR_WHITE })
	:anch(0,0.5)
	:pos(174,posY)
	:addTo(resultLayer)

	self.heroChooseNum = ui.newTTFLabel({ text = "0", size = 24, font = ChineseFont, color = uihelper.hex2rgb("#7ce810")})
	self.heroChooseNum:anch(0, 0.5):pos(294, posY):addTo(resultLayer)
	
	--获得银币：
	local word_money = ui.newTTFLabel({text = "获得银币：", size = 24, font = ChineseFont, color = display.COLOR_WHITE })
	:anch(0,0.5)
	:pos(464,posY)
	:addTo(resultLayer)

	self.moneyValue = ui.newTTFLabel({ text = "0", size = 24, font = ChineseFont, color = uihelper.hex2rgb("#7ce810")})
	self.moneyValue:anch(0, 0.5):pos(0, 0.5):pos(580, posY)
		:addTo(resultLayer)

	--银币sp
	local money = display.newSprite(GlobalRes .. "yinbi_big.png"):anch(0, 0.5):pos(660, posY)
		:addTo(resultLayer)

	local btnY = 14
	local btnOff = 250

	--取消
	local cancelBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png", "middle_disabled.png"},
		{	
			priority = self.priority,
			text = { text = "取消", size = 32, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
				self.sellHeroIds = {}
				self:initMainLayer()
			end,
		}):getLayer()
	cancelBtn:anch(0.5, 0):pos(bgSize.width/2 - btnOff, btnY):addTo(resultLayer)

	--自动：
	local autoBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png", "middle_disabled.png"},
		{	
			priority = self.priority,
			text = { text = "自动", size = 32, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
				--在当前模式下选择1，2星的将领
				self:autoSelect()
				self:updateResultLabel()
			end,
		}):getLayer()
	autoBtn:anch(0.5, 0):pos(bgSize.width/2,btnY):addTo(resultLayer)

	--出售
	local sellBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png", "middle_disabled.png"},
		{	
			priority = self.priority,
			text = { text = "出售", size = 32, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
				if #table.keys(self.sellHeroIds) > 0 then
					local confirmDialog
					confirmDialog = ConfirmDialog.new({
						priority = self.priority - 10,
						showText = { text = "卖啦卖啦", size = 24, },
						button2Data = {
							priority = self.priority - 10,
							text = "出售", font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2,
							callback = function()
								confirmDialog:getLayer():removeSelf()
								self:sellHeroRequest()
							end,
						}
					})
					confirmDialog:getLayer():addTo(display.getRunningScene())
				else
					DGMsgBox.new({ type = 1, text = "请选择卡牌！"})
				end
			end,
		}):getLayer()
	sellBtn:anch(0.5, 0):pos(bgSize.width/2 + btnOff, btnY):addTo(resultLayer)

	return resultLayer, bgSize
end

function SellLayer:autoSelect()
	self.sellHeroIds = {}
	for _, hero in pairs(self.curHeros) do
		if (hero and tonumber(hero.unitData.stars) < 3 and not unitCsv:isExpCard(hero.type)) or unitCsv:isMoneyCard(hero.type) then
			self.sellHeroIds[hero.id] = true
		end
	end
	self:initMainLayer({isAuto = true})
end 

function SellLayer:sellHeroRequest()
	if #table.keys(self.sellHeroIds) == 0 then
		return
	end

	local sellRequest = {
		roleId = game.role.id,
		otherHeroIds = clone(table.keys(self.sellHeroIds))
	}

	local bin = pb.encode("HeroActionData", sellRequest)
    game:sendData(actionCodes.HeroSellRequest, bin)
    loadingShow()
    game:addEventListener(actionModules[actionCodes.HeroSellResponse], function(event)
    	loadingHide()
    	local msg = pb.decode("HeroActionResponse", event.data)
    	if msg.result ~= 0 then print("fail") return "__REMOVE__" end

    	for id, _ in pairs(self.sellHeroIds) do
    		game.role.heros[id] = nil
    	end

    	local resultDialog = ConfirmDialog.new({
    		priority = self.priority - 10,
			showText = { text = string.format("出售 %d 张武将卡, 共计获得 %d 银币\n恭喜发财！请笑纳！", table.nums(self.sellHeroIds), msg.money), },
			button1Data = {
				text = "笑纳", font = ChineseFont, strokeColor = display.COLOR_BLACK, strokeSize = 2,
				callback = function()
					self:filterHerosByAction() 
					self:initMainLayer()
					self:showMyHeroNums()
				end,
			}
		})
		resultDialog:getLayer():addTo(display.getRunningScene())

    	return "__REMOVE__"
    end)
end

--全部显示
function SellLayer:showAll()
	self.profType = 0
	self.campType = 0
	self.starType = 0
	self:filterHerosByAction()
	self:initMainLayer()
end

--职业 profession
function SellLayer:filterByProfession(params)
	self.profType = params.profession
	self:filterHerosByAction()
	self:initMainLayer()
end 
--阵营 camp
function SellLayer:filterByCamp(params)
	self.campType = params.camp
	self:filterHerosByAction()
	self:initMainLayer()
end

--星级 star
function SellLayer:filterByStar(params)
	self.starType = params.star
	self:filterHerosByAction()
	self:initMainLayer()
end

--test
function SellLayer:sortByAllRole(params)
	local starHeros = filterHerosByAction
	for _, hero in pairs(self.curHeros) do
		if hero and tonumber(hero.unitData.stars) == tonumber(params.star) then
			table.insert(starHeros,hero)
		end
	end
	self.curHeros = starHeros
	self:initMainLayer()
end

function SellLayer:refreshViewByFilterType()
	if  self.sortType    == 1 then
		self:showAll()
	elseif self.sortType == 2 then
		self:filterByProfession()
	elseif self.sortType == 3 then
		self:filterByCamp()
	elseif self.sortType == 4 then
		self:filterByStar()
	else
		self:showAll()
	end
end

--拥有武将数量：
function SellLayer:showMyHeroNums()
	if self.infoBg then
		self.infoBg:removeSelf()
	end
	self.infoBg = display.newSprite(GlobalRes .. "label_bg.png"):anch(0, 1)
	:pos(40, self.size.height - 13)
	:addTo(self)
	local xPos, yPos = 8, self.infoBg:getContentSize().height/2
	local text = ui.newTTFLabel({text = "拥有武将：", size = 20})
	text:anch(0, 0.5):pos(xPos, yPos):addTo(self.infoBg)
	xPos = xPos + text:getContentSize().width

	local heroNums = table.nums(self.curHeros)
	text = ui.newTTFLabel({text = heroNums, size = 20, color = heroNums > 0 and uihelper.hex2rgb("#7ce810") or display.COLOR_RED })
	text:anch(0, 0.5):pos(xPos, yPos):addTo(self.infoBg)
	xPos = xPos + text:getContentSize().width
end

function SellLayer:getLayer()
	return self.mask:getLayer()
end

return SellLayer