function love.load()
	math.randomseed(os.time())
	highscores = {}
	require "load.rpc"
	require "load.graphics"
	require "load.fonts"
	require "load.sounds"
	require "load.bgm"
	require "load.save"
	require "load.version"
	loadSave()
	require "scene"
	--config["side_next"] = false
	--config["reverse_rotate"] = true
	config["fullscreen"] = false

	love.window.setMode(love.graphics.getWidth(), love.graphics.getHeight(), {resizable = true});

	if not config.das then config.das = 10 end
	if not config.arr then config.arr = 2 end
	if not config.sfx_volume then config.sfx_volume = 0.5 end
	if not config.bgm_volume then config.bgm_volume = 0.5 end

	if config.secret == nil then config.secret = false
	elseif config.secret == true then playSE("welcome") end

	if not config.gamesettings then
		config.gamesettings = {}
		config["das_last_key"] = false
	else
		config["das_last_key"] = config.gamesettings.das_last_key == 2
	end
	for _, option in ipairs(GameConfigScene.options) do
		if not config.gamesettings[option[1]] then
			config.gamesettings[option[1]] = 1
		end
	end

	if not config.input then
		scene = InputConfigScene()
	else
		if config.current_mode then current_mode = config.current_mode end
		if config.current_ruleset then current_ruleset = config.current_ruleset end
		scene = TitleScene()
	end

	game_modes = {
		require 'tetris.modes.hypertapmaster',
		require 'tetris.modes.liftoff',
		require 'tetris.modes.powerstack',
		require 'tetris.modes.prism',
	}
	rulesets = {
		require 'tetris.rulesets.arika',
		require 'tetris.rulesets.arika_ti',
		require 'tetris.rulesets.ti_srs',
		require 'tetris.rulesets.standard_exp',
	}
end

local TARGET_FPS = 60
local SAMPLE_SIZE = 60

local rolling_samples = {}
local rolling_total = 0
local average_n = 0
local frame = 0

function getSmoothedDt(dt)
	rolling_total = rolling_total + dt
	frame = frame + 1
	if frame > SAMPLE_SIZE then frame = frame - SAMPLE_SIZE end
	if average_n == SAMPLE_SIZE then
		rolling_total = rolling_total - rolling_samples[frame]
	else
		average_n = average_n + 1
	end
	rolling_samples[frame] = dt
	return rolling_total / average_n
end

local update_time = 0.52

function love.update(dt)
	processBGMFadeout(dt)
	local old_update_time = update_time
	update_time = update_time + getSmoothedDt(dt) * TARGET_FPS
	updates = 0
	while (update_time >= 1.02) do
		scene:update()
		updates = updates + 1
		update_time = update_time - 1
	end
	if math.abs(update_time - old_update_time) < 0.02 then
		update_time = old_update_time
	end
end

function love.draw()
	love.graphics.push()

	-- get offset matrix
	love.graphics.setDefaultFilter("nearest", "nearest")
	local width = love.graphics.getWidth()
	local height = love.graphics.getHeight()
	local scale_factor = math.min(width / 1280, height / 720)
	love.graphics.translate(
		(width - scale_factor * 1280) / 2,
		(height - scale_factor * 720) / 2
	)
	love.graphics.scale(scale_factor)

	scene:render()
	love.graphics.pop()
end

function love.keypressed(key, scancode)
	-- global hotkeys
	if scancode == "f4" then
		config["fullscreen"] = not config["fullscreen"]
		love.window.setFullscreen(config["fullscreen"])
	elseif scancode == "f2" and scene.title ~= "Input Config" and scene.title ~= "Game" then
		scene = InputConfigScene()
		switchBGM(nil)
	-- secret sound playing :eyes:
	elseif scancode == "f8" and scene.title == "Title" then
		config.secret = not config.secret
		saveConfig()
		scene.restart_message = true
		if config.secret then playSE("mode_decide")
		else playSE("erase") end
	-- function keys are reserved
	elseif string.match(scancode, "^f[1-9]$") or string.match(scancode, "^f[1-9][0-9]+$") then
		return
	-- escape is reserved for menu_back
	elseif scancode == "escape" then
		scene:onInputPress({input="menu_back", type="key", key=key, scancode=scancode})
	-- pass any other key to the scene, with its configured mapping
	else
		local input_pressed = nil
		if config.input and config.input.keys then
			input_pressed = config.input.keys[scancode]
		end
		scene:onInputPress({input=input_pressed, type="key", key=key, scancode=scancode})
	end
