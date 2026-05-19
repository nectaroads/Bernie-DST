print('[Bernie] Starting Better-Hud module')

-- Hide Admin Badge
local function HideAdminBadge(list)
    if list == nil then return end
    for _, v in pairs(list) do
        local widget = v.widget or v
        if widget ~= nil and widget.adminBadge ~= nil then widget.adminBadge:Hide() end
    end
end

AddClassPostConstruct("screens/playerstatusscreen", function(self)
    local old_DoInit = self.DoInit
    function self:DoInit(ClientObjs)
        old_DoInit(self, ClientObjs)
        HideAdminBadge(self.player_widgets)
        if self.scroll_list ~= nil and self.scroll_list.updatefn ~= nil then
            local old_updatefn = self.scroll_list.updatefn
            self.scroll_list.updatefn = function(playerListing, client, i)
                old_updatefn(playerListing, client, i)
                if playerListing ~= nil and playerListing.adminBadge ~= nil then playerListing.adminBadge:Hide() end
            end
        end
    end
end)

AddClassPostConstruct("widgets/redux/playerlist", function(self)
    local old_BuildPlayerList = self.BuildPlayerList
    function self:BuildPlayerList(ClientObjs)
        old_BuildPlayerList(self, ClientObjs)
        if self.scroll_list ~= nil then
            HideAdminBadge(self.scroll_list.children)
            if self.scroll_list.update_fn ~= nil then
                local old_updatefn = self.scroll_list.update_fn
                self.scroll_list.update_fn = function(context, widget, data, index)
                    old_updatefn(context, widget, data, index)
                    if widget ~= nil and widget.adminBadge ~= nil then widget.adminBadge:Hide() end
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
            ShowGuidebookPage()
            guidebookopen = true
            if GLOBAL.ThePlayer then
                GLOBAL.ThePlayer:DoTaskInTime(3, function()
                    guidebookopen = false
                end)
            end
        end
    end)
end

AddPrefabPostInit("world", OnWorldPostInit)
