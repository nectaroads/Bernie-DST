print('[Bernie] Starting Immersive-World module')

local config = GLOBAL.LoadConfig("immersiveworld.lua")

-- Tools
local function WorldHasTile(tile)
    local map = GLOBAL.TheWorld.Map
    local width, height = map:GetSize()
    for x = 0, width - 1 do
        for y = 0, height - 1 do
            if map:GetTile(x, y) == tile then return true end
        end
    end
    return false
end

-- Priority stuff
GLOBAL.ACTIONS.EAT.priority = GLOBAL.ACTIONS.FERTILIZE.priority + 1

-- Aimable flares
local FLARE_DESTINATION = AddAction("FLARE_DESTINATION", "Flare Destination", function(act)
    local doer = act.doer
    if doer == nil or doer.components.inventory == nil then return false end
    local flare_stack = doer.components.inventory:FindItem(function(item) return item.prefab == "miniflare" end)
    if flare_stack == nil then return false end
    local pt = act:GetActionPoint()
    if pt == nil then return false end
    local x, y, z = pt:Get()
    local flare = flare_stack
    if flare_stack.components.stackable ~= nil and flare_stack.components.stackable:IsStack() then
        flare = flare_stack.components.stackable:Get(1)
    else
        doer.components.inventory:RemoveItem(flare_stack)
    end
    flare.flare_destination = GLOBAL.Vector3(x, 0, z)
    flare.Transform:SetPosition(doer.Transform:GetWorldPosition())
    if flare.components.inventoryitem ~= nil then flare.components.inventoryitem:OnDropped(true) end
    return true
end)

FLARE_DESTINATION.rmb = true
FLARE_DESTINATION.map_only = true
FLARE_DESTINATION.map_works_on_unexplored = true
FLARE_DESTINATION.closes_map = true
FLARE_DESTINATION.instant = true

local function HasFlare(inst)
    local inv = inst.replica.inventory
    return inv ~= nil and inv:Has("miniflare", 1)
end

AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(0, function()
        if inst.components.playeractionpicker == nil then return end
        local old_pointspecialactionsfn = inst.components.playeractionpicker.pointspecialactionsfn
        inst.components.playeractionpicker.pointspecialactionsfn = function(inst, pos, useitem, right, usereticulepos)
            local actions = {}
            if old_pointspecialactionsfn ~= nil then
                local old_actions = old_pointspecialactionsfn(inst, pos, useitem, right, usereticulepos)
                if old_actions ~= nil then
                    for _, action in ipairs(old_actions) do
                        table.insert(actions, action)
                    end
                end
            end
            if right and useitem == nil and inst.checkingmapactions and HasFlare(inst) then table.insert(actions, GLOBAL.ACTIONS.FLARE_DESTINATION) end
            return actions
        end
    end)
end)

AddPrefabPostInit("miniflare", function(inst)
    if not GLOBAL.TheWorld.ismastersim then return end
    if inst.components.stackable == nil then
        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = GLOBAL.TUNING.STACK_SIZE_LARGEITEM
    end
    inst:DoTaskInTime(0, function()
        if inst.components.burnable == nil then return end
        local old_onignite = inst.components.burnable.onignite
        inst.components.burnable:SetOnIgniteFn(function(inst, source, doer)
            if inst.flare_destination ~= nil then
                inst:ListenForEvent("animover", function(inst)
                    if inst.flare_destination ~= nil then inst.Transform:SetPosition(inst.flare_destination.x, 0, inst.flare_destination.z) end
                end)
            end
            if old_onignite ~= nil then old_onignite(inst, source, doer) end
        end)
    end)
end)

-- MMO Stuff: Sitting
local sittable = { "evergreen_stump", "deciduoustree_stump", "marsh_tree_stump", "twiggytree_stump", "lumpy_stump", "mushroom_farm" }
for _, prefab in ipairs(sittable) do
    AddPrefabPostInit(prefab, function(inst)
        if not inst.Transform then return end
        if not inst.components.sittable then
            inst:AddComponent("sittable")
        end
    end)
