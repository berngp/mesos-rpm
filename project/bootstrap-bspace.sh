#!/bin/bash

export REMOTE="origin"

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

function run {
    if [ -z $BUILD_DIR ]; then
        echo "Please specify the build directory $BUILD_DIR!"
        exit 1
    fi
    echo "Initializing build dir $BUILD_DIR .."
    _init_build_dir
    echo "Setting git baseline.."
    _set_git_baseline
    echo "Setting templates.. "
    _set_templates
    echo "done."
}

function _init_build_dir {
    if [ ! -d repo/mesos ]; then
        echo "The Git repository at repo/mesos is missing."
        exit 1
    fi
    
    if [ -d $BUILD_DIR ]; then 
        rm -rf "$BUILD_DIR"
    fi

    mkdir -p "$BUILD_DIR"
    mkdir "$BUILD_DIR/m4"
    mkdir "$BUILD_DIR/tmp"

    if [ -d $BUILD_DIR/src ]; then
        rm -rf $BUILD_DIR/src
    fi
    mkdir "$BUILD_DIR/src"

    cp -r repo/mesos $BUILD_DIR/tmp
}

function _set_git_baseline {
    cd $BUILD_DIR/tmp/mesos

    if [  ! -z $TAG ]; then
        git checkout $TAG; 
    elif [ ! -z $COMMIT ]; then 
        git checkout $COMMIT
    elif [ ! -z $BRANCH ]; then 
        echo "Checking out branch $BRANCH form $REMOTE"
        git checkout -b ${BRANCH} ${REMOTE}/${BRANCH} 
    else 
        echo "No TAG, COMMIT, or BRANCH specified!"; 
    fi 

    GIT_QUALIFIER="`git symbolic-ref HEAD 2> /dev/null | cut -b 12-`-`git log --pretty=format:\"%h\" -1`"
    echo "$GIT_QUALIFIER" | sed 's/\//_/g' > .git-qualifier
    #rm -rf .git

    # move back to $BUILD_DIR/tmp
    cd ../
    # tar contents in tmp.
    tar cvfz mesos.tgz .
    # save git qualifier
    mv mesos/.git-qualifier ../
    # set source
    mv mesos.tgz ../src
    # move back to $BUILD_DIR
    cd $_DIR
    # remove tmp
    rm -rf $BUILD_DIR/tmp
    
}

function _set_templates {
    # Copy templates.
    cp -r templates/* $BUILD_DIR
}

while test $# -gt 0; do
    case "$1" in
        -h|--help)
            echo -e $USAGE >&2
            exit 0
            ;;
        --build*)
            export BUILD_DIR=`echo $1 | sed -e 's/^[^=]*=//g'`
            shift
            ;;
        --remote*)
            export REMOTE=`echo $1 | sed -e 's/^[^=]*=//g'`
            shift
            ;;
        --branch*)
            export BRANCH=`echo $1 | sed -e 's/^[^=]*=//g'`
            shift
            ;;
        --commit*)
            export COMMIT=`echo $1 | sed -e 's/^[^=]*=//g'`
            shift
            ;;
        --tag*)
            export TAG=`echo $1 | sed -e 's/^[^=]*=//g'`
            shift
            ;;
        *)
            break
            ;;
    esac
done

run 

