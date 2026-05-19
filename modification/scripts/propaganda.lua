print('[Bernie] Starting Propaganda module')

local config = GLOBAL.LoadConfig("propaganda.lua")

AddPrefabPostInit("world", function(inst)
    if inst:HasTag("cave") then return end
    inst:DoPeriodicTask((config and config.cooldown or 60) * 60, function()
        local propaganda = (config and config.pool) or {}
        local rand = math.random(#propaganda)
        local target = propaganda[rand]
        local data = { key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "server", message = target or "error" }
        GLOBAL.ExecuteOnAllShards(data)
    end)
end)
