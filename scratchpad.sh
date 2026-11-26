#!/usr/bin/env bash

# Enable strict behaviour. Exit on errors and unset vars. Fail on pipe errors.
set -euo pipefail

# Script Version
VERSION="v0.1.0"

# Directory for scratchpad files
SCRATCHPAD_DIR="$HOME/.cache/scratchpad"

mkdir -p "$SCRATCHPAD_DIR"  # Ensure that the scratchpad directory exists

# ----------
# SCRATCHPAD
# ----------

scratchpad() {
    # Name of the scratchpad file
    name="${1:-scratchpad}"

    # Keep names to a single file inside the scratchpad directory
    if [[ "$name" == *"/"* || "$name" == *"\\"* || "$name" == "." || "$name" == ".." ]]; then
        printf "name must be a filename, not a path\n"
        exit 1
    fi

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
    cat "$scratchpad_file"
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

# ------
# REMOVE
# ------

remove() {
    [[ -z "$1" ]] && error "no file specified"
    [[ "$1" == *"/"* || "$1" == "." || "$1" == ".." ]] && error "invalid name"
    [[ ! -e "$SCRATCHPAD_DIR/$1" ]] && error "file not found"
    rm -f "$SCRATCHPAD_DIR/$1"
    echo "removed $1"
}

# HELPERS
# -------

# Helper function to show error and exit
error() {
    printf "error: %s\n" "$*" >&2
    exit 1
}

# --------------
# COMMAND SWITCH
# --------------

case "${1:-}" in

    # HELP
    help|--help|-h)
        printf "usage: scratchpad [name]\n"
        # TODO: Update usage message
        ;;

    # VERSION
    version|--version|-v)
        printf "%s\n" "$VERSION"
        ;;

    # DIRECTORY
    dir|--dir|-d)
        directory
        ;;

    # LIST
    list|--list|-l)
        list ${@:2}
        ;;

    # REMOVE
    rm|--rm|-r)
        remove ${@:2}
        ;;

    # DEFAULT
    *)
        scratchpad $*
        ;;

esac
