--[[

Prophunt server

]]--

AddRemoteEvent("Prophunt:SwitchProp", function(player, asset_path)
	SetPlayerPropertyValue(player, "PropAsset", asset_path)
end)

AddRemoteEvent("Prophunt:PlaySound", function(player, sound)
	SetPlayerPropertyValue(player, "PropSound", sound)
end)
