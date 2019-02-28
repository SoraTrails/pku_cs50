#! /bin/bash
for file in ./1/* ;do
    file_name=$(ls -rt $file | tail -1)
    stuid=$(echo ${file_name} | cut -d '_' -f 1)
    stuname=$(echo ${file_name} | cut -d '_' -f 2)
    if [ -d /tmp/${stuid} ];then
        rm -f /tmp/${stuid}/*
    else
        mkdir -p /tmp/${stuid}
    fi
    unzip -P `echo ${stuid} | base64 -i` ${file}/${file_name} -d /tmp/${stuid} > /dev/null
    if [ ! -f /tmp/${stuid}/check.tmp -o ! -f /tmp/${stuid}/*.sb[2-3] ];then 
        echo "error : ${stuid}"
        continue
    fi
    res=$(cat /tmp/${stuid}/check.tmp | tail -1)
    f=$(ls /tmp/${stuid}/*.sb[2-3])
    cp "${f}" ./res/1/${stuid}.sb"${f: -1}"
    echo "${stuid} ${res}"
done