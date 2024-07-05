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

local mapmarkFile = "sounds/ui/mappoint2.wav"
local priorityPing = "sounds/ui/priority.wav"
local volume = 0.6
local myTeam = Spring.GetMyTeamID()

local range = 100
local isSpec = false


local GetUnitsInCylinder = Spring.GetUnitsInCylinder
local GetUnitTeam = Spring.GetUnitTeam

function widget:PlayerChanged()
    isSpec = Spring.GetSpectatingState()
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
        if unitsFound and not isSpec then
            Spring.PlaySoundFile(priorityPing, volume*0.5, nil, "ui")
        else
            Spring.PlaySoundFile( mapmarkFile, volume*20, x, y, z, nil, nil, nil, "ui")
            Spring.PlaySoundFile( mapmarkFile, volume*0.3, nil, "ui" )	-- to make sure it's still somewhat audible when far away
        end
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
