# !/bin/bash
path=${1}
stuid=`cut ${path} -d '_' -f 1`

if [ -z ${stuid} -o ! -f ${path} ]; then
    exit 1
fi

unzip /root/speller.zip 
unzip -P `echo ${stuid} | base64 -i` ${path} -d /root/speller 
cd /root/speller
make
if [ $? != 0 ]; then
    rm -rf /root/speller/*
    exit 2
fi
./speller dictionaries/large 