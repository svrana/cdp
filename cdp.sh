#!/usr/bin/env bash

cdp_log=0

# Search for directory specified in $CDP_DIR_SPEC directories.
#
# The format of CDP_DIR_SPEC is path:max-depth. path is the full path of the
# destination and max-depth is the number of directories under that path to
# search for the directory target specified by the user.
#
# For example, a CDP_DIR_SPEC of ~/Projects:1 would allow a match on any
# subdirectory of Projects, but not any sub-subdirectory, so 'foo'
# ~/Projects/foo but not /home/shaw/Projects/bar/foo.
function cdp() {
    local project="$1"
    local dir=""

    if [ -z "$CDP_DIR_SPEC" ]; then
        echo "CDP_DIR_SPEC environment variable not set"
        return 1
    fi

    if ! command -v fd > /dev/null 2>&1 ; then
        echo 'cdp requires fd to run, see https://github.com/sharkdp/fd'
    fi

    if [ -z "$project" ]; then
        if [ -n "${!CDP_DEFAULT_VAR}" ]; then
            cd "${!CDP_DEFAULT_VAR}"
        else
            echo "Must specify directory"
        fi
        return 1
    fi

    # Looping through the whole process for each directory hop instead of just
    # doing it for the first directory, i.e., fuzzy match all the way down
    local project_root="${project%%/*}"

    IFS=';' read -r -a dirspecs <<< "$CDP_DIR_SPEC"
    for dirspec in "${dirspecs[@]}" ; do
        local spec
        IFS=':' read -r -a spec <<< "$dirspec"
        local path="${spec[0]}"
        local depth="${spec[1]:-1}"
        local dirs
        local num_dirs

        dirs="$(fd -t d --max-depth "$depth" "^$project_root" "$path")"
        _log "Found directories: $dirs"
        num_dirs=$(echo "$dirs" | wc -l)
        if [ -n "$dirs" ]; then
            if [ "$num_dirs" -gt "1" ]; then
                exact_match=$(_exact_match "$project_root" "$dirs")
                if [ -n "$exact_match" ]; then
                    _log "Found exact match: $exact_match"
                    dir="$exact_match"
                else
                    dirs_depth=$(_get_dir_depth "$dirs")
                    # shallowest directory first
                    dir_depth=$(echo "$dirs_depth" | sort -n | head -n1)
                    # discard depth and the space afterwards
                    dir=${dir_depth#* }
                fi
            else
                dir=$dirs
            fi
        fi

        _log "Matched directory: $dir"
        if [ -n "$dir" ]; then
            local subdirs="${project#$project_root/*}"
            if [ "$project" != "$project_root" ]; then
                cd "$dir" && cd "$subdirs"
            else
                cd "$dir"
            fi
            return 0
        fi
    done

    echo "No directory found for '$project'"
    return 1
}

function _get_dir_depth() {
    local dirs=$1
    for dir in $dirs ; do
        count=$(echo "$dir" | grep -o '/' | wc -l)
        echo "$count $dir"
    done
    return 0
}

trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

function remove_dir_spec_dir() {
    local full_path
    full_path=$(trim "$1") # preceeding space on first directory, wtf
    local dirspecs
    IFS=';' read -r -a dirspecs <<< "$CDP_DIR_SPEC"
    for dirspec in "${dirspecs[@]}" ; do
        local spec
        IFS=':' read -r -a spec <<< "$dirspec"
        local path="${spec[0]}"
        _log "Checking if dirspec $path is in $full_path"
        if [ "${full_path#$path}" != "$full_path" ]; then
            #_log "Removing $path and returning ${full_path#$path}"
            echo "${full_path#$path}"
            return
        fi
    done

    _log "##BUG## :: Could not find a dir_spec in $full_path"
}

function dir_cmp() {
    local path="${1#/}" # remove preceeding slash if there is one
    local search_term="$2"
    local dirs
    local dir
    _log "Searching for $search_term in $path"
    IFS='/' read -r -a dirs <<< "$path"
    for dir in "${dirs[@]}" ; do
        if [ "$dir" == "$search_term" ]; then
            return 0
        fi
    done
    return 1
}

function _exact_match() {
    local search_term="$1"
    local matches="$2"
    local match_list
    readarray -t match_list <<<" $matches"

    local exact_match=""
    local dir
    for dir in "${match_list[@]}" ; do
        #_log "Checking if $search_term in $dir"
        local short_dir
        short_dir=$(remove_dir_spec_dir "$dir")
        _log "Shortened path to: '$short_dir'"
        if dir_cmp "$short_dir" "$search_term" ; then
            echo "$dir"
            return 0
        fi
    done

    echo ""

}

function _log() {
    if [ "$cdp_log" -eq 1 ]; then
        >&2 echo "$@"
    fi
}
