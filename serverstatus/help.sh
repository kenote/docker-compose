#!/bin/bash

CURRENT_DIR=$(cd $(dirname $0);pwd)

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

CURRENT_DIR=$(cd $(dirname $0);pwd)
confile="${CURRENT_DIR}/config.json"
DRAW_TABLE="$HOME/.scripts/draw_table.sh"

publip=`wget -qO- ip.p3terx.com | sed -n '1p'`
hostip=`hostname -I  | awk -F "[: ]+" '{ print $1}'`

pattern_port="^[1-9]{1}[0-9]{1,4}$"
pattern_ip="^(2[0-4][0-9]|25[0-5]|1[0-9][0-9]|[1-9]?[0-9])(\.(2[0-4][0-9]|25[0-5]|1[0-9][0-9]|[1-9]?[0-9])){3}$"
pattern_url="https?://[a-zA-Z0-9\.\/_&=@$%?~#-]*"

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
    stty erase '^H' # 解决使用read时无法回退问题
    if (is_oversea); then
        REPOSITORY_RAW_ROOT="https://raw.githubusercontent.com/kenote/install"
        REPOSITORY_RAW_COMPOSE="https://raw.githubusercontent.com/kenote/docker-compose"
    else
        REPOSITORY_RAW_ROOT="https://gitee.com/kenote/install/raw"
        REPOSITORY_RAW_COMPOSE="https://gitee.com/kenote/docker-compose/raw"
    fi
    REPOSITORY_RAW_URL="$REPOSITORY_RAW_COMPOSE/main/serverstatus"
    curl -s $REPOSITORY_RAW_ROOT/main/linux/docker/help.sh | bash -s install
    DOCKER_WORKDIR=`[ -f $HOME/.docker_profile ] && cat $HOME/.docker_profile | grep "^DOCKER_WORKDIR" | sed -n '1p' | sed 's/\(.*\)=\(.*\)/\2/g' || echo "/home/docker-data"`
}

