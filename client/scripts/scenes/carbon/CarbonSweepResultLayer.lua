-- 副本扫荡结果
-- by yangkun
-- 2014.6.24

local CarbonRes = "resource/ui_rc/carbon/"
local CarbonSweepRes = "resource/ui_rc/carbon/sweep/"
local GlobalRes = "resource/ui_rc/global/"

local SellLayer = import("..home.hero.SellLayer")
local HeroDecomposeLayer = import("..home.hero.HeroDecomposeLayer")

local CarbonSweepResultLayer = class("CarbonSweepResultLayer", function(params) 
	return display.newLayer(GlobalRes .. "rule/rule_bg.png") 
end)

function CarbonSweepResultLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -130
	self.carbonId = params.carbonId
	self.carbonData = game.role.carbonDataset[self.carbonId]
	self.carbonCsvData = mapBattleCsv:getCarbonById(self.carbonId)
	self.callback = params.callback
	self.vipData = vipCsv:getDataByLevel(game.role.vipLevel)
	self.index = 1
	self.rowHeight = 340 - 224
	-- 遮罩层
	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.size = self:getContentSize()
	self.mask = DGMask:new({ item = self , priority = self.priority })

	DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
	{
		priority = self.priority - 1,
		callback = function()
			self:remove()
		end,
	}):getLayer():anch(0.5, 0.5):pos(self.size.width, self.size.height):addTo(self)

	self.sweepResults = {}
	local viewBg = display.newSprite(CarbonSweepRes .. "sweep_result_bg.png")
	viewBg:anch(0.5, 0):pos(self.size.width/2, 109):addTo(self)
	local scrollSize = CCSizeMake(viewBg:getContentSize().width, viewBg:getContentSize().height - 10)
	local viewHandler = LuaEventHandler:create(function(fn, table, a1, a2)
		local result
		if fn == "cellSize" then
			result = self:getCellSize(#self.sweepResults - a1)

		elseif fn == "cellAtIndex" then
			if not a2 then
				a2 = CCTableViewCell:new()
				local cell = display.newNode()
				a2:addChild(cell, 0, 1)
			end

			-- 更新cell
			local cell = tolua.cast(a2:getChildByTag(1), "CCNode")
			self:createResultTableCell(cell, #self.sweepResults - a1)
			result = a2

		elseif fn == "numberOfCells" then
			result = math.ceil(#self.sweepResults)
		end

		return result
	end)

	self.resultScroll = CCNodeExtend.extend(LuaTableView:createWithHandler(viewHandler, scrollSize))
	self.resultScroll:setBounceable(true)
	self.resultScroll:setTouchPriority(self.priority - 2)
	self.resultScroll:anch(0, 0):pos(0, 5):addTo(viewBg)


	
	display.newSprite(GlobalRes .. "title_bar.png")
		:anch(0.5,1):pos(self.size.width/2, self.size.height - 10):addTo(self)
	display.newSprite(CarbonSweepRes .. "label_result.png")
		:anch(0.5,1):pos(self.size.width/2, self.size.height - 10):addTo(self)

	self.updateVipLevelHandler = game.role:addEventListener("updateVipLevel", function(event)
		self.vipData = vipCsv:getDataByLevel(game.role.vipLevel)
    	self:initTableLayer()
    end)
	self.oldLevel = game.role.level
	self:initTableLayer()

	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority})
	:anch(0,1):pos(0,display.height):addTo(self.mask:getLayer())

end

function CarbonSweepResultLayer:sendSweepRequest(sweepCount)
	local leftPlayCount = self.carbonCsvData.playCount - self.carbonData.playCnt

	local perHealth = self.carbonCsvData.consumeValue
	local healthCount = math.floor( game.role.health / perHealth )

	-- 扫荡未开启
	local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)	
	if roleInfo.sweepOpen < 1 then
		local sysMsg = sysMsgCsv:getMsgbyId(554)
		DGMsgBox.new({text = string.format(sysMsg.text, math.abs(roleInfo.sweepOpen)), type = 1})
		return
	end

	if self.carbonData.starNum < 3 then
		DGMsgBox.new({text = "3星通关副本后可以扫荡", type = 1})
		return
	end

	if healthCount <= 0 then
		-- DGMsgBox.new({text = "体力不足", type = 1})
		local HealthUseLayer = require("scenes.home.HealthUseLayer")
		local layer = HealthUseLayer.new({ priority = self.priority -10, callback = function()
				self.index = #self.sweepResults
				self:initTableLayer()
			end})
		layer:getLayer():addTo(display.getRunningScene())
		return
	end

	if leftPlayCount <= 0 then
		DGMsgBox.new({text = "今日挑战次数不足", type = 1})
		return
	end

	-- 剩余扫荡次数不足
	if self.vipData.sweepCount ~=0 and self.vipData.sweepCount <= game.role.sweepCount then
		DGMsgBox.new({msgId = 553})	
		return
	end

	-- 背包满
	if game.role:isHeroBagFull() then
		DGMsgBox.new({ msgId = 111,
			button1Data = { text = "去分解", priority = -9000,
				callback = function()
					local layer = HeroDecomposeLayer.new({priority = self.priority - 10})
					layer:getLayer():addTo(display.getRunningScene())
				end
			},
			button2Data = { text = "去出售", priority = -9000,
				callback = function()
					local layer = SellLayer.new({priority = self.priority - 10})
					layer:getLayer():addTo(display.getRunningScene())
				end
			}
		 })
		return
	end

	self.oldLevel = game.role.level
	local sweepRequest = { roleId = game.role.id, param1 = self.carbonId, param2 = sweepCount }
	local bin = pb.encode("SimpleEvent", sweepRequest)
	game:sendData(actionCodes.CarbonSweepRequest, bin, #bin)
	showMaskLayer()
	game:addEventListener(actionModules[actionCodes.CarbonSweepResponse], function(event)
		hideMaskLayer()
		-- 全局记录数据
		self.index = #self.sweepResults
		game.role.sweepResult = event.data
		local sweepResult = pb.decode("CarbonSweepResult", event.data)["result"]

		for _, result in ipairs(sweepResult) do
			local dataTable = {}
			for index, dropItem in ipairs(result.dropItems) do
				game.role:awardItemCsv(dropItem.itemId, dropItem)
				if dropItem.num > 1 and dropItem.itemTypeId == ItemTypeId.Hero then
					for i=1,dropItem.num do
						dataTable[#dataTable + 1] = dropItem
					end
				else
					dataTable[#dataTable + 1] = dropItem
				end
			end
			result.dropItems = dataTable
			table.insert(self.sweepResults, result)
		end
		self:initTableLayer()

		return "__REMOVE__"
	end)
end

function CarbonSweepResultLayer:getCellSize(index)
	local dropNums = self.sweepResults[index] and #(self.sweepResults[index].dropItems) or 1
	local line = math.floor((dropNums-1)/4)
	return CCSizeMake(556, line * self.rowHeight + 224), line
end

function CarbonSweepResultLayer:getContentOffset(endIndex, startOffset)
	endIndex = (endIndex or self.index)+1
	startOffset = startOffset or 0
	for i = #self.sweepResults, endIndex, -1 do
		startOffset = startOffset - self:getCellSize(i).height
	end
	local cellSize, line = self:getCellSize(endIndex - 1)
	return startOffset - math.max(tonum(line) - 1, 0) * self.rowHeight
end


function CarbonSweepResultLayer:initTableLayer()
	local function createItem(id)
		local item = {
			getId = function(self) return id end
		}
		return item
	end

	if self.mainLayer then
		self.mainLayer:removeSelf()
	end	
	self.mainLayer = display.newLayer()
	self.mainLayer:setContentSize(self.size)
	self.mainLayer:anch(0, 0):pos(0, 0):addTo(self)

	local xOffset = 0
	local leftSweepCount = self.vipData.sweepCount - game.role.sweepCount
	leftSweepCount = leftSweepCount < 0 and 0 or leftSweepCount
	if self.vipData.sweepCount ~= 0 and self.carbonCsvData.type ~= 3 then
		xOffset = 55
		local xPos, yPos = 230, 40
		local text = ui.newTTFLabelWithStroke({ text = "扫荡剩余次数：", size = 18, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#222222")})
		text:anch(0, 0.5):pos(xPos, yPos):addTo(self.mainLayer)
		xPos = xPos + text:getContentSize().width
		text = ui.newTTFLabelWithStroke({ text = leftSweepCount, size = 18, color = self.vipData.sweepCount > game.role.sweepCount and display.COLOR_GREEN or display.COLOR_RED, strokeColor = uihelper.hex2rgb("#222222")})
		text:anch(0, 0.5):pos(xPos, yPos):addTo(self.mainLayer)
		xPos = xPos + text:getContentSize().width
		text = ui.newTTFLabelWithStroke({ text = "/" .. self.vipData.sweepCount, size = 18, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#222222")})
		text:anch(0, 0.5):pos(xPos, yPos):addTo(self.mainLayer)
	end

	--扫荡按钮
	local sweepOne = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png", "middle_disabled.png"}, 
		{
			text = {text = "扫荡1次", font = ChineseFont, size = 24, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
				self:sendSweepRequest(1)
			end,
			priority = self.priority - 1,
		})
	sweepOne:getLayer():anch(0.5,0):pos(self.size.width/3 - xOffset, 13):addTo(self.mainLayer)

	local leftPlayCount = self.carbonCsvData.playCount - self.carbonData.playCnt

	local perHealth = self.carbonCsvData.consumeValue
	local healthCount = math.floor( game.role.health / perHealth )
	local sweepCount = healthCount >= 5 and 5 or healthCount
	sweepCount = sweepCount >= leftPlayCount and leftPlayCount or sweepCount
	sweepCount = (self.vipData.sweepCount ~= 0 and sweepCount >= leftSweepCount) and leftSweepCount or sweepCount
	sweepCount = sweepCount == 0 and 1 or sweepCount
	local sweepMul = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png", "middle_disabled.png"}, 
		{
			text = {text = string.format("扫荡%d次", sweepCount), font = ChineseFont, size = 24, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
				if self.vipData.multiSweep ~= 0 then
					self:sendSweepRequest(sweepCount)
				else
					DGMsgBox.new({type = 2, text = "达到VIP2级开启多次扫荡功能", button2Data = {
						text = "去充值",
						callback = function()
							local ReChargeLayer = require("scenes.home.shop.ReChargeLayer")
							local layer = ReChargeLayer.new({priority = self.priority - 10})
							layer:getLayer():addTo(display.getRunningScene())
						end
					}})
				end
			end,
			priority = self.priority -1,
		})
	sweepMul:getLayer():anch(0.5,0):pos(self.size.width/3*2 + xOffset, 13):addTo(self.mainLayer)


	--扫荡结果
	local offset = self.resultScroll:getContentOffset()
	self.resultScroll:reloadData()
	local addOffset = self:getContentOffset(self.index)
	offset.y = offset.y + addOffset
	self.resultScroll:setBounceable(false)
	self.resultScroll:setContentOffset(offset, false)
	
	local actions = {}
	local totalNums = #self.sweepResults
	for index = self.index+1, totalNums do
		if index > 1 then
			local offsetY = self:getContentOffset(index)
			actions[#actions + 1] = CCCallFunc:create(function()
				self.resultScroll:setContentOffset(ccp(0, offsetY), true)
			end)
		else
			local cell = self.resultScroll:cellAtIndex(totalNums - index - 1)
			if cell then
				cell:setVisible(false)
				self:performWithDelay(function() cell:setVisible(true) end, 1)
			end
		end
		actions[#actions + 1] = CCDelayTime:create(1)
	end

	showMaskLayer({delay = 30})
	actions[#actions + 1] = CCCallFunc:create(function()
		hideMaskLayer()
		self.resultScroll:setBounceable(true)
	end)

	if #actions >= 1 then
		self.resultScroll:runAction(transition.sequence(actions))
	end


end

function CarbonSweepResultLayer:remove()
	if self.callback then
		self.callback()
	end
	game.role:removeEventListener("updateVipLevel", self.updateVipLevelHandler)
	self.mask:remove()
end

function CarbonSweepResultLayer:createResultTableCell(cell, index)
	cell:removeAllChildren()
	local result = self.sweepResults[index]
	local cellSize = self:getCellSize(index)
	cell:setContentSize(cellSize)

	local introBg = display.newSprite( CarbonSweepRes .. "sweep_title.png")
	introBg:anch(0.5,0.5):pos(cellSize.width/2, cellSize.height - 20):addTo(cell)

	ui.newTTFLabelWithStroke({text = string.format("第%d次扫荡", index), size = 24, font = ChineseFont, color = uihelper.hex2rgb("#43f1fc"), strokeColor = display.COLOR_FONT})
	:anch(0.5,0.5):pos(introBg:getContentSize().width/2, introBg:getContentSize().height/2):addTo(introBg)

	local expBg = display.newSprite( CarbonSweepRes .. "exp_bg.png")
	expBg:anch(0.5, 0):pos(cellSize.width/2, cellSize.height - 72):addTo(cell)

	local exp = display.newSprite(GlobalRes .. "exp.png"):anch(0, 0.5):addTo(expBg)
	local width, yPos = exp:getContentSize().width, exp:getContentSize().height/2
	local temp = ui.newTTFLabel({text = result.exp, size = 20}):anch(0, 0.5):pos(width, yPos):addTo(exp)
	width = width + temp:getContentSize().width + 30
	temp = display.newSprite(GlobalRes .. "yinbi_big.png"):anch(0, 0.5):pos(width, yPos):addTo(exp)
	width = width + temp:getContentSize().width
	temp = ui.newTTFLabel({text = result.money, size = 20}):anch(0, 0.5):pos(width, yPos):addTo(exp)
	width = width + temp:getContentSize().width
	exp:pos((expBg:getContentSize().width - width)/2, expBg:getContentSize().height/2)
	

	for index = 1, #result.dropItems do
		local x, y = 20 + (index - 1) % 4 * 130, cellSize.height - 185 - math.floor((index-1)/4) * (130)
		local dropItem = result.dropItems[index]
		if dropItem.itemTypeId == ItemTypeId.Hero or dropItem.itemTypeId == ItemTypeId.HeroFragment then
			local itemId = dropItem.itemTypeId == ItemTypeId.Hero and dropItem.itemId - 1000 or dropItem.itemId - 2000
			local cardFrame = HeroHead.new({ 
				parent = self.resultScroll:getParent(),
				type = dropItem.itemTypeId == ItemTypeId.Hero and itemId or itemId + 2000,
				priority = self.priority - 1,
				callback = function()
					self:showItemTaps(itemId,1,dropItem.itemTypeId)
				end
				}):getLayer()
			cardFrame:anch(0,0):pos(x, y):addTo(cell)

			local unitData = unitCsv:getUnitByType(itemId)
			local name = ui.newTTFLabel({text = unitData.name, size = 18, color = uihelper.hex2rgb("#533a27")})
			name:anch(0.5,1):pos(cardFrame:getContentSize().width/2, 0):addTo(cardFrame)
			--数量
			if dropItem.num > 1 and dropItem.itemTypeId == ItemTypeId.HeroFragment then
				ui.newTTFLabelWithStroke({text = "X " .. dropItem.num, size = 18, color = display.COLOR_GREEN })
					:anch(1, 0):pos(cardFrame:getContentSize().width - 15, 8):addTo(cardFrame)
			end
		elseif itemCsv:isItem(dropItem.itemTypeId) then
			local itemFrame = ItemIcon.new({ itemId = dropItem.itemId,
					parent = self.resultScroll:getParent(),
					callback = function() 
						self:showItemTaps(dropItem.itemId,1,dropItem.itemTypeId)
					end,
					priority = self.priority - 1,
				}):getLayer()
			itemFrame:anch(0,0):pos(x, y):addTo(cell)

			local itemData = itemCsv:getItemById(dropItem.itemId)
			ui.newTTFLabel({text = itemData.name, size = 18, color = display.COLOR_DARKYELLOW})
				:anch(0.5,1):pos(itemFrame:getContentSize().width/2, 0):addTo(itemFrame )
			--数量
			if dropItem.num > 1 then
				ui.newTTFLabelWithStroke({text = "X " .. dropItem.num, size = 18, color = display.COLOR_GREEN })
					:anch(1, 0):pos(itemFrame:getContentSize().width - 15, 8):addTo(itemFrame)
			end
		end
	end
end

function CarbonSweepResultLayer:showItemTaps(itemId,itemNum,itemType)
	local itemTipsView = require("scenes.home.ItemTipsLayer")
	local itemTips = itemTipsView.new({
		itemId = itemId,
		itemNum = itemNum,
		itemType = itemType,
		showSource = false,
		priority = self.priority - 10,
		})
	display.getRunningScene():addChild(itemTips:getLayer())
	itemTips:setTag(1000)

end

function CarbonSweepResultLayer:onCleanup()
	game.role:removeEventListener("updateVipLevel", self.updateVipLevelHandler)
end

function CarbonSweepResultLayer:getLayer()
	return self.mask:getLayer()
end

return CarbonSweepResultLayer