end

function love.keyreleased(key, scancode)
	-- escape is reserved for menu_back
	if scancode == "escape" then
		scene:onInputRelease({input="menu_back", type="key", key=key, scancode=scancode})
	-- function keys are reserved
	elseif string.match(scancode, "^f[1-9]$") or string.match(scancode, "^f[1-9][0-9]+$") then
		return
	-- handle all other keys; tab is reserved, but the input config scene keeps it from getting configured as a game input, so pass tab to the scene here
	else
		local input_released = nil
		if config.input and config.input.keys then
			input_released = config.input.keys[scancode]
		end
		scene:onInputRelease({input=input_released, type="key", key=key, scancode=scancode})
	end
end

function love.joystickpressed(joystick, button)
	local input_pressed = nil
	if
		config.input and
		config.input.joysticks and
		config.input.joysticks[joystick:getName()] and
		config.input.joysticks[joystick:getName()].buttons
	then
		input_pressed = config.input.joysticks[joystick:getName()].buttons[button]
	end
	scene:onInputPress({input=input_pressed, type="joybutton", name=joystick:getName(), button=button})
end

function love.joystickreleased(joystick, button)
	local input_released = nil
	if
		config.input and
		config.input.joysticks and
		config.input.joysticks[joystick:getName()] and
		config.input.joysticks[joystick:getName()].buttons
	then
		input_released = config.input.joysticks[joystick:getName()].buttons[button]
	end
	scene:onInputRelease({input=input_released, type="joybutton", name=joystick:getName(), button=button})
end

function love.joystickaxis(joystick, axis, value)
	local input_pressed = nil
	local positive_released = nil
	local negative_released = nil
	if
		config.input and
		config.input.joysticks and
		config.input.joysticks[joystick:getName()] and
		config.input.joysticks[joystick:getName()].axes and
		config.input.joysticks[joystick:getName()].axes[axis]
	then
		if math.abs(value) >= 0.5 then
			input_pressed = config.input.joysticks[joystick:getName()].axes[axis][value >= 0.5 and "positive" or "negative"]
		end
		positive_released = config.input.joysticks[joystick:getName()].axes[axis].positive
		negative_released = config.input.joysticks[joystick:getName()].axes[axis].negative
	end
	if math.abs(value) >= 0.5 then
		scene:onInputPress({input=input_pressed, type="joyaxis", name=joystick:getName(), axis=axis, value=value})
	else
		scene:onInputRelease({input=positive_released, type="joyaxis", name=joystick:getName(), axis=axis, value=value})
		scene:onInputRelease({input=negative_released, type="joyaxis", name=joystick:getName(), axis=axis, value=value})
	end
end

function love.joystickhat(joystick, hat, direction)
	local input_pressed = nil
	local has_hat = false
	if
		config.input and
		config.input.joysticks and
		config.input.joysticks[joystick:getName()] and
		config.input.joysticks[joystick:getName()].hats and
		config.input.joysticks[joystick:getName()].hats[hat]
	then
		if direction ~= "c" then
			input_pressed = config.input.joysticks[joystick:getName()].hats[hat][direction]
		end
		has_hat = true
	end
	if input_pressed then
		scene:onInputPress({input=input_pressed, type="joyhat", name=joystick:getName(), hat=hat, direction=direction})
	elseif has_hat then
		for i, direction in ipairs{"d", "l", "ld", "lu", "r", "rd", "ru", "u"} do
			scene:onInputRelease({input=config.input.joysticks[joystick:getName()].hats[hat][direction], type="joyhat", name=joystick:getName(), hat=hat, direction=direction})
		end
	elseif direction ~= "c" then
		scene:onInputPress({input=nil, type="joyhat", name=joystick:getName(), hat=hat, direction=direction})
	else
		for i, direction in ipairs{"d", "l", "ld", "lu", "r", "rd", "ru", "u"} do
			scene:onInputRelease({input=nil, type="joyhat", name=joystick:getName(), hat=hat, direction=direction})
		end
	end
end

function love.focus(f)
	if f and (scene.title ~= "Game" or not scene.paused) then
		resumeBGM()
	else
		pauseBGM()
	end
end
