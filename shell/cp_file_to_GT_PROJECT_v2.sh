#! /bin/bash

cp_file=$1
if [ "$(file $1 | grep directory)" != "" ]; then
	echo "file: directory"
	cp_file_src=$cp_file
else
	echo "file text"
	cp_file_src=$(echo ${cp_file%/*})
fi

#echo $cp_file_src

CONFIG_FILE="GT_PROJECT/log/build_config.conf"
list=`cat $CONFIG_FILE`  
i=0
for val in $list  
do  
	array[$i]=$(echo $val)
       # echo $val
	let i++
done  

cp_file_dest="GT_PROJECT/BUILD_MTK_V1/"${array[0]}"/"${array[1]}"/"${array[2]}"/"${array[3]}"/"$cp_file_src"/"
#echo $1
mkdir -p $cp_file_dest
if [ "$(file $1 | grep directory)" != "" ]; then
	cp $1/* $cp_file_dest -rf
else
	cp $1 $cp_file_dest -rf
fi

echo "cp $1 $cp_file_dest"