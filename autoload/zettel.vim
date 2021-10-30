" Filename: autoload/zettel.vim
" Author:   18alantom
" License:  MIT License

let s:plugin_name = "zettel.vim"

" Initialize Global Variables
if !exists("g:zettel_root")
  let s:home = getenv("HOME")
  if s:home == v:null
    echoerr s:plugin_name . " : Please set $HOME or g:zettel_root."
  endif

  let g:zettel_root = s:home . "/.zettel"
endif

if !exists("g:zettel_unscoped_tagfile_name")
  let g:zettel_unscoped_tagfile_name = "tags"
endif

if !exists("g:zettel_default_field_togit")
  let g:zettel_default_field_togit = 1
endif

if !exists("g:zettel_taglink_prefix")
	let g:zettel_taglink_prefix = "z://"
endif

if !exists("g:zettel_confirm_before_overwrite")
	let g:zettel_confirm_before_overwrite = 0
endif


" Tag Headers and Meta Data
let s:field_defaults = {
  \"togit" : g:zettel_default_field_togit
\}

let s:tag_file_headers = [
  \"!_TAG_FILE_FORMAT	2	/{field} will be used to additional info/",
  \"!_TAG_FILE_SORTED	1",
  \"!_TAG_PROGRAM_AUTHOR	Alan	/github.com/18alantom/",
  \"!_TAG_PROGRAM_NAME zettel.vim",
  \"!_TAG_PROGRAM_URL	https://github.com/18alantom/vim-zettel /source code/",
\]

let s:tagsloc_path = g:zettel_root . "/" . "tagsloc.txt"
let g:zettel_tagslink_path = g:zettel_root . "/" . "tagslink.txt"
let g:zettel_taglinkcache_path = g:zettel_root .. "/" .. ".taglinks.txt"


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
  " g:zettel_root add its absolute path to &tags, tagloc.txt
  " and return it.
  "
  " stub_path_to_tagfile
  " - path stub to the tag file; g:zettel_root will be
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
    echoerr s:plugin_name . " : Current buffer has not been written to a file."
  else
    return [l:line, l:col, l:abs_file_path]
  endif
endfunction


function s:GetTagLineByTagNameAndTagFile(tagname, stub_path_to_tagfile)
  return zettel#utils#getAllTagLines({"tagfile": a:stub_path_to_tagfile, "tagname": a:tagname})
endfunction


function s:InsertTagLine(tagname, tag_line, stub_path_to_tagfile) abort
  " Will create tagfile if it doesn't exist
  let l:abs_path_to_tagfile = s:CreateTagFile(a:stub_path_to_tagfile, {}, 0)

  " Check existing
  let l:existing_taglines = s:GetTagLineByTagNameAndTagFile(a:tagname, a:stub_path_to_tagfile)
  if len(l:existing_taglines) > 0
    let l:parts = zettel#utils#getSplitLine(l:existing_taglines[0], "\t")
    let l:choice = 1
    if g:zettel_confirm_before_overwrite
      let l:message = s:plugin_name .. " : Tag '" ..
        \a:stub_path_to_tagfile .. "/" .. a:tagname .. "'" ..
        \" is already present \nfor '" .. l:parts[4] .. "' \n" ..
        \"overwrite tag?"
      let l:choice = confirm(l:message, "&yes\n&no")
    endif

    if l:choice == 2
      echo s:plugin_name .. " : Tag wasn't saved because of duplicate."
      return
    endif

    " Remove duplicate lines
    let l:lines_to_writeback = []
    let l:linesno_to_ignore = map(l:existing_taglines, {i,v -> split(v, "\t")[1] + 0})
    let l:ix = 0
    for line in readfile(l:abs_path_to_tagfile)
      let l:ix += 1
      if index(l:linesno_to_ignore, l:ix) == -1
        call add(l:lines_to_writeback, line)
      endif
    endfor
    call writefile(l:lines_to_writeback, l:abs_path_to_tagfile)
  endif

  call writefile([a:tag_line], l:abs_path_to_tagfile, "a")
