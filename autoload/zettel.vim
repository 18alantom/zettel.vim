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

if !exists("g:zettel_tags_taglink_prefix")
	let g:zettel_tags_taglink_prefix = "z://"
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
let s:taglink_pattern = '\<' .. g:zettel_tags_taglink_prefix .. '\%(\w\|[-/]\)\+'



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


function s:GetListOfAllTags() abort
  " Will return list of all taglines
  " tagline will have tagpath prepended
  let l:tags = map(split(&tags, ","), "zettel#utils#getScrubbedRelativePath(v:val)")
  let l:tags = map(l:tags, "zettel#utils#getAbsolutePath(v:val)")
  let l:tags = filter(l:tags, "filereadable(v:val)")
  let l:tags = zettel#utils#getUniqueItems(l:tags)
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
      call add(
        \l:tag_lines,
        \l:idx.. "\t" .. l:lineno .. "\t" .. abs_path_to_tagfile .. "\t" .. l:line)
      let l:idx += 1
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
  let l:tagloc_lineno = matchstr(l:taglocation, '\(\d\+\)')
  let l:filepath = l:tagparts[2]
  return l:tagname .. "  " .. l:tagpath .. repeat(" ", 4) .. l:filepath .. repeat(" ", 4) .. l:tagloc_lineno .. repeat(" ", 4) .. l:taglocation
endfunction


function s:GetTagStackUpdateDetails(tagname)
	let l:position = [bufnr()] + getcurpos()[1:]
	let l:item = {'bufnr': l:position[0], 'from': l:position, 'tagname': a:tagname}
  let l:winid = win_getid()
  let l:tagstack = gettagstack(l:winid)
  let l:tagstack['items'] = [l:item]
  return [l:winid, l:tagstack]
endfunction


function s:JumpToLocation(abs_path_to_file, loc_command) abort
  execute "edit " .. a:abs_path_to_file
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


function s:MapGetSourceLine(line)
	" Line Format
	" index \t lineno \t abs_path_to_tagfile \t tagname \t abs_path_to_file \t loc_command|;" \t field_values
  "
  " SourceLine Format
  " l:index '  ' l:tagname '  ' l:stub_path_to_tagfile '  ' l:tagloc_lineno '  ' l:abs_path_to_file
	let l:tagparts = zettel#utils#getSplitLine(a:line, "\t")
	let l:index = zettel#utils#getPaddedStr(l:tagparts[0], 4, 0)
	let l:tagname = zettel#utils#getPaddedStr(l:tagparts[3], 16)
	let l:stub_path_to_tagfile = zettel#utils#getPaddedStr(
    \zettel#utils#removeZettelRootFromPath(l:tagparts[2]), 16
	\)
  let l:tagloc_lineno = zettel#utils#getPaddedStr(
    \matchstr(l:tagparts[5], '\(\d\+\)'), 4, 0
	\)
  let l:abs_path_to_file = l:tagparts[4]

  let l:sourceline = [
    \l:index,
    \l:tagname,
    \l:stub_path_to_tagfile,
    \l:tagloc_lineno,
    \l:abs_path_to_file
	\]
  let l:delim = repeat(" ", 2)
	return join(l:sourceline, l:delim)
endfunction


function s:GetTagLinePartsFromSourceLine(tag_lines, sourceline)
  let l:delim = repeat(" ", 2)
	let l:idx = zettel#utils#getSplitLine(a:sourceline, l:delim)[0]
  return zettel#utils#getSplitLine(a:tag_lines[l:idx], "\t")
endfunction


function s:JumpToLocationAndSetTagStack(tagname, abs_path_to_file, loc_command)
  let [l:winid, l:tagstack] = s:GetTagStackUpdateDetails(a:tagname)
  let l:jump_successful = s:JumpToLocation(a:abs_path_to_file, a:loc_command)
  if l:jump_successful && &tagstack
    call settagstack(l:winid, l:tagstack, "a")
  endif
	return l:jump_successful
endfunction


function s:HandleTagJump(tag_lines, sourceline) abort
  let l:parts = s:GetTagLinePartsFromSourceLine(a:tag_lines, a:sourceline)
  let l:abs_path_to_file = l:parts[4]
  let l:tagname = l:parts[3]
  let l:loc_command = l:parts[5][:-4]
	call s:JumpToLocationAndSetTagStack(l:tagname, l:abs_path_to_file, l:loc_command)
endfunction

function s:GetFZFSourceLineHeader()
	let l:header_parts = [
		\zettel#utils#getPaddedStr("#", 4, 0),
		\zettel#utils#getPaddedStr("tagname", 16),
		\zettel#utils#getPaddedStr("tagfile", 16),
		\zettel#utils#getPaddedStr("line", 4, 0),
		\"filepath"
	\]
	let l:delim = repeat(" ", 2)
	return join(l:header_parts, l:delim)
