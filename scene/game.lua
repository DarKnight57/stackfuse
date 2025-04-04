local GameScene = Scene:extend()

GameScene.title = "Game"

require 'load.save'

function GameScene:new(game_mode, ruleset, inputs)
	self.retry_mode = game_mode
	self.retry_ruleset = ruleset
	self.secret_inputs = copy(inputs)
	self.game = game_mode(self.secret_inputs)
	self.ruleset = ruleset()
	self.game:initialize(self.ruleset, self.secret_inputs)
	self.inputs = {
		left=false,
		right=false,
		up=false,
		down=false,
		rotate_left=false,
		rotate_left2=false,
		rotate_right=false,
		rotate_right2=false,
		rotate_180=false,
		hold=false,
	}
	self.paused = false
	DiscordRPC:update({
		details = self.game.rpc_details,
		state = self.game.name,
	})
end

function GameScene:update()
	if love.window.hasFocus() and not self.paused then
		local inputs = {}
		for input, value in pairs(self.inputs) do
			inputs[input] = value
		end
		self.game:update(inputs, self.ruleset)
		self.game.grid:update()
	end
end

function GameScene:render()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(
		backgrounds[self.game:getBackground()],
		0, 0, 0,
		1, 1
	)

	love.graphics.draw(misc_graphics["shadoweffect"], 0, 0)

	-- game frame
	if self.game.grid.width == 10 and self.game.grid.height == 24 then
		love.graphics.draw(misc_graphics["frame"], 485, 93)
	end


	if self.game.grid.width ~= 10 or self.game.grid.height ~= 24 then
		love.graphics.setColor(174/255, 83/255, 76/255, 1)
		love.graphics.setLineWidth(8)
		love.graphics.line(
			60,76,
			68+16*self.game.grid.width,76,
			68+16*self.game.grid.width,84+16*(self.game.grid.height-4),
			60,84+16*(self.game.grid.height-4),
			60,76
		)
		love.graphics.setColor(203/255, 137/255, 111/255, 1)
		love.graphics.setLineWidth(4)
		love.graphics.line(
			60,76,
			68+16*self.game.grid.width,76,
			68+16*self.game.grid.width,84+16*(self.game.grid.height-4),
			60,84+16*(self.game.grid.height-4),
			60,76
		)
		love.graphics.setLineWidth(1)
	end

	self.game:drawGrid()
	self.game:drawPiece()
	self.game:drawNextQueue(self.ruleset)
	self.game:drawScoringInfo()

	-- ready/go graphics

	self.game:drawCustom()
	love.graphics.setColor(1, 1, 1, 1) --fallback color just in case
	love.graphics.setFont(font_New_Big)
	if self.game.ready_frames <= 100 and self.game.ready_frames > 52 then
		love.graphics.setColor(1, (5 / ((self.game.ready_frames) - 52)) , 0, 1)
		love.graphics.printf("READY...", 0, 320, 1272, "center")
	elseif self.game.ready_frames <= 50 and self.game.ready_frames > 2 then
		love.graphics.setColor(((self.game.ready_frames) / 50), 1, 0, 1)
		love.graphics.printf("GO!", 0, 320, 1272, "center")
	end
	love.graphics.setFont(font_New)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf(self.game.name .. " // " .. self.ruleset.name, 16, 680, 1280, "left")
	love.graphics.printf("stackfuse // " .. getVersionNumber(), -16, 680, 1280, "right")

	love.graphics.setFont(font_New_Big)
	if self.paused then love.graphics.printf("PAUSED!", 0, 320, 1272, "center") end

	if self.game.completed then
		self.game:onGameComplete()
	elseif self.game.game_over then
		self.game:onGameOver()
	end
end

function GameScene:onInputPress(e)
	if self.game.completed and (e.input == "rotate_left" or e.input == "menu_back" or e.input == "retry" or e.input == "rotate_right") then
		highscore_entry = self.game:getHighscoreData()
		highscore_hash = self.game.hash .. "-" .. self.ruleset.hash
		submitHighscore(highscore_hash, highscore_entry)
		scene = e.input == "retry" and GameScene(self.retry_mode, self.retry_ruleset, self.secret_inputs) or ModeSelectScene()
		playSE("menu_back")
	elseif e.input == "retry" then
		switchBGM(nil)
		love.audio.stop(sounds.powermode)
		scene = GameScene(self.retry_mode, self.retry_ruleset, self.secret_inputs)
	elseif e.input == "pause" and not (self.game.game_over or self.game.completed) then
		self.paused = not self.paused
		if self.paused then
			pauseBGM()
			love.audio.stop(sounds.powermode)
		else resumeBGM() end
	elseif e.scancode == "escape" then
		scene = ModeSelectScene()
		playSE("menu_back")
	elseif e.input and string.sub(e.input, 1, 5) ~= "rotate_" then
		self.inputs[e.input] = true
	end
end

function GameScene:onInputRelease(e)
	if e.input and string.sub(e.input, 1, 5) ~= "rotate_" then
		self.inputs[e.input] = false
	end
end

function submitHighscore(hash, data)
	if not highscores[hash] then highscores[hash] = {} end
	table.insert(highscores[hash], data)
	saveHighscores()
end

return GameScene
