set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath

lua require('plugins')
lua require('mappings')

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
set nofoldenable " no folds
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
nnoremap <C-f> :NERDTreeFind<CR>

" Exit Vim if NERDTree is the only window left
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() |
    \ quit | endif

let NERDTreeShowHidden=1

" Airline settings
let g:airline#extensions#ale#enabled = 1
let g:airline#extensions#tabline#enabled = 1

" CoC extensions
let g:coc_global_extensions = ['coc-tsserver']

" switch buffers with left and right arrow keys
nnoremap <left> :bp<cr>
nnoremap <right> :bn<cr>

" quickly open or copy gitlab URL for current file and line
function Gitlab(cmd)
  let l:filename = @%
  let l:lineno = "\\#L" . line('.')
  execute "!source ~/.bashrc && " . a:cmd . " " . l:filename . l:lineno
endfunction
command GitlabCopy call Gitlab("glc")
command GitlabOpen call Gitlab("glo")
map <C-g> :GitlabOpen<CR>

" nvim-test mappings
nnoremap <Leader>t :TestFile<CR>
nnoremap <Leader>n :TestNearest<CR>
