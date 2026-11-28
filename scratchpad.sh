#!/usr/bin/env bash

# scratchpad
# 
# A temporary terminal scratchpad for quick edits in the terminal and in shell pipelines.
#
# There are times when you need to write something in the terminal
# but still want the power and convenience of your editor.
# There are also times when you want to make quick, one-off edits
# to the output of one command before passing it onto the next. 
# 
# `scratchpad` wraps your editor in a few shell commands to make that easy.
#
# Using the editor directly works (mostly), but doesn't preserve history.
# If you make a small mistake while constructing your YAML or JSON,
# you may have to start over and rewrite the whole damn thing again. 
# `scratchpad` preserves your edits so you can pick up where you left off.
# 
# Scratchpad files are simple plain-text saved locally in a cache directory (`~/.cache/scratchpad`)
#
# Requirements:
# - An editor defined through `$EDITOR`
# - (optional) `bat` for colored previews when available
# - (optional) `fzf` for interactive `--show` picker

# Installation
#
# 1. Clone/Download the script somewhere.
# 2. Make the script executable with `chmod +x /path/to/scratchpad.sh`
# 3. Link it to a directory on your PATH: `ln -s /path/to/scratchpad/sh ~/.local/bin/scratchpad`

# Enable strict shell behaviour
# - e               exit immediately if a command fails
# - u               treat unset variables as errors
# - o pipefail      a pipeline fails if any command in it fails
set -euo pipefail

# Script Version
VERSION="v0.1.0"

# Directory for scratchpad files
SCRATCHPAD_DIR="$HOME/.cache/scratchpad"

mkdir -p "$SCRATCHPAD_DIR"  # Ensure that the scratchpad directory exists

# ----
# HELP
# ----

# Show the help message
show_help() {
    printf '%s\n' \
        "" \
        "terminal scratchpad" \
        "" \
        "Usage: scratchpad [name]" \
        "       scratchpad --list [ls-options]" \
        "       scratchpad --show [name]" \
        "       scratchpad --remove <name>" \
        "       scratchpad --dir" \
        "       scratchpad --examples" \
        "       scratchpad --version" \
        "       scratchpad --help" \
        "" \
        "Options:" \
        "  --list, -l              List scratchpads; forward remaining arguments to ls" \
        "  --show, --view [name]   Show a note; open the picker if name is omitted" \
        "  --remove, --rm, -r name Remove a note" \
        "  --dir, --directory, -d  Print the scratchpad directory" \
        "  --examples              Show usage examples" \
        "  --version, -v           Print the version" \
        "  --help, -h              Show this help" \
        "" \
        "NOTE: Without a [name], scratchpad uses a default note named 'scratchpad'" \
        "" \
        "CAUTION: Piped input replaces the selected note's contents before opening the editor" \
        ""
}

# Show the version information
show_version() {
    printf '%s\n' "$VERSION"
}

# Show usage examples
show_examples() {
    printf '%s\n' \
        "" \
        "Examples:" \
        "  scratchpad                       Open the default scratchpad" \
        "  scratchpad test.json             Open a named scratchpad" \
        "  git diff | scratchpad review     Replace 'review' with piped input, edit, then print" \
        "  scratchpad --list                List scratchpads" \
        "  scratchpad --show test.json      Show a scratchpad" \
        "  scratchpad --show                Pick a scratchpad with fzf" \
        "  scratchpad --remove test.json    Remove a scratchpad" \
        "  scratchpad --dir                 Print the scratchpad directory" \
        ""
}

# ----------
# SCRATCHPAD
# ----------

