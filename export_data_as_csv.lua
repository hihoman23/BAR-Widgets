function widget:GetInfo()
    return {
      name = "Export Data",
      desc = "Creates a file in Widgets/CSV_data that shows player data.",
      author = "hihoman23",
      date = "2024",
      license = "GNU GPL, v2 or later",
      layer = 0,
      enabled = false
    }
end

local globalPath = "LuaUI/Widgets/CSV_data/"
local timeInterval = 15 -- in seconds, will get converted to frames later
local ignoreList = {
    time = true,
    frame = true,
    unitsOutCaptured = true
}

local data = {}
local frame = 0

local teamList = Spring.GetTeamList()
local teamCount = 0

local GetPlayerInfo = Spring.GetPlayerInfo
local GetTeamStatsHistory = Spring.GetTeamStatsHistory
local GetAIInfo = Spring.GetAIInfo
local GetTeamInfo = Spring.GetTeamInfo
local GetGaiaTeamID = Spring.GetGaiaTeamID

local playerTable = {}
local function createPlayerTable()
    for _, team in ipairs(teamList) do
        local playerName
        local _, leader, _, ai, _, allyTeamID = GetTeamInfo(team)
        if leader then
            if ai then
                _, playerName = GetAIInfo(team)
            else
                playerName = GetPlayerInfo(leader)
            end
            if not playerName then
                playerName = "Player Not Found"
            end
        end
        playerTable[team] = playerName
    end
end

local function tableToCSV(tbl, name, finalFrame)
    local file = io.open(globalPath..name, "w")
    if file then
        local heading = ""
        for i = 0, finalFrame, timeInterval do
            heading = heading .. i/1800 .. ","
        end
        if not ((finalFrame%timeInterval)==0) then
            heading = heading .. finalFrame/1800
        end
        for stat, globalData in pairs(tbl) do
            file:write(stat.."\n")
            file:write("AllyTeamID,TeamID,Player Name,"..heading.."\n")
            for i = 0, teamCount - 1 do
                local team = i
                local data = globalData[team]
                local _, _, _, _, _, allyTeamID = GetTeamInfo(team)

                if playerTable[team] then
                    local dataString = allyTeamID..","..team..","..playerTable[team] .. ","
                    for _, val in ipairs(data) do
                        dataString = dataString .. val .. ","
                    end
                    dataString = dataString .. "\n"
                    file:write(dataString)
                end
            end
            file:write("\n")
        end
        file:close()
    end
end

local function addCurrentData(force)
    if ((frame%timeInterval)==0) or force then
        for _,teamID in ipairs(teamList) do
            if teamID ~= GetGaiaTeamID() then
                local range = GetTeamStatsHistory(teamID)
                local history = GetTeamStatsHistory(teamID,0,range)
                if history then
                    teamCount = teamCount + 1
                    history = history[#history]

                    history.damageEfficiency = (history.damageDealt/history.damageReceived)*100

                    for stat, val in pairs(history) do
                        if not ignoreList[stat] then
                            local statTable = data[stat]
                            if statTable then
                                local playerStat = data[stat][teamID]
                                if playerStat then
                                    playerStat[#playerStat+1] = val
                                else
                                    statTable[teamID] = {val}
                                end
                            else
                                data[stat] = {[teamID] = {val}}
                            end
                        end
                    end
                end
            end
        end
    end
end

function widget:GameFrame(n)
    frame =  n
    teamCount = 0
    addCurrentData(false)
end

local function createName()
    local mapName = Game.mapName
    local timeDate = os.date("%Y-%m-%d_%H-%M".."_"..mapName..".csv")
    return timeDate
end

local function saveData(finalFrame)
    addCurrentData(true)
    tableToCSV(data, createName(), finalFrame)
    Spring.Echo("Resource Data Saved")
end

function widget:Initialize()
    timeInterval = timeInterval*30
    widgetHandler:AddAction("save_resource_data", saveData, nil, "p")
end

function widget:GameStart()
    createPlayerTable()
end


function widget:GameOver()
    saveData(frame)
end