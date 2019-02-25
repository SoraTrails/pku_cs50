#! /bin/bash
for file in ./* ;do
    file_name=$(ls -rt $file | tail -1)
    stuid=$(echo ${file_name} | cut -d '_' -f 1)
    stuname=$(echo ${file_name} | cut -d '_' -f 2)
    unzip -P `echo ${stuid} | base64 -i` $file_name
    if [ ! -f ./check.tmp -o ! -f ./*.sb[2-3] ];then 
        echo "error : ${stuid}"
        continue
    fi
    res=$(cat check.tmp | tail -1)

    echo "${stuid} score ${res[0]}"
done