" vimrc -- Vim with Neovim-style defaults and a light/dark Oceanic Next colorscheme
" Requires Vim 9.1+. Sections: 1 General & UI, 2 Indentation, 3 Search & files,
" 4 Keybindings, 5 Colorscheme.

" ==============================================================================
" 1. GENERAL & UI SETTINGS
" ==============================================================================
set nocompatible              " Disable legacy Vi compatibility mode
set encoding=utf-8            " Neovim default; needed for the Unicode chars below
scriptencoding utf-8
filetype plugin indent on     " Enable filetype detection, plugins, and custom indents
syntax on                     " Enable syntax highlighting

" ------------------------------------------------------------------------------
" Neovim defaults (see :help vim-differences in Neovim)
" ------------------------------------------------------------------------------
set backspace=indent,eol,start " Backspace over everything in insert mode
set belloff=all               " No beeps or flashes
set complete-=i               " Don't scan included files for completion (slow)
set display=lastline          " Show as much of a long last line as fits
set fillchars=vert:│,fold:·   " Solid vertical split separator
set formatoptions=tcqj        " 'j' removes comment leaders when joining lines
set history=10000             " Much longer command/search history
set nojoinspaces              " One space after '.' when joining lines
set nolangremap               " Don't let 'langmap' break mappings
set laststatus=2              " Always show the status line
set listchars=tab:>\ ,trail:-,nbsp:+ " Used when :set list is on
set mouse=nvi                 " Mouse in normal, visual and insert mode
set mousemodel=popup_setpos   " Right-click opens a menu at the cursor
set nrformats=bin,hex         " Ctrl-A/Ctrl-X don't treat 007 as octal
set ruler                     " Cursor position in the status line
set sessionoptions-=options   " Don't save options in sessions...
set viewoptions-=options      " ...or views
set shortmess+=CF             " Fewer 'hit-enter' messages
set shortmess-=S              " Show search match count, e.g. [3/12]
set showcmd                   " Show partial commands in the bottom right
set sidescroll=1              " Scroll sideways one column at a time
set smarttab                  " <Tab> at line start uses 'shiftwidth'
set nostartofline             " Keep cursor column on gg, G, Ctrl-D, etc.
set switchbuf=uselast         " Quickfix jumps reuse the last window
set tabpagemax=50             " Allow up to 50 tabs with -p
set tags=./tags;,tags         " Search for tags files upward from the file
set ttimeout ttimeoutlen=50   " Fast <Esc> without breaking key codes
set wildoptions=pum,tagfile   " Show command-line completion as a popup menu
set viminfo+=!                " Remember global variables between sessions

" Cursor shape: bar in insert, underline in replace, block otherwise (like Neovim)
let &t_SI = "\e[6 q"
let &t_SR = "\e[4 q"
let &t_EI = "\e[2 q"

" Built-in plugins Neovim enables by default
packadd! matchit              " % jumps between if/else/endif, HTML tags, etc.
packadd! comment              " gc{motion} / gcc to toggle comments
packadd! editorconfig         " Respect .editorconfig files
runtime ftplugin/man.vim      " :Man command, and K opens man pages in vim

set number                    " Show standard line numbers
set numberwidth=3             " Minimal 3-character width for line numbers
set signcolumn=no             " Completely remove the grey left gutter/sign column
set cursorline                " Needed for cursorlineopt below
set cursorlineopt=number      " Highlight only the current line number, no bar across the text
set scrolloff=8               " Keep 8 lines visible above/below cursor when scrolling
set sidescrolloff=8           " Keep 8 columns visible left/right when scrolling
set nowrap                    " Don't wrap long lines automatically
set termguicolors             " Enable 24-bit True Color support

