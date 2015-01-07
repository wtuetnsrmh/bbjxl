local HeroRes = "resource/ui_rc/hero/"
local GlobalRes = "resource/ui_rc/global/"
local MapRes  = HeroRes.."map/"
local SellRes = HeroRes.."sell/"
local HomeRes = "resource/ui_rc/home/"
local LegendRes = "resource/ui_rc/carbon/legend/"

local FilterLogic = import(".hero.FilterLogic")

local FragmentDecomposeLayer = class("FragmentDecomposeLayer", function()
	return display.newLayer(GlobalRes .. "inner_bg.png")
end)

function FragmentDecomposeLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -130
	self.chooseFragments = {} --选择的碎片
	self.sortType = 1
	self.closeCallback = params.closeCallback
	self:anch(0, 0):pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1, bg = HomeRes .. "home.jpg" })
	self.size = self:getContentSize()

	--上层背景：
	self.upLayer = display.newSprite()
	self.upLayer:size(self.size)
	self.upLayer:pos(self:getContentSize().width / 2, self:getContentSize().height/2):addTo(self)
	self.bgSize = self.upLayer:getContentSize()

	--化魂
	local rightTab = display.newSprite(GlobalRes .. "tab_selected.png"):anch(0, 0.5)
	rightTab:pos(self.size.width - 14, 470):addTo(self)
	local tabSize = rightTab:getContentSize()
	ui.newTTFLabelWithStroke({ text = "化魂", dimensions = CCSizeMake(tabSize.width / 2, tabSize.height),font=ChineseFont , size = 26, 
		color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(tabSize.width / 2, tabSize.height / 2):addTo(rightTab)

	display.newSprite(GlobalRes .. "tab_arrow.png")
		:anch(0, 0.5):pos(self.size.width - 30, 470):addTo(self)

	--filterbar
	
	self.heroFilter = FilterLogic.new({ heros = self:getFragments(), sortRule = "noChange" })
	local FilterBar = require("scenes.home.hero.FilterBar")
	local filterBar = FilterBar.new({ dataSource = self.heroFilter, priority = self.priority - 1 })
	filterBar:anch(0, 1):pos(313, self.size.height - 17):addTo(self, 10)
	self.heroFilter:addEventListener("filter", function(event) self:initMainLayer(self.heroFilter:getResult()) end)
	self:initMainLayer(self.heroFilter:getResult())

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
	{	
		touchScale = 1.5,
		priority = self.priority -1,
		callback = function()
			if self.closeCallback then
					self.closeCallback()
			end
			self:getLayer():removeSelf()
		end,
	}):getLayer()
	closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self)

	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority})
	:anch(0,1):pos(0,display.height):addTo(self)

	-- 将魂数目
	local soulBg = display.newSprite(LegendRes .. "soul_bg.png")
	local soulBgSize = soulBg:getContentSize()
	soulBg:anch(0, 1):pos(30, self.size.height - 15):addTo(self)

	display.newSprite(GlobalRes .. "herosoul.png"):scale(1):anch(0, 0.5)
		:pos(5, soulBgSize.height / 2 + 8):addTo(soulBg)
	local heroSoulValue = ui.newTTFLabel({text = game.role.heroSoulNum, size = 20 })
	heroSoulValue:anch(0,0.5):pos(70, soulBgSize.height / 2):addTo(soulBg)
	self.soulValueHandler = game.role:addEventListener("updateHeroSoulNum", function(event)
		heroSoulValue:setString(event.heroSoulNum)
	end)

end

function FragmentDecomposeLayer:getFragments()
	local fragments = {}
	for id, num in pairs(game.role.fragments) do
		if num > 0 then
			table.insert(fragments, { type = id, num = num })
		end
	end
	table.sort(fragments, function(a, b)
		local unitDataA = unitCsv:getUnitByType(math.floor(a.type - 2000))
		local unitDataB = unitCsv:getUnitByType(math.floor(b.type - 2000))
		local factorA = unitDataA.stars * 10000 + a.num
		local factorB = unitDataB.stars * 10000 + b.num
		return factorA > factorB 
	end)
	return fragments

end

