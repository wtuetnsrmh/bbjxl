-- 美人列表
-- by yangkun
-- 2014.7.2

local GlobalRes = "resource/ui_rc/global/"
local BeautyRes = "resource/ui_rc/beauty/"
local HeroRes = "resource/ui_rc/hero/"

local Beauty = require("datamodel.Beauty")
local BeautyTrainLayer = import(".BeautyTrainLayer")

local BeautyListLayer = class("BeautyListLayer", function(params) 
	return display.newLayer(GlobalRes .. "inner_bg.png") 
end)

function BeautyListLayer:ctor(params)

	params = params or {}

	self.priority = params.priority or -130
	self.curBeautyIndex = 1
	self.curBeauty = nil

	self.closeCB = params.closeCB

	self.beauties = self:prepareBeauties()
	self.curBeautyData = self.beauties[self.curBeautyIndex]

	self:initUI()
end

-- 处理所有美人数据
function BeautyListLayer:prepareBeauties()
	local beauties = {}
	local fightBeauties = {}
	local restBeauties = {}
	local nonEmployBeauties = {}
	local inactiveBeauties = {}
	local myBeauties = game.role.beauties
	local allBeauties = beautyListCsv:getAllData()
	-- 处理自己的美人
	for _,beauty in pairs(myBeauties) do
		if beauty.status == beauty.class.STATUS_FIGHT then
			table.insert(fightBeauties, beautyListCsv:getBeautyById(beauty.beautyId))
		elseif beauty.status == beauty.class.STATUS_REST then
			table.insert(restBeauties, beautyListCsv:getBeautyById(beauty.beautyId))
		end
	end

	-- 处理未招募和未激活的美人
	for _,beautyData in pairs(allBeauties) do
		local flag = 0
		for _,myBeauty in pairs(myBeauties) do
			if beautyData.beautyId == myBeauty.beautyId then
				flag = 1
			end
		end

		if flag == 0 then
			-- 已激活未招募
			if beautyData.activeLevel <= game.role.level then
				table.insert(nonEmployBeauties, beautyData)
			else
				table.insert(inactiveBeauties, beautyData)
			end
		end
	end

	table.sort(fightBeauties, function(a,b) return a.beautyId > b.beautyId end)
	table.sort(restBeauties, function(a,b) return a.beautyId > b.beautyId end)
	table.sort(nonEmployBeauties, function(a,b) return a.beautyId > b.beautyId end)
	table.sort(inactiveBeauties, function(a,b) return a.beautyId > b.beautyId end)

	table.insertTo(beauties, fightBeauties)
	table.insertTo(beauties, restBeauties)
	table.insertTo(beauties, nonEmployBeauties)
	table.insertTo(beauties, inactiveBeauties)

	return beauties
end

function BeautyListLayer:getBeautyStatus(beautyData)
	for _,beauty in pairs(game.role.beauties) do
		if beauty.beautyId == beautyData.beautyId then
			return beauty.status
		end
	end
	if beautyData.activeLevel <= game.role.level then
		return Beauty.STATUS_NON_EMPLOY
	else
		return Beauty.STATUS_INACTIVE
	end
end

function BeautyListLayer:getBeautyLevel(beautyData)
	for _,beauty in pairs(game.role.beauties) do
		if beauty.beautyId == beautyData.beautyId then
			return beauty.level + (beauty.evolutionCount - 1) * beautyData.evolutionLevel
		end
	end
	return 1
end

function BeautyListLayer:getBeautyEvolutionCount(beautyData)
	for _,beauty in pairs(game.role.beauties) do
		if beauty.beautyId == beautyData.beautyId then
			return beauty.evolutionCount
		end
	end
	return 0
end

function BeautyListLayer:initUI()
	self.size = self:getContentSize()

	self.innerBg = display.newSprite()
	self.innerBg:size(self.size)
	self.innerBg:anch(0.5,0.5):pos(self:getContentSize().width/2, self:getContentSize().height/2):addTo(self)

	-- 遮罩层
	self:anch(0, 0):pos((display.width - 960) / 2, 0)
	self.mask = DGMask:new({ item = self, priority = self.priority + 1, bg = HomeRes .. "home.jpg" })

	local closeBtn = DGBtn:new(GlobalRes, {"close_normal.png", "close_selected.png"},
		{	
			touchScale = 1.5,
			priority = self.priority,
			callback = function()
				self:getLayer():removeSelf()
				if self.closeCB then self.closeCB() end
			end,
		}):getLayer()
	closeBtn:anch(0.7, 0.5):pos(self.size.width, self.size.height):addTo(self,100)

	self.tabCursor = display.newSprite(GlobalRes .. "tab_arrow.png")
	self.tabCursor:anch(0, 0.5):pos(self.size.width - 25, 470):addTo(self,100)

	local tabRadio = DGRadioGroup:new()
	local beautyBtn = DGBtn:new(GlobalRes, {"tab_normal.png", "tab_selected.png"},
		{	
			--front = BeautyRes .. "text_beauty.png",
			priority = self.priority,
			callback = function()
			end
		}, tabRadio)
	beautyBtn:getLayer():anch(0, 0.5):pos(self.size.width - 14, 470):addTo(self)
	local tabSize = beautyBtn:getLayer():getContentSize()
	ui.newTTFLabelWithStroke({ text = "美人", dimensions = CCSizeMake(tabSize.width / 2, tabSize.height), size = 26, font = ChineseFont,
		color = display.COLOR_WHITE, strokeColor = uihelper.hex2rgb("#242424") })
		:pos(tabSize.width / 2, tabSize.height / 2):addTo(beautyBtn:getLayer())

	local TopBarLayer = require("scenes.TopBarLayer")
	local layer  = TopBarLayer.new({priority = self.priority})
	:anch(0,1):pos(0,display.height):addTo(self)
