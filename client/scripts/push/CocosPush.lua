local CURRENT_MODULE_NAME = ...

local CocoPush = class("CocoPush")

function CocoPush.getInstance(interface)
    local providerClass

	if device.platform == "android" then
        providerClass = import(".cocospush.ProviderAndroid", CURRENT_MODULE_NAME)
    elseif device.platform == "ios" then
        providerClass = import(".cocospush.ProviderIOS", CURRENT_MODULE_NAME)
    else
        providerClass = import(".cocospush.ProviderMock", CURRENT_MODULE_NAME)
    end

    local provider = providerClass.new(interface)
    provider:addListener()

    return provider
end

return CocoPush
