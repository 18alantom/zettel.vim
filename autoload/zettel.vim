" Filename: autoload/zettel.vim
" Author:   18alantom
" License:  MIT License


" Initialize Global Variables
if !exists("g:zettel_tags_root")
  let s:home = getenv("HOME")
  if s:home == v:null
    echoerr s:plugin_name . " : please set $HOME or g:zettel_tags_root" 
  endif

  let g:zettel_tags_root = s:home . "/.zettel"
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
  \"togit" : g:zettel_tags_default_field_togit
\}

let s:tag_file_headers = [
  \"!_TAG_FILE_FORMAT	2	/{field} will be used to additional info/",
  \"!_TAG_FILE_SORTED	1",
  \"!_TAG_PROGRAM_AUTHOR	Alan	/github.com/18alantom/",
  \"!_TAG_PROGRAM_NAME zettel.vim",
  \"!_TAG_PROGRAM_URL	https://github.com/18alantom/vim-zettel /source code/",
\]

let s:tagsloc_path = g:zettel_tags_root . "/" . "tagsloc.txt"
let s:tagslink_path = g:zettel_tags_root . "/" . "tagslink.txt"



" Functions
function s:LoadTagsFromTagsloc() abort
  " Load tags into &tags when vim opens, if it doesn't exist, create one
  if !filereadable(s:tagsloc_path)
    call s:WriteTagsToTagsloc()
    return
  endif

  let &tags = join(readfile(s:tagsloc_path), ",")
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


function s:AddPathToTags(path) abort
  " Add a path to &tags
  let l:tags = split(&tags, ",")
  if index(l:tags, a:path) == -1
    call add(l:tags, a:path)
    let &tags = join(l:tags, ",")
  endif
endfunction


function s:GetTagFieldHeaders(default_overrides) abort
  " Returns tagfield headerlines, allows for
  " arbitary field, values in the header but
  " they are uppercased.
  "
  " default_overrides : 
  " - dictionary to override the tag field defaults
  " - example : { 'togit' : 0 }
  let l:tag_field_headers = []
  let l:tag_field_suffix = "!_TAG_FIELD_"
  let l:field_values = copy(s:field_defaults)

  call extend(l:field_values, a:default_overrides)

  for item in items(l:field_values)
    let [l:field, l:value] = item
    let l:header_line = l:tag_field_suffix .. toupper(l:field) .. " " .. l:value
    call add(l:tag_field_headers, l:header_line)
  endfor

  return l:tag_field_headers
endfunction


function s:GetTagFilePath(stub_path_to_tagfile)
  " stub_path_to_tagfile
  " - just the suffix, example : 'folder0/folder1/tagfile'
  " 
  " Return
  " l:abs_path_to_tagfile
  " - abs path to the tagfile, example: '/Users/blah/.zettel/folder0/folder1/tagfile'
  "
  " l:abs_path_to_tagdir
  " - abs path to dir with tagfile, example: '/Users/blah/.zettel/folder0/folder1'
  "
  " l:tagfile_name
  " - last part of tags_path taken as name, example: 'tagfile'
  let l:stub_path_parts = split(a:stub_path_to_tagfile, "/")
  let l:stub_path_to_tagdir = trim(join(stub_path_parts[0:-2], "/"))
  let l:stub_path_to_tagdir = zettel#utils#getScrubbedStr(l:stub_path_to_tagdir)
  let l:abs_path_to_tagdir = zettel#utils#getAbsolutePath(l:stub_path_to_tagdir, 1)
  let l:tagfile_name = trim(l:stub_path_parts[-1])
  let l:abs_path_to_tagfile = join([l:abs_path_to_tagdir, l:tagfile_name], "/")
  return [l:abs_path_to_tagfile, l:abs_path_to_tagdir, l:tagfile_name]
endfunction


