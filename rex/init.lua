rex.bind("cmd+p", "client.palette.toggle")

rex.bind("ctrl+a>h", "pane.split", { direction = "right" })
rex.bind("ctrl+a>v", "pane.split", { direction = "down" })

-- tmux.conf:63 cycled layouts here. Rex has no layouts, so even out the panes.
rex.bind("ctrl+a>space", "pane.balance")

-- Zoom the current pane to fill the tab, or go back to the splits.
rex.bind("cmd+/", "pane.zoom")

-- ctrl+a, then f: find a pane, tab or session with Go to Anything.
rex.bind("ctrl+a>f", "pane.go_to")

-- ctrl+a, then ,: reload this file and apply settings.lua.
rex.bind("ctrl+a>,", "apply_settings")

-- tmux.conf:70
rex.bind("ctrl+a>c", "client.tab.new")

-- ctrl+a, then n or p: go to the next or previous tab.
rex.bind("ctrl+a>n", "client.tab.next")
rex.bind("ctrl+a>p", "client.tab.previous")

local function is_vim(ctx)
	local p = rex.block.call("com.superlogical.terminal", "process", { block_id = ctx.block_id })
	local fg = p and p.foreground
	if not fg then
		return false
	end
	for _, name in ipairs({ fg.name, fg.argv0 }) do
		local base = (name or ""):gsub("^.*/", ""):gsub("diff$", "")
		-- Same names as tmux's is_vim: view, vim, nvim, vi, gvim, vimx, ...
		if base == "view" or base:match("^g?n?vim?x?$") then
			return true
		end
	end
	return false
end

for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
	rex.bind("ctrl+" .. key, function(ctx)
		if is_vim(ctx) then
			return false
		end
		rex.session.focus_direction({ direction = direction })
		return true
	end)
end

-- Reload this file, then apply the settings in settings.lua. The action reads
-- settings.lua each time it runs, so an edit there needs no reload first.
rex.action({
	name = "apply_settings",
	title = "Reload Config and Apply My Settings",
	run = function()
		local settings = dofile(os.getenv("HOME") .. "/.config/rex/settings.lua")
		rex.client.queue("client.config.reload")
		for _, setting in ipairs(settings) do
			rex.client.queue(setting[1], { value = setting[2] })
		end
	end,
})
-- cmd+r: rename the session. ctrl+a, then r: rename the tab.
-- Rex's own rename actions each have their own editor, so these ask in the
-- command palette instead, with the current name filled in. An empty name gives
-- the tab back its generated name.
local function view_or_error()
	local view, err = rex.session.view({})
	if not view then
		error(err, 0)
	end
	return view
end

rex.action({
	name = "rename_current_session",
	title = "Rename Current Session",
	run = function()
		local view = view_or_error()
		local name = rex.ui.input({ title = "Rename Session", value = view.label, confirm = "Rename" })
		if name then
			rex.session.set_label({ label = name })
		end
	end,
})

rex.action({
	name = "rename_current_tab",
	title = "Rename Current Tab",
	run = function()
		local view = view_or_error()
		local current = ""
		for _, window in ipairs(view.windows or {}) do
			if window.window_id == view.active_window_id then
				current = window.label or ""
			end
		end
		-- An unnamed tab has a default label like "Window d6ccdec1".
		if current:match("^Window %x+$") then
			current = ""
		end
		local name = rex.ui.input({ title = "Rename Tab", value = current, confirm = "Rename" })
		if name then
			rex.session.set_window_label({ window_id = view.active_window_id, label = name })
		end
	end,
})

rex.bind("cmd+r", "rename_current_session")
rex.bind("ctrl+a>r", "rename_current_tab")

-- Importing adds a new custom theme each time, so run this once per Mac.
rex.action({
	name = "import_dark_theme",
	title = "Import My Dark Theme",
	run = function()
		rex.client.queue("client.theme.import", {
			path = os.getenv("HOME") .. "/.config/rex/themes/Merino Dark White Cursor",
		})
	end,
})

