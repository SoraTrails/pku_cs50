# !/bin/bash
if [ -z ${SUBMITED_PATH} ];then
    submited_path=/root/submited_works
else
    submited_path=${SUBMITED_PATH}
fi

text_path=tscs50
keys_path=kscs50
path=${1}
name=${2}
stuid=`echo ${name} | cut -d '_' -f 1`

if [ -z ${stuid} -o ! -f ${path}/${name} ]; then
    exit 4
fi

rm -rf ${submited_path}/speller/dictionary.*
rm -f ${submited_path}/speller/check.tmp

# unzip /root/speller.zip 
unzip -P `echo ${stuid} | base64 -i` ${path}/${name} -d ${submited_path}/speller 2>&1 > /dev/null
cd ${submited_path}/speller/

rm -f core speller *.o
clang -fsanitize=signed-integer-overflow -fsanitize=undefined -ggdb3 -O0 -Qunused-arguments -std=c11 -Wall -Werror -Wextra -Wno-sign-compare -Wshadow   -c -o speller.o speller.c
clang -fsanitize=signed-integer-overflow -fsanitize=undefined -ggdb3 -O0 -Qunused-arguments -std=c11 -Wall -Werror -Wextra -Wno-sign-compare -Wshadow   -c -o dictionary.o dictionary.c
clang -fsanitize=signed-integer-overflow -fsanitize=undefined -ggdb3 -O0 -Qunused-arguments -std=c11 -Wall -Werror -Wextra -Wno-sign-compare -Wshadow -o speller speller.o dictionary.o 

if [ $? != 0 -o ! -f ./speller ]; then
    make clean
    exit 1
fi

filelist=`ls ./${text_path}/`
mkdir -p ${submited_path}/speller/tmp/
sum=0
for file in $filelist ;do
    # echo "./speller ./dictionaries/large ${file}"
    # res=$(/usr/bin/time -f "%e %x" ./speller ./dictionaries/large ./${text_path}/${file} 2>&1 > ./tmp/${file}.tmp)
    ./speller ./dictionaries/large ./${text_path}/${file} > ./tmp/${file}.tmp
    if [ $? != 0 ];then
        exit 2
    fi
    cat ./tmp/${file}.tmp | head --lines=-6 > ./tmp/${file}
	temp1=(`md5sum ./tmp/${file}`)
	temp2=(`md5sum ./${keys_path}/${file}`)
	if [ ${temp1[0]} != ${temp2[0]} ];then
	    echo "error: ${file}"
        exit 3
	fi
    res=$(tail -2 ./tmp/${file}.tmp | awk '{print $4}')
    sum=$(echo "${res}+${sum}" | bc)
    rm -f ./tmp/${file}*
done

echo -n ${sum}
exit 0