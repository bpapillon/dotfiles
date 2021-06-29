" plugins (vundle)
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
  Plugin 'VundleVim/Vundle.vim'

  Plugin 'Xuyuanp/nerdtree-git-plugin'
  Plugin 'ctrlpvim/ctrlp.vim'
  Plugin 'preservim/nerdtree'
  Plugin 'tpope/vim-commentary'
  Plugin 'tpope/vim-fugitive'
  Plugin 'tpope/vim-surround'
  Plugin 'vim-airline/vim-airline'
  Plugin 'vim-airline/vim-airline-themes'
  Plugin 'w0rp/ale'

  " Language support
  Plugin 'chrisbra/csv.vim'
  Plugin 'fatih/vim-go'
  Plugin 'leafgarland/typescript-vim'
  Plugin 'lifepillar/pgsql.vim'
  Plugin 'mxw/vim-jsx'
  Plugin 'pangloss/vim-javascript'
  Plugin 'thoughtbot/vim-rspec'
  Plugin 'tpope/vim-markdown'
  Plugin 'vim-ruby/vim-ruby'
  Plugin 'iloginow/vim-stylus'
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

" RSpec.vim mappings
let g:rspec_command = "!bundle exec rspec {spec}"
map <Leader>t :call RunCurrentSpecFile()<CR>
map <Leader>s :call RunNearestSpec()<CR>
map <Leader>l :call RunLastSpec()<CR>
map <Leader>a :call RunAllSpecs()<CR>

" NERDTree auto-start and keystroke mappings
autocmd VimEnter * NERDTree | wincmd p
nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>

