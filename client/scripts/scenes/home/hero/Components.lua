local GlobalRes = "resource/ui_rc/global/"
local HeroRes   = "resource/ui_rc/hero/"
local EquipRes  = "resource/ui_rc/equip/"
local HomeRes = "resource/ui_rc/home/"
local PvpRes = "resource/ui_rc/pvp/"
local ExpeditonRes = "resource/ui_rc/expedition/"
local BattleRes="resource/ui_rc/battle/"

local professionName = { [1] = "bu", [3] = "qi", [4] = "gong", [5] = "jun" }
local campName = { [1] = "qun", [2] = "wei", [3] = "shu", [4] = "wu" }

HeroHead = class("HeroHead", function(params)
	local curType = params.type
	params.type = params.type < 2000 and params.type or params.type - 2000
	params.type = params.type < 1000 and params.type or params.type - 1000

	local unitData = unitCsv:getUnitByType(params.type)
	local frameRes = string.format("frame_%d.png",  params.evolutionCount or 0)
	if tonumber(curType) >= 2000 then
		frameRes = string.format("fragment_hero_%d.png", HERO_MAX_STAR - 1)
	end
	local frame = DGBtn:new(GlobalRes, {frameRes}, params, params.group)
	local frameSize = frame:getLayer():getContentSize()
	-- display.newSprite(GlobalRes .. "frame_bottom.png")
	-- 	:pos(frameSize.width / 2, frameSize.height / 2):addTo(frame:getLayer(), -3)
	-- frame.heroImage = display.newSprite(unitData.headImage)

	if tonumber(curType) >= 2000 then
		frame.heroImage= getShaderNode({steRes = PvpRes.."fragment_mask.png",clipRes = unitData.headImage})
		frame.heroImage:setPosition(frameSize.width / 2, frameSize.height / 2)
		frame:getLayer():addChild(frame.heroImage,-2)

		if not params.hideFragment then
			display.newSprite(HeroRes.."fragment_tag.png"):anch(0, 1):pos(0, frameSize.height):addTo(frame:getLayer())
		end
	else
		frame.heroImage = display.newSprite(unitData.headImage)
		frame.heroImage:pos(frameSize.width / 2, frameSize.height / 2):addTo(frame:getLayer(), -2)
	end
	
	if params.color then
		frame.heroImage:setColor(params.color)
	end

	if tonumber(curType) < 2000 and not params.hideStar then
		local star = params.star or unitData.stars
		local starWidth = 20
		local xBegin = frameSize.width / 2 - (star - 1) * starWidth / 2
		for index = 1, star do
			display.newSprite(GlobalRes .. "star/icon_small.png")
				:anch(0.5, 0):pos(xBegin + starWidth * (index - 1), 10):addTo(frame:getLayer())
		end
	end


	--觉醒
	if params.wakeLevel and params.wakeLevel > 0 then
		local wakeRes = string.format("growth/wake_%d.png", params.wakeLevel)
		display.newSprite(HeroRes .. wakeRes)
			:anch(0.7, 0.7):pos(frameSize.width, frameSize.height):addTo(frame:getLayer(), 10)
	end
	--等级
	if params.heroLevel then
		local bg = display.newSprite(HeroRes .. "hero_level_bg.png")
		bg:anch(1, 0):scale(1.0):pos(frameSize.width - 16, 30):addTo(frame:getLayer())
		ui.newTTFLabel({text = params.heroLevel, size = 20, color = uihelper.hex2rgb("#eeeeee")})
			:anch(0.5, 0.5):pos(bg:getContentSize().width/2, bg:getContentSize().height/2):addTo(bg)
	end

	--血量
	if params.blood then
		if params.blood<=0 then
			display.newSprite(ExpeditonRes.."mask_dead.png"):pos(frameSize.width/2,frameSize.height/2)
			:addTo(frame:getLayer())
			frame:setEnable(false)
		else
			local hpProgress = display.newProgressTimer(BattleRes .. "self_hp.png", display.PROGRESS_TIMER_BAR)
			hpProgress:setMidpoint(ccp(0, 0))
			hpProgress:setBarChangeRate(ccp(1,0))
			hpProgress:setPercentage(params.blood)
			local hpSlot = display.newSprite(BattleRes .. "hp_bg.png")
			hpProgress:pos(hpSlot:getContentSize().width / 2, hpSlot:getContentSize().height / 2):addTo(hpSlot)
			hpSlot:pos(frameSize.width/2,8):addTo(frame:getLayer())
		end
	end

	--上阵
	if params.isOn then
		if params.isOn==1 and (not params.blood or params.blood > 0) then
			display.newSprite(ExpeditonRes.."choose.png"):pos(frameSize.width/2,frameSize.height/2):addTo(frame:getLayer())
		end
	end

	--灰化
	if params.gray then
		frame:setGray(true)		
	end
	
	return frame
end)

