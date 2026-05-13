print('[Bernie] Starting Anti-Griefing module')

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
