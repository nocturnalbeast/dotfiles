"                  _
"  ___ ___ ___ _ _|_|_____
" |   | -_| . | | | |     |
" |_|_|___|___|\_/|_|_|_|_|


" no need for backwards compatibility
set nocompatible

" set leader key to space
let mapleader = " "

" remove status line
set noshowmode
set noruler
set laststatus=0
set noshowcmd
set shortmess+=F

" no jumping to the opening brace
set noshowmatch

" case-aware searching but defaults to insensitive
set ignorecase
set smartcase

" mouse support - go ahead, hate me.
set mouse=a

" highlight searches
set hlsearch

" indentation settings
set tabstop=4
set softtabstop=4
set expandtab
set shiftwidth=4
set autoindent

" relative numbering ftw
set number relativenumber

" command menu matching 
set wildmode=longest,list

" apply filetype-specific settings, i guess
filetype plugin on

" disable GUI tabline
set guioptions-=e

" if using a GUI, this is the font to use
set guifont=monospace:h11

" install script for vim-plug if not installed
if empty(glob('~/.local/share/nvim/site/autoload/plug.vim'))
  silent !curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source ~/.config/nvim/init.vim
endif

" plugin list
call plug#begin('~/.local/share/nvim/plugged')

Plug 'tpope/vim-sensible'
Plug 'dense-analysis/ale'
Plug 'junegunn/goyo.vim'
Plug 'junegunn/limelight.vim'
Plug 'itchyny/lightline.vim'
Plug 'maximbaz/lightline-ale'
Plug 'mhinz/vim-startify'
Plug 'sheerun/vim-polyglot'
Plug 'preservim/nerdcommenter'
Plug 'tpope/vim-surround'
Plug 'joshdick/onedark.vim'
Plug 'ryanoasis/vim-devicons'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'airblade/vim-gitgutter'
Plug 'godlygeek/tabular'
Plug 'baskerville/vim-sxhkdrc'
Plug 'davidhalter/jedi-vim'

if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
  Plug 'deoplete-plugins/deoplete-jedi'
endif
let g:deoplete#enable_at_startup = 1

call plug#end()


" theme settings
if (has("nvim"))
    let $NVIM_TUI_ENABLE_TRUE_COLOR = 1
endif
if (has("termguicolors"))
    set termguicolors
endif

syntax enable
let g:onedark_color_overrides = {
    \  'black': { 'gui': '#202020', 'cterm': '234', 'cterm16': '0' },
    \  'red': { 'gui': '#FF8080', 'cterm': '210', 'cterm16': '9' },
    \  'dark_red': { 'gui': '#FF3333', 'cterm': '203', 'cterm16': '1' },
    \  'green': { 'gui': '#80FF8A', 'cterm': '120', 'cterm16': '10' },
    \  'yellow': { 'gui': '#EAFF80', 'cterm': '192', 'cterm16': '11' },
    \  'dark_yellow': { 'gui': '#DDFF33', 'cterm': '191', 'cterm16': '3' },
    \  'blue': { 'gui': '#8080FF', 'cterm': '105', 'cterm16': '12' },
    \  'purple': { 'gui': '#BF80FF', 'cterm': '141', 'cterm16': '13' },
    \  'cyan': { 'gui': '#80FFFF', 'cterm': '123', 'cterm16': '14' },
    \  'white': { 'gui': '#EAEAEA', 'cterm': '255', 'cterm16': '15' },
    \  'visual_black': { 'gui': '#202020', 'cterm': '234', 'cterm16': '0' },
    \  'comment_grey': { 'gui': '#636363', 'cterm': '241', 'cterm16': '15' },
    \  'gutter_fg_grey': { 'gui': '#525252', 'cterm': '239', 'cterm16': '15' },
    \  'cursor_grey': { 'gui': '#323232', 'cterm': '236', 'cterm16': '8' },
    \  'visual_grey': { 'gui': '#414141', 'cterm': '238', 'cterm16': '15' },
    \  'menu_grey': { 'gui': '#414141', 'cterm': '238', 'cterm16': '8' },
    \  'special_grey': { 'gui': '#414141', 'cterm': '238', 'cterm16': '15' },
    \  'vertsplit': { 'gui': '#202020', 'cterm': '234', 'cterm16': '15' }
    \ }
colorscheme onedark


" limelight specific settings
autocmd! User GoyoEnter Limelight
autocmd! User GoyoLeave Limelight!

let g:limelight_conceal_guifg = 'Gray'
let g:limelight_priority = -1


" lightline specific settings
let g:lightline = {
    \  'colorscheme': 'onedark',
    \  'separator': { 'left': '', 'right': '' },
    \  'subseparator': { 'left': '', 'right': '' },
    \  'tabline_separator': { 'left': '', 'right': '' },
    \  'tabline_subseparator': { 'left': '', 'right': '' }
    \ }

let g:lightline.enable = {
    \  'statusline': 1,
    \  'tabline': 1
    \ }

let g:lightline.component_expand = {
    \  'linter_checking': 'lightline#ale#checking',
    \  'linter_warnings': 'lightline#ale#warnings',
    \  'linter_errors': 'lightline#ale#errors',
    \  'linter_ok': 'lightline#ale#ok'
    \ }

let g:lightline.component_type = {
    \  'linter_checking': 'left',
    \  'linter_warnings': 'warning',
    \  'linter_errors': 'error',
    \  'linter_ok': 'left'
    \ }

let g:lightline.active = {
    \  'right': [
    \   [ 'lineinfo' ],
    \   [ 'fileformat', 'fileencoding' ],
    \   [ 'linter_checking', 'linter_errors', 'linter_warnings', 'linter_ok' ]
    \  ]
    \ }

let g:lightline.tab = {
    \'active': [ 'filename', 'modified' ],
    \'inactive': [ 'tabnum', 'filename', 'modified' ]
    \ }

let g:lightline.tabline = {
    \  'left': [ ['tabs'] ],
    \  'right': [ ['close'] ],
    \ }

let g:lightline#ale#indicator_checking = "\uf110"
let g:lightline#ale#indicator_warnings = "\uf071"
let g:lightline#ale#indicator_errors = "\uf05e"
let g:lightline#ale#indicator_ok = "\uf00c"


" nerd-commenter specific settings
let g:NERDSpaceDelims = 1
let g:NERDCommentEmptyLines = 1

" fzf specific settings
if exists('$TMUX')
  let g:fzf_layout = { 'tmux': '-p90%,60%' }
else
  let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6 } }
endif

let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'],
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
  \ 'header':  ['fg', 'Comment'] }

let g:fzf_history_dir = '~/.cache/fzf-history'

" Mapping selecting mappings
nmap <leader><tab> <plug>(fzf-maps-n)
xmap <leader><tab> <plug>(fzf-maps-x)
omap <leader><tab> <plug>(fzf-maps-o)

nmap <c-p> <plug>(fzf-files)
xmap <c-p> <plug>(fzf-files)
omap <c-p> <plug>(fzf-files)

" Insert mode completion
imap <c-x><c-k> <plug>(fzf-complete-word)
imap <c-x><c-f> <plug>(fzf-complete-path)
imap <c-x><c-l> <plug>(fzf-complete-line)

" remove the background from the colorscheme for transparent terminals
highlight Normal ctermbg=none
highlight NonText ctermbg=none
highlight Normal guibg=none
highlight NonText guibg=none
