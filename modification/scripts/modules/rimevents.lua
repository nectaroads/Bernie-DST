print('[Bernie] Starting Rim-Events module')

local config = GLOBAL.LoadConfig("rimevents.lua")
local isclient = not GLOBAL.TheNet:IsDedicated()

if isclient then
    -- Client Only
else
    -- Server Only
    local storyteller = "willow"
    local lasteventday = -2 -- -2
    local currentevent = ""
    local mindelay = 20      -- 30
    local maxdelay = 90      -- 90
    local COOLDOWN = 3      --3
    local EVENTCHANCE = 0.15   --0.15

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

    local EventHandler = {}
    local rimevents = config[storyteller] or {}

    EventHandler.rain = function(event)
        GLOBAL.TheWorld:DoTaskInTime(math.random(mindelay, maxdelay), function(inst)
            if not GLOBAL.TheWorld then return end
            if not GLOBAL.TheWorld:HasTag("cave") then GLOBAL.ExecuteOnAllShards(event.messageend) end
            GLOBAL.TheWorld:PushEvent("ms_forceprecipitation")
        end)
    end

    EventHandler.coldsnap = function(event)
        GLOBAL.TheWorld.net:SetCustomTemp(GLOBAL.TheWorld.net:GetCustomTemp() - 1)
        if event.currentloop >= event.loop then RegulateTemp() end
    end

    EventHandler.heatwave = function(event)
        GLOBAL.TheWorld.net:SetCustomTemp(GLOBAL.TheWorld.net:GetCustomTemp() + 1)
        if event.currentloop >= event.loop then RegulateTemp() end
    end

    EventHandler.attack = function(event)
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
            if not GLOBAL.TheWorld:HasTag("cave") then GLOBAL.ExecuteOnAllShards(event.messageend) end
            local x, y, z = target.Transform:GetWorldPosition()
            local count = math.random(1, event.maxcreatures)
            for i = 1, count do
                inst:DoTaskInTime(1 + i / 5, function()
                    local angle = math.random() * 2 * GLOBAL.PI
                    local radius = math.random(16, 20)
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

    EventHandler.witchcraft = function(event)
        GLOBAL.TheWorld:DoTaskInTime(math.random(mindelay, maxdelay), function(inst)
            if not GLOBAL.TheWorld then return end
            if not GLOBAL.TheWorld:HasTag("cave") then GLOBAL.ExecuteOnAllShards(event.messageend) end
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
    end

    EventHandler.blackout = function(event)
        GLOBAL.TheWorld:PushEvent("ms_setclocksegs", { day = 0, dusk = 16, night = 0 })
        GLOBAL.TheWorld:DoTaskInTime(math.random(mindelay, maxdelay), function(inst)
            if not GLOBAL.TheWorld then return end
            if not GLOBAL.TheWorld:HasTag("cave") then GLOBAL.ExecuteOnAllShards(event.messageend) end
            GLOBAL.TheWorld:PushEvent("ms_setclocksegs", { day = 0, dusk = 0, night = 16 })
        end)
    end

    EventHandler.bloodfeast = function(event)
        if not GLOBAL.TheNet then return end
        GLOBAL.TheNet:SetPVP(true)
        GLOBAL.TheWorld._bloodfeasting = true
        GLOBAL.TheWorld:DoTaskInTime(math.random(60 * 3, 60 * 8), function(inst)
            if not GLOBAL.TheWorld:HasTag("cave") then GLOBAL.ExecuteOnAllShards(event.messageend) end
            GLOBAL.TheNet:SetPVP(false)
            GLOBAL.TheWorld._bloodfeasting = false
        end)
    end

    EventHandler.randomflare = function(event)
        GLOBAL.TheWorld:DoTaskInTime(math.random(mindelay, maxdelay), function(inst)
            if not GLOBAL.TheWorld then return end
            if GLOBAL.TheWorld:HasTag("cave") then return end
            GLOBAL.ExecuteOnAllShards(event.messageend)
            local origin = GLOBAL.Vector3(0, 0, 0)
            local offset = nil
            for i = 1, 100 do
                offset = GLOBAL.FindWalkableOffset(origin, math.random() * 2 * GLOBAL.PI, math.random(100, 2000), 16, true, false)
                if offset then break end
            end
            if not offset then return end
            if not offset then return end
            local x = origin.x + offset.x
            local z = origin.z + offset.z
            local flare = GLOBAL.SpawnPrefab("megaflare")
            local tent = GLOBAL.SpawnPrefab("tent")
            local effect = GLOBAL.SpawnPrefab("shadow_merm_spawn_poof_fx")
            tent.Transform:SetPosition(x, 0, z)
            flare.Transform:SetPosition(x, 0, z)
            effect.Transform:SetPosition(x, 0, z)
            flare._forcereveal = true
            if flare.components.burnable then flare.components.burnable:Ignite() end
            local xoffeset = math.random(-6, 6)
            local zoffeset = math.random(-6, 6)
            local bounties = { "diviningrod", "piggyback", "onemanband", "teleportato_ring" }
            local loot = GLOBAL.SpawnPrefab(bounties[math.random(#bounties)])
            if loot then
                loot.Transform:SetPosition(x + xoffeset, 0, z + zoffeset)
                local effect2 = GLOBAL.SpawnPrefab("shadow_merm_spawn_poof_fx")
                effect2.Transform:SetPosition(x + xoffeset, 0, z + zoffeset)
            end
            local extraquantity = math.random(0, 3)
            if extraquantity > 0 then
                local extrabounties = { lighter = 1, perogies = 1, bananajuice = 1, dragonpie = 1, waffles = 1, fruitmedley = 1, lightbulb = 3, lantern = 1, handpillow_steelwool = 1, compass = 1, propsign = 1 }
                local keys = {}
                for prefab in pairs(extrabounties) do
                    table.insert(keys, prefab)
                end
                for i = 1, extraquantity do
                    local prefab = keys[math.random(#keys)]
                    local quantity = extrabounties[prefab]
                    local basex = x + math.random(-6, 6)
                    local basez = z + math.random(-6, 6)
                    for j = 1, quantity do
                        local item = GLOBAL.SpawnPrefab(prefab)
                        if item then
                            local spread = quantity > 1 and 2 or 0
                            local randomx = math.random(-spread, spread)
                            local randomz = math.random(-spread, spread)
                            item.Transform:SetPosition(basex + randomx, 0, basez + randomz)
                            local effect3 = GLOBAL.SpawnPrefab("shadow_merm_spawn_poof_fx")
                            effect3.Transform:SetPosition(basex + randomx, 0, basez + randomz)
                        end
                    end
                end
            end
        end)
    end

    GLOBAL.CallSadisticEvent = function(event)
        if not event then return end
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
        EventHandler[event.type](event)
        if event.loop > 0 then
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
    end

    GLOBAL.HandleShardFunction.sadistic_event = function(data)
        if not data.event then return end
        GLOBAL.CallSadisticEvent(data.event)
    end

    GLOBAL.RollSadisticEvent = function()
        if GLOBAL.TheWorld:HasTag("cave") then return end
        if math.random() > EVENTCHANCE then return end
        local keys = {}
        for k, v in pairs(rimevents) do
            if v.name ~= currentevent then table.insert(keys, k) end
        end
        if #keys <= 0 then return end
        local randomkey = keys[math.random(#keys)]
        local event = rimevents[randomkey]
        if event then
            GLOBAL.ExecuteOnAllShards({ key = "sadistic_event", event = event })
            local users = GLOBAL.GetUsers()
            local jsonEncoded = GLOBAL.json.encode({ key = "world_sadistic_event", event = event, users = users })
            GLOBAL.SendRequest(jsonEncoded)
        end
    end

    GLOBAL.TriggerSadisticEvent = function(ev)
        if rimevents[ev] then
            GLOBAL.CallSadisticEvent(rimevents[ev])
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
                    GLOBAL.RollSadisticEvent()
                end)
            end
        end)
    end)
end
