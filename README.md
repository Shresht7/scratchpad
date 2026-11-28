# `scratchpad`

A temporary terminal scratchpad for drafting text and editing piped input.

There are times when you need to write something in the terminal but also require the power and convenience of your editor. There are also times when you want to quickly do one-off edits to the output of one command before passing it along to the input to the next. `scratchpad` is just shell commands over your editor that make this easy.

Using the editor directly works (mostly), but doesn't preserve history in case you make a tiny mistake constructing your yaml and have to rewrite the whole thing again.

**Born out of the frustration of writing inline JSON for `curl`'s body.**

## Requirements

- An editor configured through `$EDITOR` / `$Env:EDITOR`
- `fzf` for the interactive `view` picker.
- `bat` is optional and is used for colored previews when available.

> [!NOTE]
> For Visual Studio Code, set the editor to `code --wait` so Scratchpad waits for you to finish editing before continuing.

## Bash

### Install

Make the script executable and link it into a directory on your `PATH`:

```sh
chmod +x /path/to/scratchpad.sh
```

```sh
ln -s /path/to/scratchpad.sh ~/.local/bin/scratchpad
```

---

### Usage

```sh
scratchpad [name]
scratchpad list [ls options]
scratchpad view [name]
scratchpad rm <name>
scratchpad dir
scratchpad version
scratchpad help
```

> [!NOTE]
> - Without a name, `scratchpad` uses the persistent `scratchpad` note.
> - Piped input replaces the selected note's contents before opening the editor.
> - `scratchpad view` opens an `fzf` picker when no name is given.
> - `scratchpad list` forwards additional arguments to `ls`.

Example:

```sh
git diff | scratchpad review | grep TODO
```

## PowerShell 7+

### Install

For the current session, import the manifest from the repository:

```powershell
Import-Module ./scratchpad.psd1
```

To enable module auto-loading, copy `scratchpad.psd1` and `scratchpad.psm1` into a directory named `scratchpad` under a writable path listed in `$env:PSModulePath`. 

Common user module directories are:

- Windows: `$HOME\Documents\PowerShell\Modules\scratchpad`
- Linux/macOS: `$HOME/.local/share/powershell/Modules/scratchpad`

Set `$Env:EDITOR` in the current session or your PowerShell profile. For Visual Studio Code:

```powershell
$Env:EDITOR = 'code --wait'
```

### Usage

The module exposes native PowerShell commands and a `scratchpad` alias for the Bash-style dispatcher:

```powershell
Open-Scratchpad [-Name <name>]
Get-Scratchpad
Show-Scratchpad [-Name <name>]
Remove-Scratchpad -Name <name>
Get-ScratchpadDirectory
```

The dispatcher supports:

```powershell
scratchpad [name]
scratchpad --list
scratchpad --view [name]
scratchpad --rm <name>
scratchpad --dir
scratchpad --version
scratchpad --help
```

> [!CAUTION]
> Piped text replaces the selected note before it opens in the editor. For example:
> 
> ```powershell
> git diff | scratchpad review
> ```

`Show-Scratchpad` opens the `fzf` picker if no name is provided. PowerShell pipelines pass objects, so the module converts incoming objects to text lines; it is intended for text, not binary data.
