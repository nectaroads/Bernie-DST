local GLOBAL = GLOBAL or _G

print('[Bernie] Starting Client-Manager Module...')

Popups = require("GUI/popups")

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
        if flairProfiles[flair] then return "images/" .. item_key .. ".xml", item_key, "profileflair_none" end
        return old_GetProfileFlairAtlasAndTex(item_key)
    end
    return old_GetProfileFlairAtlasAndTex(item_key)
end

function ShowCustomMessage(value)
    local profile = flairProfiles[value.type]
    if not profile then return end
    GLOBAL.ChatHistory:AddToHistory(GLOBAL.ChatTypes.Message, nil, nil, value.name or profile.name, value.message, profile.colour, profile.flair, false, false, TEXT_FILTER_CTX_CHAT)
end

function HandleClientChatMessage(json)
    if not (GLOBAL.TheWorld) then return end
    local data = type(json) == "table" and json or GLOBAL.json.decode(json) or nil
    if not data or not data.type or not data.message then return end
    ShowCustomMessage({ type = data.type, message = data.message })
end

function ShowWelcomeMessage(inst)
    Popups.CreateChoicePopup("Bem-vindo(a), " .. GLOBAL.TheNet:GetLocalUserName() .. "!", "1. Saiba que esse servidor é REBALANCEADO. Isso significa que terá que se adaptar a cenários mais difíceis.\n2. Existe sistemas anti-cheat funcionando. Evite Visão-noturna, Speed-hack, Super-zoom, etc.", nil, nil, "original", "small", "light")
end

function OnEnterCharacterSelect(inst)
    ShowWelcomeMessage(inst)
end

function OnWorldPostInit(inst)
    inst:ListenForEvent("entercharacterselect", OnEnterCharacterSelect)
end

AddPrefabPostInit("world", OnWorldPostInit)

AddClientModRPCHandler("bernieclientchatmessage", "content", HandleClientChatMessage)

print('[Bernie] Finished loading!')
