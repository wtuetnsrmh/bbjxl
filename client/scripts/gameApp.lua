require("config")
require("framework.init")
require("utils.init")
require("protos.init")
require("uicontrol.init")
require("framework.shortcodes")
require("constants")
require("ProtocolCode")
require("SysErrCode")

pb = require("protobuf")
audio = require("framework.audio")
json = require("framework.json")

DGMsgBox = require("uicontrol.DGMsgBox")
ConfirmDialog = require "scenes.ConfirmDialog"

GameState = require(cc.PACKAGE_NAME .. ".api.GameState")
cc.push = import(".push.init").new()

sharedDirector         = CCDirector:sharedDirector()
sharedTextureCache     = CCTextureCache:sharedTextureCache()
sharedSpriteFrameCache = CCSpriteFrameCache:sharedSpriteFrameCache()

local TcpSocket = require("network.TcpSocket")
local ByteBuffer = require "network.ByteBuffer"
local SocketActions = require("network.SocketActions")
local scheduler = require("framework.scheduler")

local gameApp = class("gameApp", cc.mvc.AppBase)

function gameApp:ctor()
	gameApp.super.ctor(self)

	self:initUserDefault()
	self:registerPbFile()
	
	self.serverList = {}
	self.role = nil
	self.guideTips = nil

	self.tcpSocket = nil
	self.byteBuffer = ByteBuffer.new()

	self.netMaskTag = 123321

	self.guides = {}

	-- 全局开关
	self.musicOn = GameData.controlInfo.musicOn
	self.soundOn = GameData.controlInfo.soundOn

	self:addEventListener(cc.mvc.AppBase.APP_ENTER_BACKGROUND_EVENT, handler(self, self.onEnterBackground))
	self:addEventListener(cc.mvc.AppBase.APP_ENTER_FOREGROUND_EVENT, handler(self, self.onEnterForeground))

	socketActions = SocketActions.new(self)
	armatureManager = require("scenes.battle.ArmatureManager").new()

	cc.push:start("CocosPush")

	if GameData.user then
		local url = string.format("http://115.29.193.94:8686/proxy?name=%s", GameData.user)
		local request = network.createHTTPRequest(function(event) 
			local request = event.request
			if event.name == "completed" then
				if request:getResponseStatusCode() == 200 then
					self.platform_uid = tonumber(request:getResponseData())
				end
			end
		end, url, "GET")
		request:setTimeout(waittime or 30)
		request:start()
	end
end

function gameApp:registerPbFile()
	local protoFiles = {"common", "role", "hero", "carbon", "gift", "friend", "store", "pvp", "equip", "expedition"}

	local parser = require("pbParser")
	parser.register(protoFiles)
end

function gameApp:initUserDefault()
	-- init GameState
	GameState.init(function(param)
		local returnValue = nil
		if param.errorCode then
			CCLuaLog("error")
		else
			-- crypto
			if param.name == "save" then
				local str = json.encode(param.values)
				str = crypto.encryptXXTEA(str, "abcd")
				returnValue = { data = str }
			elseif param.name == "load" then
				local str = crypto.decryptXXTEA(param.values.data, "abcd")
				returnValue = json.decode(str)
			end
		end
		return returnValue 
	end, "user.bin", "dangge")

	GameData = GameState.load()
	if not GameData then 
		GameData = {}
		GameData.controlInfo = { musicOn = true, soundOn = true, }
	end
end

function gameApp:run()
	CCFileUtils:sharedFileUtils():addSearchPath(device.writablePath .. "res/")
    CCFileUtils:sharedFileUtils():addSearchPath("res/")

    require("csv.CsvLoader").loadCsv()
    switchScene("login", { layer = "login" })
end

function gameApp:setServerTime(serverTime)
	self.serverTime = serverTime
	self.startTime = os.time()
end

function gameApp:nowTime()
	return self.serverTime + (os.time() - self.startTime)
end

function gameApp:passTime()
	return os.time() - self.startTime
end

