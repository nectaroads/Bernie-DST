print('[Bernie] Starting Fancy-RPC module')

local bosslasthit = {}
local world = nil

local function OnNetworkingSay(guid, userid, name, prefab, message, colour, whisper, isemote, iscave)
    local jsonEncoded = GLOBAL.json.encode({ key = "player_message", userid = userid, username = name, prefab = prefab, message = message, whisper = whisper, cave = iscave })
    GLOBAL.SendRequest(jsonEncoded)
end

AddSimPostInit(function()
    if GLOBAL.TheWorld then
        local NETWORKING_SAY = GLOBAL.Networking_Say
        GLOBAL.Networking_Say = function(guid, userid, name, prefab, message, colour, whisper, isemote)
            OnNetworkingSay(guid, userid, name, prefab, message, colour, whisper, isemote, GLOBAL.TheWorld:HasTag("cave"))
            return NETWORKING_SAY(guid, userid, name, prefab, message, colour, whisper, isemote)
        end
    end
end)

local Combat = require("components/combat")
local old_GetAttacked = Combat.GetAttacked
function Combat:GetAttacked(attacker, damage, weapon, stimuli, spdamage)
    local inst = self.inst
    if inst then
        if inst:HasTag("epic") and attacker and GLOBAL.TheWorld then
            bosslasthit[inst.GUID] = attacker
        end
    end
    return old_GetAttacked(self, attacker, damage, weapon, stimuli, spdamage)
end

local function PickWitness(exclude_userid)
    local users = GLOBAL.GetUsers()
    if exclude_userid and users[exclude_userid] then users[exclude_userid] = nil end
    local pool = {}
    for _, user in pairs(users) do table.insert(pool, user) end
    return #pool > 0 and pool[math.random(#pool)] or nil
end

local function GetSafeName(ent)
    return ent and (ent.name or (ent.GetDisplayName and ent:GetDisplayName()) or ent.prefab) or "???"
end

local function OnEntityDeath(ent, data)
    if not data then return end
    local victim = ent or (data and data.inst) or data or nil
    local cause = data.afflicter or data.cause or data.source or data.instigator or bosslasthit[victim.GUID] or nil
    local users = GLOBAL.GetUsers()
    if not victim then return end
    if victim:HasTag("epic") then
        GLOBAL.ExecuteOnAllShards({ key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "server", sound = "summerevent2022/carnivalgame_puckdrop/endbell", message = ("★ " .. GetSafeName(victim) .. " foi derrotado ★") or "error" })
        local jsonEncoded = GLOBAL.json.encode({ key = "epic_death", prefab = victim.prefab, victim = GetSafeName(victim), cause = cause and GetSafeName(cause) or "???", witness = PickWitness(cause.userid), users = users })
        GLOBAL.SendRequest(jsonEncoded)
        bosslasthit[victim.GUID] = nil
    else
        if victim:HasTag("player") then
            local jsonEncoded = GLOBAL.json.encode({ key = "player_death", victim = GetSafeName(victim), cause = GetSafeName(cause), witness = PickWitness(victim.userid), users = users })
            GLOBAL.SendRequest(jsonEncoded)
        end
    end
end

local function OnEntityRevive(inst, data)
    if not inst then return end
    local victim = inst
    local cause = data and (data.source or data.reviver or data.doer or data.cause or data.afflicter)
    GLOBAL.DumpTable(cause)
    if inst:HasTag("player") then
        local users = GLOBAL.GetUsers()
        local jsonEncoded = GLOBAL.json.encode({ key = "player_revive", victim = GetSafeName(victim), cause = GetSafeName(cause), witness = PickWitness(inst.userid), users = users })
        GLOBAL.SendRequest(jsonEncoded)
    end
end

