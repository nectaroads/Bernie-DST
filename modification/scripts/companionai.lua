print('[Bernie] Starting Companion-AI module')

local config = GLOBAL.LoadConfig("companionai.lua")

GLOBAL.companion = nil
local companionleader = nil
local companionobjective = nil
local lastcompanionobjective = nil
local companiontarget = nil

local reacttime = 1.4
local available = true

local lastposition = { x = 0, y = 0, z = 0 }
local lastlocation = {}
local lastents = {}

local base = nil
local portal = nil

local unlock_prefabs = { berrybush = "gather", berrybush2 = "gather", sapling = "gather", grass = "gather", reeds = "gather" }
--local unlock_prefabs = { treasurechest = "organize", cookpot = "cook", evergreen_stump = "dig", mound = "dig", gravestone = "dig", deciduoustree_stump = "dig", evergreen_tall = "chop", evergreen_sparse_tall = "chop", livingtree = "chop", berrybush = "gather", berrybush2 = "gather", sapling = "gather", grass = "gather", reeds = "gather", rock1 = "mine", rock2 = "mine", rock_flintless = "mine", rock_moon = "mine", rock_ice = "mine" }

local ExecuteObjective = {}

local function HasInventorySpace()
    local inv = GLOBAL.companion.components.inventory
    local usedslots = 0
    local hasspace = true
    for k, v in pairs(inv.itemslots) do
        if v ~= nil then usedslots = usedslots + 1 end
    end
    if usedslots >= 10 then hasspace = false end
    print('[Willow] Inventory: Has space? ' .. tostring(hasspace))
    return hasspace
end

local function StopWork()
    if companionleader then
        ExecuteObjective["follow"]()
    else
        ExecuteObjective["explore"]()
    end
end

local function CheckObjective(objective)
    if companionobjective == objective then return true end
    return nil
end

local function RevealMapArea(x, z)
    print('[Willow] Finding: Revealing map...')
    for _, player in ipairs(GLOBAL.AllPlayers) do
        if player and player:IsValid() and player.player_classified and player.player_classified.MapExplorer then
            player.player_classified.MapExplorer:RevealArea(x, 0, z)
        end
    end
end

local function MoveCompanion(x, y, z)
    if not GLOBAL.TheWorld.Map:IsPassableAtPoint(x, y, z) then return false end
    GLOBAL.companion.components.locomotor:GoToPoint(GLOBAL.Vector3(x, y, z))
end

local function TeleportCompanion(position, leap)
    print('[Willow] Moving: Teleporting')
    GLOBAL.companion.Transform:SetPosition(position.x, position.y, position.z)
    GLOBAL.companion.AnimState:PlayAnimation("wakeup", false)
    local fx = GLOBAL.SpawnPrefab("woby_dash_shadow_fx")
    if fx then fx.Transform:SetPosition(position.x, position.y, position.z) end
    -- checkpoint: add sound?
end

local function InvestigateLocation(radius)
    print('[Willow] Finding: Something...')
    local base_findings = { research_found = false, research = { bookstation = true, researchlab1 = true, researchlab2 = true, researchlab3 = true }, fire_found = false, fire = { firepit = true } }
    local cx, cy, cz = GLOBAL.companion.Transform:GetWorldPosition()
    local ents = GLOBAL.TheSim:FindEntities(cx, cy, cz, radius, nil, { "INLIMBO" })
    for _, ent in ipairs(ents) do
        if base_findings.research[ent.prefab] then base_findings.research_found = true end
        if base_findings.fire[ent.prefab] then base_findings.fire_found = true end
    end
    if base_findings.research_found == true and base_findings.fire_found == true then base = { cx, cy, cz } end
    RevealMapArea(cx, cz)
    local location = { x = cx, y = cy, z = cz }
    lastlocation = location
    lastents = ents
end

local function FindObjective()
    print('[Willow] Finding: Work')
    local hastool = true
    local item = GLOBAL.companion.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
    if not item then
        hastool = false
        local inventory = GLOBAL.companion.components.inventory
        if inventory then
            for k, v in pairs(inventory.itemslots) do
                if v and v.components and v.components.equippable and v.components.equippable.equipslot == GLOBAL.EQUIPSLOTS.HANDS then
                    inventory:Equip(v)
                    hastool = true
                    break
                end
            end
        end
    end

    GLOBAL.companion:DoTaskInTime(reacttime, function()
        if not GLOBAL.companion or not GLOBAL.companion:IsValid() then return end
        InvestigateLocation(20)
        local work_allowed = { explore = true, slackoff = true }
        for _, ent in ipairs(lastents) do
            if unlock_prefabs[ent.prefab] then work_allowed[unlock_prefabs[ent.prefab]] = true end
        end
        if hastool == false then
            work_allowed.mine = false
            work_allowed.chop = false
            work_allowed.dig = false
        end
        if not HasInventorySpace() then
            work_allowed.gather = false
            work_allowed.mine = false
            work_allowed.chop = false
            work_allowed.dig = false
        end
        local pool = {}
        for work, allowed in pairs(work_allowed) do
            if allowed == true then table.insert(pool, work) end
        end
        local current_work = nil
        if #pool > 0 then current_work = pool[math.random(#pool)] end
        print('[Willow] Found: ' .. current_work)
        if ExecuteObjective[current_work] then ExecuteObjective[current_work]() else ExecuteObjective["explore"]() end
    end)
