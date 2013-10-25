#!/bin/bash

#%global commit             @COMMIT_HASH@
#%global shortcommit        %(c=%{commit}; echo ${c:0:7})
#%global build_qualifier    @BULD_QUALIFIER@
#%global build_num          @BUILD_NUM@
#%global jdk_home           @JDK_HOME@
#%global jdk_version        @JDK_VERSION@
#%global mesos_version      @PACKAGE_VERSION@
#GITHUB:        https://github.com/apache/mesos/archive/%{commit}/%{name}-%{version}-%{shortcommit}.tar.gz
#ASF https://dist.apache.org/repos/dist/release/mesos/

_DIR=`pwd`

SPEC="mesos-glabs.spec"

REPO_NAME="mesos"
REMOTE_REPO="github"
BUILD_DIR="`pwd`/build"
GIT_SOURCE_URL="https://github.com/apache/mesos"

_DEBUG_F=0
_REMOTE_SRC_FILE_FF=".remote-src"

USAGE="
Bootstraps a build space for the mesos project.\n
options:\n
\t-h, --help              show brief help\n
\t--build=build_name      name of this build.\n
\t--remote=git_remote     git remote, defaults to '$REMOTE'. Only used if you specify a branch.\n
\t--branch=git_branch     git branch that we should use.\n
\t--commit=git_commit     git commit that we should use.\n
\t--tag=git_tag           git tag that we should use.\n
"

function echo_usage {
    echo -e $USAGE >&2
}

function debug_msg {
    [ $_DEBUG_F -eq 1 ] && echo -e "[DEBUG]: $1"
}

function info_msg {
    echo -e "[INFO]: $1"
}

function warn_msg {
    echo -e "[WARN]: $1"
}

function error_exit {
    echo -e "ERROR: ${1:-"Unknown Error"}" 1>&2
    exit 1
}

function _get_latest_git_tag {
    if [ -z $1 ]; then
        _latest_tag=""
    else
        _latest_tag="`git show-ref --tags | grep $1 | tail -n 1 | cut -f 2 -d ' ' | cut -f 3 -d '/'`"
    fi
    echo $_latest_tag
}

function _get_hash_from_tag {
   _hash="`git rev-list $1 | head -n 1`" 
   echo "$_hash"
}

function _generate_hash_qualifier_file {
    GIT_QUALIFIER="`git symbolic-ref HEAD 2> /dev/null | cut -b 12-`-`git log --pretty=format:\"%h\" -1`"
    echo "$GIT_QUALIFIER" | sed 's/\//_/g' > "${1:-./build}/.git-qualifier"
    echo "$GIT_QUALIFIER"
}

function _init_build_dir {
    mkdir -p "$BUILD_DIR"
    [ -z "$SPEC" ] && error_exit "No spec file defined!"
    [ ! -f "spec/$SPEC" ] && error_exit "Spec file spec/$SPEC not found!"

    cp "spec/$SPEC" "$BUILD_DIR"
    info_msg "RPM spec file set to $SPEC"
    # copy additional sources 
    cp -r src/* $BUILD_DIR
}

function _get_src_from_github {
    _name=${1:-mesos}
    _tag=${2:-HEAD}
    _commit=${3:-HEAD}

    _file="${_name}-${_tag}-${_commit}.tar.gz"

    _src_holder="${BUILD_DIR}/remote_src"
    if [ -d $_src_holder  ]; then
        rm -rf $_src_holder
    fi

    mkdir -p $_src_holder

    _remote_path="$GIT_SOURCE_URL/archive/${_commit}/${_file}"
    info_msg "Downloading $_remote_path "
    curl -L "$_remote_path" > "${_src_holder}/${_file}"

    if [ -f "$_src_holder/$_file" ]; then
        debug_msg "Untar file $_file at dir $_src_holder "
        tar -z -x -C $_src_holder -f "$_src_holder/$_file"
       
        # Obtain directory name holding the sources.
        _d="$(find $_src_holder -name "${_name}*" -type d -maxdepth 1  | tail -n 1 | xargs basename)"
        [ -z "$_d" ] && error_exit "No directory found inside the downloaded file. Please check contents of $_remote_path "

        # Obtain commit hash from directory name.
        _c="$(echo "$_d" | cut -f 2 -d '-')"
        [ -z "$_c" ] && error_exit "Directory name different than expected, expected is pattern <name>-<hash> but found $_d "

        #Target name of the sources.
        _sd="$_name-$_c"
        _t="${BUILD_DIR}/${_sd}"

        cp -r "${_src_holder}/${_d}" $_t
        info_msg "Remote sources downloaded and available at $_t"
        echo "$_sd" > "${BUILD_DIR}/$_REMOTE_SRC_FILE_FF"
        echo "$_sd"

    else
        error_exit "Remote source file not found at ${_src_holder}/${_file}"
    fi
}

function cmd_init-srpm {
    _init_build_dir
    _remote_src_name="$(_get_src_from_github $REPO_NAME $TAG $COMMIT)"
    return $?
}

function cmd_build-srpm {
    _init_build_dir
    _remote_src_name="$(_get_src_from_github $REPO_NAME $TAG $COMMIT)"
    return $?
}


function cmd_default {
    echo "Nothing to do, please provide a command."
}

function main {
    if [ -n "$_CMD" ]; then
        _c="cmd_$_CMD"
        if [ $(declare -F "$_c") ]; then
            $_c
        else
            error_exit "Command $_CMD not supported."
        fi
    else
        cmd_default
    fi
}

while test $# -gt 0; do
    case "$1" in
        -h|--help)
            echo_usage
            exit 0
            ;;
        -d|--dir*)
            export BUILD_DIR=`echo $1 | sed -e 's/^[^=]*=//g'`
            shift
            ;;
        -r|--remote*)
            export REMOTE=`echo $1 | sed -e 's/^[^=]*=//g'`
            shift
            ;;
        -b|--branch*)
            export BRANCH=`echo $1 | sed -e 's/^[^=]*=//g'`
            shift
            ;;
        -c|--commit*)
            export COMMIT=`echo $1 | sed -e 's/^[^=]*=//g'`
            shift
            ;;
        -h|--tag*)
            export TAG=`echo $1 | sed -e 's/^[^=]*=//g'`
            shift
            ;;
        -s|--spec*)
            export SPEC=`echo $1 | sed -e 's/^[^=]*=//g'`
            shift
            ;;
        --debug*)
            export _DEBUG_F=1
            shift
            ;;
        --command*)
            export _CMD=`echo $1 | sed -e 's/^[^=]*=//g'`
            shift
            ;;
        --latest-tag*)
            _tag=`echo $1 | sed -e 's/^[^=]*=//g'`
            [ "$_tag" == "--latest-tag"] && _tag=""
            if [ -n "$_tag" ]; then
                _get_latest_git_tag $tag
            else
                echo_usage
            fi
            exit $?
            ;;
        --tag-hash*)
            _tag=`echo $1 | sed -e 's/^[^=]*=//g'`
            [ "$_tag" == "--tag-hash"] && _tag=""
            if [ -n "$_tag" ]; then
                echo $(_get_hash_from_tag "$_tag")
            else
                echo_usage
            fi
            exit $?
            ;;
        --generate-hash-file*)
            _out=`echo $1 | sed -e 's/^[^=]*=//g'`
            [ "$_out" == "--generate-hash-file" ] && _out=""

            _generate_hash_qualifier_file "$_out"
            exit $?
            ;;
        *)
            break
            ;;
    esac
done

main

