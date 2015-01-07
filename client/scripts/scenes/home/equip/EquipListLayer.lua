local EquipRes = "resource/ui_rc/equip/"
local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"


local EquipLevelUp = import(".EquipLevelUp")
local EquipPopLayer = import(".EquipPopLayer")
local EquipEvolutionLayer = import(".EquipEvolutionLayer")

local EquipListLayer = class("EquipListLayer", function(params)
	return display.newLayer()
end)

function EquipListLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -132
	self:size(869, 554)
	self.size = self:getContentSize()

	

	self:listEquips()
end

function EquipListLayer:listEquips()
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end

	self.equips = table.values(game.role.equips)
	table.sort(self.equips, function(a, b) 
		local factorA = (a.masterId ~= 0 and 1 or 0) * 1000000 + a.csvData.star * 100000 + a.evolCount * 10 + a.level
		local factorB = (b.masterId ~= 0 and 1 or 0) * 1000000 + b.csvData.star * 100000 + b.evolCount * 10 + b.level
		return factorA > factorB
	end)

	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.size):addTo(self)

	local infoBg = display.newSprite(GlobalRes .. "label_bg.png"):anch(0,1):pos(18, self.size.height+3):addTo(self.mainLayer)
	ui.newTTFLabel({text = string.format("拥有装备：%d", #self.equips), size = 18})
		:anch(0, 0.5):pos(10, infoBg:getContentSize().height/2):addTo(infoBg)

	local cellSize = CCSizeMake(416, 134)
	local columns = 2

	local viewBg = display.newLayer()
	viewBg:size(850, 474)
	local viewSize = CCSizeMake(viewBg:getContentSize().width, viewBg:getContentSize().height)
	viewBg:anch(0.5, 0):pos(self.size.width / 2, 20):addTo(self.mainLayer)

	local equipTableView

	local function createCellNode(parentNode, cellIndex)
		parentNode:removeAllChildren()
		parentNode:setContentSize(CCSizeMake(viewSize.width, cellSize.height + 10))

		local xBegin = 5
		local xInterval = (viewSize.width - 2 * xBegin - columns * cellSize.width) / (columns - 1)
		local rows = math.ceil(#self.equips / columns)
		for index = (rows - cellIndex - 1) * columns + 1, columns * (rows - cellIndex) do
			local equip = self.equips[index]
			local nativeIndex = index - (rows - cellIndex - 1) * columns
			local cellNode = display.newNode()
			cellNode:size(cellSize)

			if equip then
				local params = {
					equip = equip, 
					priority = self.priority-10, 
					callback = function(flag)
						if flag == 1 then
							self:listEquips()
							return
						end
						local offset = equipTableView:getContentOffset()
						equipTableView:reloadData()
						equipTableView:setBounceable(false)
						equipTableView:setContentOffset(offset, false)
						equipTableView:setBounceable(true) 
					end, 
					flag = 2}
				EquipList.new(
				{
					equip = equip, priority = self.priority-2,
					parent = viewBg, 
					callback = function() 
						local equipPopLayer = EquipPopLayer.new(params)
						equipPopLayer:getLayer():addTo(display.getRunningScene())
					end,
					btnData1 = {
						text = "强化",
						callback = function()
							local equipLevelUp = EquipLevelUp.new(params)
							equipLevelUp:getLayer():addTo(display.getRunningScene())
						end,
					},
					btnData2 = {
						text = "炼化",
						callback = function()
							local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
							if roleInfo.equipEvolOpen < 0 then
								DGMsgBox.new({text = string.format("玩家%d级开放装备炼化", math.abs(roleInfo.equipEvolOpen)), type = 1})
								return
							end
							local equipEvolutionLayer = EquipEvolutionLayer.new(params)
							equipEvolutionLayer:getLayer():addTo(display.getRunningScene())
						end,
					}
				}):anch(0, 0):pos(0, 0):addTo(cellNode)
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
			result = math.ceil(#self.equips / columns)
		end

		return result
	end)

	equipTableView = LuaTableView:createWithHandler(viewHandler, viewSize)
	equipTableView:setBounceable(true)
	equipTableView:setTouchPriority(self.priority - 5)
	equipTableView:setPosition(ccp(0, 5))
	viewBg:addChild(equipTableView)
end

function EquipListLayer:onExit()
	
end

return EquipListLayer