print('[Bernie] Starting Sadistic-Events module')

local config = GLOBAL.LoadConfig("sadisticevents.lua")

local lasteventday = -2
local currentevent = ""

local mindelay = 30      -- 30
local maxdelay = 90      -- 90

local COOLDOWN = 3       --3
local EVENTCHANCE = 0.15 --0.15

function RegulateTemp()
    if not GLOBAL.TheWorld.net then return end
    if GLOBAL.TheWorld.net:GetCustomTemp() == 0 then return end
    local positive = GLOBAL.TheWorld.net:GetCustomTemp() > 0
    local magnitude = 1
    if positive then magnitude = -1 end
    GLOBAL.TheWorld.net:SetCustomTemp(GLOBAL.TheWorld.net:GetCustomTemp() + magnitude)
    GLOBAL.TheWorld:DoTaskInTime(4, function()
        RegulateTemp()
    end)
end

local function SpoilItem(item, seen)
    if item == nil or not item:IsValid() or seen[item] then return end
    seen[item] = true
    if item.components.perishable ~= nil then item.components.perishable:ReducePercent(0.3) end
end

local function SpoilContainer(container, seen)
    if container == nil then return end
    for slot = 1, container:GetNumSlots() do
        SpoilItem(container:GetItemInSlot(slot), seen)
    end
end

