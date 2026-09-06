local RSGCore = nil
local VORP = nil

-- State variables
local isNuiOpen = false
local isPlacing = false
local placementGhost = nil
local placementModel = nil
local placementCoords = vec3(0.0, 0.0, 0.0)
local placementRot = vec3(0.0, 0.0, 0.0)
local placementSpeedPct = 100
local isFreeMove = false

-- Movement directional flags
local moveState = {
    forward = false, back = false, left = false, right = false,
    heightUp = false, heightDown = false,
    rotLeft = false, rotRight = false,
    pitchUp = false, pitchDown = false,
    rollLeft = false, rollRight = false
}

-- Streaming Engine cache
local placedPropsCache = {}
local spawnedPropsMap = {} -- id -> entity handle
local spawnQueue = {}

-- Load JSON catalogs from client resource files
local function LoadJsonFile(filepath)
    local content = LoadResourceFile(GetCurrentResourceName(), filepath)
    if content then
        local success, result = pcall(json.decode, content)
        if success then
            return result
        end
    end
    return {}
end

local catalogSpooni = nil
local catalogBank = nil
local catalogPeds = nil
local catalogBlips = nil

CreateThread(function()
    catalogSpooni = LoadJsonFile("data/spooni_catalog.json")
    catalogBank = LoadJsonFile("data/bank_props.json")
    catalogPeds = LoadJsonFile("data/peds_catalog.json")
    catalogBlips = LoadJsonFile("data/blips_catalog.json")

    local framework = GizmoResolveFramework()
    if framework == "rsg" then
        local rsgRes = GizmoRsgResourceName()
        pcall(function()
            RSGCore = exports[rsgRes]:GetCoreObject()
        end)
    elseif framework == "vorp" then
        pcall(function()
            TriggerEvent("getCore", function(core) VORP = core end)
        end)
    end
end)

-- Model loader with timeout protection
local function LoadModelAsync(modelHash)
    if not IsModelInCdimage(modelHash) or not IsModelValid(modelHash) then
        return false
    end
    RequestModel(modelHash)
    local timeout = 5000
    local startTime = GetGameTimer()
    while not HasModelLoaded(modelHash) do
        Wait(10)
        if (GetGameTimer() - startTime) > timeout then
            return false
        end
    end
    return true
end

-- Open Gizmo NUI UI
local function OpenGizmoNUI()
    if isNuiOpen then return end
    isNuiOpen = true
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = "open",
        tree = catalogSpooni or {},
        allProps = catalogBank or {},
        peds = catalogPeds or {},
        blips = catalogBlips or {},
        lang = Config.Language or "en",
        resourceName = GetCurrentResourceName(),
        redLookupBaseUrl = Config.RedLookupBaseUrl,
        redLookupPedImageUrl = Config.RedLookupPedImageUrl,
        redLookupBlipImageUrl = Config.RedLookupBlipImageUrl,
        thumbBase = Config.PropThumbnailBaseUrl,
        placedPageSize = Config.PlacedListPageSize,
        catalogPageSize = Config.CatalogPageSize,
        wrapSpooniRoot = Config.NuiWrapSpooniPropsRoot,
        spooniRootExpanded = Config.NuiExpandSpooniRootOnOpen
    })

    -- Request latest placed props list from server
    TriggerServerEvent("rsg_prop_gizmo:server:requestPlacedProps")
end

-- Close Gizmo NUI UI
local function CloseGizmoNUI()
    if not isNuiOpen then return end
    isNuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
end

RegisterCommand("gizmo", function()
    TriggerServerEvent("rsg_prop_gizmo:server:checkPermissionAndOpen")
end, false)

RegisterNetEvent("rsg_prop_gizmo:client:openUI", function()
    OpenGizmoNUI()
end)

-- Server Sync Events
RegisterNetEvent("rsg_prop_gizmo:client:syncPlacedProps", function(propsList, foldersList)
    placedPropsCache = propsList or {}
    SendNUIMessage({
        action = "placedList",
        list = placedPropsCache,
        folders = foldersList or {}
    })
end)

