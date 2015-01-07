local GlobalRes = "resource/ui_rc/global/"
local ActivityRes = "resource/ui_rc/activity/"
local HomeRes = "resource/ui_rc/home/"
local RankRes = "resource/ui_rc/rank/"

local RoleDetailLayer = import("...RoleDetailLayer")

local RankMainLayer = class("RankMainLayer", function()
	return display.newLayer(RankRes .. "rank_bg.jpg")
end)

local tabFlags = {
	level = 1,
	pvp = 2,
	carbon = 3,
	tower = 4,
	score = 5,
	recharge = 6,
}

function RankMainLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -130
	self.size = self:getContentSize()
	self.yOffset = params.yOffset or 0
	self.parent = params.parent

	self.lastVipLevel = game.role.vipLevel

	self:anch(0.5, 0):pos(display.cx, 20)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1, bg = HomeRes .. "home.jpg" })

	local frame = display.newSprite(ActivityRes .. "bg_frame.png")
	frame:anch(0.5, 0):pos(self.size.width / 2, -10):addTo(self, 10)
	-- title
	display.newSprite(RankRes .. "rank_text.png"):anch(0.5,1)
		:pos(frame:getContentSize().width / 2, frame:getContentSize().height - 20)
		:addTo(frame)

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
				self:getLayer():removeSelf()
			end,
		}):getLayer()
	closeBtn:anch(1, 1):pos((display.width + 960) / 2, display.height):addTo(self:getLayer())

	--内容背景
	self.contentLayer = display.newSprite(RankRes .. "content_bg.png")
	self.contentLayer:anch(0.5, 0):pos(self.size.width/2, 25):addTo(self)
	self.contentSize = self.contentLayer:getContentSize()

	local tabCursor = display.newSprite(RankRes .. "tab_selected.png"):addTo(self, 100)
	--页签
	local tabs = {
		[tabFlags.level] = {
			res = {"level_text.png", "level_text_selected.png"},
		},
		[tabFlags.pvp] = {
			res = {"pvp_text.png", "pvp_text_selected.png"},
		},
		[tabFlags.carbon] = {
			res = {"carbon_text.png", "carbon_text_selected.png"},
		},
		[tabFlags.tower] = {
			res = {"tower_text.png", "tower_text_selected.png"},
		},
		[tabFlags.score] = {
			res = {"score_text.png", "score_text_selected.png"},
		},
		[tabFlags.recharge] = {
			res = {"recharge_text.png", "recharge_text_selected.png"},
		},
	}

	self.rankList = {}

	local tabRadios = DGRadioGroup:new()
	for index, data in ipairs(tabs) do
		--后面两个暂时不开
		if index >= tabFlags.score then break end

		-- local xPos, yPos = 113 + (index - 1) * 140, self.size.height - 73
		local xPos, yPos = index * (self.contentSize.width / (tabFlags.tower + 1)) + (self.size.width - self.contentSize.width)/2, self.size.height - 73
		local btn = DGBtn:new(RankRes, data.res, {
			touchScale = { 2, 1 },
			priority = self.priority - 1,
			id = index,
			callback = function()
				tabCursor:pos(xPos, yPos)
				self:initRank(index)
			end,
		}, tabRadios):getLayer()
		btn:anch(0.5, 0.5):pos(xPos, yPos):addTo(self, 100)
	end

	tabRadios:chooseById(params.tag or tabFlags.level, true)

end

function RankMainLayer:initRank(flag)
	self.contentLayer:removeAllChildren()
	self.scrollView = nil

	if flag == 3 then
		local yPos = self.contentSize.height - 33
		display.newSprite(RankRes .. "title_tex.png"):pos(self.contentSize.width/2, yPos):addTo(self.contentLayer)

		local tabs = {
			[1] = {name = "普  通"},
			[2] = {name = "精  英"},
		}
		local tabName = ui.newTTFLabelWithStroke({ text = tabs[1].name, font=ChineseFont, size = 24, strokeColor = display.COLOR_FONT })
		local slider = DGSlider:new(RankRes .. "carbon_sub_tab_bg.png", RankRes .. "tab_btn.png", {
			segments = 2,
			priority = self.priority - 1,
			callback = function(curSeg)
				tabName:setString(tabs[curSeg].name)
				self:requestRankData(curSeg + 30)
			end
			})
		
		tabName:anch(0.5, 0.5):pos(slider:getSlider():getContentSize().width/2, slider:getSlider():getContentSize().height/2):addTo(slider:getSlider(), 0, tag)
		slider:getLayer():anch(0.5, 0.5):pos(self.contentSize.width/2, yPos):addTo(self.contentLayer)
		self:requestRankData(31)
	else
		self:requestRankData(flag)
	end
