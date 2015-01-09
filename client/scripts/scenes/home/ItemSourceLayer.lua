local GiftRes = "resource/ui_rc/gift/"
local GlobalRes = "resource/ui_rc/global/"
local CarbonRes = "resource/ui_rc/carbon/"

local PvpShopLayer = import("..pvp.PvpShopLayer")
local ShopMainLayer = import("..home.shop.ShopMainLayer")
local StoreMainLayer = import(".StoreMainLayer")

local ItemSourceLayer = class("ItemSourceLayer", function()
	return display.newLayer(GlobalRes .. "rule/rule_bg.png")
end)

local SourceDatas = {
	[1] = { 
		res = "resource/icon/task/shop.png", name = "商城道具",
		hasOpen = function(params)
			return true
		end,
		callback = function(params)
			params.node:hide()
			local shopLayer = ShopMainLayer.new({ 
				chooseIndex = 2,
				priority = params.priority - 10, 
				closeCallback = function() params.node:show() end
			})
			shopLayer:getLayer():addTo(display.getRunningScene())
		end 
	},

	[2] = { 
		res = "resource/icon/task/shop1.png", name = "将魂商店",
		hasOpen = function(params)
			return true
		end,
		callback = function(params)
			local bin = pb.encode("SimpleEvent", { roleId = game.role.id, param1 = 1, param2 = 4 })
			game:sendData(actionCodes.RoleShopRequest, bin)
			loadingShow()
			game:addEventListener(actionModules[actionCodes.RoleShopResponse], function(event)
				loadingHide()
				local msg = pb.decode("RoleShopDataResponse", event.data)

				local now = game:nowTime()
				local shopDatas = {}
				for _, shopData in ipairs(msg.shopDatas) do
					shopDatas[shopData.shopIndex] = {
						shopItems = json.decode(shopData.shopItemsJson),
						refreshLeftTime = shopData.refreshLeftTime,
						checkPoint = now,
					}
				end

				local storeMainLayer = StoreMainLayer.new({ 
					shopDatas = shopDatas,
					parent = params.node, 
					priority = params.priority - 100,
					curIndex = 4})
				storeMainLayer:getLayer():addTo(display.getRunningScene())

			end)
		end,
	},

	[3] = { 
		res = "resource/icon/task/pvpbox.png", name = "战场宝箱",
		hasOpen = function(params)
			local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
			return roleInfo.pvpOpen > 0
		end,
		callback = function(params)
			switchScene("pvp")
		end,
	},

	[4] = { 
		res = "resource/icon/task/carbon.png", name = "普通副本",
		hasOpen = function(params)
			local mapId = params.mapId or 0
			local mapOpen = game.role.mapTypeDataset[1][params.mapId]
			if not mapOpen then return false end

			if params.carbonId then
				return game.role.carbonDataset[params.carbonId] ~= nil
			end

			return true
		end,
		callback = function(params)
			params = params or {}
			params.tag = 1
			if params.carbonId and game.role.carbonDataset[params.carbonId] and game.role.carbonDataset[params.carbonId].starNum >= 3 then
				ItemSourceLayer.sPopUpShortCut(params)
				return
			end	
			--switchScene("carbon", params)
			gPushFlag = true	-- tell battle scene return here
			pushScene("carbon", params)
		end,
	},

	[5] = { 
		res = "resource/icon/task/challenge.png", name = "精英副本",
		hasOpen = function(params)
			local mapId = params.mapId or 0
			if not game.role.mapTypeDataset[2] then return false end
			
			local mapOpen = game.role.mapTypeDataset[2][mapId]
			if not mapOpen then return false end

			if params.carbonId then
				return game.role.carbonDataset[params.carbonId] ~= nil
			end

			return true
		end,
		callback = function(params)
			params = params or {}
			params.tag = 2
			if params.carbonId and game.role.carbonDataset[params.carbonId] and game.role.carbonDataset[params.carbonId].starNum >= 3 then
				ItemSourceLayer.sPopUpShortCut(params)
				return
			end
			--switchScene("carbon", params)
			gPushFlag = true
			pushScene("carbon", params)
		end,
	},

	[6] = { 
		res = "resource/icon/task/legend.png", name = "名将",
		hasOpen = function(params)
			local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
			return roleInfo.legendOpen > 0
		end,
		callback = function(params)
			switchScene("legend")
		end,
	},

	[7] = { 
		res = "resource/icon/task/tower.png", name = "过关斩将",
		hasOpen = function(params)
			local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
			return roleInfo.towerOpen > 0
		end,
		callback = function(params)
			local bin = pb.encode("SimpleEvent", { roleId = game.role.id })
			game:sendData(actionCodes.TowerDataRequest, bin, #bin)
			loadingShow()
			game:addEventListener(actionModules[actionCodes.TowerDataResponse], function(event)
				loadingHide()
				local msg = pb.decode("TowerData", event.data)
				local towerPbFields = { "count", "carbonId", "totalStarNum", "preTotalStarNum", 
					"maxTotalStarNum", "curStarNum", "hpModify", "atkModify", "defModify", "sceneId1",
					"sceneId2", "sceneId3", }

				game.role.towerData = game.role.towerData or {}
				for _, field in pairs(towerPbFields) do
					game.role.towerData[field] = msg[field]
				end

				switchScene("tower")	
				return "__REMOVE__"
			end)
		end,
	},

	[8] = { 
		res = "resource/icon/task/shop2.png", name = "战功商店",
		hasOpen = function(params)
			local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
			return roleInfo.pvpOpen > 0
		end,
		callback = function(params)
			params.node:hide()
			local layer = PvpShopLayer.new({ priority = params.priority,
				shopIndex = 5,
				closeCallback = function()
					params.node:show()
				end 
			})
			layer:getLayer():addTo(display.getRunningScene())
		end,
	},

	[9] = { 
		res = "resource/icon/task/drawcard.png", name = "商城抽卡",
		hasOpen = function(params)
			return true
		end,
		callback = function(params)
			params.node:hide()
			local shopLayer = ShopMainLayer.new({ 
				chooseIndex = 1,
				priority = params.priority - 10, 
				closeCallback = function() params.node:show() end
			})
			shopLayer:getLayer():addTo(display.getRunningScene())
		end,
	},

	[10] = { 
		res = "resource/icon/task/hard.png", name = "地狱副本",
		hasOpen = function(params)
			local mapId = params.mapId or 0
			if not game.role.mapTypeDataset[3] then return false end
			local mapOpen = game.role.mapTypeDataset[3][mapId]
			if not mapOpen then return false end

			if params.carbonId then
				return game.role.carbonDataset[params.carbonId] ~= nil
			end

			return true
		end,
		callback = function(params)
			params = params or {}
			params.tag = 3

			--switchScene("carbon", params)
			gPushFlag = true
			pushScene("carbon", params)
		end,
	},

	[11] = { 
		res = "resource/icon/task/shop3.png", name = "声望商店",
		hasOpen = function(params)
			local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
			return roleInfo.expeditionOpen > 0
		end,
		callback = function(params)
			local PvpShopLayer = require("scenes.pvp.PvpShopLayer")
			local layer = PvpShopLayer.new({priority = params.priority - 1, shopIndex = 6})
			layer:getLayer():addTo(display.getRunningScene())
		end,
	},

	[12] = { 
		res = "resource/icon/task/shilian.png", name = "试炼",
		hasOpen = function(params)
			return game.role.level >= 35
		end,
		callback = function(params)
			gPushFlag = true
			pushScene("activity", params)
		end,
	},
}

function ItemSourceLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -130

	self.size = self:getContentSize()
	self.itemData = itemCsv:getItemById(params.itemId)

	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1, ObjSize = self.size,
		clickOut = function() 
			if params.closeCallback then
				params.closeCallback()
			end
			self.mask:remove() 
		end,
	})

	local titleBg = display.newSprite("resource/ui_rc/global/title_bar.png")
	display.newSprite("resource/ui_rc/gift/get_title.png"):addTo(titleBg)
		:pos(titleBg:getContentSize().width / 2, titleBg:getContentSize().height / 2)
	titleBg:pos(self.size.width / 2, self.size.height - 40):addTo(self)

	local sourceList = DGScrollView:new({ priority = self.priority - 1,
		size = CCSizeMake(self.size.width, self.size.height - 100), 
		divider = 10, })

	for index, sourceId in ipairs(self.itemData.source) do
		local sourceCell = self:initSourceCell(index, tonum(sourceId))
		sourceList:addChild(sourceCell)
	end


	sourceList:alignCenter()
	sourceList:getLayer():anch(0.5, 0):pos(self.size.width / 2, 20):addTo(self)

	self:scale(0.8):runAction(CCEaseBackOut:create(CCScaleTo:create(0.2, 1)))
