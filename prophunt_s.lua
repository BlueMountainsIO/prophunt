--[[

Prophunt server

]]--

local CountdownTime = 300
local Timer = 0

AddRemoteEvent("Prophunt:SwitchProp", function(player, asset_path)
	SetPlayerPropertyValue(player, "PropAsset", asset_path)
end)

AddRemoteEvent("Prophunt:PlaySound", function(player, sound)
	SetPlayerPropertyValue(player, "PropSound", sound)
end)

AddEvent("OnPlayerJoin", function(player)
	print("OnPlayerJoin", player)
	--SetPlayerSpawnLocation(player, 125773.000000, 80246.000000, 1645.000000, 90.0)
	SetPlayerSpawnLocation(player, 2288.000000, -170, 100, 90.0)
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
