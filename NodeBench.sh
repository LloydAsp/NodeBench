#!/bin/bash

# constant
date_time_str="$(TZ="UST-8" date +%Y-%m-%d_%H-%M-%S)"
markdown_log_file="NodeBenchResult_${date_time_str}.md"
api_url="https://nb.util.eu.org/api/bench/"

function green_color(){
    echo -ne "\e[1;32m"
}
function white_color(){
    echo -ne "\e[m"
}
function yellow_color(){
    echo -ne "\e[1;33m"
}

function print_help(){
    green_color
    cat <<- EOF
		NodeBench: Vps综合测试脚本，用于在NodeSeek发表测评文章
		Author: Lloyd@nodeseek.com

	EOF
    white_color
}

function install(){
    if [ -n "$(command -v apt)" ] ; then
        cmd1="apt-get"
        cmd2="apt-get install -y"
    elif [ -n "$(command -v yum)" ] ; then
        cmd1="yum"
        cmd2="yum install -y"
    elif [ -n "$(command -v dnf)" ] ; then
        cmd1="dnf"
        cmd2="dnf install -y"
    elif [ -n "$(command -v apk)" ] ; then
        cmd1="apk"
        cmd2="apk add"
    else
        echo "Error: Not Supported Os"
        exit 1
    fi
    $cmd1 update
    $cmd2 "$@"
}

function fetch(){
    download_url="$1"
    if [ -n "$(command -v wget)" ] ; then
        wget -qO- $download_url
        fetch_cmd="wget"
    elif [ -n "$(command -v curl)" ] ; then
        curl -sLo- $download_url
        fetch_cmd="curl"
    else
        install wget
        wget -qO- $download_url
        fetch_cmd="wget"
    fi
}

function print_header(){
    header=$1

    if [ -n "$2" ] ; then
        title_level=$2
    else
        title_level=1
    fi

    title_prefix=" "
    for _ in $(seq 1 $title_level) ; do
        title_prefix="#"$title_prefix
    done


    green_color | tee -a $markdown_log_file
    echo -ne $title_prefix | tee -a $markdown_log_file
    echo -ne $header | tee -a $markdown_log_file
    white_color | tee -a $markdown_log_file
    echo -e '\n' | tee -a $markdown_log_file
}

function print_code_block(){
    echo '```' >> $markdown_log_file
    tee -a $markdown_log_file
    echo '```' >> $markdown_log_file
}

function print_markdown_block(){
    print_header $1
    print_code_block
}

function yabs(){
    fetch 'https://yabs.sh' | bash -s -- -5 -6 | print_markdown_block Yabs测试
}

function backtrace(){
    fetch 'https://raw.githubusercontent.com/zhanghanyun/backtrace/main/install.sh' | \
        bash  2>&1 | print_markdown_block 三网回程路由测试
}

function RegionRestrictionCheck(){
    num=0 bash <(fetch https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh | \
        sed -E '/请输入正确数字或直接按回车:/d') | sed -n '/正在测试/,/测试已结束/p' | \
        print_markdown_block 流媒体平台及游戏区域限制测试
}

function hyperspeed(){
    bash <(fetch https://bench.im/hyperspeed) | \
        print_markdown_block 单线程测速
}

function benchsh(){
    fetch bench.sh | bash | \
        print_markdown_block bench.sh测试
}

function main(){
    print_help

    yabs
    backtrace
    RegionRestrictionCheck
    echo -ne "\e[1;33m是否进行单线程测速(Y/n) default Y: \e[m"
    read ans
    if [ -z "$ans" ] ; then
        ans=y
    fi
    if [ "$ans" == 'y' -o "$ans" == 'Y' ] ; then
        hyperspeed
    fi
    echo -ne "\e[1;33m是否补充测试bench.sh(y/N) default n: \e[m"
    read ans
    if [ "$ans" == 'y' -o "$ans" == 'Y' ] ; then
        benchsh
    fi

    if [ $fetch_cmd == 'curl' ] ; then
        curl -s --data-binary=@"$markdown_log_file" "$api_url"
    else
        wget -qO- --post-file "$markdown_log_file" "$api_url" | cat
    fi
}

main