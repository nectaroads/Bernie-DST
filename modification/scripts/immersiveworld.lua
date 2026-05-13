print('[Bernie] Starting Immersive-World module')

local config = GLOBAL.LoadConfig("immersiveworld.lua")

if GLOBAL.TheNet:IsDedicated() then
    local function OnPigmanPostInit(inst)
        inst:DoTaskInTime(0, function()
            -- Pigs can have special names
            if not inst or inst:HasTag("customname") or not inst.components.named then return end
            if not (inst and inst.components.named) then return end
            local dice = math.random(0, 9)
            if dice <= 2 then inst.components.named:SetName((config and config.pignames[math.random(#config.pignames)]) or "undefined") end
            inst:AddTag("customname")
            inst:WatchWorldState("phase", function(inst, phase)
                -- Pigs can eventually build a new home
                if phase == "dusk" then
                    local function PigHasHome(inst) return inst.components.homeseeker ~= nil and inst.components.homeseeker.home ~= nil and inst.components.homeseeker.home:IsValid() end
                    local function GivePigNewHouse(inst)
                        if PigHasHome(inst) then return end
                        if math.random() > 1 then return end
                        if inst.sg ~= nil then inst.sg:GoToState("refuse") end
                        inst:DoTaskInTime(0.7, function(inst)
                            if not inst or inst.components.health == nil then return end
                            local x, y, z = inst.Transform:GetWorldPosition()
                            local rot = inst.Transform:GetRotation() * GLOBAL.DEGREES
                            x = x - math.sin(rot) * 1.5
                            z = z - math.cos(rot) * 1.5
                            local dust = GLOBAL.SpawnPrefab("cavein_dust_low")
                            if dust ~= nil then dust.Transform:SetPosition(x, y, z) end
                            inst.SoundEmitter:PlaySound("dontstarve/common/place_structure_straw")
                            local house = GLOBAL.SpawnPrefab("pighouse")
                            if house == nil then return end
                            house.Transform:SetPosition(x, y, z)
                            if house.components.spawner ~= nil then
                                if house.components.spawner.child ~= nil then
                                    house.components.spawner.child:Remove()
                                    house.components.spawner.child = nil
                                end
                                house.components.spawner:TakeOwnership(inst)
                            end
                            if inst.components.homeseeker == nil then inst:AddComponent("homeseeker") end
                            inst.components.homeseeker:SetHome(house)
                        end)
                    end
                    GivePigNewHouse(inst)
                end
            end)
        end)
    end
    AddPrefabPostInit("pigman", OnPigmanPostInit)
end
