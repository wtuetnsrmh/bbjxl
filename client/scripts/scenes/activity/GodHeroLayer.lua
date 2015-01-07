local GodHeroRes = "resource/ui_rc/activity/god_hero/"
local FirstReChargeRes = "resource/ui_rc/activity/recharge/"
local DrawCardRes = "resource/ui_rc/shop/drawcard/"
local ReChargeRes = "resource/ui_rc/shop/recharge/"

local HeroInfoLayer = require("scenes.home.hero.HeroInfoLayer")

local GodHeroLayer = class("GodHeroLayer", function() 
	return display.newLayer(FirstReChargeRes.."accu_rech_bg.jpg") 
end)


function GodHeroLayer:ctor(params)
	self.params = params or {}
	self.priority = params.priority or -129
	self.heros = game.role.activityTimeList[2].data
	self.size = self:getContentSize()
	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.size):addTo(self)
	self:initUI()
	game.role.sendGodHero = true
	game.role:dispatchEvent({ name = "notifyNewMessage", type = "godHero" })
end

function GodHeroLayer:initUI()
	self.mainLayer:removeAllChildren()
	-- 上面背景
	local upperBg = display.newSprite(GodHeroRes .. "upper_bg.png")
	upperBg:anch(0.5, 1):pos(self.size.width/2, self.size.height - 25):addTo(self.mainLayer)
	local upperBgSize = upperBg:getContentSize()
	--日期
	local startAndEndTimeStr = game.role.activityTimeList[2].startAndEndTime
	local ActiveMainLayer = require("scenes.activity.ActiveMainLayer")
	local timeData = ActiveMainLayer.getTimeTable(startAndEndTimeStr)
	ui.newTTFLabelWithStroke({text = string.format("%d年%d月%d日 - %d年%d月%d日", timeData[1].year, timeData[1].month, timeData[1].day, timeData[2].year, timeData[2].month, timeData[2].day),
		size = 30, color = uihelper.hex2rgb("#fce371"), strokeColor = uihelper.hex2rgb("#a83700")})
		:anch(0.5, 1):pos(upperBgSize.width/2, upperBgSize.height - 40):addTo(upperBg)
	--描述
	uihelper.createLabel({text = "活动期间，进行五连抽有概率获得神将整卡与神将碎片。同时可抽取到每日其他武将碎片。", size = 18, color = uihelper.hex2rgb("#461804"), width = 596})
		:anch(0.5, 1):pos(upperBgSize.width/2, upperBgSize.height - 108):addTo(upperBg)
	-- 下面背景
	local lowerBg = display.newSprite(GodHeroRes .. "lower_bg.png")
	lowerBg:anch(0.5, 0):pos(self.size.width/2, 7):addTo(self.mainLayer)
	local lowerBgSize = lowerBg:getContentSize()
	--神将兵模
	local heroType = self.heros[1]
	local heroUnitData = unitCsv:getUnitByType(heroType)
	local sprite	
	local paths = string.split(heroUnitData.boneResource, "/")

	armatureManager:load(heroType)
	sprite = CCNodeExtend.extend(CCArmature:create(paths[#paths]))
	sprite:getAnimation():setSpeedScale(24 / 60)
	sprite:getAnimation():play("idle")
	local scale = heroUnitData.boneRatio / 100 * (self.profession == 3 and 1.2 or 1.2)
	sprite:scale(scale)
	local layer = display.newLayer()
	layer:size(cc.size(sprite:getContentSize().width * scale, sprite:getContentSize().height * scale))
	layer:anch(0.5, 0):pos(150, 57):addTo(lowerBg)
	sprite:pos(layer:getContentSize().width / 2, 0):addTo(layer)

	--特效
	local effectSprite
	if armatureManager:hasEffectLoaded(heroType) then
		local paths = string.split(heroUnitData.boneEffectResource, "/")
		effectSprite = CCNodeExtend.extend(CCArmature:create(paths[#paths]))
		effectSprite:getAnimation():setSpeedScale(24 / 60)
		local scale = heroUnitData.boneEffectRatio / 100 * (self.profession == 3 and 1.2 or 1.2)
		effectSprite:scale(scale)
		effectSprite:pos(layer:getContentSize().width / 2, 0):addTo(layer)
	end

	layer:setTouchEnabled(true)
	local press = false
	layer:addTouchEventListener(
		function(event, x, y) 
			if event == "began" then
				if uihelper.nodeContainTouchPoint(layer, ccp(x, y)) then			
                   press = true
				else
					return false
				end
			elseif event == "ended" then
				if uihelper.nodeContainTouchPoint(layer, ccp(x, y))  and press then
					press = false
					local animationNames
					animationNames = { "move", "idle", "attack", "attack2", "attack3", "attack4"}
				
					if heroUnitData.skillAnimateName ~= "0" then
						table.insert(animationNames, heroUnitData.skillAnimateName)
					end
					local index = math.random(1, #animationNames)
					if #animationNames[index] > 0 then
						sprite:getAnimation():play(animationNames[index])
						
						if effectSprite and (animationNames[index] == "attack" or animationNames[index] == "attack2"
							or animationNames[index] == "attack3" or animationNames[index] == "attack4"
							or animationNames[index] == heroUnitData.skillAnimateName) then
							effectSprite:getAnimation():play(animationNames[index])
						end
					end
				end	
			end
			return true
		end, false, self.priority - 1, true)
	
	--神将头像
	local heroHead = ItemIcon.new({
		itemId = heroType + 1000, 
		priority = self.priority - 2,
		callback = function()
			local layer = HeroInfoLayer.new({heroType = heroType, priority = self.priority - 30}):getLayer()
			layer:addTo(display.getRunningScene())
		end,
	}):getLayer():scale(0.8):anch(0, 0):pos(202, 182):addTo(lowerBg)
	local csvData = unitCsv:getUnitByType(heroType)
	ui.newTTFLabelWithStroke({text = csvData.name, size = 22, font = ChineseFont, strokeColor = display.COLOR_FONT})
		:anch(0.5, 1):pos(heroHead:getContentSize().width/2, 5):addTo(heroHead)

	--其他武将
	local xBegin, xInterval = 318, 133
	for index = 1, 3 do
		local heroType = self.heros[index + 1]
		local heroHead = ItemIcon.new({
			itemId = heroType + 1000, 
			priority = self.priority - 2,
			callback = function()
				local layer = HeroInfoLayer.new({heroType = heroType, priority = self.priority - 30}):getLayer()
				layer:addTo(display.getRunningScene())
			end,
		}):getLayer():anch(0, 0):pos(xBegin + (index - 1) * xInterval, 130):addTo(lowerBg)

		local csvData = unitCsv:getUnitByType(heroType)
		ui.newTTFLabelWithStroke({text = csvData.name, size = 22, font = ChineseFont, strokeColor = display.COLOR_FONT})
			:anch(0.5, 1):pos(heroHead:getContentSize().width/2, 5):addTo(heroHead)
	end

	--五连抽
	local yuanbao = display.newSprite(GlobalRes .. "yuanbao.png"):anch(0, 0):pos(349, 31):addTo(lowerBg)
	ui.newTTFLabelWithStroke({text = globalCsv:getFieldValue("godHeroCost"), size = 26, font = ChineseFont, strokeColor = display.COLOR_FONT})
		:anch(0, 0.5):pos(yuanbao:getContentSize().width, yuanbao:getContentSize().height / 2):addTo(yuanbao)
	--五连抽按钮
	local buyBtn = DGBtn:new(DrawCardRes, {"drawBtn_normal.png", "drawBtn_pressed.png"},
		{	
			priority = self.priority - 1,
			text = {text = "五连抽", size = 26, font = ChineseFont, strokeColor = display.COLOR_FONT},
			callback = function()
				local buyRequest = { roleId = game.role.id, packageId = 101, drawCard = 1 }
					
				local bin = pb.encode("BuyCardPackageRequest", buyRequest)
				game:sendData(actionCodes.StoreDrawCardRequest, bin, #bin)
				loadingShow()
				game:addEventListener(actionModules[actionCodes.StoreDrawCardResponse], function(event)
					loadingHide()
					local msg = pb.decode("BuyCardPackageResponse", event.data)

					local awardItems = {}
					while #msg.awardItems > 0 do
						local key = math.random(1, #msg.awardItems)
						table.insert(awardItems, msg.awardItems[key])
						table.remove(msg.awardItems, key)
					end
					if #awardItems == 0 then return end

					local DrawCardResultLayer = require("scenes.home.shop.DrawCardResultLayer")
					local resultLayer = DrawCardResultLayer.new({ awardItems = awardItems, 
						priority = self.priority - 10, index = 101 })
					display.getRunningScene():addChild(resultLayer:getLayer())

					return "__REMOVE__"
				end)
			end,
		}):getLayer():anch(0, 0):pos(443, 19):addTo(lowerBg)
end

function GodHeroLayer:onCleanup()
	armatureManager:dispose()
end


return GodHeroLayer