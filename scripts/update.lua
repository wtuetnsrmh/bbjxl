-- 资源和代码自动更新模块
-- changed by yangkun
-- 2014.5.14

------------------------------------------------------------------------------
--Load origin framework
------------------------------------------------------------------------------
--CCLuaLoadChunksFromZIP("res/framework_precompiled.zip")

------------------------------------------------------------------------------
--If you would update the modoules which have been require here,
--you can reset them, and require them again in modoule "appentry"
------------------------------------------------------------------------------
require("config")
require("framework.init")
require("framework.shortcodes")
require("utils.init")
require("uicontrol.init")
require "lfs"

local LoadingRes = "resource/ui_rc/loading/"
local LoginRes = "resource/ui_rc/login_rc/"
local GlobalRes = "resource/ui_rc/global/"

------------------------------------------------------------------------------
--define UpdateScene
------------------------------------------------------------------------------
local UpdateScene = class("UpdateScene", function()
	return display.newScene("UpdateScene")
end)

-- local param = "?dev=" .. device.platform
local param = ""
local list_filename = "flist"
local downList = {}
local filesNeedReload = {}

local function hex(s)
	s = string.gsub(s,"(.)",function (x) return string.format("%02X",string.byte(x)) end)
	return s
end

local function readFile(path)
	local file = io.open(path, "rb")
	if file then
		local content = file:read("*all")
		io.close(file)
		return content
	end
	return nil
end

local function removeFile(path)
	os.remove(path)
	-- io.writefile(path, "")
end

local function checkFile(fileName, cryptoCode)
	if not io.exists(fileName) then
		return false
	end

	local data = readFile(fileName)
	if data == nil then
		return false
	end

	if cryptoCode == nil then
		return true
	end

	local ms = crypto.md5(hex(data))
	if ms == cryptoCode then
		return true
	end

	return false
end

local function checkDirOK(path)
	local oldpath = lfs.currentdir()

	if lfs.chdir(path) then
		lfs.chdir(oldpath)
		return true
	end

	if lfs.mkdir(path) then
		return true
	end
end

function UpdateScene:ctor()
	self.rootPath = device.writablePath

	-- CCFileUtils:sharedFileUtils():addSearchPath(self.rootPath)
	-- CCFileUtils:sharedFileUtils():addSearchPath("res/")

	-- 脚本文件更新需要退出游戏
	self.exitGame = false

	self.processDone = false
	self.versionSame = false

	--背景 
	display.newSprite(LoginRes .. "enter_bg.jpg"):anch(0.5, 0):pos(display.cx, 0):addTo(self)

	-- 经验槽
	self.loadingBg = display.newSprite( LoadingRes .. "loading_box.png" )
	self.loadingBg:anch(0.5,0):pos(self:getContentSize().width/2,40):addTo(self)

	local loadingSlot = display.newSprite( LoadingRes .. "loading_bg.png")
	loadingSlot:pos(self.loadingBg:getContentSize().width/2, self.loadingBg:getContentSize().height/2):addTo(self.loadingBg, -1)
	self.loadingProgress = display.newProgressTimer(LoadingRes .. "loading_bar.png", display.PROGRESS_TIMER_BAR)
	self.loadingProgress:setMidpoint(ccp(0, 0.5))
	self.loadingProgress:setBarChangeRate(ccp(1,0))
	self.loadingProgress:setPercentage( 0 )
	self.loadingProgress:pos(loadingSlot:getContentSize().width/2, loadingSlot:getContentSize().height/2):addTo(loadingSlot)

	self.loadingLabel = ui.newTTFLabel({text = 0 .. "%", size = 24}):anch(0.5,0.5)
	:pos(self.loadingBg:getContentSize().width/2, self.loadingBg:getContentSize().height/2):addTo(self.loadingBg)
	self.loadingBg:setVisible(false)

	self.descLabel = ui.newTTFLabel({text = "正在检查版本...", size = 24, color = display.COLOR_FONT}):anch(0.5,0.5)
	:pos(self:getContentSize().width/2, 90):addTo(self)
end

function UpdateScene:updateFiles()
	-- 更新配置文件
	local data = readFile(self.newListFilePath)
	io.writefile(self.curListFilePath, data)
	removeFile(self.newListFilePath)

	self.curList = dofile(self.curListFilePath)
	if self.curList == nil then
		self:endProcess()
		return
	end
	print("替换flist文件完成!")

	-- 删除更新upd文件
	for i, v in ipairs(downList) do
		--local data = readFile(v)
		local fn = string.sub(v, 1, -5)
		--io.writefile(fn, data)
		removeFile(fn)
		os.rename(v, fn)
	end
	print("删除upd文件完成!")
	self.processDone = true
	self:endProcess()
