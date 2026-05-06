local GLOBAL = GLOBAL or _G
local EventHandler = GLOBAL.EventHandler
local Combat = require("components/combat")

print('[Bernie] Starting Server-Manager Module...')

local serverUrl = "http://localhost:24574/bernie"
local chatCommandPrefix = ">"

GLOBAL.AddClientModRPCHandler("bernieservertoclientchatmessage", "content", function() end)
local CLIENTCHATMESSAGE_RPC = GLOBAL.GetClientModRPC("bernieservertoclientchatmessage", "content")

local attackCooldown = 0.460
local attackCooldowns = {}

local backpackPrefabs = { "backpack", "piggyback", "krampus_sack", "icepack", "seedpouch", "spicepack", "candybag" }
local cachedPortal = nil

local currentCycle = -1

local lasthit = { daywalker = nil, daywalker2 = nil, sharkboi = nil }
local bosseswithcounters = { dragonfly = true, klaus = true }
local bosses = { alterguardian_phase1_lunarrift = true, alterguardian_phase4_lunarrift = true, wagboss_robot = true, alterguardian_phase3 = true, antlion = true, bearger = true, beequeen = true, crabking = true, daywalker = true, daywalker2 = true, deerclops = true, dragonfly = true, eyeofterror = true, klaus = true, malbatross = true, minotaur = true, moose = true, mutatedbearger = true, mutateddeerclops = true, mutatedwarg = true, shadow_bishop = true, shadow_knight = true, shadow_rook = true, sharkboi = true, stalker_atrium = true, toadstool = true, toadstool_dark = true, twinofterror1 = true, twinofterror2 = true }
local bossesnames = { alterguardian_phase1_lunarrift = "Celestial Revenant", alterguardian_phase4_lunarrift = "Celestial Scion", wagboss_robot = "W.A.R.B.O.T", mock_dragonfly = "Wilting Dragonfly", mothergoose = "The Mother Goose", moonmaw_dragonfly = "Moonmaw Dragonfly", hoodedwidow = "The Hooded Widow", eyeofterror = "The Eye of Terror", dragonfly = "Mother Dragonfly", moose = "The Moose/Goose", bearger = "Dormant Bearger", mutatedbearger = "Armored Bearger", enraged_klaus = "Vengeful Klaus ⚠", mutateddeerclops = "Crystal Deerclops", twinofterror2 = "Hungry Spazmatism", antlion = "Desert Antlion", toadstool_dark = "Misery Toadstool ⚠", enraged_dragonfly = "Burning Dragonfly ⚠", twinofterror1 = "Seeker Retinazor", stalker_atrium = "Ancient Fuelweaver", sharkboi = "Defiant Frostjaw", mutatedwarg = "Possessed Warg", shadow_knight = "Shadow Knight", shadow_bishop = "Shadow Bishop", beequeen = "Royal Bee Queen", crabking = "Mighty Crab King", deerclops = "Chilling Deerclops", daywalker = "Nightmare Werepig", minotaur = "Ancient Guardian", daywalker2 = "Scrappy Werepig", malbatross = "Flying Malbatross", shadow_rook = "Shadow Rook", klaus = "Wicked Klaus", toadstool = "Grotto Toadstool", alterguardian_phase3 = "Celestial Champion" }
local foodlist = { minotaurhorn = true, deerclops_eyeball = true, mandrake = true, cookedmandrake = true, mandrakesoup = true, gears = true, royal_jelly = true, glommerfuel = true }
local bossenragedtimer = {}
local bossdamage = {}
local bossdamagehistory = {}

function SendRequest(json)
    GLOBAL.TheSim:QueryServer(serverUrl, function(result, isSuccessful, resultCode)
        if not (isSuccessful and resultCode == 200 and result) then return end
    end, "POST", json)
end

function GetUsers()
    local users = {}
    local client_table = GLOBAL.TheNet:GetClientTable()
    if client_table then
        for _, client in ipairs(client_table) do
            if not client.performance and client.userid and client.name then
                users[client.userid] = { name = client.name or nil, userid = client.userid, guid = client.GUID or nil, prefab = client.prefab or nil, admin = client.admin or false }
            end
        end
    end
    return users
end

function SendModRPCToClient(namespace, userid, json)
    if not GLOBAL.TheWorld then return end
    GLOBAL.TheWorld:DoTaskInTime(0, function()
        GLOBAL.SendModRPCToClient(namespace, userid, json)
    end)
end

