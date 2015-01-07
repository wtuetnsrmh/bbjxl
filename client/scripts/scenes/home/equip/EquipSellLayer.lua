local EquipRes = "resource/ui_rc/equip/"
local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"
local TopBarLayer = require("scenes.TopBarLayer")

local EquipSellLayer = class("EquipSellLayer", function()
	return display.newLayer(GlobalRes.."inner_bg.png")
end)

function EquipSellLayer:ctor(params)
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
	closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self)

	local rightTab = display.newSprite(GlobalRes .. "tab_selected.png"):anch(0, 0.5)
	rightTab:pos(self:getContentSize().width - 14, 470):addTo(self)
	display.newSprite(GlobalRes .. "tab_arrow.png")
		:anch(0, 0.5):pos(self:getContentSize().width - 30, 470):addTo(self)
	local tabSize = rightTab:getContentSize()
	ui.newTTFLabelWithStroke({ text = "出售", dimensions = CCSizeMake(tabSize.width / 2, tabSize.height),font=ChineseFont , size = 26, 
		color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(tabSize.width / 2, tabSize.height / 2):addTo(rightTab)

	self:initEquipsData()
	self:listEquips()

	local layer  = TopBarLayer.new({priority = self.priority})
	layer:anch(0,1):pos(0, display.height):addTo(self)
end

function EquipSellLayer:initEquipsData()
	self.equips = {}
	self.sellEquips = {}
	for _, equip in pairs(game.role.equips) do
		if equip.masterId == 0 then
			table.insert(self.equips, equip)
		end
	end

	table.sort(self.equips, function(a, b) 
		local factorA = a.csvData.star * 100000 +  a.level
		local factorB = b.csvData.star * 100000 +  b.level
		return factorA < factorB
	end)
end

function EquipSellLayer:listEquips()
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end

	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.size):addTo(self)

	local resultLayer = self:showResultLayer()
	resultLayer:anch(0.5, 0):pos(self.size.width / 2, 10):addTo(self.mainLayer)

	local infoBg = display.newSprite(GlobalRes .. "label_bg.png"):anch(0,1):pos(38, self.size.height-15):addTo(self.mainLayer)
	ui.newTTFLabel({text = string.format("拥有装备：%d", #self.equips), size = 18})
		:anch(0, 0.5):pos(10, infoBg:getContentSize().height/2):addTo(infoBg)

	local cellSize = CCSizeMake(416, 134)
	local columns = 2

	local viewBg = display.newLayer()
	viewBg:size(850, 372)
	viewBg:anch(0.5, 0):pos(self.size.width / 2, 150):addTo(self.mainLayer)
	local viewSize = viewBg:getContentSize()

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
				local checkFrame = display.newSprite(HeroRes .. "check_frame.png"):anch(1, 0)
				EquipList.new({equip = equip, showMoney = true, priority = self.priority - 1, callback = function()
					if not self.sellEquips[equip.id] then
						self.sellEquips[equip.id] = true
						display.newSprite(HeroRes .. "checked.png"):addTo(checkFrame, 0, 100)
							:pos(checkFrame:getContentSize().width / 2, checkFrame:getContentSize().height / 2)
					else
						self.sellEquips[equip.id] = nil
						checkFrame:removeChildByTag(100)
					end
					self:updateResultLabel()
				end
				}):anch(0, 0):pos(0, 0):addTo(cellNode)
				checkFrame:pos(cellSize.width - 25, 12):addTo(cellNode)

				if self.sellEquips[equip.id] then
					display.newSprite(HeroRes .. "checked.png"):addTo(checkFrame, 0, 100)
							:pos(checkFrame:getContentSize().width / 2, checkFrame:getContentSize().height / 2)
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
			result = math.ceil(#self.equips / columns)
		end

		return result
	end)

	equipTableView = LuaTableView:createWithHandler(viewHandler, viewSize)
	equipTableView:setBounceable(true)
	equipTableView:setTouchPriority(self.priority - 2)
	equipTableView:setPosition(ccp(0, 5))
	viewBg:addChild(equipTableView)
end


function EquipSellLayer:updateResultLabel()
	local sellMoney = 0
	for equipId, value in pairs(self.sellEquips) do
		local equip = game.role.equips[equipId]
		if value then
			sellMoney = sellMoney + equip:getSellMoney()
		end
	end
	self.equipChooseNum:setString(string.format("%d", table.nums(self.sellEquips)))
	self.moneyValue:setString(string.format("%d", sellMoney))
end

function EquipSellLayer:showResultLayer()
	--背景框
	local resultLayer = display.newLayer(HeroRes .. "sell/bottom.png")
	local bgSize = resultLayer:getContentSize()

	--已选武将
	local posY = 105
	local word_Hero = ui.newTTFLabel({text = "已选装备：",size = 24, font = ChineseFont, color = display.COLOR_WHITE })
	:anch(0,0.5)
	:pos(174,posY)
	:addTo(resultLayer)

	self.equipChooseNum = ui.newTTFLabel({ text = "0", size = 24, font = ChineseFont, color = uihelper.hex2rgb("#7ce810")})
	self.equipChooseNum:anch(0, 0.5):pos(294, posY):addTo(resultLayer)
	
	--获得银币：
	local word_money = ui.newTTFLabel({text = "获得银币：", size = 24, font = ChineseFont, color = display.COLOR_WHITE })
	:anch(0,0.5)
	:pos(464,posY)
	:addTo(resultLayer)

	self.moneyValue = ui.newTTFLabel({ text = "0", size = 24, font = ChineseFont, color = uihelper.hex2rgb("#7ce810")})
	self.moneyValue:anch(0, 0.5):pos(0, 0.5):pos(580, posY)
		:addTo(resultLayer)

	--银币sp
	local money = display.newSprite(GlobalRes .. "yinbi_big.png"):anch(0, 0.5):pos(660, posY)
		:addTo(resultLayer)
	

	local btnY = 14
	local btnOff = 250

	--取消
	local cancelBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png", "middle_disabled.png"},
		{	
			priority = self.priority,
			text = { text = "取消", size = 32, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
				self.sellEquips = {}
				self:listEquips()
			end,
		}):getLayer()
	cancelBtn:anch(0.5, 0):pos(bgSize.width/2 - btnOff, btnY):addTo(resultLayer)

	--自动：
	local autoBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png", "middle_disabled.png"},
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
				local hasHighEquip = false
				if table.nums(self.sellEquips) > 0 then
					for equipId in pairs(self.sellEquips) do
						local equip = game.role.equips[equipId]
						if equip.csvData.star > 2 then
							hasHighEquip = true
							break
						end
					end
					if hasHighEquip then
						local confirmDialog
						confirmDialog = ConfirmDialog.new({
							priority = self.priority - 10,
							showText = { text = "出售列表中包含蓝色品质以上装备，是否确定出售？", size = 24, },
							button2Data = {
								priority = self.priority - 10,
								text = "出售", font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2,
								callback = function()
									confirmDialog:getLayer():removeSelf()
									self:sellEquipRequest()
								end,
							}
						})
						confirmDialog:getLayer():addTo(display.getRunningScene())
					else
						self:sellEquipRequest()
					end	
				else
					DGMsgBox.new({ type = 1, text = "请选择武器！"})
				end
			end,
		}):getLayer()
	sellBtn:anch(0.5, 0):pos(bgSize.width/2 + btnOff, btnY):addTo(resultLayer)

	return resultLayer, bgSize
end

function EquipSellLayer:autoSelect()
	self.sellEquips = {}
	for _, equip in pairs(self.equips) do
		if equip and equip.csvData.star < 3 then
			self.sellEquips[equip.id] = true
		end
	end
	self:listEquips()
end 

function EquipSellLayer:sellEquipRequest()
	if table.nums(self.sellEquips) == 0 then
		return
	end

	local bin = pb.encode("EquipActionData", {equipIds = clone(table.keys(self.sellEquips))})
    game:sendData(actionCodes.EquipSellRequest, bin)
    loadingShow()
    game:addEventListener(actionModules[actionCodes.EquipSellResponse], function(event)
    	loadingHide()
    	local msg = pb.decode("EquipActionData", event.data)

    	for id, _ in pairs(self.sellEquips) do
    		game.role.equips[id] = nil
    	end

    	local resultDialog = ConfirmDialog.new({
    		priority = self.priority - 10,
			showText = { text = string.format("出售 %d 件装备, 共计获得 %d 银币\n恭喜发财！请笑纳！", table.nums(self.sellEquips), msg.money), },
			button1Data = {
				text = "笑纳", font = ChineseFont, strokeColor = display.COLOR_BLACK, strokeSize = 2,
				callback = function()
					self:initEquipsData()
					self:listEquips()
				end,
			}
		})
		resultDialog:getLayer():addTo(display.getRunningScene())

    	return "__REMOVE__"
    end)
end



function EquipSellLayer:getLayer()
	return self.mask:getLayer()
end

function EquipSellLayer:onCleanup()
	display.removeUnusedSpriteFrames()
end

return EquipSellLayer