end

ExecuteObjective.gather = function()
    if CheckObjective("gather") then return end
    print('[Willow] Work: Gather')
    companionobjective = "gather"
    local loop = 0
    local function DoGather(target)
        if not CheckObjective("gather") then return end
        if not target or not target:IsValid() or not target.components.pickable or not target.components.pickable:CanBePicked() then
            if loop % 2 == 0 then
                if not HasInventorySpace then StopWork() end
            end
            if not lastents or #lastents <= 0 then InvestigateLocation(10) end
            local allowedprefabs = {}
            for prefab, work in pairs(unlock_prefabs) do
                if work == "gather" then allowedprefabs[prefab] = true end
            end
            for _, ent in ipairs(lastents) do
                if allowedprefabs[ent.prefab] then
                    target = ent
                    break
                end
            end
        end
        if not target or not target:IsValid() then
            StopWork()
            return
        end
        local action = GLOBAL.BufferedAction(GLOBAL.companion, target, GLOBAL.ACTIONS.PICK)
        if action:IsValid() then GLOBAL.companion.components.locomotor:PushAction(action, true) end
        loop = loop + 1
        if loop < 10 then
            DoGather(target)
            return
        end
        if companionleader and companionleader:IsValid() then
            StopWork()
            return
        end
        local dice = math.random(0, 1)
        if dice == 0 then
            StopWork()
            return
        end
        DoGather(target)
    end
    DoGather()
end

ExecuteObjective.follow = function()

end

ExecuteObjective.explore = function()
    if CheckObjective("explore") then return end
    print('[Willow] Work: Explore')
    companionobjective = "explore"
    local loop = 0
    local anchorx = math.random(-1000, 1000)
    local anchorz = math.random(-1000, 1000)
    local function IsNearAnchor(cx, cz)
        local dx = cx - anchorx
        local dz = cz - anchorz
        return (dx * dx + dz * dz) <= (30 * 30)
    end
    local function DoExplore()
        if not CheckObjective("explore") then return end
        if loop % 10 == 0 then
            local dice = math.random(0, 1)
            if dice == 0 then FindObjective() end
        end
        local cx, cy, cz = GLOBAL.companion.Transform:GetWorldPosition()
        if lastposition.x == cx and lastposition.z == cz then
            anchorx = math.random(-1000, 1000)
            anchorz = math.random(-1000, 1000)
        end
        if IsNearAnchor(cx, cz) then
            anchorx = math.random(-1000, 1000)
            anchorz = math.random(-1000, 1000)
        end
        local movex = math.random(-4, 4)
        local movez = math.random(-4, 4)
        if anchorx > 0 then movex = movex + 2 else movex = movex - 2 end
        if anchorz > 0 then movez = movez + 2 else movez = movez - 2 end
        MoveCompanion(cx + movex, cy, cz + movez)
        GLOBAL.companion:DoTaskInTime(1, function()
            loop = loop + 1
            DoExplore()
        end)
    end

    DoExplore()
end

ExecuteObjective.flee = function()

end

local tryspawn = false

local function SpawnCompanion()
    if GLOBAL.companion then return end
    if not GLOBAL.TheWorld then return end
    if not portal or not portal:IsValid() then
        for _, ent in pairs(GLOBAL.Ents) do
            if ent.prefab == "multiplayer_portal" or ent.prefab == "multiplayer_portal_moonrock" then portal = ent end
        end
    end
    if not portal then
        tryspawn = false
        return
    end
    print('[Willow] Spawning...')
    GLOBAL.companion = GLOBAL.SpawnPrefab((config and config.prefab) or "willow")
    if not GLOBAL.companion then return end
    --GLOBAL.companion.persists = true
    if GLOBAL.companion.components.health then GLOBAL.companion.components.health:SetInvincible(true) end
    if GLOBAL.companion.components.combat == nil then GLOBAL.companion:AddComponent("combat") end
    GLOBAL.companion.components.combat:SetDefaultDamage(34)
    GLOBAL.companion.components.combat:SetAttackPeriod(0.8)
    GLOBAL.companion.components.combat:SetRange(2)
    if GLOBAL.companion.components.inventory == nil then GLOBAL.companion:AddComponent("inventory") end
    if GLOBAL.companion.Physics then GLOBAL.companion.Physics:SetActive(true) end
    if GLOBAL.companion.entity then GLOBAL.companion.entity:SetCanSleep(false) end
    GLOBAL.companion:AddTag("notarget")
    GLOBAL.companion:AddTag("companion")
    GLOBAL.companion:AddTag("ghostlyfriend")
    local px, py, pz = portal.Transform:GetWorldPosition()
    TeleportCompanion({ x = px, y = py, z = pz })
    GLOBAL.companion:DoTaskInTime(3, function()
        ExecuteObjective["explore"]()
    end)
end

AddSimPostInit(function()
    AddPlayerPostInit(function(inst)
        inst:DoTaskInTime(5, function()
            if not inst or not inst:IsValid() then return end
            if GLOBAL.companion ~= nil then return end
            if tryspawn == true then return end
            tryspawn = true
            SpawnCompanion()
        end)
    end)
end)
