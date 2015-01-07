local ShopRes = "resource/ui_rc/shop/"
local HomeRes = "resource/ui_rc/home/"
local GlobalRes = "resource/ui_rc/global/"
local ParticleRes = "resource/ui_rc/particle/"

local positions = {
	[1] = { {display.cx, display.cy} },
	[5] = { 
		{-370 + display.cx, 0 + display.cy}, {display.cx + -185, display.cy}, {display.cx, display.cy},
		{display.cx + 185, display.cy}, { display.cx + 370, display.cy } 
	},
	[10] = {
		{-370 + display.cx, display.cy + 110}, {display.cx + -185, display.cy + 110}, 
		{display.cx, display.cy + 110}, {display.cx + 185, display.cy + 110}, 
		{display.cx + 370, display.cy + 100}, {-370 + display.cx, 0 + display.cy - 90}, 
		{display.cx + -185, display.cy - 90}, {display.cx, display.cy - 90},
		{display.cx + 185, display.cy - 90}, { display.cx + 370, display.cy - 90}
	}
}

local scales = { [1] = 350 / 640, [5] = 0.25, [10] = 0.25 }

local DGCardTurnOver = require("uicontrol.DGCardTurnOver")
local HeroCardLayer = import("..hero.HeroCardLayer")

local DrawCardResultLayer = class("DrawCardResultLayer", function()
	return display.newLayer()
end)

function DrawCardResultLayer:ctor(params)
	params = params or {}
	display.newSprite(HomeRes .. "home.jpg"):pos(display.cx, display.cy):addTo(self, -10)

	self.priority = params.priority or -130
	self.items = params.awardItems
	self.parent = params.parent
	self.packageId = params.index

	self.cardIndex = 1
	self:beginShow()

	self:anch(0.5, 0.5):pos(display.cx, display.cy)

	self.mask = require("uicontrol.DGMask"):new({ item = self, priority = self.priority + 1 })
end

function DrawCardResultLayer:beginShow()
	if self.mainLayer then
		self.mainLayer:removeSelf()
	end

	self.mainLayer = display.newLayer()
	self.mainLayer:size(display.width, display.height):addTo(self)

	local effectData = uihelper.loadAnimation(ShopRes .. "drawcard/", "chouka", 21, 14)
	effectData.sprite:scale(2):anch(0.5, 0.5):pos(display.cx, display.cy):addTo(self.mainLayer)
		:playAnimationOnce(effectData.animation, true, function()
			local shadow = display.newColorLayer(ccc4(0, 0, 0, 100))
			shadow:size(display.width, 400):anch(0.5, 0.5)
				:pos(display.cx, display.cy):addTo(self.mainLayer)

			if table.nums(self.items) == 1 then
				self:cardAppear()
			else
				self:multiCardAppear()
				uihelper.shake(cardStreak)
			end
		end)

	self:performWithDelay(function()
		game:playMusic(35)
	end, 0.9)

	--音效
	game:playMusic(313)		
end