end

if GLOBAL.TheNet:IsDedicated() then
    -- Worldgen
    local function GetDistanceFromLand(map, x, z, maxcheck)
        local dist = 0
        while dist <= maxcheck do
            local found_land = false
            for angle = 0, 360, 20 do
                local rad = angle * GLOBAL.DEGREES
                local px = x + math.cos(rad) * dist
                local pz = z + math.sin(rad) * dist
                local tile = map:GetTileAtPoint(px, 0, pz)
                if not GLOBAL.IsOceanTile(tile) and tile ~= GLOBAL.WORLD_TILES.IMPASSABLE then
                    found_land = true
                    break
                end
            end
            if found_land then return dist end
            dist = dist + 2
        end
        return maxcheck
    end

    local MIN_COAST_DISTANCE = 2
    local MAX_COAST_DISTANCE = 4

    local function FindOceanNearPoint(x, z)
        local map = GLOBAL.TheWorld.Map
        local candidates = {}
        local MIN_COAST_DISTANCE = 10
        local MAX_COAST_DISTANCE = 22
        for radius = 20, 100, 4 do
            for angle = 0, 360, 12 do
                local rad = angle * GLOBAL.DEGREES
                local px = x + math.cos(rad) * radius
                local pz = z + math.sin(rad) * radius
                local tile = map:GetTileAtPoint(px, 0, pz)
                if GLOBAL.IsOceanTile(tile) then
                    local coastdist = GetDistanceFromLand(map, px, pz, 40)
                    if coastdist >= MIN_COAST_DISTANCE and coastdist <= MAX_COAST_DISTANCE then
                        table.insert(candidates, { x = px, z = pz, })
                    end
                end
            end
        end
        if #candidates > 0 then return candidates[math.random(#candidates)] end
    end

    local function SpawnMandrakeForestOceanTree(inst)
        if inst._mandrakeforest_oceantree_spawned then return end
        local map = GLOBAL.TheWorld.Map
        local w, h = map:GetSize()
        local radius = math.max(w, h) * 2
        local mandrakes = GLOBAL.TheSim:FindEntities(0, 0, 0, radius, nil, { "INLIMBO" })
        local valid_mandrakes = {}
        for _, ent in ipairs(mandrakes) do
            if ent.prefab == "mandrake_planted" then table.insert(valid_mandrakes, ent) end
        end
        if #valid_mandrakes <= 0 then return end
        local mandrake = valid_mandrakes[math.random(#valid_mandrakes)]
        local x, y, z = mandrake.Transform:GetWorldPosition()
        local pos = FindOceanNearPoint(x, z)
        if pos ~= nil then
            local tree = GLOBAL.SpawnPrefab("oceantree_pillar")
            if tree ~= nil then
                tree.Transform:SetPosition(pos.x, 0, pos.z)
                inst._mandrakeforest_oceantree_spawned = true
            end
        end
    end

    AddPrefabPostInit("world", function(inst)
        local _OnSave = inst.OnSave
        local _OnLoad = inst.OnLoad
        inst.OnSave = function(inst, data)
            if _OnSave ~= nil then _OnSave(inst, data) end
            data.mandrakeforest_oceantree_spawned = inst._mandrakeforest_oceantree_spawned
        end

        inst.OnLoad = function(inst, data)
            if _OnLoad ~= nil then _OnLoad(inst, data) end
            if data ~= nil then inst._mandrakeforest_oceantree_spawned = data.mandrakeforest_oceantree_spawned end
        end

        inst:DoTaskInTime(1, SpawnMandrakeForestOceanTree)
    end)

    -- Frogs
    AddBrainPostInit("frogbrain", function(brain)
        local root = brain.bt ~= nil and brain.bt.root or nil
        if root == nil or root.children == nil then return end
        local gohome = root.children[4]
        if gohome ~= nil and gohome.children ~= nil and gohome.children[1] ~= nil then
            gohome.children[1].fn = function() return GLOBAL.TheWorld.state.isday or GLOBAL.TheWorld.state.iswinter end
        end
        local wander = root.children[5]
        if wander ~= nil and wander.children ~= nil and wander.children[1] ~= nil then
            wander.children[1].fn = function()
                if brain.inst.islunar then return true end
                return GLOBAL.TheWorld.state.isdusk or GLOBAL.TheWorld.state.isnight
            end
        end
    end)

    -- Ponds to frogs
    AddPrefabPostInit("pond", function(inst)
        inst.dayspawn = false
        inst:DoTaskInTime(0, function(inst)
            if inst.components.childspawner ~= nil then
                inst.components.childspawner:StopSpawning()
                if not GLOBAL.TheWorld.state.isday and not GLOBAL.TheWorld.state.iswinter then inst.components.childspawner:StartSpawning() end
            end
        end)
    end)

    -- Make some annoying objects burnable
    AddPrefabPostInitAny(function(inst)
        if not GLOBAL.TheWorld.ismastersim then return end
        inst:DoTaskInTime(0, function()
            local spamitems = { stinger = true }
            -- Spam items
            if spamitems[inst.prefab] then
                if inst.components.burnable == nil then inst:AddComponent("burnable") end
                if inst.components.propagator == nil then inst:AddComponent("propagator") end
                inst:AddTag("canlight")
            end
            -- Tools
            if inst.components.finiteuses ~= nil then
                if inst.components.fuel == nil then inst:AddComponent("fuel") end
                inst.components.fuel.fueltype = GLOBAL.FUELTYPE.BURNABLE
                local uses = inst.components.finiteuses.total or 100
                if uses <= 5 then
                    inst.components.fuel.fuelvalue = GLOBAL.TUNING.TINY_FUEL
                elseif uses <= 25 then
                    inst.components.fuel.fuelvalue = GLOBAL.TUNING.SMALL_FUEL
                elseif uses <= 100 then
                    inst.components.fuel.fuelvalue = GLOBAL.TUNING.MED_FUEL
                else
                    inst.components.fuel.fuelvalue = GLOBAL.TUNING.LARGE_FUEL
                end
            end
        end)
    end)

    -- Anything rottable is a fertilizer
    AddPrefabPostInitAny(function(inst)
        if inst.components.perishable ~= nil and inst.components.edible == nil then return end
        inst:DoTaskInTime(0, function()
            if inst.components.perishable ~= nil then
                if inst.components.fertilizer == nil then inst:AddComponent("fertilizer") end
                local perish = inst.components.perishable.perishtime or 0
                if perish <= GLOBAL.TUNING.PERISH_FAST then
                    inst.components.fertilizer.fertilizervalue = 2
                elseif perish <= GLOBAL.TUNING.PERISH_MED then
                    inst.components.fertilizer.fertilizervalue = 5
                else
                    inst.components.fertilizer.fertilizervalue = 10
                end
            end
        end)
    end)

    -- Gnome Stuff
    local function OnGnomeEscape(inst, owner)
        if owner == nil or owner.components.inventory == nil then return end
        local dice = math.random(0, 2)
        if dice == 0 then return end
        inst:DoTaskInTime(0, function()
            if inst.components.inventoryitem == nil then return end
            local realowner = inst.components.inventoryitem.owner
            if realowner == nil or realowner.components.inventory == nil then return end
            if realowner.SoundEmitter then realowner.SoundEmitter:PlaySound("yotb_2021/common/hitching_post/unhitching") end
            if realowner.sg and (realowner.components.rider == nil or not realowner.components.rider:IsRiding()) then realowner.sg:GoToState("slip") end
            realowner.components.inventory:DropItem(inst, true, true)
            if dice == 2 then
                local x, y, z = realowner.Transform:GetWorldPosition()
                local theta = math.random() * GLOBAL.TWOPI
                local radius = math.random(6, 12)
                local offset = GLOBAL.FindWalkableOffset(GLOBAL.Vector3(x, y, z), theta, radius, 8, true)
                if offset ~= nil then
                    inst.Transform:SetPosition(x + offset.x, 0, z + offset.z)
                    local effect = GLOBAL.SpawnPrefab("shadow_merm_spawn_poof_fx")
                    if effect then effect.Transform:SetPosition(x + offset.x, 0, z + offset.z) end
                end
            end
        end)
    end

    AddPrefabPostInit("trinket_4", function(inst)
        if not GLOBAL.TheWorld.ismastersim then return end
        inst:ListenForEvent("onputininventory", OnGnomeEscape)
    end)

    AddPrefabPostInit("trinket_13", function(inst)
        if not GLOBAL.TheWorld.ismastersim then return end
        inst:ListenForEvent("onputininventory", OnGnomeEscape)
    end)

    -- Flare reveals map
    AddSimPostInit(function()
        if not GLOBAL.TheWorld.ismastersim then return end
        local function FlareDoReveal(data)
            if data == nil or data.pt == nil then return end
            local x, y, z = data.pt:Get()
            for _, player in ipairs(GLOBAL.AllPlayers) do
                if player ~= nil and player:IsValid() and player.player_classified ~= nil and player.player_classified.MapExplorer ~= nil then player.player_classified.MapExplorer:RevealArea(x, y, z) end
            end
        end
        GLOBAL.TheWorld:ListenForEvent("miniflare_detonated", function(world, data)
            if data == nil or data.pt == nil or data.igniter == nil then return end
            local x, y, z = data.pt:Get()
            local player = data.igniter
            if player:CanSeePointOnMiniMap(x, y, z) then FlareDoReveal(data) end
        end)
        GLOBAL.TheWorld:ListenForEvent("megaflare_detonated", function(world, data)
            FlareDoReveal(data)
        end)
    end)

    local function OnPigmanPostInit(inst)
        inst:DoTaskInTime(0, function()
            -- Pigs can have special names
            if not inst or inst:HasTag("customname") or not inst.components.named then return end
            if not (inst and inst.components.named) then return end
            local dice = math.random(0, 9)
            if dice <= 2 then inst.components.named:SetName((config and config.pignames[math.random(#config.pignames)]) or "undefined") end
            inst:AddTag("customname")
            inst:WatchWorldState("phase", function(inst, phase)
                -- Pigs can eventually build a new home
                if phase == "dusk" then
                    local function PigHasHome(inst) return inst.components.homeseeker ~= nil and inst.components.homeseeker.home ~= nil and inst.components.homeseeker.home:IsValid() end
                    local function GivePigNewHouse(inst)
                        if PigHasHome(inst) then return end
                        if math.random() > 0.1 then return end
                        if inst.sg ~= nil then inst.sg:GoToState("refuse") end
                        inst:DoTaskInTime(0.7, function(inst)
                            if not inst or inst.components.health == nil then return end
                            local x, y, z = inst.Transform:GetWorldPosition()
                            local rot = inst.Transform:GetRotation() * GLOBAL.DEGREES
                            x = x - math.sin(rot) * 1.5
                            z = z - math.cos(rot) * 1.5
                            local dust = GLOBAL.SpawnPrefab("cavein_dust_low")
                            if dust ~= nil then dust.Transform:SetPosition(x, y, z) end
                            inst.SoundEmitter:PlaySound("dontstarve/common/place_structure_straw")
                            local house = GLOBAL.SpawnPrefab("pighouse")
                            if house == nil then return end
                            house.Transform:SetPosition(x, y, z)
                            if house.components.spawner ~= nil then
                                if house.components.spawner.child ~= nil then
                                    house.components.spawner.child:Remove()
                                    house.components.spawner.child = nil
                                end
                                house.components.spawner:TakeOwnership(inst)
                            end
                            if inst.components.homeseeker == nil then inst:AddComponent("homeseeker") end
                            inst.components.homeseeker:SetHome(house)
                        end)
                    end
                    GivePigNewHouse(inst)
                end
            end)
        end)
    end
    AddPrefabPostInit("pigman", OnPigmanPostInit)
end
