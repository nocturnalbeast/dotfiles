"                  _
"  ___ ___ ___ _ _|_|_____
" |   | -_| . | | | |     |
" |_|_|___|___|\_/|_|_|_|_|


" no need for backwards compatibility
set nocompatible


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
Plug 'scrooloose/nerdcommenter'
Plug 'tpope/vim-surround'
Plug 'joshdick/onedark.vim'
Plug 'ryanoasis/vim-devicons'
Plug 'junegunn/fzf'
Plug 'airblade/vim-gitgutter'
Plug 'godlygeek/tabular'

call plug#end()


" theme settings
if (has("nvim"))
    let $NVIM_TUI_ENABLE_TRUE_COLOR = 1
endif
if (has("termguicolors"))
    set termguicolors
endif

syntax enable
colorscheme onedark
let g:lightline = {
    \  'colorscheme': 'onedark',
    \  'separator': { 'left': '', 'right': '' },
    \  'subseparator': { 'left': '', 'right': '' }
    \ }


" limelight specific settings
autocmd! User GoyoEnter Limelight
autocmd! User GoyoLeave Limelight!

let g:limelight_conceal_guifg = 'Gray'
let g:limelight_priority = -1


" lightline specific settings
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

let g:lightline#ale#indicator_checking = "\uf110"
let g:lightline#ale#indicator_warnings = "\uf071"
let g:lightline#ale#indicator_errors = "\uf05e"
let g:lightline#ale#indicator_ok = "\uf00c"


" nerd-commenter specific settings
let g:NERDSpaceDelims = 1
let g:NERDCommentEmptyLines = 1


" remove the background from the colorscheme for transparent terminals
highlight Normal ctermbg=none
highlight NonText ctermbg=none
highlight Normal guibg=none
highlight NonText guibg=none
