local EquipRes = "resource/ui_rc/equip/"
local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"

local ItemSourceLayer = require("scenes.home.ItemSourceLayer")
local EquipPopLayer = import(".EquipPopLayer")

local EquipFragmentsLayer = class("EquipFragmentsLayer", function(params)
	return display.newLayer()
end)

function EquipFragmentsLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -132
	self:size(869, 554)
	self.size = self:getContentSize()

	
	self:reloadData()
	self:listEquipFragments()
end

function EquipFragmentsLayer:reloadData()
	self.fragments = {}
	for id, num in pairs(game.role.equipFragments) do
		if num > 0 then
			table.insert(self.fragments, { id = id, num = num })
		end
	end
	
	table.sort(self.fragments, function(a, b)
		local csvDataA = equipCsv:getDataByType(a.id - Equip2ItemIndex.FragmentTypeIndex)
		local csvDataB = equipCsv:getDataByType(b.id - Equip2ItemIndex.FragmentTypeIndex)
		local factorA = (a.num >= csvDataA.composeNum and 100000 or 0) + csvDataA.star * 10000 + a.num
		local factorB = (b.num >= csvDataB.composeNum and 100000 or 0) + csvDataB.star * 10000 + b.num
		return factorA > factorB  
	end)
end

function EquipFragmentsLayer:listEquipFragments()
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end

	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.size):addTo(self)

	if table.nums(self.fragments) < 1 then
		local showSp = display.newSprite(HeroRes.."frag/frag_show_no.png"):pos(230, 430):addTo(self.mainLayer)
		local wordHave = ui.newTTFLabel({ text = "暂无碎片！", size = 28, color = display.COLOR_DARKBROWN})
		:anch(0.5, 0.5)
		:pos(showSp:getContentSize().width/2, showSp:getContentSize().height/2)
		:addTo(showSp)
		return
	end

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
		local rows = math.ceil(#self.fragments / columns)
		for index = (rows - cellIndex - 1) * columns + 1, columns * (rows - cellIndex) do
			local equipFragment = self.fragments[index]
			local nativeIndex = index - (rows - cellIndex - 1) * columns
			local cellNode = display.newNode()
			cellNode:size(cellSize)

			if equipFragment then 
				local csvData = equipCsv:getDataByType(equipFragment.id - Equip2ItemIndex.FragmentTypeIndex)
				local canCompose = equipFragment.num >= csvData.composeNum
				local bg = DGBtn:new(EquipRes, {"bg_weapon_item.png"},{
						priority = self.priority - 1,
						callback = function()
							if canCompose then
								local bin = pb.encode("SimpleEvent", {roleId = game.role.id, param1 = equipFragment.id})
								game:sendData(actionCodes.EquipFragmentComposeRequest, bin, #bin)
								loadingShow()
								game:addEventListener(actionModules[actionCodes.EquipFragmentComposeResponse], function(event)
									loadingHide()
									local msg = pb.decode("SimpleEvent", event.data)

									if equipFragment.num == csvData.composeNum then
										game.role.equipFragments[equipFragment.id] = nil
									else
										game.role.equipFragments[equipFragment.id] = equipFragment.num - csvData.composeNum
									end

									self:reloadData()
									self:listEquipFragments()

									game.role:dispatchEvent({ name = "notifyNewMessage", type = "composeEquipFragment" })
									game.role:updateNewMsgTag()

									DGMsgBox.new({ type = 1, 
										text = string.format("恭喜获得[color=ff00ff00]%s[/color]装备！", csvData.name)})
									return "__REMOVE__"
								end)
							else
								local sourceLayer = ItemSourceLayer.new({ 
									priority = self.priority - 300, 
									itemId = equipFragment.id, 
									closeCallback = function()
										local offset = equipTableView:getContentOffset()
										self:reloadData()
										equipTableView:reloadData()
										equipTableView:setContentOffset(offset, false)
									end })
								sourceLayer:getLayer():addTo(display.getRunningScene())
							end
						end,
					}):getLayer():anch(0, 0):pos(0, 0):addTo(cellNode)
				local bgSize = bg:getContentSize()
				local icon = ItemIcon.new({
					itemId = equipFragment.id, 
					priority = self.priority - 2,
					callback = function() 
						local layer = EquipPopLayer.new({type = equipFragment.id - Equip2ItemIndex.FragmentTypeIndex, priority = self.priority-10, flag = 3})
						layer:getLayer():addTo(display.getRunningScene())
					end,
				}):getLayer()
				icon:scale(0.8):anch(0, 0):pos(18, 12):addTo(bg)
				
				-- 经验条
				local expSlot = display.newSprite( HeroRes .. "growth/exp_long_bg.png")
				expSlot:anch(0, 0):pos(110, 40):addTo(bg)
				local expProgress = display.newProgressTimer(HeroRes .. "growth/exp_long_fg.png", display.PROGRESS_TIMER_BAR)
				expProgress:setMidpoint(ccp(0, 0.5))
				expProgress:setBarChangeRate(ccp(1,0))
				expProgress:setPercentage( equipFragment.num / csvData.composeNum * 100)
				
				expProgress:pos(expSlot:getContentSize().width/2, expSlot:getContentSize().height/2):addTo(expSlot)
				
				ui.newTTFLabel({text = canCompose and "可召唤" or string.format("%d / %d", equipFragment.num, csvData.composeNum), size = 18})
					:anch(0.5,0.5):pos(expSlot:getContentSize().width/2, expSlot:getContentSize().height/2):addTo(expSlot)
				--名称
				local text = ui.newTTFLabelWithStroke({text = csvData.name .. "-碎片", size = 22, font = ChineseFont, strokeColor = uihelper.hex2rgb("#1a1a1a")})
				text:anch(0, 0):pos(18, 102):addTo(bg)
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
			result = math.ceil(#self.fragments / columns)
		end

		return result
	end)

	equipTableView = LuaTableView:createWithHandler(viewHandler, viewSize)
	equipTableView:setBounceable(true)
	equipTableView:setTouchPriority(self.priority - 5)
	equipTableView:setPosition(ccp(0, 5))
	viewBg:addChild(equipTableView)
end

function EquipFragmentsLayer:onExit()
	
end

return EquipFragmentsLayer