function s:CreateTagFile(stub_path_to_tagfile, default_overrides = {}, exist_err = 1) abort
  " Will create a tagfile at passed stub path prepended by
  " g:zettel_tags_root add its absolute path to &tags, tagloc.txt
  " and return it.
  "
  " stub_path_to_tagfile
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
  let l:stub_path_to_tagfile = zettel#utils#getScrubbedRelativePath(a:stub_path_to_tagfile)
  let [l:abs_path_to_tagfile, l:abs_path_to_tagdir, l:tagfile_name] = s:GetTagFilePath(l:stub_path_to_tagfile)

  call mkdir(l:abs_path_to_tagdir, "p")
  if filereadable(l:abs_path_to_tagfile)
    if !a:exist_err
      return l:abs_path_to_tagfile
    endif

    echoerr s:plugin_name . " : Tagfile '"  . l:tagfile_name
      \. "' already exists at '" . l:abs_path_to_tagdir . "'."
  else
    call writefile(s:tag_file_headers, l:abs_path_to_tagfile)

    " Apply field default headers
    let l:tag_file_field_headers = s:GetTagFieldHeaders(a:default_overrides)
    call writefile(l:tag_file_field_headers, l:abs_path_to_tagfile, "a")
    call s:AddPathToTags(l:abs_path_to_tagfile)
    call s:WriteTagsToTagsloc()

    echo s:plugin_name . " : New tagfile '" . l:tagfile_name
      \. "' created at '" . l:abs_path_to_tagdir . "'."
  endif
  return l:abs_path_to_tagfile
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


function s:GetCurrentPosition() abort
  let [l:line, l:col] = getpos(".")[1:-2]
  let l:abs_file_path = expand("%:p")

  if l:abs_file_path == ""
    echoerr s:plugin_name . " : current buffer is not saved to a file"
  endif

  return [l:line, l:col, l:abs_file_path]
endfunction


function s:InsertTagLine(tag_line, stub_path_to_tagfile) abort
  " Will create tagfile if it doesn't exist
  let l:abs_path_to_tagfile = s:CreateTagFile(a:stub_path_to_tagfile, {}, 0)
  call writefile([a:tag_line], l:abs_path_to_tagfile, "a")
endfunction


function s:GetTagLine(tagname, position, default_overrides) abort
  let [l:line, l:col, l:abs_file_path] = a:position
  " tagname {TAB} file path {TAB} tagaddress|;" {field}
  let l:tagaddress_and_term = "call cursor(" . l:line . "," . l:col . ')|;"'
  let l:tagline = join([a:tagname, l:abs_file_path, l:tagaddress_and_term], "\t")

  for k in keys(a:default_overrides)
    let l:field = k . ":" . a:default_overrides[k]
    let l:tagline = join([l:tagline, l:field], "\t")
  endfor

  return l:tagline . "\n"
endfunction


function s:GetTagNameAndTagFileStub(tag_path)
  let l:tagname = getline(".")
  let l:stub_path_to_tagfile = g:zettel_tags_unscoped_tagfile_name

  if a:tag_path=~#"^@"
    let l:stub_path_to_tagfile = zettel#utils#getScrubbedRelativePath(a:tag_path[1:])
  elseif len(a:tag_path) > 0
    let l:tag_path = zettel#utils#getScrubbedRelativePath(a:tag_path)
    let l:parts = split(l:tag_path, "/")
    let l:tagname = l:parts[-1]
    if len(l:parts[:-2]) > 0
      let l:stub_path_to_tagfile = join(l:parts[:-2], "/")
    endif
  endif

  return [
        \zettel#utils#getScrubbedStr(l:tagname),
        \zettel#utils#getScrubbedStr(l:stub_path_to_tagfile)
  \]
endfunction


function s:GetTagPath(args)
  " Returns tag_path i.e. 'folder/tagfile/tagname'
  " from arglist
  let l:tag_path = ""
  for arg in a:args
    if arg=~#'='
      continue
    endif
    let l:tag_path = arg
  endfor
  return l:tag_path
endfunction


function s:GetListOfAllTags(with_line_number=0) abort
  " Will return list of all taglines
  " tagline will have tagpath prepended
	" TODO: don't list tags not in zettel root
  let l:tags = map(split(&tags, ","), "zettel#utils#getScrubbedRelativePath(v:val)")
  let l:tags = map(l:tags, "zettel#utils#getAbsolutePath(v:val)")
  let l:tags = filter(l:tags, "filereadable(v:val)")
  let l:tags = zettel#utils#getUniqueItems(l:tags)
  let l:tag_lines = []
  let l:header_suffix = "!_TAG_"
  let l:suffix_len = len(l:header_suffix)
  for tagfile in l:tags
    let l:i = 0
    for line in readfile(l:tagfile)
      let l:i += 1
      if (line == "") ||
        \ (len(line) < l:suffix_len) ||
        \ (line[:l:suffix_len - 1] == l:header_suffix)
        continue
      endif
      if a:with_line_number
        call add(l:tag_lines, i .. "\t" .. tagfile .. "\t" .. line)
      else
        call add(l:tag_lines, tagfile .. "\t" .. line)
      endif
    endfor
  endfor
  return l:tag_lines
