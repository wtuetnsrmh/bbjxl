local CarbonRes = "resource/ui_rc/carbon/"
local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"

local AssistHeroLayer = class("AssistHeroLayer", function(params)
	return display.newLayer(GlobalRes .. "middle_popup.png")
end)

function AssistHeroLayer:ctor(params)
	params = params or {}

	self.size = self:getContentSize()
	self.priority = params.priority or -130

	-- 遮罩
	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1 })

	local backBtn = DGBtn:new(GlobalRes, {"btn_decomp_normal.png", "btn_decomp_selected.png"},
		{	
			touchScale = {3, 3},
			text = { text = "返回", size = 25, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			priority = self.priority,
			callback = function()
				self:getLayer():removeSelf(true)
			end,
		})
	backBtn:getLayer():anch(0, 1):pos(40, self.size.height - 32):addTo(self)
	self.skipBtn = DGBtn:new(GlobalRes, {"btn_decomp_normal.png", "btn_decomp_selected.png"},
		{
			touchScale = {3, 3},
			text = { text = "跳过", size = 25, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			priority = self.priority,
			callback = function()
				local assistChooseAction = { roleId = game.role.id, chosenRoleId = 0, carbonId = self.carbonId }
				local bin = pb.encode("AssistChooseAction", assistChooseAction)

				game:sendData(actionCodes.CarbonAssistChooseRequest, bin, #bin)
				loadingShow()
				game:addEventListener(actionModules[actionCodes.CarbonAssistChooseResponse], function(event)
					loadingHide()
					local msg = pb.decode("CarbonEnterAction", event.data)
					switchScene("battle", { carbonId = msg.carbonId, battleType = BattleType.PvE })	
					return "__REMOVE__"
				end)
			end,
		})
	self.skipBtn:getLayer():anch(1, 1):pos(self.size.width - 40, self.size.height - 32):addTo(self)

	display.newSprite(GlobalRes .. "title_bar.png"):anch(0.5,0.5):pos(self.size.width/2, self.size.height - 40):addTo(self)
	display.newSprite(CarbonRes .. "assist/title.png"):anch(0.5, 0.5):pos(self.size.width / 2, self.size.height - 40):addTo(self)

	local viewBg = display.newLayer()
	viewBg:size(733, 405)
	local viewSize = viewBg:getContentSize()

	self.carbonId = params.carbonId
	self.assistList = params.assistList or {}

	if table.nums(self.assistList)==0 then
		ui.newTTFLabel({text="暂时未搜索到可助战的玩家。",size=30,color=display.COLOR_WHITE}):pos(viewSize.width/2,viewSize.height/2+30)
		:addTo(viewBg)
	end

	self.assistListView = DGScrollView:new({ size = viewSize, priority = self.priority, divider = 10 })
	for index, assist in ipairs(self.assistList) do
		local cell = self:createAssistCell(assist, index)
		cell:anch(0.5, 0)
		self.assistListView:addChild(cell)
	end
	self.assistListView:alignCenter()
	self.assistListView:getLayer():anch(0.5, 0.5)
		:pos(viewSize.width / 2, viewSize.height / 2):addTo(viewBg)
	viewBg:anch(0.5, 0):pos(self.size.width / 2, 25):addTo(self)
end

function AssistHeroLayer:createAssistCell(assistInfo, index)
	local cell = display.newLayer(CarbonRes .. "assist/item_bg.png")
	local cellSize = cell:getContentSize()

	local heroInfo = { id = assistInfo.heroId, type = assistInfo.heroType, level = assistInfo.heroLevel, 
		skillLevelsJson = assistInfo.heroSkillLevelsJson, evolutionCount = assistInfo.heroEvolutionCount, wakeLevel = assistInfo.heroWakeLevel, star = assistInfo.heroStar,
		source = assistInfo.source, roleId = assistInfo.roleId, roleName = assistInfo.name, roleLevel = assistInfo.level }

	local unitData = unitCsv:getUnitByType(assistInfo.heroType)
	if unitData then
		local heroHeadBtn = HeroHead.new(
			{	
				type = unitData.type,
				priority = self.priority,
				parent = self.assistListView:getLayer(),
				wakeLevel = heroInfo.wakeLevel,
				star = heroInfo.star,
				evolutionCount = heroInfo.evolutionCount,
				callback = function()
				end,
			}):getLayer()
		heroHeadBtn:anch(0, 0.5):pos(0, cellSize.height / 2):addTo(cell)


		
	end

	local xPos, yPos = 125, 60
	ui.newTTFLabel({text = string.format("武将等级：Lv.%d", heroInfo.level), size = 22, color = uihelper.hex2rgb("#444444") })
		:anch(0, 0):pos(xPos, 60):addTo(cell)

	local text = ui.newTTFLabel({ text = "友情点", size = 22, color = uihelper.hex2rgb("#444444") })
		:anch(0, 0):pos(xPos, 22):addTo(cell)
	local friendValue = 0
	if assistInfo.first ~= 0 then
		if assistInfo.source == 1 then
			friendValue = globalCsv:getFieldValue("friendAwardPoint")
		else
			friendValue = globalCsv:getFieldValue("strangeAwardPoint")
		end
	end
	ui.newTTFLabel({ text = "+" .. friendValue, size = 22, color = uihelper.hex2rgb("#148a14") })
		:anch(0, 0):pos(xPos + text:getContentSize().width, 22):addTo(cell)

	--助战玩家信息
	local nameBg = display.newSprite(GlobalRes .. "cell_namebar.png")
	nameBg:anch(0, 0.5):pos(297, cellSize.height/2):addTo(cell)
	xPos, yPos = 16, 8
	text = ui.newTTFLabel({ text = assistInfo.name, size = 22, font = ChineseFont })
	text:anch(0, 0):pos(xPos, yPos):addTo(nameBg)
	xPos = xPos + text:getContentSize().width + 5
	ui.newTTFLabel({text = "Lv." .. assistInfo.level, size = 18, color = uihelper.hex2rgb("#ffdc7d")})
		:anch(0, 0):pos(xPos, yPos):addTo(nameBg)
	

	local chooseBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png"},
		{	
			text = { text = "助 战", size = 28, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			priority = self.priority,
			parent = self.assistListView:getLayer(),
			callback = function()
				local assistChooseAction = { roleId = game.role.id, chosenRoleId = assistInfo.roleId,
					mainHeroId = assistInfo.heroType, carbonId = self.carbonId, source = assistInfo.source }

				local bin = pb.encode("AssistChooseAction", assistChooseAction)
				game:sendData(actionCodes.CarbonAssistChooseRequest, bin, #bin)
				loadingShow()
				game:addEventListener(actionModules[actionCodes.CarbonAssistChooseResponse], function(event)
					loadingHide()
					local msg = pb.decode("CarbonEnterAction", event.data)
					switchScene("battle", { carbonId = msg.carbonId, battleType = BattleType.PvE })	
					return "__REMOVE__"
				end)
			end,
		}):getLayer()
	chooseBtn:anch(1, 0.5):pos(cellSize.width - 25, cellSize.height/2):addTo(cell)

	return cell
end

function AssistHeroLayer:getLayer()
	return self.mask:getLayer()
end

function AssistHeroLayer:onExit()
end

return AssistHeroLayer