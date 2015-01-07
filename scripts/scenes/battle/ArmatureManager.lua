local ArmatureManager = class("ArmatureManager")

function ArmatureManager:ctor()
	self.boneResources = {}
	self.boneEffectResources = {}
	self.firstLoad=false

	-- f253b6b6 a04366ad bc81d173 ed5a4e10
	ZipUtils:ccSetPvrEncryptionKeyPart(0, 4065572534)
	ZipUtils:ccSetPvrEncryptionKeyPart(1, 2688771757)
	ZipUtils:ccSetPvrEncryptionKeyPart(2, 3162624371)
	ZipUtils:ccSetPvrEncryptionKeyPart(3, 3982118416)
end

function ArmatureManager:hasLoaded(type)
	local unitData = unitCsv:getUnitByType(type)
	if not unitData then return false end

	return self.boneResources[unitData.boneResource] == true
end

function ArmatureManager:hasEffectLoaded(type)
	local unitData = unitCsv:getUnitByType(type)
	if not unitData then return false end

	return self.boneEffectResources[unitData.boneEffectResource] == true
end

function ArmatureManager:retainTexture(path)
	-- local texture = sharedTextureCache:textureForKey(path .. ".pvr.ccz")
	-- if texture then texture:retain() end
end

function ArmatureManager:releaseTexture(path)
	-- local texture = sharedTextureCache:textureForKey(path .. ".pvr.ccz")
	-- if texture then texture:release() end
end

function ArmatureManager:load(type) 
	local unitData = unitCsv:getUnitByType(type)
	if not unitData then return end

	if self.boneResources[unitData.boneResource] then
		-- display.addSpriteFramesWithFile(unitData.boneResource .. ".plist", unitData.boneResource .. ".pvr.ccz")
		return 
	end
	
	self.boneResources[unitData.boneResource] = true

	CCTexture2D:PVRImagesHavePremultipliedAlpha(true)
	display.TEXTURES_PIXEL_FORMAT[unitData.boneResource .. ".pvr.ccz"] = kCCTexture2DPixelFormat_RGBA4444
	CCArmatureDataManager:sharedArmatureDataManager():addArmatureFileInfo(unitData.boneResource .. ".pvr.ccz", 
		unitData.boneResource .. ".plist", unitData.boneResource .. ".xml")
	self:retainTexture(unitData.boneResource)

	if unitData.boneEffectResource and unitData.boneEffectResource ~= "" then
		display.TEXTURES_PIXEL_FORMAT[unitData.boneEffectResource .. ".pvr.ccz"] = kCCTexture2DPixelFormat_RGBA4444
		CCArmatureDataManager:sharedArmatureDataManager():addArmatureFileInfo(unitData.boneEffectResource .. ".pvr.ccz", 
			unitData.boneEffectResource .. ".plist", unitData.boneEffectResource .. ".xml")
		self:retainTexture(unitData.boneEffectResource)

		self.boneEffectResources[unitData.boneEffectResource] = true
	end
	CCTexture2D:PVRImagesHavePremultipliedAlpha(false)

	if not self.firstLoad then
		display.addSpriteFramesWithFile(unitData.boneResource .. ".plist", unitData.boneResource .. ".pvr.ccz")
		self.firstLoad=true
	end
end

