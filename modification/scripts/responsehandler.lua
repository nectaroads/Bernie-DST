print('[Bernie] Starting Response-Handler module')

local HandleServerResponse = {}

HandleServerResponse["bernie_rpc_client_message"] = function(data)
    GLOBAL.ExecuteOnAllShards(data)
end

HandleServerResponse.puppet = function(data)
    GLOBAL.ExecuteOnAllShards(data)
end

HandleServerResponse.kick = function(data)
    GLOBAL.ExecuteConsoleCommand("TheNet:Kick(\"" .. data.target .. "\")")
end

HandleServerResponse.ban = function(data)
    GLOBAL.ExecuteConsoleCommand("TheNet:BanForTime(\"" .. data.target .. "\", " .. data.duration .. ")")
end

HandleServerResponse.regenerate = function(data)
    GLOBAL.ExecuteConsoleCommand("c_regenerateworld()")
end

HandleServerResponse.rollback = function(data)
    GLOBAL.ExecuteConsoleCommand(string.format("c_rollback(%d)", data.quantity))
end

HandleServerResponse.terminal = function(data)
    GLOBAL.ExecuteOnAllShards(data)
end

HandleServerResponse.companion = function(data)
    GLOBAL.ExecuteOnAllShards(data, true)
end

function SendUpdateRequest()
    local jsonClient = GLOBAL.json.encode({ key = "update" })
    GLOBAL.TheSim:QueryServer(GLOBAL.serverUrl, function(result, isSuccessful, resultCode)
        if not (isSuccessful and resultCode == 200 and result) then return end
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

AddPrefabPostInit("world", function(inst)
    if GLOBAL.TheWorld:HasTag("cave") then return end
    inst:DoPeriodicTask(1, function()
        SendUpdateRequest()
    end)
end)
