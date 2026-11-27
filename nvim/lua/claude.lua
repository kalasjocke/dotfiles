-- Send comments to Claude, running in the tmux or Rex pane left of Neovim's.
--
-- comment() opens a box below the current line or the selected lines, as
-- GitHub does for a review comment: the code below moves down to make room,
-- and the box grows as you write. Its keys work as in Claude's prompt: ctrl+a
-- and ctrl+e go to the start and end of the line, shift+Enter starts a new
-- line, and Enter sends the comment with the file and lines, like
-- "nvim/init.lua:540-560: make it faster", so Claude starts on it. <Esc>
-- cancels.

local M = {}

local ns = vim.api.nvim_create_namespace("claude.comment")

-- Run a command, and say so when it fails.
local function run(command)
	local result = vim.system(command, { text = true }):wait()
	if result.code ~= 0 then
		vim.notify("Couldn't reach Claude: " .. vim.trim(result.stderr or ""), vim.log.levels.WARN)
	end
	return result.code == 0
end

-- The tmux pane just left of Neovim's, in the window Neovim's pane is in. A
-- column of border separates two panes side by side.
local function tmux_pane()
	local me = vim.env.TMUX_PANE
	local result = vim.system({
		"tmux",
		"list-panes",
		"-t",
		me,
		"-F",
		"#{pane_id} #{pane_left} #{pane_right} #{pane_top} #{pane_bottom}",
	}, { text = true }):wait()
	if result.code ~= 0 then
		return nil
	end
	local panes = {}
	for id, left, right, top, bottom in result.stdout:gmatch("(%S+) (%d+) (%d+) (%d+) (%d+)") do
		panes[id] = { left = tonumber(left), right = tonumber(right), top = tonumber(top), bottom = tonumber(bottom) }
	end
	local mine = panes[me]
	if not mine then
		return nil
	end
	local best, most = nil, -1
	for id, pane in pairs(panes) do
		local overlap = math.min(pane.bottom, mine.bottom) - math.max(pane.top, mine.top)
		if pane.right + 2 == mine.left and overlap > most then
			best, most = id, overlap
		end
	end
	return best
end

-- The Rex pane just left of Neovim's. Neovim inherits its own pane from
-- REX_BLOCK, and Rex takes that block ID wherever a session goes. Rex gives
-- each pane's rect as x, y, width and height, from 0 to 1, within its tab.
local function rex_pane()
	local me = vim.env.REX_BLOCK
	if not me then
		return nil
	end
	local result = vim.system({ "rex", "session", "inspect", me, "--json" }, { text = true }):wait()
	if result.code ~= 0 then
		return nil
	end
	for _, window in ipairs(vim.json.decode(result.stdout).windows) do
		local rects = {}
		local function walk(node)
			if node.block_id then
				rects[node.block_id] = node.rect
			elseif node.split then
				walk(node.split.before)
				walk(node.split.after)
			end
		end
		for _, layer in ipairs(window.layers or {}) do
			if layer.layout then
				walk(layer.layout)
			end
		end
		local mine = rects[me]
		if mine then
			-- The pane whose right edge touches Neovim's left edge, and that
			-- overlaps it the most from top to bottom.
			local best, most = nil, 0
			for id, rect in pairs(rects) do
				local overlap = math.min(rect[2] + rect[4], mine[2] + mine[4]) - math.max(rect[2], mine[2])
				if math.abs(rect[1] + rect[3] - mine[1]) < 1e-6 and overlap > most then
					best, most = id, overlap
				end
			end
			return best
		end
	end
end

-- Claude's pane, just left of Neovim's, in tmux or Rex, with the ways to type
-- into it. In tmux, Claude runs in a tmux pane even when tmux runs
-- in Rex, so tmux comes first.
local function claude()
	if vim.env.TMUX then
		local pane = tmux_pane()
		return pane
			and {
				text = function(text)
					return run({ "tmux", "send-keys", "-t", pane, "-l", text })
				end,
				enter = function()
					return run({ "tmux", "send-keys", "-t", pane, "Enter" })
				end,
				-- Shift+Enter reaches Claude through tmux only with its extended
				-- keys on. A backslash before Enter starts a new line in Claude's
				-- prompt in any terminal.
				newline = function()
					return run({ "tmux", "send-keys", "-t", pane, "-l", "\\" })
						and run({ "tmux", "send-keys", "-t", pane, "Enter" })
				end,
			}
	end
	local pane = rex_pane()
	local function rex(command, ...)
		return run({ "rex", command, "-s", vim.env.REX_BLOCK, ... })
	end
	return pane
		and {
			text = function(text)
				return rex("send", "-b", pane, text)
			end,
			enter = function()
				return rex("send-key", "-b", pane, "enter")
			end,
			newline = function()
				return rex("send-key", "-b", pane, "shift+enter")
			end,
		}
end

-- Type the lines into Claude's pane and press Enter, so Claude starts on them.
-- Enter would submit, so each new line goes in as Claude's prompt takes one.
function M.send(lines)
	local pane = claude()
	if not pane then
		return vim.notify("No pane left of Neovim", vim.log.levels.WARN)
	end
	for i, line in ipairs(lines) do
		if i > 1 and not pane.newline() then
			return
		end
		if line ~= "" and not pane.text(line) then
			return
		end
	end
	pane.enter()