function gameApp:newSocket(host, port)
	if self.tcpSocket then 
		self:closeSocket()
	end

	self.tcpSocket = TcpSocket.new(host, port, false)

	self.tcpSocket:addEventListener(TcpSocket.EVENT_CONNECTED, handler(self, self.onConnected))
	self.tcpSocket:addEventListener(TcpSocket.EVENT_CLOSE, handler(self,self.onStatus))
	self.tcpSocket:addEventListener(TcpSocket.EVENT_CLOSED, handler(self,self.onClosed))
	self.tcpSocket:addEventListener(TcpSocket.EVENT_CONNECT_FAILURE, handler(self,self.onConnectFailed))
	self.tcpSocket:addEventListener(TcpSocket.EVENT_DATA, handler(self,self.onData))

	return self.tcpSocket:connect()
end

function gameApp:startHeartBeat()
	if not self.messageHandler then
		self.messageHandler = scheduler.scheduleGlobal(
			function () self:sendData(actionCodes.HeartBeat, "") end, 5.0)
	end
end

function gameApp:onConnected(event)
	if self.byteBuffer then
		self.byteBuffer:reset()
	end
	
	self:startHeartBeat()
end

function gameApp:onClosed(event)
end

function gameApp:onConnectFailed(event)
	DGMsgBox.new({ type = 1, text = "服务器繁忙, 请稍后再试" })
end

function gameApp:onStatus(__event)
	echoInfo("socket status: %s", __event.name)
end

function gameApp:onData(__event)
	local msgs = self.byteBuffer:paserMessage(__event.data)
	for _, message in ipairs(msgs) do
		local cmd = struct.unpack("H", string.sub(message, 1, 2))
		local body = string.sub(message, 3)

		local actionName = actionModules[cmd]
		if not actionName or actionName == "" then return end

		if actionName ~= "Role.notifyNewEvents" then
			print("recv message:", actionName)
		end

		if #body <= 4 then
			self:dispatchEvent({ name = actionName, data = body })
		else
			self:dispatchEvent({ name = actionName, data = crypto.decryptXXTEA(body, XXTEA_KEY) })
		end
	end
end

function gameApp:closeSocket()
	if self.messageHandler then
		scheduler.unscheduleGlobal(self.messageHandler)
		self.messageHandler = nil
	end

	if self.tcpSocket then
		self.tcpSocket:close()
		self.tcpSocket:disconnect()
	end
end

function gameApp:onEnterBackground(event)
end

function gameApp:onEnterForeground(event)
	-- 设置音乐和音效相关
	if game.musicOn then
		audio.resumeMusic()
	else
		audio.pauseMusic()
	end

	if game.soundOn then
		audio.resumeAllSounds()
	else
		audio.stopAllSounds()
	end

	--后台恢复后会resume，这里需要重新暂停下
	if self.isPaused then
		self:pause()
	end

	if self.tcpSocket and self.tcpSocket.isConnected then
		self:startHeartBeat()
	end
end

