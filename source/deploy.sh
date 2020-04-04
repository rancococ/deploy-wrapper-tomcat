#!/usr/bin/env bash

##########################################################################
# deploy.sh
# --load   : load images
# --init   : init dir
# --deploy : deploy data.war
##########################################################################

set -e

# set author info
date1=`date "+%Y-%m-%d %H:%M:%S"`
date2=`date "+%Y%m%d%H%M%S"`
author="yong.ran@cdjdgm.com"

# envirionment


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

# args flag
arg_help=
arg_init=
arg_load=
arg_images_package=
arg_deploy=
arg_deploy_package=
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
args=`getopt -o h -a -l help,init,load:,deploy: -n "${source}" -- "$@"`
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
        --init | -init)
            info "option --init"
            arg_init=true
            arg_empty=false
            shift
            ;;
        --load | -load)
            info "option --load argument : $2"
            arg_load=true
            arg_empty=false
            arg_images_package=$2
            shift 2
            ;;
        --deploy | -deploy)
            info "option --deploy argument : $2"
            arg_deploy=true
            arg_empty=false
            arg_deploy_package=$2
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            error "Internal error!"
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
usage=$"`basename $0` [-h|--help] [--init] [--load=xxx.tgz] [--deploy=xxx.war]
       [-h|--help]
                       show help info.
       [--init]
                       init volume.
       [--load=xxx.tgz]
                       load images.
       [--deploy=xxx.war]
                       deploy war to datadir.
"


# init volume
fun_init_volume() {
    header "init volume : "
    hasdata=$(find "${base_dir}/volume" -type d -name data | wc -w)
    haslogs=$(find "${base_dir}/volume" -type d -name logs | wc -w)
    hastemp=$(find "${base_dir}/volume" -type d -name temp | wc -w)
    if [ ${hasdata} -gt 0 ]; then
        info "init data volume start."
        for datadir in `find "${base_dir}/volume" -type d -name data`; do
            info "init data volume : ${datadir}"
            chmod -R 777 ${datadir};
        done
        success "successfully initialized data volume"
    fi
    if [ ${haslogs} -gt 0 ]; then
        info "init logs volume start."
        for logsdir in `find "${base_dir}/volume" -type d -name logs`; do
            info "init logs volume : ${logsdir}"
            chmod -R 777 ${logsdir};
        done
        success "successfully initialized logs volume"
    fi
    if [ ${hastemp} -gt 0 ]; then
        info "init temp volume start."
        for tempdir in `find "${base_dir}/volume" -type d -name temp`; do
            info "init temp volume : ${tempdir}"
            chmod -R 777 ${tempdir};
        done
        success "successfully initialized temp volume"
    fi
    return 0
}

# load images
fun_load_images() {
    header "load images : "
    info "load image : ${arg_images_package}"
    docker load -i "${arg_images_package}";
    success "successfully loaded ${arg_images_package}"
    return 0
}

# deploy war
fun_deploy_war() {
    header "deploy war : "
    info "deploy war : ${arg_deploy_package}"
    suffix="${arg_deploy_package##*.}"
    if [ "x${suffix}" == "xwar" ]; then
        \rm -rf "${base_dir}/volume/tomcat/data/"
        mkdir -p "${base_dir}/volume/tomcat/data/"
        chmod -R 777 "${base_dir}/volume/tomcat/data/"
        unzip -q "${arg_deploy_package}" -d "${base_dir}/volume/tomcat/data/"
        success "successfully deployed ${arg_deploy_package}"
    else
        error "unsupported file format : ${arg_deploy_package}"
    fi
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

# init volume
if [ "x${arg_init}" == "xtrue" ]; then
    fun_init_volume;
fi

# load images
if [ "x${arg_load}" == "xtrue" ]; then
    if [ ! -f ${arg_images_package} ]; then
        usage "$usage";
        exit 1
    fi
    fun_load_images;
fi

# deploy war
if [ "x${arg_deploy}" == "xtrue" ]; then
    if [ ! -f ${arg_deploy_package} ]; then
        usage "$usage";
        exit 1
    fi
    fun_deploy_war;
fi

echo ""

# exit $?