end

function UpdateScene:reqNextFile()
	self.numFileCheck = self.numFileCheck + 1
	self.curStageFile = self.newList.stage[self.numFileCheck]

	if self.curStageFile and self.curStageFile.name then
		local fn = self.rootPath .. self.curStageFile.name
		-- 不需要更新
		if self:checkMd5(self.curStageFile.name, self.curStageFile.code) then
			return self:reqNextFile()
		end

		if self.curStageFile.act == "load" then
			--self.exitGame = true
			table.insert(filesNeedReload, self.curStageFile.name)
		end

		-- 更新文件已下载
		fn = fn .. ".upd"
		if checkFile(fn, self.curStageFile.code) then
			table.insert(downList, fn)
			return self:reqNextFile()
		end

		-- 请求文件
		self:requestFromServer(self.curStageFile.name)
		return
	end

	self:updateFiles()
end

function UpdateScene:showUpdateInfo()
	self.totalUpdateSize = 0
	self.totalUpdateFileNum = 0
	for _,file in pairs(self.newList.stage) do
		if not self:checkMd5(file.name, file.code) then
			self.totalUpdateSize = self.totalUpdateSize + tonumber(file.size)
			self.totalUpdateFileNum = self.totalUpdateFileNum + 1
		end
	end
	print(self.totalUpdateSize, self.totalUpdateFileNum)

	local infoLayer = display.newLayer(GlobalRes .. "confirm_bg.png")
	infoLayer:anch(0.5,0.5):pos(display.cx, display.cy)
	self.infoMask = DGMask:new({item = infoLayer})
	self:addChild(self.infoMask:getLayer(), 100)

	ui.newTTFLabel({text = "主公，检测到新版本需要更新", size = 30 })
	:anch(0,0):pos(130,130):addTo(infoLayer)

	ui.newTTFLabel({text = string.format("需更新的资源包大小约 %.1f M", self.totalUpdateSize/1000000), size = 30 })
	:anch(0,0):pos(130,90):addTo(infoLayer)

	-- 使用
	local nextBtn = DGBtn:new(GlobalRes , {"middle_normal.png", "middle_selected.png", "middle_disabled.png"}, {
			text = { text = "这次算了", size = 28, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
				require("gameEntry")
			end,
			priority = -140
		})
	nextBtn:getLayer():anch(0.5,0):pos(infoLayer:getContentSize().width/2 - 140, 16):addTo(infoLayer)

	-- 使用
	local updateBtn = DGBtn:new(GlobalRes , {"middle_normal.png", "middle_selected.png", "middle_disabled.png"}, {
			text = { text = "更新", size = 28, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
				self.infoMask:getLayer():removeSelf()

				self.numFileCheck = 0
				self.updateFileNum = 0
				self.requesting = "files"
				self:reqNextFile()

				self.descLabel:setString("正在下载更新文件...")
			end,
			priority = -140
		})
	updateBtn:getLayer():anch(0.5,0):pos(infoLayer:getContentSize().width/2 + 140, 16):addTo(infoLayer)

end

function UpdateScene:showCheckNetworkDlg(info)
	local infoLayer = display.newLayer(GlobalRes .. "confirm_bg.png")
	infoLayer:anch(0.5,0.5):pos(display.cx, display.cy)
	infoMask = DGMask:new({item = infoLayer})
	self:addChild(infoMask:getLayer(), 100)

	ui.newTTFLabel({text = info, dimensions = CCSizeMake(500, 100), size = 30 })
	:anch(0,0):pos(102,110):addTo(infoLayer)

	-- 重试
	local retryBtn = DGBtn:new(GlobalRes , {"middle_normal.png", "middle_selected.png", "middle_disabled.png"}, {
			text = { text = "重试", size = 28, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
				infoMask:getLayer():removeSelf()

				self:requestFromServer(self.requestfn or self.requesting)
			end,
			priority = -140
		})
	retryBtn:getLayer():anch(0.5,0):pos(infoLayer:getContentSize().width/2 - 140, 24):addTo(infoLayer)

	-- 退出
	local exitBtn = DGBtn:new(GlobalRes , {"middle_normal.png", "middle_selected.png", "middle_disabled.png"}, {
			text = { text = "退出", size = 28, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
			callback = function()
				CCDirector:sharedDirector():endToLua()
			end,
			priority = -140
		})
	exitBtn:getLayer():anch(0.5,0):pos(infoLayer:getContentSize().width/2 + 140, 24):addTo(infoLayer)
end

function UpdateScene:onEnterFrame(dt)
	if self.dataRecv then
		-- 配置文件
		if self.requesting == list_filename then
			loadingHide()
			self.descLabel:setString("准备下载更新文件...")
			self.loadingBg:setVisible(true)

			io.writefile(self.newListFilePath, self.dataRecv)
			self.dataRecv = nil

			self.newList = dofile(self.newListFilePath)
			if self.newList == nil then
				print("配置更新文件flist打开错误!")
				self:endProcess()
				return
			end

			print("当前版本号: " .. self.curList.ver)
			print("最新版本号: " .. self.newList.ver)
			if self.newList.ver == self.curList.ver then
				removeFile(self.newListFilePath)
				self.processDone = true
				self.versionSame = true
				self:endProcess()
				return
			end

			self:showUpdateInfo()
			return
		end

		if self.requesting == "files" then
			self.updateFileNum = self.updateFileNum + 1
			local progress = self.updateFileNum / self.totalUpdateFileNum * 100
			self.loadingProgress:setPercentage(progress)
			self.loadingLabel:setString(math.floor(progress) .. "%")

			local fn = self.rootPath .. self.curStageFile.name .. ".upd"

			-- recursion create directory
			local paths = string.split(self.curStageFile.name, "/")
			local currentPath = self.rootPath
			for index = 1, #paths - 1 do
				currentPath = currentPath .. paths[index] .. "/"
				checkDirOK(currentPath)
			end
			
			io.writefile(fn, self.dataRecv)
			self.dataRecv = nil
			if checkFile(fn, self.curStageFile.code) then
				table.insert(downList, fn)
				self:reqNextFile()
			else
				self:showCheckNetworkDlg("更新数据出错！请确保您的网络畅通，并重试")
			end
			return
		end

		return
	end
end

function UpdateScene:prepareListMap()
	for _,file in pairs(self.curList.stage) do
		self.curListMap[file.name] = file.code
	end
end

-- 检查flist中文件md5值和服务端文件md5值是否一样
function UpdateScene:checkMd5(fileName, cryptoCode)
	return self.curListMap[fileName] == cryptoCode
end

function UpdateScene:onEnter()
	if not checkDirOK(self.rootPath) then
		require("gameEntry")
		return
	end

	self.curListFilePath =  self.rootPath .. list_filename               
	self.curList = nil
	if io.exists(self.curListFilePath) then
		self.curList = dofile(self.curListFilePath)
	end

	if self.curList == nil then
		local data = CCFileUtils:sharedFileUtils():getFileData("flist")
		self.curList = assert(loadstring(data))()
	end

	if self.curList == nil then
		self.curList = {
			ver = "1.0.0",
			stage = {},
			remove = {},
		}
	end

	-- 版本号
	ui.newTTFLabel({ text = string.format("版本号 : %s", self.curList.ver), size = 24, 
		color = display.COLOR_BLACK })
		:anch(1, 0):pos(display.width - 20, 20):addTo(self)

	-- 计算版本号
	local function versionValue(version)
		local vers = string.split(string.trim(version), ".")
		return tonumber(vers[1]) * 100000 + tonumber(vers[2]) * 1000 + tonumber(vers[3])
	end

	-- 检查版本号
	local version_url = string.format("http://%s/version?platform=%s&version=%s", 
		ServerConf[ServerIndex].as, device.platform, self.curList.ver)
	local request = network.createHTTPRequest(function(event) 
		if event.name ~= "completed" then return end
		local result = event.request
		if result:getResponseStatusCode() ~= 200 then return end

		local new_version = string.trim(result:getResponseData())

		local oldValue = versionValue(self.curList.ver)
		local newValue = versionValue(new_version)
		print("最新版本号: " .. new_version, oldValue, newValue)

		if oldValue >= newValue then
			require("gameEntry")
		else
			self.curListMap = {}
			self:prepareListMap()

			self.requestCount = 0
			self.requesting = list_filename
			self.newListFilePath = self.curListFilePath .. ".upd"
			self.dataRecv = nil

			loadingShow()
			self:requestFromServer(self.requesting)

			self:scheduleUpdate(function(dt) self:onEnterFrame(dt) end)
		end
	end, version_url, "GET")
	request:setTimeout(30)
	request:start()

	print("device.platform", device.platform)
	if device.platform ~= "android" then return end

	-- avoid unmeant back
	self:performWithDelay(function()
		-- keypad layer, for android
		local layer = display.newLayer()
		layer:addKeypadEventListener(function(event)
			if event == "back" then game.exit() end
		end)
		self:addChild(layer)

		layer:setKeypadEnabled(true)
	end, 0.5)
end

function UpdateScene:onExit()
end

function UpdateScene:endProcess()
	-- load 代码和删除文件
	if self.processDone and not self.versionSame then
		for i, name in ipairs(filesNeedReload) do
			print("重加载文件: " .. name)
			CCLuaLoadChunksFromZIP(self.rootPath .. name)

			package.loaded["config"] = nil
		end
		print("重加载代码文件完成!")
		for i,v in ipairs(self.curList.remove) do
			removeFile(self.rootPath .. v)
		end
	end

	print("----------------------------------------UpdateScene:endProcess")

	if self.exitGame then

		local infoLayer = display.newLayer(GlobalRes .. "confirm_bg.png")
		infoLayer:anch(0.5,0.5):pos(display.cx, display.cy)
		local infoMask = DGMask:new({item = infoLayer})
		self:addChild(infoMask:getLayer())

		ui.newTTFLabel({text = "游戏需要重启，请重新启动游戏！", size = 30})
			:anch(0,0):pos(130,100):addTo(infoLayer)

		local okBtn = DGBtn:new(GlobalRes , {"middle_normal.png", "middle_selected.png", "middle_disabled.png"}, {
				text = { text = "确定", size = 28, font = ChineseFont, color=display.COLOR_WHITE, strokeColor = display.COLOR_FONT, strokeSize = 2},
				callback = function()
					CCDirector:sharedDirector():endToLua()
    				--os.exit()
				end,
				priority = -140
			})
		okBtn:getLayer():anch(0.5,0):pos(infoLayer:getContentSize().width/2, 16):addTo(infoLayer)

		return
	end

	-- 清空资源缓存
	CCDirector:sharedDirector():purgeCachedData()

	require("gameEntry")
end

function UpdateScene:requestFromServer(filename, waittime)
	print("===========================================")
	print("下载文件:"..filename)

	local url
	if filename == list_filename then
		url = ServerConf[ServerIndex].us .. filename .. param
	elseif not ServerConf[ServerIndex].public then
		url = ServerConf[ServerIndex].us .. filename .. param
	else
		url = ServerConf[ServerIndex].us .. "/" .. self.newList.ver .. "/" .. filename .. param	
	end
	self.requestCount = self.requestCount + 1
	self.requestfn = filename
	local index = self.requestCount
	local request = network.createHTTPRequest(function(event) self:onResponse(event, index) end, url, "GET")
	if request then
		request:setTimeout(waittime or 30)
		request:start()
	else
		self:showCheckNetworkDlg("http请求失败！请确保您的网络畅通，并重试")
	end
end

function UpdateScene:onResponse(event, index, dumpResponse)
	local request = event.request
	printf("REQUEST %d - event.name = %s", index, event.name)
	if event.name == "completed" then
		local errorCode = request:getResponseStatusCode()
		printf("REQUEST %d - getResponseStatusCode() = %d", index, errorCode)

		if errorCode ~= 200 then
			-- 重定向
			if errorCode == 302 or errorCode == 301 then
				local redirectUrl = string.match(request:getResponseHeadersString(), "http%C-%s")
				local request = network.createHTTPRequest(function(event) self:onResponse(event, index) end, 
					redirectUrl, "GET")
				request:setTimeout(waittime or 30)
				request:start()
			else
				self:showCheckNetworkDlg(string.format("返回码%d！请确保您的网络畅通，并重试", errorCode))
			end

		else
			printf("REQUEST %d - getResponseDataLength() = %d", index, request:getResponseDataLength())
			if dumpResponse then
				printf("REQUEST %d - getResponseString() =\n%s", index, request:getResponseString())
			end
			self.dataRecv = request:getResponseData()
		end
	else
		printf("REQUEST %d - getErrorCode() = %d, getErrorMessage() = %s", index, request:getErrorCode(), request:getErrorMessage())
		self:showCheckNetworkDlg("检查游戏更新失败！请确保您的网络畅通，并重试")
	end
	print("===========================================")
end

if not AUTO_UPDATE then
	require("gameEntry")
else
	local upd = UpdateScene.new()
	display.replaceScene(upd)
end