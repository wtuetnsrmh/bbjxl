-- 角色详情界面
-- revised by yangkun
-- 2014.7.4

local GlobalRes = "resource/ui_rc/global/"
local FriendRes = "resource/ui_rc/friend/"
local OtherPlayerHeroChooseLayer = import(".home.hero.OtherPlayerHeroChooseLayer")

local RoleDetailLayer = class("RoleDetailLayer", function()
	return display.newLayer(GlobalRes .. "middle_popup.png")
end)

function RoleDetailLayer:ctor(params)
	params = params or {}
	self.priority = params.priority or -130
	self.size = self:getContentSize()

	local titleBar=display.newSprite(GlobalRes .. "title_bar_long.png"):anch(0.5,0.5):pos(self.size.width/2, self.size.height - 33):addTo(self)
	display.newSprite(FriendRes .. "role_detail_title.png"):pos(titleBar:getContentSize().width/2, titleBar:getContentSize().height/2):addTo(titleBar)

	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1, ObjSize = self.size, clickOut = function() self.mask:remove() end })

	local centerBg = display.newSprite("resource/ui_rc/friend/role_detail_inner.png")
	local centerSize = centerBg:getContentSize()

	centerBg:pos(self.size.width / 2, self.size.height / 2+10):addTo(self)

	local roleResponse = params.roleDigest
	
	ui.newTTFLabel({ text = roleResponse.roleInfo.name, size = 30, color = display.COLOR_DARKYELLOW })
		:anch(0, 0):pos(50, centerSize.height - 60):addTo(centerBg)
	display.newSprite(GlobalRes .. "lv_label.png"):anch(0, 0)
		:pos(240, centerSize.height - 55):addTo(centerBg)
	ui.newTTFLabelWithStroke({ text = roleResponse.roleInfo.level, size = 28, color = display.COLOR_WHITE,strokeColor=display.COLOR_BUTTON_STROKE })
		:anch(0, 0):pos(290, centerSize.height - 60):addTo(centerBg)
	local pvpGiftData = pvpGiftCsv:getGiftData(roleResponse.roleInfo.pvpRank)
	ui.newTTFLabel({ text = "战场称号:", size = 24, color = display.COLOR_DARKYELLOW })
		:anch(0, 0):pos(50, centerSize.height - 100):addTo(centerBg)
	ui.newTTFLabelWithStroke({ text = (pvpGiftData and pvpGiftData.name or ""), size = 24, color = display.COLOR_YELLOW, })
		:anch(0, 0):pos(240, centerSize.height - 100):addTo(centerBg)
	ui.newTTFLabel({ text = "最近登录:", size = 24, color = display.COLOR_DARKYELLOW })
		:anch(0, 0):pos(50, centerSize.height - 140):addTo(centerBg)
	ui.newTTFLabelWithStroke({ text = os.date("%Y/%m/%d %H:%M", roleResponse.roleInfo.lastLoginTime), size = 24, color = display.COLOR_YELLOW })
		:anch(0, 0):pos(240, centerSize.height - 140):addTo(centerBg)

	ui.newTTFLabelWithStroke({ text = "上阵武将", size = 24, color = ccc3(63, 255, 248), strokeColor = display.COLOR_BROWNSTROKE })
		:anch(0, 0):pos(50, centerSize.height - 190):addTo(centerBg)
	local xBegin = 50
	for index, hero in ipairs(roleResponse.heros) do
		local headFrame = HeroHead.new(
			{ 
			priority = self.priority,
			type = hero.type,
			wakeLevel = hero.wakeLevel,
			star = hero.star,
			evolutionCount = hero.evolutionCount,
			callback=function()
				local layer = OtherPlayerHeroChooseLayer.new({roleInfo=roleResponse, parent = self, closemode = 1, priority = self.priority})
				layer:getLayer():addTo(display.getRunningScene())
				end,
			 }):getLayer()
		headFrame:anch(0, 0):pos(xBegin + (index - 1) * 130, centerSize.height - 310):addTo(centerBg)
		

		local unitData = unitCsv:getUnitByType(hero.type)
		local evolutionCount = uihelper.getShowEvolutionCount(hero.evolutionCount)
		local heroName = unitData.name .. (evolutionCount > 0 and "+" .. evolutionCount or "")
		ui.newTTFLabelWithStroke({ text = heroName, size = 20, font = ChineseFont, color = uihelper.getEvolColor(hero.evolutionCount), strokeColor = display.COLOR_FONT, strokeSize = 2 }):anch(0.5, 1)
			:pos(headFrame:getContentSize().width / 2, 4):addTo(headFrame)
	end

	params.button1Data = params.button1Data or {}
	params.button2Data = params.button2Data or {}
	local btnNum = table.nums(params.button2Data) > 0 and 2 or 1
	if btnNum == 1 then
		local button1 = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png"},
			{	
				priority = self.priority,
				text = { text = params.button1Data.text or "确定", size = 28, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
				callback = function()
					self:getLayer():removeSelf()
					if params.button1Data.callback then
						params.button1Data.callback()
					end
				end,
			}):getLayer()
		button1:anch(0.5, 0):pos(self.size.width / 2, 20):addTo(self)
	else
		local button1 = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png"},
			{	
				priority = self.priority,
				text = { text = params.button1Data.text or "取消", size = 28, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
				callback = function()
					self:getLayer():removeSelf()
					if params.button1Data.callback then
						params.button1Data.callback()
					end
				end,
			}):getLayer()
		button1:anch(1, 0):pos(self.size.width / 2 - 40, 20):addTo(self)

		local button2 = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png"},
			{	
				priority = self.priority,
				text = { text = params.button2Data.text or "确定", size = 28, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
				callback = function()
					self:getLayer():removeSelf()
					if params.button2Data.callback then
						params.button2Data.callback()
					end
				end,
			}):getLayer()
		button2:anch(0, 0):pos(self.size.width / 2 + 40, 20):addTo(self)
	end
end

function RoleDetailLayer:getLayer()
	return self.mask:getLayer()
end

return RoleDetailLayer