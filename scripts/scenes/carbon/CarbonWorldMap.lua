--
-- Author: yzm
-- Date: 2014-11-12 14:29:29
--副本世界地图
local CarbonRes = "resource/ui_rc/carbon/"
local ExpeditonRes = "resource/ui_rc/expedition/"

local HealthUseLayer  = require("scenes.home.HealthUseLayer")
local CarbonLayer = import(".CarbonLayer")

local CarbonWorldMap = class("CarbonWorldMap", function(params) return display.newLayer() end)

local CARBON = {}
CARBON.NORMAL = 1 		-- 普通副本
CARBON.CHALLENGE = 2 	-- 精英副本

CARBON_BUILDING_POS={
	[1]={x=2953, y=440},
	[2]={x=3190, y=390},
	[3]={x=3290, y=200},
	[4]={x=3100,y=70},
	[5]={x=2880,y=20},
	[6]={x=2720,y=150},
	[7]={x=2620,y=340},
	[8]={x=2430,y=478},
	[9]={x=2260,y=370},
	[10]={x=2400,y=225},
	[11]={x=2540,y=15},
	[12]={x=2300,y=30},
	[13]={x=2040,y=20},
	[14]={x=1820,y=107},
	[15]={x=1840,y=290},
	-- [1]={x=2953.75,y=393.1},
	-- [2]={x=3263.85,y=337.1},
	-- [3]={x=3239.85,y=99.05},
	-- [4]={x=2977.75,y=21.05},
	-- [5]={x=2719.7,y=59.05},
	-- [6]={x=2633.65,y=287.05},
	-- [7]={x=2471.65,y=478},
	-- [8]={x=2249.6,y=425.15},
	-- [9]={x=2319.6,y=247.1},
	-- [10]={x=2519.65,y=125.05},
	-- [11]={x=2331.55,y=17.05},
	-- [12]={x=2041.55,y=21.05},
	-- [13]={x=1817.45,y=65.1},
	-- [14]={x=1893.5,y=247.1},
	-- [15]={x=1651.45,y=337.1},
	-- [16]={x=1453.4,y=227.1},
	-- [17]={x=1309.35,y=21.05},
	-- [18]={x=1187.3,y=189.05},
	-- [19]={x=1089.3,y=423.15},
	-- [20]={x=833.25,y=449.05},
}
--超过15章用两张图时该值为0
local CARBON_OFFSET=1623


function CarbonWorldMap:ctor(params)
	self.params = params or {}
	self.closemode = params.closemode or 1
	self.curTag = params.tag or CARBON.NORMAL
	self.curMaps = nil
	self.skipPageIndex = params.initPageIndex
	self.showBoxGuide = params.showBoxGuide

	self.mapId = params.mapId
	self.carbonId = params.carbonId

	self.showEntry = params.showEntry

	self.normalMaps = {}
	self.challengeMaps = {}

	self.priority = params.priority or -130
	self.mask = DGMask:new({ item = self, priority = self.priority + 1,opacity=0.8})

	self:initUI()
end

function CarbonWorldMap:onEnter()
	self:checkGuide()
end

function CarbonWorldMap:checkGuide(remove)
	--黄巾之乱 or 真黄巾之乱 or 鬼黄巾之乱
	game:addGuideNode({node = self.totalPassBtn[1]:getLayer(), remove = remove,
		guideIds = {1004, 1025, 1031, 1034, 1037, 1057, 1061, 1065, 1085, 1089, 1093, 1111}
	})

	game:addGuideNode({node = self.totalPassBtn[2]:getLayer(), remove = remove,
		guideIds = {1111}
	})
	
	--精英按钮
	game:addGuideNode({node = self.challengeCarbonBtn:getLayer(), remove = remove,
		guideIds = {1056, 1060, 1064}
	})
end

function CarbonWorldMap:onExit()
	self:checkGuide(true)
end

function CarbonWorldMap:initUI()
	self:prepareData()
	self:initTopBottonBarLayer()
	if self.skipPageIndex~=0 then
		self:skipChapterByIndex(self.skipPageIndex)
		self.skipPageIndex=0
	end
