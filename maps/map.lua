
AddEvent("OnPackageStart", function()
	if GetWorld():GetMapName() ~= "industrial_area" then
		LoadPak("Industrial_Area", "/Industrial_Area/", "../../../OnsetModding/Plugins/Industrial_Area/Content/")
	
		local mapname = "/Industrial_Area/industrial_area/maps/industrial_area"
		ConnectToServer(GetServerIP(), GetServerPort(), "", mapname)
	else
		Delay(1000, function()
		    CallRemoteEvent("PlayerJoined")
		end)
	end
end)