function gameApp:packMsg(actionCode, binaray)
	local data = struct.pack("H", actionCode)
	data = data .. crypto.encryptXXTEA(binaray, XXTEA_KEY)
	local head = struct.pack(ByteBuffer.PACKAGE_HEAD_FMT, #data)
	return head .. data	
end

function gameApp:rpcRequest(params)
	local retryDialog, hasRecieved

	local result = self:sendData(params.requestCode, params.requestData)
    self:addEventListener(actionModules[params.responseCode], function(event)
    	hasRecieved = true

    	display.getRunningScene():removeChildByTag(self.netMaskTag + 1)

    	if params.callback then
    		params.callback(event)
    	end

    	return "__REMOVE__"
    end)

    if not result then return false end

    -- 如果返回true, 不一定发送成功
   	scheduler.performWithDelayGlobal(function()
   		if hasRecieved then return end

   		retryDialog = ConfirmDialog.new({
	   		priority = -10000,
	   		showText = { text = "网络故障, 请重试", size = 28, },
	   		button1Data = {
	   			text = "重试",
		   		callback = function()
		   			self:sendData(params.requestCode, params.requestData)
		   			return false
		   		end,
		   	},
		   	button2Data = {
		   		text = "返回首页",
		   		callback = function()
		   			local guideCsvData = guideCsv:getStepStartGuide(game.role.guideStep)
		   			if guideCsvData then
		   				game:activeGuide(guideCsvData.guideId)
		   			end
		   			switchScene("home")
		   		end,
		   	}
   		})

   		retryDialog:getLayer():anch(0.5, 0.5):pos(display.cx, display.cy):addTo(display.getRunningScene(), 100, self.netMaskTag + 1)
   	end, 5) 
end

function gameApp:sendData(actionCode, binaray)
	local msgData = self:packMsg(actionCode, binaray)

    local result = self.tcpSocket:send(msgData)

    if actionCode ~= actionCodes.HeartBeat then
    	print("send:", actionModules[actionCode])
    end

    local function reConnect()
		if self:newSocket(game.serverInfo.host, game.serverInfo.port) then
			local bin = pb.encode("RoleQueryLogin", { uid = game.platform_uid })
			local queryData = self:packMsg(actionCodes.RoleQueryLogin, bin)
			
			self.tcpSocket:send(queryData)
			game:addEventListener(actionModules[actionCodes.RoleQueryResponse], function(event)
				local msg = pb.decode("RoleQueryResponse", event.data)
				if msg.ret == "RET_NOT_EXIST" then
					self.tcpSocket:send(msgData)
					display.getRunningScene():removeChildByTag(self.netMaskTag)
				elseif msg.ret == "RET_HAS_EXISTED" then
					local bin = pb.encode("RoleLoginData", { name = msg.name, packageName = PACKAGE_NAME,
						deviceId = game.device })
					game:sendData(actionCodes.RoleLoginRequest, bin)
					game:addEventListener(actionModules[actionCodes.RoleLoginResponse], function(event)
						socketActions:roleLoginResponse(event)

						self:sendData(actionCode, binaray)
						display.getRunningScene():removeChildByTag(self.netMaskTag)
					end)
				elseif msg.ret == "INNER_ERROR" then
					game:closeSocket()
				end

				return "__REMOVE__"
			end)
		end
    end

    -- 发送包失败且不是心跳包
    if not result then
    	if actionCode == actionCodes.HeartBeat then
    		reConnect()
    	else
	    	display.getRunningScene():removeChildByTag(self.netMaskTag + 1)

	    	if display.getRunningScene():getChildByTag(self.netMaskTag) then
	    		return
	    	end
	    	local dialog = ConfirmDialog.new({
				priority = -10000,
				showText = { text = "不妙哦，网络不给力啊，请重新连接", size = 28, },
				button1Data = {
					callback = function()
						reConnect()
						return false
					end,
				} 
			})

			dialog:getLayer():anch(0.5, 0.5):pos(display.cx, display.cy):addTo(display.getRunningScene(), 100, self.netMaskTag)
		end
		
		return false
    end

    return true
end

function gameApp:playMusic(id)
	local musicData = musicCsv:getMusicData(id)
	if not musicData or musicData.res == "" then return end

	if musicData.type == 1 then
		if self.musicOn then
			audio.playMusic(musicData.res, musicData.isLoop == 1)
			audio.setMusicVolume(0.7)
		end
	else
		if self.soundOn then
			audio.playEffect(musicData.res, musicData.isLoop == 1)
		end
	end
end

function gameApp:preloadMusic(id)
	local musicData = musicCsv:getMusicData(id)
	if not musicData or musicData.res == "" then return end

	if musicData.type == 1 then
		audio.preloadMusic(musicData.res)
	else
		audio.preloadSound(musicData.res)
	end
end

function gameApp:unloadMusic(id)
	local musicData = musicCsv:getMusicData(id)
	if not musicData or musicData.res == "" then return end

	if musicData.type == 1 then
	else
		audio.unloadSound(musicData.res)
	end
end

function gameApp:exit()
	cc.push:stop("CocosPush")

	if device.platform == "android" then
		local javaClassName = PACKAGE_NAME
	    local javaMethodName = "quit"
	    local javaParams = {
	    	function ()
	    		self:closeSocket()

			    CCDirector:sharedDirector():endToLua()
			    --os.exit()
	    	end
	    }
	    local javaMethodSig = "(I)V"
	    luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)

	else
		local tag = 546321
	 	display.getRunningScene():removeChildByTag(tag)

	 	local ConfirmDialog = require("scenes.ConfirmDialog")
		local dialog = ConfirmDialog.new({
			priority = -20000,
	        showText = { text = "您确定要退出游戏吗？", size = 30, },
	        button1Data = {
	            callback = function()
	               self.exitLayer = nil
	            end,
	        },
	        button2Data = {
	            callback = function()
	                self:closeSocket()
					CCDirector:sharedDirector():endToLua()
	            end,
	        } 
	    })
	    dialog:getLayer():anch(0.5, 0.5):pos(display.cx, display.cy):addTo(display.getRunningScene(), 1000, tag)
	end
