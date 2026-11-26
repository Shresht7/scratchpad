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
        "Usage: scratchpad [name]" \
        "       scratchpad <command> [arguments]" \
        "" \
        "Commands:" \
        "  list, ls, --list, -l [options]  List scratchpads" \
        "  view, --view [name]             View a scratchpad; open picker if omitted" \
        "  rm, --rm, -r <name>             Remove a scratchpad" \
        "  dir, --dir, -d                  Print the scratchpad directory" \
        "  version, --version, -v          Print the version" \
        "  help, --help, -h                Show this help"
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

display_file() {
    if command -v bat > /dev/null 2>&1; then
        bat --color=always --style=plain --paging=never -- "$1"
    else
        cat "$1"
    fi
}

# --------------
# COMMAND SWITCH
# --------------

case "${1:-}" in

    # HELP
    help|--help|-h)
        show_help
        ;;

    # VERSION
    version|--version|-v)
        show_version
        ;;

    # DIRECTORY
    dir|--dir|-d)
        directory
        ;;

    # LIST
    list|ls|--list|-l)
        list "${@:2}"
        ;;

    # VIEW
    view|--view)
        view "${@:2}"
        ;;

    # REMOVE
    rm|--rm|-r)
        remove "${@:2}"
        ;;

    # DEFAULT
    *)
        scratchpad "$@"
        ;;

esac