end

function ItemSourceLayer:initSourceCell(index, sourceId)
	local sourceData = SourceDatas[sourceId]

	local params = { priority = self.priority - 10, node = self:getLayer() }
	local cellBtn = DGBtn:new(GiftRes , {"drop_bar.png"},
		{	
			priority = self.priority,
			scale = 0.95,
			callback = function()
				sourceData.callback(params)
			end,
		})
	local cellSize = cellBtn:getLayer():getContentSize()

	local frame = display.newSprite(GlobalRes .. "frame_empty.png")
	frame:anch(0, 0.5):pos(10, cellSize.height / 2):addTo(cellBtn:getLayer())
	display.newSprite(sourceData.res):addTo(frame, -1)
		:pos(frame:getContentSize().width / 2, frame:getContentSize().height / 2)

	local srcDesc = self.itemData["srcDesc" .. index]
	local srcMap = self.itemData["srcMap" .. index]
	local srcCarbon = self.itemData["srcCarbon" .. index]
	print(srcMap, srcCarbon, index, self.itemData.itemId)

	local shouldGoto = true
	if sourceId == 4 or sourceId == 5 or sourceId == 10 then
		local mapInfo = mapInfoCsv:getMapById(srcMap)
		local carbonInfo = mapBattleCsv:getCarbonById(srcCarbon)
		params.mapId, params.carbonId = srcMap, srcCarbon

		if carbonInfo then
			ui.newTTFLabel({ text = string.format("【%s】%s", sourceData.name, mapInfo.name), 
				size = 26, color = uihelper.hex2rgb("#533a27") })
				:anch(0, 0):pos(130 - 10, cellSize.height / 2 + 5):addTo(cellBtn:getLayer())
			ui.newTTFLabel({ text = carbonInfo.name, size = 24, color = display.COLOR_RED })
				:anch(0, 1):pos(130, cellSize.height / 2 - 5):addTo(cellBtn:getLayer())
		elseif mapInfo then
			ui.newTTFLabel({ text = string.format("【%s】%s", sourceData.name, mapInfo.name), 
				size = 26, color = uihelper.hex2rgb("#533a27")})
				:anch(0, 0.5):pos(130 - 10, cellSize.height / 2):addTo(cellBtn:getLayer())
		else
			shouldGoto = false

			ui.newTTFLabel({ text = string.format("【%s】", sourceData.name), size = 28, color = uihelper.hex2rgb("#533a27") })
				:anch(0, 0):pos(130, cellSize.height / 2 + 2):addTo(cellBtn:getLayer())
			ui.newTTFLabel({ text = srcDesc, size = 32, color = uihelper.hex2rgb("#533a27") })
				:anch(0, 1):pos(130, cellSize.height / 2 - 2):addTo(cellBtn:getLayer())
		end
	else
		ui.newTTFLabel({ text = string.format("【%s】", sourceData.name), size = 32, color = uihelper.hex2rgb("#533a27") })
			:anch(0, 0):pos(130, cellSize.height / 2 + 2):addTo(cellBtn:getLayer())
		ui.newTTFLabel({ text = srcDesc, size = 32, color = uihelper.hex2rgb("#533a27") })
			:anch(0, 1):pos(130, cellSize.height / 2 - 2):addTo(cellBtn:getLayer())
	end

	if shouldGoto and not sourceData.hasOpen(params) then
		cellBtn:setEnable(false)
			
		display.newSprite("resource/ui_rc/gift/closed_text.png")
			:anch(1, 0):pos(cellSize.width - 20, 20):addTo(cellBtn:getLayer())
	end

	cellBtn:getLayer():anch(0.5, 0)
	return cellBtn:getLayer()
