--[[

Prophunt server

]]--

local Players = { }

local CountdownTime = 300
local Timer = 0

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
end

AddEvent("OnPackageStart", function()
	for k, v in pairs(GetAllPlayers()) do
		InitPlayer(v)
	end
end)

AddEvent("OnPlayerJoin", function(player)
	print("OnPlayerJoin", player)
	--SetPlayerSpawnLocation(player, 125773.000000, 80246.000000, 1645.000000, 90.0)
	SetPlayerSpawnLocation(player, 2288.000000, -170, 100, 90.0)

	InitPlayer(player)
end)

AddEvent("OnPlayerQuit", function(player)
	Players[player] = nil
end)
end)

AddEvent("OnPlayerChat", function(player, message)

	message = message:gsub("<span.->(.-)</>", "%1") -- removes chat span tag

	local fullchatmessage = '<span color="#7a3dd1">[PROP]</> '..GetPlayerName(player)..'('..player..'): '..message
	AddPlayerChatAll(fullchatmessage)

end)

AddEvent("OnPackageStart", function()

	Timer = CreateTimer(function()
		CountdownTime = CountdownTime - 1
		if CountdownTime == 0 then
			CountdownTime = 300
		end
		
		for k, v in pairs(GetAllPlayers()) do
			CallRemoteEvent(v, "Prophunt:SetGameTime", CountdownTime)
		end
	end, 1000)

end)

AddEvent("OnPackageStop", function()

	DestroyTimer(Timer)
	Timer = 0

end)