end

-- The box can grow to this many lines before it scrolls.
local max_height = 10

-- Open a comment box below the current line, or the selected lines when called
-- from visual mode.
function M.comment()
	local first, last = vim.fn.line("v"), vim.fn.line(".")
	first, last = math.min(first, last), math.max(first, last)
	-- The selected text on each line, as visual mode shows it. Without a
	-- selection, the text of the current line.
	local mode = vim.fn.mode()
	local selected = mode:match("^[vV\22]")
	local regions = vim.fn.getregionpos(vim.fn.getpos("v"), vim.fn.getpos("."), { type = selected and mode or "V" })
	if selected then
		vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
	end
	local code_win, code_buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
	local path = vim.fn.expand("%:.")
	local where = path ~= "" and (path .. ":" .. (first == last and first or first .. "-" .. last)) or nil

	-- Keep the selection marked while the box is open, over the same text. An
	-- empty line gets one marked cell, as in visual mode.
	local marks = {}
	for _, region in ipairs(regions) do
		local row = region[1][2] - 1
		local length = #vim.fn.getline(row + 1)
		local from, to = region[1][3] - 1, math.min(region[2][3], length)
		if length == 0 then
			table.insert(marks, vim.api.nvim_buf_set_extmark(code_buf, ns, row, 0, {
				virt_text = { { " ", "Visual" } },
				virt_text_pos = "overlay",
			}))
		elseif to > from then
			table.insert(marks, vim.api.nvim_buf_set_extmark(code_buf, ns, row, from, { end_col = to, hl_group = "Visual" }))
		end
	end

	-- Open room for the box below the lines with virtual lines.
	local room
	local function make_room(height)
		local lines = {}
		for _ = 1, height do
			table.insert(lines, { { "" } })
		end
		room = vim.api.nvim_buf_set_extmark(code_buf, ns, last - 1, 0, { id = room, virt_lines = lines })
	end
	make_room(1)

	-- Scroll so the lines and the box fit in the window.
	vim.api.nvim_win_set_cursor(code_win, { last, 0 })
	if vim.fn.winline() + 1 > vim.api.nvim_win_get_height(code_win) then
		vim.cmd("normal! zt")
	end

	local textoff = vim.fn.getwininfo(code_win)[1].textoff
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = "markdown"
	-- No completion menu, which would take Enter.
	vim.b[buf].completion = false
	-- No border: the float's own background marks the box.
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "win",
		win = code_win,
		bufpos = { last - 1, 0 },
		row = 1,
		col = textoff,
		width = math.max(vim.api.nvim_win_get_width(code_win) - textoff, 20),
		height = 1,
		style = "minimal",
		border = "none",
	})
	vim.wo[win].wrap = true
	vim.wo[win].linebreak = true
	vim.cmd("startinsert")

	local closed = false
	local function close()
		if closed then
			return
		end
		closed = true
		pcall(vim.api.nvim_win_close, win, true)
		for _, id in ipairs(vim.list_extend(marks, { room })) do
			pcall(vim.api.nvim_buf_del_extmark, code_buf, ns, id)
		end
	end

	-- Grow the box and the room below the lines as the comment gets longer.
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		buffer = buf,
		callback = function()
			local lines = vim.api.nvim_win_text_height(win, {}).all
			local height = math.min(lines, max_height)
			if height ~= vim.api.nvim_win_get_height(win) then
				vim.api.nvim_win_set_height(win, height)
				make_room(height)
			end
			-- A new line scrolls the box before it grows. Show the whole comment
			-- again when it fits.
			if lines <= max_height then
				vim.api.nvim_win_call(win, function()
					vim.fn.winrestview({ topline = 1 })
				end)
			end
		end,
	})
	-- Leaving the box, like with a window command, cancels it.
	vim.api.nvim_create_autocmd("WinLeave", {
		buffer = buf,
		once = true,
		callback = vim.schedule_wrap(close),
	})

	local function send()
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		-- Leave out empty lines at the start and the end.
		while #lines > 0 and vim.trim(lines[1]) == "" do
			table.remove(lines, 1)
		end
		while #lines > 0 and vim.trim(lines[#lines]) == "" do
			table.remove(lines)
		end
		vim.cmd("stopinsert")
		close()
		if #lines > 0 then
			if where then
				lines[1] = where .. ": " .. lines[1]
			end
			M.send(lines)
		end
	end
	vim.keymap.set({ "n", "i" }, "<CR>", send, { buffer = buf })
	-- The rest of the keys of Claude's prompt. option+Backspace arrives as Esc
	-- then Backspace, which reads as <M-BS>.
	vim.keymap.set("i", "<M-BS>", "<C-w>", { buffer = buf })
	vim.keymap.set("i", "<S-CR>", "<CR>", { buffer = buf })
	vim.keymap.set("i", "<C-a>", "<Home>", { buffer = buf })
	vim.keymap.set("i", "<C-e>", "<End>", { buffer = buf })
	vim.keymap.set({ "n", "i" }, "<Esc>", function()
		vim.cmd("stopinsert")
		close()
	end, { buffer = buf, nowait = true })
	vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
end

return M
