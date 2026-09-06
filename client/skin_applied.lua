--- After SetPlayerModel (animal / ped skin): combat tweaks, control un-block, NUI hints (RU), /skinexit.

local function modelKind(modelLower)
    if modelLower:find("^a_c_bird") or modelLower:find("crow")
        or modelLower:find("eagle") or modelLower:find("hawk")
        or modelLower:find("owl") or modelLower:find("vulture")
        or modelLower:find("parrot") or modelLower:find("chicken")
        or modelLower:find("duck") or modelLower:find("goose")
        or modelLower:find("pigeon") or modelLower:find("seagull") then
        return "bird"
    end
    if modelLower:find("bear") or modelLower:find("grizzly") or modelLower:find("blackbear") then
        return "bear"
    end
    if modelLower:find("wolf") or modelLower:find("coyote") or modelLower:find("fox")
        or modelLower:find("dog") or modelLower:find("hyena") then
        return "canid"
    end
    if modelLower:find("cougar") or modelLower:find("panther") or modelLower:find("lion")
        or modelLower:find("lynx") or modelLower:find("bobcat") then
        return "feline"
    end
    if modelLower:find("horse") or modelLower:find("donkey") or modelLower:find("mule") then
        return "horse"
    end
    if modelLower:find("deer") or modelLower:find("elk") or modelLower:find("moose")
        or modelLower:find("buck") or modelLower:find("prong") then
        return "deer"
    end
    if modelLower:find("boar") or modelLower:find("pig") or modelLower:find("sheep")
        or modelLower:find("goat") or modelLower:find("cow") or modelLower:find("bull")
        or modelLower:find("buffalo") or modelLower:find("ox") then
        return "herbivore"
    end
    if modelLower:find("gator") or modelLower:find("croc") or modelLower:find("snake") then
        return "reptile"
    end
    if modelLower:find("rat") or modelLower:find("rabbit") or modelLower:find("squirrel")
        or modelLower:find("beaver") or modelLower:find("raccoon") or modelLower:find("skunk") then
        return "small"
    end
    return "generic"
end

--- Тип зверя для скина (bird, canid, …) — используется animal_skin_assist.lua.
function PropGizmo_ModelKindForSkin(modelName)
    local m = (type(modelName) == "string" and modelName:lower()) or ""
    return modelKind(m)
end

