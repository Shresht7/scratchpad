_scratchpad_complete() {

    # Local vars
    local current first path name action scratchpad_dir

    # Scratchpad directory
    scratchpad_dir="$HOME/.cache/scratchpad"

    local -a names=()

    local -a actions=(
        --help -h
        --version -v
        --dir --directory -d
        --list -l
        --show --view -s
        --remove --rm -r
    )

    # Initialize completions
    COMPREPLY=()

    # Current word to complete
    current="${COMP_WORDS[COMP_CWORD]}"

    if [[ -d "$scratchpad_dir" ]]; then
        for path in "$scratchpad_dir"/*; do
            if [[ ! -f "$path" ]]; then
                continue
            fi

            # Get file name
            name="${path##*/}"

            # Leading-dash names aren't valid
            if [[ "$name" == -* ]]; then
                continue
            fi

            # Add valid name to list
            names+=("$name")
        done
    fi

    # First argument: note names by default, action for flag prefixes
    if (( COMP_CWORD == 1 )); then
        for name in "${names[@]}"; do
            if [[ "$name" == "$current"* ]]; then
                COMPREPLY+=("$name")
            fi
        done

        if [[ "$current" == -* ]] || (( ${#names[@]} == 0 )); then
            for action in "${actions[@]}"; do
                if [[ "$action" == "$current"* ]]; then
                    COMPREPLY+=("$action")
                fi
            done
        fi

        return 0
    fi

    # Second argument to --show/--view or --remove: note names
    first="${COMP_WORDS[1]}"
    case "$first" in
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

# Let Bash quote completed filenames, including names with spaces
complete -o filenames -F _scratchpad_complete scratchpad
