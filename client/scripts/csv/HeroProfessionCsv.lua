local HeroProfessionCsvData = {
    m_data = {},
}

function HeroProfessionCsvData:load(fileName)
    self.m_data = {}

    local csvData = CsvLoader.load(fileName)
    
    for index = 1, #csvData do
        local professionId = tonum(csvData[index]["职业ID"])
        if professionId > 0 then
            local professionData = {}
            professionData.profession = professionId
            professionData.professionName = csvData[index]["职业名称"]
            professionData.moveSpeed = tonum(csvData[index]["移动速度"])
            professionData.attackSpeed = tonum(csvData[index]["攻击速度"])
            professionData.atcRange = tonum(csvData[index]["攻击距离"])
            professionData.frontAtcRange = tonum(csvData[index]["最前方攻击距离"])
            professionData.attackMusicId = tonum(csvData[index]["普攻音效ID"])
            professionData.skillMusicId = tonum(csvData[index]["技能音效ID"])

            self.m_data[professionData.profession] = professionData
        end
    end
end

function HeroProfessionCsvData:getDataByProfession(profession)
    return self.m_data[profession]
end

return HeroProfessionCsvData