local config = require ('config.cl_config')
local isMinigameActive = false

drawText = function(msg, coords)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z + 1)

    if onScreen then
        SetTextScale(0.4, 0.4)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(msg)
        DrawText(_x, _y)
    end
end

notify = function(msg, status)
    if not status then status = 'inform' end

    lib.notify({
        title = 'Grave Robbing',
        description = msg,
        type = status
    })
end

-- Returns a random zone with width between minW and maxW, optionally avoiding overlaps
-- Needed for the minigame below
generateZone = function(existingZones, minW, maxW)
    for _ = 1, 50 do -- try 50 times to avoid infinite loops
        local width = math.random(minW, maxW)
        local start = math.random(0, 100 - width)
        local finish = start + width

        local overlaps = false
        for _, z in pairs(existingZones) do
            if not (finish < z.start or start > z.finish) then
                overlaps = true
                break
            end
        end

        if not overlaps then
            return { start = start, finish = finish }
        end
    end
    return nil -- fallback (shouldn't happen)
end

startMinigame = function() -- if you want to incorporate a different minigame, ensure it returns 'true' to pass

    local safeZones, dangerZones = {}, {}

    -- Generate 2 safe zones
    for i = 1, 2 do
        local z = generateZone(safeZones, 10, 20) -- width between 10% and 20%
        if z then table.insert(safeZones, z) end
    end

    -- Generate 1 danger zone that doesn’t overlap
    for i = 1, 1 do
        local z = generateZone(safeZones, 5, 15) -- danger zone width 5–15%
        if z then table.insert(dangerZones, z) end
    end

    local p = promise.new()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "startMinigame",
        config = {
            stages = 5, -- Number of successful digs needed
            speed = 2000, -- Cursor movement duration (ms)
            safeZones = safeZones,
            dangerZones = dangerZones
        }
    })

    -- Wait for result via NUI callback
    RegisterNUICallback("minigameResult", function(data, cb)
        SetNuiFocus(false, false)
        cb("ok")

        p:resolve(data.success)
    end)

    -- Wait for the promise to return
    local result = Citizen.Await(p)
    return result
end

drawMarker = function(sprite, coords, size, colour)
    DrawMarker(
        sprite,
        coords.x,
        coords.y,
        coords.z,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        size,
        size,
        size,
        colour.Red,
        colour.Green,
        colour.Blue,
        255,
        false,
        true,
        2,
        nil,
        nil,
        nil,
        false
    )
end

-- Shuffle table utility
shuffle = function(tbl)
    for i = #tbl, 1, -1 do
        local rand = math.random(i)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end
end

local shuffledGraves = {}
local graveIndex = 1

-- Function to get the next valid grave
getRandomGrave = function(graveTable, maxGraves)
    -- Reshuffle if needed
    if graveIndex > maxGraves or graveIndex > #shuffledGraves then
        shuffledGraves = {table.unpack(graveTable)}
        shuffle(shuffledGraves)
        graveIndex = 1
    end

    local coord = shuffledGraves[graveIndex]
    graveIndex = graveIndex + 1
    return coord
end

-- digup grave
robGrave = function(grave)
    local playerPed = PlayerPedId()
    local dict = "anim@scripted@player@freemode@cash_dig@heeled@"
    local anim = "action"

    -- Load the animation dictionary first
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end

    -- Play the animation
    TaskPlayAnim(playerPed, dict, anim, 8.0, -8.0, 5000, 1, 0, false, false, false)
    Wait(5000)
    local outcome = lib.callback.await('corrupt-graverobbing:handleReward')
end
