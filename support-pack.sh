#!/bin/sh
#
#  Copyright (C) 2021-present Savoir-faire Linux Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

VERSION="0.1.0"

# Default configuration file
SUPPORT_PACK_CONF='/etc/support-pack/support-pack.conf'

TSTAMP=$(date +%Y%m%d-%H%M%S)

# Name of the working directory that will contain all support log files.
WORKDIR="/tmp/support-pack-${TSTAMP}"

# Name of the archive that will be created.
ARCHIVE="/tmp/support-pack-${TSTAMP}.tar.gz"

# This file is in the support-pack and contains a report of the execution of
# support-pack itself.
LOGFILE="support-pack.txt"

die()
{
    echo "$*" 1>&2
    exit 1
}

log_info()
{
    echo "[INFO ] $*" 1>&2
}

log_error()
{
    echo "[ERROR] $*" 1>&2
}

# Execute a command while adding the support-pack boilerplate.
#
# When wrapping a command with support_cmd,
#  * stdout remains unchanged
#  * stderr is captured in the support-pack log if the command returns a non-zero
#    code. Otherwise, stderr is discarded.
#
# arg1: the command to run
#
# example:
#   support_cmd ps | support_file process.txt
#
support_cmd()
{
    local ret

    echo "[SUPPORT-PACK] >>>> $*"
    log_info "Exec command \"$*\""
    local errfile=$(mktemp)

    # TERM is vt100 to avoid most color/control chars in generated text files.
    TERM=vt100 "$@" 2>"${errfile}"
    ret=$?
    if [ "${ret}" != "0" ]; then
        log_error "\"$*\" returned a non-zero error code: ${ret}"
        cat "${errfile}" | sed 's/^/\t-> /' 1>&2
    fi

    rm -f "${errfile}"
    echo
}

# Redirect stdin to a support-pack file.
# arg1: name of the file.
#
# examples:
#   support_cmd echo "Hello, World!" | support_file dummy.txt
#
support_log_file()
{
    local tmpfile=$(mktemp)
    cat >>"${tmpfile}"
    mv -f "${tmpfile}" "$WORKDIR/$1"
    log_info "Created file \"$1\""
}

# Copy a file to the support-pack.
# arg1: Source file.
# arg2: (optional) Name of the destination file in the support-pack. The name is
#       relative to the root of the support-pack.
#       If missing, use same name as source file.
support_pack_add_file()
{
    if [ ! -f "$1" ]; then
        log_error "$1 doesn't exist or is not a regular file."
        return
    fi

    local dst="$2"
    if [ -z "$dst" ]; then
        dst="$1"
    fi

    log_info "Copying \"$1\" to \"${WORKDIR}/${dst}\""
    mkdir -p "$(dirname "${WORKDIR}/${dst}")"
    cp "${1}" "${WORKDIR}/${dst}"
}

# Copy a directory to the support-pack.
# arg1: Source directory.
# arg2: (optional) Name of the destination directory in the support-pack.
#       The name is relative to the root of the support-pack.
#       If missing, use same name as source file.
support_pack_add_dir ()
{
    if [ ! -d "$1" ]; then
        log_error "$1 doesn't exist or is not a directory."
        return
    fi

    if [ -z "$2" ]; then
        log_error "copy_dir destination is empty."
        return
    fi

    log_info "Copying \"${1}\" to \"${WORKDIR}/${2}\""
    mkdir -p "$(dirname "${WORKDIR}/${2}")"
    cp -a "${1}" "${WORKDIR}/${2}"
}

usage()
{
cat <<EOF
Usage: $PROGNAME [OPTION] [CONFIG_FILE]
If [CONFIG_FILE] is specified, it is the configuration file used.
Otherwise, "${SUPPORT_PACK_CONF}" is used.
Options:
    -o <output>         Change destination path of the .tar.gz archive.
    -v or --version     Show version.
    -h or --help        Show this help text.
    --notgz             Skip tar file creation
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
    help|-h|"--help")
        usage
        exit 0
        ;;
    version|-v|"--version")
        echo $VERSION
        exit 0
        ;;
    -o)
        ARCHIVE=${2}
        shift
        ;;
    --notgz)
        NOTGZ="1"
        ;;
    -*)
        die "Unsupported flag: ${1}"
        ;;
    *)
        # Take config file as argument
        if [ -r "$1" ]; then
            SUPPORT_PACK_CONF="$(readlink -f "$1")"
        fi
        ;;
    esac
    shift
done

main()
{
    # Ensure cleanup of temporary files
    trap support_pack_cleanup EXIT

    # Cleanup anything left from the last execution of support-pack.
    rm -rf /tmp/support-pack-*

    # Create the working directory.
    mkdir -p "${WORKDIR}"

    # Run the support-pack config.
    # All stdout from the config file should be piped to a support-pack file, so
    # it's ok to ignore any remaining output.
    . "$SUPPORT_PACK_CONF"  2>&1 | tee -a "${WORKDIR}/${LOGFILE}" 1>&2

    # Tar the file.
    if [ -z "${NOTGZ}" ]; then
        log_info "Archiving files.."
        tar -C "${WORKDIR}" -cf - . | gzip -9c > "${ARCHIVE}" ||
            die "Fatal: Fail to create ${ARCHIVE}"
        local size=$(du -h ${ARCHIVE} | cut -f1)
        log_info "Archive \"${ARCHIVE}\" (${size}) has been created."

        # Outputs the name of the archive created.
        readlink -f "${ARCHIVE}"
    else
        # Outputs the name of the working directory.
        readlink -f "${WORKDIR}"
    fi
}

# Cleanup of temporary files
support_pack_cleanup()
{
    rm -rf "${tmpfile}" "${errfile}"
}

main
