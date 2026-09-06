--- Death / respawn: close gizmo NUI, fix black screen; after revive re-queue persisted animal skin.

local function clearDeathVisualGlitch()
    DoScreenFadeIn(800)
    DisplayHud(true)
    DisplayRadar(true)
    ClearFocus()
    NetworkSetInSpectatorMode(false, PlayerPedId())
    RenderScriptCams(false, false, 0, true, false, 0)
end

AddEventHandler("vorp_core:Client:OnPlayerDeath", function()
    CreateThread(function()
        Wait(80)
        TriggerEvent("prop_gizmo:internalDeathCloseUi")
        clearDeathVisualGlitch()
    end)
end)

--- If core death loop did not start (some animal peds), still try to keep screen usable.
CreateThread(function()
    repeat Wait(2000) until LocalPlayer.state and LocalPlayer.state.IsInSession
    local wasDead = false
    while true do
        Wait(350)
        local ped = PlayerPedId()
        if ped ~= 0 then
            local dead = IsPedDeadOrDying(ped, true)
            if dead then
                if not wasDead then
                    wasDead = true
                    TriggerEvent("prop_gizmo:internalDeathCloseUi")
                end
                clearDeathVisualGlitch()
            elseif wasDead then
                wasDead = false
            end
        end
    end
end)

RegisterNetEvent("vorp_core:Client:OnPlayerRevive", function()
    CreateThread(function()
        if PropGizmo_HideSkinHintAndReleaseNui then
            PropGizmo_HideSkinHintAndReleaseNui()
        end
        Wait(8000)
        if PropGizmo_SchedulePersistedSkinReplay then
            PropGizmo_SchedulePersistedSkinReplay()
        end
    end)
end)

AddEventHandler("vorpcharacter:reloadafterdeath", function()
    CreateThread(function()
        if PropGizmo_HideSkinHintAndReleaseNui then
            PropGizmo_HideSkinHintAndReleaseNui()
        end
        Wait(7500)
        if PropGizmo_SchedulePersistedSkinReplay then
            PropGizmo_SchedulePersistedSkinReplay()
        end
    end)
end)
