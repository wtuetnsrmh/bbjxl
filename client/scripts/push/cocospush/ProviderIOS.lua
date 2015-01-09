
local ProviderBase = import(".ProviderBase")
local ProviderIOS = class("ProviderIOS", ProviderBase)

local SDK_CLASS_NAME = "com.cocos.CCPushHelper"

function ProviderIOS:addListener()
	luaj.callStaticMethod(SDK_CLASS_NAME, "addScriptListener", {handler(self, self.callback_)})
end

function ProviderIOS:removeListener()
	luaj.callStaticMethod(SDK_CLASS_NAME, "removeScriptListener")
end

function ProviderIOS:startPush()
    local ok = luaj.callStaticMethod(SDK_CLASS_NAME, "startPush")
    if not ok then
        print("cc.push.ProviderIOS:ctor() - call startPush failed.")
        return false
    end

    return true
end

function ProviderIOS:stopPush()
	local ok = luaj.callStaticMethod(SDK_CLASS_NAME, "stopPush")
    if not ok then
        print("cc.push.ProviderIOS:ctor() - call stopPush failed.")
        return false
    end

    return true
end

function ProviderIOS:setAccount(account)
    local ok = luaj.callStaticMethod(SDK_CLASS_NAME, "setAccount", {account})
    if not ok then
        print("cc.push.ProviderIOS:ctor() - call setAccount failed.")
        return false
    end

    return true
end

function ProviderIOS:delAccount()
    local ok = luaj.callStaticMethod(SDK_CLASS_NAME, "delAccount", {})
    if not ok then
        print("cc.push.ProviderIOS:ctor() - call delAccount failed.")
        return false
    end

    return true
end

function ProviderIOS:setTags(tags)
    local ok = luaj.callStaticMethod(SDK_CLASS_NAME, "setTags", {table.concat(tags, ",")})
    if not ok then
        print("cc.push.ProviderIOS:ctor() - call setTags failed.")
        return false
    end

    return true
end

function ProviderIOS:delTags(tags)
    local ok = luaj.callStaticMethod(SDK_CLASS_NAME, "delTags", {table.concat(tags, ",")})
    if not ok then
        print("cc.push.ProviderIOS:ctor() - call delTags failed.")
        return false
    end

    return true
end

return ProviderIOS
