local HeroRes = "resource/ui_rc/hero/"
local GlobalRes = "resource/ui_rc/global/"

local FilterLogic = import(".FilterLogic")
local FilterBar = import(".FilterBar")
local HeroInfoLayer = import(".HeroInfoLayer")

local IntensifyHeroChooseLayer = class("IntensifyHeroChooseLayer", function(params)
	return display.newLayer(GlobalRes .. "bottom_bg.png")
end)

function IntensifyHeroChooseLayer:ctor(params)
	params = params or {}
	self.priority = params.priority or -132
	self.parent   = params.parent

	-- 遮罩层
	self:anch(0, 0):pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self, priority = self.priority - 2})

	self.mainLayer = display.newLayer(GlobalRes .. "inner_bg.png")
	self.mainLayer:anch(0.5, 0.5):pos(self:getContentSize().width / 2,
		self:getContentSize().height / 2):addTo(self)
	self.size = self.mainLayer:getContentSize()

	self.heros = table.values(game.role.heros)
	table.sort(self.heros, function(a, b) 
		local unitDataA = unitCsv:getUnitByType(a.type)
		local unitDataB = unitCsv:getUnitByType(b.type)
		local factorA = a.choose * 1000000 + (a.master > 0 and 1 or 0) * 100000 + a.star * 10000 + a.evolutionCount * 1000 + a.level
		local factorB = b.choose * 1000000 + (b.master > 0 and 1 or 0) * 100000 + b.star * 10000 + b.evolutionCount * 1000 + b.level
		return factorA == factorB and (a.type < b.type) or (factorA > factorB)
	end)

	local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
	local numberBg = display.newSprite(HeroRes .. "total_bg.png")
	numberBg:anch(0, 1):pos(8, self.size.height - 7):addTo(self.mainLayer)
	ui.newTTFLabelWithStroke({ text = "拥有武将: "..table.nums(self.heros) .. " / " .. roleInfo.bagHeroLimit, size = 24, color = display.COLOR_YELLOW })
		:anch(0, 0.5):pos(5, numberBg:getContentSize().height / 2):addTo(numberBg)

	self.heroFilter = FilterLogic.new({ heros = self.heros })
	local filterBar = FilterBar.new({ dataSource = self.heroFilter, priority = self.priority - 10})
	filterBar:anch(0, 1):pos(320, self.size.height - 3):addTo(self.mainLayer, 100)

	self:listHeros()
	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
	{	
		touchScale = 1.5,
		priority = self.priority -3,
		callback = function()
			self:getLayer():removeSelf()
		end,
	}):getLayer()
	closeBtn:anch(1, 1):pos((display.width + 960) / 2, display.height):addTo(self:getLayer())

	self:checkGuide()

	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority})
	:anch(0,1):pos(0,display.height):addTo(self)
end

