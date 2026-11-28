#!/usr/bin/env bash

# scratchpad: open/edit temporary files or piped input using your $EDITOR

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
    # Declare local variables
    local name scratchpad_file editor
    local -a editor_command

    # Name of the scratchpad file
    name="${1:-scratchpad}"

    # Keep names to a single file inside the scratchpad directory
    validate_name "$name"

    # Path to the scratchpad file
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

# Show scratchpad directory
directory() {
    echo "$SCRATCHPAD_DIR"
}

# ----
# LIST
# ----

# List scratchpad files
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
        preview_command='bat --color=always --style=plain --paging=never -- "$SCRATCHPAD_DIR"/{}'
    else
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
            # got a selection
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

# HELPERS
# -------

# Helper function to show error and exit
error() {
    printf "error: %s\n" "$*" >&2
    exit 1
}

# Validate filename
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
        bat --color=always --style=plain --paging=never -- "$file"
    else
        cat "$file"
    fi
}

# --------------
# COMMAND SWITCH
# --------------

# ${1:-} safely read the first arg, or empty string when no args were passed.
# Action flags start with a - or --. Bare words are treated as scratchpad names
# After matching a flag, `shift` removes it so "$@" / "$1" becomes its arguments.

case "${1:-}" in

    --help|-h)
        [[ $# -eq 1 ]] || error "help does not accept arguments"
        show_help
        ;;

    --version|-v)
        [[ $# -eq 1 ]] || error "version does not accept arguments"
        show_version
        ;;

    --examples, --ex)
        show_examples
        ;;

    --dir|--directory|-d)
        [[ $# -eq 1 ]] || error "directory does not accept arguments"
        directory
        ;;

    --list|-l)
        shift
        list "$@"
        ;;

    --show|--view|-s)
        shift
        (( $# <= 1 )) || error "usage: scratchpad --show [name]"
        show "${1:-}"
        ;;

    --remove|--rm|-r)
        shift
        (( $# == 1 )) || error "usage: scratchpad --remove <name>"
        remove "$1"
        ;;

    -*)
        error "unknown option: $1"
        ;;

    *)
        (( $# <= 1 )) || error "expected at most one scratchpad name"
        scratchpad "${1:-scratchpad}"
        ;;

esac