end

function BeautyListLayer:getLayer()
	return self.mask:getLayer()
end

function BeautyListLayer:onEnter()
	self:initContentLayer()
	self:checkGuide()
end

function BeautyListLayer:checkGuide(remove)
	--招募
	game:addGuideNode({node = self.employBtn, remove = remove,
		guideIds = {1213}
	})
	--出战
	if self.slider and self.curBeauty.status == Beauty.STATUS_REST then
		local worldPos = self.slider:convertToWorldSpace(ccp(0, 0))
		local size = self.slider:getContentSize()
		game:addGuideNode({rect = CCRectMake(worldPos.x, worldPos.y, size.width/2, size.height), remove = remove,
			guideIds = {1214}
		})
	end
	--培养
	if self.trainBtn then
		game:addGuideNode({node = self.trainBtn:getLayer(), remove = remove,
			guideIds = {1215}
		})
	end
end

function BeautyListLayer:onExit()
	self:checkGuide(true)
end

-- 内容层
function BeautyListLayer:initContentLayer()
	if self.contentLayer then
		self.contentLayer:removeSelf()
	end

	self.contentLayer = display.newLayer()
	self.contentLayer:size(self.size):addTo(self)

	-- display.newSprite(BeautyRes .. "list_bg.png")
	-- :anch(0.5,0.5):pos(self.size.width/2, self.size.height/2):addTo(self.contentLayer)

	self:initContentLeft()
	self:initContentRight()
end

-- 左边层
function BeautyListLayer:initContentLeft()
	self.leftContentLayer = display.newLayer()
	self.leftContentLayer:size(CCSizeMake(272, 530))
	self.leftContentLayer:pos(28, self.size.height - 560):addTo(self.contentLayer)

	self.tableView = self:createListTable()
	self.tableView:setPosition(0,2)
	self.leftContentLayer:addChild(self.tableView)

	display.newSprite(GlobalRes .. "arrow_down.png")
	:anch(0.5,0.5):scale(0.8):pos(self.leftContentLayer:getContentSize().width/2, 0):addTo(self.leftContentLayer)
end

