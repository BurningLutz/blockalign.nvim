if exists('g:loaded_blockalign_nvim') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo
set cpo&vim

vmap <silent> <Leader>a= lua require("blockalign").align_with("=")
vmap <silent> <Leader>a: lua require("blockalign").align_with(":")

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_blockalign_nvim = 1