--多张卡牌：
function DrawCardResultLayer:multiCardAppear()
	local cardNum = table.nums(self.items)
	local niubiHeros = {}

	CCTextureCache:sharedTextureCache():addImage(ShopRes.."stars_point.png")
	local hurtEffect = CCParticleSystemQuad:new()
	hurtEffect:autorelease()
	hurtEffect:initWithFile(ShopRes.."stars8.plist")
	self:addChild(hurtEffect, 100)
	hurtEffect:setPosition(ccp(display.cx, display.cy))
	hurtEffect:setScale(1)

	local cardUnitAction
	cardUnitAction = function(cardIndex)
		if cardIndex > cardNum then
			-- 出现按钮
			local againBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png"},
				{	
					priority = self.priority,
					text = { text = "再抽一次", font=ChineseFont, size = 28, color = display.COLOR_WHITE, strokeColor = display.COLOR_FONT },
					callback = function()
						local buyCardRequest = { roleId = game.role.id, packageId = self.packageId, drawCard = 1 }
						local bin = pb.encode("BuyCardPackageRequest", buyCardRequest)
						loadingShow()
			    		game:sendData(actionCodes.StoreDrawCardRequest, bin, #bin)
			    		game:addEventListener(actionModules[actionCodes.StoreDrawCardResponse], function(event)
			    			loadingHide()
			    			local msg = pb.decode("BuyCardPackageResponse", event.data)

			    			local awardItems = {}
			    			if self.packageId > 100 then
								while #msg.awardItems > 0 do
									local key = math.random(1, #msg.awardItems)
									table.insert(awardItems, msg.awardItems[key])
									table.remove(msg.awardItems, key)
								end
							else
			    				for _, pbItem in ipairs(msg.awardItems) do
			    					awardItems[#awardItems + 1] = {
			    						id = pbItem.id,
			    						itemId = pbItem.itemId,
			    						itemTypeId = pbItem.itemTypeId,
			    						num = pbItem.num,
			    						heroTrunFrag = pbItem.heroTrunFrag,
			    					}
				    			end
				    		end
			    			self.items = awardItems
			    			self:beginShow()

			    			return "__REMOVE__"
			    		end)
					end,
				}):getLayer()
			againBtn:anch(0.5, 0):pos(display.cx - 100, 50):addTo(self.mainLayer)

			local confirmBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png"},
				{	
					priority = self.priority,
					text = { text = "确 定", font=ChineseFont, size = 28, color = display.COLOR_WHITE, strokeColor = display.COLOR_FONT },
					callback = function()
						if self.parent then 
							self.parent:checkGuide() 
						end
						self:getLayer():removeSelf()
					end,
				}):getLayer()
			confirmBtn:anch(0.5, 0):pos(display.cx + 100, 50):addTo(self.mainLayer)

			if self.parent and self.parent.curClickIndex == 1 then
				againBtn:setVisible(false)
				confirmBtn:pos(display.cx,50)
			end

			return
		end

		local position = positions[cardNum][cardIndex]

		-- local whiteCard = display.newSprite(ShopRes .. "drawcard/white_card_small.png")
		-- whiteCard:anch(0.5, 0.5):pos(display.cx, display.cy):addTo(self.mainLayer)

		local itemInfo = self.items[cardIndex]
		local itemData = itemCsv:getItemById(itemCsv:calItemId(itemInfo))

		--判断是否已有英雄,有则转为相应碎片
		local heroExist = itemInfo.heroTrunFrag == 1
		if heroExist then
			local unitData = unitCsv:getUnitByType(itemData.heroType)
			itemInfo.itemTypeId = ItemTypeId.HeroFragment
			itemInfo.num = globalCsv:getFieldValue("decomposeFragNum")[unitData.stars]
			itemInfo.itemId = itemData.heroType + 2000

			itemData = itemCsv:getItemById(itemInfo.itemId)
			
		end

		local icon = ItemIcon.new({ itemId = itemCsv:calItemId(itemInfo) }):getLayer()

		local iconSize = icon:getContentSize()
		icon:anch(0.5, 0.5):pos(display.cx, display.cy):addTo(self.mainLayer)

		if self:hasBgLight(itemData) then
			display.newSprite(ShopRes .. "drawcard/head_light_bg.png"):scale(1):pos(icon:getContentSize().width / 2, icon:getContentSize().height / 2)
			:addTo(icon, -10):runAction(CCRepeatForever:create(CCRotateBy:create(0.5, 15)))
		end

		local iconAction = CCArray:create()
		iconAction:addObject(CCMoveTo:create(0.3, ccp(position[1], position[2])))	
		iconAction:addObject(CCRotateBy:create(0.3, 360 * 4))
		icon:runAction(transition.sequence({
			CCSpawn:create(iconAction),
			CCCallFunc:create(function()
				if itemData.type and itemData.type == ItemTypeId.Hero or heroExist then
					local unitData = unitCsv:getUnitByType(itemData.heroType)
					local star = unitData.stars
					ui.newTTFLabelWithStroke({text = heroExist and itemData.name or unitData.name, size = 18, color = display.COLOR_BLUE})
						:anch(0.5, 1):pos(iconSize.width / 2, -5):addTo(icon)

					if star < 0 then
						cardUnitAction(cardIndex + 1)
					else
						-- 特殊展示
						local heroSprite = HeroCardLayer.new({ heroType = unitData.type })
						local scale = 350 / heroSprite:getContentSize().width
						heroSprite:anch(0.5, 0.5):scale(scale * 0.2):pos(display.cx, display.cy) 

						local mask, actionOver
						local phase = heroExist and 1 or 2
						mask = DGMask:new({ item = heroSprite, priority = self.priority - 10, 
							click = function()
								if not actionOver then return end
								if phase == 1 then
									phase = 2
									heroSprite:scale(0.9 * scale)
									ui.newTTFLabel({text = string.format("已拥有此武将，%d星卡牌将自动转化为%d个武将碎片\n 武将碎片可用于该武将升星", unitData.stars, itemInfo.num),
										size = 40}):anch(0.5, 1):pos(heroSprite:getContentSize().width/2, -5):addTo(heroSprite)
								else 
									mask:remove()
									cardUnitAction(cardIndex + 1)
								end
								
							end})
						mask:getLayer():addTo(self.mainLayer)

						heroSprite:runAction(transition.sequence{
							CCScaleTo:create(0.3, scale),
							CCScaleTo:create(0.2, scale * 0.9),
							CCScaleTo:create(0.1, scale * 1),

							CCCallFunc:create(function()
								game:playMusic(unitData.skillMusicId)
								actionOver = true
							end)
						})

						display.newSprite(ShopRes .. "drawcard/card_light_bg.png"):scale(4):pos(heroSprite:getContentSize().width / 2, heroSprite:getContentSize().height / 2)
						:addTo(heroSprite, -2):runAction(CCRepeatForever:create(CCRotateBy:create(0.5, 15)))
						display.newSprite(ShopRes .. "drawcard/card_light_bg.png"):scale(4):pos(heroSprite:getContentSize().width / 2, heroSprite:getContentSize().height / 2)
						:addTo(heroSprite, -2):rotation(30):runAction(CCRepeatForever:create(CCRotateBy:create(0.5, -15)))

						CCNodeExtend.extend(CCParticleSystemQuad:create(ParticleRes .. "card_particles.plist")):pos(heroSprite:getContentSize().width / 2, heroSprite:getContentSize().height / 2)
						:addTo(heroSprite, -1)

						if itemInfo.num > 1 and heroExist then
							ui.newTTFLabelWithStroke({text = "X " .. itemInfo.num, size = 18, color = display.COLOR_GREEN })
								:anch(1, 0):pos(icon:getContentSize().width - 15, 8):addTo(icon)
						end
					end
				else
					-- 装备
					

					if itemInfo.num > 1 then
						ui.newTTFLabelWithStroke({text = "X " .. itemInfo.num, size = 18, color = display.COLOR_GREEN })
							:anch(1, 0):pos(icon:getContentSize().width - 15, 8):addTo(icon)
					end

					ui.newTTFLabelWithStroke({text = itemData.name, size = 18, color = display.COLOR_BLUE})
						:anch(0.5, 1):pos(icon:getContentSize().width / 2, -5):addTo(icon)
					cardUnitAction(cardIndex + 1)
				end
			end)
		}))
	end

	cardUnitAction(1)
