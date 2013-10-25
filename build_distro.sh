#!/bin/bash

export REMOTE="origin"
export BUILD_DIR="`pwd`/build"
export GIT_SOURCE_URL="https://github.com/apache/mesos"

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

function error_exit {
    echo "ERROR: ${1:-"Unknown Error"}" 1>&2
    exit 1
}

function _echo_usage {
   echo -e $USAGE >&2 
}

function _init_build_dir {
    mkdir -p "$BUILD_DIR"
    cp -r src/* $BUILD_DIR
}

function _get_latest_git_tag {
    _latest_tag="`git show-ref --tags | grep $1 | tail -n 1 | cut -f 2 -d ' ' | cut -f 3 -d '/'`"
    echo $_latest_tag
}

function _get_hash_from_tag {
   _hash="`git rev-list $1 | head -n 1`" 
   echo "$_hash"
}

function _git_qualifier_file {
    GIT_QUALIFIER="`git symbolic-ref HEAD 2> /dev/null | cut -b 12-`-`git log --pretty=format:\"%h\" -1`"
    echo "$GIT_QUALIFIER" | sed 's/\//_/g' > .git-qualifier
    echo "$GIT_QUALIFIER"
}

function _set_remote_src_github {
    _name=$1
    _version=$2
    _commit=$3

    _shortcommit="`c=$_commit; echo ${c:0:7}`"
    _file="mesos-${_version}-${_shortcommit}.tar.gz"

    _src_holder="${BUILD_DIR}/remote_src"
    if [ -d $_src_holder  ]; then
        rm -rf $_src_holder
    fi

    mkdir -p $_src_holder

    curl -L "$GIT_SOURCE_URL/archive/${commit}/${_file}" > "${_src_holder}/${_file}"

    if [ -f "$_src_holder/$_file" ]; then
        cd $_src_holder; tar xfz $_file
    else
        error_exit "Remote source file not found at ${_src_holder}/${_file}"
    fi
}

function _set_templates {
    # Copy templates.
    cp -r templates/* $BUILD_DIR
}

function run {
    [ -z "$QUALIFIER" ] || $QUALIFIER="" 
    # not using endpoint right now, could be used to point to either github or apache sf repo.
    [ -z "$ENDPOINT" ]  || $ENDPOINT="github"
    [ -z "$VERSION" ]   || error_exit "No version was specified."
    [ -z "$COMMIT" ] && [ "$ENDPOINT" == "github" ] || error_exit "Please specify a commit hash if pulling from Github (your only option for now :) )."
    # initialize build dir. 
    _init_build_dir
    # Download sources
    _get_remote_src_github "mesos" $VERSION $HASH

}

while test $# -gt 0; do
    case "$1" in
        -h|--help)
            _echo_usage
            exit 0
            ;;
        -q|--qualifier*)
            export QUALIFIER=`echo $1 | sed -e 's/^[^=]*=//g'`
            shift
            ;;
        -e|--endpoint*)
            export ENDPOINT=`echo $1 | sed -e 's/^[^=]*=//g'`
            shift
            ;;
        -v|--version*)
            export VERSION=`echo $1 | sed -e 's/^[^=]*=//g'`
            shift
            ;;
        -c|--commit*)
            export COMMIT=`echo $1 | sed -e 's/^[^=]*=//g'`
            shift
            ;;
        *)
            break
            ;;
    esac
done

run 

