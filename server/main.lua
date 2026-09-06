local RSGCore = nil
local VORP = nil

local placedProps = {}
local placedFolders = {}
local placedBlips = {}

-- Helper: Load JSON file from resource
local function LoadResourceJson(filename)
    local raw = LoadResourceFile(GetCurrentResourceName(), filename)
    if raw and raw ~= "" then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == "table" then
            return data
        end
    end
    return {}
end

-- Helper: Save JSON file atomically to resource folder
local function SaveResourceJson(filename, data)
    local raw = json.encode(data, { indent = true })
    SaveResourceFile(GetCurrentResourceName(), filename, raw, -1)
end

-- Euler angles to Quaternion converter for YMAP export
local function EulerToQuaternion(pitch, roll, yaw)
    local p = math.rad(pitch or 0.0) * 0.5
    local r = math.rad(roll or 0.0) * 0.5
    local y = math.rad(yaw or 0.0) * 0.5

    local sinP = math.sin(p)
    local cosP = math.cos(p)
    local sinR = math.sin(r)
    local cosR = math.cos(r)
    local sinY = math.sin(y)
    local cosY = math.cos(y)

    local qx = sinR * cosP * cosY - cosR * sinP * sinY
    local qy = cosR * sinP * cosY + sinR * cosP * sinY
    local qz = cosR * cosP * sinY - sinR * sinP * cosY
    local qw = cosR * cosP * cosY + sinR * sinP * sinY

    return qx, qy, qz, qw
end

