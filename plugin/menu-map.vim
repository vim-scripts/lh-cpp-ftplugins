"===========================================================================
" File:		menu-map.vim
" Author:	Luc Hermitte <EMAIL:hermitte@free.fr>
" 		<URL:http://hermitte.free.fr/vim>
"
" Purpose:	Define functions to build mappings and menus at the same time
"
" Version:	1.2
" Last Update:  09th apr 2002
"
" Last Changes: {{{
" 	Version 1.2. :
" 		(*) Code folded.
" 		(*) Take advantage of buffermenu.vim if present for local
" 		    menus.
" 		(*) If non gui is available, the menus won't be defined
" 	Version 1.1. :
"               (*) Bug corrected : 
"                   vnore(map\|menu) does not imply v+n(map\|menu) any more
" }}}
"
" Inspired By:	A function from Benji Fisher
"
" TODO:		(*) no menu if no gui.
"
"===========================================================================
"
if exists("g:loaded_menu_map") | finish | endif
let g:loaded_menu_map = 1  

"=========================================================================
" Commands {{{
command! -nargs=+ -bang      MAP      map<bang> <args>
command! -nargs=+           IMAP     imap       <args>
command! -nargs=+           NMAP     nmap       <args>
command! -nargs=+           CMAP     cmap       <args>
command! -nargs=+           VMAP     vmap       <args>
command! -nargs=+           AMAP
      \       call <SID>Map_all('amap', <f-args>)

command! -nargs=+ -bang  NOREMAP  noremap<bang> <args>
command! -nargs=+       INOREMAP inoremap       <args>
command! -nargs=+       NNOREMAP nnoremap       <args>
command! -nargs=+       CNOREMAP cnoremap       <args>
command! -nargs=+       VNOREMAP vnoremap       <args>
command! -nargs=+       ANOREMAP
      \       call <SID>Map_all('anoremap', <f-args>)
" }}}

" s:CTRL_O {{{
" Build the command (sequence of ':ex commands') to be executed from
" INSERT-mode.
function! s:CTRL_O(cmd)
  return substitute(a:cmd, '\(^\|<CR>\):', '\1\<C-O>:', 'g')
endfunction
" }}}

" CMD_and_clear_v {{{
" execute the command and then clear the @v buffer
function! CMD_and_clear_v(cmd)
  exe a:cmd
  let @v=''
endfunction
" }}}

" s:Build_CMD {{{
" build the exact command to execute regarding the mode it is dedicated
function! s:Build_CMD(prefix, cmd)
  if a:cmd[0] != ':' | return ' ' . a:cmd
  endif
  if     a:prefix[0] == "i"  | return ' ' . <SID>CTRL_O(a:cmd)
  elseif a:prefix[0] == "n"  | return ' ' . a:cmd
  elseif a:prefix[0] == "v" 
    if match(a:cmd, ":VCall") == 0
      return substitute(a:cmd, ':VCall', ' :call', ''). "\<cr>"
    else
      return
	    \ " \"vy\<C-C>:call CMD_and_clear_v('" . 
	    \ substitute(a:cmd, "<CR>$", '', '') ."')\<cr>"
    endif
  elseif a:prefix[0] == "c"  | return " \<C-C>" . a:cmd
  else                       | return ' ' . a:cmd
  endif
endfunction
" }}}

" s:Map_all {{{
" map the command to all the modes required
function! s:Map_all(map_type,...)
  let nore   = (match(a:map_type, '[aincv]*noremap') != -1) ? "nore" : ""
  let prefix = matchstr(substitute(a:map_type, nore, '', ''), '[aincv]*')
  if a:1 == "<buffer>" | let i = 3 | let binding = a:1 . ' ' . a:2
  else                 | let i = 2 | let binding = a:1
  endif
  let cmd = a:{i}
  let i = i + 1
  while i <= a:0
    let cmd = cmd . ' ' . a:{i}
    let i = i + 1
  endwhile
  let build_cmd = nore . 'map ' . binding
  while strlen(prefix)
    if prefix[0] == "a" | let prefix = "incv"
    else
      execute prefix[0] . build_cmd . <SID>Build_CMD(prefix[0],cmd)
      let prefix = strpart(prefix, 1)
    endif
  endwhile
