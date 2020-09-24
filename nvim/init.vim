call plug#begin()
Plug 'Raimondi/delimitMate'
Plug 'alampros/vim-styled-jsx'
Plug 'christoomey/vim-tmux-navigator'
Plug 'editorconfig/editorconfig-vim'
Plug 'fatih/vim-go'
Plug 'jparise/vim-graphql'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'leafgarland/typescript-vim'
Plug 'maxmellon/vim-jsx-pretty'
Plug 'mhartington/oceanic-next'
Plug 'mileszs/ack.vim'
Plug 'mxw/vim-jsx'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'othree/html5.vim'
Plug 'pangloss/vim-javascript'
Plug 'pantharshit00/vim-prisma'
Plug 'plasticboy/vim-markdown'
Plug 'rakr/vim-two-firewatch'
Plug 'scrooloose/nerdtree'
Plug 'tomtom/tcomment_vim'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'vim-airline/vim-airline'
Plug 'xojs/vim-xo'
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

" Let airline show mode
set noshowmode

" Just use the block cursor everywhere
set guicursor=

" Configure splits
set splitright
set splitbelow

" Make CursorHold arrive faster
set updatetime=300

" Force en_US
language en_US

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

" Jump to last cursor position on file reopen
augroup vimrcEx
  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
augroup END

" Make uses real tabs
au FileType make set noexpandtab

" Add ruby syntax highlighting for Thorfile, Rakefile, Vagrantfile etc.
au BufRead,BufNewFile {Gemfile,Guardfile,Rakefile,Vagrantfile,Thorfile,config.ru} set ft=ruby

" Add html syntax highlighting for .mustache
au BufRead,BufNewFile *.mustache set ft=mustache

" Add html syntax highlighting for .handlebars
au BufRead,BufNewFile *.handlebars set ft=html

" Add html syntax highlighting for .hbs
au BufRead,BufNewFile *.hbs set ft=html

" Indent using two spaces for html files
au FileType html setl sw=2 sts=2 et

" Indent Python with spaces
au Filetype python setl et ts=4 sw=4

" Add html syntax highlighting for .md
au BufRead,BufNewFile *.md set ft=markdown

" TypeScript syntax highlighting
au BufNewFile,BufRead *.tsx,*.jsx set filetype=typescript.tsx
au BufNewFile,BufRead *.ts set filetype=typescript

" Dont show tabs in Go
au BufNewFile,BufRead *.go set list listchars=tab:\ \ ,trail:·

" Enable spelling for markdown files
au BufRead,BufNewFile *.md setlocal spell

" Enable spelling for git commits
au FileType gitcommit setlocal spell

" Use C-d to increase numbers as C-a is used by tmux
nmap <C-d> <C-a>

" Use single \ to comment out line
map \ gcc

" Configure folding
set foldmethod=indent
set foldlevel=10
nnoremap <space> za
au FileType typescript.tsx setlocal foldlevel=0

" Allow backspacing over everything in insert mode
set backspace=indent,eol,start

" Load the plugin and indent settings for the detected filetype
filetype plugin indent on

" Don't use backup or swapfiles
set nobackup
set noswapfile

" Tab complete on -
set iskeyword+=-

" Gist
let g:gist_open_browser_after_post = 1
let g:gist_post_private = 2

set hidden

" Enable true color
set termguicolors

" Color scheme
set background=dark
syntax enable
let g:oceanic_next_terminal_bold = 1
let g:oceanic_next_terminal_italic = 1
colorscheme OceanicNext
let g:airline_theme='oceanicnext'

" Hack to get vim tmux navigator to work in nvim
if has('nvim')
  nmap <bs> :<c-u>TmuxNavigateLeft<cr>
endif

" Highlights lines longer than 80 chars
highlight OverLength ctermbg=red ctermfg=white guibg=#435762
match OverLength /\%81v.\+/

" No ex mode
nnoremap Q <nop>

" Force all jsx syntax highlight for all JavaScript files
let g:jsx_ext_required = 0

" Always keep 5 lines visible at all times when scrolling
set scrolloff=5

" Toggle NERDTree
map <C-n> :NERDTreeToggle<CR>

" fzf configuration
nmap <leader>t :Files<CR>

" Use a bottom split for fzf
let g:fzf_layout = { 'window': 'bot 15split enew' }

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

" Airline configuration
let g:airline_section_b = airline#section#create([])
let g:airline_section_x = airline#section#create([])
let g:airline_section_y = airline#section#create([])
let g:airline_section_z = airline#section#create([])

" Coc configuration

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gD :call CocAction('jumpDefinition', 'vsplit')<enter>
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> <leader>rn <Plug>(coc-rename)
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
nmap <Leader>a <Plug>(coc-codeaction)
nmap <silent> K :call <SID>show_documentation()<CR>
" autocmd CursorHold * silent call CocActionAsync('highlight')

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocActionAsync('doHover')
  endif
endfunction

" Use tab for trigger completion with characters ahead and navigate
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" ack.vim configuration
let g:ackprg = 'ag --vimgrep --smart-case'
nmap <Leader>f :Ack!<Space>

" Automatically rebalance splits when window is resized
au VimResized * :wincmd =

" Open accompanying test file in vertical split
" au BufRead *.ts,*.js call TestInSplit()
"
" function! TestInSplit()
"   let l:testFile = expand('%:r') . '.test.' . expand('%:e')
"   if filereadable(testFile)
"     let l:currentWindow = winnr()
"     exe "vsplit" l:testFile
"     exe "filetype" "detect"
"     exe l:currentWindow . "wincmd w"
"   endif
" endfunction