end

-- 顶底栏
function CarbonWorldMap:initTopBottonBarLayer()
	if self.topbarLayer then
		self.topbarLayer:removeSelf()
	end

	self.topbarLayer = display.newLayer()
	self.topbarLayer:size(display.width,display.height)
		:anch(0.5,0.5):pos(display.cx,display.cy):addTo(self:getLayer(), 100)
	local topbarSize = display.size

	local roleInfo = roleInfoCsv:getDataByLevel(game.role.level)

	

	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority})
	:anch(0,1):pos(0,display.height):addTo(self.topbarLayer)
	layer:setTag(10001)

	local tableRadioGrp = DGRadioGroup:new()

	-- 普通副本选择（按钮版）
	self.normalCarbonBtn = DGBtn:new(CarbonRes, {"normal_normal.png", "normal_selected.png", "normal_disabled.png"},
		{	
			id = CARBON.NORMAL,
			priority = self.priority - 1,
			callback = function()
				self:initContentLayer(CARBON.NORMAL)

			end
		},tableRadioGrp)
	self.normalCarbonBtn:getLayer():scale(1):anch(0.5, 0.5):pos(50 , topbarSize.height - 186):addTo(self.topbarLayer)

	-- 精英副本选择（按钮版）
	self.challengeCarbonBtn = DGBtn:new(CarbonRes, {"special_normal.png", "special_selected.png", "special_disabled.png"},
		{	
			id = CARBON.CHALLENGE,
			priority = self.priority - 1,
			callback = function()
				if table.nums(self.challengeMaps) > 0 then
					self:initContentLayer(CARBON.CHALLENGE)
				else
					DGMsgBox.new({type =1, text = "通关第一章后开启"})
					tableRadioGrp:chooseById(self.curTag ~= CARBON.CHALLENGE and self.curTag or CARBON.NORMAL, true)
					return false
				end
			end
		},tableRadioGrp)
	self.challengeCarbonBtn:getLayer():scale(1):anch(0.5, 0.5):pos(50 , topbarSize.height - 317):addTo(self.topbarLayer)

	-- 关闭按钮
	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"}, {
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
				if self.closemode == 2 or gPushFlag then
					popScene()
					gPushFlag = false
				else
					switchScene("home")
				end
			end
		}):getLayer()
	closeBtn:anch(1, 1):pos(topbarSize.width, topbarSize.height ):addTo(self.topbarLayer,1,1000)

	-- self:initContentLayer(self.curTag)
	tableRadioGrp:chooseById(self.curTag, true)

end


