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
    expr="${varname}=${value}"
    eval "$expr"
}

function process_expenses {
    # directory may contain 'future' and 'past'
    while read line; do
        echo "line: $line"
        parse_param recur recur "$line"
        if [[ -n "$recur" ]]; then
            echo "recurrence: $recur"
        fi
    done < "${dir}/future"
}

function process_dir {
    local dir="$1" type

    # check if this is flagged to skip
    if [[ -e "${dir}/skip" ]]; then
        echo "${dir}/skip exists; skipping dir"
        return
    fi

    # discriminate by directory type. READ THIS FROM A FILE IN THE DIR
    type=$(cat "$dir/type")

    echo "processing '$dir'"

    # TODO: Recurse, processing each subdir

    echo "type = '$type'"

    case $type in
    activities)
        # process_activities "$dir"
        ;;
    correspondence)
        # process_correspondence "$dir"
        ;;
    expenses)
        process_expenses "$dir"
        ;;
    watch)
        # process_watch "$dir"
        ;;
    *)
        echo >&2 "dir '$dir': unsupported type '$type'"
        continue
        ;;
    esac
}