local bosses = { spiderqueen = { name = "High Weaver", blacklist = { spider = true, spider_warrior = true, spider_water = true, spider_dropper = true, spider_healer = true, spider_spitter = true, spider_moon = true, spider_hider = true } }, alterguardian_phase1_lunarrift = { name = "Celestial Revenant", blacklist = {} }, alterguardian_phase4_lunarrift = { name = "Celestial Scion", blacklist = {} }, wagboss_robot = { name = "W.A.R.B.O.T", blacklist = {} }, mock_dragonfly = { name = "Wilting Dragonfly", blacklist = {} }, mothergoose = { name = "The Mother Goose", blacklist = {} }, moonmaw_dragonfly = { name = "Moonmaw Dragonfly", blacklist = {} }, hoodedwidow = { name = "The Hooded Widow", blacklist = {} }, eyeofterror = { name = "The Eye of Terror", blacklist = {} }, dragonfly = { name = "Mother Dragonfly", blacklist = {} }, moose = { name = "The Moose/Goose", blacklist = {} }, bearger = { name = "Dormant Bearger", blacklist = {} }, mutatedbearger = { name = "Armored Bearger", blacklist = {} }, enraged_klaus = { name = "Vengeful Klaus ⚠", blacklist = {} }, mutateddeerclops = { name = "Crystal Deerclops", blacklist = {} }, twinofterror2 = { name = "Hungry Spazmatism", blacklist = {} }, antlion = { name = "Desert Antlion", blacklist = {} }, toadstool_dark = { name = "Misery Toadstool ⚠", blacklist = {} }, enraged_dragonfly = { name = "Burning Dragonfly ⚠", blacklist = {} }, twinofterror1 = { name = "Seeker Retinazor", blacklist = {} }, stalker_atrium = { name = "Ancient Fuelweaver", blacklist = {} }, sharkboi = { name = "Defiant Frostjaw", blacklist = {} }, mutatedwarg = { name = "Possessed Warg", blacklist = {} }, shadow_knight = { name = "Shadow Knight", blacklist = {} }, shadow_bishop = { name = "Shadow Bishop", blacklist = {} }, beequeen = { name = "Royal Bee Queen", blacklist = {} }, crabking = { name = "Mighty Crab King", blacklist = {} }, deerclops = { name = "Chilling Deerclops", blacklist = {} }, daywalker = { name = "Nightmare Werepig", blacklist = {} }, minotaur = { name = "Ancient Guardian", blacklist = {} }, daywalker2 = { name = "Scrappy Werepig", blacklist = {} }, malbatross = { name = "Flying Malbatross", blacklist = {} }, shadow_rook = { name = "Shadow Rook", blacklist = {} }, klaus = { name = "Wicked Klaus", blacklist = {} }, toadstool = { name = "Grotto Toadstool", blacklist = {} }, alterguardian_phase3 = { name = "Celestial Champion", blacklist = {} } }

for boss, _ in pairs(bosses) do
    AddPrefabPostInit(boss, function(inst)
        inst:DoTaskInTime(0, function()
            if not inst then return end
            inst:ListenForEvent("death", OnEntityDeath)
            if inst.MakeDefeated then
                local old_MakeDefeated = inst.MakeDefeated
                function inst:MakeDefeated()
                    OnEntityDeath(nil, { inst = inst })
                    return old_MakeDefeated(inst)
                end
            end
            if inst.MakeTrader then
                local old_MakeTrader = inst.MakeTrader
                function inst:MakeTrader()
                    OnEntityDeath(nil, { inst = inst })
                    return old_MakeTrader(inst)
                end
            end
        end)
    end)
end

AddSimPostInit(function()
    AddPlayerPostInit(function(inst)
        inst:ListenForEvent("death", OnEntityDeath)
        inst:ListenForEvent("respawnfromghost", OnEntityRevive)
        inst:ListenForEvent("respawnfromcorpse", OnEntityRevive)
    end)
end)

local currentCycle = -1

local function OnCycleChange(inst)
    if GLOBAL.TheWorld and GLOBAL.TheWorld:HasTag("cave") then return end
    local cycle = inst.state.cycles
    if currentCycle == cycle then return end
    local users = GLOBAL.GetUsers()
    local jsonEncoded = GLOBAL.json.encode({ key = "world_cycle", states = inst.state, users = users })
    GLOBAL.SendRequest(jsonEncoded)
    currentCycle = cycle
end

local function OnPlayerJoined(inst, player)
    local iscave = GLOBAL.TheWorld:HasTag("cave")
    if player and player.userid then
        local state = GLOBAL.TheWorld.state or nil
        local users = GLOBAL.GetUsers()
        local jsonEncoded = GLOBAL.json.encode({ key = "player_shard_join", name = GetSafeName(player) or player.name, userid = player.userid, prefab = player.prefab, iscave = iscave, state = state, users = users })
        GLOBAL.SendRequest(jsonEncoded)
    end
end

AddPrefabPostInit("world", function(inst)
    inst:ListenForEvent("cycleschanged", OnCycleChange)
    inst:ListenForEvent("ms_playerjoined", OnPlayerJoined)
end)

local lastalert = ""
local foodlist = { minotaurhorn = true, deerclops_eyeball = true, mandrake = true, cookedmandrake = true, mandrakesoup = true, gears = true, royal_jelly = true, glommerfuel = true }

