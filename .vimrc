" plugins (vundle)
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
  " Yo dawg
  Plugin 'VundleVim/Vundle.vim'

  " File editing
  Plugin 'dense-analysis/ale'
  Plugin 'tpope/vim-commentary'
  Plugin 'tpope/vim-surround'
  Plugin 'vim-test/vim-test'

  " File navigation (fuzzy finder, filetree sidebar, version control)
  Plugin 'Xuyuanp/nerdtree-git-plugin'
  Plugin 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plugin 'junegunn/fzf.vim'
  Plugin 'preservim/nerdtree'
  Plugin 'tpope/vim-fugitive'

  " Language support
  Plugin 'fatih/vim-go'
  Plugin 'iloginow/vim-stylus'
  Plugin 'leafgarland/typescript-vim'
  Plugin 'lifepillar/pgsql.vim'
  Plugin 'mxw/vim-jsx'
  Plugin 'pangloss/vim-javascript'
  Plugin 'peitalin/vim-jsx-typescript'
  Plugin 'maxmellon/vim-jsx-pretty'
  Plugin 'tpope/vim-markdown'
  Plugin 'neoclide/coc.nvim', {'branch': 'release'}

  " Status line
  Plugin 'vim-airline/vim-airline'
  Plugin 'vim-airline/vim-airline-themes'
call vundle#end()

" colors
syntax enable " syntax highlighting
colorscheme badwolf

" file types
filetype plugin indent on

" editing & indentation
set autoindent
set backspace=indent,eol,start " backspace key works in edit mode
set tabstop=2
set softtabstop=0
set shiftwidth=2
set smarttab
set expandtab " fill tabs with spaces

" UI
set laststatus=2
set lazyredraw " redraw only when we need to.
set number " line numbers
set relativenumber " relative line numbers
set ruler " show cursor position
set scrolloff=10 " show 10 lines above and below cursor location
set showmatch " highlight matching brackets and parens
set visualbell " use visual bell instead of audio
set wildmenu " visual autocomplete for command menu

" clipboard
set clipboard=unnamed
set pastetoggle=<Leader>p

" search
set hlsearch " highlight search results
set ignorecase " case insensitive search
set incsearch " incremental search
set smartcase " unless capital letters
nnoremap <Leader><space> :nohlsearch<CR>

" ===== Instead of backing up files, just reload the buffer when it changes. =====
" The buffer is an in-memory representation of a file, it's what you edit
set autoread                         " Auto-reload buffers when file changed on disk
set nobackup                         " Don't use backup files
set nowritebackup                    " Don't backup the file while editing
set noswapfile                       " Don't create swapfiles for new buffers
set updatecount=0                    " Don't try to write swapfiles after some number of updates
set backupskip=/tmp/*,/private/tmp/* " Let me edit crontab files

" automatic commands
if has('autocmd')
  " delete trailing whitespace
  autocmd BufWritePre * :%s/\s\+$//ge
endif

" NERDTree auto-start and keystroke mappings
autocmd VimEnter * NERDTree | wincmd p
nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>

" fzf mapping
nnoremap <silent> <C-p> :GitFiles<CR>

" Exit Vim if NERDTree is the only window left
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() |
    \ quit | endif

" Airline settings
let g:airline#extensions#ale#enabled = 1
let g:airline#extensions#tabline#enabled = 1

" go to definition in a split
" TODO fix this
nnoremap gd :only<bar>vsplit<CR>gd

" CoC extensions
let g:coc_global_extensions = ['coc-tsserver']

" switch buffers with left and right arrow keys
nnoremap <left> :bp<cr>
nnoremap <right> :bn<cr>

" Gitlab stuff
function GitlabCopy()
  let l:filename = @%
  let l:lineno = "\\#L" . line('.')
  let l:cmd = "!source ~/.bashrc && glc " . l:filename . l:lineno
  execute l:cmd
endfunction
function GitlabOpen()
  let l:filename = @%
  let l:lineno = "\\#L" . line('.')
  let l:cmd = "!source ~/.bashrc && glo " . l:filename . l:lineno
  execute l:cmd
endfunction
command GitlabCopy call GitlabCopy()
command GitlabOpen call GitlabOpen()
map <C-g> :GitlabOpen<CR>