-- Start In-World Ghost Gizmo Placement Mode
local function StartPlacementMode(modelName)
    if isPlacing then return end
    local modelHash = GetHashKey(modelName)

    if not LoadModelAsync(modelHash) then
        print("[rsg_prop_gizmo] Failed to load model: " .. tostring(modelName))
        return
    end

    local playerPed = PlayerPedId()
    local pCoords = GetEntityCoords(playerPed)
    local pForward = GetEntityForwardVector(playerPed)

    local spawnDist = Config.SpawnDistance or 2.0
    local spawnHeight = Config.SpawnHeightOffset or 0.2
    
    placementCoords = vec3(
        pCoords.x + (pForward.x * spawnDist),
        pCoords.y + (pForward.y * spawnDist),
        pCoords.z + spawnHeight
    )
    placementRot = vec3(0.0, 0.0, GetEntityHeading(playerPed))
    placementModel = modelName

    -- Create ghost prop entity
    placementGhost = CreateObjectNoOffset(modelHash, placementCoords.x, placementCoords.y, placementCoords.z, false, false, false)
    SetEntityCollision(placementGhost, false, false)
    SetEntityAlpha(placementGhost, 180, false)
    FreezeEntityPosition(placementGhost, true)
    SetEntityRotation(placementGhost, placementRot.x, placementRot.y, placementRot.z, 2, true)

    isPlacing = true
    SetNuiFocus(true, false) -- Keep mouse input for UI dock while allowing camera control

    SendNUIMessage({
        action = "showPlacement",
        model = modelName,
        speedMin = Config.PlaceSpeedSliderMin,
        speedMax = Config.PlaceSpeedSliderMax,
        speedStep = Config.PlaceSpeedSliderStep,
        speedPercent = placementSpeedPct
    })

    -- Real-time placement tick loop
    CreateThread(function()
        while isPlacing and DoesEntityExist(placementGhost) do
            Wait(0)
            local speedMult = (placementSpeedPct / 100.0)
            local moveStep = (Config.PlaceStepForward or 0.05) * speedMult
            local rotStep = (Config.PlaceStepRotate or 3.0) * speedMult
            local pitchStep = (Config.PlaceStepPitch or 5.0) * speedMult
            local rollStep = (Config.PlaceStepRoll or 5.0) * speedMult

            local playerPos = GetEntityCoords(PlayerPedId())
            local camRot = GetGameplayCamRot(2)
            local yawRad = math.rad(camRot.z)
            
            -- Directional vectors based on camera orientation
            local forwardVec = vec3(-math.sin(yawRad), math.cos(yawRad), 0.0)
            local rightVec = vec3(math.cos(yawRad), math.sin(yawRad), 0.0)

            local dx, dy, dz = 0.0, 0.0, 0.0

            if moveState.forward then
                dx = dx + forwardVec.x * moveStep
                dy = dy + forwardVec.y * moveStep
            end
            if moveState.back then
                dx = dx - forwardVec.x * moveStep
                dy = dy - forwardVec.y * moveStep
            end
            if moveState.left then
                dx = dx - rightVec.x * moveStep
                dy = dy - rightVec.y * moveStep
            end
            if moveState.right then
                dx = dx + rightVec.x * moveStep
                dy = dy + rightVec.y * moveStep
            end
            if moveState.heightUp then
                dz = dz + moveStep
            end
            if moveState.heightDown then
                dz = dz - moveStep
            end

            -- Rotations
            if moveState.rotLeft then
                placementRot = vec3(placementRot.x, placementRot.y, (placementRot.z + rotStep) % 360.0)
            end
            if moveState.rotRight then
                placementRot = vec3(placementRot.x, placementRot.y, (placementRot.z - rotStep) % 360.0)
            end
            if moveState.pitchUp then
                placementRot = vec3((placementRot.x + pitchStep) % 360.0, placementRot.y, placementRot.z)
            end
            if moveState.pitchDown then
                placementRot = vec3((placementRot.x - pitchStep) % 360.0, placementRot.y, placementRot.z)
            end
            if moveState.rollLeft then
                placementRot = vec3(placementRot.x, (placementRot.y - rollStep) % 360.0, placementRot.z)
            end
            if moveState.rollRight then
                placementRot = vec3(placementRot.x, (placementRot.y + rollStep) % 360.0, placementRot.z)
            end

            -- Update coordinates with max distance restriction check
            local newCoords = vec3(placementCoords.x + dx, placementCoords.y + dy, placementCoords.z + dz)
            local maxDist = Config.PlaceMovementMaxRadius or 8.0
            if maxDist > 0.0 then
                local dist = #(newCoords - playerPos)
                if dist <= maxDist then
                    placementCoords = newCoords
                end
            else
                placementCoords = newCoords
            end

            SetEntityCoords(placementGhost, placementCoords.x, placementCoords.y, placementCoords.z, false, false, false, false)
            SetEntityRotation(placementGhost, placementRot.x, placementRot.y, placementRot.z, 2, true)
        end
    end)
