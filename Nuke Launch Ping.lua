function widget:GetInfo()
    return {
        name    = "Nuke Launch Ping",
        desc    = "Pings location and radius of nuke launches",
        author  = "hihoman23",
        date    = "2023",
        license = "GNU GPL, v3 or later",
        layer   = 0,
        enabled = true --  loaded by default?
    }
end

local nukes = {}
local myNukes = {}
local nukeDefs = {
    ["armsilo"] = true,
    ["corsilo"] = true
}
local nukeMissileDefs = {
    ["armsilo_nuclear_missile"] = true,
    ["corsilo_crblmssl"] = true
}
local explosionRanges = {
    ["armsilo_nuclear_missile"] = 640,
    ["corsilo_crblmssl"] = 960
}
local isMine
local lastPingFrame = -30
local pingCount = 0

local myTeam = Spring.GetMyTeamID()
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitDefID = Spring.GetUnitDefID

local sin, cos = math.sin,math.cos
function DrawFlatCircle(x, y, z, r, own, lines)
    lines = lines or 16
    local r1
    local r2
    for i = 1, lines do
        r1 = ((i-0.5)/lines) * 2 * math.pi
        r2 = ((i+0.5)/lines) * 2 * math.pi
        Spring.MarkerAddLine(x+r*cos(r1),y,z+r*sin(r1),x+r*cos(r2),y,z+r*sin(r2),own)
    end
end

function GetProjectTileTarget(projectileID)
    local targtype, targ = Spring.GetProjectileTarget(projectileID)
    if targtype == string.byte('g') then
      -- ground
        return targ[1],targ[2],targ[3]
    elseif targtype == string.byte('u') then
        return spGetUnitPosition(targ)
    elseif targtype == string.byte('f') then
        return Spring.GetFeaturePosition(targ)
    end
    return nil
end

function NukeLaunch(unitID, own)
    local ux, uy, uz = spGetUnitPosition(unitID)
    own = not own
    local projectiles = Spring.GetProjectilesInRectangle(ux-50,uz-50,ux+50,uz+50)
    local nukeID
    local projectileName
    for _,projectileID in pairs(projectiles) do
        projectileName = Spring.GetProjectileName(projectileID)
        if nukeMissileDefs[projectileName] then
            nukeID = projectileID
        end
    end
    projectileName = Spring.GetProjectileName(nukeID)
    

    local px, py, pz = GetProjectTileTarget(nukeID)

    Spring.MarkerAddPoint(px, py, pz, "Nuke Coming In Here", own)
    DrawFlatCircle(px, py, pz, explosionRanges[projectileName], own, 16)
end


function widget:GameFrame(n)
    local stockpile
    for nukeID, prevStockpile in pairs(nukes) do
        if pingCount >= 1 then
            pingCount = 0
            lastPingFrame = n
        end
        if (n - lastPingFrame)<5 then
            do return end
        end
        stockpile = Spring.GetUnitStockpile(nukeID)
        isMine = false
        if myNukes[nukeID] then
            isMine = true
        end
        if prevStockpile > stockpile then
            nukes[nukeID] = stockpile
            NukeLaunch(nukeID, isMine)
            pingCount = pingCount + 1
        end
        if prevStockpile < stockpile then
            nukes[nukeID] = stockpile
        end
    end
end

--[[function widget:StockpileChanged(nukeID, unitDefID, unitTeam, weaponNum, prevStockpile, stockpile)
    if not nukes[nukeID] then
        do return end
    end
    isMine = false
    if myNukes[nukeID] then
        isMine = true
    end
    if prevStockpile > stockpile then 
        nukes[nukeID] = stockpile
        NukeLaunch(nukeID, isMine)
    end
    --[[if prevStockpile < stockpile then
        nukes[nukeID] = stockpile
    end]]
--end

function AddUnit(unitID, unitDefID, unitTeam)
    local def = UnitDefs[unitDefID]
    if nukeDefs[def.name] then
        local stockpile =  Spring.GetUnitStockpile(unitID)
        nukes[unitID] = stockpile
        if unitTeam == myTeam then
            myNukes[unitID] = stockpile
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
    if myNukes[unitID] then
        myNukes[unitID] = nil
    end
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

-- cmdID 20 = attack
--function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID)
--end