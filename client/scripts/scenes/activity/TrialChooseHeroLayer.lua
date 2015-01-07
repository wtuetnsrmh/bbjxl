--
-- Author: yzm
-- Date: 2014-10-14 12:43:33
--选择英雄

local GlobalRes = "resource/ui_rc/global/"
local ExpeditonRes = "resource/ui_rc/expedition/"
local CarbonSweepRes = "resource/ui_rc/carbon/sweep/"
local BattleRes = "resource/ui_rc/battle/"

local FilterLogic = require("scenes.home.hero.FilterLogic")
local HeroInfoLayer = require("scenes.home.hero.HeroInfoLayer")

local TrialChooseHeroLayer = class("TrialChooseHeroLayer", function(params) 
	return display.newLayer() 
end)

function TrialChooseHeroLayer:ctor(params)
	self.params = params or {}
	self.activity = params.activity
	self.curMapId=params.curMapId or 1
	self.trialData = checkTable(checkTable(checkTable(checkTable(GameData, "userInfo"), tostring(game.role.id)), "trialData"), self.activity.index)
	
	self.priority = params.priority or -129
	self.mask = DGMask:new({ item = self, priority = self.priority + 1, bg = HomeRes .. "home.jpg" })
	self.size = CCSizeMake(685, 392)
	self:anch(0.5,0.5):pos(display.cx,display.cy)

	--筛选条件
	self.selectedData={type = 0, star = 1, level = 1}

	self.initUIFlag=false

	self:prepareData()
end

