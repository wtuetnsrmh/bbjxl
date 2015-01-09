local BulletManager = class("BulletManager")

function BulletManager:ctor(params)
	self.bullets = {}

	self.bulletRes = {}
	self.musicIds = {}
	self.generalBullet = 15

	-- f253b6b6 a04366ad bc81d173 ed5a4e10
	ZipUtils:ccSetPvrEncryptionKeyPart(0, 4065572534)
	ZipUtils:ccSetPvrEncryptionKeyPart(1, 2688771757)
	ZipUtils:ccSetPvrEncryptionKeyPart(2, 3162624371)
	ZipUtils:ccSetPvrEncryptionKeyPart(3, 3982118416)

	-- 加载通用特效
	self.bullets[self.generalBullet] = {}

	local generalBulletData = bulletCsv:getBulletById(self.generalBullet)
	local bulletActionData = require("csv.BulletActCsv")
	bulletActionData:load(generalBulletData.actCsv)

	local bulletPaths = string.split(generalBulletData.res, "/")

	self.bulletRes[generalBulletData.res] = true
	if device.platform ~= "ios" then
		display.TEXTURES_PIXEL_FORMAT[generalBulletData.res .. ".pvr.ccz"] = kCCTexture2DPixelFormat_RGBA4444
	else
		display.TEXTURES_PIXEL_FORMAT[generalBulletData.res .. ".pvr.ccz"] = kCCTexture2DPixelFormat_PVRTC4
	end
	display.addSpriteFramesWithFile(generalBulletData.res .. ".plist", generalBulletData.res .. ".pvr.ccz")

	-- 受伤
	local animationName = self.generalBullet .. "_" .. "hurt"
	local animation = display.getAnimationCache(animationName)
	if not tolua.isnull(animation) then return end

	local frames = {}
	local actionData = bulletActionData:getActDataById(BulletActionId["hurt"])
	if actionData then
		for _, frameId in ipairs(actionData.frameIDs) do
			local frameId = string.format("%02d", tonumber(frameId))
			frames[#frames + 1] = display.newSpriteFrame(bulletPaths[#bulletPaths] .. "_" .. frameId .. ".png")
		end

		local animation = display.newAnimation(frames, 1.0 / actionData.fps)-- 创建动画
		self.bullets[self.generalBullet]["hurt"] = self.bullets[self.generalBullet]["hurt"] or {}
		self.bullets[self.generalBullet]["hurt"]["frames"] = frames
		self.bullets[self.generalBullet]["hurt"]["fps"] = actionData.fps
		self.bullets[self.generalBullet]["hurt"]["musicId"] = actionData.musicId
		self.bullets[self.generalBullet]["hurt"]["zorder"] = actionData.layer
		game:preloadMusic(actionData.musicId)

		self.musicIds[actionData.musicId] = true
		self:cacheAnimation(animationName, animation)
	end
end

function BulletManager:cacheAnimation(name, animation)
	self.cacheAnimName = self.cacheAnimName or {}
	display.setAnimationCache(name, animation)
	self.cacheAnimName[name] = true
end

function BulletManager:load(id)
	local csvData = bulletCsv:getBulletById(id)
	if not csvData then print("bullet csv data error") end

	-- 资源为空
	if csvData.res == "" then return false end

	if self.bullets[id] then return true end
	self.bullets[id] = {}

	local bulletActionData = require("csv.BulletActCsv")
	bulletActionData:load(csvData.actCsv)

	self.bulletRes[csvData.res] = true
	if device.platform ~= "ios" then
		display.TEXTURES_PIXEL_FORMAT[csvData.res .. ".pvr.ccz"] = kCCTexture2DPixelFormat_RGBA4444
	else
		display.TEXTURES_PIXEL_FORMAT[csvData.res .. ".pvr.ccz"] = kCCTexture2DPixelFormat_PVRTC4
	end
	display.addSpriteFramesWithFile(csvData.res .. ".plist", csvData.res .. ".pvr.ccz")

	local function initAnimationData(name, prefixName, bulletActionData)
		local animationName = csvData.id .. "_" .. name
		local animation = display.getAnimationCache(animationName)
		if not tolua.isnull(animation) then return end

		local frames = {}
		local actionData = bulletActionData:getActDataById(BulletActionId[name])
		if actionData then
			for _, frameId in ipairs(actionData.frameIDs) do
				local frameId = string.format("%02d", tonumber(frameId))
				frames[#frames + 1] = display.newSpriteFrame(prefixName .. "_" .. frameId .. ".png")
				if not frames[#frames] then
					-- 再加载一遍
					-- cocos2d: TexturePVR: Error uploading compressed texture level: 0 . glError: 0x0502
					-- 从无效的操作中恢复过来
					display.addSpriteFramesWithFile(csvData.res .. ".plist", csvData.res .. ".pvr.ccz")
					frames[#frames] = display.newSpriteFrame(prefixName .. "_" .. frameId .. ".png")
				end
			end

			local animation = display.newAnimation(frames, 1.0 / actionData.fps)-- 创建动画
			self.bullets[id][name] = self.bullets[id][name] or {}
			self.bullets[id][name]["frames"] = frames
			self.bullets[id][name]["fps"] = actionData.fps
			self.bullets[id][name]["musicId"] = actionData.musicId
			self.bullets[id][name]["zorder"] = actionData.layer
			game:preloadMusic(actionData.musicId)

			self.musicIds[actionData.musicId] = true
			self:cacheAnimation(animationName, animation)
		end
	end

	local bulletPaths = string.split(csvData.res, "/")
	for name, value in pairs(BulletActionId) do
		initAnimationData(name, bulletPaths[#bulletPaths], bulletActionData)
	end

	-- 加载通用特效
	self.bullets[id]["hurt"] = self.bullets[id]["hurt"] or {}
	self.bullets[id]["hurt"]["frames"] = self.bullets[id]["hurt"]["frames"] or {}
	
	if #self.bullets[id]["hurt"]["frames"] == 0 then
		self.bullets[id]["hurt"]["frames"] = self.bullets[self.generalBullet]["hurt"]["frames"]
		self.bullets[id]["hurt"]["fps"] = self.bullets[self.generalBullet]["hurt"]["fps"]
		self.bullets[id]["hurt"]["musicId"] = self.bullets[self.generalBullet]["hurt"]["musicId"]
		self.bullets[id]["hurt"]["zorder"] = self.bullets[self.generalBullet]["hurt"]["zorder"]
	end

	return true
end

function BulletManager:getAnimation(id, name)
	local animation = display.getAnimationCache(id .. "_" .. name)
	if not animation and name == "hurt" then
		animation = display.getAnimationCache(self.generalBullet .. "_" .. name)
	end

	return animation
end

function BulletManager:getFrameCount(id, name)
	if not self.bullets[id] then return 0 end
	if not self.bullets[id][name] then return 0 end

	return table.nums(self.bullets[id][name]["frames"])
end

function BulletManager:getFrame(id, name, index)
	index = index or 1

	if not self.bullets[id] then return nil end
	if not self.bullets[id][name] then return nil end

	return self.bullets[id][name]["frames"][index]
end

function BulletManager:getFrameSprite(id, name, index)
	index = index or 1

	if not self.bullets[id] then return nil end
	if not self.bullets[id][name] then return nil end

	local bulletData = bulletCsv:getBulletById(id)
	local bulletSprite = display.newSprite(self.bullets[id][name]["frames"][index])
	bulletSprite:setScaleX(bulletData.scaleX / 100)
	bulletSprite:setScaleY(bulletData.scaleY / 100)
	return bulletSprite
end

function BulletManager:getMusicId(id, name)
	if not self.bullets[id] then return 0 end
	if not self.bullets[id][name] then return 0 end

	return tonum(self.bullets[id][name]["musicId"])
end

function BulletManager:getZorder(id, name)
	if not self.bullets[id] then return 0 end
	if not self.bullets[id][name] then return 0 end

	return tonum(self.bullets[id][name]["zorder"])
end

function BulletManager:dispose()
	for name, _ in pairs(self.bulletRes) do
		display.removeSpriteFramesWithFile(name .. ".plist", name .. ".pvr.ccz")
	end

	for id, _ in pairs(self.musicIds) do
		game:unloadMusic(id)
	end

	if self.cacheAnimName then
		for name in pairs(self.cacheAnimName) do
			display.removeAnimationCache(name)
		end
	end
end

return BulletManager