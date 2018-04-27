#!/usr/bin/env bash

function _log() {
    local cdp_log=0

    if [ "$cdp_log" -eq 1 ]; then
        >&2 echo "$@"
    fi
}

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

    # TODO: Loop through the whole process for each directory hop instead of just
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
                local dirs_list
                dirs_list=$(dirs_sort_by_depth "$dirs")
                _log "Directories sorted by depth"

                exact_match=$(_find_exact_match "$project_root" "$dirs_list")
                 if [ -n "$exact_match" ]; then
                     dir="$exact_match"
                 else
                     IFS=' ' read -r -a dirs <<< "$dirs_list"
                     dir=${dirs[0]}
                     _log "No exact match, taking shortest directory '$dir'"
                 fi
            else
                dir=$dirs
            fi
        fi

        _log "Chaning directory to: $dir"
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

function dirs_sort_by_depth() {
    local dirs="$1"

    local dirs_depth
    dirs_depth=$(_get_dir_depth "$dirs" | sort -n)

    local dirs_depth_array=()
    readarray -t dirs_depth_array <<<" $dirs_depth"
    local dirs_array=()
    for dir_depth in "${dirs_depth_array[@]}" ; do
        local dir=${dir_depth#*:}
        dirs_array+=($dir)
    done
    #_log "sorted by depth array: ${dirs_array[@]}"
    echo "${dirs_array[@]}"
}

function _get_dir_depth() {
    local dirs="$1"
    local dir
    for dir in $dirs ; do
        count="$(echo "$dir" | grep -o '/' | wc -l)"
        echo "$count:$dir"
    done
    return 0
}

function trim() {
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

function _find_exact_match() {
    local search_term="$1"
    local matches="$2"

    local match_list
    local dir
    IFS=' ' read -r -a match_list <<< "$matches"
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

