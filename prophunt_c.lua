--[[

Prophunt client

]]--

local Props = { }
local GameTime = ""
local LastTracedComp
local TraceTimeMS = 80
local TraceRange = 1000.0
local TraceTimer = 0
local DisableFootstepSoundsForProps = false
local PropSoundRange = 1800.0
local PropSounds = {
	"sounds/bruh.m4a",
	"sounds/dolphin.m4a"
}

local KeySwitchProps = "Left Mouse Button"
local KeyTaunt = "X"
local KeyRotate = "Left Ctrl"
local KeyBecomeProp = "K"

AddEvent("OnPackageStart", function()

	print("Prophunt loading")

	LoadOutlineMat()

	TraceTimer = CreateTimer(function()
	
		if Props[GetPlayerId()] == nil then return end
	
		local camX, camY, camZ = GetCameraLocation()
		local camForwardX, camForwardY, camForwardZ = GetCameraForwardVector()

		local Start = FVector(camX, camY, camZ)
		local End = Start + (FVector(camForwardX, camForwardY, camForwardZ) * FVector(TraceRange, TraceRange, TraceRange))
		local bResult, HitResult = UKismetSystemLibrary.LineTraceSingle(GetPlayerActor(), Start, End, ETraceTypeQuery.TraceTypeQuery1, true, {}, EDrawDebugTrace.None, true, FLinearColor(1.0, 0.0, 0.0, 1.0), FLinearColor(0.0, 1.0, 0.0, 1.0), 10.0)
		
		if bResult == true then
			local Actor = HitResult:GetActor()
			local Comp = HitResult:GetComponent()
			if Actor:ActorHasTag("Prophunt") and Comp then
				if Comp:IsA(UStaticMeshComponent.Class()) then
					Comp:SetRenderCustomDepth(true)
					if LastTracedComp and LastTracedComp:GetUniqueID() ~= Comp:GetUniqueID() then -- TODO: Add __eq
						LastTracedComp:SetRenderCustomDepth(false)
					end
					LastTracedComp = Comp
				end
			else
				if LastTracedComp then
					LastTracedComp:SetRenderCustomDepth(false)
					LastTracedComp = nil
				end
			end
		else
			if LastTracedComp then
				LastTracedComp:SetRenderCustomDepth(false)
				LastTracedComp = nil
			end
		end
	end, TraceTimeMS)

end)

AddEvent("OnPackageStop", function()

	DestroyTimer(TraceTimer)

	if LastTracedComp and LastTracedComp:IsValid() then
		LastTracedComp:SetRenderCustomDepth(false)
	end
	
	for k, v in pairs(Props) do
		v:Destroy()
	end
	Props = { }
	
end)

function LoadOutlineMat()
	-- Make sure to enable it once so that the outline PP mat gets loaded to make SetRenderCustomDepth work
	SetPlayerOutline(GetPlayerId(), true)
	SetPlayerOutline(GetPlayerId(), false)
end

function math.clamp(val, lower, upper)
    if lower > upper then lower, upper = upper, lower end
    return math.max(lower, math.min(upper, val))
end

