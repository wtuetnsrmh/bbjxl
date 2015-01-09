local HeroRes = "resource/ui_rc/hero/"
local GlobalRes = "resource/ui_rc/global/"
local CarbonRes = "resource/ui_rc/carbon/"
local ParticleRes = "resource/ui_rc/particle/"
local GuideRes = "resource/ui_rc/guide/"
local BattleRes = "resource/ui_rc/battle/"
local EndRes = "resource/ui_rc/carbon/end/"
local LevelUpRes = "resource/ui_rc/carbon/levelup/"


local HeroChooseLayer = import("..home.hero.HeroChooseLayer")

local RoleUpLevelLayer = class("RoleUpLevelLayer", function()
	return display.newLayer(LevelUpRes.."levelup_bg.png")
end)

function RoleUpLevelLayer:ctor(params)
	self.params = params or {}

	self.priority = params.priority or -130
	self.size = self:getContentSize()

	self:anch(0.5, 0.5):pos(display.cx, display.cy + 20)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1 })

	self:getLayer():hide()
	self:performWithDelay(function() self:getLayer():show() self:runLevelUpAction() end, 1.8)
end

function RoleUpLevelLayer:initUI()
	--light
	local lightBg = display.newSprite(EndRes .. "light.png")
	lightBg:pos(self.size.width / 2, self.size.height - 180):addTo(self,-1)
	lightBg:runAction(CCRepeatForever:create(CCRotateBy:create(1, 80)))
	
	--升级文字：
	display.newSprite(LevelUpRes .. "uplevel_text.png"):pos(self.size.width / 2, self.size.height - 120):addTo(self)

	--烟火
	local particle = CCNodeExtend.extend(CCParticleSystemQuad:create(ParticleRes .. "roleup.plist"))
	particle:anch(0.5, 0.5):addTo(self, 10):pos(self.size.width / 2, display.cy + 150)
	-- particle:setDuration(1)

	--level change

	local xPos, yPos = 226, 346
	display.newSprite(LevelUpRes .. "levelup_text_bg.png"):anch(0.5, 0.5):pos(self.size.width / 2, yPos - 3)
		:addTo(self)
	display.newSprite(GlobalRes .. "number_arrow.png"):anch(0.5, 0.5):pos(self.size.width / 2, yPos)
		:addTo(self)
	local tempNode = display.newSprite(GlobalRes .. "lv_label.png")
	tempNode:anch(0, 0.5):pos(xPos, yPos):addTo(self)
	xPos = xPos + tempNode:getContentSize().width
	ui.newTTFLabelWithStroke({text = self.params.origLevel, size = 30, strokeColor = display.COLOR_FONT})
		:anch(0, 0.5):pos(xPos, yPos):addTo(self)

	xPos = 373
	tempNode = display.newSprite(GlobalRes .. "lv_label.png")
	tempNode:anch(0, 0.5):pos(xPos, yPos):addTo(self)
	xPos = xPos + tempNode:getContentSize().width
	ui.newTTFLabelWithStroke({text = self.params.curLevel, size = 30, strokeColor = display.COLOR_FONT})
		:anch(0, 0.5):pos(xPos, yPos):addTo(self)


	self:dataChangeDetail()

	local roleInfo = roleInfoCsv:getDataByLevel(self.params.curLevel)
	local funcKeys = table.keys(roleInfo.functionOpen)

	-- 1=点将 2=pvp 3=科技 4=美人 5=星座 6=过关斩将 7=名将 8=副将
	local funcInfos = {
		["1"] = { name = "点将",
				icon = "choose_normal.png",
				res  = "resource/ui_rc/home/",
			 	callback = game.role.level ~= 12 and (function() switchScene("home") end) or nil},
		["2"] = { name = "战场", 
				res = "",
				pic = "",
				callback = function() 
					switchScene("home") 
				end },
		["3"] = { name = "科技", 
				res = "",
				pic = "",
				callback = function() 
					switchScene("home") 
				end },
		["4"] = { name = "美人", 
				res = "",
				pic = "",
				callback = function() 
					switchScene("home") 
				end },
		["5"] = { name = "星座", 
				res = "",
				pic = "",
				callback = function() 
					switchScene("home") 
				end },
		["6"] = { name = "过关斩将", 
				res = "",
				pic = "",
				callback = function() 
					switchScene("home") 
				end },
		["7"] = { name = "名将", 
				res = "",
				pic = "",
				callback = function() 
					switchScene("home") 
				end },
		["8"] = { name = "小伙伴", 
				res = "",
				pic = "",
				callback = function() 
					switchScene("home") 
				end },
		["9"] = { name = "签到", 
				res = "",
				pic = "",
				callback = function() 
					switchScene("home") 
				end },
		["10"] = { name = "扫荡", 
				res = "",
				pic = "",
				callback = nil },
		["11"] = { name = "自动战斗", 
				res = "",
				pic = "",
				callback = nil },
		["12"] = { name = "加速战斗", 
				res = "",
				pic = "",
				callback = nil },
		["13"] = { name = "经验副本", 
				res = "",
				pic = "",
				callback = function()
					switchScene("home") 
				end },
		["14"] = { name = "阵营与美女副本", 
				res = "",
				pic = "",
				callback = nil },
		["15"] = { name = "金钱副本", 
				res = "",
				pic = "",
				callback = function()
					switchScene("home") 
				end },
		["17"] = { name = "进化",
				res  = "resource/ui_rc/carbon/failure/",
				pic = "evolution.png",
				callback = function()
					switchScene("home") 
				end },
		["18"] = { name = "觉醒",		
				res  = "resource/ui_rc/carbon/failure/",
				pic = "wake.png",
				canActive = function()
					for slot, data in pairs(game.role.slots) do
						local hero = game.role.heros[data.heroId]
						if hero and hero.type == 153 then
							return true
						end
					end
					return false
				end,
				callback = function()		
					switchScene("home") 
				end },
		["19"] = { name = "出塞", 
				res = "",
				pic = "",
				callback = function() 
					switchScene("home") 
				end },
		["20"] = { name = "装备", 
				res = "",
				pic = "",
				callback = function() 
					switchScene("home")
				end },
		["21"] = { name = "技能", 
				res = "",
				pic = "",
				callback = function()
					game:activeGuide(600) 
					switchScene("home")
				end },
		["22"] = { name = "每日任务", 
				res = "",
				pic = "",
				callback = function() 
					switchScene("home")
				end },

	}

	local toPosY = #funcInfos > 1 and 200 or 170
	self.canJump = false
	for index = 1, 2 do
		print(funcKeys[index], funcInfos[funcKeys[index]])
		if not funcKeys[index] or not funcInfos[funcKeys[index]] or (funcInfos[funcKeys[index]].canActive and not funcInfos[funcKeys[index]].canActive()) then break end
		local funcInfo = funcInfos[funcKeys[index]]
		
		local yPos = 130
		display.newSprite(LevelUpRes .. "text_open.png"):anch(0.5, 0.5):pos(self.size.width/2, 182):addTo(self)
		ui.newTTFLabelWithStroke({text=funcInfo.name, size = 30, font = ChineseFont, color = uihelper.hex2rgb("#00ffff"), strokeColor = display.COLOR_FONT })
			:anch(0.5, 0.5):pos(self.size.width/2, yPos):addTo(self)
		-- 跳转
		if funcInfo.callback then
			local gotoBtn = DGBtn:new(GlobalRes, {"btn_ellipse_normal.png", "btn_ellipse_selected.png"},
				{	
					priority = self.priority,
					text = { text = "去看看", font = ChineseFont, size = 26, strokeColor = display.COLOR_FONT, strokeSize = 2},
					callback = function()
						self:getLayer():removeSelf() 
						if type(funcInfo.callback) == "function" then
							print("等级" .. self.params.curLevel)
							funcInfo.callback()
						end
					end,
				}):getLayer()
			gotoBtn:anch(0, 0.5):pos(430, yPos):addTo(self)
			self.canJump = true
			self.guideBtn = gotoBtn
		end
	end

	self:checkGuide()
	if roleInfo.guideId ~= 0 then	
		game:activeGuide(roleInfo.guideId)
	end
