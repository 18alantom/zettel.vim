" Initialize Global Variables
"
" g:zettel_tags_root
" - root folder for all tags
" - default : '~/zettel'

" g:zettel_tags_unscoped_tagfile_name
" - folder to store unscoped tags
" - default : 'tags'
"
" g:zettel_tags_default_field_togit
" - will set a field togit to tag file
" - this will be used in the future to add all files in the tag file to a git
"   repo for remote storage
" - default : 1

if !exists("g:zettel_tags_root")
  let s:home = getenv("HOME")
  if s:home == v:null
    echoerr s:plugin_name . " : please set $HOME or g:zettel_tags_root" 
  endif

  let g:zettel_tags_root = s:home . "/zettel"
endif

if !exists("g:zettel_tags_unscoped_tagfile_name")
  let g:zettel_tags_unscoped_tagfile_name = "tags"
endif

if !exists("g:zettel_tags_default_field_togit")
  let g:zettel_tags_default_field_togit = 1
endif


" Tag Headers and Meta Data
let s:plugin_name = "zettel.vim"

let s:field_defaults = {
  \"togit" : ["!_TAG_TOGIT", g:zettel_tags_default_field_togit]
\}

let s:tag_file_headers = [
  \"!_TAG_FILE_FORMAT	2	/{field} will be used to additional info/",
  \"!_TAG_FILE_SORTED	1",
  \"!_TAG_PROGRAM_AUTHOR	Alan	/github.com/18alantom/",
  \"!_TAG_PROGRAM_NAME zettel.vim",
  \"!_TAG_PROGRAM_URL	https://github.com/18alantom/vim-zettel /source code/",
\]

let s:tagsloc_path = g:zettel_tags_root . "/" . "tagsloc.txt"


" Helper Functions
function s:GetAbsolutePath(path)
  " Convert a relative (./, ../) path to absolute
  if a:path[0] == "/"
    return a:path
  endif
  let l:pathparts = split(a:path, "/")
  let l:root = split(expand("%:p:h"), "/")[0:-len(l:pathparts[0])]
  return "/" . join(root + pathparts[1:], "/")
endfunction

function s:AddPathToTags(path) abort
  " Add a path to &tags
  let l:tags = split(&tags, ",")
  if index(l:tags, a:path) == -1
    call add(l:tags, a:path)
    let &tags = join(l:tags, ",")
  endif
endfunction

function s:WriteTagsToTagsloc() abort
  " Write the content of &tags to tagsloc.txt for persistance
  let l:tags = split(&tags, ",")
  if !filereadable(s:tagsloc_path)
    call writefile(l:tags, s:tagsloc_path)
    return
  endif

  let l:tagsloc_tags = readfile(s:tagsloc_path)
  let l:tags_to_append = []
  for tag in l:tags
    if index(l:tagsloc_tags, tag) >= 0
      continue
    endif
    call add(l:tags_to_append, tag)
  endfor

  call writefile(l:tags_to_append, s:tagsloc_path, "a")
endfunction

function s:LoadTagsFromTagsloc() abort
  " Load tags into &tags when vim opens, if it doesn't exist, create one
  if !filereadable(s:tagsloc_path)
    call s:WriteTagsToTagsloc()
    return
  endif

  let &tags = join(readfile(s:tagsloc_path), ",")
endfunction

function s:GetTagFilePath(tags_path)
  " tag_file
  " - just the suffix, example : 'Desktop/code'
  " - will return the absolute path

  let l:path_parts = split(a:tags_path, "/")
  let l:tagfile_name = trim(l:path_parts[-1])

  if a:tags_path =~# '^[.]\{0,2}[/]'
    let l:tagfile_path = s:GetAbsolutePath(trim(join(path_parts[0:-2], "/")))
  else
    let l:tagfile_path = trim(join([g:zettel_tags_root] + path_parts[0:-2], "/"))
  endif

  let l:abs_path = l:tagfile_path . "/" . l:tagfile_name
  return [l:abs_path, l:tagfile_path, l:tagfile_name]
endfunction

function s:CreateTagFile(tags_path, default_overrides = {}, exist_err = 1) abort
  " tags_path
  " - path stub to the tag file; g:zettel_tags_root will be
  "   prepended to it unless it's relative (./, ../)
  " - example : 'code/pytags'
  "
  " default_overrides
  " - dictionary to override the tag field defaults
  " - example : { 'togit' : 0 }
  "
  " exist_err
  " - show an error if the file exists

  let [l:abs_path, l:tagfile_path, l:tagfile_name] = s:GetTagFilePath(a:tags_path)

  call mkdir(tagfile_path, "p")
  if filereadable(l:abs_path)
    if !a:exist_err
      return l:abs_path
    endif

    echoerr s:plugin_name . " : Tagfile '"  . l:tagfile_name
      \. "' already exists at '" . l:tagfile_path . "'."
  else
    call writefile(s:tag_file_headers, l:abs_path)

    " Apply field default headers
    let l:tag_file_field_headers = s:GetTagFieldHeaders(a:default_overrides)
    call writefile(l:tag_file_field_headers, l:abs_path, "a")
    call s:AddPathToTags(l:abs_path)
    call s:WriteTagsToTagsloc()

    echo s:plugin_name . " : New tagfile '" . l:tagfile_name
      \. "' created at '" . l:tagfile_path . "'."
  endif
  return l:abs_path
