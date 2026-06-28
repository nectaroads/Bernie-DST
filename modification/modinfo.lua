---@diagnostic disable: lowercase-global
name = "Bernie Server-Manager"
description = "The ultimate server-tool."
author = "peuloom"
version = "1.6.5.1.1"
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
        name = "Inconstant",
        hover = "The Constant becomes quite... Whimsical.",
        options = {
            { description = "Allow",  data = true },
            { description = "Forbid", data = false }
        },
        default = true,
    },
    {
        name = "Debug",
        hover = "Do not allow this option.",
        options = {
            { description = "Allow",  data = true },
            { description = "Forbid", data = false }
        },
        default = false,
    },
}
