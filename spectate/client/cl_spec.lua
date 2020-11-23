

spec = false
local specply = nil
local checktimer = nil
local needtorefirst = false

function checkuntilvalid()
   for i, ply in pairs(GetStreamedPlayers()) do
      if ply == specply then
         spec=true
         DestroyTimer(checktimer)
         checktimer = nil
         if IsFirstPersonCamera() then
            needtorefirst=true
            EnableFirstPersonCamera(false)
         end
      end
   end
end

function ConfigureSpecCollisions()
	-- If we are a prop as well, we don't want collision between props
    for k, v in pairs(GetStreamedPlayers()) do
        local PlayerActor = GetPlayerActor(v)
	    if PlayerActor then
            local Capsule = PlayerActor:GetComponentsByClass(UCapsuleComponent.Class())[1]
            Capsule:SetCollisionResponseToChannel(ECollisionChannel.ECC_Pawn, ECollisionResponse.ECR_Ignore)
            Capsule:SetCollisionResponseToChannel(ECollisionChannel.ECC_Camera, ECollisionResponse.ECR_Ignore)
            if Props[v] then
                Props[v]:SetCollisionResponseToChannel(ECollisionChannel.ECC_Pawn, ECollisionResponse.ECR_Ignore)
                Props[v]:SetCollisionResponseToChannel(ECollisionChannel.ECC_Camera, ECollisionResponse.ECR_Ignore)
            end
        end
	end
end

AddRemoteEvent("SpecRemoteEvent",function(bool,plyid,x,y,z)
    if bool == false then
        spec = false
        specply = nil
        SetCameraLocation(0,0,0,false)
        SetCameraRotation(0,0,0,false)
    else
        MyPropHuntRole = "spec"
        WaitingForPlayers = false
        specply = plyid
        actor = GetPlayerActor(GetPlayerId())
        actor:SetActorLocation(FVector( x,y,z))
        if checktimer then
            DestroyTimer(checktimer)
        end
        checktimer = CreateTimer(checkuntilvalid,10)
        if (Props[GetPlayerId()] and Props[GetPlayerId()]:IsValid()) then
            Props[GetPlayerId()]:Destroy()
            Props[GetPlayerId()] = nil
        end
        ConfigureSpecCollisions()
    end
end)

function stopspec()
    if needtorefirst then
        EnableFirstPersonCamera(true)
    end
    needtorefirst=false
    spec=false
    specply=nil
    SetCameraLocation(0,0,0,false)
    SetCameraRotation(0,0,0,false)
    CallRemoteEvent("NoLongerSpectating")
end

AddEvent("OnGameTick",function(ds)
    if spec then
        if IsValidPlayer(specply) then
            local x, y, z = GetPlayerLocation(specply)
            local x2, y2, z2 = GetPlayerLocation(GetPlayerId())
            local heading = GetPlayerHeading(specply)
            if not GetPlayerPropertyValue(specply, "Spectating") then
               if GetDistance2D(x, y, x2, y2) > 3000 then
                  actor = GetPlayerActor(GetPlayerId())
                  actor:SetActorLocation(FVector( x,y,z))
               end
               if GetPlayerVehicle(specply) == 0 then
                  local fx,fy,fz = GetPlayerForwardVector(specply)
                  local hittype, hitid, impactX, impactY, impactZ = LineTrace(x-fx*40,y-fy*40,z,x-fx*300, y-fy*300, z+150)
                  if (hittype~=2 and impactX==0 and impactY==0 and impactZ==0) then
                      SetCameraLocation(x-fx*300, y-fy*300, z+150 , true)
                      SetCameraRotation(-25,heading,0)
                  else
                      SetCameraLocation(impactX, impactY, impactZ , true)
                      SetCameraRotation(-25,heading,0)
                  end
               else
                   local veh = GetPlayerVehicle(specply)
                   local x, y, z = GetVehicleLocation(veh)
                   local rx, ry, rz = GetVehicleRotation(veh)
                   local fx,fy,fz = GetVehicleForwardVector(veh)
                   SetCameraLocation(x-fx*600, y-fy*600, z+275 , true)
                   SetCameraRotation(-15, ry, rz)
               end
            else
                AddPlayerChat("This player is spectating")
                stopspec()
            end
        else
            AddPlayerChat("Player invalid")
            stopspec()
        end
    end
end)

AddEvent("OnPlayerStreamIn", function(ply)
    if GetPlayerPropertyValue(ply, "Spectating") then
        local Body = GetPlayerSkeletalMeshComponent(player, "Body")
        Body:SetVisibility(false, false)
    end
end)

AddEvent("OnPlayerNetworkUpdatePropertyValue", function(ply, propertyName, propertyValue)
    if (ply ~= GetPlayerId() and propertyName == "Spectating") then
        if not propertyValue then
            --AddPlayerChat("no spec " .. tostring(ply))
            ResetPlayerCapsuleAndBody(ply)
        else
            --AddPlayerChat("spec " .. tostring(ply))
            local Body = GetPlayerSkeletalMeshComponent(ply, "Body")
            Body:SetVisibility(false, false)
            local PlayerActor = GetPlayerActor(ply)
            if PlayerActor then
                local Capsule = PlayerActor:GetComponentsByClass(UCapsuleComponent.Class())[1]
                Capsule:SetCollisionResponseToChannel(ECollisionChannel.ECC_Camera, ECollisionResponse.ECR_Ignore)
                Capsule:SetCollisionResponseToChannel(ECollisionChannel.ECC_Pawn, ECollisionResponse.ECR_Ignore)
            end
            if (Props[ply] and Props[ply]:IsValid()) then
                Props[ply]:Destroy()
                Props[ply] = nil
            end
        end
    end
end)

AddEvent("OnKeyPress",function(key)
    if (spec and key == "E") then
        CallRemoteEvent("ChangeSpec", specply)
    end
end)

AddEvent("OnRenderHUD", function()
    if spec then
        DrawText(5, 400, "Press E to change the spectated player")
    end
end)