install_base() {
    # 下载安装生成表格脚本
    if [[ ! -f $DRAW_TABLE ]]; then
        wget -O $DRAW_TABLE ${REPOSITORY_RAW_ROOT}/main/linux/draw_table.sh
        chmod +x $DRAW_TABLE
        clear
    fi
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
    CONTAINER_ID=`docker container ls -a -q -f "ancestor=cppla/serverstatus"`
    if [[ $CONTAINER_ID == '' ]]; then
        sys_echo "${yellow}Server Status 服务未安装${plain}"
        return 1
    fi
    CONTAINER_STATUS=`docker inspect $CONTAINER_ID | jq -r ".[0].State.Status"`
    CONTAINER_WORKDIR=`docker inspect $CONTAINER_ID | jq -r ".[0].Config.Labels[\"com.docker.compose.project.working_dir\"]"`
    HTTP_PORT=`docker inspect $CONTAINER_ID | jq -r '.[0].NetworkSettings.Ports["80/tcp"][0].HostPort'`
    BIND_PORT=`docker inspect $CONTAINER_ID | jq -r '.[0].NetworkSettings.Ports["35601/tcp"][0].HostPort'`
    confile="$CONTAINER_WORKDIR/config.json"
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

# 配置参数
sett_server_env() {

    if [[ $1 == 'save' ]]; then
        sys_echo "${green}-----------------------------${plain}"
        sys_echo " 配置 Server Status 服务"
        sys_echo "${green}-----------------------------${plain}"
        EXCLUDE_HTTP_PORT=$HTTP_PORT
        EXCLUDE_BIND_PORT=$BIND_PORT
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
    while read -p "TCP连接端口[$BIND_PORT]: " _bind_port
    do
        if [[ $_bind_port == '' ]]; then
            _bind_port=$BIND_PORT
        fi
        if !(echo $_bind_port | grep -E "$pattern_port" &> /dev/null); then
            sys_echo "${red}TCP连接端口格式错误！${plain}"
            continue
        fi
        lsof_port $_bind_port $EXCLUDE_BIND_PORT
        if [[ $? == 1 ]]; then
            continue
        fi
        break
    done

    if [[ $1 == 'save' ]]; then
        cd $CONTAINER_WORKDIR
        sed -i "s/$(cat .env | grep -E "^HTTP_PORT=")/HTTP_PORT=$_http_port/" .env
        sed -i "s/$(cat .env | grep -E "^BIND_PORT=")/BIND_PORT=$_bind_port/" .env
        docker-compose down
        docker-compose up -d
    fi
}

# 安装服务
install_server() {
    sys_echo "${green}-----------------------------${plain}"
    sys_echo " 安装 Server Status 服务"
    sys_echo "${green}-----------------------------${plain}"

    while read -p "安装路径[serverstatus]: " _workdir
    do
        if [[ $_workdir = '' ]]; then
            _workdir="serverstatus"
        fi
        _workdir=`[[ $_workdir =~ ^\/ ]] && echo "$_workdir" || echo "$DOCKER_WORKDIR/$_workdir"`
    done
    sett_server_env

    # 创建工作目录
    mkdir -p $_workdir
    cd $_workdir

    # 拉取 compose 及 配置文件
    wget --no-check-certificate -qO docker-compose.yml $REPOSITORY_RAW_COMPOSE/main/serverstatus/compose.yml
    wget --no-check-certificate -qO .env $REPOSITORY_RAW_COMPOSE/main/serverstatus/.env.example
    wget --no-check-certificate -qO config.json $REPOSITORY_RAW_COMPOSE/main/serverstatus/config.json

    # 设置参数
    sed -i "s/$(cat .env | grep -E "^HTTP_PORT=")/HTTP_PORT=$_http_port/" .env
    sed -i "s/$(cat .env | grep -E "^BIND_PORT=")/BIND_PORT=$_bind_port/" .env

    # 启动服务
    docker-compose up d
}

# 卸载服务
remove_server() {
    sys_echo "${green}-----------------------------${plain}"
    sys_echo " 卸载 Server Status 服务"
    sys_echo "${green}-----------------------------${plain}"

    cd $CONTAINER_WORKDIR
    docker-compose down -v

    confirm "是否要删除工作目录吗?" "n"
    if [[ $? == 0 ]]; then
        rm -rf $CONTAINER_WORKDIR
    fi
}

# 客户机列表
agent_list() {
    sys_echo "${green}-----------------------------${plain}"
    sys_echo " 客户机列表"
    sys_echo "${green}-----------------------------${plain}"
    echo
    list=(`cat $confile | jq -r '.servers[].username'`)
    _i=0
    content="ID\t节点\t主机\t虚拟化\t地区"
    for username in "${list[@]}"
    do
        _i=`expr $_i + 1`
        item=`cat $confile | jq -r ".servers[] | select(.username == \"$username\")"`
        it_name=`echo $item | jq -r '.name'`
        it_host=`echo $item | jq -r '.host'`
        it_type=`echo $item | jq -r '.type'`
        it_location=`echo $item | jq -r '.location'`
        content="${content}\n$_i\t${it_name}\t${it_host}\t${it_type}\t${it_location}"
    done
    sys_echo "${content}" | $DRAW_TABLE -15 -1,-8,-1
    echo
    read -p "按 0 返回, 请输入选择 [0-$_i]: " num
    if [[ $num == 'x' || $num == '0' ]]; then
        return 1
    elif [[ $num =~ ^[0-9]+$ && $num -le $_i && $num -ge 1 ]]; then
        clear
        agent_options $(expr $num - 1)
        clear
        agent_list
    else
        clear
        sys_echo "${red}请输入正确的数字 [0-$_i]${plain}"
        echo
        agent_list
    fi
}

# 客户机选项
agent_options() {
    agent=`cat $confile | jq -r ".servers[$1]"`
    agent_name=`echo $agent | jq -r '.name'`
    agent_host=`echo $agent | jq -r '.host'`
    sys_echo "${green}-----------------------------${plain}"
    sys_echo " 客户机 -- ${agent_name}[${agent_host}]"
    sys_echo "${green}-----------------------------${plain}"
    echo
    list=(返回 安装脚本 改名 移除)
    select type in "${list[@]}"
    do
        case "$type" in
        返回)
            return 1
        ;;
        安装脚本)
            clear
            agent_script $1
            clear
            agent_options $1
        ;;
        改名)
            clear
            edit_agent $1
            clear
            agent_options $1
        ;;
        移除)
            clear
            del_agent $1
            if [[ $? == 1 ]]; then
                clear
                agent_options $1
            fi
        ;;
        * )
            clear
            sys_echo "${red}请输入正确的选项${plain}"
            echo
            agent_options $1
        ;;
        esac
        break
    done
}

