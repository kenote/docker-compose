#!/bin/bash

CURRENT_DIR=$(cd $(dirname $0);pwd)

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

CURRENT_DIR=$(cd $(dirname $0);pwd)

SSS_BASE_PATH="/opt/sss"
SSS_AGENT_PATH="$SSS_BASE_PATH/agent"
SERVICE_NAME="sss-agent.service"
SSS_AGENT_SERVICE="/etc/systemd/system/$SERVICE_NAME"

pattern_port="^[1-9]{1}[0-9]{1,4}$"
pattern_ip="^(2[0-4][0-9]|25[0-5]|1[0-9][0-9]|[1-9]?[0-9])(\.(2[0-4][0-9]|25[0-5]|1[0-9][0-9]|[1-9]?[0-9])){3}$"

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
    REPOSITORY_RAW_URL="$REPOSITORY_RAW_COMPOSE/main/serverstatus"
}

sys_echo() {
    if [[ $release == 'macos' ]]; then
        echo "$@"
    else
        echo -e "$@"
    fi
}

# 读取客户机环境
read_agent_env() {
    if !(systemctl list-unit-files | grep "$SERVICE_NAME"  &> /dev/null); then
        sys_echo "${yellow}Server Status 客户机未安装${plain}"
        return 1
    fi
    AGENT_STATUS=`systemctl status $SERVICE_NAME | grep "active" | cut -d '(' -f2|cut -d ')' -f1`
    if [[ $1 == '' ]]; then
        echo
        if [[ $AGENT_STATUS == 'running' ]]; then
            sys_echo "状态 -- ${green}运行中${plain}"
        else
            sys_echo "状态 -- ${red}停止${plain}"
        fi
    fi
}

# 获取参数里的值
get_param_val() {
    eval _$2=`echo "$1" | sed -E 's/--([0-9a-zA-Z\-]+)\s/\1\=/g' | sed 's/\s/\n/g' | grep -E "^$2=" | sed -E 's/([0-9a-zA-Z\-]+)\=([^\s+])/\2/'`
}

# 获取参数
get_param() {
    keycode=`echo "$1" | base64 --decode`
    get_param_val "$keycode" host
    get_param_val "$keycode" port
    get_param_val "$keycode" user
    get_param_val "$keycode" pass
}

