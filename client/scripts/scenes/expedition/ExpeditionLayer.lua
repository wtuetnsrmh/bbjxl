--
-- Author: yzm
-- Date: 2014-10-13 11:37:30
--
local HomeRes = "resource/ui_rc/home/"
local HeroRes = "resource/ui_rc/hero/"
local ExpeditonRes = "resource/ui_rc/expedition/"
local GlobalRes = "resource/ui_rc/global/"

local ConfirmDialog = require("scenes.ConfirmDialog")
local TopBarLayer = require("scenes.TopBarLayer")
local RuleTipsLayer = import("..RuleTipsLayer")

local ExpeditionAwardLayer = import(".ExpeditionAwardLayer")
local PlayerInfor=import(".PlayerInfor")

local ExpeditionLayer = class("ExpeditionLayer", function(params) return display.newLayer() end)

m_YZHeroDtl={
	heroId = 1,
	level=1,
	evolutionCount=1,
	skillLevelJson="",
	wakeLevel=1,
	star = 1,
	blood=100,
	slot=1,
}

m_YZFighter={
	name="",
	level=1,
	id=1,-- 1-15
	angryCD=1,-- 这里的值=怒气值*10
	heroList={},
}

BUILDING_POS={
	[1]={x=101,y=161.4},[2]={x=248.05,y=40.4},[3]={x=253.05,y=284.45},
	[4]={x=395.05,y=114.7},[5]={x=590.1,y=105.7},[6]={x=479.6,y=324.75},
	[7]={x=691.65,y=340},[8]={x=707.65,y=231.7},[9]={x=783.65,y=89.65},
	[10]={x=987.7,y=120.65},[11]={x=1080.75,y=199.7},[12]={x=1105.75,y=348.7},
	[13]={x=1204.8,y=127.65},[14]={x=1408.85,y=109.75},[15]={x=1432,y=310},
}

AWARD_BOX_POS={
	[1]={x=167,y=60.75},[2]={x=239,y=216.8},[3]={x=387.05,y=216.8},
	[4]={x=559.1,y=27.75},[5]={x=484.05,y=233.8},[6]={x=604.1,y=370.85},
	[7]={x=831.15,y=316.8},[8]={x=719.15,y=160.75},[9]={x=918.15,y=166.75},
	[10]={x=1135.75,y=99.7},[11]={x=1060.75,y=301.75},[12]={x=1221.8,y=287.75},
	[13]={x=1346.8,y=53.7},[14]={x=1485.85,y=231.7},[15]={x=1545,y=397},
}

function ExpeditionLayer:ctor(params)
	params = params or {}

	self.closemode = params.closemode or 1

	self.autoPopAward=params.autoPopAward or false

	self.curMaps = {}--当前关卡武将信息

	self.curMapId = params.curMapId or 1--当前关卡ID

	self.totalMaps = {}--所有关上ID
	self.priority = params.priority or -130
	self.mask = DGMask:new({ item = self, priority = self.priority + 1, bg = HomeRes .. "home.jpg" })
	
	local layer  = TopBarLayer.new({priority = self.priority})
	layer:anch(0,1):pos(0,display.height):addTo(self)

	self.initData=game.role.expeditionData or {}

	self.battleEnd=params.battleEnd or true

	--判断是否是战斗结束后场景切过来
	if self.battleEnd then
		self:prepareData()
	else
		self:initFirstData()
	end
	

	self:initUI()
end

