vim.pack.add({
	"https://github.com/rose-pine/neovim",
	"https://github.com/creativenull/efmls-configs-nvim",
	"https://github.com/mason-org/mason.nvim",
	"https://github.com/christoomey/vim-tmux-navigator",
	"https://github.com/editorconfig/editorconfig-vim",
	"https://github.com/tpope/vim-fugitive",
	"https://github.com/tpope/vim-eunuch",
	"https://github.com/tpope/vim-surround",
	"https://github.com/tomtom/tcomment_vim",
	"https://github.com/scrooloose/nerdtree",
	"https://github.com/windwp/nvim-autopairs",
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "master" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "master" },
	"https://github.com/ibhagwan/fzf-lua",
	"https://github.com/lukas-reineke/indent-blankline.nvim",
	{ src = "https://github.com/saghen/blink.cmp", version = "v1.8.0" },
	"https://github.com/zbirenbaum/copilot.lua",
	"https://github.com/copilotlsp-nvim/copilot-lsp",
	"https://github.com/folke/sidekick.nvim",
	"https://github.com/lewis6991/gitsigns.nvim",
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
vim.cmd("colorscheme rose-pine")

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
vim.keymap.set({ "n", "v" }, "\\", "gcc", { remap = true })
-- vim.keymap.set("n", "<leader>t", ":GFiles<CR>")
vim.keymap.set("n", "<leader>t", require("fzf-lua").files)
vim.keymap.set("n", "<space>", "za")

local au = vim.api.nvim_create_augroup("MyAutocmds", { clear = true })

-- set 0 fold in typescript
vim.api.nvim_create_autocmd("FileType", {
	group = au,
	pattern = "typescript",
	callback = function()
		vim.opt_local.foldlevel = 0
	end,
})

-- Have } and { navigate past folds
vim.keymap.set("n", "}", function()
	local ln = vim.fn.search("^$", "Wn")
	return vim.fn.foldclosed(ln) == -1 and "}" or "}j}"
end, { expr = true, noremap = true })

vim.keymap.set("n", "{", function()
	local ln = vim.fn.search("^$", "Wnb")
	return vim.fn.foldclosed(ln) == -1 and "{" or "{k{"
end, { expr = true, noremap = true })

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

-- resize splits on window resize
vim.api.nvim_create_autocmd("VimResized", {
	group = au,
	pattern = "*",
	callback = function()
		vim.cmd("wincmd =")
	end,
})

-- Make diagnostics show on jump
vim.diagnostic.config({ jump = { float = true } })

-- lsp
require("mason").setup()

vim.lsp.config("*", {
	settings = {
		root_markers = { ".git" },
	},
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

-- If using nvim >= 0.11 then use the following
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
vim.lsp.config("tsserver", {
	cmd = { "typescript-language-server", "--stdio" },
	filetypes = { "typescript", "typescriptreact" },
})

local definition_vsplit = function()
	vim.lsp.buf_request(
		0,
		"textDocument/definition",
		vim.lsp.util.make_position_params(0, "utf-8"),
		function(err, result, ctx)
			if result == nil or vim.tbl_isempty(result) then
				return nil
			end

			vim.cmd("vsplit")
			vim.cmd("wincmd l")

			if vim.islist(result) then
				vim.lsp.util.show_document(result[1], "utf-8")

				if #result > 1 then
					vim.fn.setqflist(vim.lsp.util.locations_to_items(result, "utf-8"))
					vim.api.nvim_command("copen")
					vim.api.nvim_command("wincmd p")
				end
			else
				vim.lsp.util.show_document(result[1], "utf-8")
			end
		end
	)
end

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		-- lsp keymaps
		local opts = { noremap = true, silent = true }

		vim.keymap.set("n", "<leader>h", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
		vim.keymap.set("n", "gD", definition_vsplit, opts)
		vim.keymap.set("n", "S", vim.lsp.buf.signature_help, opts)
		vim.keymap.set("n", "<leader>r", vim.lsp.buf.references, opts)
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
		vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action, opts)
	end,
})

-- lua
vim.lsp.config("lua", {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	settings = { Lua = { diagnostics = { globals = { "vim" } } } },
})

-- copilot
vim.lsp.config("copilot", {
	cmd = { "copilot-language-server", "--stdio" },
})

-- copilot.lua
require("copilot").setup({
	suggestion = {
		enabled = true,
		auto_trigger = true,
		keymap = {
			accept = "<Tab>",
		},
	},
	nes = {
		enabled = false,
		auto_trigger = false,
		keymap = {
			accept_and_goto = "<leader>s",
			accept = false,
			dismiss = false,
		},
	},
	filetypes = {
		typescript = true,
		typescriptreact = true,
		json = true,
		lua = true,
		gitcommit = true,
		["*"] = false,
	},
})

vim.lsp.enable({ "efm", "tsserver", "lua", "copilot" })

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
require("nvim-treesitter").setup({
	ensure_installed = treesitter_languages,
	highlight = {
		enabled = true,
		disable = function(_, buf)
			local max_filesize = 300 * 1024 -- 300 KB
			local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
			if ok and stats and stats.size > max_filesize then
				return true
			end
		end,
		additional_vim_regex_highlighting = false,
	},
})

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
			function()
				return require("sidekick").nes_jump_or_apply()
			end,
			"fallback",
		},
	},
})

-- sidekick
require("sidekick").setup({
	nes = { enabled = false },
	cli = {
		mux = {
			backend = "tmux",
			enabled = true,
		},
	},
})

vim.keymap.set("v", "<leader>as", function()
	require("sidekick.cli").send({ prompt = "selection" })
end)
vim.keymap.set({ "v", "n" }, "<leader>af", function()
	require("sidekick.cli").send({ prompt = "fix" })
end)
vim.keymap.set({ "v", "n" }, "<leader>ap", require("sidekick.cli").prompt)

-- gitsigns
require("gitsigns").setup({})
