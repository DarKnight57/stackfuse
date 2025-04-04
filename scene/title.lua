local TitleScene = Scene:extend()

TitleScene.title = "Title"
TitleScene.restart_message = false

local main_menu_screens = {
	ModeSelectScene,
	SettingsScene,
	CreditsScene,
	ExitScene,
}

local mainmenuidle = {
	"Idle",
	"On title screen",
	"On main menu screen"
}

function TitleScene:new()
	self.main_menu_state = 1
	self.frames = 0
	self.snow_bg_opacity = 0
	self.y_offset = 0
	self.text = ""
	self.text_flag = false
	DiscordRPC:update({
		details = "In menus",
		state = mainmenuidle[math.random(#mainmenuidle)],
	})
end

function TitleScene:update()
	if self.text_flag then
		self.frames = self.frames + 1
		self.snow_bg_opacity = self.snow_bg_opacity + 0.01
	end
	if self.frames < 125 then self.y_offset = self.frames
	elseif self.frames < 185 then self.y_offset = 125
	else self.y_offset = 310 - self.frames end
end

function TitleScene:render()
	love.graphics.setFont(font_New_Big)

	love.graphics.setColor(1, 1, 1, 1 - self.snow_bg_opacity)
	love.graphics.draw(
		backgrounds["title"],
		0, 0, 0,
		1,1
	)

	love.graphics.setColor(1, 1, 1, self.snow_bg_opacity)
	love.graphics.draw(
		backgrounds["snow"],
		0, 0, 0,
		1, 1
	)

	love.graphics.print("Happy Holidays!", 320, -100 + self.y_offset)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.print(self.restart_message and "Restart Cambridge..." or "", 0, 0)

	love.graphics.setColor(1, 1, 1, 0.5)
	love.graphics.rectangle("fill", 440, 278 + 80 * self.main_menu_state, 400, 70)

	--first we draw the text shadow...
	love.graphics.setColor(0, 0, 0, 0.5)
	for i, screen in pairs(main_menu_screens) do
		love.graphics.printf(screen.title, 462, 282 + 80 * i, 360, "center")
	end
	--and then the main text.
	love.graphics.setColor(1, 1, 1, 1)
	for i, screen in pairs(main_menu_screens) do
		love.graphics.printf(screen.title, 460, 280 + 80 * i, 360, "center")
	end

end

function TitleScene:changeOption(rel)
	local len = table.getn(main_menu_screens)
	self.main_menu_state = (self.main_menu_state + len + rel - 1) % len + 1
end

function TitleScene:onInputPress(e)
	if e.input == "rotate_left" or e.scancode == "return" then
		playSE("main_decide")
		scene = main_menu_screens[self.main_menu_state]()
	elseif e.input == "up" or e.scancode == "up" then
		self:changeOption(-1)
		playSE("cursor")
	elseif e.input == "down" or e.scancode == "down" then
		self:changeOption(1)
		playSE("cursor")
	elseif e.input == "rotate_right" or e.scancode == "backspace" or e.scancode == "delete" or e.scancode == "escape" then
		love.event.quit()
	else
		self.text = self.text .. (e.scancode ~= nil and e.scancode or "")
		if self.text == "ffffff" then
			self.text_flag = true
		end
	end
end

return TitleScene
