--[[

Prophunt server

]]--

Players = { }

local CountdownTime = 300
local Timer = 0
local WeaponsTimer
local GameState = 0 -- 0 : waiting, 1 : in game
local round_number = 0
local last_hunters = {}
local ratio_hunters_props = 4 -- 1 hunter for 4 props

local function GetPropHuntPlayerCount()
    return table.len(Players)
end

function CheckToRestart(from_quit_player)
	local soustract = 0
	GameState = 0
	if Timer ~= 0 then
		DestroyTimer(Timer)
		Timer = 0
	end
	if from_quit_player then
		soustract = 1
	end
	if GetPlayerCount() - soustract > 1 then
		if from_quit_player then
			Players[from_quit_player] = nil
		end
		StartNewRound()
	elseif GetPlayerCount() - soustract == 1 then
		local ply = GetAllPlayers()[1]
		if ply == from_quit_player then
            ply = GetAllPlayers()[2]
		end
		Players[ply].role = ""
		CallRemoteEvent(ply, "SetRoleClient", "", -1)
		CallRemoteEvent(ply, "SpecRemoteEvent", false)
		SetPlayerPropertyValue(ply, "Spectating", nil)
		SetPlayerPropertyValue(ply, "PropAsset", "/Game/Geometry/DesertGasStation/Meshes/Props/SM_Bench_01")
		SetPlayerPropertyValue(ply, "PropRotation", 0.0)
	else
		last_hunters = {}
	end
end

local function GeneratePotentialHuntersTable()
	local tbl = {}
	for ply, v in pairs(Players) do
		local steamid = tostring(GetPlayerSteamId(ply))
		local was_hunter
		for i, v2 in ipairs(last_hunters) do
			if v2 == steamid then
				was_hunter = true
				break
			end
		end
		if not was_hunter then
            table.insert(tbl, ply)
		end
	end
	if table.len(tbl) == 0 then
        for ply, v in pairs(Players) do
			table.insert(tbl, ply)
		end
	elseif table.len(tbl) < math.ceil(GetPropHuntPlayerCount() / 4) then
		for ply, v2 in pairs(Players) do
			local cant_insert
			for i, v in ipairs(tbl) do
				if ply == v then
                    cant_insert = true
				end
			end
			if not cant_insert then
				table.insert(tbl, ply)
				if table.len(tbl) >= math.ceil(GetPropHuntPlayerCount() / 4) then
					break
				end
		    end
		end
	end
	return tbl
end

local function SetHunter(ply)
    CallRemoteEvent(ply, "SpecRemoteEvent", false)
	SetPlayerPropertyValue(ply, "Spectating", nil)
	SetPlayerPropertyValue(ply, "PropAsset", nil)
	Players[ply].role = "hunter"
	CallRemoteEvent(ply, "SetRoleClient", Players[ply].role, round_number)
	SetPlayerWeapon(ply, 11, 9999, true, 1)
	SetPlayerLocation(ply, 8927, 6330, 200)
	SetPlayerSpawnLocation(ply, 8927, 6330, 200, 70.0)
	SetPlayerHealth(ply, 100)
	table.insert(last_hunters, tostring(GetPlayerSteamId(ply)))
end

function StartNewRound()
	GameState = 1
	round_number = round_number + 1
	for k, v in pairs(Players) do
		Players[k].role = ""
	end
	local potential_hunters = GeneratePotentialHuntersTable()
	local len_tbl = table.len(potential_hunters)
	last_hunters = {}
	local _hunters = math.ceil(GetPropHuntPlayerCount() / 4)
	if _hunters > 1 then
		for i = 1, _hunters do
			local random = math.random(len_tbl)
			SetHunter(potential_hunters[random])
			table.remove(potential_hunters, random)
		end
	else
		if len_tbl == 1 then
			SetHunter(potential_hunters[1])
		else
			SetHunter(potential_hunters[math.random(len_tbl)])
		end
	end
	for k, v in pairs(Players) do
		if v.role ~= "hunter" then
			CallRemoteEvent(k, "SpecRemoteEvent", false)
			SetPlayerPropertyValue(k, "Spectating", nil)
			SetPlayerPropertyValue(k, "PropAsset", "/Game/Geometry/DesertGasStation/Meshes/Props/SM_Bench_01")
			SetPlayerPropertyValue(k, "PropRotation", 0.0)
			Players[k].role = "prop"
			CallRemoteEvent(k, "SetRoleClient", Players[k].role, round_number)
			SetPlayerLocation(k, 2288.000000, -170, 275)
			SetPlayerSpawnLocation(k, 2288.000000, -170, 275, 90.0)
			SetPlayerHealth(k, 100)
		end
	end
	CountdownTime = 300
	if Timer ~= 0 then
		DestroyTimer(Timer)
	end
	Timer = CreateTimer(function()
		CountdownTime = CountdownTime - 1
		if CountdownTime == 0 then
			AddPlayerChatAll("[PROPHUNT]: Props won !")
			StartNewRound()
		end
		
		for k, v in pairs(GetAllPlayers()) do
			CallRemoteEvent(v, "Prophunt:SetGameTime", CountdownTime)
		end
	end, 1000)
end

