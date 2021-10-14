" Filename: autoload/zettel/utils.vim
" Author:   18alantom
" License:  MIT License


function zettel#utils#throwErrorIfNoFZF() abort
  let l:has_fzf = exists("g:loaded_fzf") && g:loaded_fzf
  if !l:has_fzf
    echoerr s:plugin_name .. " : fzf not found"
  endif
endfunction


function zettel#utils#getUniqueItems(list)
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


function zettel#utils#getPaddedStr(str, amt, right=1)
  " Add left ' ' padding to a string
  let l:pad = repeat(' ', a:amt - len(a:str))
  if a:right
    return a:str .. l:pad
  endif
  return l:pad .. a:str
endfunction


function zettel#utils#getScrubbedStr(str)
  " Strip whitespaces and subs tabs
  let l:scrubbed = trim(a:str)
  let l:scrubbed = substitute(l:scrubbed, "\t", "\s", "g")
  return l:scrubbed
endfunction


function zettel#utils#getSplitLine(line, delim)
  " Split the given line at the delimiter
  let l:parts = split(a:line, a:delim)
  let l:parts = map(l:parts, "trim(v:val)")
  let l:parts = filter(l:parts, "len(v:val)")
  return l:parts
endfunction


function zettel#utils#getCurrentPosition() abort
  " Returns the line, column, and absolute path
  let [l:line, l:col] = getpos(".")[1:-2]
  let l:abs_file_path = expand("%:p")

  if l:abs_file_path == ""
    echoerr s:plugin_name . " : current buffer is not saved to a file"
  endif

  return [l:line, l:col, l:abs_file_path]
endfunction


" Path helpers
function zettel#utils#getScrubbedRelativePath(path)
  " Removes relativeness of a path, returns stub
  return substitute(a:path, '[.~]\+/', "", "")
endfunction

function zettel#utils#removeZettelRootFromPath(path)
  " Removes g:zettel_tags_root from the path
  " if it matches.
  let l:rootlen = len(g:zettel_tags_root)
  let l:pathstub = a:path[l:rootlen:]

  " If root matches with zettel_tags_root, remove root
  if a:path[:l:rootlen - 1] == g:zettel_tags_root && l:pathstub[0] == "/"
    return l:pathstub[1:]
  endif

  return a:path
endfunction


function zettel#utils#getAbsolutePath(path, prepend_root=0)
  " Convert a relative (~/, ./, ../) path to absolute
  " If prepend_root prepends g:zettel_tags_root to paths
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
      return g:zettel_tags_root .. "/" .. a:path
    elseif a:prepend_root
      return g:zettel_tags_root
    endif
    return "/" .. join(l:cwdparts + l:pathparts, "/")
  else
    " unreachable, need to improve above elseif
    echoerr s:plugin_name .. " : incorect path '" .. a:path .. "'"
  endif
endfunction


function zettel#utils#getRelativePath(path)
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