--- Подсказки только на русском (по запросу).
function PropGizmo_BuildSkinHintLines(modelName, _lang)
    local m = (type(modelName) == "string" and modelName:lower()) or ""
    local kind = modelKind(m)
    local lines = {}
    local title = "Управление обликом"

    if kind == "bird" then
        title = "Управление обликом · птица"
        lines[#lines + 1] =
            "Земля: WASD, Shift, прыжок как в игре. Для звериного педа включены OnMount и флаг 43 (иначе птица часто не идёт)."
        lines[#lines + 1] =
            "Полёт (упрощённый, не как у сюжетной птицы-NPC): одиночный пробел — быстрый взлёт и вход в режим полёта; двойной пробел в коротком окне — если летишь, начнётся посадка; если на земле — включение полёта."
        lines[#lines + 1] = "В полёте: W — вверх, S — вниз, A/D — поворот. Мышь — камера; V — смена вида, удержание V — кинематограф (если в config выключено подавление первого лица у зверей)."
        lines[#lines + 1] =
            "Если камера «уезжает» у мелкого педа — можно включить SkinAnimalStabilizeGameplayCamWhenLookIdle в config (по умолчанию выкл.: частый сброс дёргает камеру). Есть кулдаун SkinAnimalStabilizeCamCooldownMs."
        lines[#lines + 1] =
            "Бой: ЛКМ, F/R — как в привязках игры; отдельная «анимация укуса» по NPC только если модель есть в таблицах атаки в config (у многих птиц своей записи нет)."
    elseif kind == "bear" or kind == "feline" or kind == "canid" then
        title = "Хищник (медведь / кошка / собака и т.п.)"
        lines[#lines + 1] = "Захват цели: ПКМ (прицел), затем ЛКМ или клавиша ближнего боя."
        lines[#lines + 1] = "Ближний бой: F или R — как в обычной драке."
        lines[#lines + 1] = "Спринт: Shift. Удары чаще срабатывают в упор и при наведении на цель."
    elseif kind == "horse" then
        title = "Лошадь / похожий пед"
        lines[#lines + 1] = "Движение: WASD · Спринт: Shift · прыжок: пробел (если модель позволяет)."
        lines[#lines + 1] = "Атака: ЛКМ, F; сильный удар лошади — отдельная кнопка (см. подсказку ниже и привязки INPUT_HORSE_ATTACK)."
        lines[#lines + 1] =
            "В /animskins для лошади есть блок «сценарии»: отдых/сон на земле, лечь, встать, валяться (WORLD_ANIMAL_HORSE_* и связанные имена сценариев)."
    else
        lines[#lines + 1] =
            "Движение: WASD · Спринт: Shift · Прыжок: Пробел · Атака: ЛКМ · Ближний бой: F / R."
        lines[#lines + 1] = "Если удары не идут — наведитесь (ПКМ) на педа или подойдите ближе."
    end

    if kind ~= "bird" then
        local ag = (type(Config) == "table" and type(Config.SkinAnimalKeyAggro) == "string" and Config.SkinAnimalKeyAggro) or "u"
        local cmd = "animskins"
        local ac = type(Config) == "table" and Config.SkinAnimalAnimMenuCommand
        if type(ac) == "string" and ac ~= "" then
            cmd = ac:gsub("^/", ""):lower()
        end
        lines[#lines + 1] =
            "Не птица: «"
            .. string.upper(ag)
            .. "» — автоатака на ближайшую цель (NPC-стиль; повтор — выкл.). Звук, лечь, анимации — команда /"
            .. cmd
            .. " (встроенное меню на экране; vorp_menu не нужен). Клавиша "
            .. string.upper(ag)
            .. ": SkinAnimalKeyAggro."
        local bindExtra = type(Config) == "table" and Config.SkinAnimalBindVocalLieBoostKeys == true
        if bindExtra then
            local vo = (type(Config) == "table" and type(Config.SkinAnimalKeyVocal) == "string" and Config.SkinAnimalKeyVocal) or "g"
            local li = (type(Config) == "table" and type(Config.SkinAnimalKeyLie) == "string" and Config.SkinAnimalKeyLie) or "x"
            lines[#lines + 1] =
                "Доп. клавиши (SkinAnimalBindVocalLieBoostKeys): «"
                .. string.upper(vo)
                .. "» — звук; «"
                .. string.upper(li)
                .. "» — лечь."
        end
    end

    lines[#lines + 1] =
        "Общее: у части моделей животных удары, захват или доп. анимации скина могут не работать или не иметь своих настроек в config — так заложено у педа в игре, не обязательно баг скрипта."
    lines[#lines + 1] = "Скрыть эту панель: команда /skinexit"
    return title, lines
end

local function applyCombatAndPedFlags(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    pcall(function()
        SetBlockingOfNonTemporaryEvents(ped, false)
    end)
    pcall(function()
        SetEntityInvincible(ped, false)
    end)
    pcall(function()
        SetPedCanRagdoll(ped, true)
    end)
    if SetPedCombatAttributes then
        pcall(function()
            SetPedCombatAttributes(ped, 5, true)
            SetPedCombatAttributes(ped, 46, true)
            SetPedCombatAttributes(ped, 21, true)
            SetPedCombatAttributes(ped, 50, true)
            SetPedCombatAttributes(ped, 58, true)
            SetPedCombatAttributes(ped, 93, true)
        end)
    end
    if SetPedCombatAbility then
        pcall(function()
            SetPedCombatAbility(ped, 2)
        end)
    end
    if SetPedCombatMovement then
        pcall(function()
            SetPedCombatMovement(ped, 2)
        end)
    end
    if SetPedCombatRange then
        pcall(function()
            SetPedCombatRange(ped, 2)
        end)
    end
    pcall(function()
        Citizen.InvokeNative(0xBD75500141E4725C, ped, joaat("COMBAT_ANIMAL"))
    end)
end

local function enableMovementAndCombatControlsFor(durationMs)
    local untilT = GetGameTimer() + (tonumber(durationMs) or 30000)
    CreateThread(function()
        while GetGameTimer() < untilT do
            Wait(0)
            local ped = PlayerPedId()
            if ped == 0 or IsPedDeadOrDying(ped, true) then
                Wait(200)
            else
                local c = {
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
                for i = 1, #c do
                    pcall(function()
                        EnableControlAction(0, c[i], true)
                    end)
                end
            end
        end
    end)
end

--- Скрыть подсказку скина и гарантированно отпустить NUI-фокус (смерть / ревайв / /skinexit).
function PropGizmo_HideSkinHintAndReleaseNui()
    SendNUIMessage({ action = "skinHint", show = false })
    if type(PropGizmo_ForceReleaseNuiAndCursor) == "function" then
        PropGizmo_ForceReleaseNuiAndCursor()
    else
        pcall(function()
            SetNuiFocus(false, false)
            SetNuiFocusKeepInput(false)
        end)
    end
end

local function sendSkinHintWhenAlive(title, lines)
    CreateThread(function()
        local deadline = GetGameTimer() + 120000
        while GetGameTimer() < deadline do
            local p = PlayerPedId()
            if p ~= 0 and not IsPedDeadOrDying(p, true) then
                break
            end
            Wait(400)
        end
        local p = PlayerPedId()
        if p == 0 or IsPedDeadOrDying(p, true) then return end
        Wait(1200)
        p = PlayerPedId()
        if p == 0 or IsPedDeadOrDying(p, true) then return end
        SendNUIMessage({
            action = "skinHint",
            show = true,
            title = title,
            lines = lines,
        })
    end)
end

function PropGizmo_OnSkinApplied(modelName, lang, ped)
    if type(modelName) ~= "string" then return end
    ped = ped or PlayerPedId()
    Wait(100)
    ped = PlayerPedId()
    applyCombatAndPedFlags(ped)

    if type(PropGizmo_StartAnimalAssist) == "function" then
        PropGizmo_StartAnimalAssist(modelName)
    end

    local duration = 30000
    if type(Config) == "table" and Config.SkinApplyControlBoostMs then
        duration = tonumber(Config.SkinApplyControlBoostMs) or duration
    end
    enableMovementAndCombatControlsFor(duration)

    local title, lines = PropGizmo_BuildSkinHintLines(modelName, lang)
    local pCheck = PlayerPedId()
    if pCheck ~= 0 and IsPedDeadOrDying(pCheck, true) then
        sendSkinHintWhenAlive(title, lines)
    else
        SendNUIMessage({
            action = "skinHint",
            show = true,
            title = title,
            lines = lines,
        })
    end
end

RegisterCommand("skinexit", function()
    PropGizmo_HideSkinHintAndReleaseNui()
end, false)

pcall(function()
    TriggerEvent("chat:addSuggestion", "/skinexit", "Скрыть подсказку управления скином (prop gizmo)")
end)