local function FindMultiplayerPortal()
    if cachedPortal ~= nil and cachedPortal:IsValid() then
        return cachedPortal
    end
    local ents = GLOBAL.TheSim:FindEntities(0, 0, 0, 10000, nil, nil)
    for _, ent in ipairs(ents) do
        if ent.prefab == "multiplayer_portal" or ent.prefab == "multiplayer_portal_moonrock" then
            cachedPortal = ent
            return ent
        end
    end
    return nil
end

function HandleShardFunction(key, value)
    if key == "playercontroller" then
        for _, player in ipairs(GLOBAL.AllPlayers) do
            if player.userid == value.userid then
                if value.message then
                    if player.components.talker then player.components.talker:Say(value.message, 3) end
                end
                if value.animation then
                    if player.sg and player.sg:HasStateTag("idle") then player:PushEvent("emote", { anim = value.animation }) end
                end
                if value.soundeffect then
                    if player.SoundEmitter then player.SoundEmitter:PlaySound(value.soundeffect) end
                end
            end
        end
    elseif key == "terminal" then
        GLOBAL.ExecuteConsoleCommand(value.message)
    elseif key == "kill" then
        for _, player in ipairs(GLOBAL.AllPlayers) do
            if player.SoundEmitter then player.SoundEmitter:PlaySound("dontstarve/quagmire/HUD/new_recipe") end
            if player.sg and player.sg:HasStateTag("idle") then player:PushEvent("emote", { anim = "emote_jumpcheer" }) end
        end
    elseif key == "clientchatmessage" then
        if value.userid then
            local json = GLOBAL.json.encode({ type = value.type, message = value.message, name = value.name or nil })
            if json then
                SendModRPCToClient(CLIENTCHATMESSAGE_RPC, value.userid, json)
            end
            return
        end
        local users = GetUsers()
        for _, player in pairs(users) do
            if player and player.userid then
                local json = GLOBAL.json.encode({ type = value.type, message = value.message, name = value.name or nil })
                if json then
                    SendModRPCToClient(CLIENTCHATMESSAGE_RPC, player.userid, json)
                end
            end
        end
    end
end

function ExecuteOnAllShards(key, value)
    HandleShardFunction(key, value)
    local shard_id = GLOBAL.TheWorld and GLOBAL.TheWorld.shardid
    for shard, _ in pairs(GLOBAL.Shard_GetConnectedShards()) do
        if shard ~= shard_id then
            local json = GLOBAL.json.encode(value)
            SendModRPCToShard(GetShardModRPC("bernieshardfunction", "content"), shard, key, json)
        end
    end
end

AddShardModRPCHandler("bernieshardfunction", "content", function(_, key, json)
    local value = GLOBAL.json.decode(json)
    HandleShardFunction(key, value)
end)

function HandleChatCommands(guid, userid, name, prefab, message, colour, whisper, isemote, iscave)
    if not message or #message == 0 then return false end
    local trimmed_message = message:match("^%s*(.-)%s*$")
    if (trimmed_message == "") then return false end
    local prefix = trimmed_message:sub(1, 1)
    local command = trimmed_message:sub(2):match("^%s*(.-)%s*$")
    if prefix ~= chatCommandPrefix then return false end
    return true
end

function OnNetworkingSay(guid, userid, name, prefab, message, colour, whisper, isemote, iscave)
    if HandleChatCommands(guid, userid, name, prefab, message, colour, whisper, isemote, iscave) then return end
    local jsonEncoded = GLOBAL.json.encode({ key = "message", userid = userid, username = name, prefab = prefab, message = message, whisper = whisper, cave = iscave })
    SendRequest(jsonEncoded)
end

local function OnPlayerItemGet(inst, data)
    if not (data.item and data.item:HasTag("backpack")) then return end
    local equippedBackpack = inst.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.BODY)
    if equippedBackpack and not equippedBackpack:HasTag("backpack") then equippedBackpack = nil end
    if equippedBackpack and data.item then
        inst.components.inventory:DropItem(equippedBackpack, true, true)
        inst.components.inventory:Equip(data.item)
    end
    local backpackCount = 0
    for _, item in pairs(inst.components.inventory.itemslots) do
        if item and item:HasTag("backpack") then
            if backpackCount >= 1 or equippedBackpack then inst.components.inventory:DropItem(item, true, true) end
            backpackCount = backpackCount + 1
        end
    end
end

local function OnPlayerEquip(inst, data)
    if not (data and data.item) then return end
    if not data.item:HasTag("backpack") then return end
    for _, item in pairs(inst.components.inventory.itemslots) do
        if item and item:HasTag("backpack") then inst.components.inventory:DropItem(item, true, true) end
    end
    local activeItem = inst.components.inventory.activeitem
    if activeItem and activeItem:HasTag("backpack") then inst.components.inventory:DropItem(activeItem, true, true) end
end

