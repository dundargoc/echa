" Leader key
let mapleader = "\<Space>"

" Map leader to which_key
nnoremap <silent> <Leader> :silent <c-u> :silent WhichKey '<Space>'<CR>
vnoremap <silent> <Leader> :silent <c-u> :silent WhichKeyVisual '<Space>'<CR>

" Create map to add keys to
let g:which_key_map =  {}

" Single letter mappings
"" Generate documentation using 'vim-doge'
nnoremap <silent> <Leader>d :DogeGenerate<CR>
let g:which_key_map['d'] = 'document'

"" Execute in jupyter current line and go down by one line
nmap <silent> <Leader>j  <Plug>(IPy-Run)j
"" Execute in jupyter selection and go down by one line after the end of
"" selection
vmap <silent> <Leader>j  <Plug>(IPy-Run)'>j
let g:which_key_map['j'] = 'jupyter run'

" Send text to neoterm buffer
nnoremap <Leader>s :TREPLSendLine<cr>j
vnoremap <Leader>s :TREPLSendSelection<cr>'>j
let g:which_key_map['s'] = 'send to terminal'

"" Toggle custom wrap settings
nnoremap <silent> <Leader>w :call ToggleWrap()<CR>
let g:which_key_map['w'] = 'wrap toggle'

"" Strip whitespace
let g:which_key_map['W'] = ["StripWhitespace", 'whitespace strip']

" b is for 'buffer'
let g:which_key_map.b = {
  \ 'name' : '+buffer' ,
  \ 'd'  : [':Bclose'  , 'delete'],
  \ 'D'  : [':Bclose!' , 'delete!'],
  \ }

" c is for 'coc.nvim'
let g:which_key_map.c = {
  \ 'name' : '+Coc' ,
  \ '.' : [':CocConfig'                        , 'config'],
  \ ';' : ['<Plug>(coc-refactor)'              , 'refactor'],
  \ 'A' : ['<Plug>(coc-codeaction-selected)'   , 'selected action'],
  \ 'a' : ['<Plug>(coc-codeaction)'            , 'line action'],
  \ 'B' : [':CocPrev'                          , 'prev action'],
  \ 'b' : [':CocNext'                          , 'next action'],
  \ 'c' : [':CocList commands'                 , 'commands'],
  \ 'D' : ['<Plug>(coc-declaration)'           , 'declaration'],
  \ 'd' : ['<Plug>(coc-definition)'            , 'definition'],
  \ 'e' : [':CocList extensions'               , 'extensions'],
  \ 'F' : ['<Plug>(coc-format)'                , 'format'],
  \ 'f' : ['<Plug>(coc-format-selected)'       , 'format selected'],
  \ 'h' : ['<Plug>(coc-float-hide)'            , 'hide'],
  \ 'I' : [':CocList -A --normal diagnostics'  , 'diagnostics'],
  \ 'i' : ['<Plug>(coc-implementation)'        , 'implementation'],
  \ 'J' : ['<Plug>(coc-diagnostic-next-error)' , 'next error'],
  \ 'j' : ['<Plug>(coc-diagnostic-next)'       , 'next diagnostic'],
  \ 'K' : ['<Plug>(coc-diagnostic-prev-error)' , 'prev error'],
  \ 'k' : ['<Plug>(coc-diagnostic-prev)'       , 'prev diagnostic'],
  \ 'l' : ['<Plug>(coc-codelens-action)'       , 'code lens'],
  \ 'O' : [':CocList outline'                  , 'outline'],
  \ 'o' : ['<Plug>(coc-openlink)'              , 'open link'],
  \ 'q' : ['<Plug>(coc-fix-current)'           , 'quickfix action'],
  \ 'R' : ['<Plug>(coc-references)'            , 'references'],
  \ 'r' : ['<Plug>(coc-rename)'                , 'rename'],
  \ 'S' : [':CocList snippets'                 , 'snippets'],
  \ 's' : [':CocList -A --normal -I symbols'   , 'references'],
  \ 't' : ['<Plug>(coc-type-definition)'       , 'type definition'],
  \ 'U' : [':CocUpdate'                        , 'update CoC'],
  \ 'u' : [':CocListResume'                    , 'resume list'],
  \ 'Z' : [':CocEnable'                        , 'enable CoC'],
  \ 'z' : [':CocDisable'                       , 'disable CoC'],
  \ }

