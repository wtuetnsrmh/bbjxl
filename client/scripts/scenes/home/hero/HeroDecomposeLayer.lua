local HeroRes = "resource/ui_rc/hero/"
local GlobalRes = "resource/ui_rc/global/"
local HomeRes = "resource/ui_rc/home/"
local MapRes  = HeroRes.."map/"
local TowerRes = "resource/ui_rc/activity/tower/"
local AwardRes = "resource/ui_rc/carbon/award/"

local FilterLogic = import(".FilterLogic")
local FilterBar = import(".FilterBar")
local HeroInfoLayer = import(".HeroInfoLayer")

local HeroDecomposeLayer = class("HeroDecomposeLayer", function(params)
	return display.newLayer(GlobalRes .. "inner_bg.png")
end)

function HeroDecomposeLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -132
	self.closeCallback = params.closeCallback
	self.size = self:getContentSize()

	-- 遮罩层
	self:anch(0, 0):pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self , priority = self.priority + 1, bg = HomeRes .. "home.jpg"})

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
				if self.closeCallback then
					self.closeCallback()
				end
				self:getLayer():removeSelf()
			end,
		}):getLayer()
	closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self)

	-- 右侧按钮
	local tabLabel = display.newSprite(GlobalRes .. "tab_selected.png")
	tabLabel:anch(0, 0.5):pos(self:getContentSize().width - 14, 470):addTo(self)
	local btnSize = tabLabel:getContentSize()

	display.newSprite(GlobalRes.."tab_arrow.png"):anch(1,0.5):pos(10, btnSize.height/2)
		:addTo(tabLabel)

	ui.newTTFLabelWithStroke({ text = "分解", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(tabLabel)

	self.heros = self:filterHeros()


	self:showMyHeroNums()

	self.heroFilter = FilterLogic.new({ heros = self.heros, sortRule = "noChange" })
	local filterBar = FilterBar.new({ dataSource = self.heroFilter, priority = self.priority - 10})
	filterBar:anch(0, 1):pos(313, self.size.height - 17):addTo(self, 10)

	self:listHeros()

	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority})
	:anch(0,1):pos(0,display.height):addTo(self)
end

function HeroDecomposeLayer:filterHeros()
	local heros = {}

	for id, hero in pairs(game.role.heros) do
		-- 非素材卡
		if not (hero.type >= 991 and hero.type <= 999) and hero.master == 0 and hero.choose == 0  and hero.unitData.stars >= 3 then
			table.insert(heros, hero)
		end
	end

	table.sort(heros, function(a,b) 
		local unitDataA = unitCsv:getUnitByType(a.type)
		local unitDataB = unitCsv:getUnitByType(b.type)
		local factorA = a.star * 1000000 + a.type * 100 - a.level
		local factorB = b.star * 1000000 + b.type * 100 - b.level
		return factorA > factorB 
	end)

	return heros
end

