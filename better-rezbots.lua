function widget:GetInfo()
    return {
        name    = "Better Rezbots",
        desc    = "Adds toggle(alt + w) to rezbots that allows them to rezzurect units and then immediately reclaim them.",
        author  = "hihoman23",
        date    = "2023",
        license = "GNU GPL, v2 or later",
        layer   = 0,
        enabled = true --  loaded by default?
    }
end

local rezNames = {
    ["armrectr"] = true,
    ["cornecro"] = true
}
local rezzers = {}
local reclaimAfterRez = true

local myTeam = Spring.GetMyTeamID()


function widget:KeyPress(key, mods, isRepeat)
    if (key == 119) and (mods.alt) then -- alt + w
        reclaimAfterRez = not reclaimAfterRez
        if reclaimAfterRez then
            Spring.Echo("reclaiming rezzurected units activated")
        else
            Spring.Echo("reclaiming rezzurected units disabled")
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
    if rezzers[bID] and reclaimAfterRez then
        Spring.GiveOrderToUnit(bID,
            CMD.INSERT,
            {0,CMD.RECLAIM,CMD.OPT_SHIFT,unitID},
            {"alt"}
        )
    end
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
