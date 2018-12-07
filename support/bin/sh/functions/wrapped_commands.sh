#!/usr/bin/env bash
SURROUNDED_WITH_SINGLE_QUOTES="^\'.*\'$"
SURROUNDED_WITH_DOUBLE_QUOTES="^\".*\"$"
STARTS_WITH_HYPHEN="^-"
EQUALS_SIGN='='

_FUNCTIONS_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck source=support/bin/sh/functions/cic.sh
source "${_FUNCTIONS_PATH}/cic.sh"


function content_after() {
    local matcher=$1
    grep -o "${matcher}.*" | sed -e s/"^${matcher}"//
}

function content_before(){
    local matcher=$1
    cut -d "${matcher}" -f 1
}

function sanitise_value(){
    local unsanitised_value=$1
    if [[ "${unsanitised_value}" =~ ${SURROUNDED_WITH_DOUBLE_QUOTES} ]]
    then
        echo "'${unsanitised_value}'"
    else
        echo "\"${unsanitised_value}\""
    fi
}


function sanitise_option(){
    local unsanitised_option=$1

    local option
    option=$(echo "${unsanitised_option}" | content_before "=")
    local value
    value=$(echo "${unsanitised_option}" | content_after "=" )

    if [[ ! "${value}" =~ ${SURROUNDED_WITH_SINGLE_QUOTES} ]] &&
        [[ ! "${value}" =~ ${SURROUNDED_WITH_DOUBLE_QUOTES} ]]
    then
        echo "${option}=$(sanitise_value "${value}")"
    else
        echo "${unsanitised_option}"
    fi

}

function build_command(){
    local command=$1
    shift

    for argument in "$@"
    do
        if [[ "${argument}" =~ ${STARTS_WITH_HYPHEN} ]] && [[ "${argument}" =~ ${EQUALS_SIGN} ]]
        then
            argument=$(sanitise_option "${argument}")
        elif [[ "${argument}" =~ ${EQUALS_SIGN} ]]
        then
           argument=$(sanitise_value "${argument}")
        fi
        command="${command} ${argument}"
    done

    echo "${command}"
}

function standard_docker_options(){
    echo "-t" \
         "--privileged" \
         "--network $(cic_network)" \
         "-w $(cic_working_dir)"
}

function docker_mounts(){
    local mounts
    # Needed by cic commands
    mounts="-v /var/run/docker.sock:/var/run/docker.sock"
    mounts="${mounts} -v /sys/fs/cgroup:/sys/fs/cgroup:ro"
    mounts="${mounts} -v $(source_tracks_path):$(target_tracks_path)"
    mounts="${mounts} -v $(source_scaffold_path):$(target_scaffold_path)"
    mounts="${mounts} -v $(source_scaffold_structure):$(target_scaffold_structure)"
    mounts="${mounts} -v $(source_exercises_path):$(target_exercises_path)"
    mounts="${mounts} -v ${HOME}/.netrc:/root/.netrc"

    # Needed by all commands
    mounts="${mounts} -v $(working_directory):$(cic_working_dir)"

    echo "${mounts}"
}

function options_and_mounts(){
    local extra_options=$1
    echo "$(docker_mounts) ${extra_options} $(standard_docker_options)"
}

function run(){
    local options=($1)
    local image=$2
    shift 2

    local command="$(bootstrap_cic_environment) $(build_command "${@}")"
    docker run ${options[@]} "${image}" /bin/bash -ilc "${command}"
}

function run_command(){
    local image=$1
    shift

    run "$(options_and_mounts)" "${image}" "${@}"
}

function run_interactive_command(){
    local image=$1
    shift

    run "$(options_and_mounts -i)" "${image}" "${@}"
}