end

function RoleUpLevelLayer:runLevelUpAction()
	local function runAnimation(fileName, frameNum, fps, xOffset)
		display.addSpriteFramesWithFile(LevelUpRes..fileName..".plist", LevelUpRes..fileName..".png")

		local frames = {}
		for index = 1, frameNum do
			local frameId = string.format("%02d", index)
			frames[#frames + 1] = display.newSpriteFrame(fileName.."_" .. frameId .. ".png")
		end

		fps = fps or frameNum
		xOffset = xOffset or 0
		local animation = display.newAnimation(frames, 1.0 / fps)
		local sprite = display.newSprite(frames[1]):anch(0.5, 0.5):pos(display.cx + xOffset, display.cy):addTo(self:getLayer())
		sprite:scale(2.0)
		sprite:runAction(transition.sequence({
			CCAnimate:create(animation),
			CCRemoveSelf:create(),
			}))
	end

	self:setVisible(false)
	
	runAnimation("levelup", 15, nil, 20)

	local moveBy = {ccp(display.cx-100, display.cy), ccp(display.cx, display.cy), ccp(display.cx+100, display.cy)}
	local xPos = {0, display.cx, display.width}
	local delayTime = 0
	for index = 1, 3 do
		local sprite = display.newSprite(LevelUpRes .. string.format("levelup_text_%d.png", index))
		sprite:scale(15.0):pos(xPos[index], display.cy):addTo(self:getLayer())
		sprite:setOpacity(0)
		local array = CCArray:create()
		array:addObject(CCScaleTo:create(0.2, 0.8))
		array:addObject(CCMoveTo:create(0.2, moveBy[index]))
		array:addObject(CCFadeIn:create(0.15))
		local seq = {
			CCDelayTime:create(delayTime),
			CCSpawn:create(array),
			CCScaleTo:create(0.1, 1.4),
			CCScaleTo:create(0.1, 1),
		}
		if index == 3 then
			table.insert(seq, CCCallFunc:create(function() 
				self:setVisible(true)
				self:initUI()
			end))
		end
		table.insert(seq, CCDelayTime:create((3-index)*0.05 + 0.15))
		table.insert(seq, CCRemoveSelf:create())

		sprite:runAction(transition.sequence(seq))
		delayTime = delayTime + 0.15
	end
	runAnimation("text_star", 9, nil, -20)

	game:playMusic(33)

	-- sprite:runAction(transition.sequence({
	-- 	CCAnimate:create(animation),
	-- 	CCRemoveSelf:create(),
	-- 	}))
end

function RoleUpLevelLayer:onEnter()
	
end

function RoleUpLevelLayer:checkGuide(remove)
	if self.guideBtn then
		game:addGuideNode({node = self.guideBtn, remove = remove,
			guideIds = {1009, 1039, 1067, 1095, 1180, 1190, 1200, 1210, 1220, 1230, 1240, 1250, 1260, 1270, 1274, 1281}
		})
	end
end

function RoleUpLevelLayer:onExit()
	self:checkGuide(true)
end

function RoleUpLevelLayer:dataChangeDetail()
	--体力：
	local fontSize = 20
	local posY1 , posY2 ,posY3 = 283, 232
	local posX1 , posX2 , posX3, posX4 , posX5 = 201,359,345,416,446
	ui.newTTFLabel({ text = "当前体力", size = fontSize })
		:anch(0.5, 0):pos(posX1, posY1):addTo(self)


	local curNum = game.role.health
	local oldHeal = game.role.oldHealth
	curNum = oldHeal > curNum and oldHeal or curNum

	ui.newTTFLabel({ text = tostring(oldHeal), size = fontSize })
		:anch(0, 0):pos(posX3,posY1):addTo(self)

	display.newSprite(GlobalRes .. "number_arrow.png"):anch(0.5, 0)
		:pos(posX4, posY1):addTo(self)

	ui.newTTFLabel({ text = tostring(curNum), size = fontSize, color = uihelper.hex2rgb("#7ce810") })
		:anch(0, 0):pos(posX5, posY1):addTo(self)

	--等级上限：
	ui.newTTFLabel({ text = "武将等级上限", size = fontSize })
		:anch(0.5, 0):pos(posX1, posY2):addTo(self)
	ui.newTTFLabel({ text = self.params.origLevel, size = fontSize })
		:anch(0, 0):pos(posX3, posY2):addTo(self)
	display.newSprite(GlobalRes .. "number_arrow.png"):anch(0.5, 0)
		:pos(posX4, posY2):addTo(self)
	ui.newTTFLabel({ text = self.params.curLevel, size = fontSize, color = uihelper.hex2rgb("#7ce810") })
		:anch(0, 0):pos(posX5, posY2):addTo(self)


	local sureBtn = DGBtn:new(GlobalRes, {"btn_ellipse_normal.png", "btn_ellipse_selected.png"},
		{	
			priority = self.priority,
			text = { text = "确定", size = 26, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
				self:getLayer():removeSelf()
				if self.params.onComplete and not canJump then
					self.params.onComplete() 
				end
			end,
		}):getLayer()
	sureBtn:anch(0.5, 0):pos(self.size.width * 0.5, 36):addTo(self)
	
end

function RoleUpLevelLayer:getLayer()
	return self.mask:getLayer()
end

return RoleUpLevelLayer