_scratchpad_complete_names() {
    local current="$1"
    local scratchpad_dir="$HOME/.cache/scratchpad"
    local path name

    # Return if scratchpad dir doesn't exist
    [[ -d "$scratchpad_dir" ]] || return 0

    for path in "$scratchpad_dir"/*; do
        [[ -f "$path" ]] || continue    # If not a file, skip

        # Get the file name
        name="${path##*/}"
        if [[ "$name" == "$current"* ]]; then
            COMPREPLY+=("$name")     # Add match to completions
        fi
    done
}

_scratchpad_complete() {
    local current command action
 
    local -a actions=(
        help --help -h
        version --version -v
        dir --dir -d
        list ls --list -l
        view --view
        rm --rm -r
    )

    COMPREPLY=()
    current="${COMP_WORDS[COMP_CWORD]}"

    # First argument: subcommands and existing note names
    if (( COMP_CWORD == 1 )); then
        for action in "${actions[@]}"; do
            if [[ "$action" == "$current"* ]]; then
                COMPREPLY+=("$action")
            fi
        done
    
        _scratchpad_complete_names "$current"
        return 0
    fi

    # Second argument to view/rm: existing note names
    command="${COMP_WORDS[1]}"
    case "$command" in
        view|--view|rm|--rm|-r)
            if (( COMP_CWORD == 2 )); then
                _scratchpad_complete_names "$current"
            fi
            ;;
    esac
}

# Let Bash quote completed filenames, including names with spaces
complete -o filenames -F _scratchpad_complete scratchpad
