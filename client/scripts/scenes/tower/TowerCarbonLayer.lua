local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"
local TowerRes = "resource/ui_rc/activity/tower/"

local TowerRankLayer = import(".TowerRankLayer")
local RuleTipsLayer = import("..RuleTipsLayer")

local TowerCarbonLayer = class("TowerCarbonLayer", function()
	return display.newLayer(GlobalRes .. "inner_bg.png")
end)

function TowerCarbonLayer:ctor(params)
	self.params = params or {}

	self.size = self:getContentSize()
	self.priority = self.params.priority or - 130
	self.towerData = game.role.towerData

	self:anch(0, 0):pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1, opacity = 0 })

	-- 剩余次数
	local textBg = display.newSprite(TowerRes .. "leftcount_bg.png")
	textBg:anch(0.5, 1):pos(display.cx, display.height - 15):addTo(self:getLayer())
	
	local textNode = display.newNode()

	local prefix = ui.newTTFLabelWithStroke({ text = "今日剩余挑战次数 : ", size = 28, 
		font = ChineseFont, color = uihelper.hex2rgb("#fde335"), strokeColor = uihelper.hex2rgb("#242424") })
	prefix:anch(0, 0.5):addTo(textNode)
	local prefixSize = prefix:getContentSize()
	local countLabel = ui.newTTFLabelWithStroke({ text = game.role.towerData.count, size = 28, 
		font = ChineseFont, color = uihelper.hex2rgb("7ce810"), strokeColor = uihelper.hex2rgb("#242424") })
	countLabel:anch(0, 0.5):addTo(textNode)
	local countSize = countLabel:getContentSize()
	local suffix = ui.newTTFLabelWithStroke({ text = string.format(" / 3"), size = 28, 
		font = ChineseFont, color = uihelper.hex2rgb("#fde335"), strokeColor = uihelper.hex2rgb("#242424") })
	suffix:anch(0, 0.5):addTo(textNode)
	local suffixSize = suffix:getContentSize()

	textNode:anch(0.5, 0.5):size(prefixSize.width + countSize.width + suffixSize.width, prefixSize.height)
		:pos(textBg:getContentSize().width / 2, textBg:getContentSize().height / 2):addTo(textBg)
	prefix:anch(0, 0):pos(0, 0)
	countLabel:anch(0, 0):pos(prefixSize.width, 0)
	suffix:anch(0, 0):pos(prefixSize.width + countSize.width, 0)

	--标题bg
	self.tabCursor = display.newSprite(GlobalRes .. "tab_arrow.png")
	self.tabCursor:anch(1, 0.5):pos(self.size.width, 470):addTo(self, 100)
	local infoTab = display.newSprite(GlobalRes .. "tab_selected.png"):anch(0, 0.5)
	infoTab:pos(self.size.width - 14, 470):addTo(self, -1)
	local tabSize = infoTab:getContentSize()
	ui.newTTFLabelWithStroke({ text = "难度", dimensions = CCSizeMake(tabSize.width / 2, tabSize.height), size = 26, font = ChineseFont, 
		color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(tabSize.width / 2, tabSize.height / 2):addTo(infoTab)

	-- 星魂商店
	local shopBtn = DGBtn:new(GlobalRes, {"vertical_normal.png", "vertical_selected.png"},
		{	
			priority = self.priority,
			front=TowerRes.."star_shop_text.png",
			touchScale = { 2, 1 },
			callback = function()
				local PvpShopLayer = require("scenes.pvp.PvpShopLayer")
				local shopLayer = PvpShopLayer.new({priority = self.priority - 10, shopIndex = 7})
				shopLayer:getLayer():addTo(display.getRunningScene())
			end,
		}):getLayer()
	shopBtn:anch(0, 0.5):pos(self.size.width - 14, 360):addTo(self, -1)

	--排行：
	local rankBtn = DGBtn:new(GlobalRes, {"vertical_normal.png", "vertical_selected.png"},
		{	
			priority = self.priority,
			touchScale = { 2, 1 },
			callback = function()
				local RankMainLayer = require("scenes.home.rank.RankMainLayer")
				local layer = RankMainLayer.new({ parent = self, priority = self.priority - 10, tag = 4 })
				layer:getLayer():addTo(display.getRunningScene())	
			end,
		}):getLayer()
	rankBtn:anch(0, 0.5):pos(self.size.width - 14, 250):addTo(self, -1)
	local btnSize = rankBtn:getContentSize()
	ui.newTTFLabelWithStroke({ text = "排行", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(rankBtn)

	--规则：
	local ruleBtn = DGBtn:new(GlobalRes, {"vertical_normal.png", "vertical_selected.png"},
		{	
			priority = self.priority,
			touchScale = { 2, 1 },
			callback = function()
				local ruleLayer = RuleTipsLayer.new({ priority = self.priority - 100, 
					file = "txt/function/tower_rule.txt",
					args = { }
				})
				ruleLayer:getLayer():addTo(display.getRunningScene())	
			end,
		}):getLayer()
	ruleBtn:anch(0, 0.5):pos(self.size.width - 14, 140):addTo(self, -1)
	ui.newTTFLabelWithStroke({ text = "规则", dimensions = CCSizeMake(btnSize.width / 2, btnSize.height), size = 26, font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(ruleBtn)

	--tilebg
	local titleBg = display.newSprite(GlobalRes .. "title_bar.png")
	titleBg:pos(self.size.width / 2, self.size.height - 30):addTo(self)
	--stage
	display.newTextSprite(TowerRes .. "number_slot.png", { text = self.towerData.carbonId % 100, size = 36, font = ChineseFont, color = display.COLOR_WHITE, strokeColor = display.COLOR_BROWNSTROKE, strokeSize = 2 })
		:pos(titleBg:getContentSize().width / 2, titleBg:getContentSize().height / 2):addTo(titleBg)

	local textBg = display.newSprite(GlobalRes .. "label_bg.png")
	local textSize = textBg:getContentSize()
	textBg:anch(1, 0):pos(self.size.width - 30, self.size.height - 48):addTo(self)

	--得星数量：
	local offset = 10
	local deLabel = ui.newTTFLabel({ text = string.format("得", self.towerData.totalStarNum), size = 20, color = display.COLOR_WHITE })
		:anch(0, 0.5):pos(offset, textSize.height / 2 ):addTo(textBg)
	local deNumLabel = ui.newTTFLabel({ text = string.format("%d", self.towerData.totalStarNum), size = 20, color = display.COLOR_GREEN })
		:anch(0, 0.5):pos(deLabel:getPositionX() + deLabel:getContentSize().width + 5, textSize.height / 2 ):addTo(textBg)
	display.newSprite(GlobalRes .. "star/icon_big.png"):anch(0, 0.5)
		:scale(0.7):pos(deNumLabel:getPositionX() + deNumLabel:getContentSize().width, textSize.height / 2 ):addTo(textBg)

	--剩余星数：
	local shengLabel = ui.newTTFLabel({ text = "剩", size = 20, color = display.COLOR_WHITE })
		:anch(0, 0.5):pos(120, textSize.height / 2 ):addTo(textBg)
	local shengNumLabel = ui.newTTFLabel({ text = tostring(self.towerData.curStarNum), size = 20, color = display.COLOR_GREEN })
		:anch(0, 0.5):pos(shengLabel:getContentSize().width + shengLabel:getPositionX() + 5, textSize.height / 2 ):addTo(textBg)
	display.newSprite(GlobalRes .. "star/icon_big.png"):anch(0, 0.5)
		:scale(0.7):pos(shengNumLabel:getContentSize().width + shengNumLabel:getPositionX(), textSize.height / 2 ):addTo(textBg)

	--再过多少关reward：
	self:needStagesShow()

	local whiteBg = display.newSprite(GlobalRes .. "front_bg.png")
	whiteBg:anch(0.5, 0):pos(self.size.width / 2, 25):addTo(self)
	local whiteSize = whiteBg:getContentSize()

	local xBegin = 20
	local xInterval = (whiteSize.width - 262 * 3 - 2 * xBegin) / 2
	for difficult = 1, 3 do
		local carbonIcon = self:createCarbonIcon(difficult)
		local size = carbonIcon:getContentSize()
		carbonIcon:anch(0.5, 0.5):pos(xBegin + (xInterval + size.width) * (difficult - 1) + size.width / 2, 70 + size.height / 2)
			:addTo(whiteBg)
	end

	-- 当前加成
	-- 属性加成
	local attrLabel = display.newSprite(TowerRes .. "attr_bg.png")
	local labelSize = attrLabel:getContentSize()

	ui.newTTFLabel({ text = "当前加成", size = 20, color = uihelper.hex2rgb("#ffda7d") })
		:anch(0, 0.5):pos(10, labelSize.height / 2):addTo(attrLabel)
	display.newSprite(GlobalRes .. "attr_hp.png"):pos(130, labelSize.height / 2):addTo(attrLabel)
	display.newSprite(GlobalRes .. "attr_atk.png"):pos(230, labelSize.height / 2):addTo(attrLabel)
	display.newSprite(GlobalRes .. "attr_def.png"):pos(330, labelSize.height / 2):addTo(attrLabel)
	ui.newTTFLabel({ text = string.format("+%d%%", self.towerData.hpModify), size = 20, color = uihelper.hex2rgb("#7ce810") })
		:anch(0, 0.5):pos(150, labelSize.height / 2):addTo(attrLabel)
	ui.newTTFLabel({ text = string.format("+%d%%", self.towerData.atkModify), size = 20, color = uihelper.hex2rgb("#7ce810") })
		:anch(0, 0.5):pos(250, labelSize.height / 2):addTo(attrLabel)
	ui.newTTFLabel({ text = string.format("+%d%%", self.towerData.defModify), size = 20, color = uihelper.hex2rgb("#7ce810") })
		:anch(0, 0.5):pos(350, labelSize.height / 2):addTo(attrLabel)

	attrLabel:anch(0.5, 0):pos(whiteSize.width / 2, 20):addTo(whiteBg)

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
				switchScene("home")	
			end,
		}):getLayer()
	closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self)

end

function TowerCarbonLayer:createCarbonIcon(difficult)
	local towerDiffData = towerDiffCsv:getDiffData(difficult)
	if not towerDiffData then return end

	local sceneId = game.role.towerData["sceneId" .. difficult]
	if not sceneId or sceneId == 0 then
		local sceneIndies = {
			[1] = { low = 1, up = 10 }, [2] = { low = 11, up = 20 }, [3] = { low = 21, up = 40 },
			[4] = { low = 41, up = 60 }, [5] = { low = 61, up = 80 }, [6] = { low = 81, up = 100 },
		}		
		local carbonNum = self.towerData.carbonId % 100
		local sceneIndex
		for index, data in ipairs(sceneIndies) do
			if data.low <= carbonNum and data.up >= carbonNum then
				sceneIndex = index
				break
			end
		end

		local randomIndex = math.random(1, #towerDiffData["scene" .. sceneIndex .. "Ids"])
		sceneId = tonumber(towerDiffData["scene" .. sceneIndex .. "Ids"][randomIndex])
		game.role:updateTowerData({ ["sceneId" .. difficult] = sceneId })
	end
	local towerSceneData = towerSceneCsv:getSceneData(sceneId)
	if not towerSceneData then return end

	local carbonIcon = DGBtn:new(TowerRes, {"frame_difficulty.png"},
		{	
			scale = 0.97,
			priority = self.priority,
			callback = function()
				if game.role.towerData.count <= 0 then
					DGMsgBox.new({ msgId = SYS_ERR_TOWER_PLAY_COUNT_LIMIT })
					return
				end

				local bin = pb.encode("SimpleEvent", { roleId = game.role.id })
				game:sendData(actionCodes.TowerBattleBegin, bin, #bin)
				game:addEventListener(actionModules[actionCodes.TowerBattleBegin], function(event)
					
					switchScene("battle", { battleType = 3, carbonId = self.towerData.carbonId, 
						difficult = difficult, sceneId = sceneId })

					return "__REMOVE__"
				end)

				
			end,
		}):getLayer()
	local frameSize = carbonIcon:getContentSize()

	display.newSprite(TowerRes .. difficult .. "_difficulty.png")
		:pos(frameSize.width / 2, frameSize.height - 40):addTo(carbonIcon)

	local unitData = unitCsv:getUnitByType(towerSceneData.heroType)
	local heroCard = display.newSprite(unitData.cardRes)

	local headClipper = CCClippingNode:create()
	headClipper:setStencil(display.newSprite(TowerRes .. "card_stencil.png"))
	headClipper:setInverted(false)
	headClipper:setAlphaThreshold(0)
	headClipper:setPosition(frameSize.width / 2, frameSize.height / 2)
	heroCard:scale(400 / 850):addTo(headClipper)
	carbonIcon:addChild(headClipper, -1)

	local starBg = display.newSprite(TowerRes .. "startips_bg.png")
	ui.newTTFLabel({ text = string.format("得     倍数 X %d", towerDiffData.starModify), size = 24, color = display.COLOR_WHITE })
		:pos(starBg:getContentSize().width / 2, starBg:getContentSize().height / 2):addTo(starBg)
	display.newSprite(GlobalRes .. "star/icon_big.png"):anch(0.5, 0.5):pos(90, starBg:getContentSize().height / 2):addTo(starBg)
	starBg:anch(0.5, 0):pos(frameSize.width / 2, 40):addTo(carbonIcon, -1)

	return carbonIcon
end

--再过多少关reward：
function TowerCarbonLayer:needStagesShow()
	local bg = display.newSprite(GlobalRes .. "label_bg.png")
	bg:anch(0, 0):pos(30, self.size.height - 48):addTo(self)

	local bgSize = bg:getContentSize()
	local offset = 10

	local wordFront = ui.newTTFLabel({ text = "再过", size = 20, color = display.COLOR_WHITE })
		:anch(0, 0.5):pos(offset, bgSize.height / 2):addTo(bg)

	local carbonNum = self.towerData.carbonId % 100
	local carbonNumLabel = ui.newTTFLabel({ text = string.format("%d", (5 - carbonNum % 5) % 5 + 1), size = 20, color = uihelper.hex2rgb("#7ce810")})
		:anch(0, 0.5):pos(wordFront:getPositionX() + wordFront:getContentSize().width + offset, bgSize.height / 2):addTo(bg)

	ui.newTTFLabel({ text = "关结算奖励", size = 20,  color = display.COLOR_WHITE })
		:anch(0, 0.5):pos(carbonNumLabel:getPositionX() + carbonNumLabel:getContentSize().width + offset, bgSize.height / 2):addTo(bg)
end

function TowerCarbonLayer:getLayer()
	return self.mask:getLayer()
end

return TowerCarbonLayer