local GlobalRes = "resource/ui_rc/global/"
local CarbonRes = "resource/ui_rc/carbon/"

local failureTips = {
	[1] = { --升级
		icon = "intensify_normal.png",
		res  = "resource/ui_rc/home/",
		levelLimit = 1,
		callback = function() switchScene("home", { layer = "intensify" }) end
	},

	-- [2] = { --点将
	-- 	icon = "choose_normal.png",
	-- 	res  = "resource/ui_rc/home/",
	-- 	levelLimit = 10,
	-- 	callback = function() switchScene("home", { layer = "chooseHero" }) end
	-- },

	[2] = { --进化
		icon = "evolution_normal.png",
		res  = "resource/ui_rc/home/",
		levelLimit = 1,
		callback = function() switchScene("home", { layer = "evolution" }) end
	},
	
	[3] = { --科技
		icon = "old_keji.png",
		res  = "resource/ui_rc/home/",
		levelLimit = 11,
		callback = function() switchScene("home", { layer = "tech" }) end
	},

	[4] = { --装备
		icon = "equip_normal.png",
		res  = "resource/ui_rc/home/",
		levelLimit = 10,
		callback = function() switchScene("home", { layer = "equip" }) end
	},	

	[5] = { --抽卡
		icon = "drawcard_normal.png",
		res  = "resource/ui_rc/home/",
		levelLimit = 5,
		callback = function() switchScene("home", { layer = "shop" }) end
	},

	[6] = { --觉醒
		icon = "old_jiangxing.png",
		res  = "resource/ui_rc/home/",
		levelLimit = 10,
		callback = function() switchScene("home", { layer = "herostar" }) end
	},

	[7] = { --将星
		icon = "old_jiangxing.png",
		res  = "resource/ui_rc/home/",
		levelLimit = 21,
		callback = function() switchScene("home", { layer = "herostar" }) end
	},

	[8] = { --美人
		icon = "old_meiren.png",
		res  = "resource/ui_rc/home/",
		levelLimit = 23,
		callback = function() switchScene("home", { layer = "beauty" }) end
	},
}

local FailureHelperLayer = class("FailureHelperLayer", function()
	return display.newLayer()	
end)

function FailureHelperLayer:ctor(params)
	params = params or {}
	self.size = CCSizeMake(642, 612)
	self.priority = params.priority or -130

	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1 })

	ui.newTTFLabelWithStroke({ text = "你可以通过以下方式使自己变得更强！", size = 22, font = ChineseFont }):addTo(self)
			:anch(0.5, 0.5):pos(self.size.width / 2 + 50, self.size.height/2 + 40)

	for index, tipData in ipairs(failureTips) do
		local posX = index > 4 and self.size.width/4 * (index - 4) or self.size.width/5 * index
		local posY = index > 4 and 150 or 270
		local tipsBtn = DGBtn:new(tipData.res, {tipData.icon},
			{	
				scale = 1.05,
				priority = self.priority - 1,
				callback = function()
					if game.role.level < tipData.levelLimit then
						DGMsgBox.new({ msgId = 172 })
						return
					end

					tipData.callback()
				end,
			})
		tipsBtn:getLayer():anch(0.5, 0.5):pos(posX + 50, posY):addTo(self)

		local btnSize = tipsBtn:getLayer():getContentSize()
	end
end

function FailureHelperLayer:getLayer()
	return self.mask:getLayer()
end

return FailureHelperLayer