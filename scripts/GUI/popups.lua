local PopupDialogScreen = require "screens/popupdialog"

local function CreateChoicePopup(title, body, action_yes, action_no, theme, longness, style)
	local choices = {
		{
			text = "OK",
			cb = function()
				TheFrontEnd:PopScreen()
				if action_yes then
					action_yes()
				end
			end
		}
	}

	if action_no then
		table.insert(choices,
			{
				text = "Cancel",
				cb = function()
					TheFrontEnd:PopScreen()
					action_no()
				end
			}
		)
	end

	TheFrontEnd:PushScreen(
		PopupDialogScreen(title, body, choices, nil, nil, style)
	)
end

local function CreateProcessPopup(title, body, process, postexec_process)
	TheFrontEnd:PushScreen(PopupDialogScreen(title, body, { text = "...", cb = function() end }))
	TheWorld:DoTaskInTime(0, function()
		process()
		TheFrontEnd:PopScreen()
		postexec_process()
	end)
end

return {
	["CreateProcessPopup"] = CreateProcessPopup,
	["CreateChoicePopup"] = CreateChoicePopup
}
