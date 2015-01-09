-- 战斗系统暂停层
-- by yangkun
-- 2014.2.25

local BattlePauseLayer = class("BattlePauseLayer", function(params)
	return display.newLayer()
end)

function BattlePauseLayer:ctor(params)
	params = params or {}

	self.priority = params.priority or - 130
	self.parent = params.parent
	self.battleType = params.battleType or BattleType.PvE

	self.musicOn = game.musicOn
	
	self.maskLayer = DGMask:new({ item = self, priority = self.priority + 1 })
	self:initUI()
end

function BattlePauseLayer:initUI()
	local exitBtn = DGBtn:new(BattleRes, {"exit_battle.png","exit_battle_press.png"},
		{
			scale = 0.9,
			priority = self.priority,
			callback = function ()
				game:resume()

				if self.parent.battleStatus == 2 then 
					return

				elseif self.parent.battleStatus == 0 then

					if self.battleType == BattleType.PvP then
						switchScene("pvp")
					elseif self.battleType == BattleType.PvE then
						switchScene("carbon",{
						tag = self.parent.carbonInfo.type, 
						initPageIndex = math.floor((self.parent.carbonInfo.carbonId-10000*tonumber(self.parent.carbonInfo.type))/100)
					})
					elseif self.battleType == BattleType.Legend then
						switchScene("legend")
					elseif self.battleType == BattleType.Tower then
						switchScene("tower")
					elseif self.battleType == BattleType.Money then
						switchScene("activity")
					elseif self.battleType == BattleType.Exp or self.battleType == BattleType.Trial then
						switchScene("activity")
					elseif self.battleType == BattleType.Exped then
						switchScene("expedition")
					end
				else
					if self.parent.battleScheduleHandler then
						CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.parent.battleScheduleHandler)
						self.parent.battleScheduleHandler = nil
					end
					
					self:getLayer():removeSelf()

					if self.battleType == BattleType.PvE then
						self.parent:endPhaseGame({ starNum = 0 })

					elseif self.battleType == BattleType.PvP then
						self.parent:endGame({ starNum = 0 })

					elseif self.battleType == BattleType.Legend then
						self.parent:endGame({ starNum = 0 })

					elseif self.battleType == BattleType.Tower then
						self.parent:endGame({ starNum = 0 })
					elseif self.battleType == BattleType.Money then
						--提示：结束战斗将无奖励，确定和取消
						self:noRewardShow()
					elseif self.battleType == BattleType.Exp or self.battleType == BattleType.Trial then
						--经验副本提示：
						self:noRewardShow()
					elseif self.battleType == BattleType.Exped then
						self.parent:endGame({ starNum = 0,sendToServerFlag=0 })
					end
				end
			end,
		})
	exitBtn:getLayer():anch(0.5, 0.5):pos(display.cx - 300, display.cy):addTo(self)

	
	local btnBg = self.musicOn and "sound_on.png" or "sound_off.png"
	local btnPressBg = self.musicOn and "sound_on_press.png" or "sound_off_press.png"
	self.soundBtn = DGBtn:new(BattleRes, {btnBg,btnPressBg},
		{
			priority = self.priority,
			callback = function ()
				self:switchMusic()

				local btnBg = self.musicOn and "sound_on.png" or "sound_off.png"
				local btnPressBg = self.musicOn and "sound_on_press.png" or "sound_off_press.png"
				self.soundBtn:setBg(nil, {BattleRes .. btnBg,BattleRes .. btnPressBg})
			end,
		})
	self.soundBtn:getLayer():anch(0.5, 0.5):pos(display.cx, display.cy):addTo(self)

	

	local continueBtn = DGBtn:new(BattleRes, {"resume.png","resume_press.png"},
		{
			scale = 0.9,
			priority = self.priority,
			callback = function ()
				self:getLayer():removeSelf()
				game:resume()
			end,
		})
	continueBtn:getLayer():anch(0.5, 0.5):pos(display.cx + 300, display.cy):addTo(self)

	
end

function BattlePauseLayer:switchMusic()
	self.musicOn = not self.musicOn

	GameData.controlInfo = GameData.controlInfo or {}
	GameData.controlInfo.musicOn = self.musicOn
	GameData.controlInfo.soundOn = self.musicOn

	game.musicOn = self.musicOn
	game.soundOn = self.musicOn

	if self.musicOn then
		
		game:playMusic(3)
		audio.resumeAllSounds()
	else
		audio.pauseMusic()
		audio.stopAllSounds()
	end

	
end

function BattlePauseLayer:noRewardShow()
	CCDirector:sharedDirector():getScheduler():setTimeScale(1)
	switchScene("activity")

	-- local tipLayer = require("scenes.activity.IsQuitLayer")
	-- local isQuitLayer = tipLayer.new()
	-- isQuitLayer:addTo(self)
	-- self:addChild(isQuitLayer:getLayer())
	-- CCDirector:sharedDirector():getRunningScene():addChild(isQuitLayer,9999)
	
end

function BattlePauseLayer:getLayer()
	return self.maskLayer:getLayer()
end

return BattlePauseLayer