end

-- Stop placement mode & cleanup ghost entity
local function StopPlacementMode()
    isPlacing = false
    if placementGhost and DoesEntityExist(placementGhost) then
        DeleteEntity(placementGhost)
        placementGhost = nil
    end
    if placementModel then
        SetModelAsNoLongerNeeded(GetHashKey(placementModel))
        placementModel = nil
    end
    SendNUIMessage({ action = "hidePlacement" })
    if isNuiOpen then
        SetNuiFocus(true, true)
    else
        SetNuiFocus(false, false)
    end
end

-- NUI Callbacks
RegisterNUICallback("close", function(data, cb)
    CloseGizmoNUI()
    cb("ok")
end)

RegisterNUICallback("searchArchetype", function(data, cb)
    local query = data and data.query
    if query and type(query) == "string" and #query >= 2 then
        local results = exports[GetCurrentResourceName()]:SearchArchetypes(query, catalogBank)
        cb(results or {})
    else
        cb({})
    end
end)


RegisterNUICallback("beginPlace", function(data, cb)
    if data and data.model then
        StartPlacementMode(data.model)
    end
    cb("ok")
end)

RegisterNUICallback("placementMove", function(data, cb)
    if data and data.direction then
        moveState[data.direction] = data.pressed or false
    end
    cb("ok")
end)

RegisterNUICallback("placementSetSpeed", function(data, cb)
    if data and data.percent then
        placementSpeedPct = tonumber(data.percent) or 100
    end
    cb("ok")
end)

RegisterNUICallback("placementSetFreeMove", function(data, cb)
    if data then
        isFreeMove = data.enabled or false
        if isFreeMove then
            SetNuiFocus(false, false)
        else
            SetNuiFocus(true, false)
        end
    end
    cb("ok")
end)

RegisterNUICallback("placeConfirm", function(data, cb)
    if isPlacing and placementGhost and DoesEntityExist(placementGhost) then
        local coords = GetEntityCoords(placementGhost)
        local rot = GetEntityRotation(placementGhost, 2)
        local model = placementModel

        TriggerServerEvent("rsg_prop_gizmo:server:placeProp", {
            model = model,
            x = coords.x,
            y = coords.y,
            z = coords.z,
            pitch = rot.x,
            roll = rot.y,
            yaw = rot.z,
            kind = "prop"
        })
    end
    StopPlacementMode()
    cb("ok")
end)

RegisterNUICallback("placementCancel", function(data, cb)
    StopPlacementMode()
    cb("ok")
end)

