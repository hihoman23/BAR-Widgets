function widget:GetInfo()
	return {
		name      = "Reclaim enemy units",
		desc      = "When an area reclaim command is sent but there are no valid targets, enemies are automatically targeted",
		author    = "hihoman23",
		date      = "jan2024",
		license   = "GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

local onlyReclaimWhenNoTarget = false

local myTeam = Spring.GetMyTeamID()
local myAllyTeam = Spring.GetMyAllyTeamID()
local GetUnitsInCylinder = Spring.GetUnitsInCylinder
local GetUnitAllyTeam = Spring.GetUnitAllyTeam
local GiveOrderToUnit = Spring.GiveOrderToUnit
local GetFeaturesInCylinder = Spring.GetFeaturesInCylinder

local CMD_RECLAIM = CMD.RECLAIM



function widget:UnitCommand(unitID, _, unitTeam, cmdID, cmdParams, cmdOpts)
    if (cmdID == CMD_RECLAIM) and (#cmdParams == 4) and (unitTeam == myTeam) and not cmdOpts.shift then
		local x, z, r = cmdParams[1], cmdParams[3], cmdParams[4]
		local unitsInRange = GetUnitsInCylinder(x, z, r)

		if (#GetFeaturesInCylinder(x, z, r) > 0) and onlyReclaimWhenNoTarget then
			return
		end

		local enemiesInRange = {}
		for _, uID in ipairs(unitsInRange) do
			if GetUnitAllyTeam(uID) ~= myAllyTeam then
				table.insert(enemiesInRange, uID)
			end
		end

		for _, enemyID in ipairs(enemiesInRange) do
			GiveOrderToUnit(unitID, CMD_RECLAIM, {enemyID}, {'shift'})
		end
	end
end