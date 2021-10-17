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
"
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
  let l:pos = nvim_buf_get_extmark_by_id(0, l:namespace, a:marker, l:opts)
  if len(l:pos) == 0
    return [0, 0]
  endif
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

function s:GetPosFromLocCommand(loc_command)
  " loc_command format: 'call cursor(line,col)|;"'
  let l:pos = split(a:loc_command[12:-5], ",")
  let l:pos = map(l:pos, {i,v -> v + 0}) " Cast to number
  return l:pos
endfunction

function s:GetMarkerDictKeyFromTagLineParts(parts)
  let l:stub_path_to_tagfile = zettel#utils#removeZettelRootFromPath(a:parts[2])
  let l:tagname = a:parts[3]
  return l:stub_path_to_tagfile .. "/" .. l:tagname
endfunction

function s:SetMarkerDict(taglines) abort
  echo "setting the tagmarker dict"
  if !exists("b:zettel_tag_marker_dict")
    let b:zettel_tag_marker_dict = {}
  endif
  for line in a:taglines
    let l:parts = zettel#utils#getSplitLine(line, "\t")
    let l:key = s:GetMarkerDictKeyFromTagLineParts(l:parts)

    if has_key(b:zettel_tag_marker_dict, l:key)
      continue
    endif

    let l:pos = s:GetPosFromLocCommand(l:parts[5])
    let l:marker = s:GetMarkerFromPos(l:pos)

    if !l:marker
      continue
    endif
    let b:zettel_tag_marker_dict[l:key] = {'pos':l:pos, 'marker':l:marker}
  endfor
endfunction

function! zettel#autoupdate#createTagMarkerDict() abort
  let l:abs_file_path = expand("%:p")
  if len(l:abs_file_path) == 0
    return
  endif

  let l:taglines = zettel#utils#getAllTagLines({"filepath":l:abs_file_path})
  call s:SetMarkerDict(taglines)
endfunction

function! zettel#autoupdate#updateTagFilesWithTagMarkerDict()
  " on closing a buffer writeback all the changes
endfunction

function! zettel#autoupdate#updateTagMarkerDictOnTagInsertion()
  " when a tag is inserted add it's ref to the tag marker dict
endfunction




" TagLink Autoupdation
"
function! zettel#autoupdate#createTagLinkMarkerDict() abort
  " create and maintain a taglink marker dict for all taglinks in the file
endfunction

function! zettel#autoupdate#updateTagLinkFilesWithTagLinkMarkerDict()
  " on closing a buffer writeback all the changes
endfunction

function! zettel#autoupdate#updateTagLinkMarkerDictOnTagLinkInsertion()
  " when a taglink is inserted add it's ref to the taglink marker dict
endfunction
