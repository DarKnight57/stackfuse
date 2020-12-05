local ConfigScene = Scene:extend()

ConfigScene.title = "Game Settings"

require 'load.save'

ConfigScene.options = {
	-- this serves as reference to what the options' values mean i guess?
	{"manlock",			"Manual locking",{"Per ruleset","Per gamemode","Harddrop", "Softdrop"}},
	{"piece_colour", "Piece Colours", {"Per ruleset","Arika"			 ,"TTC"}},
	{"world_reverse","A Button Rotation", {"Left"				 ,"Auto"		,"Right"}},
	{"das_last_key", "DAS Switch", {"Default", "Instant"}},
	{"synchroes_allowed", "Synchroes", {"Per ruleset", "On", "Off"}},
	{"sfxpack", "Soundpack", {"Default", "TGM only", "Hailey"}},
}
local optioncount = #ConfigScene.options

function ConfigScene:new()
	-- load current config
	self.config = config.input
	self.highlight = 1

	DiscordRPC:update({
		details = "In menus",
		state = "Changing game settings",
	})
end

function ConfigScene:update()
	config["das_last_key"] = config.gamesettings.das_last_key == 2
	-- reload the sounds when saving if the soundpack has changed or something
end

function ConfigScene:render()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(
		backgrounds["game_config"],
		0, 0, 0,
		0.5, 0.5
	)

	love.graphics.setFont(font_3x5_4)
	love.graphics.print("GAME SETTINGS", 80, 40)

	love.graphics.setColor(1, 1, 1, 0.5)
	love.graphics.rectangle("fill", 20, 98 + self.highlight * 20, 170, 22)

	love.graphics.setFont(font_3x5_2)
	for i, option in ipairs(ConfigScene.options) do
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf(option[2], 40, 100 + i * 20, 150, "left")
		for j, setting in ipairs(option[3]) do
			love.graphics.setColor(1, 1, 1, config.gamesettings[option[1]] == j and 1 or 0.5)
			love.graphics.printf(setting, 100 + 110 * j, 100 + i * 20, 100, "center")
		end
	end
end

function ConfigScene:onInputPress(e)
	if e.input == "menu_decide" or e.scancode == "return" then
		playSE("mode_decide")
		saveConfig()
		scene = TitleScene()
	elseif e.input == "up" or e.scancode == "up" then
		playSE("cursor")
		self.highlight = Mod1(self.highlight-1, optioncount)
	elseif e.input == "down" or e.scancode == "down" then
		playSE("cursor")
		self.highlight = Mod1(self.highlight+1, optioncount)
	elseif e.input == "left" or e.scancode == "left" then
		playSE("cursor_lr")
		local option = ConfigScene.options[self.highlight]
		config.gamesettings[option[1]] = Mod1(config.gamesettings[option[1]]-1, #option[3])
	elseif e.input == "right" or e.scancode == "right" then
		playSE("cursor_lr")
		local option = ConfigScene.options[self.highlight]
		config.gamesettings[option[1]] = Mod1(config.gamesettings[option[1]]+1, #option[3])
	elseif e.input == "menu_back" or e.scancode == "delete" or e.scancode == "backspace" then
		loadSave()
		scene = TitleScene()
	end
end

return ConfigScene