-- Framework initialization
CreateThread(function()
    placedProps = LoadResourceJson(Config.ServerPlacedPropsFile or "placed_props_sync.json")
    placedFolders = LoadResourceJson(Config.ServerPlacedFoldersFile or "placed_prop_folders.json")
    placedBlips = LoadResourceJson(Config.ServerPlacedBlipsFile or "placed_blips_sync.json")

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
    print(("[rsg_prop_gizmo] Loaded %d placed props from database."):format(#placedProps))
end)

-- Permission verification check
local function IsPlayerAllowed(src)
    if Config.AllowGizmoForEveryone then
        return true
    end

    if IsPlayerAceAllowed(src, "command.gizmo") or IsPlayerAceAllowed(src, "group.admin") then
        return true
    end

    local framework = GizmoResolveFramework()
    if framework == "rsg" and RSGCore then
        local Player = RSGCore.Functions.GetPlayer(src)
        if Player then
            local pGroup = Player.PlayerData.group or "user"
            for _, group in ipairs(Config.CommandAccess.AdminGroups or {}) do
                if group == pGroup or RSGCore.Functions.HasPermission(src, group) then
                    return true
                end
            end
        end
    elseif framework == "vorp" and VORP then
        local User = VORP.getUser(src)
        if User then
            local Character = User.getUsedCharacter
            local group = Character and Character.group or "user"
            for _, g in ipairs(Config.CommandAccess.AdminGroups or {}) do
                if g == group then return true end
            end
        end
    end

    return false
end

RegisterServerEvent("rsg_prop_gizmo:server:checkPermissionAndOpen")
AddEventHandler("rsg_prop_gizmo:server:checkPermissionAndOpen", function()
    local src = source
    if IsPlayerAllowed(src) then
        TriggerClientEvent("rsg_prop_gizmo:client:openUI", src)
    else
        TriggerClientEvent("chat:addMessage", src, {
            color = { 255, 0, 0 },
            multiline = true,
            args = { "System", "You do not have permission to access /gizmo." }
        })
    end
end)

RegisterServerEvent("rsg_prop_gizmo:server:requestPlacedProps")
AddEventHandler("rsg_prop_gizmo:server:requestPlacedProps", function()
    local src = source
    TriggerClientEvent("rsg_prop_gizmo:client:syncPlacedProps", src, placedProps, placedFolders)
end)

-- Place Prop Handler with Server-Authoritative Distance Validation
RegisterServerEvent("rsg_prop_gizmo:server:placeProp")
AddEventHandler("rsg_prop_gizmo:server:placeProp", function(data)
    local src = source
    if not IsPlayerAllowed(src) or not data or not data.model then return end

    local pPed = GetPlayerPed(src)
    local pCoords = GetEntityCoords(pPed)
    local targetCoords = vec3(tonumber(data.x) or 0.0, tonumber(data.y) or 0.0, tonumber(data.z) or 0.0)

    -- Anti-cheat max distance validation check
    local maxDistCheck = Config.PlaceMaxDistanceCheck or 30.0
    if maxDistCheck > 0.0 then
        local dist = #(pCoords - targetCoords)
        if dist > maxDistCheck then
            print(("[rsg_prop_gizmo] Warning: Player %d tried to place object out of bounds (dist: %.2fm)"):format(src, dist))
            return
        end
    end

    local newId = ("prop_%d_%d"):format(os.time(), math.random(1000, 9999))
    local entry = {
        id = newId,
        model = data.model,
        x = targetCoords.x,
        y = targetCoords.y,
        z = targetCoords.z,
        pitch = tonumber(data.pitch) or 0.0,
        roll = tonumber(data.roll) or 0.0,
        yaw = tonumber(data.yaw) or 0.0,
        kind = data.kind or "prop",
        placedBy = GetPlayerName(src),
        placedAt = os.time()
    }

    table.insert(placedProps, entry)
    SaveResourceJson(Config.ServerPlacedPropsFile or "placed_props_sync.json", placedProps)

    -- Broadcast update to all clients
    TriggerClientEvent("rsg_prop_gizmo:client:syncPlacedProps", -1, placedProps, placedFolders)
end)

-- Delete Placed Prop Handler
RegisterServerEvent("rsg_prop_gizmo:server:deletePlacedProp")
AddEventHandler("rsg_prop_gizmo:server:deletePlacedProp", function(propId)
    local src = source
    if not IsPlayerAllowed(src) then return end

    local foundIndex = nil
    for i = 1, #placedProps do
        if placedProps[i].id == propId then
            foundIndex = i
            break
        end
    end

    if foundIndex then
        table.remove(placedProps, foundIndex)
        SaveResourceJson(Config.ServerPlacedPropsFile or "placed_props_sync.json", String or placedProps)
        TriggerClientEvent("rsg_prop_gizmo:client:syncPlacedProps", -1, placedProps, placedFolders)
    end
end)

-- YMAP Exporter Event Handler
RegisterServerEvent("rsg_prop_gizmo:server:exportYmap")
AddEventHandler("rsg_prop_gizmo:server:exportYmap", function()
    local src = source
    if not IsPlayerAllowed(src) then return end

    local xmlHeader = '<?xml version="1.0" encoding="UTF-8"?>\n<CMapData>\n  <flags value="0"/>\n  <type>CMAPDATA_TYPE_STORIES</type>\n  <entities>\n'
    local xmlFooter = '  </entities>\n</CMapData>\n'

    local xmlBody = ""
    for i = 1, #placedProps do
        local prop = placedProps[i]
        if prop.kind == "prop" or prop.kind == nil then
            local qx, qy, qz, qw = EulerToQuaternion(prop.pitch, prop.roll, prop.yaw)
            xmlBody = xmlBody .. string.format([[
    <Item type="CEntityDef">
      <archetypeName>%s</archetypeName>
      <flags value="1572865"/>
      <position x="%.8f" y="%.8f" z="%.8f"/>
      <rotation x="%.8f" y="%.8f" z="%.8f" w="%.8f"/>
      <scaleXY value="1.0"/>
      <scaleZ value="1.0"/>
    </Item>
]], prop.model, prop.x, prop.y, prop.z, qx, qy, qz, qw)
        end
    end

    local fullYmap = xmlHeader .. xmlBody .. xmlFooter
    SaveResourceFile(GetCurrentResourceName(), "export_world_props.ymap.xml", fullYmap, -1)
    print("[rsg_prop_gizmo] Generated export_world_props.ymap.xml successfully.")
end)