" e is for 'explorer'
let g:which_key_map.e = {
  \ 'name' : '+explorer' ,
  \ 't' : [':NERDTreeToggle' , 'toggle'],
  \ 'f' : [':NERDTreeFind'   , 'find file'],
  \ }

" f is for both 'fzf' and 'find'
let g:which_key_map.f = {
  \ 'name' : '+fzf' ,
  \ '/' : [':History/'         , '"/" history'],
  \ ';' : [':Commands'         , 'commands'],
  \ 'b' : [':Buffers'          , 'open buffers'],
  \ 'C' : [':BCommits'         , 'buffer commits'],
  \ 'c' : [':Commits'          , 'commits'],
  \ 'f' : [':Files'            , 'files'],
  \ 'F' : [':GFiles --others'  , 'files untracked'],
  \ 'g' : [':GFiles'           , 'git files'],
  \ 'G' : [':GFiles?'          , 'modified git files'],
  \ 'H' : [':History:'         , 'command history'],
  \ 'h' : [':History'          , 'file history'],
  \ 'L' : [':BLines'           , 'lines (current buffer)'],
  \ 'l' : [':Lines'            , 'lines (all buffers)'],
  \ 'M' : [':Maps'             , 'normal maps'],
  \ 'm' : [':Marks'            , 'marks'],
  \ 'p' : [':Helptags'         , 'help tags'],
  \ 'r' : [':Rg'               , 'text Rg'],
  \ 'S' : [':Colors'           , 'color schemes'],
  \ 's' : [':CocList snippets' , 'snippets'],
  \ 'T' : [':BTags'            , 'buffer tags'],
  \ 't' : [':Tags'             , 'project tags'],
  \ 'w' : [':Windows'          , 'search windows'],
  \ 'y' : [':Filetypes'        , 'file types'],
  \ 'z' : [':FZF'              , 'FZF'],
  \ }

" g is for git
"" Functions `GitGutterNextHunkCycle()` and `GitGutterPrevHunkCycle()` are
"" defined in 'general/functions.vim'
let g:which_key_map.g = {
  \ 'name' : '+git' ,
  \ 'A' : [':Git add %'                     , 'add buffer'],
  \ 'a' : ['<Plug>(GitGutterStageHunk)'     , 'add hunk'],
  \ 'b' : [':Git blame'                     , 'blame'],
  \ 'D' : [':Gvdiffsplit!'                  , 'diff split'],
  \ 'd' : [':Git diff'                      , 'diff'],
  \ 'f' : [':GitGutterFold'                 , 'fold unchanged'],
  \ 'g' : [':Git'                           , 'git window'],
  \ 'h' : [':diffget //2'                   , 'merge from left (our)'],
  \ 'j' : [':call GitGutterNextHunkCycle()' , 'next hunk'],
  \ 'k' : [':call GitGutterPrevHunkCycle()' , 'prev hunk'],
  \ 'l' : [':diffget //3'                   , 'merge from right (their)'],
  \ 'p' : ['<Plug>(GitGutterPreviewHunk)'   , 'preview hunk'],
  \ 'q' : [':GitGutterQuickFix | copen'     , 'quickfix hunks'],
  \ 'R' : [':Git reset %'                   , 'reset buffer'],
  \ 't' : [':GitGutterLineHighlightsToggle' , 'toggle highlight'],
  \ 'u' : ['<Plug>(GitGutterUndoHunk)'      , 'undo hunk'],
  \ 'V' : [':GV!'                           , 'view buffer commits'],
  \ 'v' : [':GV'                            , 'view commits'],
  \ }

