--累充
-- Author: yzm
-- Date: 2014-12-01 21:07:00
--
local GlobalRes = "resource/ui_rc/global/"
local FirstReChargeRes = "resource/ui_rc/activity/recharge/"
local ShopRes = "resource/ui_rc/shop/"
local ParticleRes = "resource/ui_rc/particle/"

local AccumulatedRechargeLayer = class("AccumulatedRechargeLayer", function() 
	return display.newLayer(FirstReChargeRes.."accu_rech_bg.jpg") 
end)

function AccumulatedRechargeLayer:ctor(params)
	self:setNodeEventEnabled(true)
	self.params = params or {}
	self.priority = params.priority or -129
	self.size = self:getContentSize()
	self.tipsTag=2014
	
	display.newSprite(FirstReChargeRes.."heroImg.png"):anch(1,0.5):pos(self.size.width,self.size.height/2):addTo(self)

	self:initData()
	self:initContentLayer()
end

function AccumulatedRechargeLayer:initData()
	self.giftDatas=ljczCsv:getAllData()

	local startAndEndTimeStr=game.role.activityTimeList[1].startAndEndTime

	local timeData=require("scenes.activity.ActiveMainLayer").getTimeTable(startAndEndTimeStr)

	local limitTime=timeData[1].month.."月"..timeData[1].day.."日00:01--"..timeData[2].month.."月"..(tonum(timeData[2].day)-1).."日23:59"

	local barBg=display.newSprite(FirstReChargeRes.."accu_rech_bar_bg.png"):pos(self.size.width/2,450):addTo(self)
	ui.newTTFLabel({align=display.CENTER,text="活动期间、累积充值达到相应条件，即可领取貂蝉碎片与情缘装备等好礼~赶快行动吧~",dimensions=CCSizeMake(451, 60),size=20,color=display.COLOR_WHITE})
		:pos(barBg:getContentSize().width/2-40,53):addTo(barBg)
	ui.newTTFLabelWithShadow({text=limitTime,size=26,color=display.COLOR_WHITE,strokeSize=2,strokeColor=uihelper.hex2rgb("#242424")})
		:anch(0.5,0.5):pos(barBg:getContentSize().width/2-215,103):addTo(barBg)

	self.tableSize=CCSize(558,363)
end

