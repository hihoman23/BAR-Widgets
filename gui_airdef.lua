include("keysym.h.lua")

function widget:GetInfo()
	return {
		name    = "Air Defense Range",
		desc    = "Displays range of enemy air defenses",
		author  = "lov",
		date    = "2023",
		license = "GNU GPL v2",
		layer   = 0,
		enabled = false
	}
end
-----------------------------Changelog--------------------
--hihoman23    (15nov2023): Added an option to only show AA rings when aircraft are selected 



local onlyShowWhenAircraftSelected = true

-- CONFIGURATION
local lowspec = false -- if your computer is low spec
local keycode = 111   -- o key


local enabledAsSpec = false
local pi = math.pi

local function rgb(r, b, g, a)
	return { r / 255, b / 255, g / 255 }
end
-- local id = 27685
-- local _, vy, _ = Spring.GetUnitWeaponVectors(id, 1)
-- local x, y, z = Spring.GetUnitPosition(id)
-- local gy = Spring.GetGroundHeight(x, z)
-- Spring.Echo("HIEHGT", vy, y, gy, vy - gy)
local color1 = rgb(39, 255, 0) -- missile
local color3 = rgb(0, 55, 255) --strongmissile
local color2 = rgb(255, 0, 0)  --flak
local unitList = {
	-- ARMADA
	armrl = { weapons = { 2 }, color = color1, weaponheight = 64 }, --nettle
	armfrt = { weapons = { 2 }, color = color1, weaponheight = 64 }, --floating nettle
	armferret = { weapons = { 2 }, color = color1, weaponheight = 16 },
	armfrock = { weapons = { 2 }, color = color1, weaponheight = 29 },
	armcir = { weapons = { 2 }, color = color3, weaponheight = 46 }, --chainsaw

	armflak = { weapons = { 2 }, color = color2, weaponheight = 44 },
	armfflak = { weapons = { 2 }, color = color2 }, --floating flak AA
	armmercury = { weapons = { 1 }, color = color3, weaponheight = 70 },


	armsam = { weapons = { 2 }, color = color1 },  --whistler
	armjeth = { weapons = { 2 }, color = color1 }, --bot
	armamph = { weapons = { 2 }, color = color1 }, --platypus
	armaak = { weapons = { 2 }, color = color1 },  -- t2bot
	armlatnk = { weapons = { 2 }, color = color1 }, --jaguar
	armyork = { weapons = { 2 }, color = color2 }, --mflak


	armpt = { weapons = { 2 }, color = color1 }, --boat
	armaas = { weapons = { 2 }, color = color1 }, --t2boat
	armah = { weapons = { 2 }, color = color1 }, --hover

	-- armamd = { weapons = { 3 } }, --antinuke
	-- armscab = { weapons = { 3 } }, --antinuke

	corrl = { weapons = { 2 }, color = color1 },
	corfrt = { weapons = { 2 }, color = color1 }, --floating rocket laucher
	cormadsam = { weapons = { 2 }, color = color1 },
	corfrock = { weapons = { 2 }, color = color1 },

	corflak = { weapons = { 2 }, color = color2 },
	cornaa = { weapons = { 2 }, color = color2 },
	corscreamer = { weapons = { 1 }, color = color3, weaponheight = 59 },


	corcrash = { weapons = { 2 }, color = color1 }, --bot
	coraak = { weapons = { 2 }, color = color1 },  --t2bot

	cormist = { weapons = { 2 }, color = color1 }, --lasher
	corsent = { weapons = { 2 }, color = color2 }, --flak
	corban = { weapons = { 2 }, color = color3 },

	corpt = { weapons = { 2 }, color = color1 },  --boat
	corarch = { weapons = { 2 }, color = color1 }, --t2boat
	corah = { weapons = { 2 }, color = color1 },  --hover


	-- corfmd = { weapons = { 3 } }, --an
	-- cormabm = { weapons = { 3 } }, --an

}
-- cache only what we use
local weapTab = {} --WeaponDefs
local wdefParams = { 'salvoSize', 'reload', 'coverageRange', 'damages', 'range', 'type', 'projectilespeed',
	'heightBoostFactor', 'heightMod', 'heightBoostFactor', 'projectilespeed', 'myGravity' }
