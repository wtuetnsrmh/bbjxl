local LoadingRes = "resource/ui_rc/loading/"

local HeroCardLayer = import(".home.hero.HeroCardLayer")

local BattleLoadingLayer = class("BattleLoadingLayer", function()
	return display.newLayer(LoadingRes .. "battleload_bg.jpg")
end)

function BattleLoadingLayer:ctor(params)
	params = params or {}
	self.priority = params.priority or -130
	self.size = self:getContentSize()
	self.callback = params.callback
	self.loadingInfo = params.loadingInfo or {}
	self.showText=params.showText or false

	self.size = self:getContentSize()
	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1 })

	self.removeImages = {}
	self.removeImages[LoadingRes .. "battleload_bg.jpg"] = true

	if self.showText then
		local tipText=display.newSprite(LoadingRes.."tip.png"):pos(self.size.width/2,58):addTo(self)
	end
	

	local loadingCsv = require("csv.LoadingCsv")
	loadingCsv:load("csv/loading.csv")
	local loadTips = loadingCsv:randLoadingTips()

	if loadTips.type == 1 then
		self.removeImages[loadTips.image] = true
		display.newSprite(loadTips.image):pos(self.size.width / 2 - 230, display.cy):addTo(self)
	else
		local heroCard = HeroCardLayer.new({ heroType = loadingCsv:randHero(loadTips.id), star = HERO_MAX_STAR, evolutionCount = evolutionModifyCsv:getEvolMaxCount() })
		heroCard:scale(300 / 640):anch(0.5, 0.5):pos(self.size.width / 2 - 230, display.cy+32):addTo(self)
	end

	local content = CCFileUtils:sharedFileUtils():getFileDataXXTEA(loadTips.desc)
	local loadingText = ui.newTTFRichLabel({ text = content, dimensions = CCSizeMake(400, 400), size = 24})
	loadingText:pos(self.size.width / 2 + 200, display.cy):addTo(self)
end

function BattleLoadingLayer:onEnter()
	self:startLoading()
end

function BattleLoadingLayer:startLoading()
	-- 延迟0.1秒后开始加载
	self:performWithDelay(function() self:loadResources() end, 0.1)
end

function BattleLoadingLayer:loadResources()
	local images = self.loadingInfo.images or {}
	for _, image in ipairs(images) do
		CCTextureCache:sharedTextureCache():addImage(image)
	end

	local function boneLoaded(percent)
		-- 加载完毕
		if percent >= 1 then
			if self.callback then self.callback() end
			CCTexture2D:PVRImagesHavePremultipliedAlpha(false)
		end
	end

	local heroTypes = self.loadingInfo.heroTypes or {}
	if self.loadingInfo.loadRoleHeros then
		for _, hero in pairs(game.role.chooseHeros) do
			heroTypes[hero.type] = true
		end
	end

	for type, _ in pairs(heroTypes) do
		armatureManager:asyncLoad(type, boneLoaded)
	end
end

function BattleLoadingLayer:getLayer()
	return self.mask:getLayer()
end

function BattleLoadingLayer:onCleanup()
	for name, bool in pairs(self.removeImages) do
		display.removeSpriteFrameByImageName(name)
	end
end

return BattleLoadingLayer