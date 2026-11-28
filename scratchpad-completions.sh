# ================
# BASH COMPLETIONS
# ================

# Bash completions for `scratchpad`

# Enable it by sourcing this file from your shell startup, for example in ~/.bashrc:
#   source /path/to/scratchpad-completions.sh
# 
# Or install/copy it into your bash-completions directory so it loads automatically, for example:
#   ~/.local/share/bash-completion/completions/scratchpad
# The exact auto-load directory depends on your bash-completion setup.

# Bash programmable completion for `scratchpad`
# Bash calls this function on Tab and provides:
#   COMP_WORDS: array of words on the current command line
#   COMP_CWORD: index of the word being completed
#   COMPREPLY:  array we fill with completion candidates

_scratchpad_complete() {

    # Local vars (local keeps them from leaking into the user's shell)
    local current first path name action scratchpad_dir

    # Scratchpad directory
    scratchpad_dir="$HOME/.cache/scratchpad"

    # Array of note names
    local -a names=()

    # Array of actions
    local -a actions=(
        --help -h
        --version -v
        --dir --directory -d
        --list -l
        --show --view -s
        --remove --rm -r
        --examples --ex
    )

    # Initialize completions array
    COMPREPLY=()

    # Current word to complete
    current="${COMP_WORDS[COMP_CWORD]}"

    # Collect note names from the directory
    if [[ -d "$scratchpad_dir" ]]; then

        # Skip if no files
        for path in "$scratchpad_dir"/*; do
            if [[ ! -f "$path" ]]; then
                continue
            fi

            # This funky syntax strips the dir and keeps only the filename
            name="${path##*/}"

            # Leading-dash names aren't valid
            if [[ "$name" == -* ]]; then
                continue
            fi

            # Add valid name to list
            names+=("$name")
        done
    fi

    # First Argument
    # Suggest note names by default.
    # Show action flags only when the user has started typing `-`
    # or when there are no saved notes
    if (( COMP_CWORD == 1 )); then
        for name in "${names[@]}"; do
            if [[ "$name" == "$current"* ]]; then
                COMPREPLY+=("$name")
            fi
        done

        # If no matches, suggest actions anyway
        if [[ "$current" == -* ]] || (( ${#names[@]} == 0 )); then
            for action in "${actions[@]}"; do
                if [[ "$action" == "$current"* ]]; then
                    COMPREPLY+=("$action")
                fi
            done
        fi

        return 0
    fi

    # Second Argument
    # For actions that take a note name, complete note names in the next position
    first="${COMP_WORDS[1]}"
    case "$first" in

        # Actions that need a note name
        --show|--view|-s|--remove|--rm|-r)
            if (( COMP_CWORD == 2 )); then
                for name in "${names[@]}"; do
                    if [[ "$name" == "$current"* ]]; then
                        COMPREPLY+=("$name")
                    fi
                done
            fi
            ;;

    esac
}

# Register the completion function for the scratchpad command.
# -o filenames let Bash quote/escape completed names (e.g. spaces)
complete -o filenames -F _scratchpad_complete scratchpad
