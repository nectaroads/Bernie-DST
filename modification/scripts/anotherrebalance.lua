print('[Bernie] Starting Another-Rebalance module')

local config = GLOBAL.LoadConfig("anotherrebalance.lua")

-- Trinket slot
local Inv = require "widgets/inventorybar"

local trinkets = { compass = true, trinket_4 = true, trinket_13 = true }

Assets = Assets or {}
table.insert(Assets, Asset("IMAGE", "images/trinket.tex"))
table.insert(Assets, Asset("ATLAS", "images/trinket.xml"))

GLOBAL.EQUIPSLOTS.TRINKET = "trinket"

AddGlobalClassPostConstruct("widgets/inventorybar", "Inv", function()
    local Inv_Refresh_base = Inv.Refresh or function() return "" end
    local Inv_Rebuild_base = Inv.Rebuild or function() return "" end

    function Inv:LoadExtraSlots(self)
        self.bg:SetScale(1.35, 1, 1.25)
        self.bgcover:SetScale(1.35, 1, 1.25)

        if self.addextraslots == nil then
            self.addextraslots = 1

            self:AddEquipSlot(GLOBAL.EQUIPSLOTS.TRINKET, "images/trinket.xml", "trinket.tex")

            if self.inspectcontrol then
                local W = 68
                local SEP = 12
                local INTERSEP = 28
                local inventory = self.owner.replica.inventory
                local num_slots = inventory:GetNumSlots()
                local num_equip = #self.equipslotinfo
                local num_buttons = self.controller_build and 0 or 1
                local num_slotintersep = math.ceil(num_slots / 5)
                local num_equipintersep = num_buttons > 0 and 1 or 0
                local total_w = (num_slots + num_equip + num_buttons) * W + (num_slots + num_equip + num_buttons - num_slotintersep - num_equipintersep - 1) * SEP + (num_slotintersep + num_equipintersep) * INTERSEP
                self.inspectcontrol.icon:SetPosition(-4, 6)
                self.inspectcontrol:SetPosition((total_w - W) * .5 + 3, -6, 0)
            end
        end
    end

    function Inv:Refresh()
        Inv_Refresh_base(self)
        Inv:LoadExtraSlots(self)
    end

    function Inv:Rebuild()
        Inv_Rebuild_base(self)
        Inv:LoadExtraSlots(self)
    end
end)

AddPrefabPostInitAny(function(inst)
    if trinkets[inst.prefab] then
        inst:AddTag("trinket")
        if not GLOBAL.TheWorld.ismastersim then return inst end
        if inst.components.stackable ~= nil then inst:RemoveComponent("stackable") end
        if inst.components.equippable == nil then inst:AddComponent("equippable") end
        inst.components.equippable.equipslot = GLOBAL.EQUIPSLOTS.TRINKET
    end
end)

-- Compass HUD
AddClassPostConstruct("widgets/hudcompass", function(self)
    local function CheckTrinketCompass()
        if self.owner ~= nil and self.owner.replica.inventory ~= nil then
            local item = self.owner.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.TRINKET)
            if item ~= nil and (item:HasTag("compass") or item.prefab == "compass") then
                self:OpenCompass()
                return
            end
        end
        self:CloseCompass()
    end
    self.inst:ListenForEvent("equip", CheckTrinketCompass, self.owner)
    self.inst:ListenForEvent("unequip", CheckTrinketCompass, self.owner)
    self.inst:ListenForEvent("refreshinventory", CheckTrinketCompass, self.owner)
    self.inst:ListenForEvent("inventoryclosed", CheckTrinketCompass, self.owner)
    self.inst:DoTaskInTime(0, CheckTrinketCompass)
end)

local wigfridcombos = {}