--场景初始化：
function FragmentDecomposeLayer:initMainLayer(fragments)
	if self.mainLayer then 
		self.mainLayer:removeSelf() 
	end

	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.bgSize):anch(0.5, 0.5)
		:pos(self.bgSize.width / 2, self.bgSize.height / 2):addTo(self.upLayer)

	self:showResultLayer()

	--深色底版：
	local upBg = display.newLayer()
	upBg:size(850, 352)
	upBg:anch(0.5, 0):pos(self.upLayer:getContentSize().width / 2, 143):addTo(self.mainLayer)

	local cellSize = CCSizeMake(415, 132)
	local tableSize = CCSizeMake(upBg:getContentSize().width, upBg:getContentSize().height)

	local columns = 2

	local function createCellNode(parentNode, cellIndex)
		parentNode:removeAllChildren()
		parentNode:setContentSize(CCSizeMake(upBg:getContentSize().width, cellSize.height + 10))

		local xBegin = 10
		local xInterval = (tableSize.width - 2 * xBegin - columns * cellSize.width) / (columns - 1)
		local rows = math.ceil(#fragments/ columns)
		for index = (rows - cellIndex - 1) * columns + 1, columns * (rows - cellIndex) do
			local fragment = fragments[index]
			local nativeIndex = index - (rows - cellIndex - 1) * columns

			local unitData = unitCsv:getUnitByType(fragment and math.floor(fragment.type - 2000) or 0)
			if unitData then
				local fragmentNode = display.newNode()
				fragmentNode:size(cellSize):anch(0, 0)
					:pos(xBegin + (cellSize.width + xInterval) * (nativeIndex - 1), 5)
					:addTo(parentNode)

				local checkFrame = display.newSprite(HeroRes .. "check_frame.png"):anch(1, 0)
				local heroCell = HeroListCell.new({ 
					type = fragment.type,
					priority = self.priority,
					parent = upBg,
					callback = function()
						if not self.chooseFragments[fragment.type] then
							self.chooseFragments[fragment.type] = fragment.num
							display.newSprite(HeroRes .. "checked.png"):addTo(checkFrame, 0, 100)
								:pos(checkFrame:getContentSize().width / 2, checkFrame:getContentSize().height / 2)
						else
							self.chooseFragments[fragment.type] = nil
							checkFrame:removeChildByTag(100)
						end
						self:updateResultLabel()
					end
				}):getLayer()
				heroCell:anch(0, 0):addTo(fragmentNode)
				checkFrame:pos(cellSize.width - 25, 12):addTo(heroCell)

				--当前拥有：
				local xPos, yPos = 150, 25
				local text = ui.newTTFLabel({ text = "收集：", size = 18, color = uihelper.hex2rgb("#533b22") })
				text:anch(0, 0):pos(xPos, yPos):addTo(heroCell)
				xPos = xPos + text:getContentSize().width
				-- --收集label
				local needFragmentNum = globalCsv:getComposeFragmentNum(unitData.stars)
				local col =   needFragmentNum > fragment.num and display.COLOR_RED or uihelper.hex2rgb("#009100")
				text = ui.newTTFLabel({ text = fragment.num, size = 18, color = col })
				text:anch(0, 0):pos(xPos, yPos):addTo(heroCell)
				xPos = xPos + text:getContentSize().width

				ui.newTTFLabel({ text = "/" .. needFragmentNum, size = 18, color = uihelper.hex2rgb("#533b22") })
					:anch(0, 0):pos(xPos, yPos):addTo(heroCell)



				if self.chooseFragments[fragment.type] then
					display.newSprite(HeroRes .. "checked.png"):addTo(checkFrame, 0, 100)
						:pos(checkFrame:getContentSize().width / 2, checkFrame:getContentSize().height / 2)
				end
			end
		end
	end

	local viewHandler = LuaEventHandler:create(function(fn, table, a1, a2)
		local result
		if fn == "cellSize" then
			result = CCSizeMake(self.bgSize.width, cellSize.height + 10)

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
			result = math.ceil(#fragments/ columns)
		end

		return result
	end)

	self.fragmentListView = LuaTableView:createWithHandler(viewHandler, tableSize)
	self.fragmentListView:setBounceable(true)
	self.fragmentListView:setTouchPriority(self.priority - 1)
	self.fragmentListView:setPosition(0, 10)
	upBg:addChild(self.fragmentListView)
end

function FragmentDecomposeLayer:updateResultLabel()
	self.heroChooseNum:setString(tostring(table.nums(self.chooseFragments)))
	local totalSoulNum = 0
	for fragmentId, num in pairs(self.chooseFragments) do
		local unitData = unitCsv:getUnitByType(math.floor(fragmentId - 2000))
		if unitData then
			totalSoulNum = totalSoulNum + globalCsv:getFieldValue("fragmentToSoul") * num
		end
	end
	self.soulNum:setString(tostring(totalSoulNum))
end

--底部bottom
function FragmentDecomposeLayer:showResultLayer()
	local resultLayer = display.newSprite(SellRes .. "bottom.png")
	resultLayer:anch(0.5, 0):pos(self.bgSize.width / 2, 10):addTo(self.mainLayer)

	local bgSize = resultLayer:getContentSize()

	local posY = 105
	--已选数量：
	local hasSelectNum = ui.newTTFLabel({ text = "已选碎片：", size = 24, font = ChineseFont, color = display.COLOR_WHITE })
	hasSelectNum:anch(0,0.5):pos(174,posY):addTo(resultLayer)
	

	--数量label：
	self.heroChooseNum = ui.newTTFLabel({ text = "0", size = 24, font = ChineseFont, color = uihelper.hex2rgb("#7ce810")})
	self.heroChooseNum:anch(0, 0.5):pos(294, posY):addTo(resultLayer)

	--获得魂的数量：
	local soulNumLabel = ui.newTTFLabel({ text = "共计分解：", size = 24, font = ChineseFont, color = display.COLOR_WHITE })
	soulNumLabel:anch(0,0.5):pos(464,posY):addTo(resultLayer)

	--数量label:
	self.soulNum = ui.newTTFLabel({text = "0", size = 24, font = ChineseFont, color = uihelper.hex2rgb("#7ce810")})
	self.soulNum:anch(0, 0.5):pos(0, 0.5):pos(580, posY):addTo(resultLayer)

	display.newSprite(GlobalRes .. "herosoul.png"):anch(0, 0.5):pos(660, posY + 10):addTo(resultLayer)

	local cancelBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png"},
		{	
			priority = self.priority,
			text = { text = "取消", size = 32, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
				self.chooseFragments = {}
				self:initMainLayer(self.heroFilter:getResult())
			end,
		}):getLayer()
	cancelBtn:anch(0.5, 0):pos(bgSize.width/3, 10):addTo(resultLayer)

	local confirmBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png"},
		{	
			priority = self.priority,
			text = { text = "确定", size = 32, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
				local decomposeRequest = { roleId = game.role.id, fragmentIds = table.keys(self.chooseFragments), }
				local bin = pb.encode("DecomposeFragment", decomposeRequest)
				game:sendData(actionCodes.FragmentDecomposeRequest, bin, #bin)
				loadingShow()
				game:addEventListener(actionModules[actionCodes.FragmentDecomposeResponse], function(event)
					loadingHide()

					local msg = pb.decode("DecomposeFragment", event.data)
					local totalSoulNum = 0
					for index, fragmentId in ipairs(msg.fragmentIds) do
						local unitData = unitCsv:getUnitByType(math.floor(fragmentId - 2000))
						if unitData then
							totalSoulNum = totalSoulNum + globalCsv:getFieldValue("fragmentToSoul") * game.role.fragments[fragmentId]
						end
						game.role.fragments[fragmentId] = nil
					end

					DGMsgBox.new({ type = 1, text = string.format("您获得%d 个将魂", totalSoulNum)})					

					self.chooseFragments = {}

					self.heroFilter.source = self:getFragments()
					self.heroFilter:filter()
					self:initMainLayer(self.heroFilter:getResult())

					return "__REMOVE__"
				end)
			end,
		}):getLayer()
	confirmBtn:anch(0.5, 0):pos(bgSize.width/3*2, 10):addTo(resultLayer)

	-- return resultLayer, bgSize
end


function FragmentDecomposeLayer:getLayer()
	return self.mask:getLayer()
end

function FragmentDecomposeLayer:onExit(  )
	game.role:removeEventListener("updateHeroSoulNum", self.soulValueHandler)
end

function FragmentDecomposeLayer:onCleanup()
	display.removeUnusedSpriteFrames()
end

return FragmentDecomposeLayer