endfunction

function s:GetTagFieldHeaders(default_overrides) abort
  " default_overrides : 
  " - dictionary to override the tag field defaults
  " - example : { 'togit' : 0 }
  let l:tag_field_headers = []

  for k in keys(s:field_defaults)
    let [l:field_template, l:field_default] = s:field_defaults[k]
    if has_key(a:default_overrides, k)
      let l:field_default = a:default_overrides[k]
    endif
    call add(l:tag_field_headers, l:field_template . " " . l:field_default)
  endfor

  return l:tag_field_headers
endfunction

function s:GetDefaultOverrides(args) abort
  let l:default_overrides = {}
  for i in a:args
    let l:split = split(i, "=")
    if len(l:split) != 2
      continue
    endif
    let [l:key, l:value] = l:split
    let l:default_overrides[key] = value
  endfor
  return l:default_overrides
endfunction

function s:GetTagLoc() abort
  let [l:line, l:col] = getpos(".")[1:-2]
  let l:abs_file_path = expand("%:p")

  if l:abs_file_path == ""
    echoerr s:plugin_name . " : current buffer is not saved to a file"
  endif

  return [l:line, l:col, l:abs_file_path]
endfunction

function s:InsertTagLine(tag_line, tags_path) abort
  " Will create tagfile if it doesn't exist
  let l:abs_path = s:CreateTagFile(a:tags_path, {}, 0)
  call writefile([a:tag_line], l:abs_path, "a")
endfunction

function s:GetTagLine(tag, tag_loc, default_overrides) abort
  let [l:line, l:col, l:abs_file_path] = a:tag_loc
  " tagname {TAB} file path {TAB} tagaddress|;" {field}
  let l:tagaddress_and_term = "call cursor(" . l:line . "," . l:col . ')|;"'
  let l:tagline = join([a:tag, l:abs_file_path, l:tagaddress_and_term], "\t")

  for k in keys(a:default_overrides)
    let l:field = k . ":" . a:default_overrides[k]
    let l:tagline = join([l:tagline, l:field], "\t")
  endfor

  return l:tagline . "\n"
endfunction

function s:GetTagAndTagsFile(tags_string)
  let l:tag = getline(".")
  let l:tag_file = g:zettel_tags_unscoped_tagfile_name

  if a:tags_string=~#"^@"
    let l:tag_file = a:tags_string[1:]
  elseif len(a:tags_string) > 0
    let l:temp = split(a:tags_string, "/")
    let l:tag = l:temp[-1]
    if len(l:temp[:-2]) > 0
      let l:tag_file = join(l:temp[:-2], "/")
    endif
  endif

  return [
        \s:GetScrubbedStr(l:tag),
        \s:GetScrubbedStr(l:tag_file)
  \]
endfunction

function s:GetScrubbedStr(str)
  " Strip whitespaces and subs tabs
  let l:scrubbed = trim(a:str)
  let l:scrubbed = substitute(l:scrubbed, "\t", "\s", "g")
  return l:scrubbed
endfunction

function s:GetTagsString(args)
  let l:tags_string = ""
  for arg in a:args
    if arg=~#'='
      continue
    endif
    let l:tags_string = arg
  endfor
  return l:tags_string
endfunction


" Autoload functions called from plugin/zettel.vim
function! zettel#initialize() abort
  call mkdir(g:zettel_tags_root, "p")
  call s:LoadTagsFromTagsloc()
  call s:CreateTagFile(g:zettel_tags_unscoped_tagfile_name, {}, 0)
endfunction

function! zettel#createNewTagFile(...) abort
  " Shim function between a command and s:CreateTagFile
  " - a.000[0]  : path/to/tagfile | tagfile
  " - a.000[1:] : {fieldname}={fieldvalue}
  " eg: ['/py/pytags', 'togit=0']
  let l:tags_path = a:000[0]
  let l:default_overrides = s:GetDefaultOverrides(a:000)
  call s:CreateTagFile(l:tags_path, l:default_overrides)
endfunction

function! zettel#insertTag(...) abort
  " Function that inserts a tag into a tag file
  " - a.000[0]  : @path/to/tagfile | tagfile/tagname | tagname
  " - a.000[1:] : {fieldname}={fieldvalue}
  let l:tags_string = s:GetTagsString(a:000)
  let [l:tag, l:tags_path] = s:GetTagAndTagsFile(l:tags_string)
  let l:tag_loc = s:GetTagLoc() " [line, col, filename]
  let l:default_overrides = s:GetDefaultOverrides(a:000)
  let l:tag_line = s:GetTagLine(l:tag, l:tag_loc, l:default_overrides)
  call s:InsertTagLine(l:tag_line, l:tags_path)

  " if tags_path has a '/' split by it
  " use first n-1 (n if starts with @) values in split to find tag file (for now exact match)
  " use last value as tag name (if doesn't start with @) else use line as tag name
  " get the line location in the file line number or literal line location? 
  " (check how marks are stored)
  " write line name, location and key values to the file.
endfunction