# 配置参数
sett_agent_env() {
    _default_port=`cat $SSS_AGENT_PATH/client-linux.py | grep -E "^PORT" | sed -E 's/\s//g' | sed 's/\(.*\)=\(.*\)/\2/g'`
    while [ ${#} -gt 0 ];
    do
        case "$1" in
        --host | -H )
            _host=$2
            shift
        ;;
        --port | -P )
            _port=$2
            shift
        ;;
        --user )
            _user=$2
            shift
        ;;
        --pass )
            _pass=$2
            shift
        ;;
        --token )
            _token=$2
            shift
        ;;
        * )
            sys_echo "${red}Unknown parameter : $1${plain}"
            return 1
            shift
        esac
        shift 1
    done

    if [[ $_token != '' ]]; then
        get_param $_token
    fi
    
    if [[ $_host == '' || $_user == '' || $_pass = '' ]]; then
        
        list=(使用Token 传统方式)
        echo "选择连接方式: "
        select type in ${list[@]}
        do
            case "$type" in
            使用Token)
                while read -p "Token: " _token
                do
                    if [[ $_token == '' ]]; then
                        sys_echo "${red}请填写 Token!${plain}"
                        continue
                    fi
                    break
                done
                get_param $_token
            ;;
            传统方式)
                while read -p "服务器IP: " _host
                do
                    if [[ $_host == '' ]]; then
                        sys_echo "${red}请填写 服务器IP${plain}"
                        continue
                    fi
                    break
                done
                while read -p "服务器端口[$_default_port]: " _port
                do
                    if [[ $_port == '' ]]; then
                        _port=$_default_port
                    fi
                    if !(echo $_port | grep -E "$pattern_port" &> /dev/null); then
                        sys_echo "${red}服务器端口格式错误！${plain}"
                        continue
                    fi
                    break
                done
                while read -p "用户名: " _user
                do
                    if [[ $_user == '' ]]; then
                        sys_echo "${red}请填写 用户名${plain}"
                        continue
                    fi
                    break
                done
                while read -p "密码: " _pass
                do
                    if [[ $_pass == '' ]]; then
                        sys_echo "${red}请填写 密码${plain}"
                        continue
                    fi
                    break
                done
            ;;
            * )
                continue
            ;;
            esac
            break
        done
    fi

    if [[ $_port == '' ]]; then
        _port=$_default_port
    fi

    # 修改默认端口
    if [[ $_port != $_default_host ]]; then
        sed -i "s/$(cat $SSS_AGENT_PATH/client-linux.py | grep -E "^PORT")/PORT = $_port/" $SSS_AGENT_PATH/client-linux.py
    fi

    # 修改用户参数
    SSS_AGENT_EXEC=`echo "$(command -v python3 2> /dev/null || command -v python) $SSS_AGENT_PATH/client-linux.py SERVER=$_host USER=$_user PASSWORD=$_pass"`
    sed -i "s/$(cat ${SSS_AGENT_SERVICE} | grep -E "^WorkingDirectory=" | sed -E 's/\//\\\//g')/WorkingDirectory=$(echo $SSS_AGENT_PATH | sed -E 's/\//\\\//g')/" $SSS_AGENT_SERVICE
    sed -i "s/$(cat ${SSS_AGENT_SERVICE} | grep -E "^ExecStart=" | sed -E 's/\//\\\//g')/ExecStart=$(echo $SSS_AGENT_EXEC | sed -E 's/\//\\\//g')/" $SSS_AGENT_SERVICE

    # 刷新进程
    systemctl daemon-reload
    if [[ $(systemctl is-enabled $SERVICE_NAME) == 'enabled' ]]; then
        systemctl restart $SERVICE_NAME
    else
        systemctl enable $SERVICE_NAME
        systemctl start $SERVICE_NAME
    fi

    read_agent_env
}

# 安装客户机
install_agent() {
    sys_echo "${green}-----------------------------${plain}"
    sys_echo " 安装 Server Status 客户机"
    sys_echo "${green}-----------------------------${plain}"

    if !(is_command python3); then
        yum install -y python3 2> /dev/null || apt install -y python3
    fi

    # 创建工作目录
    mkdir -p $SSS_AGENT_PATH
    chmod 777 -R $SSS_AGENT_PATH

    # 下载脚本
    wget --no-check-certificate -qO $SSS_AGENT_PATH/client-linux.py $REPOSITORY_RAW_URL/client-linux.py
    wget --no-check-certificate -qO $SSS_AGENT_SERVICE $REPOSITORY_RAW_URL/agent.service

    # 配置参数
    sett_agent_env "$@"

}

# 卸载客户机
remove_agent() {
    sys_echo "${green}-----------------------------${plain}"
    sys_echo " 卸载 Server Status 客户机"
    sys_echo "${green}-----------------------------${plain}"

    _SSS_AGENT_PATH=$SSS_AGENT_PATH
    if (systemctl list-unit-files | grep "$SERVICE_NAME"  &> /dev/null); then
        _SSS_AGENT_PATH=`cat $SSS_AGENT_SERVICE | grep -E "^WorkingDirectory=" | sed 's/\(.*\)=\(.*\)/\2/g'`
        systemctl stop $SERVICE_NAME
        systemctl disable $SERVICE_NAME
        rm -rf $SSS_AGENT_SERVICE
    fi

    if [[ -d $_SSS_AGENT_PATH ]]; then
        rm -rf $_SSS_AGENT_PATH
    fi
}

