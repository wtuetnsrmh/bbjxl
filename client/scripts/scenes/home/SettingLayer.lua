-- 新UI 设置界面
-- by yangkun
-- 2014.4.10

local GlobalRes = "resource/ui_rc/global/"
local SettingRes = "resource/ui_rc/setting/"
local HeroRes = "resource/ui_rc/hero/"

local HeroMapLayer = import(".hero.HeroMapLayer")
local CurMonthAwardLayer = import(".assign.CurMonthAwardLayer")

local SettingLayer = class("SettingLayer", function(params) 
	return display.newLayer()
end)

function SettingLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -129

	self:initUI()
end

function SettingLayer:onEnter()
	self:initContentLayer()
end

function SettingLayer:getLayer()
	return self.mask:getLayer()
end

function SettingLayer:initUI()
	self.innerBg = display.newSprite(GlobalRes .. "inner_bg.png")
	self.size = self.innerBg:getContentSize()
	self.innerBg:anch(0,0):pos(0, 10):addTo(self)

	-- 遮罩层
	self:anch(0, 0):pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1 })

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
				self:getLayer():removeSelf()
			end,
		}):getLayer()
	closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self,100)

	self.tabCursor = display.newSprite(GlobalRes .. "tab_arrow.png")
	self.tabCursor:anch(1, 0.5):pos(self.size.width, 470):addTo(self, 100)

	local tabRadio = DGRadioGroup:new()
	local menuBtn = DGBtn:new(GlobalRes, {"tab_normal.png", "tab_selected.png"},
		{	
			--front = SettingRes .. "text_menu.png",
			priority = self.priority,
			callback = function()
			end
		}, tabRadio)
	menuBtn:getLayer():anch(0, 0.5):pos(self.size.width - 14, 470):addTo(self)
	local tabSize = menuBtn:getLayer():getContentSize()
	ui.newTTFLabelWithStroke({ text = "菜单", dimensions = CCSizeMake(tabSize.width / 2, tabSize.height), size = 26, font = ChineseFont,
		color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(tabSize.width / 2, tabSize.height / 2):addTo(menuBtn:getLayer())

end

function SettingLayer:initContentLayer()
	if self.contentLayer then
		self.contentLayer:removeSelf()
	end

	self.contentLayer = display.newLayer()
	self.contentLayer:size(self:getContentSize()):pos(3,-50):addTo(self)
	local contentSize = self.contentLayer:getContentSize()

	self.button1 = DGBtn:new(SettingRes, {"button_bg.png"}, {
			callback = function()
				game.musicOn = not game.musicOn
				if game.musicOn then
					if not audio.isMusicPlaying() then
						game:playMusic(1)
					else
						audio.resumeMusic()
					end
				else
					audio.pauseMusic()
				end

				GameData.controlInfo = GameData.controlInfo or {}
				GameData.controlInfo.musicOn = game.musicOn
				GameState.save(GameData)

				self.musicSprite:removeSelf()
				self.musicSprite = display.newSprite( game.musicOn and SettingRes .. "music_on.png" or SettingRes .. "music_off.png")
				self.musicSprite:pos(340, self.button1:getLayer():getContentSize().height/2):addTo(self.button1:getLayer())
			
			end,
			priority = self.priority -1
		})
	self.button1:getLayer():pos(32, contentSize.height - 203):addTo(self.contentLayer)

	ui.newTTFLabelWithStroke({text = "背景音乐", size = 30, font = ChineseFont, color = display.COLOR_WHITE }):anch(0,0.5):pos(35, self.button1:getLayer():getContentSize().height/2 ):addTo(self.button1:getLayer())

	self.musicSprite = display.newSprite( game.musicOn and SettingRes .. "music_on.png" or SettingRes .. "music_off.png")
	self.musicSprite:pos(340, self.button1:getLayer():getContentSize().height/2):addTo(self.button1:getLayer())
	
	self.button2 = DGBtn:new(SettingRes, {"button_bg.png"}, {
			callback = function()
				game.soundOn = not game.soundOn
				if game.soundOn then
					audio.resumeAllSounds()
				else
					audio.stopAllSounds()
				end

				GameData.controlInfo = GameData.controlInfo or {}
				GameData.controlInfo.soundOn = game.soundOn
				GameState.save(GameData)

				self.soundSprite:removeSelf()
				self.soundSprite = display.newSprite( game.soundOn and SettingRes .. "sound_on.png" or SettingRes .. "sound_off.png")
				self.soundSprite:pos(340, self.button2:getLayer():getContentSize().height/2):addTo(self.button2:getLayer())
			end,
			priority = self.priority -1
		})
	self.button2:getLayer():pos(462, contentSize.height - 203):addTo(self.contentLayer)

	ui.newTTFLabelWithStroke({text = "音效", size = 30, font = ChineseFont, color = display.COLOR_WHITE,shadowColor=uihelper.hex2rgb("#242424")}):anch(0,0.5):pos(35, self.button2:getLayer():getContentSize().height/2 ):addTo(self.button2:getLayer())

	self.soundSprite = display.newSprite( game.soundOn and SettingRes .. "sound_on.png" or SettingRes .. "sound_off.png")
	self.soundSprite:pos(340, self.button2:getLayer():getContentSize().height/2):addTo(self.button2:getLayer())

	local button5 = DGBtn:new(SettingRes, {"button_bg.png"}, {
			callback = function()
			end,
			priority = self.priority -1
		})
	button5:getLayer():pos(32, contentSize.height - 344):addTo(self.contentLayer)

	ui.newTTFLabelWithStroke({text = "意见反馈", size = 30, font = ChineseFont, color = display.COLOR_WHITE,shadowColor=uihelper.hex2rgb("#242424")}):anch(0,0.5):pos(35, button5:getLayer():getContentSize().height/2 ):addTo(button5:getLayer())

	local subButton5 = DGBtn:new(GlobalRes, {"square_green_normal.png", "square_green_selected.png", "square_disabled.png"}, {
			text = { text = "查看", size = 26, font = ChineseFont , strokeColor = uihelper.hex2rgb("#242424") },
			callback = function()
			end,	
			priority = self.priority -2
		})
	subButton5:getLayer():anch(0.5,0.5):pos(340, button5:getLayer():getContentSize().height/2):addTo(button5:getLayer())


	local button6 = DGBtn:new(SettingRes, {"button_bg.png"}, {
			callback = function()

			end,
			priority = self.priority -1
		})
	button6:getLayer():pos(462, contentSize.height - 344):addTo(self.contentLayer)

	ui.newTTFLabelWithStroke({text = "游戏帮助", size = 30, font = ChineseFont, color = display.COLOR_WHITE,shadowColor=uihelper.hex2rgb("#242424")}):anch(0,0.5):pos(35, button6:getLayer():getContentSize().height/2 ):addTo(button6:getLayer())

	local subButton6 = DGBtn:new(GlobalRes, {"square_green_normal.png", "square_green_selected.png", "square_disabled.png"}, {
			text = { text = "瞅瞅", size = 26, font = ChineseFont , strokeColor = uihelper.hex2rgb("#242424")},
			callback = function()

			end,
			priority = self.priority -2
		})
	subButton6:getLayer():anch(0.5,0.5):pos(340, button6:getLayer():getContentSize().height/2):addTo(button6:getLayer())

	local button7 = DGBtn:new(SettingRes, {"button_bg.png"}, {
			callback = function()

			end,
			priority = self.priority -1
		})
	button7:getLayer():pos(32, contentSize.height - 485):addTo(self.contentLayer)

	ui.newTTFLabelWithStroke({text = "制作团队", size = 30, font = ChineseFont, color = display.COLOR_WHITE,shadowColor=uihelper.hex2rgb("#242424")}):anch(0,0.5):pos(35, button7:getLayer():getContentSize().height/2 ):addTo(button7:getLayer())

	local subButton7 = DGBtn:new(GlobalRes, {"square_green_normal.png", "square_green_selected.png", "square_disabled.png"}, {
			text = { text = "围观", size = 26, font = ChineseFont , strokeColor = uihelper.hex2rgb("#242424")},
			callback = function()

			end,
			priority = self.priority -2
		})
	subButton7:getLayer():anch(0.5,0.5):pos(340, button7:getLayer():getContentSize().height/2):addTo(button7:getLayer())

	local button8 = DGBtn:new(SettingRes, {"button_bg.png"}, {
			callback = function()

			end,
			priority = self.priority -1
		})
	button8:getLayer():pos(462, contentSize.height - 485):addTo(self.contentLayer)

	local subButton8
	if PACKAGE_NAME == "com.koramgame.lwsg.pp" or PACKAGE_NAME == "com.koramgame.lwsg.ky" then
		local label = PACKAGE_NAME == "com.koramgame.lwsg.pp" and "PP用户中心" or "快用用户中心"
		ui.newTTFLabelWithStroke({text = label, size = 30, font = ChineseFont, font = ChineseFont,color = display.COLOR_WHITE,shadowColor=uihelper.hex2rgb("#242424")}):anch(0,0.5):pos(35, button8:getLayer():getContentSize().height/2 ):addTo(button8:getLayer())

		subButton8 = DGBtn:new(GlobalRes, {"square_green_normal.png", "square_green_selected.png", "square_disabled.png"}, {
			text = { text = "进入", size = 26, font = ChineseFont , strokeColor = uihelper.hex2rgb("#242424") },
			callback = function()
				luaoc.callStaticMethod("ChannelManager", "userCenter", {})
			end,
			priority = self.priority -2
		})
	else
		ui.newTTFLabelWithStroke({text = "退出登录", size = 30, font = ChineseFont, font = ChineseFont,color = display.COLOR_WHITE,shadowColor=uihelper.hex2rgb("#242424")}):anch(0,0.5):pos(35, button8:getLayer():getContentSize().height/2 ):addTo(button8:getLayer())

		subButton8 = DGBtn:new(GlobalRes, {"square_green_normal.png", "square_green_selected.png", "square_disabled.png"}, {
			text = { text = "注销", size = 26, font = ChineseFont , strokeColor = uihelper.hex2rgb("#242424") },
			callback = function()
				game:closeSocket()
				-- game.role = nil
				
				switchScene("login", { layer = "login", logout = true })
			end,
			priority = self.priority -2
		})
	end
	subButton8:getLayer():anch(0.5,0.5):pos(340, button8:getLayer():getContentSize().height/2):addTo(button8:getLayer())
end

function SettingLayer:showHeroMap()
	local layer = HeroMapLayer.new({priority = self.priority -10})
	display.getRunningScene():addChild(layer:getLayer())
end

function SettingLayer:onCleanup()
	display.removeUnusedSpriteFrames()
end

return SettingLayer