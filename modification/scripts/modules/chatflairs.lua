print('[Bernie] Starting Chat-Flairs module')

local isclient = not GLOBAL.TheNet:IsDedicated()

if isclient then
    local flairs = GLOBAL.LoadConfig("flairs.lua") or {}
    for flair, content in pairs(flairs) do
        table.insert(Assets, Asset("IMAGE", "images/profileflair_" .. flair .. ".tex"))
        table.insert(Assets, Asset("ATLAS", "images/profileflair_" .. flair .. ".xml"))
    end

    local old_GetProfileFlairAtlasAndTex = GLOBAL.GetProfileFlairAtlasAndTex
    GLOBAL.GetProfileFlairAtlasAndTex = function(item_key)
        if item_key and type(item_key) == "string" then
            local flair = item_key:gsub("profileflair_", "")
            if flairs[flair] then return ("images/" .. item_key .. ".xml"), (item_key .. ".tex"), "profileflair_none.tex" end
        end
        return old_GetProfileFlairAtlasAndTex(item_key)
    end

    if GLOBAL.ChatHistory and not GLOBAL.ChatHistory._bernie_colour_patch then
        GLOBAL.ChatHistory._bernie_colour_patch = true
        local old_GenerateChatMessage = GLOBAL.ChatHistory.GenerateChatMessage
        function GLOBAL.ChatHistory:GenerateChatMessage(chat_type, sender_userid, sender_netid, sender_name, message, colour, icondata, whisper, localonly, text_filter_context)
            local result = old_GenerateChatMessage(self, chat_type, sender_userid, sender_netid, sender_name, message, colour, icondata, whisper, localonly, text_filter_context)
            if result and result.type == GLOBAL.ChatTypes.Message and (sender_name == "" or sender_name == " ") then result.m_colour = result.s_colour or colour or { 0.8706, 0.5725, 0.3843, 1 } end
            return result
        end
    end

    local function NormalizeColour(colour)
        if not colour then return { 0.8706, 0.5725, 0.3843, 1 } end
        if colour.r then return { colour.r or 1, colour.g or 1, colour.b or 1, colour.a or 1, } end
        return { colour[1] or 1, colour[2] or 1, colour[3] or 1, colour[4] or 1, }
    end

    GLOBAL.ShowCustomMessage = function(value)
        if not GLOBAL.ChatHistory then return end
        local profile = value.profile or flairs[value.type] or {}
        local name = value.name or " "
        local message = value.message or "hello"
        if value.colour then value.colour = NormalizeColour(value.colour) end
        local colour = value.colour or profile.colour or { 0.8706, 0.5725, 0.3843, 1 }
        local flair = value.flair or profile.flair
        local chattype = value.chattype or "message"
        if value.talker then
            local inst = GLOBAL.Ents[value.talker]
            if inst and inst:IsValid() and inst.components.talker then inst.components.talker:Say(message, nil, nil, nil, nil, colour) end
        end
        if chattype == "message" then
            GLOBAL.ChatHistory:AddToHistory(GLOBAL.ChatTypes.Message, nil, nil, name, message, colour, flair, false, false, TEXT_FILTER_CTX_CHAT)
        elseif chattype == "whisper" then
            GLOBAL.ChatHistory:AddToHistory(GLOBAL.ChatTypes.Message, nil, nil, name, message, colour, flair, true, true, TEXT_FILTER_CTX_CHAT)
        end
    end

    local clienteventhandler = {}
    clienteventhandler.blink = function()
        if not GLOBAL.ThePlayer or not GLOBAL.TheFrontEnd then return end
        local fadetime = 0.5
        GLOBAL.TheFrontEnd:Fade(false, 0)
        GLOBAL.ThePlayer:DoTaskInTime(0, function()
            GLOBAL.TheFrontEnd:Fade(true, fadetime)
        end)
    end

    clienteventhandler.overlay = function(data)
        if not GLOBAL.ThePlayer or not GLOBAL.ThePlayer.HUD then return end
        if GLOBAL.ThePlayer.HUD[data.overlay] then
            if data.value == true then
                GLOBAL.ThePlayer.HUD[data.overlay]:Show()
            else
                GLOBAL.ThePlayer.HUD[data.overlay]:Hide()
            end
        end
    end

    GLOBAL.ClientEventHandler.message = function(data)
        print(data)
        if data.sound and GLOBAL.ThePlayer then GLOBAL.ThePlayer.SoundEmitter:PlaySound(data.sound) end
        if data.event and GLOBAL.ThePlayer and clienteventhandler[data.event] then clienteventhandler[data.event]() end
        if data.overlay and GLOBAL.ThePlayer then clienteventhandler.overlay(data) end
        GLOBAL.ShowCustomMessage(data)
    end
else
    GLOBAL.HandleShardFunction.message = function(data)
        if not data then return end
        print("[Log] Sending chat message: " .. data.message)
        if not data.userid then
            for _, player in ipairs(GLOBAL.AllPlayers) do
                if player and player:IsValid() then
                    SendModRPCToClient(GetClientModRPC("bernie_client_rpc", "content"), player.userid, GLOBAL.json.encode(data))
                    return
                end
            end
        else
            for _, player in ipairs(GLOBAL.AllPlayers) do
                if player and player:IsValid() and player.userid == data.userid then
                    SendModRPCToClient(GetClientModRPC("bernie_client_rpc", "content"), player.userid, GLOBAL.json.encode(data))
                    return
                end
            end
        end
    end
end
