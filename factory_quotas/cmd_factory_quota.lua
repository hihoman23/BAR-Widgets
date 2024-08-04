function widget:GetInfo()
    return {
      name = "Factory Quotas",
      desc = "Creates quotas of units that should be fulfilled(for example 5 Sheldons, 5 Sumos), will be queued before factory queue.",
      author = "hihoman23",
      date = "2024",
      license = "GNU GPL, v2 or later",
      layer = -1,
      enabled = false
    }
end

local quotas = {}

local allUnits = {}

local possibleFacts = {}
local factoryDefIDs = {}


for unitDefID, uDef in pairs(UnitDefs) do
    if uDef.isFactory then
        factoryDefIDs[unitDefID] = true
        for _, opt in pairs(uDef.buildOptions) do
            possibleFacts[opt] = possibleFacts[opt] or {}
            possibleFacts[opt][unitDefID] = true
        end
    end
end

-- Speeeed
local myTeam = Spring.GetMyTeamID()
local GiveOrderToUnit = Spring.GiveOrderToUnit
local GetFactoryCommands = Spring.GetFactoryCommands
local GetTeamUnitsCounts = Spring.GetTeamUnitsCounts
local GetTeamUnitsByDefs = Spring.GetTeamUnitsByDefs
-----



local function isFactoryUsable(factoryID)
    local commandq = GetFactoryCommands(factoryID, 2)
    return commandq and( #commandq == 0 or not (commandq[1].options.alt or commandq[2].options.alt))
end

local function tryToBuild(unitDefID, ignore)
    for factDefID, _ in pairs(possibleFacts[unitDefID] or {}) do
        local factories = GetTeamUnitsByDefs(myTeam, factDefID)
        for _, factory in ipairs(factories) do
            if isFactoryUsable(factory) and not ignore[factory] then
                GiveOrderToUnit(factory, -unitDefID, {}, {"alt"})
                return factory
            end
        end
    end
end

local function fillQuotas()
    allUnits = GetTeamUnitsCounts(myTeam)

    local newQuotas = {}
    for unitDefID , quota in pairs(quotas) do
        if quota.amount > (allUnits[unitDefID] or 0) then
            newQuotas[#newQuotas + 1] = {unitDefID, quota}
        end
    end

    local function isBetterQuota(quota1, quota2)
        local need1 = (allUnits[quota1[1]] or 0)/quota1[2].amount
        local need2 = (allUnits[quota2[1]] or 0)/quota2[2].amount
        return need1 < need2
    end

    table.sort(newQuotas, isBetterQuota)

    local usedFacts = {}
    for _, quotaPair in ipairs(newQuotas) do
        local fact = tryToBuild(quotaPair[1], usedFacts)
        if fact then
            usedFacts[fact] = true
        end
    end
end

function widget:GameFrame(n)
    if n % 30 == 0 then
        fillQuotas()
    end
end

function widget:PlayerChanged(playerID)
    if Spring.GetSpectatingState() then
        widgetHandler:RemoveWidget(self)
    end
    myTeam = Spring.GetMyTeamID()
end

function widget:Initialize()
    widget:PlayerChanged()

    for unitName, _ in pairs(quotas) do
        quotas[UnitDefNames[unitName].id] = quotas[unitName]
        quotas[unitName] = nil
    end

    WG.Quotas = {}
    WG.Quotas.getQuotas = function()
        return quotas
    end
    WG.Quotas.update = function(newQuotas)
        quotas = newQuotas
    end
end

function widget:Shutdown()
    WG.Quotas = nil
end
