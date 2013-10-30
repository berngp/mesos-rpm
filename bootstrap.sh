#!/bin/bash -x

#GITHUB:    https://github.com/apache/mesos/archive/%{commit}/%{name}-%{version}-%{shortcommit}.tar.gz
#ASF:       https://dist.apache.org/repos/dist/release/mesos/

_DIR=`pwd`

SPEC="mesos-glabs.spec"

REPO_NAME="mesos"
REMOTE_REPO="github"
BUILD_DIR="`pwd`/build"
GIT_SOURCE_URL="https://github.com/apache/mesos"

# Internal Flags
_DEBUG=0
_INC_HASH_QUALIFIER=0
_INC_BUILDNUM_QUALIFIER=0

# Reference Hidden Files.
_REMOTE_SRC_FILE_F=".remote-src"
_REMOTE_SRC_TAR_F=".remote-tar"
_COMMIT_HASH_F=".commit-hash"
_MESOS_V_F=".mesos-version"
_MESOS_SRPM_F=".mesos-srpm"

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
    [ $_DEBUG -eq 1 ] && echo -e "[DEBUG]: $1"
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

## 
# Git Functions, require to be executed in a full git repo.
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
######

function _init_build_dir {
    mkdir -p "$BUILD_DIR/BUILD"
    mkdir -p "$BUILD_DIR/RPMS"
    mkdir -p "$BUILD_DIR/SOURCES"
    mkdir -p "$BUILD_DIR/SPECS"
    mkdir -p "$BUILD_DIR/SRPMS"

    [ -z "$SPEC" ] && error_exit "No spec file defined!"

    _spec_file="spec/${SPEC}"
    [ ! -f "$_spec_file" ] && error_exit "Spec file $_spec_file not found!"

    cp $_spec_file "$BUILD_DIR/SPECS/mesos.spec"

    info_msg "RPM spec file set to $SPEC"
    # copy additional sources 
    cp -r src/* "$BUILD_DIR/SOURCES"
}

function _get_mesos_version {
    _mesos_configure_f="$1/configure.ac"
    [ ! -f "$_mesos_configure_f"  ] && error_exit "No configure.ac file available at $1"

    _mesos_version="$(perl -wn -e '/AC_INIT\(\[mesos\], \[([\d.]+)\]\)/ && print $1 and close $ARGV' $_mesos_configure_f)"
    [ -z "$_mesos_version" ] && error_exit "Unable to resolve the Mesos version from $_mesos_configure_f !"
    echo "$_mesos_version"
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
        tar -z -x -C $_src_holder -f "$_src_holder/$_file" 2>&1
       
        # Obtain directory name holding the sources.
        _d="$(find $_src_holder -maxdepth 1 -type d -name "${_name}*" | tail -n 1 | xargs basename)"
        [ -z "$_d" ] && error_exit "No directory found inside the downloaded file. Please check contents of $_remote_path "

        # Obtain commit hash from directory name.
        _c="$(echo "$_d" | cut -f 2 -d '-')"
        [ -z "$_c" ] && error_exit "Directory name different than expected, expected is pattern <name>-<hash> but found $_d "

        #Target name of the sources.
        _sd="$_name-$_c"
        _t="${_sd}.tgz"
        _t_path="${BUILD_DIR}/SOURCES/${_t}"
        [ -d "$_t_path" ] && rm -rf "$_t_path"
        cp -r "${_src_holder}/${_file}" "$_t_path"

        info_msg "Remote sources downloaded and available at $_t"

        _mesos_version="$(_get_mesos_version "$_src_holder/$_d")"

        echo "$_c"  > "${BUILD_DIR}/$_COMMIT_HASH_F"
        echo "$_t"  > "${BUILD_DIR}/$_REMOTE_SRC_TAR_F"
        echo "$_sd" > "${BUILD_DIR}/$_REMOTE_SRC_FILE_F"
        echo "$_mesos_version" > "${BUILD_DIR}/$_MESOS_V_F"

    else
        error_exit "Remote source file not found at ${_src_holder}/${_file}"
    fi
}



function _get_jdk_version {
    [ ! -x "$1/bin/java" ] && error_exit "Unable to execute [$1/bin/java] !"

    _jdk_version=$("$1/bin/java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo "$_jdk_version"
}

function cmd_init-rpm {
    _init_build_dir

    if [ ! -f "${BUILD_DIR}/$_REMOTE_SRC_FILE_F" ]; then
        _remote_src_name="$(_get_src_from_github $REPO_NAME $TAG $COMMIT)"
    fi

    if [ -f "${BUILD_DIR}/$_REMOTE_SRC_TAR_F" ]; then
        _remote_src_tar="$(cat "${BUILD_DIR}/$_REMOTE_SRC_TAR_F")"
    else
        error_exit "Unable to read the remote tar file name ${BUILD_DIR}/${_REMOTE_SRC_TAR_F}!"
    fi
    debug_msg "Remote Src Tar resolves to: $_remote_src_tar"

    if [ -f "${BUILD_DIR}/$_REMOTE_SRC_FILE_F" ]; then
        _remote_src_name="$(cat "${BUILD_DIR}/$_REMOTE_SRC_FILE_F")"
    else
        error_exit "Unable to read the remote source file name ${BUILD_DIR}/${_REMOTE_SRC_FILE_F}!"
    fi
    debug_msg "Remote Src Name resolves to: $_remote_src_name"

    if [ -f "${BUILD_DIR}/$_COMMIT_HASH_F" ]; then
        _commit="$(cat "${BUILD_DIR}/$_COMMIT_HASH_F")"
    else
        error_exit "Unable to read the commit hash form file ${BUILD_DIR}/${_COMMIT_HASH_F}, look like the sources were not properly initialized!"
    fi
    debug_msg "Commit resolved to [$_commit]"

    if [ -f "${BUILD_DIR}/$_MESOS_V_F" ]; then
        _mesos_version="$(cat "${BUILD_DIR}/$_MESOS_V_F")"
    else
        error_exit "Unable to to get the Mesos Version from ${BULD_DIR}/${_MESOS_V_F}!"
    fi
    debug_msg "Resolved Mesos Version [$_mesos_version]"


    _build_qualifier="${TAG}"

    if [ $_INC_BUILDNUM_QUALIFIER -eq 1 ]; then
        [ -z "$_build_qualifier" ] && _build_qualifier="build" 
        _build_qualifier="${_build_qualifier}.${BUILD_NUMBER:-na}"
    fi

    if [ $_INC_HASH_QUALIFIER -eq 1 ]; then
        _sc="$(echo ${_commit:0:7})"
        _build_qualifier="${_build_qualifier}.${_sc}"
    fi
    debug_msg "Build qualifier resolved to [$_build_qualifier]"

    _jdk_home="$JAVA_HOME"
    debug_msg "JDK Home resolved to [$_jdk_home]"

    _jdk_version="$(_get_jdk_version "$_jdk_home")"
    debug_msg "JDK Version resolved to [$_jdk_version]"

    #$(cd $BUILD_DIR; autoreconf --install -Wall --verbose)

    echo "
export REMOTE_SRC_TAR=\"${_remote_src_tar}\"
export REMOTE_SRC_NAME=\"${_remote_src_name}\"
export MESOS_VERSION=\"${_mesos_version}\"
export BUILD_QUALIFIER=\"${_build_qualifier}\"
export JDK_HOME=\"${_jdk_home}\"
export JDK_VERSION=\"${_jdk_version}\"
    " > $BUILD_DIR/spec-env.sh

    return $?
}

function cmd_build-srpm {
    cmd_init-rpm

    msg="$(cd $BUILD_DIR; 
    source ./spec-env.sh; 
    rpmbuild -bs --define '_topdir '$BUILD_DIR SPECS/mesos.spec)"
    _out=$?
    info_msg "$msg"
    _srpm_path="$(echo "$msg" | awk '{print $2}')"
    #_srpm_name="$(basename "$_srpm_path")"

    echo "$_srpm_path" > "$BUILD_DIR/$_MESOS_SRPM_F"
    info_msg "SRPM name [$_srpm_path] stored at $BUILD_DIR/$_MESOS_SRPM_F"

    return $_out 
}

function cmd_build-rpm {
    cmd_init-rpm

    msg="$(cd $BUILD_DIR; 
    source ./spec-env.sh; 
    rpmbuild -ba --define '_topdir '$BUILD_DIR SPECS/mesos.spec)"
    _out=$?
    info_msg "$msg"

    return $_out
}

function cmd_mock-init {

    if [ -f "${BUILD_DIR}/$_MESOS_SRPM_F" ]; then
        _srpm_path="$(cat "${BUILD_DIR}/$_MESOS_SRPM_F")"
    else
        error_exit "Unable to read the SRPM path from file name ${BUILD_DIR}/${_MESOS_SRPM_F}!"
    fi
    debug_msg "SRPM Path : $_srpm_path"

    mock init
    debug_msg "Mock environment initialized."
    
    $( source "$BUILD_DIR/spec-env.sh";
        mock --copyin "$JAVA_HOME" "$JAVA_HOME";
        debug_msg "Mock: JAVA_HOME [$JAVA_HOME] copied." )

    mock --copyin "$BUILD_DIR/spec-env.sh" "/etc/profile.d/spec-env.sh"
    debug_msg "Mock: spec-env.sh copied."

    debug_msg "Mock: Installing dependencies as defined by the SRPM $_srpm_path"
    mock --installdeps "$_srpm_path"
}

function cmd_mock-rebuild {

    if [ -f "${BUILD_DIR}/$_MESOS_SRPM_F" ]; then
        _srpm_path="$(cat "${BUILD_DIR}/$_MESOS_SRPM_F")"
    else
        error_exit "Unable to read the SRPM path from file name ${BUILD_DIR}/${_MESOS_SRPM_F}!"
    fi
    debug_msg "SRPM Path : $_srpm_path"

    _mock_rslt_d="$BUILD_DIR/mock"
    [ -d "$_mock_rslt_d" ] && rm -rf "$_mock_rslt_d"
    mkdir -p "$_mock_rslt_d"

    msg="$(mock --rebuild --no-clean --no-cleanup-after --resultdir="$_mock_rslt_d" --verbose -- "$_srpm_path")"
    _out=$?

    info_msg "Mock: $msg"

    return $_out
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
            info_msg "The argument -r|--remote is not yet supported and will be ignored."
            shift
            ;;
        -b|--branch*)
            export BRANCH=`echo $1 | sed -e 's/^[^=]*=//g'`
            info_msg "The argument -b|--branch is not yet supported and will be ignored."
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
            info_msg "Debug Enabled"
            export _DEBUG=1
            shift
            ;;
        --hashq*)
            info_msg "Including Hash as part of the build qualifier."
            export _INC_HASH_QUALIFIER=1
            shift
            ;;
        --buildnumq*)
            info_msg "Including Build Number as part of the build qualifier."
            export _INC_BUILDNUM_QUALIFIER=1
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