HeroListCell = class("HeroListCell", function(params)
	local curType = params.type
	params.type = params.type < 2000 and params.type or params.type - 2000
	params.type = params.type < 1000 and params.type or params.type - 1000
	local unitData = unitCsv:getUnitByType(params.type)

	local cell = DGBtn:new(HeroRes, {"cell_bar.png"}, params)
	local layer = cell:getLayer()
	local cellSize = layer:getContentSize()

	local frame = HeroHead.new({ type = curType, wakeLevel = params.wakeLevel, 
		hideFragment = true, star = params.star, evolutionCount = params.evolutionCount,
		gray = params.gray, callback = params.headCallback, priority = params.headCallback and params.priority - 1 })
	if curType >= 2000 then
		frame:getLayer():anch(0, 0):pos(25, 13):addTo(layer)
	else
		frame:getLayer():anch(0, 0):pos(18, 4):addTo(layer)
	end

	-- level
	if params.level then
		ui.newTTFLabel({ text = "Lv." .. params.level, size = 18, color = uihelper.hex2rgb("#533b22") })
			:anch(0, 0.5):pos(150, cellSize.height / 2):addTo(layer)
	end

	-- profession
	local professionBg = display.newSprite(HeroRes .. "profession_bg.png")
	professionBg:anch(0, 1):pos(6, cellSize.height - 6):addTo(layer)
	display.newSprite(HeroRes .. string.format("profession_%s.png", professionName[unitData.profession]))
		:pos(professionBg:getContentSize().width / 2, professionBg:getContentSize().height / 2):addTo(professionBg)

	-- camp and name
	local nameBar = display.newSprite(HeroRes .. "name_bar.png")
	nameBar:anch(0, 1):pos(162, cellSize.height - 22):addTo(layer)

	local nameSize = nameBar:getContentSize()
	local campBg = display.newSprite(HeroRes .. string.format("camp_small_%s.png", campName[unitData.camp]))
	campBg:anch(0.5, 0.5):pos(0, nameSize.height / 2):addTo(nameBar)

	local heroName = unitData.name
	local evolutionCount = uihelper.getShowEvolutionCount(params.evolutionCount)
	if evolutionCount > 0 then
		heroName = heroName .. "+" .. evolutionCount
	end
	ui.newTTFLabel({ text = heroName, size = 24, font = ChineseFont, color = uihelper.getEvolColor(params.evolutionCount) })
		:anch(0, 0.5):pos(30, nameSize.height / 2):addTo(nameBar)

	return cell
end)

