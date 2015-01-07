-- 新UI 副本UI层
-- by yangkun
-- 2014.3.24

local HomeRes = "resource/ui_rc/home/"
local HeroRes = "resource/ui_rc/hero/"
local CarbonRes = "resource/ui_rc/carbon/"
local GlobalRes = "resource/ui_rc/global/"

local CarbonSweepLayer = import(".CarbonSweepLayer")
local HealthUseLayer  = require("scenes.home.HealthUseLayer")
local StarAwardLayer = import(".StarAwardLayer")

local CarbonLayer = class("CarbonLayer", function(params) return display.newLayer() end)

local CARBON = {}
CARBON.NORMAL = 1 		-- 普通副本
CARBON.CHALLENGE = 2 	-- 精英副本

local HEAD_ICO_OFFSET={
	[3]={
		{x=-255.65,y=64.55},
		{x=-6.05,y=-84},
		{x=246,y=63.5},
	},
	[5]={
		{x=-346.65,y=111.05},
		{x=-177.6,y=-86.05},
		{x=-9.05,y=106.05},
		{x=158.5,y=-88.05},
		{x=327.05,y=108.05},
	},
	[10]={
		{x=-390.6,y=0},
		{x=-261.6,y=157.05},
		{x=-225.05,y=-65},
		{x=-89,y=85.55},
		{x=-78,y=-157.05},
		{x=56.5,y=-38.05},
		{x=74,y=146.55},
		{x=250.55,y=133.55},
		{x=287.05,y=-80.05},
		{x=394.1,y=84.05},
	},

}

function CarbonLayer:ctor(params)
	self.params = params or {}

	self.closemode = params.closemode or 1
	self.curTag = params.tag or CARBON.NORMAL
	self.curMaps = nil
	self.initPageIndex = params.initPageIndex
	self.showBoxGuide = params.showBoxGuide

	-- self.mapId = params.mapId
	self.carbonId = params.carbonId

	self.showEntry = params.showEntry

	self.normalMaps = {}
	self.challengeMaps = {}

	self.priority = params.priority or -128
	self.mask = DGMask:new({ item = self, priority = self.priority + 1})
end

function CarbonLayer:onEnter()
	self:initUI()
	self:checkGuide()
end

function CarbonLayer:initUI()
	self:prepareCarbonData()
	self:initTopBarLayer()
end

-- 顶栏
function CarbonLayer:initTopBarLayer()
	if self.topbarLayer then
		self.topbarLayer:removeSelf()
	end

	self.topbarLayer = display.newLayer()
	self.topbarLayer:size(display.width, 76)
		:pos(0,display.height-76):addTo(self, 1)
	local topbarSize = self.topbarLayer:getContentSize()

	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority})
	:anch(0,1):pos(0,topbarSize.height):addTo(self.topbarLayer)

	-- 关闭按钮
	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"}, {
			touchScale = 1.5,
			priority=self.priority,
			swallowsTouches=true,
			callback = function()
				if self.params.callBack then
					self.params.callBack()
				end
				self:getLayer():removeSelf()
			end
		}):getLayer()
	closeBtn:anch(1, 1):pos(topbarSize.width, topbarSize.height ):addTo(self.topbarLayer)

	self:initContentLayer(self.curTag)

	if self.showEntry then
		local sweepLayer = CarbonSweepLayer.new({priority=self.priority,carbonId = self.carbonId, closeCallback = function() self:checkGuide() end})
		sweepLayer:getLayer():addTo(display.getRunningScene())
		self.showEntry=false
	end
end

function CarbonLayer:getNumberString(number)
	local ret = tostring(number)

	if number >= 10000 and number < 100000000 then
		ret = string.format( "%d万", tonum(number/10000) )
	elseif number >= 100000000 then
		ret = string.format( "%d亿", tonum(number/100000000))
	end

	return ret
end 

function CarbonLayer:prepareCarbonData()
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
end

