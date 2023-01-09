 call plug#begin()
Plug 'Raimondi/delimitMate'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'mileszs/ack.vim'
" Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'christoomey/vim-tmux-navigator'
Plug 'editorconfig/editorconfig-vim'
Plug 'scrooloose/nerdtree'
Plug 'tomtom/tcomment_vim'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
Plug 'tpope/vim-surround'
Plug 'ervandew/supertab'

Plug 'neovim/nvim-lspconfig'
" Plug 'ms-jpq/coq_nvim', {'branch': 'coq'}
" Plug 'folke/lsp-colors.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-treesitter/nvim-treesitter', { 'branch': '0.5-compat', 'do': ':TSUpdate' }
Plug 'kyazdani42/nvim-web-devicons'
Plug 'folke/trouble.nvim'

Plug 'jparise/vim-graphql'
Plug 'leafgarland/typescript-vim'
Plug 'maxmellon/vim-jsx-pretty'
Plug 'peitalin/vim-jsx-typescript'
Plug 'plasticboy/vim-markdown'
Plug 'udalov/kotlin-vim'
Plug 'mustache/vim-mustache-handlebars'

Plug 'NLKNguyen/papercolor-theme'
Plug 'bluz71/vim-moonfly-colors'
Plug 'challenger-deep-theme/vim', { 'as': 'challenger-deep' }
Plug 'haishanh/night-owl.vim'
Plug 'mhartington/oceanic-next'
Plug 'rakr/vim-two-firewatch'
Plug 'rose-pine/neovim'

call plug#end()

" Load indentation
filetype plugin indent on

" Enable syntax highlighting
syntax on

" Use a sane leader
let mapleader = ","

" Show line numbers
set number

" Make tabs appear as two spaces
set tabstop=2

" Use two spaces for tabs
set softtabstop=2

" Indent with two spaces
set shiftwidth=2

" Set sane tab width
set tw=110

" Expand tabs to spaces
set expandtab

" Highlight tabs and trailing spaces
set list listchars=tab:··,trail:·

" Highlight search results
set hlsearch

" Highlight search as we search
set incsearch

" Ignore case in search
set ignorecase

" Smart case sensitive
set smartcase

" Always show tabs
set showtabline=2

" Automatically loadchanged files
set autoread

" Skip nvim welcome message
set shortmess+=I

" Just use the block cursor everywhere
set guicursor=

" Configure splits
set splitright
set splitbelow

" Make CursorHold arrive faster
set updatetime=300

" Don't use F1 for help
nmap <F1> <nop>

" Sync vim and os pasteboard
set clipboard+=unnamedplus

" Mouse configuration
set mouse=a
map <ScrollWheelUp> <C-Y>
map <ScrollWheelDown> <C-E>