-- tmux.conf:75-84: ctrl+a, m, then 1-9 moves the current tab to that position.
rex.action({
	name = "move_tab",
	title = "Move Tab to Position",
	args = { index = "integer" },
	run = function(ctx, args)
		local view, err = rex.session.view({})
		if not view then
			error(err, 0)
		end
		local others = {}
		for _, window in ipairs(view.windows) do
			if window.window_id ~= view.active_window_id then
				table.insert(others, window.window_id)
			end
		end
		-- Place it before the tab now at that position, or last if there is none.
		local _, move_err = rex.session.move_window({
			window_id = view.active_window_id,
			before_window_id = others[args.index],
		})
		if move_err then
			error(move_err, 0)
		end
	end,
})
for index = 1, 9 do
	rex.bind("ctrl+a>m>" .. index, "move_tab", { index = index })
end

-- tmux's default ctrl+a, then 1-9 (base-index 1): go to the tab at that position.
for index = 1, 9 do
	rex.bind("ctrl+a>" .. index, "client.tab.goto", { index = index })
end

-- cmd+1-9: go to the session at that position, in the order rex ls lists them.
-- ctrl+a, then 1-9 goes to a tab instead.
rex.action({
	name = "goto_session",
	title = "Go to Session at Position",
	args = { index = "integer" },
	run = function(ctx, args)
		local list, err = rex.call("session.list", {})
		if not list then
			error(err, 0)
		end
		local target = (list.sessions or {})[args.index]
		if target and ctx.client_id then
			rex.client.queue("session.select", { session_id = target.session_id })
		end
	end,
})
for index = 1, 9 do
	rex.bind("cmd+" .. index, "goto_session", { index = index })
end

-- cmd+s: open the session list, Rex's Change Session picker.
rex.bind("cmd+s", "session.switch")

-- tmux's default ctrl+a, then [: copy mode, with vi keys as in tmux.conf:94-98.
rex.bind("ctrl+a>[", "pane.copy_mode.enter")

local shell = "com.superlogical.terminal.shell"
local src = os.getenv("HOME") .. "/src"

-- The directory of the program in front in the current pane. Shells here
-- don't report their directory to Rex, so pwd is often empty.
local function current_dir(ctx)
	if not ctx.block_id then
		return nil
	end
	local terminal = "com.superlogical.terminal"
	local pwd = rex.block.call(terminal, "pwd", { block_id = ctx.block_id })
	local process = rex.block.call(terminal, "process", { block_id = ctx.block_id })
	return (pwd and pwd.path) or (process and process.foreground and process.foreground.cwd)
end

-- tmux.conf:70: Claude Code on the left and a shell on the right. Claude Code
-- is typed into a shell, so quitting it leaves the shell.
local function claude_layout(cwd)
	return rex.layout.horizontal(
		0.5,
		rex.layout.block({ flavor = shell, options = { cwd = cwd, initial_input = "claude\r" } }),
		rex.layout.block({ flavor = shell, options = { cwd = cwd } })
	)
end

-- Create a session with one tab and show it. Without a label, the server picks
-- a name, as New Session does.
local function new_session(ctx, layout)
	local created, err = rex.call("session.create", { initial_windows = { { layout = layout } } })
	if not created then
		error(err, 0)
	end
	if ctx.client_id then
		rex.client.queue("session.select", { session_id = created.session_id })
	end
	return { session_id = created.session_id }
end

rex.action({
	name = "claude_tab",
	title = "New Claude Code Tab",
	run = function(ctx)
		local _, err = rex.session.new_window({ layout = claude_layout(current_dir(ctx)) })
		if err then
			error(err, 0)
		end
	end,
})

rex.action({
	name = "src_session",
	title = "New Session in ~/src",
	run = function(ctx)
		return new_session(ctx, rex.layout.block({ flavor = shell, options = { cwd = src } }))
	end,
})
rex.bind("cmd+n", "src_session")

rex.action({
	name = "claude_session",
	title = "New Claude Code Session in ~/src",
	run = function(ctx)
		return new_session(ctx, claude_layout(src))
	end,
})
rex.bind("shift+cmd+n", "claude_session")
