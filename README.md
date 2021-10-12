# zettel.vim

A plugin to help you maintain your [Zettelkasten](https://zettelkasten.de/introduction/) or [Antinet](https://daily.scottscheper.com/num/247/) or some other esoteric note-taking-knowledge-building system you may have.

## Introduction

## Concepts

## KeyBindings
These keybindings call commands, some of which expect args. For more details on
the commands, check the [**Commands**](#commands) section.
- `<leader>zc` — Calls [`ZettelCreateNewTagFile`](#zettelcreatenewtagfile) which creates a new tag file. *
- `<leader>zi` — Calls [`ZettelInsertTag`](#zettelinserttag) which will insert a tag into a tag file. *
- `<leader>zj` — Calls [`ZettelJumpToTag`](#zetteljumptotag) which opens the *FZF* window listing
    all the tags. Selected tag will open in the current window.
- `<leader>zl` — Calls [`ZettelInsertTagLink`](#zettelinserttaglink) which will open an *FZF* listing
    all the tags. Selected tag will cause its taglink to be inserted at the cursor
    position.
- `<leader>zd` — Calls [`ZettelDeleteTag`](#zetteldeletetag) which will open a multiselect (using `<Tab>`) *FZF* window. Selected tags will be deleted forever.

To prevent the default key bindings add this line to your `.vimrc`:
```
  let g:zettel_tags_prevent_default_bindings = 1
```

_*  requires args._

## Commands


#### `ZettelCreateNewTagFile`
Creates a new tag file at `g:zettel_tags_root`. Field values are optional.
- **format** — `ZettelCreateNewTagFile {tagfile} [{field}={value}]`
- **example** — `ZettelCreateNewTagFile recipes togit=0`
    - A tag file named "recipes" is created with `togit` field value set to 0.

#### `ZettelInsertTag`
Inserts a tag into the specified tag file file. If tag file is not provided
`g:zettel_tags_unscoped_tagfile_name` is used. If the provided tag file doesn't
exist then it is created first. If nothing is provided or arg starts with an @
(`@tagfile`) then the line under the cursor is used as the tagname.
- **format** — `ZettelInsertTag [{tagname|tagfile/tagname|@tagfile}] [{field}={value}]`
- **example** — `ZettelInsertTag recipes/lasagne`
    - A tag name "lasagne" is added to the tag file "recipes"

#### `ZettelJumpToTag`
Opens an *FZF* window listing all the tags across all the tag files. On
selection by typing `<Enter>`, the file pointed to by the tag is opened in the
current window.
- **format** — `ZettelJumpToTag`

#### `ZettelInsertTagLink`
Opens an *FZF* window listing all the tags across all the tag files. On
selection by typing `<Enter>`, a taglink to the selected tag is inserted after
the cursor.
- **format** — `ZettelInsertTagLink`

#### `ZettelDeleteTag`
Opens an *FZF* window listing all the tags across all the tag files. Multiple
tags can be selected by typing `<Tab>` or a single on by typing `<Enter>` for
deletion.
- **format** — `ZettelDeleteTag`

## Global Variables
List of global variables used by `zettel.vim` that can be changed to override default
behaviour.
- `g:zettel_tags_root` — Location where all the tagfiles are stored. Default:
    `$HOME/zettel`
- `g:zettel_tags_prevent_default_bindings` — Setting this will prevent default
    keybindings from being set. Default: 0
- `g:zettel_tags_unscoped_tagfile_name` — Location of tags where a tag file isn't
    provided on insertaion. Default: `tags`
- `g:zettel_tags_default_field_togit` — Used to set tag file level `togit` field
    value. Default: 0

## Field Values
These are key value pairs set for each tag file or tag.

### `togit`
To mark files that have to be added to a bare git repository. All tags in a file
where `togit` is set to 1 will be added unless overridden by a tag level
`togit`.

*This hasn't been implemented yet.*

## TODO
- [ ] add `togit` functionality.
- [ ] update tag location when text pointed to by tag moves, like how marks
    function.
