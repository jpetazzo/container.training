#!/usr/bin/env bash

export BASH_COMPLETION_DEBUG=true

PROG=${PROG:=$(basename "${BASH_SOURCE}")}

_cli_bash_autocomplete() {
     local cur opts base
     COMPREPLY=()
     cur="${COMP_WORDS[COMP_CWORD]}"
     opts=$( ${COMP_WORDS[@]:0:$COMP_CWORD} --generate-bash-completion )
     COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
     return 0
 }

complete -F _cli_bash_autocomplete $PROG

###############
### HELPERS ###
###############

stderr_echo() {
    >&2 echo "$@"
}

_filedir() {
    COMPREPLY=( $( compgen $@ -- "$cur" ) )
}

__workshopctl_check_auth() {
    [ ! -z "$AWS_SECRET_ACCESS_KEY" ] && return 1
    [ ! -z "$AWS_ACCESS_KEY_ID" ] && return 1
    COMPREPLY=( $( compgen -W "NO_AUTH_FOUND_PLEASE_SET_ENVVARS" ) )
}

# __workshopctl_to_alternatives transforms a multiline list of strings into a single line
# string with the words separated by `|`.
# This is used to prepare arguments to __workshopctl_pos_first_nonflag().
__workshopctl_to_alternatives() {
    local parts=( $1 )
    local IFS='|'
    echo "${parts[*]}"
}

__workshopctl_tags_to_extglob() {
    local extglob=$( __workshopctl_to_alternatives "$1" )
    echo "@($extglob)"
}

aws_list_tags() {
    # Print all instance ClientTokens in our region
    aws ec2 describe-instances --query "Reservations[*].Instances[*].ClientToken" \
        | tr '\t' '\n' \
        | sort -u
}

__workshopctl_tags() {
    aws_list_tags
}

__workshopctl_complete_tags() {
    __workshopctl_check_auth && return

    local IFS=$'\n'
    local tags=( $(__workshopctl_tags $1) )
    unset IFS
    COMPREPLY=( $(compgen -W "${tags[*]}" -- "$cur") )
}

_workshopctl() {
    local previous_extglob_setting=$(shopt -p extglob)
    shopt -s extglob

    local commands=$(workshopctl --generate-bash-completion)

    # These options are valid as global options for all client commands
    local global_boolean_options="
            --help
            --generate-bash-completion
    "
    local global_options_with_args="
    "

    COMPREPLY=()
    local cur prev words cword
    _get_comp_words_by_ref -n : cur prev words cword

    local command='workshopctl' command_pos=0 subcommand_pos
    local counter=1
    while [ $counter -lt $cword ]; do
        case "${words[$counter]}" in
            -*)
                ;;
            *)
                command="${words[$counter]}"
                command_pos=$counter
                break
                ;;
        esac
        (( counter++ ))
    done

    local completions_func=_workshopctl_${command}
    declare -F $completions_func >/dev/null && $completions_func

    eval "$previous_extglob_setting"
    return 0
}

_workshopctl_workshopctl() {
    local boolean_options="
        $global_boolean_options
        --help
        --version
    "

    case "$cur" in
        -*)
            COMPREPLY=( $( compgen -W "$boolean_options $global_options_with_args" -- "$cur" ) )
            ;;
        *)
            COMPREPLY=( $( compgen -W "${commands[*]} help" -- "$cur" ) )
            ;;
    esac
}

_workshopctl_cards() {
    case "$prev" in
        $(__workshopctl_tags_to_extglob "$(__workshopctl_tags)") )
            _filedir -f #-X '!*.@(yml|YML|yaml|YAML)'
            ;;
        *)
            __workshopctl_complete_tags
            return
            ;;
    esac
}

_workshopctl_deploy() {
    case "$prev" in
        $(__workshopctl_tags_to_extglob "$(__workshopctl_tags)") )
            _filedir -f #-X '!*.@(yml|YML|yaml|YAML)'
            ;;
        *)
            [ -f "$prev" ] && return  # if last argument was a file, we're done here
            __workshopctl_complete_tags
            return
            ;;
    esac
}

_workshopctl_ids() {
    case "$prev" in
        $(__workshopctl_tags_to_extglob "$(__workshopctl_tags)") )
            return
            ;;
        *)
            __workshopctl_complete_tags
            return
            ;;
    esac
}

_workshopctl_ips() {
    case "$prev" in
        $(__workshopctl_tags_to_extglob "$(__workshopctl_tags)") )
            return
            ;;
        *)
            __workshopctl_complete_tags
            return
            ;;
    esac
}

_workshopctl_start() {
    case "$prev" in
        # If the previous argument is a number, then the next argument should be a file
        [0-9]*)
            _filedir -f #-X '!*.@(yml|YML|yaml|YAML)'
            return
            ;;
        *)
            return
            ;;
    esac
}

_workshopctl_status() {
    case "$prev" in
        $(__workshopctl_tags_to_extglob "$(__workshopctl_tags)") )
            return
            ;;
        *)
            __workshopctl_complete_tags
            return
            ;;
    esac
}

_workshopctl_stop() {
    case "$prev" in
        $(__workshopctl_tags_to_extglob "$(__workshopctl_tags)") )
            return
            ;;
        *)
            __workshopctl_complete_tags
            return
            ;;
    esac
}

_workshopctl_stop() {
    case "$prev" in
        $(__workshopctl_tags_to_extglob "$(__workshopctl_tags)") )
            return
            ;;
        *)
            __workshopctl_complete_tags
            return
            ;;
    esac
}

complete -F _workshopctl workshopctl
