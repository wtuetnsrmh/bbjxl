-- 新UI 副本Scene
-- by yangkun
-- 2014.3.24

local CarbonWorldMap = import(".CarbonWorldMap")
local CarbonLayer = import(".CarbonLayer")
local ConfirmDialog = import("..ConfirmDialog")
local FailureHelperLayer = import(".FailureHelperLayer")
local AssistHeroLayer = import(".AssistHeroLayer")

local CarbonScene = class("CarbonScene", function (params)
    return display.newScene("CarbonScene")
end)

function CarbonScene:ctor(params)
	self.params = params or {}
end

function CarbonScene:onEnter()
    -- 助战
    --[[if self.params.assistInfo and self.params.assistInfo.source ~= 1
        and game.role.guideStep ~= 8 and game.role.guideStep ~= 9 and game.role.guideStep ~= 10 and game.role.guideStep ~= 14 then
        local addAssistDialog = ConfirmDialog.new({
            showText = { text = string.format("是否添加[%s]为好友？", self.params.assistInfo.roleName), size = 28, },
            button2Data = {
                text = "加好友", font = ChineseFont, strokeColor = display.COLOR_FONT, strokeSize = 2,
                callback = function()
                    local applicationInfo = {
                        roleId = game.role.id,
                        objectId = self.params.assistInfo.roleId,
                        timestamp = game:nowTime(),
                    }
                    local bin = pb.encode("ApplicationInfo", applicationInfo)
                    game:sendData(actionCodes.FriendCreateApplication, bin)
                end,
            } 
        })
        addAssistDialog:getLayer():anch(0.5, 0.5):pos(display.cx, display.cy):addTo(self, 1)
    end]]

    self.mainLayer = CarbonWorldMap.new(self.params)
    self.mainLayer:getLayer():addTo(self)

    if self.params and self.params.layerType == 1 then
        local assistChooseAction = { roleId = game.role.id, chosenRoleId = 0, carbonId = self.params.carbonId  }
        local bin = pb.encode("AssistChooseAction", assistChooseAction)

        game:sendData(actionCodes.CarbonAssistChooseRequest, bin, #bin)
        game:addEventListener(actionModules[actionCodes.CarbonAssistChooseResponse], function(event)
            local msg = pb.decode("CarbonEnterAction", event.data)
            switchScene("battle", { carbonId = msg.carbonId, battleType = BattleType.PvE }) 
            return "__REMOVE__"
        end)
    end

    -- avoid unmeant back
    self:performWithDelay(function()
        -- keypad layer, for android
        local layer = display.newLayer()
        layer:addKeypadEventListener(function(event)
            if event == "back" then switchScene("home") end
        end)
        self:addChild(layer)

        layer:setKeypadEnabled(true)
    end, 0.5)
end

function CarbonScene:onCleanup()
    display.removeUnusedSpriteFrames()
end

return CarbonScene