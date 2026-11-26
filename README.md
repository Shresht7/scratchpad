# `scratchpad`

A temporary terminal scratchpad

## Installation

### Bash

Download the script and make it executable.

```sh
chmod +x /path/to/scratchpad.sh
```

Link it to a directory in your PATH

```sh
ln -s /path/to/scratchpad.sh ~/.local/bin/scratchpad
```

---

## Usage

```sh
scratchpad [name]
scratchpad list
scratchpad view [name]
scratchpad rm <name>
scratchpad dir
scratchpad version
scratchpad help
```

> [!NOTE]
> The `name` is optional. Without it, the default `scratchpad` is used.
> `scratchpad view` will open an interactive picker with `fzf` if no name is given.
