" Filename: autoload/zettel/utils.vim
" Author:   18alantom
" License:  MIT License


" Autoload isn't working hence this.
let s:plugin_name = "zettel.vim"


function! zettel#utils#getLocCommand(line, col)
  return "call cursor(" .. a:line .. "," .. a:col .. ')|;"'
endfunction


function! zettel#utils#getPosFromLocCommand(loc_command) abort
  " loc_command includes the '|;"' term
  let l:pos = split(a:loc_command[12:-5], ",")
  let l:pos = map(l:pos, "str2nr(v:val)") " Cast to number
  return l:pos
endfunction


function! zettel#utils#throwErrorIfNoFZF() abort
  let l:has_fzf = exists("g:loaded_fzf") && g:loaded_fzf
  if !l:has_fzf
    echoerr s:plugin_name .. " : fzf not found"
  endif
endfunction


function! zettel#utils#getUniqueItems(list) abort
  " Return a set of unique items in a list
  " Uniq wasn't working in some cases
  let l:uniquelist = []
  for i in a:list
    if index(l:uniquelist, i) == -1
      call add(l:uniquelist, i)
    endif
  endfor
  return l:uniquelist
endfunction


function! zettel#utils#getPaddedStr(str, amt, right=1) abort
  " Add left ' ' padding to a string
  let l:pad = repeat(' ', a:amt - len(a:str))
  if a:right
    return a:str .. l:pad
  endif
  return l:pad .. a:str
endfunction


function! zettel#utils#getScrubbedStr(str) abort
  " Strip whitespaces and subs tabs
  let l:scrubbed = trim(a:str)
  let l:scrubbed = substitute(l:scrubbed, "\t", "\s", "g")
  return l:scrubbed
endfunction


function! zettel#utils#getSplitLine(line, delim) abort
  " Split the given line at the delimiter
  let l:parts = split(a:line, a:delim)
  let l:parts = map(l:parts, "trim(v:val)")
  let l:parts = filter(l:parts, "len(v:val)")
  return l:parts
endfunction


function! zettel#utils#getCurrentPosition() abort
  " Returns the line, column, and absolute path
  let [l:line, l:col] = getpos(".")[1:-2]
  let l:abs_file_path = expand("%:p")

  if l:abs_file_path == ""
    echoerr s:plugin_name . " : current buffer is not saved to a file"
  endif

  return [l:line, l:col, l:abs_file_path]
endfunction


function! zettel#utils#getScrubbedRelativePath(path) abort
  " Removes relativeness of a path, returns stub
  return substitute(a:path, '[.~]\+/', "", "")
endfunction


function! zettel#utils#removeZettelRootFromPath(path) abort
  " Removes g:zettel_root from the path
  " if it matches.
  let l:rootlen = len(g:zettel_root)
  let l:pathstub = a:path[l:rootlen:]

  " If root matches with zettel_root, remove root
  if a:path[:l:rootlen - 1] == g:zettel_root && l:pathstub[0] == "/"
    return l:pathstub[1:]
  endif

  return a:path
endfunction


function! zettel#utils#getAbsolutePath(path, prepend_root=0) abort
  " Convert a relative (~/, ./, ../) path to absolute
  " If prepend_root prepends g:zettel_root to paths
  " of the form 'path/to/file'
  let l:cwd = expand("%:p:h")
  let l:cwdparts = split(l:cwd, "/")
  let l:pathparts = split(a:path, "/")

  if a:path[0] == "/"
    return a:path
  elseif a:path[:1] == "~/"
    return $HOME .. a:path[1:]
  elseif a:path[:2] == "../"
    return "/" .. join(l:cwdparts[:-2] + l:pathparts[1:], "/")
  elseif a:path[:1] == "./"
    return "/" .. join(l:cwdparts + l:pathparts[1:], "/")
  elseif a:path[0] != "/"
    if a:prepend_root && len(a:path)
      return g:zettel_root .. "/" .. a:path
    elseif a:prepend_root
      return g:zettel_root
    endif
    return "/" .. join(l:cwdparts + l:pathparts, "/")
  else
    " unreachable, need to improve above elseif
    echoerr s:plugin_name .. " : incorect path '" .. a:path .. "'"
  endif
