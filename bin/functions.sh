# Functions to support operation of scripts in the 'impel' project.

function draw_line {
    local length=$1
    local i
    for (( i=0; i<length; i++)); do echo -n '-'; done; echo;
}

function parse_param {
    local varname="$1"; shift
    local param="$1"; shift
    local text="$*"
    local rx="^.*\(${param}:([^\)]*)\)"

    if [[ ! "$text" =~ $rx ]]; then
        # no match
        return
    fi

    local value=${BASH_REMATCH[1]}
    expr="${varname}=\"${value}\""
    eval "$expr"
}

function process_expenses {
    # directory may contain 'future' and 'past'
    while read line; do
        echo "line: $line"
        local recur=''
        parse_param recur recur "$line"
        if [[ -n "$recur" ]]; then
            echo " recurrence: $recur"
        fi
    done < "${dir}/future"
}

function process_activities {
    # directory may contain 'future' and 'past'
    local curly_brace=0
    while read line; do
        local a=$(echo "$line" | sed 's/[^{]*//g')
        local curly_brace_open=${#a}
        local a=$(echo "$line" | sed 's/[^}]*//g')
        local curly_brace_close=${#a}
        (( curly_brace = curly_brace + curly_brace_open - curly_brace_close ))
        echo "(curly_brace $curly_brace) line: $line"
        local recur=''
        parse_param recur recur "$line"
        if [[ -n "$recur" ]]; then
            echo " recurrence: $recur"
        fi
    done < "${dir}/future"
}

function process_correspondence {
    # directory may contain 'future' and 'past'
    # other subdirectories should be traversed
    local this_dir_type="$dir_type"
    local due=''
    local blank_line_rx='^\s*$'
    if [[ -r "${dir}/future" ]]; then
        while read line; do
            if [[ "$line" =~ $blank_line_rx ]]; then continue; fi
            echo "line: $line"
            parse_param due due "$line"
            if [[ -n "$due" ]]; then
                echo " due: $due"
            fi
        done < "${dir}/future"
    fi
    for subdir in "${dir}"/*; do
        if [[ ! -d "$subdir" ]]; then
            continue
        fi
        process_dir "${subdir}"
        dir_type="$this_dir_type" # set this back to parent value to avoid unexpected inheritance from peers
    done
}

function process_dir {
    local dir="$1"

    # check if this is flagged to skip
    if [[ -e "${dir}/skip" ]]; then
        echo "${dir}/skip exists; skipping dir"
        return
    fi

    # discriminate by directory type. READ THIS FROM A FILE IN THE DIR
    if [[ -r "${dir}/type" ]]; then
        dir_type=$(cat "${dir}/type")
    fi

    echo "processing '$dir'"

    # TODO: Recurse, processing each subdir

    echo "type = '$dir_type'"

    case $dir_type in
    activities)
        process_activities "$dir"
        ;;
    correspondence)
        process_correspondence "$dir"
        ;;
    expenses)
        process_expenses "$dir"
        ;;
    watch)
        # process_watch "$dir"
        ;;
    *)
        echo >&2 "dir '$dir': unsupported type '$dir_type'"
        continue
        ;;
    esac
}

