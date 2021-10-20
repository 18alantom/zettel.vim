" Filename: autoload/zettel/autoupdate.vim
" Author:   18alantom
" License:  MIT License

" Autoupdation of Tags & Taglinks
"
" Keeps track of logical location of a tag | taglink
" so that when it changes the references in tag and
" taglink files can be updated.
"
" When a buffer is opened to a file load all tags,
" taglinks and assign a marker (nvim: extended_mark)
" to them.
"
" Marker will keep track of the location. Using the
" marker the updated location of the tag | taglink
" can be obtained.
"
" When a buffer is being left or closed If the location
" has changed then writeback the new line:col to the
" respective files
"
" b:zettel_tag_marker_dict = {
"   'tagfile/tagname' : {
"     'pos' : [line, col] // from the tagfile
"     'marker' : // this depends on whether neovim or vim
"   }
" }
 
 
function s:GetVimMarker(pos) abort
  " TODO: Complete this using text-properties
  return 0
endfunction

function s:GetPosFromVimMarker(marker) abort
  " TODO: Complete this
  return [0,0]
endfunction

function s:GetNamespace()
  return nvim_create_namespace("zettel")
endfunction

function s:GetNeoVimMarker(pos) abort
  let l:namespace = s:GetNamespace()
  let [l:line, l:col] = a:pos
  let l:opts = {}

  " Treesitter bug: E5555: API call: col value outside range
  try
    let l:marker = nvim_buf_set_extmark(0, l:namespace, l:line, l:col, l:opts)
  catch /E5555:/
    let l:marker = nvim_buf_set_extmark(0, l:namespace, l:line, 0, l:opts)
  endtry

  return l:marker
endfunction

function s:GetPosFromNeoVimMarker(marker) abort
  let l:namespace = s:GetNamespace()
  let l:opts = {}
  " Returns [] if no ext-mark found
  let l:pos = nvim_buf_get_extmark_by_id(0, l:namespace, a:marker, l:opts)
  return l:pos
endfunction

function s:GetMarkerFromPos(pos) abort
  if has("nvim")
    return s:GetNeoVimMarker(a:pos)
  else
    return s:GetVimMarker(a:pos)
endfunction

function s:GetPosFromMarker(marker) abort
  if has("nvim")
    return s:GetPosFromNeoVimMarker(a:marker)
  else
    return s:GetPosFromVimMarker(a:marker)
endfunction

function s:GetMarkerDictKeyFromTagLineParts(parts)
  let l:stub_path_to_tagfile = zettel#utils#removeZettelRootFromPath(a:parts[2])
  let l:tagname = a:parts[3]
  return l:stub_path_to_tagfile .. "/" .. l:tagname
endfunction

function s:SetMarkerDict(taglines) abort
  " echo 'setting the tagmarker dict'
  if !exists("b:zettel_tag_marker_dict")
    let b:zettel_tag_marker_dict = {}
  endif
  for line in a:taglines
    let l:parts = zettel#utils#getSplitLine(line, "\t")
    let l:key = s:GetMarkerDictKeyFromTagLineParts(l:parts)

    if has_key(b:zettel_tag_marker_dict, l:key)
      continue
    endif

    let l:pos = zettel#utils#getPosFromLocCommand(l:parts[5])
    let l:marker = s:GetMarkerFromPos(l:pos)

    if !l:marker
      continue
    endif
    let b:zettel_tag_marker_dict[l:key] = {'pos':l:pos, 'marker':l:marker}
  endfor
endfunction

function s:UpdateMarkerDictWithUpdateDetails() abort
  for key in keys(b:zettel_tag_marker_dict)
    let [l:oldline, l:oldcol] = b:zettel_tag_marker_dict[key]["pos"]
    let l:marker = b:zettel_tag_marker_dict[key]["marker"]
    let l:pos = s:GetPosFromMarker(l:marker)
    let b:zettel_tag_marker_dict[key]["writeback"] = 0
    call writefile([string(["128", key, [l:oldline, l:oldcol], l:pos])], "/Users/alan/Desktop/vimp/debug.txt", "a")

    if type(l:pos) == type(0) && !l:pos
      continue
    endif

    if type(l:pos) == type([]) && len(l:pos) == 0
      continue
    endif

    let [l:line, l:col] = l:pos
    if l:oldline != l:line || (l:oldcol != l:col && l:col != 0)
      let b:zettel_tag_marker_dict[key]["writeback"] = 1
      let b:zettel_tag_marker_dict[key]["newpos"] = [l:line, l:col]
    endif
  endfor