show_menu() {
    num=$1
    max_num=7
    if [[ $num == '' ]]; then
        sys_echo "${green}Server Status 客户机${plain}"
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

        echo && read -p "请输入选择 [0-$max_num]: " num
        echo
    fi

    case "${num}" in
    0 | x ) # 退出脚本
        clear && exit 0
    ;;
    1 ) # 查看状态
        clear
        read_agent_env
        echo
        read  -n1  -p "按任意键继续" key
        clear
        show_menu
    ;;
    2 | 3 | 4 )
        clear
        read_agent_env "only"
        if [[ $? == 1 ]]; then
            echo
            read  -n1  -p "按任意键继续" key
            clear
            show_menu
            return 1
        fi
        case "${num}" in
        2 )
            if [[ $AGENT_STATUS == 'running' ]]; then
                confirm "Server Status 客户机正在运行, 是否要重启?" "n"
                if [[ $? == 0 ]]; then
                    sys_echo "重启中..."
                    systemctl restart $SERVICE_NAME
                else
                    clear
                    show_menu
                    return 0
                fi
            else
                echo
                sys_echo "启动中..."
                systemctl start $SERVICE_NAME
            fi
        ;;
        3 )
            if [[ $AGENT_STATUS == 'running' ]]; then
                echo
                sys_echo "停止中..."
                systemctl stop $SERVICE_NAME
            else
                echo
                sys_echo "${yellow}Server Status 客户机已停止${plain}"
            fi
        ;;
        4 )
            echo
            sys_echo "重启中..."
            systemctl restart $SERVICE_NAME
        ;;
        esac
        read_agent_env
        echo
        read  -n1  -p "按任意键继续" key
        clear
        show_menu
    ;;
    5 ) # 安装客户机
        clear
        read_agent_env "only"
        if [[ $? == 0 ]]; then
            sys_echo "${yellow}Server Status 客户机已经安装${plain}"
            echo
            read  -n1  -p "按任意键继续" key
            clear
            show_menu
            return 1
        fi
        confirm "确定要安装 Server Status 客户机吗?" "n"
        if [[ $? == 0 ]]; then
            clear
            install_agent
            sys_echo "${green}Server Status 客户机安装完毕${plain}"
            echo
            read  -n1  -p "按任意键继续" key
        fi
        clear
        show_menu
    ;;
    6 ) # 卸载服务
        clear
        read_agent_env "only"
        if [[ $? == 1 ]]; then
            echo
            read  -n1  -p "按任意键继续" key
            clear
            show_menu
            return 1
        fi
        confirm "确定要卸载 Server Status 客户机吗?" "n"
        if [[ $? == 0 ]]; then
            clear
            remove_agent
            sys_echo "${green}Server Status 客户机卸载完毕${plain}"
            echo
            read  -n1  -p "按任意键继续" key
        fi
        clear
        show_menu
    ;;
    7 ) # 配置参数
        clear
        read_agent_env "only"
        if [[ $? == 1 ]]; then
            echo
            read  -n1  -p "按任意键继续" key
            clear
            show_menu
            return 1
        fi
        confirm "确定要重新配置 Server Status 客户机吗?" "n"
        if [[ $? == 0 ]]; then
            sys_echo "${green}-----------------------------${plain}"
            sys_echo " 配置客户机参数"
            sys_echo "${green}-----------------------------${plain}"
            sett_agent_env "$@"
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

main() {
    clear
    case "$1" in
    install )
        read_agent_env "only"
        if [[ $? == 0 ]]; then
            sett_agent_env "${@:2}"
        else
            install_agent "${@:2}"
        fi
    ;;
    remove )
        read_agent_env "only"
        if [[ $? == 0 ]]; then
            remove_agent
            sys_echo "${green}Server Status 客户机卸载完毕${plain}"
        fi
    ;;
    * )
        show_menu
    ;;
    esac
}

clear
check_sys
pre_check
main "$@"
