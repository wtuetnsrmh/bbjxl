
local ProviderBase = import(".ProviderBase")
local ProviderMock = class("ProviderMock", ProviderBase)

local SDK_CLASS_NAME = "com.cocos.CCPushHelper"

function ProviderMock:addListener()
end

function ProviderMock:removeListener()
end

function ProviderMock:startPush()
    return true
end

function ProviderMock:stopPush()
    return true
end

function ProviderMock:setAccount(account)
    return true
end

function ProviderMock:delAccount()
    return true
end

function ProviderMock:setTags(tags)
    return true
end

function ProviderMock:delTags(tags)
    return true
end

return ProviderMock