local function OnPlayerAttacked(inst, data)
    if not (data.damage and data.damage > 8) then return end
    if math.random() <= 0.9 then return end
    for _, item in pairs(inst.components.inventory.itemslots) do
        if item and item:HasTag("backpack") then
            inst.components.inventory:DropItem(item, true, true)
            if inst.SoundEmitter then inst.SoundEmitter:PlaySound("yotb_2021/common/hitching_post/unhitching") end
            break
        end
    end
    local activeItem = inst.components.inventory.activeitem
    if activeItem and activeItem:HasTag("backpack") then inst.components.inventory:DropItem(activeItem, true, true) end
end

AddSimPostInit(function()
    if GLOBAL.TheWorld then
        local NETWORKING_SAY = GLOBAL.Networking_Say
        GLOBAL.Networking_Say = function(guid, userid, name, prefab, message, colour, whisper, isemote)
            OnNetworkingSay(guid, userid, name, prefab, message, colour, whisper, isemote, GLOBAL.TheWorld:HasTag("cave"))
            return NETWORKING_SAY(guid, userid, name, prefab, message, colour, whisper, isemote)
        end
    end
    AddPlayerPostInit(function(inst)
        inst:ListenForEvent("itemget", OnPlayerItemGet)
        inst:ListenForEvent("equip", OnPlayerEquip)
        inst:ListenForEvent("attacked", OnPlayerAttacked)
        inst:DoPeriodicTask(3, function(inst)
            local temp = inst.components.temperature
            local hunger = inst.components.hunger
            if temp ~= nil and hunger ~= nil then
                if not temp:IsFreezing() and not temp:IsOverheating() then return end
                hunger:DoDelta(-1, nil, "temperature_penalty")
            end
        end)
    end)
end)

local function OnBackpackPostInit(inst)
    if not inst.components.inventoryitem then inst:AddComponent("inventoryitem") end
    inst.components.inventoryitem.cangoincontainer = true
    inst.components.inventoryitem:SetOnPutInInventoryFn(function(inst, owner)
        if not (owner and owner.components.container and owner ~= inst.components.inventory) then return end
        inst:DoTaskInTime(0, function()
            if owner:HasTag("pocketdimension_container") then
                local portal = FindMultiplayerPortal() or nil
                if portal ~= nil then
                    local x, y, z = portal.Transform:GetWorldPosition()
                    owner.components.container:DropItem(inst, true, true)
                    inst.Transform:SetPosition(x, y, z)
                    local effect = GLOBAL.SpawnPrefab("woby_dash_shadow_fx")
                    effect.Transform:SetPosition(x, y, z)
                end
                return
            end
            owner.components.container:DropItem(inst, true, true)
        end)
    end)
end

for _, prefab in ipairs(backpackPrefabs) do
    AddPrefabPostInit(prefab, OnBackpackPostInit)
end

local function OnPrototyperPostInit(inst)
    local oldSetRadius = inst.SetRadius
    function inst:SetRadius(radius)
        oldSetRadius(inst, radius * 2)
    end
end

AddComponentPostInit("prototyper", OnPrototyperPostInit)

local function OnPoopPostInit(inst, data)
    inst:DoTaskInTime(0, function()
        inst:AddTag("icebox_valid")
    end)
end

AddPrefabPostInit("poop", OnPoopPostInit)
AddPrefabPostInit("guano", OnPoopPostInit)

local function OnMermKingPostInit(inst)
    inst:DoTaskInTime(0, function()
        if not GLOBAL.TheWorld.ismastersim then return end
        inst.CallGuards = function() end
    end)
end

AddPrefabPostInit("mermking", OnMermKingPostInit)

local customPigNames = { "Pigloom", "Lalachinus", "Alfacius", "Malia" }

