local GlobalRes = "resource/ui_rc/global/"
local TowerRes = "resource/ui_rc/activity/tower/"

local RoleDetailLayer = import("..RoleDetailLayer")

local TowerRankLayer = class("TowerRankLayer", function()
	return display.newLayer(GlobalRes .. "rank/rank_bg.png")
end)

function TowerRankLayer:ctor(params)
	params = params or {}

	self.size = self:getContentSize()
	self.priority = params.priority or -130

	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1 })

	-- 关闭按钮
	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"}, 
		{
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
				self:getLayer():removeSelf()
			end,
		}):getLayer()
	closeBtn:anch(0.5, 0.5):pos(self.size.width, self.size.height):addTo(self)

	local titlebg = display.newSprite(GlobalRes .. "title_bar.png")
		:pos(self.size.width/2, self.size.height - 35):addTo(self)
	display.newSprite(GlobalRes .. "rank/rank_text.png")
		:pos(titlebg:getContentSize().width/2, titlebg:getContentSize().height/2):addTo(titlebg)

	self.rankMapData = params.rankMapData

	local cellSize = display.newSprite(GlobalRes .. "rank/rank_cell.png"):getContentSize()
	local scrollView

	local function createCellNode(cellNode, rankData)
		display.newSprite(GlobalRes .. "rank/rank_cell.png")
			:pos(cellSize.width / 2, cellSize.height / 2):addTo(cellNode)
	
		-- rank
		if rankData.index <= 3 then
			display.newSprite(GlobalRes .. string.format("rank/rank_%d.png", rankData.index))
				:pos(60, cellSize.height / 2):addTo(cellNode)
		end
		ui.newBMFontLabel({ text = rankData.index, font = GlobalRes .. "rank/rank.fnt"})
			:pos(60, cellSize.height / 2):addTo(cellNode)

		if rankData.mainHeroType > 0 then
			local headFrame = HeroHead.new({type = rankData.mainHeroType, wakeLevel = rankData.mainHeroWakeLevel, star = rankData.mainHeroStar, evolutionCount = rankData.mainHeroEvolutionCount})
			headFrame:getLayer():anch(0.5, 0.5):pos(180, cellSize.height / 2):addTo(cellNode)
		end

		local infoBg = display.newSprite(GlobalRes .. "cell_namebar.png")
		infoBg:anch(0, 1):pos(260, cellSize.height - 20):addTo(cellNode)
		local infoSize = infoBg:getContentSize()
		ui.newTTFLabel({text = rankData.name, size = 26, color = display.COLOR_WHITE, font = ChineseFont })
			:anch(0, 0.5):pos(20, infoSize.height / 2):addTo(infoBg)
		ui.newTTFLabel({text = "Lv. " .. rankData.level, size = 26, color = uihelper.hex2rgb("#ffdc7d") })
			:anch(1, 0.5):pos(infoSize.width - 20, infoSize.height / 2):addTo(infoBg)

		ui.newTTFLabelWithStroke({ text = "闯关 ", size = 20, color = display.COLOR_WHITE, font = ChineseFont,
			strokeColor = uihelper.hex2rgb("#242424") })
			:anch(0, 0.5):pos(260, 25):addTo(cellNode)
		ui.newTTFLabelWithStroke({text = rankData.carbonNum, size = 20, font = ChineseFont, color = uihelper.hex2rgb("#ffd200") })
			:anch(0, 0.5):pos(320, 25):addTo(cellNode)
		ui.newTTFLabelWithStroke({ text = "得星 ", size = 20, color = display.COLOR_WHITE, font = ChineseFont, 
			strokeColor = uihelper.hex2rgb("#242424") })
			:anch(0, 0.5):pos(390, 25):addTo(cellNode)
		local starNumLabel=ui.newTTFLabelWithStroke({text = rankData.totalStarNum, size = 20, font = ChineseFont, color = display.COLOR_WHITE, 
			strokeColor = uihelper.hex2rgb("#242424") })
			:anch(0, 0.5):pos(440, 25):addTo(cellNode)
		display.newSprite(GlobalRes .. "star/icon_small.png"):anch(0, 0.5)
			:pos(starNumLabel:getPositionX()+starNumLabel:getContentSize().width+2,
			 starNumLabel:getPositionY()+3):addTo(cellNode)

		local queryBtn = DGBtn:new(GlobalRes, {"square_green_normal.png", "square_green_selected.png"},
			{	
				priority = self.priority - 1,
				text = { text = "查看", size = 28, strokeColor = display.COLOR_FONT },
				callback = function()
					local bin = pb.encode("SimpleEvent", { roleId = rankData.roleId })
					game:sendData(actionCodes.RoleDigestInfoRequest, bin)
					game:addEventListener(actionModules[actionCodes.RoleDigestInfoResponse], function(event)
						local roleDigest = pb.decode("RoleLoginResponse", event.data)
						local roleDigestLayer = RoleDetailLayer.new({ priority = self.priority - 10, roleDigest = roleDigest })
						roleDigestLayer:getLayer():addTo(display.getRunningScene())
						return "__REMOVE__"
					end)
				end,
			}):getLayer()
		queryBtn:anch(1, 0.5):pos(cellSize.width - 10, cellSize.height / 2):addTo(cellNode)
	end

	local viewSize = CCSizeMake(720, self.size.height - 80)

	local viewHandler = LuaEventHandler:create(function(fn, table, a1, a2)
		local result
		if fn == "cellSize" then
			result = cellSize 

		elseif fn == "cellAtIndex" then
			if not a2 then
				a2 = CCTableViewCell:new()
				local cell = display.newNode()
				a2:addChild(cell, 0, 1)
			end

			-- 更新cell
			local cell = tolua.cast(a2:getChildByTag(1), "CCNode")
			createCellNode(cell, self.rankMapData[#self.rankMapData - a1])
			result = a2

		elseif fn == "numberOfCells" then
			result = math.ceil(#self.rankMapData)
		end

		return result
	end)

	scrollView = CCNodeExtend.extend(LuaTableView:createWithHandler(viewHandler, viewSize))
	scrollView:setBounceable(true)
	scrollView:setTouchPriority(self.priority - 1)
	scrollView:anch(0.5, 0):pos(self.size.width / 2, 10):addTo(self)
end

function TowerRankLayer:getLayer()
	return self.mask:getLayer()
end

return TowerRankLayer