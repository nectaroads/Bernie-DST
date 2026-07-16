print('[Bernie] Starting Client-Hud module')

local isclient = not GLOBAL.TheNet:IsDedicated()

if isclient then
    -- Assets
    table.insert(Assets, Asset("IMAGE", "images/tab_discord.tex"))
    table.insert(Assets, Asset("ATLAS", "images/tab_discord.xml"))
end

local config = GLOBAL.LoadConfig("clienthud.lua")
local islocked = false
local screen = nil
GLOBAL.debugscreen = nil

local ImageButton = require("widgets/imagebutton")

if isclient then
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

            -- Discord Button
            if self.customlink_button == nil then
                self.customlink_button = self.root:AddChild(ImageButton("images/tab_discord.xml", "tab_discord.tex"))
                self.customlink_button:SetScale(.4)
                self.customlink_button:SetHoverText("Discord", { font = GLOBAL.NEWFONT_OUTLINE, offset_x = 0, offset_y = 38, colour = GLOBAL.WHITE })
                self.customlink_button:SetOnClick(function() GLOBAL.VisitURL("https://discord.com/invite/37yfuWjyj7") end)
            end
            self.customlink_button:SetPosition(-281, 200)
            if self.viewgroup_button ~= nil then self.viewgroup_button:SetPosition(-377, 200) end
            if self.toggleservertext_button ~= nil then self.toggleservertext_button:SetPosition(-329, 200) end
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

    -- Show Screens
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

    function ShowWelcomeMessage()
        if not config or not config.join then return end
        local title = CookString(config.join.title, GLOBAL.ThePlayer)
        local description = CookString(config.join.description, GLOBAL.ThePlayer)
        GLOBAL.TheFrontEnd:PushScreen(require("screens/bigpopupdialog")(title, description, { { text = config.leave, cb = function() GLOBAL.DoRestart(true) end }, { text = config.accept, cb = function() GLOBAL.TheFrontEnd:PopScreen() end } }))
    end

    local function ShowList(title, description, buttons)
        screen = require("screens/textlistpopupdialog")("\n\n" .. tostring(title or ""), GLOBAL.StringToLines(description), nil, buttons)
        GLOBAL.TheFrontEnd:PushScreen(screen)
        return screen
    end

    local function BuildDescription(description)
        if type(description) == "table" then return table.concat(description, "\n") end
        return description or ""
    end

    local pageindex = 1
    local rankfillings = {}

    local function FillPagesWithFillings(pages, fillings)
        if fillings == nil then return pages end
        for pageindex, filling in pairs(fillings) do
            local page = pages[pageindex]
            if page ~= nil and page.description ~= nil and filling ~= nil then
                for _, line in ipairs(filling) do
                    table.insert(page.description, line)
                end
            end
        end
        return pages
    end

    local function ShowGuidebookPage(target, fillings)
        if not target then target = "guidebook" end
        local pages = config and GLOBAL.CopyTable(config[target] or {}) or {}
        pages = FillPagesWithFillings(pages, fillings)
        local page = pages[pageindex]
        if not page then return end
        local buttons = {}
        if GLOBAL.ThePlayer then GLOBAL.ThePlayer.SoundEmitter:PlaySound("dontstarve/common/use_book") end
        if pageindex == 1 then
            table.insert(buttons, {
                text = config and config["close"] or "undefined",
                cb = function()
                    GLOBAL.TheFrontEnd:PopScreen()
                    screen = nil
                end
            })
        end
        if pageindex > 1 then
            table.insert(buttons, {
                text = config and config["_return"] or "undefined",
                cb = function()
                    GLOBAL.TheFrontEnd:PopScreen()
                    pageindex = pageindex - 1
                    ShowGuidebookPage(target, fillings)
                end
            })
        end
        if pages[pageindex + 1] then
            table.insert(buttons, {
                text = config and config["continue"] or "undefined",
                cb = function()
                    GLOBAL.TheFrontEnd:PopScreen()
                    pageindex = pageindex + 1
                    ShowGuidebookPage(target, fillings)
                end,
            })
        else
            table.insert(buttons, {
                text = config and config.accept or "undefined",
                cb = function()
                    GLOBAL.TheFrontEnd:PopScreen()
                    screen = nil
                end
            })
        end
        local description = BuildDescription(page.description)
        ShowList(CookString(page.title, GLOBAL.ThePlayer), CookString(description, GLOBAL.ThePlayer), buttons)

        if screen ~= nil and screen.proot ~= nil then
            local ImageButton = require("widgets/imagebutton")
            screen.topbutton = screen.proot:AddChild(ImageButton())
            screen.topbutton:SetText("Desligar F1/F2")
            --screen.topbutton.text:SetColour(.7, .7, .7, 1)
            screen.topbutton.image:SetTint(1, 1, 1, 1)
            screen.topbutton:SetPosition(0, -260, 0) -- 210
            screen.topbutton:SetScale(.75)
            screen.topbutton:SetOnClick(function()
                islocked = true
            end)
            GLOBAL.debugscreen = screen
        end
    end

    local function BuildRankFilling(data, key)
        local filling = {}
        local leaderboard
        local rankkey
        if key == "points" then
            leaderboard = data.pointsleaderboard
            rankkey = "pointrank"
        elseif key == "oinks" then
            leaderboard = data.oinksleaderboard
            rankkey = "oinkrank"
        else
            return filling
        end
        local found = false
        if leaderboard then
            for i, entry in ipairs(leaderboard) do
                local num = i < 10 and "0" .. tostring(i) or tostring(i)
                local line = num .. ". " .. tostring(entry.name or "Unknown") .. " | " .. tostring(entry[key] or 0)
                if i <= 10 then table.insert(filling, line) end
                if data.player and entry.userid == data.player.userid then found = true end
            end
        end
        if not found and data.player then
            table.insert(filling, tostring(data.player[rankkey] or "?") .. ". " .. tostring(data.player.name or "Você") .. " | " .. tostring(data.player[key] or 0))
        end
        return filling
    end

    GLOBAL.ClientEventHandler.rank = function(data)
        rankfillings[2] = BuildRankFilling(data, "points")
        rankfillings[3] = BuildRankFilling(data, "oinks")
    end

    AddPrefabPostInit("world", function(inst)
        inst:ListenForEvent("entercharacterselect", ShowWelcomeMessage)
        GLOBAL.BindKey(282, function()
            if not screen and not islocked then ShowGuidebookPage() end
        end)
        GLOBAL.BindKey(283, function()
            if not screen and not islocked then ShowGuidebookPage("rank", rankfillings) end
        end)
        GLOBAL.ShowCustomMessage({ type = 'server', message = 'Primeira vez aqui? Aperte F1 e aprenda sobre o servidor.' })
        GLOBAL.ShowCustomMessage({ type = 'server', message = 'Tem alguma dica/reclamação? Aperte tab e acesse nosso discord!' })
    end)
else
    GLOBAL.HandleShardFunction.rank = function(data)
        if not data or not data.userid then return end
        for _, player in ipairs(GLOBAL.AllPlayers) do
            if player and player:IsValid() and player.userid == data.userid then
                SendModRPCToClient(GetClientModRPC("bernie_client_rpc", "content"), player.userid, GLOBAL.json.encode(data))
                return
            end
        end
    end
end
