Config = {}

-- Core: "auto" (detect vorp_core or RSG core), or force "vorp" / "rsg".
-- In server.cfg start vorp_core OR rsg-core before this resource.
Config.Framework = "vorp"

-- RSG only: resource name if not "rsg-core" (e.g. "rsg_core"). "auto" mode tries rsg-core then rsg_core.
Config.RsgCoreResource = "rsg-core"

-- UI language: "en" or "ru".
Config.Language = "en"

-- Access to the /gizmo command.
-- Users can open if they match an allowed job OR pass the admin check below.
-- RSG (rsg-core): AdminGroups = ACE permission strings checked via HasPermission (e.g. "admin" — same as /ooc admin in stock RSG).
-- VORP: AdminGroups = VORP group names from your users table.
-- If true: /gizmo is available to everyone (ignores AdminGroups/Jobs checks).
Config.AllowGizmoForEveryone = false
Config.CommandAccess = {
    AdminGroups = {
        "admin",
    },
    Jobs = {
        -- Example: "sheriff", "police", "marshal"
    },
}

-- Category visibility rules (tab = category, block = subcategory).
-- Fill category names exactly as they appear in the sidebar.
Config.CategoryAccess = {
    -- Optional global allow-list. Empty = all categories allowed by default.
    AllowedCategories = {
        -- Example: "Bank", "Tools", "Work"
    },

    -- Global deny-list for full categories (hide tab).
    HiddenCategories = {
        -- Example: "Body Parts"
    },

    -- Global deny-list for blocks inside a category (hide specific block).
    HiddenBlocks = {
        -- Example:
        -- ["Work"] = { "Anvil", "Wagon parts" }
    },

    -- Job-specific overrides.
    Jobs = {
        -- Example:
        -- ["blacksmith"] = {
        --     AllowedCategories = { "Work", "Tools" },
        --     HiddenCategories = { "Religion" },
        --     HiddenBlocks = {
        --         ["Work"] = { "Wagon", "Trash" }
        --     }
        -- }
    }
}

-- Placement step sizes.
Config.PlaceStepForward = 0.05
Config.PlaceStepSide = 0.05
Config.PlaceStepUp = 0.05
Config.PlaceStepRotate = 3.0
Config.PlaceStepPitch = 5.0
Config.PlaceStepRoll = 5.0

-- Max distance from player to placement preview while moving (meters). 0 = no limit.
-- Legacy name still supported: Config.PlaceMaxDistance (if PlaceMovementMaxRadius is nil).
Config.PlaceMovementMaxRadius = 8.0

-- Speed slider (percent).
Config.PlaceSpeedSliderMin = 5
Config.PlaceSpeedSliderMax = 100
Config.PlaceSpeedSliderStep = 5

-- Spawn distance in front of player (meters).
Config.SpawnDistance = 1.8
Config.SpawnHeightOffset = 0.35
-- Peds tab: spawn offset in front of the player (meters).
Config.PedSpawnDistance = 2.5
Config.PedSpawnHeightOffset = 0.0

-- Server: placed props JSON file in resource folder (persists across restarts).
Config.ServerPlacedPropsFile = "placed_props_sync.json"
-- Server: placed map blips (synced for all players).
Config.ServerPlacedBlipsFile = "placed_blips_sync.json"
-- Server: persisted player ped models (Steam / license keys from identifiers).
Config.ServerPlayerSkinFile = "player_skin_persist.json"
-- Server: last N assignments (who gave whom which ped model).
Config.ServerPlayerSkinHistoryFile = "player_skin_history.json"
Config.SkinHistoryMaxEntries = 80
-- Client: after applying a skin, EnableControlAction runs this long (ms) to soften other scripts blocking inputs.
Config.SkinApplyControlBoostMs = 30000

