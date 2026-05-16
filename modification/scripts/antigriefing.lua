print('[Bernie] Starting Anti-Griefing module')

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

local ASH_RESTORE_VALUE = 3

local function ConvertAshes(inst, container)
    if container == nil or container.slots == nil then return end
    local ash_slots = {}
    for k, item in pairs(container.slots) do
        if item ~= nil and item.prefab == "ash" then table.insert(ash_slots, { slot = k, ash = item }) end
    end
    local wasconsumed = false
    for _, data in ipairs(ash_slots) do
        local ash = data.ash
        while ash ~= nil
            and ash:IsValid()
            and ash.components.stackable ~= nil
            and ash.components.stackable:StackSize() > 0
        do
            local restored_this_ash = 0
            for i = 1, ASH_RESTORE_VALUE do
                local prefab = GetFirstBurntItem()
                if prefab == nil then break end
                local item = GLOBAL.SpawnPrefab(prefab)
                if item ~= nil then
                    local accepted = container:GiveItem(item)
                    if not accepted then
                        local x, y, z = inst.Transform:GetWorldPosition()
                        item.Transform:SetPosition(x, y, z)
                    end
                    ConsumeBurntItem(prefab)
                    restored_this_ash = restored_this_ash + 1
                    wasconsumed = true
                else
                    break
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

if GLOBAL.TheNet:IsDedicated() then
    -- Rebuild burnt stuff
    GLOBAL.RebuildBurntStructure = function(target, doer)
        if target == nil or not target:IsValid() then return false end
        if not target:HasTag("burnt") then return false end
        local prefab = target.prefab
        local x, y, z = target.Transform:GetWorldPosition()
        local rot = target.Transform:GetRotation()
        target:Remove()
        local rebuilt = GLOBAL.SpawnPrefab(prefab)
        if rebuilt == nil then return false end
        rebuilt.Transform:SetPosition(x, y, z)
        rebuilt.Transform:SetRotation(rot)
        if rebuilt.SoundEmitter then rebuilt.SoundEmitter:PlaySound("dontstarve/common/place_structure_stone") end
        return true
    end
end

GLOBAL.STRINGS.ACTIONS.REBUILD_BURNT = "Repair"

local REBUILD_BURNT = AddAction("REBUILD_BURNT", "Repair", function(act)
    local target = act.target
    local doer = act.doer
    if target == nil or doer == nil then return false end
    if not target:HasTag("burnt") then return false end
    if not target:HasTag("structure") then return false end
    return GLOBAL.RebuildBurntStructure(target, doer)
end)

REBUILD_BURNT.priority = 3
REBUILD_BURNT.distance = 2
REBUILD_BURNT.mount_valid = true

AddComponentAction("SCENE", "inspectable", function(inst, doer, actions, right)
    if right and inst:HasTag("burnt") and inst:HasTag("structure") then table.insert(actions, GLOBAL.ACTIONS.REBUILD_BURNT) end
end)

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(GLOBAL.ACTIONS.REBUILD_BURNT, "dolongaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(GLOBAL.ACTIONS.REBUILD_BURNT, "dolongaction"))
