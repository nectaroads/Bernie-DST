print('[Bernie] Starting Anti-Cheat module')

local config = GLOBAL.LoadConfig("anticheat.lua")

local whitelisted = { modlist = {}, snapshot = {} }

AddModRPCHandler("bernie_rpc_server_message", "content", function(player, json)
    if GLOBAL.TheNet:IsDedicated() then
        if player == nil or json == nil then return end
        local success, data = GLOBAL.pcall(GLOBAL.json.decode, json)
        if data and data.key then
            if data.key == "snapshot" then
                local iscaves = GLOBAL.TheWorld:HasTag("cave")
                whitelisted.snapshot[player.userid] = data.snapshot

                local count = {}
                for userid, snapshot in pairs(whitelisted.snapshot) do
                    if snapshot ~= nil then
                        count[snapshot] = (count[snapshot] or 0) + 1
                    end
                end

                local best_snapshot = nil
                local best_count = 0

                for snapshot, amount in pairs(count) do
                    if amount > best_count then
                        best_snapshot = snapshot
                        best_count = amount
                    end
                end

                local userid = player.userid

                if best_snapshot and data.snapshot then
                    if data.snapshot ~= best_snapshot then
                        if best_count > 1 then
                            GLOBAL.ExecuteOnAllShards({ key = "bernie_rpc_client_message", rpc = "bernie_rpc_client_message", type = "willow", message = player and (player.name or (player.GetDisplayName and player:GetDisplayName()) or player.prefab) .. " será expulso por receber a flag 'Client Modificado'. Se você acredita que essa mensagem é um erro, por favor, notifique no servidor do Discord.", whisper = false, })
                            GLOBAL.TheWorld:DoTaskInTime(10, function()
                                GLOBAL.TheNet:Kick(userid)
                            end)
                        end
                    end
                end

                local jsonEncoded = GLOBAL.json.encode({ key = "player_snapshot", victim = player.name or (player.GetDisplayName and player:GetDisplayName()), snapshot = data.snapshot, userid = player.userid, caves = iscaves })
                GLOBAL.SendRequest(jsonEncoded)
            else
                if data.key == "modlist" then
                    whitelisted.modlist[player.userid] = true
                    local jsonEncoded = GLOBAL.json.encode({ key = "player_modlist", victim = player.name or (player.GetDisplayName and player:GetDisplayName()), modlist = data.modlist, userid = player.userid })
                    GLOBAL.SendRequest(jsonEncoded)
                end
            end
        end
    end
end)

if GLOBAL.TheNet:IsDedicated() then
    -- Server

    -- Some verification stuff...
    AddSimPostInit(function()
        AddPlayerPostInit(function(inst)
            inst:DoTaskInTime(0, function()
                if not inst then return end
                whitelisted.modlist[inst.userid] = false
                whitelisted.snapshot[inst.userid] = false
            end)
            inst:DoTaskInTime(30, function()
                if not inst then return end
                if not whitelisted.modlist[inst.userid] or not whitelisted.snapshot[inst.userid] then
                    if inst and inst:IsValid() and inst.Network and inst.Network.Disconnect then inst.Network:Disconnect() end
                    local jsonEncoded = GLOBAL.json.encode({ key = "player_cheating", victim = inst.name or (inst.GetDisplayName and inst:GetDisplayName()), userid = inst.userid })
                    GLOBAL.SendRequest(jsonEncoded)
                end
            end)
        end)
    end)

    -- NO Attack-Animation-Cancel
    local Combat = require("components/combat")

    local attackCooldown = 0.460
    local attackCooldowns = {}

    local old_GetAttacked = Combat.GetAttacked
    function Combat:GetAttacked(attacker, damage, weapon, stimuli, spdamage)
        if attacker and attacker:IsValid() and attacker:HasTag("player") and attacker.sg and attacker.sg.currentstate then
            local isattack = attacker.sg.currentstate.name == "attack"
            local isequippable = weapon and weapon.components and weapon.components.equippable ~= nil
            local ishighdamage = damage > 30
            local cooldown = attackCooldown

            if isattack and isequippable and ishighdamage then
                local userid = attacker.userid or tostring(attacker.GUID)
                local now = GLOBAL.GetTime()
                local last = attackCooldowns[userid]

                if attacker.components.rider and attacker.components.rider:IsRiding() then cooldown = cooldown * 1.06 end
                if weapon.prefab == "alarmingclock" then cooldown = cooldown * 1.14 end

                if last ~= nil then
                    local delta = now - last
                    if delta < cooldown then
                        local multiplier = delta / cooldown
                        damage = damage * multiplier
                    end
                end
                attackCooldowns[userid] = now
            end
        end
        return old_GetAttacked(self, attacker, damage, weapon, stimuli, spdamage)
    end
