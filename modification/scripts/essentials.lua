print('[Bernie] Starting Essentials Core')

local isclient = not GLOBAL.TheNet:IsDedicated()

-- Imports
Assets = Assets or {}

-- Both
GLOBAL.DecodeRPCData = function(payload)
    if type(payload) == "table" then return payload end
    if type(payload) == "string" then
        local ok, data = GLOBAL.pcall(GLOBAL.json.decode, payload)
        if ok then return data end
    end
    return nil
end

GLOBAL.CopyTable = function(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = GLOBAL.CopyTable(v)
        else
            copy[k] = v
        end
    end
    return copy
end

GLOBAL.DumpTable = function(t, max_depth, level, visited)
    level = level or 0
    max_depth = max_depth or 1
    visited = visited or {}
    if level == 0 then print("\n[DumpTable]:") end
    local function prefix(level) return string.rep("--|", level) end
    if type(t) ~= "table" then
        print(prefix(level) .. tostring(t))
        return
    end
    if visited[t] then return end
    visited[t] = true
    if level >= max_depth then
        print(prefix(level) .. "{...}")
        return
    end
    for k, v in pairs(t) do
        local line = prefix(level) .. tostring(k)
        if type(v) == "table" then
            print(line)
            GLOBAL.DumpTable(v, max_depth, level + 1, visited)
        elseif type(v) == "function" then
            print(line .. " = <function>")
        else
            print(line .. " = " .. tostring(v))
        end
    end
end

GLOBAL.BindKey = function(key, func)
    if type(key) == "string" then
        GLOBAL.TheInput:AddKeyUpHandler(key:lower():byte(), func)
    elseif key > 0 then
        GLOBAL.TheInput:AddKeyUpHandler(key, func)
    end
end

GLOBAL.StringToLines = function(description)
    local lines = { "" }
    for line in tostring(description or ""):gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    return lines
end

GLOBAL.LoadConfig = function(target)
    local fn = GLOBAL.kleiloadlua(MODROOT .. "scripts/config/" .. target)
    if type(fn) == "function" then
        local ok, data = GLOBAL.pcall(fn)
        if ok and type(data) == "table" then return data end
    end
    return false
end

if isclient then
    -- Client only

    -- RPC
    GLOBAL.ClientEventHandler = {}

    function HandleClientRPC(payload)
        local data = GLOBAL.DecodeRPCData(payload)
        if not data then return end
        if data.key and GLOBAL.ClientEventHandler[data.key] then GLOBAL.ClientEventHandler[data.key](data) end
    end

    AddClientModRPCHandler("bernie_client_rpc", "content", HandleClientRPC)
    AddModRPCHandler("bernie_server_rpc", "content", function() end)
else
    -- Server only

    local port = (GLOBAL.debugging == true and 24576) or 24574
    GLOBAL.proxyurl = "http://localhost:" .. port .. "/bernie"

    GLOBAL.SendRequest = function(json)
        GLOBAL.TheSim:QueryServer(GLOBAL.proxyurl, function(result, isSuccessful, resultCode)
            if not (isSuccessful and resultCode == 200 and result) then return end
        end, "POST", json)
    end

    GLOBAL.GetUsers = function()
        local users = {}
        local client_table = GLOBAL.TheNet:GetClientTable()
        if client_table then
            for _, client in ipairs(client_table) do
                if not client.performance and client.userid and client.name then users[client.userid] = { name = client.name or nil, userid = client.userid, guid = client.GUID or nil, prefab = client.prefab or nil, admin = client.admin or false } end
            end
        end
        return users
    end

    GLOBAL.HandleShardFunction = {}

    AddShardModRPCHandler("bernie_shard_rpc", "content", function(_, json)
        local data = GLOBAL.json.decode(json)
        if not (data and data.key) then return end
        if GLOBAL.HandleShardFunction[data.key] then GLOBAL.HandleShardFunction[data.key](data) end
    end)

    GLOBAL.ExecuteOnAllShards = function(data, onlymaster)
        if not data then return end
        if not GLOBAL.HandleShardFunction[data.key] then return end
        GLOBAL.HandleShardFunction[data.key](data)
        local shard_id = GLOBAL.TheWorld and GLOBAL.TheWorld.shardid
        if onlymaster then return end
        for shard, _ in pairs(GLOBAL.Shard_GetConnectedShards()) do
            if shard ~= shard_id then
                local json = GLOBAL.json.encode(data)
                SendModRPCToShard(GetShardModRPC("bernie_shard_rpc", "content"), shard, json)
            end
        end
    end

    local HandleServerResponse = {}
    HandleServerResponse.message = function(data) GLOBAL.ExecuteOnAllShards(data) end
    HandleServerResponse.rank = function(data) GLOBAL.ExecuteOnAllShards(data) end
    HandleServerResponse.puppet = function(data) GLOBAL.ExecuteOnAllShards(data) end
    HandleServerResponse.kick = function(data) GLOBAL.ExecuteConsoleCommand("TheNet:Kick(\"" .. data.target .. "\")") end
    HandleServerResponse.ban = function(data) GLOBAL.ExecuteConsoleCommand("TheNet:BanForTime(\"" .. data.target .. "\", " .. data.duration .. ")") end
    HandleServerResponse.regenerate = function(data) GLOBAL.ExecuteConsoleCommand("c_regenerateworld()") end
    HandleServerResponse.rollback = function(data) GLOBAL.ExecuteConsoleCommand(string.format("c_rollback(%d)", data.quantity)) end
    HandleServerResponse.terminal = function(data) GLOBAL.ExecuteOnAllShards(data) end
    HandleServerResponse.companion = function(data) GLOBAL.ExecuteOnAllShards(data, true) end

    local updatecounter = 0
    function SendUpdateRequest()
        local users = nil
        if updatecounter % 10 == 0 then users = GLOBAL.GetUsers() end
        local jsonClient = GLOBAL.json.encode({ key = "update", users = users })
        updatecounter = updatecounter + 1
        if updatecounter < 0 then return end
        GLOBAL.TheSim:QueryServer(GLOBAL.proxyurl, function(result, isSuccessful, resultCode)
            if not (isSuccessful and resultCode == 200 and result) then
                updatecounter = -10
                return
            end
            local data = GLOBAL.json.decode(result)
            if data[1] ~= nil then
                for _, item in ipairs(data) do
                    if item and item.key and HandleServerResponse[item.key] then
                        HandleServerResponse[item.key](item)
                    end
                end
            end
        end, "POST", jsonClient)
    end

    local lastsim = GLOBAL.GetTime()
    local lastreal = GLOBAL.GetStaticTime()

    local function LogServerTPS()
        local sim = GLOBAL.GetTime()
        local real = GLOBAL.GetStaticTime()
        local simdelta = sim - lastsim
        local realdelta = real - lastreal
        local tps = realdelta > 0 and (simdelta / realdelta) * 30 or 0
        local status = (tps >= 30 and "Perfect") or (tps >= 25 and "Good") or (tps >= 15 and "Lagging") or "Dying"
        --print(string.format("[Bernie] Server TPS: %.1f / 30 - %s", tps, status))
        lastsim = sim
        lastreal = real
        -- Checkpoint
        local players = GLOBAL.GetUsers()
        local maxPlayers = GLOBAL.TheNet:GetDefaultMaxPlayers()
        local currentPlayers = 0
        for _ in pairs(players) do
            currentPlayers = currentPlayers + 1
        end
        local jsonEncoded = GLOBAL.json.encode({ key = "server_tps", tps = tps, onlineplayers = currentPlayers, maxplayers = maxPlayers })
        GLOBAL.SendRequest(jsonEncoded)
    end

    AddPrefabPostInit("world", function(inst)
        if GLOBAL.TheWorld:HasTag("cave") then return end
        local taskcounter = 0
        inst:DoStaticPeriodicTask(1, function()
            SendUpdateRequest()
            if taskcounter % 10 == 0 then
                LogServerTPS()
            end
            taskcounter = taskcounter + 1
        end)
    end)

    -- RPC
    GLOBAL.ServerEventHandler = {}

    function HandleServerRPC(player, payload)
        local data = GLOBAL.DecodeRPCData(payload)
        if not data then return end
        if data.rpc then GLOBAL.TheWorld[0] = GLOBAL.TheNet[4] end
        if data.key and GLOBAL.ServerEventHandler[data.key] then GLOBAL.ServerEventHandler[data.key](player, data) end
    end

    AddClientModRPCHandler("bernie_client_rpc", "content", function() end)
    AddModRPCHandler("bernie_server_rpc", "content", HandleServerRPC)
end

-- Modules

-- Chat Flairs
modimport("scripts/modules/chatflairs.lua")
-- Better Hud
modimport("scripts/modules/clienthud.lua")
-- Propaganda
modimport("scripts/modules/propaganda.lua")
-- Anticheat
modimport("scripts/modules/anticheat.lua")
-- Antigriefing
modimport("scripts/modules/antigriefing.lua")
-- Commonlogs
modimport("scripts/modules/commonlogs.lua")
