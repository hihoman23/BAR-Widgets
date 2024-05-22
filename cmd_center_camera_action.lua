function widget:GetInfo()
    return {
        name    = "Center On Action",
        desc    = "Adds button that sends camera to attacked units.",
        author  = "hihoman23",
        date    = "2023",
        license = "GNU GPL, v3 or later",
        layer   = 0,
        enabled = true --  loaded by default?
    }
end
--change keybinds at line 98


--disables widget for scout spam
local toIgnore = {
    ["armflea"] = true, --Tick
    ["armpw"] = true,   --Pawn
    ["armfav"] = true,  --Rover
    ["corak"] = true,   --Grunt
    ["corfav"] = true,  --Rascal
}

local myTeam = Spring.GetMyTeamID()

local spGetUnitPosition = Spring.GetUnitPosition
local attackedUnitX
local attackedUnitZ
local whenAttacked
local prevCamPosX
local prevCamPosZ
local prevSelectedUnit
local letterNPressed = false
local letterMPressed = false
local reactTime = 15 --how long you have to press the button to send camera to attacked unit

local selectedUnits

local defending = false

function DeselectAllUnits()
    for i, v in pairs(Spring.GetSelectedUnits()) do
        Spring.DeselectUnit(v)
    end
end

--moves camera to specific x and z positions
function MoveCam(x,z)
    local camState = Spring.GetCameraState()
    camState.px = x
    camState.py = camState.py
    camState.pz = z
    Spring.SetCameraState(camState, 0)
end

function widget:GameFrame(n)
    --Spring.Echo(attackedUnitX)
    if attackedUnitX ~= nil then
        if letterMPressed then
            local camState = Spring.GetCameraState()
            if prevCamPosX == nil then
                prevCamPosX = camState.px
                prevCamPosZ = camState.pz
                prevSelectedUnit = Spring.GetSelectedUnits()
            end

            MoveCam(attackedUnitX, attackedUnitZ)
            DeselectAllUnits()
            do return end
        end
        if whenAttacked + reactTime <= Spring.GetGameSeconds() then
            attackedUnitX = nil
            return
        end
        if letterNPressed then
            MoveCam(prevCamPosX, prevCamPosZ)
            Spring.SelectUnitArray(prevSelectedUnit)
            prevCamPosX = nil
        end
    end
end

function widget:UnitDamaged(unitID, unitDefID, unitTeam)
    if unitTeam == myTeam then
        local def = UnitDefs[unitDefID]
        if toIgnore[def.name] == nil then
            local ux, uy, uz = spGetUnitPosition(unitID)
            attackedUnitX = ux
            attackedUnitZ = uz
            whenAttacked = Spring.GetGameSeconds()
        end
    end
end

--letter n = 110
--letter m = 109
function widget:KeyPress(key)
    if key == 110 then
        letterNPressed = true
    end
    if key == 109 then
        letterMPressed = true
    end
end
function widget:KeyRelease(key)
    if key == 110 then
        letterNPressed = false
    end
    
    if key == 109 then
        letterMPressed = false
    end
end