function ArmatureManager:asyncLoad(type, listener)
	local unitData = unitCsv:getUnitByType(type)
	if not unitData then return false end

	if self.boneResources[unitData.boneResource] then
		-- display.addSpriteFramesWithFile(unitData.boneResource .. ".plist", unitData.boneResource .. ".pvr.ccz")
		return 
	end

	CCTexture2D:PVRImagesHavePremultipliedAlpha(true)
	display.TEXTURES_PIXEL_FORMAT[unitData.boneResource .. ".pvr.ccz"] = kCCTexture2DPixelFormat_RGBA4444
	CCArmatureDataManager:sharedArmatureDataManager():addArmatureFileInfoAsync(unitData.boneResource .. ".pvr.ccz", 
		unitData.boneResource .. ".plist", unitData.boneResource .. ".xml", listener)
	self:retainTexture(unitData.boneResource)

	if unitData.boneEffectResource and unitData.boneEffectResource ~= "" then
		display.TEXTURES_PIXEL_FORMAT[unitData.boneEffectResource .. ".pvr.ccz"] = kCCTexture2DPixelFormat_RGBA4444
		CCArmatureDataManager:sharedArmatureDataManager():addArmatureFileInfoAsync(unitData.boneEffectResource .. ".pvr.ccz", 
			unitData.boneEffectResource .. ".plist", unitData.boneEffectResource .. ".xml", listener)
		self:retainTexture(unitData.boneEffectResource)

		self.boneEffectResources[unitData.boneEffectResource] = true
	end
	-- CCTexture2D:PVRImagesHavePremultipliedAlpha(false)

	self.boneResources[unitData.boneResource] = true
	return true
end

function ArmatureManager:unload(type)
	local unitData = unitCsv:getUnitByType(type)
	if not unitData then return end

	if not self.boneResources[unitData.boneResource] then return end

	CCArmatureDataManager:sharedArmatureDataManager():removeArmatureFileInfo(unitData.boneResource .. ".xml")
	display.removeSpriteFramesWithFile(unitData.boneResource .. ".plist", unitData.boneResource .. ".pvr.ccz")
	self:releaseTexture(unitData.boneResource)

	if unitData.boneEffectResource and unitData.boneEffectResource ~= "" then
		CCArmatureDataManager:sharedArmatureDataManager():removeArmatureFileInfo(unitData.boneEffectResource .. ".xml")
		display.removeSpriteFramesWithFile(unitData.boneEffectResource .. ".plist", unitData.boneEffectResource .. ".pvr.ccz")
		self:releaseTexture(unitData.boneEffectResource)

		self.boneEffectResources[unitData.boneEffectResource] = nil
	end

	self.boneResources[unitData.boneResource] = nil
end

function ArmatureManager:reserveTypes(reservedHeros)
	local reserverdBones = {}
	local reserverdEffectBones = {}
	for type, _ in pairs(reservedHeros) do
		local unitData = unitCsv:getUnitByType(type)
		if unitData then
			reserverdBones[unitData.boneResource] = true
			if unitData.boneEffectResource ~= "" then
				reserverdEffectBones[unitData.boneEffectResource] = true
			end
		end
	end

	for name, _ in pairs(self.boneResources) do
		if not reserverdBones[name] then
			CCArmatureDataManager:sharedArmatureDataManager():removeArmatureFileInfo(name .. ".xml")
			display.removeSpriteFramesWithFile(name .. ".plist", name .. ".pvr.ccz")
			self:releaseTexture(name)
		end
	end

	for name, _ in pairs(self.boneEffectResources) do
		if not reserverdEffectBones[name] then
			CCArmatureDataManager:sharedArmatureDataManager():removeArmatureFileInfo(name .. ".xml")
			display.removeSpriteFramesWithFile(name .. ".plist", name .. ".pvr.ccz")
			self:releaseTexture(name)
		end
	end

	self.boneResources = reserverdBones
	self.boneEffectResources = reserverdEffectBones
end

function ArmatureManager:dispose()
	for name, _ in pairs(self.boneResources) do
		CCArmatureDataManager:sharedArmatureDataManager():removeArmatureFileInfo(name .. ".xml")
		display.removeSpriteFramesWithFile(name .. ".plist", name .. ".pvr.ccz")
		self:releaseTexture(name)
	end
	self.boneResources = {}

	for name, _ in pairs(self.boneEffectResources) do
		CCArmatureDataManager:sharedArmatureDataManager():removeArmatureFileInfo(name .. ".xml")
		display.removeSpriteFramesWithFile(name .. ".plist", name .. ".pvr.ccz")
		self:releaseTexture(name)
	end
	self.boneEffectResources = {}
	-- CCArmatureDataManager:purge()	
end

return ArmatureManager