endfunction


function! zettel#utils#getRelativePath(path) abort
  " Removes g:zettel_root from the path
  " Converts absolute paths to relative
  
  let l:rootlen = len(g:zettel_root)
  let l:pathstub = a:path[l:rootlen:]

  " Blank defaults to unscoped tagfile
  if a:path == g:zettel_unscoped_tagfile_name
    return ""
  endif

  " If root matches with zettel_root, remove root
  if a:path[:l:rootlen - 1] == g:zettel_root && l:pathstub[0] == "/"
    if l:pathstub[1:] == g:zettel_unscoped_tagfile_name
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


" Filters to get *lines:
"
"   tagline format:
"     {tagname}	{TAB} {filepath} {TAB} {tagaddress} {term} {field} ..
"
"   filters = {
"     'tagfile': '...',
"     'tagname': '...',
"     'filepath': '...',
"   }
"
"   taglink format:
"     {filepath} {TAB} {line:col} {TAB} {taglink}
"
"   filters = {
"     'filepath': '...',
"     'taglink': '...'
"   }
"
"
function! zettel#utils#getAllTagLines(filters={}) abort
  " Will return list of all taglines
  " tagline will have tagpath prepended
  let l:tags = map(split(&tags, ","), "zettel#utils#getScrubbedRelativePath(v:val)")
  let l:tags = map(l:tags, "zettel#utils#getAbsolutePath(v:val, 1)")
  let l:tags = filter(l:tags, "filereadable(v:val)")
  let l:tags = zettel#utils#getUniqueItems(l:tags)

  if has_key(a:filters, "tagfile") && len(a:filters["tagfile"]) > 0
    let l:filter_paths = a:filters["tagfile"]
    if type(l:filter_paths) != type([])
      let l:filter_paths = [a:filters["tagfile"]]
    endif

    " Map stopped working for somereason in nvim
    let l:ff_tag_path = []
    for path in l:filter_paths
      let l:temp = zettel#utils#getScrubbedRelativePath(path)
      let l:temp = zettel#utils#getAbsolutePath(l:temp, 1)
      call add(l:ff_tag_path, l:temp)
    endfor

    let l:tags = filter(l:tags, {i,v -> index(l:ff_tag_path, v) != -1})
  endif

  let l:tag_lines = []
  let l:header_suffix = "!_TAG_"
  let l:suffix_len = len(l:header_suffix)
  let l:idx = 0
  for abs_path_to_tagfile in l:tags
    let l:lineno = 0
    for line in readfile(abs_path_to_tagfile)
      let l:lineno += 1
      if (line == "") ||
        \ (line[:l:suffix_len - 1] == l:header_suffix)
        continue
      endif
      let l:parts = zettel#utils#getSplitLine(line, "\t")

      " Filters
      if has_key(a:filters, "tagname") && l:parts[0] != a:filters["tagname"]
        continue
      endif

      if has_key(a:filters, "filepath") && l:parts[1] != a:filters["filepath"]
        continue
      endif

      call add(
        \l:tag_lines,
        \l:idx.. "\t" .. l:lineno .. "\t" .. abs_path_to_tagfile .. "\t" .. l:line
      \)
      let l:idx += 1
    endfor
  endfor
  return l:tag_lines
endfunction


function! zettel#utils#getAllTagLinkLines(filters={}) abort
	let l:taglink_lines = readfile(g:zettel_tagslink_path)
  if !len(a:filters)
    return l:taglink_lines
  endif
  let l:filtered_taglink_lines = []
  for line in l:taglink_lines
    let l:parts = zettel#utils#getSplitLine(line, "\t")

    " Filters
    if has_key(a:filters, "filepath") && l:parts[0] != a:filters["filepath"]
      continue
    endif

    if has_key(a:filters, "taglink") && l:parts[2] != a:filters["taglink"]
      continue
    endif

    call add(l:filtered_taglink_lines, line)
  endfor
  
  return l:filtered_taglink_lines
endfunction