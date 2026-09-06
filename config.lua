Config = {}

-- Framework detection mode: "auto" (tries rsg-core / vorp_core), "rsg", or "vorp"
Config.Framework = "auto"
Config.RsgCoreResource = "rsg-core"

-- Interface language: "en" or "ru"
Config.Language = "en"

-- Access configuration for /gizmo command
Config.AllowGizmoForEveryone = false
Config.CommandAccess = {
    AdminGroups = {
        "admin",
        "god",
        "mod"
    },
    Jobs = {
        -- Example: "sheriff", "marshal"
    }
}

-- Category visibility rules
Config.CategoryAccess = {
    AllowedCategories = {},
    HiddenCategories = {},
    HiddenBlocks = {},
    Jobs = {}
}

-- Step increments for placement gizmo controls
Config.PlaceStepForward = 0.05
Config.PlaceStepSide = 0.05
Config.PlaceStepUp = 0.05
Config.PlaceStepRotate = 3.0
Config.PlaceStepPitch = 5.0
Config.PlaceStepRoll = 5.0

-- Max placement distance from player entity (0.0 = unlimited)
Config.PlaceMovementMaxRadius = 8.0

-- Speed slider defaults
Config.PlaceSpeedSliderMin = 5
Config.PlaceSpeedSliderMax = 100
Config.PlaceSpeedSliderStep = 5

-- Default spawn placement offsets in front of player
Config.SpawnDistance = 2.0
Config.SpawnHeightOffset = 0.2
Config.PedSpawnDistance = 2.5
Config.PedSpawnHeightOffset = 0.0

-- Server persistence filenames (stored inside resource directory)
Config.ServerPlacedPropsFile = "placed_props_sync.json"
Config.ServerPlacedBlipsFile = "placed_blips_sync.json"
Config.ServerPlacedFoldersFile = "placed_prop_folders.json"

-- Catalog data sources
Config.SpooniCatalogFile = "data/spooni_catalog.json"
Config.BankPropsCatalogFile = "data/bank_props.json"
Config.PedsCatalogFile = "data/peds_catalog.json"
Config.BlipsCatalogFile = "data/blips_catalog.json"

-- Blip map defaults
Config.BlipStyle = 1664425300
Config.BlipScale = 0.2

-- Image CDN lookup endpoints
Config.RedLookupBaseUrl = "https://redlookup.com"
Config.RedLookupPedImageUrl = ""
Config.RedLookupBlipImageUrl = ""
Config.PropThumbnailBaseUrl = "https://pub-baba8ba72b514b59b37deb644a62a310.r2.dev/props"

-- Anti-cheat max placement distance check on server submission (0.0 = disabled)
Config.PlaceMaxDistanceCheck = 30.0

-- Client distance streaming engine configuration
Config.PlacedPropLoadDistance = 180.0
Config.PlacedPropUnloadDistance = 220.0
Config.PlacedStreamRefreshMs = 1200
Config.PlacedStreamSpawnBudgetPerTick = 12

-- UI Pagination limits
Config.PlacedListPageSize = 100
Config.CatalogPageSize = 120

-- Category tree layout
Config.NuiWrapSpooniPropsRoot = false
Config.NuiExpandSpooniRootOnOpen = true

-- Framework Helper Functions
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
    local rsgName = GizmoRsgResourceName()
    if GetResourceState(rsgName) == "started" then
        return "rsg"
    end
    if GetResourceState("vorp_core") == "started" then
        return "vorp"
    end
    return nil
end