endfunction


function s:GetTagLine(tagname, position, default_overrides) abort
  let [l:line, l:col, l:abs_file_path] = a:position
  " tagname {TAB} file path {TAB} tagaddress|;" {field}
  let l:loc_command = zettel#utils#getLocCommand(l:line, l:col)
  let l:tagline = join([a:tagname, l:abs_file_path, l:loc_command], "\t")

  for k in keys(a:default_overrides)
    let l:field = k . ":" . a:default_overrides[k]
    let l:tagline = join([l:tagline, l:field], "\t")
  endfor

  return l:tagline . "\n"
endfunction


function s:GetTagNameAndTagFileStub(tag_path)
  let l:tagname = getline(".")
  let l:stub_path_to_tagfile = g:zettel_unscoped_tagfile_name

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
  if expand("%:p") != a:abs_path_to_file
    execute "edit " .. a:abs_path_to_file
  endif
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


function s:MapGetTagLinkSourceLine(tagline)
  let l:parts = zettel#utils#getSplitLine(a:tagline, "\t")
  let l:path = zettel#utils#getPaddedStr(l:parts[0], 62)
  let [l:line, l:col] = split(l:parts[1], ":")
  let l:line = zettel#utils#getPaddedStr(l:line, 5, 0)
  let l:col = zettel#utils#getPaddedStr(l:col, 5, 0)
  return join([l:path, l:line, l:col], repeat(" ", 2))
endfunction




function s:GetTagLinePartsFromSourceLine(tag_lines, sourceline) abort
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
	return g:zettel_taglink_prefix .. l:taglink_path
endfunction


function s:DeleteTagLinkLineByTaglinksFromCache(taglinks) abort
  let l:tagslink_lines = readfile(g:zettel_taglinkcache_path)
  let l:lines_to_writeback = filter(l:tagslink_lines, {i,v -> index(a:taglinks, split(v, "\t")[2])==-1})
  call writefile(l:lines_to_writeback, g:zettel_taglinkcache_path)
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
  call s:DeleteTagLinkLineByTaglinksFromCache(l:all_taglinks)
endfunction


function s:InsertTagLink(taglink)
	execute "normal! a" .. a:taglink .. "\<ESC>"
endfunction


function s:HandleTagLinkInsertion(tag_lines, sourceline) abort
  " Sink function for fzf, this will insert the tagline
  " insert tag into file
  " insert tag into taglink file
  let l:abs_path_to_file = expand("%:p")
  if l:abs_path_to_file == ""
    echoerr s:plugin_name . " : Current buffer has not been written to a file."
  endif

  let l:parts = s:GetTagLinePartsFromSourceLine(a:tag_lines, a:sourceline)
	let l:tagname = l:parts[3]
	let l:abs_path_to_tagfile = l:parts[2]
	let l:stub_path_to_tagfile = zettel#utils#removeZettelRootFromPath(l:abs_path_to_tagfile)
	let l:taglink = s:GetTagLink(l:stub_path_to_tagfile, l:tagname)

	call s:InsertTagLink(l:taglink)
  call zettel#taglinks#updateTagLinkLoc(l:abs_path_to_file)
endfunction


function s:RunFZFToDisplayTags(source, Sink, is_sinklist=0, is_multi=0) abort
  call zettel#utils#throwErrorIfNoFZF()
  let l:preview_cmd = "cat -n {5}"
  if executable("bat")
    let l:preview_cmd = "bat --color=always --highlight-line={4} {5}"
  endif
	let l:header = s:GetFZFSourceLineHeader()
	let l:options = ['--no-sort',
    \'--nth=1,2,3',
		\'--preview="' .. l:preview_cmd .. '"',
		\'--preview-window=up,+{4}',
		\'--header="' .. l:header .. '"',
		\'--prompt "Tag> "'
	\]

  if a:is_multi
    call add(l:options, '--multi')
  endif

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


