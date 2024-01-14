function widget:GetInfo()
	return {
		name = "Reclaim Destruct",
		desc = "Adds a command(action handler) to all units that makes all constructors that can relcaim without moving reclaim that unit. Keybind to self_reclaim.",
		author = "hihoman23",
		date = "January 2024",
		license = "GNU GPL, v2 or later",
		layer = 0,
		enabled = true,
	}
end

include("keysym.h.lua")

local constructors = {} -- will get filled up with each constructor in the form of {unitID, buildRange^2}

local GetSelectedUnits = Spring.GetSelectedUnits
local GetSpectatingState = Spring.GetSpectatingState
local GetUnitPosition = Spring.GetUnitPosition
local GiveOrderToUnitArray = Spring.GiveOrderToUnitArray
local GetSelectedUnits = Spring.GetSelectedUnits
local myTeam = Spring.GetMyTeamID()

local CMD_INSERT = CMD.INSERT

local function distSq(x1, z1, x2, z2)
    return (x1 - x2)*(x1 - x2) + (x1 - x2)*(x1 - x2)
end

local function getValidCons(x, z, target)
    local validCons = {}
    for con, dist in pairs(constructors) do
        local conX, _, conZ = GetUnitPosition(con)
        if (distSq(conX, conZ, x, z) <= dist) and (target ~= con) then
            validCons[#validCons+1] = con
        end
    end
    return validCons
end

local function reclaimSelectedUnits()
    for _, unitID in pairs(GetSelectedUnits()) do
        local ux, _, uz = GetUnitPosition(unitID)
        GiveOrderToUnitArray(
            getValidCons(ux, uz),
            CMD_INSERT,
            {0,CMD.RECLAIM, CMD.OPT_SHIFT,unitID},
            {'alt'}
        )
    end
end

function InitUnit(unitID, unitDefID, unitTeam)
    if unitTeam == myTeam then
        local def = UnitDefs[unitDefID]
        if def.isBuilder then
            constructors[unitID] = def.buildDistance*def.buildDistance
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
    if constructors[unitID] then
        constructors[unitID] = nil
    end
end

function widget:Initialize()

    widgetHandler:AddAction("self_reclaim", reclaimSelectedUnits, nil, "p")

    if GetSpectatingState() then
        widgetHandler:RemoveWidget(self)
        do return end
    end

    for _, unitID in pairs(Spring.GetTeamUnits(myTeam)) do
        InitUnit(unitID, Spring.GetUnitDefID(unitID), myTeam)
    end
end

function widget:PlayerChanged(playerID)
    if GetSpectatingState() then
        widgetHandler:RemoveWidget(self)
    end
end