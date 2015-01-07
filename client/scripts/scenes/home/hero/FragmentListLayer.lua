local GlobalRes = "resource/ui_rc/global/"

--New Source Path 
local HeroRes = "resource/ui_rc/hero/"
local GrowthRes = HeroRes.."growth/"
local FragmentRes = HeroRes.."frag/"
local ShopRes = "resource/ui_rc/shop/"
local LegendRes = "resource/ui_rc/carbon/legend/"

local ItemSourceLayer = require("scenes.home.ItemSourceLayer")
local HeroCardLayer = import(".HeroCardLayer")
local HeroInfoLayer = import(".HeroInfoLayer")

local FilterLogic = import(".FilterLogic")
local FilterBar = import(".FilterBar")

local function fragmentSort(a, b)
	local unitDataA = unitCsv:getUnitByType(math.floor(a.type - 2000))
	local unitDataB = unitCsv:getUnitByType(math.floor(b.type - 2000))
	local factorA = (a.num >= globalCsv:getComposeFragmentNum(unitDataA.stars) and 1000000 or 0) + a.num * 10 + unitDataA.stars
	local factorB = (b.num >= globalCsv:getComposeFragmentNum(unitDataB.stars) and 1000000 or 0) + b.num * 10 + unitDataB.stars
	return factorA > factorB  
end

local function getFragments()
	local fragments = {}
	for _,hero in pairs(unitCsv.m_data) do
		if hero.heroOpen > 0 and not game.role:heroExist(hero.type) then
			local fragType = hero.type + 2000
			table.insert(fragments, { type = fragType, num = tonum(game.role.fragments[fragType]) })
		end
	end
	table.sort(fragments, fragmentSort)
	return fragments
end

local FragmentListLayer = class("FragmentListLayer", function(params)
	return display.newLayer()
end)

function FragmentListLayer:ctor(params)
	params = params or {}
	self.priority = params.priority or -132
	self.parent = params.parent
	self:size(869, 554)
	self.tipsTag = 2322

	self:anch(0.5, 0):pos(display.cx, 0)

	self.bgSize = self:getContentSize()


	self.cellSize = CCSizeMake(415, 132)
	self.tableSize = CCSizeMake(self.bgSize.width, self.bgSize.height - 90)

	self.tableLayer = display.newLayer()
	self.tableLayer:size(self.tableSize):anch(0.5, 0.5):pos(self.bgSize.width/2, self.bgSize.height/2 - 20):addTo(self)

	game.role:updateNewMsgTag()

	local fragments = getFragments()
	self.heroFilter = FilterLogic.new({ heros = fragments, sortRule = "noChange" })
	local filterBar = FilterBar.new({ dataSource = self.heroFilter, priority = self.priority - 1 })
	filterBar:anch(0, 1):pos(292, self.bgSize.height):addTo(self,10)
	self.heroFilter:addEventListener("filter", function(event) self:showFragments(self.heroFilter:getResult()) end)
	self:showFragments(fragments)

	-- 将魂数目
	local soulBg = display.newSprite(LegendRes .. "soul_bg.png")
	local soulBgSize = soulBg:getContentSize()
	soulBg:anch(0, 1):pos(30, self.bgSize.height + 3):addTo(self)

	display.newSprite(GlobalRes .. "herosoul.png"):scale(1):anch(0, 0.5)
		:pos(5, soulBgSize.height / 2 + 8):addTo(soulBg)
	local heroSoulValue = ui.newTTFLabel({text = game.role.heroSoulNum, size = 20 })
	heroSoulValue:anch(0,0.5):pos(70, soulBgSize.height / 2):addTo(soulBg)
	self.soulValueHandler = game.role:addEventListener("updateHeroSoulNum", function(event)
		heroSoulValue:setString(event.heroSoulNum)
	end)
end

function FragmentListLayer:onEnter()
	self:checkGuide()
end

function FragmentListLayer:checkGuide(remove)
	game:addGuideNode({node = self.guideBtn, remove = remove,
		guideIds = {502}
	})
	if self.fragmentTableView then
		self.fragmentTableView:setTouchEnabled(not game:hasGuide())
	end
