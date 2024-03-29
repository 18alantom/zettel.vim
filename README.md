# zettel.vim 🔗

A plugin to hyperlink files, facilitating  your
[Zettelkasten](https://zettelkasten.de/introduction/) or
Antinet or some other esoteric
note-taking-knowledge-building system you may have.

## Index
- [Introduction](#introduction)
- [Installation](#installation)
- [Key Bindings](#keybindings)
- [Commands](#commands)
- [Menu](#menu)
- [Global Variables](#global-variables)
- [Field Values](#field-values)

---

## Introduction
![Zettel Demo](.github/zettel_demo.gif)

Essentially what this plugin does is help you create hyperlinks and jump across
files that you edit in vim.

It does this by making use of vim's *tag* functionality (see `:h tag`) which is
used to mark locations in a file.
Generally you need a tool such as [ctags](https://en.wikipedia.org/wiki/Ctags)
to generate a populated tagfile. This helps you create your own tags and
tagfiles and jump around the marked files using FZF.

There are two concepts used here:
1. **tag**: this marks a location in a file.
2. **taglink**: this points to a *tag* from another location.

*Tags* aren't visible in a file; *taglinks* are visible in a file, by default
they have the following format `z://[tagfile]/[tagname]`.

### Usage
A simple way of using this plugin is:
1. Mark a location (A) using a [_tag_](#zettelinserttag) (`<leader>zi`).
2. Place a [_taglink_](#zettelinserttaglink) (`<leader>zl`) at another location (B).
3. Press `Ctrl-]` on the _taglink_ (at B) it will jump to the _tag_ (at A).
4. Pressing `Ctrl-T` will jump back (to B).

The locations (A, B) mentioned above can belong to the same file or different
files.

## Installation
This plugin makes use of [FZF](https://github.com/junegunn/fzf), check [this
md file](https://github.com/junegunn/fzf/blob/master/README-VIM.md) if you haven't
set it up for vim yet.

### Using [vim-plug](https://github.com/junegunn/vim-plug)
```vim
call plug#begin('~/.vim/plugged')
" ...
Plug '18alantom/zettel.vim'
" ...
call plug#end()
```

## Key Bindings
These keybindings call commands defined by the plugin, some of which expect
args. For more details on the commands, check the [**Commands**](#commands)
section.

| Binding   | What it does|
|--------------|-------------|
| `<leader>zi` |Calls [`ZettelInsertTag`](#zettelinserttag) which will insert a tag into a tag file. *|
| `<leader>zj` | Calls [`ZettelListTags`](#zettellisttags), which will open an *FZF* window listing all the tags. `<Enter>` will select a tag and will open it in the current window.|
| `<leader>zl` | Calls [`ZettelInsertTagLink`](#zettelinserttaglink) which will open an *FZF* window listing all the tags. Selected tag will cause its taglink to be inserted at the cursor position.|
| `<leader>zd` | Calls [`ZettelDeleteTag`](#zetteldeletetag) which will open a multiselect (using `<Tab>`) *FZF* window. Selected tags will be deleted forever. |
| `<leader>zm` | Runs the `:emenu` command for Zettel's commands, `<Tab>` completion and cursor keys can be used for navigating the menu, `<enter>` will it.|
| `<C-]>` | Jump to from taglink under cursor to a tag. If a taglink is not found then it falls back to default behaviour.|

_* requires args._

_Note: The `<leader>` key by default is `\`, to change it to `<space>` you can add this `let mapleader = "\<Space>"` to your `.vimrc`. For more infor check `:h leader` or [this SO post](https://vi.stackexchange.com/questions/281/how-can-i-find-out-what-leader-is-set-to-and-is-it-possible-to-remap-leader)._

### Prevent Default Bindings

To not use the default key bindings add this line to your `.vimrc`:
```vim
let g:zettel_prevent_default_bindings = 1
```

If you don't want to use the default bindings but still keep the `Ctrl-]`
behaviour then add this to your `.vimrc`:
```vim
function s:OverloadCtrlSqBracket()
  let l:zettel_jump = zettel#tagLinkJump()
  if l:zettel_jump == 2
    return
  endif

  if !l:zettel_jump
    execute "normal!\<C-]>"
  endif
endfunction
nnoremap <silent> <C-]> :call <SID>OverloadCtrlSqBracket()<CR>
```

## Commands

#### `ZettelCreateNewTagFile`
Creates a new tag file at `g:zettel_root`. Field values are optional.
- **format** — `ZettelCreateNewTagFile {tagfile} [{field}={value}]`
- **example** — `:ZettelCreateNewTagFile recipes togit=0`
    - A tag file named "recipes" is created with `togit` field value set to 0.

#### `ZettelInsertTag`
Inserts a tag into the specified tag file file. If tag file is not provided
`g:zettel_unscoped_tagfile_name` is used. If the provided tag file doesn't
exist then it is created first.
- **format** — `ZettelInsertTag [{tagname|tagfile/tagname|@tagfile}] [{field}={value}]`
- **example** — `:ZettelInsertTag recipes/lasagne`
    - A tag name "lasagne" is added to the tag file "recipes"

#### `ZettelListTags`
Opens an *FZF* window listing all the tags across all the tag files. On
selection by typing `<Enter>`, the file pointed to by the tag is opened in the
current window. Displayed tags can be filtered by tagfiles by adding them after
the command.
- **format** — `:ZettelListTags [tagfile_1] [tagfile_2] [...]`
- **example** — `:ZettelListTags recipes`
    - All tags in the tagfile "recipes" is listed out in an *FZF* window.

#### `ZettelInsertTagLink`
Opens an *FZF* window listing all the tags across all the tag files. On
selection by typing `<Enter>`, a taglink to the selected tag is inserted after
the cursor.
- **format** — `:ZettelInsertTagLink`

#### `ZettelDeleteTag`
Opens an *FZF* window listing all the tags across all the tag files. Multiple
tags can be selected by typing `<Tab>` or a single on by typing `<Enter>` for
deletion. Displayed tags can be filtered by tagfiles by adding them after
the command.
- **format** — `:ZettelDeleteTag [tagfile_1] [tagfile_2] [...]`
- **example** — `:ZettelDeleteTag recipes`
    - All tags in the tagfile "recipes" is listed out in an *FZF* window for
      deletion.

#### `ZettelListTagLinks`
Opens an *FZF* window listing all the inserted taglinks. Selecting a taglink
will open the file containing the taglink in the current window.
- **format** — `:ZettelListTagLinks`

#### `ZettelListTagsInThisFile`
Opens an *FZF* window listing all the tags in the file related to the open
buffer. On selection by typing `<Enter>`, the file pointed to by the tag is
opened in the current window.
- **format** — `:ZettelListTagsInThisFile`

#### `ZettelListTagLinksInThisFile`
Opens an *FZF* window listing all the taglinks in the file related to the open
buffer. On selection by typing `<Enter>`, the file containing the taglink is
opened in the current window.
- **format** — `:ZettelListTagLinksInThisFile`

#### `ZettelListTagLinksToATag`
Opens an *FZF* window listing all the tags, on selecting a tag a new *FZF* window
opens up showing all the taglinks that link to the selected tag. Displayed tags
can be filtered by tagfiles by adding them after the command.
- **format** — `:ZettelListTagLinksToATag [tagfile_1] [tagfile_2] [...]`
- **example** — `:ZettelListTagLinksToATag recipes`
    - All tags in the tagfile "recipes" is listed out in an *FZF* window on
        selecting one of them all taglinks to that tag are displayed.

#### `ZettelDeleteTagFile`
Opens an *FZF* window with all the tag files, also showing the number of tags
and taglinks linked to these tags in each file. Multiple tagfiles can be selected
by typing `<Tab>`. Typing `<Enter>` will delete the selected tagfiles. Taglinks
to these tags will have to be manually removed, this is by design to prevent
editing user files.
- **format** — `:ZettelDeleteTagFile`

## Menu

You can use the menu to access plugin commands. The menu can be invoked by
using `<leader>zm` and supports `<Tab>` completion.
![Zettel Demo Menu](.github/zettel_demo_menu.gif)


## Global Variables
List of global variables used by `zettel.vim` that can be changed in the `.vimrc` to override default
behaviour.

|Variable| Default |What it does|
|--------|---------|------------|
| `g:zettel_root` |  `$HOME/.zettel` | Location where all the tagfiles are stored. |
| `g:zettel_prevent_default_bindings` | `0` | Setting this will prevent default keybindings from being set. |
| `g:zettel_unscoped_tagfile_name` | `tags` | Location of tags where a tag file isn't provided on insertion. |
| `g:zettel_default_field_togit`| `1` | Used to set tag file level `togit` field value. |
| `g:zettel_taglink_prefix`| `"z://"` | Used to identify a taglink by prefixing it.|
| `g:zettel_confirm_before_overwrite`| `0` | If a duplicate tag is found in a tagfile, setting this to 1 will cause zettel to confirm before overwriting it.|

## Field Values
These are key value pairs set for each tag file or tag.

### `togit`
To mark files that have to be added to a bare git repository. All tags in a file
where `togit` is set to 1 will be added unless overridden by a tag level
`togit`.

*This hasn't been implemented yet. No plans to do so as of now, but seems useful
so may add it in later.*

---

For more info type `:h zettel` in vim.
