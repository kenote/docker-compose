#!/bin/bash

CURRENT_DIR=$(cd $(dirname $0);pwd)

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

pattern_port="^[1-9]{1}[0-9]{1,4}$"

is_oversea() {
    curl --connect-timeout 5 https://www.google.com -s --head | head -n 1 | grep "HTTP/1.[01] [23].." &> /dev/null;
}

is_command() { command -v $@ &> /dev/null; }

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [默认$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

check_sys(){
    if [ $(uname) == 'Darwin' ]; then
        release='macos'
    elif [[ -f /etc/redhat-release ]]; then
        release="centos"
    elif cat /etc/issue | grep -q -E -i "debian"; then
        release="debian"
    elif cat /etc/issue | grep -q -E -i "ubuntu"; then
        release="ubuntu"
    elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
        release="centos"
    elif cat /proc/version | grep -q -E -i "debian"; then
        release="debian"
    elif cat /proc/version | grep -q -E -i "ubuntu"; then
        release="ubuntu"
    elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
        release="centos"
    fi
}

pre_check() {
    sys_echo "${yellow}检测系统环境中...${plain}"
    trap 'clear; exit' INT
    if (is_oversea); then
        REPOSITORY_RAW_ROOT="https://raw.githubusercontent.com/kenote/install"
        REPOSITORY_RAW_COMPOSE="https://raw.githubusercontent.com/kenote/docker-compose"
    else
        REPOSITORY_RAW_ROOT="https://gitee.com/kenote/install/raw"
        REPOSITORY_RAW_COMPOSE="https://gitee.com/kenote/docker-compose/raw"
    fi
    REPOSITORY_RAW_URL="$REPOSITORY_RAW_COMPOSE/main/zfile"
    curl -s $REPOSITORY_RAW_ROOT/main/linux/docker/help.sh | bash -s install
    DOCKER_WORKDIR=`[ -f $HOME/.docker_profile ] && cat $HOME/.docker_profile | grep "^DOCKER_WORKDIR" | sed -n '1p' | sed 's/\(.*\)=\(.*\)/\2/g' || echo "/home/docker-data"`
    clear
}

sys_echo() {
    if [[ $release == 'macos' ]]; then
        echo "$@"
    else
        echo -e "$@"
    fi
}

# 读取服务环境
read_server_env() {
    CONTAINER_ID=`docker container ls -a -q -f "ancestor=zhaojun1998/zfile"`
    if [[ $CONTAINER_ID == '' ]]; then
        sys_echo "${yellow}ZFile 服务未安装${plain}"
        return 1
    fi
    CONTAINER_STATUS=`docker inspect $CONTAINER_ID | jq -r ".[0].State.Status"`
    CONTAINER_WORKDIR=`docker inspect $CONTAINER_ID | jq -r ".[0].Config.Labels[\"com.docker.compose.project.working_dir\"]"`
    HTTP_PORT=`docker inspect $CONTAINER_ID | jq -r '.[0].NetworkSettings.Ports["8080/tcp"][0].HostPort'`
    UPLOAD_DIR=`cat $CONTAINER_WORKDIR/.env | grep -E "^UPLOAD_DIR=" | sed -E 's/\s//g' | sed 's/\(.*\)=\(.*\)/\2/g'`
    if [[ $1 == '' ]]; then
        echo
        if [[ $CONTAINER_STATUS == 'running' ]]; then
            sys_echo "状态 -- ${green}运行中${plain}"
        else
            sys_echo "状态 -- ${red}停止${plain}"
        fi
    fi
}

# 检查端口占有
lsof_port() {
    if [[ $1 == $2 ]]; then
        return 0
    fi
    if (lsof -i:$1 &> /dev/null); then
        sys_echo "${red}端口 [$1] 已被占用${plain}"
        return 1
    fi
}

# 设置文件变量值
set_file_env() {
    sed -i "s/$(cat $3 | grep -E "^$1=" | sed -e 's/[]\/$*.^[]/\\&/g')/$1=$(echo $2 | sed -e 's/[]\/$*.^[]/\\&/g')/" $3
}

# 配置参数
sett_server_env() {

    if [[ $1 == 'save' ]]; then
        sys_echo "${green}-----------------------------${plain}"
        sys_echo " 配置 ZFile 服务"
        sys_echo "${green}-----------------------------${plain}"
        EXCLUDE_HTTP_PORT=$HTTP_PORT
        
    fi
    while read -p "HTTP端口[$HTTP_PORT]: " _http_port
    do
        if [[ $_http_port == '' ]]; then
            _http_port=$HTTP_PORT
        fi
        if !(echo $_http_port | grep -E "$pattern_port" &> /dev/null); then
            sys_echo "${red}HTTP端口格式错误！${plain}"
            continue
        fi
        lsof_port $_http_port $EXCLUDE_HTTP_PORT
        if [[ $? == 1 ]]; then
            continue
        fi
        break
    done
    while read -p "本地策略存放路径[$UPLOAD_DIR]: " _upload_dir
    do
        if [[ $_upload_dir = '' ]]; then
            _upload_dir=$UPLOAD_DIR
        fi
        break
    done
    
    if [[ $1 == 'save' ]]; then
        confirm "确定要更新配置吗?" "n"
        if [[ $? == 0 ]]; then
            cd $CONTAINER_WORKDIR
            mkdir -p $_upload_dir
            set_file_env "HTTP_PORT" $_http_port .env
            set_file_env "UPLOAD_DIR" $_upload_dir .env
            echo
            docker-compose down
            docker-compose up -d
        else
            return 1
        fi
    fi
}

# 安装服务
install_server() {
    sys_echo "${green}-----------------------------${plain}"
    sys_echo " 安装 ZFile 服务"
    sys_echo "${green}-----------------------------${plain}"

    while read -p "安装路径[zfile]: " _workdir
    do
        if [[ $_workdir = '' ]]; then
            _workdir="zfile"
        fi
        _workdir=`[[ $_workdir =~ ^\/ ]] && echo "$_workdir" || echo "$DOCKER_WORKDIR/$_workdir"`
        break
    done

    # 创建工作目录
    mkdir -p $_workdir
    cd $_workdir
    mkdir -p {db,logs}

    # 拉取 compose 及 配置文件
    wget --no-check-certificate -qO docker-compose.yml $REPOSITORY_RAW_COMPOSE/main/zfile/compose.yml
    wget --no-check-certificate -qO .env $REPOSITORY_RAW_COMPOSE/main/zfile/.env.example
    wget --no-check-certificate -qO application.properties $REPOSITORY_RAW_COMPOSE/main/zfile/application.properties

    # 设置参数
    HTTP_PORT=`cat .env | grep -E "^HTTP_PORT=" | sed -E 's/\s//g' | sed 's/\(.*\)=\(.*\)/\2/g'`
    UPLOAD_DIR=`cat .env | grep -E "^UPLOAD_DIR=" | sed -E 's/\s//g' | sed 's/\(.*\)=\(.*\)/\2/g'`
    sett_server_env
    mkdir -p $_upload_dir
    set_file_env "HTTP_PORT" $_http_port .env
    set_file_env "UPLOAD_DIR" $_upload_dir .env

    # 启动服务
    echo
    docker-compose up -d
}

# 卸载服务
remove_server() {
    sys_echo "${green}-----------------------------${plain}"
    sys_echo " 卸载 ZFile 服务"
    sys_echo "${green}-----------------------------${plain}"

    cd $CONTAINER_WORKDIR
    echo
    docker-compose down -v

    confirm "是否要删除工作目录吗?" "n"
    if [[ $? == 0 ]]; then
        rm -rf $CONTAINER_WORKDIR
    fi
}

# 升级容器
update_server() {
    sys_echo "${green}-----------------------------${plain}"
    sys_echo " 升级 ZFile 容器"
    sys_echo "${green}-----------------------------${plain}"

    cd $CONTAINER_WORKDIR
    echo
    docker-compose down
    docker-compose up -d
}

show_menu() {
    num=$1
    max_num=8
    if [[ $num == '' ]]; then
        sys_echo "${green}ZFile -- 在线文件存储${plain}"
        echo
        sys_echo "${green} 0${plain}. 退出脚本"
        sys_echo "------------------------"
        sys_echo "${green} 1${plain}. 查看状态"
        sys_echo "${green} 2${plain}. 启动服务"
        sys_echo "${green} 3${plain}. 停止服务"
        sys_echo "${green} 4${plain}. 重启服务"
        sys_echo "------------------------"
        sys_echo "${green} 5${plain}. 安装服务"
        sys_echo "${green} 6${plain}. 卸载服务"
        sys_echo "${green} 7${plain}. 配置参数"
        sys_echo "${green} 8${plain}. 升级容器"

        echo && read -p "请输入选择 [0-$max_num]: " num
        echo
    fi

    case "${num}" in
    0 | x ) # 退出脚本
        clear && exit 0
    ;;
    1 ) # 查看状态
        clear
        read_server_env
        echo
        read  -n1  -p "按任意键继续" key
        clear
        show_menu
    ;;
    2 | 3 | 4 )
        clear
        read_server_env "only"
        if [[ $? == 1 ]]; then
            echo
            read  -n1  -p "按任意键继续" key
            clear
            show_menu
            return 1
        fi
        cd $CONTAINER_WORKDIR
        case "${num}" in
        2 )
            if [[ $CONTAINER_STATUS == 'running' ]]; then
                confirm "ZFile 服务正在运行, 是否要重启?" "n"
                if [[ $? == 0 ]]; then
                    echo
                    docker-compose restart
                else
                    clear
                    show_menu
                    return 0
                fi
            else
                echo
                docker-compose start
            fi
        ;;
        3 )
            if [[ $CONTAINER_STATUS == 'running' ]]; then
                echo
                docker-compose stop
            else
                echo
                sys_echo "${yellow}ZFile 服务已停止${plain}"
            fi
        ;;
        4 )
            echo
            docker-compose restart
        ;;
        esac
        read_server_env
        echo
        read  -n1  -p "按任意键继续" key
        clear
        show_menu
    ;;
    5 ) # 安装服务
        clear
        read_server_env "only"
        if [[ $? == 0 ]]; then
            sys_echo "${yellow}ZFile 服务已经安装${plain}"
            echo
            read  -n1  -p "按任意键继续" key
            clear
            show_menu
            return 1
        fi
        confirm "确定要安装 ZFile 服务吗?" "n"
        if [[ $? == 0 ]]; then
            clear
            install_server
            sys_echo "${green}ZFile 服务安装完毕${plain}"
            echo
            read  -n1  -p "按任意键继续" key
        fi
        clear
        show_menu
    ;;
    6 ) # 卸载服务
        clear
        read_server_env "only"
        if [[ $? == 1 ]]; then
            echo
            read  -n1  -p "按任意键继续" key
            clear
            show_menu
            return 1
        fi
        confirm "确定要卸载 ZFile 服务吗?" "n"
        if [[ $? == 0 ]]; then
            clear
            remove_server
            sys_echo "${green}ZFile 服务卸载完毕${plain}"
            echo
            read  -n1  -p "按任意键继续" key
        fi
        clear
        show_menu
    ;;
    7 ) # 配置参数
        clear
        read_server_env "only"
        if [[ $? == 1 ]]; then
            echo
            read  -n1  -p "按任意键继续" key
            clear
            show_menu
            return 1
        fi
        confirm "确定要重新配置 ZFile 服务吗?" "n"
        if [[ $? == 0 ]]; then
            clear
            sett_server_env "save"
            if [[ $? == 0 ]]; then
                echo
                read  -n1  -p "按任意键继续" key
            fi
        fi
        clear
        show_menu
    ;;
    8 ) # 升级容器
        clear
        read_server_env "only"
        if [[ $? == 1 ]]; then
            echo
            read  -n1  -p "按任意键继续" key
            clear
            show_menu
            return 1
        fi
        confirm "确定要升级 ZFile 相关容器吗?" "n"
        if [[ $? == 0 ]]; then
            clear
            update_server
            echo
            read  -n1  -p "按任意键继续" key
        fi
        clear
        show_menu
    ;;
    * )
        clear
        sys_echo "${red}请输入正确的数字 [0-$max_num]${plain}"
        echo
        show_menu
    ;;
    esac
}

clear
check_sys
pre_check
show_menu