local bosses = { leif_sparse = { name = "Sparse Treeguard", blacklist = {} }, leif = { name = "Treeguard", blacklist = {} }, spiderqueen = { name = "Grand Spider Queen", blacklist = { spider = true, spider_warrior = true, spider_water = true, spider_dropper = true, spider_healer = true, spider_spitter = true, spider_moon = true, spider_hider = true } }, alterguardian_phase1_lunarrift = { name = "Celestial Revenant", blacklist = {} }, alterguardian_phase4_lunarrift = { name = "Celestial Scion", blacklist = {} }, wagboss_robot = { name = "W.A.R.B.O.T", blacklist = {} }, mock_dragonfly = { name = "Wilting Dragonfly", blacklist = {} }, mothergoose = { name = "The Mother Goose", blacklist = {} }, moonmaw_dragonfly = { name = "Moonmaw Dragonfly", blacklist = {} }, hoodedwidow = { name = "The Hooded Widow", blacklist = {} }, eyeofterror = { name = "The Eye of Terror", blacklist = {} }, dragonfly = { name = "Mother Dragonfly", blacklist = {} }, moose = { name = "The Moose/Goose", blacklist = {} }, bearger = { name = "Dormant Bearger", blacklist = {} }, mutatedbearger = { name = "Armored Bearger", blacklist = {} }, enraged_klaus = { name = "Vengeful Klaus ⚠", blacklist = {} }, mutateddeerclops = { name = "Crystal Deerclops", blacklist = {} }, twinofterror2 = { name = "Hungry Spazmatism", blacklist = {} }, antlion = { name = "Desert Antlion", blacklist = {} }, toadstool_dark = { name = "Misery Toadstool ⚠", blacklist = {} }, enraged_dragonfly = { name = "Burning Dragonfly ⚠", blacklist = {} }, twinofterror1 = { name = "Seeker Retinazor", blacklist = {} }, stalker_atrium = { name = "Ancient Fuelweaver", blacklist = {} }, sharkboi = { name = "Defiant Frostjaw", blacklist = {} }, mutatedwarg = { name = "Possessed Warg", blacklist = {} }, shadow_knight = { name = "Shadow Knight", blacklist = {} }, shadow_bishop = { name = "Shadow Bishop", blacklist = {} }, beequeen = { name = "Royal Bee Queen", blacklist = { beeguard = true, bee = true, killerbee = true } }, crabking = { name = "Mighty Crab King", blacklist = {} }, deerclops = { name = "Chilling Deerclops", blacklist = {} }, daywalker = { name = "Nightmare Werepig", blacklist = {} }, minotaur = { name = "Ancient Guardian", blacklist = {} }, daywalker2 = { name = "Scrappy Werepig", blacklist = {} }, malbatross = { name = "Flying Malbatross", blacklist = {} }, shadow_rook = { name = "Shadow Rook", blacklist = {} }, klaus = { name = "Wicked Klaus", blacklist = {} }, toadstool = { name = "Grotto Toadstool", blacklist = {} }, alterguardian_phase3 = { name = "Celestial Champion", blacklist = {} } }
local aoecreatures = { tentacle = { name = "Tentacle", blacklist = {} } }

for k, v in pairs(bosses) do
    aoecreatures[k] = v
end