-- 滑动层
function CarbonLayer:initContentLayer(tag)
	if self.contentLayer and self.curTag == tag then return end

	if self.contentLayer then
		self.contentLayer:removeSelf()
		self.scrollView:removeEventListener("changePageIndex", self.listenChangePage)
		self.initPageIndex = nil
	end

	self.curTag = tag
	self.curMaps = tag == CARBON.NORMAL and self.normalMaps or self.challengeMaps
	self.contentLayer = display.newLayer(CarbonRes.."passBg.png")
	self.contentLayer:size(self.contentLayer:getContentSize().width, self.contentLayer:getContentSize().height)
	self.contentLayer:anch(0.5,0.5):pos(display.cx,display.cy-20):addTo(self)

	local initPageIndex = self.initPageIndex

	-- 查找当前最后一个开启的章节
	for index = #self.curMaps, 1, -1 do
		local infoData = mapInfoCsv:getMapById(self.curMaps[index])
		if infoData.openLevel <= game.role.level then
			if not self.initPageIndex then
				initPageIndex = index
			end

			self.lastPageIndex = index
			break
		end
	end

	local maps = mapInfoCsv:getMapsByType(self.curTag)
	initPageIndex = initPageIndex > table.nums(maps) and table.nums(maps) or initPageIndex
	self.lastPageIndex = #self.curMaps > table.nums(maps) and table.nums(maps) or #self.curMaps

	self.scrollView = DGPageView.new({
		priority=self.priority,
		size = CCSizeMake(self.contentLayer:getContentSize().width,self.contentLayer:getContentSize().height),
		dataSource = self.curMaps,
		initPageIndex = initPageIndex,
		lastPageIndex = self.lastPageIndex,
		cellAtIndex = function(index) 
			return self:createCarbonCell(index)
		end
	})
	self.scrollView:getLayer():addTo(self.contentLayer)

	local mapId,infoData
	local nameStr,nameArr
	self.listenChangePage=self.scrollView:addEventListener("changePageIndex", function(event)
		if self.chapterName then
			mapId=self.curMaps[event.pageIndex]
			infoData = mapInfoCsv:getMapById(mapId)
			nameArr = string.split(infoData.name," ")
			nameStr = nameArr[1].."          "..nameArr[3]
			self.chapterName:setString(nameStr)
		end
		end)
	mapId=self.curMaps[self.scrollView:getCurPageIndex()]
	infoData = mapInfoCsv:getMapById(mapId)
	nameArr = string.split(infoData.name," ")
	nameStr = nameArr[1].."          "..nameArr[3]
	self.chapterName=ui.newTTFLabelWithStroke({ text = nameStr, font = ChineseFont, size = 34, color = uihelper.hex2rgb("#532500"), strokeColor = uihelper.hex2rgb("#ffce7b"),strokeSize=1 })
	:pos(self.contentLayer:getContentSize().width/2, self.contentLayer:getContentSize().height-40):addTo(self.contentLayer)
	
end

