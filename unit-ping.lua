function widget:GetInfo()
    return {
        name    = "Attacked Unit Ping",
        desc    = "Adds button that sends camera to attacked units.",
        author  = "hihoman23",
        date    = "2023",
        license = "GNU GPL, v3 or later",
        layer   = 0,
        enabled = true --  loaded by default?
    }
end

--disables widget for scout spam
local toIgnore = {
    ["armflea"] = true, --Tick
    ["armpw"] = true,   --Pawn
    ["armfav"] = true,  --Rover
    ["corak"] = true,   --Grunt
    ["corfav"] = true,  --Rascal
}

local myTeam = Spring.GetMyTeamID()

local camState = Spring.GetCameraState()

local attackedUnit
local whenAttacked
local reactTime = 5 --how long you have to press the button to send camera to attacked unit

function widget:GameFrame(n)
    if attackedUnit then
        if whenAttacked + reactTime <= os.time(os.date("!*t")) then
            attackedUnit = nil
            return
        end
        local ux, uy, uz = spGetUnitPosition(attackedUnit)
        camState.px = ux
        camState.pz = uz
    end
end

function widget:UnitDamaged(unitID, unitDefID, unitTeam)
    local def = UnitDefs[unitDefID]
    if toIgnore[def.name] == nil then
        attackedUnit = unitID
        whenAttacked = os.time(os.date("!*t"))
    end
end
