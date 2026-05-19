-- So, I need to think how the AI will work...
-- The behavior will follow something like this: Directive > Task > Action

local config = GLOBAL.LoadConfig("companionai.lua")

-- Class itself
GLOBAL.companion = {
    entity = nil,
    target = nil,
    leader = nil,
    explorepos = nil,
    directive = "independent",
    task = "explore",
    action = nil,
    actionindex = 1,
    portal = nil,
    lastscan = {
        interests = {},
        location = nil
    }
}

local companion = GLOBAL.companion

-- CONSTS
local SCAN_RADIUS = 24
local RESCAN_DISTANCE = 24
local MAX_USED_INVENTORY_SLOTS = 10
local EXPLORE_MIN_DISTANCE = 18
local EXPLORE_MAX_DISTANCE = 36
local EXPLORE_TRIES = 20

-- Workable prefabs
local FORAGE_PREFABS = { grass = true, sapling = true, berrybush = true, berrybush2 = true, carrot_planted = true, red_mushroom = true, green_mushroom = true, blue_mushroom = true }
local MINE_PREFABS = { rock1 = true, rock2 = true, rock_flintless = true, rock_moon = true, stalagmite = true, stalagmite_tall = true, rock_ice = true }
local CHOP_PREFABS = { evergreen = true, evergreen_sparse = true, deciduoustree = true, twiggytree = true, moon_tree = true }
local DIG_PREFABS = { gravestone = true, mound = true, evergreen_stump = true, evergreen_sparse_stump = true, deciduoustree_stump = true, twiggytree_stump = true, moon_tree_stump = true }

local function IsForageable(ent)
    return ent ~= nil and ent:IsValid() and FORAGE_PREFABS[ent.prefab] and ent.components.pickable ~= nil and ent.components.pickable:CanBePicked()
end

local function IsMineable(ent)
    return ent ~= nil and ent:IsValid() and MINE_PREFABS[ent.prefab] and ent.components.workable ~= nil and ent.components.workable:CanBeWorked() and ent.components.workable.action == GLOBAL.ACTIONS.MINE
end

local function IsChoppable(ent)
    return ent ~= nil and ent:IsValid() and CHOP_PREFABS[ent.prefab] and ent.components.workable ~= nil and ent.components.workable:CanBeWorked() and ent.components.workable.action == GLOBAL.ACTIONS.CHOP
end

local function IsDiggable(ent)
    return ent ~= nil and ent:IsValid() and DIG_PREFABS[ent.prefab] and ent.components.workable ~= nil and ent.components.workable:CanBeWorked() and ent.components.workable.action == GLOBAL.ACTIONS.DIG
end

local directives = {
    independent = {
        explore = true,
        forage = true,
        mine = true,
        chop = true,
        dig = true,
    }
}

local tasks = {
    explore = {
        distance = 3,
        weight = 3,
        actions = {
            "find_explore_position",
            "go_to_explore_position",
            "inspect_nearby",
        }
    },
    forage = {
        filters = IsForageable,
        distance = 3,
        weight = 2,
        actions = {
            "find_target",
            "go_to_target",
            "collect_target",
        }
    },
    mine = {
        filters = IsMineable,
        distance = 3,
        weight = 1,
        actions = {
            "find_target",
            "go_to_target",
            "mine_target",
            "collect_nearby",
        }
    },
    chop = {
        filters = IsChoppable,
        distance = 3,
        weight = 1,
        actions = {
            "find_target",
            "go_to_target",
            "chop_target",
            "find_dig_target_nearby",
            "go_to_target",
            "dig_target",
            "collect_nearby",
        }
    },
    dig = {
        filters = IsDiggable,
        distance = 3,
        weight = 1,
        actions = {
            "find_target",
            "go_to_target",
            "dig_target",
            "collect_nearby",
        }
    }
}

local function FindExplorePosition()
    print("[Willow] Finding explore position...")
    local inst = companion.entity
    if not inst or not inst:IsValid() then return false end
    local map = GLOBAL.TheWorld.Map
    local x, y, z = inst.Transform:GetWorldPosition()
    for i = 1, EXPLORE_TRIES do
        local angle = math.random() * 2 * GLOBAL.PI
        local distance = EXPLORE_MIN_DISTANCE + math.random() * (EXPLORE_MAX_DISTANCE - EXPLORE_MIN_DISTANCE)
        local px = x + math.cos(angle) * distance
        local pz = z + math.sin(angle) * distance
        if map:IsPassableAtPoint(px, 0, pz) and not map:IsGroundTargetBlocked(GLOBAL.Vector3(px, 0, pz)) then
            companion.explorepos = GLOBAL.Vector3(px, 0, pz)
            return true
        end
    end
    companion.explorepos = nil
    return false
