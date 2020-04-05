#!/usr/bin/env bash

##########################################################################
# build.sh
# for centos 7.x
# author : yong.ran@cdjdgm.com
# require : docker and docker-compose
##########################################################################

# set -x
set -e

# set author info
date1=`date "+%Y-%m-%d %H:%M:%S"`
date2=`date "+%Y%m%d%H%M%S"`
author="yong.ran@cdjdgm.com"

set -o noglob

# font and color 
bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr0)

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
white=$(tput setaf 7)

# header and logging
header() { printf "\n${underline}${bold}${blue}> %s${reset}\n" "$@"; }
header2() { printf "\n${underline}${bold}${blue}>> %s${reset}\n" "$@"; }
info() { printf "${white}➜ %s${reset}\n" "$@"; }
warn() { printf "${yellow}➜ %s${reset}\n" "$@"; }
error() { printf "${red}✖ %s${reset}\n" "$@"; }
success() { printf "${green}✔ %s${reset}\n" "$@"; }
usage() { printf "\n${underline}${bold}${blue}Usage:${reset} ${blue}%s${reset}\n" "$@"; }

trap "error '******* ERROR: Something went wrong.*******'; exit 1" sigterm
trap "error '******* Caught sigint signal. Stopping...*******'; exit 2" sigint

set +o noglob

# entry base dir
pwd=`pwd`
base_dir="${pwd}"
source="$0"
while [ -h "$source" ]; do
    base_dir="$( cd -P "$( dirname "$source" )" && pwd )"
    source="$(readlink "$source")"
    [[ $source != /* ]] && source="$base_dir/$source"
done
base_dir="$( cd -P "$( dirname "$source" )" && pwd )"
cd "${base_dir}"

# envirionment
product_name="tomcat"
product_version="3.5.41.8"
images=(
registry.cdjdgm.com/wrapper/wrapper-tomcat:3.5.41.8-centos
)
temp_uuid="$(cat /proc/sys/kernel/random/uuid)"
build_home="/tmp/build_${temp_uuid}"

# args flag
arg_help=
arg_build=
arg_empty=true

# parse parameter
# echo $@
# define options, -o : short options, -a : simple mode for long options (starts with -), -l : long options
# no colon after, indicating no parameter
# followed by a colon to indicate that there is a required parameter
# followed by two colons to indicate that there is an optional parameter (the optional parameter must be next to the option)
# -n information on error
# -- it is also an option. for example, to create a directory named "-f", "mkdir -- -f" will be used
# $@ take the parameter list from the command line
# args=`getopt -o ab:c:: -a -l apple,banana:,cherry:: -n "${source}" -- "$@"`
args=`getopt -o h -a -l help,build -n "${source}" -- "$@"`
# terminate the execution when there is an error in the execution of getopt
if [ $? != 0 ]; then
    error "terminating..." >&2
    exit 1
fi
# echo ${args}
# reorder parameters(The purpose of using eval is to prevent the shell command in the parameter from being extended by mistake)
eval set -- "${args}"
# handling specific options
while true
do
    case "$1" in
        -h | --help | -help)
            info "option -h|--help"
            arg_help=true
            arg_empty=false
            shift
            ;;
        --build | -build)
            info "option --build"
            arg_build=true
            arg_empty=false
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            error "internal error!"
            exit 1
            ;;
    esac
done
# display parameters other than options (parameters without options will be last)
# arg is the built-in variable of getopt. the value in arg is $@ (the parameter passed in from the command line) after processing
for arg do
   warn "$arg";
done

##########################################################################

# show usage
usage=$"`basename $0` [-h|--help] [--build]
       [-h|--help]
                  show help info.
       [--build]
                  build ${product_name}.
"

# build
fun_build() {
    header "build ${product_name} : "

    info "init directory"
    \rm -rf "${build_home}"
    mkdir -p "${build_home}/${product_name}"

    info "copy files"
    \cp -rf "${base_dir}/source"/. "${build_home}/${product_name}"

    info "pull images"
    save_images=""
    for image in ${images[@]}; do
        docker pull ${image}
        save_images="${save_images} ${image}"
    done

    info "save images"
    docker save -o "${build_home}/${product_name}"/images.tgz ${save_images}

    find "${build_home}/${product_name}" | xargs touch
    find "${build_home}/${product_name}" -type d -print | xargs chmod 755
    find "${build_home}/${product_name}" -type f -print | xargs chmod 644
    find "${build_home}/${product_name}" -type f -name ".keep" | xargs rm -rf

    chmod 744 "${build_home}/${product_name}"/*.sh

    mkdir -p "${base_dir}/release"
    tar -C "${build_home}" -czf "${base_dir}"/release/${product_name}-${product_version}.tgz "${product_name}"

    \rm -rf "${build_home}"

    success "successfully builded registry."

    return 0
}

##########################################################################

# argument is empty
if [ "x${arg_empty}" == "xtrue" ]; then
    usage "$usage";
    exit 1
fi

# show usage
if [ "x${arg_help}" == "xtrue" ]; then
    usage "$usage";
    exit 1
fi

# build
if [ "x${arg_build}" == "xtrue" ]; then
    fun_build;
fi

echo ""

# exit $?
