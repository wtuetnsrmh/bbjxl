local MoneyRes = "resource/ui_rc/activity/money/"
local GlobalRes = "resource/ui_rc/global/"
local HomeRes = "resource/ui_rc/home/"

local MoneyCarbonLayer = class("MoneyCarbonLayer", function()
	return display.newLayer(MoneyRes .. "diff_bg.png")
end)

--second 服务器和cd之差
function MoneyCarbonLayer:ctor(params)
	self.params = params or {}

	self.priority = self.params.priority or - 130
	self.size = self:getContentSize()
	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.mask = DGMask:new({ item = self, priority = self.priority - 1,ObjSize = self.size,
		click = function()
		end,
		clickOut = function()
			print(" touch close layer")
			self:removeAllChildren()
			self:getLayer():removeFromParent()
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
	ui.newTTFRichLabel({text = "[color=FF533B22]击杀敌将数量越多，获得越多的银币[/color]", size = 20 })
		:pos(self.size.width / 2, 75):addTo(self)
	ui.newTTFRichLabel({text = "[color=FF533B22]推荐使用 [color=FF533B22]攻击型[/color] 武将[/color]", size = 20 })
		:pos(self.size.width / 2, 45):addTo(self)

	local moneyTip={"16","30","50","75"}
	--初始化buttons：
	local xBegin = 42
	local xInterval = (innerSize.width - 2 * xBegin - 4 * 150) / 3
	for index = 1, 4 do
		--button
		local mBattleBtnR = DGBtn:new(MoneyRes, {"diff_bar_normal.png", "diff_bg_selected.png"},
			{	
				priority = self.priority - 10,
				callback = function()				
					local bin = pb.encode("SimpleEvent", { roleId = game.role.id,param1 = index})
					game:sendData(actionCodes.MoneyBattleRequest, bin)
					game:addEventListener(actionModules[actionCodes.MoneyBattleRequest], handler(self, self.canEnter))
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

		local battleInfo = moneyBattleCsv:getDataById(index)
		local infoBg = display.newSprite(MoneyRes.."chicken_cost.png")
		infoBg:anch(0.5, 1):pos(btnSize.width / 2, -10):addTo(mBattleBtn)
		local bgSize = infoBg:getContentSize()
		if game.role.level >= battleInfo.level then
			display.newSprite(GlobalRes.."chicken.png")
				:anch(0,0.5):pos(10, bgSize.height/2):addTo(infoBg)

			ui.newTTFLabel({ text = battleInfo.health, size = 20, color = uihelper.hex2rgb("#444444") })
				:pos(bgSize.width * 0.5, bgSize.height * 0.5):addTo(infoBg)
		else
			local grayShadeProgram = UIUtil:shaderForKey("ShaderPositionTextureGray")
			icon:setShaderProgram(grayShadeProgram)
			mBattleBtnR.item[1]:setShaderProgram(grayShadeProgram)
			mBattleBtnR.item[2]:setShaderProgram(grayShadeProgram)

			ui.newTTFLabel({text=battleInfo.level.."级开启",color=display.COLOR_RED,size=20,font=ChineseFont})
			:pos(bgSize.width / 2, bgSize.height / 2):addTo(infoBg)
			-- display.newSprite(string.format("%smoney_level_%d.png",MoneyRes,index))	
			-- 	:pos(bgSize.width / 2, bgSize.height / 2):addTo(infoBg)
		end
	end

	local txtBg=display.newSprite(GlobalRes .. "label_bg.png")
	txtBg:anch(0,0.5):pos(51,innerSize.height - 25):addTo(innerBg)
	local times = globalCsv:getFieldValue("expBattleTimes")
	local word_refresh = ui.newTTFLabel({ text = "今日剩余次数:", size = 20, color = display.COLOR_WHITE })
	word_refresh:anch(0, 0.5):pos(74, innerSize.height - 25):addTo(innerBg)

	ui.newTTFLabel({text = string.format("%d",tonumber(times) - game.role.moneyBattleCount),size = 20,color = uihelper.hex2rgb("#7ce810") })
		:anch(0, 0.5):pos(word_refresh:getContentSize().width + 80, innerSize.height - 25):addTo(innerBg)

	--用action做时间计时器：
	if self.params.seconds > 0 then
		self.cdTime = self.params.seconds
	else
		self.cdTime = 0
	end

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

	self:checkGuide()
end

--分：秒
function MoneyCarbonLayer:getTimeFormateStr(seconds)
	local s = tonumber(seconds)
	return string.format("%02d:%02d",math.floor(s/60),s%60)
end

--state 0 可以 4.体力不足 5.等级不足 
function MoneyCarbonLayer:canEnter(event)
	local msg = pb.decode("SimpleEvent", event.data)
	local state = tonumber( msg.param1)
	local battleid = tonumber(msg.param2)
	if state == 0 then
		self:initMoneyBattleFiled(battleid)
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
function MoneyCarbonLayer:initMoneyBattleFiled(battleID)
	local r = moneyBattleCsv:getDataById(battleID)

	switchScene("battle", { 
		battleType = BattleType.Money, 
		carbonId = r.btres, 
		round = 1,                 --初始化回合数为1
		battleindex = battleID,    --选择的管卡index
		})
end

function MoneyCarbonLayer:checkGuide()
	
end

function MoneyCarbonLayer:getLayer()
	return self.mask:getLayer()
end

return MoneyCarbonLayer