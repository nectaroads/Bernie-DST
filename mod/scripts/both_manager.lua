local GLOBAL = GLOBAL or _G

print('[Bernie] Starting Both-Manager Module...')

Assets = { Asset("IMAGE", "images/profileflair_ashley.tex"), Asset("ATLAS", "images/profileflair_ashley.xml"), Asset("IMAGE", "images/profileflair_bernie.tex"), Asset("ATLAS", "images/profileflair_bernie.xml"), Asset("IMAGE", "images/profileflair_willow.tex"), Asset("ATLAS", "images/profileflair_willow.xml"), Asset("IMAGE", "images/profileflair_global.tex"), Asset("ATLAS", "images/profileflair_global.xml"), Asset("IMAGE", "images/profileflair_private.tex"), Asset("ATLAS", "images/profileflair_private.xml"), Asset("IMAGE", "images/profileflair_discord.tex"), Asset("ATLAS", "images/profileflair_discord.xml"), Asset("IMAGE", "images/profileflair_staffdiscord.tex"), Asset("ATLAS", "images/profileflair_staffdiscord.xml"), Asset("IMAGE", "images/profileflair_server.tex"), Asset("ATLAS", "images/profileflair_server.xml") }

GLOBAL.DumpTable = function (t, max_depth, level, visited)
    level = level or 0
    max_depth = max_depth or 1
    visited = visited or {}

    if level == 0 then print("\n=====[DumpTable]=====") end

    local function prefix(level)
        return string.rep("--|", level)
    end

    if type(t) ~= "table" then
        print(prefix(level) .. tostring(t))
        return
    end

    if visited[t] then return end
    visited[t] = true

    if level >= max_depth then
        print(prefix(level) .. "{...}")
        return
    end

    for k, v in pairs(t) do
        local line = prefix(level) .. tostring(k)

        if type(v) == "table" then
            print(line)
            GLOBAL.DumpTable(v, max_depth, level + 1, visited)
        elseif type(v) == "function" then
            print(line .. " = <function>")
        else
            print(line .. " = " .. tostring(v))
        end
    end
end

print('[Bernie] Finished loading!')