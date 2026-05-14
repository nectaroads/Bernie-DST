print('[Bernie] Starting Immersive-World module')

local config = GLOBAL.LoadConfig("immersiveworld.lua")

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
        realowner.sg:GoToState("slip")
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
    -- Flare reveals map
    AddSimPostInit(function()
        if not GLOBAL.TheWorld.ismastersim then return end
        local function FlareDoReveal(data)
            if data == nil or data.pt == nil then return end
            local x, y, z = data.pt:Get()
            for _, player in ipairs(GLOBAL.AllPlayers) do
                if player ~= nil and player:IsValid() and player.player_classified ~= nil and player.player_classified.MapExplorer ~= nil
                then
                    player.player_classified.MapExplorer:RevealArea(x, y, z)
                end
            end
        end
        GLOBAL.TheWorld:ListenForEvent("miniflare_detonated", function(world, data)
            FlareDoReveal(data)
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