end

local function GoToExplorePosition(distance)
    print("[Willow] Going to explore position...")
    local inst = companion.entity
    local pos = companion.explorepos
    if not inst or not inst:IsValid() then return false end
    if pos == nil then return false end
    if inst.components.locomotor == nil then return false end
    if inst:GetDistanceSqToPoint(pos.x, pos.y, pos.z) <= (distance or 3) * (distance or 3) then return true end
    inst.components.locomotor:GoToPoint(pos)
    return false
end

local function GetEquippedSlots()
    local inst = companion.entity
    local result = {}
    if not inst or not inst:IsValid() or inst.components.inventory == nil then return result end
    for slotname, slotid in pairs(GLOBAL.EQUIPSLOTS) do
        result[slotname] = inst.components.inventory:GetEquippedItem(slotid)
    end
    return result
end

local function HasInventorySpace()
    local inst = companion.entity
    if not inst or not inst:IsValid() or inst.components.inventory == nil then return false end
    local inv = inst.components.inventory
    local used = 0
    local maxslots = inv:GetNumSlots()
    for slot = 1, maxslots do
        if inv.itemslots[slot] ~= nil then used = used + 1 end
    end
    return used < MAX_USED_INVENTORY_SLOTS
end

local function TryEquipMissingSlots()
    local inst = companion.entity
    if not inst or not inst:IsValid() or inst.components.inventory == nil then return end
    local inv = inst.components.inventory
    for slotname, slotid in pairs(GLOBAL.EQUIPSLOTS) do
        local equipped = inv:GetEquippedItem(slotid)
        if equipped == nil then
            for _, item in pairs(inv.itemslots) do
                if item ~= nil and item.components.equippable ~= nil and item.components.equippable.equipslot == slotid then
                    inv:Equip(item)
                    break
                end
            end
        end
    end
end

local function GetCompanionPosition()
    if not companion.entity or not companion.entity:IsValid() then return nil end
    return companion.entity:GetPosition()
end

local function ShouldRescan()
    local pos = GetCompanionPosition()
    if pos == nil then return false end
    if companion.lastscan.location == nil then return true end
    return pos:DistSq(companion.lastscan.location) >= RESCAN_DISTANCE * RESCAN_DISTANCE
end

local function ScanNearby()
    local inst = companion.entity
    if not inst or not inst:IsValid() then return {} end
    local pos = inst:GetPosition()
    companion.lastscan.location = pos
    companion.lastscan.interests = GLOBAL.TheSim:FindEntities(pos.x, pos.y, pos.z, SCAN_RADIUS, nil, { "INLIMBO", "NOCLICK", "FX" })
    return companion.lastscan.interests
end

local function FindDigTargetNearby()
    ScanNearby()
    local interests = companion.lastscan.interests
    local inst = companion.entity
    local best = nil
    local bestdist = nil
    for i = #interests, 1, -1 do
        local ent = interests[i]
        if ent == nil or not ent:IsValid() then
            table.remove(interests, i)
        elseif IsDiggable(ent) then
            local dist = inst:GetDistanceSqToInst(ent)
            if best == nil or dist < bestdist then
                best = ent
                bestdist = dist
            end
        end
    end
    companion.target = best
    return best
end

local function FindInterest(filterfn)
    print("[Willow] Finding interest...")
    local interests = companion.lastscan.interests
    if ShouldRescan() then interests = ScanNearby() end
    for i = #interests, 1, -1 do
        local ent = interests[i]
        if ent == nil or not ent:IsValid() then
            table.remove(interests, i)
        elseif filterfn(ent) then
            companion.target = ent
            return ent
        end
    end
    interests = ScanNearby()
    for i = #interests, 1, -1 do
        local ent = interests[i]
        if ent == nil or not ent:IsValid() then
            table.remove(interests, i)
        elseif filterfn(ent) then
            companion.target = ent
            return ent
        end
    end
    companion.target = nil
    return nil
end

local function GoToTarget(distance)
    print("[Willow] Going to target...")
    local inst = companion.entity
    local target = companion.target
    if not inst or not inst:IsValid() then return false end
    if not target or not target:IsValid() then return false end
    if inst.components.locomotor == nil then return false end
    if inst:GetDistanceSqToInst(target) <= (distance or 2) * (distance or 2) then return true end
    inst.components.locomotor:GoToPoint(target:GetPosition())
    return false
end

local function DoBufferedAction(action, target, cleartarget)
    local inst = companion.entity
    if companion.actionbusy then return true end
    if not inst or not inst:IsValid() then return false end
    if not target or not target:IsValid() then return false end
    if inst.components.locomotor == nil then return false end
    companion.actionbusy = true
    local ba = GLOBAL.BufferedAction(inst, target, action)
    ba:AddSuccessAction(function()
        companion.actionbusy = false
        if cleartarget then companion.target = nil end
    end)
    ba:AddFailAction(function() companion.actionbusy = false end)
    inst.components.locomotor:PushAction(ba, true)
    return true