" Tab completion
set wildmode=list:longest,list:full
set wildignore+=*.o,*.obj,.git,*.rbc,*.class,.svn,vendor/gems/*,*.scssc,.gitkeep,*.pyc

" Jump to last cursor position on file open
augroup vimrcEx
  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
augroup END

" Make uses real tabs
au FileType make set noexpandtab

" Indent using two spaces for html files
au FileType html setl sw=2 sts=2 et

" TypeScript syntax highlighting
au BufNewFile,BufRead *.tsx,*.jsx set filetype=typescript.tsx
au BufNewFile,BufRead *.ts set filetype=typescript

" Enable spelling for markdown files
au BufRead,BufNewFile *.md setlocal spell

" Enable spelling for git commits
au FileType gitcommit setlocal spell

" Use single \ to comment out line
map \ gcc

" Configure folding
set foldmethod=indent
set foldlevel=10
nnoremap <space> za
au FileType typescript.tsx setlocal foldlevel=0

nnoremap <expr> } foldclosed(search('^$', 'Wn')) == -1 ? "}" : "}j}"
nnoremap <expr> { foldclosed(search('^$', 'Wnb')) == -1 ? "{" : "{k{"

" Allow backspacing over everything in insert mode
set backspace=indent,eol,start

" Load the plugin and indent settings for the detected filetype
filetype plugin indent on

" Don't use backup or swapfiles
set nobackup
set noswapfile

" Tab complete on -
set iskeyword+=-

set hidden

" Enable true color
set termguicolors

" Color scheme
set background=dark
syntax enable
" let g:oceanic_next_terminal_bold = 1
" let g:oceanic_next_terminal_italic = 1
colorscheme OceanicNext

" let g:rose_pine_variant = "moon"
" let g:rose_pine_bold_vertical_split_line = 1
" colorscheme rose-pine


" colorscheme dim
" let g:airline_theme='oceanicnext'
" colorscheme jellybeans
" colorscheme challenger_deep
" colorscheme PaperColor
" colorscheme moonfly
" colorscheme nightfly
" colorscheme night-owl

" Highlights lines longer than 110 chars
highlight OverLength ctermbg=red ctermfg=white guibg=#435762
match OverLength /\%111v.\+/

" Disable ex mode
nnoremap Q <nop>

" Always keep 3 lines visible at all times when scrolling
set scrolloff=3

" Automatically rebalance splits when window is resized
au VimResized * :wincmd =

" set completeopt=menu,menuone,noselect
set completeopt=menu,menuone

" Hack to get vim tmux navigator to work
nmap <bs> :<c-u>TmuxNavigateLeft<cr>

" NERDTree configuration
" map <C-n> :NERDTreeToggle<CR>

" fzf configuration
nmap <leader>t :Files<CR>

" Use a bottom split for fzf
let g:fzf_layout = { 'window': 'bot 15split enew' }
let g:fzf_preview_window = ''

" Reset seach term with esc
nmap <silent> <esc> :let @/ = ""<cr>

" Make fzf colors match Vim colors
let g:fzf_colors = {
  \ 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Comment'],
  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':     ['fg', 'Statement'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'border':  ['fg', 'Ignore'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment'],
\}

" coq configuration.
" let g:coq_settings = {
"   \ 'auto_start': 'shut-up',
"   \ 'display.icons.mode': 'none',
"   \ 'keymap.recommended': v:false,
"   \ 'keymap.jump_to_mark': '<c-q>',
"   \ 'clients.tmux.enabled': v:false,
"   \ 'clients.snippets.enabled': v:false,
" \}
" ino <silent><expr> <Esc>   pumvisible() ? "\<C-e><Esc>" : "\<Esc>"
" ino <silent><expr> <C-c>   pumvisible() ? "\<C-e><C-c>" : "\<C-c>"
" ino <silent><expr> <BS>    pumvisible() ? "\<C-e><BS>"  : "\<BS>"
" ino <silent><expr> <CR>    pumvisible() ? (complete_info().selected == -1 ? "\<C-e><CR>" : "\<C-y>") : "\<CR>"
" ino <silent><expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
" ino <silent><expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<BS>"

" Configure format on save.
autocmd! BufWritePre *.ts :lua vim.lsp.buf.formatting_seq_sync()
autocmd! BufWritePre *.tsx :lua vim.lsp.buf.formatting_seq_sync()
autocmd! BufWritePre *.js :lua vim.lsp.buf.formatting_seq_sync()
autocmd! BufWritePre *.css :lua vim.lsp.buf.formatting_seq_sync()
autocmd! BufWritePre *.json :lua vim.lsp.buf.formatting_seq_sync()

" Configure supertab
let g:SuperTabDefaultCompletionType = "<c-n>"

lua << EOF
local lspconfig = require('lspconfig')
local util = require('vim.lsp.util')

-- vim.lsp.set_log_level('trace')

-- nvim-lsp configuration.
goto_definition = function(split_cmd)
  vim.lsp.buf_request( 0,
    "textDocument/definition",
    util.make_position_params(),
    function(err, result, ctx)
      if result == nil or vim.tbl_isempty(result) then
        print('No location found')
        return nil
      end

      if split_cmd then
        vim.cmd(split_cmd)
      end

      if vim.tbl_islist(result) then
        util.jump_to_location(result[1], 'utf-8')

        if #result > 1 then
          vim.fn.setqflist(util.locations_to_items(result, 'utf-8'))
          vim.api.nvim_command("copen")
          vim.api.nvim_command("wincmd p")
        end
      else
        util.jump_to_location(result, 'utf-8')
      end
    end
  )
end

local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  -- Mappings.
  local opts = { noremap=true, silent=true }
  buf_set_keymap('n', 'gd', '<cmd>lua goto_definition()<cr>', opts)
  buf_set_keymap('n', 'gD', '<cmd>lua goto_definition("vsplit")<cr>', opts)
  buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', 'S', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<leader>a', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  -- buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<leader>e', '<cmd>lua vim.diagnostic.open_float(0, { scope="line" })<CR>', opts)
  buf_set_keymap('n', '[g', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']g', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)

  vim.diagnostic.config({virtual_text=false, signs=true, update_in_insert=false})

  vim.api.nvim_buf_set_option(0, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
end

lspconfig.tsserver.setup({
  on_attach = on_attach,
  flags = {
    debounce_text_changes = 150,
  },
})

lspconfig.graphql.setup({
  on_attach = on_attach,
})

lspconfig.clangd.setup({
  on_attach = on_attach,
  cmd = { "/usr/local/Cellar/llvm/13.0.0_1/bin/clangd", "--background-index" }
})

-- efm configuration.

local prettierd = {
  formatCommand = 'prettierd "${INPUT}"',
  formatStdin = true,
}

local luafmt = {
  formatCommand = "lua-format -i",
  formatStdin = true
}

local rustfmt = {
  formatCommand = "rustfmt",
  formatStdin = true
}

local languages = {
  css = { prettierd },
  graphql = { prettierd },
  html = { prettierd },
  javascript = { prettierd },
  javascriptreact = { prettierd },
  json = { prettierd },
  lua = { luafmt },
  markdown = { prettierd },
  rust = { rustfmt },
  scss = { prettierd },
  typescript = { prettierd },
  typescriptreact = { prettierd },
  yaml = { prettierd }
}

lspconfig.efm.setup {
  filetypes = vim.tbl_keys(languages),
  init_options = { documentFormatting = true },
  settings = {
    languages = languages,
    rootMarkers = { ".git/", "package.json" },
  },
  flags = {
    debounce_text_changes = 150,
  },
}

-- coq configuration.
-- vim.g.coq_settings = {
--   auto_start = 'shut-up',
--   display = {
--     icons = {
--       mode = 'none'
--     }
--   },
--   keymap = {
--     recommended = false,
--     -- Remap this key to not conflict with tmux navigator.
--     jump_to_mark = "<c-q>"
--   },
--   clients = {
--     tmux = {
--       enabled = false,
--     },
--     snippets = {
--       enabled = false,
--     }
--   }
-- }
-- require('coq')

-- Setup trouble
require("trouble").setup {}

vim.api.nvim_set_keymap("n", "<leader>d", "<cmd>Trouble<cr>", {silent = true, noremap = true})
vim.api.nvim_set_keymap("n", "<leader>r", "<cmd>Trouble lsp_references<cr>", {silent = true, noremap = true})

-- Setup telescope
local actions = require("telescope.actions")
local trouble = require("trouble.providers.telescope")

local telescope = require("telescope")

telescope.setup {
  defaults = {
    mappings = {
--      i = { ["<leader>-t>"] = trouble.open_with_trouble },
--      n = { ["<leader>-t"] = trouble.open_with_trouble },

      i = { ["<leader>t>"] = require('telescope.actions').open_qflist },
      n = { ["<leader>t"] = require('telescope.actions').open_qflist },
    },
  },
}

require'nvim-treesitter.configs'.setup {
  ensure_installed = "maintained",
  sync_install = false,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
}
EOF

" CoC configuration

" let g:coc_global_extensions = ['coc-tsserver', 'coc-prettier']
" let g:coc_global_extensions = ['coc-tsserver', 'coc-prettier', 'coc-graphql']

" nmap <silent> gd <Plug>(coc-definition)
" nmap <silent> gD :call CocAction('jumpDefinition', 'vsplit')<enter>
" nmap <silent> gy <Plug>(coc-type-definition)
" nmap <silent> gi <Plug>(coc-implementation)
" nmap <silent> gr <Plug>(coc-references)
" nmap <silent> <leader>rn <Plug>(coc-rename)
" nmap <silent> [g <Plug>(coc-diagnostic-prev)
" nmap <silent> ]g <Plug>(coc-diagnostic-next)
" nmap <Leader>a <Plug>(coc-codeaction)
" nmap <silent> K :call <SID>show_documentation()<CR>
" nmap <silent> <leader>d :<C-u>CocList diagnostics<cr>
" autocmd CursorHold * silent call CocActionAsync('highlight')

" function! s:show_documentation()
"   if (index(['vim','help'], &filetype) >= 0)
"     execute 'h '.expand('<cword>')
"   else
"     call CocActionAsync('doHover')
"   endif
" endfunction

" Use tab for trigger completion with characters ahead and navigate
" inoremap <silent><expr> <TAB>
"       \ pumvisible() ? "\<C-n>" :
"       \ <SID>check_back_space() ? "\<TAB>" :
"       \ coc#refresh()
" inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
"
" function! s:check_back_space() abort
"   let col = col('.') - 1
"   return !col || getline('.')[col - 1]  =~# '\s'
" endfunction

" ack.vim configuration
" let g:ackprg = 'ag --vimgrep --smart-case'
" nmap <Leader>f :Ack!<Space>
" cnoreabbrev Ack Ack!
" cnoreabbrev Ag Ag!