function AccumulatedRechargeLayer:initContentLayer()
	if self.tableView then
		self.tableView:removeSelf()
		self.tableView = nil
	end

	local handler = LuaEventHandler:create(function(fn, tbl, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(554, 155) --cell size
        elseif fn == "cellAtIndex" then
			if not a2 then
                a2 = CCTableViewCell:new()
                local cell = display.newNode()
                a2:addChild(cell, 0, 1)
            end
            local cell = nil
            if a2:getChildByTag(1) then
            	cell = tolua.cast(a2:getChildByTag(1), "CCNode")
            	cell:removeAllChildren()
            end

            self:creatGiftCell(cell, a1, flag)
            r = a2
        elseif fn == "numberOfCells" then
            r = table.nums(self.giftDatas)
        end
        return r
    end)

	local offset = 10

	local viewSize = CCSizeMake(self.tableSize.width, self.tableSize.height - offset)
	self.tableView = CCNodeExtend.extend(LuaTableView:createWithHandler(handler, viewSize))
    self.tableView:setBounceable(true)
    self.tableView:setTouchPriority(self.priority - 2)
    self.tableView:setPosition(CCPoint(41,0))
	self:addChild(self.tableView)

	-- 偏移
	local usedCount = 0
	local itemCount = #self.giftDatas
    for i=1, itemCount do
    	local record = self.giftDatas[i]
    	if game.role.rechargeGifts[record.id] == 1 then
			usedCount = usedCount + 1
		else
			break
		end
    end

    local offset = -155 * (itemCount - usedCount + 0.5) + viewSize.height
   	self.tableView:setBounceable(false)
	self.tableView:setContentOffset(ccp(0, offset), false)
	self.tableView:setBounceable(true)
end

function AccumulatedRechargeLayer:creatGiftCell(parentNode, cellIndex, flag)
	parentNode:removeAllChildren()

	local record = self.giftDatas[#self.giftDatas - cellIndex]
	
	local cellsp = display.newSprite(FirstReChargeRes.."item_bg.png")
	cellsp:anch(0.5, 0):pos(self.tableSize.width/2, 0):addTo(parentNode)
	display.newSprite(GlobalRes.."yuanbao.png"):pos(42,122):addTo(cellsp)

	local ww = cellsp:getContentSize().width
	local hh = cellsp:getContentSize().height
		
	--领取button
	local used = false
	used = game.role.rechargeGifts[record.id] == 1	

	--累充达到多少可领取：
	local needRechargeRMB = record.accumulatedRech
	
	local tempNode = display.newSprite():anch(0,0.5):pos(24,117):addTo(cellsp)
	tempNode:setContentSize(CCSizeMake(550, 46))
	local tipLabel = DGRichLabel.new({ size = 22, font = ChineseFont}):anch(0, 0.5)
		:pos(45, 27):addTo(tempNode)
	tipLabel:setString("累计充值[color=2cfe1c]"..tostring(needRechargeRMB).."[/color]元")

	ui.newTTFLabel({ text = game.role.rechargeRMB.."/"..needRechargeRMB, size = 20, color = uihelper.hex2rgb("#ffffff") })
		:anch(1, 0.5):pos(tempNode:getContentSize().width-50, 27):addTo(tempNode)

	local useBtn = DGBtn:new(GlobalRes, {"square_green_normal.png", "square_green_selected.png","square_disabled.png"}, 
	{
		text = {text = (used and "已领" or "领取"), size = 26, font = ChineseFont, color = display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2 },
		parent = self.tableView,
		callback = function()
			self.curOffSetY  = self.tableView:getContentOffset().y
			local useRequest = { roleId = game.role.id, param1 = record.id }
			local bin = pb.encode("SimpleEvent", useRequest)

			game:sendData(actionCodes.RoleGetAccumulatedRechargeGiftRequest, bin, #bin)
			loadingShow()
			game:addEventListener(actionModules[actionCodes.RoleGetAccumulatedRechargeGiftResponse], function(event)
				loadingHide()
				self.tableView:reloadData()
				self.tableView:setContentOffset(ccp(0, self.curOffSetY), false)

				-- TODO 添加领取成功后的界面
				local giftShow = require("scenes.activity.GiftShowLayer")
				local showView = giftShow.new({ 
					priority = self.priority - 10 , 
					items=record.awardItems,
				})
				showView:getLayer():addTo(display.getRunningScene())

				game.role:dispatchEvent({ name = "notifyNewMessage", type = "accumulatedRechargeState" })
				
				return "__REMOVE__"
			end)

			game.role:addEventListener("ErrorCode" .. SYS_ERR_ACCUMULATED_RECHARGE_OVER, function(event)
				loadingHide()
				DGMsgBox.new({ type = 1, text = "活动已结束!" })
				return "__REMOVE__"
			end)

			game.role:addEventListener("ErrorCode" .. SYS_ERR_ACCUMULATED_RECHARGE_GIFT_DONT_RECV, function(event)
				loadingHide()
				DGMsgBox.new({ type = 1, text = "未达到领取条件!" })
				return "__REMOVE__"
			end)

			game.role:addEventListener("ErrorCode" .. SYS_ERR_HAVE_RECEIVE_FIRST_RECHARGE_AWARD, function(event)
				loadingHide()
				DGMsgBox.new({ type = 1, text = "已领取!" })
				return "__REMOVE__"
			end)
		end,
		priority = self.priority - 2
	})
	useBtn:getLayer():anch(0.5, 0):pos(ww - 82, 19):addTo(cellsp)
	useBtn:setEnable(game.role.rechargeRMB >= needRechargeRMB and not used)

	--头像初始化：
	local itemTable = record.awardItems
	local iconCount = table.nums(itemTable)
	for i=1, iconCount do
		if iconCount < 5 then
			local itemId     = itemTable[i].itemId
			local itemCount  = itemTable[i].itemCount
			local icon = self:getItemIcon(itemId, itemCount, 2)
			icon:scale(0.8):anch(0, 0.5):pos(20 + (i - 1) * 95, hh * 0.4):addTo(cellsp)
		end
	end
end

--头像subview
function AccumulatedRechargeLayer:getItemIcon(itemId,itemCount,itemType)
	local iData = nil
	local haveNum
	local xx = self.size.width * 0.25
	local yy = self.size.height * 0.81

	iData = itemCsv:getItemById(tonumber(itemId))
	local frame = ItemIcon.new({ itemId = tonumber(itemId),
		parent = self, 
		priority = self.priority -1,
		callback = function()
			self:showItemTaps(itemId,itemCount,iData.type)
		end,
	}):getLayer()
	frame:setColor(ccc3(100, 100, 100))

	--数量
	ui.newTTFLabel({ text = "x"..itemCount, size = 20, color = display.COLOR_GREEN })
		:anch(1, 0):pos(frame:getContentSize().width - 5, frame:getContentSize().height * 0.05)
		:addTo(frame)

	return frame
end 

function AccumulatedRechargeLayer:showItemTaps(itemId,itemNum,itemType)
	self:purgeItemTaps()
	local itemTipsView = require("scenes.home.ItemTipsLayer")
	local itemTips = itemTipsView.new({ itemId = itemId, itemNum = itemNum, itemType = itemType })
	display.getRunningScene():addChild(itemTips:getLayer())
	itemTips:setTag(self.tipsTag)
end

function AccumulatedRechargeLayer:purgeItemTaps()
	if display.getRunningScene():getChildByTag(self.tipsTag) then
		display.getRunningScene():getChildByTag(self.tipsTag):removeFromParent()
	end
end

function AccumulatedRechargeLayer:getLayer()
	return self.mask:getLayer()
end

function AccumulatedRechargeLayer:onEnter()
	
end

function AccumulatedRechargeLayer:onExit()
end

return AccumulatedRechargeLayer