local function OnComponentEater(self)
    local old_Eat = self.Eat
    function self:Eat(food)
        local result = old_Eat(self, food)
        if not (result and food and food.prefab) then return result end
        if foodlist[food.prefab] and self.inst then
            local victim = (food.components and food.components.named and food.components.named.name) or (food.prefab and GLOBAL.STRINGS.NAMES[string.upper(food.prefab)]) or food.prefab
            local cause = GetSafeName(self.inst)
            if lastalert == ("eat" .. cause .. victim) then return end
            local users = GLOBAL.GetUsers()
            local userid = self.inst.userid
            lastalert = "eat" .. cause .. victim
            GLOBAL.ExecuteOnAllShards({ key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "server", message = (cause .. " está comendo " .. victim .. "...") })
            local jsonEncoded = GLOBAL.json.encode({ key = "entity_eat", victim = victim, cause = cause, userid = userid, users = users })
            GLOBAL.SendRequest(jsonEncoded)
        end
        return result
    end
end

local function OnComponentBurnable(self)
    local old_Ignite = self.Ignite
    function self:Ignite(immediate, source, ...)
        local result = old_Ignite(self, immediate, source, ...)
        if not (self.inst and self.inst.prefab and source) then return result end
        local player = source
        if source.components and source.components.inventoryitem then player = source.components.inventoryitem:GetGrandOwner() or source end
        if player and player:HasTag("player") then
            local victim = (self.inst.components and self.inst.components.named and self.inst.components.named.name) or (self.inst.prefab and GLOBAL.STRINGS.NAMES[string.upper(self.inst.prefab)]) or self.inst.prefab
            local cause = GetSafeName(player)
            local userid = player.userid
            local structure = self.inst:HasTag("structure") or false
            if not structure then return end
            if lastalert == "burn" .. cause .. victim then return result end
            lastalert = "burn" .. cause .. victim
            local users = GLOBAL.GetUsers()
            if structure then GLOBAL.ExecuteOnAllShards({ key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "server", message = cause .. " está queimando " .. victim .. "...", whisper = false, }) end
            local jsonEncoded = GLOBAL.json.encode({ key = "player_burn", victim = victim, cause = cause, userid = userid, structure = structure, users = users })
            GLOBAL.SendRequest(jsonEncoded)
        end
        return result
    end
end

AddComponentPostInit("eater", OnComponentEater)
AddComponentPostInit("burnable", OnComponentBurnable)

local old_Hammer = GLOBAL.ACTIONS.HAMMER.fn
GLOBAL.ACTIONS.HAMMER.fn = function(act)
    if act and act.doer and act.target then
        local doer = act.doer
        local target = act.target
        local workable = target.components and target.components.workable
        if workable and workable.workleft == 1 and doer.userid then
            local victim = (target.components and target.components.named and target.components.named.name) or (target.prefab and GLOBAL.STRINGS.NAMES[string.upper(target.prefab)]) or target.name or target.prefab or "???"
            local cause = GetSafeName(doer)
            local userid = doer.userid
            local structure = target:HasTag("structure") or false
            if lastalert ~= ("break" .. cause .. victim) then
                local users = GLOBAL.GetUsers()
                lastalert = "break" .. cause .. victim
                if structure then GLOBAL.ExecuteOnAllShards({ key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "server", message = cause .. " está quebrando " .. victim .. "...", whisper = false, }) end
                local jsonEncoded = GLOBAL.json.encode({ key = "player_break", victim = victim, cause = cause, userid = userid, structure = structure, users = users, })
                GLOBAL.SendRequest(jsonEncoded)
            end
        end
    end
    return old_Hammer(act)
end

local oldNetworking_Announcement = GLOBAL.Networking_Announcement
GLOBAL.Networking_Announcement = function(message, colour, announce_type)
    if GLOBAL.TheWorld and GLOBAL.TheWorld:HasTag("cave") then return oldNetworking_Announcement(message, colour, announce_type) end
    local event_key = nil
    local players = GLOBAL.GetUsers()
    if not players then return oldNetworking_Announcement(message, colour, announce_type) end
    local player = nil
    local register = nil
    if announce_type == "join_game" then
        event_key = "joingame"
        player = message:gsub(" has joined the game.", "")
        for userid, p in pairs(players) do
            if p.name == player then
                register = register or {}
                register[userid] = p
            end
        end
    elseif announce_type == "leave_game" then
        event_key = "leavegame"
        player = message:gsub(" has left the game.", "")
    else
        print("[Bernie] Announce Type: " .. tostring(announce_type))
    end

    if event_key then
        local maxPlayers = GLOBAL.TheNet:GetDefaultMaxPlayers()
        local currentPlayers = 0
        for _ in pairs(players) do
            currentPlayers = currentPlayers + 1
        end
        local emptyspace = math.max(0, maxPlayers - currentPlayers)
        local jsonEncoded = GLOBAL.json.encode({ key = "player_" .. event_key, name = player, message = message, register = register, players = players, emptyspace = emptyspace, maxplayers = maxPlayers })
        GLOBAL.SendRequest(jsonEncoded)
    end

    return oldNetworking_Announcement(message, colour, announce_type)
end