end

function gameApp:pause()
	display.pause()
	self.isPaused = true
end

function gameApp:resume()
	display.resume()
	self.isPaused = false
end

function gameApp:addGuideNode(params)
	for _, id in ipairs(params.guideIds) do
		self.guides[id] = not params.remove and params or nil
	
		if not params.remove and id == game.guideId then
			self:activeGuide(id)
		end
	end
end

function gameApp:activeGuide(id, oldId)
	id = id or 0
	oldId = oldId or 0

	self.guideId = id
	if id == 0 then
		if self.role then
			self.role:updateGuideStep(1000)
		end
		return
	end

	local guideData = self.guides[id]
	local oldCsvData = guideCsv:getGuideById(oldId)
	if oldCsvData and oldCsvData.updateStep ~= 0 and self.role then
		self.role:updateGuideStep(oldCsvData.updateStep)
	end

	local csvData = guideCsv:getGuideById(id)
	print("guideId", id, guideData, display.getRunningScene().name)
	
	local tag = 12311
	local GuideTipsLayer = require("scenes.GuideTipsLayer")
	local GuidePlotLayer = require("scenes.GuidePlotLayer")
	--还没加入,如果是对话直接加入
	if not guideData or (not guideData.node and not guideData.rect) then
		if csvData.talkId ~= 0 then
			display.getRunningScene():removeChildByTag(tag)
			local guidePlot = GuidePlotLayer.new({ guideId = id, onComplete = function()
				self:activeGuide(csvData.nextGuideId, id)
			end })
			guidePlot:getLayer():addTo(display.getRunningScene(), 1000, tag)
		else
			return
		end
	else
		display.getRunningScene():removeChildByTag(tag)
		if guideData.beginFunc then
			guideData.beginFunc()
		end
		
		local ok
		if csvData.talkId ~= 0 then
			ok = true
			local guidePlot = GuidePlotLayer.new({ guideId = id, onComplete = function()
				self:activeGuide(csvData.nextGuideId, id)
			end })
			guidePlot:getLayer():addTo(display.getRunningScene(), 1000, tag)
		else
			local guideTips
		 	ok = pcall(function() guideTips = GuideTipsLayer.new({ node = guideData.node, guideBtn = guideData.guideBtn, guideId = id, rect = guideData.rect, checkContain = guideData.checkContain,
				degree = guideData.degree or 0, distance = guideData.distance or 0, onClick = guideData.endFunc,
				opacity = guideData.opacity, notDelay = guideData.notDelay }) end)
		 	if ok then
				guideTips:addTo(display.getRunningScene(), 1000, tag)
				if guideData.action then
					guideTips:setArrowVisible(false)
					guideTips:showHand(guideData.action.from, guideData.action.to)
				end
			end
		end
	end
	self.guides[id] = nil
end

function gameApp:activeSpecialGuide(id)
	local guideData = checkTable(checkTable(checkTable(GameData, "userInfo"), tostring(game.role.id)), "guideData")
	if guideData[tostring(id)] or self.guideId ~= 0 then 
		return false
	end

	guideData[tostring(id)] = 1
	GameState.save(GameData)
	self:activeGuide(id)
	return true
end

function gameApp:hasGuide()
	return display.getRunningScene():getChildByTag(12311)
end

return gameApp
