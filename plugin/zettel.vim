" Filename: plugin/zettel.vim
" Author:   18alantom
" License:  MIT License


if exists("g:loaded_zettel")
  finish
endif
let g:loaded_zettel = 1

call zettel#initialize()


" Commands
command! -nargs=+ ZettelCreateNewTagFile
  \ call zettel#createNewTagFile(<f-args>)
command! -nargs=* -complete=customlist,s:GetCompletionInsertTag ZettelInsertTag
  \ call zettel#insertTag(<f-args>)
command! ZettelJumpToTag call zettel#jumpToTag()
command! ZettelInsertTagLink call zettel#insertTagLink()
command! ZettelDeleteTag call zettel#deleteTag()


" Key Bindings
if !exists("g:zettel_tags_prevent_default_bindings")
  nnoremap <unique> <leader>zc :ZettelCreateNewTagFile<space>
  nnoremap <unique> <leader>zi :ZettelInsertTag<space>
  nnoremap <unique> <leader>zj :ZettelJumpToTag<cr>
  nnoremap <unique> <leader>zl :ZettelInsertTagLink<cr>
  nnoremap <unique> <leader>zd :ZettelDeleteTag<cr>
endif


" Completion Functions
function s:GetCompletionInsertTag(arg_lead, cmd_line, cursor_pos)
  " TODO: Add suggestions with word under cursor suffixed
  " TODO: Add suggestions with '@' prefixed for line entry
  let l:tags = []
  for t in split(&tags, ",")
    if !filereadable(t)
      continue
    endif
    call add(l:tags, zettel#utils#getRelativePath(t))
  endfor
  return uniq(l:tags)
endfunction
