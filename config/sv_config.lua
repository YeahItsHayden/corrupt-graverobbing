return {
   ['minPolice'] = 0, -- the minimum amount of police required
   ['maxGraves'] = true, -- whether or not grave count should be limited
   ['graveCount'] = 3, -- amount of graves to rob to 'win'
   ['graves'] = {
        vec3(-1662.67, -169.0, 57.56),
        vec3(-1669.36, -160.16, 57.76),
        vec3(-1673.67, -164.9, 57.94)
   },
   ['maxItems'] = 5, -- max amount of items to give
   ['loot'] = {
        {label = 'Water', item = 'water', min = 1, max = 5},
   },
   ['startDetails'] = {
        ped = `A_M_Y_HasJew_01`, 
        pedCoords = vec3(-2288.49, 370.08, 173.6),
        heading = 29.32,
   }
}