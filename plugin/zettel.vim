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
command! ZettelListTags call zettel#listTags()
command! ZettelInsertTagLink call zettel#insertTagLink()
command! ZettelDeleteTag call zettel#deleteTag()
command! ZettelListTagsInThisFile call zettel#listTagsInThisFile()

if !g:zettel_dont_maintain_taglink_file
  command! ZettelListTagLinks call zettel#listTagLinks()
  command! ZettelListTagLinksToATag call zettel#listTagLinksToATag()
  command! ZettelCleanTagLinkFile call zettel#cleanTagLinkFile()
endif


" Key Bindings
if !exists("g:zettel_prevent_default_bindings")
  nnoremap <unique> <leader>zi :ZettelInsertTag<space>
  nnoremap <unique> <leader>zj :ZettelListTags<cr>
  nnoremap <unique> <leader>zl :ZettelInsertTagLink<cr>
  nnoremap <unique> <leader>zd :ZettelDeleteTag<cr>
  nnoremap <silent> <C-]> :call <SID>OverloadCtrlSqBracket()<CR>
endif


" Internal Functions
function s:GetCompletionInsertTag(arg_lead, cmd_line, cursor_pos)
  let l:tags = []
  for t in split(&tags, ",")
    if !filereadable(t)
      continue
    endif
    call add(l:tags, zettel#utils#getRelativePath(t))
  endfor
  return uniq(l:tags)
endfunction


function s:OverloadCtrlSqBracket()
  let l:zettel_jump = zettel#tagLinkJump()
  if l:zettel_jump == 2
    return
  endif

  if !l:zettel_jump
    execute "normal!\<C-]>"
  endif
endfunction