function CarbonLayer:createCarbonCell(index)
	local cellNode = display.newNode():size(self.contentLayer:getContentSize())

	local mapId = self.curMaps[index]
	local infoData = mapInfoCsv:getMapById(mapId)

	if not mapId or game.role.level < infoData.openLevel then
		local msg = sysMsgCsv:getMsgbyId(565)
		DGMsgBox.new({ type = 1, text = string.format(msg.text, infoData.openLevel) })
		return
	end

	local cellSize = cellNode:getContentSize()
	local cellContentSize = CCSizeMake(cellSize.width, cellSize.height - self.topbarLayer:getContentSize().height)

	-- 章节背景
	local cellBg =display.newSprite(infoData.bgRes)-- CCSpriteExtend.extend(CCSprite:create(infoData.bgRes, CCRectMake((1140-display.width)/2,0,display.width, display.height)))
	cellBg:anch(0.5,0.5):pos(cellNode:getContentSize().width/2,cellNode:getContentSize().height/2-20):addTo(cellNode, -1)
	
	self.guideBtns = {}
	-- 副本
	local carbonIds = table.keys(game.role.mapDataset[mapId])
	local totalStarNum = 0
	table.sort(carbonIds, function(a,b) return a<b end)
	local carbonMapsInfo=mapBattleCsv:getCarbonByMap(mapId)
	table.sort(carbonMapsInfo, function(a,b) return a.carbonId<b.carbonId end)
	for i = 1, #carbonMapsInfo do
		local carbonId = carbonMapsInfo[i].carbonId
		local carbonData = carbonMapsInfo[i]--mapBattleCsv:getCarbonById(carbonId)
		
		-- boss 头像框
		local frameRes = "headframe_" .. carbonData.bossIcon .. ".png"
		local headBtn = DGBtn:new(CarbonRes, {frameRes}, {
				
				priority=self.priority,
				callback = function()
					local sweepLayer = CarbonSweepLayer.new({carbonId = carbonId,priority=self.priority, closeCallback = function() self:checkGuide() end})
					sweepLayer:getLayer():addTo(display.getRunningScene())
				end,
				--scale = 1.05,
			})
		headBtn:setEnable(carbonIds[#carbonIds]>=carbonId)
		self.guideBtns[i] = headBtn:getLayer()
		
		local headSize = headBtn:getLayer():getContentSize()
		local bossData = unitCsv:getUnitByType(carbonData.bossId)
		local headIcon = getShaderNode({steRes = CarbonRes.."headcut.png",clipRes = bossData.headImage})
		headIcon:setPosition(headSize.width/2, headSize.height/2)
		headBtn:getLayer():addChild(headIcon, -1)

		local passNameBg=display.newSprite(CarbonRes.."starBar.png"):pos(headSize.width/2,3):addTo(headBtn:getLayer())

		local x = cellSize.width/2 + HEAD_ICO_OFFSET[#carbonMapsInfo][i].x
		local y = cellSize.height/2 + HEAD_ICO_OFFSET[#carbonMapsInfo][i].y
		local headNode = display.newNode():size(headSize)
		headBtn:getLayer():anch(0.5, 0.5):pos(headSize.width / 2, headSize.height / 2):addTo(headNode)
		headNode:anch(0.5,0.5):pos(x,y):addTo(cellNode, carbonId)

		if not canChallenge then
			headNode:setColor(ccc3(100, 100, 100))
		end

		if carbonId == self.carbonId or (not self.carbonId and i == #carbonIds and index == self.lastPageIndex) then
			local nextArrow = display.newSprite(CarbonRes .. "next_arrow.png")
			nextArrow:anch(0.5, 0):pos(x, y + 50):addTo(cellNode,carbonId+10)
				:runAction(CCRepeatForever:create(transition.sequence({
					CCMoveBy:create(0.5, ccp(0, 10)),
					CCMoveBy:create(0.5, ccp(0, -10))
				})))

		end

		-- 星级
		local interval = 30
		local carbonStar = game.role.carbonDataset[carbonId] and game.role.carbonDataset[carbonId].starNum or 0
		totalStarNum = totalStarNum + carbonStar
		for j = 1, 3 do
			local star
			if j <= carbonStar then
				star = display.newSprite( CarbonRes .. "star.png" )
			else
				star = display.newSprite( CarbonRes .. "star_gray.png")
			end
			star:pos(passNameBg:getContentSize().width / 2 + interval *(j -2), 8*(j%2)+51):addTo(passNameBg)

		end

		-- 副本名字
		ui.newTTFLabelWithStroke({ text = carbonData.name, size = 20, color = uihelper.hex2rgb("#fdedcd"),font=ChineseFont  })
			:anch(0.5, 0):pos(passNameBg:getContentSize().width / 2, 8 ):addTo(passNameBg)

		if carbonId == self.carbonId then
			display.newSprite("resource/ui_rc/guide/halo.png")
				:pos(headSize.width / 2, headSize.height / 2):addTo(headNode)
				:runAction(CCRepeatForever:create(transition.sequence({
						CCScaleTo:create(0.5, 1.1),
						CCScaleTo:create(0.5, 0.95)
					})))
		end
	end

	if true then 
		-- 总的星级
		local starBg = display.newSprite( CarbonRes .. "star_bg.png")
		starBg:anch(1,0):pos(cellNode:getContentSize().width-22, 16):addTo(cellNode)
		
		-- 地图奖励
		local mapData = game.role.mapTypeDataset[infoData.type][mapId]
		local techItemData = techItemCsv:getDataByMap(mapId)
		local xPos= 10
		local boxRes
		local particleFlag=false
		local curIndex=1
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


		local boxBtn 
		local Ptag = 9000 + curIndex
		local boxBtnNode=display.newNode()
		boxBtnNode:scale(0.7)
		boxBtn = DGBtn:new(CarbonRes, {boxRes},
			{	
				priority=self.priority,
				scale = 1.08,
				callback = function()
					local layer = StarAwardLayer.new({ priority=self.priority,mapId = mapId, boxIndex = curIndex, totalStarNum = totalStarNum, 
						callback = function() 
							getCurrentBoxRes()
							boxBtn:setBg(1, CarbonRes .. boxRes) 
							if not particleFlag and boxBtn:getLayer():getChildByTag(351201) then
								boxBtn:getLayer():getChildByTag(351201):stopAllActions()
								boxBtn:getLayer():getChildByTag(351201):removeFromParent()
								boxBtn:getLayer():getChildByTag(Ptag):removeFromParent()
							end

							if self.params.parent then
								self.params.parent:updataChapterAwardBoxState()
							end
						end,
						dismissCallback = function()
							self.showBoxGuide = false
							self:checkGuide()
						end})
					layer:getLayer():addTo(display.getRunningScene())
					game:addGuideNode({node = layer:getLayer(), remove = remove, opacity = 0,
						guideIds = {905}
					})
				end,
			})
		boxBtn:getLayer():addTo(boxBtnNode)
		boxBtnNode:size(boxBtn:getLayer():getContentSize()):pos(xPos, 20):addTo(starBg)
		self.boxBtn = boxBtn:getLayer()

		--particle
		local addParticle=function()
			if particleFlag then
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
		local starLable = DGRichLabel.new({ size = 22, font = ChineseFont })
		local text = "[color=7ce810]" .. totalStarNum .. "[/color]/"..3 * infoData.carbonNum
		starLable:setString(text)
		starLable:setPosition(CCPoint(85,24))
		starLable:setAnchorPoint(CCPoint(0,0.5))
		starBg:addChild(starLable)
		
		local star2 = display.newSprite( CarbonRes .. "star.png")
		star2:anch(0,0.5):pos(145,40):addTo(starBg)
	end

	

	-- 左右滑动箭头
	if index ~= 1 then
		local leftArrowBtn = DGBtn:new(CarbonRes , {"arrow.png", "arrow.png", "arrow_disabled.png"}, {
			priority=self.priority,
				callback = function()
					if not self.scrollView.isScroll then
						self.scrollView:autoScroll(0)
					end
				end
			})
		leftArrowBtn:setEnable(index > 1)
		leftArrowBtn:getLayer():setRotationY(180)
		leftArrowBtn:getLayer():anch(1, 0.5):pos(0, cellSize.height / 2):addTo(cellNode, 1)
	end

	local passedCarbonNum = 0
	for _, carbonId in ipairs(carbonIds) do
		local carbonStar = game.role.carbonDataset[carbonId].starNum
		passedCarbonNum = passedCarbonNum + (carbonStar > 0 and 1 or 0)
	end

	if passedCarbonNum >= infoData.carbonNum then
		-- 左右滑动箭头
		local rightArrowBtn = DGBtn:new(CarbonRes , {"arrow.png", "arrow.png", "arrow_disabled.png"}, {
				priority=self.priority,
				callback = function()
					local mapId = self.curMaps[index + 1]
					local infoData = mapInfoCsv:getMapById(mapId or (self.curMaps[index] + 1))
					if self.curTag == CARBON.CHALLENGE and not self.challengeMaps[index + 1] then
						DGMsgBox.new({type = 1, text = string.format("通关普通%s后开启", infoData.name)})
						return
					end

					if infoData and game.role.level < infoData.openLevel then
						local msg = sysMsgCsv:getMsgbyId(565)
						DGMsgBox.new({ type = 1, text = string.format(msg.text, infoData.openLevel)})
						return
					else
						
					end

					if not self.scrollView.isScroll then
						self.scrollView:autoScroll(1)
					end
				end
			})
		rightArrowBtn:getLayer():anch(1,0.5):pos(cellContentSize.width, cellSize.height / 2):addTo(cellNode, 1)
	end

	return cellNode
end

function CarbonLayer:checkGuide(remove)
	--副本新手引导
	game:addGuideNode({node = self.guideBtns[1], remove = remove,
		guideIds = {1005, 1058, 1086}
	})
	game:addGuideNode({node = self.guideBtns[2], remove = remove,
		guideIds = {1026, 1062, 1090}
	})
	game:addGuideNode({node = self.guideBtns[3], remove = remove,
		guideIds = {1032, 1066, 1094}
	})
	game:addGuideNode({node = self.guideBtns[4], remove = remove,
		guideIds = {1035}
	})
	game:addGuideNode({node = self.guideBtns[5], remove = remove,
		guideIds = {1038}
	})
	--副本宝箱指引
	game:addGuideNode({node = self.boxBtn:getParent(), guideBtn = self.boxBtn, remove = remove,
		guideIds = {1029}
	})


	--强制引导
	local forceGuideSteps = {2, 7, 8, 9, 10, 13, 14, 15}
	local forceGuideIds = {1005, 1026, 1032, 1035, 1038, 1058, 1062, 1066}
	if not remove and game.guideId ~= 1029 then
		local index = table.keyOfItem(forceGuideSteps, game.role.guideStep)
		if index then
			game:activeGuide(forceGuideIds[index])
		end
	end
end


function CarbonLayer:getLayer()
	return self.mask:getLayer()
end

function CarbonLayer:onExit()
	self:checkGuide(true)
	game.role:removeEventListener("updateHealth", self.updateHealthHandler)
    game.role:removeEventListener("updateLevel", self.updateLevelHandler)
    game.role:removeEventListener("updateVipLevel", self.updateVipLevelHandler)
end

return CarbonLayer