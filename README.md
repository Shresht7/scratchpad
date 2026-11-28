# `scratchpad`

A temporary terminal scratchpad for quick edits in the terminal and in shell pipelines.

There are times when you need to write something in the terminal but still want the power and convenience of your editor. There are also times when you want to make quick, one-off edits to the output of one command before passing it onto the next. `scratchpad` wraps your editor in a few shell commands to make that easy.

Using the editor directly works (mostly), but doesn't preserve history. If you make a small mistake while constructing your YAML or JSON, you may have to start over and rewrite the whole damn thing again. `scratchpad` preserves your edits so you can pick up where you left off.

Scratchpad files are plain-text files saved locally in a cache directory (`~/.cache/scratchpad`).

**Born out of the frustration of writing inline JSON for `curl`'s body.**

## Requirements

- An editor command configured through `$SCRATCHPAD_EDITOR`, `$EDITOR`, or `$VISUAL` (PowerShell: `$Env:SCRATCHPAD_EDITOR`, `$Env:EDITOR`, `$Env:VISUAL`), resolved in that order.
- `fzf` *(optional)*: enables the interactive picker when showing a scratchpad without a name.
- `bat` *(optional)*: used for colored previews when available.

> [!NOTE]
> For Visual Studio Code, set the editor command to `code --wait` so Scratchpad waits for you to finish editing before continuing.

## Usage

Common behavior across Bash and PowerShell:

- Without a name, `scratchpad` uses the persistent `scratchpad` file.
- After editing, Scratchpad emits the saved contents (stdout in Bash, pipeline output in PowerShell).
- Scratchpad names must be filenames, not paths or options.

> [!CAUTION]
> Piped input replaces the selected scratchpad's contents before opening the editor.

### Bash

#### Install

Make the script executable and link it into a directory on your `PATH`:

```sh
chmod +x /path/to/scratchpad.sh
```

```sh
ln -s /path/to/scratchpad.sh ~/.local/bin/scratchpad
```

#### Commands

```sh
scratchpad [name]
scratchpad --list [ls options]
scratchpad --show [name]
scratchpad --remove <name>
scratchpad --dir
scratchpad --examples
scratchpad --version
scratchpad --help
```

> [!NOTE]
> - `scratchpad --show` opens an interactive `fzf` picker when no name is given (requires `fzf`).
> - `scratchpad --list` forwards additional arguments to `ls`.

Example:

```sh
git diff | scratchpad review | grep TODO
```

#### Completions

Bash completions are provided in `scratchpad-completions.sh`.

Source it from your shell startup, for example in `~/.bashrc`:

```sh
source /path/to/scratchpad-completions.sh
```

Or copy/install it into your bash-completion directory so it loads automatically, for example:

```sh
~/.local/share/bash-completion/completions/scratchpad
```

### PowerShell

#### Install

For the current session, import the manifest from the repository:

```powershell
Import-Module ./scratchpad.psd1
```

To enable module auto-loading, copy `scratchpad.psd1` and `scratchpad.psm1` into a directory named `scratchpad` under a writable path listed in `$env:PSModulePath`.

Common user module directories are:

- Windows: `$HOME\Documents\PowerShell\Modules\scratchpad`
- Linux/macOS: `$HOME/.local/share/powershell/Modules/scratchpad`

Set your editor command in the current session or your PowerShell profile. For Visual Studio Code:

```powershell
$Env:EDITOR = 'code --wait'
```

#### Commands

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
scratchpad --show [name]
scratchpad --remove <name>
scratchpad --dir
scratchpad --version
scratchpad --help
```

> [!NOTE]
> - `Show-Scratchpad` uses an interactive `fzf` picker when no name is provided (requires `fzf`).
> - PowerShell pipelines pass objects, so the module converts incoming objects to text lines; it is intended for text, not binary data.

For example:

```powershell
git diff | scratchpad review | Set-Content review.txt
```

## License

[MIT](LICENSE)