function ExpeditionLayer:initFirstData()
	local totalMaps={}
		for _,fighter in ipairs(self.initData.fightList) do
			local map={heroList={}}
			map.name=fighter.name
			map.level=fighter.level
			map.id=fighter.id
			map.beauties=fighter.beauties or {}
			map.angryCD=tonumber(fighter.angryCD)/10  --服务端过来的是*10

			for _,hero in ipairs(fighter.heroList) do
				local heroInfo={}
				heroInfo.heroId=hero.id
				heroInfo.level=hero.level
				heroInfo.evolutionCount=hero.evolutionCount
				heroInfo.skillLevelJson=hero.skillLevelJson
				heroInfo.wakeLevel=hero.wakeLevel
				heroInfo.star = hero.star
				heroInfo.blood=hero.blood
				heroInfo.slot=hero.slot
				heroInfo.attrsJson=hero.attrsJson or {}
				table.insert(map.heroList,heroInfo)
			end

			totalMaps[map.id]=map
			self.totalMaps=totalMaps

		end


		self.curMapId=#totalMaps --返回当前关

		self.curMaps =self.totalMaps[self.curMapId]

		self.drawStatus=self.initData.drawStatus

		self.leftCnt=self.initData.leftCnt or 0

		self:initContentLayer()
end

function ExpeditionLayer:initUI()

	self:initTopBottonBarLayer()
end

-- 顶底栏
function ExpeditionLayer:initTopBottonBarLayer()
	if self.topbarLayer then
		self.topbarLayer:removeSelf()
	end

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
				switchScene("home")
			end,
		}):getLayer()
	closeBtn:anch(1, 1):pos(display.width,display.height):addTo(self:getLayer(),100)

end


function ExpeditionLayer:prepareData()	

	local bin=pb.encode("SimpleEvent",{})
	game:sendData(actionCodes.ExpeditionRequest, bin)
	loadingShow()
	game:addEventListener(actionModules[actionCodes.ExpeditionResponse], function(event)
		local msg=pb.decode("ExpeditionResponse",event.data)

		loadingHide()

		local totalMaps={}

		for _,fighter in ipairs(msg.fightList) do
			local map={heroList={}}
			map.name=fighter.name
			map.level=fighter.level
			map.id=fighter.id
			map.passiveSkills=fighter.passiveSkills or {}
			map.beauties=fighter.beauties or {}
			map.angryCD=tonumber(fighter.angryCD)/10  --服务端过来的是*10

			for _,hero in ipairs(fighter.heroList) do
				local heroInfo={}
				heroInfo.heroId=hero.id
				heroInfo.level=hero.level
				heroInfo.evolutionCount=hero.evolutionCount
				heroInfo.skillLevelJson=hero.skillLevelJson
				heroInfo.wakeLevel=hero.wakeLevel
				heroInfo.star = hero.star
				heroInfo.blood=hero.blood
				heroInfo.slot=hero.slot
				heroInfo.attrsJson=hero.attrsJson or {}
				table.insert(map.heroList,heroInfo)
			end

			totalMaps[map.id]=map
			self.totalMaps=totalMaps

		end

		self.curMapId=#totalMaps --返回当前关

		self.curMaps =self.totalMaps[self.curMapId]

		self.drawStatus=msg.drawStatus

		self.leftCnt=msg.leftCnt or 0
		
		self:setTouchEnabled(true)

		self:initContentLayer()

		return "__REMOVE__"
	end)

end