endfunction
" }}}

" MenuMake {{{
" Build the menu and map its associated binding to all the modes required
function! MenuMake(prefix, code, text, binding, ...)
  let nore   = (match(a:prefix, '[aincv]*nore') != -1) ? "nore" : ""
  let prefix = matchstr(substitute(a:prefix, nore, '', ''), '[aincv]*')
  let b = (a:1 == "<buffer>") ? 1 : 0
  let i = b + 1 
  let cmd = a:{i}
  let i = i + 1
  while i <= a:0
    let cmd = cmd . ' ' . a:{i}
    let i = i + 1
  endwhile
  let build_cmd = nore . "menu " . a:code . ' ' . escape(a:text, '\ ') 
  if strlen(a:binding) != 0
    let build_cmd = build_cmd . '<tab>' . escape(a:binding, '\ ')
    if b != 0
      call <SID>Map_all(prefix.nore."map", ' <buffer> '.a:binding, cmd)
    else
      call <SID>Map_all(prefix.nore."map", a:binding, cmd)
    endif
  endif
  if has("gui")
    while strlen(prefix)
      execute <SID>BMenu(b).prefix[0].build_cmd.<SID>Build_CMD(prefix[0],cmd)
      let prefix = strpart(prefix, 1)
    endwhile
  endif
endfunction
" }}}

" s:BMenu {{{
" If <buffermenu.vim> is installed and the menu should be local, then the
" apropriate string is returned.
function! s:BMenu(b)
  return (a:b && exists(':Bmenu')) ? 'B' : ''
endfunction
" }}}

" IVN_MenuMake {{{
function! IVN_MenuMake(code, text, binding, i_cmd, v_cmd, n_cmd, ...)
  " nore options
  let nore_i = (a:0 > 0) ? ((a:1 != 0) ? 'nore' : '') : ''
  let nore_v = (a:0 > 1) ? ((a:2 != 0) ? 'nore' : '') : ''
  let nore_n = (a:0 > 2) ? ((a:3 != 0) ? 'nore' : '') : ''
  " 
  call MenuMake('i'.nore_i,a:code,a:text, a:binding, '<buffer>', a:i_cmd)
  call MenuMake('v'.nore_v,a:code,a:text, a:binding, '<buffer>', a:v_cmd)
  if strlen(a:n_cmd) != 0
    call MenuMake('n'.nore_n,a:code,a:text, a:binding, '<buffer>', a:n_cmd)
  endif
endfunction
" }}}

" End !
finish

"=========================================================================
" Examples : {{{
" Call a command (':Command')
call MenuMake("nic", '50.340', '&LaTeX.Build Ta&gs', "<C-L>g",
      \ '<buffer>', ":TeXtags<CR>")
" With '{' expanding to '{}��', or '{}' regarding the mode
call IVN_MenuMake('50.360.200', '&LaTeX.&Insert.\toto{}', ']toto',
      \ '\\toto{', '{%i\\toto<ESC>%l', "viw]toto")
" Noremap for the visual maps
call IVN_MenuMake('50.360.200', '&LaTeX.&Insert.\titi{}', ']titi',
      \ '\\titi{', '<ESC>`>a}<ESC>`<i\\titi{<ESC>%l', "viw]titi", 0, 1, 0)
" Noremap for the insert and visual maps
call IVN_MenuMake('50.360.200', 'HT&ML.&Insert.<tata></tata>', ']tata',
      \ '<tata></tata><esc>?<<CR>i', 
      \ '<ESC>`>a</tata><ESC>`<i<tata><ESC>/<\\/tata>/e1<CR>', "viw]tata", 
      \ 1, 1, 0)
" }}}

"=========================================================================
" vim600: set fdm=marker:
