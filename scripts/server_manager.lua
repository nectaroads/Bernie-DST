local GLOBAL = GLOBAL or _G

print('[Bernie] Starting Server-Manager Module...')

local serverUrl = "http://localhost:24574/bernie"
local chatCommandPrefix = ">"

GLOBAL.AddClientModRPCHandler("bernieclientchatmessage", "content", function() end)
local CLIENTCHATMESSAGE_RPC = GLOBAL.GetClientModRPC("bernieclientchatmessage", "content")

local attackCooldown = 0.460
local attackCooldowns = {}

local backpackPrefabs = { "backpack", "piggyback", "krampus_sack", "icepack", "seedpouch", "spicepack", "candybag" }
local cachedPortal = nil

function SendProxyRequest(json)
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
    if key == "clientchatmessage" then
        if value.userid then
            local json = GLOBAL.json.encode({ type = value.type, message = value.message })
            if json then
                SendModRPCToClient(CLIENTCHATMESSAGE_RPC, value.userid, json)
            end
            return
        end
        local users = GetUsers()
        for _, player in pairs(users) do
            if player and player.userid then
                local json = GLOBAL.json.encode({ type = value.type, message = value.message })
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
    --if command == "d:sm" then
    --    HandleShardFunction("clientchatmessage", { message = "[Global] Message 1...", type = "global" })
    --    HandleShardFunction("clientchatmessage", { message = "[Private] Message 1...", type = "private", userid = userid })
    --    HandleShardFunction("clientchatmessage", { message = "[Global] Message 2...", type = "discord" })
    --    HandleShardFunction("clientchatmessage", { message = "[Private] Message 2...", type = "willow", userid = userid })
    --end
    return true
end

function OnNetworkingSay(guid, userid, name, prefab, message, colour, whisper, isemote, iscave)
    if HandleChatCommands(guid, userid, name, prefab, message, colour, whisper, isemote, iscave) then return end
    local jsonEncoded = GLOBAL.json.encode({ key = "message", userid = userid, username = name, prefab = prefab, message = message, whisper = whisper, cave = iscave })
    SendProxyRequest(jsonEncoded)
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

local function OnPlayerHitOther(inst, data)
    if not inst and not data then return end
    local guid = inst.GUID and GLOBAL.tostring(inst.GUID)
    if not attackCooldowns[guid] then attackCooldowns[guid] = 0 end
    local currentTime = GLOBAL.GetTime()
    local cooldownValue = attackCooldown
    local state = inst.sg and inst.sg.currentstate and inst.sg.currentstate and inst.sg.currentstate.name
    if state ~= "attack" then return end
    if inst.components.inventory then
        local handItem = inst.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
        if handItem then
            if handItem.prefab == "alarmingclock" then cooldownValue = cooldownValue * 1.15 end
            if inst.components.rider and inst.components.rider:IsRiding() then cooldownValue = cooldownValue * 1.06 end
        end
    end
    if attackCooldowns[guid] > currentTime and inst.components and inst.components.combat then
        local threshhold = attackCooldowns[guid] - currentTime
        local debuffProportion = 1 - (threshhold / 0.005) * 0.05
        if debuffProportion < 0 then debuffProportion = 0 end
        inst.components.combat.externaldamagemultipliers:SetModifier("speeddamagemultiplier", debuffProportion)
    else
        inst.components.combat.externaldamagemultipliers:SetModifier("speeddamagemultiplier", 1)
    end
    attackCooldowns[guid] = currentTime + cooldownValue
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
        inst:ListenForEvent("onhitother", OnPlayerHitOther)
        inst:ListenForEvent("itemget", OnPlayerItemGet)
        inst:ListenForEvent("equip", OnPlayerEquip)
        inst:ListenForEvent("attacked", OnPlayerAttacked)
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

local customPigNames = { "Peu-lamb", "Lalachinus" }

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
    "Cancelar animações NÃO funciona. Nem mesmo com mods.",
    "Evite mods como Visão-noturna, Zoom e etc.",
    "Mochilas podem ser colocadas em seu inventário!",
    "Reis Merm não chamam ajuda quando são golpeados, Constant os abandonou!"
}

AddPrefabPostInit("world", function(inst)
     if not GLOBAL.TheWorld.ismastersim then return end
    inst:DoPeriodicTask(60, function()
        local rand = math.random(#propaganda)
        local target = propaganda[rand]
        local data = { type = "server", message = target }
        ExecuteOnAllShards("clientchatmessage", data)
    end)
end)

local function HandleServerResponse(array)
    for _, entry in ipairs(array) do
        if entry.key then
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

print('[Bernie] Finished loading!')
