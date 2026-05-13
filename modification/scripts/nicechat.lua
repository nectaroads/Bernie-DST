print('[Bernie] Starting Nice-Chat module')

Assets = { Asset("IMAGE", "images/profileflair_ashley.tex"), Asset("ATLAS", "images/profileflair_ashley.xml"), Asset("IMAGE", "images/profileflair_bernie.tex"), Asset("ATLAS", "images/profileflair_bernie.xml"), Asset("IMAGE", "images/profileflair_willow.tex"), Asset("ATLAS", "images/profileflair_willow.xml"), Asset("IMAGE", "images/profileflair_global.tex"), Asset("ATLAS", "images/profileflair_global.xml"), Asset("IMAGE", "images/profileflair_private.tex"), Asset("ATLAS", "images/profileflair_private.xml"), Asset("IMAGE", "images/profileflair_discord.tex"), Asset("ATLAS", "images/profileflair_discord.xml"), Asset("IMAGE", "images/profileflair_staffdiscord.tex"), Asset("ATLAS", "images/profileflair_staffdiscord.xml"), Asset("IMAGE", "images/profileflair_server.tex"), Asset("ATLAS", "images/profileflair_server.xml") }

local flairProfiles = {
    ashley = { name = "Ashley", colour = { 0.173, 0.463, 0.604, 1 }, flair = "profileflair_ashley" },
    bernie = { name = "Bernie", colour = { 0.502, 0.349, 0.235, 1 }, flair = "profileflair_bernie" },
    willow = { name = "Willow", colour = { 0.612, 0.188, 0.212, 1 }, flair = "profileflair_willow" },
    global = { name = "Global", colour = { 0.278, 0.651, 0.451, 1 }, flair = "profileflair_global" },
    private = { name = "Private", colour = { 0.447, 0.463, 0.529, 1 }, flair = "profileflair_private" },
    discord = { name = "Discord", colour = { 0.549, 0.596, 0.855, 1 }, flair = "profileflair_discord" },
    staff = { name = "Staff", colour = { 0.8706, 0.5725, 0.3843, 1 }, flair = "profileflair_staffdiscord" },
    server = { name = "Server", colour = { 0.298, 0.251, 0.263, 1 }, flair = "profileflair_server" }
}

local old_GetProfileFlairAtlasAndTex = GLOBAL.GetProfileFlairAtlasAndTex
GLOBAL.GetProfileFlairAtlasAndTex = function(item_key)
    if item_key and type(item_key) == "string" then
        local flair = item_key:gsub("profileflair_", "")
        if flairProfiles[flair] then
            local atlas = "images/" .. item_key .. ".xml"
            return atlas, item_key, "profileflair_none"
        end
        return old_GetProfileFlairAtlasAndTex(item_key)
    end
    return old_GetProfileFlairAtlasAndTex(item_key)
end

GLOBAL.custommessage = nil

-- God toasting dammit that took toasting 6 toasting hours, toast.
require("chathistory")

if GLOBAL.ChatHistory and not GLOBAL.ChatHistory._bernie_colour_patch then
    GLOBAL.ChatHistory._bernie_colour_patch = true
    local old_GenerateChatMessage = GLOBAL.ChatHistory.GenerateChatMessage
    function GLOBAL.ChatHistory:GenerateChatMessage(chat_type, sender_userid, sender_netid, sender_name, message, colour, icondata, whisper, localonly, text_filter_context)
        local result = old_GenerateChatMessage(self, chat_type, sender_userid, sender_netid, sender_name, message, colour, icondata, whisper, localonly, text_filter_context)
        if result and result.type == GLOBAL.ChatTypes.Message then
            if sender_name == "" or sender_name == " " or sender_name == "debug" then
                result.m_colour = result.s_colour or colour
            end
        end
        return result
    end
end

local function NormalizeColour(colour)
    if not colour then return nil end
    if colour.r then return { colour.r or 1, colour.g or 1, colour.b or 1, colour.a or 1, } end
    return { colour[1] or 1, colour[2] or 1, colour[3] or 1, colour[4] or 1, }
end

GLOBAL.ShowCustomMessage = function(value)
    if not GLOBAL.ThePlayer then return end

    local profile = value.profile or flairProfiles[value.type] or {}
    local name = value.name or "" --profile.name
    local message = value.message or "hello"
    if value.colour then value.colour = NormalizeColour(value.colour) end
    local colour = value.colour or profile.colour
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

clienteventhandler.blink = function(data)
    if not GLOBAL.ThePlayer or not GLOBAL.TheFrontEnd then return end
    local count = data.count or 1
    local rate = data.rate or 0.15
    local blacktime = data.blacktime or 0.04
    local fadetime = data.fadetime or 0.15
    for i = 0, count do
        GLOBAL.ThePlayer:DoTaskInTime(i * rate, function()
            GLOBAL.TheFrontEnd:Fade(false, 0)
            GLOBAL.ThePlayer:DoTaskInTime(blacktime, function()
                GLOBAL.TheFrontEnd:Fade(true, fadetime)
            end)
        end)
    end
end

local function DecodeRPCData(payload)
    if type(payload) == "table" then return payload end
    if type(payload) == "string" then
        local ok, data = GLOBAL.pcall(GLOBAL.json.decode, payload)
        if ok then return data end
    end
    return nil
end

function HandleClientChatMessage(payload)
    if not GLOBAL.TheWorld then return end
    local data = DecodeRPCData(payload)
    if not data then return end
    if data.event and clienteventhandler[data.event] then clienteventhandler[data.event](data) end
    GLOBAL.ShowCustomMessage(data)
end

AddClientModRPCHandler("bernie_rpc_client_message", "content", HandleClientChatMessage)
