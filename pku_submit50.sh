#! /bin/bash
version=(3 2)
ip=23.105.208.75
# 修改版本需要三步：
# pku_submit50.sh中的version
# rz提交，运行build.sh
# 修改server中的version

# set -e

input_name_id(){
    if [ ! -d ~/.submit50 ];then
        mkdir -p ~/.submit50
    fi
    echo "<注意> 请输入您的姓名与学号"
    echo -n "姓名:"
    read name
    while [ ${name}x = x ]; do
        echo "<错误> 输入姓名不能为空"
        echo -n "姓名:"
        read name
    done
    echo $name | sed 's/[[:space:]]//g'  > ~/.submit50/config

    echo -n "学号:"
    read stuid
    while [ ${stuid}x = x ]; do
        echo "<错误> 输入学号不能为空"
        echo -n "学号:"
        read stuid
    done
    while [[ ${#stuid} -ne 10 || ${stuid:0:1} != '1' ]] || [[ -z "`echo ${stuid} | sed -n '/^[0-9][0-9]*$/p'`" ]] ;do
        echo "<错误> 学号格式有误"
        echo -n "学号:"
        read stuid
    done
    echo $stuid >> ~/.submit50/config
}

login(){
    if [ ! -f ~/.submit50/config ];then
        input_name_id
    fi

    while true; do
        name=`sed -n 1p ~/.submit50/config`
        stuid=`sed -n 2p ~/.submit50/config`
        echo "<注意> 读取到您的姓名为：${name}，学号为：${stuid}"
        echo -n "[按下ENTER键继续或者输入任意字符确定后重新输入] "
        read flag
        if [ ${flag}x = x ];then
            if [[ ${#stuid} -ne 10 || ${stuid:0:1} != '1' ]] || [[ -z "`echo ${stuid} | sed -n '/^[0-9][0-9]*$/p'`" ]] ;then
                echo "<错误> 学号格式有误"
                input_name_id
            else
                break
            fi
        else
            input_name_id
        fi
    done


}

update(){
    echo "==> 正在检查更新。。。"
    name=`sed -n 1p ~/.submit50/config`
    stuid=`sed -n 2p ~/.submit50/config`
    # TODO: curl debug
    code=$(curl -d "name=${name}&stuid=${stuid}" -o /tmp/cs50_pku_version -m 20 -s -w %{http_code} "${ip}/version")
    if [ ${code} != "200" ];then
        echo "<错误> 检查更新失败，错误码：${code}"
        exit
    fi
    latest_version=(`cat /tmp/cs50_pku_version`)
    if [ ${latest_version[0]} -gt ${version[0]} -o ${latest_version[0]} -eq ${version[0]} -a ${latest_version[1]} -gt ${version[1]} ];then
        echo "==> 最新版本为${latest_version[0]}.${latest_version[1]}，正在更新。。。"
        code=$(curl -d "name=${name}&stuid=${stuid}" -o ~/.submit50/pku_submit50.c -m 20 -s -w %{http_code} "${ip}/update")
        if [ ${code} != "200" ];then
            echo "<错误> 更新失败，错误码：${code}"
            exit
        fi
        gcc -o ~/.submit50/pku_submit50 ~/.submit50/pku_submit50.c
        rm -f ~/.submit50/pku_submit50.c
        echo "==> 更新完成，请重新运行本程序"
        rm -f /tmp/cs50_pku_version
        exit
    else
        echo "==> 已经是最新版本！"
        rm -f /tmp/cs50_pku_version
    fi
}

upload(){
    name=`sed -n 1p ~/.submit50/config`
    stuid=`sed -n 2p ~/.submit50/config`
    code=$(curl -F "file=@${1}" -F "name=${name}" -F "stuid=${stuid}" -F "work=${2}" -F "correct_num=${3}" -o /dev/null -m 20 -s -w %{http_code} ${ip}/upload)
    if [ ${code} != "200" ];then
        echo "<错误> 上传失败，错误码：${code}"
        exit
    fi
}

echo "submit50 for pkuers, version :${version[0]}.${version[1]}"
echo "使用帮助：pku_submit50 [作业所在文件夹路径，默认当前路径]"
login
name=`sed -n 1p ~/.submit50/config`
stuid=`sed -n 2p ~/.submit50/config`
update
echo "==> 请选择所要提交的作业:"
echo "    [1] 第一次sctrach作业"
echo "    [2] 第二次c语言credit作业"
echo "    [3] 第三次c语言speller作业"
echo "    [4] 第四次作业"
echo "    [5] 第五次作业"
echo -n "==> 请输入作业数字号:"
read flag
case $flag in
1)
    problem_num=1
    echo "作业1已过期，无法提交"
    exit
    if [ "$1"x != x ];then
        path=$(readlink -f $1)
    else
        path=`pwd`
    fi

    tmp=$(find $path -maxdepth 1 -name "*.sb[2-3]" 2> /dev/null)
    if [ -z "${tmp}" ];then
        echo "<错误> 未在路径 ${path} 下找到sb2或sb3文件，请重新指定路径"
        exit
    fi
    sbi_num=$(ls -l $path/*.sb[2-3] | wc -l)

    if [ ${sbi_num} -gt 1 ];then
        echo "<错误> 在路径 ${path} 下找到多个sb2或sb3文件，请明确您要提交的文件"
        exit
    fi

    res=$(find $path -maxdepth 1 -name '*.sb3')
    year=2019
    if [ -z "${res}" ];then
        res=$(find $path -maxdepth 1 -name '*.sb2')
        year=2018
    fi
    if [ -z "${res}" ];then
        echo "<错误> 未知错误，请联系助教"
        exit
    fi
    cd ${path}
    if [ -f  ~/.submit50/check.tmp ];then
        rm -f  ~/.submit50/check.tmp
    fi
    echo "您指定的作业${problem_num}文件路径为${res}"
    echo -n "[按下ENTER键继续或者输入任意字符退出]"
    read flag
    if [ ${flag}x != x ];then
        exit
    fi

    echo "==> 正在使用check50检查作业："
    if [ -f ~/.submit50/check.tmp ];then
        # echo "<错误> 检测到您当前已在运行pku_submit50，请等待上传完成再运行。若未在运行，请联系助教"
        rm -f ~/.submit50/check.tmp
    fi
    check50 cs50/${year}/x/scratch | tee  ~/.submit50/check.tmp
    passed=$(cat ~/.submit50/check.tmp | grep ":)" | wc -l)
    warnings=$(cat ~/.submit50/check.tmp | grep ":|" | wc -l)
    errors=$(cat ~/.submit50/check.tmp | grep ":(" | wc -l)
    if [ ${warnings} = 0 -a ${errors} = 0 -a ${passed} = 0 ];then
        echo "<错误> 使用check50检查失败，请稍后重试"
        exit
    fi
    echo "==> 您本次检测结果如下: ";echo
    echo -e "\033[32m [Passed]    ${passed} \033[0m"
    echo -e "\033[33m [Warnings]  ${warnings} \033[0m"
    echo -e "\033[31m [Errors]    ${errors} \033[0m";echo

    echo -e "`date`" >> ~/.submit50/check.tmp
    echo -e "${stuid}_${name}" >> ~/.submit50/check.tmp
    echo -e "${passed} ${warnings} ${errors}" >> ~/.submit50/check.tmp
    echo "==> 请问您是否要将本次的结果打包提交? （可多次提交，成绩评判将以最后一次提交为准）"
    echo -n "[按下ENTER键继续或者输入任意字符退出]"
    read flag
    if [ ${flag}x = x ];then
        echo "==> 正在打包。。。"
        if [ ! -d ~/.submit50/${stuid}/ ];then
            mkdir -p ~/.submit50/${stuid}/
        fi
        num=1
        while [ -f ~/.submit50/${stuid}/${stuid}_${name}_${problem_num}_${num}.zip ]; do
            num=$((num+1))
        done
        zippwd=`echo $stuid | base64 -i`
        mkdir -p ~/.submit50/tmp
        cp "${res}" ~/.submit50/tmp/
        cp ~/.submit50/check.tmp ~/.submit50/tmp/
        zip -P "$zippwd" -j ~/.submit50/${stuid}/${stuid}_${name}_${problem_num}_${num}.zip ~/.submit50/tmp/* > /dev/null
        rm -rf ~/.submit50/tmp/
        echo "==> 打包完成，正在上传"
        upload ~/.submit50/${stuid}/${stuid}_${name}_${problem_num}_${num}.zip ${problem_num} ${passed}
        echo "==> 上传完毕"
        #，这是您对作业${problem_num}的第${num}次提交
        rm -f ~/.submit50/check.tmp
        exit
    else
        rm -f ~/.submit50/check.tmp
        exit
    fi
;;
2)
    problem_num=2
    # echo "<错误> 尚未布置该作业"
    # exit
    if [ "$1"x != x ];then
        path=$(readlink -f $1)
    else
        path=`pwd`
    fi

    if [ -f ${path} ];then
        tmp=$(echo "${path}" | grep ".*\/credit\.c$")
        if [ -z "${tmp}" ]; then
            echo "<错误> 路径错误，请重新指定路径"
            exit
        else
            res=${path}
        fi
    else
        res=$(find $path -maxdepth 1 -name "credit.c" 2> /dev/null)
        if [ -z "${res}" ];then
            echo "<错误> 未在路径 ${path} 下找到credit.c，请重新指定路径"
            exit
        fi
    fi
    echo "您指定的作业${problem_num}文件路径为${res}"
    echo -n "[按下ENTER键继续或者输入任意字符退出]"
    read flag
    if [ ${flag}x != x ];then
        exit
    fi
    cd `dirname ${res}`

    code=`cat credit.c | sed "s/\r//g" | sed 's/\/\/.*//g' | sed ':a;N;s/\n//g;ta' | sed 's/\/\*.*\*\///g'`
    test_case="371449635398431 378282246310005 5555555555554444 4111111111111111 5105105105105100 4012888888881881"
    for c in ${test_case}; do
        trick=`echo ${code} | grep "${c}"`
        if [ -n "${trick}" ]; then
            echo "<错误> 检测到您可能在代码中非法使用了测试用例，如有疑问请联系助教"
            exit 1
        fi    
    done
    
    echo "==> 正在使用check50检查作业："
    if [ -f ~/.submit50/check.tmp ];then
        # echo "<错误> 检测到您当前已在运行pku_submit50，请等待上传完成再运行。若未在运行，请联系助教"
        rm -f ~/.submit50/check.tmp
    fi
    check50 cs50/2018/spring/credit | tee  ~/.submit50/check.tmp
    passed=$(cat ~/.submit50/check.tmp | grep ":)" | wc -l)
    warnings=$(cat ~/.submit50/check.tmp | grep ":|" | wc -l)
    errors=$(cat ~/.submit50/check.tmp | grep ":(" | wc -l)
    if [ ${warnings} = 0 -a ${errors} = 0 -a ${passed} = 0 ];then
        echo "<错误> 使用check50检查失败，请稍后重试"
        exit
    fi
    echo "==> 您本次检测结果如下: ";echo
    echo -e "\033[32m [Passed]    ${passed} \033[0m"
    echo -e "\033[33m [Warnings]  ${warnings} \033[0m"
    echo -e "\033[31m [Errors]    ${errors} \033[0m";echo

    echo -e "`date`" >> ~/.submit50/check.tmp
    echo -e "${stuid}_${name}" >> ~/.submit50/check.tmp
    echo -e "${passed} ${warnings} ${errors}" >> ~/.submit50/check.tmp
    

    echo "==> 请问您是否要将本次的结果打包提交? （可多次提交，成绩评判将以最后一次提交为准）"
    echo -n "[按下ENTER键继续或者输入任意字符退出]"
    read flag
    if [ ${flag}x = x ];then
        echo "==> 正在打包。。。"
        if [ ! -d ~/.submit50/${stuid}/ ];then
            mkdir -p ~/.submit50/${stuid}/
        fi
        num=1
        while [ -f ~/.submit50/${stuid}/${stuid}_${name}_${problem_num}_${num}.zip ]; do
            num=$((num+1))
        done
        zippwd=`echo $stuid | base64 -i`
        mkdir -p ~/.submit50/tmp
        cp "${res}" ~/.submit50/tmp/
        cp ~/.submit50/check.tmp ~/.submit50/tmp/
        zip -P "$zippwd" -j ~/.submit50/${stuid}/${stuid}_${name}_${problem_num}_${num}.zip ~/.submit50/tmp/* > /dev/null
        rm -rf ~/.submit50/tmp/
        echo "==> 打包完成，正在上传"
        upload ~/.submit50/${stuid}/${stuid}_${name}_${problem_num}_${num}.zip ${problem_num}  ${passed}
        echo "==> 上传完毕"
        md5=(`md5sum  ~/.submit50/${stuid}/${stuid}_${name}_${problem_num}_${num}.zip`)
        echo "==> 本次提交的hash值为：${md5[0]}"
        echo "==> 访问 http://soratrails.me/homework${problem_num} 查看您的提交"
        rm -f ~/.submit50/check.tmp
        exit
    else
        rm -f ~/.submit50/check.tmp
        exit
    fi

;;
3)
    problem_num=3
    # echo "<错误> 尚未布置该作业"
    # exit
    if [ "$1"x != x ];then
        path=$(readlink -f $1)
    else
        path=`pwd`
    fi

    if [ -f ${path} ];then
        tmp=$(echo "${path}" | grep ".*\/dictionary\.[c|h]$")
        if [ -z "${tmp}" ]; then
            echo "<错误> 路径错误，请重新指定路径"
            exit
        else
            res=($(find `dirname ${path}` -maxdepth 1 -name "dictionary.[c|h]" 2> /dev/null))
        fi
    else
        res=($(find $path -maxdepth 1 -name "dictionary.[c|h]" 2> /dev/null))
        if [ ${#res[@]} -ne 2 ];then
            echo "<错误> 未在路径 ${path} 下找到dictionary.c和dictionary.h，请重新指定路径"
            exit
        fi
    fi
    echo "您指定的作业${problem_num}文件1路径为${res[0]}"
    echo "您指定的作业${problem_num}文件2路径为${res[1]}"
    echo -n "[按下ENTER键继续或者输入任意字符退出]"
    read flag
    if [ ${flag}x != x ];then
        exit
    fi

    cd `dirname ${res}`
    echo "==> 即将本地检查您的作业,是否继续？"
    echo -n "[按下ENTER键继续或者输入任意字符跳过本地检查直接使用check50检查并提交]"
    read flag
    if [ ${flag}x == x ];then
        if [ ! -f ./speller ];then
            echo "<错误> 未找到可执行文件speller，请先编译您的代码"
            exit 1
        fi
        filelist=`ls ./texts/`
        sum=0
        for file in ${filelist} ;do
            echo -n "==> 正在验证文件 ${file} ... "
            ./speller ./dictionaries/large ./texts/${file} > ./${file}.res 2>&1
            if [ $? != 0 ];then
                echo -e "\n<错误> 检测到运行时错误，请打开文件${file}.res查看错误信息"
                exit 2
            fi

            cat ./${file}.res | head --lines=-6 > /tmp/${file}
            temp1=(`md5sum /tmp/${file}`)
            temp2=(`md5sum ./keys/${file}`)
            if [ ${temp1[0]} != ${temp2[0]} ];then
                echo -e "\n<错误> 结果错误，请保证代码中没有打印额外信息，打开文件${file}.res查看程序输出"
                exit 3
            fi
            result=$(tail -2 ./${file}.res | awk '{print $4}')
            sum=$(echo "${result}+${sum}" | bc)
            rm -f ${file}.res /tmp/${file}
            echo -e "\033[32m 通过 \033[0m"
        done
        echo "==> 全部测试用例通过，您的本地运行时间为 ${sum}s，该运行时间仅供参考"
    fi

    echo "==> 正在使用check50检查作业："
    if [ -f ~/.submit50/check.tmp ];then
        # echo "<错误> 检测到您当前已在运行pku_submit50，请等待上传完成再运行。若未在运行，请联系助教"
        rm -f ~/.submit50/check.tmp
    fi
    check50 cs50/2019/x/speller | tee  ~/.submit50/check.tmp
    passed=$(cat ~/.submit50/check.tmp | grep ":)" | wc -l)
    warnings=$(cat ~/.submit50/check.tmp | grep ":|" | wc -l)
    errors=$(cat ~/.submit50/check.tmp | grep ":(" | wc -l)
    if [ ${warnings} = 0 -a ${errors} = 0 -a ${passed} = 0 ];then
        echo "<错误> 使用check50检查失败，请稍后重试"
        exit
    fi
    echo "==> 您本次检测结果如下: ";echo
    echo -e "\033[32m [Passed]    ${passed} \033[0m"
    echo -e "\033[33m [Warnings]  ${warnings} \033[0m"
    echo -e "\033[31m [Errors]    ${errors} \033[0m";echo

    echo -e "`date`" >> ~/.submit50/check.tmp
    echo -e "${stuid}_${name}" >> ~/.submit50/check.tmp
    echo -e "${passed} ${warnings} ${errors}" >> ~/.submit50/check.tmp
    echo "==> 请问您是否要将本次的结果打包提交? "
    echo "==>（可多次提交，本次作业成绩评判将以在服务器上运行最快的一次提交为准）"
    echo -n "[按下ENTER键继续或者输入任意字符退出]"
    read flag
    if [ ${flag}x = x ];then
        echo "==> 正在打包。。。"
        if [ ! -d ~/.submit50/${stuid}/ ];then
            mkdir -p ~/.submit50/${stuid}/
        fi
        num=1
        while [ -f ~/.submit50/${stuid}/${stuid}_${name}_${problem_num}_${num}.zip ]; do
            num=$((num+1))
        done
        zippwd=`echo $stuid | base64 -i`
        mkdir -p ~/.submit50/tmp
        cp "${res[0]}" ~/.submit50/tmp/
        cp "${res[1]}" ~/.submit50/tmp/
        cp ~/.submit50/check.tmp ~/.submit50/tmp/
        zip -P "$zippwd" -j ~/.submit50/${stuid}/${stuid}_${name}_${problem_num}_${num}.zip ~/.submit50/tmp/* > /dev/null
        rm -rf ~/.submit50/tmp/
        echo "==> 打包完成，正在上传"
        upload ~/.submit50/${stuid}/${stuid}_${name}_${problem_num}_${num}.zip ${problem_num}  ${passed}
        echo "==> 上传完毕，您的代码正在后台编译运行。。。"
        md5=(`md5sum  ~/.submit50/${stuid}/${stuid}_${name}_${problem_num}_${num}.zip`)
        echo "==> 本次提交的hash值为：${md5[0]}"
        echo "==> 访问 http://soratrails.me/query 查询您的提交"
        echo "==> 查看排名请访问 http://soratrails.me/homework${problem_num} "

        rm -f ~/.submit50/check.tmp
        exit
    else
        rm -f ~/.submit50/check.tmp
        exit
    fi
;;
4)
    echo "<错误> 尚未布置该作业"
    exit
    echo "==> 请选择所要提交的作业:"
    echo "    [1] Hello"
    echo "    [2] Mario"
    echo "    [3] Cash"
    echo "    [4] Credit"
    echo -n "==> 请输入作业数字号:"
    read flag
    case $flag in
    1)
        problem_num=41
        file_name="hello"
    ;;
    2)
        problem_num=42
        file_name="mario"
    ;;
    3)
        problem_num=43
        file_name="cash"
    ;;
    4)
        problem_num=44
        file_name="credit"
    ;;
    *)
        echo "<错误> 不合法的输入"
        exit
    ;;
    esac

    if [ "$1"x != x ];then
        path=$(readlink -f $1)
    else
        path=`pwd`
    fi

    if [ -f ${path} ];then
        tmp=$(echo "${path}" | grep ".*\/${file_name}\.py$")
        if [ -z "${tmp}" ]; then
            echo "<错误> 路径错误，请重新指定路径"
            exit
        else
            res=${path}
        fi
    else
        res=$(find $path -maxdepth 1 -name "${file_name}.py" 2> /dev/null)
        if [ -z "${res}" ];then
            echo "<错误> 未在路径 ${path} 下找到${file_name}.py，请重新指定路径"
            exit
        fi
    fi
    echo "您指定的作业4.${file_name}文件路径为${res}"
    echo -n "[按下ENTER键继续或者输入任意字符退出]"
    read flag
    if [ ${flag}x != x ];then
        exit
    fi
    cd `dirname ${res}`

    echo "==> 正在使用check50检查作业："
    if [ -f ~/.submit50/check.tmp ];then
        rm -f ~/.submit50/check.tmp
    fi
    if [ ${problem_num} -eq 42 ];then
        check50 cs50/2019/x/sentimental/${file_name}/more | tee  ~/.submit50/check.tmp
    else
        check50 cs50/2019/x/sentimental/${file_name} | tee  ~/.submit50/check.tmp
    fi
    passed=$(cat ~/.submit50/check.tmp | grep ":)" | wc -l)
    warnings=$(cat ~/.submit50/check.tmp | grep ":|" | wc -l)
    errors=$(cat ~/.submit50/check.tmp | grep ":(" | wc -l)
    if [ ${warnings} = 0 -a ${errors} = 0 -a ${passed} = 0 ];then
        echo "<错误> 使用check50检查失败，请稍后重试"
        exit
    fi
    echo "==> 您本次检测结果如下: ";echo
    echo -e "\033[32m [Passed]    ${passed} \033[0m"
    echo -e "\033[33m [Warnings]  ${warnings} \033[0m"
    echo -e "\033[31m [Errors]    ${errors} \033[0m";echo

    echo -e "`date`" >> ~/.submit50/check.tmp
    echo -e "${stuid}_${name}" >> ~/.submit50/check.tmp
    echo -e "${passed} ${warnings} ${errors}" >> ~/.submit50/check.tmp
    echo "==> 请问您是否要将本次的结果打包提交? （可多次提交，成绩评判将以最后一次提交为准）"
    echo -n "[按下ENTER键继续或者输入任意字符退出]"
    read flag
    if [ ${flag}x = x ];then
        echo "==> 正在打包。。。"
        if [ ! -d ~/.submit50/${stuid}/ ];then
            mkdir -p ~/.submit50/${stuid}/
        fi
        num=1
        while [ -f ~/.submit50/${stuid}/${stuid}_${name}_${problem_num}_${num}.zip ]; do
            num=$((num+1))
        done
        zippwd=`echo $stuid | base64 -i`
        mkdir -p ~/.submit50/tmp
        cp "${res}" ~/.submit50/tmp/
        cp ~/.submit50/check.tmp ~/.submit50/tmp/
        zip -P "$zippwd" -j ~/.submit50/${stuid}/${stuid}_${name}_${problem_num}_${num}.zip ~/.submit50/tmp/* > /dev/null
        rm -rf ~/.submit50/tmp/
        echo "==> 打包完成，正在上传"
        upload ~/.submit50/${stuid}/${stuid}_${name}_${problem_num}_${num}.zip ${problem_num} ${passed}
        echo "==> 上传完毕"
        md5=(`md5sum  ~/.submit50/${stuid}/${stuid}_${name}_${problem_num}_${num}.zip`)
        echo "==> 本次提交的hash值为：${md5[0]}"
        echo "==> 访问 http://soratrails.me/homework4/${file_name} 查看您的提交"
        rm -f ~/.submit50/check.tmp
        exit
    else
        rm -f ~/.submit50/check.tmp
        exit
    fi

;;
5)
    echo "<错误> 尚未布置该作业"
    exit
;;
*)
    echo "<错误> 不合法的输入"
    exit
;;
esac

