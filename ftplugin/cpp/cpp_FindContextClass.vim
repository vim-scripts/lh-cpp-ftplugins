" ========================================================================
" File:			cpp_FindContextClass.vim
" Author:		Luc Hermitte <MAIL:hermitte at free.fr>
" 			<URL:http://hermitte.free.fr/vim/>
"
" Last Update:		21st jul 2002
"
" Dependencies:		VIM 6.0+

" Defines:
" * Function: Cpp_SearchClassDefinition(lineNo)
"   Returns the class name of any member at line lineNo -- could be of the
"   form : "A::B::C" for embeded classes.
"
" TODO:
" * support templates -> A<T>::B, etc
" ==========================================================================
"
if exists("g:loaded_cpp_FindContextClass_vim")
  finish
endif
let g:loaded_cpp_FindContextClass_vim = 1
  "" line continuation used here ??
  let s:cpo_save = &cpo
  set cpo&vim


"
" ==========================================================================
" Checks whether lineNo is in between the '{' at line classStart and its
" '}' counterpart ; in that case, returns "::".className

" ==========================================================================
" Search for a class definition (not forwarded definition) on several lines
" {{{
function! Cpp_SearchClassDefinition(lineNo)
  let pos = a:lineNo
  exe a:lineNo
  let class = ""
  while pos != 0
    let pos = searchpair('class\s\+\<\i\+\>\%(\n\|\s\)*{', '', '};', 'bW')
    if pos != 0
      let cls_name = substitute(getline(pos),
	    \ '^.*\s*class\s\+\(\<\i\+\>\).*$', '\1', '')
      let class = class . '::' . cls_name
    endif
  endwhile
  exe a:lineNo
  return substitute (class, '^:\+', '', 'g')
endfunction
" }}}
  let &cpo = s:cpo_save
" ========================================================================
" vim60: set fdm=marker:
