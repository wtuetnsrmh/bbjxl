local GlobalRes = "resource/ui_rc/global/"
local LegendRes = "resource/ui_rc/carbon/legend/"
local HeroRes = "resource/ui_rc/hero/"
local LegendSelectedDiffLayer = import(".LegendSelectedDiffLayer")

local LegendHeroLayer = class("LegendHeroLayer", function()
	return display.newLayer(LegendRes .. "bg_mingjiang.png")
end)

function LegendHeroLayer:ctor(params)
	params = params or {}
	self.priority = params.priority or -130

	self.size = self:getContentSize()
	self:pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1 })

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
				switchScene("home")
			end,
		}):getLayer()
	closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self,100)

    self:initHomeLayer()

    -- 右侧按钮
	local chooseTab = display.newSprite(GlobalRes .. "tab_selected.png"):anch(0, 0.5)
	chooseTab:pos(self.size.width - 14, 470):addTo(self)
	display.newSprite(GlobalRes .. "tab_arrow.png")
		:anch(0, 0.5):pos(self.size.width - 25, 470):addTo(self)
	local tabSize = chooseTab:getContentSize()
	ui.newTTFLabelWithStroke({ text = "名将", dimensions = CCSizeMake(tabSize.width / 2, tabSize.height), size = 26, font = ChineseFont,
		color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(tabSize.width / 2, tabSize.height / 2):addTo(chooseTab)

	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority})
	:anch(0,1):pos(0,display.height):addTo(self)
end



function LegendHeroLayer:initHomeLayer()
	if self.mainLayer then
		game.role:removeEventListener("updateLegendBattleLimit", self.legendBattleCntUpdate)
		game.role:removeEventListener("updateHeroSoulNum", self.soulValueHandler)
		self.mainLayer:removeSelf()
	end

	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.size)
	local bgSize = self.mainLayer:getContentSize()
	self.mainLayer:anch(0.5, 0.5):pos(self.size.width / 2, self.size.height / 2):addTo(self)

	local carbonId = game.role.legendCardonIdIndex
	local carbonData = legendBattleCsv:getCarbonById(tonum(carbonId))

	-- 武将形象
	local unitData = unitCsv:getUnitByType(carbonData.heroType)
	self:showHeroInfo(unitData)

	-- 碎片
	ui.newTTFLabel({text="碎片掉落:", size = 20, color = uihelper.hex2rgb("#7398a1")})
		:pos(700,490):addTo(self)

	local xInterval = 5
	local xBegin = 800

	for index, fragmentData in pairs(carbonData.fragmentIds) do
		local heroType = math.floor(tonumber(fragmentData[1]) - 2000)
		local unitData = unitCsv:getUnitByType(heroType)

		local headBtn = HeroHead.new({
			type = tonumber(fragmentData[1]),
			priority = self.priority - 1,
			callback = function()
				-- local layer = require("scenes.home.hero.HeroInfoLayer").new({heroType = heroType, priority = self.priority -10})
				-- display.getRunningScene():addChild(layer:getLayer())
			end,
		}):getLayer()

		headBtn:anch(0.5, 0):scale(0.7):pos(xBegin + (index - 1) * (100 + xInterval), 453):addTo(self)

		-- ui.newTTFLabel({ text = string.format("%s·碎片",unitData.name), size = 18, color = display.COLOR_WHITE })
		-- 	:anch(0.5, 1):pos(headBtn:getContentSize().width / 2, -5):addTo(headBtn)
	end

	-- 武将名字
	ui.newTTFLabel({text=unitData.name, size = 26,font = ChineseFont, color = uihelper.hex2rgb("#befbfa")})
		:pos(self.size.width/2,490):addTo(self)



	local titleBg = display.newSprite(LegendRes.."bg_itemRest.png"):anch(0,0.5):pos(46,490):addTo(self)
	ui.newTTFLabel({text = "今日剩余次数:", size = 20})
		:anch(0, 0.5):pos(20, titleBg:getContentSize().height/2):addTo(titleBg)
	local legendBattleCntLabel = ui.newTTFLabel({ text = game.role.legendBattleLimit, size = 20, color = uihelper.hex2rgb("#7ce810") })
	legendBattleCntLabel:anch(0, 0.5):pos(155, titleBg:getContentSize().height/2):addTo(titleBg)

	local addBattleCntBtn = DGBtn:new(GlobalRes, {"add_normal.png", "add_selected.png"},
		{	
			scale = 1.05,
			priority = self.priority,
			callback = function()
				if tonum(game.role.legendBuyCount) >= game.role:getLegendBuyLimit() then
					DGMsgBox.new({ text = "您当前的剩余购买次数为0，您可以通过提升vip等级来提升挑战次数", type = 2 })
				else
					local costYuanbao = functionCostCsv:getCostValue("legendBattleCnt", game.role.legendBuyCount)
					DGMsgBox.new({ 
						text = string.format(
							"是否花费"..costYuanbao.."元宝增加1次挑战机会\n您今日的剩余购买次数为%d", game.role:getLegendBuyLimit() - game.role.legendBuyCount), type = 2,
						button2Data = { callback = function()
							local bin = pb.encode("SimpleEvent", { roleId = game.role.id })
            				game:sendData(actionCodes.LegendBattleAddCount, bin)
						end }
					})
				end
			end,
		})
	addBattleCntBtn:getLayer():anch(0.5, 0.5):pos(234, 490):addTo(self)

	local challengeBtn = DGBtn:new(GlobalRes, {"btn_ellipse_normal.png", "btn_ellipse_selected.png", "btn_ellipse_selected.png"},
		{
			priority = self.priority,
			text = { text = "挑 战", size = 26, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_BUTTON_STROKE, strokeSize = 2},
			callback = function()
				local legendSelectedDiffLayer = LegendSelectedDiffLayer.new({ carbonId = carbonData.carbonId }):getLayer()
				self:getLayer():addChild(legendSelectedDiffLayer,10)
				
			end,
		})
	challengeBtn:getLayer():anch(0.5, 0):pos(self.size.width / 2, 80):addTo(self)
	challengeBtn:setEnable(tonum(game.role.legendBattleLimit) > 0)
	challengeBtn:setGray(tonum(game.role.legendBattleLimit) == 0)
	self.legendBattleCntUpdate = game.role:addEventListener("updateLegendBattleLimit", function(event)
		legendBattleCntLabel:setString(string.format("%d", event.legendBattleLimit))
		challengeBtn:setGray(tonum(game.role.legendBattleLimit) == 0)
		if tonum(event.legendBattleLimit) > 0 then
			challengeBtn:setEnable(true)
		else
			challengeBtn:setEnable(false)
		end
	end)