ItemIcon = class("ItemIcon", function(params)
	params = params or {}

	local itemData = itemCsv:getItemById(params.itemId or 0)
	local frameRes = itemData and string.format("item_%d.png", itemData.stars) or "item_1.png"

	if (itemData and itemData.type == ItemTypeId.EquipFragment) or battleSoulCsv:isFragment(params.itemId) then
		frameRes = string.format("fragment_hero_%d.png", itemData.stars)
	end

	local btn = DGBtn:new(GlobalRes, {frameRes}, params, params.group)

	if not itemData then 
		display.newSprite(GlobalRes .. "frame_bottom.png"):addTo(btn:getLayer(), -1)
			:pos(btn:getLayer():getContentSize().width / 2, btn:getLayer():getContentSize().height / 2)
		return btn 
	end

	local frameSize = btn:getLayer():getContentSize()
	if itemData.type == ItemTypeId.Hero then
		params.type = itemData.heroType
		params.evolutionCount = evolutionModifyCsv:getEvolMaxCount()
		return HeroHead.new(params)
	elseif itemData.type == ItemTypeId.HeroFragment then
		params.type = itemData.itemId
		return HeroHead.new(params)
	elseif itemData.type == ItemTypeId.EquipFragment or battleSoulCsv:isFragment(params.itemId) then

		display.newSprite(HeroRes.."fragment_tag.png"):anch(0, 1):pos(0, frameSize.height):addTo(btn:getLayer())
	end

	
	local frame
	if itemData.type == ItemTypeId.HeroEvolution then
		frame = display.newSprite(HeroRes .. string.format("evolution/item_bg_%d.png", itemData.stars))
	else
		frame = display.newSprite(EquipRes .. string.format("equip_bottom_%d.png", itemData.stars))
	end
	
	--等级
	if params.level then
		local bg = display.newSprite(HeroRes .. "hero_level_bg.png")
		bg:anch(1, 0):scale(1.1):pos(frameSize.width - 8, 10):addTo(btn:getLayer())
		ui.newTTFLabel({text = params.level, size = 20, color = uihelper.hex2rgb("#eeeeee")})
			:anch(0.5, 0.5):pos(bg:getContentSize().width/2, bg:getContentSize().height/2):addTo(bg)
	end

	if itemData then
		local icon 
		if itemData.type == ItemTypeId.EquipFragment or battleSoulCsv:isFragment(params.itemId) then
			icon= getShaderNode({steRes = PvpRes.."fragment_mask.png",clipRes = itemData.icon})
			icon:setPosition(frameSize.width / 2, frameSize.height / 2)
			btn:getLayer():addChild(icon,-2)

			local headClipper = CCClippingNode:create()
			headClipper:setStencil(display.newSprite(PvpRes.."fragment_mask.png"))
			headClipper:setInverted(false)
			headClipper:setAlphaThreshold(0)
			headClipper:setPosition(frameSize.width / 2, frameSize.height / 2)
			headClipper:addChild(frame)
			btn:getLayer():addChild(headClipper,-3)
		else
			frame:pos(frameSize.width / 2, frameSize.height / 2):addTo(btn:getLayer(), -2)

			icon = display.newSprite(itemData.icon)
			icon:pos(frameSize.width / 2, frameSize.height / 2):addTo(btn:getLayer(), -1)
		end
		
		

		if params.color then
			icon:setColor(params.color)
		end

		if params.gray then
			local grayShadeProgram = UIUtil:shaderForKey("ShaderPositionTextureGray")
			icon:setShaderProgram(grayShadeProgram)
			frame:setShaderProgram(grayShadeProgram)
			display.newSprite(GlobalRes .. frameRes):pos(frameSize.width / 2, frameSize.height / 2)
				:addTo(btn:getLayer()):setShaderProgram(grayShadeProgram)
		end
	end
	btn:getLayer():anch(0.5, 0.5)
	
	return btn
end)

