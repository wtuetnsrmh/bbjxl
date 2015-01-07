-- avaoid memory leak
collectgarbage("setpause", 100);
collectgarbage("setstepmul", 5000);

CCLuaLoadChunksFromZIP("res/framework_precompiled.dg")

-- for CCLuaEngine
function __G__TRACKBACK__(errorMessage)
    CCLuaLog("----------------------------------------")
    CCLuaLog("LUA ERROR: "..tostring(errorMessage).."\n")
    CCLuaLog(debug.traceback("", 2))
    CCLuaLog("----------------------------------------")

	-- 错误日志上传
	local host = ServerConf[ServerIndex].as 
	local url = string.format("http://%s/errorReport?uid=%s&uname=%s&errorMsg=%s", 
		ServerConf[ServerIndex].as, game.platform_uid, game.platform_uname or "", errorMessage)
	local request = network.createHTTPRequest(function(event) end, url, "GET")
	request:setTimeout(waittime or 30)
	request:start()
end

game = require("gameApp").new()

-- 网络发生切换，直接close socket
function netchange(networkName)
	print(networkName, game.preNetwordName)
	if game.preNetwordName and networkName ~= game.preNetwordName then
		game:closeSocket()
	end

	game.preNetwordName = networkName
end

xpcall(function() game:run() end, __G__TRACKBACK__)