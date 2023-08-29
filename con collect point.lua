function widget:GetInfo()
    return {
        name    = "Con collect point",
        desc    = "Allows adding of collect points were constructers can collect after being idle",
        author  = "hihoman23",
        date    = "2023",
        license = "GNU GPL, v2 or later",
        layer   = 0,
        enabled = true --  loaded by default?
    }
end

local cons = {}
local meetingPoints = {}
local commaListen = false
local commaPressTime = -10
local coms = {
    ["armcom"] = true,
    ["corcom"] = true
}

local myTeam = Spring.GetMyTeamID()
local spGiveOrderToUnit = Spring.GiveOrderToUnit

local CMD_MOVE = CMD.MOVE

function Dist(x1, y1, x2, y2)
    return math.sqrt((x1-x2)^2+(y1-y2)^2)
end

function widget:UnitIdle(unitID)
    if cons[unitID] then
        if #meetingPoints ~= 0 then
            local ux, uy, uz = Spring.GetUnitPosition(unitID)
            local bestDist = math.huge
            local bestPos
            local currDist
            for _, pos in pairs(meetingPoints) do
                currDist = Dist(ux, uz, pos[1], pos[3])
                if currDist < bestDist then
                    bestDist = currDist
                    bestPos = pos
                end
            end
            if bestDist>100 then
                spGiveOrderToUnit(unitID, CMD_MOVE, { bestPos[1], bestPos[2], bestPos[3]}, 0)
            end
        end
    end
end

function widget:MousePress(_,_,button)
    local mouseX, mouseY = Spring.GetMouseState()
    local desc, args = Spring.TraceScreenRay(mouseX, mouseY, true)
    if nil == desc then return end -- off map
    local x = args[1]
    local y = args[2]
    local z = args[3]
    if Spring.GetGameSeconds() - commaPressTime > 5 then
        commaListen = false
    end
    if commaListen then
        meetingPoints[#meetingPoints+1] = {x, y, z}
        commaListen = false
    end
end


function widget:KeyRelease(key)
    if key == 44 then
        if not commaListen then
            commaListen = true
            commaPressTime = Spring.GetGameSeconds()
        else
            commaListen = false
            meetingPoints = {}
        end
    end
end

function InitUnit(unitID, unitDefID, unitTeam)
    if unitTeam == myTeam then
        local def = UnitDefs[unitDefID]
        if (def.isBuilder == true and (not coms[def.name])) and (def.canMove and def.speed > 0.000001) then
            cons[unitID] = true
        end
    end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
    InitUnit(unitID, unitDefID, unitTeam)
end

function widget:UnitGiven(unitID, unitDefID, unitTeam)
    InitUnit(unitID, unitDefID, unitTeam)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
    if cons[unitID] then
        cons[unitID] = nil
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