function table.len(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

function SetPropInternal(player, mesh)
	if Props[player] and Props[player]:IsValid() then
		Props[player]:Destroy()
		Props[player] = nil
	end

	local PlayerActor = GetPlayerActor(player)
	local SMC = PlayerActor:AddComponent(UStaticMeshComponent.Class())
	SMC:SetMobility(EComponentMobility.Movable)
	SMC:SetStaticMesh(mesh)
	local Bounds = mesh:GetBounds()
	
	local Capsule = PlayerActor:GetComponentsByClass(UCapsuleComponent.Class())[1]
	
	-- Adjust player collision to roughly fit the mesh bounds
	Capsule:SetCapsuleSize((Bounds.BoxExtent.X + Bounds.BoxExtent.Y) / 3.0, Bounds.BoxExtent.Z, true)
	
	local Body = GetPlayerSkeletalMeshComponent(player, "Body")
	
	-- Attach the prop to the body SK mesh to get smoothed movement for remote players in multiplayer.
	local Rules = FAttachmentTransformRules(EAttachmentRule.SnapToTarget, true)
	SMC:AttachToComponent(Body, Rules, "")
	
	local HalfHeight = Capsule:GetUnscaledCapsuleHalfHeight()
	local MeshAdjust = Body:GetRelativeLocation().Z * -1.0
	
	-- Adjust prop location to the floor.
	SMC:SetRelativeLocation(FVector(0.0, 0.0, (((HalfHeight - HalfHeight) - HalfHeight) - 2.0) + MeshAdjust))
	
	Props[player] = SMC
	
	Body:SetVisibility(false, false)
	
	if player == GetPlayerId() then
		local ViewDist = Bounds.BoxExtent.Z * math.clamp(math.sqrt(Bounds.BoxExtent.Z), 0.0, 2.0) * 3.0
		TraceRange = 1000.0 + ViewDist
		SetCameraViewDistance(ViewDist)
		SetPlayerRotationRate(720.0)
		SetPlayerJumpZVelocity(600.0)
		ShowWeaponHUD(false)
		ShowHealthHUD(false)
		CreateSound("sounds/ui_interact1.mp3")
	else
		TogglePlayerTag(player, "name", false)
		TogglePlayerTag(player, "health", false)
		TogglePlayerTag(player, "armor", false)
		TogglePlayerTag(player, "voice", false)
	end
	
	ConfigurePlayerCollisions()
end

function SetPlayerPropByAsset(player, asset_path)
	local mesh = UStaticMesh.LoadFromAsset(asset_path)
	SetPropInternal(player, mesh)
end

function SetPlayerPropByMesh(player, mesh)
	SetPropInternal(player, mesh)
end

function ConfigurePlayerCollisions()
	-- If we are a prop as well, we don't want collision between props
	for k, v in pairs(GetStreamedPlayers()) do
		local PlayerActor = GetPlayerActor(v)
		if PlayerActor then
			local Capsule = PlayerActor:GetComponentsByClass(UCapsuleComponent.Class())[1]
			if Props[v] ~= nil and Props[GetPlayerId()] ~= nil then
				Capsule:SetCollisionResponseToChannel(ECollisionChannel.ECC_Pawn, ECollisionResponse.ECR_Ignore)
				Capsule:SetCollisionResponseToChannel(ECollisionChannel.ECC_Camera, ECollisionResponse.ECR_Ignore)
				Props[v]:SetCollisionResponseToChannel(ECollisionChannel.ECC_Pawn, ECollisionResponse.ECR_Ignore)
				Props[v]:SetCollisionResponseToChannel(ECollisionChannel.ECC_Camera, ECollisionResponse.ECR_Ignore)
				--AddPlayerChat("Ignoring colis "..v)
			else
				Capsule:SetCollisionResponseToChannel(ECollisionChannel.ECC_Pawn, ECollisionResponse.ECR_Block)
				Capsule:SetCollisionResponseToChannel(ECollisionChannel.ECC_Camera, ECollisionResponse.ECR_Block)
				--Props[v]:SetCollisionResponseToChannel(ECollisionChannel.ECC_Pawn, ECollisionResponse.ECR_Block)
				--AddPlayerChat("NOT Ignoring colis "..v)
			end
		end
	end
end

AddEvent("OnPlayerStreamIn", function(player)
	local PropAsset = GetPlayerPropertyValue(player, "PropAsset")

	if PropAsset ~= nil then
		SetPlayerPropByAsset(player, PropAsset)
	end	
end)

AddEvent("OnPlayerStreamOut", function(player)
	if Props[player] and Props[player]:IsValid() then
		Props[player]:Destroy()
		Props[player] = nil
	end	
end)

if DisableFootstepSoundsForProps then
	AddEvent("OnPlayerFootstep", function(player, floor_type)
		if Props[player] ~= nil then
			return false
		end
	end)
end

AddEvent("OnPlayerToggleAim", function(toggle)
	if Props[GetPlayerId()] ~= nil then
		if toggle then
			return false
		end
	end
end)

AddEvent("OnPlayerCrouch", function(toggle)
	if Props[GetPlayerId()] ~= nil then
		return false
	end
end)

AddEvent("OnPlayerNetworkUpdatePropertyValue", function(player, propertyName, propertyValue)
	if propertyName == "PropAsset" then
		SetPlayerPropByAsset(player, propertyValue)
	elseif propertyName == "PropSound" then
		local x, y, z = GetPlayerLocation(player)
		CreateSound3D(PropSounds[propertyValue], x, y, z, PropSoundRange)
	elseif propertyName == "PropRotation" then
		if player ~= GetPlayerId() then
			local Rotation = Props[player]:GetRelativeRotation()
			Props[player]:SetRelativeRotation(FRotator(0.0, propertyValue, 0.0))
		end
	end
end)

AddEvent("OnPlayerSpawn", function()
	LoadOutlineMat()
end)

AddEvent("OnRenderHUD", function()
	local ScreenX, ScreenY = GetScreenSize()
	
	SetDrawColor(RGB(255, 0, 0))
	SetTextDrawScale(1.4, 1.4)
	DrawText(30.0, ScreenY - 90.0, "HEALTH: "..tostring(math.floor(GetPlayerHealth()+0.5)))

	SetDrawColor(RGB(255, 255, 255))
	SetTextDrawScale(1.0, 1.0)
	DrawText(30.0, ScreenY - 60.0, "TIME "..GameTime)
	DrawText(30.0, ScreenY - 40.0, "Props 0 Hunter 0")

	SetTextDrawScale(1.3, 1.3)
	SetDrawColor(RGB(255, 113, 0))
	DrawText(ScreenX - 200.0, ScreenY - 130, "CONTROLS")
	SetDrawColor(RGB(255, 255, 255))
	SetTextDrawScale(1.0, 1.0)
	DrawText(ScreenX - 200.0, ScreenY - 100, "Switch Props: "..KeySwitchProps)
	DrawText(ScreenX - 200.0, ScreenY - 80, "Taunt: "..KeyTaunt)
	DrawText(ScreenX - 200.0, ScreenY - 60, "Rotate: "..KeyRotate)
	DrawText(ScreenX - 200.0, ScreenY - 40, "Become a Prop: "..KeyBecomeProp)

	DrawText(ScreenX / 2.0 - 70.0, ScreenY - 20, "github.com/BlueMountainsIO/prophunt")

	SetTextDrawScale(1.3, 1.3)
	DrawText(ScreenX / 2.0 - 70.0, 20, "Waiting for players")
end)

AddEvent("OnKeyPress", function(k)

	if k == KeyBecomeProp then
		local Asset = "/Game/Geometry/DesertGasStation/Meshes/Props/SM_Bench_01"
		SetPlayerPropByAsset(GetPlayerId(), Asset)
		CallRemoteEvent("Prophunt:SwitchProp", Asset)
	end
	
	if k == KeySwitchProps then	
		if LastTracedComp and LastTracedComp:IsValid() then
			local SMC = Cast(UStaticMeshComponent.Class(), LastTracedComp)
			if SMC then
				local mesh = SMC:GetStaticMesh()
				SetPlayerPropByMesh(GetPlayerId(), mesh)
				CallRemoteEvent("Prophunt:SwitchProp", mesh:GetPathName())
			end
		end
	end
	
	if k == KeyTaunt then
		if Props[GetPlayerId()] ~= nil then
			local r = Random(1, table.len(PropSounds))
			CallRemoteEvent("Prophunt:PlaySound", r)
		end
	end

	if k == KeyRotate then
		if Props[GetPlayerId()] ~= nil then
			--local PlayerActor = GetPlayerActor()
			--local Rotation = PlayerActor:GetActorRotation()
			--PlayerActor:SetActorRotation(Rotation + FRotator(0.0, 90.0, 0.0))
			local Rotation = Props[GetPlayerId()]:GetRelativeRotation()
			Props[GetPlayerId()]:SetRelativeRotation(Rotation + FRotator(0.0, 90.0, 0.0))
			CallRemoteEvent("Prophunt:ChangeRotation", Props[GetPlayerId()]:GetRelativeRotation().Yaw)
		end
	end

end)

AddRemoteEvent("Prophunt:SetGameTime", function(ServerGameTime)
	GameTime = string.format("%02d:%02d", math.floor(tostring(ServerGameTime / 60)), math.floor(tostring(tostring(ServerGameTime % 60))))
end)
