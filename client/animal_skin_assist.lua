--- Доп. управление в облике животного после скина: контекст ввода (идея из redm-fixanimals),
--- ближняя «атака» с анимацией по ЛКМ на NPC, опциональные анимации по клавишам из Config.

PropGizmo_AssistAnimalActive = false
PropGizmo_AssistAnimalKind = nil

local lastMeleeMs = 0
local meleeCooldownMs = 2000
local requestClipSetLoaded

--- Птица: одиночный пробел — быстрый взлёт; двойной — посадка / включение полёта.
local birdFlightActive = false
local birdLandingActive = false
local birdJumpFirstTapMs = 0
local lastGameplayCamStabilizeMs = 0

--- Режим «как NPC»: TaskCombatPed по ближайшей цели, звуки, лежание, буст спринта.
local animalAggroActive = false
local lastAnimalCombatTaskMs = 0
--- Встроенное меню /animskins (без vorp_menu); сессия гасит «залипание» при повторном /animskins.
local animSkinBuiltinMenuOpen = false
local animMenuSession = 0
local lastAnimalLieMs = 0
--- Текущая цель NPC-агрессии (для SetRelationshipBetweenGroups один раз на цель).
local animalAggroCombatTarget = nil

local function cfgNum(key, default)
    if type(Config) ~= "table" then return default end
    local n = tonumber(Config[key])
    return n or default
end

local function cfgBool(key, default)
    if type(Config) ~= "table" then return default end
    local v = Config[key]
    if v == nil then return default end
    return v == true
end

local function cfgTable(key)
    if type(Config) ~= "table" then return nil end
    local t = Config[key]
    return (type(t) == "table") and t or nil
end