else
    -- Client

    local lastdistance = 30
    local deltasqupdate = 4

    local function HashSnapshot()
        local hash = nil

        local function CreateHash(input)
            if type(input) ~= "string" then input = tostring(input) or "NIL" end
            local servername = GLOBAL.TheNet:GetServerName() or "unknown"
            local serverclan = GLOBAL.TheNet.GetServerClanID and GLOBAL.TheNet:GetServerClanID() or "noclan"
            local hostid = (servername .. "-snapshot-" .. serverclan):gsub(" ", "")
            local data = input .. "::" .. hostid
            local hash = 0
            for i = 1, #data do
                hash = (hash + string.byte(data, i) * i) % 1000000007
            end
            return tostring(hash)
        end

        local function NormalizeDump(dump)
            local _, path_end = dump:find("%.lua" .. string.char(0))
            return path_end ~= nil and dump:sub(path_end + 1) or dump
        end

        local function ToHex(str)
            return (str:gsub('.', function(c)
                return string.format('%02X ', string.byte(c))
            end))
        end

        local function GetFunctionHash(func)
            local dumped_code = string.dump(func)
            local normalized = NormalizeDump(dumped_code)
            return CreateHash(normalized)
        end

        hash = GetFunctionHash(HashSnapshot)

        function OnWorldPostInit(inst)
            -- NO CONSOLE
            inst:DoTaskInTime(0, function()
                -- IF NOT ADMIN
                if not GLOBAL.TheNet:GetIsServerAdmin() then
                    local ConsoleScreen = GLOBAL.require("screens/consolescreen")
                    ConsoleScreen.OnBecomeActive = function() end
                    ConsoleScreen.OnRawKey = function(key, down) end
                    ConsoleScreen.OnRawKeyHandler = function(key, down) end
                end
            end)

            -- NO Cursed-Mods
            function FindProblematicStuff(arr)
                local cursedmods = {}

                for path, name in GLOBAL.pairs(arr) do
                    local ok, result = GLOBAL.pcall(require, path)
                    if ok and result then cursedmods[path] = name end
                end

                if GLOBAL.next(cursedmods) ~= nil then
                    if not config then return end
                    local title = "\n\n\n\n" .. (config.title or "title")
                    local description = "\n\n" .. (config.description or "description")
                    local modnames = {}

                    for _, name in GLOBAL.pairs(cursedmods) do
                        GLOBAL.table.insert(modnames, name)
                    end

                    description = description .. GLOBAL.table.concat(modnames, ", ")

                    GLOBAL.TheFrontEnd:PushScreen(require("screens/bigpopupdialog")(title, description, { { text = config.leave, cb = function() GLOBAL.DoRestart(true) end }, { text = config.accept, cb = function() GLOBAL.DoRestart(true) end } }))
                    if inst then inst:DoTaskInTime(30, function() if inst then GLOBAL.DoRestart(true) end end) end
                end
            end

            local function FindProblematicMods(arr)
                local cursedmods = {}

                for id, name in GLOBAL.pairs(arr) do
                    if GLOBAL.KnownModIndex:IsModEnabled("workshop-" .. tostring(id)) then cursedmods[id] = name end
                end

                for _, modname in GLOBAL.pairs(GLOBAL.KnownModIndex:GetModsToLoad()) do
                    if type(modname) == "string" and not modname:match("^workshop%-") and modname ~= "DontStarveLuaJIT2-Server" then cursedmods[modname] = modname end
                end

                if GLOBAL.next(cursedmods) ~= nil then
                    if not config then return end
                    local title = "\n\n\n\n" .. (config.title or "title")
                    local description = "\n\n" .. (config.description or "description")
                    local modnames = {}
                    for _, name in GLOBAL.pairs(cursedmods) do
                        GLOBAL.table.insert(modnames, tostring(name))
                    end
                    description = description .. GLOBAL.table.concat(modnames, ", ")
                    GLOBAL.TheFrontEnd:PushScreen(require("screens/bigpopupdialog")(title, description, { { text = config.leave, cb = function() GLOBAL.DoRestart(true) end }, { text = config.accept, cb = function() GLOBAL.DoRestart(true) end }, }))
                    if inst then
                        inst:DoTaskInTime(20, function()
                            if inst then GLOBAL.DoRestart(true) end
                        end)
                    end
                end
            end

            inst:DoTaskInTime(1, function()
                local cursedclasses = { ["widgets/biomelabels"] = "Biome Revealer (Client)", }
                FindProblematicStuff(cursedclasses)
                local cursedmods = { [3384030282] = "EP Tweaked", [3451668942] = "Night Hawk", [2525858933] = "Environment Pinger", [2972170454] = "Orbit View", [3476753797] = "Change Skill Points", [3336589631] = "Change Skill Points", [2274036595] = "Chinese Cheat", [3718007569] = "Biome Revealer", [1781410139] = "Zoom++", [2837642411] = "Zoom++", [3715602247] = "Zoom++", [3620804278] = "Zoom++", [1684135933] = "Better Night-Vision", [2800827630] = "Unhappy Cheating", [2114536684] = "Happy Cheating", [3014188454] = "Cheating", [3525558556] = "Range Indicator", [3091801418] = "Scan Map", [3727683251] = "Auto Kite", [3650971812] = "Free Camera" }
                FindProblematicMods(cursedmods)
            end)
        end

        AddPrefabPostInit("world", OnWorldPostInit)

        local function DisableCheats(self)
            local player = GLOBAL.ThePlayer

            self.target = player
            if self.fov ~= 35 then self.fov = 35 end
            self.pangain = 4
            self.headinggain = 20
            self.distancegain = 1
            self.zoomstep = 8
            if self.mindist ~= 15 then self.mindist = 15 end
            if self.maxdist ~= 50 then self.maxdist = 50 end
            if lastdistance > self.maxdist + self.extramaxdist then lastdistance = self.maxdist + self.extramaxdist end
            if lastdistance > self.maxdist * 2 then lastdistance = self.maxdist end
            self.distancetarget = lastdistance
            if self.mindistpitch ~= 30 then self.mindistpitch = 30 end
            if self.maxdistpitch ~= 60 then self.maxdistpitch = 60 end

            local enablednightvision = false
            local allowednightvision = false

            if player and player.components and player.components.playervision then
                local hat = player.replica and player.replica.inventory and player.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HEAD)
                if player.components.playervision.forcenightvision or player.components.playervision:HasNightVision() then enablednightvision = true end
                if enablednightvision == true and player.components.playervision.forcednightvisionstack and player.components.playervision.forcednightvisionstack[1] then allowednightvision = true end
                if hat and hat:HasTag("nightvision") then allowednightvision = true end
                if enablednightvision == true and allowednightvision == false then
                    player.components.playervision.forcenightvision = false
                    player:PushEvent("nightvision", false)
                end
            end
        end

        local applyFn = nil

        -- NO Extra-FOV, Extra-ZOOM, Night-Vision
        AddClassPostConstruct("cameras/followcamera", function(self)
            self.SetDefault = function()
                self.targetpos = GLOBAL.Vector3(0, 0, 0)
                self:SetDefaultOffset()
                if self.headingtarget == nil then self.headingtarget = 45 end
                self.fov = 35
                self.pangain = 4
                self.headinggain = 20
                self.distancegain = 1
                self.continuousdistancegain = 6
                self.zoomstep = 8
                self.distancetarget = lastdistance
                self.mindist = 15
                self.maxdist = 50
                self.mindistpitch = 30
                self.maxdistpitch = 60
                self.paused = false
                self.shake = nil
                self.controllable = true
                self.cutscene = false

                if self.gamemode_defaultfn then self.gamemode_defaultfn(self) end
                self:SetTarget(self.target)
            end

            self.Apply = function()
                local pitch = self.pitch * GLOBAL.DEGREES
                local heading = self.heading * GLOBAL.DEGREES
                local cos_pitch = math.cos(pitch)
                local cos_heading = math.cos(heading)
                local sin_heading = math.sin(heading)
                local dx = -cos_pitch * cos_heading
                local dy = -math.sin(pitch)
                local dz = -cos_pitch * sin_heading

                DisableCheats(self)

                local xoffs, zoffs = 0, 0
                if self.currentscreenxoffset ~= 0 then
                    local hoffs = 2 * self.currentscreenxoffset / GLOBAL.RESOLUTION_Y
                    local magic_number = 1.03
                    local screen_heights = math.tan(self.fov * .5 * GLOBAL.DEGREES) * self.distance * magic_number
                    xoffs = -hoffs * sin_heading * screen_heights
                    zoffs = hoffs * cos_heading * screen_heights
                end

                self.camera_pos = GLOBAL.Vector3(self.currentpos.x - dx * self.distance + xoffs, self.currentpos.y - dy * self.distance, self.currentpos.z - dz * self.distance + zoffs)
                self.camera_dir = GLOBAL.Vector3(dx, dy, dz)
                GLOBAL.TheSim:SetCameraPos(self.camera_pos:Get())
                GLOBAL.TheSim:SetCameraDir(self.camera_dir:Get())

                local right = (self.heading + 90) * GLOBAL.DEGREES
                local rx = math.cos(right)
                local ry = 0
                local rz = math.sin(right)

                local ux = dy * rz - dz * ry
                local uy = dz * rx - dx * rz
                local uz = dx * ry - dy * rx

                self.camera_up = GLOBAL.Vector3(ux, uy, uz)

                GLOBAL.TheSim:SetCameraUp(self.camera_up:Get())
                GLOBAL.TheSim:SetCameraFOV(self.fov)

                local old_camera_pos = self.last_update_camera_pos
                local old_camera_dir = self.last_update_camera_dir
                local old_camera_up = self.last_update_camera_up

                if old_camera_pos == nil or
                    old_camera_pos:DistSq(self.camera_pos) >= deltasqupdate or
                    old_camera_dir:DistSq(self.camera_dir) >= deltasqupdate or
                    old_camera_up:DistSq(self.camera_up) >= deltasqupdate
                then
                    self.last_update_camera_pos = self.camera_pos
                    self.last_update_camera_dir = self.camera_dir
                    self.last_update_camera_up = self.camera_up
                    self.large_dist_update = true
                end

                local listendist = -.1 * self.distance
                GLOBAL.TheSim:SetListener(dx * listendist + self.currentpos.x, dy * listendist + self.currentpos.y, dz * listendist + self.currentpos.z, dx, dy, dz, ux, uy, uz)
            end

            applyFn = self.Apply

            self.ZoomIn = function(self, step)
                lastdistance = math.max(self.mindist, self.distancetarget - (step or self.zoomstep))
            end
            self.ZoomOut = function(self, step)
                lastdistance = math.min(self.maxdist, self.distancetarget + (step or self.zoomstep))
            end
        end)

        AddGlobalClassPostConstruct("camerashake", "CameraShake", function(self)
            local oldStartShake = self.StartShake
            function self:StartShake(type, duration, speed, scale, ...)
                return oldStartShake(self, type, duration, speed, (scale or 1) * 0.5, ...)
            end
        end)

        AddClassPostConstruct("screens/playerhud", function(self)
            function self:UpdateClouds(camera)
                if self.clouds then self.clouds:Hide() end
                if self.clouds_on then
                    self.clouds_on = false
                    GLOBAL.TheFocalPoint.SoundEmitter:KillSound("windsound")
                end
            end
        end)

        local function BeWitnessToServer(inst)
            if GLOBAL.TheNet ~= nil then
                if GLOBAL.KnownModIndex ~= nil then
                    local mods = GLOBAL.KnownModIndex:GetModsToLoad()
                    if mods ~= nil and #mods > 0 then
                        local json = GLOBAL.json.encode({ key = "modlist", modlist = mods }) or ""
                        SendModRPCToServer(GetModRPC("bernie_rpc_server_message", "content"), json)
                    end
                end
            end
        end

        AddPlayerPostInit(function(inst)
            inst:DoPeriodicTask(1, function()
                if not inst or not inst:IsValid() then return end
                if not inst then return end
                if (inst ~= GLOBAL.ThePlayer) then return end
                local cam = GLOBAL.TheCamera
                if applyFn and cam.Apply ~= applyFn then
                    if inst then GLOBAL.DoRestart(true) end
                end
            end)
            inst:DoTaskInTime(3, function()
                if not inst or not inst:IsValid() then return end
                if not inst then return end
                if (inst ~= GLOBAL.ThePlayer) then return end
                BeWitnessToServer(inst)
                local json = GLOBAL.json.encode({ key = "snapshot", snapshot = hash })
                SendModRPCToServer(GetModRPC("bernie_rpc_server_message", "content"), json)
            end)
        end)
    end

    HashSnapshot()
end
