local EquipRes = "resource/ui_rc/equip/"
local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"

local Hero = require("datamodel.Hero")

local EquipChooseLayer = class("EquipChooseLayer", function(params)
	return display.newLayer(GlobalRes .. "inner_bg.png")
end)

function EquipChooseLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -132
	self.slot = params.slot
	self.equipSlot = params.equipSlot
	self.equipId = params.equipId
	self.equip = self.equipId and game.role.equips[self.equipId] or nil
	self.callback = params.callback
	self.hero = params.hero
	self.size = self:getContentSize()

	self:anch(0, 0):pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1, bg = HomeRes .. "home.jpg"})
	

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			priority = self.priority,
			callback = function()		
				if self.callback then 
					self.callback()
				end
				self.mask:remove()
			end,
		}):getLayer()
	closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self)
	

	self:initEquipsData()
	self:listEquips()

	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority})
	:anch(0,1):pos(0,display.height):addTo(self)
end

function EquipChooseLayer:onEnter()
	self:checkGuide()
end

function EquipChooseLayer:checkGuide(remove)
	game:addGuideNode({node = self.guideBtn, remove = remove,
		guideIds = {1277}
	})
	self.equipTableView:setTouchEnabled(not game:hasGuide())
end

function EquipChooseLayer:onExit()
	self:checkGuide(true)
end

function EquipChooseLayer:initEquipsData()
	self.equips = {}
	for _, equip in pairs(game.role.equips) do
		if equip.csvData.equipSlot == self.equipSlot and equip ~= self.equip then
			table.insert(self.equips, equip)
		end
	end

	table.sort(self.equips, function(a, b) 
		local factorA = (a.masterId ~= 0 and 0 or 1) * 1000000 + (self:isRelation(a.type) and 1 or 0) * 100000 + a.csvData.star * 10000 + a.evolCount * 10 + a.level
		local factorB = (b.masterId ~= 0 and 0 or 1) * 1000000 + (self:isRelation(b.type) and 1 or 0) * 100000 + b.csvData.star * 10000 + b.evolCount * 10 + b.level
		return factorA > factorB
	end)
end

function EquipChooseLayer:isRelation(equipType)
	if not self.hero then return false end
	for count, relation in ipairs(self.hero.unitData.relation) do
		if relation[1] == 2 and table.find(relation[2], equipType) then
			return true
		end
	end
	return false
end

function EquipChooseLayer:listEquips()
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end

	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.size):addTo(self)

	local infoBg = display.newSprite(GlobalRes .. "label_bg.png"):anch(0,1):pos(40, self.size.height-15):addTo(self.mainLayer)
	ui.newTTFLabel({text = string.format("拥有装备：%d", #self.equips), size = 18})
		:anch(0, 0.5):pos(10, infoBg:getContentSize().height/2):addTo(infoBg)

	local cellSize = CCSizeMake(416, 134)
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
		local rows = math.ceil((self.equip and #self.equips + 1 or #self.equips) / columns)
		for index = (rows - cellIndex - 1) * columns + 1, columns * (rows - cellIndex) do
			local equip = self.equips[(self.equip and index - 1  or index)]
			local nativeIndex = index - (rows - cellIndex - 1) * columns
			local cellNode = display.newNode()
			cellNode:size(cellSize)
			
			if equip or (self.equip and index == 1) then
				local function sendRequest()
					local oldAttrs = Hero.sGetEquipAttrs(self.slot)
					local bin = pb.encode("SimpleEvent", {roleId = game.role.id, param1 = self.slot, param2 = equip and equip.id or 0, param3 = self.equipSlot })
					game:sendData(actionCodes.EquipChooseRequest, bin, #bin)
				    game:addEventListener(actionModules[actionCodes.EquipChooseResponse], function(event)
				    	if self.callback then 
							self.callback()
						end
						uihelper.sShowAttrsChange({curAttrs = Hero.sGetEquipAttrs(self.slot), oldAttrs = oldAttrs, offset = ccp(95, 115)})
						self.mask:remove()
						return "__REMOVE__"
				    end)
				end
				local equipCell
				equipCell = EquipList.new({equip = equip, priority = self.priority - 1, parent = viewBg, callback = sendRequest,
					btnData1 = {
						text = "穿戴",
						callback = function() 
							game:dispatchEvent({name = "btnClicked", data = equipCell}) 
							sendRequest() 
						end,
					},
				})
				equipCell:anch(0, 0):pos(0, 0):addTo(cellNode)
				if index == 1 then
					self.guideBtn = equipCell
				end
				if equip and self:isRelation(equip.type) then
					display.newSprite(HeroRes .. "tag_relation.png")
						:anch(1, 1):pos(equipCell:getContentSize().width + 1, equipCell:getContentSize().height):addTo(equipCell)
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
			result = math.ceil((self.equip and #self.equips + 1 or #self.equips) / columns)
		end

		return result
	end)

	self.equipTableView = LuaTableView:createWithHandler(viewHandler, viewSize)
	self.equipTableView:setBounceable(true)
	self.equipTableView:setTouchPriority(self.priority - 2)
	self.equipTableView:setPosition(ccp(0, 5))
	viewBg:addChild(self.equipTableView)
end

function EquipChooseLayer:getLayer()
	return self.mask:getLayer()
end

return EquipChooseLayer