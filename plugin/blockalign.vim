if exists('g:loaded_blockalign_nvim') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo
set cpo&vim

vmap <silent> <Leader>a= :call <SID>align_with("=", true)<CR>
vmap <silent> <Leader>a: :call <SID>align_with(":", true)<CR>
vmap <silent> <Leader>a, :call <SID>align_with(",", true)<CR>
vmap <silent> <Leader>A= :call <SID>align_with("=", false)<CR>
vmap <silent> <Leader>A: :call <SID>align_with(":", false)<CR>
vmap <silent> <Leader>A, :call <SID>align_with(",", false)<CR>

command -range -nargs=1 BlockAlign call <SID>align_with("<args>")

function s:align_with(sep) range
  call v:lua.require'blockalign'.align_with(a:sep)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_blockalign_nvim = 1