end

local function PickTarget()
    print("[Willow] Picking target...")
    local target = companion.target
    if not IsForageable(target) then
        companion.target = nil
        return false
    end
    return DoBufferedAction(GLOBAL.ACTIONS.PICK, target, true)
end

local function MineTarget()
    print("[Willow] Mining target...")
    local target = companion.target
    if target == nil or not target:IsValid() then
        companion.target = nil
        return "done"
    end
    if not IsMineable(target) then
        companion.target = nil
        return "done"
    end
    DoBufferedAction(GLOBAL.ACTIONS.MINE, target, false)
    return "running"
end

local function ChopTarget()
    print("[Willow] Chopping target...")
    local target = companion.target
    if target == nil or not target:IsValid() then
        companion.target = nil
        return "done"
    end
    if not IsChoppable(target) then
        companion.target = nil
        return "done"
    end
    DoBufferedAction(GLOBAL.ACTIONS.CHOP, target, false)
    return "running"
end

local function DigTarget()
    print("[Willow] Digging target...")
    local target = companion.target
    if target == nil or not target:IsValid() then
        companion.target = nil
        return "done"
    end
    if not IsDiggable(target) then
        companion.target = nil
        return "done"
    end
    DoBufferedAction(GLOBAL.ACTIONS.DIG, target, false)
    return "running"
end

local function IsCollectable(ent)
    return ent ~= nil and ent:IsValid() and ent.components.inventoryitem ~= nil and ent.components.inventoryitem.canbepickedup and not ent:IsInLimbo() and not ent:HasTag("INLIMBO") and not ent:HasTag("NOCLICK") and ent.entity:IsVisible()
end

local function FindNearbyCollectable()
    local interests = companion.lastscan.interests
    if ShouldRescan() then interests = ScanNearby() end
    local inst = companion.entity
    local best = nil
    local bestdist = nil
    for i = #interests, 1, -1 do
        local ent = interests[i]
        if ent == nil or not ent:IsValid() then
            table.remove(interests, i)
        elseif IsCollectable(ent) then
            local dist = inst:GetDistanceSqToInst(ent)
            if best == nil or dist < bestdist then
                best = ent
                bestdist = dist
            end
        end
    end
    return best
end

local function CollectNearby()
    print("[Willow] Collecting nearby...")
    if not HasInventorySpace() then
        companion.target = nil
        return "done"
    end
    if companion.actionbusy then return "running" end
    if companion.target ~= nil and companion.target:IsValid() and IsCollectable(companion.target) then
        DoBufferedAction(GLOBAL.ACTIONS.PICKUP, companion.target, true)
        return "running"
    end
    ScanNearby()
    local item = FindNearbyCollectable()
    if item == nil then
        companion.target = nil
        return "done"
    end
    companion.target = item
    DoBufferedAction(GLOBAL.ACTIONS.PICKUP, item, true)
    return "running"
end

local function SetTask(taskname)
    if taskname == nil then return end
    TryEquipMissingSlots()
    companion.task = taskname
    companion.action = nil
    companion.actionindex = 1
    companion.target = nil
end

local function TeleportCompanion(position)
    companion.entity.Transform:SetPosition(position.x, position.y, position.z)
    companion.entity.AnimState:PlayAnimation("wakeup", false)
    local fx = GLOBAL.SpawnPrefab("woby_dash_shadow_fx")
    if fx then fx.Transform:SetPosition(position.x, position.y, position.z) end
end

local function EstablishPortal()
    if not companion.portal or not companion.portal:IsValid() then
        for _, ent in pairs(GLOBAL.Ents) do
            if ent.prefab == "multiplayer_portal" or ent.prefab == "multiplayer_portal_moonrock" then
                companion.portal = ent
                return true
            end
        end
    end
    return nil
end

local function FindInspectable()
    local interests = companion.lastscan.interests
    if ShouldRescan() then interests = ScanNearby() end
    local inst = companion.entity
    local best = nil
    local bestdist = nil
    for i = #interests, 1, -1 do
        local ent = interests[i]
        if ent == nil or not ent:IsValid() then
            table.remove(interests, i)
        elseif not ent:HasTag("FX")
            and not ent:HasTag("NOCLICK")
            and ent.entity:IsVisible() then
            local dist = inst:GetDistanceSqToInst(ent)
            if best == nil or dist < bestdist then
                best = ent
                bestdist = dist
            end
        end
    end
    return best