-- 滑动层
function ExpeditionLayer:initContentLayer()
	if self.layer then
		self.layer:removeSelf()

		self.awardLayer=nil
		self.arraw=nil
	end

	self.contentLayer = display.newLayer(ExpeditonRes .. "bg.png")
	self.contentSize=self.contentLayer:getContentSize()
	self.contentLayer:anch(0,0):pos(0,0)

	self.BUILDING_INDEX=1

	self:getLayer():setTouchEnabled(true)
	self:getLayer():addTouchEventListener(function(event, x, y) return self:onTouch(event, x, y) end, false, self.priority)

	self.totalPassBtn={}
	for i=1,15 do
		local cell=self:createCarbonCell(i)
		cell:pos(BUILDING_POS[i].x,BUILDING_POS[i].y):addTo(self.contentLayer,self.BUILDING_INDEX+1)
	end

	local maskSize=CCSize(843,478)

	self.maxLimit=self.contentSize.width-maskSize.width
	self.moveLimit=0

	--设置当前所在关的箭头提示
	if self.curMapId>0 then

		--if not self:allDead() then
			self.arraw=display.newSprite(ExpeditonRes.."arrow.png"):anch(0.5,0)
				:pos(BUILDING_POS[self.curMapId].x+55,BUILDING_POS[self.curMapId].y+55)
				:addTo(self.contentLayer,1000)
			self.arraw:runAction(CCRepeatForever:create(transition.sequence({
							CCMoveBy:create(0.5, ccp(0, 20)),
							CCMoveBy:create(0.5, ccp(0, -20))
						})))
		--end
		

		--云
		local offsetY=100
		self.cloudLayer=display.newSprite(ExpeditonRes.."cloud.png")
		self.cloudLayer:anch(0,0):pos(BUILDING_POS[self.curMapId].x+offsetY,0):addTo(self.contentLayer,self.BUILDING_INDEX+10)

		
		local moveLimit=self.cloudLayer:getPositionX()+self.cloudLayer:getContentSize().width-maskSize.width
		moveLimit=moveLimit>self.maxLimit and self.maxLimit or moveLimit
		self.moveLimit=moveLimit

		--地图移到当前关
		local initOffsetX=200
		local moveOffsetX=BUILDING_POS[self.curMapId].x-initOffsetX
		moveOffsetX=moveOffsetX>self.moveLimit and self.moveLimit or moveOffsetX
		moveOffsetX=moveOffsetX<0 and 0 or moveOffsetX
		self.contentLayer:setPositionX(-moveOffsetX)
	end
	
	self:updataAwardBox()

	

	--滚动窗口位置与大小设置，超出此窗口的部分都将隐藏	
	self.baseLayer = CCClippingLayer:create()
	self.baseLayer:setContentSize(CCSizeMake(maskSize.width,maskSize.height))
	self.baseLayer:addChild(self.contentLayer,self.BUILDING_INDEX)
	self.baseLayer:setPosition(CCPoint(58,46))

	self.layer = display.newLayer()
	self.layer:size(960,583)
	display.newSprite(ExpeditonRes .. "box_bg.png"):anch(0,0):pos(53,40):addTo(self.layer)
	self.layer:addChild(self.baseLayer)
	self.layer:anch(0.5,0):pos(display.cx,0)
	self:getLayer():addChild(self.layer)
	display.newSprite(ExpeditonRes.."topBar.png"):anch(0,0):pos(0,0):addTo(self.layer)

	--下面按钮
	self:initBottonUI()

	--如果第一次进来则自动请求生成数据
	if #self.totalMaps==0 then
		local count=0
		local bin=pb.encode("SimpleEvent",{})
		game:sendData(actionCodes.ExpeditionRestartReq, bin)
		loadingShow()
		game:addEventListener(actionModules[actionCodes.ExpeditionRestartRes], function(event)
			count=count+1
			local msg=pb.decode("ExpeditionResponse",event.data)
			loadingHide()
			
			if msg.errCode~=0 then
				if msg.errCode==SYS_ERR_YZ_LEFT_COUNT then
					DGMsgBox.new({text = "剩余次数不足!", type = 1})
					return "__REMOVE__"
				elseif msg.errCode==SYS_ERR_UNKNOWN then
					print("msg.errCode="..msg.errCode)
					DGMsgBox.new({text = "错误码："..msg.errCode, type = 1})
					return "__REMOVE__"
				end
				
			else
				self:starInitData(msg)
				
				return "__REMOVE__"
			end

		end)
	end

end