-- === Animal / bird player skin extras (client/animal_skin_assist.lua) ===
-- Идея контекста ввода и ближнего боя близка к https://github.com/kibook/redm-fixanimals (анимации из игры).
-- Полноценный полёт птицы и сюжетные сцены «прыжка на спину» этим не добавляются — только земля + ЛКМ + опциональные клипы.
Config.SkinAnimalExtrasEnabled = true
Config.SkinAnimalMeleeOnAttack = true
Config.SkinAnimalMeleeCooldownMs = 2000
Config.SkinAnimalAllowCrouchToggle = true
Config.SkinAnimalQuickAnimsEnabled = true
-- Клавиши для RegisterKeyMapping (латиница в нижнем регистре, как в настройках R*).
Config.SkinAnimalKeyMappingDescription = "Prop Gizmo скин"
-- Точная настройка укуса/удара по модели (хэш joaat). Если нет — используется fallback по «типу» в animal_skin_assist.lua.
-- Пример: [`A_C_Wolf`] = { dict = "creatures_mammal@wolf@melee@attacks@streamed_core", name = "attack", radius = 3.0, force = 3.0, damage = 25 },
Config.SkinAnimalMeleeByHash = {}
-- Доп. анимации только через меню /animskins: ключ = тип (bird, canid, feline, bear, reptile, small, herbivore, deer, horse, generic).
-- Каждая запись: { dict, name, durationMs, flag, menuLabel? }. menuLabel — подпись в меню /animskins (иначе «Из config #N»).
Config.SkinAnimalQuickAnims = {
    -- Пример (раскомментируйте и проверьте в игре):
    -- canid = {
    --     { dict = "creatures_mammal@wolf@normal@", name = "idle", durationMs = 5000, flag = 49 },
    -- },
}

-- === Режим «как NPC»: агрессия TaskCombatPed, звуки, лечь (client/animal_skin_assist.lua) ===
-- ПКМ не трогаем — он обычно прицел; клавиши ниже (латиница для RegisterKeyMapping в GTA PC).
-- Звук / лечь: по умолчанию только через меню /animskins (встроенный список, без vorp_menu).
Config.SkinAnimalBindVocalLieBoostKeys = false
-- Команда меню анимаций (без слэша в RegisterCommand).
Config.SkinAnimalAnimMenuCommand = "animskins"
-- true = открывать список через vorp_menu (если ресурс запущен); false = всегда встроенное меню на экране.
Config.SkinAnimalAnimMenuUseVorpMenu = false
-- Сколько строк показывать во встроенном меню (остальное — прокрутка).
Config.SkinAnimalAnimMenuBuiltinMaxLines = 12
Config.SkinAnimalNpcCombatEnabled = true
Config.SkinAnimalNpcCombatPredatorsOnly = true
-- Если PredatorsOnly = false — агрессия для любого не-человека кроме птицы (крыса и т.д. могут вести себя странно).
Config.SkinAnimalNpcCombatRadius = 22.0
Config.SkinAnimalNpcCombatRetaskMs = 2200
-- «Лечь» в меню: пауза между повторами (мс); флаг TaskPlayAnim (часто 524290 = без ухода корнем — подбирайте под модель).
Config.SkinAnimalLieCooldownMs = 12000
Config.SkinAnimalLieAnimFlag = 524290
Config.SkinAnimalApplyPredatorCombatStats = true
Config.SkinAnimalApplyReptileCombatStats = true
-- default_animal_clipset может сломать отдельные скины — по умолчанию выкл.
Config.SkinAnimalApplyDefaultAnimalClipset = false
Config.SkinAnimalVocalizeEnabled = true
Config.SkinAnimalKeyAggro = "u"
Config.SkinAnimalKeyVocal = "g"
Config.SkinAnimalKeyLie = "x"

-- Временная неуязвимость в зверином скине (тест / без смерти от окружения). Выключите: false.
-- Таблица ударов: client/fixanimals_attack_types_data.lua (как redm-fixanimals-master). Отключить: false.
Config.SkinAnimalUseFixAnimalsAttackTypes = true
-- Имена ресурсов redm-fixanimals (любой запущенный) — для PvP-релея TriggerServerEvent("fixanimals:attack", …).
Config.SkinAnimalFixAnimalsResourceNames = {
    "redm-fixanimals-master",
    "redm-fixanimals",
}

Config.SkinAnimalTempInvincible = true
-- Как fixanimals: каждый кадр DisableFirstPersonCamThisFrame (меньше глюков FP у зверей). false = лучше кинематограф и V.
Config.SkinAnimalSuppressFirstPersonCam = false
-- Смещение follow-камеры: по умолчанию ВЫКЛ. — частый сброс даёт дёрганье. Включайте только если камера «уезжает» без движения мыши.
Config.SkinAnimalStabilizeGameplayCamWhenLookIdle = false
Config.SkinAnimalStabilizeCamLookThreshold = 0.06
-- Минимум мс между сбросами (если стабилизация включена).
Config.SkinAnimalStabilizeCamCooldownMs = 2200
-- Птица: двойной пробел в окне (мс) — взлёт/посадка (переключение «режима полёта» + импульс).
Config.SkinBirdDoubleTapMs = 400
-- Одиночный пробел: резкий импульс вверх + (если ещё не в полёте) включить режим полёта.
Config.SkinBirdQuickTakeoffOnJump = true
Config.SkinBirdQuickTakeoffForceZ = 2.35
Config.SkinBirdQuickTakeoffForceFwd = 0.65
-- По умолчанию наземная ходьба = сброс clipset движка (лучше для A_C_Hawk_01 и др.). Включите true, чтобы снова навешивать клипы снизу.
Config.SkinBirdGroundApplyMovementClipset = false
-- Если SkinBirdGroundApplyMovementClipset = true — по очереди (например только default_bird_clipset).
Config.SkinBirdGroundClipsets = {}
-- (Устарело) раньше снимали флаг 43 каждый кадр — это ломало ходьбу как в redm-fixanimals (там 43=true + OnMount).
-- Clipset для включённого режима полёта по двойному пробелу.
Config.SkinBirdFlightClipsets = {
    "bird_fly",
}
-- Полёт птицы: W = вверх, S = вниз (силы в ApplyForceToEntity).
Config.SkinBirdFlightForceUpZ = 1.45
Config.SkinBirdFlightForceFwd = 0.55
Config.SkinBirdFlightForceDownZ = 1.15
Config.SkinBirdFlightForceDownFwd = 0.22
-- Посадка по двойному пробелу: автоспуск, пока не достигнута высота до земли.
Config.SkinBirdLandingForceZ = 0.95
Config.SkinBirdLandingForceFwd = 0.12
Config.SkinBirdLandingStopHeight = 0.95
-- Поворот в полёте/при посадке: A/D (градусов в секунду).
Config.SkinBirdFlightTurnDegPerSec = 120.0
-- Устарело: используйте SkinAnimalSuppressFirstPersonCam. Если true только для птицы — как раньше «ванильная» камера.
Config.SkinBirdAllowVanillaCamera = true
-- Client: wait this long AFTER vorp spawn finished (vorp_core:Client:OnPlayerSpawned) before re-applying saved Player skin.
-- Keeps multichar / creator on a normal human until you are in session.
Config.PersistedSkinAfterSpawnDelayMs = 3000
-- Client: ignore duplicate auto skin requests closer than this (ms) — spawn + resource restart race.
Config.PersistedSkinAutoApplyDebounceMs = 8000
-- Server: named folders of placed prop IDs (for organizing Placed list).
Config.ServerPlacedFoldersFile = "placed_prop_folders.json"
-- Catalogs: extend JSON files; NUI loads peds client-side, blips also on server for validation.
Config.PedsCatalogFile = "data/peds_catalog.json"
Config.BlipsCatalogFile = "data/blips_catalog.json"
-- Map blip appearance (RedM native style hash; default matches common script usage).
Config.BlipStyle = 1664425300
Config.BlipScale = 0.2
-- RedLookup (https://redlookup.com) — thumbnail URL for Peds / Blips cards. Use {name} and optionally {sprite}.
-- If empty, the UI tries several paths under RedLookupBaseUrl; if RedLookup changes, set explicit URLs from DevTools → Network.
Config.RedLookupBaseUrl = "https://redlookup.com"
Config.RedLookupPedImageUrl = ""
Config.RedLookupBlipImageUrl = ""
-- Server: max distance from player ped to placement point (anti-cheat). 0 = off.
Config.PlaceMaxDistanceCheck = 30.0

-- Client streaming for world-placed props (spawn only near player).
-- Load radius (meters): props spawn when you are within this distance.
-- Unload radius (meters): props despawn when farther; keep >= load distance.
-- Legacy names still supported: PlacedStreamDistance / PlacedDespawnDistance (if new keys are nil).
Config.PlacedPropLoadDistance = 180.0
Config.PlacedPropUnloadDistance = 220.0
Config.PlacedStreamRefreshMs = 1200
Config.PlacedStreamSpawnBudgetPerTick = 12

-- NUI "Placed" page size (prevents UI freezes with huge lists).
Config.PlacedListPageSize = 100
Config.CatalogPageSize = 120

-- Prop preview in NUI: {id}.webp. Empty = only local html/img/*.png/.webp.
Config.PropThumbnailBaseUrl = "https://pub-baba8ba72b514b59b37deb644a62a310.r2.dev/props"

-- NUI: nest all categories under "Spooni Props".
Config.NuiWrapSpooniPropsRoot = false
-- If wrap is enabled, auto-expand "Spooni Props" on open.
Config.NuiExpandSpooniRootOnOpen = true

-- Server: on resource start, download full catalog from Supabase into data/spooni_catalog.json.
-- After a successful download, restart the resource (or server) so clients load the file.
-- Anon key is the same as in spooni.pages.dev JS (DevTools -> Network -> apikey).
Config.SpooniFetchCatalogOnResourceStart = false
Config.SpooniSupabaseUrl = "https://gzddqqtajsoqeaknhykn.supabase.co"
Config.SpooniSupabaseAnonKey = ""

-- Show in-game hint when catalog has only one top category.
Config.CatalogHintIfSingleCategory = true

-- === Framework detection (client + server; keep in this file so it always loads) ===

function GizmoRsgResourceName()
    local preferred = (type(Config) == "table" and type(Config.RsgCoreResource) == "string") and Config.RsgCoreResource or nil
    if preferred and preferred ~= "" and GetResourceState(preferred) == "started" then
        return preferred
    end
    if GetResourceState("rsg-core") == "started" then
        return "rsg-core"
    end
    if GetResourceState("rsg_core") == "started" then
        return "rsg_core"
    end
    return (preferred and preferred ~= "" and preferred) or "rsg-core"
end

function GizmoResolveFramework()
    local mode = "auto"
    if type(Config) == "table" and type(Config.Framework) == "string" then
        mode = Config.Framework:lower()
    end
    if mode == "vorp" then
        return "vorp"
    end
    if mode == "rsg" then
        return "rsg"
    end
    if GetResourceState("vorp_core") == "started" then
        return "vorp"
    end
    local rsgName = GizmoRsgResourceName()
    if GetResourceState(rsgName) == "started" then
        return "rsg"
    end
    return nil
end
