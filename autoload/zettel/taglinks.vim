" Filename: autoload/taglinks.vim
" Author:   18alantom
" License:  MIT License

" Taglinks are maintained by keeping references to
" a list of files where taglinks have been inserted.
"
" These paths to these files are stored at the var
" s:taglinklocs_path with their last modified date.
"
" When the taglinks (filtered or otherwise) are
" required these files are scanned for taglinks and
" written to g:zettel_taglinkcache_path.
"
" A file is scanned only if the cache file isn't present
" or it's last modified timestamp was after the stored
" last modified timestamp.


let g:zettel_taglinkcache_path = g:zettel_root .. "/" .. ".taglinks.txt"
let s:taglinklocs_path = g:zettel_root .. "/" .. ".taglinklocs.txt"
let s:taglink_pattern = '\<' .. g:zettel_taglink_prefix .. '\%(\w\|[-/]\)\+'


function s:GetTagLinkLinesFromCache() abort
  let l:taglink_lines = []
  if filereadable(g:zettel_taglinkcache_path)
    let l:taglink_lines = readfile(g:zettel_taglinkcache_path)
  endif
  return l:taglink_lines
endfunction


function s:GetListOfUpdatedTagLocFiles() abort
  if !filereadable(s:taglinklocs_path)
    return [[], []]
  endif

  let l:list = readfile(s:taglinklocs_path)
  let l:list = map(l:list, {i,v -> zettel#utils#getSplitLine(v, "\t")})

  let l:list_of_files = []
  let l:list_of_dropped_files = []
  if !filereadable(g:zettel_taglinkcache_path)
    let l:list_of_files = map(l:list, {i,v -> v[0]})
  else
    for item in l:list
      if !filereadable(item[0])
        call add(l:list_of_dropped_files, item[0])
        continue
      endif

      let l:last_saved = str2nr(item[1])
      let l:last_modified = getftime(item[0])

      let l:line = join(item, "\t")
      if l:last_modified > l:last_saved
        let l:line = join([item[0], l:last_modified], "\t")
        call add(l:list_of_files, item[0])
      endif
    endfor
  endif
  return [l:list_of_files, l:list_of_dropped_files]
endfunction


function zettel#taglinks#getTagLinkMatches(line) abort
  let taglink_matches = []
  call substitute(a:line, s:taglink_pattern, '\=add(taglink_matches, submatch(0))', 'g')
  return taglink_matches
endfunction


function s:GetTagLinksFromFile(abs_file_path) abort
  " taglink format: 'abs_path_to_file_with_taglink {TAB} line:col {TAB} taglink
  let l:taglink_lines = []
  let l:lineno = 0
  for line in readfile(a:abs_file_path)
    let l:lineno += 1

    " Add all taglinks in the line
    for m in zettel#taglinks#getTagLinkMatches(line)
      let [l:taglink, l:start] = matchstrpos(line, m)[:1]
      let l:pos = join([l:lineno, l:start], ":")
      let l:tagline = join([a:abs_file_path, l:pos, l:taglink], "\t")
      call add(l:taglink_lines, l:tagline)
    endfor
  endfor
  return l:taglink_lines
endfunction


function s:UpdateCacheAndGetAllTagLinkLines() abort
  let [l:files_to_check, l:files_to_drop] = s:GetListOfUpdatedTagLocFiles()
  let l:cached_lines = s:GetTagLinkLinesFromCache()
  let l:updated_lines = []

  " Lines from unupdated files
  for line in l:cached_lines
    let l:abs_file_path = zettel#utils#getSplitLine(line, "\t")[0]
    let l:will_be_updated =  index(l:files_to_check, l:abs_file_path) != -1
    let l:will_be_dropped =  index(l:files_to_drop, l:abs_file_path) != -1

    if l:will_be_updated || l:will_be_dropped
      continue
    endif

    call add(l:updated_lines, line)
  endfor

  " Lines from updated files
  for abs_file_path in l:files_to_check
    let l:taglink_lines_from_file = s:GetTagLinksFromFile(abs_file_path)
    call extend(l:updated_lines, l:taglink_lines_from_file)
  endfor

  call writefile(l:updated_lines, g:zettel_taglinkcache_path)
  return l:updated_lines
endfunction


function s:UpdateTagLinkLocs(taglinklocs)
  let l:writeback_list = []
  for line in readfile(s:taglinklocs_path)
    let l:parts = zettel#utils#getSplitLine(line, "\t")
    if index(a:taglinklocs, l:parts[0]) == -1
      continue
    endif
    call add(l:writeback_list, line)
  endfor
  call writefile(l:writeback_list, s:taglinklocs_path)
endfunction


function! zettel#taglinks#getAllTagLinkLines(filters={}) abort
  " Every time this function is called
  " the taglinklocs file is cleaned i.e
  " files that have not taglinks or files
  " that have been deleted are removed
  " from it.
  let l:taglink_lines = s:UpdateCacheAndGetAllTagLinkLines()

  let l:taglinklocs = []
  let l:filtered_taglink_lines = []

  let l:has_filepath = has_key(a:filters, "filepath")
  let l:has_taglink = has_key(a:filters, "taglink")

  for line in l:taglink_lines
    let l:parts = zettel#utils#getSplitLine(line, "\t")
    if index(l:taglinklocs, l:parts[0]) == -1
      call add(l:taglinklocs, l:parts[0])
    endif

    " Filters
    if l:has_filepath && l:parts[0] != a:filters["filepath"]
      continue
    endif

    if l:has_taglink && l:parts[2] != a:filters["taglink"]
      continue
    endif

    call add(l:filtered_taglink_lines, line)
  endfor
  
  call s:UpdateTagLinkLocs(l:taglinklocs)
  return l:filtered_taglink_lines
endfunction


function! zettel#taglinks#updateTagLinkLoc(abs_file_path) abort
  " format: {abs_file_path} {TAB} {timestamp}
  let l:last_modified = getftime(a:abs_file_path)
  let l:update_line = join([a:abs_file_path, l:last_modified], "\t")

  if !filereadable(s:taglinklocs_path)
    call writefile([l:update_line], s:taglinklocs_path)
    return
  endif

  let l:lines_to_write = []
  let l:add_update_line = 1
  for line in readfile(s:taglinklocs_path)
    let l:parts = zettel#utils#getSplitLine(line, "\t")
    if l:parts[0] == a:abs_file_path && str2nr(l:parts[1]) < l:last_modified
      continue
    elseif l:parts[0] == a:abs_file_path && str2nr(l:parts[1]) > l:last_modified
      let l:add_update_line = 0
    endif
    call add(l:lines_to_write, line)
  endfor

  if l:add_update_line
    call add(l:lines_to_write, l:update_line)
  endif

  call writefile(l:lines_to_write, s:taglinklocs_path)
endfunction
