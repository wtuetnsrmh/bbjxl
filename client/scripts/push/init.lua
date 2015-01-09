local CURRENT_MODULE_NAME = ...

local push = class("cc.push")

local DEFAULT_PROVIDER_OBJECT_NAME = "CocosPush"

function push:ctor()
    cc.GameObject.extend(self):addComponent("components.behavior.EventProtocol"):exportMethods()
    self.events = import(".events", CURRENT_MODULE_NAME)
    self.providers_ = {}
end

function push:start(name)
    if not self.providers_[name] then
        local providerFactoryClass = import("." .. name, CURRENT_MODULE_NAME).new()
        local provider = providerFactoryClass.getInstance(self)

        self.providers_[name] = provider
        if not self.providers_[DEFAULT_PROVIDER_OBJECT_NAME] then
            self.providers_[DEFAULT_PROVIDER_OBJECT_NAME] = provider
        end
    end
end

function push:stop(name)
    local provider = self:getProvider(name)
    if provider then
        provider:removeListener()
        self.providers_[name or DEFAULT_PROVIDER_OBJECT_NAME] = nil
    end
end

--[[
args {
    command = "要执行的命令",
    providerName = "模块名字",
    args = "执行命令的参数"
}
]]
function push:doCommand(args)
    local provider = self:getProvider(name)
    if provider then
        provider:doCommand(args)
    end
end

function push:getProvider(name)
    name = name or DEFAULT_PROVIDER_OBJECT_NAME
    if self.providers_[name] then
        return self.providers_[name]
    end
    print("cc.push:getProvider() - provider %s not exists", name)
end

return push
