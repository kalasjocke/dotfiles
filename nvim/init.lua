vim.pack.add({
	"https://github.com/rose-pine/neovim",
	"https://github.com/creativenull/efmls-configs-nvim",
	"https://github.com/mason-org/mason.nvim",
	"https://github.com/christoomey/vim-tmux-navigator",
	"https://github.com/editorconfig/editorconfig-vim",
	"https://github.com/tpope/vim-fugitive",
	"https://github.com/tpope/vim-rhubarb",
	"https://github.com/tpope/vim-eunuch",
	"https://github.com/tpope/vim-surround",
	"https://github.com/tomtom/tcomment_vim",
	"https://github.com/scrooloose/nerdtree",
	"https://github.com/windwp/nvim-autopairs",
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
	"https://github.com/ibhagwan/fzf-lua",
	"https://github.com/lukas-reineke/indent-blankline.nvim",
	{ src = "https://github.com/saghen/blink.cmp", version = "v1.10.2" },
	-- "https://github.com/zbirenbaum/copilot.lua",
	-- "https://github.com/copilotlsp-nvim/copilot-lsp",
	"https://github.com/folke/snacks.nvim",
	"https://github.com/coder/claudecode.nvim",
	"https://github.com/lewis6991/gitsigns.nvim",
	"https://github.com/folke/trouble.nvim",
	"https://github.com/rebelot/kanagawa.nvim",
})

-- options
vim.opt.number = true
vim.opt.wrap = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.textwidth = 110
vim.opt.expandtab = true
vim.opt.swapfile = false
vim.g.mapleader = ","
vim.opt.winborder = "rounded"
vim.opt.clipboard = "unnamedplus"
vim.opt.foldmethod = "indent"
vim.opt.foldlevel = 10
vim.opt.signcolumn = "yes"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.cmd.colorscheme("rose-pine")

-- fzf
require("fzf-lua").setup({
	winopts = {
		preview = {
			hidden = true,
		},
	},
})

-- keymaps
vim.keymap.set("n", "<leader>o", ":update<CR> :source<CR>")
vim.keymap.set("n", "<leader>w", ":write<CR>")
vim.keymap.set("n", "<leader>q", ":quit<CR>")
vim.keymap.set({ "n", "v" }, "\\", "gcc", { remap = true })
vim.keymap.set("n", "<leader>t", require("fzf-lua").files)
vim.keymap.set("n", "<leader>f", require("fzf-lua").live_grep)
vim.keymap.set("n", "<leader>s", require("fzf-lua").lsp_live_workspace_symbols)
vim.keymap.set("n", "<space>", "za")
vim.keymap.set("x", "<C-h>", "<Cmd>TmuxNavigateLeft<CR>")
vim.keymap.set("x", "<C-j>", "<Cmd>TmuxNavigateDown<CR>")
vim.keymap.set("x", "<C-k>", "<Cmd>TmuxNavigateUp<CR>")
vim.keymap.set("x", "<C-l>", "<Cmd>TmuxNavigateRight<CR>")
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

local au = vim.api.nvim_create_augroup("MyAutocmds", { clear = true })

-- set 0 fold in typescript
-- vim.api.nvim_create_autocmd("FileType", {
-- 	group = au,
-- 	pattern = "typescript",
-- 	callback = function()
-- 		vim.opt_local.foldlevel = 0
-- 	end,
-- })

-- Have } and { navigate past folds
vim.keymap.set("n", "}", function()
	local ln = vim.fn.search("^$", "Wn")
	return vim.fn.foldclosed(ln) == -1 and "}" or "}j}"
end, { expr = true, noremap = true })

vim.keymap.set("n", "{", function()
	local ln = vim.fn.search("^$", "Wnb")
	return vim.fn.foldclosed(ln) == -1 and "{" or "{k{"
end, { expr = true, noremap = true })

-- restore cursor position when reopening a file
vim.api.nvim_create_autocmd("BufReadPost", {
	group = au,
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
			vim.api.nvim_win_set_cursor(0, mark)
		end
	end,
})

-- set spell in markdown
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	group = au,
	pattern = "*.md",
	callback = function()
		vim.opt_local.spell = true
	end,
})

-- set spell in gitcommit
vim.api.nvim_create_autocmd("FileType", {
	group = au,
	pattern = "gitcommit",
	callback = function()
		vim.opt_local.spell = true
	end,
})