endfunction


function s:MapGetFormattedTagLine(i, tagline)
  let l:tagparts = zettel#utils#getSplitLine(a:tagline, "\t")
  let l:tagpath = zettel#utils#removeZettelRootFromPath(l:tagparts[0])
  let l:tagpath = zettel#utils#getPaddedStr(l:tagpath, 48)
  let l:tagname = zettel#utils#getPaddedStr(l:tagparts[1], 24)
  let l:taglocation = l:tagparts[3]
  let l:lineno = matchstr(l:taglocation, '\(\d\+\)')
  let l:filepath = l:tagparts[2]
  return l:tagname .. "  " .. l:tagpath .. repeat(" ", 4) .. l:filepath .. repeat(" ", 4) .. l:lineno .. repeat(" ", 4) .. l:taglocation
endfunction


function s:GetTagLink(tagname, tagpath, taglineno)
  " TODO: complete this function
endfunction


function s:GetFormattedTagLink(taglink)
  " TODO: complete this function
endfunction


function s:InsertTagLink(taglink)
  " TODO: complete this function
endfunction


function s:InsertLinkIntoLinkFile(taglink)
  " format: 'pathtofilewithlink {TAB} linkloc {TAB} taglink
  " taglink contains tagfile path and the the tagname
  " just needs to be destructured
  let [l:line, l:col, l:linkpath] = s:GGetTagLocetCurrentPosition() " [line, col, filename]
  let l:linkloc = "call cursor(" .. l:line .. "," .. l:col .. ")"
  let l:linkline = l:linkpath .. "\t" .. l:linkloc .. "\t" .. a:taglink
  writefile([l:linkline], s:tagslink_path, "a")
endfunction


function s:HandleTagSelection(tagline) abort
  " Sink function for fzf, this will insert the tagline
  " insert tag into file
  " insert tag into taglink file

  " let l:taglink = s:GetTagLink(a:tagline)
  " let l:formatted_taglink = s:GetFormattedTagLink(l:taglink)
  " call s:InsertTagLink(l:formatted_taglink)
  " call s:InsertLinkIntoLinkFile(l:taglink)
endfunction


function s:HandleTagJump(tagline)
  let l:parts = zettel#utils#getSplitLine(a:tagline, "  ")
  let l:tagname = l:parts[0]
  let l:stub_path_to_tagfile = l:parts[2]
  let l:loc_command = l:parts[4][:-4]
  let [l:winid, l:tagstack] = s:GetTagStackUpdateDetails(l:tagname)
  let l:jump_successful = s:JumpToTag(l:stub_path_to_tagfile, l:loc_command)
  if l:jump_successful && &tagstack
    call settagstack(l:winid, l:tagstack, "a")
  endif
endfunction


function s:GetTagStackUpdateDetails(tagname)
	let l:position = [bufnr()] + getcurpos()[1:]
	let l:item = {'bufnr': l:position[0], 'from': l:position, 'tagname': a:tagname}
  let l:winid = win_getid()
  let l:tagstack = gettagstack(l:winid)
  let l:tagstack['items'] = [l:item]
  return [l:winid, l:tagstack]
endfunction


function s:JumpToTag(file_path, loc_command) abort
  execute "edit " .. a:file_path
  execute a:loc_command
  return 1
endfunction


function s:MapGetFormattedTagLineForDeletion(i, tagline)
  let l:tagparts = zettel#utils#getSplitLine(a:tagline, "\t")
  let l:taglineno = l:tagparts[0]
  let l:tagpath = zettel#utils#removeZettelRootFromPath(l:tagparts[1])
  let l:tagpath = zettel#utils#getPaddedStr(l:tagpath, 48)
  let l:tagname = zettel#utils#getPaddedStr(l:tagparts[2], 24)
  let l:lineno = zettel#utils#getPaddedStr(matchstr(l:tagparts[4], '\(\d\+\)'), 4)
  let l:filepath = l:tagparts[3]
  return l:tagname .. "  " .. l:taglineno .. "  " .. l:tagpath .. repeat(" ", 4) .. l:filepath .. repeat(" ", 4) .. l:lineno
endfunction