local function isHumanLikePed(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return false end
    local ok, res = pcall(function()
        return IsPedHuman(ped)
    end)
    return ok and res == true
end

local function applyBirdGroundState(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    --- Как redm-fixanimals: у не-человека флаг 43 = true + контекст OnMount — иначе птица часто «замёрзшая».
    pcall(function()
        SetPedConfigFlag(ped, 43, true)
    end)
    pcall(function()
        SetPedConfigFlag(ped, 146, false)
    end)
    pcall(function()
        if SetPedCanFly then
            SetPedCanFly(ped, false)
        end
    end)
    pcall(function()
        if ResetPedMovementClipset then
            ResetPedMovementClipset(ped, 0.25)
        end
    end)
    if cfgBool("SkinBirdGroundApplyMovementClipset", false) then
        local clips = cfgTable("SkinBirdGroundClipsets")
        if type(clips) == "table" and #clips > 0 then
            for i = 1, #clips do
                local clip = clips[i]
                if type(clip) == "string" and requestClipSetLoaded(clip) then
                    pcall(function()
                        if SetPedMovementClipset then
                            SetPedMovementClipset(ped, clip, 1.0)
                        end
                    end)
                end
            end
        end
    end
end

local function applyBirdFlightState(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    pcall(function()
        SetPedConfigFlag(ped, 43, true)
    end)
    pcall(function()
        SetPedConfigFlag(ped, 146, true)
    end)
    pcall(function()
        if SetPedCanFly then
            SetPedCanFly(ped, true)
        end
    end)
    local clips = cfgTable("SkinBirdFlightClipsets")
    if type(clips) ~= "table" or #clips == 0 then
        clips = { "bird_fly" }
    end
    for i = 1, #clips do
        local clip = clips[i]
        if type(clip) == "string" and requestClipSetLoaded(clip) then
            pcall(function()
                if SetPedMovementClipset then
                    SetPedMovementClipset(ped, clip, 1.0)
                end
            end)
        end
    end
end

local function birdHeightAboveGround(ped)
    local c = GetEntityCoords(ped)
    local ok, found, gz = pcall(function()
        return GetGroundZFor_3dCoord(c.x, c.y, c.z + 1.0, false)
    end)
    if not ok or not found then return nil end
    return c.z - gz
end

local function applyBirdYaw(ped)
    if PropGizmo_AssistAnimalKind ~= "bird" then return end
    local left = IsControlPressed(0, `INPUT_MOVE_LEFT_ONLY`) or IsDisabledControlPressed(0, `INPUT_MOVE_LEFT_ONLY`)
    local right = IsControlPressed(0, `INPUT_MOVE_RIGHT_ONLY`) or IsDisabledControlPressed(0, `INPUT_MOVE_RIGHT_ONLY`)
    if not left and not right then return end
    local degPerSec = cfgNum("SkinBirdFlightTurnDegPerSec", 120.0)
    local dt = GetFrameTime()
    if not dt or dt <= 0 then
        dt = 0.016
    end
    local h = GetEntityHeading(ped)
    if left then
        h = h - degPerSec * dt
    end
    if right then
        h = h + degPerSec * dt
    end
    SetEntityHeading(ped, h)
end

local function applyBirdFlightImpulse(ped)
    if not birdFlightActive or PropGizmo_AssistAnimalKind ~= "bird" then return end
    applyBirdYaw(ped)
    local up = IsControlPressed(0, `INPUT_MOVE_UP_ONLY`) or IsDisabledControlPressed(0, `INPUT_MOVE_UP_ONLY`)
    local down = IsControlPressed(0, `INPUT_MOVE_DOWN_ONLY`) or IsDisabledControlPressed(0, `INPUT_MOVE_DOWN_ONLY`)
    local f = GetEntityForwardVector(ped)
    local upZ = cfgNum("SkinBirdFlightForceUpZ", 1.45)
    local downZ = cfgNum("SkinBirdFlightForceDownZ", 1.15)
    local upFwd = cfgNum("SkinBirdFlightForceFwd", 0.42)
    local downFwd = cfgNum("SkinBirdFlightForceDownFwd", 0.22)

    if up then
        pcall(function()
            ApplyForceToEntity(ped, 1, f.x * upFwd, f.y * upFwd, upZ, 0.0, 0.0, 0.0, 0, true, true, false, true, false)
        end)
    elseif down then
        pcall(function()
            ApplyForceToEntity(ped, 1, f.x * downFwd, f.y * downFwd, -math.abs(downZ), 0.0, 0.0, 0.0, 0, true, true, false, true, false)
        end)
    end
end

local function birdQuickTakeoffBurst(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    local fz = cfgNum("SkinBirdQuickTakeoffForceZ", 2.35)
    local ff = cfgNum("SkinBirdQuickTakeoffForceFwd", 0.65)
    local f = GetEntityForwardVector(ped)
    pcall(function()
        ApplyForceToEntity(ped, 1, f.x * ff, f.y * ff, fz, 0.0, 0.0, 0.0, 0, true, true, false, true, false)
    end)
end

local function processBirdJump(ped)
    if PropGizmo_AssistAnimalKind ~= "bird" then return end
    local jump = IsControlJustPressed(0, `INPUT_JUMP`) or IsDisabledControlJustPressed(0, `INPUT_JUMP`)
    if not jump then return end
    local now = GetGameTimer()
    local win = cfgNum("SkinBirdDoubleTapMs", 400)
    if birdJumpFirstTapMs > 0 and (now - birdJumpFirstTapMs) <= win then
        birdJumpFirstTapMs = 0
        if birdFlightActive then
            birdFlightActive = false
            birdLandingActive = true
            applyBirdFlightState(ped)
        else
            birdFlightActive = true
            birdLandingActive = false
            applyBirdFlightState(ped)
        end
        return
    end
    birdJumpFirstTapMs = now
    if cfgBool("SkinBirdQuickTakeoffOnJump", true) then
        birdQuickTakeoffBurst(ped)
    end
    if not birdFlightActive and not birdLandingActive then
        birdFlightActive = true
        birdLandingActive = false
        applyBirdFlightState(ped)
    end
end

local function processBirdLandingStep(ped)
    if not birdLandingActive or PropGizmo_AssistAnimalKind ~= "bird" then return end
    applyBirdYaw(ped)
    local h = birdHeightAboveGround(ped)
    local stopH = cfgNum("SkinBirdLandingStopHeight", 0.95)
    if h and h <= stopH then
        birdLandingActive = false
        applyBirdGroundState(ped)
        return
    end
    local f = GetEntityForwardVector(ped)
    local lz = math.abs(cfgNum("SkinBirdLandingForceZ", 0.95))
    local lf = cfgNum("SkinBirdLandingForceFwd", 0.12)
    pcall(function()
        ApplyForceToEntity(ped, 1, f.x * lf, f.y * lf, -lz, 0.0, 0.0, 0.0, 0, true, true, false, true, false)
    end)
end

requestClipSetLoaded = function(name)
    if type(name) ~= "string" or name == "" then return false end
    if not RequestClipSet or not HasClipSetLoaded then return false end
    RequestClipSet(name)
    local deadline = GetGameTimer() + 4500
    while GetGameTimer() < deadline do
        local ok, loaded = pcall(function()
            return HasClipSetLoaded(name)
        end)
        if ok and (loaded == 1 or loaded == true) then
            return true
        end
        Wait(10)
    end
    return false
end

--- Настройка птицы после смены модели: наземная локомоция + опциональный полёт по двойному пробелу.
function PropGizmo_SetupBirdAbilities(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    pcall(function()
        SetPedConfigFlag(ped, 301, false)
    end)
    pcall(function()
        SetPedCanRagdoll(ped, false)
    end)
    applyBirdGroundState(ped)
end

local function isHorseLikePed(ped)
    if PropGizmo_AssistAnimalKind == "horse" then return true end
    local ok, r = pcall(function()
        return IsPedHorse(ped)
    end)
    return ok and r == true
end

--- Fallback по «типу» из PropGizmo_ModelKindForSkin (если нет точной записи в Config.SkinAnimalMeleeByHash).
local FALLBACK_MELEE = {
    bear = { dict = "creatures_mammal@bear@melee@streamed_core", name = "attack", radius = 3.0, force = 5.0, damage = 20 },
    feline = { dict = "creatures_mammal@cougar@melee@streamed_core", name = "attack", radius = 2.0, force = 3.0, damage = 18 },
    canid = { dict = "creatures_mammal@wolf@melee@attacks@streamed_core", name = "attack", radius = 3.0, force = 3.0, damage = 22 },
    reptile = { dict = "creatures_reptile@alligator@melee@streamed_core", name = "attack", radius = 2.5, force = 2.0, damage = 22 },
    small = { dict = "creatures_mammal@raccoon@melee", name = "nip_attack", radius = 2.0, force = 1.0, damage = 12 },
    herbivore = { dict = "creatures_mammal@coyote@melee@streamed_core", name = "attack", radius = 2.5, force = 2.0, damage = 15 },
    deer = { dict = "creatures_mammal@coyote@melee@streamed_core", name = "attack", radius = 2.5, force = 2.0, damage = 15 },
}

local function setControlContext(pad, ctx)
    pcall(function()
        Citizen.InvokeNative(0x2804658EB7D8A50B, pad, ctx)
    end)
end

--- Как в skin_applied: каждый кадр, пока активен звериный ассист (после 30s boost тоже).
local ASSIST_MOVEMENT_CONTROLS = {
    `INPUT_ATTACK`,
    `INPUT_MELEE_ATTACK`,
    `INPUT_MELEE_GRAPPLE`,
    `INPUT_MELEE_MODIFIER`,
    `INPUT_HORSE_ATTACK`,
    `INPUT_JUMP`,
    `INPUT_SPRINT`,
    `INPUT_HORSE_SPRINT`,
    `INPUT_MOVE_UP_ONLY`,
    `INPUT_MOVE_DOWN_ONLY`,
    `INPUT_MOVE_LEFT_ONLY`,
    `INPUT_MOVE_RIGHT_ONLY`,
    `INPUT_DUCK`,
    `INPUT_COVER`,
    `INPUT_AIM`,
    `INPUT_INTERACT_OPTION1`,
    `INPUT_INTERACT_OPTION2`,
}

--- Камера (мышь), смена вида (V), кинематографическое удержание.
local ASSIST_CAMERA_CONTROLS = {
    `INPUT_LOOK_LR`,
    `INPUT_LOOK_UD`,
    `INPUT_LOOK_UP_ONLY`,
    `INPUT_LOOK_DOWN_ONLY`,
    `INPUT_LOOK_LEFT_ONLY`,
    `INPUT_LOOK_RIGHT_ONLY`,
    `INPUT_PC_FREE_LOOK`,
    `INPUT_NEXT_CAMERA`,
    `INPUT_CINEMATIC_CAM_LR`,
    `INPUT_CINEMATIC_CAM_UD`,
}

local function enableAssistMovementControls()
    for i = 1, #ASSIST_MOVEMENT_CONTROLS do
        pcall(function()
            EnableControlAction(0, ASSIST_MOVEMENT_CONTROLS[i], true)
        end)
    end
    --- Pad 0–2: камера / кинематограф частично висят не на pad 0.
    for p = 0, 2 do
        for i = 1, #ASSIST_CAMERA_CONTROLS do
            pcall(function()
                EnableControlAction(p, ASSIST_CAMERA_CONTROLS[i], true)
            end)
        end
    end
end

local function shouldSuppressFirstPersonCamThisFrame()
    if cfgBool("SkinAnimalSuppressFirstPersonCam", false) then
        return true
    end
    if PropGizmo_AssistAnimalKind == "bird" then
        return not cfgBool("SkinBirdAllowVanillaCamera", true)
    end
    return false
end

local function stabilizeGameplayCamIfLookIdle()
    if not cfgBool("SkinAnimalStabilizeGameplayCamWhenLookIdle", true) then return end
    local th = cfgNum("SkinAnimalStabilizeCamLookThreshold", 0.045)
    local function mag(control)
        local a = 0.0
        pcall(function()
            a = math.abs(GetControlNormal(0, control))
        end)
        local b = 0.0
        pcall(function()
            b = math.abs(GetDisabledControlNormal(0, control))
        end)
        return math.max(a, b)
    end
    if mag(`INPUT_LOOK_LR`) > th or mag(`INPUT_LOOK_UD`) > th then
        return
    end
    pcall(function()
        SetGameplayCamRelativeHeading(0.0, 1.0)
    end)
    pcall(function()
        if SetGameplayCamRelativePitch then
            SetGameplayCamRelativePitch(0.0, 1.0)
        end
    end)
end

local function getPedCrouchMovement(ped)
    return Citizen.InvokeNative(0xD5FE956C70FF370B, ped)
end

local function setPedCrouchMovement(ped, state, immediately)
    pcall(function()
        Citizen.InvokeNative(0x7DE9692C6F64CFE8, ped, state, immediately)
    end)
end

--- Успешно загруженные dict (у RedM DoesAnimDictExist часто false до первого Request).
local animDictKnownLoaded = {}

local function playAnimDict(ped, dict, name, durationMs, flag)
    if not ped or ped == 0 or not dict or dict == "" or not name or name == "" then return false end
    RequestAnimDict(dict)
    local deadline = GetGameTimer() + 8000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < deadline do
        Wait(10)
    end
    if not HasAnimDictLoaded(dict) then return false end
    animDictKnownLoaded[dict] = true
    local dur = tonumber(durationMs) or 3500
    local flg = tonumber(flag) or 0
    pcall(function()
        TaskPlayAnim(ped, dict, name, 4.0, 4.0, dur, flg, 1.0, false, false, false, "", false)
    end)
    return true
end

local function entryFromFixAnimalsAttackList(ped)
    if not cfgBool("SkinAnimalUseFixAnimalsAttackTypes", true) then return nil end
    local list = rawget(_G, "FixAnimalsAttackTypesList")
    if type(list) ~= "table" then return nil end
    local h = GetEntityModel(ped)
    for i = 1, #list do
        local e = list[i]
        if type(e) == "table" and type(e.models) == "table" then
            for j = 1, #e.models do
                if e.models[j] == h then
                    local anim = e.animation
                    if type(anim) == "table" and type(anim.dict) == "string" and type(anim.name) == "string" then
                        return {
                            dict = anim.dict,
                            name = anim.name,
                            radius = tonumber(e.radius) or 2.5,
                            force = tonumber(e.force) or 0.0,
                            damage = tonumber(e.damage) or 0,
                        }
                    end
                end
            end
        end
    end
    return nil
end

local function meleeSpecForPed(ped)
    local h = GetEntityModel(ped)
    local byHash = cfgTable("SkinAnimalMeleeByHash")
    if byHash and byHash[h] then
        return byHash[h]
    end
    local fromFix = entryFromFixAnimalsAttackList(ped)
    if fromFix then
        return fromFix
    end
    local k = PropGizmo_AssistAnimalKind
    if type(k) == "string" and FALLBACK_MELEE[k] then
        return FALLBACK_MELEE[k]
    end
    return nil
end

local function resolveFixAnimalsResourceName()
    local names = cfgTable("SkinAnimalFixAnimalsResourceNames")
    if type(names) ~= "table" or #names == 0 then
        names = { "redm-fixanimals-master", "redm-fixanimals" }
    end
    for i = 1, #names do
        local n = names[i]
        if type(n) == "string" and n ~= "" and GetResourceState(n) == "started" then
            return n
        end
    end
    return nil
end

local function getPlayerServerIdFromPed(ped)
    for _, player in ipairs(GetActivePlayers()) do
        if GetPlayerPed(player) == ped then
            return GetPlayerServerId(player)
        end
    end
    return nil
end

local function isPvpLooselyEnabled()
    local ok, rel = pcall(function()
        return GetRelationshipBetweenGroups(`PLAYER`, `PLAYER`)
    end)
    return ok and rel == 5
end

local function validMeleeTarget(playerPed, target)
    if not target or target == 0 or not DoesEntityExist(target) then return false end
    if IsPedDeadOrDying(target, true) then return false end
    if IsPedAPlayer(target) and not isPvpLooselyEnabled() then return false end
    return true
end

local function getClosestPed(playerPed, radius)
    local playerCoords = GetEntityCoords(playerPed)
    local itemset = CreateItemset(true)
    local size = Citizen.InvokeNative(0x59B57C4B06531E1E, playerCoords, radius, itemset, 1, Citizen.ResultAsInteger())
    local closestPed, minDist = nil, radius
    if size and size > 0 then
        for i = 0, size - 1 do
            local ped = GetIndexedItemInItemset(i, itemset)
            if ped and ped ~= 0 and ped ~= playerPed and validMeleeTarget(playerPed, ped) then
                local pedCoords = GetEntityCoords(ped)
                local d = #(playerCoords - pedCoords)
                if d < minDist then
                    closestPed = ped
                    minDist = d
                end
            end
        end
    end
    if IsItemsetValid(itemset) then
        DestroyItemset(itemset)
    end
    return closestPed
end

local function npcAggroAllowedForKind(kind)
    if kind == "bird" or kind == nil then return false end
    if not cfgBool("SkinAnimalNpcCombatPredatorsOnly", true) then
        return true
    end
    return kind == "bear" or kind == "feline" or kind == "canid" or kind == "reptile"
end

local function canUseNpcAnimalExtras()
    if not cfgBool("SkinAnimalExtrasEnabled", true) then return false end
    if not PropGizmo_AssistAnimalActive then return false end
    local ped = PlayerPedId()
    if ped == 0 or isHumanLikePed(ped) then return false end
    return true
end

local function applyAnimalNpcSetup(ped, kind)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    if kind == "bird" then return end
    if cfgBool("SkinAnimalApplyPredatorCombatStats", true) then
        local reptileOk = kind == "reptile" and cfgBool("SkinAnimalApplyReptileCombatStats", true)
        if kind == "bear" or kind == "feline" or kind == "canid" or reptileOk then
            if SetPedCombatAttributes then
                pcall(function()
                    SetPedCombatAttributes(ped, 5, true)
                    SetPedCombatAttributes(ped, 46, true)
                end)
            end
            if SetPedFleeAttributes then
                pcall(function()
                    SetPedFleeAttributes(ped, 0, false)
                end)
            end
            if SetPedCombatRange then
                pcall(function()
                    SetPedCombatRange(ped, 2)
                end)
            end
            if SetPedCombatAbility then
                pcall(function()
                    SetPedCombatAbility(ped, 2)
                end)
            end
        end
    end
    if cfgBool("SkinAnimalApplyDefaultAnimalClipset", false) then
        if requestClipSetLoaded("default_animal_clipset") and SetPedMovementClipset then
            pcall(function()
                SetPedMovementClipset(ped, "default_animal_clipset", 1.0)
            end)
        end
    end
end

local function tryPlayAnimalVocal(ped, token)
    if not cfgBool("SkinAnimalVocalizeEnabled", true) then return end
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    local t = (type(token) == "string" and token) or "GROWL"
    pcall(function()
        if PlayAnimalVocalization then
            PlayAnimalVocalization(ped, t, true)
        end
    end)
end

local function playContextualAnimalVocal(ped)
    if not ped or ped == 0 then return end
    local m = GetEntityModel(ped)
    local kind = PropGizmo_AssistAnimalKind
    if m == `A_C_Wolf` or m == `MP_A_C_Wolf` or m == `A_C_Wolf_Medium` or m == `A_C_Wolf_Small` then
        tryPlayAnimalVocal(ped, "HOWL")
        return
    end
    if m == `A_C_Bear_01` or m == `A_C_BearBlack_01` or m == `MP_A_C_Bear_01` then
        tryPlayAnimalVocal(ped, "ROAR")
        return
    end
    --- Кошки / пума / пантера: в игре чаще уместен ROAR, чем общий GROWL (зависит от сборки).
    if kind == "feline"
        or m == `A_C_Panther_01`
        or m == `MP_A_C_Panther_01`
        or m == `A_C_Cougar_01`
        or m == `MP_A_C_Cougar_01`
        or m == `A_C_LionMangy_01` then
        tryPlayAnimalVocal(ped, "ROAR")
        return
    end
    if kind == "reptile" then
        tryPlayAnimalVocal(ped, "HISS")
        return
    end
    tryPlayAnimalVocal(ped, "GROWL")
end

--- Кандидаты «лечь на месте» (TaskAnimalUnalerted у игрока часто уводит педа вперёд — не используем).
local LIE_ANIM_TRIES = {
    feline = {
        { dict = "creatures_mammal@cougar@normal@", name = "sleep" },
        { dict = "creatures_mammal@cougar@normal@", name = "rest" },
        { dict = "creatures_mammal@cougar@normal@", name = "idle" },
    },
    canid = {
        { dict = "creatures_mammal@wolf@normal@", name = "sleep" },
        { dict = "creatures_mammal@wolf@normal@", name = "idle" },
        { dict = "creatures_mammal@coyote@normal@", name = "sleep" },
    },
    bear = {
        { dict = "creatures_mammal@bear@normal@", name = "sleep" },
        { dict = "creatures_mammal@bear@normal@", name = "idle" },
    },
    reptile = {
        { dict = "creatures_reptile@alligator@normal@", name = "idle" },
    },
    deer = {
        { dict = "creatures_mammal@deer@normal@", name = "idle" },
    },
    herbivore = {
        { dict = "creatures_mammal@boar@normal@", name = "idle" },
    },
    small = {
        { dict = "creatures_mammal@raccoon@normal@", name = "idle" },
    },
    horse = {
        { dict = "creatures_mammal@horse@loco@idle@normal", name = "idle" },
    },
    generic = {
        { dict = "creatures_mammal@cougar@normal@", name = "idle" },
    },
}

local function runAnimalLieMenuAction(kind)
    local ped = PlayerPedId()
    if ped == 0 or not DoesEntityExist(ped) then return end
    local cd = cfgNum("SkinAnimalLieCooldownMs", 12000)
    local now = GetGameTimer()
    if lastAnimalLieMs > 0 and (now - lastAnimalLieMs) < cd then
        skinAnimMenuTip(("«Лечь» можно снова через ~%d с"):format(math.ceil((cd - (now - lastAnimalLieMs)) / 1000)), 2800)
        return
    end
    lastAnimalLieMs = now
    pcall(function()
        ClearPedTasksImmediately(ped, true, true)
    end)
    Wait(0)
    local flg = math.floor(cfgNum("SkinAnimalLieAnimFlag", 524290))
    local tries = LIE_ANIM_TRIES[kind] or LIE_ANIM_TRIES.generic
    for i = 1, #tries do
        local e = tries[i]
        if type(e) == "table" and e.dict and e.name and animDictExists(e.dict) then
            if playAnimDict(ped, e.dict, e.name, 14000, flg) then
                return
            end
        end
    end
    skinAnimMenuTip("Не нашлась анимация «лечь» для этого типа — добавьте dict/name в config (см. LIE_ANIM_TRIES в коде).", 5000)
end

--- Пресеты для /animskins (если dict/clip не подходит модели — пункт можно убрать или поправить).
local SKIN_ANIM_MENU_PRESETS = {
    canid = {
        { label = "Спокойная стойка (волк)", dict = "creatures_mammal@wolf@normal@", name = "idle", durationMs = 8000, flag = 49 },
        { label = "Койот — idle", dict = "creatures_mammal@coyote@normal@", name = "idle", durationMs = 8000, flag = 49 },
    },
    feline = {
        { label = "Пума / кошка — idle", dict = "creatures_mammal@cougar@normal@", name = "idle", durationMs = 8000, flag = 49 },
    },
    bear = {
        { label = "Медведь — idle", dict = "creatures_mammal@bear@normal@", name = "idle", durationMs = 8000, flag = 49 },
    },
    reptile = {
        { label = "Аллигатор — idle", dict = "creatures_reptile@alligator@normal@", name = "idle", durationMs = 8000, flag = 49 },
    },
    deer = {
        { label = "Олень — idle", dict = "creatures_mammal@deer@normal@", name = "idle", durationMs = 8000, flag = 49 },
    },
    herbivore = {
        { label = "Кабан — idle", dict = "creatures_mammal@boar@normal@", name = "idle", durationMs = 8000, flag = 49 },
    },
    small = {
        { label = "Енот — idle", dict = "creatures_mammal@raccoon@normal@", name = "idle", durationMs = 8000, flag = 49 },
    },
    horse = {
        { label = "Лошадь — idle", dict = "creatures_mammal@horse@loco@idle@normal", name = "idle", durationMs = 8000, flag = 49 },
        { label = "Лошадь — idle (цикл)", dict = "creatures_mammal@horse@loco@idle@normal", name = "idle", durationMs = -1, flag = 1 },
    },
    bird = {
        { label = "Птица — idle (если есть у модели)", dict = "creatures_mammal@hawk@normal@", name = "idle", durationMs = 6000, flag = 49 },
    },
    generic = {
        { label = "Универсально — idle волка", dict = "creatures_mammal@wolf@normal@", name = "idle", durationMs = 8000, flag = 49 },
    },
}

local function skinAnimMenuTip(msg, ms)
    local t = tonumber(ms) or 4500
    pcall(function()
        TriggerEvent("vorp:TipRight", msg, t)
    end)
    print(("^3[Prop Gizmo /animskins]^7 %s"):format(msg))
end

local function tryGetMenuData()
    if GetResourceState("vorp_menu") ~= "started" then return nil end
    local ok, md = pcall(function()
        return exports.vorp_menu:GetMenuData()
    end)
    if ok and type(md) == "table" and type(md.Open) == "function" then
        return md
    end
    return nil
end

local function kindRuSubtitle(kind)
    local map = {
        bird = "птица",
        canid = "псы / волк / койот",
        feline = "кошки / пума",
        bear = "медведь",
        reptile = "рептилия",
        deer = "олень",
        herbivore = "копытное / кабан",
        small = "мелкое животное",
        horse = "лошадь",
        generic = "животное",
    }
    return map[kind] or "животное"
end

local function animDictExists(dict)
    if type(dict) ~= "string" or dict == "" then return false end
    if animDictKnownLoaded[dict] then return true end
    local ok, ex = pcall(function()
        return DoesAnimDictExist(dict)
    end)
    if ok and ex == true then
        animDictKnownLoaded[dict] = true
        return true
    end
    RequestAnimDict(dict)
    local d = GetGameTimer() + 900
    while GetGameTimer() < d do
        if HasAnimDictLoaded(dict) then
            animDictKnownLoaded[dict] = true
            return true
        end
        Wait(0)
    end
    return false
end

local function playAnimMenuEntry(entry)
    if type(entry) ~= "table" or not entry.dict or not entry.name then return false end
    local ped = PlayerPedId()
    if ped == 0 or IsPedDeadOrDying(ped, true) then return false end
    return playAnimDict(ped, entry.dict, entry.name, entry.durationMs or 5000, entry.flag or 49)
end

local function appendPresetRows(elements, kind)
    local lists = SKIN_ANIM_MENU_PRESETS[kind]
    if type(lists) ~= "table" then
        lists = SKIN_ANIM_MENU_PRESETS.generic
    end
    if type(lists) ~= "table" then return end
    for i = 1, #lists do
        local e = lists[i]
        if type(e) == "table" and e.dict and e.name and animDictExists(e.dict) then
            elements[#elements + 1] = {
                label = e.label or (e.dict .. " / " .. e.name),
                value = "play_anim",
                dict = e.dict,
                name = e.name,
                durationMs = e.durationMs,
                flag = e.flag,
            }
        end
    end
end

--- Сценарии лошади (имена как в датчиках R* — joaat в рантайме).
local HORSE_ANIMSKINS_SCENARIOS = {
    { label = "Лежание · отдых (WORLD_ANIMAL_HORSE_RESTING)", name = "WORLD_ANIMAL_HORSE_RESTING" },
    { label = "Сон · лежит (WORLD_ANIMAL_HORSE_SLEEPING)", name = "WORLD_ANIMAL_HORSE_SLEEPING" },
    { label = "Валяется / катается (WORLD_ANIMAL_HORSE_ROLLING)", name = "WORLD_ANIMAL_HORSE_ROLLING" },
    { label = "Катание (HORSE_ROLL)", name = "HORSE_ROLL" },
    { label = "Ложится — начало (HORSE_LIE_DOWN)", name = "HORSE_LIE_DOWN" },
    { label = "Ложится — anim (ANIM_HORSE_LIE_DOWN)", name = "ANIM_HORSE_LIE_DOWN" },
    { label = "Встать (HORSE_GET_UP)", name = "HORSE_GET_UP" },
    { label = "Встать — anim (ANIM_HORSE_GET_UP)", name = "ANIM_HORSE_GET_UP" },
}

local function beginHorseScenarioMenuAction(ped, scenarioName)
    if not ped or ped == 0 or type(scenarioName) ~= "string" or scenarioName == "" then return end
    local h = GetHashKey(scenarioName)
    CreateThread(function()
        pcall(function()
            ClearPedTasksImmediately(ped, true, true)
        end)
        Wait(80)
        pcall(function()
            if SetPedCanPlayAmbientAnims then
                SetPedCanPlayAmbientAnims(ped, true)
            end
        end)
        if type(TaskStartScenarioInPlaceHash) == "function" then
            pcall(function()
                TaskStartScenarioInPlaceHash(ped, h, -1, true, 0, 0, false)
            end)
        else
            pcall(function()
                TaskStartScenarioInPlace(ped, h, -1, true, false, false, false)
            end)
        end
    end)
end

local function appendHorseAnimSkinsScenarioRows(elements, kind, ped)
    if kind ~= "horse" and not (ped and ped ~= 0 and isHorseLikePed(ped)) then return end
    elements[#elements + 1] = {
        label = "—— Лошадь: сценарии (лежит / встать / катание) ——",
        value = "_horse_hdr",
    }
    for i = 1, #HORSE_ANIMSKINS_SCENARIOS do
        local r = HORSE_ANIMSKINS_SCENARIOS[i]
        if type(r) == "table" and type(r.name) == "string" and r.label then
            elements[#elements + 1] = {
                label = r.label,
                value = "horse_scenario",
                scenario = r.name,
            }
        end
    end
end

local function appendConfigQuickAnimRows(elements, kind)
    if not cfgBool("SkinAnimalQuickAnimsEnabled", true) then return end
    local lists = cfgTable("SkinAnimalQuickAnims")
    if not lists or type(lists[kind]) ~= "table" then return end
    local arr = lists[kind]
    for i = 1, #arr do
        local e = arr[i]
        if type(e) == "table" and e.dict and e.name and animDictExists(e.dict) then
            local lab = (type(e.menuLabel) == "string" and e.menuLabel) or ("Из config #" .. tostring(i))
            elements[#elements + 1] = {
                label = lab,
                value = "play_anim",
                dict = e.dict,
                name = e.name,
                durationMs = e.durationMs,
                flag = e.flag,
            }
        end
    end
end

local function toggleAnimalNpcAggroCommand()
    if not cfgBool("SkinAnimalNpcCombatEnabled", true) then return end
    if not canUseNpcAnimalExtras() then return end
    if not npcAggroAllowedForKind(PropGizmo_AssistAnimalKind) then return end
    animalAggroActive = not animalAggroActive
    local p = PlayerPedId()
    if not animalAggroActive then
        animalAggroCombatTarget = nil
        pcall(function()
            ClearPedTasks(p)
        end)
    else
        animalAggroCombatTarget = nil
        playContextualAnimalVocal(p)
    end
end

local function buildAnimalSkinMenuElements()
    local elements = {}
    local kind = PropGizmo_AssistAnimalKind or "generic"
    local animCount = 0
    if kind ~= "bird" then
        elements[#elements + 1] = { label = "Звук (рычание / вой / рев)", value = "vocal" }
        elements[#elements + 1] = { label = "Лечь / отдых (анимация на месте, с кулдауном)", value = "lie" }
        if cfgBool("SkinAnimalNpcCombatEnabled", true) and npcAggroAllowedForKind(kind) then
            elements[#elements + 1] = {
                label = animalAggroActive and "NPC автоатака: ВКЛ (нажми — выкл.)" or "NPC автоатака: ВЫКЛ (нажми — вкл.)",
                value = "aggro_toggle",
            }
        end
    else
        elements[#elements + 1] = { label = "Птица: звук / лечь / NPC-агрессия здесь недоступны", value = "_bird_note" }
    end
    if cfgBool("SkinAnimalAllowCrouchToggle", true) and kind ~= "bird" and kind ~= "horse" then
        elements[#elements + 1] = { label = "Низкая стойка / присед (переключить)", value = "crouch_toggle" }
    end
    elements[#elements + 1] = { label = "Сбросить анимации (ClearPedTasks)", value = "clear_tasks" }
    local beforeAnim = #elements
    appendHorseAnimSkinsScenarioRows(elements, kind, PlayerPedId())
    appendConfigQuickAnimRows(elements, kind)
    appendPresetRows(elements, kind)
    animCount = #elements - beforeAnim
    if animCount == 0 then
        elements[#elements + 1] = {
            label = "Нет словарей анимаций для этого типа в игре — добавьте Config.SkinAnimalQuickAnims[тип].",
            value = "_hint_anim",
        }
    end
    return elements
end

local function handleAnimalSkinMenuSelection(cur, kind)
    if not cur or type(cur.value) ~= "string" then return end
    local v = cur.value
    if v == "_bird_note" or v == "_hint_anim" or v == "_horse_hdr" then return end
    if v == "vocal" then
        if kind ~= "bird" then
            playContextualAnimalVocal(PlayerPedId())
        end
    elseif v == "lie" and kind ~= "bird" then
        runAnimalLieMenuAction(kind)
    elseif v == "aggro_toggle" and kind ~= "bird" then
        toggleAnimalNpcAggroCommand()
    elseif v == "crouch_toggle" then
        local p = PlayerPedId()
        if p ~= 0 and kind ~= "bird" and kind ~= "horse" and not isHorseLikePed(p) then
            setPedCrouchMovement(p, not getPedCrouchMovement(p), true)
        end
    elseif v == "clear_tasks" then
        local p = PlayerPedId()
        pcall(function()
            ClearPedTasksImmediately(p, true, true)
        end)
        pcall(function()
            ClearPedTasks(p)
        end)
        pcall(function()
            if StopAnimPlayback then
                StopAnimPlayback(p, 0, true)
            end
        end)
    elseif v == "play_anim" then
        playAnimMenuEntry(cur)
    elseif v == "horse_scenario" then
        local ped = PlayerPedId()
        if kind == "horse" or isHorseLikePed(ped) then
            local sn = cur.scenario
            if type(sn) == "string" and sn ~= "" then
                beginHorseScenarioMenuAction(ped, sn)
            end
        end
    end
end

local function drawAnimMenuLiteral(normX, normY, text, scale, center, r, g, b, a)
    if not text or text == "" then return end
    local str = CreateVarString(10, "LITERAL_STRING", tostring(text))
    pcall(function()
        SetTextFontForCurrentCommand(0)
        SetTextScale(scale or 0.32, scale or 0.32)
        SetTextColor(r or 255, g or 255, b or 255, a or 220)
        if center then
            SetTextCentre(true)
        else
            SetTextCentre(false)
        end
        SetTextDropshadow(1, 0, 0, 0, 200)
        DisplayText(str, normX, normY)
    end)
end

local function openAnimalSkinAnimMenuBuiltin(elements, kind)
    if not elements or #elements == 0 then
        skinAnimMenuTip("Список действий пуст.", 4000)
        return
    end
    animMenuSession = animMenuSession + 1
    local sid = animMenuSession
    animSkinBuiltinMenuOpen = true
    local sel = 1
    local maxVis = math.floor(math.max(6, math.min(16, cfgNum("SkinAnimalAnimMenuBuiltinMaxLines", 12))))
    CreateThread(function()
        while animSkinBuiltinMenuOpen and animMenuSession == sid do
            Wait(0)
            if not PropGizmo_AssistAnimalActive then
                break
            end
            local ped = PlayerPedId()
            if ped == 0 or isHumanLikePed(ped) then
                break
            end
            local fe = {
                `INPUT_FRONTEND_UP`,
                `INPUT_FRONTEND_DOWN`,
                `INPUT_FRONTEND_ACCEPT`,
                `INPUT_FRONTEND_CANCEL`,
            }
            for i = 1, #fe do
                pcall(function()
                    EnableControlAction(0, fe[i], true)
                end)
            end
            local up = IsControlJustPressed(0, `INPUT_FRONTEND_UP`) or IsDisabledControlJustPressed(0, `INPUT_FRONTEND_UP`)
            local down = IsControlJustPressed(0, `INPUT_FRONTEND_DOWN`) or IsDisabledControlJustPressed(0, `INPUT_FRONTEND_DOWN`)
            local accept = IsControlJustPressed(0, `INPUT_FRONTEND_ACCEPT`) or IsDisabledControlJustPressed(0, `INPUT_FRONTEND_ACCEPT`)
            local cancel = IsControlJustPressed(0, `INPUT_FRONTEND_CANCEL`) or IsDisabledControlJustPressed(0, `INPUT_FRONTEND_CANCEL`)
            if up then
                sel = math.max(1, sel - 1)
            elseif down then
                sel = math.min(#elements, sel + 1)
            elseif accept then
                pcall(function()
                    handleAnimalSkinMenuSelection(elements[sel], kind)
                end)
                break
            elseif cancel then
                break
            end
            local first = math.max(1, math.min(sel - 2, #elements - maxVis + 1))
            local last = math.min(#elements, first + maxVis - 1)
            drawAnimMenuLiteral(0.5, 0.08, "Анимации скина (/animskins)", 0.42, true, 255, 248, 220, 255)
            drawAnimMenuLiteral(0.5, 0.12, ("Тип: %s"):format(kindRuSubtitle(kind)), 0.30, true, 220, 220, 200, 230)
            for idx = first, last do
                local row = idx - first + 1
                local y = 0.16 + row * 0.032
                local e = elements[idx]
                local lab = (e and e.label) and tostring(e.label) or "?"
                if idx == sel then
                    drawAnimMenuLiteral(0.08, y, ("› %s"):format(lab), 0.34, false, 255, 220, 120, 255)
                else
                    drawAnimMenuLiteral(0.08, y, ("  %s"):format(lab), 0.32, false, 235, 235, 235, 210)
                end
            end
            drawAnimMenuLiteral(0.5, 0.88, "Вверх / Вниз — список  ·  Enter — выбрать  ·  Esc — закрыть", 0.26, true, 200, 200, 200, 200)
        end
        if animMenuSession == sid then
            animSkinBuiltinMenuOpen = false
        end
    end)
end

local function openAnimalSkinAnimMenuVorp(MenuData, elements, kind)
    local ns = (GetCurrentResourceName() or "vorp_prop_gizmo") .. "_animal_anim"
    local menuName = "AnimSkinsMain"
    MenuData.Open("default", ns, menuName, {
        title = "Анимации скина",
        subtext = ("Тип: %s · модель — как в каталоге"):format(kindRuSubtitle(kind)),
        align = "top-left",
        elements = elements,
    }, function(data, menu)
        local cur = data and data.current
        if not cur or type(cur.value) ~= "string" then
            if menu and menu.close then menu.close(true, true, true) end
            return
        end
        handleAnimalSkinMenuSelection(cur, kind)
        if menu and menu.close then menu.close(true, true, true) end
    end, function(menu)
        if menu and menu.close then menu.close(true, true, true) end
    end)
end

local function openAnimalSkinAnimMenu()
    if not PropGizmo_AssistAnimalActive then
        skinAnimMenuTip("Сначала примените звериный скин (ассист не активен).", 5000)
        return
    end
    local ped = PlayerPedId()
    if ped == 0 or isHumanLikePed(ped) then
        skinAnimMenuTip("Команда только в облике животного.", 5000)
        return
    end
    local kind = PropGizmo_AssistAnimalKind or "generic"
    local elements = buildAnimalSkinMenuElements()
    if cfgBool("SkinAnimalAnimMenuUseVorpMenu", false) then
        local MenuData = tryGetMenuData()
        if MenuData then
            openAnimalSkinAnimMenuVorp(MenuData, elements, kind)
            return
        end
        skinAnimMenuTip("vorp_menu не запущен — открываю встроенное меню.", 4000)
    end
    openAnimalSkinAnimMenuBuiltin(elements, kind)
end

local function faceEntity(attacker, target)
    local p1 = GetEntityCoords(attacker)
    local p2 = GetEntityCoords(target)
    local heading = GetHeadingFromVector_2d(p2.x - p1.x, p2.y - p1.y)
    SetEntityHeading(attacker, heading)
end

local function applyMeleeResult(attacker, target, spec)
    if not spec then return end
    local force = tonumber(spec.force) or 0.0
    if force > 0 and not IsPedAPlayer(target) then
        pcall(function()
            SetPedToRagdoll(target, 800, 800, 0, false, false, false)
        end)
        local fv = GetEntityForwardVector(attacker)
        SetEntityVelocity(target, fv.x * force, fv.y * force, fv.z * force + 0.15)
    end
    local dmg = tonumber(spec.damage) or 0
    if dmg > 0 and not IsPedAPlayer(target) then
        pcall(function()
            ApplyDamageToPed(target, math.floor(dmg), 1, -1, 0)
        end)
    end
end

local function tryMeleeAttack()
    if not cfgBool("SkinAnimalExtrasEnabled", true) then return end
    if not cfgBool("SkinAnimalMeleeOnAttack", true) then return end
    local now = GetGameTimer()
    if now - lastMeleeMs < meleeCooldownMs then return end
    local playerPed = PlayerPedId()
    if playerPed == 0 or IsPedDeadOrDying(playerPed, true) or IsPedRagdoll(playerPed) then return end
    local spec = meleeSpecForPed(playerPed)
    if not spec or not spec.dict or not spec.name then return end
    local radius = tonumber(spec.radius) or 2.5
    local target = getClosestPed(playerPed, radius)
    if not target then return end
    lastMeleeMs = now
    faceEntity(playerPed, target)
    playAnimDict(playerPed, spec.dict, spec.name, 2200, 0)
    if IsPedAPlayer(target) then
        if resolveFixAnimalsResourceName() then
            local tid = getPlayerServerIdFromPed(target)
            if tid then
                TriggerServerEvent("fixanimals:attack", tid, -1)
            end
        end
    else
        applyMeleeResult(playerPed, target, spec)
    end
end

local function tryPlayQuickAnim(slot)
    if not cfgBool("SkinAnimalExtrasEnabled", true) then return end
    if not cfgBool("SkinAnimalQuickAnimsEnabled", true) then return end
    local k = PropGizmo_AssistAnimalKind
    if type(k) ~= "string" then return end
    local lists = cfgTable("SkinAnimalQuickAnims")
    if not lists or not lists[k] then return end
    local entry = lists[k][slot]
    if type(entry) ~= "table" or not entry.dict or not entry.name then return end
    local ped = PlayerPedId()
    if ped == 0 or IsPedDeadOrDying(ped, true) then return end
    playAnimDict(ped, entry.dict, entry.name, entry.durationMs or 4000, entry.flag or 49)
end

function PropGizmo_StartAnimalAssist(modelName)
    PropGizmo_StopAnimalAssist()
    if not cfgBool("SkinAnimalExtrasEnabled", true) then return end
    if type(modelName) ~= "string" or modelName == "" then return end
    local ped = PlayerPedId()
    if ped == 0 then return end
    if isHumanLikePed(ped) then return end
    PropGizmo_AssistAnimalActive = true
    PropGizmo_AssistAnimalKind = (type(PropGizmo_ModelKindForSkin) == "function") and PropGizmo_ModelKindForSkin(modelName) or "generic"
    local cd = tonumber(Config and Config.SkinAnimalMeleeCooldownMs) or 2000
    meleeCooldownMs = math.max(500, math.min(cd, 10000))
    birdFlightActive = false
    birdLandingActive = false
    birdJumpFirstTapMs = 0
    pcall(function()
        SetPedConfigFlag(ped, 43, true)
        SetPedConfigFlag(ped, 146, false)
        SetPedConfigFlag(ped, 301, false)
    end)
    if cfgBool("SkinAnimalTempInvincible", true) then
        pcall(function()
            SetEntityInvincible(ped, true)
        end)
    end
    if PropGizmo_AssistAnimalKind == "horse" or isHorseLikePed(ped) then
        pcall(function()
            SetPedCanJump(ped, true)
            SetPedConfigFlag(ped, 301, true)
        end)
    end
    if PropGizmo_AssistAnimalKind == "bird" then
        PropGizmo_SetupBirdAbilities(ped)
    else
        applyAnimalNpcSetup(ped, PropGizmo_AssistAnimalKind)
    end
    CreateThread(function()
        Wait(100)
        pcall(function()
            SetGameplayCamRelativeHeading(0.0, 1.0)
        end)
        pcall(function()
            if SetGameplayCamInitialHeading then
                SetGameplayCamInitialHeading(0.0)
            end
        end)
    end)
end

function PropGizmo_StopAnimalAssist()
    PropGizmo_AssistAnimalActive = false
    PropGizmo_AssistAnimalKind = nil
    birdFlightActive = false
    birdLandingActive = false
    birdJumpFirstTapMs = 0
    animalAggroActive = false
    lastAnimalCombatTaskMs = 0
    animalAggroCombatTarget = nil
    animSkinBuiltinMenuOpen = false
    pcall(function()
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    end)
    setControlContext(2, 0)
    local ped = PlayerPedId()
    if ped ~= 0 and DoesEntityExist(ped) then
        pcall(function()
            SetEntityInvincible(ped, false)
        end)
        pcall(function()
            SetPedConfigFlag(ped, 43, false)
        end)
        pcall(function()
            SetPedConfigFlag(ped, 146, false)
        end)
        pcall(function()
            SetPedConfigFlag(ped, 301, false)
        end)
        pcall(function()
            if ResetPedMovementClipset then
                ResetPedMovementClipset(ped, 0.25)
            end
        end)
        pcall(function()
            if SetPedCanFly then
                SetPedCanFly(ped, false)
            end
        end)
        pcall(function()
            SetPedCanRagdoll(ped, true)
        end)
    end
end

function PropGizmo_AppendAnimalSkinHints(lines, kind)
    if not cfgBool("SkinAnimalExtrasEnabled", true) then return end
    if type(lines) ~= "table" or type(kind) ~= "string" then return end
    if cfgBool("SkinAnimalTempInvincible", true) then
        lines[#lines + 1] =
            "Временная неуязвимость в зверином скине включена (Config.SkinAnimalTempInvincible). Снимается при сбросе скина / выходе из облика."
    end
    if kind == "bird" then
        lines[#lines + 1] =
            "Птица — земля: WASD, Shift; OnMount + флаг 43 (иначе часто нет шага). Полёт упрощённый, не как у NPC-птицы."
        lines[#lines + 1] =
            "Пробел — быстрый взлёт + вход в полёт; двойной пробел в окне SkinBirdDoubleTapMs — посадка (если летишь) или включение полёта с земли."
        lines[#lines + 1] = "В полёте: W/S — высота, A/D — поворот; мышь — камера; V — вид, удержание V — кинематограф (если SkinAnimalSuppressFirstPersonCam = false)."
        lines[#lines + 1] =
            "Смещение камеры: стабилизация по умолчанию выкл. (иначе дёрганье). При необходимости — SkinAnimalStabilizeGameplayCamWhenLookIdle, порог и SkinAnimalStabilizeCamCooldownMs в config."
    elseif kind == "horse" then
        lines[#lines + 1] =
            "Лошадь / ездовое: прыжок — пробел (если модель позволяет). Атака — ЛКМ, F (ближний бой), сильный удар лошади — отдельная кнопка (часто ПКМ в привязках лошади — см. INPUT_HORSE_ATTACK в настройках)."
        lines[#lines + 1] =
            "Меню /animskins: блок сценариев — лежание (RESTING), сон (SLEEPING), валянье (ROLLING), лечь/встать (HORSE_LIE_DOWN / GET_UP и anim-варианты). Часть имён может не сработать на конкретном педе."
    elseif kind == "bear" or kind == "feline" or kind == "canid" then
        lines[#lines + 1] =
            "Хищник: движение WASD, спринт Shift, прыжок пробел. Атака — ЛКМ и/или F/R (ближний бой). Рядом с NPC — доп. анимация «укуса» по ЛКМ (если настроен fallback / Config)."
    elseif kind == "reptile" then
        lines[#lines + 1] =
            "Рептилия: движение WASD; атака ЛКМ / F. В воде скорость плавания может отличаться. Ближний бой с NPC — см. ЛКМ и Config."
    elseif kind == "deer" or kind == "herbivore" then
        lines[#lines + 1] =
            "Травоядное: WASD, Shift, пробел. ЛКМ / F — удары, если модель их поддерживает; у NPC — доп. клип по ЛКМ при наличии настроек."
    elseif kind == "small" then
        lines[#lines + 1] =
            "Мелкое животное: WASD, Shift, пробел; ЛКМ / F. Ближний бой с NPC — ЛКМ при настроенном fallback."
    else
        lines[#lines + 1] =
            "Животное: WASD, Shift, пробел; ЛКМ / F / R — как в стандартных привязках. Точное поведение зависит от модели педа."
    end
    if cfgBool("SkinAnimalMeleeOnAttack", true) then
        local spec = meleeSpecForPed(PlayerPedId())
        if spec then
            lines[#lines + 1] =
                "Кастомная ближняя атака (анимация): ЛКМ / F / удар лошади — рядом с NPC (игрокам только при PvP). Кд: SkinAnimalMeleeCooldownMs."
        elseif kind ~= "bird" then
            lines[#lines + 1] =
                "Если нет своей анимации укуса — добавьте SkinAnimalMeleeByHash[модель] в config.lua."
        end
    end
    if cfgBool("SkinAnimalAllowCrouchToggle", true) and kind ~= "bird" and kind ~= "horse" then
        lines[#lines + 1] = "Низкая стойка / присед (если есть): клавиша ближнего боя лошади (часто G)."
    end
    if cfgBool("SkinAnimalQuickAnimsEnabled", true) then
        lines[#lines + 1] =
            "Доп. анимации из Config.SkinAnimalQuickAnims[«"
            .. kind
            .. "»] — только пункты в меню /"
            .. ((type(Config) == "table" and type(Config.SkinAnimalAnimMenuCommand) == "string" and Config.SkinAnimalAnimMenuCommand:gsub("^/", ""):lower()) or "animskins")
            .. " (отдельных клавиш-слотов нет)."
    end
    if kind ~= "bird" and cfgBool("SkinAnimalNpcCombatEnabled", true) then
        local ag = (type(Config) == "table" and type(Config.SkinAnimalKeyAggro) == "string" and Config.SkinAnimalKeyAggro) or "u"
        local cmd = "animskins"
        local ac = type(Config) == "table" and Config.SkinAnimalAnimMenuCommand
        if type(ac) == "string" and ac ~= "" then
            cmd = ac:gsub("^/", ""):lower()
        end
        lines[#lines + 1] =
            "NPC-атака: "
            .. string.upper(ag)
            .. " — вкл/выкл автоатаки на ближайшую цель (хищник/рептилия по умолчанию, см. SkinAnimalNpcCombatPredatorsOnly). "
            .. "Звук, лечь, пресеты анимаций — команда /"
            .. cmd
            .. " (встроенное меню или vorp_menu при SkinAnimalAnimMenuUseVorpMenu). Клавиша "
            .. string.upper(ag)
            .. " в config: SkinAnimalKeyAggro."
        if cfgBool("SkinAnimalBindVocalLieBoostKeys", false) then
            local vo = (type(Config) == "table" and type(Config.SkinAnimalKeyVocal) == "string" and Config.SkinAnimalKeyVocal) or "g"
            local li = (type(Config) == "table" and type(Config.SkinAnimalKeyLie) == "string" and Config.SkinAnimalKeyLie) or "x"
            lines[#lines + 1] =
                "Доп. привязки (SkinAnimalBindVocalLieBoostKeys): "
                .. string.upper(vo)
                .. " — звук; "
                .. string.upper(li)
                .. " — лечь."
        end
    end
    lines[#lines + 1] =
        "У части моделей нет рабочих ударов или нет своих строк в SkinAnimalMeleeByHash / SkinAnimalQuickAnims — это нормально для многих педов в RDR."
end

CreateThread(function()
    while true do
        if PropGizmo_AssistAnimalActive then
            Wait(0)
            local ped = PlayerPedId()
            if ped == 0 or not DoesEntityExist(ped) then
                PropGizmo_StopAnimalAssist()
            else
                if isHumanLikePed(ped) then
                    PropGizmo_StopAnimalAssist()
                else
                    if cfgBool("SkinAnimalExtrasEnabled", true) then
                        --- redm-fixanimals: для любого звериного скина (включая птиц) — OnMount иначе WASD часто не двигает педа.
                        setControlContext(2, joaat("OnMount"))
                        if PropGizmo_AssistAnimalKind == "bird" and not birdFlightActive then
                            pcall(function()
                                if SetPedCanFly then
                                    SetPedCanFly(ped, false)
                                end
                            end)
                        end
                        if shouldSuppressFirstPersonCamThisFrame() then
                            pcall(DisableFirstPersonCamThisFrame)
                        end
                        enableAssistMovementControls()
                        stabilizeGameplayCamIfLookIdle()
                        if PropGizmo_AssistAnimalKind == "bird" then
                            processBirdJump(ped)
                            if birdFlightActive then
                                applyBirdFlightImpulse(ped)
                            elseif birdLandingActive then
                                processBirdLandingStep(ped)
                            end
                        end
                        if isHorseLikePed(ped) or PropGizmo_AssistAnimalKind == "horse" then
                            pcall(function()
                                SetPedCanJump(ped, true)
                            end)
                        end
                        if cfgBool("SkinAnimalMeleeOnAttack", true) then
                            local a1 = IsControlJustPressed(0, `INPUT_ATTACK`)
                            local a2 = IsControlJustPressed(0, `INPUT_MELEE_ATTACK`)
                            local a3 = IsControlJustPressed(0, `INPUT_HORSE_ATTACK`)
                            if a1 or a2 or a3 then
                                tryMeleeAttack()
                            end
                        end
                        if cfgBool("SkinAnimalAllowCrouchToggle", true)
                            and PropGizmo_AssistAnimalKind ~= "bird"
                            and PropGizmo_AssistAnimalKind ~= "horse"
                            and not isHorseLikePed(ped)
                            and IsControlJustPressed(0, `INPUT_HORSE_MELEE`) then
                            setPedCrouchMovement(ped, not getPedCrouchMovement(ped), true)
                        end
                        if cfgBool("SkinAnimalNpcCombatEnabled", true) and animalAggroActive then
                            local k = PropGizmo_AssistAnimalKind
                            if npcAggroAllowedForKind(k) then
                                local now = GetGameTimer()
                                local ret = cfgNum("SkinAnimalNpcCombatRetaskMs", 2200)
                                if now - lastAnimalCombatTaskMs >= ret then
                                    lastAnimalCombatTaskMs = now
                                    local rad = cfgNum("SkinAnimalNpcCombatRadius", 22.0)
                                    local tgt = getClosestPed(ped, rad)
                                    if tgt then
                                        if animalAggroCombatTarget ~= tgt then
                                            animalAggroCombatTarget = tgt
                                            local gA = GetPedRelationshipGroupHash(ped)
                                            local gT = GetPedRelationshipGroupHash(tgt)
                                            pcall(function()
                                                SetRelationshipBetweenGroups(5, gA, gT)
                                                SetRelationshipBetweenGroups(5, gT, gA)
                                            end)
                                        end
                                        pcall(function()
                                            SetPedKeepTask(ped, true)
                                        end)
                                        pcall(function()
                                            if TaskCombatPed then
                                                TaskCombatPed(ped, tgt, 0, 0)
                                            else
                                                Citizen.InvokeNative(0xF166E48407BAC484, ped, tgt, 0, 0)
                                            end
                                        end)
                                    else
                                        animalAggroCombatTarget = nil
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else
            Wait(500)
        end
    end
end)

local function bindAnimalFeatureKeys()
    if type(RegisterKeyMapping) ~= "function" then return end
    local base = (type(Config) == "table" and type(Config.SkinAnimalKeyMappingDescription) == "string" and Config.SkinAnimalKeyMappingDescription)
        or "Prop Gizmo скин"
    local agg = (type(Config) == "table" and type(Config.SkinAnimalKeyAggro) == "string" and Config.SkinAnimalKeyAggro) or "u"
    RegisterKeyMapping("+prop_gizmo_animal_aggro", base .. " — NPC-атака (повтор — выкл.)", "keyboard", string.lower(agg))
    if cfgBool("SkinAnimalBindVocalLieBoostKeys", false) then
        local voc = (type(Config) == "table" and type(Config.SkinAnimalKeyVocal) == "string" and Config.SkinAnimalKeyVocal) or "g"
        local lie = (type(Config) == "table" and type(Config.SkinAnimalKeyLie) == "string" and Config.SkinAnimalKeyLie) or "x"
        RegisterKeyMapping("+prop_gizmo_animal_vocal", base .. " — звук (рычит/воет)", "keyboard", string.lower(voc))
        RegisterKeyMapping("+prop_gizmo_animal_lie", base .. " — лечь/расслабиться", "keyboard", string.lower(lie))
    end
end

RegisterCommand("+prop_gizmo_animal_aggro", function()
    toggleAnimalNpcAggroCommand()
end, false)
RegisterCommand("-prop_gizmo_animal_aggro", function() end, false)

RegisterCommand("+prop_gizmo_animal_vocal", function()
    if not canUseNpcAnimalExtras() then return end
    if PropGizmo_AssistAnimalKind == "bird" then return end
    playContextualAnimalVocal(PlayerPedId())
end, false)
RegisterCommand("-prop_gizmo_animal_vocal", function() end, false)

RegisterCommand("+prop_gizmo_animal_lie", function()
    if not canUseNpcAnimalExtras() then return end
    if PropGizmo_AssistAnimalKind == "bird" then return end
    runAnimalLieMenuAction(PropGizmo_AssistAnimalKind or "generic")
end, false)
RegisterCommand("-prop_gizmo_animal_lie", function() end, false)

local function animSkinsCommandName()
    local raw = (type(Config) == "table" and Config.SkinAnimalAnimMenuCommand) or "animskins"
    local n = (type(raw) == "string" and raw:gsub("^/", ""):lower()) or "animskins"
    if n == "" then n = "animskins" end
    return n
end

RegisterCommand(animSkinsCommandName(), function()
    if not cfgBool("SkinAnimalExtrasEnabled", true) then
        skinAnimMenuTip("Ассист животного выключен (SkinAnimalExtrasEnabled).", 4000)
        return
    end
    openAnimalSkinAnimMenu()
end, false)

CreateThread(function()
    Wait(900)
    bindAnimalFeatureKeys()
end)

AddEventHandler("onResourceStop", function(res)
    if res ~= GetCurrentResourceName() then return end
    PropGizmo_StopAnimalAssist()
end)