for weaponDefID, weaponDef in pairs(WeaponDefs) do
	weapTab[weaponDefID] = {}
	for i, param in ipairs(wdefParams) do
		weapTab[weaponDefID][param] = weaponDef[param]
	end
end
wdefParams = nil

local unitRadius = {}
local unitNumWeapons = {}
local canMove = {}
local unitSpeeds = {}
local unitName = {}
local unitWeapons = {}
for unitDefID, unitDef in pairs(UnitDefs) do
	unitRadius[unitDefID] = unitDef.radius
	local weapons = unitDef.weapons
	if #weapons > 0 then
		unitNumWeapons[unitDefID] = #weapons
		for i = 1, #weapons do
			if not unitWeapons[unitDefID] then
				unitWeapons[unitDefID] = {}
			end
			unitWeapons[unitDefID][i] = weapons[i].weaponDef
		end
	end
	unitSpeeds[unitDefID] = unitDef.speed
	-- for a, b in unitDef:pairs() do
	-- 	Spring.Echo(a, b)
	-- end
	canMove[unitDefID] = unitDef.canMove
	unitName[unitDefID] = unitDef.name
end

--Button display configuration
--position only relevant if no saved config data found
local buttonConfig          = {}
buttonConfig["enabled"]     = {
	ally = { ground = false, air = false, nuke = false, radar = false },
	enemy = { ground = true, air = true, nuke = true, radar = false }
}

local rangeCircleList --glList for drawing range circles

local spGetSpectatingState  = Spring.GetSpectatingState
local spec, fullview        = spGetSpectatingState()
local myAllyTeam            = Spring.GetMyAllyTeamID()

local defences              = {}

local lineConfig            = {}
lineConfig["lineWidth"]     = 1.5 -- calcs dynamic now
lineConfig["alphaValue"]    = 0.0 --> dynamic behavior can be found in the function "widget:Update"
lineConfig["circleDivs"]    = 80.0

local myPlayerID
local drawalpha             = 25

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---
local GL_LINE_LOOP          = GL.LINE_LOOP
local glBeginEnd            = gl.BeginEnd
local glColor               = gl.Color
local glDepthTest           = gl.DepthTest
local glLineWidth           = gl.LineWidth
local glTranslate           = gl.Translate
local glVertex              = gl.Vertex
local glCallList            = gl.CallList
local glCreateList          = gl.CreateList
local glDeleteList          = gl.DeleteList

local sqrt                  = math.sqrt
local abs                   = math.abs
local upper                 = string.upper
local floor                 = math.floor
local PI                    = math.pi
local cos                   = math.cos
local sin                   = math.sin

local spEcho                = Spring.Echo
local spGetGameSeconds      = Spring.GetGameSeconds
local spGetMyPlayerID       = Spring.GetMyPlayerID
local spGetPlayerInfo       = Spring.GetPlayerInfo
local spGetPositionLosState = Spring.GetPositionLosState
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitPosition     = Spring.GetUnitPosition
local spGetGroundHeight     = Spring.GetGroundHeight
local spIsGUIHidden         = Spring.IsGUIHidden
local spGetLocalTeamID      = Spring.GetLocalTeamID
local spIsSphereInView      = Spring.IsSphereInView

local chobbyInterface

