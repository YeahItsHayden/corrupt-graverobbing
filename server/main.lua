local config = require 'config/sv_config'
local sConfig = require ('config.sh_config')

lib.callback.register('corrupt-graverobbing:returnGraves', function()
    return config['graves'], config['maxGraves'], config['graveCount']
end)

lib.callback.register('corrupt-graverobbing:alertPolice', function(source)
    alertPolice(source)
    return true
end)

lib.callback.register('corrupt-graverobbing:returnPedDetails', function()
    return config['startDetails']
end)

lib.callback.register('corrupt-graverobbing:returnPolice', function()
    if sConfig['framework'] == 'qbx' then 
        local cops = exports.qbx_core:GetDutyCountJob(sConfig['policeJob'])

        if cops >= config['minPolice'] then
            return true 
        else
            return false
        end
    elseif sConfig['framework'] == 'esx' then 
        local cops = ESX.GetExtendedPlayers('job', sConfig['policeJob'])
        local police = 0

        for i = 1, #cops do 
            police = i
        end

        if police >= sConfig['minPolice'] then 
            return true 
        else
            return false 
        end
    end
end)