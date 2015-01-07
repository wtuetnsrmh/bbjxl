local TrialBattleCsvData = {
    m_data = {},
}

function TrialBattleCsvData:load(fileName)
    self.m_data = {}

    local csvData = CsvLoader.load(fileName)
    
    for index = 1, #csvData do
        local battleid= tonum(csvData[index]["id"])
        if battleid > 0 then
            self.m_data[battleid] = {
                id = battleid,
                desc = tostring(csvData[index]["副本描述"]),
                hard = tostring(csvData[index]["难度"]),
                health = tonum(csvData[index]["体力消耗"]),
                level = tonum(csvData[index]["开放等级"]),
                openday = string.toArray(csvData[index]["开放日期"], " ", true),
                maxround = tonum(csvData[index]["战斗阶段"]),
               
                btres = tostring(csvData[index]["战斗配表"]),
                bgRes1 = tostring(csvData[index]["战斗场景1"]),
                bgRes2 = tostring(csvData[index]["战斗场景2"]),
                bgRes3 = tostring(csvData[index]["战斗场景3"]),
            }
        end
    end
end

function TrialBattleCsvData:isOpen(bigId)
    local data = self:getDataById(bigId .. 1)
    if data then
        -- if data.level > game.role.level then
        --     return false, "未到开放等级"
        -- end

        local day = os.date("*t", game:nowTime()).wday
        day = day == 1 and 7 or day - 1
        for i=1, #data.openday do
            if data.openday[i] == day then 
                return true
            end
        end
        return false
    end
    --没有数据处理成长期开放
    return true
end
        

function TrialBattleCsvData:getDataById(id)
    return self.m_data[tonumber(id)]
end

return TrialBattleCsvData