end

function ItemSourceLayer.sPopUpShortCut(params)
	local tipsTag = 8541
	-- params.priority = -2000

	local function purgeItemTaps()
		if display.getRunningScene():getChildByTag(tipsTag) then
			display.getRunningScene():getChildByTag(tipsTag):removeFromParent()
		end
	end

	local function showItemTaps(itemId,itemNum,itemType)
		purgeItemTaps()
		local itemTipsView = require("scenes.home.ItemTipsLayer")
		local itemTips = itemTipsView.new({
			itemId = itemId,
			itemNum = itemNum,
			itemType = itemType,
			showSource = false,
			priority = params.priority - 10
		})
		display.getRunningScene():addChild(itemTips:getLayer())
		itemTips:setTag(tipsTag)
	end

	local bg = display.newSprite(GlobalRes .. "rule/rule_bg.png")
	bg:anch(0.5, 0.5):pos(display.cx, display.cy)
	local bgSize = bg:getContentSize()
	local mask
	mask = DGMask:new({ item = bg, opacity = 0, priority = params.priority, ObjSize = bgSize,
		clickOut = function() mask:remove() end,
	})
	mask:getLayer():addTo(display.getRunningScene())

	local carbon = game.role.carbonDataset[params.carbonId]
	local mapInfo = mapInfoCsv:getMapById(params.mapId)
	local carbonInfo = mapBattleCsv:getCarbonById(params.carbonId)
	--标题
	local titleBg = display.newSprite(GlobalRes .. "title_bar_long.png")
	titleBg:anch(0.5, 1):pos(bgSize.width/2, bgSize.height - 10):addTo(bg)
	ui.newTTFLabelWithStroke({text = carbonInfo.name, color = uihelper.hex2rgb("#fde335"), font = ChineseFont, size = 38})
		:anch(0.5, 0.5):pos(titleBg:getContentSize().width/2, titleBg:getContentSize().height/2):addTo(titleBg)
	--可能掉落
	local contentBg = display.newSprite(CarbonRes .. "sweep/sweep_result_bg.png")
	contentBg:anch(0.5, 0):pos(bgSize.width/2, 105):addTo(bg)

	local introBg = display.newSprite( CarbonRes .. "sweep/sweep_title.png")
	introBg:anch(0.5,0.5):pos(contentBg:getContentSize().width/2, contentBg:getContentSize().height - 40):addTo(contentBg)

	ui.newTTFLabelWithStroke({text = "可能获得", size = 24, font = ChineseFont, color = uihelper.hex2rgb("#43f1fc"), strokeColor = display.COLOR_FONT})
		:anch(0.5, 0.5):pos(introBg:getContentSize().width/2, introBg:getContentSize().height/2):addTo(introBg)
	--详细掉落列表
	local dropData = dropCsv:getDropData(params.carbonId)[1]
	local count, columns = 1, 3 
	for index, drop in pairs(dropData.specialDrop) do
		if tonumber(drop[4]) > 0 then
			local itemId = tonumber(drop[1])
			local itemFrame = ItemIcon.new({ itemId = itemId,
				priority = params.priority-1,
				callback = function()
					showItemTaps(tonum(itemId), 1, itemCsv:getItemById(itemId).itemTypeI)
				end,
				}):getLayer()
			itemFrame:scale(1):anch(0.5, 0.5):pos(120 + (count-1)%columns*172, count>columns and 92 or 228):addTo(contentBg)
			count = count + 1
		end
	end

	local vipInfo = vipCsv:getDataByLevel(game.role.vipLevel)
	local leftSweepCount = vipInfo.sweepCount - game.role.sweepCount
	leftSweepCount = leftSweepCount < 0 and 0 or leftSweepCount
	if vipInfo.sweepCount ~= 0 then
		local xPos, yPos = 125, 90
		local text = ui.newTTFLabelWithStroke({ text = "扫荡剩余次数：", size = 18, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#222222")})
		text:anch(0, 0.5):pos(xPos, yPos):addTo(bg)
		xPos = xPos + text:getContentSize().width
		text = ui.newTTFLabelWithStroke({ text = leftSweepCount, size = 18, color = vipInfo.sweepCount > game.role.sweepCount and display.COLOR_GREEN or display.COLOR_RED, strokeColor = uihelper.hex2rgb("#222222")})
		text:anch(0, 0.5):pos(xPos, yPos):addTo(bg)
		xPos = xPos + text:getContentSize().width
		text = ui.newTTFLabelWithStroke({ text = "/" .. vipInfo.sweepCount, size = 18, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#222222")})
		text:anch(0, 0.5):pos(xPos, yPos):addTo(bg)
	end
	--扫荡按钮
	local sweepLayer = require("scenes.carbon.CarbonSweepResultLayer")
	DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png", "middle_disabled.png"}, 
	{
		text = {text = "扫荡", font = ChineseFont, size = 24, strokeColor = uihelper.hex2rgb("#022849")},
		callback = function()
			local layer = sweepLayer.new({priority = params.priority - 10, carbonId = params.carbonId})
			layer:getLayer():addTo(display.getRunningScene())
			purgeItemTaps()
			mask:remove()
		end,
		priority = params.priority - 1,
	}):getLayer():anch(0.5, 0):pos(bgSize.width/3, 17):addTo(bg)

	--前往按钮
	DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png", "middle_disabled.png"}, 
	{
		text = {text = "前往", font = ChineseFont, size = 24, strokeColor = uihelper.hex2rgb("#022849")},
		callback = function()
			gPushFlag = true
			pushScene("carbon", params)
			purgeItemTaps()
			mask:remove()
		end,
		priority = params.priority - 1,
	}):getLayer():anch(0.5, 0):pos(bgSize.width/3*2, 17):addTo(bg)
end

function ItemSourceLayer:getLayer()
	return self.mask:getLayer()
end

return ItemSourceLayer