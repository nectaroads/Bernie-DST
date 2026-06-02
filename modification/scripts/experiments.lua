print('[Bernie] Starting Experiments module')

GLOBAL.serverUrl = "http://localhost:24574/bernie"

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

if not GLOBAL.TheNet:IsDedicated() then return end

GLOBAL.AddClientModRPCHandler("bernie_rpc_client_message", "content", function() end)
GLOBAL.AddClientModRPCHandler("bernie_rpc_client_rank", "content", function() end)

GLOBAL.HandleShardFunction = {}

GLOBAL.SendRequest = function(json)
    GLOBAL.TheSim:QueryServer(GLOBAL.serverUrl, function(result, isSuccessful, resultCode)
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

AddShardModRPCHandler("bernie_rpc_shard_function", "content", function(_, json)
    local data = GLOBAL.json.decode(json)
    if not (data and data.key) then return end
    if GLOBAL.HandleShardFunction[data.key] then GLOBAL.HandleShardFunction[data.key](data) end
end)

GLOBAL.HandleShardFunction["bernie_rpc_client_message"] = function(data)
    local json = GLOBAL.json.encode(data)
    if not data.userid then
        local users = GLOBAL.GetUsers()
        for _, player in pairs(users) do
            if player and player.userid then
                if json then SendModRPCToClient(GetClientModRPC("bernie_rpc_client_message", "content"), player.userid, json) end
            end
        end
    else
        SendModRPCToClient(GetClientModRPC("bernie_rpc_client_message", "content"), data.userid, json)
    end
end

GLOBAL.HandleShardFunction["sadistic_event"] = function(data)
    if not data then return end
    if GLOBAL.CallSadisticEvent then
        GLOBAL.CallSadisticEvent(data.event)
    else
        print("[LOG] GLOBAL.CallSadisticEvent NOT FOUND.")
    end
end

GLOBAL.HandleShardFunction.rank = function(data)
    local json = GLOBAL.json.encode(data)
    if not data.userid then
        local users = GLOBAL.GetUsers()
        for _, player in pairs(users) do
            if player and player.userid then
                if json then SendModRPCToClient(GetClientModRPC("bernie_rpc_client_rank", "content"), player.userid, json) end
            end
        end
    else
        SendModRPCToClient(GetClientModRPC("bernie_rpc_client_rank", "content"), data.userid, json)
    end
end

GLOBAL.ExecuteOnAllShards = function(data, onlymaster)
    if not data then return end
    print("[LOG] ExecuteOnAllShards: " .. data.key)
    if not GLOBAL.HandleShardFunction[data.key] then return end
    GLOBAL.HandleShardFunction[data.key](data)
    local shard_id = GLOBAL.TheWorld and GLOBAL.TheWorld.shardid
    if onlymaster then return end
    for shard, _ in pairs(GLOBAL.Shard_GetConnectedShards()) do
        if shard ~= shard_id then
            local json = GLOBAL.json.encode(data)
            SendModRPCToShard(GetShardModRPC("bernie_rpc_shard_function", "content"), shard, json)
        end
    end
end