endfunction


function s:GetTagLink(stub_path_to_tagfile, tagname)
	let l:taglink_path = join([a:stub_path_to_tagfile, a:tagname], "/")
	return g:zettel_tags_taglink_prefix .. l:taglink_path
endfunction


function s:DeleteTagLinkLineByTaglinks(taglinks)
  let l:tagslink_lines = readfile(s:tagslink_path)
  let l:lines_to_writeback = filter(l:tagslink_lines, {i,v -> index(a:taglinks, split(v, "\t")[2])==-1})
  call writefile(l:lines_to_writeback, s:tagslink_path)
endfunction


function s:HandleTagDeletion(tag_lines, sourcelines) abort
  let l:todelete = {}
  for sourceline in a:sourcelines
    let l:parts = s:GetTagLinePartsFromSourceLine(a:tag_lines, sourceline)
    let l:lineno = l:parts[1]

	  " Get Taglink
    let l:abs_path_to_tagfile = l:parts[2]
	  let l:tagname = l:parts[3]
	  let l:stub_path_to_tagfile = zettel#utils#removeZettelRootFromPath(l:abs_path_to_tagfile)
	  let l:taglink = s:GetTagLink(l:stub_path_to_tagfile, l:tagname)

    if !has_key(l:todelete, l:abs_path_to_tagfile)
      let l:todelete[l:abs_path_to_tagfile] = []
    endif

    call add(l:todelete[l:abs_path_to_tagfile], [l:lineno, l:taglink])
  endfor

	let l:all_taglinks = []
  for key in keys(l:todelete)
	  let l:details = l:todelete[key]
    let l:linenos = map(copy(l:details), {i,v -> v[0]})
    let l:taglinks = map(l:details, {i,v -> v[1]})
	  call extend(l:all_taglinks, l:taglinks)

    let l:lines_to_writeback = []
    let l:i = 0
    for line in readfile(key)
      let l:i += 1
      if index(l:linenos, l:i .. "") == -1
        call add(l:lines_to_writeback, line)
      endif
    endfor
    call writefile(l:lines_to_writeback, key)
  endfor

	let l:all_taglinks = zettel#utils#getUniqueItems(l:all_taglinks)
  call s:DeleteTagLinkLineByTaglinks(l:all_taglinks)
endfunction


function s:GetFormattedTagLink(taglink)
	" Probably change this if markdown file
	return a:taglink
endfunction


function s:InsertTagLink(taglink)
	execute "normal! a" .. a:taglink .. "\<ESC>"
endfunction


function s:InsertTagLinkIntoLinkFile(taglink)
  " format: 'abs_path_to_file_with_taglink {TAB} line:col {TAB} taglink
  let [l:line, l:col, l:filepath] = s:GetCurrentPosition() " [line, col, filename]
  let l:cursor_pos = l:line .. ":" .. l:col
	let l:linkline = join([l:filepath, l:cursor_pos, a:taglink], "\t")
  call writefile([l:linkline], s:tagslink_path, "a")
endfunction


function s:HandleTagLinkInsertion(tag_lines, sourceline) abort
  " Sink function for fzf, this will insert the tagline
  " insert tag into file
  " insert tag into taglink file
  let l:parts = s:GetTagLinePartsFromSourceLine(a:tag_lines, a:sourceline)
	let l:tagname = l:parts[3]
	let l:abs_path_to_tagfile = l:parts[2]
	let l:stub_path_to_tagfile = zettel#utils#removeZettelRootFromPath(l:abs_path_to_tagfile)
	let l:taglink = s:GetTagLink(l:stub_path_to_tagfile, l:tagname)
	let l:taglink = s:GetFormattedTagLink(l:taglink)
	call s:InsertTagLink(l:taglink)
  call s:InsertTagLinkIntoLinkFile(l:taglink)
endfunction


function s:RunFZFToDisplayTags(source, Sink, is_sinklist=0)
  call zettel#utils#throwErrorIfNoFZF()
  let l:preview_cmd = "cat -n {5}"
  if executable("bat")
    let l:preview_cmd = "bat --color=always --highlight-line={4} {5}"
  endif
	let l:header = s:GetFZFSourceLineHeader()
	let l:options = ['--no-sort',
    \'--nth=1,2,3',
    \'--multi',
		\'--preview="' .. l:preview_cmd .. '"',
		\'--preview-window=up,+{4}',
		\'--header="' .. l:header .. '"',
		\'--prompt "Tag> "'
	\]

	let l:fzf_kwargs = {
		\'source': a:source,
		\'options' : join(l:options, " ")
	\}

	if a:is_sinklist
		let l:fzf_kwargs['sink*'] = a:Sink
	else
		let l:fzf_kwargs['sink'] = a:Sink
	endif

  call fzf#run(fzf#wrap(l:fzf_kwargs))