function HeroDecomposeLayer:listHeros()

	local cellSize = CCSizeMake(415, 132)
	local columns = 2
	local heroNum = #self.heroFilter:getResult()
	local viewBg = display.newLayer()
	viewBg:size(850, 474)
	local viewSize = CCSizeMake(viewBg:getContentSize().width, viewBg:getContentSize().height)
	viewBg:anch(0.5, 0):pos(self.size.width / 2, 20):addTo(self)

	local function createCellNode(parentNode, cellIndex)
		parentNode:removeAllChildren()
		parentNode:setContentSize(CCSizeMake(viewSize.width, cellSize.height + 10))
		local xBegin = 5
		local xInterval = (viewSize.width - 2 * xBegin - columns * cellSize.width) / (columns - 1)
		local rows = math.ceil(#self.heroFilter:getResult() / columns)
		for index = (rows - cellIndex - 1) * columns + 1, columns * (rows - cellIndex) do
			local hero = self.heroFilter:getResult()[index]
			local nativeIndex = index - (rows - cellIndex - 1) * columns
			local cellNode = display.newNode()
			cellNode:size(cellSize)

			if hero then
				local decompMoney = hero:getSellMoney(true)
				local heroCell = HeroListCell.new({ type = hero.type, level = hero.level, 
					wakeLevel = hero.wakeLevel,
					star = hero.star,
					evolutionCount = hero.evolutionCount, priority = self.priority,
					parent = viewBg,
					callback = function()
						local decomposeBg = display.newSprite(AwardRes .. "box_small_bg.png")
						decomposeBg:anch(0.5, 0.5):pos(display.cx, display.cy)
						local mask = DGMask:new({item = decomposeBg, priority = self.priority - 20})
						mask:getLayer():addTo(display.getRunningScene())
						local bgSize = decomposeBg:getContentSize()
						--武将分解
						display.newSprite(GlobalRes .. "title_bar.png")
							:anch(0.5, 1):pos(bgSize.width / 2, bgSize.height - 10):addTo(decomposeBg)
						display.newSprite(HeroRes .. "hero_decompose.png")
							:anch(0.5, 1):pos(bgSize.width / 2, bgSize.height - 10):addTo(decomposeBg)

						local posY = bgSize.height - 135
						HeroHead.new({type = hero.type, hideStars = true, wakeLevel = hero.wakeLevel, star = hero.star, evolutionCount = hero.evolutionCount})
							:getLayer():anch(0, 0.5):pos(130, posY):addTo(decomposeBg)
						display.newSprite(HeroRes .. "decompose_arrow.png")
							:anch(0, 0.5):pos(295, posY):addTo(decomposeBg)
						HeroHead.new({type = hero.type + 2000, hideStars = true})
							:getLayer():anch(0, 0.5):pos(380, posY):addTo(decomposeBg)

						--分解结果文字
						local fontBg = display.newSprite(HeroRes .. "dec_result_bg.png")
						fontBg:anch(0.5, 0):pos(bgSize.width / 2, 100):addTo(decomposeBg)
						local fontBgSize = fontBg:getContentSize()
						local fragmentNum = hero.unitData.decompose[hero.wakeLevel]
						ui.newTTFLabel({text = hero.unitData.name, size = 20, color = uihelper.hex2rgb("#edb833")})
							:anch(0.5, 0.5):pos(125, fontBgSize.height/2):addTo(fontBg)
						ui.newTTFRichLabel({text = string.format("分解为[color=ff7ce810]%d[/color]个", fragmentNum), size = 20})
							:anch(0, 0.5):pos(180, fontBgSize.height/2):addTo(fontBg)
						ui.newTTFLabel({text = hero.unitData.name .. "碎片", size = 20, color = uihelper.hex2rgb("#edb833")})
							:anch(0.5, 0.5):pos(375, fontBgSize.height/2):addTo(fontBg)

						--按钮
						DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png", "middle_disabled.png"}, {
							text = {text = "取消", size = 28, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
							priority = self.priority -30,
							callback = function()
								mask:remove()
							end
						}):getLayer():anch(0.5, 0):pos(bgSize.width/3, 15):addTo(decomposeBg)

						DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png", "middle_disabled.png"}, {
							text = {text = "分解", size = 28, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
							priority = self.priority - 30,
							callback = function()
								local bin = pb.encode("SimpleEvent", { roleId = game.role.id, param1 = hero.id })
								game:sendData(actionCodes.HeroDecomposeRequest, bin, #bin)
								loadingShow()
								game:addEventListener(actionModules[actionCodes.HeroDecomposeResponse], function(event)
									loadingHide()
									
									--数据处理
									local fragmentId = hero.type + 2000
									if game.role.fragments[fragmentId] then
										game.role.fragments[fragmentId] = game.role.fragments[fragmentId] + fragmentNum
									else
										game.role.fragments[fragmentId] = fragmentNum
									end
									game.role.heros[hero.id] = nil
								
									--界面显示
									local resultBg = display.newSprite(GlobalRes .. "tips_small.png")
									resultBg:anch(0.5, 0.5):pos(display.cx, display.cy)
									DGMask:new({
										item = resultBg, 
										priority = self.priority - 40, 
										click = function()
											mask:remove()
											--重载数据,记录offset保证回到原来视图进度
											local offset = self.heroTableView:getContentOffset()
											self.heros = self:filterHeros()
											self.heroFilter.source = self.heros
											self.heroFilter:filter()
											self.heroTableView:reloadData()
											self:showMyHeroNums()
											--暂时关闭，保证offset在最大和最小之间
											self.heroTableView:setBounceable(false)
											self.heroTableView:setContentOffset(offset, false)
											self.heroTableView:setBounceable(true)
										end}):getLayer():addTo(mask:getLayer())

									local text = string.format("你获得[color=ff12f3ff]%d[/color]个[color=ffffec18]%s碎片[/color]", fragmentNum, hero.unitData.name)
									if decompMoney > 0 then
										text = string.format("%s和%d银币", text, decompMoney)
									end
									ui.newTTFRichLabel({text = text, size = 24})
										:anch(0.5, 0.5):pos(resultBg:getContentSize().width/2, resultBg:getContentSize().height/2):addTo(resultBg)
								end)
							end
						}):getLayer():anch(0.5, 0):pos(bgSize.width/3*2, 15):addTo(decomposeBg)
					end
				}):getLayer()
				heroCell:anch(0, 0):addTo(cellNode)

				local cellSize = heroCell:getContentSize()

				-- 碎片
				local posY = 33
				local fragment = display.newSprite(HeroRes .. "fragment_tag.png"):anch(0, 0.5):pos(145, posY)
				:addTo(heroCell)

				--碎片Num
				ui.newTTFLabelWithStroke({text = hero.unitData.decompose[hero.wakeLevel], size = 28, font = ChineseFont, strokeColor = display.COLOR_FONT })
					:anch(0, 0.5):pos(fragment:getContentSize().width + fragment:getPositionX() + 7, posY-1):addTo(heroCell)

				--分解获得银币
				if decompMoney > 0 then
					local money = display.newSprite(GlobalRes .. "yinbi_big.png"):anch(0, 0.5):pos(245, posY)
					:addTo(heroCell)

					ui.newTTFLabelWithStroke({text = decompMoney, size = 28, font = ChineseFont, strokeColor = display.COLOR_FONT })
						:anch(0, 0.5):pos(money:getContentSize().width + money:getPositionX() + 7, posY-1):addTo(heroCell)
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
			result = math.ceil(#self.heroFilter:getResult() / columns)
		end

		return result
	end)

	self.heroTableView = LuaTableView:createWithHandler(viewHandler, viewSize)
	self.heroTableView:setBounceable(true)
	self.heroTableView:setTouchPriority(self.priority - 1)
	self.heroTableView:setPosition(ccp(0, 5))
	viewBg:addChild(self.heroTableView)

	self.heroFilter:addEventListener("filter", function(event) self.heroTableView:reloadData() end)
end

--拥有武将数量：
function HeroDecomposeLayer:showMyHeroNums()
	if self.infoBg then
		self.infoBg:removeSelf()
	end
	self.infoBg = display.newSprite(GlobalRes .. "label_bg.png"):anch(0, 1)
	:pos(40, self.size.height - 13)
	:addTo(self)
	local xPos, yPos = 8, self.infoBg:getContentSize().height/2
	local text = ui.newTTFLabel({text = "拥有武将：", size = 20})
	text:anch(0, 0.5):pos(xPos, yPos):addTo(self.infoBg)
	xPos = xPos + text:getContentSize().width

	local heroNums = table.nums(self.heros)
	text = ui.newTTFLabel({text = heroNums, size = 20, color = heroNums > 0 and uihelper.hex2rgb("#7ce810") or display.COLOR_RED })
	text:anch(0, 0.5):pos(xPos, yPos):addTo(self.infoBg)
	xPos = xPos + text:getContentSize().width
end

function HeroDecomposeLayer:getLayer()
	return self.mask:getLayer()
end

return HeroDecomposeLayer