-- reload files changed externally
vim.api.nvim_create_autocmd({ "FocusGained" }, {
	group = au,
	command = "checktime",
})

-- resize splits on window resize
vim.api.nvim_create_autocmd("VimResized", {
	group = au,
	pattern = "*",
	callback = function()
		vim.cmd("wincmd =")
	end,
})

-- Make diagnostics show on jump
vim.diagnostic.config({
	jump = {
		on_jump = function(_, bufnr)
			vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false })
		end,
	},
})

-- lsp
require("mason").setup()

vim.lsp.config("*", {
	root_markers = { ".git" },
})

local eslint = require("efmls-configs.linters.eslint")
local prettier = require("efmls-configs.formatters.prettier_d")
local stylua = require("efmls-configs.formatters.stylua")
local languages = {
	typescript = { eslint, prettier },
	typescriptreact = { eslint, prettier },
	json = { eslint, prettier },
	css = { eslint, prettier },
	html = { prettier },
	lua = { stylua },
	markdown = { prettier },
}

-- efm
vim.lsp.config("efm", {
	cmd = { "efm-langserver" },
	filetypes = vim.tbl_keys(languages),
	settings = {
		languages = languages,
	},
	init_options = {
		documentFormatting = true,
		documentRangeFormatting = true,
	},
})

vim.api.nvim_create_autocmd("BufWritePre", {
	callback = function(args)
		local efm = vim.lsp.get_clients({ name = "efm", bufnr = args.buf })
		if vim.tbl_isempty(efm) then
			return
		end
		vim.lsp.buf.format({ name = "efm", async = false })
	end,
})

-- typescript
-- vim.lsp.config("tsserver", {
-- 	cmd = { "typescript-language-server", "--stdio" },
-- 	filetypes = { "typescript", "typescriptreact" },
-- })
vim.lsp.config("vtsls", {
	cmd = { "vtsls", "--stdio" },
	filetypes = { "typescript", "typescriptreact" },
})

local definition_vsplit = function()
	local client = vim.lsp.get_clients({ bufnr = 0, method = "textDocument/definition" })[1]
	if not client then
		return
	end
	local encoding = client.offset_encoding

	vim.lsp.buf_request(
		0,
		"textDocument/definition",
		vim.lsp.util.make_position_params(0, encoding),
		function(_, result)
			if result == nil or vim.tbl_isempty(result) then
				return nil
			end

			vim.cmd("vsplit")
			vim.cmd("wincmd l")

			if vim.islist(result) then
				vim.lsp.util.show_document(result[1], encoding)

				if #result > 1 then
					vim.fn.setqflist(vim.lsp.util.locations_to_items(result, encoding))
					vim.api.nvim_command("copen")
					vim.api.nvim_command("wincmd p")
				end
			else
				vim.lsp.util.show_document(result, encoding)
			end
		end
	)
end

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		-- lsp keymaps
		local opts = { noremap = true, silent = true }

		vim.keymap.set("n", "<leader>h", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "gd", "<cmd>Trouble lsp_definitions open<cr>", opts)
		vim.keymap.set("n", "gD", definition_vsplit, opts)
		vim.keymap.set("n", "S", vim.lsp.buf.signature_help, opts)
		vim.keymap.set("n", "<leader>r", "<cmd>Trouble lsp_references open focus=true<cr>", opts)
		vim.keymap.set("n", "<leader>d", "<cmd>Trouble diagnostics toggle<cr>", opts)
		vim.keymap.set("n", "<leader>R", vim.lsp.buf.rename, opts)
		vim.keymap.set("n", "<leader>a", function()
			vim.lsp.buf.code_action({
				filter = function(action)
					return not action.disabled
				end,
			})
		end, opts)
	end,
})

-- lua
vim.lsp.config("lua", {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	settings = { Lua = { diagnostics = { globals = { "vim" } } } },
})

-- copilot
-- vim.lsp.config("copilot", {
-- 	cmd = { "copilot-language-server", "--stdio" },
-- })

-- copilot.lua
-- require("copilot").setup({
-- 	suggestion = {
-- 		enabled = true,
-- 		auto_trigger = true,
-- 		keymap = {
-- 			accept = "<Tab>",
-- 		},
-- 	},
-- 	nes = {
-- 		enabled = false,
-- 		auto_trigger = false,
-- 		keymap = {
-- 			accept_and_goto = "<leader>s",
-- 			accept = false,
-- 			dismiss = false,
-- 		},
-- 	},
-- 	filetypes = {
-- 		typescript = true,
-- 		typescriptreact = true,
-- 		json = true,
-- 		lua = true,
-- 		gitcommit = true,
-- 		["*"] = false,
-- 	},
-- })

