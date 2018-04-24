#!/usr/bin/env bash

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

    local project_root="${project%%/*}"

    IFS=';' read -r -a dirspecs <<< "$CDP_DIR_SPEC"
    for dirspec in "${dirspecs[@]}" ; do
        local spec
        IFS=':' read -r -a spec <<< "$dirspec"
        path="${spec[0]}"
        depth="${spec[1]:-1}"

        dirs="$(fd -t d --max-depth "$depth" "$project_root" "$path")"
        if [ -n "$dirs" ]; then
            dirs_depth=$(_get_dir_depth "$dirs")
             # shallowest directory first
            dir_depth=$(echo "$dirs_depth" | sort -n | head -n1)
            # discard depth and the space afterwards
            dir=${dir_depth#* }
        fi

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
