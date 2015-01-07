local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"
local HeroChooseRes = "resource/ui_rc/hero/choose/"

local HeroGainExpLayer = class("HeroGainExpLayer", function(params) 
	return display.newLayer(HeroChooseRes .. "partner_popup.png") 
end)

function HeroGainExpLayer:ctor(params)

	params = params or {}

	self.priority = params.priority or -129
	self.itemId = params.itemId
	self.itemData = itemCsv:getItemById(self.itemId)
	self.size = self:getContentSize()
	self:anch(0.5,0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority, ObjSize = self.size, clickOut = function()
		if params.closeCallback then
			params.closeCallback()
		end 
		self.mask:remove() 
	end})

	self.useCount = 0
	self.heros = {}
	for id, hero in pairs(game.role.heros) do
		local _hero = clone(hero)
		table.insert(self.heros, _hero)
	end
	table.sort(self.heros, function(a, b)
		local factorA = a.choose * 1000000 + (a.master > 0 and 1 or 0) * 100000 + a.star * 10000 + a.evolutionCount * 1000 + a.level
		local factorB = b.choose * 1000000 + (b.master > 0 and 1 or 0) * 100000 + b.star * 10000 + b.evolutionCount * 1000 + b.level
		return factorA == factorB and (a.type < b.type) or (factorA > factorB)
	end)
	self:initUI()
end

function HeroGainExpLayer:initUI()
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end
	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.size):addTo(self)

	-- title
	local bg = display.newSprite(HeroChooseRes .. "partner_item_bg.png")
	bg:anch(0.5, 1):pos(self.size.width/2, self.size.height - 22):addTo(self.mainLayer)
	ui.newTTFLabel({text = "选择武将", size = 24, color = uihelper.hex2rgb("#d8f8ff"), font = ChineseFont})
		:anch(0.5, 0.5):pos(bg:getContentSize().width/2, bg:getContentSize().height/2):addTo(bg)
	--使用提示
	ui.newTTFLabel({text = "长按武将头像即可快速使用经验丹", size = 20, color = uihelper.hex2rgb("#f7c338"), font = ChineseFont})
		:anch(0.5, 1):pos(self.size.width/2, self.size.height - 65):addTo(self.mainLayer)
	self:listHeros()
end

