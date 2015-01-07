local TowerRes = "resource/ui_rc/activity/tower/"
local HeroRes = "resource/ui_rc/hero/"

local attrIndies = { [1] = "hp", [2] = "atk", [3] = "def" }

local attrNames = {
	[1] = { name = "生命加成", field = "hp", res = "hp_frame.png" },
	[2] = { name = "攻击加成", field = "atk", res = "atk_frame.png" },
	[3] = { name = "防御加成", field = "def", res = "def_frame.png" },
}

local TowerAttrModifyLayer = class("TowerAttrModifyLayer", function()
	return display.newLayer(GlobalRes .. "rule/rule_bg.png")
end)

function TowerAttrModifyLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -130
	self.size = self:getContentSize()

	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1 })

	local titleBg = display.newSprite(GlobalRes .. "title_bar.png")
	titleBg:pos(self.size.width / 2, self.size.height - 35):addTo(self)
	display.newSprite(TowerRes .. "attr_title.png")
		:pos(titleBg:getContentSize().width / 2, titleBg:getContentSize().height / 2):addTo(titleBg)

	local innerBg = display.newSprite(TowerRes .. "award_innerbg.png")
	local innerSize = innerBg:getContentSize()
	innerBg:anch(0.5, 0):pos(self.size.width / 2, 70):addTo(self)

	local towerData = game.role.towerData

	self.towerAttrModifyData = towerAttrCsv:getRandAttrModify()
	if not self.towerAttrModifyData then return end

	local statsBg = display.newSprite(TowerRes .. "attr_bg.png")
	statsBg:pos(innerSize.width / 2, innerSize.height - 30):addTo(innerBg)
	local statsSize = statsBg:getContentSize()

	ui.newTTFLabel({ text = string.format("已闯过关%d关", (towerData.carbonId - 1) % 100), size = 20, color = uihelper.hex2rgb("#ffda7d") })
		:anch(0, 0.5):pos(20, statsSize.height / 2):addTo(statsBg)
	ui.newTTFLabel({ text = string.format("得星 %d", towerData.totalStarNum), size = 20, color = uihelper.hex2rgb("#ffda7d") })
		:anch(0, 0.5):pos(160, statsSize.height / 2):addTo(statsBg)
	display.newSprite(GlobalRes .. "star/icon_big.png"):pos(270, statsSize.height / 2):addTo(statsBg)
	ui.newTTFLabel({ text = string.format("还剩 %d", towerData.curStarNum), size = 20, color = uihelper.hex2rgb("#ffda7d") })
		:anch(0, 0.5):pos(310, statsSize.height / 2):addTo(statsBg)
	display.newSprite(GlobalRes .. "star/icon_big.png"):pos(420, statsSize.height / 2):addTo(statsBg)

	ui.newTTFLabel({ text = "临时加强武将属性，选择一项后继续战斗", size = 20, color = uihelper.hex2rgb("#533a27") })
		:anch(0.5, 1):pos(innerSize.width / 2, innerSize.height - 55):addTo(innerBg)

	local attrBegin = 20
	local attrInterval = (innerSize.width - 2 * attrBegin - 3 * 168) / 2
	table.sort(attrNames, function(a, b) return self.towerAttrModifyData[a.field .. "Modify"] < self.towerAttrModifyData[b.field .. "Modify"] end)
	for index = 1, #attrNames do
		local attrBtn = self:initAttrCell(index)
		local size = attrBtn:getContentSize()

		attrBtn:anch(0.5, 0.5):pos(attrBegin + (index - 1) * (168 + attrInterval) + size.width / 2, 165)
			:addTo(innerBg)
	end

	-- 当前加成
	-- 属性加成
	local attrLabel = display.newSprite(TowerRes .. "attr_bg.png")
	local labelSize = attrLabel:getContentSize()

	ui.newTTFLabel({ text = "当前加成", size = 20, color = uihelper.hex2rgb("#ffda7d") })
		:anch(0, 0.5):pos(10, labelSize.height / 2):addTo(attrLabel)
	display.newSprite(GlobalRes .. "attr_hp.png"):pos(130, labelSize.height / 2):addTo(attrLabel)
	display.newSprite(GlobalRes .. "attr_atk.png"):pos(230, labelSize.height / 2):addTo(attrLabel)
	display.newSprite(GlobalRes .. "attr_def.png"):pos(330, labelSize.height / 2):addTo(attrLabel)
	ui.newTTFLabel({ text = string.format("+%d%%", towerData.hpModify), size = 20, color = uihelper.hex2rgb("#7ce810") })
		:anch(0, 0.5):pos(150, labelSize.height / 2):addTo(attrLabel)
	ui.newTTFLabel({ text = string.format("+%d%%", towerData.atkModify), size = 20, color = uihelper.hex2rgb("#7ce810") })
		:anch(0, 0.5):pos(250, labelSize.height / 2):addTo(attrLabel)
	ui.newTTFLabel({ text = string.format("+%d%%", towerData.defModify), size = 20, color = uihelper.hex2rgb("#7ce810") })
		:anch(0, 0.5):pos(350, labelSize.height / 2):addTo(attrLabel)

	attrLabel:anch(0.5, 0):pos(self.size.width / 2, 20):addTo(self)
