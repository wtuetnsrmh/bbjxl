local HeroRes = "resource/ui_rc/hero/"
local GlobalRes = "resource/ui_rc/global/"

local FilterLogic = import(".FilterLogic")
local FilterBar = import(".FilterBar")

local HeroPartnerChooseLayer = class("HeroPartnerChooseLayer", function(params)
	return display.newLayer(GlobalRes .. "inner_bg.png")
end)

function HeroPartnerChooseLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -132
	self.size = self:getContentSize()

	--位置
	self.index = params.index
	self.closeCallback = params.closeCallback

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

	ui.newTTFLabelWithStroke({ text = "小伙伴", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 22, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(tabLabel)

	self.heros = self:filterHeros()

	self.heroFilter = FilterLogic.new({ heros = self.heros, sortRule = "noChange" })
	local filterBar = FilterBar.new({ dataSource = self.heroFilter, priority = self.priority - 10})
	filterBar:anch(0, 1):pos(313, self.size.height - 17):addTo(self, 100)

	self:listHeros()
	self:showMyHeroNums()

	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority})
	:anch(0,1):pos(0,display.height):addTo(self)
end

function HeroPartnerChooseLayer:showMyHeroNums()
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

function HeroPartnerChooseLayer:filterHeros()
	local heros = {}

	for id, hero in pairs(game.role.heros) do
		-- 非素材卡
		if hero.master == 0 and hero.choose == 0 and not table.find(game.role.partners, id) then
			table.insert(heros, hero)
		end
	end

	table.sort(heros, function(a,b) 
		local unitDataA = unitCsv:getUnitByType(a.type)
		local unitDataB = unitCsv:getUnitByType(b.type)
		local factorA = (game.role:isActiveRelation(a.type) and 1 or 0) * 100000 + a.star * 10000 + a.evolutionCount * 1000 + a.level
		local factorB = (game.role:isActiveRelation(b.type) and 1 or 0) * 100000 + b.star * 10000 + b.evolutionCount * 1000 + b.level
		return factorA > factorB 
	end)

	return heros
end

function HeroPartnerChooseLayer:listHeros()
	local cellSize = CCSizeMake(415, 132)
	local columns = 2

	local viewBg = display.newLayer()
	viewBg:size(850, 474)
	local viewSize = viewBg:getContentSize()
	viewBg:anch(0.5, 0):pos(self.size.width / 2, 20):addTo(self)

	local function sendChooseRequest(hero)
		local chooseRequest = {
			roleId = game.role.id,
			heroId = hero and hero.id or 0,
			slot = self.index,
		}

		local bin = pb.encode("HeroChooseRequest", chooseRequest)
	    game:sendData(actionCodes.HeroPartnerRequest, bin)
	    loadingShow()
	    game:addEventListener(actionModules[actionCodes.HeroPartnerRequest], function(event)
	    	loadingHide()

	    	if self.closeCallback then
	    		self.closeCallback()
	    	end
			self.mask:remove()

			return "__REMOVE__"
	    end)
	end

	local function createCellNode(parentNode, cellIndex)
		parentNode:removeAllChildren()
		parentNode:setContentSize(CCSizeMake(viewSize.width, cellSize.height + 10))

		local xBegin = 5
		local xInterval = (viewSize.width - 2 * xBegin - columns * cellSize.width) / (columns - 1)
		local rows = math.ceil((tonum(game.role.partners[self.index]) ~= 0 and #self.heroFilter:getResult() + 1 or #self.heroFilter:getResult()) / columns)
		for index = (rows - cellIndex - 1) * columns + 1, columns * (rows - cellIndex) do
			local hero = self.heroFilter:getResult()[tonum(game.role.partners[self.index]) ~= 0 and index - 1 or index]
			local nativeIndex = index - (rows - cellIndex - 1) * columns
			local cellNode = display.newNode()
			cellNode:size(cellSize)

			if hero then
				local heroCell = HeroListCell.new({ type = hero.type, level = hero.level, 
					wakeLevel = hero.wakeLevel, star = hero.star,
					evolutionCount = hero.evolutionCount, priority = self.priority,
					parent = viewBg,
					callback = function()
						sendChooseRequest(hero)
					end
				}):getLayer()
				heroCell:anch(0, 0):addTo(cellNode)

				local cellSize = heroCell:getContentSize()

				-- 属性
				local totalAttrs = hero:getTotalAttrValues()
				local attrNames = { "atk", "def", "hp" }
				for index, name in ipairs(attrNames) do
					-- atk
					display.newSprite(GlobalRes .. string.format("attr_%s.png", name))
						:anch(0, 0.5):pos(305, 20 + (index - 1) * 25):addTo(heroCell)
					ui.newTTFLabel({text = math.floor(totalAttrs[name]), size = 20,
						color = uihelper.hex2rgb("#333333") })
						:anch(0, 0.5):pos(335, 20 + (index - 1) * 25):addTo(heroCell)
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

				if game.role:isActiveRelation(hero.type) then
					display.newSprite(HeroRes .. "tag_relation.png")
						:anch(1, 1):pos(cellSize.width + 1, cellSize.height - 4):addTo(heroCell)
				end
			elseif tonum(game.role.partners[self.index]) ~= 0 and index == 1 then
				local noneBtn = DGBtn:new(HeroRes, {"cell_bar.png"},
					{	
						parent = viewBg,
						priority = self.priority,
						callback = function()
							sendChooseRequest(hero)
						end,
					}):getLayer()
				local cellSize = noneBtn:getContentSize()

				local emptyIcon = display.newSprite(GlobalRes .. "frame_empty.png"):anch(0, 0):pos(25, 10):addTo(noneBtn)
				display.newSprite(GlobalRes .. "frame_bottom.png"):addTo(emptyIcon, -1)
					:pos(emptyIcon:getContentSize().width / 2, emptyIcon:getContentSize().height / 2)

				ui.newTTFLabel({text = "不选择小伙伴", size = 36, color = display.COLOR_DARKYELLOW })
					:anch(0, 0.5):pos(150, cellSize.height / 2):addTo(noneBtn)

				local professionBg = display.newSprite(HeroRes .. "profession_bg.png")
				professionBg:anch(0, 1):pos(6, cellSize.height - 6):addTo(noneBtn)

				noneBtn:anch(0, 0):addTo(cellNode)
			end

			cellNode:anch(0, 0):pos(xBegin + (cellSize.width + xInterval) * (nativeIndex - 1), 10)
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
			result = math.ceil((tonum(game.role.partners[self.index]) ~= 0 and #self.heroFilter:getResult() + 1 or #self.heroFilter:getResult()) / columns)
		end

		return result
	end)

	local heroTableView = LuaTableView:createWithHandler(viewHandler, viewSize)
	heroTableView:setBounceable(true)
	heroTableView:setTouchPriority(self.priority - 1)
	heroTableView:setPosition(ccp(0, 5))
	viewBg:addChild(heroTableView)

	self.heroFilter:addEventListener("filter", function(event) heroTableView:reloadData() end)
end

function HeroPartnerChooseLayer:getLayer()
	return self.mask:getLayer()
end

return HeroPartnerChooseLayer