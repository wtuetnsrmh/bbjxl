local MoneyBattleCsvData = {
    m_data = {},
}

function MoneyBattleCsvData:load(fileName)
    self.m_data = {}

    local csvData = CsvLoader.load(fileName)
    
    for index = 1, #csvData do
        local battleid= tonum(csvData[index]["id"])
        if battleid > 0 then
            self.m_data[battleid] = {
                id = battleid,
                desc = tostring(csvData[index]["副本描述"]),
                hard = tostring(csvData[index]["难度"]),
                health = tostring(csvData[index]["体力消耗"]),
                level = tonum(csvData[index]["开放等级"]),
                openday = tostring(csvData[index]["开放日期"]),
                atk = tostring(csvData[index]["实力系数"]),
                btres = tostring(csvData[index]["战斗配表"]),
                bgRes1 = tostring(csvData[index]["战斗场景1"]),
                bgRes2 = tostring(csvData[index]["战斗场景2"]),
                bgRes3 = tostring(csvData[index]["战斗场景3"]),
                bgRes4 = tostring(csvData[index]["战斗场景4"]),
                bgRes5 = tostring(csvData[index]["战斗场景5"]),
                talkid = tostring(csvData[index]["战斗对话"]),

                maxround = tostring(csvData[index]["战斗阶段"]),
                killMoney = tonum(csvData[index]["击杀银币奖励"]),
                passAward = tonum(csvData[index]["单关奖励"]),
                passGrowth = tonum(csvData[index]["单关成长"]),
                heroExp = tonum(csvData[index]["武将经验"]),
            }
        end
    end
end

function MoneyBattleCsvData:getDataById(id)
    return self.m_data[tonumber(id)]
end

return MoneyBattleCsvData