end

function RankMainLayer:requestRankData(flag)
	if self.scrollView then
		self.scrollView:removeSelf()
		self.scrollView = nil
	end

	local cellHeight = 114
	local function refreshContent()
		self.myIndex = nil	
		local scrollSize = CCSizeMake(self.contentSize.width, self.contentSize.height - (flag > 30 and 60 or 10))
		local viewHandler = LuaEventHandler:create(function(fn, table, a1, a2)
			local result
			if fn == "cellSize" then
				result = CCSizeMake(self.contentSize.width, cellHeight)

			elseif fn == "cellAtIndex" then
				if not a2 then
					a2 = CCTableViewCell:new()
					local cell = display.newNode()
					a2:addChild(cell, 0, 1)
				end

				-- 更新cell
				local cell = tolua.cast(a2:getChildByTag(1), "CCNode")
				self:creatRankNode(cell, a1, flag)
				result = a2

			elseif fn == "numberOfCells" then
				result = math.ceil(#self.rankList[flag])
			end

			return result
		end)

		self.scrollView = CCNodeExtend.extend(LuaTableView:createWithHandler(viewHandler, scrollSize))
		self.scrollView:setBounceable(true)
		self.scrollView:setTouchPriority(self.priority - 1)
		self.scrollView:anch(0.5, 0):pos(self.contentSize.width / 2, 0):addTo(self.contentLayer)

		local myIndex
		for index, data in ipairs(self.rankList[flag]) do
			if data.roleId == game.role.id then
				myIndex = index
				break
			end
		end
		if myIndex then	
			local offset = -(#self.rankList[flag] - myIndex - 1.3) * cellHeight
			self.scrollView:setBounceable(false)
			self.scrollView:setContentOffset(ccp(0, offset), false)
			self.scrollView:setBounceable(true)
		end
	end

	if not self.rankList[flag] then 
		local bin = pb.encode("SimpleEvent", { roleId = game.role.id, param1 = flag })
		game:sendData(actionCodes.RoleRankRequest, bin)
		loadingShow()
		game:addEventListener(actionModules[actionCodes.RoleRankResponse], function(event)
			loadingHide()
			local msg = pb.decode("RankList", event.data)
			self.rankList[flag] = msg.rankList
			refreshContent()
			return "__REMOVE__"
		end)
	else
		refreshContent()
	end
end

-- 创建对手的信息面板
function RankMainLayer:creatRankNode(parentNode, index, flag)
	parentNode:removeAllChildren()

	local rankInfo = self.rankList[flag][#self.rankList[flag] - index]
	local isMyself = rankInfo.roleId == game.role.id
	local cellNode = display.newSprite(RankRes .. (isMyself and "my_item_bg.png" or "rank_item_bg.png"))
	cellNode:anch(0.5, 0):pos(self.contentSize.width/2, 0):addTo(parentNode)
	local cellSize = cellNode:getContentSize()

	--排名
	if rankInfo.rank < 4 then
		display.newSprite(GlobalRes .. "rank/rank_" .. rankInfo.rank .. ".png")
		:anch(0.5,0.5):pos(66, cellSize.height - 50):addTo(cellNode)
	end
	ui.newBMFontLabel({ text = rankInfo.rank, font = GlobalRes .. "rank/rank.fnt"})
		:anch(0.5,0.5):pos(66, cellSize.height - 45):addTo(cellNode)
	--头像
	local heroUnitData = unitCsv:getUnitByType(rankInfo.mainHeroType)
	local headFrame = HeroHead.new({type = rankInfo.mainHeroType, wakeLevel = rankInfo.mainHeroWakeLevel, star = rankInfo.mainHeroStar, evolutionCount = rankInfo.mainHeroEvolutionCount}):getLayer()
	headFrame:anch(0, 0.5):pos(130, cellSize.height / 2):addTo(cellNode)

	local xPos = 267
	--名称
	local nameLabel = ui.newTTFLabelWithStroke({ text = rankInfo.name, font=ChineseFont, size = 26, strokeColor = display.COLOR_FONT })
	nameLabel:anch(0, 0):pos(xPos, 63):addTo(cellNode)
	--等级
	ui.newTTFLabelWithStroke({ text = "Lv." .. rankInfo.level, font=ChineseFont, size = 22, color = uihelper.hex2rgb("#ffd200"), strokeColor = display.COLOR_FONT })
		:anch(0, 0):pos(nameLabel:getContentSize().width+5, 0):addTo(nameLabel)

	if flag == tabFlags.pvp or flag == tabFlags.level then
		--称号
		local giftData = pvpGiftCsv:getGiftData(rankInfo.rank)
		local nickLabel = ui.newTTFLabelWithStroke({ text = "称号", font=ChineseFont, size = 24, strokeColor = display.COLOR_FONT })
		nickLabel:anch(0, 1):pos(xPos, 47):addTo(cellNode)
		ui.newTTFLabelWithStroke({ text = (giftData and giftData.name or ""), font=ChineseFont, size = 24, color = uihelper.hex2rgb("#ffd200"), strokeColor = display.COLOR_FONT })
			:anch(0, 0):pos(nickLabel:getContentSize().width+3, 0):addTo(nickLabel)
	elseif flag == tabFlags.tower then
		--闯关
		local text = ui.newTTFLabelWithStroke({ text = "闯关", font=ChineseFont, size = 24, strokeColor = display.COLOR_FONT })
		text:anch(0, 1):pos(xPos, 47):addTo(cellNode)
		ui.newTTFLabelWithStroke({ text = rankInfo.extraParam1, font=ChineseFont, size = 24, color = uihelper.hex2rgb("#ffd200"), strokeColor = display.COLOR_FONT })
			:anch(0, 0):pos(text:getContentSize().width+3, 0):addTo(text)
		--星数
		text = ui.newTTFLabelWithStroke({ text = "得星", font=ChineseFont, size = 24, strokeColor = display.COLOR_FONT })
		text:anch(0, 1):pos(xPos + 115, 47):addTo(cellNode)
		ui.newTTFLabelWithStroke({ text = rankInfo.extraParam2, font=ChineseFont, size = 24, color = uihelper.hex2rgb("#ffd200"), strokeColor = display.COLOR_FONT })
			:anch(0, 0):pos(text:getContentSize().width+3, 0):addTo(text)
	elseif flag > 30 then
		local carbonId = rankInfo.extraParam1
		local mapInfo = mapInfoCsv:getMapById(math.floor(carbonId / 100))
		local carbonData = mapBattleCsv:getCarbonById(carbonId)
		if mapInfo and carbonData then
			local name = string.mySplit(mapInfo.name)
			--第几章
			local text = ui.newTTFLabelWithStroke({ text = name[1], font=ChineseFont, size = 24, color = uihelper.hex2rgb("#ffd200"), strokeColor = display.COLOR_FONT })
			text:anch(0, 1):pos(xPos, 47):addTo(cellNode)
			--关卡名
			ui.newTTFLabelWithStroke({ text = carbonData.name, font=ChineseFont, size = 24, color = uihelper.hex2rgb("#ffd200"), strokeColor = display.COLOR_FONT })
				:anch(0, 0):pos(text:getContentSize().width+15, 0):addTo(text)
		end
	end

	local xPos, yPos = cellSize.width - 28, cellSize.height / 2
	if not isMyself then
		local queryBtn = DGBtn:new(GlobalRes, {"square_normal.png", "square_selected.png"},
			{	
				parent = self.scrollView,
				text = { text = "查看", size = 26, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
				priority = self.priority - 1,
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
		queryBtn:anch(1, 0.5):pos(xPos, yPos):addTo(cellNode)
	else
		display.newSprite(RankRes .. "my_rank_text.png"):anch(1, 0.5):pos(xPos, yPos):addTo(cellNode)
	end
end


function RankMainLayer:getLayer()
	return self.mask:getLayer()
end

function RankMainLayer:onEnter()
	self.parent:hide()
end

function RankMainLayer:onExit()
	self.parent:show()
end

return RankMainLayer