function TrialChooseHeroLayer:initUI()
	self.tabCursor = display.newSprite(GlobalRes .. "tab_arrow.png")
	self.tabCursor:anch(1, 0.5):pos(display.cx+self.size.width/2-50, 550):addTo(self, 102)

	local tabRadio = DGRadioGroup:new()
	local totalTypeBtn = DGBtn:new(ExpeditonRes, {"tab_normal.png", "tab_selected.png"},
		{	
			forceScale=0.9,
			priority = self.priority,
			callback = function()
				self.tabCursor:pos(display.cx+self.size.width/2-50, 550)
				self.selectedData.type = 0
				self.heroFilter:filterByType(self.selectedData)
			end
		}, tabRadio)
	totalTypeBtn:getLayer():anch(0.5, 0.5):pos(display.cx+self.size.width/2-2, 550):addTo(self)
	local btnSize = totalTypeBtn:getLayer():getContentSize()
	ui.newTTFLabelWithStroke({ text = "全部", font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:anch(0.5,0.5):pos(btnSize.width / 2, btnSize.height / 2):addTo(totalTypeBtn:getLayer(), 101)

	local nearBtn = DGBtn:new(ExpeditonRes, {"tab_normal.png", "tab_selected.png"},
		{	
			forceScale=0.9,
			priority = self.priority,
			callback = function()
				self.tabCursor:pos(display.cx+self.size.width/2-50, 490)
				self.selectedData.type = 1
				self.heroFilter:filterByType(self.selectedData)
			end,
		}, tabRadio)
	nearBtn:getLayer():anch(0.5, 0.5):pos(display.cx+self.size.width/2-2, 490):addTo(self)
	ui.newTTFLabelWithStroke({ text = "步兵", font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(nearBtn:getLayer(), 101)

	local farBtn = DGBtn:new(ExpeditonRes, {"tab_normal.png", "tab_selected.png"},
		{	
			forceScale=0.9,
			priority = self.priority,
			callback = function()
				self.tabCursor:pos(display.cx+self.size.width/2-50, 430)
				self.selectedData.type = 3
				self.heroFilter:filterByType(self.selectedData)
			end,
		}, tabRadio)
	farBtn:getLayer():anch(0.5, 0.5):pos(display.cx+self.size.width/2-2, 430):addTo(self,101)
	ui.newTTFLabelWithStroke({ text = "骑兵",  font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(farBtn:getLayer(), 10)

	local ArcherBtn = DGBtn:new(ExpeditonRes, {"tab_normal.png", "tab_selected.png"},
		{	
			forceScale=0.9,
			priority = self.priority,
			callback = function()
				self.tabCursor:pos(display.cx+self.size.width/2-50, 370)
				self.selectedData.type = 4
				self.heroFilter:filterByType(self.selectedData)
			end,
		}, tabRadio)
	ArcherBtn:getLayer():anch(0.5, 0.5):pos(display.cx+self.size.width/2-2, 370):addTo(self,101)
	ui.newTTFLabelWithStroke({ text = "弓兵", font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(ArcherBtn:getLayer(), 10)

	local adviserBtn = DGBtn:new(ExpeditonRes, {"tab_normal.png", "tab_selected.png"},
		{	
			forceScale=0.9,
			priority = self.priority,
			callback = function()
				self.tabCursor:pos(display.cx+self.size.width/2-50, 310)
				self.selectedData.type = 5
				self.heroFilter:filterByType(self.selectedData)
			end,
		}, tabRadio)
	adviserBtn:getLayer():anch(0.5, 0.5):pos(display.cx+self.size.width/2-2, 310):addTo(self,101)
	ui.newTTFLabelWithStroke({ text = "军师", font = ChineseFont,
		size = 26, color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(btnSize.width / 2, btnSize.height / 2):addTo(adviserBtn:getLayer(), 10)

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1,
			priority = self.priority,
			callback = function()
				
				self:getLayer():removeSelf()
			end,
		}):getLayer()
	closeBtn:anch(1, 1):pos(display.width, display.height):addTo(self,100)

	self.initUIFlag=true
end


function TrialChooseHeroLayer:initBottonUI()
	if self.bottonContentLayer then
		self.bottonContentLayer:removeSelf()
	end

	self.bottonContentLayer=display.newLayer(ExpeditonRes.."challengBg.png"):anch(0.5,0):pos(display.cx,27):addTo(self)

	local index=0
	for _,hero in ipairs(self.chooseHeros) do
		local heroCell = self:createCell({ type = hero.type, level = hero.level, wakeLevel = hero.wakeLevel, star = hero.star,
			evolutionCount = hero.evolutionCount, priority = self.priority,
			parent = self.bottonContentLayer,
			callback = function()
				--去掉上阵
				self:updataHerosIsOn({HeroId=hero.id,isOn=2} )

				self.heroTableView:reloadData()

				self:initBottonUI()
			end
		})
		heroCell:anch(0, 0.5):pos(552-index*100-index*30, self.bottonContentLayer:getContentSize().height/2):addTo(self.bottonContentLayer)

		index=index+1
	end


	local function chooseRequest()
		local heroList={}

		for _,hero in ipairs(self.chooseHeros) do
			table.insert(heroList,hero.id)
		end
		local chooseOpponent = {
			id = self.curMapId,
			heroList = heroList
		}

		self.trialData.chooseHeros = heroList

		GameState.save(GameData)
		
		local bin = pb.encode("SimpleEvent", {roleId = game.role.id, param1 = self.curMapId, param2 = self.activity.index})
		game:sendData(actionCodes.TrialBattleRequest, bin)
		loadingShow()
		game:addEventListener(actionModules[actionCodes.TrialBattleRequest], function(event)
			local msg = pb.decode("BattleEndResult", event.data)
			loadingHide()

			local attackHeros={}

			local Hero = require("datamodel.Hero")
			
			for _, hero in ipairs(self.chooseHeros) do
				local attrs = hero:getTotalAttrValues(nil, heroList)--相应槽位装备属性加成
				local pvpHero = {
					id = hero.id,
					type = hero.type,
					index = hero.slot,
					level = hero.level,
					evolutionCount = hero.evolutionCount,
					skillLevelJson = hero.skillLevelJson,
					wakeLevel=hero.wakeLevel,
					star = hero.star,
				}
				table.merge(pvpHero, attrs)
				pvpHero.attack = pvpHero.atk
				pvpHero.defense = pvpHero.def
				table.insert(attackHeros, pvpHero)
			end

			switchScene("battle", { battleType = BattleType.Trial, soldiers = attackHeros, 
				trialData = self.trialData, carbonId = self.curMapId, dropItems = msg.dropItems})

			self:getLayer():removeSelf()

			return "__REMOVE__"
		end)
	end

	--挑战
	local fireBackSp = self:frameActionOnSprite("nuqi_normal",5,true)
	:pos(745,100):scale(1.5)
	:addTo(self.bottonContentLayer)

	

	local challengeBtn=DGBtn:new(ExpeditonRes, {"challengBt_normal.png","challengBt_selected.png"},
	{
		priority = self.priority-10,
		callback = function()
			if #self.chooseHeros>0 then
				showMaskLayer({opacity=0})
				local fireFrountSp = self:frameActionOnSprite("nuqi_up",6,false)
				:pos(750,120):scale(1.5)
				:addTo(self.bottonContentLayer)
				fireFrountSp:performWithDelay(function() 
					hideMaskLayer()
					chooseRequest()
					end, 0.5)
			else
				DGMsgBox.new({text="请选择出战武将！",type=1})
			end
			
			
		end}):getLayer()
	challengeBtn:anch(0.5,0.5):pos(745,74):addTo(self.bottonContentLayer)

end

function TrialChooseHeroLayer:frameActionOnSprite(fileName,frameNum,isForever)

	display.addSpriteFramesWithFile(BattleRes..fileName..".plist", BattleRes..fileName..".png")
	local framesTable = {}
	for index = 1, frameNum do
		local frameId = string.format("%02d", index)
		framesTable[#framesTable + 1] = display.newSpriteFrame(fileName.."_" .. frameId .. ".png")
	end
	local panimate = display.newAnimation(framesTable, 1.0/10)
	local sprite = display.newSprite(framesTable[1])
	if isForever then
		sprite:playAnimationForever(panimate)
	else
		sprite:playAnimationOnce(panimate)
	end
	return sprite
end

function TrialChooseHeroLayer:prepareData()
	if not self.initUIFlag then
		self:initUI()
	end
	
	self:initData()

	self:initHeroList()
	
	self.selectedData.type = 0
	self.heroFilter:filterByType(self.selectedData)

	self:initBottonUI()

	--武将数
	local contentText= "[color=FFFFFFFF]持有数: [color=FF7CE810]%s[/color][color=FFFFFFFF]/%s[/color][/color]"
	local heroNumLabel=ui.newTTFRichLabel({ text = string.format(contentText,#self.heroFilter:getResult(),#self.heros),  size = 22,font=ChineseFont})
		:anch(0,1):pos(display.cx-760/2,self:getContentSize().height-10):addTo(self.contentLayer)
end


function TrialChooseHeroLayer:initData()
	self.heros = {}
	for _, hero in pairs(game.role.heros) do
		if ((self.activity.index <= 4 and self.activity.index == hero.unitData.camp) or (self.activity.index > 4 and hero.unitData.sex == 1))
			and not unitCsv:isExpCard(hero.type) and not unitCsv:isMoneyCard(hero.type) then
			hero.isOn = 2
			table.insert(self.heros, hero)
		end
	end
	

	self.chooseHeros={}
	
	local chooseHeros = checkTable(self.trialData, "chooseHeros")
	local formation = checkTable(self.trialData, "formation")
	local tempHeros = {}
	--设置阵型中的为上阵
	for _,hero in ipairs(self.heros) do
		local index = table.keyOfItem(chooseHeros, hero.id)
		if index then
			hero.isOn = 1
			hero.slot = table.keyOfItem(formation, hero.id) or index
			tempHeros[index] = hero
		end
	end
	self.chooseHeros = table.values(tempHeros)

	table.sort(self.heros, function(a, b) 
		local unitDataA = unitCsv:getUnitByType(a.type)
		local unitDataB = unitCsv:getUnitByType(b.type)
		local factorA = a.choose * 1000000 + (a.master > 0 and 1 or 0) * 100000 + a.star * 10000 + a.evolutionCount * 1000 + a.level
		local factorB = b.choose * 1000000 + (b.master > 0 and 1 or 0) * 100000 + b.star * 10000 + b.evolutionCount * 1000 + b.level
		return factorA == factorB and (a.type < b.type) or (factorA > factorB)
	end)

	self.heroFilter = FilterLogic.new({ heros = self.heros })
	self.heroFilter:addEventListener("filter", function(event) self.heroTableView:reloadData() end)

end

--更新self.heros的上阵状态
function TrialChooseHeroLayer:updataHerosIsOn(params)

	for _,hero in ipairs(self.heros) do

		if hero.id==params.HeroId then
			hero.isOn=params.isOn

			self:updataChooseHeros(hero)
		end
	end
end

--更新选中的武将
function TrialChooseHeroLayer:updataChooseHeros(updataHero)
	local exist=false
	for _,hero in ipairs(self.chooseHeros) do
		if hero.id==updataHero.id then
			hero.isOn=updataHero.isOn
			if hero.isOn==2 then
				--如果是下阵则站位重置
				updataHero.slot=0
			end
			exist=true
		end
	end

	local deleteIndex=nil
	for i=1,#self.chooseHeros do
		if self.chooseHeros[i].isOn==2 then
			deleteIndex=i
		end
	end
	if deleteIndex then
		table.remove(self.chooseHeros,deleteIndex)--移除未上阵的
	end
	
	if not exist then
		--设置新加的slot
		updataHero.slot=self:findMinSlod()
		table.insert(self.chooseHeros,updataHero)
	end

	--重置slot
	-- for index,hero in ipairs(self.chooseHeros) do
	-- 	hero.slot=index
	-- end
end

function TrialChooseHeroLayer:findMinSlod()
	local function existSlod(slot)
		for _,hero in ipairs(self.chooseHeros) do
			if hero.slot==slot then
				return true
			end
		end
		return false
	end

	local index=1
	for i=1,6 do
		index=i
		if not existSlod(index) then
			return index
		end
	end

	return index
end

function TrialChooseHeroLayer:existChooseHero(chooseHero)
	for _,hero in pairs(self.chooseHeros) do
		if hero.type==chooseHero.type then
			return true
		end
	end

	return false
end

-- 内容层
function TrialChooseHeroLayer:initHeroList(curtype)

	if self.contentLayer then
		self.contentLayer:removeSelf()
	end

	self.contentLayer = display.newLayer()
	self.contentLayer:setContentSize(self:getContentSize())
	self.contentLayer:addTo(self,1)

	local cellSize = CCSizeMake(120, 120)
	local columns = 5

	local viewBg = display.newLayer(ExpeditonRes.."chooseHeroBg.png")
	viewBg:size(673, 328)
	local viewSize = CCSizeMake(viewBg:getContentSize().width, viewBg:getContentSize().height)
	viewBg:anch(0.5, 0):pos(display.cx-56, 209):addTo(self.contentLayer)


	local function createCellNode(parentNode, cellIndex)
		parentNode:removeAllChildren()
		parentNode:setContentSize(CCSizeMake(viewSize.width, cellSize.height + 10))

		local xBegin = 40
		local xInterval = (viewSize.width - 2 * xBegin - columns * cellSize.width) / (columns - 1)
		local rows = math.ceil(#self.heroFilter:getResult() / columns)
		for index = (rows - cellIndex - 1) * columns + 1, columns * (rows - cellIndex) do
			local hero = self.heroFilter:getResult()[index]
			local nativeIndex = index - (rows - cellIndex - 1) * columns
			local cellNode = display.newNode()
			cellNode:size(cellSize)

			if hero then
				local heroCell = self:createCell({ type = hero.type, level = hero.level, wakeLevel = hero.wakeLevel, star = hero.star,
					evolutionCount = hero.evolutionCount, priority = self.priority,blood=hero.blood ,isOn=hero.isOn,
					parent = viewBg,
					callback = function()
						if #self.chooseHeros<5 then
							--同一武将只能上一个
							if hero.isOn==2 then
								--未上阵
								if not self:existChooseHero(hero) then
									self:updataHerosIsOn({HeroId=hero.id,isOn=hero.isOn and (hero.isOn==1 and 2 or 1) or 1} )

									self.heroTableView:reloadData()

									self:initBottonUI()
								else
									DGMsgBox.new({text="您已有相同的武将上阵!",type=1})
								end

							else
								--已上阵
								self:updataHerosIsOn({HeroId=hero.id,isOn=hero.isOn and (hero.isOn==1 and 2 or 1) or 1} )

								self.heroTableView:reloadData()

								self:initBottonUI()
							end
							
							
						else
							if hero.isOn==1 then
								self:updataHerosIsOn({HeroId=hero.id,isOn=hero.isOn and (hero.isOn==1 and 2 or 1) or 1} )

								self.heroTableView:reloadData()

								self:initBottonUI()
							else
								echoInfo("choose hero max %d", 5)
							end
							
						end

					end
				})
				heroCell:anch(0, 0):addTo(cellNode)

				
			end

			cellNode:anch(0, 0):pos(xBegin + (cellSize.width + xInterval) * (nativeIndex - 1), 10)
				:addTo(parentNode)
		end
	end

	local viewHandler = LuaEventHandler:create(function(fn, table, a1, a2)
		local result
		if fn == "cellSize" then
			result = CCSizeMake(viewSize.width, cellSize.height + 10)

		elseif fn == "cellAtIndex" then
			if not a2 then
				a2 = CCTableViewCell:new()
				local cell = display.newNode()
				a2:addChild(cell, 0, 1)
			end

			-- 更新cell
			local cell = tolua.cast(a2:getChildByTag(1), "CCNode")
			createCellNode(cell, a1)
			result = a2

		elseif fn == "numberOfCells" then
			result = math.ceil(#self.heroFilter:getResult() / columns)
		end

		return result
	end)

	self.heroTableView = LuaTableView:createWithHandler(viewHandler, viewSize)
	self.heroTableView:setBounceable(true)
	self.heroTableView:setTouchPriority(self.priority - 5)
	self.heroTableView:setPosition(ccp(0, 31))
	viewBg:addChild(self.heroTableView)
end

function TrialChooseHeroLayer:createCell(params)
	local heroBtn = HeroHead.new( 
	{
		type = params.type and params.type or 0,
		wakeLevel = params.wakeLevel,
		star = params.star,
		evolutionCount = params.evolutionCount,
		heroLevel = params.level,
		hideStars = true,
		priority = params.priority,
		isOn=params.isOn,
		callback = params.callback,
	}):getLayer()

	return heroBtn
end


function TrialChooseHeroLayer:getLayer()
	return self.mask:getLayer()
end

function TrialChooseHeroLayer:onExit()
end


return TrialChooseHeroLayer