EquipList = class("EquipList", function(params)
	params = params or {}
	local equip = params.equip
	local priority = params.priority or -129
	local showMoney = params.showMoney

	local bg = DGBtn:new(EquipRes, {"bg_weapon_item.png", }, params)
	local bgSize = bg:getLayer():getContentSize()
	local itemId = equip and equip.type + Equip2ItemIndex.ItemTypeIndex or nil
	local icon = ItemIcon.new({itemId = itemId}):getLayer()
	icon:scale(0.8):anch(0, 0):pos(18, 12):addTo(bg:getLayer())
	if equip then
		local xPos, yPos = 18, 102
		--名称等级
		local text = ui.newTTFLabelWithStroke({text = equip:getName(), size = 22, font = ChineseFont, strokeColor = uihelper.hex2rgb("#242424")})
		text:anch(0, 0):pos(xPos, yPos):addTo(bg:getLayer())
		xPos = xPos + text:getContentSize().width + 4
		ui.newTTFLabelWithStroke({text = string.format("Lv.%d", equip.level), size = 18, color = uihelper.hex2rgb("#fefe33"), strokeColor = uihelper.hex2rgb("#242424")})
			:anch(0, 0):pos(xPos, yPos):addTo(bg:getLayer())

		--穿戴于谁身上
		if equip.masterId ~= 0 and unitCsv:getUnitByType(equip.masterId) then
			local equipedBg = display.newSprite(EquipRes .. "equip_by_bg.png")
			equipedBg:anch(1, 0):pos(bgSize.width - 10, yPos + 2):addTo(bg:getLayer())
			display.newSprite(EquipRes .. "bg_equiped_by.png")
				:anch(0.6, 0.5):pos(0, equipedBg:getContentSize().height/2):addTo(equipedBg)
			ui.newTTFLabel({text = unitCsv:getUnitByType(equip.masterId).name, size = 18})
				:anch(0.5, 0):pos(equipedBg:getContentSize().width/2, 2):addTo(equipedBg)		
		end

		if not showMoney then
			--属性
			local attrs = equip:getBaseAttributes()
			local yPos, yInterval, count = 85, 20, 1
			for key, value in pairs(EquipAttEnum) do
				if count > 3 then break end
				if attrs[key] > 0 then
					count = count + 1
					ui.newTTFLabel({ text = string.format("%s+%d", EquipAttName[value],attrs[key]), size = 18, color = uihelper.hex2rgb("#444444") })
						:anch(0, 1):pos(109, yPos):addTo(bg:getLayer())
					yPos = yPos - yInterval
				end
			end
		else
			--显示卖出银币
			local money = display.newSprite(GlobalRes .. "yinbi.png"):anch(0, 0):pos(145, 18):addTo(bg:getLayer())
			local path = "resource/ui_rc/battle/font/num_b.fnt"
			local sellMoney = equip:getSellMoney()
			ui.newBMFontLabel({ text =string.format("%d", sellMoney), font = path}):anch(0, 0):scale(0.8)
				:pos(money:getContentSize().width + money:getPositionX() + 20, 18):addTo(bg:getLayer())
		end

		--按钮
		if params.btnData1 then
			local xPos = bgSize.width - 18
			local btn1Ypos = params.btnData2 and bgSize.height - 42 or bgSize.height - 65
			DGBtn:new(EquipRes, {"btn_equip_normal.png", "btn_equip_selected.png"}, {
				text = {text = params.btnData1.text, size = 24, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
				priority = priority - 1,
				callback = params.btnData1.callback,
			}):getLayer():anch(1, 1):pos(xPos, btn1Ypos):addTo(bg:getLayer())

			if params.btnData2 then
				DGBtn:new(EquipRes, {"btn_equip_normal.png", "btn_equip_selected.png"}, {
					text = {text = params.btnData2.text, size = 24, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
					priority = priority - 1,
					callback = params.btnData2.callback,
				}):getLayer():anch(1, 0):pos(xPos, 10):addTo(bg:getLayer())
			end
		end
	else
		ui.newTTFLabel({text = "卸下装备", size = 36, color = display.COLOR_DARKYELLOW })
			:anch(0, 0.5):pos(150, bgSize.height / 2):addTo(bg:getLayer())
	end
	return bg:getLayer()
end)
