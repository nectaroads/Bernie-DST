local GLOBAL = GLOBAL or _G

print('[Bernie] Starting Client-Manager Module...')

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
    ShowCustomMessage({ type = data.type, message = data.message, name = data.name or nil })
end

function ShowWelcomeMessage(inst)
    GLOBAL.TheFrontEnd:PushScreen(require("screens/bigpopupdialog")(
        "\n\n\n\nAtenção, " .. GLOBAL.TheNet:GetLocalUserName() .. "!",
        "\n\nO servidor se diferencia criando cenários mais difíceis. Isso implica que o jogo foi rebalanceado para esse papel.  Também contamos com anticheats, evite visão-noturna!",
        {
            {
                text = "Sair",
                cb = function()
                    GLOBAL.DoRestart(true)
                end
            },
            {
                text = "Concordo",
                cb = function()
                    GLOBAL.TheFrontEnd:PopScreen()

                    GLOBAL.TheFrontEnd:PushScreen(require("screens/textlistpopupdialog")(
                        "\n\nPrincipais mudanças:",
                        { "", "1) Gigantes causam dano em área.", "2) Fome, frio e calor te enfraquecem.", "3) Toadstool mais frágil e devagar.", "4) Sombras mais perigosas!", "5) Pedras térmicas mais fracas.", "6) Dragonfly e Beequeen desviáveis.", "7) Deerclops mais resistente."},
                        nil,
                        {{ 
                            text = "OK", 
                            cb = function() 
                                GLOBAL.TheFrontEnd:PopScreen() 
                            end 
                        }}
                    ))
                end
            }
        }
    ))
end

function OnEnterCharacterSelect(inst)
    ShowWelcomeMessage(inst)
end

function OnWorldPostInit(inst)
    inst:ListenForEvent("entercharacterselect", OnEnterCharacterSelect)
end

AddPrefabPostInit("world", OnWorldPostInit)

GLOBAL.cammaxdistpitch = 60
GLOBAL.lastdistance = 30

local function BindKey(key, func)
    if type(key) == "string" then
        GLOBAL.TheInput:AddKeyUpHandler(key:lower():byte(), func)
    elseif key > 0 then
        GLOBAL.TheInput:AddKeyUpHandler(key, func)
    end
end

local function AddPitch(value)
    if GLOBAL.TheCamera then
        local camera = GLOBAL.TheCamera
        if value > 0 then
            camera.maxdistpitch = math.min(camera.maxdistpitch + value, 60)
        else
            camera.maxdistpitch = math.max(camera.maxdistpitch + value, 40)
        end
        GLOBAL.cammaxdistpitch = camera.maxdistpitch
        if GLOBAL.ThePlayer.components.talker then
            GLOBAL.ThePlayer.components.talker:Say("Pitch em " .. camera.maxdistpitch .. " (Padrão 60)")
        end
    end
end

BindKey(290, function() AddPitch(-5) end)
BindKey(291, function() AddPitch(5) end)

AddClassPostConstruct("screens/playerhud", function(self) self.UpdateClouds = function() end end)
AddComponentPostInit("focalpoint", function(self, inst) self.StartFocusSource = function() end end)

AddClassPostConstruct("cameras/followcamera", function(self)
    local FollowCameraSetDefault = self.SetDefault
    self.SetDefault = function(self)
        FollowCameraSetDefault(self)
        self.targetpos = GLOBAL.Vector3(0, 0, 0)
        self:SetDefaultOffset()
        if self.headingtarget == nil then
            self.headingtarget = 45
        end
        self.fov = 35
        self.pangain = 4
        self.headinggain = 20
        self.distancegain = 1
        self.zoomstep = 8
        self.mindist = 10
        self.maxdist = 43
        self.distancetarget = GLOBAL.lastdistance
        self.mindistpitch = 30
        self.maxdistpitch = GLOBAL.cammaxdistpitch
        self.shake = nil
        if self.gamemode_defaultfn then
            self.gamemode_defaultfn(self)
        end
        if self.target ~= nil then
            self:SetTarget(self.target)
        end
    end

    self.ZoomIn = function(self, step)
        self.distancetarget = math.max(self.mindist, self.distancetarget - (step or self.zoomstep))
        GLOBAL.lastdistance = self.distancetarget
    end

    self.ZoomOut = function(self, step)
        self.distancetarget = math.min(self.maxdist, self.distancetarget + (step or self.zoomstep))
        GLOBAL.lastdistance = self.distancetarget
    end
end)

AddGlobalClassPostConstruct("camerashake", "CameraShake", function(self)
    local oldStartShake = self.StartShake
    function self:StartShake(type, duration, speed, scale, ...)
        return oldStartShake(self, type, duration, speed, (scale or 1) * 0.5, ...)
    end
end)

local function CheckPlayer(inst)
    inst:DoPeriodicTask(1, function()
        local headitem = nil
        local camera = GLOBAL.TheCamera

        local enablednightvision = false
        local allowednightvision = false
        local invaliddistancevision = false
        local invalidfovvision = false
        
        if inst.replica then headitem = inst.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HEAD) end

        if inst.components.playervision then
            if inst.components.playervision.forcenightvision or inst.components.playervision:HasNightVision() then enablednightvision = true end
        end

        if headitem ~= nil and inst.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HEAD):HasTag("nightvision") then allowednightvision = true end
        if inst.components.playervision.forcednightvisionstack and inst.components.playervision.forcednightvisionstack[1] then allowednightvision = true end

        if camera.fov > 35 then invalidfovvision = true end

        local distancevisionhelmets = { scrap_monoclehat = true }
        if  camera.maxdist > 43 then
            local limit = 43
            if headitem ~= nil and distancevisionhelmets[headitem.prefab] then limit = limit + 20 end
            if camera.maxdist > limit then invaliddistancevision = true end
        end

        if enablednightvision == true and allowednightvision == false then
            inst.components.playervision.forcenightvision = false
            inst:PushEvent("nightvision", false)
        end

        if invaliddistancevision == true then
            if headitem ~= nil and distancevisionhelmets[headitem.prefab] then
                camera.maxdist = 63
            else
                camera.maxdist = 43
            end
        end

        if invalidfovvision == true then camera.fov = 35 end
    end)
end

AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(0, function()
        if (inst == GLOBAL.ThePlayer) then
            inst:DoTaskInTime(0, CheckPlayer)
            ShowCustomMessage({ type = "discord", message = "Tem alguma dúvida? Junte-se ao nosso Discord: discord.gg/37yfuWjyj7" })
        end
    end)
end)

AddClientModRPCHandler("bernieservertoclientchatmessage", "content", HandleClientChatMessage)

print('[Bernie] Finished loading!')