function ExpeditionLayer:starInitData(msg)
	local totalMaps={}

	for _,fighter in ipairs(msg.fightList) do
		local map={heroList={}}
		map.name=fighter.name
		map.level=fighter.level
		map.id=fighter.id
		map.passiveSkills=fighter.passiveSkills or {}
		map.beauties=fighter.beauties or {}
		map.angryCD=tonumber(fighter.angryCD)/10  --服务端过来的是*10

		for _,hero in ipairs(fighter.heroList) do
			local heroInfo={}
			heroInfo.heroId=hero.id
			heroInfo.level=hero.level
			heroInfo.evolutionCount=hero.evolutionCount
			heroInfo.skillLevelJson=hero.skillLevelJson
			heroInfo.wakeLevel=hero.wakeLevel
			heroInfo.star = hero.star
			heroInfo.blood=hero.blood
			heroInfo.slot=hero.slot
			heroInfo.attrsJson=hero.attrsJson or {}
			table.insert(map.heroList,heroInfo)
		end

		totalMaps[map.id]=map
		self.totalMaps=totalMaps

	end

	self.curMapId=#totalMaps --返回当前关

	self.curMaps =self.totalMaps[self.curMapId]

	self.drawStatus=msg.drawStatus

	self.leftCnt=msg.leftCnt or 0
	
	self:setTouchEnabled(true)

	self:initContentLayer()
end

