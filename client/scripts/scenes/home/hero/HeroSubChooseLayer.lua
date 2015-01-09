local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"

local FilterLogic = import(".FilterLogic")
local FilterBar = import(".FilterBar")

local HeroSubChooseLayer = class("HeroSubChooseLayer", function(params)
	return display.newLayer(GlobalRes .. "inner_bg.png")
end)

function HeroSubChooseLayer:ctor(params)
	params = params or {}
	self.priority = params.priority or -132

	self.size = self:getContentSize()

	self.beChangedHero = params.hero

	self.chooseHeroIds = {}
	self.heros = {}
	self.chooseHeroTypes = {}
	self.parent = params.parent
	self.slot = params.slot

	self:anch(0, 0):pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self , priority = self.priority + 1, bg = HomeRes .. "home.jpg"})

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
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

	ui.newTTFLabelWithStroke({ text = "换将", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(tabLabel)

	self:filterHeros(params.action)

	self.heroFilter = FilterLogic.new({ heros = self.heros })
	local filterBar = FilterBar.new({ dataSource = self.heroFilter, priority = self.priority - 10})
	filterBar:anch(0, 1):pos(313, self.size.height - 17):addTo(self, 100)

	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority})
	:anch(0,1):pos(0, display.height):addTo(self)

	self:showHeroList(params.action or "change")
	self:showMyHeroNums()
	self:checkGuide()
end

function HeroSubChooseLayer:filterHeros(action)
	for id, hero in pairs(game.role.heros) do
		if hero.choose == 1 then
			self.chooseHeroIds[hero.id] = true
			self.chooseHeroTypes[hero.type] = hero.id
		end

		-- 非素材卡
		if not (hero.type >= 991 and hero.type <= 999) and hero.master == 0 then
			if action == "add" then
				if hero.choose ~= 1 then
					table.insert(self.heros, hero)
				end
			else
				-- 主将位置
				if hero.id ~= self.beChangedHero.id then
					table.insert(self.heros, hero)
				end
			end
		end
	end
	table.sort(self.heros, function(a, b)
		local unitDataA = unitCsv:getUnitByType(a.type)
		local unitDataB = unitCsv:getUnitByType(b.type)
		local factorA = a.choose * 100000 + a.star * 10000 + a.evolutionCount * 1000 + a.level
		local factorB = b.choose * 100000 + b.star * 10000 + b.evolutionCount * 1000 + b.level
		return factorA == factorB and (a.type < b.type) or (factorA > factorB)
	end)
end

function HeroSubChooseLayer:showMyHeroNums()
	local infoBg = display.newSprite(GlobalRes .. "label_bg.png"):anch(0, 1)
	:pos(40, self.size.height - 13)
	:addTo(self)
	local xPos, yPos = 8, infoBg:getContentSize().height/2
	local text = ui.newTTFLabel({text = "拥有武将：", size = 20})
	text:anch(0, 0.5):pos(xPos, yPos):addTo(infoBg)
	xPos = xPos + text:getContentSize().width

	local heroNums = table.nums(self.heros)
	text = ui.newTTFLabel({text = heroNums, size = 20, color = heroNums > 0 and uihelper.hex2rgb("#7ce810") or display.COLOR_RED })
	text:anch(0, 0.5):pos(xPos, yPos):addTo(infoBg)
	xPos = xPos + text:getContentSize().width
end

