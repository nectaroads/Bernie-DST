print('[Bernie] Reading host configuration...')
local inconstant = GetModConfigData("Inconstant")
GLOBAL.debugging = GetModConfigData("Debug")

print('[Bernie] Starting module imports...')
modimport("scripts/essentials.lua")
modimport("scripts/inconstant.lua")

print('[Bernie] Finished loading!')