function HeroGainExpLayer:listHeros()

	local cellSize = CCSizeMake(375, 122)
	local columns = 2

	local viewBg = display.newLayer()
	viewBg:size(self.size.width, 351)
	local viewSize = CCSizeMake(viewBg:getContentSize().width, viewBg:getContentSize().height)
	viewBg:anch(0.5, 0):pos(self.size.width / 2, 20):addTo(self.mainLayer)


	local function createCellNode(parentNode, cellIndex, removeAll)
		parentNode:setContentSize(CCSizeMake(viewSize.width, cellSize.height))
		if removeAll then
			parentNode:removeAllChildren()
		end
		local tag = 1
		local xBegin = 30
		local xInterval = (viewSize.width - 2 * xBegin - columns * cellSize.width) / (columns - 1)
		local rows = math.ceil(#self.heros / columns)
		for index = (rows - cellIndex - 1) * columns + 1, columns * (rows - cellIndex) do
			local hero = self.heros[index]
			local nativeIndex = index - (rows - cellIndex - 1) * columns
			local cellNode = parentNode:getChildByTag(tag)
			local added = true
			if not cellNode then
				cellNode = display.newLayer()
				added = false
				cellNode:size(cellSize)
			end
			cellNode:removeAllChildren()
			
			if hero then
				local heroCell = HeroListCell.new({ type = hero.type, level = hero.level, wakeLevel = hero.wakeLevel, star = hero.star,
					evolutionCount = hero.evolutionCount, priority = self.priority,
					parent = viewBg,
				}):getLayer()
				heroCell:scale(0.9):anch(0, 0):addTo(cellNode)

				local cellSize = heroCell:getContentSize()
				-- 经验条
				local expSlot = display.newSprite( HeroRes .. "growth/exp_bar_bg.png")
				expSlot:anch(0, 0):pos(150, 15):addTo(heroCell)
				local expProgress = display.newProgressTimer(HeroRes .. "growth/exp_bar_fg.png", display.PROGRESS_TIMER_BAR)
				expProgress:setMidpoint(ccp(0, 0.5))
				expProgress:setBarChangeRate(ccp(1,0))
				expProgress:setPercentage(hero.oldPercentage and hero.oldPercentage or hero.exp / hero:getLevelTotalExp() * 100)
				
				expProgress:pos(expSlot:getContentSize().width/2, expSlot:getContentSize().height/2):addTo(expSlot)
				cellNode.expProgress = expProgress
				
				ui.newTTFLabel({text = string.format("%d / %d", hero.exp, hero:getLevelTotalExp()), size = 18})
					:anch(0.5,0.5):pos(expSlot:getContentSize().width/2, expSlot:getContentSize().height/2):addTo(expSlot)

				if hero.choose == 1 then
					display.newSprite(HeroRes .. "tag_selected.png")
						:anch(1, 1):pos(cellSize.width, cellSize.height - 5):addTo(heroCell)
				end

				if table.find(game.role.partners, hero.id) then
					display.newSprite(HeroRes .. "tag_partner.png")
						:anch(1, 1):pos(cellSize.width, cellSize.height - 5):addTo(heroCell)
				end


				--快捷使用
				local function refresh()
					local oldLevel =  hero.level
					hero:addExp(self.itemData.heroExp)
					hero.oldPercentage = cellNode.expProgress:getPercentage()
					createCellNode(parentNode, cellIndex)
					--使用数量
					local useCount = self.useCount == 0 and 1 or self.useCount
					local text = ui.newTTFLabel({text = "X" .. useCount, size = 24, font = ChineseFont, color = uihelper.hex2rgb("#673b1b")})
					text:anch(1, 0):pos(cellSize.width - 50, 40):addTo(cellNode)
					text:runAction(transition.sequence({
						CCDelayTime:create(0.2),
						CCFadeOut:create(0.2),
						CCRemoveSelf:create(),
					}))
					--增加经验
					local text = ui.newTTFLabel({text = "经验+" .. self.itemData.heroExp, size = 20, font = ChineseFont, color = uihelper.hex2rgb("#c435f3")})
					text:anch(0.5, 0.5):pos(cellNode:getPositionX() + 227.5, cellNode:getPositionY() + cellSize.height/2 - 20):addTo(parentNode)
					text:runAction(transition.sequence({
						CCSpawn:createWithTwoActions(CCMoveBy:create(0.3, ccp(0, 50)), CCFadeOut:create(0.4)),
						CCRemoveSelf:create(),
					}))
					--进度条特效
					local seq, time = {}, 0.2
					--升级特效
					if oldLevel < hero.level then
						local anim = uihelper.loadAnimation(HeroRes .. "growth/", "LevelUp", 12)
						anim.sprite:anch(0.5, 0.5):pos(cellNode:getPositionX() + 68, cellNode:getPositionY() + 52):addTo(parentNode, 999)
						anim.sprite:runAction(transition.sequence({
							CCAnimate:create(anim.animation),
							CCRemoveSelf:create(),
						}))	

						time = time / 2
						table.insert(seq, CCProgressTo:create(time, 100)) 			
					end
					local curPercentage = hero.exp / hero:getLevelTotalExp() * 100
					table.insert(seq, CCProgressTo:create(time, curPercentage))
					cellNode.expProgress:runAction(transition.sequence(seq))
					hero.oldPercentage = curPercentage
				end
	
				local function endFunc(toRefresh)
					self.touch = false
					if self.useCount > tonum(totable(game.role.items[self.itemId]).count) then
						DGMsgBox.new({text = "经验丹已用完！", type = 1})
						self.useCount = self.useCount - 1
					end
					if hero:getLevelMaxExp() == 0 then
						DGMsgBox.new({text = "武将等级已满！", type = 1})
						self.useCount = self.useCount - 1
					end
					if self.useCount > 0 then
						local itemUseRequest = { roleId = game.role.id, param1 = self.itemId, param2 = self.useCount, param3 = hero.id }	
						local bin = pb.encode("SimpleEvent", itemUseRequest)
						game:sendData(actionCodes.ItemUseRequest, bin)
						loadingShow()	
						game:addEventListener(actionModules[actionCodes.ItemUseResponse], function(event)
							loadingHide()
							if toRefresh then
								refresh()
							end
							return "__REMOVE__"
						end)
					end
					cellNode:stopAllActions()
					self.useCount = 0
				end

				local CANCELDIS = 50
				cellNode:addTouchEventListener(
					function(event, x, y)
						if event == "began" then
							if not self.touch and uihelper.nodeContainTouchPoint(cellNode, ccp(x, y)) then
								local useItem
								useItem = function(timeInterval)
									cellNode:performWithDelay(function()
										if self.touch then
											self.useCount = self.useCount + 1
											if self.useCount <= tonum(totable(game.role.items[self.itemId]).count) and hero:getLevelMaxExp() > 0 then
												refresh()
											else
												endFunc()
											end
											useItem(0.2)
										else
											endFunc()
										end
									end, timeInterval)
								end
								useItem(0.5)
								self.touch = true
								self.lastX = x
								self.lastY = y
							else
								return false
							end
						elseif event == "moved" then
							if math.abs(self.lastX - x) > CANCELDIS or math.abs(self.lastY - y) > CANCELDIS or
								not uihelper.nodeContainTouchPoint(cellNode, ccp(x, y)) then
								self.touch = false
								return false
							end
						elseif event == "ended"  then
							if self.touch then
								local refresh = false
								if self.useCount == 0 and event == "ended" then 
									self.useCount = 1
									refresh = true 
								end
								endFunc(refresh)
								lastX = 0
							end
						end

						return true
					end, false, self.priority - 2, true)
				cellNode:setTouchEnabled(true)
			else
				cellNode:removeSelf()
			end

			if not added then
				cellNode:anch(0, 0):pos(xBegin + (cellSize.width + xInterval) * (nativeIndex - 1), 0)
					:addTo(parentNode, 0, tag)
			end
			tag = tag + 1
		end
	end

	local viewHandler = LuaEventHandler:create(function(fn, table, a1, a2)
		local result
		if fn == "cellSize" then
			result = CCSizeMake(viewSize.width, cellSize.height)

		elseif fn == "cellAtIndex" then
			if not a2 then
				a2 = CCTableViewCell:new()
				local cell = display.newLayer()
				a2:addChild(cell, 0, 1)
			end

			-- 更新cell
			local cell = tolua.cast(a2:getChildByTag(1), "CCNode")
			createCellNode(cell, a1, true)
			result = a2

		elseif fn == "numberOfCells" then
			result = math.ceil(#self.heros / columns)
		end

		return result
	end)

	self.heroTableView = LuaTableView:createWithHandler(viewHandler, viewSize)
	self.heroTableView:setBounceable(true)
	self.heroTableView:setTouchPriority(self.priority - 5)
	self.heroTableView:setPosition(ccp(0, 0))
	viewBg:addChild(self.heroTableView)
end

function HeroGainExpLayer:sendItemUseRequest(hero)
	
end

function HeroGainExpLayer:getLayer()
	return self.mask:getLayer()
end


return HeroGainExpLayer