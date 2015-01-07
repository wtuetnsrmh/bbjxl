-- 背包界面
-- by yangkun
-- 2014.6.2

local GlobalRes = "resource/ui_rc/global/"
local HomeRes = "resource/ui_rc/home/"
local GiftRes = "resource/ui_rc/gift/"
local AwardRes = "resource/ui_rc/carbon/award/"
local HeroRes = "resource/ui_rc/hero/"

local GiftPreviewLayer = import(".shop.GiftPreviewLayer")
local ItemSellLayer = import(".item.ItemSellLayer")
local TopBarLayer = import("..TopBarLayer")

local ItemMainLayer = class("ItemMainLayer", function(params) 
	return display.newLayer(GlobalRes .. "inner_bg.png") 
end)

local ITEMTAG = {}
ITEMTAG.All = 1
ITEMTAG.Consume = 2
ITEMTAG.Material = 3

function ItemMainLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -129
	self.size = self:getContentSize()
	self.parent = params.parent
	
	self.curTag = params.tag or ITEMTAG.All
	self.useItemNum=0
	self.cellHeight = 142
	self:initUI()
end

function ItemMainLayer:initUI()
	-- 遮罩层
	self:anch(0, 0):pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1,bg = HomeRes .. "home.jpg"})

	self.tableWidth = 840

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
				self:getLayer():removeSelf()
			end,
		}):getLayer()
	closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self,100)

	self.tabCursor = display.newSprite(GlobalRes .. "tab_arrow.png")
	self.tabCursor:anch(1, 0.5):pos(self.size.width, 470):addTo(self, 100)

	local tabRadio = DGRadioGroup:new()

	--道具
	local itemBtn = DGBtn:new(GlobalRes, {"tab_normal.png", "tab_selected.png"},
		{	
			priority = self.priority,
			callback = function()
				self:initItemList()
			end
		}, tabRadio)
	itemBtn:getLayer():anch(0, 0.5):pos(self.size.width - 14, 470):addTo(self)

	local btnSize = itemBtn:getLayer():getContentSize()
	ui.newTTFLabelWithStroke({ text = "全部", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(itemBtn:getLayer(), 10)

	-- 消耗品
	local consumeBtn = DGBtn:new(GlobalRes, {"tab_normal.png", "tab_selected.png"},
		{	
			priority = self.priority,
			callback = function()
				self:initConsumeList()
			end
		}, tabRadio)
	consumeBtn:getLayer():anch(0, 0.5):pos(self.size.width - 14, 360):addTo(self)
	ui.newTTFLabelWithStroke({ text = "消耗品", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 22, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(consumeBtn:getLayer(), 10)

	-- 材料
	local materielBtn = DGBtn:new(GlobalRes, {"tab_normal.png", "tab_selected.png"},
		{	
			priority = self.priority,
			callback = function()
				self:initMaterielList()
			end
		}, tabRadio)
	materielBtn:getLayer():anch(0, 0.5):pos(self.size.width - 14, 250):addTo(self)
	ui.newTTFLabelWithStroke({ text = "材料", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(materielBtn:getLayer(), 10)

	tabRadio:chooseByIndex(self.curTag, true)

	local layer  = TopBarLayer.new({priority = self.priority})
	layer:anch(0,1):pos(0,display.height):addTo(self)
end

function ItemMainLayer:getLayer()
	return self.mask:getLayer()
end

function ItemMainLayer:prepareBagTableData()
	self.items = {}
	local itemIds = table.keys(game.role.items)
	for _,itemId in pairs(itemIds) do
		print("itemId", itemId)
		local itemData = itemCsv:getItemById(itemId)

		if itemCsv:isItem(itemData.type) then
			table.insert(self.items, itemId)
		end
	end
	table.sort(self.items)

	if self.curTag == ITEMTAG.All then
		self.curTableArray = self.items
	elseif self.curTag == ITEMTAG.Consume then
		self.curTableArray = {}
		for _, itemId in pairs(self.items) do
			local itemData = itemCsv:getItemById(itemId)
			if itemCsv:isConsumption(itemData.type) then
				table.insert(self.curTableArray, itemId)
			end
		end
		table.sort(self.curTableArray)
	else
		self.curTableArray = {}
		for _, itemId in pairs(self.items) do
			local itemData = itemCsv:getItemById(itemId)
			if itemCsv:isMateriel(itemData.type) then
				table.insert(self.curTableArray, itemId)
			end
		end
		table.sort(self.curTableArray)
	end

	--保证宝箱位置正确
	if self.itemId then
		local index = table.keyOfItem(self.curTableArray, self.itemId)
		if index then
			table.remove(self.curTableArray, index)
			table.insert(self.curTableArray, self.itemIndex, self.itemId)
		end
	end
end

function ItemMainLayer:initSellLayer()
	local params = {priority = self.priority - 10}
	if self.curTag == ITEMTAG.Material then
		params.callback = function()
			self:initMaterielList()
		end
	elseif self.curTag == ITEMTAG.All then
			params.callback = function()
			self:initItemList()
		end
	end
	local layer = ItemSellLayer.new(params)
	layer:getLayer():addTo(display.getRunningScene())
end

function ItemMainLayer:initItemList()
	if self.contentLayer then
		self.contentLayer:removeSelf()
	end

	self.curTag = ITEMTAG.All
	self.tabCursor:pos(self.size.width, 470)

	self:prepareBagTableData()
	self.contentLayer = display.newLayer()
	self.contentLayer:size(self.size)
	self.contentLayer:anch(0.5, 0):pos(self.size.width / 2, 5):addTo(self)

	-- 出售
	local sellEquipBtn = DGBtn:new(GlobalRes, {"vertical_normal.png", "vertical_selected.png"},
		{	
			priority = self.priority,
			touchScale = { 2, 1 },
			callback = function()
				self:initSellLayer()
			end
		}):getLayer()
	sellEquipBtn:anch(0, 0.5):pos(self.size.width - 14, 120):addTo(self.contentLayer , -1)
	local btnSize = sellEquipBtn:getContentSize()
	ui.newTTFLabelWithStroke({ text = "出售", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), size = 26, font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(sellEquipBtn)

	self.tableLayer = display.newLayer()
	self.tableLayer:size(self.tableWidth, 490):anch(0.5,0)
		:pos(self.contentLayer:getContentSize().width/2, 30):addTo(self.contentLayer)
	self.tableView = self:createBagTable()
	self.tableView:setPosition(0,0)
	self.tableLayer:addChild(self.tableView)

	self:showNumTips()	
end

function ItemMainLayer:initConsumeList()
	if self.contentLayer then
		self.contentLayer:removeSelf()
	end
	self.curTag = ITEMTAG.Consume
	self:prepareBagTableData()

	self.contentLayer = display.newLayer()
	self.contentLayer:size(self.size)
	self.contentLayer:anch(0.5, 0):pos(self.size.width / 2, 5):addTo(self)

	self.tabCursor:pos(self.size.width, 360)	

	self.tableLayer = display.newLayer()
	self.tableLayer:size(self.tableWidth, 490)
	:anch(0.5,0):pos(self.contentLayer:getContentSize().width/2, 30):addTo(self.contentLayer)

	self.tableView = self:createBagTable()
	self.tableView:setPosition(0,0)
	self.tableLayer:addChild(self.tableView)

	self:showNumTips()
end

function ItemMainLayer:initMaterielList()
	if self.contentLayer then
		self.contentLayer:removeSelf()
	end
	self.curTag = ITEMTAG.Material
	self:prepareBagTableData()

	self.contentLayer = display.newLayer()
	self.contentLayer:size(self.size)
	self.contentLayer:anch(0.5, 0):pos(self.size.width / 2, 5):addTo(self)

	-- 出售
	local sellEquipBtn = DGBtn:new(GlobalRes, {"vertical_normal.png", "vertical_selected.png"},
		{	
			priority = self.priority,
			touchScale = { 2, 1 },
			callback = function()
				self:initSellLayer()
			end
		}):getLayer()
	sellEquipBtn:anch(0, 0.5):pos(self.size.width - 13, 120):addTo(self.contentLayer , -1)
	local btnSize = sellEquipBtn:getContentSize()
	ui.newTTFLabelWithStroke({ text = "出售", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), size = 26, font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(sellEquipBtn)

	self.tabCursor:pos(self.size.width, 250)	

	self.tableLayer = display.newLayer()
	self.tableLayer:size(self.tableWidth, 490)
	:anch(0.5,0):pos(self.contentLayer:getContentSize().width/2, 30):addTo(self.contentLayer)

	self.tableView = self:createBagTable()
	self.tableView:setPosition(0,0)
	self.tableLayer:addChild(self.tableView)

	self:showNumTips()
end

function ItemMainLayer:showNumTips()
	local classNames = {
		[ITEMTAG.All] = "道具数量: ",
		[ITEMTAG.Consume] = "消耗品: ",
		[ITEMTAG.Material] = "材料: ",
	}

	local numberBg = display.newSprite(GlobalRes .. "label_bg.png")
	numberBg:anch(0, 1):pos(35, self.contentLayer:getContentSize().height - 20):addTo(self.contentLayer)
	local xPos = 5
	local label = ui.newTTFLabel({ text = classNames[self.curTag], size = 20 })
	label:anch(0, 0.5):pos(5, numberBg:getContentSize().height/2):addTo(numberBg)
	xPos = xPos + label:getContentSize().width

	ui.newTTFLabel({text = table.nums(self.curTableArray), size = 20, color = display.COLOR_GREEN })
		:anch(0, 0.5):pos(xPos, numberBg:getContentSize().height/2):addTo(numberBg)
end

function ItemMainLayer:createBagTable()
	local handler = LuaEventHandler:create(function(fn, tbl, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.tableWidth, self.cellHeight)
        elseif fn == "cellAtIndex" then
			if not a2 then
                a2 = CCTableViewCell:new()
                local cell = display.newNode()
                a2:addChild(cell, 0, 1)
            end

            local cell = tolua.cast(a2:getChildByTag(1), "CCNode")
            cell:removeAllChildren()

            local index = a1
            self:createBagCell(cell, index)
            r = a2
        elseif fn == "numberOfCells" then
            r = math.floor((table.nums(self.curTableArray) - 1) / 2) + 1
        end

        return r
    end)

	local tableView = LuaTableView:createWithHandler(handler, self.tableLayer:getContentSize())
    tableView:setBounceable(true)
    tableView:setTouchPriority(self.priority - 3)
	return tableView
end

function ItemMainLayer:createBagCell(cellNode, index)
	local totalCellNum = math.floor((table.nums(self.curTableArray) - 1) / 2) + 1
	local leftIndex = 2 * (totalCellNum - index) -1
	local rightIndex = leftIndex + 1

	local function createItemNode(itemIndex)
		local bg = display.newSprite(HomeRes .. "item/cell_bg.png")
		local itemData = itemCsv:getItemById(self.curTableArray[itemIndex])

		local itemFrame = ItemIcon.new({ itemId = self.curTableArray[itemIndex], 
			priority = self.priority -2, 
			callback =  function()
				
				if itemData.type == 19 then
					local giftPreviewLayer = GiftPreviewLayer.new({itemId = itemData.itemId, priority = self.priority -10, parent = self, type = 2})
					giftPreviewLayer:getLayer():addTo(display.getRunningScene())
				else
					self:showItemTaps(self.curTableArray[itemIndex],game.role.items[self.curTableArray[itemIndex]].count,2)
				end
			end})
		itemFrame:getLayer():scale(0.8):anch(0,0):pos(20, 10):addTo(bg)

		-- 数量
		local numLabel = ui.newTTFLabel({text = string.format("数量: %d", game.role.items[self.curTableArray[itemIndex]].count), 
			size = 18, color = uihelper.hex2rgb("#533a27") })
		numLabel:pos(340, bg:getContentSize().height - 20):addTo(bg)

		-- 名字
		ui.newTTFLabelWithStroke({text = itemData.name, size = 24, 
			color = display.COLOR_WHITE, font = ChineseFont, strokeColor = uihelper.hex2rgb("#242424") })
			:anch(0,0.5):pos(15, bg:getContentSize().height - 20):addTo(bg)

		-- 描述
		ui.newTTFLabel({text = itemData.desc, width = 200, size = 18, color = display.COLOR_DARKYELLOW, dimensions = CCSizeMake(200, 95)})
			:anch(0,0):pos(120, 10):addTo(bg)
		
		-- 使用
		if not itemCsv:isMateriel(itemData.type) then
			local useBtn = DGBtn:new( GlobalRes , {"square_green_normal.png", "square_green_selected.png", "square_disabled.png"}, 
				{
					priority = self.priority - 2,
					text = { text = "使用", size = 30, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
					callback = function()
						self:userItemRequest(self.curTableArray[itemIndex])
					end
				})
			useBtn:setEnable(self:getUseBtnStatus(self.curTableArray[itemIndex]))
			useBtn:getLayer():anch(0.5,0.5):scale(0.8):pos(368, bg:getContentSize().height / 2 - 17):addTo(bg)
		end

		return bg
	end

	if self.curTableArray[leftIndex] then
		local itemNode = createItemNode(leftIndex)
		itemNode:anch(0,0):pos(0,0):addTo(cellNode)
	end

	if self.curTableArray[rightIndex] then
		local itemNode = createItemNode(rightIndex)
		itemNode:anch(0,0):pos(430,0):addTo(cellNode)
	end
end

function ItemMainLayer:refreshItemList()
	self:prepareBagTableData()
			
	local itemTableContentOffsetY = self.tableView:getContentOffset().y
	self.tableView:reloadData()	
	self.tableView:setBounceable(false)
	if self.tableView:getContentSize().height<490 then
		itemTableContentOffsetY=490-self.tableView:getContentSize().height
	end
	if self.itemId then
		local totalCellNum = math.floor((table.nums(self.curTableArray) - 1) / 2) + 1
		itemTableContentOffsetY = -(totalCellNum - self.tableIndex) * self.cellHeight
	end
	self.tableView:setContentOffset(ccp(0,itemTableContentOffsetY), false)
	self.tableView:setBounceable(true)

	self:showNumTips()
end

function ItemMainLayer:userItemRequest(itemId)
	local itemData = itemCsv:getItemById(itemId)
	--商店刷新符使用
	if itemData.type == 17 then
		local layer = require("scenes.pvp.PvpShopLayer").new({ 
			priority = self.priority - 10,
			shopIndex = 5,
			closeCallback = function() 
				self:refreshItemList()	
			end
		})
		display.getRunningScene():addChild(layer:getLayer())

	elseif itemData.type == 4 then
		local itemUseRequest = { roleId = game.role.id, param1 = itemData.itemId, param2 = 1 }	
		local bin = pb.encode("SimpleEvent", itemUseRequest)
		game:sendData(actionCodes.ItemUseRequest, bin)
		self.useItemNum=self.useItemNum+1;
		loadingShow()	
		game:addEventListener(actionModules[actionCodes.ItemUseResponse], function(event)
			loadingHide()
			self:refreshItemList()
			if self.useItemNum<=0 then
				return "__REMOVE__"
			else
				return false
			end
			
		end)

	elseif itemData.type == 19 then
		local giftPreviewLayer = GiftPreviewLayer.new({itemId = itemData.itemId, priority = self.priority -10, type = 2, parent = self})
		giftPreviewLayer:getLayer():addTo(display.getRunningScene())

	-- 随机道具
	elseif itemData.type == 20 or itemData.type == 21 then
		local itemUseRequest = { roleId = game.role.id, param1 = itemData.itemId, param2 = 1 }	
		local bin = pb.encode("SimpleEvent", itemUseRequest)
		game:sendData(actionCodes.ItemUseRequest, bin)
		loadingShow()
		game:addEventListener(actionModules[actionCodes.ItemUseResponse], function(event)
			self.itemId = itemData.itemId
			self.itemIndex = table.keyOfItem(self.curTableArray, self.itemId)
			local itemTableContentOffsetY = self.tableView:getContentOffset().y
			local totalCellNum = math.floor((table.nums(self.curTableArray) - 1) / 2) + 1
			self.tableIndex = totalCellNum + itemTableContentOffsetY / self.cellHeight
			loadingHide()
			self:refreshItemList()	
			local itemList = pb.decode("ItemList", event.data)
			local item = itemList.items[1]
			local itemData = itemCsv:getItemById(item.itemId)
			--加入提示
			display.getRunningScene():removeChildByTag(100)

			local msgBg = display.newSprite(GlobalRes .. "flash_msg_bg.png")
			local bgSize = msgBg:getContentSize()

			local descLabel = DGRichLabel.new({ 
				text = string.format("获得 [color=ffff00]%s[/color][color=00ff00]%d[/color] 个", itemData.name, item.num), 
				width = bgSize.width - 20, 
				size = 24,
			})
			local scale = 0.7
			local icon = ItemIcon.new({itemId = item.itemId}):getLayer()
			icon:anch(1, 0.5):scale(scale):pos(0, descLabel:getContentSize().height/2):addTo(descLabel)
			local width = descLabel:getContentSize().width + icon:getContentSize().width * scale
			descLabel:anch(0, 0.5):pos((bgSize.width - width)/2, bgSize.height / 2):addTo(msgBg)

			msgBg:anch(0.5, 0.5):pos(display.cx, display.cy):addTo(display.getRunningScene(),99999, 100)

			local effectTime = 1
			msgBg:runAction(transition.sequence({
				CCDelayTime:create(1),
				CCCallFunc:create(function() uihelper.fadeTree({node = msgBg, from = 255, to = 0, effectTime = effectTime}) end),
				CCDelayTime:create(effectTime),
				CCRemoveSelf:create(),
			}))

			self.itemId = nil
			return "__REMOVE__"
		end)
	elseif itemData.type == 27 then
		local HeroGainExpLayer = require("scenes.home.hero.HeroGainExpLayer")
		local layer = HeroGainExpLayer.new({priority = self.priority - 10, itemId = itemId, closeCallback = function() self:refreshItemList() end})
		layer:getLayer():addTo(display.getRunningScene())
	end

end

function ItemMainLayer:getUseBtnStatus(itemId)
	if itemId >= 5000 and itemId <= 9999 then
		return true
	end
	
	local itemData = itemCsv:getItemById(itemId)

	if itemData.type == 15 or itemData.type == 18 then
		for _,beauty in pairs(game.role.beauties) do
			if beauty.status == beauty.class.STATUS_FIGHT then
				return true
			end
		end
		return false
	end
	return true
end

function ItemMainLayer:showItemTaps(itemID,itemCount,itemType)
	display.getRunningScene():removeChildByTag(10000)

	local itemTipsView = require("scenes.home.ItemTipsLayer")
	local itemTips = itemTipsView.new({
		itemId = itemID,
		itemNum= itemCount,
		itemType = itemType,
	})
	display.getRunningScene():addChild(itemTips:getLayer(), 0, 10000)
end

function ItemMainLayer:onEnter()
	self.parent:hide()
end

function ItemMainLayer:onExit()
	self.parent:show()
end

function ItemMainLayer:onCleanup()
	display.removeUnusedSpriteFrames()
end

return ItemMainLayer