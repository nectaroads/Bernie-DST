print('[Bernie] Starting Inconstant Core')

local isclient = not GLOBAL.TheNet:IsDedicated()

-- Both
modimport("scripts/modules/tunings.lua")
modimport("scripts/modules/rimevents.lua")
modimport("scripts/modules/rebalances.lua")

if isclient then
    -- Server only
else
    -- Client only
end