" Wildmenu: Built-in tab autocompletion menu for commands and files
set wildmenu
set wildmode=longest:full,full
set wildignore=*.o,*.obj,*~,*.pyc,*.git,*.hg,*.svn,*/node_modules/*

" ==============================================================================
" 2. INDENTATION & TABS (Modern Defaults)
" ==============================================================================
set expandtab                 " Use spaces instead of tabs
set tabstop=2                 " 1 tab = 2 spaces
set shiftwidth=2              " Indent level = 2 spaces
set softtabstop=2             " Backspace removes 2 spaces
set autoindent                " Copy indent from current line when starting a new line
set smartindent               " Insert extra indent in C-style blocks/braces

" ==============================================================================
" 3. SEARCH & FILE HANDLING
" ==============================================================================
set ignorecase                " Case-insensitive searching...
set smartcase                 " ...unless search term contains uppercase letters
set incsearch                 " Highlight search matches as you type
set hlsearch                  " Keep search matches highlighted
set hidden                    " Allow switching buffers without saving first
set autoread                  " Reload file if changed externally

" Clean backup/undo directories (prevents cluttering working folders with .swp)
set nobackup
set nowritebackup
set noswapfile
if has('persistent_undo')
  set undofile                " Maintain undo history across Vim restarts
  set undodir=~/.vim/undo//
  " Unlike Neovim, Vim doesn't create the undo folder itself
  if !isdirectory(expand('~/.vim/undo'))
    call mkdir(expand('~/.vim/undo'), 'p', 0700)
  endif
endif

" ==============================================================================
" 4. KEYBINDINGS & EFFICIENCY
" ==============================================================================
" Set Spacebar as the Leader key
let mapleader = " "

" Fast saving and quitting
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>

" Clear search highlights with Space + Esc
nnoremap <leader><Esc> :noh<CR>

" Window navigation shortcuts (Ctrl + h/j/k/l)
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Keep selection active when indenting in Visual Mode
vnoremap < <gv
vnoremap > >gv

" Move visual lines (handles long wrapped lines naturally)
nnoremap j gj
nnoremap k gk

" --- Neovim default mappings ---
" Neovim's Ctrl-L (clear search highlight) is omitted: Ctrl-L is window navigation
" here, and <leader><Esc> clears highlighting instead.
nnoremap Y y$
nnoremap & :&&<CR>
nnoremap Q @@
" Make Ctrl-U / Ctrl-W in insert mode undoable as a separate step
inoremap <C-U> <C-G>u<C-U>
inoremap <C-W> <C-G>u<C-W>
" * and # in visual mode search for the selected text
xnoremap * y/\V<C-R>=escape(@", '/\')<CR><CR>
xnoremap # y?\V<C-R>=escape(@", '?\')<CR><CR>
" Bracket navigation: quickfix, location list, buffers, args (count works, e.g. 3]q)
nnoremap <silent> [q :<C-U>execute v:count1 . 'cprevious'<CR>
nnoremap <silent> ]q :<C-U>execute v:count1 . 'cnext'<CR>
nnoremap <silent> [l :<C-U>execute v:count1 . 'lprevious'<CR>
nnoremap <silent> ]l :<C-U>execute v:count1 . 'lnext'<CR>
nnoremap <silent> [b :<C-U>execute v:count1 . 'bprevious'<CR>
nnoremap <silent> ]b :<C-U>execute v:count1 . 'bnext'<CR>
nnoremap <silent> [a :<C-U>execute v:count1 . 'previous'<CR>
nnoremap <silent> ]a :<C-U>execute v:count1 . 'next'<CR>

" ==============================================================================
" 5. COLORSCHEME (Oceanic Next palette, follows macOS light/dark mode)
" ==============================================================================
" Palette from Oceanic Next by Dmitri Voronianski
" (https://github.com/voronianski/oceanic-next-color-scheme).
" Dark is the original Oceanic Next palette. Light flips the grays and uses
" deeper accent colors: every accent is at least 4.5:1 contrast on the light
" background (the WCAG readability standard for body text).
"   sel       = visual selection    border    = split lines, ~ and hidden chars
"   search    = search match bg     on_search = text drawn on search/diff highlights
let s:palettes = {
      \ 'dark': {
      \   'bg': '#1B2B34', 'bg_alt': '#343D46', 'sel': '#4F5B66', 'border': '#4F5B66',
      \   'comment': '#65737E', 'fg_dim': '#A7ADBA', 'fg': '#C0C5CE', 'strong': '#D8DEE9',
      \   'red': '#EC5F67', 'orange': '#F99157', 'yellow': '#FAC863', 'green': '#99C794',
      \   'cyan': '#5FB3B3', 'blue': '#6699CC', 'purple': '#C594C5', 'brown': '#AB7967',
      \   'search': '#FAC863', 'cursearch': '#F99157', 'on_search': '#1B2B34' },
      \ 'light': {
      \   'bg': '#EEF1F5', 'bg_alt': '#D8DEE7', 'sel': '#C9D7E8', 'border': '#A9B3BF',
      \   'comment': '#5E6B76', 'fg_dim': '#4F5B66', 'fg': '#2E3A44', 'strong': '#1B2B34',
      \   'red': '#BF3740', 'orange': '#AE4F17', 'yellow': '#856400', 'green': '#3B7536',
      \   'cyan': '#1C7070', 'blue': '#2F62A0', 'purple': '#8A4B8A', 'brown': '#7D5040',
      \   'search': '#F7D987', 'cursearch': '#F4AE80', 'on_search': '#1B2B34' },
      \ }

" s:Hi(group, fg, bg, attr) -- '' leaves fg/bg unset, attr defaults to NONE
function! s:Hi(group, fg, bg, ...) abort
  let l:attr = a:0 ? a:1 : 'NONE'
  execute 'highlight' a:group
        \ 'guifg=' . (empty(a:fg) ? 'NONE' : a:fg)
        \ 'guibg=' . (empty(a:bg) ? 'NONE' : a:bg)
        \ 'gui=' . l:attr 'cterm=' . l:attr
endfunction

" Apply the palette that matches the current 'background'
function! s:ApplyColors() abort
  let p = s:palettes[&background ==# 'light' ? 'light' : 'dark']
  highlight clear
  if exists('syntax_on') | syntax reset | endif

  " Editor UI
  call s:Hi('Normal',       p.fg,      p.bg)
  call s:Hi('LineNr',       p.comment, p.bg)
  call s:Hi('CursorLineNr', p.yellow,  p.bg, 'bold')
  call s:Hi('CursorLine',   '',        p.bg_alt)
  call s:Hi('ColorColumn',  '',        p.bg_alt)
  call s:Hi('SignColumn',   p.comment, p.bg)
  call s:Hi('VertSplit',    p.border,  p.bg)
  call s:Hi('StatusLine',   p.strong,  p.bg_alt)
  call s:Hi('StatusLineNC', p.comment, p.bg_alt)
  call s:Hi('TabLine',      p.comment, p.bg_alt)
  call s:Hi('TabLineFill',  '',        p.bg_alt)
  call s:Hi('TabLineSel',   p.strong,  p.bg, 'bold')
  call s:Hi('Pmenu',        p.fg,      p.bg_alt)
  call s:Hi('PmenuSel',     p.bg,      p.blue)
  call s:Hi('PmenuSbar',    '',        p.sel)
  call s:Hi('PmenuThumb',   '',        p.fg_dim)
  call s:Hi('WildMenu',     p.bg,      p.blue)
  call s:Hi('Visual',       '',        p.sel)
  call s:Hi('Search',       p.on_search, p.search)
  call s:Hi('IncSearch',    p.on_search, p.cursearch)
  call s:Hi('CurSearch',    p.on_search, p.cursearch)
  call s:Hi('MatchParen',   p.strong,  p.sel, 'bold')
  call s:Hi('Folded',       p.comment, p.bg_alt)
  call s:Hi('FoldColumn',   p.comment, p.bg)
  call s:Hi('NonText',      p.border,  '')
  call s:Hi('EndOfBuffer',  p.border,  '')
  call s:Hi('SpecialKey',   p.border,  '')
  call s:Hi('Directory',    p.blue,    '')
  call s:Hi('Title',        p.blue,    '', 'bold')
  call s:Hi('ErrorMsg',     p.red,     '')
  call s:Hi('WarningMsg',   p.orange,  '')
  call s:Hi('MoreMsg',      p.green,   '')
  call s:Hi('ModeMsg',      p.green,   '')
  call s:Hi('Question',     p.blue,    '')
  call s:Hi('QuickFixLine', '',        p.bg_alt)
  call s:Hi('DiffAdd',      p.green,   p.bg_alt)
  call s:Hi('DiffChange',   p.yellow,  p.bg_alt)
  call s:Hi('DiffDelete',   p.red,     p.bg_alt)
  call s:Hi('DiffText',     p.on_search, p.search)
  call s:Hi('SpellBad',     p.red,     '', 'undercurl')
  call s:Hi('SpellCap',     p.blue,    '', 'undercurl')
  call s:Hi('SpellRare',    p.purple,  '', 'undercurl')
  call s:Hi('SpellLocal',   p.cyan,    '', 'undercurl')

  " Syntax
  call s:Hi('Comment',      p.comment, '', 'italic')
  call s:Hi('Constant',     p.orange,  '')
  call s:Hi('String',       p.green,   '')
  call s:Hi('Character',    p.green,   '')
  call s:Hi('Number',       p.orange,  '')
  call s:Hi('Boolean',      p.orange,  '')
  call s:Hi('Float',        p.orange,  '')
  call s:Hi('Identifier',   p.red,     '')
  call s:Hi('Function',     p.blue,    '')
  call s:Hi('Statement',    p.purple,  '')
  call s:Hi('Conditional',  p.purple,  '')
  call s:Hi('Repeat',       p.purple,  '')
  call s:Hi('Label',        p.yellow,  '')
  call s:Hi('Operator',     p.cyan,    '')
  call s:Hi('Keyword',      p.purple,  '')
  call s:Hi('Exception',    p.red,     '')
  call s:Hi('PreProc',      p.yellow,  '')
  call s:Hi('Include',      p.blue,    '')
  call s:Hi('Define',       p.purple,  '')
  call s:Hi('Macro',        p.red,     '')
  call s:Hi('Type',         p.yellow,  '')
  call s:Hi('StorageClass', p.yellow,  '')
  call s:Hi('Structure',    p.purple,  '')
  call s:Hi('Typedef',      p.yellow,  '')
  call s:Hi('Special',      p.cyan,    '')
  call s:Hi('SpecialChar',  p.brown,   '')
  call s:Hi('Tag',          p.yellow,  '')
  call s:Hi('Delimiter',    p.brown,   '')
  call s:Hi('Underlined',   p.blue,    '', 'underline')
  call s:Hi('Error',        p.red,     p.bg, 'bold')
  call s:Hi('Todo',         p.yellow,  p.bg_alt, 'bold')
endfunction

" --- Follow the macOS appearance setting ---
" `defaults read -g AppleInterfaceStyle` prints "Dark" in dark mode and fails in light mode.
let s:appearance_cmd = 'defaults read -g AppleInterfaceStyle 2>/dev/null || echo Light'

function! s:SetBackground(mode) abort
  if a:mode !=# &background
    let &background = a:mode
    call s:ApplyColors()
    redraw!
  endif
endfunction

function! s:OnAppearance(channel, msg) abort
  call s:SetBackground(a:msg =~? 'dark' ? 'dark' : 'light')
endfunction

" Ask macOS in the background so vim never pauses while checking
function! s:CheckAppearance(...) abort
  call job_start(['sh', '-c', s:appearance_cmd], {'out_cb': function('s:OnAppearance')})
endfunction

if has('mac') && executable('defaults')
  " Check once at startup (synchronously, so the first screen has the right colors)
  let &background = system(s:appearance_cmd) =~? 'dark' ? 'dark' : 'light'
  if has('job') && has('timers')
    call timer_start(3000, function('s:CheckAppearance'), {'repeat': -1})  " every 3s
    augroup follow_os_appearance
      autocmd!
      autocmd FocusGained * call s:CheckAppearance()  " and when switching back to vim
    augroup END
  endif
else
  set background=dark
endif
call s:ApplyColors()