" i is for IPython
"" Qt Console connection.
""" **To create working connection, execute both keybindings** (second after
""" console is created).
""" **Note**: Qt Console is opened with Python interpreter that is used in
""" terminal when opened NeoVim (i.e. output of `which python`). As a
""" consequence, if that Python interpreter doesn't have 'jupyter' or
""" 'qtconsole' installed, Qt Console will not be created.
""" `CreateQtConsole()` is defined in 'plug-config/nvim-ipy.vim'.
nmap <silent> <Leader>iq :call CreateQtConsole()<CR>
nmap <silent> <Leader>ik :IPython<Space>--existing<Space>--no-window<CR>

"" Execution
nmap <silent> <Leader>ic  <Plug>(IPy-RunCell)
nmap <silent> <Leader>ia  <Plug>(IPy-RunAll)

""" One can also setup a completion connection (generate a completion list
""" inside NeoVim but options taken from IPython session), but it seems to be
""" a bad practice methodologically.
"" imap <silent> <C-k> <Cmd>call IPyComplete()<cr>
""   " This one should be used only when inside Insert mode after <C-o>
"" nmap <silent> <Leader>io <Cmd>call IPyComplete()<cr>

let g:which_key_map.i = {
  \ 'name' : '+IPython',
  \ 'a' : 'run all',
  \ 'c' : 'run cell',
  \ 'k' : 'connect',
  \ 'q' : 'Qt Console',
  \ }

" q is for 'quickfix'
let g:which_key_map.q = {
  \ 'name' : '+quickfix' ,
  \ 'c' : [':cclose'    , 'close'],
  \ 'f' : [':cfirst'    , 'first'],
  \ 'j' : [':cnext'     , 'next'],
  \ 'k' : [':cprevious' , 'previous'],
  \ 'l' : [':clast'     , 'last'],
  \ 'o' : [':copen'     , 'open'],
  \ }

" r is for 'R'
"" These mappings send commands to current neoterm buffer, so some sort of R
"" interpreter should already run there
nnoremap <silent> <Leader>rc :T devtools::check()<CR>
nnoremap <silent> <Leader>rC :T devtools::test_coverage()<CR>
nnoremap <silent> <Leader>rd :T devtools::document()<CR>
nnoremap <silent> <Leader>ri :T devtools::install(keep_source=TRUE)<CR>
nnoremap <silent> <Leader>rl :T devtools::load_all()<CR>
nnoremap <silent> <Leader>rk :T rmarkdown::render("%")<CR>
" Copy to clipboard and make reprex (which itself is loaded to clipboard)
vnoremap <silent> <Leader>rr "+y :T reprex::reprex()<CR>
nnoremap <silent> <Leader>rT :T devtools::test_file("%")<CR>
nnoremap <silent> <Leader>rt :T devtools::test()<CR>

let g:which_key_map.r = {
  \ 'name' : '+R',
  \ 'c' : 'check',
  \ 'C' : 'coverage',
  \ 'd' : 'document',
  \ 'i' : 'install',
  \ 'l' : 'load all',
  \ 'k' : 'knit file',
  \ 'r' : 'reprex selection',
  \ 'T' : 'test file',
  \ 't' : 'test',
  \ }

" t is for 'terminal' (uses 'neoterm')
"" `ShowActiveNeotermREPL()` is defined in 'general/functions.vim'
nnoremap <silent> <Leader>ta :call ShowActiveNeotermREPL()<CR>
nnoremap <silent> <Leader>tc :<c-u>exec v:count."Tclose\!"<CR>
nnoremap <silent> <Leader>tf :<c-u>exec "TREPLSetTerm ".v:count<CR>
nnoremap <silent> <Leader>tl :call neoterm#list_ids()<CR>

let g:which_key_map.t = {
  \ 'name' : '+terminal' ,
  \ 'a' :                        'echo active REPL id',
  \ 'C' : [':TcloseAll!'       , 'close all terminals'],
  \ 'c' :                        'close term (prepend by id)',
  \ 'f' :                        'focus term (prepend by id)',
  \ 'l' :                        'list terminals',
  \ 's' : [':belowright Tnew'  , 'split terminal'],
  \ 'v' : [':vertical Tnew'    , 'vsplit terminal'],
  \ }

" T is for 'test'
let g:which_key_map.T = {
  \ 'name' : '+test' ,
  \ 'F' : [':TestFile -strategy=make | copen'    , 'file (quickfix)'],
  \ 'f' : [':TestFile'                           , 'file'],
  \ 'L' : [':TestLast -strategy=make | copen'    , 'last (quickfix)'],
  \ 'l' : [':TestLast'                           , 'last'],
  \ 'N' : [':TestNearest -strategy=make | copen' , 'nearest (quickfix)'],
  \ 'n' : [':TestNearest'                        , 'nearest'],
  \ 'S' : [':TestSuite -strategy=make | copen'   , 'suite (quickfix)'],
  \ 's' : [':TestSuite'                          , 'suite'],
  \ }

" Register 'which-key' mappings
call which_key#register('<Space>', "g:which_key_map")
