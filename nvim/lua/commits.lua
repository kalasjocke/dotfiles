-- Go through git commits with a diff of each changed file.
--
-- A new tab shows the list of commits at the bottom and the diff above it.
-- In the list and in the diff:
--
--   <CR> o  on a commit: show or hide its files. On a file: open its diff.
--   ]c [c   next or previous commit, at its first file
--   ]f [f   next or previous file of the commit, wrapping around
--   ]h [h   next or previous hunk in the diff
--   K       the full commit message
--   q       close the tab
--
-- The diff shows the file as of the commit, as ,gd shows a buffer's changes
-- with gitsigns: added and changed lines highlighted, removed lines shown above
-- them, and unchanged lines folded. Closing the list with :q closes the tab.
--
-- The file is the real one, checked out in a worktree of the repo at
-- <git dir>/commits-view, so language servers work in it as in any file. The
-- worktree shares the repo's objects, so it needs no fetch, and its
-- node_modules folders link to the ones in the checkout. Its files are
-- read-only. A file the commit deleted shows in a scratch buffer instead.

local M = {}

local ns = vim.api.nvim_create_namespace("commits")
-- Color the counts and statuses with the text color of the diff groups. Some
-- themes give those groups a background too, which this leaves out.
local function set_highlights()
	for name, from in pairs({ CommitsAdded = "Added", CommitsRemoved = "Removed", CommitsChanged = "Changed" }) do
		vim.api.nvim_set_hl(0, name, { fg = vim.api.nvim_get_hl(0, { name = from, link = false }).fg, default = true })
	end
	vim.api.nvim_set_hl(0, "CommitsSelected", { link = "Visual", default = true })
	vim.api.nvim_set_hl(0, "CommitsAddLine", { link = "GitSignsAddLn", default = true })
	vim.api.nvim_set_hl(0, "CommitsChangeLine", { link = "GitSignsChangeLn", default = true })
	vim.api.nvim_set_hl(0, "CommitsDeleteLine", { link = "GitSignsDeleteVirtLn", default = true })
end
set_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_highlights })

-- One header line per commit, then the --raw and --numstat lines of its files.
-- %x1e starts a commit and %x1f separates its fields.
local format = "--format=%x1e%H%x1f%h%x1f%P%x1f%an%x1f%ar%x1f%D%x1f%s"

local status_hl = { A = "CommitsAdded", D = "CommitsRemoved", M = "CommitsChanged" }

local function git(root, args)
	local result = vim.system(vim.list_extend({ "git", "-C", root }, args), { text = true }):wait()
	if result.code ~= 0 then
		return nil, vim.trim(result.stderr or "")
	end
	return result.stdout
end

-- The repo of the current file, or of the current directory.
local function repo()
	local name = vim.api.nvim_buf_get_name(0)
	local file = vim.bo.buftype == "" and name ~= "" and vim.fn.resolve(name) or nil
	local dirs = { vim.fn.getcwd() }
	if file then
		table.insert(dirs, 1, vim.fs.dirname(file))
	end
	for _, dir in ipairs(dirs) do
		local root = git(dir, { "rev-parse", "--show-toplevel" })
		if root then
			return vim.trim(root), file and vim.fs.relpath(vim.trim(root), file)
		end
	end
end

local function parse(out)
	local commits = {}
	for chunk in out:gmatch("\30([^\30]*)") do
		local lines = vim.split(chunk, "\n", { trimempty = true })
		local f = vim.split(lines[1], "\31")
		local commit = {
			hash = f[1],
			short = f[2],
			parent = f[3]:match("^%S+"),
			author = f[4],
			date = f[5],
			refs = f[6],
			subject = f[7],
			files = {},
			adds = 0,
			dels = 0,
		}
		local by_path = {}
		for i = 2, #lines do
			local status, path = lines[i]:match("^:%S+ %S+ %S+ %S+ (%a)%d*\t(.+)$")
			if status then
				by_path[path] = { path = path, status = status, adds = "-", dels = "-" }
				table.insert(commit.files, by_path[path])
			else
				local adds, dels, numstat_path = lines[i]:match("^(%S+)\t(%S+)\t(.+)$")
				local file = numstat_path and by_path[numstat_path]
				if file then
					file.adds, file.dels = adds, dels
					commit.adds = commit.adds + (tonumber(adds) or 0)
					commit.dels = commit.dels + (tonumber(dels) or 0)
				end
			end
		end
		table.insert(commits, commit)
	end
	return commits
