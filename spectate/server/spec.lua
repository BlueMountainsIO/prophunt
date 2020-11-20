
function speclogic(cmdply,ply)
     SetPlayerPropertyValue(cmdply, "Spectating", true, true)
     AddPlayerChat(cmdply, "You are spectating " .. GetPlayerName(ply))
     local x, y, z = GetPlayerLocation(ply)
     CallRemoteEvent(cmdply, "SpecRemoteEvent", true, ply, x, y, z)
end

function table.len(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

function ChangePlayerSpec(ply, specply)
    local tbl = {}
    for k, v in pairs(GetAllPlayers()) do
        if (ply ~= v and specply ~= v and Players[v] and (Players[v].role == "hunter" or Players[v].role == "prop")) then
            table.insert(tbl, v)
        end
    end
    local len = table.len(tbl)
    if len > 0 then
       speclogic(ply, tbl[math.random(len)])
    end
end

AddRemoteEvent("NoLongerSpectating",function(ply)
    SetPlayerPropertyValue(ply, "Spectating", nil, true)
    ChangePlayerSpec(ply, ply)
end)

AddRemoteEvent("ChangeSpec", function(ply, specply)
    ChangePlayerSpec(ply, specply)
end)
