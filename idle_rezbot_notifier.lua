function widget:GetInfo()
    return {
        name    = "Idle Rezbot Notifier",
        desc    = "Notifies you when a rezbot is idle(alt + h) to toggle. Then, press alt + s to go to the rezbot(with the camera) and alt + d to go back.",
        author  = "hihoman23",
        date    = "2023",
        license = "GNU GPL, v3 or later",
        layer   = 0,
        enabled = true --  loaded by default?
    }
end

local rezNames = {
    ["armrectr"] = true,
    ["cornecro"] = true
}
local rezzers = {}
local myTeam = Spring.GetMyTeamID()
local pingIdles = true
local lastPingedRezzer
local prevCamX
local prevCamZ
local prevSelectedUnits

function DeselectAllUnits()
    for _, v in pairs(Spring.GetSelectedUnits()) do
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

-- returns x, z
function GetCamPos()
    local camState = Spring.GetCameraState()
    local x, z = camState.px, camState.pz
    return x, z
end

function widget:UnitIdle(unitID)
    if rezzers[unitID] and pingIdles then
        local ux, uy, uz = Spring.GetUnitPosition(unitID)
        Spring.MarkerAddPoint(ux, uy, uz, "rezzer idle", true)
        lastPingedRezzer = unitID
    end
end

function widget:KeyPress(key, mods, isRepeat)
    if (key == 104) and (mods.alt) then -- alt + h
        pingIdles = not pingIdles
        if pingIdles then
            Spring.Echo("idle rezbot notifications activated")
        else
            Spring.Echo("idle rezbot notifications disabled")
        end
    end
    if (key == 115) and (mods.alt) then -- alt + s
        if lastPingedRezzer then
            local selUnits = Spring.GetSelectedUnits()
            if not (selUnits[1] == lastPingedRezzer) then
                prevCamX, prevCamZ = GetCamPos()
                prevSelectedUnits = selUnits
            end
            local ux, _, uz = Spring.GetUnitPosition(lastPingedRezzer)
            MoveCam(ux, uz)
            DeselectAllUnits()
            Spring.SelectUnit(lastPingedRezzer)
        end
    end
    if (key == 100) and (mods.alt) then -- alt + d
        if prevCamX then
            MoveCam(prevCamX, prevCamZ)
            DeselectAllUnits()
            Spring.SelectUnitArray(prevSelectedUnits)
        end
    end
end

function InitUnit(unitID, unitDefID, unitTeam)
    if unitTeam == myTeam then
        local def = UnitDefs[unitDefID]
        if rezNames[def.name] then
            rezzers[unitID] = true
        end
    end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam, bID)
    InitUnit(unitID, unitDefID, unitTeam)
end

function widget:UnitGiven(unitID, unitDefID, unitTeam)
    InitUnit(unitID, unitDefID, unitTeam)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
    if rezzers[unitID] then
        rezzers[unitID] = nil
    end
end

function widget:Initialize()
    if Spring.GetSpectatingState() then
        widgetHandler:RemoveWidget(self)
        do return end
    end

    for _, unitID in pairs(Spring.GetTeamUnits(myTeam)) do
        InitUnit(unitID, Spring.GetUnitDefID(unitID), myTeam)
    end
end

function widget:PlayerChanged(playerID)
    if Spring.GetSpectatingState() then
        widgetHandler:RemoveWidget(self)
    end
end