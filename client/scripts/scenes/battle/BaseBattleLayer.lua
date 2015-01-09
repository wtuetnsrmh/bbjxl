import(".BattleConstants")
local ControlLayer = import(".ControlLayer")
local SpriteBullet = import(".SpriteBullet")
local SpriteSoldier = import(".SpriteSoldier")
local BattlePauseLayer = import(".BattlePauseLayer")

local BaseBattleLayer = class("BaseBattleLayer", ControlLayer)
local TransitionMoveSpeed = 300
local sharedScheduler = CCDirector:sharedDirector():getScheduler()

function BaseBattleLayer:ctor(params)
	require("framework.api.EventProtocol").extend(self)
	
	params = params or {}

	self.rowCount = BattleConstants.RowMax
	self.colCount = BattleConstants.ColMax
	self.collisionPixel = 70
    self.battleType = params.battleType
	self.angryCD = params.angryCD or globalCsv:getFieldValue("angryCD")

	self.currentStage = 1
	self.battleStatus = 0 	-- 0:表示未开始, 1:进行中, 2:结束

	-- 阵型坐标
	self.leftFormationPositions = {}
	self.rightFormationPositions = {}

	-- 技能阴影叠加计数
	self.skillMaskCount = 0

	-- 特效上层
	self.effectLayer0 = ControlLayer.new()
	self.effectLayer0:addTo(self, BattleConstants.zOrderConstants["effect0"])
	
	-- 特效下层
	self.effectLayer1 = ControlLayer.new()
	self.effectLayer1:addTo(self, BattleConstants.zOrderConstants["effect1"])

	-- 用于接收触摸事件
	self:setTouchEnabled(false)
	self:addTouchEventListener(function(event, x, y) return self:onTouch(event, x, y) end)
end

