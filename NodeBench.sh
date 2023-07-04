#!/bin/bash

# constant
date_time_str="$(TZ="UST-8" date +%Y-%m-%d_%H-%M-%S)"
markdown_log_file="NodeBenchResult_${date_time_str}.md"

# clear log file
> $markdown_log_file

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
    elif [ -n "$(command -v curl)" ] ; then
        curl -sLo- $download_url
    else
        install wget
        wget -qO- $download_url
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


    echo -n "$title_prefix" >> $markdown_log_file
    green_color
    echo -ne '>>>>>>>>   '
    echo -ne $header | tee -a $markdown_log_file
    echo -ne '   <<<<<<<<'
    white_color
    echo | tee -a $markdown_log_file
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

function detailInfo(){
    print_header "详细信息"
    print_header "CPU" 2
    (
        if [ -n "$(command -v lscpu)" ] ; then
            echo 'lscpu';
            lscpu
        else
            echo "cat /proc/cpuinfo | sed -n 1,/^$/p";
            cat /proc/cpuinfo | sed -n 1,/^$/p
        fi
    ) | print_code_block
    print_header "Merory" 2
    (
        echo 'free -h';
        free -h
    ) | print_code_block
    print_header "Disk" 2
    (
        echo 'df -hT';
        df -hT
    ) | print_code_block
}

function create_server(){
    if [ -z "$(command -v nc)" ] ; then
        install netcat
    fi

    green_color
    echo -n "请输入http监听端口号，默认8765:"
    white_color
    read ans
    if [ -z "$ans" ] ; then
        ans=8765
    fi
    ip_addr="$(curl -sL ip.gs)"
    if echo $ip_addr | grep ':' ;then
        echo "请在浏览器中打开http://[${ip_addr}]:${ans}"
    else
        echo "请在浏览器中打开http://${ip_addr}:${ans}"
    fi
    echo "复制结束后，ctrl + c 结束"
    #while true; do
    (
        echo -ne "HTTP/1.1 200 OK\r\n"`
        `"Content-Length: $(wc -c < $markdown_log_file)\r\n"`
        `"content-type: text/plain; charset=utf-8\r\n\r\n";
        cat "$markdown_log_file" | \
        | sed 's/^.*\x1B\[0K//g' | \
          sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g'
    ) | \
    nc -l -p "$ans";
    #done
}

function main(){
    print_help

    yabs
    backtrace
    RegionRestrictionCheck
    detailInfo
    echo -ne "\e[1;33m是否进行单线程测速(y/N) default n: \e[m"
    read ans
    if [ "$ans" == 'y' -o "$ans" == 'Y' ] ; then
        hyperspeed
    fi
    echo -ne "\e[1;33m是否补充测试bench.sh(y/N) default n: \e[m"
    read ans
    if [ "$ans" == 'y' -o "$ans" == 'Y' ] ; then
        benchsh
    fi
    echo -ne "\e[1;33m是否开启本地服务器方便复制文件(Y/n) default y: \e[m"
    read ans
    if [ -z "$ans" ] ; then
        ans=y
    fi
    if [ "$ans" == 'y' -o "$ans" == 'Y' ] ; then
        create_server
    fi
}

main