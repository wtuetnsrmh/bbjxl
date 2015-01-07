-- 星星奖励显示层
-- by yangkun
-- 2014.5.14

local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"
local DrawCardRes = "resource/ui_rc/shop/drawcard/"
local AwardRes = "resource/ui_rc/carbon/award/"

local StarAwardLayer = class("StarAwardLayer", function(params) 
	return display.newLayer(AwardRes .. "box_small_bg.png") 
end)

function StarAwardLayer:ctor(params)

	params = params or {}

	self.priority = params.priority or -129
	self.parent = params.parent
	self.mapId = params.mapId
	self.boxIndex = params.boxIndex
	self.totalStarNum = params.totalStarNum
	self.callback = params.callback
	self.dismissCallback = params.dismissCallback
	self.tipsTag = 7878
	self:initUI()
	local techData = techItemCsv:getDataByMap(self.mapId)
	local mapInfoData = mapInfoCsv:getMapById(self.mapId)
	local awardData = game.role.mapTypeDataset[mapInfoData.type][self.mapId]
	
	self:initContentLayer()

end

function StarAwardLayer:initUI()
	self.size = self:getContentSize()

	local topBg = display.newSprite(GlobalRes .. "title_bar_long.png")
	topBg:anch(0.5,1):pos(self:getContentSize().width/2, self.size.height - 10):addTo(self)

	display.newSprite(AwardRes .. "title_text.png")
		:pos(topBg:getContentSize().width/2,topBg:getContentSize().height/2):addTo(topBg)

	self:anch(0.5,0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self , priority = self.priority, ObjSize = CCSizeMake(660, 332),
		clickOut = function() 
			self.mask:remove() 
			self.dismissCallback()
		end})
end

function StarAwardLayer:initContentLayer()
	if self.contentLayer then
		self.contentLayer:removeSelf()
	end

	self.contentLayer = display.newLayer()
	self.contentLayer:size(self:getContentSize())
	self.contentLayer:addTo(self)
	local contentSize = self:getContentSize()

	-- 灰色底板
	local itemBg = display.newLayer()
	itemBg:size(CCSizeMake(554, 164))
	itemBg:anch(0.5, 0):pos(contentSize.width / 2, contentSize.height - 233):addTo(self.contentLayer)

	local techData = techItemCsv:getDataByMap(self.mapId)
	local mapInfoData = mapInfoCsv:getMapById(self.mapId)
	local awardData = game.role.mapTypeDataset[mapInfoData.type][self.mapId]
	self.lastPageNum = table.nums(awardData)
	self.scrollView = DGPageView.new({
		priority=self.priority-3,
		size = CCSizeMake(self.contentLayer:getContentSize().width-80,self.contentLayer:getContentSize().height),
		dataSource = {1,2,3},
		initPageIndex = self.boxIndex,
		lastPageIndex = self.lastPageNum,
		cellAtIndex = function(index) 
			return self:createCell(index)
		end
	})
	self.scrollView:getLayer():pos(40,0):addTo(self.contentLayer)

	self.listenChangePage=self.scrollView:addEventListener("changePageIndex", function(event)
		self:refreshArrow(event.pageIndex)
	end)
	self:refreshArrow(self.boxIndex)

	--星级数量
	local starLable = DGRichLabel.new({ size = 22, font = ChineseFont })
	local text = "[color=7ce810]" .. self.totalStarNum .. "[/color]/"..3 * mapInfoData.carbonNum
	starLable:setString(text)
	starLable:setPosition(CCPoint(508,283))
	starLable:setAnchorPoint(CCPoint(1,0.5))
	self.contentLayer:addChild(starLable)
	
	local star2 = display.newSprite( GlobalRes .. "star/icon_popup.png")	
	star2:anch(0,0.5):pos(contentSize.width-70,contentSize.height-32):addTo(self.contentLayer)
end

function StarAwardLayer:refreshArrow(curIndex)
	if self.arrowLayer then
		self.arrowLayer:removeSelf()
	end

	self.arrowLayer = display.newLayer()
	self.arrowLayer:size(self:getContentSize())
	self.arrowLayer:addTo(self)

	-- 左右滑动箭头
	if curIndex ~= 1 then
		local leftArrowBtn = DGBtn:new(DrawCardRes , {"arrow_left.png", "arrow_left.png", "arrow_left.png"}, {
			priority=self.priority-4,
				callback = function()
					if not self.scrollView.isScroll then
						self.scrollView:autoScroll(0)
					end
				end
			})
		leftArrowBtn:setEnable(curIndex > 1)
		leftArrowBtn:getLayer():anch(1, 0.5):pos(38, self:getContentSize().height / 2):addTo(self.arrowLayer, 1)
	end

	if curIndex < self.lastPageNum then
		local rightArrowBtn = DGBtn:new(DrawCardRes , {"arrow_right.png", "arrow_right.png", "arrow_right.png"}, {
				priority=self.priority-4,
				callback = function()
					if not self.scrollView.isScroll then
						self.scrollView:autoScroll(1)
					end
				end
			})
		rightArrowBtn:getLayer():anch(1,0.5):pos(self:getContentSize().width, self:getContentSize().height / 2):addTo(self.arrowLayer, 1)
	end
	
