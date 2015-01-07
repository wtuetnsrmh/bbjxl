--远征
import(".BattleConstants")
local SpriteCamp = import(".SpriteCamp")
local SpriteSoldier = import(".SpriteSoldier")
local BattlePlotLayer = import(".BattlePlotLayer")
local ControlLayer = import(".ControlLayer")
local BaseBattleLayer = import(".BaseBattleLayer")
local BottomBarController = import(".BottomBarController")
local BattleEndLayer = import(".BattleEndNewLayer")

local BgRes = "resource/bg/"

local DGBtn = require("uicontrol.DGBtn")

local sharedScheduler = CCDirector:sharedDirector():getScheduler()

local ExpeditionBattleLayer = class("ExpeditionBattleLayer", BaseBattleLayer)

function ExpeditionBattleLayer:ctor(params)
	params = params or {}

	ExpeditionBattleLayer.super.ctor(self, params)

	self.curMapData=params.curMapData or {}
	self.mYangryCD=params.mYangryCD or 0

	--self.opponentRoleId = params.opponentRoleId

	self.rightHeros = params.rightHeros
	self.rightPassiveSkills = params.rightPassiveSkills or {}
	self.rightBeauties = params.rightBeauties or {}

	self.leftHeros=params.leftHeros
	self.leftPassiveSkills=params.leftPassiveSkills or {}

	self.battleLogic = nil

	-- 用于接收触摸事件
	self:setTouchEnabled(false)

	local heroTypes = {}
	for _, hero in pairs(self.rightHeros) do
		if hero.type > 0 then heroTypes[hero.type] = true end
	end

	-- loading ui
	--地图随机
	local totalMap={"ChengNei_1.jpg","ChengQiang_1.jpg","HuLaoGuan_1.jpg","JunYingWai_1.jpg","ShanGu_1.jpg","ShuLin_1.jpg","TianYe_1.jpg","pvp.jpg"}
	local index=math.random(#totalMap)
	local mapBgUrl=totalMap[index]
	local battleLoadingLayer
	battleLoadingLayer = BattleLoadingLayer.new({ priority = -128,
		callback = function()
			CCTexture2D:PVRImagesHavePremultipliedAlpha(false)
			
			battleLoadingLayer:getLayer():removeSelf()

			self.bg = display.newSprite(BgRes .. mapBgUrl)
			self.bg:pos(display.cx, display.cy):addTo(self)

			--增加粒子position,tag,res,parent,zorder,scale,file
			-- local particleParam={
			-- 	res="resource/ui_rc/battle/rainNew.plist",
			-- 	parent=self.bg,
			-- 	tag = 10000,
			-- 	position=ccp(0,0),
			-- 	scale=1,

			-- }
			-- showParticleEffect(particleParam)

			self:initCommonUI(params)
			self:initBattleField()
			game.role.leftMembers = 0
			game.role.leftMembers = table.nums(self.battleField.leftSoldierMap)
		end,
		loadingInfo = {
			images = { BgRes .. "pvp.jpg" },
			heroTypes = heroTypes,
			loadRoleHeros = true,
		}
	})
	battleLoadingLayer:getLayer():addTo(display:getRunningScene())
end

-- 初始化战场
function ExpeditionBattleLayer:initBattleField()
	local passiveSkills, beauties = game.role:getFightBeautySkills()

	self.leftCamp = SpriteCamp.new({ camp = "left",angryAccumulateTime=0,angryUnitNum=self.mYangryCD, 
		passiveSkills = passiveSkills, beauties = beauties})
	--battleType:用于判断是否是首场战斗从而判断是否加怒气
	self.rightCamp = SpriteCamp.new({ camp = "right",angryAccumulateTime=0,angryUnitNum=self.curMapData.angryCD, battleType = BattleType.Exped, 
		passiveSkills = self.rightPassiveSkills, beauties = self.rightBeauties })
	
	self:refreshAngrySlot(
		--angryUnitNum:初始怒气格数（要保存的值），angryAccumulateTime：初始默认的积累怒气值 0
		{ angryUnitNum = self.leftCamp.angryUnitNum, angryAccumulateTime = self.leftCamp.angryAccumulateTime })

	self.battleField = require("logical.battle.BattleField").new({ leftCamp = self.leftCamp, rightCamp = self.rightCamp })

	self:initLeftField()
	self:initRightField()

	self.heroBottomLayer = BottomBarController.new({ battle = self })
	self.heroBottomLayer:anch(0.5, 0):pos(display.cx, 0):addTo(self, BattleConstants.zOrderConstants["bottomBar"])
end

function ExpeditionBattleLayer:initLeftField()
	-- -- 左边战场的武将
	local soldiers = {}

	for _, soldier in ipairs(self.leftHeros) do
		local col, row = BattleConstants:indexToAnch(soldier.index)
		soldier.anchPointX, soldier.anchPointY = col, row

		table.insert(soldiers, soldier)
	end

	self:addBattleHeros(soldiers)
end

function ExpeditionBattleLayer:initRightField()
	local soldiers = {}

	-- 右边战场的武将
	for _, soldier in ipairs(self.rightHeros) do

		if soldier.blood>0 then
			local col, row = BattleConstants:indexToAnch(soldier.index, "right")
			soldier.camp = "right"
			soldier.anchPointX, soldier.anchPointY = col, row

			table.insert(soldiers, soldier)
		end
		
	end

	self:addBattleHeros(soldiers)
end

function ExpeditionBattleLayer:saveExpeFormation()

	local formation={}
	for anchKey, soldier in pairs(self.battleField.leftSoldierMap) do
		local index = BattleConstants:anchToIndex(soldier.anchPoint.x, soldier.anchPoint.y)
		formation[index] = soldier.id
	end

	-- dump(formation)

	--保存阵型
	local bin = pb.encode("UpdateYzFormationReq", {yzFormationJson=json.encode(formation)})
	game:sendData(actionCodes.UpdateYzFormationReq, bin, #bin)
	loadingShow()
	game:addEventListener(actionModules[actionCodes.UpdateYzFormationRes], function(event)
		self:setTouchEnabled(true)

		self:hideUI()
		self:showBattleUI()
		self:showLeftTime()

		local msg=pb.decode("SimpleEvent",event.data)
		loadingHide()

		game.role.yzFormation={}
		game.role.yzFormation=formation

		for i=1,6 do
			if formation[i] then
				-- print("formation[i]",i,formation[i])
				for _,hero in ipairs(self.leftHeros) do
					if hero.id==formation[i] then
						hero.index=i
					end
				end
			end
		end

		game:playMusic(6)

		self.battleLogic = require("logical.battle.Battle").new({ battleField =  self.battleField })
		self.battleLogic:init()

		-- 事件监听
		self.battleLogic:addEventListener("gameOver", handler(self, self.endGame))
		self.battleField:addEventListener("soldierDead", handler(self, self.onSoldierDead))

		self:showBeautyInspire(function()
			self:dispatchEvent({ name = "battleStart" })

			sharedScheduler:setTimeScale(game.role.battleSpeed)

			self.battleStatus = 1
			self.battleScheduleHandler = sharedScheduler:scheduleScriptFunc(function(diff) self.battleLogic:schedule(diff) end,
				2 / 60, false)
		end)

		return "__REMOVE__"
	end)

	
end


function ExpeditionBattleLayer:startGame()
	

	-- 阵型保存
	self:saveExpeFormation()

	
end

function ExpeditionBattleLayer:getLeftTimeString(time)
	local minute = math.floor(time / 60)
	local second = time % 60
	return string.format("%02d:%02d", minute, second)
end

function ExpeditionBattleLayer:showLeftTime()
	self.leftTime = globalCsv:getFieldValue("battleMaxTime")
	
	if self.leftTimeLabel then	
		self.leftTimeLabel:setString(self:getLeftTimeString(self.leftTime))
		self.leftTimeLabel:setVisible(true)
	else
		local countDownBg = display.newSprite(BattleRes .. "countdown_bg.png")
		countDownBg:anch(0.5,0.5):pos(200,display.height - 45):addTo(self)
		local bgSize = countDownBg:getContentSize()

		self.leftTimeLabel = ui.newTTFLabelWithStroke({text = "00:00", size = 26 })
		self.leftTimeLabel:anch(0, 0.5):pos(90, bgSize.height / 2):addTo(countDownBg)

		display.newSprite(BattleRes .. "hourglass.png")
			:anch(0, 0.5):pos(10, bgSize.height / 2):addTo(countDownBg)
	end

	local setLeftTime
	setLeftTime = function()
		if self.leftTime > 0 then
			self.leftTimeLabel:setString(self:getLeftTimeString(self.leftTime))
			self.leftTime = self.leftTime - 1

			self.leftTimeLabel:runAction(transition.sequence({
				CCDelayTime:create(1),
				CCCallFunc:create(setLeftTime),
			}))
		else
			self.leftTimeLabel:setString("00:00")
			self:setTouchEnabled(false)

			self:endGame({starNum = 0})	
		end
	end
	setLeftTime()
end

function ExpeditionBattleLayer:getCurBlood(heroIndex,result,camp)
	if result==1 and camp=="right" then
		return 0--我方胜，则敌方血量为0
	end

	if result==2 and camp=="left" then
		return 0
	end

	local col, row = BattleConstants:indexToAnch(heroIndex,camp)

	local soldier={}
	if camp=="right" then
		soldier=self.battleField.rightSoldierMap[camp..col..row]
	else
		soldier=self.battleField.leftSoldierMap[camp..col..row]
	end
	
	
	return soldier and math.floor(math.floor(soldier.hp)*100/soldier.maxHp) or 0

end

function ExpeditionBattleLayer:returnYZFighter(heros,id_type,result)

	local camp=id_type=="type" and "right" or "left"


	local heroList={}

	for _,hero in ipairs(heros) do
		local temp_YZHeroDtl={
			id = hero[id_type],
			level=hero.level,
			evolutionCount=hero.evolutionCount,
			skillLevelJson=hero.skillLevelJson,
			wakeLevel=hero.wakeLevel,
			star = hero.star,
			blood=self:getCurBlood(hero.index,result,camp),
			slot=hero.index,
			attrsJson=hero.attrsJson,
		}

		table.insert(heroList,temp_YZHeroDtl)
	end

	local returnYZFighter={
		name=id_type=="type" and self.curMapData.name or "",--敌我区分处理
		level=id_type=="type" and self.curMapData.level or 1,--敌我区分处理
		id=self.curMapData.id,-- 1-15
		angryCD=id_type=="type" and math.floor(self.battleField.rightCamp.angryUnitNum*10) or math.floor(self.battleField.leftCamp.angryUnitNum*10),-- 这里的值=怒气值*10
		heroList=heroList,
	}

	return returnYZFighter
end

function ExpeditionBattleLayer:endGame(event)
	if self.battleScheduleHandler then
		sharedScheduler:unscheduleScriptEntry(self.battleScheduleHandler)
		self.battleScheduleHandler = nil
	end
	sharedScheduler:setTimeScale(1)

	self:dispatchEvent({ name = "battleEnd" })
	self.battleStatus = 2

	if self.leftTimeLabel then
		self.leftTimeLabel:stopAllActions()
	end

	event.sendToServerFlag=event.sendToServerFlag and 0 or 1 	

	local starNum = event.starNum-- and event.starNum or self.battleField:calculateGameResult()

	local joinHeros = {}
	local soldiers = self.leftHeros
	for _,soldier in ipairs(soldiers) do
		table.insert(joinHeros,{ id = soldier.type })
	end

	showMaskLayer()
	self:runAction(transition.sequence{
		CCDelayTime:create(1),
		CCCallFunc:create(function()
			hideMaskLayer()

			if event.sendToServerFlag==1 then
				-- 将战斗结果发往服务端
				local endGameRequest = { 
					id = self.curMapData.id, 
					result=starNum>0 and 1 or 2,
					myself=self:returnYZFighter(self.leftHeros,"id",result),
					other = self:returnYZFighter(self.rightHeros,"type",result),
					joinHeros = joinHeros,
				}

				--dump(endGameRequest)

				local bin = pb.encode("EndExpeditionRequest",endGameRequest)

				game:rpcRequest({
					requestCode = actionCodes.EndExpeditionRequest,
					requestData = bin,
					responseCode = actionCodes.EndExpeditionReponse,
					callback = function(event)
						
				    	bulletManager:dispose()
						armatureManager:dispose()

						local msg
						if event.data then
							msg= pb.decode("SimpleEvent", event.data)
						end
				    	
						 if msg and msg.param1==SYS_ERR_YZ_OPER then
						 	DGMsgBox.new({text = "远征非法操作!"..msg.param1,type=1})
						 	local battleEndLayer = BattleEndLayer.new({ curMapId=self.curMapData.id,battleType = BattleType.Exped,starNum=0,dropItems={},bgImg = self.bg:getTexture()})
							display.getRunningScene():addChild(battleEndLayer:getLayer())
							return
						 end
		
				    	local battleEndLayer = BattleEndLayer.new({ curMapId=self.curMapData.id,battleType = BattleType.Exped,
				    		starNum=starNum,dropItems={},bgImg = self.bg:getTexture(), joinHeros = joinHeros,
				    		 exp = forceMatchCsv:getAwardById(self.curMapData.id).exp, roleExp = 0 } )
						display.getRunningScene():addChild(battleEndLayer:getLayer())
					end,
				})
			else
				--如果强退不发数据到服务端
				bulletManager:dispose()
				armatureManager:dispose()
				local battleEndLayer = BattleEndLayer.new({ curMapId=self.curMapData.id,battleType = BattleType.Exped,starNum=starNum,dropItems={},bgImg = self.bg:getTexture()})
				display.getRunningScene():addChild(battleEndLayer:getLayer())
			end
			
		end)
	})
end

-- 战场武将挂掉
function ExpeditionBattleLayer:onSoldierDead(event)
	local soldier = self.battleField[event.camp .. "SoldierMap"][event.anchKey]

	if not soldier then return end
	
	self[event.camp .. "FormationPositions"][soldier.anchPoint.x][soldier.anchPoint.y].hero = nil
	if soldier:getState() == "skillAttack" then
		self:showSkillMask(false, soldier)
	end

	soldier.sprite:runAction(transition.sequence({
		CCFadeOut:create(1),
		CCCallFunc:create(function() soldier:dispose() end)
	}))	
end

function ExpeditionBattleLayer:onCleanup()
	game:removeAllEventListenersForEvent(actionModules[actionCodes.PvpEndGameResponse])
	if self.battleScheduleHandler then
		sharedScheduler:unscheduleScriptEntry(self.battleScheduleHandler)
		self.battleScheduleHandler = nil
	end
end

return ExpeditionBattleLayer
