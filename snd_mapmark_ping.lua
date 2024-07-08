function widget:GetInfo()
    return {
      name = "Mapmark Ping",
      desc = "Plays a sound when a point mapmark is placed by an allied player.",
      author = "hihoman23",
      date = "June 2024",
      license = "GNU GPL, v2 or later",
      layer = 0,
      enabled = true
    }
end

------------  config --------------
local mapmarkFile = "sounds/ui/mappoint2.wav"
local priorityPing = "sounds/ui/priority.wav"
local volume = 0.6
local range = 100

----------- local variables -------------
local isSpec = false
local airCount = 0

---------- Spring functions ---------------
local myTeam = Spring.GetMyTeamID()
local GetTeamAllyTeamID = Spring.GetTeamAllyTeamID
local myAllyTeam = GetTeamAllyTeamID(myTeam)
local GetUnitsInCylinder = Spring.GetUnitsInCylinder
local GetUnitTeam = Spring.GetUnitTeam
local GetUnitDefID = Spring.GetUnitDefID
local GetAllUnits = Spring.GetAllUnits
local GetUnitAllyTeam = Spring.GetUnitAllyTeam


local aircraft = {}
for unitDefID, def in pairs(UnitDefs) do
    if def.isAirUnit and not def.isBuilder then
        aircraft[unitDefID] = true
    end
end

function widget:PlayerChanged()
    isSpec = Spring.GetSpectatingState()
    myTeam = Spring.GetMyTeamID()
    myAllyTeam = GetTeamAllyTeamID(myTeam)
end

local function initUnit(unitID, unitDefID, team)
    if aircraft[unitDefID] and team == myTeam then
        airCount = airCount + 1
    end
end

function widget:Initialize()
    widget:PlayerChanged()
	WG['mapmarkping'] = {}
	WG['mapmarkping'].getMapmarkVolume = function()
		return volume
	end
	WG['mapmarkping'].setMapmarkVolume = function(value)
		volume = value
	end

    for _, uID in ipairs(GetAllUnits()) do
        initUnit(uID, GetUnitDefID(uID), GetUnitTeam(uID))
    end
end

function checkForAircraft(...)
    local units = GetUnitsInCylinder(...)
    for _, uID in ipairs(units) do
        if not (myAllyTeam == GetUnitAllyTeam(uID)) and aircraft[GetUnitDefID(uID)] then
            return true
        end
    end

    return false
end

function widget:MapDrawCmd(playerID, cmdType, x, y, z, a, b, c)
    if cmdType == "point" then
        local allUnits = GetUnitsInCylinder(x, z, range)
        local unitFound = false

        for _, unit in ipairs(allUnits) do
            if GetUnitTeam(unit) == myTeam then
                unitFound = true
                break
            end
        end

        if not unitFound and airCount > 0 then
            unitFound = string.find(a, "air") or checkForAircraft(x, z, range) 
        end

        if unitFound and (not isSpec) then
            Spring.PlaySoundFile(priorityPing, volume*0.5, nil, "ui")
        else
            Spring.PlaySoundFile( mapmarkFile, volume*20, x, y, z, nil, nil, nil, "ui")
            Spring.PlaySoundFile( mapmarkFile, volume*0.3, nil, "ui" )	-- to make sure it's still somewhat audible when far away
        end
    end
end


function widget:UnitCreated(...)
    initUnit(...)
end

function widget:UnitGiven(...)
    initUnit(...)
    
    local _, unitDefID, _, oldTeam = ...
    if oldTeam == myTeam and aircraft[unitDefID] then
        airCount = airCount - 1
    end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
    if unitTeam == myTeam and aircraft[unitDefID] then
        airCount = airCount - 1
    end
end

function widget:GetConfigData(data)
	return {
		volume = volume,
	}
end

function widget:SetConfigData(data)
	if data.volume ~= nil then
		volume = data.volume
	end
end