endfunction

function s:GetTagFileUpdateDict() abort
  " grouped by tagfile
  "
  " l:update_dict = {
  "   'tagfile_0' : {
  "     'tagname_0': [newline_0, newcol_0],
  "     'tagname_1': [newline_1, newcol_1],
  "     ...
  "   },
  "   ...
  " }
  let l:update_dict = {}
  for key in keys(b:zettel_tag_marker_dict)
    if !b:zettel_tag_marker_dict[key]["writeback"]
      continue
    endif

    let l:parts = split(key, "/")
    let l:stub_path_to_tagfile = join(l:parts[:-2], "/")
    let l:tagname = l:parts[-1]

    if !has_key(l:update_dict, l:stub_path_to_tagfile)
      let l:update_dict[l:stub_path_to_tagfile] = {}
    endif

    let [l:line, l:col] = b:zettel_tag_marker_dict[key]["newpos"]
    let l:update_dict[l:stub_path_to_tagfile][l:tagname] = [l:line, l:col]
  endfor

  return l:update_dict
endfunction

function s:UpdateTagFile(update_dict) abort
  let l:header_suffix = "!_TAG_"
  let l:suffix_len = len(l:header_suffix)

  for key in keys(a:update_dict)
    let l:lines_to_writeback = []
    let l:abs_path_to_tagfile = zettel#utils#getAbsolutePath(key, 1)
    if !file_readable(l:abs_path_to_tagfile)
      continue
    endif

    for line in readfile(l:abs_path_to_tagfile)
      if len(line) == 0
        continue
      endif

      if line[:l:suffix_len - 1] == l:header_suffix
        call add(l:lines_to_writeback, line)
        continue
      endif

      " {tagname} \t {filepath} \t {loc_command} \t {fieldvalues ...}
      let l:parts = zettel#utils#getSplitLine(line, "\t")
      let l:tagname = l:parts[0]
      if !has_key(a:update_dict[key], l:tagname)
        call add(l:lines_to_writeback, line)
      else
        let [l:line, l:col] = a:update_dict[key][l:tagname]
        let l:loc_command = zettel#utils#getLocCommand(l:line, l:col)
        let l:updated_line = join([l:tagname, l:parts[1], l:loc_command] + l:parts[3:], "\t")
        call add(l:lines_to_writeback, l:updated_line)
      endif
    endfor

    call writefile(l:lines_to_writeback, l:abs_path_to_tagfile)
  endfor
endfunction

function s:LoadTagMarkerDict() abort
  let l:abs_file_path = expand("%:p")
  if len(l:abs_file_path) == 0
    return
  endif

  let l:taglines = zettel#utils#getAllTagLines({"filepath":l:abs_file_path})
  call s:SetMarkerDict(taglines)
endfunction

function s:UpdateTagFilesWithTagMarkerDict() abort
  if !exists("b:zettel_tag_marker_dict") || len(b:zettel_tag_marker_dict) == 0
    return
  endif
  " on closing a buffer writeback all the changes
  call s:UpdateMarkerDictWithUpdateDetails()
  let l:update_dict = s:GetTagFileUpdateDict()
  call s:UpdateTagFile(l:update_dict)
  unlet b:zettel_tag_marker_dict
endfunction


" TagLink Autoupdation
"
function s:LoadTagLinkMarkerDict() abort
  " create and maintain a taglink marker dict for all taglinks in the file
endfunction

function s:UpdateTagLinkFilesWithTagLinkMarkerDict()
  " on closing a buffer writeback all the changes
endfunction



" Autoload functions
function! zettel#autoupdate#loadMarkerDicts()
  call s:LoadTagMarkerDict()
  call s:LoadTagLinkMarkerDict()
endfunction

function! zettel#autoupdate#updateFiles()
  call s:UpdateTagFilesWithTagMarkerDict()
  call s:UpdateTagLinkFilesWithTagLinkMarkerDict()
endfunction
