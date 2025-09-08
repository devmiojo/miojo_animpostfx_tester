local AUTO_STOP_MS = 60000 -- 1 min
local currentFx = nil
local stopTimer = nil
local menuId = 'miojo_postfx_menu'
lib.locale()

local function playFx(name)
    if not name or name == '' then return end
    Citizen.InvokeNative(0x4102732DF6B4005F, name) -- ANIMPOSTFX_PLAY
end

local function stopFx(name)
    if not name or name == '' then return end
    Citizen.InvokeNative(0xB4FD7446BAB2F394, name) -- ANIMPOSTFX_STOP
end

local function isFxRunning(name)
    if not name or name == '' then return false end
    return Citizen.InvokeNative(0x4A123E85D7C4CA0B, name, Citizen.ResultAsInteger()) == 1
end

local function stopAll()
    Citizen.InvokeNative(0xD2209BE128B5418C) -- ANIMPOSTFX_STOP_ALL
end

local timerGen = 0
local function startAutoStopTimer(name)
    timerGen = timerGen + 1
    local myGen = timerGen
    stopTimer = true
    SetTimeout(AUTO_STOP_MS, function()
        if stopTimer and myGen == timerGen and isFxRunning(name) then
            stopFx(name)
            if currentFx == name then currentFx = nil end
            lib.notify({
                title = 'Miojo HUB',
                description = string.format(locale('stopped_automatically', name)),
                type = 'info'
            })
        end
    end)
end

local function toggleFx(name)
    if not name then return end
    if currentFx == name then
        if isFxRunning(name) then
            stopFx(name)
            currentFx = nil
            stopTimer = nil
            lib.notify({title = 'Miojo HUB', description = string.format(locale('stopped_effect', name)), type = 'success'})
        else
            playFx(name)
            currentFx = name
            startAutoStopTimer(name)
            lib.notify({title = 'Miojo HUB', description = string.format(locale('started_effect', name)), type = 'success'})
        end
        return
    end

    if currentFx and isFxRunning(currentFx) then
        stopFx(currentFx)
    end
    stopTimer = nil

    playFx(name)
    currentFx = name
    startAutoStopTimer(name)
    lib.notify({title = 'Miojo HUB', description = string.format(locale('toggled_effect'), name), type = 'success'})
end

local function buildPostFxMenu()
    if not AnimPostFX or not AnimPostFX.List or #AnimPostFX.List == 0 then
        return lib.notify({
            title = 'Miojo HUB',
            description = locale('list_empty'),
            type = 'error'
        })
    end

    local opts = {}
    for i, fxName in ipairs(AnimPostFX.List) do
        opts[i] = {
            label = fxName,
            icon = 'film',
            close = false,
            args = { name = fxName },
        }
    end

    lib.registerMenu({
        id = menuId,
        title = 'Miojo HUB AnimPostFX Tester',
        position = 'top-right',
        useMouse = true,
        useSearch = true,
        onClose = function() end,
        onSelected = function(selected, scrollIndex, args)
        end,
        options = opts
    }, function(_, _, args)
         if args and args.name then
            toggleFx(args.name)
        end
    end)
end

local function openPostFxMenu()
    buildPostFxMenu()
    lib.showMenu(menuId)
end

RegisterCommand('postfx', function()
    openPostFxMenu()
end, false)

RegisterCommand('postfxstop', function()
    if currentFx and isFxRunning(currentFx) then
        stopFx(currentFx)
    end
    currentFx = nil
    stopTimer = nil
    for _, fxName in ipairs(AnimPostFX.List) do
        stopFx(fxName)
    end
    stopAll()
    lib.notify({title = 'Miojo HUB', description = locale('all_effects_stop'), type = 'warning'})
end, false)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    stopAll()
end)
