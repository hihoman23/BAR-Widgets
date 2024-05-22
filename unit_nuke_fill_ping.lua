function widget:GetInfo()
    return {
        name    = "Nuke Ping",
        desc    = "Pings when nuke missile is ready",
        author  = "hihoman23",
        date    = "2023",
        license = "GNU GPL, v3 or later",
        layer   = 0,
        enabled = true --  loaded by default?
    }
end

local makePingRed = true
local pingColor
if makePingRed then
    pingColor = "\255"..string.char(255)..string.char(1)..string.char(1)
else
    pingColor = ""
end
local nukePings = 0
local maxPings = 5
local nukes = {}
local nukeDefs = {
    ["armsilo"] = true,
    ["corsilo"] = true
}

local myTeam = Spring.GetMyTeamID()
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitDefID = Spring.GetUnitDefID

--[[function widget:GameFrame()
    for nukeID, prevStockpile in pairs(nukes) do
        local stockpile = Spring.GetUnitStockpile(nukeID)
        if prevStockpile > stockpile then
            nukes[nukeID] = stockpile
        end
        if nukePings < maxPings then
            if prevStockpile < stockpile then

                nukes[nukeID] = stockpile
                nukePings =  nukePings + 1
                local ux, uy, uz = spGetUnitPosition(nukeID)
                Spring.MarkerAddPoint(ux, uy, uz, "nuke is ready", true)
            end
        end
    end
end]]

function widget:StockpileChanged(nukeID, unitDefID, unitTeam, weaponNum, prevStockpile, stockpile)
    if nukes[nukeID] and (nukePings < maxPings) then
        if prevStockpile > stockpile then
            nukes[nukeID] = stockpile
        end
        if prevStockpile < stockpile then

            nukes[nukeID] = stockpile
            nukePings =  nukePings + 1
            local ux, uy, uz = spGetUnitPosition(nukeID)
            Spring.MarkerAddPoint(ux, uy, uz, pingColor .. "nuke is ready", true)
        end
    end
end

function AddUnit(unitID, unitDefID, unitTeam)
    local def = UnitDefs[unitDefID]
    if nukeDefs[def.name] then
        if unitTeam == myTeam then
            local stockpile =  Spring.GetUnitStockpile(unitID)
            nukes[unitID] = stockpile
        end
    end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
    AddUnit(unitID, unitDefID, unitTeam)
end

function widget:UnitGiven(unitID, unitDefID, unitTeam)
    AddUnit(unitID, unitDefID, unitTeam)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
    if nukes[unitID] then
        nukes[unitID] = nil
    end
end

function widget:Initialize()
    if Spring.GetSpectatingState() then
        widgetHandler:RemoveWidget(self)
        do return end
    end
    for _, unitID in pairs(Spring.GetTeamUnits(myTeam)) do
        AddUnit(unitID, spGetUnitDefID(unitID), myTeam)
    end
end

function widget:PlayerChanged(playerID)
    if Spring.GetSpectatingState() then
        widgetHandler:RemoveWidget(self)
    end
end
