local Battle = class("Battle")

function Battle:ctor(params)
	require("framework.api.EventProtocol").extend(self)

	params = params or {}

	self.frame = 2 / 60 * 1000	-- 固定帧时间间隔, 避免误差
	self.randomSeed = params.randomSeed or os.time()	-- 每场战斗的随机种子

	self.battleField = params.battleField
	params.battleField.battle = self
	self.parent = params.parent
end

function Battle:init()
	self.battleStartTime = os.clock() * 1000

	self.battleField:init({ battle = self })

	-- 设置种子
	math.randomseed(self.randomSeed)
end

function Battle:pause(value)
	self.battleField:pause(value)
end

function Battle:schedule(diff)
	-- 检测被动技能是否刷完毕
	self.checkPassive = self.checkPassive or false
	
	local notOver = false
	if not self.checkPassive then
		local soldiers = {}
		table.insertTo(soldiers, table.values(self.battleField.leftSoldierMap))
		table.insertTo(soldiers, table.values(self.battleField.rightSoldierMap))
		for _,soldier in pairs(soldiers) do
			if soldier.isPassiveAni then
				notOver = true
				break
			end
		end
	end

	if notOver then return end

	if self.parent and not self.firstCall then
		self.parent:showLeftTime()
		self.firstCall = true
	end

	self.checkPassive = true

	self.battleCurrentTime = os.clock() * 1000

	self.battleField:update(diff)

	if self.battleField:gameOver() then
		-- 所有士兵站立闲置
		self.battleField:standbyAllSoldiers()

		self:dispatchEvent({ name = "gameOver", starNum = self.battleField:calculateGameResult() })
	end
end

return Battle