# 安装脚本
agent_script() {
    agent=`cat $confile | jq -r ".servers[$1]"`
    agent_name=`echo $agent | jq -r '.name'`
    agent_host=`echo $agent | jq -r '.host'`
    sys_echo "${green}-----------------------------${plain}"
    sys_echo " 安装脚本 -- ${agent_name}[${agent_host}]"
    sys_echo "${green}-----------------------------${plain}"

    agent_user=`echo $agent | jq -r '.username'`
    agent_pass=`echo $agent | jq -r '.password'`

    if [[ $publip == $hostip ]]; then
        list=($hostip 127.0.0.1)
    else
        list=($publip $hostip 127.0.0.1)
    fi
    echo "选择关联 IP: "
    select ip in "${list[@]}"
    do
        if [[ $ip == '' ]]; then
            continue
        fi
        server_host=$ip
        break
    done
    echo
    sys_echo "-> 关联 IP: ${yellow}$server_host${plain}"
    echo
    server_port=`cat $CONTAINER_WORKDIR/.env | grep -E '^BIND_PORT=' | sed 's/\(.*\)=\(.*\)/\2/g'`
    agent_param="--host $server_host --port $server_port --user $agent_user --pass $agent_pass"
    list=(使用Token 传统方式)
    echo "选择连接方式: "
    select type in ${list[@]}
    do
        case "$type" in
        使用Token)
            agent_token=`echo "${agent_param}" | base64 | tr -d "\n"`
            echo
            sys_echo "-> 连接方式: ${yellow}$type${plain}"
            echo
            sys_echo "复制以下代码到客户机执行"
            sys_echo "------------------------------------------------"
            sys_echo "wget -O sss-agent.sh ${REPOSITORY_RAW_URL}/agent.sh \\"
            sys_echo "&& chmod +x sss-agent.sh && sudo \\"
            sys_echo "&& sudo ./sss-agent.sh install --token ${agent_token}"
            sys_echo "------------------------------------------------"
            echo
        ;;
        传统方式)
            echo
            sys_echo "-> 连接方式: ${yellow}$type${plain}"
            echo
            sys_echo "复制以下代码到客户机执行"
            sys_echo "------------------------------------------------"
            sys_echo "wget -O sss-agent.sh ${REPOSITORY_RAW_URL}/agent.sh \\"
            sys_echo "&& chmod +x sss-agent.sh && sudo \\"
            sys_echo "&& sudo ./sss-agent.sh install ${agent_param}"
            sys_echo "------------------------------------------------"
            echo
        ;;
        * )
            continue
        ;;
        esac
        break
    done
    echo
    read  -n1  -p "按任意键继续" key
}

# 修改客户机
edit_agent() {
    agent=`cat $confile | jq -r ".servers[$1]"`
    agent_name=`echo $agent | jq -r '.name'`
    agent_host=`echo $agent | jq -r '.host'`
    agent_type=`echo $agent | jq -r '.type'`
    agent_location=`echo $agent | jq -r '.location'`
    sys_echo "${green}-----------------------------${plain}"
    sys_echo " 修改 -- ${agent_name}[${agent_host}]"
    sys_echo "${green}-----------------------------${plain}"

    while read -p "节点[$agent_name]: " _agent_name
    do
        if [[ $_agent_name == '' ]]; then
            _agent_name=$agent_name
        fi
        break
    done
    while read -p "主机[$agent_host]: " _agent_host
    do
        if [[ $_agent_host == '' ]]; then
            _agent_host=$agent_host
        fi
        break
    done
    while read -p "虚拟化[$agent_type]: " _agent_type
    do
        if [[ $_agent_type == '' ]]; then
            _agent_type=$agent_type
        fi
        break
    done
    sys_echo "地区代码请参阅 https://www.dute.org/country-code"
    while read -p "地区[$agent_location]: " _agent_location
    do
        if [[ $_agent_location == '' ]]; then
            _agent_location=$agent_location
        fi
        break
    done
    confirm "确定要写入配置吗?" "n"
    if [[ $? == 1 ]]; then
        return 1
    fi

    # 拼接 JSON
    agent=`echo $agent | jq -r ".name=\"$_agent_name\""`
    agent=`echo $agent | jq -r ".host=\"$_agent_host\""`
    agent=`echo $agent | jq -r ".type=\"$_agent_type\""`
    agent=`echo $agent | jq -r ".location=\"$_agent_location\""`

    # 写入配置
    setting=`cat $confile | jq -r ".servers[$1]=$agent"`

    echo "$setting" | jq > ${confile}
    sleep 1

    # 重启服务
    cd $CONTAINER_WORKDIR
    docker-compose restart
}

# 移除客户机
del_agent() {
    agent=`cat $confile | jq -r ".servers[$1]"`
    agent_name=`echo $agent | jq -r '.name'`
    agent_host=`echo $agent | jq -r '.host'`
    sys_echo "${green}-----------------------------${plain}"
    sys_echo " 移除 -- ${agent_name}[${agent_host}]"
    sys_echo "${green}-----------------------------${plain}"

    confirm "确定要移除客户机吗?" "n"
    if [[ $? == 1 ]]; then
        return 1
    fi

    # 写入配置
    setting=`cat $confile | jq -r "del(.servers[$1])"`

    echo "$setting" | jq > ${confile}
    sleep 1

    # 重启服务
    cd $CONTAINER_WORKDIR
    docker-compose restart
}

