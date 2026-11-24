-- Show the current buffer's changes side by side, as GitHub's split diff does:
-- the index on the left with removed lines in red, the buffer on the right
-- with added lines in green, and an empty row with no line number across from
-- a line only the other side has.
--
-- It's gitsigns' diffthis in Neovim's diff mode, which lines the sides up.
-- Diff mode colors a line that only one side has the same on both sides, so
-- each window maps the diff colors to its own.

local M = {}

-- Blend color a into color b by amount, from 0 to 1.
local function mix(a, b, amount)
	local out = 0
	for shift = 16, 0, -8 do
		local x, y = bit.band(bit.rshift(a, shift), 0xff), bit.band(bit.rshift(b, shift), 0xff)
		out = out + bit.lshift(math.floor(x * amount + y * (1 - amount) + 0.5), shift)
	end
	return out
end

-- Backgrounds only, so syntax colors show through: the theme's Added and
-- Removed colors faint for a line, and stronger for the changed text in it.
local function set_highlights()
	local function fg(name, default)
		return vim.api.nvim_get_hl(0, { name = name, link = false }).fg or default
	end
	local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg or 0
	local add, remove = fg("Added", 0x3fb950), fg("Removed", 0xf85149)
	vim.api.nvim_set_hl(0, "DiffSplitAdd", { bg = mix(add, bg, 0.15) })
	vim.api.nvim_set_hl(0, "DiffSplitAddText", { bg = mix(add, bg, 0.35) })
	vim.api.nvim_set_hl(0, "DiffSplitRemove", { bg = mix(remove, bg, 0.15) })
	vim.api.nvim_set_hl(0, "DiffSplitRemoveText", { bg = mix(remove, bg, 0.35) })
end
set_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_highlights })

-- Diff mode's colors on each side. DiffDelete is the empty row across from a
-- line the other side has.
local sides = {
	left = "DiffAdd:DiffSplitRemove,DiffChange:DiffSplitRemove,DiffText:DiffSplitRemoveText,"
		.. "DiffTextAdd:DiffSplitRemoveText,DiffDelete:Normal",
	right = "DiffAdd:DiffSplitAdd,DiffChange:DiffSplitAdd,DiffText:DiffSplitAddText,"
		.. "DiffTextAdd:DiffSplitAddText,DiffDelete:Normal",
}

-- Set the window's own colors and an empty fill for its side, leaving the
-- values new windows get alone. Returns the values it replaced.
local function style(win, side)
	local saved = {
		winhighlight = vim.api.nvim_get_option_value("winhighlight", { win = win }),
		fillchars = vim.api.nvim_get_option_value("fillchars", { win = win }),
	}
	-- Replace an earlier diff fill, as the window may have this style already.
	local fill = vim.tbl_filter(function(item)
		return not vim.startswith(item, "diff:")
	end, vim.split(saved.fillchars, ",", { trimempty = true }))
	table.insert(fill, "diff: ")
	local fillchars = table.concat(fill, ",")
	vim.api.nvim_set_option_value("winhighlight", sides[side], { scope = "local", win = win })
	vim.api.nvim_set_option_value("fillchars", fillchars, { scope = "local", win = win })
	return saved
end

-- Color two windows in diff mode as GitHub does, with the old version on the
-- left and the new one on the right. Returns a function that puts the right
-- window's options back.
function M.style(left, right)
	style(left, "left")
	local saved = style(right, "right")
	return function()
		if vim.api.nvim_win_is_valid(right) then
			for name, value in pairs(saved) do
				vim.api.nvim_set_option_value(name, value, { scope = "local", win = right })
			end
		end
	end
end

local function index_window()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.startswith(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)), "gitsigns://") then
			return win
		end
	end
end

-- Open the split, or close it when it's open.
function M.toggle()
	local left = index_window()
	if left then
		return vim.api.nvim_win_close(left, false)
	end
	local right = vim.api.nvim_get_current_win()
	require("gitsigns").diffthis(
		nil,
		{ vertical = true },
		vim.schedule_wrap(function(err)
			left = index_window()
			if err or not left then
				return
			end
			-- However the left side closes, put the right side back.
			vim.api.nvim_create_autocmd("WinClosed", {
				pattern = tostring(left),
				once = true,
				callback = M.style(left, right),
			})
		end)
	)
end

return M