function BaseBattleLayer:initCommonUI()
	display.addSpriteFramesWithFile("resource/ui_rc/battle/left_grid.plist", "resource/ui_rc/battle/left_grid.png")
	local leftGridFrames = {}

	for index = 1, 6 do
		local frameId = string.format("%02d", index)
		leftGridFrames[#leftGridFrames + 1] = display.newSpriteFrame("left_grid_" .. frameId .. ".png")
	end
	self.leftGridAnimation = display.newAnimation(leftGridFrames, 2.0 / 10)

	-- 武将位置需要调整
	-- 左边的占位符
	for col = 1, self.colCount do
		self.leftFormationPositions[col] = self.leftFormationPositions[col] or {}
		for row = 1, self.rowCount do
			self.leftFormationPositions[col] = self.leftFormationPositions[col] or {}
			self.leftFormationPositions[col][row] = self.leftFormationPositions[col][row] or {}
			self.leftFormationPositions[col][row].x = BattleConstants.leftPositions[col][row].x
			self.leftFormationPositions[col][row].y = BattleConstants.leftPositions[col][row].y

			local placeHolder = display.newSprite(leftGridFrames[1])
			placeHolder:addTo(self):pos(BattleConstants.leftPositions[col][row].x, BattleConstants.leftPositions[col][row].y)
			self.leftFormationPositions[col][row].placeHolder = placeHolder
			placeHolder:playAnimationForever(self.leftGridAnimation)
		end
	end

	-- 右边的占位符
	for col = 1, self.colCount do
		self.rightFormationPositions[col] = self.rightFormationPositions[col] or {}
		for row = 1, self.rowCount do
			self.rightFormationPositions[col][row] = self.rightFormationPositions[col][row] or {}
			self.rightFormationPositions[col][row].x = BattleConstants.rightPositions[col][row].x
			self.rightFormationPositions[col][row].y = BattleConstants.rightPositions[col][row].y

			local placeHolder = display.newSprite(BattleRes .. "right_grid.png")
			placeHolder:addTo(self):pos(BattleConstants.rightPositions[col][row].x, BattleConstants.rightPositions[col][row].y)
			self.rightFormationPositions[col][row].placeHolder = placeHolder
		end
	end

	-- 施放attack2时的脚底小光圈
	self.attack2Effect = SpriteBullet.new({ id = 100, usage = 1 })
end

-- 显示战场上的武将
function BaseBattleLayer:addBattleHeros(battleHeros)
	local heros = table.values(battleHeros)
	for index, hero in ipairs(heros) do
		-- 没有初始化过
		if not hero.armatureName then
			hero.battleField = self.battleField
			hero.parentLayer = self
			hero = SpriteSoldier.new(hero)
			--hero:initHeroAttributeByPassiveSkills()
		end

		self.battleField:addSoldier(hero)
		hero:initHeroDisplay()
		
		if hero.camp == "left" then
			hero.displayNode:setRotationY(180)

			local position = self.leftFormationPositions[hero.anchPoint.x][hero.anchPoint.y]
			hero.position = { x = position.x, y = position.y }

			local zorderValue = BattleConstants:calSoldierZorder(hero.anchPoint.x, hero.anchPoint.y)
			hero.displayNode:pos(position.x - 580, position.y):addTo(self, zorderValue)
			position.hero = hero

			-- action
			local actions = {
				CCCallFunc:create(function() hero.animation:play("move") end),
				CCMoveTo:create(580 / TransitionMoveSpeed, ccp(position.x, position.y)),
				CCCallFunc:create(function() hero.animation:play("idle") end),
			}
			hero.displayNode:runAction(transition.sequence(actions))
		else
			local position = self.rightFormationPositions[hero.anchPoint.x][hero.anchPoint.y]

			local zorderValue = BattleConstants:calSoldierZorder(hero.anchPoint.x, hero.anchPoint.y, "right")
			hero.displayNode:pos(position.x + 580, position.y):addTo(self, zorderValue)
			hero.position = { x = position.x, y = position.y }
			position.hero = hero

			-- action
			local actions = {
				CCCallFunc:create(function() hero.animation:play("move") end),
				CCMoveTo:create(580 / TransitionMoveSpeed, ccp(position.x, position.y)),
				CCCallFunc:create(function() 
					hero.animation:play("idle") 
					-- 最后一个士兵
					if index == #heros then
						-- 开始战斗按钮 -- 改成箭头
						if(self.currentStage == 1 or globalCsv:getFieldValue("pauseBattle") == 1 ) and self.battleType ~= BattleType.Start then
							self.startGameBtn = DGBtn:new(BattleRes, {"begin_normal.png", "begin_selected.png"},
								{	
									callback = function()
										self:startGame()
									end,
								})

							self.startGameBtn.item[1]:runAction(CCRepeatForever:create(
								transition.sequence({
									CCScaleTo:create(0.5, 0.8),
									CCScaleTo:create(0.5, 1)
								})))
							local startSize = self.startGameBtn:getLayer():getContentSize()

							local fireBackSp = self:frameActionOnSprite("battle_begin",5,true)
							:pos(startSize.width/2, startSize.height/2)
							:addTo(self.startGameBtn:getLayer())

							self.startGameBtn:getLayer():anch(0.5, 0.5)
								:pos(display.width - 140, display.height / 2 + 50):addTo(self, BattleConstants.zOrderConstants["bottomBar"])

							game:addGuideNode({node = self.startGameBtn:getLayer(),
								guideIds = {1007, }
							})

							-- 暂停按钮
							self.pauseBtn = DGBtn:new(BattleRes, {"pause_btn.png","pause_btn_press.png"},
								{
									scale = 0.9,
									callback = function()
										local battlePauseLayer = BattlePauseLayer.new({parent = self,carbonInfo=self.carbonInfo, battleType = self.battleType})
										battlePauseLayer:getLayer():pos(0,0):addTo(self, BattleConstants.zOrderConstants["pause"])

										game:pause()
									end
								})
							self.pauseBtn:getLayer():anch(0, 0.5)
								:pos(20, display.height - 45):addTo(self, BattleConstants.zOrderConstants["controBtns"])
						else
							self:startGame()
						end
						self:setTouchEnabled(true)
					end
				end),
			}
			hero.displayNode:runAction(transition.sequence(actions))
		end
	end
end

-- 隐藏战斗显示的UI
function BaseBattleLayer:hideUI()
	-- 左侧占位符
	for col = 1, self.colCount do
		for row = 1, self.rowCount do
			self.leftFormationPositions[col][row].placeHolder:removeSelf()
		end
	end

	for col = 1, self.colCount do
		for row = 1, self.rowCount do
			self.rightFormationPositions[col][row].placeHolder:removeSelf()
		end
	end

	-- 开始按钮
	if self.startGameBtn then
		self.startGameBtn:getLayer():removeSelf()
	end
end

-- 显示开始战斗后的显示UI
function BaseBattleLayer:showBattleUI(...)
	-- 加速按钮
	if not self.speedUpBtn then
		self.speedUpBtn = DGBtn:new(BattleRes, { game.role.battleSpeed .. "_speed.png",game.role.battleSpeed .. "_speed_press.png" },
			{
				callback = function()
					local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
					if game.role.vipLevel < 1 and roleInfo.speedOpen < 0 then
						local sysMsg = sysMsgCsv:getMsgbyId(555)
						DGMsgBox.new({text = string.format(sysMsg.text, math.abs(roleInfo.speedOpen)), type = 1})
					else
						game.role.battleSpeed = game.role.battleSpeed == 2 and 1 or 2
						local bin = pb.encode("RoleUpdateProperty", { key = "battleSpeed", newValue = game.role.battleSpeed, roleId = game.role.id })
						game:sendData(actionCodes.RoleUpdateProperty, bin, #bin)
						self.speedUpBtn:setBg(nil, {BattleRes .. game.role.battleSpeed .. "_speed.png",BattleRes .. game.role.battleSpeed .. "_speed_press.png"})

						sharedScheduler:setTimeScale(game.role.battleSpeed)
					end
				end,
			})
		self.speedUpBtn:getLayer():anch(1, 0.5):pos(display.width - 138, display.height - 45):addTo(self)
	end

	-- 自动战斗按钮
	if not self.autoGameBtn then
		--pvp双方自动战斗
		if self.battleType==BattleType.PvP then
			self.leftCamp.isAutoFight=true
		end

		self.autoGameBtn = DGBtn:new(BattleRes, { self.leftCamp.isAutoFight and "auto_cancel.png" or "auto.png",self.leftCamp.isAutoFight and "auto_cancel_pressed.png" or "auto_press.png"},
			{	
				noTouch=self.battleType==BattleType.PvP,
				callback = function()
					local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)
					local isVipEnough = vipCsv:getDataByLevel(game.role.vipLevel).autoBattle
					if not tobool(isVipEnough) and roleInfo.autoOpen < 0 then
						local sysMsg = sysMsgCsv:getMsgbyId(556)
						DGMsgBox.new({text = string.format(sysMsg.text, math.abs(roleInfo.autoOpen)), type = 1})
					else
						self.leftCamp.isAutoFight = not self.leftCamp.isAutoFight
						local res = self.leftCamp.isAutoFight and "auto_cancel.png" or "auto.png"

						self.autoGameBtn:setBg(nil, {BattleRes .. res,BattleRes .. (self.leftCamp.isAutoFight and "auto_cancel_pressed.png" or "auto_press.png")})
					end
				end,
			})
		self.autoGameBtn:getLayer():anch(1, 0.5):pos(display.width - 20, display.height - 45):addTo(self)
	end
end

function BaseBattleLayer:savePveFormation()
	game.role.pveFormation = {}
	
	for anchKey, soldier in pairs(self.battleField.leftSoldierMap) do
		local index = BattleConstants:anchToIndex(soldier.anchPoint.x, soldier.anchPoint.y)
		game.role.pveFormation[index] = soldier.id
	end

	game.role:updatePveFormation()
end

function BaseBattleLayer:refreshAngrySlot()
	local angryFrame = display.newSprite(BattleRes .. "anger_frame.png")
	local angryBg = display.newSprite(BattleRes .. "anger_bg.png")
	angryBg:anch(0, 0):pos(-94, -14):addTo(angryFrame, -2)
	angryFrame:pos(display.cx, 190):addTo(self, BattleConstants.zOrderConstants["controBtns"] + 17, 1001)

	--怒气火光：
	local fireBackSp = self:frameActionOnSprite("nuqi_normal",5,true)
	:pos(55,angryFrame:getContentSize().height/2 + 60):scale(0.8)
	:addTo(angryBg)

	--怒字
	local fireFontIco = display.newSprite(BattleRes.."anger_font.png")
		:pos(59,angryFrame:getContentSize().height/2 + 45):addTo(angryBg)

	--进度光效：
	local yy = angryFrame:getContentSize().height/2 - 4
	local ww = angryFrame:getContentSize().width + 5
	

	local size = 0
	size = size + self.leftCamp.angryUnitNum * 4
	size = size + math.floor(self.leftCamp.angryAccumulateTime * 4 / self.angryCD)

	local angryProgress = display.newProgressTimer(BattleRes .. "anger_bar.png", display.PROGRESS_TIMER_BAR)
	angryProgress:setMidpoint(ccp(0, 0))
	angryProgress:setBarChangeRate(ccp(1, 0))
	angryProgress:setPercentage(size * 100 / 60)
	angryProgress:pos(angryFrame:getContentSize().width / 2 -2, angryFrame:getContentSize().height / 2 ):addTo(angryFrame,-1)

	--line fire
	local lineFire = self:frameActionOnSprite("nuqi_increase",10,true):pos(-4,yy+4):addTo(angryProgress)
	lineFire:setScaleY(0.9)

	--line fire corver
	local fireLineBg = display.newSprite(BattleRes.."line_fire_bg.png"):anch(1,0.5):pos(-6, yy+4):addTo(angryProgress,999)

	local size = 0
	local offset = 0
	size = size + self.leftCamp.angryUnitNum * 4
	size = size + math.floor(self.leftCamp.angryAccumulateTime * 4 / self.angryCD)
	lineFire:pos(size / 60 * ww,yy+4)
	fireLineBg:pos(size / 60 * ww,yy+4)

	self.leftCamp:addEventListener("updateAngryValue", function(event)
		local size = 0
		size = size + self.leftCamp.angryUnitNum * 4
		size = size + math.floor(self.leftCamp.angryAccumulateTime * 4 / self.angryCD)
		angryProgress:setPercentage(size * 100 / 60)
		offset = angryProgress:getPercentage()
		if offset > 99.5 then
			lineFire:setVisible(false)
			fireLineBg:setVisible(false)
		else
			lineFire:setVisible(true)
			fireLineBg:setVisible(true)
			lineFire:pos(offset/100 * ww + 5 * (1-offset/100) - 4,yy+4)
			fireLineBg:pos(offset/100 * ww + 5 * (1-offset/100) - 6,yy+4)
		end
		
	end)
end

function BaseBattleLayer:fireForDead()
	if self:getChildByTag(1001) then
		local fireFrountSp = self:frameActionOnSprite("nuqi_up",6,false)
		:pos(-30,80)
		:addTo(self:getChildByTag(1001))
	end
end

function BaseBattleLayer:frameActionOnSprite(fileName,frameNum,isForever)

	display.addSpriteFramesWithFile(BattleRes..fileName..".plist", BattleRes..fileName..".png")
	local framesTable = {}
	for index = 1, frameNum do
		local frameId = string.format("%02d", index)
		framesTable[#framesTable + 1] = display.newSpriteFrame(fileName.."_" .. frameId .. ".png")
	end
	local panimate = display.newAnimation(framesTable, 1.0/10)
	local sprite = display.newSprite(framesTable[1])
	if isForever then
		sprite:playAnimationForever(panimate)
	else
		sprite:playAnimationOnce(panimate)
	end
	return sprite
end

-- 美人鼓舞
function BaseBattleLayer:showBeautyInspire(callback)
	local beautyMask = DGMask:new({ opacity = 0 })
	beautyMask:getLayer():addTo(self, 1000)

	local allBeauties = {}
	for _, beauty in ipairs(self.battleField.leftCamp.beauties) do
		table.insert(allBeauties, { beauty = beauty, camp = "left" })
	end
	for _, beauty in ipairs(self.battleField.rightCamp.beauties) do
		table.insert(allBeauties, { beauty = beauty, camp = "right" })
	end

	local endCallback = function()
		beautyMask:remove()
		callback()
	end

	local addData={}
	local beautyShowAction
	beautyShowAction = function(index)
		if index > #allBeauties then
			endCallback()
			return
		end

		local beautyId = allBeauties[index].beauty.beautyId
		local camp = allBeauties[index].camp
		local res = beautyListCsv:getBeautyById(beautyId).heroRes
		local maskRes=beautyListCsv:getBeautyById(beautyId).heroMaskRes

		--1.init beauty and word
		local hxStart = (camp == "right") and  display.cx * 3 or -display.cx
		local wxStart = (camp == "right") and  -display.cx or display.cx * 3

		local blackbg = display.newSprite("resource/ui_rc/battle/beauty/beauty_bg.png")
		:pos(hxStart,display.cy)
		:addTo(self, 8000)
		blackbg:setCascadeOpacityEnabled(true)

		local bx = (camp == "right") and  700 or 400 
		local lineSp = display.newSprite("resource/ui_rc/battle/beauty/beauty_line.png")
		local beautySp = uihelper.createMaskSprite(res,maskRes)
		:scale(0.5)
		:pos(bx,100) 
		:addTo(lineSp)

		local headIcon = getShaderNode({steRes = "resource/ui_rc/battle/beauty/beauty_cut.png",node = lineSp,isFlip = (camp == "right")})
		headIcon:setPosition(ccp(blackbg:getContentSize().width/2, blackbg:getContentSize().height/2))
		blackbg:addChild(headIcon)
		blackbg:setFlipX(camp == "right")

		local wordSp = display.newSprite("resource/ui_rc/battle/beauty/beauty_inspire.png")
		:pos(wxStart,display.cy)
		:addTo(self, 8000)

		local artFontRes = {"attr_HP","attr_Attack","attr_Defense"}

		-- 2.enter battle
		local yy = display.cy
		local hxEnd = display.cx
		local wxEnd = (camp == "left") and display.cx + 152 or display.cx - 152 
		local prop = {[1] = "hpBonus",[2] = "atkBonus",[3] = "defBonus"}	
		local Hero = require("datamodel.Hero")
		local beautys = {}
		beautys[#beautys + 1] = allBeauties[index].beauty
		
		addData[index]= Hero.sGetBeautyBonusValues()

		local function showAddtion(sindex, camp, callback,addAttrs)
			if sindex < 4 then 
				local roundi = 0
				local soldierNum = table.nums(self.battleField[camp .. "SoldierMap"])
				for anchKey, soldier in pairs(self.battleField[camp .. "SoldierMap"]) do
					local bg = display.newNode()
						:anch(0.5, 0.5)
						:pos(soldier.position.x - 26, soldier.position.y + 150)
						:addTo(self,999)
					local artFt = display.newSprite("resource/ui_rc/battle/effect/"..artFontRes[sindex]..".png")
						:anch(0.5,0.5)
						:pos(0,4)
						:addTo(bg)
					local addtionLabel = ui.newBMFontLabel({ text = "+"..tostring(addAttrs[prop[sindex]]), font = "resource/ui_rc/battle/font/num_b.fnt" })
						:anch(0.5, 0.5)
						:pos(artFt:getContentSize().width + 10,0)
						:addTo(bg)
					bg:setScale(0.2)
					bg:runAction(transition.sequence({
						CCSpawn:createWithTwoActions(CCMoveBy:create(0.5, ccp(0, 20)), CCScaleTo:create(0.2, 0.8)),
						CCRemoveSelf:create(),
						CCCallFunc:create(function()
								roundi = roundi + 1
		                        if roundi >= soldierNum then
		                        	showAddtion(sindex + 1, camp, callback,addAttrs)		  
		                        	if sindex == 3 and callback then
		                        		callback()
		                        	end
		                        end
							end),
					}))
				end
			end
		end

		--修正：
		local xRM = (camp == "right") and display.cx * 2 or display.cx * -2  
		self:runAction(transition.sequence({
               CCCallFunc:create(function()
               		blackbg:runAction(transition.sequence({
						CCMoveTo:create(0.1, ccp(hxEnd, yy)),
					}))
					wordSp:runAction(transition.sequence({
						CCMoveTo:create(0.1, ccp(wxEnd, yy)),
					}))
               	end),
               CCDelayTime:create(1),
               CCCallFunc:create(function()
               		blackbg:runAction(transition.sequence({
						CCMoveBy:create(0.1, ccp(xRM,0)),
						-- CCCallFunc:create(function()
						-- 	showAddtion(1)
						-- end),
						CCDelayTime:create(0.6),
						CCRemoveSelf:create(),
					}))
					wordSp:runAction(transition.sequence({
						CCMoveBy:create(0.1, ccp(xRM,0)),
						CCRemoveSelf:create(),
						CCCallFunc:create(function()
							if index < 2 then 
								if index + 1 > #allBeauties then
									showAddtion(1, camp, endCallback,addData[1])
								else
									beautyShowAction(index + 1)
								end
							else
							 	showAddtion(1, "left", endCallback,addData[1])
							 	showAddtion(1, "right",nil,addData[2])
							end 
						end)
					}))
               	end),
			}))
	end

	beautyShowAction(1)
end

function BaseBattleLayer:showSkillMask(bool, skillSoldier)
	if bool then 
		if self.skillMaskCount == 0 then
			self.bg:setColor(ccc3(64, 64, 64))
		end
		self.skillMaskCount = self.skillMaskCount + 1

		local function highlightSoldier(anchKey, soldier)
			if skillSoldier:getAnchKey() ~= anchKey and soldier:getState() ~= "skillAttack" then
				soldier.sprite:setColor(ccc3(64, 64, 64))
			else
				soldier.sprite:setColor(ccc3(255, 255, 255))
			end
		end

		for anchKey, soldier in pairs(self.battleField.leftSoldierMap) do
			highlightSoldier(anchKey, soldier)
		end

		for anchKey, soldier in pairs(self.battleField.rightSoldierMap) do
			highlightSoldier(anchKey, soldier)
		end
	else
		self.skillMaskCount = self.skillMaskCount - 1
		if self.skillMaskCount > 0 then return end

		self.bg:setColor(ccc3(255, 255, 255))

		for anchKey, soldier in pairs(self.battleField.leftSoldierMap) do
			soldier.sprite:setColor(ccc3(255, 255, 255))
		end

		for anchKey, soldier in pairs(self.battleField.rightSoldierMap) do
			soldier.sprite:setColor(ccc3(255, 255, 255))
		end
	end
end

function BaseBattleLayer:onTouch(event, x, y)
	if event == "began" then
		return self:onTouchBegan(x, y)
	elseif event == "moved" then
		self:onTouchMove(x, y)
	elseif event == "ended" then
		self:onTouchEnd(x, y)
	elseif event == "cancelled" then
		self.isDragging = false
	end
end

function BaseBattleLayer:onTouchBegan(x, y)
	if self.isDragging then
		return false
	end

	local p = ccp(x, y)

	-- 战斗之前的排兵布阵
	if self.battleStatus == 0 then
		local containHeros = {}
		for col = 1, self.colCount do
			for row = 1, self.rowCount do
				local hero = self.leftFormationPositions[col][row].hero
				if hero and hero.displayNode:boundingBox():containsPoint(p) then
					table.insert(containHeros, { hero = hero, col = col, row = row })
				end
			end
		end

		table.sort(containHeros, function(a, b) return a.hero.displayNode:getZOrder() > b.hero.displayNode:getZOrder() end)

		-- do not touch on the soldier
		if #containHeros == 0 then return false end

		self.drag = {
			col = containHeros[1].col,
			row = containHeros[1].row,
			hero = containHeros[1].hero,
			beginPos = p,
		}
		self.isDragging = true

		containHeros[1].hero.displayNode:zorder(BattleConstants.zOrderConstants["dragSoldier"])

		self.dragMask = DGMask:new({ opacity = 0 })
		self.dragMask:getLayer():addTo(display.getRunningScene())

		return true
	end

	return false
end

function BaseBattleLayer:onTouchMove(x, y)
	if self.dragIcon then self.dragIcon:removeSelf() self.dragIcon = nil end

	local originXPos, originYPos = self.leftFormationPositions[self.drag.col][self.drag.row].x, self.leftFormationPositions[self.drag.col][self.drag.row].y
	self.drag.hero.displayNode:pos(originXPos + (x - self.drag.beginPos.x), originYPos + (y - self.drag.beginPos.y))

	-- 判断终点是否在战区格子
	local p = ccp(x, y)

	local location = { row = 0, col = 0}
	local minDistance = math.huge
	for col = 1, self.colCount do
		for row = 1, self.rowCount do
			local distance = ccpDistance(ccp(self.drag.hero.displayNode:getPositionX(), self.drag.hero.displayNode:getPositionY()), ccp(self.leftFormationPositions[col][row].x, self.leftFormationPositions[col][row].y))
			if distance <= self.collisionPixel and distance < minDistance then
				location.col, location.row = col, row
				minDistance = distance
				break
			end
		end
	end

	if minDistance <= self.collisionPixel then
		self.dragIcon = display.newSprite(BattleRes .. "drag_grid.png")
		self.dragIcon:addTo(self)
			:pos(BattleConstants.leftPositions[location.col][location.row].x - 10, 
				BattleConstants.leftPositions[location.col][location.row].y)
	end
end

function BaseBattleLayer:onTouchEnd(x, y)
	if self.dragMask then self.dragMask:remove() self.dragMask = nil end
	if self.dragIcon then self.dragIcon:removeSelf() self.dragIcon = nil end
	self.isDragging = false
	local p = ccp(x, y)

	-- 在原来格子晃动
	if ccpDistance(p, self.drag.beginPos) <= 10 then
		-- 战区格子
		local zorderValue = BattleConstants:calSoldierZorder(self.drag.col, self.drag.row)
		local position = self.leftFormationPositions[self.drag.col][self.drag.row]
		self.drag.hero.displayNode:pos(position.x, position.y):zorder(zorderValue)
		game:playMusic(21)
		return
	end

	-- 判断终点是否在战区格子
	local location = { row = 0, col = 0}
	local minDistance = math.huge
	for col = 1, self.colCount do
		for row = 1, self.rowCount do
			local distance = ccpDistance(ccp(self.drag.hero.displayNode:getPositionX(), self.drag.hero.displayNode:getPositionY()), ccp(self.leftFormationPositions[col][row].x, self.leftFormationPositions[col][row].y))
			if distance <= self.collisionPixel and distance < minDistance then
				location.col, location.row = col, row
				minDistance = distance
				break
			end
		end
	end

	if location.row == 0 and location.col == 0 then
		-- 移到无效区域, 回到原来位置
		local zorderValue = BattleConstants:calSoldierZorder(self.drag.col, self.drag.row)
		local position = self.leftFormationPositions[self.drag.col][self.drag.row]
		self.drag.hero.displayNode:pos(position.x, position.y):zorder(zorderValue)
		game:playMusic(21)
		return
	else
		-- 战区交换位置
		-- 位置更新, 同时更新映射表的数据
		game:playMusic(21)
		self.battleField.leftSoldierMap[self.drag.hero:getAnchKey()] = nil

		local position = self.leftFormationPositions[self.drag.col][self.drag.row]
		local curPosition = self.leftFormationPositions[location.col][location.row]
		local zorderValue = BattleConstants:calSoldierZorder(location.col, location.row)
		self.drag.hero.displayNode:pos(curPosition.x, curPosition.y):zorder(zorderValue)
		self.drag.hero.position = { x = curPosition.x, y = curPosition.y }
		self.drag.hero.anchPoint = { x = location.col, y = location.row }
		self.battleField.leftSoldierMap[self.drag.hero:getAnchKey()] = self.drag.hero

		if curPosition.hero then
			local zorderValue = BattleConstants:calSoldierZorder(self.drag.col, self.drag.row)
			curPosition.hero.displayNode:pos(position.x, position.y):zorder(zorderValue)
			curPosition.hero.position = { x = position.x, y = position.y }
			curPosition.hero.anchPoint = { x = self.drag.col, y = self.drag.row }
			self.battleField.leftSoldierMap[curPosition.hero:getAnchKey()] = curPosition.hero
		end

		position.hero, curPosition.hero = curPosition.hero, position.hero
	end
end

function BaseBattleLayer:onExit()
	self.battleField:dispose()

	display.removeSpriteFramesWithFile("resource/ui_rc/battle/left_grid.plist", "resource/ui_rc/battle/left_grid.png")

	self.attack2Effect:dispose()
end

return BaseBattleLayer