end

function StarAwardLayer:nextBox()

	self.boxIndex = self.boxIndex + 1
	if self.boxIndex <= self.lastPageNum then 
		self.scrollView:setEnable(false)
		if not self.scrollView.isScroll then
			require("framework.scheduler").performWithDelayGlobal(function()
				if not self.scrollView.isScroll then
					self.scrollView:setEnable(true)
					self.scrollView.drag.active = true
					self.scrollView:autoScroll(1)
				end

			end, 0.1)
		end
	end
end

function StarAwardLayer:createCell(index)
	local cellNode = display.newNode():size(self.contentLayer:getContentSize())
	local contentSize = self:getContentSize()

	local techData = techItemCsv:getDataByMap(self.mapId)
	local mapInfoData = mapInfoCsv:getMapById(self.mapId)
	local awardData = game.role.mapTypeDataset[mapInfoData.type][self.mapId]
	
	local awardItems = techData["award" .. index]

	local initX = -40
	local i = -1
	for type, count in pairs(awardItems) do
		local itemId = tonum(type)
		local itemData = itemCsv:getItemById(itemId)
		local itemFrame = ItemIcon.new({ itemId = itemId, 
					callback = function() 
						self:showItemTaps(itemId,count,itemData.type)
					end,
					priority = self.priority - 2,
				}):getLayer()
		itemFrame:anch(0.5,0.5):pos(contentSize.width/2 + i * 140+initX, contentSize.height/2 + 30):addTo(cellNode)

		
		ui.newTTFLabel({text = itemData.name, size = 22, color = display.COLOR_DARKYELLOW })
			:anch(0.5,1):pos(itemFrame:getContentSize().width/2, -5):addTo(itemFrame )

		ui.newTTFLabel({text = "x"..count, size = 20, color = display.COLOR_GREEN})
		:anch(1,0):pos(itemFrame:getContentSize().width - 6, 6):addTo(itemFrame)

		i = i + 1
	end
	local status = awardData["award".. index .."Status"]
	local needStarNum = tonum(techData.awardStarNums[tostring(index)])
	if status == 1 then
		local getBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png", "middle_disabled.png"},
		{	
			priority = self.priority,
			text = {text = "已领取", size = 32, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 1 },
			disable = true,
			callback = function()
			end,
		})
		getBtn:getLayer():anch(0.5,0):pos(contentSize.width/2+initX, 15):addTo(cellNode)
	elseif (status == 0 and self.totalStarNum >= needStarNum) then
		-- 使用
		local useBtn = DGBtn:new(GlobalRes , {"middle_normal.png", "middle_selected.png", "middle_disabled.png"}, {
				text = { text = "领取", size = 32, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
				callback = function()
					local bin = pb.encode("SimpleEvent", 
							{ roleId = game.role.id, param1 = self.mapId, param2 = tonum(index) })
					game:sendData(actionCodes.CarbonOpenAwardRequest, bin)
					loadingShow()
					game:addEventListener(actionModules[actionCodes.CarbonOpenAwardResponse], function(event)
						loadingHide()
						local msg = pb.decode("SimpleEvent", event.data)

						awardData["award".. index .."Status"] = 1

						self.callback()
						self.scrollView:refresh()
						self:nextBox()
						
						-- self.dismissCallback()
						-- self.mask:remove() 

						return "__REMOVE__"
					end)
				end,
				priority = self.priority - 2
			})
		useBtn:getLayer():anch(0.5,0):pos(contentSize.width/2+initX, 15):addTo(cellNode)
		self.useBtn = useBtn:getLayer()
	else
		ui.newTTFLabelWithStroke({ text = string.format("达到 %d        可领取", needStarNum), size = 28, font = ChineseFont, color = display.COLOR_WHITE, strokeColor = display.COLOR_BLACK })
		:anch(0.5, 0):pos(contentSize.width/2+initX, 24):addTo(cellNode)

		display.newSprite(HeroRes .. "star.png"):anch(0.5,0):pos(contentSize.width/2 + 10+initX, 28):addTo(cellNode)
	end

	return cellNode
end

function StarAwardLayer:getLayer()
	return self.mask:getLayer()
end

function StarAwardLayer:onCleanup()
	game:dispatchEvent({name = "btnClicked", data = self:getLayer()})
end


function StarAwardLayer:showItemTaps(itemId,itemNum,itemType)
	self:purgeItemTaps()
	local itemTipsView = require("scenes.home.ItemTipsLayer")
	local itemTips = itemTipsView.new({
		itemId = itemId,
		itemNum = itemNum,
		itemType = itemType,
		})
	display.getRunningScene():addChild(itemTips:getLayer())
	itemTips:setTag(1000)
end

function StarAwardLayer:purgeItemTaps()
	if display.getRunningScene():getChildByTag(1000) then
		display.getRunningScene():getChildByTag(1000):removeFromParent()
	end
end

return StarAwardLayer