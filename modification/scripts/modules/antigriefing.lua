print('[Bernie] Starting Antigriefing module')

local isclient = not GLOBAL.TheNet:IsDedicated()

-- You can actually get burnt items back using Chester
local burntitems = {}

local function GetFirstBurntItem()
    for prefab, amount in pairs(burntitems) do
        if amount > 0 then return prefab end
    end
end

local function ConsumeBurntItem(prefab)
    if burntitems[prefab] == nil then return end
    burntitems[prefab] = burntitems[prefab] - 1
    if burntitems[prefab] <= 0 then burntitems[prefab] = nil end
end

local ASH_RESTORE_VALUE = 2

local function ConvertAshes(inst, container)
    local ignoredprefabs = { stinger = true, gunpowder = true }
    if container == nil or container.slots == nil then return end
    local ash_slots = {}
    for k, item in pairs(container.slots) do
        if item ~= nil and item.prefab == "ash" then table.insert(ash_slots, { slot = k, ash = item }) end
    end
    local wasconsumed = false
    for _, data in ipairs(ash_slots) do
        local ash = data.ash
        while ash ~= nil and ash:IsValid() and ash.components.stackable ~= nil and ash.components.stackable:StackSize() > 0
        do
            local restored_this_ash = 0
            for i = 1, ASH_RESTORE_VALUE do
                local prefab = GetFirstBurntItem()
                while prefab ~= nil and ignoredprefabs[prefab] do
                    ConsumeBurntItem(prefab)
                    prefab = GetFirstBurntItem()
                end
                if prefab == nil then break end
                local item = GLOBAL.SpawnPrefab(prefab)
                if item ~= nil then
                    if item.components.equippable ~= nil
                        or item.components.perishable ~= nil
                        or item.components.health ~= nil
                    then
                        item:Remove()
                        ConsumeBurntItem(prefab)
                    else
                        local accepted = container:GiveItem(item)
                        if not accepted then
                            local x, y, z = inst.Transform:GetWorldPosition()
                            item.Transform:SetPosition(x, y, z)
                        end
                        ConsumeBurntItem(prefab)
                        restored_this_ash = restored_this_ash + 1
                        wasconsumed = true
                    end
                else
                    ConsumeBurntItem(prefab)
                end
            end
            if restored_this_ash > 0 then
                ash.components.stackable:Get(1):Remove()
            else
                break
            end
            if GetFirstBurntItem() == nil then break end
        end
    end

    if wasconsumed == true then
        if inst.sg then inst.sg:GoToState("hit") end
        local x, y, z = inst.Transform:GetWorldPosition()
        local effect = GLOBAL.SpawnPrefab("shadow_merm_spawn_poof_fx")
        if effect then effect.Transform:SetPosition(x, y, z) end
    end
end

local function AddBurntItem(prefab, amount)
    if prefab == nil or prefab == "ash" then return end
    amount = amount or 1
    if burntitems[prefab] == nil then
        if GLOBAL.GetTableSize(burntitems) >= 10 then return end
        burntitems[prefab] = 0
    end
    burntitems[prefab] = burntitems[prefab] + amount
end

AddPrefabPostInit("chester", function(inst)
    if not GLOBAL.TheWorld.ismastersim then return end
    inst:DoTaskInTime(0, function()
        if inst.components.container == nil then return end
        local old_onclosefn = inst.components.container.onclosefn
        inst.components.container.onclosefn = function(inst, ...)
            if old_onclosefn ~= nil then old_onclosefn(inst, ...) end
            inst:DoTaskInTime(1, function()
                if inst and inst:IsValid() then
                    ConvertAshes(inst, inst.components.container)
                end
            end)
        end
    end)
end)

AddPrefabPostInitAny(function(inst)
    if not GLOBAL.TheWorld.ismastersim then return end
    inst:DoTaskInTime(0, function()
        if inst.components.inventoryitem == nil then return end
        if inst.components.burnable == nil then return end
        local old_onburnt = inst.components.burnable.onburnt
        inst.components.burnable:SetOnBurntFn(function(inst)
            local amount = 1
            if inst.components.stackable ~= nil then amount = inst.components.stackable:StackSize() end
            AddBurntItem(inst.prefab, amount)
            if old_onburnt ~= nil then old_onburnt(inst) end
        end)
    end)
end)

-- Repair Burnt

GLOBAL.STRINGS.ACTIONS.REBUILD_BURNT = "Repair"

local REBUILD_BURNT = AddAction("REBUILD_BURNT", "Repair", function(act)
    local target = act.target
    if target == nil or not target:IsValid() then return false end
    if not GLOBAL.TheWorld.ismastersim then return true end
    if not target:HasTag("burnt") then return false end
    local prefab = target.prefab
    local x, y, z = target.Transform:GetWorldPosition()
    local rot = target.Transform:GetRotation()
    target:Remove()
    local rebuilt = GLOBAL.SpawnPrefab(prefab)
    if rebuilt.SoundEmitter then rebuilt.SoundEmitter:PlaySound("dontstarve/common/place_structure_stone") end
    local fx = GLOBAL.SpawnPrefab("cavein_dust_low")
    if fx then
        fx.Transform:SetPosition(x, y, z)
        fx.Transform:SetScale(0.7, 0.7, 0.7)
        if fx.AnimState then fx.AnimState:SetMultColour(1, 1, 1, 0.4) end
    end
    if rebuilt == nil then return false end
    rebuilt.Transform:SetPosition(x, y, z)
    rebuilt.Transform:SetRotation(rot)
    return true
end)

REBUILD_BURNT.rmb = true
REBUILD_BURNT.priority = 10
REBUILD_BURNT.distance = 1

local function CanRepairBurnt(inst, doer, actions, right)
    if right and inst:HasTag("burnt") then table.insert(actions, REBUILD_BURNT) end
end

AddComponentAction("SCENE", "workable", CanRepairBurnt)

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(REBUILD_BURNT, "dolongaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(REBUILD_BURNT, "dolongaction"))
