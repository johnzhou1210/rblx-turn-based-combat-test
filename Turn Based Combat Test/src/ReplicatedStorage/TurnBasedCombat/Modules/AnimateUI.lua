local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")

local SOURCE_LOCALE = "en"
local translator = nil

local AnimateUI = {}

function AnimateUI.loadTranslator()
	pcall(function()
		translator = LocalizationService:GetTranslatorForPlayerAsync(Players.LocalPlayer)
	end)
	if not translator then
		pcall(function()
			translator = LocalizationService:GetTranslatorForLocaleAsync(SOURCE_LOCALE)
		end)
	end
end

function AnimateUI.typeWrite(guiObject, text, delayBetweenChars)
	local coro = coroutine.wrap(function()
		guiObject.Visible = true
		guiObject.AutoLocalize = false
		local displayText = text

		-- Translate text if possible
		if translator then
			displayText = translator:Translate(guiObject, text)
		end

		-- Replace line break tags so grapheme loop will not miss those characters
		displayText = displayText:gsub("", "\n")
		displayText:gsub("<[^<>]->", "")
		-- Set translated/modified text on parent
		guiObject.Text = displayText
		local index = 0
		for first, last in utf8.graphemes(displayText) do
			index = index + 1
			guiObject.MaxVisibleGraphemes = index
			wait(delayBetweenChars)
		end
	end)
	coro();
end
return AnimateUI