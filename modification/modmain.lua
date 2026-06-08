print('[Bernie] Reading host configuration...')
local inconstant = GetModConfigData("Inconstant")
GLOBAL.debugging = GetModConfigData("Debug")

print('[Bernie] Starting module imports...')
modimport("scripts/essentials.lua")
if inconstant then modimport("scripts/inconstant.lua") end

print('[Bernie] Finished loading!')
