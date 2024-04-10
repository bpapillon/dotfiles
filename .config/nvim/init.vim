set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath

lua require('plugins')
lua require('mappings')
lua require('coc')

" Colors
syntax enable " syntax highlighting
colorscheme badwolf

" File types
filetype plugin indent on

" Editing & indentation
set autoindent
set backspace=indent,eol,start " backspace key works in edit mode
set tabstop=2
set softtabstop=0
set shiftwidth=2
set smarttab
set expandtab " fill tabs with spaces

" UI
set laststatus=2
set lazyredraw " redraw only when we need to
set nofoldenable " no folds
set number " line numbers
set relativenumber " relative line numbers
set ruler " show cursor position
set scrolloff=10 " show 10 lines above and below cursor location
set showmatch " highlight matching brackets and parens
set visualbell " use visual bell instead of audio
set wildmenu " visual autocomplete for command menu

" Clipboard
set clipboard=unnamed
set pastetoggle=<Leader>p

" Search
set hlsearch " highlight search results
set ignorecase " case insensitive search
set incsearch " incremental search
set smartcase " unless capital letters
nnoremap <Leader><space> :nohlsearch<CR>

" Instead of backing up files, just reload the buffer when it changes.
set autoread                         " Auto-reload buffers when file changed on disk
set nobackup                         " Don't use backup files
set nowritebackup                    " Don't backup the file while editing
set noswapfile                       " Don't create swapfiles for new buffers
set updatecount=0                    " Don't try to write swapfiles after some number of updates
set backupskip=/tmp/*,/private/tmp/* " Let me edit crontab files

" Automatic commands
if has('autocmd')
  " Delete trailing whitespace
  autocmd BufWritePre * :%s/\s\+$//ge

  " Enable automatic formatting with Prettier on file save
  autocmd BufWritePre *.js,*.jsx,*.ts,*.tsx,*.json,*.html,*.css,*.scss,*.md :Prettier
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
let g:coc_global_extensions = ['coc-tsserver', 'coc-go']

" Switch buffers with left and right arrow keys
nnoremap <left> :bp<cr>
nnoremap <right> :bn<cr>

" Open or copy GitHub URL for current file and line
function GitHub(cmd)
  let l:filename = @%
  let l:lineno = "\\#L" . line('.')
  execute "!source ~/.bashrc && " . a:cmd . " " . l:filename . l:lineno
endfunction
command GitHubCopy call GitHub("ghc")
command GitHubOpen call GitHub("gho")
map <C-g> :GitHubOpen<CR>

" nvim-test mappings
nnoremap <Leader>t :TestFile<CR>
nnoremap <Leader>n :TestNearest<CR>

" Markdown syntax highlighting
let g:markdown_fenced_languages = ['html', 'go=go', 'javascript', 'js=javascript', 'python', 'sql', 'ts=typescript', 'typescript', 'vim', 'yaml']

" ChatVim
" Start a new empty chat file with `:Chat`
" Start a named chat file with `:Chat name`
function! Chat(suffix)
  let file_suffix = ''
  let date_suffix = strftime('%Y%m%d')

  if empty(a:suffix)
    let file_suffix = date_suffix . '_' . strftime('%H%M%S')
  else
    let file_suffix = date_suffix . '_' . a:suffix
  endif

  execute 'vsplit ~/projects/chat/' . file_suffix . '.md'
endfunction

command! -nargs=? Chat call Chat('<args>')

" SQL format
autocmd FileType sql call SqlFormatter()
augroup end
function SqlFormatter()
    set noai
    " set mappings...
    map ,f  :%!sqlformat --reindent --keywords upper --identifiers lower -<CR>
endfunction

" Go

" format imports on save
autocmd BufWritePre *.go :silent call CocAction('runCommand', 'editor.action.organizeImport')
autocmd BufWritePre *.go :silent call CocAction('runCommand', 'editor.action.format')
