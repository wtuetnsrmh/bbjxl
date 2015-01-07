
local ProviderBase = class("ProviderBase")

local events = import("..events")

function ProviderBase:ctor(interface)
    self.interface_ = interface
end

function ProviderBase:callback_(event)
    local infos = string.split(event, "|")
    local evt = {
        provider = "push.CocoPush",
        type = infos[1],
        code = infos[2] 
    }
    if infos[3] then
        evt.sucTags = string.split(infos[3], ",")
    end
    if infos[4] then
        evt.failTags = string.split(infos[4], ",")
    end
    
    evt.name = events.LISTENER
    self.interface_:dispatchEvent(evt)
end

function ProviderBase:doCommand(args)
    if args.command == "startPush" then
        self:startPush()
    elseif args.command == "stopPush" then
        self:stopPush()
    elseif args.command == "setAccount" then
        if type(args.args) ~= "string" then
            print("cc.push.cocopush.ProviderBase:setAccount() - args must be string")
            return 
        end
        self:setAccount(args.args)
    elseif args.command == "delAccount" then
        self:delAccount()
    elseif args.command == "setTags" then
        if type(args.args) ~= "table" then
            print("cc.push.cocopush.ProviderBase:setTags() - args must be table")
            return 
        end
        self:setTags(args.args)
    elseif args.command == "delTags" then
        if type(args.args) ~= "table" then
            print("cc.push.cocopush.ProviderBase:delTags() - args must be table")
            return 
        end
        self:delTags(args.args)
    else
        print("cc.push.cocopush.ProviderBase:doCommand() - invaild command:" .. args.command)
    end
end

return ProviderBase