local SpriteBullet = import(".SpriteBullet")
local SpriteSoldier = import(".SpriteSoldier")

local SpriteBuff = class("SpriteBuff", require("logical.battle.Buff"))

function SpriteBuff:ctor(params)
	SpriteBuff.super.ctor(self, params)

	if self.csvData and self.csvData.bulletId > 0 then
		self.bullet = SpriteBullet.new({ id = self.csvData.bulletId, usage = 3 })
	end
end

function SpriteBuff:onBegin(soldier)
	if not self.bullet then return end

	-- 头顶ICON
	-- 检查位置
	if self.bullet.csvData.tipsIcon ~= "" then
		local curPos = soldier.buffIconIndex % 2 ~= 0 and 1 or 2
		soldier.displayNode:removeChildByTag(1000 + curPos)

		display.newSprite(self.bullet.csvData.tipsIcon)
			:pos((curPos == 1 and -20 or 20) + soldier.nodeSize.width / 2, 190)
			:addTo(soldier.displayNode, SpriteSoldier.zOrderConstants["buffIcon"], 1000 + curPos)
		soldier.buffIconIndex = soldier.buffIconIndex + 1
	end

	-- 缓速变灰操作
	if self.csvData.type == 18 then
		local grayShadeProgram = UIUtil:shaderForKey("ShaderPositionTextureGray")
		soldier.sprite:setShaderProgram(grayShadeProgram)
	end

	if bulletManager:getFrameCount(self.bullet.id, "begin") == 0 then
		return
	end

	local beginSprite = display.newSprite(bulletManager:getFrame(self.bullet.id, "begin"))
	beginSprite:setScaleX(self.bullet.csvData.scaleX / 100)
	beginSprite:setScaleY(self.bullet.csvData.scaleY / 100)
	beginSprite:anch(0.5, 0.5):pos(self.bullet.csvData.beginXOffset + soldier.nodeSize.width / 2, self.bullet.csvData.beginYOffset)
		:addTo(soldier.displayNode)

	-- 开始特效，特效1s开播持续特效
	beginSprite:runAction(transition.sequence({
		CCAnimate:create(bulletManager:getAnimation(self.bullet.id, "begin")),
		CCRemoveSelf:create(),
		CCCallFunc:create(function() 
			self.inProgress = false 
			self:effect(soldier) 
		end)
	}))
end

function SpriteBuff:onProgress(soldier)
	if not self.bullet or not self.bullet.hasAnimation then return end

	if self.inProgress then return end

	self.inProgress = true

	if bulletManager:getFrameCount(self.bullet.id, "progress") == 0 then end

	local progressSprite = display.newSprite(bulletManager:getFrame(self.bullet.id, "progress"))
	progressSprite:setScaleX(self.bullet.csvData.scaleX / 100)
	progressSprite:setScaleY(self.bullet.csvData.scaleY / 100)
	progressSprite:addTo(soldier.displayNode, SpriteSoldier.zOrderConstants["bulletLayer" .. bulletManager:getZorder(self.bullet.id, "progress")])
		:pos(self.bullet.csvData.oppositeX1 + soldier.nodeSize.width / 2, self.bullet.csvData.oppositeY1)

	self.progressSprite = progressSprite
	progressSprite:playAnimationOnce(bulletManager:getAnimation(self.bullet.id, "progress"), true, 
		function() 
			self.progressSprite = nil
			self.inProgress = false 
		end
	)
	
end

function SpriteBuff:dispose(soldier)
	-- 缓速变灰操作
	if self.csvData.type == 18 then
		local origShadeProgram = UIUtil:shaderForKey("ShaderPositionTextureColor")
		soldier.sprite:setShaderProgram(origShadeProgram)
	end

	soldier.displayNode:removeChildByTag(1001)
	soldier.displayNode:removeChildByTag(1002)

	if self.progressSprite then
		self.progressSprite:removeSelf()
		self.progressSprite = nil
	end
end

return SpriteBuff