function s:GetFZFTagLinkSourceLineHeader()
	let l:header_parts = [
		\zettel#utils#getPaddedStr("filepath", 62),
		\zettel#utils#getPaddedStr("line", 5, 0),
		\zettel#utils#getPaddedStr("col", 5, 0),
	\]
	let l:delim = repeat(" ", 2)
	return join(l:header_parts, l:delim)
endfunction


function s:RunFZFToDisplayTagLinks(source, Sink, is_sinklist=0) abort
  call zettel#utils#throwErrorIfNoFZF()
  let l:preview_cmd = "cat -n {1}"
  if executable("bat")
    let l:preview_cmd = "bat --color=always --highlight-line={2} {1}"
  endif
	let l:header = s:GetFZFTagLinkSourceLineHeader()
	let l:options = ['--no-sort',
    \'--nth=1,2,3',
		\'--preview="' .. l:preview_cmd .. '"',
		\'--preview-window=up,+{2}',
		\'--header="' .. l:header .. '"',
		\'--prompt "TagLink> "'
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


function s:HandleJumpToTaglink(taglink_sourceline) abort
	let l:parts = zettel#utils#getSplitLine(a:taglink_sourceline, repeat(" ", 2))
	let l:abs_path_to_file = l:parts[0]
  let l:line = l:parts[1]
  let l:col = l:parts[2]
  let l:loc_command = zettel#utils#getLocCommand(l:line, l:col)
	call s:JumpToLocation(l:abs_path_to_file, l:loc_command)
endfunction


function s:DestructureTagLink(taglink) abort
  let l:tagpath = a:taglink[len(g:zettel_taglink_prefix):]
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


function s:GetJumpLocationFromTagLine(tagline) abort
	let l:parts = split(a:tagline, "\t")
	return [l:parts[1], l:parts[2]]
endfunction


function s:JumpFromTagLink(taglink) abort
	let [l:stub_path_to_tagfile, l:tagname] = s:DestructureTagLink(a:taglink)
	let l:tagline = s:GetTagLineFromTagFile(l:stub_path_to_tagfile, l:tagname)
  if len(l:tagline) == 0
    echoerr s:plugin_name .. " : Tag pointed to by '" .. a:taglink .. "' has been deleted."
    return 2
  endif

	let [l:abs_path_to_file, l:loc_command] = s:GetJumpLocationFromTagLine(l:tagline)
	return s:JumpToLocationAndSetTagStack(l:tagname, l:abs_path_to_file, l:loc_command)
endfunction


function s:GetTagLinkFromSourceLine(sourceline) abort
  let l:parts = zettel#utils#getSplitLine(a:sourceline, "  ")
  let l:stub_path_to_tagfile = zettel#utils#removeZettelRootFromPath(l:parts[2])
  let l:taglink = s:GetTagLink(l:stub_path_to_tagfile, l:parts[1])
  return l:taglink
endfunction


function s:HandleTagSelectionToListTagLinks(sourceline) abort
  let l:taglink = s:GetTagLinkFromSourceLine(a:sourceline)
  let l:taglink_lines = zettel#taglinks#getAllTagLinkLines({"taglink":l:taglink})
  let l:source = map(l:taglink_lines, "s:MapGetTagLinkSourceLine(v:val)")
  let l:Sink = function("s:HandleJumpToTaglink")
  call s:RunFZFToDisplayTagLinks(l:source, l:Sink, 0)
endfunction


function s:SetCountDictKey(count_dict, key)
  if !has_key(a:count_dict, a:key)
    let a:count_dict[a:key] = {"tags":0, "taglinks":0}
  endif
endfunction


function s:GetTagFileDeletionSourceLine()
  let l:tag_lines = zettel#utils#getAllTagLines()
  let l:taglink_lines = zettel#taglinks#getAllTagLinkLines()
  let l:tagfiles = zettel#utils#getTagFiles()

  " Initialize count dict
  let l:count_dict = {}
  for tf in l:tagfiles
    let l:tf = zettel#utils#removeZettelRootFromPath(tf)
    call s:SetCountDictKey(l:count_dict, l:tf)
  endfor

  " Set the tag counts
  for tl in l:tag_lines
    let l:tf = zettel#utils#getSplitLine(tl, "\t")[2]
    let l:tf = zettel#utils#removeZettelRootFromPath(l:tf)
    call s:SetCountDictKey(l:count_dict, l:tf)
    let l:count_dict[l:tf]["tags"] += 1
  endfor

  " Set the taglink counts
  for tll in l:taglink_lines
    let l:taglink = zettel#utils#getSplitLine(tll, "\t")[2]
    let l:taglink = l:taglink[len(g:zettel_taglink_prefix):]
    let l:tf = join(split(l:taglink, "/")[:-2], "/")
    call s:SetCountDictKey(l:count_dict, l:tf)
    let l:count_dict[l:tf]["taglinks"] += 1
  endfor

  let l:sourcelines = []
  for tf in keys(l:count_dict)
    let l:tc = zettel#utils#getPaddedStr(l:count_dict[tf]["tags"], 5, 0)
    let l:tlc = zettel#utils#getPaddedStr(l:count_dict[tf]["taglinks"], 8, 0)
    let l:tf = zettel#utils#getPaddedStr(tf, 48)
    let l:sourceline = join([l:tf, l:tc, l:tlc], repeat(" ", 2))
    call add(l:sourcelines, l:sourceline)
  endfor
  unlet l:count_dict
  return l:sourcelines
endfunction


function s:HandleTagFileDeletion(sourcelines)
  let l:tagfiles = map(a:sourcelines, {i,v -> zettel#utils#getSplitLine(v:val, repeat(' ', 2))[0]})
  let l:tagfiles = map(l:tagfiles, "zettel#utils#getAbsolutePath(v:val, 1)")

  let l:lines_to_writeback = []
  for line in readfile(s:tagsloc_path)
    if index(l:tagfiles, line) == -1
      call add(l:lines_to_writeback, line)
    endif
  endfor

  for tagfile in l:tagfiles
    call delete(tagfile)
  endfor

  call writefile(l:lines_to_writeback, s:tagsloc_path)
  call s:LoadTagsFromTagsloc()

  " No need to regenerate TagLinkCache, taglinks pointing to the
  " deleted tags are not removed (by design) the the cache will
  " remain the same.
  "
  " Dead references will have to manually be removed.
  "
  " call zettel#taglinks#regenerateTagLinkCache()
endfunction


function s:IntializeAutoupdate() abort
  augroup zettel_autoupdate_tags
    " default fzf is vsplit, tab split, split, e
    autocmd BufEnter * call zettel#autoupdate#loadMarkerDicts()
    autocmd BufLeave,BufUnload * call zettel#autoupdate#updateFiles()
  augroup END
endfunction


" Autoload functions to be called in plugin/zettel.vim
function! zettel#initialize() abort
  call mkdir(g:zettel_root, "p")
  call s:LoadTagsFromTagsloc()
  call s:CreateTagFile(g:zettel_unscoped_tagfile_name, {}, 0)
  call s:IntializeAutoupdate()
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
  call zettel#autoupdate#updateFiles()
  let l:tag_path = s:GetTagPath(a:000)
  let [l:tagname, l:stub_path_to_tagfile] = s:GetTagNameAndTagFileStub(l:tag_path)
  let l:position = s:GetCurrentPosition() " [line, col, filename]
  let l:default_overrides = s:GetDefaultOverrides(a:000)
  let l:tag_line = s:GetTagLine(l:tagname, l:position, l:default_overrides)
  call s:InsertTagLine(l:tagname, l:tag_line, l:stub_path_to_tagfile)
  call zettel#autoupdate#loadMarkerDicts()
endfunction


function! zettel#listTags(in_this_file, ...) abort
  call zettel#autoupdate#updateFiles()

  let l:filters = {}
  if a:in_this_file
    let l:filters = {"filepath": expand("%:p")}
  endif
  let l:filters["tagfile"] = a:000
  
  let l:tag_lines = zettel#utils#getAllTagLines(l:filters)
  let l:source = map(copy(l:tag_lines), "s:MapGetSourceLine(v:val)")
  let l:Sink = function("s:HandleTagJump", [l:tag_lines])
	call s:RunFZFToDisplayTags(l:source, l:Sink, 0)
  call zettel#autoupdate#loadMarkerDicts()
endfunction


function! zettel#insertTagLink() abort
  call zettel#autoupdate#updateFiles()
  let l:tag_lines = zettel#utils#getAllTagLines()
  let l:source = map(copy(l:tag_lines), "s:MapGetSourceLine(v:val)")
  let l:Sink = function("s:HandleTagLinkInsertion", [l:tag_lines])
	call s:RunFZFToDisplayTags(l:source, l:Sink, 0)
  call zettel#autoupdate#loadMarkerDicts()
endfunction


function! zettel#deleteTag(...) abort
  call zettel#autoupdate#updateFiles()
  let l:tag_lines = zettel#utils#getAllTagLines({"tagfile":a:000})
  let l:source = map(copy(l:tag_lines), "s:MapGetSourceLine(v:val)")
  let l:Sink = function("s:HandleTagDeletion", [l:tag_lines])
	call s:RunFZFToDisplayTags(l:source, l:Sink, 1, 1)
  call zettel#autoupdate#loadMarkerDicts()
endfunction


function! zettel#listTagLinks(in_this_file=0) abort
  call zettel#autoupdate#updateFiles()

  let l:filters = {}
  if a:in_this_file
    let l:filters = {"filepath": expand("%:p")}
  endif

	let l:taglink_lines = zettel#taglinks#getAllTagLinkLines(l:filters)
  let l:source = map(l:taglink_lines, "s:MapGetTagLinkSourceLine(v:val)")
  let l:Sink = function("s:HandleJumpToTaglink")
  call s:RunFZFToDisplayTagLinks(l:source, l:Sink, 0)
  call zettel#autoupdate#loadMarkerDicts()
endfunction


function! zettel#tagLinkJump() abort
  call zettel#autoupdate#updateFiles()
  let l:line = getline(".")
  let l:col = getpos(".")[2]
  let l:matches = zettel#taglinks#getTagLinkMatches(l:line)
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
  call zettel#autoupdate#loadMarkerDicts()
  return s:JumpFromTagLink(l:selected_taglink)
endfunction


function! zettel#listTagLinksToATag(...) abort
  call zettel#autoupdate#updateFiles()
  let l:tag_lines = zettel#utils#getAllTagLines({"tagfile":a:000})
  let l:source = map(copy(l:tag_lines), "s:MapGetSourceLine(v:val)")
  let l:Sink = function("s:HandleTagSelectionToListTagLinks")
	call s:RunFZFToDisplayTags(l:source, l:Sink, 0)
  call zettel#autoupdate#loadMarkerDicts()
endfunction


function! zettel#deleteTagFile() abort
  call zettel#autoupdate#updateFiles()
  let l:source = s:GetTagFileDeletionSourceLine()
	let l:header_parts = [
		\zettel#utils#getPaddedStr("tagfile", 48),
		\zettel#utils#getPaddedStr("tags", 5, 0),
		\zettel#utils#getPaddedStr("taglinks", 8, 0),
	\]
	let l:delim = repeat(" ", 2)
	let l:header = join(l:header_parts, repeat(" ", 2))
	let l:options = ['--no-sort --multi',
    \'--nth=1',
	  \'--header="' .. l:header .. '"',
	  \'--prompt "TagFile> "'
	\]

	let l:fzf_kwargs = {
	  \'source': l:source,
	  \'options': join(l:options, " "),
    \'sink*': function("s:HandleTagFileDeletion")
	\}
  call fzf#run(fzf#wrap(l:fzf_kwargs))
  call zettel#autoupdate#loadMarkerDicts()
endfunction