end

function DrawCardResultLayer:hasBgLight(itemData)
	if not itemData then return false end

	if itemData.stars >= 3 or itemData.type == ItemTypeId.Hero or itemData.type == ItemTypeId.HeroFragment or itemData.type == ItemTypeId.Equip or itemData.type == ItemTypeId.EquipFragment then
		return true
	end
	return false
end

function DrawCardResultLayer:cardAppear()
	local itemInfo = self.items[1]
	-- 装备
	local itemData = itemCsv:getItemById(itemCsv:calItemId(itemInfo))

	--判断是否已有英雄,有则转为相应碎片
	local heroExist = itemInfo.heroTrunFrag == 1
	if heroExist then
		local unitData = unitCsv:getUnitByType(itemData.heroType)
		itemInfo.itemTypeId = ItemTypeId.HeroFragment
		itemInfo.num = globalCsv:getFieldValue("decomposeFragNum")[unitData.stars]
		itemInfo.itemId = itemData.heroType + 2000

		itemData = itemCsv:getItemById(itemInfo.itemId)
		
	end

	local icon = ItemIcon.new({ itemId = itemCsv:calItemId(itemInfo) }):getLayer()
	icon:anch(0.5, 0.5):scale(0.1):pos(display.cx, display.cy + 10):addTo(self.mainLayer)

	ui.newTTFLabelWithStroke({text = itemData.name, size = 18, color = display.COLOR_BLUE})
		:anch(0.5, 1):pos(icon:getContentSize().width / 2, -5):addTo(icon)

	if self:hasBgLight(itemData) then
		display.newSprite(ShopRes .. "drawcard/head_light_bg.png"):scale(1):pos(icon:getContentSize().width / 2, icon:getContentSize().height / 2)
		:addTo(icon, -10):runAction(CCRepeatForever:create(CCRotateBy:create(0.5, 15)))
	end
	-- display.newSprite(ShopRes .. "drawcard/head_light_bg.png"):scale(1):pos(icon:getContentSize().width / 2, icon:getContentSize().height / 2)
	-- :addTo(icon, -10):rotation(30):runAction(CCRepeatForever:create(CCRotateBy:create(0.5, -15)))
	

	local actions = {}
	actions[#actions + 1] = CCEaseBounceOut:create(CCScaleTo:create(0.5, 1))
	actions[#actions + 1] = CCCallFunc:create(function()
		-- 出现按钮
		local againBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png", "middle_disabled.png"},
			{	
				priority = self.priority,
				text = { text = "再抽一次", font=ChineseFont, size = 28, color = display.COLOR_WHITE, strokeColor = display.COLOR_FONT },
				callback = function()
					local buyCardRequest = { roleId = game.role.id, packageId = self.packageId, drawCard = 1 }
					loadingShow()
					local bin = pb.encode("BuyCardPackageRequest", buyCardRequest)
		    		game:sendData(actionCodes.StoreDrawCardRequest, bin, #bin)
		    		game:addEventListener(actionModules[actionCodes.StoreDrawCardResponse], function(event)
		    			loadingHide()
		    			local msg = pb.decode("BuyCardPackageResponse", event.data)
		    			if game.role.shopThreshold[self.packageId] then 
							game.role.shopThreshold[self.packageId] = msg.threshold
						end

		    			local awardItems = {}
		    			for _, pbItem in ipairs(msg.awardItems) do
	    					awardItems[#awardItems + 1] = {
	    						id = pbItem.id,
	    						itemId = pbItem.itemId,
	    						itemTypeId = pbItem.itemTypeId,
	    						num = pbItem.num,
	    						heroTrunFrag = pbItem.heroTrunFrag,
	    					}
		    			end
		    			self.items = awardItems
		    			self:beginShow()

		    			return "__REMOVE__"
		    		end)
				end,
			})
		againBtn:getLayer():anch(0.5, 0):pos(display.cx - 100, 50):addTo(self.mainLayer)
		againBtn:setEnable(game.role.oldGuideStep ~= 3 and game.role.oldGuideStep ~= 4)

		self.confirmBtn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png", "middle_disabled.png"},
			{	
				priority = self.priority,
				text = { text = "确 定", font=ChineseFont, size = 28, color = display.COLOR_WHITE, strokeColor = display.COLOR_FONT },
				callback = function()
					if self.parent then 
						self.parent:checkGuide() 
						self.parent:refreshThreshold() 
					end
					self:getLayer():removeSelf()
				end,
			}):getLayer()
		self.confirmBtn:anch(0.5, 0):pos(display.cx + 100, 50):addTo(self.mainLayer)
		
	end)

	-- 武将出现
	if itemData.type == ItemTypeId.Hero or heroExist then
		actions[#actions + 1] = CCCallFunc:create(function()
			local heroSprite = HeroCardLayer.new({ heroType = itemData.heroType })
			heroSprite:anch(0.5, 0.5):scale(0.1):pos(display.cx, display.cy)

			local unitData = unitCsv:getUnitByType(itemData.heroType)
			game:playMusic(unitData.skillMusicId)

			local mask, actionOver
			local phase, finalScale = heroExist and 1 or 2, 350 / heroSprite:getContentSize().width
			mask = DGMask:new({ item = heroSprite, priority = self.priority - 10, 
				click = function()
					if not actionOver then return end
					if phase == 1 then
						phase = 2
						heroSprite:scale(0.8 * finalScale)
						ui.newTTFLabelWithStroke({text = string.format("已拥有此武将，%d星卡牌将自动转化为%d个武将碎片\n 武将碎片可用于该武将升星", unitData.stars, globalCsv:getFieldValue("decomposeFragNum")[unitData.stars]),
							size = 45, font = ChineseFont, strokeColor = display.COLOR_FONT}):anch(0.5, 1):pos(heroSprite:getContentSize().width/2, -10):addTo(heroSprite)
					else 
						mask:remove()
					end
				end})
			heroSprite:runAction(transition.sequence{
				CCEaseBounceOut:create(CCScaleTo:create(1, finalScale)),
				CCCallFunc:create(function() 
					actionOver = true
					self:checkGuide()
				end)
			})
			mask:getLayer():addTo(self.mainLayer)
			self.cardMask = mask

			display.newSprite(ShopRes .. "drawcard/card_light_bg.png"):scale(4):pos(heroSprite:getContentSize().width / 2, heroSprite:getContentSize().height / 2)
			:addTo(heroSprite, -2):runAction(CCRepeatForever:create(CCRotateBy:create(0.5, 15)))
			display.newSprite(ShopRes .. "drawcard/card_light_bg.png"):scale(4):pos(heroSprite:getContentSize().width / 2, heroSprite:getContentSize().height / 2)
			:addTo(heroSprite, -2):rotation(30):runAction(CCRepeatForever:create(CCRotateBy:create(0.5, -15)))

			CCNodeExtend.extend(CCParticleSystemQuad:create(ParticleRes .. "card_particles.plist")):pos(heroSprite:getContentSize().width / 2, heroSprite:getContentSize().height / 2)
			:addTo(heroSprite, -1)
		end)

		if itemInfo.num > 1 and heroExist then
			ui.newTTFLabelWithStroke({text = "X " .. itemInfo.num, size = 18, color = display.COLOR_GREEN })
				:anch(1, 0):pos(icon:getContentSize().width - 15, 8):addTo(icon)
		end
	else
		if itemInfo.num > 1 then
			ui.newTTFLabelWithStroke({text = "X " .. itemInfo.num, size = 18, color = display.COLOR_GREEN })
				:anch(1, 0):pos(icon:getContentSize().width - 15, 8):addTo(icon)
		end
	end
	icon:runAction(transition.sequence(actions))
end

function DrawCardResultLayer:checkGuide(remove)
	--新手引导
	game:addGuideNode({rect = CCRectMake(0, 0, display.width, display.height), opacity = 0, remove = remove,
		guideIds = {900, 902},
		onClick = function() self.cardMask:remove() end,
	})
	--新手引导
	game:addGuideNode({node = self.confirmBtn, remove = remove,
		guideIds = {901, 903}
	})
end

function DrawCardResultLayer:onExit()
	self:checkGuide(true)
end 

function DrawCardResultLayer:getLayer()
	return self.mask:getLayer()
end

return DrawCardResultLayer