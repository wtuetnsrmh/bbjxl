local TowerRes = "resource/ui_rc/activity/tower/"
local GlobalRes = "resource/ui_rc/global/"
local AwardRes = "resource/ui_rc/carbon/award/"
local MoneyBattleRes = "resource/ui_rc/activity/money/"

local TowerAttrModifyLayer = import(".TowerAttrModifyLayer")

local TowerAwardLayer = class("TowerAwardLayer", function()
	return display.newLayer()
end)

function TowerAwardLayer:ctor(params)
	self.params = params or {}

	self.priority = params.priority or -130
	self.size = CCSizeMake(960, 640)
	self:setContentSize(self.size)
	self:anch(0.5, 0.5):pos(display.cx, display.cy + 25)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1 ,opacity = 200})
	self.tipsTag = 7879

	self.mainLayer = display.newLayer()
	self.mainLayer:addTo(self)
	self.mainLayer:setContentSize(self.size)
	

	local bg = display.newSprite(AwardRes .. "box_small_bg.png")
	local bgSize = bg:getContentSize()

	bg:anch(0.5, 0.5):pos(self.size.width/2,self.size.height/2):addTo(self.mainLayer)

	local titlebg = display.newSprite(GlobalRes .. "title_bar.png")
		:pos(bgSize.width/2, bgSize.height - 35):addTo(bg)

	display.newSprite(TowerRes .. "award_text.png")
		:pos(titlebg:getContentSize().width/2, titlebg:getContentSize().height/2):addTo(titlebg)

	local towerData = game.role.towerData
	local confirmBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png"},
		{	
			text = { text = "确定", size = 26, strokeColor = uihelper.hex2rgb("#242424") },
			priority = self.priority,
			callback = function()	
				self:showAwardBox()		
				
			end,
		}):getLayer()
	confirmBtn:anch(0.5, 0):pos(bgSize.width / 2, 20):addTo(bg)

	
	local towerBattleData = towerBattleCsv:getCarbonData(params.carbonId)
	local addYuanbaoValue = (towerBattleData.yuanbaoAward and towerBattleData.yuanbaoAwardStarNeed <= (towerData.totalStarNum - towerData.preTotalStarNum)) and towerBattleData.yuanbaoNum or 0

	ui.newTTFLabelWithStroke({ text = "每5关奖励一次, 得星越多奖励越多!", size = 28, font = ChineseFont, strokeColor = uihelper.hex2rgb("#242424") })
		:anch(0.5, 0):pos(bgSize.width / 2, bgSize.height - 45-72):addTo(bg)

	local bottomBg = display.newSprite(GlobalRes .. "label_middle_bg.png")
	local barSize = bottomBg:getContentSize()

	bottomBg:anch(0.5, 0):pos(bgSize.width / 2, bgSize.height - 102-72):addTo(bg)
	ui.newTTFLabel({ text = "银币: ", size = 20 }):anch(0, 0.5):pos(30, barSize.height / 2):addTo(bottomBg)
	ui.newTTFLabel({ text = (towerData.totalStarNum - towerData.preTotalStarNum) * towerBattleData.moneyStarUnit, 
		size = 20, color = uihelper.hex2rgb("#7ce810") })
		:anch(0, 0.5):pos(150, barSize.height / 2):addTo(bottomBg)
	display.newSprite(GlobalRes .. "yinbi.png"):anch(1, 0.5):pos(barSize.width - 10, barSize.height / 2):addTo(bottomBg)

	local bottomBg = display.newSprite(GlobalRes .. "label_middle_bg.png")
	bottomBg:anch(0.5, 0):pos(bgSize.width / 2, bgSize.height - 145-72):addTo(bg)
	ui.newTTFLabel({ text = "元宝: ", size = 20 }):anch(0, 0.5):pos(30, barSize.height / 2):addTo(bottomBg)
	ui.newTTFLabel({ text = addYuanbaoValue, size = 20, color = uihelper.hex2rgb("#7ce810") })
		:anch(0, 0.5):pos(150, barSize.height / 2):addTo(bottomBg)
	display.newSprite(GlobalRes .. "yuanbao.png"):anch(1, 0.5):pos(barSize.width - 10, barSize.height / 2):addTo(bottomBg)


	local towerPbFields = { "count", "carbonId", "totalStarNum", "preTotalStarNum", 
					"maxTotalStarNum", "curStarNum", "hpModify", "atkModify", "defModify", "sceneId1",
					"sceneId2", "sceneId3","opendBoxNum" }
	game.role.towerData = game.role.towerData or {}
	for _, field in pairs(towerPbFields) do
		game.role.towerData[field] = params.msg.towerData[field]
	end
end