local eventhandler = {
    witchcraft = function(event)
        GLOBAL.TheWorld:DoTaskInTime(math.random(mindelay, maxdelay), function(inst)
            if not GLOBAL.TheWorld then return end
            if not GLOBAL.TheWorld:HasTag("cave") then GLOBAL.ExecuteOnAllShards({ key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "bernie", message = config and config[event.type].messageend }) end
            local seen = {}
            for _, player in ipairs(GLOBAL.AllPlayers) do
                if player ~= nil and player:IsValid() then
                    if player.components.inventory ~= nil then
                        for slot, item in pairs(player.components.inventory.itemslots) do
                            SpoilItem(item, seen)
                        end
                        for slot, equip in pairs(player.components.inventory.equipslots) do
                            SpoilItem(equip, seen)
                            if equip.components.container ~= nil then SpoilContainer(equip.components.container, seen) end
                        end
                    end
                    local x, y, z = player.Transform:GetWorldPosition()
                    local ents = GLOBAL.TheSim:FindEntities(x, y, z, 5, nil, { "INLIMBO", "NOCLICK" })
                    for _, ent in ipairs(ents) do
                        if ent ~= nil and ent:IsValid() and ent.components.container ~= nil then SpoilContainer(ent.components.container, seen) end
                    end
                end
            end
        end)
    end,

    coldsnap = function(event)
        GLOBAL.TheWorld.net:SetCustomTemp(GLOBAL.TheWorld.net:GetCustomTemp() - 1)
        if event.currentloop >= event.loop then RegulateTemp() end
    end,

    heatwave = function(event)
        GLOBAL.TheWorld.net:SetCustomTemp(GLOBAL.TheWorld.net:GetCustomTemp() + 1)
        if event.currentloop >= event.loop then RegulateTemp() end
    end,

    rain = function(event)
        GLOBAL.TheWorld:DoTaskInTime(math.random(mindelay, maxdelay), function(inst)
            if not GLOBAL.TheWorld then return end
            if not GLOBAL.TheWorld:HasTag("cave") then GLOBAL.ExecuteOnAllShards({ key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "bernie", message = config and config[event.type].messageend }) end
            GLOBAL.TheWorld:PushEvent("ms_forceprecipitation")
        end)
    end,

    blackout = function(event)
        GLOBAL.TheWorld:PushEvent("ms_setclocksegs", { day = 0, dusk = 16, night = 0 })
        GLOBAL.TheWorld:DoTaskInTime(math.random(mindelay, maxdelay), function(inst)
            if not GLOBAL.TheWorld then return end
            if not GLOBAL.TheWorld:HasTag("cave") then GLOBAL.ExecuteOnAllShards({ key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "bernie", message = config and config[event.type].messageend }) end
            GLOBAL.TheWorld:PushEvent("ms_setclocksegs", { day = 0, dusk = 0, night = 16 })
        end)
    end,

    attack = function(event)
        GLOBAL.TheWorld:DoTaskInTime(math.random(mindelay, maxdelay), function(inst)
            local players = {}
            for _, player in ipairs(GLOBAL.AllPlayers) do
                if player ~= nil and player.components.health ~= nil and not player.components.health:IsDead()
                then
                    table.insert(players, player)
                end
            end
            if #players <= 0 then return end
            local target = players[math.random(#players)]
            local name = target:GetDisplayName() or target.name

            if not GLOBAL.TheWorld:HasTag("cave") then GLOBAL.ExecuteOnAllShards({ key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "bernie", message = ((config and config[event.name].messagefind) or "???") }) end
            local x, y, z = target.Transform:GetWorldPosition()
            local count = math.random(1, event.maxcreatures)
            for i = 1, count do
                inst:DoTaskInTime(1 + i / 5, function()
                    local angle = math.random() * 2 * GLOBAL.PI
                    local radius = math.random(12, 18)
                    local sx = x + math.cos(angle) * radius
                    local sz = z + math.sin(angle) * radius
                    if GLOBAL.TheWorld.Map:IsPassableAtPoint(sx, 0, sz) then
                        local monster = (GLOBAL.TheWorld:HasTag("cave") and GLOBAL.SpawnPrefab(event.alt)) or GLOBAL.SpawnPrefab(event.prefab)
                        local fx = GLOBAL.SpawnPrefab("woby_dash_shadow_fx")
                        if fx ~= nil then fx.Transform:SetPosition(sx, 0, sz) end
                        if monster ~= nil then
                            monster.Transform:SetPosition(sx, 0, sz)
                            if monster.components.combat ~= nil then monster.components.combat:SetTarget(target) end
                            if monster.components.follower ~= nil then monster.components.follower:SetLeader(nil) end
                        end
                    end
                end)
            end
        end)
    end
}

GLOBAL.CallSadisticEvent = function(event)
    if not event then
        print("[LOG] Event not found!")
        return
    end
    if currentevent ~= event.type then
        currentevent = event.type
        event.currentloop = 0
    end
    if event.currentloop == nil then event.currentloop = 0 end
    if event.currentloop == 0 and event.messagestart ~= nil then
        if not GLOBAL.TheWorld:HasTag("cave") then GLOBAL.ExecuteOnAllShards(event.messagestart) end
        for _, player in ipairs(GLOBAL.AllPlayers) do
            if player ~= nil and player:IsValid() and player.SoundEmitter ~= nil then
                player.SoundEmitter:PlaySound("rifts4/shadowthrall_mouth/taunt")
            end
        end
    end
    eventhandler[event.type](event)
    if event.currentloop >= event.loop then
        if event.messageend then
            if not GLOBAL.TheWorld:HasTag("cave") then GLOBAL.ExecuteOnAllShards(event.messageend) end
            for _, player in ipairs(GLOBAL.AllPlayers) do
                if player ~= nil and player:IsValid() and player.SoundEmitter ~= nil then
                    player.SoundEmitter:PlaySound("dontstarve/quagmire/music/gorge_win", nil, 0.5)
                end
            end
        end
        return true
    end
    event.currentloop = event.currentloop + 1
    GLOBAL.TheWorld:DoTaskInTime(6, function()
        GLOBAL.CallSadisticEvent(event)
    end)
end

local sadisticevents = {
    blackout = {
        messagestart = { key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "bernie", message = config and config.blackout.messagestart, event = "blink" },
        name = "blackout",
        type = "blackout",
        loop = 0,
        currentloop = 0
    },
    witchcraft = {
        messagestart = { key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "bernie", message = config and config.witchcraft.messagestart, event = "blink" },
        name = "witchcraft",
        type = "witchcraft",
        loop = 0,
        currentloop = 0
    },
    krampusattack = {
        messagestart = { key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "bernie", message = config and config.krampusattack.messagestart, event = "blink" },
        name = "krampusattack",
        type = "attack",
        loop = 0,
        currentloop = 0,
        prefab = "powder_monkey",
        alt = "monkey",
        maxcreatures = 3,
    },
    houndattack = {
        messagestart = { key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "bernie", message = config and config.houndattack.messagestart, event = "blink" },
        name = "houndattack",
        type = "attack",
        loop = 0,
        currentloop = 0,
        prefab = "hound",
        alt = "terrorbeak",
        maxcreatures = 3
    },
    heatwave = {
        messagestart = { key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "bernie", message = config and config.heatwave.messagestart, event = "blink" },
        name = "heatwave",
        type = "heatwave",
        loop = 60,
        currentloop = 0,
        messageend = { key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "bernie", message = config and config.heatwave.messageend }
    },
    coldsnap = {
        messagestart = { key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "bernie", message = config and config.coldsnap.messagestart, event = "blink" },
        name = "coldsnap",
        type = "coldsnap",
        loop = 60,
        currentloop = 0,
        messageend = { key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "bernie", message = config and config.coldsnap.messageend }
    },
    rain = {
        messagestart = { key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "bernie", message = config and config.rain.messagestart, event = "blink" },
        name = "rain",
        type = "rain",
        loop = 0,
        currentloop = 0
    }
}

local function RollSadisticEvent()
    if GLOBAL.TheWorld:HasTag("cave") then return end
    if math.random() > EVENTCHANCE then return end
    local keys = {}
    for k, v in pairs(sadisticevents) do
        if v.name ~= currentevent then table.insert(keys, k) end
    end
    if #keys <= 0 then return end
    local randomkey = keys[math.random(#keys)]
    local event = sadisticevents[randomkey]
    if event then
        GLOBAL.ExecuteOnAllShards({ key = "sadistic_event", event = event })
        local users = GLOBAL.GetUsers()
        local jsonEncoded = GLOBAL.json.encode({ key = "world_sadistic_event", event = event, users = users })
        GLOBAL.SendRequest(jsonEncoded)
        --GLOBAL.CallSadisticEvent(inst, event)
    end
end

GLOBAL.TriggerSadisticEvent = function(ev)
    if sadisticevents[ev] then
        GLOBAL.CallSadisticEvent(sadisticevents[ev])
    end
end

AddPrefabPostInit("world", function(inst)
    if not GLOBAL.TheWorld.ismastersim then return end
    GLOBAL.TheWorld:WatchWorldState("phase", function(inst, phase)
        if phase == "day" then
            local dice = math.random(3, 36)
            GLOBAL.TheWorld:DoTaskInTime(dice, function()
                local currentday = GLOBAL.TheWorld.state.cycles
                if currentday - lasteventday < COOLDOWN then return end
                lasteventday = currentday
                RollSadisticEvent()
            end)
        end
    end)
end)
