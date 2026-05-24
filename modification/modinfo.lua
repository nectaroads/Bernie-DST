name = "Bernie Server-Manager"
description = "The ultimate server-tool."
author = "peuloom"
version = "1.5.3.3.7"
forumthread = "WIP"
api_version = 10
icon_atlas = "modicon.xml"
icon = "modicon.tex"
all_clients_require_mod = true
client_only_mod = false
server_only_mod = false
dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false

configuration_options = {
    {
        name = "Anti-Cheat",
        hover = "Prevents players from activating cheats, mostly.",
        options = {
            { description = "Allow",  data = true },
            { description = "Forbid", data = false }
        },
        default = true,
    },
    {
        name = "Anti-Griefing",
        hover = "Now you have tools to prevent griefing and fix destroyed stuff.",
        options = {
            { description = "Allow",  data = true },
            { description = "Forbid", data = false }
        },
        default = true,
    },
    {
        name = "Nice-Chat",
        hover = "Profile pictures, color manipulation, have a nicer chat looking.",
        options = {
            { description = "Allow",  data = true },
            { description = "Forbid", data = false }
        },
        default = true,
    },
    {
        name = "Better-Hud",
        hover = "Improves the hud, add some popups to your server, information is cool.",
        options = {
            { description = "Allow",  data = true },
            { description = "Forbid", data = false }
        },
        default = true,
    },
    {
        name = "Another-Rebalance",
        hover = "Add some spice to the gameplay. Peuloom's balance tweaks.",
        options = {
            { description = "Allow",  data = true },
            { description = "Forbid", data = false }
        },
        default = true,
    },
    {
        name = "Propaganda",
        hover = "Your server will randomly send messages to everyone. (Nicechat required)",
        options = {
            { description = "Allow",  data = true },
            { description = "Forbid", data = false }
        },
        default = true,
    },
    {
        name = "Fancy-RPC",
        hover = "Send messages to a proxy, you need to setup it first. (Nicechat required)",
        options = {
            { description = "Allow",  data = true },
            { description = "Forbid", data = false }
        },
        default = true,
    },
    {
        name = "Immersive-World",
        hover = "Experience a Constant more immersed than ever before!",
        options = {
            { description = "Allow",  data = true },
            { description = "Forbid", data = false }
        },
        default = true,
    },
    {
        name = "Companion-AI",
        hover = "Have a companion AI playing on your server. (Nicechat required)",
        options = {
            { description = "Allow",  data = true },
            { description = "Forbid", data = false }
        },
        default = false,
    }
}