end

function TowerAttrModifyLayer:initAttrCell(index)
	local attrName = attrNames[index].field

	-- 查找对应的属性ID
	local attrId
	for index, name in ipairs(attrIndies) do
		if attrName == name then attrId = index end
	end

	local attrEnbale = game.role.towerData.curStarNum >= self.towerAttrModifyData[attrName .. "Star"]
	local attrBtn = DGBtn:new(TowerRes, { attrNames[index].res },
		{	
			scale = 0.97,
			priority = self.priority,
			callback = function()

				local modifyRequest = { roleId = game.role.id, 
					param1 = self.towerAttrModifyData.attrId, param2 = attrId, 
					param3 = game.role.towerData.carbonId 
				}
				local bin = pb.encode("SimpleEvent", modifyRequest)
				game:sendData(actionCodes.TowerAttrModifyRequest, bin)
				game:addEventListener(actionModules[actionCodes.TowerAttrModifyResponse], function(event)
					local msg = pb.decode("TowerData", event.data)

					local towerData = game.role.towerData
					towerData.curStarNum = msg.curStarNum
					towerData[attrName .. "Modify"] = msg[attrName .. "Modify"]

					switchScene("tower")

					return "__REMOVE__"
				end)
			end,
		})
	attrBtn:setEnable(attrEnbale)
	if not attrEnbale then attrBtn.item[1]:setColor(ccc3(100, 100, 100)) end
	local attrBtnSize = attrBtn:getLayer():getContentSize()

	ui.newTTFLabelWithStroke({ text = string.format("+%d%%", self.towerAttrModifyData[attrName .. "Modify"]), 
		size = 48, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424")})
		:pos(attrBtnSize.width / 2, attrBtnSize.height / 2):addTo(attrBtn:getLayer())

	local consumeBg = display.newSprite(GlobalRes .. "label_short_bg.png")
	consumeBg:anch(0.5, 1):pos(attrBtnSize.width / 2, -5):addTo(attrBtn:getLayer())
	local consumeSize = consumeBg:getContentSize()

	ui.newTTFLabel({ text = "消耗", size = 20 }):anch(0, 0.5)
		:pos(25, consumeSize.height / 2):addTo(consumeBg)
	ui.newTTFLabel({ text = self.towerAttrModifyData[attrName .. "Star"], size = 20, color = uihelper.hex2rgb("#7ce810") })
		:anch(0, 0.5):pos(80, consumeSize.height / 2):addTo(consumeBg)
	display.newSprite(GlobalRes .. "star/icon_big.png"):anch(1, 0.5)
		:pos(consumeSize.width - 10, consumeSize.height / 2)
		:addTo(consumeBg)

	return attrBtn:getLayer()
end

function TowerAttrModifyLayer:getLayer()
	return self.mask:getLayer()
end

return TowerAttrModifyLayer