" neovim config


" basic stuff
set nocompatible
set showmatch
set ignorecase
set mouse=v
set hlsearch
set tabstop=4
set softtabstop=4
set expandtab
set shiftwidth=4
set autoindent
set number
set wildmode=longest,list


" install script for vim-plug if not installed
if empty(glob('~/.local/share/nvim/site/autoload/plug.vim'))
  silent !curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source ~/.config/nvim/init.vim
endif


" plugin list
call plug#begin('~/.local/share/nvim/plugged')

Plug 'tpope/vim-surround'
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'deoplete-plugins/deoplete-jedi'
" Only using Python for now, will enable these later
"Plug 'padawan-php/deoplete-padawan', { 'do': 'composer install' }
"Plug 'carlitux/deoplete-ternjs', { 'do': 'npm install -g tern' }
"Plug 'jjohnson338/deoplete-mssql'
Plug 'scrooloose/syntastic'
Plug 'scrooloose/nerdcommenter'
Plug 'sheerun/vim-polyglot'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'trapd00r/neverland-vim-theme'
Plug 'ryanoasis/vim-devicons'

call plug#end()


" color settings
colorscheme neverland
let g:airline_theme='distinguished'


" airline specific settings
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'


" nerd-commenter specific settings
let g:NERDSpaceDelims = 1
let g:NERDCommentEmptyLines = 1


" syntastic specific settings
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0


" deoplete specific settings
let g:deoplete#enable_at_startup = 1


" ctrl-p specific settings
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlPMixed'


" remove the background from the colorscheme for transparent terminals
highlight Normal ctermbg=none
highlight NonText ctermbg=none
highlight Normal guibg=none
highlight NonText guibg=none


" some useful key bindings

" moving a line up or down
noremap <A-j> :m .+1<CR>==
noremap <A-k> :m .-2<CR>==
inoremap <A-j> <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv

" quickly save the file you're working on
nnoremap <leader>s :w<cr>
inoremap <leader>s <C-c>:w<cr>

" change panes
noremap <C-l> <C-w>l
noremap <C-h> <C-w>h
noremap <C-j> <C-w>j
noremap <C-k> <C-w>k

" move to start or end of the line without moving your hand from homerow
nnoremap H ^
nnoremap L $

" switch between uppercase and lowercase
inoremap ,cu <esc>mzgUiw`za
inoremap ,cl <esc>mzguiw`za

