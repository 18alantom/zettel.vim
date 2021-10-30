" Filename: autoload/zettel/autoupdate.vim
" Author:   18alantom
" License:  MIT License

" Autoupdation of Tags
"
" Keeps track of logical location of a tag so that
" when it changes the references in tag and files
" can be updated.
"
" When a buffer is opened to a file load all tags
" and assign a marker (nvim: extended_mark) to them.
"
" Marker will keep track of the location. Using the
" marker the updated location of the tag can be
" obtained.
"
" When a buffer is being left or closed If the location
" has changed then writeback the new line:col to the
" respective files
"
" b:zettel_marker_dict = {
"   'tags' : {
"     'tagfile/tagname' : {
"       'pos' : [line, col] // from the tagfile
"       'marker' : marker_id // this depends on *vim
"     }
"   }
" }
let s:prop_type_name = "Zettel"


function s:AddPropType()
  if len(prop_type_get(s:prop_type_name)) == 0
    call prop_type_add(s:prop_type_name, {})
  endif
endfunction
 

function s:UpdatePropId()
  if !exists("b:zettel_prop_id")
    let b:zettel_prop_id = 1
  else
    let b:zettel_prop_id += 1
  endif
endfunction
 

function s:GetVimMarker(pos) abort
  call s:AddPropType()
  call s:UpdatePropId()

  let [l:line, l:col] = a:pos
  call prop_add(l:line, l:col, {"id":b:zettel_prop_id, "type":s:prop_type_name})
  return b:zettel_prop_id
endfunction


function s:GetPosFromVimMarker(marker) abort
  let l:options = {"id":a:marker, "type":s:prop_type_name}

  let l:prop = prop_find(l:options, "f")
  if len(l:prop) == 0
    let l:prop = prop_find(l:options, "b")
  endif

  if len(l:prop) == 0
    return []
  endif

  return [l:prop["lnum"], l:prop["col"]]
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


function s:SetMarkerDictDetails(lines, mkey)
  " Update dict with tags
  for line in a:lines
    let l:parts = zettel#utils#getSplitLine(line, "\t")

    let l:key = ""
    if a:mkey == "tags"
      let l:key = s:GetMarkerDictKeyFromTagLineParts(l:parts)
    else
      return
    endif

    if has_key(b:zettel_marker_dict[a:mkey], l:key)
      continue
    endif

    let l:pos = ""
    if a:mkey == "tags"
      let l:pos = zettel#utils#getPosFromLocCommand(l:parts[5])
    else
      return
    endif

    let l:marker = s:GetMarkerFromPos(l:pos)
    if !l:marker
      continue
    endif
    let b:zettel_marker_dict[a:mkey][l:key] = {"pos":l:pos, "marker":l:marker}
  endfor
endfunction


function s:UpdateMarkerDictWithUpdateDetails(mkey) abort
  for key in keys(b:zettel_marker_dict[a:mkey])
    let [l:oldline, l:oldcol] = b:zettel_marker_dict[a:mkey][key]["pos"]
    let l:marker = b:zettel_marker_dict[a:mkey][key]["marker"]
    let l:pos = s:GetPosFromMarker(l:marker)
    let b:zettel_marker_dict[a:mkey][key]["writeback"] = 0

    if type(l:pos) == type(0) && !l:pos
      continue
    endif

    if type(l:pos) == type([]) && len(l:pos) == 0
      continue
    endif

    let [l:line, l:col] = l:pos
    if l:oldline != l:line || (l:oldcol != l:col && l:col != 0)
      let b:zettel_marker_dict[a:mkey][key]["writeback"] = 1
      let b:zettel_marker_dict[a:mkey][key]["newpos"] = [l:line, l:col]
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
  for key in keys(b:zettel_marker_dict["tags"])
    if !b:zettel_marker_dict["tags"][key]["writeback"]
      continue
    endif

    let l:parts = split(key, "/")
    let l:stub_path_to_tagfile = join(l:parts[:-2], "/")
    let l:tagname = l:parts[-1]

    if !has_key(l:update_dict, l:stub_path_to_tagfile)
      let l:update_dict[l:stub_path_to_tagfile] = {}
    endif

    let [l:line, l:col] = b:zettel_marker_dict["tags"][key]["newpos"]
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


function s:LoadMarkerDict(abs_file_path) abort
  let l:taglines = zettel#utils#getAllTagLines({"filepath":a:abs_file_path})

  if !exists("b:zettel_marker_dict")
    let b:zettel_marker_dict = {"tags":{}}
  endif

  " Update dict with tags
  call s:SetMarkerDictDetails(l:taglines, "tags")
endfunction


function s:UpdateFilesWithMarkerDict() abort
  if !exists("b:zettel_marker_dict") || len(b:zettel_marker_dict["tags"]) == 0
    return
  endif

  call s:UpdateMarkerDictWithUpdateDetails("tags")
  let l:tagfile_update_dict = s:GetTagFileUpdateDict()
  call s:UpdateTagFile(l:tagfile_update_dict)
  unlet b:zettel_marker_dict
endfunction


function! zettel#autoupdate#loadMarkerDicts()
  let l:abs_file_path = expand("%:p")
  if len(l:abs_file_path) == 0
    return
  endif
  call s:LoadMarkerDict(l:abs_file_path)
endfunction


function! zettel#autoupdate#updateFiles()
  call s:UpdateFilesWithMarkerDict()
  if exists("b:zettel_prop_id")
    unlet b:zettel_prop_id
  endif
endfunction
