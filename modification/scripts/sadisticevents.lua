print('[Bernie] Starting Sadistic-Events module')

local config = GLOBAL.LoadConfig("sadisticevents.lua")

local lasteventday = -2
local currentevent = ""

function RainEvent(inst, event)
    GLOBAL.TheWorld:PushEvent("ms_forceprecipitation")
end

function BlackoutEvent(inst, event)
    GLOBAL.TheWorld:PushEvent("ms_setclocksegs", { day = 0, dusk = 0, night = 16, })
end

function RaidEvent(inst, event, prefab, maxcreatures)
    inst:DoTaskInTime(math.random(30, 90), function(inst)
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
        GLOBAL.ExecuteOnAllShards({ key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "bernie", message = ((config and config[event.name].messagefind) or "???") .. name .. "!" }, true)
        local x, y, z = target.Transform:GetWorldPosition()
        local count = math.random(2, maxcreatures)
        for i = 1, count do
            inst:DoTaskInTime(1 + i / 5, function()
                local angle = math.random() * 2 * GLOBAL.PI
                local radius = math.random(12, 18)
                local sx = x + math.cos(angle) * radius
                local sz = z + math.sin(angle) * radius
                if GLOBAL.TheWorld.Map:IsPassableAtPoint(sx, 0, sz) then
                    local hound = GLOBAL.SpawnPrefab(prefab)
                    local fx = GLOBAL.SpawnPrefab("woby_dash_shadow_fx")
                    if fx ~= nil then fx.Transform:SetPosition(sx, 0, sz) end
                    if hound ~= nil then
                        hound.Transform:SetPosition(sx, 0, sz)
                        if hound.components.combat ~= nil then hound.components.combat:SetTarget(target) end
                        if hound.components.follower ~= nil then hound.components.follower:SetLeader(nil) end
                    end
                end
            end)
        end
    end)
end

function RegulateTemp(inst)
    if not GLOBAL.TheWorld.net then return end
    if GLOBAL.TheWorld.net:GetCustomTemp() == 0 then return end
    local positive = GLOBAL.TheWorld.net:GetCustomTemp() > 0
    local magnitude = 1
    if positive then magnitude = -1 end
    GLOBAL.TheWorld.net:SetCustomTemp(GLOBAL.TheWorld.net:GetCustomTemp() + magnitude)
    inst:DoTaskInTime(4, function()
        RegulateTemp(inst)
    end)
end

function ColdSnapEvent(inst, event)
    GLOBAL.TheWorld.net:SetCustomTemp(GLOBAL.TheWorld.net:GetCustomTemp() - 1)
    if event.currentloop >= event.loop then RegulateTemp(inst) end
end

function HeatWaveEvent(inst, event)
    GLOBAL.TheWorld.net:SetCustomTemp(GLOBAL.TheWorld.net:GetCustomTemp() + 1)
    if event.currentloop >= event.loop then RegulateTemp(inst) end
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

function WitchcraftEvent(inst, event)
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
end

function CallSadisticEvent(inst, event)
    if currentevent ~= event.name then
        currentevent = event.name
        event.currentloop = 0
    end
    if event.currentloop == nil then event.currentloop = 0 end
    if event.currentloop == 0 and event.messagestart ~= nil then
        GLOBAL.ExecuteOnAllShards(event.messagestart, true)
        for _, player in ipairs(GLOBAL.AllPlayers) do
            if player ~= nil and player:IsValid() and player.SoundEmitter ~= nil then
                player.SoundEmitter:PlaySound("dontstarve/quagmire/creature/gnaw/rumble")
                player.SoundEmitter:PlaySound("dontstarve/rain/thunder_far")
            end
        end
    end
    event.func(inst, event)
    if event.currentloop >= event.loop then
        if event.messageend then
            GLOBAL.ExecuteOnAllShards(event.messageend, true)
            for _, player in ipairs(GLOBAL.AllPlayers) do
                if player ~= nil and player:IsValid() and player.SoundEmitter ~= nil then
                    player.SoundEmitter:PlaySound("dontstarve/quagmire/music/gorge_win")
                    player.SoundEmitter:PlaySound("dontstarve/rain/thunder_far")
                end
            end
        end
        return true
    end
    event.currentloop = event.currentloop + 1
    inst:DoTaskInTime(6, function()
        CallSadisticEvent(inst, event)
    end)
end

local sadisticevents = {
    blackout = {
        messagestart = { key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "bernie", message = config and config.blackout.messagestart, event = "blink" },
        name = "blackout",
        loop = 0,
        currentloop = 0,
        func = function(inst, event) BlackoutEvent(inst, event) end
    },
    witchcraft = {
        messagestart = { key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "bernie", message = config and config.witchcraft.messagestart, event = "blink" },
        name = "witchcraft",
        loop = 0,
        currentloop = 0,
        func = function(inst, event) WitchcraftEvent(inst, event) end
    },
    krampusattack = {
        messagestart = { key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "bernie", message = config and config.krampusattack.messagestart, event = "blink" },
        name = "krampusattack",
        loop = 0,
        currentloop = 0,
        func = function(inst, event) RaidEvent(inst, event, "krampus", 3) end
    },
    houndattack = {
        messagestart = { key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "bernie", message = config and config.houndattack.messagestart, event = "blink" },
        name = "houndattack",
        loop = 0,
        currentloop = 0,
        func = function(inst, event) RaidEvent(inst, event, "hound", 4) end
    },
    heatwave = {
        messagestart = { key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "bernie", message = config and config.heatwave.messagestart, event = "blink" },
        name = "heatwave",
        loop = 60,
        currentloop = 0,
        messageend = { key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "bernie", message = config and config.heatwave.messageend },
        func = function(inst, event) HeatWaveEvent(inst, event) end
    },
    coldsnap = {
        messagestart = { key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "bernie", message = config and config.coldsnap.messagestart, event = "blink" },
        name = "coldsnap",
        loop = 60,
        currentloop = 0,
        messageend = { key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "bernie", message = config and config.coldsnap.messageend },
        func = function(inst, event) ColdSnapEvent(inst, event) end
    },
    rain = {
        messagestart = { key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "bernie", message = config and config.rain.messagestart, event = "blink" },
        name = "rain",
        loop = 0,
        currentloop = 0,
        func = function(inst, event) RainEvent(inst, event) end
    }
}

local function RollSadisticEvent(inst)
    if math.random() > 0.1 then return end
    local keys = {}
    for k, v in pairs(sadisticevents) do
        if v.name ~= currentevent then table.insert(keys, k) end
    end
    if #keys <= 0 then return end
    local randomkey = keys[math.random(#keys)]
    local event = sadisticevents[randomkey]
    if event ~= nil then CallSadisticEvent(inst, event) end
end

GLOBAL.TriggerSadisticEvent = function(ev)
    if sadisticevents[ev] then
        CallSadisticEvent(GLOBAL.TheWorld, sadisticevents[ev])
    end
end

AddPrefabPostInit("world", function(inst)
    if not GLOBAL.TheWorld.ismastersim then return end
    inst:WatchWorldState("phase", function(inst, phase)
        if phase == "day" then
            local dice = math.random(3, 36)
            inst:DoTaskInTime(dice, function()
                local currentday = GLOBAL.TheWorld.state.cycles
                if currentday - lasteventday < 2 then return end
                lasteventday = currentday
                RollSadisticEvent(inst)
            end)
        end
    end)
end)
