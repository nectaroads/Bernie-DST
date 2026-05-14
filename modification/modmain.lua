print('[Bernie] Reading host configuration...')
local anticheat = GetModConfigData("Anti-Cheat")
local antigriefing = GetModConfigData("Anti-Griefing")
local immersiveworld = GetModConfigData("Immersive-World")
local anotherrebalance = GetModConfigData("Another-Rebalance")

local nicechat = GetModConfigData("Nice-Chat")
local betterhud = GetModConfigData("Better-Hud")

local propaganda = GetModConfigData("Propaganda")
local fancyrpc = GetModConfigData("Fancy-RPC")
local companionai = GetModConfigData("Companion-AI")

print('[Bernie] Starting module imports...')
local isServer = GLOBAL.TheNet:IsDedicated() -- Load order
modimport("scripts/experiments.lua")
if not isServer and nicechat then modimport("scripts/nicechat.lua") end
if isServer and propaganda then modimport("scripts/propaganda.lua") end
if not isServer and betterhud then modimport("scripts/betterhud.lua") end
if isServer and companionai then modimport("scripts/companionai.lua") end
if antigriefing then modimport("scripts/antigriefing.lua") end
if anticheat then modimport("scripts/anticheat.lua") end
if immersiveworld then modimport("scripts/immersiveworld.lua") end
if anotherrebalance then modimport("scripts/anotherrebalance.lua") end
if anotherrebalance then modimport("scripts/sadisticevents.lua") end
if isServer and fancyrpc then modimport("scripts/fancyrpc.lua") end
if isServer then modimport("scripts/responsehandler.lua") end

print('[Bernie] Finished loading!')
