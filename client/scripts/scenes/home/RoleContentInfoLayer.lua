local GlobalRes = "resource/ui_rc/global/"
local HeadRes = "resource/ui_rc/home/"
local HomeRes = "resource/ui_rc/home/"
local LoginRes = "resource/ui_rc/login_rc/"
local ShopRes = "resource/ui_rc/shop/vip/"
local InfoRes = "resource/ui_rc/hero/info/"

local RoleContentInfoLayer = class("RoleContentInfoLayer", function()
	return display.newLayer(HeadRes .. "head_bg.png")
end)

function RoleContentInfoLayer:ctor(params)

	self.params = params or {}
	self.views = {}
	self.priority = self.params.priority or - 900
	self:setNodeEventEnabled(true)
	self.w = self:getContentSize().width
	self.h = self:getContentSize().height
	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1,ObjSize = self:getContentSize(),
		click = function()
		end,
		clickOut = function()
			self:removeAllChildren()
			self:getLayer():removeFromParent()
		end,})

	local xPos, yPos = 158, self.h - 62
	--vipbtn
	local vipBtn = DGBtn:new(GlobalRes, {"topbar_normal.png", "topbar_selected.png"},
	{	
		priority = self.priority,
		text = { text = "vip特权", size = 22, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2, font = ChineseFont},
		callback = function()
			local VipLayer = require("scenes.home.shop.VipLayer")
			local vipLayer = VipLayer.new({ priority = self.priority - 10})
			vipLayer:getLayer():addTo(display.getRunningScene(),999)
		end,
	}):getLayer()
	vipBtn:anch(0, 0.5):pos(50, yPos):addTo(self)
	--vip 
	local tempNode = display.newSprite(HomeRes .. "vip_img_big.png"):anch(0, 0.5):pos(158, yPos):addTo(self)
	xPos = xPos + tempNode:getContentSize().width + 2
	tempNode = ui.newTTFLabelWithStroke({ text = game.role.vipLevel, size = 28, font = ChineseFont, strokeColor = display.COLOR_FONT })
		:anch(0, 0.5):pos(xPos, yPos):addTo(self)
	tempNode:setSkewX(20)
	--名称
	local roleNameLabel = ui.newTTFLabel({ text = game.role.name, size = 26, color = uihelper.hex2rgb("#ffd200"), font = ChineseFont })
		:anch(0.5, 0.5):pos(self.w/2, yPos):addTo(self)

	
	
	--头像：
	-- local heroData = unitCsv:getUnitByType(game.role.heros[game.role.mainHeroId].type)
	-- local headIcon = getShaderNode({steRes = HomeRes.."head_cut.png",clipRes = heroData.headImage})
	-- headIcon:setPosition(ccp(80, 400 ))
	-- self:addChild(headIcon)

	--头像框：
	-- display.newSprite(HeadRes.."headbox.png"):pos(0,0):addTo(headIcon)	

	--等级
	local level = ui.newTTFLabel({ text = "当前等级：", size = 22, color = uihelper.hex2rgb("#ffd200"), font = ChineseFont})
		:anch(1, 0)
		:pos(self.w/2, 314)
		:addTo(self)
	ui.newTTFLabel({ text = tostring(game.role.level), size = 22, font = ChineseFont})
		:anch(0, 0)
		:pos(self.w/2 + 5, 314)
		:addTo(self)

	--经验label：
	local exp = ui.newTTFLabel({ text = "当前经验：", size = 22, color = uihelper.hex2rgb("#ffd200"), font = ChineseFont})
		:anch(1, 0)
		:pos(self.w/2, 277)
		:addTo(self)

	local roleInfo = roleInfoCsv:getDataByLevel(game.role.level + 1)
	local expcur = game.role.exp
	local expall = roleInfo and roleInfo.upLevelExp or game.role.exp

	--经验进度：
	local expProBg = display.newSprite(HomeRes.."exp_bg.png"):anch(0,0):pos(self.w/2+5, 277):addTo(self)
	local expProLine = display.newProgressTimer(HomeRes.."exp_bar.png",display.PROGRESS_TIMER_BAR)
	expProLine:setMidpoint(ccp(0, 0))
	expProLine:setBarChangeRate(ccp(1, 0))
	expProLine:setPercentage(expcur / expall * 100)
	expProLine:pos(expProBg:getContentSize().width/2,expProBg:getContentSize().height/2)
	:addTo(expProBg)

	display.newSprite(HomeRes .. "exp_bar_frame.png")
		:pos(expProBg:getContentSize().width/2,expProBg:getContentSize().height/2):addTo(expProBg)


	
	local expPercent = expcur .. " / " .. expall
	local level = ui.newTTFLabel({ text = expPercent, size = 18 })
		:anch(0.5, 0.5)
		:pos(expProBg:getContentSize().width/2,expProBg:getContentSize().height/2)
		:addTo(expProBg)

	--武将等级上限
	local herolevel = ui.newTTFLabel({ text = "武将等级上限：", size = 22, color = uihelper.hex2rgb("#ffd200"), font = ChineseFont})
		:anch(1, 0)
		:pos(self.w/2, 237)
		:addTo(self)
	ui.newTTFLabel({ text = game.role.level, size = 22, font = ChineseFont })
		:anch(0, 0)
		:pos(self.w/2+5, 237)
		:addTo(self)

	local xx1 ,xx2 = 175, 383
	local yy1 ,yy2 = 194, 144
	-- --金币
	local goldsp = display.newSprite(GlobalRes.."yuanbao.png"):pos(xx1, yy1):addTo(self)
	local gold = ui.newTTFLabel({ text = tostring(game.role.yuanbao), size = 24, font = ChineseFont })
		:anch(0, 0.5)
		:pos(206, yy1)
		:addTo(self)
	-- --银币
	local moneysp = display.newSprite(GlobalRes.."yinbi_big.png"):pos(xx2, yy1):addTo(self)
	local money = ui.newTTFLabel({ text = tostring(game.role.money), size = 24, font = ChineseFont })
		:anch(0, 0.5)
		:pos(415, yy1)
		:addTo(self)
	-- --魂
	local soulSp = display.newSprite(GlobalRes.."herosoul.png"):pos(xx1,yy2):addTo(self)
	local soul = ui.newTTFLabel({ text = tostring(game.role.heroSoulNum), size = 24, font = ChineseFont })
		:anch(0, 0.5)
		:pos(206, yy2-10)
		:addTo(self)
	-- --战功
	local lingpaiIcon = display.newSprite(GlobalRes.."lingpai.png"):scale(0.9):pos(xx2,yy2):addTo(self)
	local lingpaiValue = ui.newTTFLabel({ text = tostring(game.role.lingpaiNum), size = 24, font = ChineseFont })
		:anch(0, 0.5)
		:pos(415, yy2-10)
		:addTo(self)

	--好友
	local friendBtn = DGBtn:new(GlobalRes, {"btn_ellipse_normal.png", "btn_ellipse_selected.png"}, {
		priority = self.priority - 1,
		text = {text = "好友", size = 26, font = ChineseFont, strokeColor = display.COLOR_FONT},
		callback = function()
			pushScene("friend")
		end,
		}):getLayer()
	friendBtn:anch(0.5, 0):pos(self.w/4 - 15, 43):addTo(self)
	--技能配置
	local skillSettingBtn = DGBtn:new(GlobalRes, {"btn_ellipse_normal.png", "btn_ellipse_selected.png"}, {
		priority = self.priority - 1,
		text = {text = "技能配置", size = 26, font = ChineseFont, strokeColor = display.COLOR_FONT},
		callback = function()
			local layer = require("scenes.home.hero.HeroSkillOrderLayer").new({ priority = self.priority - 10 })
			layer:getLayer():anch(0.5, 0.5):pos(self.w/2, self.h/2):addTo(self, 100)
		end,
		}):getLayer()
	skillSettingBtn:anch(0.5, 0):pos(self.w/4*2, 43):addTo(self)
	--设置
	local settingBtn = DGBtn:new(GlobalRes, {"btn_ellipse_normal.png", "btn_ellipse_selected.png"}, {
		priority = self.priority - 1,
		text = {text = "设置", size = 26, font = ChineseFont, strokeColor = display.COLOR_FONT},
		callback = function()
			local layer = require("scenes.home.SettingLayer").new({ priority = self.priority - 10 })
			layer:getLayer():anch(0.5, 0.5):pos(self.w/2, self.h/2):addTo(self, 100)
		end,
		}):getLayer()
	settingBtn:anch(0.5, 0):pos(self.w/4*3 + 15, 43):addTo(self)

	


	--更新名字：
	self.updateNameHandler = game.role:addEventListener("updateName", function(event)
								roleNameLabel:setString(event.rolename) 
							end)

	-- --改名字：

	local reName = DGBtn:new(HeadRes, {"cname_nor.png", "cname_sel.png"},
	{	
		priority = self.priority - 1,
		callback = function()

			local RenameLayer = require("scenes.home.RenameLayer")
			local renameLayer = RenameLayer.new({priority = self.priority - 10})
			CCDirector:sharedDirector():getRunningScene():addChild(renameLayer:getLayer(),999)

		end,
	}):getLayer()
	reName:anch(1, 0.5):pos(self.w - 40, yPos):addTo(self)
end


function RoleContentInfoLayer:getLayer()
	return self.mask:getLayer()
end

function RoleContentInfoLayer:onExit()
	if game.role then
		game.role:removeEventListener("updateName", self.updateNameHandler)
		game.role:removeEventListener("updateHealth", self.updateHealthHandler)
    end

    display.removeUnusedSpriteFrames()
end

return RoleContentInfoLayer