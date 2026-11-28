#!/usr/bin/env bash

# Enable strict behaviour. Exit on errors and unset vars. Fail on pipe errors.
set -euo pipefail

# Script Version
VERSION="v0.1.0"

# Directory for scratchpad files
SCRATCHPAD_DIR="$HOME/.cache/scratchpad"

mkdir -p "$SCRATCHPAD_DIR"  # Ensure that the scratchpad directory exists

# ----
# HELP
# ----

show_help() {
    printf '%s\n' \
        "" \
        "terminal scratchpad" \
        "" \
        "Usage: scratchpad [name]" \
        "       scratchpad --list [ls-options]" \
        "       scratchpad --view [name]" \
        "       scratchpad --remove <name>" \
        "       scratchpad --dir" \
        "       scratchpad --version" \
        "       scratchpad --help" \
        "" \
        "Options:" \
        "  --list, -l              List scratchpads; forward remaining arguments to ls" \
        "  --view [name]           View a note; open the picker if name is omitted" \
        "  --remove, --rm, -r name Remove a note" \
        "  --dir, --directory, -d  Print the scratchpad directory" \
        "  --version, -v           Print the version" \
        "  --help, -h              Show this help" \
        ""
}

show_version() {
    printf '%s\n' "$VERSION"
}

# ----------
# SCRATCHPAD
# ----------

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

    if [[ -t 0 ]]; then
        # Interactive use: keep the current note, creating if needed
        [[ -e "$scratchpad_file" ]] || : > "$scratchpad_file"
    else
        # Pipeline use: replace the note with incoming text
        cat > "$scratchpad_file"
    fi

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
    "${editor_command[@]}" "$scratchpad_file" </dev/tty >/dev/tty 2>&1

    # Once we're done editing, forward the file contents to stdout
    display_file "$scratchpad_file"
}

# ---------
# DIRECTORY
# ---------

directory() {
    echo "$SCRATCHPAD_DIR"
}

# ----
# LIST
# ----

list() {
    ls "$SCRATCHPAD_DIR" "$@"
}

# ----
# VIEW
# ----

pick() {
    local preview_command

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

view() {
    local name selection pick_status
    
    name="${1:-}"
    if [[ -z "$name" ]]; then
        if selection=$(pick); then
            # got a selection
            if [[ -n "$selection" ]]; then
                display_file "$SCRATCHPAD_DIR/$selection"
            fi
        else
            # fzf selection failed
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
    if [[ "$name" == *"/"* || "$name" == *"\\"* || "$name" == "." || "$name" == ".." ]]; then
        error "name must be a filename, not a path"
    fi
}

# Display file with bat if available and outputting to an interactive terminal, else cat
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

case "${1:-}" in

    --help|-h)
        [[ $# -eq 1 ]] || error "help does not accept arguments"
        show_help
        ;;

    --version|-v)
        [[ $# -eq 1 ]] || error "version does not accept arguments"
        show_version
        ;;

    --dir|--directory|-d)
        [[ $# -eq 1 ]] || error "directory does not accept arguments"
        directory
        ;;

    --list|-l)
        shift
        list "$@"
        ;;

    --view|--show|-s)
        shift
        (( $# <= 1 )) || error "usage: scratchpad --view [name]"
        view "${1:-}"
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
