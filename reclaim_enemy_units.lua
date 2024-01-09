local widgetName = "Reclaim enemy units"

function widget:GetInfo()
	return {
		name      = widgetName,
		desc      = "When an area reclaim command is sent but there are no valid targets, enemies are automatically targeted",
		author    = "hihoman23",
		date      = "jan2024",
		license   = "GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

local onlyReclaimWhenNoTarget = false
local stopBeforeQueueing = true

local myTeam = Spring.GetMyTeamID()
local myAllyTeam = Spring.GetMyAllyTeamID()
local GetUnitsInCylinder = Spring.GetUnitsInCylinder
local GetUnitAllyTeam = Spring.GetUnitAllyTeam
local GiveOrderToUnit = Spring.GiveOrderToUnit
local GetFeaturesInCylinder = Spring.GetFeaturesInCylinder

local CMD_RECLAIM = CMD.RECLAIM

local toDo = {}
local frame = 0

function widget:GameFrame(n)
	frame = n

	for k, toDoThing in pairs(toDo) do
		if toDoThing.when == frame then
			toDoThing.what()
			toDo[k] = nil
		end
	end
end


function widget:Initialize()
	if WG.options then
		WG.options.addOption({ widgetname = widgetName, id = "stopToggle", group = "custom", category = 2, name = "Don't Area Reclaim", type = "bool", value = stopBeforeQueueing, description = "Don't reclaim features before reclaiming enemy units(if there are no enemy units, area reclaim will still work)",
			onchange = function(i, value)
				stopBeforeQueueing = value
			end,
		})
	end
end

function widget:UnitCommand(unitID, _, unitTeam, cmdID, cmdParams, cmdOpts)
    if (cmdID == CMD_RECLAIM) and (#cmdParams == 4) and (unitTeam == myTeam) and not cmdOpts.shift then
		local x, z, r = cmdParams[1], cmdParams[3], cmdParams[4]
		local unitsInRange = GetUnitsInCylinder(x, z, r)

		if onlyReclaimWhenNoTarget and (#GetFeaturesInCylinder(x, z, r) > 0) then
			return
		end

		local enemiesInRange = {}
		for _, uID in ipairs(unitsInRange) do
			if GetUnitAllyTeam(uID) ~= myAllyTeam then
				table.insert(enemiesInRange, uID)
			end
		end

		toDo[#toDo+1] = {
			when = frame + 1, -- issue one frame later to prevent unit_immobile_builder.lua from canceling
			what = function ()
				if #enemiesInRange ~= 0 then
					for i, enemyID in ipairs(enemiesInRange) do
						if (i == 1) and stopBeforeQueueing then
							GiveOrderToUnit(unitID, CMD_RECLAIM, {enemyID}, {})
						else
							GiveOrderToUnit(unitID, CMD_RECLAIM, {enemyID}, {'shift'})
						end
					end
				end
			end
		}
	end
end

function widget:GetConfigData()
	local data = {
		stopBeforeQueueing = stopBeforeQueueing,
		onlyReclaimWhenNoTarget = onlyReclaimWhenNoTarget,
	}
	return data
end

function widget:SetConfigData(data)
	if data then
		stopBeforeQueueing = data.stopBeforeQueueing
		onlyReclaimWhenNoTarget = data.onlyReclaimWhenNoTarget
	end
end