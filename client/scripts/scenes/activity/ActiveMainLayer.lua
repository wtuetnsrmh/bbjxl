local ChickenRes = "resource/ui_rc/activity/chicken/"
local GlobalRes = "resource/ui_rc/global/"
local ActivityRes = "resource/ui_rc/activity/"
local ActivityVIPRes = "resource/ui_rc/activity/vip/"
local FirstReChargeRes = "resource/ui_rc/activity/recharge/"
local GodHeroRes = "resource/ui_rc/activity/god_hero/"
local json = require("framework.json")

local EatChickenLayer = import(".EatChickenLayer") 
local AccumulatedRechargeLayer = import(".AccumulatedRechargeLayer") 
local vipGiftLayer = import(".VipGiftLayer") 
local FundLayer = import(".FundLayer")
local GodHeroLayer = import(".GodHeroLayer")  

local ActiveMainLayer = class("ActiveMainLayer", function()
	return display.newLayer(ChickenRes .. "left.png")
end)


local activeList = {
	[1] = {
			id = 0,name = "chicken", class = EatChickenLayer, notifyType = "eatChicken",listener = "chickListen", limitTime = false,icoPath = ChickenRes,icoImage = "chicken_icon.png",
			func = function(self) 
				self:showContentLayer("chicken")
			end				
		  },
	[2] = {
			-- id 对应activelist.csv表中的id 无时间限制的活动为0
			id = 1,name = "rechargeAward", class = AccumulatedRechargeLayer, notifyType = "accumulatedRechargeState",listener = "accumulatedListen", limitTime = true,icoPath = FirstReChargeRes,icoImage = "accumulatedIco.png",
			func = function(self) 
				self:showContentLayer("rechargeAward")
			end				
		  },
	[3] = {
			id = 0,name = "vipGift", class = vipGiftLayer, notifyType = "null",listener = "null", limitTime = false,icoPath = ActivityVIPRes,icoImage = "vip_ico.png",
			func = function(self) 
				self:showContentLayer("vipGift")
			end				
		  },
	-- [3] = {
	-- 		id = 0,name = "fund", class = FundLayer, notifyType = "fund", listener = "fund", limitTime = false, icoPath = ActivityRes, icoImage = "fund/fund_icon.png",
	-- 		func = function(self) 
	-- 			self:showContentLayer("fund")
	-- 		end				
	-- 	  },
	[4] = {
			-- id 对应activelist.csv表中的id 无时间限制的活动为0
			id = 2, name = "godHero", class = GodHeroLayer, notifyType = "godHero",listener = "godHeroListen", limitTime = true, icoPath = GodHeroRes,icoImage = "godHero_icon.png",
			func = function(self) 
				self:showContentLayer("godHero")
			end				
		  },
}

function ActiveMainLayer:ctor(params)
	params = params or {}
	self.priority = params.priority or -129
	self.size = self:getContentSize()

	self:anch(0.5, 0):pos(display.cx, 20)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1,bg = HomeRes .. "home.jpg"})

	--右半部分：
	local rightCorver = display.newSprite(ChickenRes.."right.png")
	:anch(1,0.5):pos(self.size.width,self.size.height/2):addTo(self,2)

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"}, {
			touchScale = 1.5,
			priority = self.priority - 5,
			callback = function()
				self:getLayer():removeFromParent()
			end
		}):getLayer()
	closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height + 20):addTo(self,100)

	self:initData()
	
	display.newSprite(ActivityRes .. "bg_frame.png")
	:pos(self.size.width / 2,self.size.height / 2 + 25):addTo(self,2)

	self.mainSize = CCSizeMake(800 ,554)
	self.mainLayer = display.newLayer()
	self.mainLayer:size(self.mainSize):pos(0, 0):addTo(self,1)

	local layer = EatChickenLayer.new({priority = self.priority})
	self.mainLayer:addChild(layer)
	self.activityName = "chicken"
	
end

function ActiveMainLayer:initData()
	if not self.timeListener then
		self.timeListener = game.role:addEventListener("ActivityTimeListRefresh", function(event)
			self:initContentLayer()
		end)
	end
	self:initContentLayer()
end