function CarbonWorldMap:prepareData()	

	local mapIds = table.keys(game.role.mapDataset)
	for _,mapId in pairs(mapIds) do 
		local infoData = mapInfoCsv:getMapById(mapId)
		if mapId < 300 and infoData.openLevel <= game.role.level then
			if mapId < 200 then
				table.insert(self.normalMaps, mapId)
			elseif mapId > 200 and mapId < 300 then
				table.insert(self.challengeMaps, mapId)
			end
		end
	end
	table.sort(self.normalMaps)
	table.sort(self.challengeMaps)

	self.skipPageIndex=self.skipPageIndex or 0
	if self.mapId then
		if self.curTag == CARBON.NORMAL then
			for index, mapId in ipairs(self.normalMaps) do
				if self.mapId == mapId then
					self.skipPageIndex = index
				end
			end
		elseif self.curTag == CARBON.CHALLENGE then
			for index, mapId in ipairs(self.challengeMaps) do
				if self.mapId == mapId then
					self.skipPageIndex = index
				end
			end
		end
	end

	game.role.currentLastOpenCarbonIds = game.role.currentLastOpenCarbonIds or {}
	game.role.currentLastOpenCarbonIds[100] = self.normalMaps[#self.normalMaps]
	game.role.currentLastOpenCarbonIds[200] = self.challengeMaps[#self.challengeMaps]

end

-- 滑动层
function CarbonWorldMap:initContentLayer(tag)
	if self.layer then
		self.layer:removeSelf()
		self.initPageIndex = nil
	end

	self.curTag = tag
	self.curMaps = tag == CARBON.NORMAL and self.normalMaps or self.challengeMaps
	local initPageIndex = self.initPageIndex

	-- 查找当前最后一个开启的章节
	for index = #self.curMaps, 1, -1 do
		local infoData = mapInfoCsv:getMapById(self.curMaps[index])
		if infoData.openLevel <= game.role.level then
			if not self.initPageIndex then
				initPageIndex = index
			end
			break
		end
	end

	local maps = mapInfoCsv:getMapsByType(self.curTag)
	initPageIndex = initPageIndex > table.nums(maps) and table.nums(maps) or initPageIndex
	self.initPageIndex=initPageIndex

	self.contentLayer = display.newLayer()

	self.contentSize=CCSize(2040,640)--self.contentLayer:getContentSize()
	self.contentLayer:anch(0,0):pos(0,0)

	local worldMapTexture1=sharedTextureCache:textureForKey(CarbonRes.."worldMap1.jpg")
	if not worldMapTexture1 then
		worldMapTexture1=sharedTextureCache:addImage(CarbonRes.."worldMap1.jpg")
		worldMapTexture1:retain()
	end
	local worldMap1=CCSprite:createWithTexture(worldMapTexture1)


	--预留功能
	-- local worldMapTexture2=sharedTextureCache:textureForKey(CarbonRes.."worldMap2.jpg")
	-- local worldMap2
	-- if not worldMapTexture2 then
	-- 	print("error:worldMapTexture2 dispose")
	-- 	worldMapTexture2=sharedTextureCache:addImage(CarbonRes.."worldMap2.jpg")
	-- 	worldMapTexture2:retain()
	-- end
	-- worldMap2=CCSprite:createWithTexture(worldMapTexture2)

	worldMap1:setAnchorPoint(CCPoint(0,0))
	-- worldMap2:setAnchorPoint(CCPoint(0,0))
	self.contentLayer:addChild(worldMap1)

	if self.curTag == CARBON.CHALLENGE then
		display.newColorLayer(ccc4(245, 0, 69, 85))
			:size(worldMap1:getContentSize()):addTo(worldMap1)
	end
	-- worldMap2:setPositionX(worldMap1:getContentSize().width)
	-- self.contentLayer:addChild(worldMap2)

	self.BUILDING_INDEX=1

	self:getLayer():setTouchEnabled(true)
	self:getLayer():addTouchEventListener(function(event, x, y) return self:onTouch(event, x, y) end, false, self.priority)

	self.totalPassBtn={}
	for i=1,15 do
		local cell = self:createCarbonCell(i)
		cell:pos(CARBON_BUILDING_POS[i].x-CARBON_OFFSET,CARBON_BUILDING_POS[i].y):addTo(self.contentLayer,self.BUILDING_INDEX+1,self.BUILDING_INDEX+1)
	end

	local maskSize=CCSize(display.width,display.height)

	self.maxLimit=self.contentSize.width-maskSize.width
	self.moveLimit=0

	--设置当前所在关的箭头提示
	if self.initPageIndex>0 then
		
		self.arraw=display.newSprite(ExpeditonRes.."arrow.png"):anch(0.5,0)
			:pos(CARBON_BUILDING_POS[self.initPageIndex].x+162/2-CARBON_OFFSET,CARBON_BUILDING_POS[self.initPageIndex].y+162/2)
			:addTo(self.contentLayer,1000)
		self.arraw:runAction(CCRepeatForever:create(transition.sequence({
				CCMoveBy:create(0.5, ccp(0, 20)),
				CCMoveBy:create(0.5, ccp(0, -20))
			})))

		--云
		local offsetX=-150
		self.cloudLayer=display.newSprite(CarbonRes.."carbonCloud.png")
		self.cloudLayer:anch(1,0):pos(CARBON_BUILDING_POS[self.initPageIndex].x+offsetX-CARBON_OFFSET,0):addTo(self.contentLayer,self.BUILDING_INDEX+20)

		
		local moveLimit=-(self.cloudLayer:getPositionX()-self.cloudLayer:getContentSize().width)
		moveLimit=moveLimit>0 and 0 or moveLimit
		self.moveLimit=moveLimit

		--地图移到当前关

		local initOffsetX=300
		local moveOffsetX
		if self.skipPageIndex~=0 then
			moveOffsetX=CARBON_BUILDING_POS[self.skipPageIndex].x-initOffsetX-CARBON_OFFSET
		else
			moveOffsetX=CARBON_BUILDING_POS[self.initPageIndex].x-initOffsetX-CARBON_OFFSET
		end
		moveOffsetX=-moveOffsetX>self.moveLimit and self.moveLimit or -moveOffsetX--最左边限定（显示全部的云）
		moveOffsetX=moveOffsetX<-self.maxLimit and -self.maxLimit or moveOffsetX--最右边限定
		moveOffsetX=moveOffsetX>0 and 0 or moveOffsetX--最左边限定（显示全部地图）
		self.contentLayer:setPositionX(moveOffsetX)
	end

	--滚动窗口位置与大小设置，超出此窗口的部分都将隐藏	
	self.baseLayer = CCClippingLayer:create()
	self.baseLayer:setContentSize(CCSizeMake(maskSize.width,maskSize.height))
	self.baseLayer:addChild(self.contentLayer,self.BUILDING_INDEX)
	self.baseLayer:setPosition(CCPoint(0,0))

	self.layer = display.newLayer()
	self.layer:size(display.width,display.height)
	self.layer:addChild(self.baseLayer)
	self.layer:anch(0.5,0):pos(display.cx,0)
	self:getLayer():addChild(self.layer)

	self:checkGuide()
end

function CarbonWorldMap:updataChapterAwardBoxState()
	local tempX = self.contentLayer:getPositionX()
	self:initContentLayer(self.curTag)
	self.contentLayer:setPositionX(tempX)
end


function CarbonWorldMap:skipChapterByIndex(index)
	local closeBtn=self.topbarLayer:getChildByTag(1000)--closeBtn
	closeBtn:setVisible(false)

	local healthBg=self.topbarLayer:getChildByTag(10001)
	healthBg:setVisible(false)

	self:getLayer():setTouchEnabled(false)
	local tempParams=clone(self.params)
	tempParams.priority=self.priority-2
	tempParams.tag=self.curTag
	tempParams.initPageIndex=index
	tempParams.parent = self
	tempParams.callBack=function()
		self:getLayer():setTouchEnabled(true)
		closeBtn:setVisible(true)
		healthBg:setVisible(true)
	end

	local carbonLayer=CarbonLayer.new(tempParams)
		carbonLayer:getLayer():addTo(self:getLayer(),101)
end

function CarbonWorldMap:checkEnter(index)
	index= index - 1
	local mapId = self.curMaps[index + 1]

	local infoData = mapInfoCsv:getMapById(mapId or (self.curMaps[index] + 1))
	if self.curTag == CARBON.CHALLENGE and not self.challengeMaps[index + 1] then
		local tempInfo = mapInfoCsv:getMapById((mapId or (self.curMaps[index] + 1))-100)
		DGMsgBox.new({type = 1, text = string.format("通关普通%s后开启", tempInfo.name)})
		return
	end

	if infoData and game.role.level < infoData.openLevel then
		local msg = sysMsgCsv:getMsgbyId(565)
		DGMsgBox.new({ type = 1, text = string.format(msg.text, infoData.openLevel)})
		return
	end
end

function CarbonWorldMap:createCarbonCell(index)
	local cellNode = display.newNode()
	local mapId = self.curMaps[index]

	local icoBtn=DGBtn:new(CarbonRes.."build/", {string.format("passIco%d.png",index),string.format("passIco%d_pressed.png",index)},
		{	
			noTouch=index>self.initPageIndex+1 and true or false,
			priority = self.priority,
			swallowsTouches=false,
			selectAnchor = { 0.5, 0.5 },
			callback = function()
				if index == (self.initPageIndex+1) then
					self:checkEnter(index)
				else
					--点击进入时强制这个变量，防止失败后再来一次进入时不挑战后引起的BUG（bugid:1274）
					self.params.showEntry=false
					self:skipChapterByIndex(index)
				end
				
			end,
		})
	self.totalPassBtn[#self.totalPassBtn+1]=icoBtn

	icoBtn:getLayer():addTo(cellNode)
	if index>self.initPageIndex then
		local grayShadeProgram = UIUtil:shaderForKey("ShaderPositionTextureGray")
		icoBtn.item[1]:setShaderProgram(grayShadeProgram)
		icoBtn.item[2]:setShaderProgram(grayShadeProgram)
	end

	local maps = mapInfoCsv:getMapsByType(self.curTag)
	local infoData = maps[index]

	local normalLabel=display.newNode()
	display.newSprite(CarbonRes.."passNameBg.png"):addTo(normalLabel)
	local nameArr = string.split(infoData.name, " ")

	ui.newTTFLabel({text=nameArr[1],size = 20, font = ChineseFont,
		color=(index>self.initPageIndex and display.COLOR_WHITE or uihelper.hex2rgb("#ffe156"))})
		:pos(-40,12):addTo(normalLabel)

	ui.newTTFLabel({text=nameArr[3],size = 20, font = ChineseFont,
		color=(index>self.initPageIndex and display.COLOR_WHITE or uihelper.hex2rgb("#ffe156"))})
		:pos(0,-10):addTo(normalLabel)

	normalLabel:pos(80,20):addTo(icoBtn.item[1])

	local selectedLabel=display.newNode()
	display.newSprite(CarbonRes.."passNameBg_selected.png"):addTo(selectedLabel)
	ui.newTTFLabel({text=nameArr[1],size = 20, font = ChineseFont,
		color=(index>self.initPageIndex and display.COLOR_WHITE or uihelper.hex2rgb("#ffe156"))})
		:pos(-40,12):addTo(selectedLabel)

	ui.newTTFLabel({text=nameArr[3],size = 20, font = ChineseFont,
		color=(index>self.initPageIndex and display.COLOR_WHITE or uihelper.hex2rgb("#ffe156"))})
		:pos(0,-10):addTo(selectedLabel)

	selectedLabel:pos(80,20):addTo(icoBtn.item[2])

	-- 显示星数和箱子
	if mapId then
		local mapData = game.role.mapTypeDataset[self.curTag][mapId]
		local techItemData = techItemCsv:getDataByMap(mapId)
		local xPos= 130
		local boxRes
		local particleFlag=false
		local curIndex=1
		local totalStarNum = 0
		local carbonMapsInfo=mapBattleCsv:getCarbonByMap(mapId)
		for i = 1, #carbonMapsInfo do
			local carbonId = carbonMapsInfo[i].carbonId
			local carbonStar = game.role.carbonDataset[carbonId] and game.role.carbonDataset[carbonId].starNum or 0
			totalStarNum = totalStarNum + carbonStar
		end
		
		local getCurrentBoxRes=function()
			particleFlag=false
			for index = 1, 3 do
				-- 有数据
				if table.nums(techItemData["award" .. index]) > 0 then
					local status = mapData["award".. index .."Status"]

					if (status == 0 and totalStarNum >= tonum(techItemData.awardStarNums[tostring(index)])) then
						boxRes = "box"..index.."_open.png"
						particleFlag=true
						curIndex=index
						break
					end

					--取最后一个开的
					if status == 1 and index==3 then
						boxRes = "box"..index.."_empty.png"
						curIndex=index
					end

					if status == 1 and index~=3 and mapData["award".. index+1 .."Status"]~=1 then
						boxRes = "box"..(index+1).."_close.png"
						curIndex=index+1
					end
					
					--全关取最前面一个
					if status==0 and totalStarNum < tonum(techItemData.awardStarNums[tostring(index)]) and index==1 then
						boxRes = "box"..index.."_close.png"
					end
				end
			end
		end
		getCurrentBoxRes()

		
		--particle
		local addParticle=function()
			if particleFlag then
				local boxBtn 
				local Ptag = 9000 + curIndex
				local boxBtnNode=display.newNode()
				boxBtnNode:scale(0.5)
				boxBtn = DGBtn:new(CarbonRes, {boxRes},{})
				boxBtn:getLayer():addTo(boxBtnNode)
				boxBtnNode:size(boxBtn:getLayer():getContentSize()):pos(xPos, -10):addTo(cellNode)
				self.boxBtn = boxBtn:getLayer()


				local light = display.newSprite(CarbonRes.."back_light.png")
				light:setAnchorPoint(ccp(0.5, 0.5))
				light:setPosition(ccp(50, 30))
				boxBtn:getLayer():addChild(light,-1)
				light:setScale(1.0)
				light:runAction(CCRepeatForever:create(transition.sequence({
							CCScaleTo:create(0.5, 1.3),
							CCScaleTo:create(0.5, 1.1)
					})))
				light:setTag(351201)

				local s = boxBtn:getLayer():getContentSize()
				showParticleEffect({
					position = ccp(s.width * 0.5,s.height * 0.5),
					tag = Ptag,
					parent = boxBtn:getLayer(),
					zorder = 100,
					scale = 0.6,
					res = "resource/ui_rc/particle/kaifu_icon.plist",
				})
			end
		end

		addParticle()

		
		--星级数量
		local starLable = DGRichLabel.new({ size = 18, font = ChineseFont })
		local text = "[color=7ce810]" .. totalStarNum .. "[/color]/"..3 * infoData.carbonNum
		starLable:setString(text)
		starLable:setAnchorPoint(CCPoint(0.5,0.5))

		starLable:setPosition(CCPoint(140-starLable:getContentSize().width,22))
		cellNode:addChild(starLable)
		
		local star2 = display.newSprite( CarbonRes .. "star.png")
		star2:anch(0,0.5):pos(142,35):addTo(cellNode)
	else
		--星级数量
		local starLable = DGRichLabel.new({ size = 18, font = ChineseFont })
		local text = "[color=7ce810]" .. 0 .. "[/color]/"..3 * infoData.carbonNum
		starLable:setString(text)
		starLable:setAnchorPoint(CCPoint(0.5,0.5))

		starLable:setPosition(CCPoint(140-starLable:getContentSize().width,22))
		cellNode:addChild(starLable)
		
		local star2 = display.newSprite( CarbonRes .. "star.png")
		star2:anch(0,0.5):pos(142,35):addTo(cellNode)
	end
	
	
	return cellNode
end

function CarbonWorldMap:onTouch(event, x, y)
	if event == "began" then
		return self:onTouchBegan(x, y)
	elseif event == "moved" then
		self:onTouchMove(x, y)
	elseif event == "ended" then
		self:onTouchEnd(x, y)
	end
end

function CarbonWorldMap:onTouchBegan(x, y)
	if game:hasGuide() then
		return false
	end
	self.drag = {
		beganTime = os.clock(),
		beginX = x,
		frontX = self.contentLayer:getPositionX(),
		
	}	

	return true
end

function CarbonWorldMap:onTouchMove(x, y)
	self:moveOffset(x - self.drag.beginX)
end

function CarbonWorldMap:onTouchEnd(x, y)
	self.drag = {}
end

function CarbonWorldMap:moveOffset(xOffset, animation)
	local frontX = self.drag.frontX + xOffset
	
	if frontX > self.moveLimit then
		-- 左侧上限
		frontX = self.moveLimit
	elseif frontX <= -self.maxLimit then
		-- 右侧上限
		frontX = -self.maxLimit
	end
	if animation then
		self.contentLayer:moveTo(1, frontX, 0)
	else
		self.contentLayer:pos(frontX, 0)
	end
	
end

function CarbonWorldMap:getLayer()
	return self.mask:getLayer()
end

function CarbonWorldMap:onExit()
    
end

return CarbonWorldMap