if GLOBAL.TheNet:IsDedicated() then
    local EventHandler = GLOBAL.EventHandler
    -- Tools
    local function DamagePlayer(target, total_damage)
        if not (target and target.components and target.components.health and target.components.inventory) then return end
        if target.components.health:IsDead() then return end
        local slots = { GLOBAL.EQUIPSLOTS.HEAD, GLOBAL.EQUIPSLOTS.BODY, GLOBAL.EQUIPSLOTS.HANDS }
        local remaining_damage = total_damage
        for _, slot in ipairs(slots) do
            local item = target.components.inventory:GetEquippedItem(slot)
            if item and item.components.armor then
                local absorb = item.components.armor.absorb_percent or 0
                local absorb_damage = total_damage * absorb
                item.components.armor:TakeDamage(absorb_damage * (item.components.armor.condition / item.components.armor.maxcondition))
                remaining_damage = remaining_damage - absorb_damage
            end
        end
        if remaining_damage > 0 then
            target.components.health:DoDelta(-remaining_damage, nil, "beefalo_impact")
        end
    end

    -- No Willow's friendly fire damage
    local Burnable = GLOBAL.require("components/burnable")
    local old_Ignite = Burnable.Ignite
    function Burnable:Ignite(immediate, source, doer)
        old_Ignite(self, immediate, source, doer)
        local controlled_burn_source = (doer ~= nil and doer:HasTag("controlled_burner")) or (source ~= nil and source:HasTag("controlled_burner"))
        if controlled_burn_source then self.stokeablefire = true end
    end

    local Health = GLOBAL.require("components/health")
    local old_DoFireDamage = Health.DoFireDamage
    function Health:DoFireDamage(amount, doer, instant)
        if self.inst ~= nil and self.inst:HasTag("player") and doer ~= nil and doer.components.burnable ~= nil and doer.components.burnable.stokeablefire then return end
        return old_DoFireDamage(self, amount, doer, instant)
    end

    -- Wonkey stuff
    local function IsValidMonkeyTarget(target)
        return target ~= nil and target.prefab ~= "wonkey"
    end

    local function MakeMonkeyNeutralToWonkey(inst)
        inst:DoTaskInTime(0, function()
            if inst.components.combat ~= nil then
                local old_retargetfn = inst.components.combat.targetfn
                inst.components.combat:SetRetargetFunction(3, function(monkey)
                    local target = old_retargetfn ~= nil and old_retargetfn(monkey) or nil
                    if IsValidMonkeyTarget(target) then return target end
                    return nil
                end)
            end
        end)
    end

    AddPrefabPostInit("monkey", MakeMonkeyNeutralToWonkey)
    AddPrefabPostInit("powder_monkey", MakeMonkeyNeutralToWonkey)

    AddPrefabPostInit("cursed_monkey_token", function(inst)
        inst:RemoveTag("nosteal")
        if not GLOBAL.TheWorld.ismastersim then return end
        inst:DoTaskInTime(0, function()
            if inst.components.inventoryitem ~= nil then
                inst.components.inventoryitem.canonlygoinpocket = false
                inst.components.inventoryitem.keepondrown = false
            end

            if inst.components.curseditem ~= nil then
                inst.components.curseditem.active = false
                inst.components.curseditem.cursed_target = nil
                inst.components.curseditem.target = nil
                inst:RemoveTag("applied_curse")
                inst:RemoveTag("cursed_inventory_item")
            end
        end)
    end)

    -- Player stuff
    local function OnEntityRevive(inst, data)
        if not inst then return end
        local victim = inst
        local cause = data and (data.source or data.reviver or data.doer or data.cause or data.afflicter)
        if inst:HasTag("player") then
            -- max health debuff
            if not (cause.prefab == "resurrectionstatue" or cause.prefab == "resurrectionstone") then
                if inst.components.health ~= nil then inst.components.health:DeltaPenalty(TUNING.HEART_HEALTH_PENALTY) end
                if inst.components.health ~= nil and cause.prefab == "multiplayer_portal" or cause.prefab == "multiplayer_portal_moonrock" then inst.components.health:DeltaPenalty(TUNING.HEART_HEALTH_PENALTY) end
            end
        end
    end

    -- Less annoying Willow gameplay, she gets ember automatically
    local willow_ember_common = require("prefabs/willow_ember_common")
    local _SpawnEmberAt = willow_ember_common.SpawnEmberAt

    willow_ember_common.SpawnEmberAt = function(x, y, z, victim, marksource)
        if marksource and victim ~= nil and victim._embersource ~= nil then
            local killer = victim._embersource
            if killer.prefab == "willow" and killer.components.inventory ~= nil and killer:IsValid() and not killer:HasTag("playerghost") then
                local ember = GLOBAL.SpawnPrefab("willow_ember")
                ember._embersource = killer
                killer.components.inventory:GiveItem(ember, nil, killer:GetPosition())
                return
            end
        end

        return _SpawnEmberAt(x, y, z, victim, marksource)
    end

    AddPrefabPostInit("willow_ember", function(inst)
        inst:ListenForEvent("onputininventory", function(inst, data)
            local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
            if owner == nil then return end
            local smallest = nil
            local count = 0
            for _, item in pairs(owner.components.inventory.itemslots) do
                if item ~= nil and item.prefab == "willow_ember" then
                    count = count + 1
                    if smallest == nil then
                        smallest = item
                    else
                        local itemsize = item.components.stackable ~= nil and item.components.stackable:StackSize() or 1
                        local smallestsize = smallest.components.stackable ~= nil and smallest.components.stackable:StackSize() or 1
                        if itemsize < smallestsize then smallest = item end
                    end
                end
            end
            if count > 1 and smallest ~= nil then owner.components.inventory:DropItem(smallest, true, true) end
        end)
    end)

    -- Dragonfly never gets stunned
    AddStategraphPostInit("dragonfly", function(sg)
        sg.events.stunned = EventHandler("stunned", function(inst)
            if inst.components.health ~= nil and not inst.components.health:IsDead() then
                inst:TransformFire()
                --inst.sg:GoToState("idle")
            end
        end)
    end)

    -- Damage rebalance
    local Combat = require("components/combat")
    local old_GetAttacked = Combat.GetAttacked
    local bossdamagehistory = {}
    function Combat:GetAttacked(attacker, damage, weapon, stimuli, spdamage)
        local inst = self.inst

        if inst then
            -- Walls resistance stuff
            if damage ~= nil and inst:HasTag("wall") then
                damage = damage * 0.1
            end

            if attacker and (attacker:HasTag("shadowcreature") or attacker:HasTag("shadow_aligned")) then
                -- Wolf is weaker against shadow creatures
                if inst and inst.prefab == "wolfgang" then
                    damage = damage * 1.25
                end
            end

            -- if it's Willow's skill, burn
            local willowskills = { willow_shadow_flame = true, flamethrower_fx = true }
            local iswillowskill = (weapon and willowskills[weapon.prefab]) or nil

            if iswillowskill and inst.components.burnable then
                if not inst:HasTag("player") then
                    inst.components.burnable:Ignite(nil, attacker)
                end
            end

            local rider = damage and damage > 0 and attacker and attacker.components.rideable and attacker.components.rideable:GetRider()

            if rider then
                print("rider found")
                print("rider prefab " .. rider.prefab)
            end

            -- If a boss is being attacked
            if inst:HasTag("epic") then
                -- Alone players are stronger against bosses
                if rider then
                    if not bossdamagehistory[inst.GUID] then bossdamagehistory[inst.GUID] = {} end
                    if not bossdamagehistory[inst.GUID][rider.GUID] then
                        bossdamagehistory[inst.GUID][rider.GUID] = true
                        if not bossdamagehistory[inst.GUID].size then bossdamagehistory[inst.GUID].size = 0 end
                        bossdamagehistory[inst.GUID].size = bossdamagehistory[inst.GUID].size + 1
                    end
                    if bossdamagehistory[inst.GUID].size <= 1 then damage = damage * 1.3 end
                end

                if attacker and attacker:HasTag("player") then
                    if not bossdamagehistory[inst.GUID] then bossdamagehistory[inst.GUID] = {} end
                    if not bossdamagehistory[inst.GUID][attacker.GUID] then
                        bossdamagehistory[inst.GUID][attacker.GUID] = true
                        if not bossdamagehistory[inst.GUID].size then bossdamagehistory[inst.GUID].size = 0 end
                        bossdamagehistory[inst.GUID].size = bossdamagehistory[inst.GUID].size + 1
                    end
                    if iswillowskill then
                        inst.components.health:DoDelta(-50 * 0.3, nil, "willow_skill_bonus", nil, attacker)
                    else
                        if bossdamagehistory[inst.GUID].size <= 1 then damage = damage * 1.3 end
                    end
                end
                if bossdamagehistory[inst.GUID] and damage >= inst.components.health.currenthealth then bossdamagehistory[inst.GUID] = nil end
            end

            -- If a boss is attacking
            if attacker and attacker:HasTag("epic") then
                -- Abby takes 50% less damage from bosses
                if inst.prefab == "abigail" then damage = damage * 0.3 end
            end

            -- If the target is a beefalo
            if inst.prefab == "beefalo" and damage and damage > 0 then
                -- If has a rider
                local rider = inst.components.rideable and inst.components.rideable:GetRider()
                if rider then
                    local riderdamage = damage * 0.10
                    damage = damage * 0.90
                    DamagePlayer(rider, riderdamage)
                    -- Walter can't stay, no more beefalo for you buddy!
                    if rider.prefab == "walter" then inst.components.rideable:Buck() end
                end
            end

            -- Extra true-damage when anything is frozen
            if inst.components.freezable and inst.components.freezable:IsFrozen() and damage and damage > 0 then
                local health = inst.components.health
                if health then
                    local bonus = math.floor(health.maxhealth * 0.1)
                    damage = damage + bonus
                end
            end

            -- Wigfrids scale damage with combos
            if damage and damage > 3 then
                if inst.prefab == "wathgrithr" then
                    wigfridcombos[inst.GUID] = 0
                else
                    if inst.components and inst.components.rideable ~= nil and inst.components.rideable.rider ~= nil and inst.components.rideable.rider.prefab == "wathgrithr" then
                        wigfridcombos[inst.GUID] = 0
                    end
                end

                if attacker and attacker.prefab == "wathgrithr" then
                    if not wigfridcombos[attacker.GUID] then wigfridcombos[attacker.GUID] = 0 end
                    wigfridcombos[attacker.GUID] = wigfridcombos[attacker.GUID] + 0.5
                    if wigfridcombos[attacker.GUID] > 20 then wigfridcombos[attacker.GUID] = 20 end

                    local mount = nil
                    if attacker.components.rider ~= nil then mount = attacker.components.rider:GetMount() end
                    if mount then damage = damage * 1.1 end

                    damage = damage + wigfridcombos[attacker.GUID]
                else
                    if attacker and attacker.components and attacker.components.rideable ~= nil and attacker.components.rideable.rider ~= nil and attacker.components.rideable.rider.prefab == "wathgrithr" then
                        damage = damage * 1.25
                        if not wigfridcombos[attacker.components.rideable.rider.GUID] then wigfridcombos[attacker.components.rideable.rider.GUID] = 0 end
                        wigfridcombos[attacker.components.rideable.rider.GUID] = wigfridcombos[attacker.components.rideable.rider.GUID] + 0.5
                        if wigfridcombos[attacker.components.rideable.rider.GUID] > 20 then wigfridcombos[attacker.components.rideable.rider.GUID] = 20 end
                        damage = damage + wigfridcombos[attacker.components.rideable.rider.GUID]
                    end
                end
            end

            if inst:HasTag("player") then
                -- Players are weaker when starving, freezing or overheating
                -- Players takes extra 2 true-damage if temperature is not comfy enough.
                if inst.components.temperature ~= nil then
                    local temp = inst.components.temperature
                    if temp:IsOverheating() or temp:IsFreezing() then
                        inst.components.health:DoDelta(-2, nil, "temp_bonus")
                    end
                end
                -- Players takes extra 2 true-damage if starving.
                if inst.components.hunger ~= nil then
                    if inst.components.hunger:GetPercent() < TUNING.HUNGRY_THRESH then
                        inst.components.health:DoDelta(-2, nil, "hunger_bonus")
                    end
                end
            end

            if attacker and attacker:HasTag("player") and damage and damage > 0 then
                -- Wanda pocketwatch horror damage partially ignores planar entity resistance
                if attacker.prefab == "wanda" then
                    local weapon = attacker.components.combat ~= nil and attacker.components.combat:GetWeapon() or nil
                    if weapon ~= nil and weapon.prefab == "pocketwatch_weapon" and (weapon.horrordamage or 0) > 0 and inst.components.planarentity ~= nil
                    then
                        local wanted_damage = damage
                        local full_pierce_damage = ((((wanted_damage / 4) + 8) ^ 2) - 64) / 4
                        damage = wanted_damage + ((full_pierce_damage - wanted_damage) * 0.6)
                        weapon.horrordamage = math.max((weapon.horrordamage or 0) - 1, 0)
                    end
                end

                local multiplier = 1
                -- Uncomfy players deal less damage.
                if attacker.components.temperature ~= nil then
                    local temp = attacker.components.temperature
                    if temp:IsOverheating() or temp:IsFreezing() then multiplier = multiplier * 0.9 end
                end
                -- Starving players deal less damage too.
                if attacker.components.hunger ~= nil and attacker.components.hunger:GetPercent() < TUNING.HUNGRY_THRESH then multiplier = multiplier * 0.9 end
                damage = math.floor(damage * multiplier + 0.5)
            end
        end

        return old_GetAttacked(self, attacker, damage, weapon, stimuli, spdamage)
    end

    -- Better backpacks
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

    -- Gnome Stuff, damn
    local function SpawnNear(inst, prefab, radius)
        local x, y, z = inst.Transform:GetWorldPosition()
        local offset = GLOBAL.FindWalkableOffset(GLOBAL.Vector3(x, y, z), math.random() * 2 * GLOBAL.PI, radius or math.random(2, 6), 8, true)
        if offset ~= nil then
            local obj = GLOBAL.SpawnPrefab(prefab)
            if obj ~= nil then
                obj.Transform:SetPosition(x + offset.x, 0, z + offset.z)
                local effect = GLOBAL.SpawnPrefab("bee_poof_big")
                effect.Transform:SetPosition(x + offset.x, 0, z + offset.z)
                return obj
            end
        end
    end

    local function GiveItem(inst, prefab)
        local item = GLOBAL.SpawnPrefab(prefab)
        if item ~= nil and inst.components.inventory ~= nil then
            inst.components.inventory:GiveItem(item)
            if inst.SoundEmitter then inst.SoundEmitter:PlaySound("yotb_2021/common/hitching_post/unhitching") end
        end
    end

    local function DropFirstItem(inst)
        if inst.components.inventory == nil then return end
        for k, item in pairs(inst.components.inventory.itemslots) do
            if item ~= nil then
                inst.components.inventory:DropItem(item, true, true)
                if inst.SoundEmitter then inst.SoundEmitter:PlaySound("yotb_2021/common/hitching_post/unhitching") end
                return
            end
        end
    end

    local function TeleportNearby(inst)
        local x, y, z = inst.Transform:GetWorldPosition()
        local offset = GLOBAL.FindWalkableOffset(GLOBAL.Vector3(x, y, z), math.random() * 2 * GLOBAL.PI, math.random(6, 12), 16, true)
        if offset ~= nil then
            local effect = GLOBAL.SpawnPrefab("woby_dash_shadow_fx")
            effect.Transform:SetPosition(x + offset.x, 0, z + offset.z)
            inst:DoTaskInTime(0.1, function()
                if not inst or not inst:IsValid() then return end
                inst.Transform:SetPosition(x + offset.x, 0, z + offset.z)
                local effect2 = GLOBAL.SpawnPrefab("shadow_merm_spawn_poof_fx")
                effect2.Transform:SetPosition(x + offset.x, 0, z + offset.z)
            end)
        end
    end

    local function DoGnomeEvent(trinket, inst, event)
        if event.message and trinket.components.talker then trinket.components.talker:Say(event.message) end
        if event.spawnnearby then SpawnNear(inst, event.spawnnearby, 4) end
        if event.spawnenemy then
            local enemy = SpawnNear(inst, event.spawnenemy, 5)
            if enemy and enemy.components.combat then enemy.components.combat:SetTarget(inst) end
        end
        if event.state and inst.sg then
            if inst.sg and (inst.components.rider == nil or not inst.components.rider:IsRiding()) then
                inst.sg:GoToState(event.state)
            end
        end
        if event.give then GiveItem(inst, event.give) end
        if event.drop then DropFirstItem(inst) end
        if event.teleport then TeleportNearby(inst) end
        if event.lightning then
            local x, y, z = inst.Transform:GetWorldPosition()
            GLOBAL.TheWorld:PushEvent("ms_sendlightningstrike", GLOBAL.Vector3(x, y, z))
        end
        if event.confusion then
            local x, y, z = inst.Transform:GetWorldPosition()
            local effect = GLOBAL.SpawnPrefab("woby_dash_shadow_fx")
            effect.Transform:SetPosition(x, y, z)
            inst.AnimState:SetScale(-0.9, -1.1, -1.1)
            inst:DoTaskInTime(10, function()
                if inst:IsValid() then inst.AnimState:SetScale(1, 1, 1) end
            end)
        end
        if event.wetness and inst.components.moisture then
            inst.components.moisture:DoDelta(event.wetness)
        end
        if event.health and inst.components.health then
            inst.components.health:DoDelta(event.health)
        end
        if event.sanity and inst.components.sanity then
            inst.components.sanity:DoDelta(event.sanity)
        end
        if event.temperature and inst.components.temperature then
            inst.components.temperature:DoDelta(event.temperature)
        end
    end

    AddSimPostInit(function()
        AddPlayerPostInit(function(inst)
            inst:ListenForEvent("itemget", OnPlayerItemGet)
            inst:ListenForEvent("equip", OnPlayerEquip)
            inst:ListenForEvent("respawnfromghost", OnEntityRevive)
            inst:ListenForEvent("respawnfromcorpse", OnEntityRevive)

            inst:DoPeriodicTask(28, function()
                local dice = math.random(0, 30)
                if dice % 3 == 0 then
                    local trinket = inst.components.inventory and inst.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.TRINKET)
                    if trinket == nil then return end
                    if trinket.prefab == "trinket_4" or trinket.prefab == "trinket_13" then
                        local events = config.gnomeevents
                        local keys = {}
                        for name in pairs(events) do
                            table.insert(keys, name)
                        end
                        local event = events[keys[math.random(#keys)]]
                        if event then DoGnomeEvent(trinket, inst, event) end
                    end
                end
            end)

            inst:DoTaskInTime(0, function()
                if inst and inst.userid and inst.components.maprevealable then inst.components.maprevealable:AddRevealSource(inst, "compassbearer") end
            end)
        end)
    end)

    local cachedPortal = nil

    local function FindMultiplayerPortal()
        if cachedPortal ~= nil and cachedPortal:IsValid() then return cachedPortal end
        for _, ent in pairs(GLOBAL.Ents) do
            if ent.prefab == "multiplayer_portal" or ent.prefab == "multiplayer_portal_moonrock" then
                cachedPortal = ent
                return ent
            end
        end
        return nil
    end

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

    local backpackPrefabs = { "backpack", "piggyback", "krampus_sack", "icepack", "seedpouch", "spicepack", "candybag" }

    for _, prefab in ipairs(backpackPrefabs) do
        AddPrefabPostInit(prefab, OnBackpackPostInit)
    end

    -- Prototyper range
    local function OnPrototyperPostInit(inst)
        local oldSetRadius = inst.SetRadius
        function inst:SetRadius(radius)
            oldSetRadius(inst, radius * 2)
        end
    end

    AddComponentPostInit("prototyper", OnPrototyperPostInit)

    -- Merm king can't be exploited
    local function OnMermKingPostInit(inst)
        inst:DoTaskInTime(0, function()
            inst.CallGuards = function() end
        end)
    end

    AddPrefabPostInit("mermking", OnMermKingPostInit)

    -- Climatic stuff
    AddPrefabPostInit("world", function(inst)
        inst:DoTaskInTime(0, function()
            inst.net:SetCustomTemp(0)
        end)
    end)

    -- Bosses rebalance
    for creature, _ in pairs(aoecreatures) do
        AddPrefabPostInit(creature, function(inst)
            inst:DoTaskInTime(0, function()
                local data = aoecreatures[inst.prefab]
                if data == nil or inst.components.combat == nil then return end
                local old_DoAttack = inst.components.combat.DoAttack
                inst.components.combat.DoAttack = function(combat, target, weapon, projectile, stimuli, instancemult)
                    if target == nil then return old_DoAttack(combat, target, weapon, projectile, stimuli, instancemult) end
                    if data.blacklist ~= nil and data.blacklist[target.prefab] then return end
                    local attacker = combat.inst
                    local range = attacker.hitrange or 3
                    old_DoAttack(combat, target, weapon, projectile, stimuli, instancemult)
                    combat:DoAreaAttack(target, range, weapon, function(guy) return not (guy ~= nil and data.blacklist ~= nil and data.blacklist[guy.prefab]) end, stimuli, nil, nil)
                end
            end)
        end)
    end

    -- Wanda rework
    local HORROR_DAMAGE_PER_FUEL = 50

    AddPrefabPostInit("pocketwatch_weapon", function(inst)
        if not GLOBAL.TheWorld.ismastersim then return end
        inst.horrordamage = inst.horrordamage or 0
        local old_OnSave = inst.OnSave
        inst.OnSave = function(inst, data)
            if old_OnSave ~= nil then old_OnSave(inst, data) end
            data.horrordamage = inst.horrordamage or 0
        end
        local old_OnLoad = inst.OnLoad
        inst.OnLoad = function(inst, data)
            if old_OnLoad ~= nil then old_OnLoad(inst, data) end
            inst.horrordamage = data ~= nil and data.horrordamage or 0
        end
        inst:DoTaskInTime(0, function(inst)
            if inst.components.fueled == nil or inst.components.fueled.TakeFuelItem == nil then return end
            local old_TakeFuelItem = inst.components.fueled.TakeFuelItem
            inst.components.fueled.TakeFuelItem = function(self, item, doer, ...)
                local is_horrorfuel = item ~= nil and item.prefab == "horrorfuel"
                local result = old_TakeFuelItem(self, item, doer, ...)
                if result and is_horrorfuel then
                    inst.horrordamage = (inst.horrordamage or 0) + HORROR_DAMAGE_PER_FUEL
                end
                return result
            end
        end)
    end)

    -- Change loottable
    local changeloot = {
        walrus = { { 'meat', 1.00 }, { 'blowdart_pipe', 0.5 }, { 'walrushat', 0.50 }, { 'walrus_tusk', 0.5 }, { 'walrus_tusk', 0.5 } },
        slurtle = { { 'slurtleslime', 1.00 }, { 'slurtle_shellpieces', 0.80 }, { 'slurtleslime', 0.80 }, { 'slurtlehat', 0.30 } },
        snurtle = { { 'slurtleslime', 1.00 }, { 'slurtle_shellpieces', 0.80 }, { 'slurtleslime', 0.80 }, { 'armorsnurtleshell', 0.80 } },
    }

    for prefab, loot in pairs(changeloot) do
        AddPrefabPostInit(prefab, function(inst)
            GLOBAL.SetSharedLootTable(prefab, loot)
            if inst.components.lootdropper ~= nil then
                inst.components.lootdropper:SetLoot({})
                inst.components.lootdropper:SetChanceLootTable(nil)
                inst.components.lootdropper:SetChanceLootTable(prefab)
            end
        end)
    end
end

for boss, _ in pairs(bosses) do
    AddPrefabPostInit(boss, function(inst)
        inst:DoTaskInTime(0, function()
            local data = bosses[inst.prefab]
            if not data then return end
            inst.name = data.name
            inst.displayname = data.name
            if not inst:HasTag("epic") then inst:AddTag("epic") end
        end)
    end)
end

-- Trinket gnomes
local gnomeprefabs = { "trinket_4", "trinket_13" }

for _, prefab in ipairs(gnomeprefabs) do
    AddPrefabPostInit(prefab, function(inst)
        inst:DoTaskInTime(0, function()
            if not inst or not inst:IsValid() then return end
            local TALK_LP = "summerevent/characters/crowkid/neutral"
            local function ontalk(inst)
                if inst.localsounds == nil then return end
                inst.localsounds.SoundEmitter:KillSound("talk")
                inst.localsounds.SoundEmitter:PlaySound(TALK_LP or "dontstarve/characters/woodie/lucytalk_LP", "talk")
            end

            local function ondonetalking(inst)
                if inst.localsounds ~= nil then inst.localsounds.SoundEmitter:KillSound("talk") end
            end

            if not GLOBAL.TheNet:IsDedicated() then
                inst.localsounds = GLOBAL.CreateEntity()
                inst.localsounds:AddTag("FX")
                inst.localsounds.entity:AddTransform()
                inst.localsounds.entity:AddSoundEmitter()
                inst.localsounds.entity:SetParent(inst.entity)
                inst.localsounds:Hide()
                inst.localsounds.persists = false
                inst:ListenForEvent("ontalk", ontalk)
                inst:ListenForEvent("donetalking", ondonetalking)
            end

            if inst.components.talker == nil then inst:AddComponent("talker") end

            inst.components.talker.fontsize = 32
            inst.components.talker.font = GLOBAL.TALKINGFONT
            inst.components.talker.colour = GLOBAL.Vector3(.9, .3, .3)
            inst.components.talker.offset = GLOBAL.Vector3(0, 0, 0)
            inst.components.talker.symbol = "swap_object"

            inst:DoPeriodicTask(48, function()
                if not inst or not inst:IsValid() then return end
                local dice = math.random(0, 1)
                if dice == 0 then
                    local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
                    local equipped = inst.components.equippable ~= nil and inst.components.equippable:IsEquipped()
                    if not equipped then
                        local gnomequotes = config.gnomequotes
                        local quote = gnomequotes[math.random(#gnomequotes)]
                        if quote ~= nil and inst.components.talker ~= nil then inst.components.talker:Say(quote) end
                    end
                end
            end)
        end)
    end)
end

-- New recipes
env.AddRecipe2("piggyback", { GLOBAL.Ingredient("pigskin", 6), GLOBAL.Ingredient("silk", 6), GLOBAL.Ingredient("rope", 4) }, GLOBAL.TECH.SCIENCE_TWO)
env.AddRecipe2("compass", { GLOBAL.Ingredient("goldnugget", 1), GLOBAL.Ingredient("marble", 1) }, GLOBAL.TECH.SCIENCE_TWO)

-- Tuning
TUNING.MONKEY_TOKEN_COUNTS.LEVEL_1 = 0
TUNING.MONKEY_TOKEN_COUNTS.LEVEL_2 = 2
TUNING.MONKEY_TOKEN_COUNTS.LEVEL_3 = 3
TUNING.MONKEY_TOKEN_COUNTS.LEVEL_4 = 5
TUNING.WES_DAMAGE_MULT = 1
TUNING.WES_WORK_MULTIPLIER = 1
TUNING.BALLOON_DAMAGE = 20
TUNING.BALLOON_ATTACK_RANGE = 3
TUNING.WONKEY_WALK_SPEED_PENALTY = 1.1
TUNING.WONKEY_SPEED_BONUS = 2.5
TUNING.WONKEY_TIME_TO_RUN = 2
TUNING.WONKEY_RUN_HUNGER_RATE_MULT = 1.1
TUNING.WILLOW_LUNAR_FIRE_COOLDOWN = 20
TUNING.WILLOW_LUNAR_FIRE_DAMAGE = 12
TUNING.WILLOW_LUNAR_FIRE_PLANAR_DAMAGE = 24
TUNING.WX78_MIN_MOISTURE_DAMAGE = -1
TUNING.WX78_MOVESPEED_CHIPBOOSTS = { 0.00, 0.10, 0.20, 0.30 }
TUNING.WOLFGANG_SANITY_NIGHT_DRAIN = 1.5
TUNING.WOLFGANG_SANITY_NIGHT_DRAIN_SMALL = 1.25
--TUNING.SHADOW_PILLAR_DURATION = 12
--TUNING.SHADOW_PILLAR_DURATION_BOSS = 6
--TUNING.SHADOW_PILLAR_DURATION_PLAYER = 3

TUNING.BEEFALO_HUNGER_RATE = TUNING.BEEFALO_HUNGER_RATE * 0.8
TUNING.BEEFALO_DOMESTICATION_ATTACKED_BY_PLAYER_DOMESTICATION = 0
TUNING.BEEFALO_DOMESTICATION_ATTACKED_DOMESTICATION = 0
TUNING.BEEFALO_DOMESTICATION_LOSE_DOMESTICATION = 0
TUNING.BEEFALO_DOMESTICATION_ATTACKED_OBEDIENCE = 0
TUNING.BEEFALO_DOMESTICATION_GAIN_DOMESTICATION = TUNING.BEEFALO_DOMESTICATION_GAIN_DOMESTICATION * 1.2
TUNING.BEEFALO_DOMESTICATION_BRUSHED_DOMESTICATION = TUNING.BEEFALO_DOMESTICATION_BRUSHED_DOMESTICATION * 1.2

TUNING.OCEANTREE_STAGES_TO_SUPERTALL = 2
TUNING.MAX_FIRE_DAMAGE_PER_SECOND = 160

TUNING.GRUEDAMAGE = 9999
TUNING.WALRUS_REGEN_PERIOD = TUNING.WALRUS_REGEN_PERIOD * 0.5
TUNING.CRAWLINGHORROR_HEALTH = 500
TUNING.CRAWLINGHORROR_DAMAGE = 60
TUNING.CRAWLINGHORROR_ATTACK_PERIOD = 1.5
TUNING.TERRORBEAK_SPEED = 9
TUNING.BEEGUARD_HEALTH = 140
TUNING.BEEGUARD_DASH_SPEED = 7
TUNING.BEEGUARD_SPEED = 4
TUNING.LAVAE_HEALTH = 140

TUNING.SHADOW_ROOK.HIT_RANGE = 2.5
TUNING.SHADOW_KNIGHT.ATTACK_RANGE_LONG = 3
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
TUNING.DRAGONFLY_ATTACK_RANGE = 5
TUNING.DRAGONFLY_SPEED = 4
TUNING.DRAGONFLY_FIRE_SPEED = 5
TUNING.DRAGONFLY_HIT_RANGE = 5
TUNING.DRAGONFLY_FIRE_HIT_RANGE = 5
TUNING.BEEQUEEN_DAMAGE = 200
TUNING.BEEQUEEN_SPEED = 3
TUNING.BEEQUEEN_ATTACK_PERIOD = 2
TUNING.BEEQUEEN_ATTACK_RANGE = 5
TUNING.BEEQUEEN_HIT_RANGE = 5
TUNING.BEEQUEEN_SPAWNGUARDS_CD = { 28, 26, 24, 22 }
TUNING.BEEQUEEN_FOCUSTARGET_CD = { 120, 60, 32, 24 }
TUNING.NO_BOSS_TIME = 16

TUNING.HEATROCK_NUMUSES = TUNING.HEATROCK_NUMUSES * 3
TUNING.HEAT_ROCK_CARRIED_BONUS_HEAT_FACTOR = 0.7
TUNING.EFFIGY_HEALTH_PENALTY = 0
TUNING.PIGGYBACK_SPEED_MULT = 1

TUNING.BUILD_DISTANCE = 0.6

TUNING.DAY_HEAT = 12
TUNING.NIGHT_COLD = -14
TUNING.SUMMER_RAIN_TEMP = -16
TUNING.MIN_ENTITY_TEMP = -32.5
TUNING.MAX_ENTITY_TEMP = 123.5