function ActiveMainLayer:prepareData()
	self.filterData = {}
	for index,data in ipairs(activeList) do
		if data.limitTime then
			if ActiveMainLayer.inLimitTime(data.id,game:nowTime()) then
				self.filterData[#self.filterData+1] = data
			end
		else
			self.filterData[#self.filterData+1] = data
		end
	end
end

function ActiveMainLayer:initContentLayer()
	if self.mianSp then
		self.tableView:removeSelf()
		self.tableView=nil
		self.mianSp:removeSelf()
		self.mianSp=nil
	end
	self.mianSp = display.newSprite()
	:pos(self.size.width / 2,self.size.height / 2 + 25):addTo(self,3)
	self.mianSp:setContentSize(CCSize(1009,619))

	local titleBg = display.newSprite(ChickenRes .. "title.png")
	titleBg:pos(self.mianSp:getContentSize().width/2, self.mianSp:getContentSize().height -50):addTo(self.mianSp)

	self:prepareData()

	self.selectedIndex = self.selectedIndex or #self.filterData - 1

	local handler = LuaEventHandler:create(function(fn, tbl, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(115, 115) --cell size
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

            self:creatCell(cell, a1)
            r = a2
        elseif fn == "numberOfCells" then
            r = table.nums(self.filterData)
        end
        return r
    end)

	local viewSize = CCSizeMake(129,464)
	self.tableView = CCNodeExtend.extend(LuaTableView:createWithHandler(handler, viewSize))
    self.tableView:setBounceable(true)
    self.tableView:setTouchPriority(self.priority - 51)
    self.tableView:setPosition(CCPoint(830,49))
	self.mianSp:addChild(self.tableView)

end

function ActiveMainLayer:creatCell(parentNode, cellIndex)
	local cellSize = CCSize(130,130)

	parentNode:removeAllChildren()

	local curData = self.filterData[#self.filterData - cellIndex]

	if self.selectedIndex == cellIndex then
		local lightFrame = display.newSprite(FirstReChargeRes.."lightFrame.png")
			:anch(0.5,0.5):pos(cellSize.width/2,cellSize.height/2):addTo(parentNode,1,10000)
	end

	local icoBtn = self:getIcon(curData.icoPath,{curData.icoImage},
		{	
			priority = self.priority - 50,
			callback = function()
				curData.func(self)
				self.selectedIndex = cellIndex
				self.offset = self.tableView:getContentOffset().y
				self.tableView:reloadData()

				self.tableView:setBounceable(false)
				self.tableView:setContentOffset(ccp(0, self.offset or 0), false)
				self.tableView:setBounceable(true)
			end
		})
	icoBtn:anch(0.5,0.5):pos(cellSize.width/2,cellSize.height/2):addTo(parentNode)

	
	if curData.notifyType ~= "null" then
		local tagNode=display.newNode()
		tagNode:setContentSize(CCSize(94,94))
		tagNode:anch(0.5,0.5):pos(cellSize.width/2,cellSize.height/2):addTo(parentNode,21)

		if self[curData.listener] then
			game.role:removeEventListener("notifyNewMessage", self[curData.listener])
		end
			
		self[curData.listener] = game.role:addEventListener("notifyNewMessage", function(event)
			if event.type == curData.notifyType then
				tagNode:removeChildByTag(9999)
				if event.action == "add" then
					uihelper.newMsgTag(tagNode, ccp(94 - 25, 0))
				end
			end
		end)
	end
	
end

function ActiveMainLayer.getTimeTable(timeStr)
	local t = {}
	if timeStr ~= nil then
		local temp = string.split(timeStr, " ")
		for i=1,table.nums(temp) do
			local st = string.split(tostring(temp[i]), "=") 
			t[i] = {}
			t[i]["year"]    = st[1]
			t[i]["month"] = st[2]
			t[i]["day"] = st[3]
		end
	end
	return t
end

function ActiveMainLayer.inLimitTime(activityId, time)
	if not game.role.activityTimeList then return false end
	local startAndEndTimeStr=game.role.activityTimeList[activityId].startAndEndTime
	local timeData=ActiveMainLayer.getTimeTable(startAndEndTimeStr)
	if #timeData==0 then return false end
	local startTime=os.time{year=timeData[1].year, month=timeData[1].month, day=timeData[1].day, hour=0, min=0, sec=0}
	local endTime=os.time{year=timeData[2].year, month=timeData[2].month, day=timeData[2].day , hour=0, min=0, sec=0}
	if tonum(time)>startTime and tonum(time)<endTime then
		return true
	end

	return false
end

function ActiveMainLayer:showContentLayer(name,update)
	update = update or false
	if self.activityName == name and not update then
		return
	end

	self.mainLayer:removeAllChildren()
	self.activityName = name

	for _,curData in ipairs(self.filterData) do
		if curData.name == name then
			local layer = curData.class.new( { priority = self.priority, parent = self } )
			self.mainLayer:addChild(layer)
		end
		
	end

end

function ActiveMainLayer:showOthers()
	self.mainLayer:removeAllChildren()
end

function ActiveMainLayer:getIcon(path,file,params)
	local iconBtn = DGBtn:new(path,file,params):getLayer()
	display.newSprite(GlobalRes.."item_5.png")
	:pos(iconBtn:getContentSize().width/2,iconBtn:getContentSize().height/2)
	:addTo(iconBtn)
	return iconBtn
end

function ActiveMainLayer:onCleanup()
	for _,curData in ipairs(self.filterData) do
		if curData.notifyType ~= "null" then
			game.role:removeEventListener("notifyNewMessage", self[curData.listener])
		end
	end

	if self.timeListener then
		game.role:removeEventListener("ActivityTimeListRefresh", self.timeListener)
	end
end

function ActiveMainLayer:getLayer()
	return self.mask:getLayer()
end

return ActiveMainLayer