function HeroSubChooseLayer:showHeroList(action)
	local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)

	local changeOther = action == "change" and self.slot ~= 1
	local cellSize = CCSizeMake(415, 132)
	local columns = 2

	local viewBg = display.newLayer()
	viewBg:size(850, 474)
	local viewSize = viewBg:getContentSize()
	viewBg:anch(0.5, 0):pos(self.size.width / 2, 20):addTo(self)

	local function createCellNode(parentNode, cellIndex)
		parentNode:removeAllChildren()
		parentNode:setContentSize(CCSizeMake(viewSize.width, cellSize.height + 10))

		local xBegin = 5
		local xInterval = (viewSize.width - 2 * xBegin - columns * cellSize.width) / (columns - 1)
		local rows = math.ceil((changeOther and #self.heroFilter:getResult() + 1 or #self.heroFilter:getResult()) / columns)
		for index = (rows - cellIndex - 1) * columns + 1, columns * (rows - cellIndex) do
			local hero = self.heroFilter:getResult()[(changeOther and index - 1 or index)]
			local nativeIndex = index - (rows - cellIndex - 1) * columns
			local cellNode = display.newNode()
			cellNode:size(cellSize)

			if hero then
				local heroCell
				heroCell = HeroListCell.new({ type = hero.type, level = hero.level, wakeLevel = hero.wakeLevel, star = hero.star,
					evolutionCount = hero.evolutionCount, priority = self.priority, notSendClickEvent = true,
					parent = viewBg,
					callback = function()
						self:heroBtnAction(hero, heroCell)
					end
				}):getLayer()
				heroCell:anch(0, 0):addTo(cellNode)
				if index == 1 then
					self.guideBtn = heroCell
				end

				local cellSize = heroCell:getContentSize()
				if hero.choose == 1 then
					display.newSprite(HeroRes .. "tag_selected.png")
						:anch(1, 1):pos(cellSize.width + 3, cellSize.height - 3):addTo(heroCell)
				end

				if table.find(game.role.partners, hero.id) then
					display.newSprite(HeroRes .. "tag_partner.png")
						:anch(1, 1):pos(cellSize.width, cellSize.height - 5):addTo(heroCell)
				end

				-- skill
				local skillIds = hero:getAllSkillIds()
				if skillIds["1"] then
					local skillData = skillCsv:getSkillById(skillIds["1"])					
					if skillData.icon ~= "" then
						local skillIcon = display.newSprite(skillData.icon)
						skillIcon:scale(29/skillIcon:getContentSize().width):anch(0, 0):pos(150, 20):addTo(heroCell)
					end
				end

				for index = 2, 4 do
					if skillIds[tostring(index)] then
						local skillData = skillPassiveCsv:getPassiveSkillById(math.abs(skillIds[tostring(index)]))					
						if skillData and skillData.icon ~= "" then
							local skillIcon = display.newSprite(skillData.icon)
							skillIcon:scale(29/skillIcon:getContentSize().width):anch(0, 0):pos(150 + (index - 1) * 35, 20):addTo(heroCell)
							if skillIds[tostring(index)] < 0 then
								skillIcon:setColor(ccc3(125, 125, 125))
							end
						end
					end
				end	

				local changeBtn = DGBtn:new(GlobalRes, {"btn_small_green_nol.png", "btn_small_green_sel.png"},
					{	
						text = { text = "上阵", size = 24, font = ChineseFont, strokeColor = display.COLOR_FONT },
						priority = self.priority,
					}):getLayer()
				changeBtn:anch(1, 0):pos(cellSize.width - 5, 10):addTo(heroCell)

			elseif (changeOther and index == 1) then
				local noneBtn
				noneBtn = DGBtn:new(HeroRes, {"cell_bar.png"},
					{	
						parent = viewBg,
						priority = self.priority,
						notSendClickEvent = true,
						callback = function()
							self.chooseHeroTypes[self.beChangedHero.type] = nil
							self.chooseHeroIds[self.beChangedHero.id] = nil
							self:chooseHeroRequest(nil, noneBtn)
						end,
					}):getLayer()
				local cellSize = noneBtn:getContentSize()

				local emptyIcon = display.newSprite(GlobalRes .. "frame_empty.png"):anch(0, 0):pos(25, 10):addTo(noneBtn)
				display.newSprite(GlobalRes .. "frame_bottom.png"):addTo(emptyIcon, -1)
					:pos(emptyIcon:getContentSize().width / 2, emptyIcon:getContentSize().height / 2)
				ui.newTTFLabel({text = "不选择武将", size = 36, color = display.COLOR_DARKYELLOW })
					:anch(0, 0.5):pos(150, cellSize.height / 2):addTo(noneBtn)

				local professionBg = display.newSprite(HeroRes .. "profession_bg.png")
				professionBg:anch(0, 1):pos(6, cellSize.height - 6):addTo(noneBtn)

				noneBtn:anch(0, 0):addTo(cellNode)
			end

			cellNode:anch(0, 0):pos(xBegin + (cellSize.width + xInterval) * (nativeIndex - 1), 0)
				:addTo(parentNode)
		end
	end

	local viewHandler = LuaEventHandler:create(function(fn, table, a1, a2)
		local result
		if fn == "cellSize" then
			result = CCSizeMake(viewSize.width, cellSize.height + 10)

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
			result = math.ceil((changeOther and #self.heroFilter:getResult() + 1 or #self.heroFilter:getResult()) / columns)
		end

		return result
	end)

	self.heroTableView = LuaTableView:createWithHandler(viewHandler, viewSize)
	self.heroTableView:setBounceable(true)
	self.heroTableView:setTouchPriority(self.priority - 1)
	self.heroTableView:setPosition(ccp(0, 5))
	viewBg:addChild(self.heroTableView)

	self.heroFilter:addEventListener("filter", function(event) self.heroTableView:reloadData() end)
end

function HeroSubChooseLayer:heroBtnAction(hero, btn)
	-- 判断类型(和当前被选类型相同可以, 和其他武将类型相同不行)
	local slotHeroId
	if game.role.slots[tostring(self.slot)] then
		slotHeroId = tonum(game.role.slots[tostring(self.slot)].heroId)
	else
		slotHeroId = 0
	end
	
	if slotHeroId == 0 then
		-- 新增
		if self.chooseHeroTypes[hero.type] then
			DGMsgBox.new({ msgId = 110 })
			return
		end
	elseif slotHeroId > 0 then
		-- 替换
		local slotHero = game.role.heros[slotHeroId]
		-- 非调换武将
		if hero.choose ~= 1 and slotHero.type ~= hero.type and self.chooseHeroTypes[hero.type] then
			DGMsgBox.new({ msgId = 110 })
			return
		end
	end

	self:chooseHeroRequest(hero, btn)
end

function HeroSubChooseLayer:checkGuide(remove)
	--选列表第一个武将
	game:addGuideNode({node = self.guideBtn, remove = remove,
		guideIds = {1018, 1022, 1076}
	})
	self.heroTableView:setTouchEnabled(not game:hasGuide())
end

function HeroSubChooseLayer:onExit()
	self:checkGuide(true)
end

function HeroSubChooseLayer:chooseHeroRequest(hero, btn)
	local chooseRequest = {
		roleId = game.role.id,
		heroId = hero and hero.id or 0,
		slot = self.slot,
	}

	local bin = pb.encode("HeroChooseRequest", chooseRequest)
    game:sendData(actionCodes.HeroChoose, bin)
    loadingShow()

    game:addEventListener(actionModules[actionCodes.HeroChooseResponse], function(event)
    	local msg = pb.decode("SimpleEvent", event.data)
    	loadingHide()
    	game:dispatchEvent({name = "btnClicked", data = btn})

    	game.role.chooseHeros = {}
    	for _, slotData in pairs(game.role.slots) do
    		if tonum(slotData.heroId) > 0 then
    			table.insert(game.role.chooseHeros, game.role.heros[tonum(slotData.heroId)])
    		end
    	end

    	game.role:updateNewMsgTag()

		self.parent:showMainLayer(self.slot)
		self.mask:remove()

		return "__REMOVE__"
    end)
end

function HeroSubChooseLayer:getLayer()
	return self.mask:getLayer()
end

return HeroSubChooseLayer