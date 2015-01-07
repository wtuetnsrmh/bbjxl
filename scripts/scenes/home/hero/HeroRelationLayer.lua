local GlobalRes = "resource/ui_rc/global/"
local HeroRes = "resource/ui_rc/hero/"

local HeroRelationLayer = class("HeroRelationLayer", function(params) 
	return display.newLayer() 
end)

function HeroRelationLayer:ctor(params)

	params = params or {}
	self.priority = params.priority
	local hero = params.hero
	if not hero or table.nums(hero.unitData.relation) == 0 then
		return
	end

	local bg = display.newScale9Sprite(HeroRes .. "choose/assist_bg.png")
	bg:anch(0.5, 0.5):pos(display.cx, display.cy)

	local mask
	mask = DGMask:new({ item = bg, opacity = 0, priority = self.priority, click = function() mask:remove() end })
	mask:getLayer():addTo(display.getRunningScene())

	local width = 500
	local detailLayer = display.newLayer()
	
	-- 情缘
	local nHeight = 0
	nHeight = nHeight - 24

	for index = 1, table.nums(hero.unitData.relation) do
		local relation = hero.unitData.relation[index]
		local color = (hero.relation and table.find(hero.relation, relation)) and display.COLOR_YELLOW or display.COLOE_WHITE
		--名称
		local xPos = 15
		local name = ui.newTTFLabel({ text = "【"..relation[6].."】", size = 20, color = color})
		name:anch(0, 1):pos(xPos, nHeight):addTo(detailLayer)
		xPos = xPos + name:getContentSize().width
		--描述
		local desc = unitCsv:formatRelationDesc(relation)
								
		local descLabel = uihelper.createLabel({text = desc, size = 20, color = color, width = width - xPos - 20 })
		descLabel:anch(0, 1):pos(xPos, nHeight):addTo(detailLayer)

		nHeight = nHeight - descLabel:getContentSize().height - 10
	end
	nHeight = nHeight - 28
	bg:setContentSize(CCSizeMake(width, math.abs(nHeight)))
	detailLayer:size(width, 10):anch(0, 1):pos(0, bg:getContentSize().height):addTo(bg)
end

return HeroRelationLayer