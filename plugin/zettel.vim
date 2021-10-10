if exists("g:loaded_zettel")
  finish
endif
let g:loaded_zettel = 1

call zettel#initialize()

" Commands
command! -nargs=+ ZettelCreateNewTagFile
  \call zettel#createNewTagFile(<f-args>)
nnoremap <unique> <leader>zn :ZettelCreateNewTagFile<space>
" Creates a new tags file
" - format: ZettelCreateNewTagFile {tagfile_name|pathtotagfile/tagfiel_name} [{field}={value}]
" - If relative or absolute paths are used g:zettel_tags_root is ignored
"
" example: 'ZettelCreateNewTagFile path/to/tagfile'
" - 'tagfile' is created at [g:zettel_tags_root]/path/to
" - default togit value for this file is set to g:zettel_tags_default_field_togit
"
" example: 'ZettelCreateNewTagFile ./temp/tagfile togit=0'
" - 'tagfile' is created at ./temp
" - default togit value for this file is set to 0

command! -nargs=* -complete=customlist,s:CompletionInsertTag ZettelInsertTag
  \call zettel#insertTag(<f-args>)
nnoremap <unique> <leader>zi :ZettelInsertTag<space>
" TODO: this command is incomplete
" TODO: add tab complete to prefix the tag files
" Inserts a tag into the specified file
" - format: ZettelInsertTag [{tagname|tagspath/tagname}] [{field}={value}]
" - if no argument is supplied the current line is used as the tag name
" - if a relative path or a string with a slash is supplied the respective
"   tagfile is selected.
" - if a string starts with @ it is considered as the tagfile path and current
"   line is used as the tagname.
" - If tagfile is not found at a given path, a new tagfile is created.
"
" example: 'ZettelInsertTag ./temp/tagfile/tagname togit=0'
" - will insert a tag 'tagname' into './temp/tagfile' with field 'togit' set to
"   a value of 0.
" - if './temp/tagfile' isn't present it will create the tagfile with the
"   defaults set by 'g:zettel_tags_*' variables
"
" example: 'ZettelInsertTag @./temp/tagfile'
" - will insert a tag with it's name as the current line under the cursor into
"   './temp/tagfile'
" - the file may be created if it doesn't exist
"
" example: 'ZettelInsertTag'
" - will insert a tag with it's name as the current line under the cursor into
"   'g:zettel_tags_root/tags'

if !exists("g:zettel_tags_prevent_default_bindings")
  nnoremap <leader>zc :ZettelCreateNewTagFile<space>
  nnoremap <leader>zi :ZettelInsertTag<space>
endif

" Completion Functions
function s:CompletionInsertTag(arg_lead, cmd_line, cursor_pos)
  " TODO: Add suggestions with word under cursor suffixed
  " TODO: Add suggestions with '@' prefixed for line entry
  let l:tags = []
  for t in split(&tags, ",")
    if !filereadable(t)
      continue
    endif
    call add(l:tags, s:GetRelativePath(t))
  endfor
  return uniq(l:tags)
endfunction

function s:GetRelativePath(path)
  " Removes g:zettel_tags_root from the path
  " Converts absolute paths to relative
  " TODO : return [..] relative path
  
  let l:rootlen = len(g:zettel_tags_root)
  let l:pathstub = a:path[l:rootlen:]

  " Blank defaults to unscoped tagfile
  if a:path == g:zettel_tags_unscoped_tagfile_name
    return ""
  endif

  " If root matches with zettel_tags_root, remove root
  if a:path[:l:rootlen - 1] == g:zettel_tags_root && l:pathstub[0] == "/"
    if l:pathstub[1:] == g:zettel_tags_unscoped_tagfile_name
      return ""
    endif
    return l:pathstub[1:] .. "/"
  endif

  " If root matches with filepath sub with ./
  let l:filepath = expand("%:p:h")
  let l:fplen = len(l:filepath)
  let l:pathstub = a:path[l:fplen:]
  if a:path[:l:fplen - 1] == l:filepath && l:pathstub[0] == "/"
    return "./" .. l:pathstub[1:] .. "/"
  endif

  return a:path .. "/"
endfunction