end

local actions = {
    find_target = function(taskdata)
        return FindInterest(taskdata.filters) ~= nil and "done" or "failed"
    end,

    go_to_target = function(taskdata)
        return GoToTarget(taskdata.distance or 2) and "done" or "running"
    end,

    collect_target = function(taskdata)
        return PickTarget() and "done" or "failed"
    end,

    mine_target = function(taskdata)
        return MineTarget()
    end,

    chop_target = function(taskdata)
        return ChopTarget()
    end,

    find_dig_target_nearby = function(taskdata)
        return FindDigTargetNearby() ~= nil and "done" or "done"
    end,

    dig_target = function(taskdata)
        return DigTarget()
    end,

    collect_nearby = function(taskdata)
        return CollectNearby()
    end,

    find_explore_position = function(taskdata)
        return FindExplorePosition() and "done" or "failed"
    end,

    go_to_explore_position = function(taskdata)
        return GoToExplorePosition(taskdata.distance or 3) and "done" or "running"
    end,

    inspect_nearby = function(taskdata)
        print("[Willow] Inspecting nearby...")
        local inst = companion.entity
        if not inst or not inst:IsValid() then return "failed" end
        local target = FindInspectable()
        if target ~= nil then
            inst:FacePoint(target.Transform:GetWorldPosition())
            companion.memory = companion.memory or {}
            companion.memory.lastinspect = target
        end
        companion.explorepos = nil
        return "done"
    end,
}

local function ChooseAllowedTask()
    local allowed = directives[companion.directive]
    if allowed == nil then return nil end
    local pool = {}
    local totalweight = 0
    for taskname, enabled in pairs(allowed) do
        local taskdata = tasks[taskname]
        if enabled and taskdata ~= nil then
            local weight = taskdata.weight or 1
            if weight > 0 then
                totalweight = totalweight + weight
                table.insert(pool, { name = taskname, weight = weight, })
            end
        end
    end
    if totalweight <= 0 then return nil end
    local roll = math.random() * totalweight
    local acc = 0
    for _, entry in ipairs(pool) do
        acc = acc + entry.weight
        if roll <= acc then return entry.name end
    end
    return pool[#pool].name
end

local function UpdateCompanion()
    local inst = companion.entity
    if not inst or not inst:IsValid() then return end
    local allowed = directives[companion.directive]
    if allowed == nil then return end
    if companion.task == nil or not allowed[companion.task] or tasks[companion.task] == nil then SetTask(ChooseAllowedTask()) end
    local taskdata = tasks[companion.task]
    if taskdata == nil then return end
    local actionname = taskdata.actions[companion.actionindex]
    if actionname == nil then
        SetTask(ChooseAllowedTask())
        return
    end
    companion.action = actionname
    local actionfn = actions[actionname]
    if actionfn == nil then
        companion.actionindex = companion.actionindex + 1
        return
    end
    local result = actionfn(taskdata)
    if result == "done" then
        companion.actionindex = companion.actionindex + 1
    elseif result == "failed" then
        SetTask(ChooseAllowedTask())
    elseif result == "running" then
        return
    end
end

local function SpawnCompanion()
    if not GLOBAL.TheWorld then return end
    if not EstablishPortal() then return end

    companion.entity = GLOBAL.SpawnPrefab((config and config.prefab) or "wilson")
    if not companion.entity then return end

    if companion.entity.components.health then companion.entity.components.health:SetInvincible(true) end
    if companion.entity.components.combat == nil then companion.entity:AddComponent("combat") end
    companion.entity.components.combat:SetDefaultDamage(34)
    companion.entity.components.combat:SetAttackPeriod(0.6)
    companion.entity.components.combat:SetRange(2)

    if companion.entity.components.inventory == nil then companion.entity:AddComponent("inventory") end

    if companion.entity.Physics then companion.entity.Physics:SetActive(true) end
    if companion.entity.entity then companion.entity.entity:SetCanSleep(false) end
    --GLOBAL.companion.persists = true

    companion.entity:AddTag("notarget")
    companion.entity:AddTag("companion")
    companion.entity:AddTag("ghostlyfriend")

    local px, py, pz = companion.portal.Transform:GetWorldPosition()
    TeleportCompanion({ x = px, y = py, z = pz })

    companion.entity:DoTaskInTime(3, function()
        if not companion.entity or not companion.entity:IsValid() then return end
        companion.entity:DoPeriodicTask(0.5, function()
            if not companion.entity or not companion.entity:IsValid() then return end
            UpdateCompanion()
        end)
    end)
end

AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(5, function()
        if not inst or not inst:IsValid() then return end
        if companion.entity and companion.entity:IsValid() then return end
        SpawnCompanion()
    end)
end)
