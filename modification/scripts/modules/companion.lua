print('[Bernie] Starting Companion module')

local isclient = not GLOBAL.TheNet:IsDedicated()

-- Companion variables
local companion = {}

companion.inst = nil
companion.leader = nil
companion.busy = false
companion.base = nil
companion.loop = 0

companion.target = {}
companion.target.work = nil
companion.target.foe = nil

companion.objective = nil
companion.task = nil
companion.step = nil

companion.investigation = {}
companion.investigation.objects = {}
companion.investigation.lastpos = {}
companion.investigation.lasttask = nil

-- Brain constants
local STEPS = {}
STEPS.INVESTIGATE_AREA = nil
STEPS.REACH = nil
STEPS.INTERACT = nil
STEPS.COLLECT = nil
STEPS.ACT = nil
STEPS.ATTACK = nil
STEPS.SUPPORT = nil
STEPS.APPROACH = nil
STEPS.INSPECT = nil
STEPS.EMOTE = nil
STEPS.EAT = nil
STEPS.DROP = nil

local TASKS = {}
TASKS.EXPLORE = { STEPS = { "REACH", "REACH", "REACH", "INVESTIGATE_AREA", "INSPECT" } }
TASKS.FORAGE = { STEPS = { "INVESTIGATE_AREA", "REACH", "INTERACT" } }
TASKS.CLEAN = { STEPS = { "INVESTIGATE_AREA", "REACH", "COLLECT" } }
TASKS.WORK = { STEPS = { "INVESTIGATE_AREA", "REACH", "ACT", "COLLECT" } }
TASKS.JOIN = { STEPS = { "APPROACH" } }

local OBJECTIVES = {}
OBJECTIVES.SURVIVE = { "EXPLORE", "FORAGE", "WORK" }

-- Events
local function OnAttackIntent(inst, target)
end

local function OnAttackOther(inst, data)
    local target = data.target
    if not target then return end
end

-- Hooks
local function HookAttackIntent(inst)
    if not inst.components.locomotor or inst._attackintenthooked then return end
    inst._attackintenthooked = true
    local PushAction = inst.components.locomotor.PushAction
    inst.components.locomotor.PushAction = function(self, bufferedaction, run, try_instant)
        if bufferedaction ~= nil and bufferedaction.action == ACTIONS.ATTACK and bufferedaction.target ~= nil then OnAttackIntent(inst, bufferedaction.target) end
        return PushAction(self, bufferedaction, run, try_instant)
    end
end

-- Core
local function SpawnCompanion(player)
    if not GLOBAL.TheWorld or GLOBAL.TheWorld:HasTag("cave") then return end
    if companion.inst then return end

    local inst = nil
    -- Spawn companion
    if not inst then
        inst = GLOBAL.SpawnPrefab("willow")
        companion.inst = inst
    end

    if not inst then return end

    -- Core variables
    inst.persists = true
    -- Add components
    if not inst.components.combat then inst.AddComponent("combat") end
    if not inst.components.inventory then inst.AddComponent("inventory") end
    -- Change their components
    if inst.components.combat then
        inst.components.combat:SetDefaultDamage(34)
        inst.components.combat:SetAttackPeriod(0.5)
        inst.components.combat:SetRange(2)
    end
    if inst.inventory then
        inst.components.inventory:DisableDropOnDeath()
        inst.components.inventory:Open()
    end
    -- Change tags
    inst:RemoveTag("player")
    inst.AddTag("companion")
    inst:AddComponent("areaaware")
    -- Events
    --inst:ListenForEvent("onattackother", OnAttackOther)
    --inst:ListenForEvent("attacked", OnAttacked)
    --inst:ListenForEvent("death", OnDeath)
    --inst:ListenForEvent("healthdelta", OnSanityDelta)
    --inst:ListenForEvent("sanitydelta", OnSanityDelta)
    --inst:ListenForEvent("moisturedelta", OnMoistureDelta)
    --inst:ListenForEvent("temperaturedelta", OnTemperatureDelta)
    --inst:ListenForEvent("equip", OnEquip)
    --inst:ListenForEvent("unequip", OnUnequip)
    --inst:ListenForEvent("armorbroke", OnArmorBroke)
    --inst:ListenForEvent("itemget", OnItemGet)
    -- Hooks
    --HookAttackIntent(inst)
end

AddPlayerPostInit(function(inst)
    SpawnCompanion(inst)
end)
