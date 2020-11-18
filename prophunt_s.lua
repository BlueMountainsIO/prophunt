--[[

Prophunt server

]]--

Players = { }

local CountdownTime = 300
local Timer = 0
local WeaponsTimer
local GameState = 0 -- 0 : waiting, 1 : in game
local round_number = 0

function CheckToRestart(from_quit)
	local soustract = 0
	GameState = 0
	if Timer ~= 0 then
		DestroyTimer(Timer)
		Timer = 0
	end
	if from_quit then
        soustract = 1
	end
	if GetPlayerCount() - soustract > 1 then
		StartNewRound()
	elseif GetPlayerCount() - soustract == 1 then
		local ply = GetAllPlayers()[1]
		Players[ply].role = ""
		CallRemoteEvent(ply, "SetRoleClient", "", -1)
		CallRemoteEvent(ply, "SpecRemoteEvent", false)
		SetPlayerPropertyValue(ply, "Spectating", nil)
		SetPlayerPropertyValue(ply, "PropAsset", "/Game/Geometry/DesertGasStation/Meshes/Props/SM_Bench_01")
		SetPlayerPropertyValue(ply, "PropRotation", 0.0)
	end
end

function StartNewRound()
	GameState = 1
	local role = "prop"
	round_number = round_number + 1
	for k, v in pairs(Players) do
		if role == "prop" then
			role = "hunter"
			CallRemoteEvent(k, "SpecRemoteEvent", false)
			SetPlayerPropertyValue(k, "Spectating", nil)
			SetPlayerPropertyValue(k, "PropAsset", "/Game/Geometry/DesertGasStation/Meshes/Props/SM_Bench_01")
			SetPlayerPropertyValue(k, "PropRotation", 0.0)
			Players[k].role = "prop"
			CallRemoteEvent(k, "SetRoleClient", Players[k].role)
		elseif role == "hunter" then
			role = "prop"
			CallRemoteEvent(k, "SpecRemoteEvent", false)
			SetPlayerPropertyValue(k, "Spectating", nil)
			SetPlayerPropertyValue(k, "PropAsset", nil)
			SetPlayerHealth(k, 0)
			Players[k].role = "hunter"
			CallRemoteEvent(k, "SetRoleClient", Players[k].role)
			SetPlayerWeapon(k, 11, 9999, true, 1)
		end
		SetPlayerLocation(k, 2288.000000, -170, 250, 90.0)
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
		if GetPlayerCount() > 1 then
			StartNewRound()
		end
	else
		Players[player].role = "spec"
		ChangePlayerSpec(player, player)
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
	for k, v in pairs(GetAllPlayers()) do
		InitPlayer(v)
	end
    WeaponsTimer = CreateTimer(CheckWeaponsTimer, 1000)
end)

AddEvent("OnPlayerJoin", function(player)
	--print("OnPlayerJoin", player)
	--SetPlayerSpawnLocation(player, 125773.000000, 80246.000000, 1645.000000, 90.0)
	SetPlayerSpawnLocation(player, 2288.000000, -170, 100, 90.0)
	SetPlayerRespawnTime(player, 1000)

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
				CheckToRestart(true)
			end
		end
		if Players[player].role == "prop" then
			if GetPropsCount() <= 1 then
				AddPlayerChatAll("[PROPHUNT]: Hunters won !")
				CheckToRestart(true)
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

	message = message:gsub("<span.->(.-)</>", "%1") -- removes chat span tag

	local fullchatmessage = '<span color="#7a3dd1">[PROP]</> '..GetPlayerName(player)..'('..player..'): '..message
	AddPlayerChatAll(fullchatmessage)

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