function IntensifyHeroChooseLayer:listHeros()
	local cellSize = CCSizeMake(415, 132)
	local columns = 2

	local viewBg = display.newSprite(HeroRes .. "view_bg.png")
	local viewSize = CCSizeMake(viewBg:getContentSize().width, viewBg:getContentSize().height - 10)
	viewBg:anch(0.5, 0):pos(self.size.width / 2, 20):addTo(self.mainLayer)

	local function createCellNode(parentNode, cellIndex)
		parentNode:removeAllChildren()
		parentNode:setContentSize(CCSizeMake(viewSize.width, cellSize.height + 10))

		local xBegin = 5
		local xInterval = (viewSize.width - 2 * xBegin - columns * cellSize.width) / (columns - 1)
		local rows = math.ceil(#self.heroFilter:getResult() / columns)
		for index = (rows - cellIndex - 1) * columns + 1, columns * (rows - cellIndex) do
			local hero = self.heroFilter:getResult()[index]
			local nativeIndex = index - (rows - cellIndex - 1) * columns
			local cellNode = display.newNode()
			cellNode:size(cellSize)

			if hero then
				local heroCell = HeroListCell.new({ type = hero.type, level = hero.level, wakeLevel = hero.wakeLevel, star = hero.star,
					evolutionCount = hero.evolutionCount, priority = self.priority -5,
					parent = viewBg,
					callback = function()
						
						-- if self.parent and self.parent.callType == 1 then --强化
							self.parent.mainHeroId = hero.id
							self.parent.fodderHeroIds = {}
							self.parent:initContentLeft()
							self.parent:initContentRight()
							self:getLayer():removeSelf()
						-- else
						-- 	local infoLayer = HeroInfoLayer.new({ heroId = hero.id, priority = self.priority - 10 })
						-- 	infoLayer:getLayer():addTo(display.getRunningScene())
						-- end
					end
				}):getLayer()
				heroCell:anch(0, 0):addTo(cellNode)

				local cellSize = heroCell:getContentSize()

				-- 属性
				local totalAttrs = hero:getTotalAttrValues()
				local attrNames = { "atk", "def", "hp" }
				for index, name in ipairs(attrNames) do
					-- atk
					display.newSprite(HeroRes .. string.format("attr_%s.png", name))
						:anch(0, 0.5):pos(305, 20 + (index - 1) * 25):addTo(heroCell)
					ui.newTTFLabelWithStroke({text = math.floor(totalAttrs[name]), size = 20 })
						:anch(0, 0.5):pos(335, 20 + (index - 1) * 25):addTo(heroCell)
				end

				-- skill
				local skillIds = hero:getAllSkillIds()
				local bg = display.newSprite(HeroRes .. "skill_icon_bg.png")
				bg:anch(0, 0):pos(145, 15):addTo(heroCell)

				local bgSize = bg:getContentSize()
				if skillIds["1"] then
					local skillData = skillCsv:getSkillById(skillIds["1"])					
					if skillData.icon ~= "" then
						display.newSprite(skillData.icon):scale(1 / 3)
							:pos(bgSize.width / 2, bgSize.height / 2):addTo(bg)
					end
				end

				for index = 2, 4 do
					local bg = display.newSprite(HeroRes .. "skill_icon_bg.png")
					bg:anch(0, 0):pos(145 + (index - 1) * 40, 15):addTo(heroCell)

					local bgSize = bg:getContentSize()
					if skillIds[tostring(index)] then
						local skillData = skillPassiveCsv:getPassiveSkillById(math.abs(skillIds[tostring(index)]))					
						if skillData and skillData.icon ~= "" then
							local skillIcon = display.newSprite(skillData.icon):scale(1 / 3)
							skillIcon:pos(bgSize.width / 2, bgSize.height / 2):addTo(bg)
							if skillIds[tostring(index)] < 0 then
								skillIcon:setColor(ccc3(125, 125, 125))
							end
						end
					end
				end

				if hero.choose == 1 then
					display.newSprite(HeroRes .. "tag_selected.png")
						:anch(1, 1):pos(cellSize.width, cellSize.height - 5):addTo(heroCell)
				end

				if hero.master > 0 then
					display.newSprite(HeroRes .. "tag_assistant.png")
						:anch(1, 1):pos(cellSize.width, cellSize.height - 5):addTo(heroCell)
				end
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
			result = math.ceil(#self.heroFilter:getResult() / columns)
		end

		return result
	end)

	local heroTableView = LuaTableView:createWithHandler(viewHandler, viewSize)
	heroTableView:setBounceable(true)
	heroTableView:setTouchPriority(self.priority - 12)
	heroTableView:setPosition(ccp(0, 5))
	viewBg:addChild(heroTableView)

	self.heroFilter:addEventListener("filter", function(event) heroTableView:reloadData() end)
end

function IntensifyHeroChooseLayer:checkGuide()
	
end

function IntensifyHeroChooseLayer:getLayer()
	return self.mask:getLayer()
end

return IntensifyHeroChooseLayer