-- 奖励内容展示：
local ChickenRes = "resource/ui_rc/activity/chicken/"

--shop yellow_frame.png 包箱发光  yuanbao_1.png  可以做动作

local EatChickenLayer = class("EatChickenLayer", function() 
	return display.newLayer(ChickenRes.."bg.jpg") 
end)

local index = 1

function EatChickenLayer:ctor(params)
	self:setNodeEventEnabled(true)
	self.params = params or {}
	self.priority = params.priority or -129
	self.size = self:getContentSize()
	self:canEatNowRequest()
end

function EatChickenLayer:canEatNowRequest()
	local bin = pb.encode("SimpleEvent", { roleId = game.role.id})
	game:sendData(actionCodes.RoleCanEatChickenRequest, bin)
	loadingShow()
	game:addEventListener(actionModules[actionCodes.RoleCanEatChickenRequest], function(event)
		loadingHide()
		local msg = pb.decode("SimpleEvent", event.data)
		if msg.param1 == 3 then
			self.canEat = true
		else
			self.canEat = false
		end
		self:initUIByData()

		return "__REMOVE__"
	end)
end

function EatChickenLayer:initUIByData()
	local ww,hh = self:getContentSize().width,self:getContentSize().height
	local canEat = self.canEat

	--对话框：
	local talkbg = display.newSprite(ChickenRes.."msgbg.png")
	talkbg:setPosition(ccp(ww * 0.32, hh * 0.65))
	self:addChild(talkbg)

	ui.newTTFRichLabel({text = "[color=FFFFFFFF]主公，每日[color=FFFFD200]12—14[/color]点和[color=FFFFD200]18—20[/color]点可以吃烧鸡补充体力呦！[/color]", size = 24,
		color = display.COLOR_WHITE, dimensions = CCSizeMake(280, 200),font=ChineseFont  })
		:anch(1, 0.5)
		:pos(talkbg:getContentSize().width - 35, talkbg:getContentSize().height * 0.5)
		:addTo(talkbg)


	function showTips(index)
		if index <= 2 then
			local time = 0.2
			display.newSprite(ChickenRes.."tips_text_"..index..".png"):pos(ww/2,hh/2):scale(0.2):addTo(self)
			:runAction(transition.sequence({
					CCSpawn:createWithTwoActions(CCScaleTo:create(time, 0.8), CCMoveTo:create(time, ccp(ww/2, hh/2 + 60))),
					CCDelayTime:create(0.5),
					CCRemoveSelf:create(),
					CCCallFunc:create(function()
						showTips(index + 1)
					end)
				}))
		end
	end

	--烧鸡
	local chickPicBtn
	chickPicBtn = DGBtn:new(ChickenRes, {"chicken.png","chicken.png","chicken.png"},
		{	
			scale = 1.05,
			priority = self.priority - 50,
			callback = function() 
				local bin = pb.encode("SimpleEvent", { roleId = game.role.id})
				game:sendData(actionCodes.RoleEatChickenRequest, bin)
				game:addEventListener(actionModules[actionCodes.RoleEatChickenRequest], function(event)
					local msg = pb.decode("SimpleEvent", event.data)
					if msg.param1 == 3 then
						showTips(1)
						chickPicBtn:getLayer():setVisible(false)
						chickPicBtn:setEnable(false)
					end

					game.role:dispatchEvent({ name = "notifyNewMessage", type = "eatChicken" })

					return "__REMOVE__"
				end)
			end,
		})
	chickPicBtn:getLayer():anch(0.5, 0.5)
	:pos(350, 100)
	:addTo(self,999)
	chickPicBtn:setEnable(self.canEat)
	chickPicBtn:getLayer():setVisible(self.canEat)

	local frame = display.newSprite(ChickenRes.."chicken.png")
	frame:setPosition(ccp(chickPicBtn:getLayer():getContentSize().width/2, chickPicBtn:getLayer():getContentSize().height/2))
	chickPicBtn:getLayer():addChild(frame,-1)
	frame:runAction(CCRepeatForever:create(transition.sequence({
		CCScaleTo:create(0.5, 0.9),
		CCScaleTo:create(0.5, 1.03)
		})))
	
end 

function EatChickenLayer:getLayer()
	return self.mask:getLayer()
end

function EatChickenLayer:onEnter()
	print("***** onenter ******")
end

function EatChickenLayer:onExit()
end

return EatChickenLayer