local GLOBAL = GLOBAL or _G
GLOBAL.isServerSide = GLOBAL.TheNet:GetIsServer()
GLOBAL.isClientSide = GLOBAL.TheNet:GetIsClient() or (GLOBAL.isServerSide and not GLOBAL.TheNet:IsDedicated())

print('[Bernie] Starting module imports...')

modimport("scripts/both_manager.lua")
if (GLOBAL.isClientSide) then
    modimport("scripts/client_manager.lua")
elseif (GLOBAL.isServerSide) then
    modimport("scripts/server_manager.lua")
end

print('[Bernie] Finished loading!')
