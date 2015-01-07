-- pvp战场排行
-- by yangkun
-- 2014.7.3

local GlobalRes = "resource/ui_rc/global/"
local PvpRes = "resource/ui_rc/pvp/"
local PvpRankRes = "resource/ui_rc/global/rank/"
local TowerRes = "resource/ui_rc/activity/tower_bak/"

local RoleDetailLayer = import("..RoleDetailLayer")

local RankLayer = class("RankLayer", function()
	return display.newLayer(PvpRankRes .. "rank_bg.png")
end)

function RankLayer:ctor(params)
	params = params or {}
	self.priority = params.priority or -130
	self.rankList = params.rankList or {}

	self.size = self:getContentSize()
	self.priority = params.priority or -130

	display.newSprite(GlobalRes .. "title_bar.png"):anch(0.5,0.5):pos(self.size.width/2, self.size.height - 40):addTo(self)
	display.newSprite(PvpRankRes .. "rank_text.png"):anch(0.5,0.5):pos(self.size.width/2, self.size.height - 40):addTo(self)

	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1,ObjSize=self:getContentSize(),clickOut=function()
		self:getLayer():removeSelf()
	end })

	self:initScrollLayer()
end

function RankLayer:initScrollLayer()
	local scrollView

	local cellSize = display.newSprite(PvpRankRes .. "rank_cell.png"):getContentSize()

	-- 创建对手的信息面板
	local function createOpponentNode(cellNode, rankInfo)
		display.newSprite(PvpRankRes .. "rank_cell.png")
			:pos(cellSize.width / 2, cellSize.height / 2):addTo(cellNode)

		if rankInfo.pvpRank < 4 then
			display.newSprite(PvpRankRes .. "rank_" .. rankInfo.pvpRank .. ".png")
			:anch(0.5,0.5):pos(66, cellSize.height - 50):addTo(cellNode)
		end
		ui.newBMFontLabel({ text = rankInfo.pvpRank, font = PvpRankRes .. "rank.fnt"})
			:anch(0.5,0.5):pos(66, cellSize.height - 45):addTo(cellNode)

		local heroUnitData = unitCsv:getUnitByType(rankInfo.mainHeroType)
		local headFrame = HeroHead.new({type = rankInfo.mainHeroType, wakeLevel = rankInfo.mainHeroWakeLevel, star = rankInfo.mainHeroStar, evolutionCount = rankInfo.mainHeroEvolutionCount}):getLayer()
		headFrame:anch(0, 0.5):pos(130, cellSize.height / 2):addTo(cellNode)

		local infoBg = display.newSprite(GlobalRes .. "cell_namebar.png")
		infoBg:anch(0, 1):pos(260, cellSize.height - 20):addTo(cellNode)
		local infoSize = infoBg:getContentSize()
		local giftData = pvpGiftCsv:getGiftData(rankInfo.pvpRank)
		local nameLabel=ui.newTTFLabel({ text = rankInfo.name,font=ChineseFont , size = 26 })
			:anch(0, 0.5):pos(10, infoSize.height/2):addTo(infoBg)
		local nickLabel=ui.newTTFLabelWithStroke({ text = "称号 : ",font=ChineseFont , size = 20, color = display.COLOR_WHITE })
			:anch(0, 0):pos(infoBg:getPositionX(), cellSize.height - 93):addTo(cellNode)
		ui.newTTFLabelWithStroke({ text = (giftData and giftData.name or ""),font=ChineseFont , size = 20, color =uihelper.hex2rgb("#ffd200") })
			:anch(0, 0):pos(nickLabel:getPositionX()+nickLabel:getContentSize().width, cellSize.height - 93):addTo(cellNode)

		local lvLabel=ui.newTTFLabel({ text = "Lv." .. rankInfo.level, size = 22, color = uihelper.hex2rgb("#ffdc7d")})
			:anch(0, 0.5):pos(nameLabel:getContentSize().width, infoSize.height /2):addTo(infoBg)
		nameLabel:setPositionX((infoSize.width-nameLabel:getContentSize().width-lvLabel:getContentSize().width)/2)
		lvLabel:setPositionX(nameLabel:getPositionX()+nameLabel:getContentSize().width)

		local queryBtn = DGBtn:new(GlobalRes, {"square_green_normal.png", "square_green_selected.png"},
			{	
				parent = scrollView,
				text = { text = "查看", size = 26, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_BUTTON_STROKE, strokeSize = 2},
				priority = self.priority,
				callback = function()
					local bin = pb.encode("SimpleEvent", { roleId = rankInfo.roleId })
					game:sendData(actionCodes.RoleDigestInfoRequest, bin)
					game:addEventListener(actionModules[actionCodes.RoleDigestInfoResponse], function(event)
						local roleDigest = pb.decode("RoleLoginResponse", event.data)
						local roleDigestLayer = RoleDetailLayer.new({ 
							priority = self.priority - 10, roleDigest = roleDigest,
						})
						roleDigestLayer:getLayer():addTo(display.getRunningScene())

						return "__REMOVE__"
					end)
				end,
			}):getLayer()
		queryBtn:anch(1, 0.5):pos(cellSize.width - 10, cellSize.height / 2):addTo(cellNode)
		return cellNode
	end

	local scrollSize = CCSizeMake(720, 430)

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
			createOpponentNode(cell, self.rankList[#self.rankList - a1])
			result = a2

		elseif fn == "numberOfCells" then
			result = math.ceil(#self.rankList)
		end

		return result
	end)

	scrollView = CCNodeExtend.extend(LuaTableView:createWithHandler(viewHandler, scrollSize))
	scrollView:setBounceable(true)
	scrollView:setTouchPriority(self.priority - 1)
	scrollView:anch(0.5, 0):pos(self.size.width / 2, 10):addTo(self)
end

function RankLayer:getLayer()
	return self.mask:getLayer()
end

return RankLayer