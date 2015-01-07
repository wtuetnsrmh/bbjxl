
-- 0 - disable debug info, 1 - less debug info, 2 - verbose debug info
DEBUG = 0
DEBUG_FPS = true
OPEN_STAR_BATTLE = true  --开场战斗
-- DEBUG_MEM = true

XXTEA_KEY = "699D448D6D24f7F941E9F6E99F823E18"

local platform = CCApplication:sharedApplication():getTargetPlatform()
if platform ~= kTargetIpad then
	CONFIG_SCREEN_WIDTH = 960
	CONFIG_SCREEN_HEIGHT = 640
	CONFIG_SCREEN_AUTOSCALE = "FIXED_HEIGHT_PRIOR"
else
	CONFIG_SCREEN_AUTOSCALE = function(w,h)
		CONFIG_SCREEN_WIDTH = 1024
		CONFIG_SCREEN_HEIGHT = 640
	end
end

ServerIndex = 4

ServerConf = {
	[1] = {
		-- 账号服务器
		as = "115.29.193.94:8686",
		-- 更新服务器
		us = string.format("http://%s:8091/update/", "115.29.193.94"),
		-- 逻辑服务器列表
		serverList = {
			[1] = { id = 1, name = "日常测试服", free = 0.2, host = "115.29.193.94", port = 9898 },
		},
		public = false,
	},
	[2] = {
		-- 账号服务器
		as = "182.254.154.183",
		-- 更新服务器
		us = string.format("http://%s:8091/update/", "182.254.154.183"),
		-- 逻辑服务器列表
		serverList = {
			[1] = { id = 1, name = "内网测试服", free = 0.2, host = "182.254.154.183", port = 9898 },
		},
		public = true,
	},
	[3] = {
		-- 账号服务器
		as = "116.213.213.67",
		-- 更新服务器
		us = "http://static.kunlun.com/lwsg/android/main/",
		-- 逻辑服务器列表
		serverList = {
			[1] = { id = 1, name = "对酒当歌", free = 0.2, host = "116.213.213.67", port = 9898 },
		},
		public = true,
	},
	[4] = {
		-- 账号服务器
		as = "115.29.193.94:8686",
		-- 更新服务器
		us = string.format("http://%s:8091/update/", "115.29.193.94"),
		-- 逻辑服务器列表
		serverList = {
			[1] = { id = 1, name = "本地测试服", free = 0.2, host = "127.0.0.1", port = 9898 },
		},
		public = false,
	},
}

AUTO_UPDATE = false