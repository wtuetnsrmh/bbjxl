
BattleConstants = {
	-- 阵型坐标
	leftPositions = {
		[1] = { [1] = ccp(-340 + display.cx, 240), [2] = ccp(-410 + display.cx, 340)},
		[2] = { [1] = ccp(-200 + display.cx, 240), [2] = ccp(-270 + display.cx, 340)},
		[3] = { [1] = ccp(-60 + display.cx, 240), [2] = ccp(-130 + display.cx, 340)},
	},
	rightPositions = {
		[1] = { [1] = ccp(130 + display.cx, 240), [2] = ccp(60 + display.cx, 340)},
		[2] = { [1] = ccp(270 + display.cx, 240), [2] = ccp(200 + display.cx, 340)},
		[3] = { [1] = ccp(410 + display.cx, 240), [2] = ccp(340 + display.cx, 340)},
	},

	zOrderConstants = {
		["background"] = -20,
		["effect1"] = 1,	-- 技能特效下层
		["controBtns"] = 2,
		["rightSoldierBegin"] = 3,
		["leftSoldierBegin"] = 11,
		["dragSoldier"] = 17,
		["effect0"] = 20,	-- 技能特效上层
		["bottomBar"] = 30,
		["skillMask"] = 100,
		["stage"] = 110,
		["bossAppear"] = 120,
		["plot"] = 130,
		["pause"] = 140,
	},

	GeneralBullet = 11,	-- 通用子弹类型

	ColMax = 3,
	RowMax = 2,
}

function BattleConstants:indexToAnch(index, camp)
	camp = camp or "left"
	if camp == "left" then
		local col = self.ColMax - math.floor((index - 1) / self.RowMax)
		local row = self.RowMax - (index - 1) % self.RowMax
		return col, row
	else
		local col = math.floor((index - 1) / self.RowMax) + 1
		local row = self.RowMax - (index - 1) % self.RowMax
		return col, row
	end
end

function BattleConstants:anchToIndex(col, row)
	return (self.ColMax - col) * self.RowMax + (self.ColMax - row)
end

function BattleConstants:calSoldierZorder(anchPointX, anchPointY, camp)
	camp = camp or "left"
	if camp == "left" then
		return self.zOrderConstants["leftSoldierBegin"] + 10 - anchPointX - 3 * anchPointY  --1-6
	else
		return self.zOrderConstants["rightSoldierBegin"] + 6 + anchPointX - 3 * anchPointY  --1 - 6
	end
end
