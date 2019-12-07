#!/usr/bin/env bash

##########################################################################
# deploy.sh
# --load   : 加载镜像
# --init   : 初始目录
##########################################################################

set -e

#
# set author info
#
date1=`date "+%Y-%m-%d %H:%M:%S"`
date2=`date "+%Y%m%d%H%M%S"`
author="yong.ran@cdjdgm.com"

#
# envirionment
#


set -o noglob

#
# font and color 
#
bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr0)

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
white=$(tput setaf 7)

#
# header and logging
#
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

#
# entry base dir
#
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

#
# args flag
#
arg_help=
arg_load=
arg_init=
arg_empty=true

arg_package=

#
# parse parameter
#
# echo $@
# 定义选项， -o 表示短选项 -a 表示支持长选项的简单模式(以 - 开头) -l 表示长选项 
# a 后没有冒号，表示没有参数
# b 后跟一个冒号，表示有一个必要参数
# c 后跟两个冒号，表示有一个可选参数(可选参数必须紧贴选项)
# -n 出错时的信息
# -- 也是一个选项，比如 要创建一个名字为 -f 的目录，会使用 mkdir -- -f ,
#    在这里用做表示最后一个选项(用以判定 while 的结束)
# $@ 从命令行取出参数列表(不能用用 $* 代替，因为 $* 将所有的参数解释成一个字符串
#                         而 $@ 是一个参数数组)
# args=`getopt -o ab:c:: -a -l apple,banana:,cherry:: -n "${source}" -- "$@"`
args=`getopt -o h -a -l help,load:,init -n "${source}" -- "$@"`
# 判定 getopt 的执行时候有错，错误信息输出到 STDERR
if [ $? != 0 ]; then
    error "Terminating..." >&2
    exit 1
fi
# echo ${args}
# 重新排列参数的顺序
# 使用eval 的目的是为了防止参数中有shell命令，被错误的扩展。
eval set -- "${args}"
# 处理具体的选项
while true
do
    case "$1" in
        -h | --help | -help)
            info "option -h|--help"
            arg_help=true
            arg_empty=false
            shift
            ;;
        --load | -load)
            info "option --load argument : $2"
            arg_load=true
            arg_empty=false
            arg_package=$2
            shift 2
            ;;
        --init | -init)
            info "option --init"
            arg_init=true
            arg_empty=false
            shift
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
#显示除选项外的参数(不包含选项的参数都会排到最后)
# arg 是 getopt 内置的变量 , 里面的值，就是处理过之后的 $@(命令行传入的参数)
for arg do
   warn "$arg";
done

# show usage
usage=$"`basename $0` [-h|--help] [--load=xxx.tgz] [--init]
       [-h|--help]
                       show help info.
       [--load=xxx.tgz]
                       load images.
       [--init]
                       init volume.
"


# load images
fun_load_images() {
    header "load images : "
    info "load image : ${arg_package}"
    docker load -i "${arg_package}";
    success "successfully loaded ${arg_package}"
    return 0
}

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

# load images
if [ "x${arg_load}" == "xtrue" ]; then
    if [ ! -f ${arg_package} ]; then
        usage "$usage";
        exit 1
    fi
    fun_load_images;
fi

# init volume
if [ "x${arg_init}" == "xtrue" ]; then
    fun_init_volume;
fi

echo ""

exit $?