end

function LegendHeroLayer:showHeroInfo(unitData, index)

	local sprite
	local effectSprite

	local function playAnimation(index)
		if unitData then
			local animationNames
			animationNames = { "move", "idle", "attack", "attack2", "attack3", "attack4"}
			if unitData.skillAnimateName ~= "0" then
				table.insert(animationNames, unitData.skillAnimateName)
			end
			index = math.random(index or 1, #animationNames)
			if #animationNames[index] > 0 then
				sprite:getAnimation():play(animationNames[index])

				if effectSprite and (animationNames[index] == "attack" or animationNames[index] == "attack2"
					or animationNames[index] == "attack3" or animationNames[index] == "attack4"
					or animationNames[index] == unitData.skillAnimateName) then
					effectSprite:getAnimation():play(animationNames[index])
				end
			end
		end
	end
	-- 模型属性
	local modelFrame = DGBtn:new(GlobalRes, {"rich_btn.png"},
		{
			priority = self.priority,
			callback = function()
				if unitData then	
					playAnimation()
				end
			end,
		}):getLayer()
	modelFrame:size(288, 301):anch(0, 0):pos(300, 120):addTo(self)

	if unitData then
		local paths = string.split(unitData.boneResource, "/")

		armatureManager:load(unitData.type)
		sprite = CCNodeExtend.extend(CCArmature:create(paths[#paths]))
		sprite:getAnimation():setSpeedScale(24 / 60)
		sprite:getAnimation():play("idle")

		sprite:scale(unitData.boneRatio / 70)
		sprite:pos(modelFrame:getContentSize().width / 2, 50):addTo(modelFrame)

		-- 特效
		if armatureManager:hasEffectLoaded(unitData.type) then
			local paths = string.split(unitData.boneEffectResource, "/")
			effectSprite = CCNodeExtend.extend(CCArmature:create(paths[#paths]))
			effectSprite:getAnimation():setSpeedScale(24 / 60)

			effectSprite:scale(unitData.boneEffectRatio / 70)
			effectSprite:pos(modelFrame:getContentSize().width / 2, 35):addTo(modelFrame)
		end
	end

	
end

function LegendHeroLayer:getLayer()
	return self.mask:getLayer()
end

function LegendHeroLayer:onCleanup()
	armatureManager:dispose()
	display.removeUnusedSpriteFrames()
end

function LegendHeroLayer:onExit()
	game.role:removeEventListener("updateLegendBattleLimit", self.legendBattleCntUpdate)
	game.role:removeEventListener("updateHeroSoulNum", self.soulValueHandler)
end

return LegendHeroLayer