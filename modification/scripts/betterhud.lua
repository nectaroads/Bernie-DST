print('[Bernie] Starting Better-Hud module')

-- Hide Admin Badge
local function HideAdminBadge(target)
    if target ~= nil then
        for _, player in ipairs(target) do
            if player then player.adminBadge:Hide() end
        end
    end
end

AddClassPostConstruct("screens/playerstatusscreen", function(inst)
    local old_DoInit = inst.DoInit
    function inst:DoInit(ClientObjs)
        old_DoInit(self, ClientObjs)
        HideAdminBadge(inst.player_widgets)
        if inst.scroll_list and inst.scroll_list.updatefn then
            local scroll_updateFn = inst.scroll_list.updatefn
            if scroll_updateFn ~= nil then
                function inst.scroll_list.updatefn(playerListing, client, i)
                    scroll_updateFn(playerListing, client, i)
                    playerListing.adminBadge:Hide()
                end
            end
        end
    end
end)

AddClassPostConstruct("widgets/redux/playerlist", function(inst)
    local old_BuildPlayerList = inst.BuildPlayerList
    function inst:BuildPlayerList(ClientObjs)
        old_BuildPlayerList(self, ClientObjs)
        HideAdminBadge(inst.scroll_list.children)
        if inst.scroll_list and inst.scroll_list.update_fn then
            local scroll_updateFn = inst.scroll_list.update_fn
            if scroll_updateFn ~= nil then
                function inst.scroll_list.update_fn(context, widget, data, index)
                    scroll_updateFn(context, widget, data, index)
                    widget.adminBadge:Hide()
                end
            end
        end
    end
end)

local function CookString(str, player)
    if not str then return false end
    str = tostring(str)

    local name = nil
    local prefab = nil
    local userid = nil

    if player then
        name = player:GetDisplayName()
        prefab = player.prefab
        userid = player.userid
    else
        name = GLOBAL.TheNet:GetLocalUserName()
    end

    str = str:gsub("%%player%%", name or "User")
    str = str:gsub("%%prefab%%", prefab or "Prefab")
    str = str:gsub("%%userid%%", userid or "KU_ID")
    return str
end

local config = GLOBAL.LoadConfig("betterhud.lua")

function ShowWelcomeMessage()
    if not config or not config.join then return end
    local title = CookString(config.join.title, GLOBAL.ThePlayer)
    local description = CookString(config.join.description, GLOBAL.ThePlayer)
    GLOBAL.TheFrontEnd:PushScreen(require("screens/bigpopupdialog")(title, description, { { text = config.leave, cb = function() GLOBAL.DoRestart(true) end }, { text = config.accept, cb = function() GLOBAL.TheFrontEnd:PopScreen() end } }))
end

local function ShowList(title, description, buttons)
    GLOBAL.TheFrontEnd:PushScreen(require("screens/textlistpopupdialog")("\n\n" .. tostring(title or ""), GLOBAL.StringToLines(description), nil, buttons))
end

local pageindex = 1
local guidebookopen = false

local function ShowGuidebookPage()
    local pages = config and config.guidebook or {}
    local page = pages[pageindex]
    if not page then return end

    local buttons = {}

    if pageindex == 1 then
        table.insert(buttons, {
            text = config and config["close"] or "undefined",
            cb = function()
                GLOBAL.TheFrontEnd:PopScreen()
                guidebookopen = false
            end
        })
    end

    if pageindex > 1 then
        table.insert(buttons, {
            text = config and config["_return"] or "undefined",
            cb = function()
                GLOBAL.TheFrontEnd:PopScreen()
                pageindex = pageindex - 1
                ShowGuidebookPage()
            end
        })
    end

    if pages[pageindex + 1] then
        table.insert(buttons, {
            text = config and config["continue"] or "undefined",
            cb = function()
                GLOBAL.TheFrontEnd:PopScreen()
                pageindex = pageindex + 1
                ShowGuidebookPage()
            end,
        })
    else
        table.insert(buttons, {
            text = config and config.accept or "undefined",
            cb = function()
                GLOBAL.TheFrontEnd:PopScreen()
                guidebookopen = false
            end
        })
    end

    ShowList(CookString(page.title, GLOBAL.ThePlayer), CookString(page.description, GLOBAL.ThePlayer), buttons)
end

function OnWorldPostInit(inst)
    inst:ListenForEvent("entercharacterselect", ShowWelcomeMessage)
    GLOBAL.BindKey(282, function()
        if guidebookopen == false then
            local screen = GLOBAL.TheFrontEnd:GetActiveScreen()
            if screen and screen.name == "TextListPopupDialog" then return end
            ShowGuidebookPage()
            guidebookopen = true
        end
    end)
end

AddPrefabPostInit("world", OnWorldPostInit)