local function OnPigmanPostInit(inst)
    inst:DoTaskInTime(0, function()
        if not inst or inst:HasTag("customname") or not inst.components.named then return end
        if not (inst and inst.components.named) then return end
        local dice = math.random(0, 9)
        if dice <= 2 then inst.components.named:SetName(customPigNames[math.random(#customPigNames)]) end
        inst:AddTag("customname")
    end)
end

AddPrefabPostInit("pigman", OnPigmanPostInit)

local function DamageRider(rider, total_damage)
    if not (rider and rider.components and rider.components.health and rider.components.inventory) then return end
    if rider.components.health:IsDead() then return end
    local slots = { GLOBAL.EQUIPSLOTS.HEAD, GLOBAL.EQUIPSLOTS.BODY, GLOBAL.EQUIPSLOTS.HANDS }
    local remaining_damage = total_damage
    for _, slot in ipairs(slots) do
        local item = rider.components.inventory:GetEquippedItem(slot)
        if item and item.components.armor then
            local absorb = item.components.armor.absorb_percent or 0
            local absorb_damage = total_damage * absorb
            item.components.armor:TakeDamage(absorb_damage * (item.components.armor.condition / item.components.armor.maxcondition))
            remaining_damage = remaining_damage - absorb_damage
        end
    end
    if remaining_damage > 0 then
        rider.components.health:DoDelta(-remaining_damage, nil, "beefalo_impact")
    end
end

local function OnBeefaloPostInit(inst, data)
    inst:DoTaskInTime(0, function()
        inst:ListenForEvent("obediencedelta", function(inst)
            local tamed = inst.components.domesticatable:IsDomesticated() or
                inst.components.domesticatable:GetDomestication() > 0
            local poop_spawner = inst.components.periodicspawner
            if tamed and poop_spawner then poop_spawner:Stop() end
        end)
        inst:ListenForEvent("goneferal", function(inst)
            local poop_spawner = inst.components.periodicspawner
            if poop_spawner then poop_spawner:Start() end
        end)
        inst:ListenForEvent("attacked", function(beef, data)
            if data and data.damage and beef.components.rideable then
                local rider = beef.components.rideable:GetRider()
                if rider then
                    local damage_to_rider = (data.damage or 1) * 0.5
                    DamageRider(rider, damage_to_rider)
                    if rider.prefab == "walter" then
                        beef.components.rideable:Buck()
                    end
                end
            end
        end)
    end)
end

AddPrefabPostInit("beefalo", OnBeefaloPostInit)

local propaganda = { 
    "Sabia que estercos podem ser colocados em geladeiras?", 
    "Cuidado! Beefalos distribuem dano para quem está acima dele.",
    "Walter não consegue manter equilíbrio em Beefalos.",
    "Alguns porcos possuem nomes especiais de jogadores...",
    "Junte-se ao nosso Discord: discord.gg/37yfuWjyj7",
    "Evite mods como Visão-noturna, Zoom e etc.",
    "Mochilas podem ser colocadas em seu inventário!",
    "Reis Merm não chamam ajuda quando são golpeados, Constant os abandonou!",
    "Você enfraquece quando sente frio, calor ou fome...",
    "Qualquer coisa congelada recebe dano extra!",
    "Sombras são mais perigosas por aqui...",
    "Os gigantes se comportam diferente, tome cuidado!",
    "Jogadores isolados causam mais dano em gigantes.",
    "Não fique na escuridão, Grue está mais violento.",
    "Gigantes possuem armadura adaptativa, mas Sobreviventes são imunes!"
}

local function HandleServerResponse(array)
    for _, entry in ipairs(array) do
        if entry.key then
            if entry.key == "message" then
                ExecuteOnAllShards("clientchatmessage", entry.value)
            elseif entry.key == "playercontroller" then
                ExecuteOnAllShards("playercontroller", entry.value)
            elseif entry.key == "kick" then
                GLOBAL.ExecuteConsoleCommand("TheNet:Kick(\"" .. entry.value.userid .. "\")")
            elseif entry.key == "ban" then
                GLOBAL.ExecuteConsoleCommand("TheNet:BanForTime(\"" .. entry.value.userid .. "\", " .. entry.value.duration .. ")")
            elseif entry.key == "userlist" then
                local users = GetUsers()
                local jsonEncoded = GLOBAL.json.encode({ key = "userlist", users = users, interaction = entry.value.interaction })
                SendRequest(jsonEncoded)
            elseif entry.key == "regenerate" then
                GLOBAL.ExecuteConsoleCommand("c_regenerateworld()")
            elseif entry.key == "rollback" then
                GLOBAL.ExecuteConsoleCommand(string.format("c_rollback(%d)", entry.value.quantity))
            elseif entry.key == "terminal" then
                ExecuteOnAllShards("terminal", entry.value)
            elseif entry.key == "ping" then
                GLOBAL.TheNet:Announce(entry.value.message, nil, nil)
            elseif entry.key == "kill" then
                ExecuteOnAllShards("kill")
            end
        end
    end
end

local function SendUpdateRequest()
    local jsonClient = GLOBAL.json.encode({ key = "update" })
    GLOBAL.TheSim:QueryServer(serverUrl, function(result, isSuccessful, resultCode)
        if not (isSuccessful and resultCode == 200 and result) then return end
        local jsonServer = GLOBAL.json.decode(result)
        HandleServerResponse(jsonServer)
    end, "POST", jsonClient)
end

AddPrefabPostInit("world", function(inst)
    if not GLOBAL.TheWorld.ismastersim then return end
    inst:DoPeriodicTask(1, function()
        SendUpdateRequest()
    end)
    inst:DoPeriodicTask(60 * 60, function()
        local rand = math.random(#propaganda)
        local target = propaganda[rand]
        local data = { type = "server", message = target }
        ExecuteOnAllShards("clientchatmessage", data)
    end)
end)

local old_DoAttack = Combat.DoAttack

function Combat:DoAttack(target, weapon, projectile, stimuli, instancemult)
    local inst = self.inst
    if inst:HasTag("epic") then
        local range = self.hitrange or 3
        self:DoAreaAttack(inst, range, weapon, stimuli, nil, nil, instancemult)
        return true
    end
    return old_DoAttack(self, target, weapon, projectile, stimuli, instancemult)
end

-- If something takes damage

local old_GetAttacked = Combat.GetAttacked

function Combat:GetAttacked(attacker, damage, weapon, stimuli, spdamage)
    local inst = self.inst
    local health = self.inst.components.health

    -- Everything takes massive damage if frozen.
    if inst.components.freezable ~= nil and inst.components.freezable:IsFrozen() and damage ~= nil and damage > 0 then
        local health = inst.components.health
        if health then
            local bonus = math.floor(health.maxhealth * 0.05)
            damage = damage + bonus
        end
    end

    -- Helpers list
    if attacker and inst:HasTag("epic") then
        lasthit[inst.prefab] = attacker

        if not bossdamage[inst.GUID] then bossdamage[inst.GUID] = {} end
        if not bossdamagehistory[inst.GUID] then bossdamagehistory[inst.GUID] = {} end
        
        if health.currenthealth >= health.maxhealth then
            bossdamage[inst.GUID] = {}
            bossdamagehistory[inst.GUID] = {}
        else
            bossdamage[inst.GUID][attacker.GUID] = attacker
            table.insert(bossdamagehistory[inst.GUID], attacker)
            if #bossdamagehistory[inst.GUID] > 7 then table.remove(bossdamagehistory[inst.GUID], 1) end
        end
            
        local helpers = bossdamage[inst.GUID]
        local count = 0

        for _, player in pairs(helpers) do 
            if player and player:HasTag("player") then
                count = count + 1
            end
        end

        if attacker:HasTag("player") then 
            if count <= 1 then
                damage = damage * 1.5
            end
        else
            local sameprefab = 0
            for _, hitter in ipairs(bossdamagehistory[inst.GUID]) do
                if hitter and hitter.prefab == attacker.prefab then
                    sameprefab = sameprefab + 1
                end
            end
            local repeats = math.max(0, math.floor((sameprefab - 1) / 3))
            local reduction = math.max(0.1, 1 - (repeats * 0.45))
            damage = damage * reduction
        end
    end

    if inst:HasTag("player") then
        -- Players take extra 3 damage if temperature is not comfy enough.
        if inst.components.temperature ~= nil then
            local temp = inst.components.temperature
            if temp:IsOverheating() or temp:IsFreezing() then
                inst.components.health:DoDelta(-4, nil, "temp_bonus")
            end
        end
        -- Players take extra 3 damage if starving.
        if inst.components.hunger ~= nil then
            if inst.components.hunger:GetPercent() < TUNING.HUNGRY_THRESH then
                inst.components.health:DoDelta(-4, nil, "hunger_bonus")
            end
        end
    end

    if attacker and attacker:HasTag("player") and damage ~= nil and damage > 0 then
        local multiplier = 1
        -- Uncomfy players deal less damage.
        if attacker.components.temperature ~= nil then
            local temp = attacker.components.temperature
            if temp:IsOverheating() or temp:IsFreezing() then multiplier = multiplier * 0.8 end
        end
        -- Starving players deal less damage.
        if attacker.components.hunger ~= nil and attacker.components.hunger:GetPercent() < TUNING.HUNGRY_THRESH then multiplier = multiplier * 0.8 end
        damage = math.floor(damage * multiplier + 0.5)
    end

    return old_GetAttacked(self, attacker, damage, weapon, stimuli, spdamage)
end

AddStategraphPostInit("beeguard", function(sg)
    sg.events.attacked = EventHandler("attacked", function(inst, data)
        if inst.components.health ~= nil and inst.components.health:IsDead() then
            inst.sg:GoToState("death")
            return
        end
    end)
end)

AddStategraphPostInit("dragonfly", function(sg)
    sg.events.stunned = EventHandler("stunned", function(inst)
        if inst.components.health ~= nil and not inst.components.health:IsDead() then
            inst:TransformFire()
            inst.sg:GoToState("idle")
        end
    end)
end)

-- Logger
local function OnEntityDeath(ent, data)
    local inst = ent or (data and data.inst) or data
    local cause = data.cause and data.afflicter or lasthit[inst.prefab] or nil
    if bosses[inst.prefab] then
        local victim = inst.prefab
        if victim == "klaus" and not inst:IsUnchained() then return end
        local doer = cause and cause:GetDisplayName() or "Alguém"
        local userid = cause and cause.userid
        if victim == "stalker_atrium" and (doer == nil) then return end
        local players = GetUsers()
        local helpers = bossdamage[inst.GUID]
        if inst.enraged then
            if bossenragedtimer[inst.prefab] > 30 then
                victim = "enraged_" .. victim
            end
        end
        ExecuteOnAllShards("clientchatmessage", { type = "server", message = "★ " .. bossesnames[victim] .. " foi derrotado ★", whisper = false })

        local helpers_names = {}
        
        if helpers then
            for _, player in pairs(helpers) do
                if player and player.userid then
                    table.insert(helpers_names, {
                        name = player:GetDisplayName(),
                        userid = player.userid
                    })
                end
            end
        end

        local jsonEncoded = GLOBAL.json.encode({ key = "kill", name = bossesnames[victim], victim = victim, doer = doer, userid = userid, players = players, helpers = helpers_names })
        SendRequest(jsonEncoded)
        bossdamage[inst.GUID] = nil
        if bossenragedtimer[inst.prefab] then
            bossenragedtimer[inst.prefab] = 0
        end
    elseif inst.userid then
        local killer = data and data.afflicter or nil
        local killerprefab = nil
        local killername = nil
        if killer and killer.prefab then
            killerprefab = killer.prefab
            killername = GLOBAL.STRINGS.NAMES[string.upper(killerprefab)] or killerprefab
        end
        local users = GetUsers()
        local jsonEncoded = GLOBAL.json.encode({ key = "playerdeath", victim = inst:GetDisplayName(), userid = inst.userid, prefab = inst.prefab, doer = killername or killerprefab or data.cause or "Desconhecido", players = users })
        SendRequest(jsonEncoded)
    end
end

local function OnPlayerDeath(world, data)
    local inst = data.inst
    if not inst then return end
    if not inst.userid then return end
    local killer = data and data.afflicter or nil
    local cause = data and data.cause
    local killerprefab = nil
    local killername = nil
    if type(killer) == "table" and killer.prefab then
        killerprefab = killer.prefab
        killername = GLOBAL.STRINGS.NAMES[string.upper(killerprefab)] or killerprefab
    end
    local users = GetUsers()
    local jsonEncoded = GLOBAL.json.encode({ key = "playerdeath", victim = inst:GetDisplayName(), userid = inst.userid, prefab = inst.prefab, doer = killername or killerprefab or cause or "Desconhecido", players = users })
    SendRequest(jsonEncoded)
end

local function OnPlayerRevived(inst, data)
    if not inst then return end
    local users = GetUsers()
    local jsonEncoded = GLOBAL.json.encode({ key = "playerrevive", name = inst:GetDisplayName(), userid = inst.userid, prefab = inst.prefab, players = users })
    SendRequest(jsonEncoded)
end

local function OnPlayerJoined(inst, player)
    local iscave = GLOBAL.TheWorld:HasTag("cave")
    if player and player.userid then
        local state = GLOBAL.TheWorld.state or nil
        local jsonEncoded = GLOBAL.json.encode({ key = "playershardjoin", name = player:GetDisplayName() or player.name, userid = player.userid, prefab = player.prefab, iscave = iscave, state = state })
        SendRequest(jsonEncoded)
    end
end

local function OnComponentEater(self)
    local old_Eat = self.Eat
    function self:Eat(food)
        local result = old_Eat(self, food)
        if not (result and food and food.prefab) then return result end
        if foodlist[food.prefab] and self.inst then
            local victim = (food.components and food.components.named and food.components.named.name) or (food.prefab and GLOBAL.STRINGS.NAMES[string.upper(food.prefab)]) or food.prefab
            local doer = self.inst:GetDisplayName() or "Alguém"
            local userid = self.inst.userid
            ExecuteOnAllShards("clientchatmessage", { type = "server", message = doer .. " está comendo " .. victim .. "...", whisper = false })
            local jsonEncoded = GLOBAL.json.encode({ key = "alert", key = "eat", doer = doer, userid = userid, victim = victim })
            SendRequest(jsonEncoded)
        end
        return result
    end
end

local function OnComponentBurnable(self)
    local old_Ignite = self.Ignite
    function self:Ignite(immediate, source, ...)
        local result = old_Ignite(self, immediate, source, ...)
        if self.inst and self.inst.prefab and source then
            local player = source
            if source.components and source.components.inventoryitem then player = source.components.inventoryitem:GetGrandOwner() or source end
            if player and player:HasTag("player") then
                local victim = (self.inst.components and self.inst.components.named and self.inst.components.named.name) or (self.inst.prefab and GLOBAL.STRINGS.NAMES[string.upper(self.inst.prefab)]) or self.inst.prefab
                local doer = player:GetDisplayName() or "Alguém"
                local userid = player.userid or nil
                local structure = false
                if (self.inst:HasTag("structure")) then structure = true end
                if structure then
                    ExecuteOnAllShards("clientchatmessage", { type = "server", message = doer .. " está queimando " .. victim .. "...", whisper = false })
                end
                local jsonEncoded = GLOBAL.json.encode({ key = "alert", key = "burn", doer = doer, userid = userid, victim = victim, structure = structure })
                SendRequest(jsonEncoded)
            else
            end
        end
        return result
    end
end

local function OnCycleChange(inst)
    if GLOBAL.TheWorld and GLOBAL.TheWorld:HasTag("cave") then return end
    local cycle = inst.state.cycles
    if currentCycle == cycle then return end
    local users = GetUsers()
    local jsonEncoded = GLOBAL.json.encode({ key = "cycle", states = inst.state, users = users })
    currentCycle = cycle
    SendRequest(jsonEncoded)
end

local oldNetworking_Announcement = GLOBAL.Networking_Announcement
GLOBAL.Networking_Announcement = function(message, colour, announce_type)
    if GLOBAL.TheWorld and GLOBAL.TheWorld:HasTag("cave") then return end
    local event_key = nil
    local players = GetUsers()
    if not players then return end
    local player = nil
    local register = nil
    if announce_type == "join_game" then
        event_key = "joingame"
        player = message:gsub(" has joined the game.", "")
        for userid, p in pairs(players) do
            if p.name == player then
                if register == nil then register = {} end
                register[userid] = p
            end
        end
    elseif announce_type == "leave_game" then
        event_key = "leavegame"
        player = message:gsub(" has left the game.", "")
    else
        print("[Bernie] Announce Type: " .. announce_type)
    end
    if event_key then
        local maxPlayers = GLOBAL.TheNet:GetDefaultMaxPlayers()
        local jsonEncoded = GLOBAL.json.encode({ key = event_key, name = player, message = message, register = register, players = players, maxplayers = maxPlayers })
        SendRequest(jsonEncoded)
    end
    return oldNetworking_Announcement(message, colour, announce_type)
end

AddSimPostInit(function()
    AddPlayerPostInit(function(inst)
        inst:ListenForEvent("ms_respawnedfromghost", OnPlayerRevived)
        inst:ListenForEvent("respawnfromcorpse", OnPlayerRevived)
    end)
end)

AddPrefabPostInit("world", function(inst)
    inst:ListenForEvent("cycleschanged", OnCycleChange)
    inst:ListenForEvent("ms_playerjoined", OnPlayerJoined)
    inst:ListenForEvent("entity_death", OnPlayerDeath)
end)

for boss, _ in pairs(bosses) do
    AddPrefabPostInit(boss, function(inst)
        inst:ListenForEvent("death", OnEntityDeath)
        inst:ListenForEvent("attacked", OnEntityHit)

        inst:DoTaskInTime(0, function()
            if not inst:HasTag("epic") then inst:AddTag("epic") end
        end)
    end)
end

AddPrefabPostInit("daywalker", function(inst)
    inst:DoTaskInTime(0, function()
        local old_MakeDefeated = inst.MakeDefeated
        function inst:MakeDefeated()
            OnEntityDeath(nil, { inst = inst })
            return old_MakeDefeated(inst)
        end
    end)
end)

AddPrefabPostInit("daywalker2", function(inst)
    inst:DoTaskInTime(0, function()
        local old_MakeDefeated = inst.MakeDefeated
        function inst:MakeDefeated()
            OnEntityDeath(nil, { inst = inst })
            return old_MakeDefeated(inst)
        end
    end)
end)

AddPrefabPostInit("sharkboi", function(inst)
    inst:DoTaskInTime(0, function()
        local old_MakeTrader = inst.MakeTrader
        function inst:MakeTrader()
            OnEntityDeath(nil, { inst = inst })
            return old_MakeTrader(inst)
        end
    end)
end)

AddComponentPostInit("eater", OnComponentEater)
AddComponentPostInit("burnable", OnComponentBurnable)

local _ACTION_HAMMER = GLOBAL.ACTIONS.HAMMER.fn
GLOBAL.ACTIONS.HAMMER.fn = function(act)
    if act.doer and act.target and act.target.components.workable.workleft == 1 then
        if act.doer.userid then
            local structure = false
            if (act.target:HasTag("structure")) then structure = true end
            if structure then
                ExecuteOnAllShards("clientchatmessage", { type = "server", message = act.doer.name .. " está quebrando " .. act.target.name .. "...", whisper = false })
            end
            local jsonEncoded = GLOBAL.json.encode({ key = "alert", key = "break", doer = act.doer.name, userid = act.doer.userid, victim = act.target.name, structure = structure })
            SendRequest(jsonEncoded)
        end
    end
    return _ACTION_HAMMER(act)
end

-- Survivors
GLOBAL.TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WILSON = { "backpack" }

TUNING.WES_WORK_MULTIPLIER = 1
TUNING.WONKEY_WALK_SPEED_PENALTY = 1
TUNING.WONKEY_SPEED_BONUS = 1.5
TUNING.WONKEY_TIME_TO_RUN = 2
TUNING.WONKEY_RUN_HUNGER_RATE_MULT = 1.1

TUNING.SHADOW_PILLAR_DURATION = 12
TUNING.SHADOW_PILLAR_DURATION_BOSS = 6
TUNING.SHADOW_PILLAR_DURATION_PLAYER = 3

-- Environment
TUNING.OCEANTREE_STAGES_TO_SUPERTALL = 2

-- Creatures
TUNING.GRUEDAMAGE = 999
TUNING.WALRUS_REGEN_PERIOD = TUNING.WALRUS_REGEN_PERIOD * 0.6
TUNING.CRAWLINGHORROR_HEALTH = 400
TUNING.CRAWLINGHORROR_DAMAGE = 40
TUNING.CRAWLINGHORROR_ATTACK_PERIOD = 2

TUNING.BEEGUARD_HEALTH = 300
TUNING.BEEGUARD_DASH_SPEED = 7
TUNING.LAVAE_HEALTH = 150
TUNING.BEEGUARD_SPEED = 4

-- Bosses
TUNING.TOADSTOOL_HEALTH = 32500
TUNING.TOADSTOOL_MUSHROOMBOMB_RADIUS = 3
TUNING.TOADSTOOL_SPOREBOMB_HIT_RANGE = 3
TUNING.TOADSTOOL_SPORECLOUD_RADIUS = 4
TUNING.TOADSTOOL_SPORECLOUD_LIFETIME = 20
TUNING.TOADSTOOL_MUSHROOMSPROUT_CHOPS = 6
TUNING.TOADSTOOL_MUSHROOMSPROUT_CD = 40

TUNING.CRABKING_CLAW_ATTACKRANGE = 3.6
TUNING.CRABKING_CLAW_BOATDAMAGE = 20
TUNING.CRABKING_GEYSER_BOATDAMAGE = 5
TUNING.CRABKING_REGEN = 25

TUNING.DEERCLOPS_HEALTH = 8000
TUNING.DEERCLOPS_ATTACK_PERIOD = 3

TUNING.DRAGONFLY_ENRAGE_DURATION = 30
TUNING.DRAGONFLY_FIRE_DAMAGE = 200
TUNING.DRAGONFLY_ATTACK_RANGE = 6
TUNING.DRAGONFLY_SPEED = 4
TUNING.DRAGONFLY_FIRE_SPEED = 5
TUNING.DRAGONFLY_HIT_RANGE = 5
TUNING.DRAGONFLY_FIRE_HIT_RANGE = 5

TUNING.BEEQUEEN_DAMAGE = 200
TUNING.BEEQUEEN_SPEED = 3
TUNING.BEEQUEEN_ATTACK_RANGE = 5
TUNING.BEEQUEEN_HIT_RANGE = 4
TUNING.BEEQUEEN_SPAWNGUARDS_CD = { 24, 22, 18, 16 }
TUNING.BEEQUEEN_FOCUSTARGET_CD = { 120, 60, 32, 24 }
TUNING.BEEQUEEN_MIN_GUARDS_PER_SPAWN = 2
TUNING.BEEQUEEN_MAX_GUARDS_PER_SPAWN = 4
TUNING.BEEQUEEN_TOTAL_GUARDS = 4
TUNING.BEEQUEEN_HONEYTRAIL_SPEED_PENALTY = 0.2

TUNING.SPAWN_KLAUS = true

-- Items
TUNING.HEATROCK_NUMUSES = TUNING.HEATROCK_NUMUSES * 3
TUNING.HEAT_ROCK_CARRIED_BONUS_HEAT_FACTOR = 0.2

-- Systems
TUNING.BUILD_DISTANCE = 0.8

print('[Bernie] Finished loading!')
