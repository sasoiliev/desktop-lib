''
  syntax enable
  set background=dark
  let g:solarized_termcolors=256
  colorscheme solarized
  let g:airline_theme='solarized'
  let g:airline_solarized_bg='dark'
  set undodir=~/.vim/tmp/undo//
  set encoding=utf-8
  set modelines=0
  set noswapfile
  set tabstop=2
  set shiftwidth=2
  set softtabstop=2
  set expandtab
  set wrap
  set textwidth=80
  set formatoptions=qrn1
  if version >= 703
    set colorcolumn=+1
  endif
  filetype plugin indent on
  set autoindent
  set noshowmode
  set showcmd
  set hidden
  set visualbell
  set ttyfast
  set ruler
  set backspace=indent,eol,start
  set laststatus=2
  set history=1000
  set list
  set matchtime=3
  set mouse=a
  if version >= 703
    set colorcolumn=+1
    set norelativenumber
    set undofile
    set undoreload=10000
  endif
  set synmaxcol=800
  set notimeout
  set ttimeout
  set ttimeoutlen=10
  set backupskip=/tmp/*,/private/tmp/*
  set complete=.,w,b,u,t
  set completeopt=longest,menuone,preview
  set number
  set listchars=tab:▸\ ,eol:¬,extends:❯,precedes:❮
  set showbreak=↲
  function! ToggleFormatting()
      let l:formatting = &showbreak
      if &showbreak != ""
          set nonumber
          set listchars=
          set showbreak=
          set textwidth=0
      else
          set number
          set listchars=tab:▸\ ,eol:¬,extends:❯,precedes:❮
          set showbreak=↲
          set textwidth=80
      endif
  endfunction
  nnoremap <c-f> :call ToggleFormatting()<cr>
  augroup line_return
      au!
      au BufReadPost *
          \ if line("'\"") > 0 && line("'\"") <= line("$") |
          \     execute 'normal! g`"zvzz' |
          \ endif
  augroup END
  if has('xterm_clipboard') || has('win32')
    set clipboard=unnamedplus
  endif

  " tab-controls
  map t :tabnew<cr>
  map <c-m> :tabnext<cr>
  map <c-n> :tabprevious<cr>

  " Keep the cursor in place while joining lines
  nnoremap J mzJ`z

  " Navigate wrapped lines with j/k
  nnoremap j gj
  nnoremap k gk

  " Split line (sister to [J]oin lines)
  " The normal use of S is covered by cc, so don't worry about shadowing it.
  nnoremap S i<cr><esc>^mwgk:silent! s/\v +$//<cr>:noh<cr>`w

  " Disable auto-indentation while pasting
  let &t_SI .= "\<Esc>[?2004h"
  let &t_EI .= "\<Esc>[?2004l"
  inoremap <special> <expr> <Esc>[200~ XTermPasteBegin()
  function! XTermPasteBegin()
    set pastetoggle=<Esc>[201~
    set paste
    return ""
  endfunction
''

