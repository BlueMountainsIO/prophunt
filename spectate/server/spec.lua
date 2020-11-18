
function speclogic(cmdply,ply)
     SetPlayerPropertyValue(cmdply, "Spectating", true, true)
     AddPlayerChat(cmdply, "You are spectating " .. GetPlayerName(ply))
     local x, y, z = GetPlayerLocation(ply)
     CallRemoteEvent(cmdply, "SpecRemoteEvent", true, ply, x, y, z)
end

function ChangePlayerSpec(ply, specply)
    for k, v in pairs(GetAllPlayers()) do
        if (ply ~= v and specply ~= v and Players[v] and (Players[v].role == "hunter" or Players[v].role == "prop")) then
            speclogic(ply, v)
        end
    end
end

AddRemoteEvent("NoLongerSpectating",function(ply)
    SetPlayerPropertyValue(ply, "Spectating", nil, true)
    ChangePlayerSpec(ply, ply)
end)

AddRemoteEvent("ChangeSpec", function(ply, specply)
    ChangePlayerSpec(ply, specply)
end)