# 添加客户机
create_agent() {
    sys_echo "${green}-----------------------------${plain}"
    sys_echo " 添加客户机"
    sys_echo "${green}-----------------------------${plain}"

    while read -p "节点: " _agent_name
    do
        if [[ $_agent_name == '' ]]; then
            sys_echo "节点名称不能为空"
        fi
        break
    done
    _default_host="[$_agent_name]"
    while read -p "主机$_default_host: " _agent_host
    do
        if [[ $_agent_host == '' ]]; then
            _agent_host=$_agent_name
        fi
        break
    done
    while read -p "虚拟化[kvm]: " _agent_type
    do
        if [[ $_agent_type == '' ]]; then
            _agent_type="kvm"
        fi
        break
    done
    sys_echo "地区代码请参阅 https://www.dute.org/country-code"
    while read -p "地区[cn]: " _agent_location
    do
        if [[ $_agent_location == '' ]]; then
            _agent_location="cn"
        fi
        break
    done
    confirm "确定要写入配置吗?" "n"
    if [[ $? == 1 ]]; then
        return 1
    fi
    _agent_user=`uuidgen | tr -dc '[:xdigit:]'`
    _agent_pass=`strings /dev/urandom | tr -dc A-Za-z0-9 | head -c16; echo`

    # 拼接 JSON
    agent="{\"monthstart\":\"1\"}"
    agent=`echo $agent | jq -r ".name=\"$_agent_name\""`
    agent=`echo $agent | jq -r ".host=\"$_agent_host\""`
    agent=`echo $agent | jq -r ".type=\"$_agent_type\""`
    agent=`echo $agent | jq -r ".location=\"$_agent_location\""`
    agent=`echo $agent | jq -r ".username=\"$_agent_user\""`
    agent=`echo $agent | jq -r ".password=\"$_agent_pass\""`

    # 写入配置
    len=`cat $confile | jq -r ".servers | length"`
    setting=`cat $confile | jq -r ".servers[$len]=$agent"`

    echo "$setting" | jq > ${confile}
    sleep 1

    # 重启服务
    cd $CONTAINER_WORKDIR
    docker-compose restart

    # 显示安装脚本
    echo
    agent_script $len
}

show_menu() {
    num=$1
    max_num=9
    if [[ $num == '' ]]; then
        sys_echo "${green}Server Status 探针管理${plain}"
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
        sys_echo "------------------------"
        sys_echo "${green} 8${plain}. 客户机列表"
        sys_echo "${green} 9${plain}. 添加客户机"

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
                confirm "Server Status 服务正在运行, 是否要重启?" "n"
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
                sys_echo "${yellow}Server Status 服务已停止${plain}"
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
            sys_echo "${yellow}Server Status 服务已经安装${plain}"
            echo
            read  -n1  -p "按任意键继续" key
            clear
            show_menu
            return 1
        fi
        confirm "确定要安装 Server Status 服务吗?" "n"
        if [[ $? == 0 ]]; then
            clear
            install_server
            sys_echo "${green}Server Status 服务安装完毕${plain}"
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
        confirm "确定要卸载 Server Status 服务吗?" "n"
        if [[ $? == 0 ]]; then
            clear
            remove_server
            sys_echo "${green}Server Status 服务卸载完毕${plain}"
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
        confirm "确定要重新配置 Server Status 服务吗?" "n"
        if [[ $? == 0 ]]; then
            clear
            sett_server_env "save"
            echo
            read  -n1  -p "按任意键继续" key
        fi
        clear
        show_menu
    ;;
    8 ) # 客户机列表
        clear
        read_server_env "only"
        if [[ $? == 1 ]]; then
            echo
            read  -n1  -p "按任意键继续" key
            clear
            show_menu
            return 1
        fi
        clear
        agent_list
        clear
        show_menu
    ;;
    9 ) # 添加客户机
        clear
        read_server_env "only"
        if [[ $? == 1 ]]; then
            echo
            read  -n1  -p "按任意键继续" key
            clear
            show_menu
            return 1
        fi
        clear
        create_agent
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
    case "$1" in
    install )
        show_menu 5
    ;;
    * )
        show_menu
    ;;
    esac
}

clear
check_sys
pre_check
install_base
main "$@"