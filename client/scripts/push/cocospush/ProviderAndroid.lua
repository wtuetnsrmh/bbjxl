
local ProviderBase = import(".ProviderBase")
local ProviderAndroid = class("ProviderAndroid", ProviderBase)

local SDK_CLASS_NAME = "com.cocos.CCPushHelper"

function ProviderAndroid:addListener()
	luaj.callStaticMethod(SDK_CLASS_NAME, "addScriptListener", {handler(self, self.callback_)})
end

function ProviderAndroid:removeListener()
	luaj.callStaticMethod(SDK_CLASS_NAME, "removeScriptListener")
end

function ProviderAndroid:startPush()
    local ok = luaj.callStaticMethod(SDK_CLASS_NAME, "startPush")
    if not ok then
        print("cc.push.ProviderAndroid:ctor() - call startPush failed.")
        return false
    end

    return true
end

function ProviderAndroid:stopPush()
	local ok = luaj.callStaticMethod(SDK_CLASS_NAME, "stopPush")
    if not ok then
        print("cc.push.ProviderAndroid:ctor() - call stopPush failed.")
        return false
    end

    return true
end

function ProviderAndroid:setAccount(account)
    local ok = luaj.callStaticMethod(SDK_CLASS_NAME, "setAccount", {account})
    if not ok then
        print("cc.push.ProviderAndroid:ctor() - call setAccount failed.")
        return false
    end

    return true
end

function ProviderAndroid:delAccount()
    local ok = luaj.callStaticMethod(SDK_CLASS_NAME, "delAccount", {})
    if not ok then
        print("cc.push.ProviderAndroid:ctor() - call delAccount failed.")
        return false
    end

    return true
end

function ProviderAndroid:setTags(tags)
    local ok = luaj.callStaticMethod(SDK_CLASS_NAME, "setTags", {table.concat(tags, ",")})
    if not ok then
        print("cc.push.ProviderAndroid:ctor() - call setTags failed.")
        return false
    end

    return true
end

function ProviderAndroid:delTags(tags)
    local ok = luaj.callStaticMethod(SDK_CLASS_NAME, "delTags", {table.concat(tags, ",")})
    if not ok then
        print("cc.push.ProviderAndroid:ctor() - call delTags failed.")
        return false
    end

    return true
end

return ProviderAndroid
