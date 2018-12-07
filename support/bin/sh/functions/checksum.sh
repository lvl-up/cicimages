#!/usr/bin/env bash

# shellcheck source=support/bin/sh/functions/utils.sh
CHECKSUM_SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${CHECKSUM_SCRIPT_PATH}/functions/utils.sh"

function check_required_enviroment_is_set() {
    exit_unless_var_defined TRACKS_PATH && exit_unless_directory_exists "${TRACKS_PATH}"
    exit_unless_var_defined EXERCISES_PATH && exit_unless_directory_exists "${EXERCISES_PATH}"
    exit_unless_var_defined SCAFFOLD_PATH && exit_unless_directory_exists "${SCAFFOLD_PATH}"
    exit_unless_var_defined SCAFFOLD_STRUCTURE && exit_unless_file_exists "${SCAFFOLD_STRUCTURE}"
    exit_unless_var_defined CIC_COURSEWARE_VERSION
    exit_unless_var_defined CIC_COURSEWARE_IMAGE
}