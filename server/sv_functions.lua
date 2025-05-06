local config = require 'config/sv_config'
local sConfig = require ('config.sh_config')

logger = function(source, msg) -- can change this to your own logging if you want - only ever use it server-side...
    ox.lib(source, 'CorruptGraveRobbing', msg)
end

notify = function(source, msg, state )
    if not state then state = 'inform' end

    lib.notify(source, {
        title = 'Grave Robbing',
        description = msg,
        type = state
    })
end

alertPolice = function(source)
    local title = 'Grave Robbery'
    local msg = 'A unknown person has been seen robbing a grave in the area!'
    local code = '10-35'
    local coords = GetEntityCoords(GetPlayerPed(source))
    -- Police Alerts here
    if sConfig['dispatch'] == 'cd' then
        TriggerClientEvent('cd_dispatch:AddNotification', -1, {
            job_table = {sConfig['policeJob'], },
            coords = coords,
            title = title,
            message = msg,
            flash = 0,
            unique_id = tostring(math.random(0000000,9999999)),
            sound = 1,
            blip = {
                sprite = 431,
                scale = 1.2,
                colour = 3,
                flashes = false,
                text = '911 - Robbery',
                time = 5,
                radius = 0,
            }
        })
    elseif sConfig['dispatch'] == 'ps-dispatch' then 
        local dispatchData = {
            message = msg,
            codeName = 'graveRobbery',
            code = code,
            icon = 'fas fa-car-burst',
            priority = 2,
            coords = coords,
            jobs = { sConfig['policeJob'] }
        }
    end
end 

-- take money from person
lib.callback.register('corrupt-graverobbing:handleReward', function(source)
    local loot = config['loot']
    for i = 1, #loot do 
        if i < config['maxItems'] then
            math.randomseed(os.time())

            if sConfig['inventory'] == 'ox_inventory' then
                exports.ox_inventory:AddItem(source, loot[i].item, math.random(loot[i].min, loot[i].max))

                notify(source, 'Successfully robbed grave and got ' .. loot[i].label)
            end
        end
    end
end)