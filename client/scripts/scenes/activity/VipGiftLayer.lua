--vip
-- Author: yzm
-- Date: 2014-12-01 21:07:00
--
local GlobalRes = "resource/ui_rc/global/"
local ActivityVIPRes = "resource/ui_rc/activity/vip/"
local FirstReChargeRes = "resource/ui_rc/activity/recharge/"
local ShopRes = "resource/ui_rc/shop/"
local ParticleRes = "resource/ui_rc/particle/"

local ShopMainLayer = require("scenes.home.shop.ShopMainLayer")

local VipGiftLayer = class("VipGiftLayer", function() 
	return display.newLayer(FirstReChargeRes.."accu_rech_bg.jpg") 
end)

function VipGiftLayer:ctor(params)
	self:setNodeEventEnabled(true)
	self.params = params or {}
	self.priority = params.priority or -129
	self.size = self:getContentSize()
	self.tipsTag=2014

	display.newSprite(ActivityVIPRes.."heroImg.png"):anch(1,0.5):pos(self.size.width,self.size.height/2):addTo(self)
	
	self:initData()
	self:initContentLayer()
end

function VipGiftLayer:initData()
	self.titleTip={
		[1]={
			vip = 7,
			frag = 30,
			price = 488,
		},
		[2]={
			vip = 9,
			frag = 50,
			price = 988,
		},
		[3]={
			vip = 12,
			frag = 100,
			price = 2888,
		},
		[4]={
			vip = 15,
			frag = 150,
			price = 8888,
		},
	}
	local vipItemsId={5007,5009,5012,5015}
	self.giftDatas = { }
	for _,vipItemId in ipairs(vipItemsId) do
		local itemsData=itemCsv:getItemById(vipItemId).itemInclude
		local awardItems={}
		for itemId,itemCount in pairs(itemsData) do
			table.insert(awardItems,{ itemId = itemId, itemCount = itemCount })
		end
		table.insert(self.giftDatas,{ awardItems = awardItems })
	end

	local barBg=display.newSprite(FirstReChargeRes.."accu_rech_bar_bg.png"):pos(self.size.width/2,450):addTo(self)
	ui.newTTFLabel({align=display.CENTER,text="VIP礼包限购放送！每提升一次VIP，即可购买相应礼包，内有极品装备，更能获得五星绝世神将-赵去！"
		,dimensions=CCSizeMake(481, 60),size=20,color=display.COLOR_WHITE})
		:pos(barBg:getContentSize().width/2-40,100):addTo(barBg)

	local gotoBtn = DGBtn:new(GlobalRes, {"btn_ellipse_normal.png", "btn_ellipse_selected.png"}, {
		priority = self.priority - 2,
		text = {text = "前 往", size = 26, font = ChineseFont, strokeColor = display.COLOR_FONT},
		callback = function()
			local layer = ShopMainLayer.new({ chooseIndex = 3,priority = self.priority-60})
			layer:getLayer():addTo(display.getRunningScene())
		end,
		}):getLayer()
	gotoBtn:anch(0.4, 0):pos(barBg:getContentSize().width/2-40, 15):addTo(barBg)

	self.tableSize=CCSize(558,363)
end

function VipGiftLayer:initContentLayer()
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

    local offset = -155 * (#self.giftDatas + 0.5) + viewSize.height
   	self.tableView:setBounceable(false)
	self.tableView:setContentOffset(ccp(0, offset), false)
	self.tableView:setBounceable(true)
end

function VipGiftLayer:creatGiftCell(parentNode, cellIndex, flag)
	parentNode:removeAllChildren()

	local nativeIndex = #self.giftDatas - cellIndex
	local record = self.giftDatas[nativeIndex]
	
	local cellsp = display.newSprite(FirstReChargeRes.."item_bg.png")
	cellsp:anch(0.5, 0):pos(self.tableSize.width/2, 0):addTo(parentNode)
	display.newSprite(GlobalRes.."yuanbao.png"):pos(460,122):addTo(cellsp)

	local content ="[color=fff2e3cb]达到VIP"..self.titleTip[nativeIndex].vip..",购买宝箱可得[color=fff38820]"..self.titleTip[nativeIndex].frag.."个赵云碎片[/color][/color]"
	local title = ui.newTTFRichLabel({align =ui.TEXT_ALIGN_LEFT, text = content, size = 22, font = ChineseFont  })
		:anch(0,0.5):pos(24,122):addTo(cellsp)

	local priceLabe = ui.newTTFLabel({text=self.titleTip[nativeIndex].price, size=20, color = uihelper.hex2rgb("#f2e3cb")})
		:anch(0,0.5):pos(485,122):addTo(cellsp)

	local ww = cellsp:getContentSize().width
	local hh = cellsp:getContentSize().height
		
	
	--头像初始化：
	local itemTable = record.awardItems
	table.sort(itemTable,function(a,b) return a.itemId < b.itemId end)
	local iconCount = table.nums(itemTable)
	for i=1, iconCount do
		if iconCount < 6 then
			local itemId     = itemTable[i].itemId
			local itemCount  = itemTable[i].itemCount
			local icon = self:getItemIcon(itemId, itemCount, 2)
			icon:scale(0.8):anch(0, 0.5):pos(35 + (i - 1) * 100, hh * 0.4):addTo(cellsp)
		end
	end
end

--头像subview
function VipGiftLayer:getItemIcon(itemId,itemCount,itemType)
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

	if iData.type == ItemTypeId.HeroFragment then
		self:frameActionOnSprite():scale(1.1):pos(frame:getContentSize().width/2,frame:getContentSize().height/2+2):addTo(frame)
	end
	
	--数量
	ui.newTTFLabel({ text = "x"..itemCount, size = 20, color = display.COLOR_GREEN })
		:anch(1, 0):pos(frame:getContentSize().width - 5, frame:getContentSize().height * 0.05)
		:addTo(frame)

	return frame
end 

function VipGiftLayer:frameActionOnSprite()

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

function VipGiftLayer:showItemTaps(itemId,itemNum,itemType)
	self:purgeItemTaps()
	local itemTipsView = require("scenes.home.ItemTipsLayer")
	local itemTips = itemTipsView.new({ itemId = itemId, itemNum = itemNum, itemType = itemType })
	display.getRunningScene():addChild(itemTips:getLayer())
	itemTips:setTag(self.tipsTag)
end

function VipGiftLayer:purgeItemTaps()
	if display.getRunningScene():getChildByTag(self.tipsTag) then
		display.getRunningScene():getChildByTag(self.tipsTag):removeFromParent()
	end
end

function VipGiftLayer:getLayer()
	return self.mask:getLayer()
end

function VipGiftLayer:onEnter()
	
end

function VipGiftLayer:onExit()
end

return VipGiftLayer