collectgarbage("setpause", 100)
collectgarbage("setstepmul", 5000)

BattleRes = "resource/ui_rc/battle/"

import(".BattleConstants")
local PveBattleLayer = import(".PveBattleLayer")
local PvpBattleLayer = import(".PvpBattleLayer")
local TowerBattleLayer = import(".TowerBattleLayer")
local LegendBattleLayer = import(".LegendBattleLayer")
local StartBattleLayer = import(".StartBattleLayer")
local BulletManager = import(".BulletManager")
local MoneyBattleLayer = import(".MoneyBattleLayer")
local ExpBattleLayer = import(".ExpBattleLayer")
local ExpeditonBattleLayer = import(".ExpeditionBattleLayer")
local TrialBattleLayer = import(".TrialBattleLayer")

local BattleScene = class("BattleScene", function(params)
	return display.newScene("BattleScene")
end)

function BattleScene:ctor(params)
	self.params = params or {}	
	if not bulletManager then
		bulletManager = BulletManager.new()
	end
end

function BattleScene:onEnter()
	if self.params.battleType == BattleType.PvP then
		self.battleLayer = PvpBattleLayer.new(self.params)

	elseif self.params.battleType == BattleType.Tower then
		self.battleLayer = TowerBattleLayer.new(self.params)

	elseif self.params.battleType == BattleType.PvE then
		self.battleLayer = PveBattleLayer.new(self.params)

	elseif self.params.battleType == BattleType.Legend then
		self.battleLayer = LegendBattleLayer.new(self.params)

	elseif self.params.battleType == BattleType.Start then
		self.battleLayer = StartBattleLayer.new(self.params) 

	elseif self.params.battleType == BattleType.Money then
		self.battleLayer = MoneyBattleLayer.new(self.params)
		
	elseif self.params.battleType == BattleType.Exp then
		self.battleLayer = ExpBattleLayer.new(self.params)

	elseif self.params.battleType == BattleType.Exped then
		self.battleLayer = ExpeditonBattleLayer.new(self.params)
	elseif self.params.battleType == BattleType.Trial then
		self.battleLayer = TrialBattleLayer.new(self.params)
	end
	
	game:playMusic(2)
	self.battleLayer:pos(0, 0):addTo(self)
end

function BattleScene:onExit()
	game:playMusic(1)

	bulletManager:dispose()
	bulletManager = nil

	armatureManager:dispose()

	display.removeUnusedSpriteFrames()
end

return BattleScene