function s:HandleTagDeletion(taglines)
  let l:todelete = {}
  for tagline in a:taglines
    let l:parts = zettel#utils#getSplitLine(tagline, "  ")
    let l:lineno = l:parts[1]
    let l:tagfilepath = zettel#utils#getAbsolutePath(l:parts[2], 1)
    if !has_key(l:todelete, l:tagfilepath)
      let l:todelete[l:tagfilepath] = []
    endif
    call add(l:todelete[l:tagfilepath], l:lineno)
  endfor

  for key in keys(l:todelete)
    let l:linestowrite = []
    let l:i = 0
    for line in readfile(key)
      let l:i += 1
      if index(l:todelete[key], l:i .. "") == -1
        call add(l:linestowrite, line)
      endif
    endfor
    call writefile(l:linestowrite, key)
  endfor

  " TODO: Delete taglinks
endfunction



" Autoload functions called from plugin/zettel.vim
function! zettel#initialize() abort
  call mkdir(g:zettel_tags_root, "p")
  call s:LoadTagsFromTagsloc()
  call s:CreateTagFile(g:zettel_tags_unscoped_tagfile_name, {}, 0)
endfunction


" Autoload functions called by user commands
function! zettel#createNewTagFile(...) abort
  " Creates a new tagfile with given fields at given path
  " - a.000[0]  : path/to/tagfile | tagfile
  " - a.000[1:] : {fieldname}={fieldvalue}
  " eg: ['/py/pytags', 'togit=0']
  let l:stub_path_to_tagfile = a:000[0]
  let l:default_overrides = s:GetDefaultOverrides(a:000)
  call s:CreateTagFile(l:stub_path_to_tagfile, l:default_overrides)
endfunction


function! zettel#insertTag(...) abort
  " Function that inserts a tag into a tag file
  " - a.000[0]  : @path/to/tagfile | tagfile/tagname | tagname
  " - a.000[1:] : {fieldname}={fieldvalue}
  let l:tag_path = s:GetTagPath(a:000)
  let [l:tagname, l:stub_path_to_tagfile] = s:GetTagNameAndTagFileStub(l:tag_path)
  let l:position = s:GetCurrentPosition() " [line, col, filename]
  let l:default_overrides = s:GetDefaultOverrides(a:000)
  let l:tag_line = s:GetTagLine(l:tagname, l:position, l:default_overrides)
  call s:InsertTagLine(l:tag_line, l:stub_path_to_tagfile)
endfunction


function! zettel#insertTagLink() abort
  " Function that inserts a taglink at the current cursor position
  " - a.000[0] : tagfile/tagname | tagname
  call zettel#utils#throwErrorIfNoFZF()

  let l:preview_cmd = "cat -n {3}"
  if executable("bat")
    let l:preview_cmd = "bat --color=always --highlight-line={4} {3}"
  endif

  let l:tag_lines = s:GetListOfAllTags()
  call fzf#run(
    \fzf#wrap(
      \{
        \'source': map(l:tag_lines, function('s:MapGetFormattedTagLine')),
        \'options': '--no-sort --preview="echo tagname={1} tagfile={2};'.. l:preview_cmd ..'" --preview-window=up,+{4},~1 --prompt "Tag>"',
        \'sink' : function('s:HandleTagSelection')
      \}
    \)
  \)
endfunction


function! zettel#jumpToTag() abort
  call zettel#utils#throwErrorIfNoFZF()

  let l:preview_cmd = "cat -n {3}"
  if executable("bat")
    let l:preview_cmd = "bat --color=always --highlight-line={4} {3}"
  endif

  let l:tag_lines = s:GetListOfAllTags()
  call fzf#run(
    \fzf#wrap(
      \{
        \'source': map(l:tag_lines, function('s:MapGetFormattedTagLine')),
        \'options': '--no-sort --preview="echo tagname={1} tagfile={2};'.. l:preview_cmd ..'" --preview-window=up,+{4},~1 --prompt "Tag>"',
        \'sink' : function('s:HandleTagJump')
      \}
    \)
  \)
endfunction


function! zettel#deleteTag() abort
  call zettel#utils#throwErrorIfNoFZF()

  let l:preview_cmd = "cat -n {4}"
  if executable("bat")
    let l:preview_cmd = "bat --color=always --highlight-line={5} {4}"
  endif

  let l:tag_lines = s:GetListOfAllTags(1)
  call fzf#run(
    \fzf#wrap(
      \{
        \'source': map(l:tag_lines, function('s:MapGetFormattedTagLineForDeletion')),
        \'options': '--multi --no-sort --preview="echo tagname={1} tagfile={3};'.. l:preview_cmd ..'" --preview-window=up,+{5},~1 --prompt "Tag>"',
        \'sink*' : function('s:HandleTagDeletion')
      \}
    \)
  \)
endfunction