# Open or edit a scratchpad file
scratchpad() {
    # Declare local variables (prevents polluting the user's shell)
    local name scratchpad_file editor
    local -a editor_command

    # Name of the scratchpad file. Defaults to `scratchpad`
    name="${1:-scratchpad}"

    # Keep names to a single file inside the scratchpad directory
    validate_name "$name"

    # Full path to the scratchpad file
    scratchpad_file="$SCRATCHPAD_DIR/$name"

    # stdin is a terminal (-t 0) for normal interactive use:
    # keep existing note contents, creating an empty file if needed.
    # When stdin is piped, replace the note with the piped text so the
    # editor starts from that input.
    if [[ -t 0 ]]; then
        # Interactive use: keep the current note, creating if needed
        [[ -e "$scratchpad_file" ]] || : > "$scratchpad_file"
    else
        # Pipeline use: replace the note with incoming text
        cat > "$scratchpad_file"
    fi

    # Resolve $EDITOR into a command array
    # - If the whole value is an executable path/name (including spaces), use it as-is.
    # - Otherwise split on whitespace so values like "code --wait" become: command + args

    # Editor to use for the scratchpad
    editor="${EDITOR:-micro}"

    # Build the editor command array
    editor_command=()

    # Allow either an executable path (including one with spaces)
    # or a simple command plus arguments, such as "code --wait"
    if command -v "$editor" > /dev/null 2>&1; then
        editor_command=("$editor")
    else 
        read -r -a editor_command <<< "$editor"
        ((${#editor_command[@]} > 0)) || error "EDITOR is empty"
        command -v "${editor_command[0]}" > /dev/null 2>&1 || error "editor not found: ${editor_command[0]}"
    fi

    # Open the scratchpad with the editor
    # Run the editor attached to the real terminal, not the pipeline stdin/stdout.
    # This lets `git diff | scratchpad name | ...` still open an interactive editor
    "${editor_command[@]}" "$scratchpad_file" </dev/tty >/dev/tty 2>&1

    # Once we're done editing, forward the file contents to stdout
    display_file "$scratchpad_file"
}

# ---------
# DIRECTORY
# ---------

# Show the scratchpad directory
directory() {
    echo "$SCRATCHPAD_DIR"
}

# ----
# LIST
# ----

# List all scratchpad files using ls
# Args are forwarded to the ls command
list() {
    ls "$SCRATCHPAD_DIR" "$@"
}

# ----
# SHOW
# ----

# Pick a scratchpad file with fzf
pick() {
    local preview_command

    # fzf's --preview runs a shell command;
    # {} is replaced by the selected filename.
    # SCRATCHPAD_DIR is exported into the fzf environment so the
    # preview command can resolve the full path

    # Choose preview command based on available tools
    if command -v bat >/dev/null 2>&1; then
        # If bat is available, use it for syntax highlighting
        preview_command='bat --color=always --style=plain --paging=never -- "$SCRATCHPAD_DIR"/{}'
    else
        # Otherwise, fallback to using standard cat
        preview_command='cat -- "$SCRATCHPAD_DIR"/{}'
    fi

    # Run fzf with preview
    ls "$SCRATCHPAD_DIR" | SCRATCHPAD_DIR="$SCRATCHPAD_DIR" fzf \
        --preview "$preview_command" \
        --preview-window "right:75%" \
        --reverse
}

# Show the contents of scratchpad file
show() {
    local name selection pick_status
    
    name="${1:-}"
    if [[ -z "$name" ]]; then
        if selection=$(pick); then
            if [[ -n "$selection" ]]; then
                display_file "$SCRATCHPAD_DIR/$selection"
            fi
        else
            # fzf exit codes: 0 selected, 1 no match, 130 cancelled (Esc/Ctrl+C)
            # Treat "no selection" and "cancelled" as a normal no-op
            pick_status=$?
            case "$pick_status" in
                1|130) return 0;;
                *) return "$pick_status";;
            esac
        fi
    else
        validate_name "$name"
        if [[ ! -e "$SCRATCHPAD_DIR/$name" ]]; then
            error "file not found"
        fi
        display_file "$SCRATCHPAD_DIR/$name"
    fi
}

# ------
# REMOVE
# ------

# Remove a scratchpad file
remove() {
    local name
    name="${1:-}"
    [[ -z "$name" ]] && error "no file specified"
    validate_name "$name"
    [[ ! -e "$SCRATCHPAD_DIR/$name" ]] && error "file not found"
    rm -f "$SCRATCHPAD_DIR/$name"
    echo "removed $name"
}

# -------
# HELPERS
# -------

# Helper function to show error and exit
error() {
    printf "error: %s\n" "$*" >&2
    exit 1
}

# Validate filename.
# - Must not start with a - (- and -- are reserved for options)
# - Must not have a / (should not be a path)
# - Must not have a \ (should not be a path)
# - Must not contain . or .. (should not be a relative path)
validate_name() {
    local name="$1"
    if [[ "$name" == -* || "$name" == *"/"* || "$name" == *"\\"* || "$name" == "." || "$name" == ".." ]]; then
        error "name must be a filename, not a path or option"
    fi
}

# Display file contents.
# Use bat only when stdout is a terminal (-t 1), so piped
# output stays plain text. --color=always keeps preview colored when bat is used
# explicitly in an interactive preview/pager context
display_file() {
    local file="$1"
    if [[ -t 1 ]] && command -v bat >/dev/null 2>&1; then
        # Use bat if available and when stdout is a terminal
        bat --color=always --style=plain --paging=never -- "$file"
    else
        # Otherwise fallback to standard cat
        cat "$file"
    fi
}

# --------------
# COMMAND SWITCH
# --------------

# ${1:-} safely read the first arg, or empty string when no args were passed.
# Action flags start with a - or --. Bare words are treated as scratchpad names
# After matching a flag, `shift` removes it so "$@" / "$1" becomes its arguments.

# Dispatch based on the first argument (name or --option)
case "${1:-}" in

    # -- HELP --

    --help|-h)
        [[ $# -eq 1 ]] || error "help does not accept arguments"
        show_help
        ;;

    # -- VERSION --

    --version|-v)
        [[ $# -eq 1 ]] || error "version does not accept arguments"
        show_version
        ;;

    # -- EXAMPLE --

    --examples, --ex)
        show_examples
        ;;

    # -- DIRECTORY --

    --dir|--directory|-d)
        [[ $# -eq 1 ]] || error "directory does not accept arguments"
        directory
        ;;

    # -- LIST --

    --list|-l)
        shift
        list "$@"
        ;;

    # -- SHOW --

    --show|--view|-s)
        shift
        (( $# <= 1 )) || error "usage: scratchpad --show [name]"
        show "${1:-}"
        ;;

    # -- REMOVE --

    --remove|--rm|-r)
        shift
        (( $# == 1 )) || error "usage: scratchpad --remove <name>"
        remove "$1"
        ;;

    # -- UNKNOWN OPTION --

    -*)
        error "unknown option: $1"
        ;;

    # -- EVERYTHING ELSE / CATCH-ALL --

    *)
        (( $# <= 1 )) || error "expected at most one scratchpad name"
        scratchpad "${1:-scratchpad}"
        ;;

esac
