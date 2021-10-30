" Filename: plugin/zettel.vim
" Author:   18alantom
" License:  MIT License


if exists("g:loaded_zettel")
  finish
endif
let g:loaded_zettel = 1

call zettel#initialize()


" Tagfile Commands
command! -nargs=+ ZettelCreateNewTagFile
  \ call zettel#createNewTagFile(<f-args>)
command! ZettelDeleteTagFile call zettel#deleteTagFile()

" Tag Commands
command! -nargs=* -complete=customlist,s:GetCompletionInsertTag ZettelInsertTag
  \ call zettel#insertTag(<f-args>)
command! -nargs=* -complete=customlist,s:GetCompletionListTags ZettelListTags
  \ call zettel#listTags(0, <f-args>)
command! -nargs=* -complete=customlist,s:GetCompletionListTags ZettelDeleteTag
  \ call zettel#deleteTag(<f-args>)
command! ZettelListTagsInThisFile call zettel#listTags(1)

" Taglink Commands
command! ZettelInsertTagLink call zettel#insertTagLink()
command! ZettelListTagLinks call zettel#listTagLinks()
command! ZettelListTagLinksInThisFile call zettel#listTagLinks(1)
command! -nargs=* -complete=customlist,s:GetCompletionListTags ZettelListTagLinksToATag
  \ call zettel#listTagLinksToATag(<f-args>)


" Key Bindings
if !exists("g:zettel_prevent_default_bindings")
  nnoremap <unique> <leader>zi :ZettelInsertTag<space>
  nnoremap <unique> <leader>zj :ZettelListTags<cr>
  nnoremap <unique> <leader>zl :ZettelInsertTagLink<cr>
  nnoremap <unique> <leader>zd :ZettelDeleteTag<cr>
  nnoremap <unique> <leader>zm :emenu Zettel.
  nnoremap <silent> <C-]> :call <SID>OverloadCtrlSqBracket()<CR>
endif


" Menu
menu Zettel.Insert.Tag :ZettelInsertTag<space>
menu Zettel.Insert.TagLink :ZettelInsertTagLink<cr>

menu Zettel.List.Tags.All :ZettelListTags<cr>
menu Zettel.List.Tags.ByTagFile :ZettelListTags<space>
menu Zettel.List.Tags.InThisFile :ZettelListTagsInThisFile<cr>

menu Zettel.List.TagLinks.All :ZettelListTagLinks<cr>
menu Zettel.List.TagLinks.InThisFile :ZettelListTagLinksInThisFile<cr>
menu Zettel.List.TagLinks.ByTag :ZettelListTagLinksToATag<space>

menu Zettel.Delete.Tags.DisplayAll :ZettelDeleteTag<cr>
menu Zettel.Delete.Tags.DisplayByTagFile :ZettelDeleteTag<space>
menu Zettel.Delete.TagFiles :ZettelDeleteTagFile<cr>


" Internal Functions
function s:GetCompletionInsertTag(arg_lead, cmd_line, cursor_pos)
  let l:tags = []
  for t in split(&tags, ",")
    if !filereadable(t)
      continue
    endif
    call add(l:tags, zettel#utils#getRelativePath(t))
  endfor
  let l:tags = uniq(l:tags)
  if len(a:arg_lead) > 0
    let l:tags = filter(l:tags, {i,v -> match(v, '^' .. a:arg_lead) == 0})
  endif
  return l:tags
endfunction


function s:MapReplaceBlankWithUnscoped(tag)
  if len(a:tag) == 0
    return g:zettel_unscoped_tagfile_name
  endif
  return a:tag
endfunction


function s:GetCompletionListTags(arg_lead, cmd_line, cursor_pos)
  let l:tags = s:GetCompletionInsertTag(a:arg_lead, a:cmd_line, a:cursor_pos)
  let l:tags = map(l:tags, "s:MapReplaceBlankWithUnscoped(v:val)")
  let l:tags = map(l:tags, {i,v -> v[:-2]})
  return l:tags
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
