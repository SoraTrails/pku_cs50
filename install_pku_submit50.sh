#! /bin/bash
# set -e

res=$(which pku_submit50)
if [ ! -z $res ]; then
    echo "<注意> 您已经安装了pku_submit50，继续将覆盖安装"
    echo -n "[按下ENTER键继续或者输入任意字符退出]"
    read flag
    if [ ${flag}x != x ];then
        exit
    fi
fi

echo "==> 正在下载最新版pku_submit50"

mkdir -p ~/.submit50/
code=$(curl -d "name=install&stuid=install" -o ~/.submit50/pku_submit50.c -m 15 -s -w %{http_code} "23.105.208.75/update")
if [ ${code} != "200" ];then
    echo "<错误> 安装失败，错误码：${code}"
    exit
fi
gcc -o ~/.submit50/pku_submit50 ~/.submit50/pku_submit50.c
rm -f ~/.submit50/pku_submit50.c

res=$(which pku_submit50)
if [ -z $res ]; then
    sudo ln -s ~/.submit50/pku_submit50 /bin/pku_submit50
fi
echo "==> 安装完成"
echo "使用帮助：pku_submit50 [作业所在文件夹路径，默认当前路径]"