AddRemoteEvent("Prophunt:SwitchProp", function(player, asset_path)
	SetPlayerPropertyValue(player, "PropAsset", asset_path)
	SetPlayerPropertyValue(player, "PropRotation", 0.0)
end)

AddRemoteEvent("Prophunt:PlaySound", function(player, sound)

	if GetTimeSeconds() - Players[player].taunt_cooldown < 5.0 then
		return
	end

	Players[player].taunt_cooldown = GetTimeSeconds()

	SetPlayerPropertyValue(player, "PropSound", sound)

end)

AddRemoteEvent("Prophunt:ChangeRotation", function(player, rot)
	SetPlayerPropertyValue(player, "PropRotation", rot)
end)

function InitPlayer(player)
	Players[player] = { }
	Players[player].taunt_cooldown = 0
	Players[player].role = ""
	if GameState == 0 then
		--print("GetPropHuntPlayerCount() " .. tostring(GetPropHuntPlayerCount()))
		if GetPropHuntPlayerCount() > 1 then
			StartNewRound()
		end
	else
		Players[player].role = "spec"
		ChangePlayerSpec(player, player)
		--print("spec InitPlayer")
	end
end

function CheckWeaponsTimer()
    for k, v in pairs(Players) do
		if v.role ~= "hunter" then
            SetPlayerWeapon(k, 1, 0, false, 1)
		end
	end
end

AddEvent("OnPackageStart", function()
    WeaponsTimer = CreateTimer(CheckWeaponsTimer, 1000)
end)

AddEvent("OnPlayerJoin", function(player)
	--print("OnPlayerJoin", GetPlayerName(player))
	--SetPlayerSpawnLocation(player, 125773.000000, 80246.000000, 1645.000000, 90.0)
	SetPlayerSpawnLocation(player, 2288.000000, -170, 275, 90.0)
	SetPlayerRespawnTime(player, 3000)

	--InitPlayer(player)
end)

function GetPropsCount()
	count = 0
    for i, v in pairs(Players) do
		if v.role == "prop" then
			count = count + 1
		end
	end
	return count
end

function GetHuntersCount()
	count = 0
    for i, v in pairs(Players) do
		if v.role == "hunter" then
			count = count + 1
		end
	end
	return count
end

AddEvent("OnPlayerQuit", function(player)
	if Players[player] then
		if Players[player].role == "hunter" then
			if GetHuntersCount() <= 1 then
				AddPlayerChatAll("[PROPHUNT]: Props won !")
				CheckToRestart(player)
			end
		end
		if Players[player].role == "prop" then
			if GetPropsCount() <= 1 then
				AddPlayerChatAll("[PROPHUNT]: Hunters won !")
				CheckToRestart(player)
			end
		end
		Players[player] = nil
    end
end)

AddEvent("OnPlayerDeath", function(ply, killer)
	if Players[ply] then
		if (Players[ply].role == "hunter" or Players[ply].role == "prop") then
			local won
			if Players[ply].role == "hunter" then
				if GetHuntersCount() <= 1 then
					won = true
					AddPlayerChatAll("[PROPHUNT]: Props won !")
					StartNewRound()
				end
			end
			if Players[ply].role == "prop" then
				if GetPropsCount() <= 1 then
					won = true
					AddPlayerChatAll("[PROPHUNT]: Hunters won !")
					StartNewRound()
				end
			end
			if not won then
				ChangePlayerSpec(ply, ply)
				Players[ply].role = "spec"
			end
	    end
	end
end)

AddEvent("OnPlayerChat", function(player, message)

	if Players[player] then
		local fullchatmessage
		if (Players[player].role == "prop" or Players[player].role == "hunter") then
			message = message:gsub("<span.->(.-)</>", "%1") -- removes chat span tag
			local color
			if Players[player].role == "prop" then
				color = "#7a3dd1"
			elseif Players[player].role == "hunter" then
				color = "#8b0000"
			end
			fullchatmessage = '<span color="'.. color ..'">['.. string.upper(Players[player].role) ..']</> '..GetPlayerName(player)..'('..player..'): '..message
		else
			fullchatmessage = GetPlayerName(player)..'('..player..'): '..message
	    end

		AddPlayerChatAll(fullchatmessage)
	end

end)

AddEvent("OnPackageStop", function()

	DestroyTimer(Timer)
	Timer = 0

	if WeaponsTimer then
		DestroyTimer(WeaponsTimer)
		WeaponsTimer = nil
	end

end)

AddRemoteEvent("PlayerJoined", function(ply)
    InitPlayer(ply)
end)

AddRemoteEvent("SetWeaponHunter", function(ply)
	if Players[ply].role == "hunter" then
		SetPlayerWeapon(ply, 11, 9999, true, 1)
	end
end)

AddEvent("OnPlayerWeaponShot", function(ply, weap, hittype, hitid, hitX, hitY, hitZ, startX, startY, startZ, normalX, normalY, normalZ, BoneName)
	if Players[ply] then
		if hittype == HIT_PLAYER then
			if Players[ply].role == "hunter" then
				if Players[hitid] then
					if Players[hitid].role == "hunter" then
					    return false
					end
				end
			else
				return false
			end
		end
	end
end)