end

local function pad(value, width)
	value = tostring(value)
	return value .. string.rep(" ", width - #value)
end

-- Draw the list. Each row is a commit or one of its files. The counts sit at
-- the right edge of the window, in columns: files, added and removed. Returns
-- the row marked as the one in the diff.
local function render(state)
	local w = { files = 0, adds = 0, dels = 0 }
	for _, commit in ipairs(state.commits) do
		w.files = math.max(w.files, #tostring(#commit.files))
		w.adds = math.max(w.adds, #tostring(commit.adds))
		w.dels = math.max(w.dels, #tostring(commit.dels))
	end
	local lines, highlights, counts = {}, {}, {}
	state.rows = {}
	local function add(segments, row, files, adds, dels)
		local text = ""
		for _, segment in ipairs(segments) do
			if segment[2] then
				table.insert(highlights, { #lines, #text, #text + #segment[1], segment[2] })
			end
			text = text .. segment[1]
		end
		if state.counts then
			counts[#lines] = {
				{ " " .. pad(files, w.files), "NonText" },
				{ "  " },
				{ pad(adds, w.adds), "CommitsAdded" },
				{ " " },
				{ pad(dels, w.dels) .. " ", "CommitsRemoved" },
			}
		end
		table.insert(lines, text)
		table.insert(state.rows, row)
	end
	for ci, commit in ipairs(state.commits) do
		local segments = { { commit.short, "Identifier" } }
		if commit.refs ~= "" then
			table.insert(segments, { " (" .. commit.refs .. ")", "String" })
		end
		table.insert(segments, { " " .. commit.subject })
		table.insert(segments, { " " .. commit.author .. ", " .. commit.date, "Comment" })
		add(segments, { commit = ci }, #commit.files, commit.adds, commit.dels)
		if state.expanded[ci] then
			for fi, file in ipairs(commit.files) do
				segments =
					{ { "  " .. file.status, status_hl[file.status] or "NonText" }, { " " .. file.path, "NonText" } }
				add(segments, { commit = ci, file = fi }, "", file.adds, file.dels)
			end
		end
	end
	local buf = state.list_buf
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	for _, hl in ipairs(highlights) do
		vim.api.nvim_buf_set_extmark(buf, ns, hl[1], hl[2], { end_col = hl[3], hl_group = hl[4] })
	end
	for row, chunks in pairs(counts) do
		vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
			virt_text = chunks,
			virt_text_pos = "right_align",
			-- Keep the selected row's background under the counts.
			hl_mode = "combine",
		})
	end
	-- Mark the file in the diff, or its commit when its files are hidden.
	local current, selected = state.current, 1
	for i, row in ipairs(state.rows) do
		if row.commit == current.commit and (not row.file or row.file == current.file) then
			selected = i
		end
	end
	vim.api.nvim_buf_set_extmark(buf, ns, selected - 1, 0, { line_hl_group = "CommitsSelected" })
	return selected
end

local function lines_at(root, rev, path)
	local out = rev and git(root, { "show", rev .. ":" .. path })
	if not out then
		return {}
	end
	local lines = vim.split(out, "\n")
	if lines[#lines] == "" then
		table.remove(lines)
	end
	return lines
end

-- The node_modules folders of the checkout, up to three levels down.
local function find_dependencies(root)
	local found = {}
	local function skip(dir)
		local name = vim.fs.basename(dir)
		return name ~= "node_modules" and not name:match("^%.")
	end
	for rel, type in vim.fs.dir(root, { depth = 3, skip = skip }) do
		if type == "directory" and vim.fs.basename(rel) == "node_modules" then
			table.insert(found, rel)
		end
	end
	return found
end

-- Link the checkout's node_modules folders into the view, so imports resolve.
-- They hold the checkout's installed packages, not the commit's. Run it after
-- each checkout, which can add the folders they go in.
local function link_dependencies(state)
	for _, rel in ipairs(state.dependencies) do
		local target, link = state.root .. "/" .. rel, state.view .. "/" .. rel
		local stat = vim.uv.fs_lstat(link)
		if stat and stat.type == "link" and vim.uv.fs_readlink(link) ~= target then
			vim.uv.fs_unlink(link)
			stat = nil
		end
		if not stat and vim.uv.fs_stat(vim.fs.dirname(link)) then
			vim.uv.fs_symlink(target, link)
		end
	end
end

-- The view's files are read-only. When a checkout changes one that's open,
-- reload it without asking. When it removes one, close it. Neovim would
-- otherwise warn about the missing file and then wait a second.
local view_files = "*/commits-view/*"
vim.api.nvim_create_autocmd("BufReadPost", {
	pattern = view_files,
	callback = function(args)
		vim.bo[args.buf].readonly = true
		vim.bo[args.buf].modifiable = false
	end,
})
vim.api.nvim_create_autocmd("FileChangedShell", {
	pattern = view_files,
	callback = function(args)
		if vim.v.fcs_reason ~= "deleted" then
			vim.v.fcs_choice = "reload"
			return
		end
		vim.v.fcs_choice = ""
		-- This autocmd may not delete buffers itself.
		vim.schedule(function()
			if vim.api.nvim_buf_is_valid(args.buf) and #vim.fn.win_findbuf(args.buf) == 0 then
				pcall(vim.api.nvim_buf_delete, args.buf, {})
			end
		end)
	end,
})

-- The view worktree of the repo, created the first time.
local function view_for(root)
	local common = git(root, { "rev-parse", "--path-format=absolute", "--git-common-dir" })
	if not common then
		return nil
	end
	local view = vim.trim(common) .. "/commits-view"
	if not vim.uv.fs_stat(view .. "/.git") then
		git(root, { "worktree", "prune" })
		local _, err = git(root, { "worktree", "add", "--quiet", "--detach", view, "HEAD" })
		if err then
			vim.notify("Can't create " .. view .. ": " .. err, vim.log.levels.WARN)
			return nil
		end
	end
	return view
end

-- Check out a commit in the view and reload its files that are open.
-- Tell the language servers working there which files changed, since the
-- vtsls watcher in init.lua skips paths under .git.
local function checkout(state, hash)
	if state.checked_out == hash then
		return true
	end
	local _, err = git(state.view, { "checkout", "--quiet", "--detach", "--force", hash })
	if err then
		vim.notify(err, vim.log.levels.WARN)
		return false
	end
	local from = state.checked_out
	state.checked_out = hash
	link_dependencies(state)
	vim.cmd("checktime")
	local diff = from and git(state.view, { "diff", "--name-status", "--no-renames", from, hash })
	if not diff then
		return true
	end
	local changes = {}
	for status, path in diff:gmatch("(%a)%d*\t([^\n]+)") do
		local kind = ({ A = 1, D = 3 })[status] or 2
		table.insert(changes, { uri = vim.uri_from_fname(state.view .. "/" .. path), type = kind })
	end
	for _, client in ipairs(vim.lsp.get_clients()) do
		if client.root_dir and vim.startswith(client.root_dir, state.view) then
			client:notify("workspace/didChangeWatchedFiles", { changes = changes })
		end
	end
	return true
end

-- The keys of the list and the diff, besides <CR> and o in the list. Set
-- further down, as they call functions defined there.
local keys, map

-- The browser state of each buffer the diff window shows.
local showing = {}

-- Take the diff off a buffer the diff window no longer shows, and close it
-- when no other window shows it either.
local function release(buf)
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	showing[buf] = nil
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	for lhs in pairs(keys) do
		pcall(vim.keymap.del, "n", lhs, { buffer = buf })
	end
	if #vim.fn.win_findbuf(buf) == 0 then
		pcall(vim.api.nvim_buf_delete, buf, {})
	end
end

local function scratch()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].modifiable = false
	return buf
end

-- Put the file in the diff window: the view's copy, or a scratch buffer with
-- these lines when the view can't show it.
local function open_file(state, hash, path, lines)
	local buf
	if path and state.view and checkout(state, hash) and vim.uv.fs_stat(state.view .. "/" .. path) then
		vim.api.nvim_win_call(state.diff_win, function()
			vim.cmd("silent keepalt keepjumps edit " .. vim.fn.fnameescape(state.view .. "/" .. path))
		end)
		buf = vim.api.nvim_win_get_buf(state.diff_win)
		vim.bo[buf].buflisted = false
	else
		buf = state.diff_buf
		if vim.bo[buf].buftype ~= "nofile" then
			buf = scratch()
		end
		vim.bo[buf].modifiable = true
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		vim.bo[buf].modifiable = false
		pcall(vim.treesitter.stop, buf)
		vim.bo[buf].filetype = path and vim.filetype.match({ filename = path, contents = lines }) or ""
		vim.api.nvim_win_set_buf(state.diff_win, buf)
	end
	if buf ~= state.diff_buf then
		local previous = state.diff_buf
		state.diff_buf = buf
		release(previous)
	end
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	showing[buf] = state
	map(state, buf)
	vim.wo[state.diff_win].winbar = path and ("%#Identifier#" .. hash:sub(1, 7) .. "%* " .. path) or ""
	return buf
end

-- The view's files are real files in a repo, so gitsigns attaches to them a
-- moment after they open, and its ]h and [h replace the browser's. They'd find
-- no hunks, since the view has no uncommitted changes. Put the browser's keys
-- back after each gitsigns update, which comes after its on_attach. Gitsigns
-- stays attached and shows no signs, as the view has nothing to show.
vim.api.nvim_create_autocmd("User", {
	pattern = "GitSignsUpdate",
	callback = function(args)
		local buf = args.data and args.data.buffer
		if buf and showing[buf] then
			map(showing[buf], buf)
		end
	end,
})

-- Unchanged lines more than this far from a change are folded.
local context = 6

-- Draw the old lines diffed into the buffer, and fold the unchanged lines.
-- Returns the line each hunk starts at, with the number of removed lines drawn
-- above it.
local function show_diff(state, buf, old)
	local new = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	if #new == 1 and new[1] == "" then
		new = {}
	end
	local hunks, keep = {}, {}
	local tab = string.rep(" ", vim.bo[buf].tabstop)
	local width = vim.o.columns
	-- An empty file is an empty string, not one empty line, or an added file's
	-- blank lines would match it and split its one hunk.
	local function text(lines)
		return #lines > 0 and table.concat(lines, "\n") .. "\n" or ""
	end
	local diff = vim.text.diff(text(old), text(new), { result_type = "indices", algorithm = "histogram" })
	for _, hunk in ipairs(diff) do
		local old_start, old_count, new_start, new_count = unpack(hunk)
		local line_hl = old_count == 0 and "CommitsAddLine" or "CommitsChangeLine"
		for line = new_start, new_start + new_count - 1 do
			vim.api.nvim_buf_set_extmark(buf, ns, line - 1, 0, { line_hl_group = line_hl })
		end
		-- Removed lines go above the new ones, or below the line before them
		-- when nothing replaced them.
		local virt_lines = {}
		for line = old_start, old_start + old_count - 1 do
			local removed = old[line]:gsub("\t", tab)
			table.insert(
				virt_lines,
				{ { removed .. string.rep(" ", width - vim.fn.strdisplaywidth(removed)), "CommitsDeleteLine" } }
			)
		end
		-- A deleted file has one empty line, and its hunk starts at 0, so its
		-- removed lines go above that line.
		local above = new_count > 0 or new_start == 0
		local anchor = math.max(new_start, 1)
		if #virt_lines > 0 then
			vim.api.nvim_buf_set_extmark(buf, ns, anchor - 1, 0, { virt_lines = virt_lines, virt_lines_above = above })
		end
		table.insert(hunks, { line = anchor, above = above and old_count or 0 })
		local last = new_count > 0 and new_start + new_count - 1 or anchor
		for line = anchor - context, last + context do
			keep[line] = true
		end
	end

	-- Set the folds for this buffer in this window only, so a file opened from
	-- here with gd keeps its usual folding.
	vim.api.nvim_win_call(state.diff_win, function()
		vim.opt_local.foldmethod = "manual"
		vim.opt_local.foldlevel = 0
		vim.cmd("silent! normal! zE")
		local first = nil
		for line = 1, #new + 1 do
			if line <= #new and not keep[line] then
				first = first or line
			elseif first then
				vim.cmd(first .. "," .. (line - 1) .. "fold")
				first = nil
			end
		end
	end)
	return hunks
end

-- Move to the start of the next or previous hunk, with its removed lines in
-- view.
local function jump_hunk(state, direction, from)
	local cursor = from or vim.api.nvim_win_get_cursor(state.diff_win)[1]
	local target = nil
	for _, hunk in ipairs(state.hunks) do
		if direction > 0 and hunk.line > cursor and not target then
			target = hunk
		elseif direction < 0 and hunk.line < cursor then
			target = hunk
		end
	end
	if not target then
		return
	end
	vim.api.nvim_win_call(state.diff_win, function()
		vim.api.nvim_win_set_cursor(0, { target.line, 0 })
		vim.cmd("normal! zz")
		if target.line == 1 then
			vim.fn.winrestview({ topline = 1, topfill = target.above })
		end
	end)
end

-- Open the diff of a commit's file and mark it in the list.
local function show(state, ci, fi)
	local commit = state.commits[ci]
	local file = commit.files[fi]
	state.current = { commit = ci, file = fi }
	local path = file and file.path
	local old = path and lines_at(state.root, commit.parent, path) or {}
	-- Without a view, the scratch buffer needs the file's lines. With one, it
	-- only shows files the commit deleted, which have none.
	local lines = (not state.view and path) and lines_at(state.root, commit.hash, path) or {}
	local buf = open_file(state, commit.hash, path, lines)
	state.hunks = show_diff(state, buf, old)
	vim.api.nvim_win_set_cursor(state.diff_win, { 1, 0 })
	jump_hunk(state, 1, 0)
	vim.api.nvim_win_set_cursor(state.list_win, { render(state), 0 })
end

-- The list row under the cursor, when the cursor is in the list.
local function list_row(state)
	return vim.api.nvim_get_current_win() == state.list_win and state.rows[vim.fn.line(".")] or nil
end

-- Move to the next or previous commit, with its files shown in the list.
local function step_commit(state, direction)
	local ci = state.current.commit + direction
	if state.commits[ci] then
		state.expanded[ci] = true
		show(state, ci, 1)
	end
end

-- Move to the next or previous file of one commit, wrapping around at its
-- first and last file. In the list, that's the commit under the cursor,
-- starting from the file under the cursor. Elsewhere, it's the commit in the
-- diff.
local function step_file(state, direction)
	local row = list_row(state)
	local ci = row and row.commit or state.current.commit
	local files = state.commits[ci].files
	if #files == 0 then
		return
	end
	local fi = row and row.file or (ci == state.current.commit and state.current.file)
	if not fi then
		-- On another commit's line: start at its first file, or its last for [f.
		fi = direction > 0 and 0 or 1
	end
	show(state, ci, (fi - 1 + direction) % #files + 1)
end

local function step_hunk(state, direction)
	for _ = 1, vim.v.count1 do
		jump_hunk(state, direction)
	end
end

local function show_message(state)
	local row = list_row(state)
	local commit = state.commits[row and row.commit or state.current.commit]
	local message = git(state.root, { "show", "-s", "--format=%h %an, %ad%n%n%B", commit.hash }) or ""
	vim.lsp.util.open_floating_preview(vim.split(vim.trim(message), "\n"), "gitcommit", { focus_id = "commits" })
end

local function toggle(state)
	local row = state.rows[vim.fn.line(".")]
	if row.file then
		-- show() puts the diff's cursor on the first hunk. Go there.
		show(state, row.commit, row.file)
		return vim.api.nvim_set_current_win(state.diff_win)
	end
	state.expanded[row.commit] = not state.expanded[row.commit]
	render(state)
end

keys = {
	["]c"] = function(state)
		step_commit(state, 1)
	end,
	["[c"] = function(state)
		step_commit(state, -1)
	end,
	["]f"] = function(state)
		step_file(state, 1)
	end,
	["[f"] = function(state)
		step_file(state, -1)
	end,
	["]h"] = function(state)
		step_hunk(state, 1)
	end,
	["[h"] = function(state)
		step_hunk(state, -1)
	end,
	K = show_message,
	q = function()
		vim.cmd.tabclose()
	end,
}

function map(state, buf)
	for lhs, fn in pairs(keys) do
		vim.keymap.set("n", lhs, function()
			fn(state)
		end, { buffer = buf, nowait = true })
	end
end

-- Open the commits that `git log <args>` lists. opts.root is the repo, and
-- opts.path, when set, is the only file each commit shows, for `git log -L`.
function M.open(args, opts)
	opts = opts or {}
	local root = opts.root or repo()
	if not root then
		return vim.notify("Not in a git repo", vim.log.levels.WARN)
	end
	local log = { "log", format }
	if not opts.path then
		vim.list_extend(log, { "--no-merges", "--no-renames", "--raw", "--numstat" })
	end
	local out, err = git(root, vim.list_extend(log, args))
	if not out then
		return vim.notify(err, vim.log.levels.ERROR)
	end
	local commits = parse(out)
	if #commits == 0 then
		return vim.notify("No commits", vim.log.levels.WARN)
	end
	if opts.path then
		for _, commit in ipairs(commits) do
			commit.files = { { path = opts.path, status = "M" } }
		end
	end

	local state = { root = root, commits = commits, expanded = {}, counts = not opts.path }
	state.view = view_for(root)
	if state.view then
		state.checked_out = vim.trim(git(state.view, { "rev-parse", "HEAD" }) or "")
		state.dependencies = find_dependencies(root)
		link_dependencies(state)
	end
	vim.cmd("tabnew")
	local placeholder = vim.api.nvim_get_current_buf()
	local tab = vim.api.nvim_get_current_tabpage()
	state.diff_win, state.diff_buf = vim.api.nvim_get_current_win(), scratch()
	vim.api.nvim_win_set_buf(state.diff_win, state.diff_buf)
	vim.cmd("botright 17split")
	state.list_win, state.list_buf = vim.api.nvim_get_current_win(), scratch()
	vim.api.nvim_win_set_buf(state.list_win, state.list_buf)
	pcall(vim.api.nvim_buf_delete, placeholder, {})
	vim.bo[state.list_buf].filetype = "commits"
	for option, value in pairs({
		number = false,
		relativenumber = false,
		signcolumn = "no",
		foldcolumn = "0",
		cursorline = true,
		wrap = false,
		winfixheight = true,
	}) do
		vim.wo[state.list_win][option] = value
	end
	map(state, state.list_buf)
	for _, lhs in ipairs({ "<CR>", "o" }) do
		vim.keymap.set("n", lhs, function()
			toggle(state)
		end, { buffer = state.list_buf })
	end
	-- Closing the list or the diff some other way than q, like :q, closes the
	-- tab too.
	for _, win in ipairs({ state.list_win, state.diff_win }) do
		vim.api.nvim_create_autocmd("WinClosed", {
			pattern = tostring(win),
			once = true,
			callback = function()
				vim.schedule(function()
					if vim.api.nvim_tabpage_is_valid(tab) and #vim.api.nvim_list_tabpages() > 1 then
						vim.cmd.tabclose(vim.api.nvim_tabpage_get_number(tab))
					end
					release(state.diff_buf)
				end)
			end,
		})
	end
	show(state, 1, 1)
end

-- The last 100 commits.
function M.log()
	M.open({ "-n", "100" })
end

-- The commits on this branch that origin's default branch doesn't have, oldest
-- first.
function M.branch()
	local root = repo()
	local base = root and git(root, { "rev-parse", "--abbrev-ref", "origin/HEAD" })
	M.open({ vim.trim(base or "origin/main") .. "..HEAD", "--reverse" }, { root = root })
end

-- The commits that changed the current file.
function M.file()
	local root, path = repo()
	if not path then
		return vim.notify("Not a file in a git repo", vim.log.levels.WARN)
	end
	M.open({ "--", path }, { root = root })
end

-- The commits that changed the selected lines. Call it from visual mode.
function M.lines()
	local first, last = vim.fn.line("v"), vim.fn.line(".")
	vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
	local root, path = repo()
	if not path then
		return vim.notify("Not a file in a git repo", vim.log.levels.WARN)
	end
	local range = math.min(first, last) .. "," .. math.max(first, last) .. ":" .. path
	M.open({ "-L", range, "-s" }, { root = root, path = path })
end

return M
