local HeroRes = "resource/ui_rc/hero/"
local GlobalRes = "resource/ui_rc/global/"
local MapRes  = HeroRes.."map/"

local FilterLogic = import(".FilterLogic")
local FilterBar = import(".FilterBar")
local HeroInfoLayer = import(".HeroInfoLayer")

local HeroListLayer = class("HeroListLayer", function(params)
	return display.newLayer()
end)

function HeroListLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -132
	self.parent   = params.parent
	self:size(869, 554)
	self.size = self:getContentSize()
	self:setNodeEventEnabled(true)

	self:reloadData()
	self:listHeros()
end

function HeroListLayer:reloadData()
	self.heros = table.values(game.role.heros)
	table.sort(self.heros, function(a, b) 
		local unitDataA = unitCsv:getUnitByType(a.type)
		local unitDataB = unitCsv:getUnitByType(b.type)
		local factorA = a.choose * 1000000 + (a.master > 0 and 1 or 0) * 100000 + a.star * 10000 + a.evolutionCount * 1000 + a.level
		local factorB = b.choose * 1000000 + (b.master > 0 and 1 or 0) * 100000 + b.star * 10000 + b.evolutionCount * 1000 + b.level
		return factorA == factorB and (a.type > b.type) or (factorA > factorB)
	end)

	if self:getChildByTag(100) then
		self:removeChildByTag(100, true)
	end

	self.heroFilter = FilterLogic.new({ heros = self.heros })
	self.heroFilter:addEventListener("filter", function(event) self.heroTableView:reloadData() end)
	local filterBar = FilterBar.new({ dataSource = self.heroFilter, priority = self.priority - 10})
	filterBar:anch(0, 1):pos(292, self.size.height):addTo(self, 100, 100)
end

--拥有武将数量：
function HeroListLayer:showMyHeroNums()
	local infoBg = display.newSprite(GlobalRes .. "label_bg.png"):anch(0, 1)
	:pos(18, self.size.height + 3)
	:addTo(self.mainLayer)
	local xPos, yPos = 8, infoBg:getContentSize().height/2
	local text = ui.newTTFLabel({text = "拥有武将：", size = 20})
	text:anch(0, 0.5):pos(xPos, yPos):addTo(infoBg)
	xPos = xPos + text:getContentSize().width

	local heroNums = table.nums(self.heros)
	text = ui.newTTFLabel({text = heroNums, size = 20, color = heroNums > 0 and uihelper.hex2rgb("#7ce810") or display.COLOR_RED })
	text:anch(0, 0.5):pos(xPos, yPos):addTo(infoBg)
	xPos = xPos + text:getContentSize().width
end

function HeroListLayer:listHeros()
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end

	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.size):addTo(self)

	self:showMyHeroNums()

	local cellSize = CCSizeMake(415, 132)
	local columns = 2

	local viewBg = display.newLayer()
	viewBg:size(850, 474)
	local viewSize = CCSizeMake(viewBg:getContentSize().width, viewBg:getContentSize().height)
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
					evolutionCount = hero.evolutionCount, priority = self.priority,
					parent = viewBg,
					callback = function()
						local infoLayer = HeroInfoLayer.new({ heroId = hero.id, priority = self.priority - 10, parent = self,
							closeCallback = function ()
								local offset = self.heroTableView:getContentOffset()
								self:reloadData()
								self:listHeros()
								self.heroTableView:setBounceable(false)
								self.heroTableView:setContentOffset(offset, false)
								self.heroTableView:setBounceable(true) 
								self:setVisible(true)
							end})
						infoLayer:getLayer():addTo(display.getRunningScene())
						self:setVisible(false)
					end
				}):getLayer()
				heroCell:anch(0, 0):addTo(cellNode)

				local cellSize = heroCell:getContentSize()

				-- -- 属性
				-- local totalAttrs = hero:getTotalAttrValues()
				-- local attrNames = { "atk", "def", "hp" }
				-- for index, name in ipairs(attrNames) do
				-- 	-- atk
				-- 	display.newSprite(HeroRes .. string.format("attr_%s.png", name))
				-- 		:anch(0, 0.5):pos(305, 20 + (index - 1) * 25):addTo(heroCell)
				-- 	ui.newTTFLabel({text = math.floor(totalAttrs[name]), size = 20, 
				-- 		color = uihelper.hex2rgb("#333333") })
				-- 		:anch(0, 0.5):pos(335, 20 + (index - 1) * 25):addTo(heroCell)
				-- end

				-- skill
				local skillIds = hero:getAllSkillIds()
				if skillIds["1"] then
					local skillData = skillCsv:getSkillById(skillIds["1"])					
					if skillData.icon ~= "" then
						local skillIcon = display.newSprite(skillData.icon)
						skillIcon:scale(36/skillIcon:getContentSize().width):anch(0, 0):pos(150, 15):addTo(heroCell)
					end
				end

				for index = 2, 4 do
					if skillIds[tostring(index)] then
						local skillData = skillPassiveCsv:getPassiveSkillById(math.abs(skillIds[tostring(index)]))					
						if skillData and skillData.icon ~= "" then
							local skillIcon = display.newSprite(skillData.icon)
							skillIcon:scale(36/skillIcon:getContentSize().width):anch(0, 0):pos(150 + (index - 1) * 50, 15):addTo(heroCell)
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

				if table.find(game.role.partners, hero.id) then
					display.newSprite(HeroRes .. "tag_partner.png")
						:anch(1, 1):pos(cellSize.width, cellSize.height - 5):addTo(heroCell)
				end

				if hero:canEvolution() or hero:canBattleSoul() or hero:canStarUp() or hero:canSkillUp() then
					uihelper.newMsgTag(heroCell, ccp(-5, 0))
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

	self.heroTableView = LuaTableView:createWithHandler(viewHandler, viewSize)
	self.heroTableView:setBounceable(true)
	self.heroTableView:setTouchPriority(self.priority - 5)
	self.heroTableView:setPosition(ccp(0, 5))
	viewBg:addChild(self.heroTableView)
end

function HeroListLayer:onExit()
	-- game.role:removeEventListener("after_intensify", self.afterIntensifyHandler)
end

return HeroListLayer