local mapBaseHeight
local h                     = {}
for i = 1, 3 do
	for i = 1, 3 do
		h[#h + 1] = Spring.GetGroundHeight(Game.mapSizeX * i / 4, Game.mapSizeZ * i / 4)
	end
end
mapBaseHeight = 0
for _, s in ipairs(h) do
	mapBaseHeight = mapBaseHeight + s
end
mapBaseHeight = mapBaseHeight / #h
local gy = math.max(0, mapBaseHeight)


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Shutdown()
	if rangeCircleList then
		gl.DeleteList(rangeCircleList)
	end
end

local function init()
	local units = Spring.GetAllUnits()
	for i = 1, #units do
		local unitID = units[i]
		UnitDetected(unitID, Spring.IsUnitAllied(unitID))
		-- Spring.Echo("height", unitID, Spring.GetUnitDefID(unitID), Spring.GetUnitHeight(unitID), Spring.GetUnitMass(unitID),
		-- 	Spring.GetUnitRadius(unitID), Spring.GetUnitArmored(unitID))
	end
end

function widget:Initialize()
	myPlayerID = spGetLocalTeamID()

	init()
end

function widget:KeyPress(key, modifier, isRepeat)
	if key == keycode then
		drawalpha = (drawalpha + 25) % 75
		UpdateCircleList()
	end
end

function widget:UnitEnteredLos(unitID, allyTeam)
	UnitDetected(unitID, false, allyTeam)
end

function widget:UnitEnteredRadar(unitID, allyTeam)
	if defences[unitID] then
		local i
		for i = 1, #defences[unitID].weapons do
			defences[unitID].weapons[i].range = defences[unitID].weapons[i].originalrange
		end
	end
end

local function traceRay(x, y, z, tx, ty, tz)
	local stepsize = 3
	local dx       = tx - x
	local dy       = ty - y
	local dz       = tz - z
	local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
	if not (distance > stepsize) then return tx, ty, tz end
	local iterations = distance / stepsize
	local nx         = dx / distance
	local ny         = dy / distance
	local nz         = dz / distance
	local height
	for i = 0, iterations do
		x = x + nx * stepsize
		y = y + ny * stepsize
		z = z + nz * stepsize
		height = Spring.GetGroundHeight(x, z)
		if y < height then
			return x, height, z
		end
	end
	return tx, ty, tz
end

local function drawCircle(x, y, z, range, weaponheight, donttraceray)
	if lowspec then donttraceray = true end
	local altitude = 85
	local list = { { x, y + weaponheight, z } }
	local numSegments = 100
	local angleStep = (2 * pi) / numSegments
	local gy = Spring.GetGroundHeight(x, z)
	for i = 0, numSegments do
		local angle = i * angleStep
		local rx = sin(angle) * range + x
		local rz = cos(angle) * range + z
		local dx = x - rx
		local dz = z - rz
		local len2d = math.sqrt(dx ^ 2 + dz ^ 2)
		local splits = 30
		local step = len2d / splits
		dx = dx / len2d
		dz = dz / len2d
		local j = 0
		local ry = Spring.GetGroundHeight(rx, rz) + altitude
		while j < splits - 1 and not donttraceray do
			local hx, hy, hz = traceRay(x, gy + weaponheight, z, rx, ry, rz)
			if hx == rx and hy == ry and hz == rz then
				j = splits + 1 -- exit
			else
				rx = rx + dx * step
				rz = rz + dz * step
				ry = Spring.GetGroundHeight(rx, rz) + altitude
				j = j + 1
			end
		end

		list[#list + 1] = { rx, ry, rz }
	end
	return list
end

function UnitDetected(unitID, allyTeam, teamId)
	local unitDefID = spGetUnitDefID(unitID)
	local x, y, z = spGetUnitPosition(unitID)
	local uName = unitName[unitDefID]
	if unitList[uName] == nil then return end

	local foundWeapons = {}
	for i = 1, unitNumWeapons[unitDefID] do
		if unitList[uName]["weapons"][i] then
			local weaponDef = weapTab[unitWeapons[unitDefID][i]]
			local range = weaponDef.range --get normal weapon range
			local type = unitList[uName]["weapons"][i]
			local dam = weaponDef.damages
			local dps, damage
			local color = unitList[uName].color
			color[4] = .2

			dps = 0
			damage = dam[Game.armorTypes.vtol]
			if damage then
				dps = damage * weaponDef.salvoSize / weaponDef.reload
			end

			-- color1 = GetColorsByTypeAndDps(dps, type, (allyTeam == false))

			local weaponheight = unitList[uName].weaponheight or 63
			local verts = drawCircle(x, y, z, range, weaponheight, type == 1)


			foundWeapons[#foundWeapons + 1] = {
				type = type,
				range = range,
				originalrange = range,
				color1 = color,
				unitID = unitID,
				weaponnum = i,
				weaponheight = weaponheight,
				verts = verts,
				x = x,
				y = y,
				z = z
			}
		end
	end
	defences[unitID] = {
		allyState = (allyTeam == false),
		pos = { x, y, z },
		unitId = unitID,
		mobile = canMove[unitDefID],
		weapons = foundWeapons,
		unitSpeed = unitSpeeds[unitDefID]
	}

	UpdateCircleList()
end

function ResetGl()
	glColor({ 1.0, 1.0, 1.0, 1.0 })
	glLineWidth(1.0)
end

function widget:PlayerChanged()
	if myAllyTeam ~= Spring.GetMyAllyTeamID() or fullview ~= select(2, spGetSpectatingState()) then
		myAllyTeam = Spring.GetMyAllyTeamID()
		spec, fullview = spGetSpectatingState()
		init()
	end
end


local lastupdate = 0
local updateinterval = .6
function widget:Update()
	if fullview and not enabledAsSpec then
		return
	end
	if drawalpha == 0 then
		return
	end
	local time = spGetGameSeconds()

	if time - lastupdate > updateinterval then
		lastupdate = time
		local didupdate = false
		for k, def in pairs(defences) do
			if def.mobile then
				local ux, uy, uz = Spring.GetUnitPosition(def["unitId"])
				for i = 1, #def.weapons do
					local weapon = def.weapons[i]
					local upd = false
					if not uy then
						weapon.range = weapon.range - def.unitSpeed * updateinterval
						upd = true
					else
						if weapon.x ~= ux or weapon.y ~= uy or weapon.z ~= uz then
							upd = true
						end
						weapon.x = ux
						weapon.y = uy
						weapon.z = uz
					end
					if upd then
						didupdate = true
						if weapon.range > 0 then
							weapon.verts = drawCircle(weapon.x, weapon.y, weapon.z, weapon.range, weapon.weaponheight)
						else
							defences[k] = nil
						end
					end
				end
			end
			local x, y, z = def["pos"][1], def["pos"][2], def["pos"][3]
			local a, b, c = spGetPositionLosState(x, y, z)
			local losState = b
			if losState then
				if not spGetUnitDefID(def["unitId"]) then
					defences[k] = nil
					didupdate = true
				end
			end
		end
		if didupdate then
			UpdateCircleList()
		end
	end
end

local function BuildVertexList(verts)
	for i, vert in pairs(verts) do
		glVertex(vert)
	end
end

function DrawRanges()
	local selectedUnits = Spring.GetSelectedUnits()
	local aircraftSelected = false
	for _, uID in ipairs(selectedUnits) do
		if UnitDefs[Spring.GetUnitDefID(uID)].canfly then
			aircraftSelected = true
		end
	end
	if (not aircraftSelected)and onlyShowWhenAircraftSelected then
		do return end
	end

	glDepthTest(false)
	glTranslate(0, 0, 0) -- else it gets rendered below map sometimes
	local color
	local range
	for test, def in pairs(defences) do
		gl.PushMatrix()
		for i, weapon in pairs(def["weapons"]) do
			local execDraw = spIsSphereInView(def["pos"][1], def["pos"][2], def["pos"][3], weapon["range"])
			if execDraw then
				color = weapon["color1"]
				range = weapon["range"]

				gl.Blending("alpha_add")
				glColor(color[1], color[2], color[3], drawalpha / 255)
				gl.PolygonMode(GL.FRONT_AND_BACK, GL.FILL)
				glBeginEnd(GL.TRIANGLE_FAN, BuildVertexList, weapon.verts)
			end
		end
		gl.PopMatrix()
	end

	glDepthTest(true)
end

function UpdateCircleList()
	--delete old list
	if rangeCircleList then
		glDeleteList(rangeCircleList)
	end

	rangeCircleList = glCreateList(function()
		--create new list
		DrawRanges()
		ResetGl()
	end)
end

function widget:RecvLuaMsg(msg, playerID)
	if msg:sub(1, 18) == 'LobbyOverlayActive' then
		chobbyInterface = (msg:sub(1, 19) == 'LobbyOverlayActive1')
	end
end

function widget:DrawWorld()
	if fullview and not enabledAsSpec then
		return
	end
	if drawalpha == 0 then
		return
	end
	if chobbyInterface then return end
	if not spIsGUIHidden() and (not WG['topbar'] or not WG['topbar'].showingQuit()) then
		if rangeCircleList then
			glCallList(rangeCircleList)
		else
			UpdateCircleList()
		end
	end
end

function widget:GetConfigData()
	return {
		alpha = drawalpha,
	}
end

function widget:SetConfigData(data)
	if data.alpha ~= nil then
		drawalpha = data.alpha
	end
end
