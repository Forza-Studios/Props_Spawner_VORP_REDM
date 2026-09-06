local ArchetypeIndexer = {}
local archetypeCache = {}
local validModelCache = {}

-- Hashes string using RedM Joaat
local function joaat(str)
    if not str or str == "" then return 0 end
    return GetHashKey(str)
end

-- Layer 2 lookup: Native RDR3 Asset Indexer
function ArchetypeIndexer.ValidateNativeModel(modelName)
    if not modelName or type(modelName) ~= "string" or modelName == "" then return false end
    
    local lowerName = modelName:lower()
    if validModelCache[lowerName] ~= nil then
        return validModelCache[lowerName]
    end

    local modelHash = joaat(lowerName)
    -- Native authoritative lookup against RDR3 asset CD Image index
    local isCdImage = IsModelInCdimage(modelHash)
    local isValid = IsModelValid(modelHash)
    local exists = (isCdImage and isValid) or false
    
    validModelCache[lowerName] = exists
    return exists
end

-- Filter or inject native archetypes when searching
function ArchetypeIndexer.SearchArchetypes(query, existingCatalogList)
    if not query or query == "" then
        return existingCatalogList or {}
    end

    local cleanQuery = query:lower():gsub("%s+", "")
    local cacheKey = cleanQuery
    if archetypeCache[cacheKey] then
        return archetypeCache[cacheKey]
    end

    local results = {}
    local seen = {}

    -- 1. Filter existing catalog list
    if existingCatalogList then
        for i = 1, #existingCatalogList do
            local model = existingCatalogList[i]
            if type(model) == "string" then
                if model:lower():find(cleanQuery, 1, true) then
                    table.insert(results, model)
                    seen[model:lower()] = true
                end
            end
        end
    end

    -- 2. Dual-Layer Fallback: If clean query looks like a valid model string or archetype pattern
    -- Check common RDR2 prop prefix patterns if user typed something specific like "house", "barn", "cabin", etc.
    local searchCandidates = { cleanQuery }
    if not cleanQuery:find("^p_") and not cleanQuery:find("^s_") and not cleanQuery:find("^m_") then
        table.insert(searchCandidates, "p_" .. cleanQuery)
        table.insert(searchCandidates, "s_" .. cleanQuery)
    end

    for _, candidate in ipairs(searchCandidates) do
        if not seen[candidate] and ArchetypeIndexer.ValidateNativeModel(candidate) then
            table.insert(results, candidate)
            seen[candidate] = true
        end
    end

    archetypeCache[cacheKey] = results
    return results
end

function ArchetypeIndexer.ClearCache()
    archetypeCache = {}
    validModelCache = {}
end

exports("SearchArchetypes", ArchetypeIndexer.SearchArchetypes)
exports("ValidateNativeModel", ArchetypeIndexer.ValidateNativeModel)

return ArchetypeIndexer
