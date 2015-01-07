--领取首充奖励界面
-- Author: yzm
-- Date: 2014-11-29 17:04:09
--
local GlobalRes = "resource/ui_rc/global/"
local FirstReChargeRes = "resource/ui_rc/activity/recharge/"
local ShopRes = "resource/ui_rc/shop/"
local ParticleRes = "resource/ui_rc/particle/"

local ReChargeLayer = import("..home.shop.ReChargeLayer")

local FirstRechargeLayer=class("FirstRechargeLayer",function()
	return display.newSprite(FirstReChargeRes.."bg.png")
	end)

function FirstRechargeLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or -130
	self.callback=params.callback

	self:anch(0.5, 0.5):pos(display.cx, display.cy)
	self.size=self:getContentSize()
	self.mask = DGMask:new({ item = self, priority = self.priority + 1 ,ObjSize = CCSize(811,508), clickOut = function() self.mask:remove() end})

	self.tipsTag = 7878

	self:initContentLayer()

	
end

function FirstRechargeLayer:initContentLayer()
	if self.contentLayer then
		self.contentLayer:removeSelf()
	end

	self.contentLayer=display.newSprite()
	self.contentLayer:setContentSize(self.size)
	self.contentLayer:pos(self.size.width/2,self.size.height/2):addTo(self)

	--显示奖品
	local boxBg=display.newSprite(FirstReChargeRes.."box.png"):anch(0,0):pos(129.95,120):addTo(self.contentLayer)

	local yb=display.newSprite(FirstReChargeRes.."yb.png"):anch(0,0):pos(410,230):addTo(self.contentLayer)
	self:ShowStar(yb)

	local awardData=globalCsv:getFieldValue("firstRechargeAward")
	
	local awardItems={}
	local keys=table.keys(awardData)
	local sortKeys ={}
	local heroKeys,otherKeys={},{}
	for _,key in ipairs(keys) do
		if itemCsv:getItemById(key) and itemCsv:getItemById(key).type == ItemTypeId.Hero then
			table.insert(heroKeys,key)
		else
			table.insert(otherKeys,key)
		end
	end
	local heroNum =#heroKeys
	table.insertTo(heroKeys,otherKeys,#heroKeys+1)
	for index,itemId in ipairs(heroKeys) do
		table.insert(awardItems,{itemId=itemId,itemCount=awardData[itemId]})
		local icon = self:getItemIcon(itemId, awardData[itemId],index)
		icon:scale(0.7):anch(0, 0.5):pos(170 + (index-1) * 89, 51):addTo(boxBg)
		
		--加特效
		if index <= heroNum then
			self:frameActionOnSprite():scale(1.1):pos(icon:getContentSize().width/2,icon:getContentSize().height/2+2):addTo(icon)
		end
	end
	
	local getAwardBtn=DGBtn:new(FirstReChargeRes,{"get_normal.png","get_pressed.png"},
		{
			text={text=game.role.firstRechargeAwardState == 0 and "立即充值" or "领  取",size=28,font=ChineseFont,strokeSize=2,strokeColor=uihelper.hex2rgb("#242424") },
			priority=self.priority,
			callback=function()
				if game.role.firstRechargeAwardState == 0 then
					local layer = ReChargeLayer.new({priority = self.priority - 10,callback=function()
							self:initContentLayer()
						end})
					layer:getLayer():addTo(display.getRunningScene())
				elseif game.role.firstRechargeAwardState == 1 then
					local bin = pb.encode("SimpleEvent", { roleId = game.role.id})
					game:sendData(actionCodes.GiftRechargeAwardRequest, bin)
					loadingShow()
					game:addEventListener(actionModules[actionCodes.GiftRechargeAwardResponse], function(event)
						loadingHide()
						local giftShow = require("scenes.activity.GiftShowLayer")
						local showView = giftShow.new({ 
							priority = self.priority - 10 , 
							items = awardItems,
							callback = function()
							if self.callback then self.callback() end
							self.mask:remove()
						end
						})
						showView:getLayer():addTo(display.getRunningScene())

						return "__REMOVE__"
					end)

					game.role:addEventListener("ErrorCode" .. SYS_ERR_NOT_FIRST_RECHARGE_AWARD, function(event)
						loadingHide()
						DGMsgBox.new({ type = 1, text = "未达到领取条件!" })
						self.mask:remove()
						return "__REMOVE__"
					end)

					game.role:addEventListener("ErrorCode" .. SYS_ERR_HAVE_RECEIVE_FIRST_RECHARGE_AWARD, function(event)
						loadingHide()
						DGMsgBox.new({ type = 1, text = "已领取!" })
						self.callback()
						self.mask:remove()
						return "__REMOVE__"
					end)
				end
			end,
		}):getLayer()
	getAwardBtn:anch(0,0):pos(219.1,50):addTo(self.contentLayer)

	local particle = CCNodeExtend.extend(CCParticleSystemQuad:create(ParticleRes .. "firstRechargeParticle.plist"))
	particle:setPositionType(kCCPositionTypeRelative)
	particle:anch(0.5, 0.5):pos(250, 380):addTo(self.contentLayer)

end

--头像subview
function FirstRechargeLayer:getItemIcon(itemId,itemCount,index)
	local iData = nil

	iData = itemCsv:getItemById(tonumber(itemId))
	local frame = ItemIcon.new({ itemId = tonumber(itemId),
		parent = self.tableLayer, 
		priority = self.priority -1,
		callback = function()
			self:showItemTaps(itemId,itemCount,iData.type)
		end,
	}):getLayer()
	frame:setColor(ccc3(100, 100, 100))

	
	--数量
	local numLabe=ui.newTTFLabelWithShadow({ text = "x"..itemCount, size = 20, color = uihelper.hex2rgb("#ffd200")
		,strokeColor=uihelper.hex2rgb("#242424") ,strokeSize=2})
		:addTo(frame)
	numLabe:anch(0, 0):pos(78-numLabe:getContentSize().width+15,15)

	return frame
end 

function FirstRechargeLayer:ShowStar(parent)
	local xx,yy = parent:getContentSize().width,parent:getContentSize().height
	local posX , posY = 0 , 0 
	local pTable = {
		{x = 10, y = 25},
		{x = 30, y = 25},
		{x = 40, y = 30},
		{x = 20, y = 50},
		{x = 50, y = 40},
		{x = 10, y = 15},
		{x = 50, y = 55},
	}
	local star
	for i=1,3 do
		star = display.newSprite(ShopRes.."shop_star.png")
	:pos(20,20):addTo(parent)
		star:runAction(CCRepeatForever:create(transition.sequence({
		CCSpawn:createWithTwoActions(CCFadeIn:create(0.2), CCRotateBy:create(0.5, 40)),
		CCSpawn:createWithTwoActions(CCRotateBy:create(0.2, 40), CCFadeOut:create(0.2)),
		CCDelayTime:create(0.8 - i * 0.2),
		CCCallFunc:create(function() 
			local index = math.random(1,5)
			star:pos(pTable[index].x, pTable[index].y-30)
		end),
	})))
	end
end 

function FirstRechargeLayer:frameActionOnSprite()

	display.addSpriteFramesWithFile(FirstReChargeRes.."effect/hero_halo.plist", FirstReChargeRes.."effect/hero_halo.png")
	local framesTable = {}
	for index = 1, 5 do
		local frameId = string.format("%02d", index)
		framesTable[#framesTable + 1] = display.newSpriteFrame("hero_halo_" .. frameId .. ".png")
	end
	local panimate = display.newAnimation(framesTable, 1.0/10)
	local sprite = display.newSprite(framesTable[1])
	sprite:playAnimationForever(panimate)
	return sprite
end


function FirstRechargeLayer:showItemTaps(itemId,itemNum,itemType)
	self:purgeItemTaps()
	local itemTipsView = require("scenes.home.ItemTipsLayer")
	local itemTips = itemTipsView.new({ itemId = itemId, itemNum = itemNum, itemType = itemType })
	display.getRunningScene():addChild(itemTips:getLayer())
	itemTips:setTag(self.tipsTag)
end

function FirstRechargeLayer:purgeItemTaps()
	if display.getRunningScene():getChildByTag(self.tipsTag) then
		display.getRunningScene():getChildByTag(self.tipsTag):removeFromParent()
	end
end

function FirstRechargeLayer:getLayer()
	return self.mask:getLayer()
end

function FirstRechargeLayer:onEnter()
	print("***** FirstRechargeLayer onenter ******")
end
function FirstRechargeLayer:onCleanup()
end
function FirstRechargeLayer:onExit()
	
end

return FirstRechargeLayer