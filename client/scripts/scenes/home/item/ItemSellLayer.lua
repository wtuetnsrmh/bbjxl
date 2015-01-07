--
-- Author: yujiuhe
-- Date: 2014-08-26 21:14:13
--
local EquipRes = "resource/ui_rc/equip/"
local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"
local HomeRes = "resource/ui_rc/home/"
local TopBarLayer = require("scenes.TopBarLayer")

local ItemSellLayer = class("ItemSellLayer", function()
	return display.newLayer(GlobalRes.."inner_bg.png")
end)

function ItemSellLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -130
	self.callback = params.callback
	self.size = self:getContentSize()

	-- 遮罩层
	self:anch(0, 0):pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self , priority = self.priority + 1, bg = HomeRes .. "home.jpg"})

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
				if self.callback then
					self.callback()
				end
				self:getLayer():removeSelf()
			end,
		}):getLayer()
	-- closeBtn:anch(1, 1):pos((display.width + 960) / 2, display.height):addTo(self:getLayer())
	closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self,100)

	local rightTab = display.newSprite(GlobalRes .. "tab_selected.png"):anch(0, 0.5)
	rightTab:pos(self:getContentSize().width - 15, 470):addTo(self, -1)
	local btnSize = rightTab:getContentSize()
	ui.newTTFLabelWithStroke({ text = "出售", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), size = 26, font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(rightTab)
	display.newSprite(GlobalRes .. "tab_arrow.png"):pos(self.size.width - 15, 470):addTo(self)

	self:initItemsData()
	self:listItems()

	local layer  = TopBarLayer.new({priority = self.priority})
	layer:anch(0,1):pos(0,display.height):addTo(self)
end

function ItemSellLayer:initItemsData()
	self.items = {}
	self.sellItems = {}
	local itemIds = table.keys(game.role.items)
	for _,itemId in pairs(itemIds) do
		local itemData = itemCsv:getItemById(itemId)
		if itemCsv:isMateriel(itemData.type) then
			table.insert(self.items, itemId)
		end
	end

	table.sort(self.items, function(a, b)
		local itemDataA = itemCsv:getItemById(a)
		local itemDataB = itemCsv:getItemById(b)

		local factorA = (itemDataA.type == ItemTypeId.Useless and 1 or 0) * 10000 + a
		local factorB = (itemDataB.type == ItemTypeId.Useless and 1 or 0) * 10000 + b
		return factorA > factorB
	end)
end

function ItemSellLayer:listItems()
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end

	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.size):addTo(self)

	local numberBg = display.newSprite(GlobalRes .. "label_bg.png")
	numberBg:anch(0, 1):pos(35, self.size.height - 15):addTo(self)
	local label = ui.newTTFLabel({ text = "材料: ", size = 20 })
	label:anch(0, 0.5):pos(5, numberBg:getContentSize().height/2):addTo(numberBg)
	ui.newTTFLabel({text = table.nums(self.items), size = 20, color = display.COLOR_GREEN })
		:anch(0, 0.5):pos(5 + label:getContentSize().width, numberBg:getContentSize().height/2):addTo(numberBg)
	
	local cellSize = CCSizeMake(409, 136)
	local columns = 2

	local viewSize = CCSizeMake(850, 395)
	local viewLayer = display.newLayer()
	viewLayer:size(viewSize):anch(0.5, 0):pos(self.size.width / 2, 120):addTo(self.mainLayer)

	local resultLayer = self:showResultLayer()
	resultLayer:anch(0.5, 0):pos(self.size.width / 2, 10):addTo(self.mainLayer)

	local itemTableView

	local function createCellNode(parentNode, cellIndex)
		parentNode:removeAllChildren()
		parentNode:setContentSize(CCSizeMake(viewSize.width, cellSize.height + 10))

		local xBegin = 5
		local xInterval = (viewSize.width - 2 * xBegin - columns * cellSize.width) / (columns - 1)
		local rows = math.ceil(#self.items / columns)
		for index = (rows - cellIndex - 1) * columns + 1, columns * (rows - cellIndex) do
			local itemId = self.items[index]
			local nativeIndex = index - (rows - cellIndex - 1) * columns
			local cellNode = display.newNode()
			cellNode:size(cellSize)

			if itemId then
				local checkFrame = display.newSprite(HeroRes .. "check_frame.png"):anch(0.5, 0.5)
				local bg = DGBtn:new( HomeRes, {"item/cell_bg.png"}, {
					priority = self.priority - 1,
					parent = viewLayer, 
					callback =  function()	
						if not self.sellItems[itemId] then
							self.sellItems[itemId] = true
							display.newSprite(HeroRes .. "checked.png"):addTo(checkFrame, 0, 100)
								:pos(checkFrame:getContentSize().width / 2, checkFrame:getContentSize().height / 2)
						else
							self.sellItems[itemId] = nil
							checkFrame:removeChildByTag(100)
						end
						self:updateResultLabel()
					end}):getLayer():anch(0, 0):pos(0, 0):addTo(cellNode)

				local itemFrame = ItemIcon.new({ itemId = itemId }) 
					
				itemFrame:getLayer():scale(0.8):anch(0,0):pos(20, 10):addTo(bg)
				checkFrame:pos(cellSize.width - 80, 60):addTo(cellNode)

				if self.sellItems[itemId] then
					display.newSprite(HeroRes .. "checked.png"):addTo(checkFrame, 0, 100)
						:pos(checkFrame:getContentSize().width / 2, checkFrame:getContentSize().height / 2)
				end
		
				-- 数量
				ui.newTTFLabel({text = string.format("数量: %d", game.role.items[itemId].count), size = 18, color = uihelper.hex2rgb("#533a27"), strokerColor = display.COLOR_BLACK, strokeSize = 1 })
				:anch(0,0.5):pos(320, bg:getContentSize().height - 20):addTo(bg)

				-- 名字
				local itemData = itemCsv:getItemById(itemId)
				ui.newTTFLabelWithStroke({text = itemData.name, size = 24, color = display.COLOR_WHITE, font = ChineseFont, strokeColor = display.COLOR_BUTTON_STROKE, strokeSize = 2 })
					:anch(0,0.5):pos(15, bg:getContentSize().height - 20):addTo(bg)

				--银币
				local money = display.newSprite(GlobalRes .. "yinbi_big.png"):anch(0, 0):pos(125, 38):addTo(bg)
				local path = "resource/ui_rc/battle/font/num_b.fnt"
				local itemData = itemCsv:getItemById(itemId)
				local count = game.role.items[itemId].count
				local sellMoney = 0
				if itemData then
					sellMoney = itemData.sellMoney * count
				end
				ui.newBMFontLabel({ text =string.format("%d", sellMoney), font = path}):anch(0, 0):scale(0.8)
					:pos(money:getContentSize().width + money:getPositionX()+5 , 40):addTo(bg)
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
			result = math.ceil(#self.items / columns)
		end

		return result
	end)

	itemTableView = LuaTableView:createWithHandler(viewHandler, viewSize)
	itemTableView:setBounceable(true)
	itemTableView:setTouchPriority(self.priority - 2)
	itemTableView:setPosition(ccp(0, 5))
	viewLayer:addChild(itemTableView)
end


function ItemSellLayer:updateResultLabel()
	local sellMoney = 0
	for itemId, value in pairs(self.sellItems) do
		local itemData = itemCsv:getItemById(itemId)
		local count = game.role.items[itemId].count
		if value and itemData then
			sellMoney = sellMoney + itemData.sellMoney * count
		end
	end
	self.itemChooseNum:setString(string.format("%d", table.nums(self.sellItems)))
	self.moneyValue:setString(string.format("%d", sellMoney))
end

function ItemSellLayer:showResultLayer()
	--背景框
	local resultLayer = display.newLayer(HeroRes .. "sell/bottom.png")
	local bgSize = resultLayer:getContentSize()

	--已选武器
	local posY = bgSize.height - 44
	ui.newTTFLabel({text = "已选材料：",size = 24,color = display.COLOR_WHITE, font = ChineseFont })
		:anch(0, 0.5):pos(220, posY):addTo(resultLayer)

	self.itemChooseNum = ui.newTTFLabel({ text = "0", size = 24, color = ccc3(0, 255, 0)})
	self.itemChooseNum:anch(0, 0.5):pos(360, posY):addTo(resultLayer)
	
	--获得银币：
	ui.newTTFLabel({text = "获得银币：",size = 24,color = display.COLOR_WHITE, font = ChineseFont }) 
		:anch(0,0.5):pos(460, posY):addTo(resultLayer)

	self.moneyValue = ui.newTTFLabel({ text = "0", size = 24, color = ccc3(0, 255, 0)})
	self.moneyValue:anch(1, 0.5):pos(0, 0.5):pos(640, posY)
		:addTo(resultLayer)

	--银币sp
	display.newSprite(GlobalRes .. "yinbi_big.png"):anch(0, 0.5):pos(650, posY):addTo(resultLayer)

	local btnY = 15
	local btnOff = 250

	--取消
	local cancelBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png", "middle_disabled.png"},
		{	
			priority = self.priority,
			text = { text = "取消", size = 32, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
				self.sellItems = {}
				self:listItems()
			end,
		}):getLayer()
	cancelBtn:anch(0.5, 0):pos(bgSize.width/2 - btnOff, btnY):addTo(resultLayer)

	--自动：
	local autoBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png","middle_disabled.png"},
		{	
			priority = self.priority,
			text = { text = "自动", size = 32, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
				--在当前模式下选择1，2星的武器
				self:autoSelect()
				self:updateResultLabel()
			end,
		}):getLayer()
	autoBtn:anch(0.5, 0):pos(bgSize.width/2,btnY):addTo(resultLayer)

	--出售
	local sellBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png",},
		{	
			priority = self.priority,
			text = { text = "出售", size = 32, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
				local hasHighItem = false
				if table.nums(self.sellItems) > 0 then
					for itemId in pairs(self.sellItems) do
						local itemData = itemCsv:getItemById(itemId)
						if itemData.stars > 2 then
							hasHighItem = true
							break
						end
					end
					if hasHighItem then
						local confirmDialog
						confirmDialog = ConfirmDialog.new({
							priority = self.priority - 10,
							showText = { text = "出售列表中包含蓝色品质以上物品，是否确定出售？", size = 24, },
							button2Data = {
								priority = self.priority - 10,
								text = "出售", font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2,
								callback = function()
									confirmDialog:getLayer():removeSelf()
									self:sellItemRequest()
								end,
							}
						})
						confirmDialog:getLayer():addTo(display.getRunningScene())
					else
						self:sellItemRequest()
					end	
				else
					DGMsgBox.new({ type = 1, text = "请选择道具！"})
				end
			end,
		}):getLayer()
	sellBtn:anch(0.5, 0):pos(bgSize.width/2 + btnOff, btnY):addTo(resultLayer)

	return resultLayer, bgSize
end

function ItemSellLayer:autoSelect()
	self.sellItems = {}
	for _, itemId in pairs(self.items) do
		local itemData = itemCsv:getItemById(itemId)
		if itemData and itemData.type == ItemTypeId.Useless then
			self.sellItems[itemId] = true
		end
	end
	self:listItems()
end 

function ItemSellLayer:sellItemRequest()
	if table.nums(self.sellItems) == 0 then
		return
	end

	local items = {}
	for itemId in pairs(self.sellItems) do
		table.insert(items, {itemId = itemId})
	end
		
	local bin = pb.encode("ItemList", {items = items})
    game:sendData(actionCodes.ItemSellRequest, bin)
    loadingShow()
    game:addEventListener(actionModules[actionCodes.ItemSellResponse], function(event)
    	loadingHide()
    	local msg = pb.decode("SimpleEvent", event.data)

    	for itemId, _ in pairs(self.sellItems) do
    		game.role.items[itemId] = nil
    	end

    	local resultDialog = ConfirmDialog.new({
    		priority = self.priority - 10,
			showText = { text = string.format("出售 %d 件道具, 共计获得 %d 银币\n恭喜发财！请笑纳！", table.nums(self.sellItems), msg.param1), },
			button1Data = {
				text = "笑纳", font = ChineseFont, strokeColor = display.COLOR_BLACK, strokeSize = 2,
				callback = function()
					self:initItemsData()
					self:listItems()
				end,
			}
		})
		resultDialog:getLayer():addTo(display.getRunningScene())

    	return "__REMOVE__"
    end)
end



function ItemSellLayer:getLayer()
	return self.mask:getLayer()
end

function ItemSellLayer:onCleanup()
	display.removeUnusedSpriteFrames()
end

return ItemSellLayer