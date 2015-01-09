local MoneyRes = "resource/ui_rc/activity/money/"
local GlobalRes = "resource/ui_rc/global/"
local HomeRes = "resource/ui_rc/home/"

local TrialChooseHeroLayer = import(".TrialChooseHeroLayer")

local TrialCarbonLayer = class("TrialCarbonLayer", function()
	return display.newLayer(MoneyRes .. "diff_bg.png")
end)

function TrialCarbonLayer:ctor(params)
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

	--title
	local titlebg = display.newSprite(GlobalRes .. "title_bar.png")
		:pos(self.size.width/2, self.size.height - 35):addTo(self)
	display.newSprite(MoneyRes .. "special_title_bg.png")
		:pos(titlebg:getContentSize().width/2, titlebg:getContentSize().height/2):addTo(titlebg)

	local innerBg = display.newSprite()
	innerBg:size(763,255)
	local innerSize = innerBg:getContentSize()
	innerBg:anch(0.5, 0):pos(self.size.width / 2, 90):addTo(self)

	-- 副本描述

	--初始化buttons：
	local xBegin = 42
	local xInterval = (innerSize.width - 2 * xBegin - 4 * 150) / 3
	for index = 1, 4 do
		local battleInfo = trialBattleCsv:getDataById(params.activity.index .. index)
		--button
		local mBattleBtnR = DGBtn:new(MoneyRes, {"diff_bar_normal.png", "diff_bg_selected.png"},
			{	
				priority = self.priority - 10,
				multiClick = false,
				callback = function()				
					if game.role.health < battleInfo.health then
						local HealthUseLayer = require("scenes.home.HealthUseLayer")
						local layer = HealthUseLayer.new({ priority = self.priority -10})
						layer:getLayer():addTo(display.getRunningScene())
						return
					end

					if game.role.level < battleInfo.level then
						DGMsgBox.new({ type = 1, text = "等级不足！"})
						return
					end

					if self.cdTime > 0 then
						DGMsgBox.new({ type = 1, text = "下次刷新时间未到！"})
						return
					end
					
					local layer = TrialChooseHeroLayer.new({priority = self.priority - 10, activity = params.activity, curMapId = battleInfo.id}):getLayer()
					layer:addTo(display.getRunningScene()) 
				end,
			})
		local mBattleBtn = mBattleBtnR:getLayer()
		mBattleBtn:pos(xBegin + (150 + xInterval) * (index - 1), 50):addTo(innerBg)
		local btnSize = mBattleBtn:getContentSize()

		--icon
		local icon = display.newSprite(string.format("%sdiff_icon_%d.png",MoneyRes,index))
		icon:pos(btnSize.width / 2, btnSize.height / 2):addTo(mBattleBtn)
		mBattleBtn:setTag(index + 10000)

		--困难度：
		local hardly = display.newSprite(string.format("%sdiff_text_%d.png",MoneyRes,index))
		hardly:pos(btnSize.width / 2,20):addTo(mBattleBtn)

		local infoBg = display.newSprite(MoneyRes.."chicken_cost.png")
		infoBg:anch(0.5, 1):pos(btnSize.width / 2, -10):addTo(mBattleBtn)
		local bgSize = infoBg:getContentSize()
		if game.role.level >= battleInfo.level then
			display.newSprite(GlobalRes.."chicken.png")
				:anch(0,0.5):pos(10, bgSize.height/2):addTo(infoBg)

			ui.newTTFLabel({ text = battleInfo.health, size = 20, color = uihelper.hex2rgb("#444444") })
				:pos(bgSize.width * 0.5, bgSize.height * 0.5):addTo(infoBg)
		else		
			mBattleBtnR:setGray(true)
			ui.newTTFLabel({text=battleInfo.level.."级开启",color=display.COLOR_RED,size=20,font=ChineseFont})
			:pos(bgSize.width / 2, bgSize.height / 2):addTo(infoBg)
			-- display.newSprite(string.format("%smoney_level_%d.png",MoneyRes,index))	
			-- 	:pos(bgSize.width / 2, bgSize.height / 2):addTo(infoBg)
		end
	end

	local txtBg=display.newSprite(GlobalRes .. "label_bg.png")
	txtBg:anch(0,0.5):pos(51,innerSize.height - 25):addTo(innerBg)
	local word_refresh = ui.newTTFLabel({ text = "今日剩余次数:", size = 20, color = display.COLOR_WHITE })
	word_refresh:anch(0, 0.5):pos(74, innerSize.height - 25):addTo(innerBg)

	ui.newTTFLabel({text = string.format("%d",2 - tonum(game.role[string.format("%sBattleCount", params.activity.name)])),size = 20,color = uihelper.hex2rgb("#7ce810") })
		:anch(0, 0.5):pos(word_refresh:getContentSize().width + 80, innerSize.height - 25):addTo(innerBg)


	self.cdTime = math.max(tonum(game.role[string.format("%sBattleCD", params.activity.name)]) - game:nowTime(), 0)
	

	--刷新时间：
	local txtBg=display.newSprite(GlobalRes .. "label_bg.png")
	txtBg:anch(0,0.5):pos(innerSize.width / 2 + 127,innerSize.height - 25):addTo(innerBg)
	local word_time = ui.newTTFLabel({ text = "下次刷新时间：", size = 20, color = display.COLOR_WHITE})
	word_time:anch(0,0.5):pos(innerSize.width / 2 + 135, innerSize.height - 25):addTo(innerBg)

	local timeLabel = ui.newTTFLabel({ text = self:getTimeFormateStr(self.cdTime), size = 20, color = uihelper.hex2rgb("#7ce810"), })
	timeLabel:pos(word_time:getContentSize().width + innerSize.width / 2 + 155, innerSize.height - 25):addTo(innerBg)

	self:runAction(CCRepeatForever:create(transition.sequence({  
    CCDelayTime:create(1),
	CCCallFunc:create(function()
			self.cdTime = self.cdTime - 1
        	if self.cdTime <= 0 then
        		timeLabel:setString(self:getTimeFormateStr(0))
        		self:stopAllActions()
        	else
        		timeLabel:setString(self:getTimeFormateStr(self.cdTime))
        	end
		end), 
	})))
end

--分：秒
function TrialCarbonLayer:getTimeFormateStr(seconds)
	local s = tonumber(seconds)
	return string.format("%02d:%02d",math.floor(s/60),s%60)
end

--state 0 可以 4.体力不足 5.等级不足 
function TrialCarbonLayer:canEnter(event)
	local msg = pb.decode("SimpleEvent", event.data)
	local state = tonumber( msg.param1)
	local battleid = tonumber(msg.param2)
	if state == 0 then
		self:initBattleFiled(battleid)
	elseif state == 4 then
		local HealthUseLayer = require("scenes.home.HealthUseLayer")
		local layer = HealthUseLayer.new({ priority = self.priority -10})
		layer:getLayer():addTo(display.getRunningScene())
	elseif state == 5 then
		DGMsgBox.new({ type = 1, text = "等级不足！"})
	elseif state == 6 then
		DGMsgBox.new({ type = 1, text = "下次刷新时间未到！"})
	end
	return "__REMOVE__"
end

--创建战场：
function TrialCarbonLayer:initBattleFiled(battleID)
	local r = moneyBattleCsv:getDataById(battleID)

	switchScene("battle", { 
		battleType = BattleType.Trial, 
		carbonId = r.btres, 
		round = 1,                 --初始化回合数为1
		battleindex = battleID,    --选择的管卡index
		})
end


function TrialCarbonLayer:getLayer()
	return self.mask:getLayer()
end

return TrialCarbonLayer