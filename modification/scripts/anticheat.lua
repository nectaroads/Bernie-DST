print('[Bernie] Starting Anti-Cheat module')

local whitelisted = {}

AddModRPCHandler("bernie_rpc_server_message", "content", function(player, json)
    if GLOBAL.TheNet:IsDedicated() then
        if player == nil or json == nil then return end
        local success, mods = GLOBAL.pcall(GLOBAL.json.decode, json)
        whitelisted[player.userid] = true
        local jsonEncoded = GLOBAL.json.encode({ key = "player_context", victim = player.name or (player.GetDisplayName and player:GetDisplayName()), context = mods })
        GLOBAL.SendRequest(jsonEncoded)
    end
end)

if GLOBAL.TheNet:IsDedicated() then
    -- Server

    -- Some verification stuff...
    AddSimPostInit(function()
        AddPlayerPostInit(function(inst)
            whitelisted[inst.userid] = false
            inst:DoTaskInTime(30, function()
                if whitelisted[inst.userid] == false then
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

    local config = GLOBAL.LoadConfig("cheatpopup.lua")

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

        inst:DoTaskInTime(3, function()
            local cursedmods = { ["widgets/biomelabels"] = "Biome Revealer (Client)", }
            FindProblematicStuff(cursedmods)
        end)
    end

    AddPrefabPostInit("world", OnWorldPostInit)

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
                    local json = GLOBAL.json and GLOBAL.json.encode and GLOBAL.json.encode(mods) or ""
                    SendModRPCToServer(GetModRPC("bernie_rpc_server_message", "content"), json)
                end
            end
        end
    end

    AddPlayerPostInit(function(inst)
        inst:DoTaskInTime(3, function()
            if (inst == GLOBAL.ThePlayer) then
                BeWitnessToServer(inst)
            end
        end)
    end)
end