end

--刷新碎片显示：
function FragmentListLayer:showFragments(fragmentData)
	self.tableLayer:removeAllChildren()
	self:removeChildByTag(10)
	self:removeChildByTag(20)

	local columns = 2
	local fragments = fragmentData

	local function createCellNode(parentNode, cellIndex)
		parentNode:removeAllChildren()
		parentNode:setContentSize(CCSizeMake(self.bgSize.width, self.cellSize.height + 10))

		local xBegin = 15
		local xInterval = (self.tableSize.width - 2 * xBegin - columns * self.cellSize.width) / (columns - 1)
		local rows = math.ceil(#fragments / columns)
		for index = (rows - cellIndex - 1) * columns + 1, columns * (rows - cellIndex) do
			local fragment = fragments[index]
			local nativeIndex = index - (rows - cellIndex - 1) * columns
			local cellNode = display.newNode()
			cellNode:size(self.cellSize)	
			
			local unitData = unitCsv:getUnitByType(fragment and math.floor(fragment.type - 2000) or 0)
			local gotoBtn 
			if unitData then
				local needFragmentNum = globalCsv:getComposeFragmentNum(unitData.stars)
				local canCompose = fragment.num >= needFragmentNum
				local heroCell
				heroCell = HeroListCell.new({ 
					type = fragment.type,
					priority = self.priority,
					parent = self.tableLayer,
					notSendClickEvent = true,
					gray = not canCompose,
					headCallback = not canCompose and function()
						local layer = HeroInfoLayer.new({heroType = fragment.type - 2000, priority = self.priority - 10,})
						layer:getLayer():addTo(display.getRunningScene())
					end or nil,
					callback = function()
						if canCompose then
							local exchangeRequest = { roleId = game.role.id, param1 = fragment.type, }
							local bin = pb.encode("SimpleEvent", exchangeRequest)
							game:sendData(actionCodes.FragmentExchangeRequest, bin, #bin)
							loadingShow()
							game:addEventListener(actionModules[actionCodes.FragmentExchangeResponse], function(event)
								loadingHide()
								game:dispatchEvent({name = "btnClicked", data = heroCell})
								local msg = pb.decode("SimpleEvent", event.data)

								local fragments = getFragments()
								self.heroFilter.source = fragments
								self.heroFilter:filter()

								self:showFragments(self.heroFilter:getResult())

								game.role:dispatchEvent({ name = "notifyNewMessage", type = "composeFragment" })
								game.role:updateNewMsgTag()


								DGMsgBox.new({ type = 1, 
									text = string.format("恭喜获得[color=ff00ff00]%s[/color]卡牌！", unitData.name)})

								-- 展示卡牌
								local heroCard = HeroCardLayer.new({ heroType = unitData.type })
								heroCard:anch(0.5, 0.5):scale(0.1):center()
								local mask, actionOver
								mask = DGMask:new({ item = heroCard, priority = self.priority - 10,
									click = function() 
										if not actionOver then return end
										mask:remove()
									end })
								mask:getLayer():addTo(display.getRunningScene())
								local actions = transition.sequence({
									CCScaleTo:create(0.1, 0.6),
									CCScaleTo:create(0.2, 0.45),
									CCScaleTo:create(0.1, 0.5),
									CCCallFunc:create(function() 
										actionOver = true
										game:playMusic(unitData.skillMusicId)
										--新手引导
										game:addGuideNode({rect = CCRectMake(0, 0, display.width, display.height), opacity = 0,
											guideIds = {910},
											onClick = function() mask:remove() end,
										})

									end)
								})
								heroCard:runAction(actions)
								display.newSprite(ShopRes .. "drawcard/card_light_bg.png"):scale(4):pos(heroCard:getContentSize().width / 2, heroCard:getContentSize().height / 2)
								:addTo(heroCard, -2):runAction(CCRepeatForever:create(CCRotateBy:create(0.5, 15)))
								display.newSprite(ShopRes .. "drawcard/card_light_bg.png"):scale(4):pos(heroCard:getContentSize().width / 2, heroCard:getContentSize().height / 2)
								:addTo(heroCard, -2):rotation(30):runAction(CCRepeatForever:create(CCRotateBy:create(0.5, -15)))

								CCNodeExtend.extend(CCParticleSystemQuad:create(ParticleRes .. "card_particles.plist")):pos(heroCard:getContentSize().width / 2, heroCard:getContentSize().height / 2)
								:addTo(heroCard, -1)
	
								return "__REMOVE__"
							end)
						else
							local itemId = math.floor(fragment.type - 2000) + 2000
							local sourceLayer = ItemSourceLayer.new({ priority = self.priority - 300, itemId = itemId,
									closeCallback = function()
										local offset = self.fragmentTableView:getContentOffset()
										local fragments = getFragments()
										self.heroFilter.source = fragments
										self.heroFilter:filter()
										self:showFragments(self.heroFilter:getResult())
										self.fragmentTableView:setContentOffset(offset, false)
									end })
							sourceLayer:getLayer():addTo(display.getRunningScene())
						end
					end
				}):getLayer()
				heroCell:anch(0, 0):addTo(cellNode)
				if index == 1 then
					self.guideBtn = heroCell
					--新手引导
					if canCompose and game:activeSpecialGuide(502) then
						self:checkGuide()
					end
				end

				-- 经验条
				local expSlot = display.newSprite( HeroRes .. "growth/exp_long_bg.png")
				expSlot:anch(0, 0):pos(150, 30):addTo(heroCell)
				local expProgress = display.newProgressTimer(HeroRes .. "growth/exp_long_fg.png", display.PROGRESS_TIMER_BAR)
				expProgress:setMidpoint(ccp(0, 0.5))
				expProgress:setBarChangeRate(ccp(1,0))
				expProgress:setPercentage( fragment.num / needFragmentNum * 100)
				
				expProgress:pos(expSlot:getContentSize().width/2, expSlot:getContentSize().height/2):addTo(expSlot)
				
				ui.newTTFLabel({text = canCompose and "可召唤" or string.format("%d / %d", fragment.num, needFragmentNum), size = 18})
					:anch(0.5,0.5):pos(expSlot:getContentSize().width/2, expSlot:getContentSize().height/2):addTo(expSlot)
			end
			cellNode:anch(0, 0):pos(xBegin + (self.cellSize.width + xInterval) * (nativeIndex - 1), 10)
				:addTo(parentNode)
		end
	end

	local viewHandler = LuaEventHandler:create(function(fn, table, a1, a2)
		local result
		if fn == "cellSize" then
			result = CCSizeMake(self.bgSize.width, self.cellSize.height + 10)

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
			result = math.ceil(#fragments / columns)
		end
		return result
	end)
	self.fragmentTableView = LuaTableView:createWithHandler(viewHandler, self.tableSize)
	self.fragmentTableView:setBounceable(true)
	self.fragmentTableView:setTouchPriority(self.priority - 100)

	self.tableLayer:addChild(self.fragmentTableView)
end

function FragmentListLayer:showItemTaps(itemID,itemHave,itemType)
	self:purgeItemTaps()
	local itemTipsView = require("scenes.home.ItemTipsLayer")
	local itemTips = itemTipsView.new({
		itemId = itemID,
		itemNum = itemHave,
		itemType = itemType,
		})
	display.getRunningScene():addChild(itemTips:getLayer())
	itemTips:setTag(self.tipsTag)

end

function FragmentListLayer:purgeItemTaps()
	if display.getRunningScene():getChildByTag(self.tipsTag) then
		display.getRunningScene():getChildByTag(self.tipsTag):removeFromParent()
	end
end

function FragmentListLayer:getLayer()
	return self.mask:getLayer()
end

function FragmentListLayer:onExit()
	self:checkGuide(true)
	if self.fragmentTag then
		game.role:removeEventListener("notifyNewMessage", self.fragmentTag)
	end
	game.role:removeEventListener("updateHeroSoulNum", self.soulValueHandler)
end

return FragmentListLayer