endfunction


function s:HandleJumpToTaglink(taglink_line)
	let l:parts = zettel#utils#getSplitLine(a:taglink_line, "\t")
	let l:abs_path_to_file = l:parts[0]
	let l:loc_command = "call cursor("..join(split(l:parts[1], ":"), ",")..")"
	call s:JumpToLocation(l:abs_path_to_file, l:loc_command)
endfunction


function s:GetTagLinkMatches(line)
  let taglink_matches = []
  call substitute(a:line, s:taglink_pattern, '\=add(taglink_matches, submatch(0))', 'g')
  return taglink_matches
endfunction


function s:DestructureTagLink(taglink)
  let l:tagpath = a:taglink[len(g:zettel_tags_taglink_prefix):]
  let l:parts = split(l:tagpath, "/")
  let l:tagname = l:parts[-1]
  let l:stub_path_to_tagfile = join(l:parts[:-2], "/")
	return [l:stub_path_to_tagfile, l:tagname]
endfunction


function s:GetTagLineFromTagFile(stub_path_to_tagfile, tagname) abort
	let l:abs_path_to_tagfile = zettel#utils#getAbsolutePath(a:stub_path_to_tagfile, 1)
	let l:lines = reverse(readfile(l:abs_path_to_tagfile))
	for line in l:lines
		if split(line, "\t")[0] == a:tagname
			return line
		endif
	endfor
	return ""
endfunction


function s:GetJumpLocationFromTagLine(tagline)
	let l:parts = split(a:tagline, "\t")
	return [l:parts[1], l:parts[2]]
endfunction


function s:JumpFromTagLink(taglink) abort
	let [l:stub_path_to_tagfile, l:tagname] = s:DestructureTagLink(a:taglink)
	let l:tagline = s:GetTagLineFromTagFile(l:stub_path_to_tagfile, l:tagname)
	let [l:abs_path_to_file, l:loc_command] = s:GetJumpLocationFromTagLine(l:tagline)
	return s:JumpToLocationAndSetTagStack(l:tagname, l:abs_path_to_file, l:loc_command)
endfunction



" Autoload functions to be called in plugin/zettel.vim
function! zettel#initialize() abort
  call mkdir(g:zettel_tags_root, "p")
  call s:LoadTagsFromTagsloc()
  call s:CreateTagFile(g:zettel_tags_unscoped_tagfile_name, {}, 0)
endfunction


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


function! zettel#jumpToTag() abort
  let l:tag_lines = s:GetListOfAllTags()
  let l:source = map(copy(l:tag_lines), "s:MapGetSourceLine(v:val)")
  let l:Sink = function("s:HandleTagJump", [l:tag_lines])
	call s:RunFZFToDisplayTags(l:source, l:Sink, 0)
	return
endfunction


function! zettel#insertTagLink() abort
  let l:tag_lines = s:GetListOfAllTags()
  let l:source = map(copy(l:tag_lines), "s:MapGetSourceLine(v:val)")
  let l:Sink = function("s:HandleTagLinkInsertion", [l:tag_lines])
	call s:RunFZFToDisplayTags(l:source, l:Sink, 0)
endfunction


function! zettel#deleteTag() abort
  let l:tag_lines = s:GetListOfAllTags()
  let l:source = map(copy(l:tag_lines), "s:MapGetSourceLine(v:val)")
  let l:Sink = function("s:HandleTagDeletion", [l:tag_lines])
	call s:RunFZFToDisplayTags(l:source, l:Sink, 1)
endfunction


function! zettel#listTagLinks() abort
	let l:taglink_lines = readfile(s:tagslink_path)
	call fzf#run(fzf#wrap({"source":l:taglink_lines, "sink": function("s:HandleJumpToTaglink")}))
endfunction


function! zettel#tagLinkJump() abort
  let l:line = getline(".")
  let l:col = getpos(".")[2]
  let l:matches = s:GetTagLinkMatches(l:line)
  if len(l:matches) == 0
    return 0
  endif
  let l:match_positions = []

  " Get start and end index of the taglinks.
  for m in l:matches
    call add(l:match_positions, matchstrpos(l:line, m))
  endfor

  " Select taglink with cursor in it.
  let l:selected_taglink = filter(
    \copy(l:match_positions),
    \{i,v-> v[1]<= l:col && v[2] >= l:col}
  \)

  " Select the closest if none
  if len(l:selected_taglink) == 0
    let l:start_dist = map(
      \copy(l:match_positions),
      \{i,v-> v[1] - l:col}
    \)
    let l:ix = index(
      \l:start_dist,
      \min(l:start_dist)
    \)
    let l:selected_taglink = l:match_positions[l:ix][0]
  else
    let l:selected_taglink = l:selected_taglink[0][0]
  endif
  return s:JumpFromTagLink(l:selected_taglink)
endfunction