vim.lsp.enable({ "efm", "vtsls", "lua" })

-- treesitter
local treesitter_languages = {
	"bash",
	"dockerfile",
	"graphql",
	"html",
	"json",
	"lua",
	"markdown",
	"markdown_inline",
	"rust",
	"typescript",
}
require("nvim-treesitter").setup()

vim.api.nvim_create_autocmd("FileType", {
	pattern = treesitter_languages,
	callback = function()
		vim.treesitter.start()
	end,
})

-- autopairs
require("nvim-autopairs").setup({})

-- indentation lines
require("ibl").setup({ scope = { enabled = false } })

-- blink
require("blink.cmp").setup({
	keymap = {
		preset = "enter",
		["<C-k>"] = { "select_prev", "fallback" },
		["<C-j>"] = { "select_next", "fallback" },
		["<Tab>"] = {
			"snippet_forward",
			-- function()
			-- 	return require("sidekick").nes_jump_or_apply()
			-- end,
			"fallback",
		},
	},
})

-- snacks
require("snacks").setup({
	-- default settings
	-- enable = true,
	-- timeout = 1000,
	-- message = "Saved",
	-- position = "top",
})

-- claudecode
require("claudecode").setup({
	visual_demotion_delay_ms = 10,
	terminal = {
		provider = "none",
	},
	diff_opts = {
		open_in_new_tab = true,
	},
})

local function get_claude_pane()
	return vim.trim(vim.fn.system([[
		tmux list-panes -F '#{pane_id} #{pane_pid}' | while IFS=' ' read -r id pid; do
			if pgrep -P "$pid" -f claude >/dev/null 2>&1; then
				printf "%s" "$id"
				break
			fi
		done
	]]))
end

local function focus_claude_pane()
	local pane = get_claude_pane()
	if pane ~= "" then
		vim.fn.system({ "tmux", "select-pane", "-t", pane })
	end
end

vim.keymap.set("v", "<leader>as", function()
	vim.cmd("ClaudeCodeSend")
	focus_claude_pane()
end)
vim.keymap.set("v", "<leader>aS", "<cmd>ClaudeCodeSend<cr>")
vim.keymap.set("v", "<leader>ae", function()
	local pane = get_claude_pane()
	if pane ~= "" then
		vim.fn.system({ "tmux", "send-keys", "-t", pane, "-l", "Explain the selection" })
		vim.fn.system({ "tmux", "send-keys", "-t", pane, "Enter" })
	end
end)

-- gitsigns
require("gitsigns").setup({
	on_attach = function(bufnr)
		local gs = package.loaded.gitsigns
		local opts = { buffer = bufnr }

		-- Navigation
		vim.keymap.set("n", "]h", function()
			gs.nav_hunk("next")
		end, opts)
		vim.keymap.set("n", "[h", function()
			gs.nav_hunk("prev")
		end, opts)

		-- Staging
		vim.keymap.set("n", "<leader>gs", gs.stage_hunk, opts)
		vim.keymap.set("n", "<leader>gr", gs.reset_hunk, opts)
		vim.keymap.set("n", "<leader>gu", gs.undo_stage_hunk, opts)
		vim.keymap.set("n", "<leader>gp", gs.preview_hunk, opts)
		vim.keymap.set("n", "<leader>gS", gs.stage_buffer, opts)
		vim.keymap.set("n", "<leader>gR", gs.reset_buffer, opts)

		-- Visual mode staging
		vim.keymap.set("v", "<leader>gs", function()
			gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, opts)
		vim.keymap.set("v", "<leader>gr", function()
			gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, opts)
	end,
})

-- Git commands
vim.keymap.set("n", "<leader>gb", "<cmd>Gitsigns blame<cr>")
vim.keymap.set("n", "<leader>gd", "<cmd>Gdiffsplit<cr>")

-- trouble
require("trouble").setup({
	keys = {
		["<esc>"] = "close",
	},
	modes = {
		lsp_references = {
			auto_refresh = false,
			follow = false,
		},
	},
})
vim.keymap.set("n", "<leader>c", "<cmd>Trouble close<cr>")
vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>")
vim.keymap.set("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>")
vim.keymap.set("n", "<leader>xq", "<cmd>Trouble qflist toggle<cr>")
