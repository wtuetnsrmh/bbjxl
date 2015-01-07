local GlobalRes = "resource/ui_rc/global/"
local HomeRes = "resource/ui_rc/home/"
local MoneyRes = "resource/ui_rc/activity/money/"
local LegendRes = "resource/ui_rc/carbon/legend/"
local HeroRes   = "resource/ui_rc/hero/"

local LegendSelectedDiffLayer = class("LegendSelectedDiffLayer", function()
	return display.newLayer(MoneyRes .. "diff_bg.png")
end)

function LegendSelectedDiffLayer:ctor(params)
	self.params = params or {}
	self.priority = self.params.priority or - 130
	self.size = self:getContentSize()
	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority - 1,ObjSize = self.size,
		click = function()
		end,
		clickOut = function()
			self.mask:remove()
		end,})

	local innerBg = display.newSprite()
	innerBg:size(self.size.width,self.size.height)
	local innerSize = innerBg:getContentSize()
	innerBg:anch(0.5, 0):pos(self.size.width / 2, 90):addTo(self)

	--title
	local titlebg = display.newSprite(GlobalRes .. "title_bar.png")
		:pos(self.size.width/2, self.size.height - 35):addTo(self)
	display.newSprite(MoneyRes .. "special_title_bg.png")
		:pos(titlebg:getContentSize().width/2, titlebg:getContentSize().height/2):addTo(titlebg)

	local titleBg = display.newSprite(GlobalRes.."label_bg.png"):pos(self.size.width/2,320):addTo(self)
	ui.newTTFLabel({text = "今日剩余次数:", size = 20})
		:anch(0, 0.5):pos(20, titleBg:getContentSize().height/2):addTo(titleBg)
	local legendBattleCntLabel = ui.newTTFLabel({ text = game.role.legendBattleLimit, size = 20, color = uihelper.hex2rgb("#7ce810") })
	legendBattleCntLabel:anch(0, 0.5):pos(155, titleBg:getContentSize().height/2):addTo(titleBg)

	local addBattleCntBtn = DGBtn:new(GlobalRes, {"add_normal.png", "add_selected.png"},
		{	
			scale = 1.05,
			priority = self.priority-10,
			callback = function()
				if tonum(game.role.legendBuyCount) >= game.role:getLegendBuyLimit() then
					DGMsgBox.new({ text = "您当前的剩余购买次数为0，您可以通过提升vip等级来提升挑战次数", type = 2 })
				else
					local costYuanbao = functionCostCsv:getCostValue("legendBattleCnt", game.role.legendBuyCount)
					DGMsgBox.new({ 
						text = string.format(
							"是否花费"..costYuanbao.."元宝增加1次挑战机会\n您今日的剩余购买次数为%d", game.role:getLegendBuyLimit() - game.role.legendBuyCount), type = 2,
						button2Data = { callback = function()
							local bin = pb.encode("SimpleEvent", { roleId = game.role.id })
            				game:sendData(actionCodes.LegendBattleAddCount, bin)
						end }
					})
				end
			end,
		})
	addBattleCntBtn:getLayer():anch(0.5, 0.5):pos(200, titleBg:getContentSize().height/2):addTo(titleBg)


	--初始化buttons：
	local xBegin = 73
	local xInterval = (innerSize.width - 2 * xBegin - 3 * 150) / 2
	for index = 1, 3 do
		--button
		local mBattleBtnR = DGBtn:new(MoneyRes, {"diff_bar_normal.png", "diff_bg_selected.png"},
			{	
				priority = self.priority - 10,
				multiClick = false,
				callback = function()				
					local saveLegendLimit = { roleId = game.role.id, param1 = params.carbonId, param2 = index}
					local bin = pb.encode("SimpleEvent", saveLegendLimit)
					game:sendData(actionCodes.LegendBattleEnterRequest, bin)
					loadingShow()
					game:addEventListener(actionModules[actionCodes.LegendBattleEnterResponse], function(event)
						loadingHide()
						local msg = pb.decode("SimpleEvent", event.data)
						switchScene("battle", { battleType = BattleType.Legend, carbonId = msg.param1,diffIndex = msg.param2 })

						return "__REMOVE__"
					end)
				end,
			})
		local mBattleBtn = mBattleBtnR:getLayer()
		mBattleBtn:pos(xBegin + (150 + xInterval) * (index - 1), 45):addTo(innerBg)
		local btnSize = mBattleBtn:getContentSize()

		--icon
		local icon = display.newSprite(string.format("%sdiff_icon_%d.png",MoneyRes,index))
		icon:pos(btnSize.width / 2, btnSize.height / 2):addTo(mBattleBtn)
		mBattleBtn:setTag(index + 10000)

		--困难度：
		local hardly = display.newSprite(LegendRes..string.format("diff%d.png",index))
		hardly:pos(btnSize.width / 2,22):addTo(mBattleBtn)

		local infoBg = display.newSprite(MoneyRes.."chicken_cost.png")
		infoBg:anch(0.5, 1):pos(btnSize.width / 2, -10):addTo(mBattleBtn)
		local bgSize = infoBg:getContentSize()


		display.newSprite(HeroRes.."fragment_tag.png"):anch(0,0.5):pos(15,bgSize.height/2):addTo(infoBg)
		ui.newTTFLabel({text="X"..index,color=uihelper.hex2rgb("#444444"),size=20})
			:pos(bgSize.width / 2+20, bgSize.height / 2):addTo(infoBg)
	end

	display.newSprite(LegendRes.."bg_item.png"):anch(0.5,0.5):pos(self.size.width/2,60):addTo(self)
	ui.newTTFRichLabel({text = "小挑怡情，大挑伤身，强挑灰飞烟灭", size = 22,color =uihelper.hex2rgb("#4f351a") })
		:pos(self.size.width / 2, 60):addTo(self)

	self.legendBattleCntUpdate = game.role:addEventListener("updateLegendBattleLimit", function(event)
		legendBattleCntLabel:setString(string.format("%d", event.legendBattleLimit))
	end)
	
end


function LegendSelectedDiffLayer:getLayer()
	return self.mask:getLayer()
end

function LegendSelectedDiffLayer:onExit()
	game.role:removeEventListener("updateLegendBattleLimit", self.legendBattleCntUpdate)
end

return LegendSelectedDiffLayer