function TowerAwardLayer:frameActionOnSprite()

	display.addSpriteFramesWithFile(TowerRes.."BoxOpen.plist", TowerRes.."BoxOpen.png")
	local framesTable = {}
	for index = 1, 5 do
		local frameId = string.format("%02d", index)
		framesTable[#framesTable + 1] = display.newSpriteFrame("BoxOpen_" .. frameId .. ".png")
	end
	local panimate = display.newAnimation(framesTable, 1.0/10)
	local sprite = display.newSprite(framesTable[1])
	-- sprite:playAnimationForever(panimate)
	return sprite,panimate
end

function TowerAwardLayer:showAwardBox()
	if self.mainLayer then
		self.mainLayer:removeSelf()
		self.mainLayer=nil
	end
	self.mainLayer = display.newLayer()
	self.mainLayer:addTo(self)
	self.mainLayer:setContentSize(self.size)

	local bg = display.newSprite(TowerRes.."bg_prize.png")
		:pos(self.size.width/2,display.cy+40):addTo(self.mainLayer)
	local bgSize = bg:getContentSize()

	local randomItems = {}
	local keys = table.keys(self.params.msg.awardItems)

	local tempRandom = {}
	local tempRandom2 = {}
	for i,v in ipairs(keys) do
		if math.random() > 0.5 then
			table.insert(tempRandom,v)
		else
			table.insert(tempRandom2,v)
		end
	end
	for i,v in ipairs(tempRandom2) do
		table.insert(tempRandom,v)
	end

	for i,v in ipairs(tempRandom) do
		table.insert(randomItems,self.params.msg.awardItems[v])
	end

	local box,ani = self:frameActionOnSprite()
	local boxArr = {}
	self.openedBoxIndex = {}
	for index,itemData in ipairs(randomItems) do
		self.openedBoxIndex[index] = true

		local awardBox = DGBtn:new(nil, { "#BoxOpen_01.png", "#BoxOpen_01.png" },
		{	
			priority = self.priority -1,
			callback = function()
				local awardItems = {}
				table.insert(awardItems,{itemId = itemData.itemId,num = itemData.num})
				local openData = { towerData = game.role.towerData, awardItems = awardItems }	
				local bin = pb.encode("TowerAwardData", openData)
				game:sendData(actionCodes.TowerOpenAwardRequest, bin)
				loadingShow()
				game:addEventListener(actionModules[actionCodes.TowerOpenAwardResponse], function(event)
					loadingHide()
					local msg = pb.decode("SimpleEvent", event.data)
					if msg.param1 == 0 then
						self.openedBoxIndex[index] = false

						game.role.towerData.opendBoxNum = tonum(msg.param2)

						boxArr[index]:getLayer():setVisible(false)
						boxArr[index]:getLayer():stopAllActions()
						local box,ani = self:frameActionOnSprite()
						box:pos(134+(index-1)*150+(index-1)*50+118/2,bgSize.height/2+110/2-93):addTo(bg)
						transition.playAnimationOnce(box, ani, true, function()
							local itemIco = self:createItem(itemData.itemId,itemData.num)
							itemIco:pos(134+(index-1)*150+(index-1)*50+50,bgSize.height/2+50-93):addTo(bg)
							boxArr[index]:getLayer():removeSelf()
							end)

						self:refreshPrice()

					elseif msg.param1 == SYS_ERR_YUANBAO_NOT_ENOUGH then
						DGMsgBox.new({text = "元宝不足!", type = 1})
						
					elseif msg.param1 == SYS_ERR_TOWER_ERR then
						print("非法操作！")

					end
					return "__REMOVE__"
				end)
				
			end,
		})
		awardBox:getLayer():pos(134+(index-1)*150+(index-1)*50,bgSize.height/2-93):addTo(bg)

		local scaleAction = CCScaleBy:create(1, 1.1, 1.05)
		local tintByAction = CCTintTo:create(1, 255, 255, 128)

		local spawnAction = CCArray:create()
		spawnAction:addObject(scaleAction)
		spawnAction:addObject(tintByAction)
		local spawnActionRe = CCArray:create()
		spawnActionRe:addObject(scaleAction:reverse())
		spawnActionRe:addObject(CCTintTo:create(1, 255, 255, 255))

		awardBox.item[1]:runAction(
			CCRepeatForever:create(transition.sequence{
				CCSpawn:create(spawnAction),
				CCSpawn:create(spawnActionRe),
				})
			)

		boxArr[index] = awardBox
	end

	self.openTotalBox = function()
		if self.priceLayer then
			self.priceLayer:removeSelf()
			self.priceLayer = nil
		end

		for i=1,4 do
			local itemData = randomItems[i]
			if self.openedBoxIndex[i] then
				boxArr[i]:getLayer():setVisible(false)
				boxArr[i]:getLayer():stopAllActions()
				local box,ani = self:frameActionOnSprite()
				box:pos(134+(i-1)*150+(i-1)*50+118/2,bgSize.height/2+110/2-93):addTo(bg)
				transition.playAnimationOnce(box, ani, true, function()
					local itemIco = self:createItem(itemData.itemId,itemData.num)
					itemIco:pos(134+(i-1)*150+(i-1)*50+50,bgSize.height/2+50-93):addTo(bg)
					boxArr[i]:getLayer():removeSelf()
					end)
			end
		end
		
	end
	
	self:refreshPrice()
end

function TowerAwardLayer:refreshPrice()

	if self.priceLayer then
		self.priceLayer:removeSelf()
		self.priceLayer = nil
	end

	self.priceLayer = display.newLayer()
	self.priceLayer:setContentSize(self.size)
	self.priceLayer:addTo(self.mainLayer)

	local openNum = game.role.towerData.opendBoxNum

	local delayFlag = false
	for index = 1, 4 do
		
		if openNum > 0 then
			-- 元宝打开
			if self.openedBoxIndex[index] then
				local bg = display.newSprite(TowerRes.."bg_itemCost.png")
				:pos(134+(index-1)*150+(index-1)*50+50,280-36):addTo(self.priceLayer)
				display.newSprite(GlobalRes.."yuanbao.png"):anch(0,0):pos(5,0):addTo(bg)

				local priceDic = string.tomap(globalCsv:getFieldValue("towerOpenBoxPrice"))
				ui.newTTFLabel({text= priceDic[tostring(openNum+1)],size = 18})
				:pos(62,18):addTo(bg)

				delayFlag = true
			end
			
		else
			-- 免费打开
			ui.newTTFLabel({text="免费" ,size = 18,color = uihelper.hex2rgb("#30ceea")})
			:pos(134+(index-1)*150+(index-1)*50+60,243):addTo(self.priceLayer)
		end
	end

	if game.role.towerData.opendBoxNum > 0 then
		local confirmBtn = DGBtn:new(GlobalRes, {"btn_ellipse_normal.png", "btn_ellipse_selected.png"},
			{	
				text = { text = "离 开", size = 24, strokeColor = uihelper.hex2rgb("#242424"),font = ChineseFont },
				priority = self.priority,
				callback = function()	
					if self.openTotalBox and delayFlag then
						self.openTotalBox()
						self:performWithDelay(function()
							--有属性加成
							local carbonData = towerBattleCsv:getCarbonData(self.params.carbonId)
							if carbonData.attrBonus then
								self:getLayer():removeSelf()
								local attrModifyLayer = TowerAttrModifyLayer.new({ priority = self.params.priority - 10})
								display.getRunningScene():addChild(attrModifyLayer:getLayer())
							else
								switchScene("tower")
							end	
						end, 2)
					else
						--有属性加成
						local carbonData = towerBattleCsv:getCarbonData(self.params.carbonId)
						if carbonData.attrBonus then
							self:getLayer():removeSelf()
							local attrModifyLayer = TowerAttrModifyLayer.new({ priority = self.params.priority - 10})
							display.getRunningScene():addChild(attrModifyLayer:getLayer())
						else
							switchScene("tower")
						end	
					end
					
					
				end,
			}):getLayer()
		confirmBtn:anch(0.5, 0):pos(self.size.width / 2, 86):addTo(self.priceLayer)
	end
end

function TowerAwardLayer:createItem(itemId,itemCount)
	
	local iData = nil

	iData = itemCsv:getItemById(tonumber(itemId))
	local frame = ItemIcon.new({ itemId = tonumber(itemId),
		parent = self.tableLayer, 
		priority = self.priority -1,
		callback = function()
			-- self:showItemTaps(itemId,itemCount,iData.type)
		end,
	}):getLayer()
	frame:setColor(ccc3(100, 100, 100))
	frame:setScale(0.7)
	
	--数量
	local numLabe=ui.newTTFLabelWithShadow({ text = "x"..itemCount, size = 20, color = uihelper.hex2rgb("#ffd200")
		,strokeColor=uihelper.hex2rgb("#242424") ,strokeSize=2})
		:addTo(frame)
	numLabe:anch(0, 0):pos(78-numLabe:getContentSize().width+15,15)

	-- 名字
	local nameLabel = ui.newTTFLabelWithStroke({text=iData.name ,size = 26,color = uihelper.hex2rgb("#30ceea"),strokeColor=uihelper.hex2rgb("#242424"),strokeSize=1})
		:addTo(frame)
	nameLabel:pos(frame:getContentSize().width/2,-35)

	-- 光圈
	display.newSprite(MoneyBattleRes .. "money_light.png"):addTo(frame, -30):scale(2)
		:pos(frame:getContentSize().width / 2, frame:getContentSize().height / 2)
		:runAction(CCRepeatForever:create(CCRotateBy:create(0.2, 20)))


	return frame
end

function TowerAwardLayer:showItemTaps(itemId,itemNum,itemType)
	self:purgeItemTaps()
	local itemTipsView = require("scenes.home.ItemTipsLayer")
	local itemTips = itemTipsView.new({ itemId = itemId, itemNum = itemNum, itemType = itemType })
	display.getRunningScene():addChild(itemTips:getLayer())
	itemTips:setTag(self.tipsTag)
end

function TowerAwardLayer:purgeItemTaps()
	if display.getRunningScene():getChildByTag(self.tipsTag) then
		display.getRunningScene():getChildByTag(self.tipsTag):removeFromParent()
	end
end

function TowerAwardLayer:getLayer()
	return self.mask:getLayer()
end

return TowerAwardLayer