function ExpeditionLayer:initBottonUI()
	if self.buttomLayer then
		self.buttomLayer:removeSelf()
		self.buttomLayer=nil
	end

	self.buttomLayer=display.newLayer():anch(0.5,0):pos(display.cx,30):addTo(self:getLayer(),101)
	local buttonBg=display.newSprite(ExpeditonRes.."bottomBG.png"):anch(0.5,0.5):pos(display.cx,10):addTo(self.buttomLayer)

	--查看规则
	local ruleBtn = DGBtn:new(ExpeditonRes, {"btn_bg.png"},
			{
				priority = self.priority - 2,
				touchScale = { 2, 1 },
				scale=0.9,
				text = { text = "查看规则" , size = 26, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
				callback = function()
					--TODO
					local ruleLayer = RuleTipsLayer.new({ priority = self.priority - 100, 
						file = "txt/function/zzsf_rule.txt",
					})
					ruleLayer:getLayer():addTo(display.getRunningScene())	
				end
			}):getLayer()
	ruleBtn:anch(0.5,0.5):pos(89,40):addTo(buttonBg)

	--声望商店
	local shopBtn = DGBtn:new(ExpeditonRes, {"btn_bg.png"},
			{
				priority = self.priority - 2,
				scale=0.9,
				text = { text = "声望商店" , size = 26, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
				callback = function()
					local PvpShopLayer = require("scenes.pvp.PvpShopLayer")
					local layer = PvpShopLayer.new({priority = self.priority - 1, shopIndex = 6})
					layer:getLayer():addTo(display.getRunningScene())				
				end
			}):getLayer()
	shopBtn:anch(0.5,0.5):pos(272,40):addTo(buttonBg)

	local shopIco=display.newSprite(ExpeditonRes.."prestige.png"):anch(0,0.5):pos(-5,30):addTo(shopBtn)

	local countLabelTip=ui.newTTFLabel({text="今日剩余次数：",size=22,color=display.COLOR_WHITE})
		:anch(0,0):pos(402,25):addTo(buttonBg)
	local countLabel=ui.newTTFLabel({text=self.leftCnt,size=22,color=uihelper.hex2rgb("#2ce41e")})
		:anch(0,0):pos(countLabelTip:getPositionX()+countLabelTip:getContentSize().width,25):addTo(buttonBg)

	--重新开始
	local resetBtn = DGBtn:new(ExpeditonRes, {"btn_bg.png"},
			{
				priority = self.priority - 2,
				scale=0.9,
				text = { text = "重新开始" , size = 26, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
				callback = function()
					local confirmDialog = ConfirmDialog.new({
						priority = self.priority - 10,
						showText = { text = "是否重新开始?", size = 24, font = ChineseFont, color = display.COLOR_YELLOW },
						button2Data = {
							callback = function()
								local count=1
								local bin=pb.encode("SimpleEvent",{})
								game:sendData(actionCodes.ExpeditionRestartReq, bin)
								loadingShow()
								game:addEventListener(actionModules[actionCodes.ExpeditionRestartRes], function(event)
									count=count+1
									local msg=pb.decode("ExpeditionResponse",event.data)
									loadingHide()
									
									if msg.errCode~=0 then
										if msg.errCode==SYS_ERR_YZ_LEFT_COUNT then
											DGMsgBox.new({text = "剩余次数不足!", type = 1})
											return "__REMOVE__"
										elseif msg.errCode==SYS_ERR_UNKNOWN then
											--DGMsgBox.new({text = "错误码："..msg.errCode, type = 1})
											print("msg.errCode="..msg.errCode)
											DGMsgBox.new({text = "错误码："..msg.errCode, type = 1})
											return "__REMOVE__"
										end
										
									else
										self:starInitData(msg)
										return "__REMOVE__"
									end
									
								end)
							end,
						}
					})
					confirmDialog:getLayer():addTo(display.getRunningScene())

				end
			}):getLayer()
	resetBtn:anch(0.5,0.5):pos(667,40):addTo(buttonBg)
end

function ExpeditionLayer:updataAwardBox()
	--宝箱
	if self.awardLayer then
		self.awardLayer:removeSelf()
		self.awardLayer=nil
	end

	self.awardLayer=display.newLayer()
	self.awardLayer:addTo(self.contentLayer,self.BUILDING_INDEX+1)

	for i,award in ipairs(self.drawStatus) do
		local awardCell=self:createBoxCell(i,award):pos(AWARD_BOX_POS[i].x,AWARD_BOX_POS[i].y):addTo(self.awardLayer,1,i)
	end

	--如果当前关的上一个宝箱没领取则不开放，箭头定位到上一个宝箱
	if self.curMapId>1 and self.drawStatus[self.curMapId-1]==1 then
		local grayShadeProgram = UIUtil:shaderForKey("ShaderPositionTextureGray")
		self.totalPassBtn[self.curMapId].item[1]:setShaderProgram(grayShadeProgram)
		self.totalPassBtn[self.curMapId].item[2]:setShaderProgram(grayShadeProgram)
		self.totalPassBtn[self.curMapId]:getLayer():setTouchEnabled(false)
		
		if self.arraw then
			self.arraw:pos(AWARD_BOX_POS[self.curMapId-1].x+25,AWARD_BOX_POS[self.curMapId-1].y+22)
		end
	else
		if self.arraw then
			if self.curMapId==#AWARD_BOX_POS and self:allDead() then
				--最后一关过了定位到最后一个宝箱
				if self.drawStatus[self.curMapId]==1 then
					self.arraw:pos(AWARD_BOX_POS[self.curMapId].x+25,AWARD_BOX_POS[self.curMapId].y+22)
				else
					self.arraw:removeSelf()
				end
				
			else
				self.arraw:stopAllActions()
				self.arraw:pos(BUILDING_POS[self.curMapId].x+55,BUILDING_POS[self.curMapId].y+55)
				self.arraw:runAction(CCRepeatForever:create(transition.sequence({
							CCMoveBy:create(0.5, ccp(0, 20)),
							CCMoveBy:create(0.5, ccp(0, -20))
						})))
			end
			
		end
		if self.curMapId>1 then
			local grayShadeProgram = UIUtil:shaderForKey("ShaderPositionTextureColor")
			self.totalPassBtn[self.curMapId].item[1]:setShaderProgram(grayShadeProgram)
			self.totalPassBtn[self.curMapId].item[2]:setShaderProgram(grayShadeProgram)
			self.totalPassBtn[self.curMapId]:getLayer():setTouchEnabled(true)
		end
		

	end
		
end

function ExpeditionLayer:createBoxCell(index,award)

	local cellNode = display.newNode()
	local csvType = forceMatchCsv:getAwardById(index).type
	
	-- 1未领取, 2已领取, 3不能领取
	local icoUrl=award==2 and csvType.."_open.png" or csvType..".png"

	local icoBtn=DGBtn:new(nil, {icoUrl},
		{	
			scale=0.9,
			priority = self.priority,
			swallowsTouches=false,
			--selectAnchor = { 0.5, 0 },
			callback = function()
				--开宝箱
				if award==1 then
					
					local bin = pb.encode("SimpleEvent", 
						{ param1 = index })
					game:sendData(actionCodes.DrawExpedition, bin)
					loadingShow()
					game:addEventListener(actionModules[actionCodes.DrawExpeditionResponse], function(event)
						loadingHide()

						local msg
						if event.data then
							msg = pb.decode("DrawExpeditionResponse", event.data)
						end

						if msg and msg.errCode==SYS_ERR_YZ_HAS_DRAW then
							DGMsgBox.new({text = "已经领取", type = 1})
						else

							local awardLayer=ExpeditionAwardLayer.new({priority=self.priority-1,items=msg.items,mapId=index,callback=function()
							self.drawStatus[index]=2--已领取
							self:updataAwardBox()
							end}):getLayer():addTo(display.getRunningScene())

						end

						return "__REMOVE__"
					end)

					
				end
			end,
		})

	if award~=1 and index<self.curMapId then
		local grayShadeProgram = UIUtil:shaderForKey("ShaderPositionTextureGray")
		icoBtn.item[1]:setShaderProgram(grayShadeProgram)
	end

	icoBtn:getLayer():addTo(cellNode)
	icoBtn:setEnable(award==1 and true or false)

	return cellNode
end

--全死不能挑战
function ExpeditionLayer:allDead()
	for _,soldier in ipairs(self.curMaps.heroList) do
		if soldier then
			if soldier.blood>0 then
				return false
			end
		end
	end

	return true
end

function ExpeditionLayer:createCarbonCell(index)
	local cellNode = display.newNode()

	local icoBtn=DGBtn:new(ExpeditonRes, {string.format("%02d.png",index),string.format("%02d_pressed.png",index)},
		{	
			noTouch=index>self.curMapId and true or false,
			priority = self.priority,
			swallowsTouches=false,
			selectAnchor = { 0.5, 0 },
			callback = function()
				local palyerinfo=PlayerInfor.new({priority = self.priority - 10,curMapId=index,
					challenge=(index==self.curMapId and not self:allDead()) and true or false,data=self.totalMaps[index]})
				palyerinfo:getLayer():addTo(display.getRunningScene())
			end,
		})

	self.totalPassBtn[#self.totalPassBtn+1]=icoBtn

	icoBtn:getLayer():addTo(cellNode)
	if index>self.curMapId  then
		local grayShadeProgram = UIUtil:shaderForKey("ShaderPositionTextureGray")
		icoBtn.item[1]:setShaderProgram(grayShadeProgram)
		icoBtn.item[2]:setShaderProgram(grayShadeProgram)
	end
	

	return cellNode
end

function ExpeditionLayer:onTouch(event, x, y)
	if event == "began" then
		return self:onTouchBegan(x, y)
	elseif event == "moved" then
		self:onTouchMove(x, y)
	elseif event == "ended" then
		self:onTouchEnd(x, y)
	end
end

function ExpeditionLayer:onTouchBegan(x, y)
	self.drag = {
		beganTime = os.clock(),
		beginX = x,
		frontX = self.contentLayer:getPositionX(),
		
	}	

	return true
end

function ExpeditionLayer:onTouchMove(x, y)
	self:moveOffset(x - self.drag.beginX)
end

function ExpeditionLayer:onTouchEnd(x, y)
	self.drag = {}
end

function ExpeditionLayer:moveOffset(xOffset, animation)
	local frontX = self.drag.frontX + xOffset
	
	if frontX > 0 then
		-- 左侧上限
		frontX = 0
	elseif frontX <= -self.moveLimit then
		-- 右侧上限
		frontX = -self.moveLimit
	end
	if animation then
		self.contentLayer:moveTo(1, frontX, 0)
	else
		self.contentLayer:pos(frontX, 0)
	end
	
end

function ExpeditionLayer:getLayer()
	return self.mask:getLayer()
end

function ExpeditionLayer:onExit()

end

return ExpeditionLayer