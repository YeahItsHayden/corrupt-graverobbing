local config = require ('config.cl_config')
local sConfig = require ('config.sh_config')
local spawnedPed = false
local starterNPC, startedMission

RegisterCommand("robgrave", function() 
    TriggerEvent('corrupt-graverobbing:spawnGraves')
end, false)

CreateThread(function()
    local pedDetails = lib.callback.await('corrupt-graverobbing:returnPedDetails')

    RequestModel(pedDetails.ped)

    while not HasModelLoaded(pedDetails.ped) do 
        Wait(1)
    end

    if sConfig['interaction'] == 'ox-target' then 
        local NPCStarterzone = exports.ox_target:addBoxZone({
            name = 'graveNpcZone',
            coords = vec3(pedDetails.pedCoords.x, pedDetails.pedCoords.y, pedDetails.pedCoords.z + 1),
            size = vec3(2, 2, 2),
            rotation = 90,
            debug = false,
            options = {
                {
                    icon = 'fa fa-clipboard',
                    label = 'Speak to NPC',
                    onSelect = function()

                        local alert = lib.alertDialog({
                            header = 'Hello there',
                            content = 'Would you like to do a little mission for me?\n Its definitely legal!',
                            centered = true,
                            cancel = true
                        })

                        if alert == 'cancel' then return end
                            
                        if not startedMission then
                            local enoughPolice = lib.callback.await('corrupt-graverobbing:returnPolice')
                            if enoughPolice and sConfig['policeRequired'] then 
                                TriggerEvent('corrupt-graverobbing:spawnGraves')
                            elseif not sConfig['policeRequired'] then 
                                TriggerEvent('corrupt-graverobbing:spawnGraves')
                            else 
                                notify('There are not enough police on', 'error')
                            end
                        elseif startedMission then 
                            notify('You have already started the mission.', 'error')
                        end
                    end,
                    distance = 200,
                }
            }
        })
    end


    while true do 
        Wait(0)

        playerCoords = GetEntityCoords(PlayerPedId())

        if #(playerCoords - pedDetails.pedCoords) < 15 then
            if not spawnedPed then
                spawnedPed = true
                starterNPC = CreatePed(0, pedDetails.ped, pedDetails.pedCoords.x, pedDetails.pedCoords.y, pedDetails.pedCoords.z, pedDetails.heading, false, true)
                FreezeEntityPosition(starterNPC, true)
            end
            
            if sConfig['interaction'] == 'text' then
                if #(playerCoords - pedDetails.pedCoords) < 2.5 then 
                    drawText('Press [~r~E~w~] to speak to person', pedDetails.pedCoords)

                    if IsControlJustPressed(0, 38) and not startedMission then
                        local enoughPolice = lib.callback.await('corrupt-graverobbing:returnPolice')

                        local alert = lib.alertDialog({
                            header = 'Hello there',
                            content = 'Would you like to do a little mission for me?\n Its definitely legal!',
                            centered = true,
                            cancel = true
                        })

                        if alert ~= 'cancel' then
                            if enoughPolice and sConfig['policeRequired'] then 
                                TriggerEvent('corrupt-graverobbing:spawnGraves')
                            elseif not sConfig['policeRequired'] then 
                                TriggerEvent('corrupt-graverobbing:spawnGraves')
                            else 
                                notify('There are not enough police on', 'error')
                            end     
                        end    
                    elseif IsControlJustPressed(0, 38) and startedMission then 
                        notify('You have already started the mission.', 'error')
                    end
                end
            end
        else
            if spawnedPed then 
                SetPedAsNoLongerNeeded(starterNPC)
                DeletePed(starterNPC)
                spawnedPed = false
            end
            Wait(2500)
        end
    end 
end)

RegisterNetEvent('corrupt-graverobbing:spawnGraves', function()
    notify('You have started a grave robbing mission\nCheck your map for the blips of grave robbery.', 'success')
    startedMission = true 


    -- Variable init
    local graves = {}
    local graveMarkers = config['graveMarkers']

    -- Get grave data
    local graveTable, maxGraves, graveCount = lib.callback.await('corrupt-graverobbing:returnGraves') 
    for i = 1, #graveTable do
        local grave = getRandomGrave(graveTable, graveCount)
        table.insert(graves, grave)

        -- Break if we exceed our max count
        if maxGraves and i == graveCount then 
            break 
        end
    end

    local graveBlip = {}

    for k, v in pairs(graves) do
        graveBlip[k] = AddBlipForCoord(v.x, v.y, v.z)
        SetBlipSprite(graveBlip[k], graveMarkers.blipSprite)
        SetBlipDisplay(graveBlip[k], 4)
        SetBlipScale(graveBlip[k], graveMarkers.blipScale)
        SetBlipColour(graveBlip[k], graveMarkers.blipColour)
        SetBlipAsShortRange(graveBlip[k], true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(graveMarkers.blipTitle)
        EndTextCommandSetBlipName(graveBlip[k]) 
    end

    -- Thread to handle marker drawing etc
    if sConfig['interaction'] == 'text' then
        while true do 
            Wait(0)

            playerCoords = GetEntityCoords(PlayerPedId())

            for k, v in pairs(graves) do
                if #(playerCoords - v) < 5 then 
                    drawMarker(graveMarkers.sprite, v, graveMarkers.size, graveMarkers.colour)

                    if #(playerCoords - v) < 2.5 then 
                        drawText("Press [~r~E~w~] to dig up grave", vec3(v.x,v.y,v.z-1))

                        if IsControlJustPressed(0, 38) then
                            local game = startMinigame()
                            print(game)
                            if game then 
                                table.remove(graves, k) 
                                RemoveBlip(graveBlip[k])
                                robGrave()

                                if not next(graves) then
                                    notify('You have completed the robbery! Now flee!', 'success') 
                                end
                            else 
                                notify('Failed to rob grave', 'error')

                                lib.callback('corrupt-graverobbing:alertPolice')
                            end
                        end 
                    end
                end
            end
        end
    elseif sConfig['interaction'] == 'ox-target' then
        local graveZone = {} 
        for k,v in pairs(graves) do 
            local zone = exports.ox_target:addBoxZone({
                name = 'grave' .. k,
                coords = v,
                size = vec3(2, 2, 2),
                rotation = 90,
                debug = false,
                options = {
                    {
                        icon = 'fa fa-clipboard',
                        label = 'Dig Grave',
                        onSelect = function()
                            local game = startMinigame() 
                            if game then 
                                table.remove(graves, k)
                                exports.ox_target:removeZone('grave' .. k) 
                                RemoveBlip(graveBlip[k])
                                robGrave()

                                if not next(graves) then
                                    notify('You have completed the robbery! Now flee!', 'success') 
                                end
                            else 
                                notify('Failed to rob grave', 'error')

                                lib.callback('corrupt-graverobbing:alertPolice')
                            end
                        end,
                        distance = 200,
                    }
                }
            })
        end
    end
end)