function BeautyListLayer:createListTable()
	local cellSize = CCSizeMake(266, 100)

	local handler = LuaEventHandler:create(function(fn, table, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(cellSize.width, cellSize.height)
        elseif fn == "cellAtIndex" then
			if not a2 then
                a2 = CCTableViewCell:new()
                local cell = display.newNode()
                a2:addChild(cell, 0, 1)
            end

            local cell = tolua.cast(a2:getChildByTag(1), "CCNode")
            cell:removeAllChildren()

            local index = a1
            self:createBeautyListCell(cell, index)
            r = a2
        elseif fn == "numberOfCells" then
            r = #self.beauties
        end

        return r
    end)

	local size = CCSizeMake(self.leftContentLayer:getContentSize().width, self.leftContentLayer:getContentSize().height-24)
	local beautyTableView = LuaTableView:createWithHandler(handler, size)
    beautyTableView:setBounceable(true)
    beautyTableView:setTouchPriority(self.priority -2)
	return beautyTableView
end

function BeautyListLayer:getBeautyByData(beautyData)
	for _,beauty in pairs(game.role.beauties) do
		if beauty.beautyId == beautyData.beautyId then
			return beauty
		end
	end
	return nil
end

function BeautyListLayer:createBeautyByData(beautyData)
	local beauty = {}
	beauty.beautyId = beautyData.beautyId
	beauty.level = 1
	beauty.evolutionCount = 1
	beauty.potentialHp = 0
	beauty.potentialAtk = 0
	beauty.potentialDef = 0

	if beautyData.activeLevel <= game.role.level then
		beauty.status = Beauty.STATUS_NON_EMPLOY
	else
		beauty.status = Beauty.STATUS_INACTIVE
	end

	return beauty
end

function BeautyListLayer:createBeautyListCell(cellNode, index)
	local cellSize = CCSizeMake(266, 108)

	local beautyData = self.beauties[#self.beauties - index]

	local beautyBtn = DGBtn:new(BeautyRes, {"cell_bg.png","cell_bg.png","cell_bg.png"},
		{
			callback = function ()
				self.curBeautyIndex = #self.beauties - index
				self.curBeautyData = self.beauties[self.curBeautyIndex]
				self:initContentRight()
				self.descBg = nil

				if self.curChoose then
					self.curChoose:removeSelf()
				end
				
				local curOffset = self.tableView:getContentOffset()
				self.tableView:reloadData()
				self.tableView:setBounceable(false)
				self.tableView:setContentOffset(curOffset)
				self.tableView:setBounceable(true)
			end,
			priority = self.priority -1,
		}):getLayer()
	if beautyData == self.curBeautyData then
		display.newSprite(BeautyRes .. "cell_choose.png")
			:anch(0.5,0.5):pos(cellSize.width/2, cellSize.height/2 -4):addTo(cellNode, 1)
	end

	-- 头像
	local frameRes = beautyData and string.format("frame_%d.png", beautyData.star) or "frame_5.png"

	local btn = DGBtn:new(GlobalRes, {frameRes}, {})
	local frameSize = btn:getLayer():getContentSize()
	display.newSprite(beautyData.headImage):pos(frameSize.width / 2, frameSize.height / 2)
		:addTo(btn:getLayer(), -1)
	btn:getLayer():scale(0.8):anch(0,0.5):pos(5, beautyBtn:getContentSize().height/2 + 1):addTo(beautyBtn)

	-- 名字
	ui.newTTFLabel({ text = beautyData.beautyName, size = 22})
	:anch(0,0):pos(110, beautyBtn:getContentSize().height - 46):addTo(beautyBtn)

	local evolution = self:getBeautyEvolutionCount(beautyData)
	local level = self:getBeautyLevel(beautyData)

	-- ui.newTTFLabel({ text = string.format("%d阶", evolution), size = 20 })
	-- :anch(0,0):pos(190, beautyBtn:getContentSize().height - 41):addTo(beautyBtn)
	-- :setVisible(evolution > 0)

	ui.newTTFLabel({ text = string.format("Lv %d", level),font=ChineseFont , size = 18,color=uihelper.hex2rgb("#ffde7d")})
	:anch(0,0):pos(200, beautyBtn:getContentSize().height - 44):addTo(beautyBtn)

	local status = self:getBeautyStatus(beautyData)

	if status == Beauty.STATUS_FIGHT then
		local statusBg = display.newSprite(BeautyRes .. "status_fight.png")
		statusBg:anch(0,0):pos(140,beautyBtn:getContentSize().height - 86):addTo(beautyBtn)
	elseif status == Beauty.STATUS_REST then
		local statusBg = display.newSprite(BeautyRes .. "status_rest.png")
		statusBg:anch(0,0):pos(140,beautyBtn:getContentSize().height - 86):addTo(beautyBtn)
	else
		local statusBg = display.newSprite(BeautyRes .. "status_non_employ.png")
		statusBg:anch(0,0):pos(140,beautyBtn:getContentSize().height - 86):addTo(beautyBtn)
	end

	if status == Beauty.STATUS_INACTIVE then
		--display.newSprite(BeautyRes .. "cell_mask.png"):anch(0.5,0.5):pos(cellSize.width/2, cellSize.height/2):addTo(cellNode, 1)
	end

	beautyBtn:anch(0.5, 0):pos(cellSize.width/2, 0):addTo(cellNode)
end

local function addTipsZone(params)
	params = params or {}
	if not params.node then return end

	local tipsZone = DGBtn:new(BeautyRes, {}, {
		priority = params.priority - 1,
		callback = function()
			local tipsBg = display.newSprite(GlobalRes .. "tips_small.png")
			local bgSize = tipsBg:getContentSize()
			local mask
			mask = DGMask:new({ item = tipsBg, opacity = 0, priority = params.priority - 1000, click = function() mask:remove() end })
			mask:getLayer():addTo(display.getRunningScene())
			display.align(tipsBg, params.anchorPoint or display.CENTER_RIGHT)
			tipsBg:setPosition(params.node:convertToWorldSpace(ccp(0, 0)))

			ui.newTTFLabel({text = "---提供所有武将的属性加成---", size = 20, color = display.COLOR_YELLOW})
				:anch(0.5, 1):pos(bgSize.width/2, bgSize.height - 20):addTo(tipsBg)
			DGRichLabel.new({text = string.format("生命：[color=00ff00]+%d[/color]", params.hp * globalCsv:getFieldValue("beautyHpFactor")), size = 20})
				:anch(0, 0.5):pos(50, bgSize.height/2):addTo(tipsBg)
			DGRichLabel.new({text = string.format("攻击：[color=00ff00]+%d[/color]", params.atk * globalCsv:getFieldValue("beautyAtkFactor")), size = 20})
				:anch(0, 0.5):pos(210, bgSize.height/2):addTo(tipsBg)
			DGRichLabel.new({text = string.format("防御：[color=00ff00]+%d[/color]", params.def * globalCsv:getFieldValue("beautyDefFactor")), size = 20})
				:anch(0, 0.5):pos(370, bgSize.height/2):addTo(tipsBg)
		end	
	}):getLayer()
	return tipsZone
end

-- 右边层
function BeautyListLayer:initContentRight()
	if self.rightContentLayer then
		self.rightContentLayer:stopAllActions()
		self.rightContentLayer:removeAllChildren()
		self.rightContentLayer:removeSelf()
	end

	if self:getBeautyStatus(self.curBeautyData) ~= Beauty.STATUS_INACTIVE and 
		self:getBeautyStatus(self.curBeautyData) ~= Beauty.STATUS_NON_EMPLOY then
		self.curBeauty = self:getBeautyByData(self.curBeautyData)
	else
		self.curBeauty = self:createBeautyByData(self.curBeautyData)
	end

	self.rightContentLayer = display.newLayer()
	self.rightContentLayer:size(CCSizeMake(574,self.contentLayer:getContentSize().height))
	:pos(302, 5):addTo(self.contentLayer)

	local rightSize = self.rightContentLayer:getContentSize()
	display.newSprite(BeautyRes .. "list_right.png"):anch(0,0):pos(0, rightSize.height - 558):addTo(self.rightContentLayer)

	-- 美人前景：
	local heroBg = display.newLayer()
	heroBg:size(CCSizeMake(374, 508))
	heroBg:anch(0,0):pos(0 ,self.size.height - 556):addTo(self.rightContentLayer)

	-- 美人图片
	--local beautyPic = display.newSprite( self.curBeautyData.heroRes )
	print(self.curBeautyData.heroMaskRes)
	local beautyPic=uihelper.createMaskSprite(self.curBeautyData.heroRes,self.curBeautyData.heroMaskRes)
	local scale = 1.1/2
	beautyPic:scale(scale):anch(0.5,0.5):pos(heroBg:getContentSize().width/2, heroBg:getContentSize().height/2):addTo(heroBg, -1)

	local time = 1.7
	local dtime = 0.3
	beautyPic:runAction(CCRepeatForever:create(transition.sequence({
			CCDelayTime:create(dtime),
			CCScaleTo:create(time, scale + 0.015),
			CCDelayTime:create(dtime),
			CCScaleTo:create(time, scale),
		})))
	local d1 = CCDelayTime:create(dtime)
	local moveBy = CCMoveBy:create(time, ccp(0, 3))
	local d2 = CCDelayTime:create(dtime)
	local rev=moveBy:reverse()
	local actionArr1 = CCArray:create()
	actionArr1:addObject(d1)
	actionArr1:addObject(moveBy)
	actionArr1:addObject(d2)
	actionArr1:addObject(rev)
	local seq  = CCSequence:create(actionArr1)
	local repeatForever =CCRepeatForever:create(seq);
	beautyPic:runAction(repeatForever)

	-- 名字
	local nameBg = display.newSprite( BeautyRes .. "name_bg.png")
	nameBg:anch(0.5,1):pos(heroBg:getContentSize().width/2, heroBg:getContentSize().height):addTo(heroBg,1)

	if self:getBeautyEvolutionCount(self.curBeautyData) > 0 then
		local nameLable=ui.newTTFLabel({ text = string.format("%s ",self.curBeautyData.beautyName)
			, size = 28,font=ChineseFont , color = display.COLOR_WHITE})
		:anch(0,0.5):pos(nameBg:getContentSize().width/2, nameBg:getContentSize().height/2):addTo(nameBg)
		local levelLabel=ui.newTTFLabel({ text = string.format("%d阶",self:getBeautyEvolutionCount(self.curBeautyData) )
			, size = 28,font=ChineseFont , color = uihelper.hex2rgb("#ffd200")})
		:anch(0,0.5):pos(nameBg:getContentSize().width/2, nameBg:getContentSize().height/2):addTo(nameBg)
		nameLable:setPositionX((nameBg:getContentSize().width-nameLable:getContentSize().width-levelLabel:getContentSize().width)/2)
		levelLabel:setPositionX(nameLable:getPositionX()+nameLable:getContentSize().width)

	else
		ui.newTTFLabel({ text = string.format("%s",self.curBeautyData.beautyName ), size = 28, color = display.COLOR_WHITE, strokeColor = display.COLOR_BROWNSTROKE, strokeSize = 2 })
		:pos(nameBg:getContentSize().width/2, nameBg:getContentSize().height/2):addTo(nameBg)
	end

	-- 星级
	local startY = heroBg:getContentSize().height - 107
	for index = 1, self.curBeautyData.star do
		local x = 40
		local y = startY - (index - 1) * 46
		display.newSprite(GlobalRes .. "star/icon_big.png"):pos(x,y):addTo(heroBg, 2)
	end

	-- 技能框
	local skillBg = display.newSprite( BeautyRes .. "skill_bg.png")
	skillBg:anch(0.5,0):pos(heroBg:getContentSize().width/2+5, 15):addTo(heroBg, 1)

	local startX = 20
	for index = 1, 3 do
		local skillId = tonum(self.curBeautyData["beautySkill" .. index])
		local passiveSkillData = skillPassiveCsv:getPassiveSkillById(skillId)

		local skillBtn = DGBtn:new(GlobalRes, {"item_7.png"}, {
				callback = function()
					if self.descBg then
						self.descBg:removeSelf()
						self.descBg = nil
					end

					self.descBg = display.newSprite(HeroRes .. "choose/assist_bg.png")
					self.descBg:anch(0.5,0):pos(heroBg:getContentSize().width/2, skillBg:getPositionY()+skillBg:getContentSize().height-10):addTo(heroBg,3)
					:runAction(transition.sequence({
							CCDelayTime:create(2),
							CCRemoveSelf:create(),
							CCCallFunc:create(function() self.descBg = nil end)
						}))

					-- 技能名
					ui.newTTFLabel({text = string.format("【%s】", passiveSkillData.name), size = 22, color = display.COLOR_GREEN})
					:anch(0,0):pos(15, 85):addTo(self.descBg)

					if self.curBeauty.evolutionCount < index then
						ui.newTTFLabel({text = string.format("(%d阶激活)", index), size = 22, color = display.COLOR_GREEN})
						:anch(0,0):pos(130, 85):addTo(self.descBg)
					end

					ui.newTTFLabel({text = passiveSkillData.desc, size = 18,
						dimensions = CCSizeMake(self.descBg:getContentSize().width - 40, 40) })
						:anch(0,0):pos(20, 30):addTo(self.descBg)
				end,
				priority = self.priority -1
			}):getLayer()
		local x = startX + (index - 1) * 110
		skillBtn:scale(0.8):anch(0,0.5):pos(x, skillBg:getContentSize().height/2):addTo(skillBg)

		local skillImage = display.newSprite(passiveSkillData.icon):pos(skillBtn:getContentSize().width/2, skillBtn:getContentSize().height/2)
		:addTo(skillBtn, -1)

		if self.curBeauty.evolutionCount < index then
			skillImage:setColor(ccc3(64,64,64))
		end

	end

	-- 属性背景框
	local attrBg = display.newLayer()
	attrBg:size(CCSizeMake(216,507))
	attrBg:anch(0,0):pos(360, rightSize.height - 580):addTo(self.rightContentLayer)
	local bgSize = attrBg:getContentSize()

	if self.curBeauty.status == Beauty.STATUS_FIGHT or self.curBeauty.status == Beauty.STATUS_REST then
		display.newSprite(BeautyRes .. "detail_bg_short.png"):anch(0.5,1):pos(bgSize.width/2, bgSize.height - 8):addTo(attrBg)
	else
		display.newSprite(BeautyRes .. "detail_bg_long.png"):anch(0.5,1):pos(bgSize.width/2, bgSize.height - 8):addTo(attrBg)
	end

	-- 美色、才艺、品德（生命 攻击 防御）
	local levelPerEvolution = self.curBeautyData.evolutionLevel
	local curLevel = (self.curBeauty.evolutionCount - 1) * levelPerEvolution + self.curBeauty.level
	local curHp = self.curBeautyData.hpGrow * (curLevel - 1) + self.curBeautyData.hpInit
	local curAtk = self.curBeautyData.atkGrow * (curLevel - 1) + self.curBeautyData.atkInit
	local curDef = self.curBeautyData.defGrow * (curLevel - 1) + self.curBeautyData.defInit

	local titleBg1 = display.newSprite( BeautyRes .. "title_bg.png")
	titleBg1:anch(0.5,0):pos(bgSize.width/2, bgSize.height - 42):addTo(attrBg)

	local employLabel = ui.newTTFLabel({text="基础属性",font=ChineseFont ,size=20,color=uihelper.hex2rgb("#ffde7d")})
	employLabel:anch(0.5,0):pos(bgSize.width/2, bgSize.height - 43):addTo(attrBg)
	-- 基础属性
	local tipsZone = addTipsZone({node = employLabel, hp = curHp, atk = curAtk, def = curDef, priority = self.priority})
	tipsZone:size(bgSize.width, 75):anch(0, 1):pos(0, bgSize.height - 43):addTo(attrBg)

	ui.newTTFLabel({text = string.format("美色 : %d", curHp), size = 18})
	:anch(0,0): pos(65, bgSize.height - 70):addTo(attrBg)

	ui.newTTFLabel({text = string.format("才艺 : %d", curAtk), size = 18})
	:anch(0,0): pos(65, bgSize.height - 95):addTo(attrBg)

	ui.newTTFLabel({text = string.format("品德 : %d", curDef), size = 18})
	:anch(0,0): pos(65, bgSize.height - 120):addTo(attrBg)

	local titleBg2 = display.newSprite( BeautyRes .. "title_bg.png")
	titleBg2:anch(0.5,0):pos(bgSize.width/2, bgSize.height - 152):addTo(attrBg)

	local employLabel = ui.newTTFLabel({text="潜力评价",font=ChineseFont ,size=20,color=uihelper.hex2rgb("#ffde7d")})
	employLabel:anch(0.5,0):pos(bgSize.width/2, bgSize.height - 152):addTo(attrBg)

	local pingjiaBg = display.newSprite( BeautyRes .. "pingjia_bg.png")
	:anch(0.5,0.5):pos(bgSize.width/2, bgSize.height - 173):addTo(attrBg)

	-- 潜力评价
	local temp={
		["十里挑一"]="potential_1.png",
		["百里挑一"]="potential_2.png",
		["千里挑一"]="potential_3.png",
		["万里挑一"]="potential_4.png",
		["天下无双"]="potential_5.png"
	}
	
	display.newSprite(BeautyRes..temp[self.curBeautyData.potentialDesc])
	:pos(pingjiaBg:getContentSize().width/2, pingjiaBg:getContentSize().height/2):addTo(pingjiaBg)

	if self.curBeauty.status == Beauty.STATUS_FIGHT or self.curBeauty.status == Beauty.STATUS_REST then
		-- 潜力属性
		local titleBg3 = display.newSprite( BeautyRes .. "title_bg.png")
		titleBg3:pos(bgSize.width/2, bgSize.height - 212):addTo(attrBg)

		local potentialAttr = ui.newTTFLabel({text="潜力属性",font=ChineseFont ,size=20,color=uihelper.hex2rgb("#ffde7d")})
		potentialAttr:pos(bgSize.width/2, bgSize.height - 212):addTo(attrBg)

		local tipsZone = addTipsZone({node = potentialAttr, hp = self.curBeauty.potentialHp, atk = self.curBeauty.potentialAtk, def = self.curBeauty.potentialDef, priority = self.priority})
		tipsZone:size(bgSize.width, 75):anch(0, 1):pos(0, bgSize.height - 222):addTo(attrBg)

		ui.newTTFLabel({text = string.format("美色 : %d", self.curBeauty.potentialHp), size = 18})
		:anch(0,0): pos(65, bgSize.height - 252):addTo(attrBg)

		ui.newTTFLabel({text = string.format("才艺 : %d", self.curBeauty.potentialAtk), size = 18})
		:anch(0,0): pos(65, bgSize.height - 279):addTo(attrBg)

		ui.newTTFLabel({text = string.format("品德 : %d", self.curBeauty.potentialDef), size = 18})
		:anch(0,0): pos(65, bgSize.height - 302):addTo(attrBg)

	end

	-- 加button
	if self.curBeauty.status == Beauty.STATUS_INACTIVE  or self.curBeauty.status == Beauty.STATUS_NON_EMPLOY then
		-- 招募
		local titleBg4 = display.newSprite( BeautyRes .. "title_bg.png")
		titleBg4:pos(bgSize.width/2, bgSize.height - 212):addTo(attrBg)

		local employLabel = ui.newTTFLabel({text="招募条件",font=ChineseFont ,size=20,color=uihelper.hex2rgb("#ffde7d")})
		employLabel:pos(bgSize.width/2, bgSize.height - 212):addTo(attrBg)

		-- 激活条件
		ui.newTTFLabel({ text = string.format("人物等级" ), size = 18})
		:anch(0.5,0.5):pos(bgSize.width/2, bgSize.height - 243):addTo(attrBg)

		local levelLabel = ui.newTTFLabel({ text = string.format("%d", self.curBeautyData.activeLevel), 
			size = 18, 
			color = game.role.level >= self.curBeautyData.activeLevel and uihelper.hex2rgb("#7ce810") or uihelper.hex2rgb("#ff0000") })
			:anch(0.5,0.5):pos(bgSize.width/2, bgSize.height - 263):addTo(attrBg)

		display.newSprite(BeautyRes.."division_PropertyBeauty.png"):anch(0.5,1):pos(bgSize.width/2,bgSize.height - 275)
		:addTo(attrBg)

		local y = 285
		if self.curBeautyData.preBeautyId > 0 then
			ui.newTTFLabel({ text = string.format("需要招募美人"), size = 18, strokeColor = display.COLOR_BROWNSTROKE, strokeSize = 2})
			:anch(0.5,0.5):pos(bgSize.width/2, bgSize.height - y-7):addTo(attrBg)

			local beautyData = beautyListCsv:getBeautyById(self.curBeautyData.preBeautyId)
			local nameLabel = ui.newTTFLabel({ text = beautyData.beautyName, size = 18})
			:anch(0.5,0.5):pos(bgSize.width / 2, bgSize.height - y - 30):addTo(attrBg)
			nameLabel:setColor(game.role:hasBeauty(self.curBeautyData.preBeautyId) and display.COLOR_GREEN or display.COLOR_RED)

			y = y + 55
		end

		display.newSprite(BeautyRes.."division_PropertyBeauty.png"):anch(0.5,1):pos(bgSize.width/2,bgSize.height - y +10)
		:addTo(attrBg)

		if self.curBeautyData.preChallengeId > 0 then
			ui.newTTFLabel({ text = string.format("通关副本"), size = 18, strokeColor = display.COLOR_BROWNSTROKE, strokeSize = 2})
			:anch(0.5,0.5):pos(bgSize.width/2, bgSize.height - y-5):addTo(attrBg)

			y = y + 30
			local carbonData = mapBattleCsv:getCarbonById(self.curBeautyData.preChallengeId)
			local chapterNum =  ( self.curBeautyData.preChallengeId - 20000 ) / 100
			local carbonLabel = ui.newTTFLabel({ text = string.format("第%d章 %s", chapterNum, carbonData.name), size = 18})
			:anch(0.5,0.5):pos(bgSize.width / 2, bgSize.height - y):addTo(attrBg)
			local isPass = game.role.carbonDataset[self.curBeautyData.preChallengeId] and game.role.carbonDataset[self.curBeautyData.preChallengeId].starNum > 0
			carbonLabel:setColor( isPass and display.COLOR_GREEN or display.COLOR_RED)
		end

		local btn = DGBtn:new(GlobalRes, {"middle_normal.png", "middle_selected.png", "middle_disabled.png"},
			{
				priority = self.priority - 2,
				text = { text = "招募" , size = 30, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
				callback = function()
					local employRequest = { roleId = game.role.id, param1 = self.curBeauty.beautyId }
					local bin = pb.encode("SimpleEvent", employRequest)

					game:sendData(actionCodes.BeautyEmployRequest, bin, #bin)
					game:addEventListener(actionModules[actionCodes.BeautyEmployResponse], function(event)
						local beauty = pb.decode("BeautyDetail", event.data)

						local newBeauty = require("datamodel.Beauty").new(beauty)
						game.role.beauties[beauty.beautyId] = newBeauty

						self.beauties = self:prepareBeauties()
						self.tableView:reloadData()
						self:initContentRight()

						return "__REMOVE__"
					end)
				end
			})
		btn:setEnable(self:canEmploy())
		btn:getLayer():anch(0.5,0):pos(bgSize.width/2, bgSize.height - 450):addTo(attrBg)
		self.employBtn = btn:getLayer()

		-- 招募花费
		local costBg = display.newScale9Sprite(BeautyRes .. "bg_costBeauty.png", 15,0, CCSizeMake(69,21))
		:anch(0,0.5):pos(50, bgSize.height - 463):addTo(attrBg)
		if self.curBeautyData.employMoney[1] == "1" then
			display.newSprite(GlobalRes .. "yinbi.png")
				:pos(73, bgSize.height - 463):addTo(attrBg)
			local costLabel=ui.newTTFLabel({ text = self.curBeautyData.employMoney[2], size = 18, color = display.COLOR_WHITE})
				:anch(0, 0.5):pos(96, bgSize.height - 463):addTo(attrBg)
			costBg:setContentSize(CCSize(60+costLabel:getContentSize().width,21))
			costBg:anch(0,0.5)
			costBg:setPositionX(50)
		else
			display.newSprite(GlobalRes .. "yuanbao.png")
				:scale(0.8,0.8):pos(73, bgSize.height - 463):addTo(attrBg)
			local costLabel=ui.newTTFLabel({ text = self.curBeautyData.employMoney[2], size = 18, color = display.COLOR_WHITE})
				:anch(0, 0.5):pos(96, bgSize.height - 463):addTo(attrBg)
			costBg:setContentSize(CCSize(60+costLabel:getContentSize().width,21))
			costBg:anch(0,0.5)
			costBg:setPositionX(50)
		end
		
	elseif self.curBeauty.status == Beauty.STATUS_REST then

		local slider = DGSlider:new(BeautyRes .. "status_bg.png", BeautyRes .. "btn_rest.png", {
			segments = 2,
			curSeg = 2,
			priority = self.priority - 1,
			callback = function(curSeg)
				local featureOpenInfo = roleInfoCsv:getDataByLevel(game.role.level)
				local fightRequest = { roleId = game.role.id, param1 = self.curBeauty.beautyId }
				local bin = pb.encode("SimpleEvent", fightRequest)

				game:sendData(actionCodes.BeautyFightRequest, bin, #bin)
				game:addEventListener(actionModules[actionCodes.BeautyFightResponse], function(event)
					local msg = pb.decode("SimpleEvent", event.data)

					if msg.param1 == 1 then
						for _,beauty in pairs(game.role.beauties) do
							if beauty.status == beauty.class.STATUS_FIGHT then
								beauty.status = beauty.class.STATUS_REST
							end
						end
						self.curBeauty.status = Beauty.STATUS_FIGHT
						self.beauties = self:prepareBeauties()
						self.tableView:reloadData()
						self:initContentRight()
					end
					return "__REMOVE__"
				end)
			end
			}):getLayer()
		slider:anch(0.5,0):pos(bgSize.width/2, bgSize.height - 360):addTo(attrBg)
		self.slider = slider

		display.newSprite(BeautyRes .. "status_rest.png"):anch(0.5,0):pos(bgSize.width/2, bgSize.height - 400):addTo(attrBg)
		
		self.trainBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png", "middle_disabled.png"},
			{
				priority = self.priority - 2,
				text = { text = "培养" , font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
				callback = function()
					local layer = BeautyTrainLayer.new({beauty = self.curBeauty, priority = self.priority -10, closeCallback = function() self:initContentRight() end})
					layer:getLayer():addTo(display.getRunningScene())
				end
			})
		self.trainBtn:getLayer():anch(0.5,0):pos(bgSize.width/2, bgSize.height - 470):addTo(attrBg)

	elseif self.curBeauty.status == Beauty.STATUS_FIGHT then
		local slider = DGSlider:new(BeautyRes .. "status_bg.png", BeautyRes .. "btn_fight.png", {
			segments = 2,
			curSeg = 1,
			priority = self.priority - 1,
			callback = function(curSeg)
				local restRequest = { roleId = game.role.id, param1 = self.curBeauty.beautyId }
				local bin = pb.encode("SimpleEvent", restRequest)

				game:sendData(actionCodes.BeautyRestRequest, bin, #bin)
				game:addEventListener(actionModules[actionCodes.BeautyRestResponse], function(event)
					local msg = pb.decode("SimpleEvent", event.data)

					self.curBeauty.status = Beauty.STATUS_REST
					self.beauties = self:prepareBeauties()
					self.tableView:reloadData()
					self:initContentRight()

					return "__REMOVE__"
				end)
			end
			}):getLayer()
		slider:anch(0.5,0):pos(bgSize.width/2, bgSize.height - 360):addTo(attrBg)

		display.newSprite(BeautyRes .. "status_fight.png"):anch(0.5,0):pos(bgSize.width/2, bgSize.height - 400):addTo(attrBg)

		self.trainBtn = DGBtn:new(GlobalRes, {"btn_green_nol.png", "btn_green_sel.png", "middle_disabled.png"},
			{
				priority = self.priority - 2,
				text = { text = "培养" , font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
				callback = function()
					local layer = BeautyTrainLayer.new({beauty = self.curBeauty, priority = self.priority -10, parent = self, closeCallback = function() self:initContentRight() end})
					layer:getLayer():addTo(display.getRunningScene())
				end
			})
		self.trainBtn:getLayer():anch(0.5,0):pos(bgSize.width/2, bgSize.height - 470):addTo(attrBg)
	end

	self:checkGuide()
end

function BeautyListLayer:canEmploy()
	-- 等级限制
	local levelFlag = game.role.level >= self.curBeautyData.activeLevel
	
	-- 前置美人限制
	local beautyFlag = true 
	if self.curBeautyData.preBeautyId > 0 then
		beautyFlag = game.role:hasBeauty(self.curBeautyData.preBeautyId)
	end

	-- 副本限制
	local carbonFlag = true
	if self.curBeautyData.preChallengeId > 0 then
		carbonFlag = game.role.carbonDataset[self.curBeautyData.preChallengeId] and game.role.carbonDataset[self.curBeautyData.preChallengeId].starNum > 0
	end

	-- 花费限制
	local costFlag = true
	if self.curBeautyData.employMoney[1] == "1" then
		costFlag = game.role.money >= tonum(self.curBeautyData.employMoney[2])
	else
		costFlag = game.role.yuanbao >= tonum(self.curBeautyData.employMoney[2])
	end

	return levelFlag and beautyFlag and carbonFlag and costFlag
end

function BeautyListLayer:onCleanup()
	display.removeUnusedSpriteFrames()
end

return BeautyListLayer