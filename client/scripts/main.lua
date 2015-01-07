-- for CCLuaEngine
function __G__TRACKBACK__(errorMessage)
    CCLuaLog("----------------------------------------")
    CCLuaLog("LUA ERROR: "..tostring(errorMessage).."\n")
    CCLuaLog(debug.traceback("", 2))
    CCLuaLog("----------------------------------------")

	-- 错误日志上传
	local host = ServerConf[ServerIndex].as 
	local url = string.format("http://%s/errorReport?uid=%s&uname=%s&errorMsg=%s", 
		ServerConf[ServerIndex].as, device.platform, game.platform_uname or "", errorMessage)
	local request = network.createHTTPRequest(function(event) end, url, "GET")
	request:setTimeout(waittime or 30)
	request:start()
end

xpcall(function() require("update") end, __G__TRACKBACK__)