RegisterNUICallback("placementReset", function(data, cb)
    if isPlacing and placementGhost then
        local pPed = PlayerPedId()
        local pCoords = GetEntityCoords(pPed)
        local pForward = GetEntityForwardVector(pPed)
        placementCoords = vec3(pCoords.x + pForward.x * 2.0, pCoords.y + pForward.y * 2.0, pCoords.z + 0.2)
        placementRot = vec3(0.0, 0.0, GetEntityHeading(pPed))
    end
    cb("ok")
end)

RegisterNUICallback("spawnPedAtPlayer", function(data, cb)
    if data and data.model then
        local pPed = PlayerPedId()
        local pCoords = GetEntityCoords(pPed)
        local pForward = GetEntityForwardVector(pPed)
        TriggerServerEvent("rsg_prop_gizmo:server:placeProp", {
            model = data.model,
            x = pCoords.x + (pForward.x * 2.5),
            y = pCoords.y + (pForward.y * 2.5),
            z = pCoords.z,
            pitch = 0.0,
            roll = 0.0,
            yaw = GetEntityHeading(pPed),
            kind = "ped"
        })
    end
    cb("ok")
end)

RegisterNUICallback("beginPlaceBlip", function(data, cb)
    if data and data.name then
        local pPed = PlayerPedId()
        local pCoords = GetEntityCoords(pPed)
        TriggerServerEvent("rsg_prop_gizmo:server:placeProp", {
            model = data.name,
            x = pCoords.x,
            y = pCoords.y,
            z = pCoords.z,
            pitch = 0.0,
            roll = 0.0,
            yaw = 0.0,
            kind = "blip"
        })
    end
    cb("ok")
end)

RegisterNUICallback("placedTeleport", function(data, cb)
    if data and data.id then
        for i = 1, #placedPropsCache do
            local item = placedPropsCache[i]
            if item.id == data.id then
                SetEntityCoords(PlayerPedId(), item.x, item.y, item.z + 0.5, false, false, false, false)
                break
            end
        end
    end
    cb("ok")
end)

RegisterNUICallback("placedDelete", function(data, cb)
    if data and data.id then
        TriggerServerEvent("rsg_prop_gizmo:server:deletePlacedProp", data.id)
    end
    cb("ok")
end)

RegisterNUICallback("exportYmap", function(data, cb)
    TriggerServerEvent("rsg_prop_gizmo:server:exportYmap")
    cb("ok")
end)

-- Distance Streaming Engine Tick Thread
CreateThread(function()
    while true do
        Wait(Config.PlacedStreamRefreshMs or 1200)
        local playerPos = GetEntityCoords(PlayerPedId())
        local loadDist = Config.PlacedPropLoadDistance or 180.0
        local unloadDist = Config.PlacedPropUnloadDistance or 220.0
        local budget = Config.PlacedStreamSpawnBudgetPerTick or 12
        local spawnedThisTick = 0

        for i = 1, #placedPropsCache do
            local propData = placedPropsCache[i]
            if propData.kind == "prop" or propData.kind == nil then
                local propPos = vec3(propData.x, propData.y, propData.z)
                local dist = #(playerPos - propPos)
                local id = propData.id

                if dist <= loadDist then
                    if not spawnedPropsMap[id] and spawnedThisTick < budget then
                        local hash = GetHashKey(propData.model)
                        if LoadModelAsync(hash) then
                            local ent = CreateObjectNoOffset(hash, propData.x, propData.y, propData.z, false, false, false)
                            SetEntityRotation(ent, propData.pitch or 0.0, propData.roll or 0.0, propData.yaw or 0.0, 2, true)
                            FreezeEntityPosition(ent, true)
                            SetModelAsNoLongerNeeded(hash)
                            spawnedPropsMap[id] = ent
                            spawnedThisTick = spawnedThisTick + 1
                        end
                    end
                elseif dist > unloadDist then
                    if spawnedPropsMap[id] then
                        if DoesEntityExist(spawnedPropsMap[id]) then
                            DeleteEntity(spawnedPropsMap[id])
                        end
                        spawnedPropsMap[id] = nil
                    end
                end
            end
        end
    end
end)
