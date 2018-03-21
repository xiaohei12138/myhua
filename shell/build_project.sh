#! /bin/bash

#工程备份路径
BACKUP_CODE_DIR="tmp_backup_dir"
#保存工程路径文件
STORE_PROJECT_PATH_TXT="build_config.txt"
#工程文件路径
#PROJECT_PATH="GT_PROJECT/BUILD_MTK_V1/P650/V2.0/gxt/c18/"
PROJECT_PATH=""
#CPU NUM
JOBS=""
let "JOBS=$(grep -r "processor" /proc/cpuinfo |wc -l)/2"
#lunch project
LUNCH_PROJECT=""


#项目工程保存方式
PROJECT_BASE="GT_PROJECT/BUILD_MTK_V1/"
PROJECT_PATH_ARRAY=("board_number" "board_version" "customer_name" "project_name")
RETURN_VALUE=""

#MTK 默认原始工程路径 device/mediateksample/
MTK_DEFAULT_PROJECT_ARRAY=("mediateksample" "together")

#编译选项
IS_NEED_BUILD_BOOT=""
IS_NEED_BUILD_DTS=""
IS_NEED_BUILD_LK=""
IS_NEED_BUILD_PRELOADER=""
IS_NEED_BUILD_NEW_ALL=""
IS_NEED_BUILD_UPDATE_ALL=""
IS_NEED_BUILD_MODEM=""
IS_NEED_BUILD_MODULE=""
BUILD_TYPE="eng"

function backup_files()
{
	rm $BACKUP_CODE_DIR -rf
	project_files=`find $PROJECT_PATH/ -type f `
	for file in $project_files
	do
		original_file=$(echo ${file##$PROJECT_PATH/}) #原始路径下的文件
		file_path=$(echo $(echo ${original_file%/*}))
		mkdir -p $BACKUP_CODE_DIR"/"$file_path
		cp $original_file $BACKUP_CODE_DIR"/"$file_path

	done
}

function restore_files()
{
	cp 	$BACKUP_CODE_DIR/* . -rf
	rm $BACKUP_CODE_DIR -rf
}

function cover_file()
{
	cp $PROJECT_PATH/* . -rf
}

function prebuild_work()
{
	rm $BACKUP_CODE_DIR -rf
	if [ x$IS_NEED_BUILD_BOOT = "x" ] && [ x$IS_NEED_BUILD_DTS = "x" ] &&
	   [ x$IS_NEED_BUILD_LK = "x" ] && [ x$IS_NEED_BUILD_PRELOADER = "x" ] && 
	   [ x$IS_NEED_BUILD_NEW_ALL = "x" ] && [ x$IS_NEED_BUILD_UPDATE_ALL = "x" ] && 
	   [ x$IS_NEED_BUILD_MODULE = "x" ] && [ x$IS_NEED_BUILD_MODEM = "x" ]; then
			echo -e "	\033[35m ERROR :  no match [$_select_] Options \033[0m"
	 		exit		
	 else
	 	backup_files
	 	cover_file
	 fi
}

function select_build_option()
{
		if [ x$1 = "x" ];	then	
			echo -e ""
			echo -e "	[OPTION]: :"
			echo -e "	\033[1;31m k|K \033[0m : build boot"
			echo -e "	\033[1;31m d|D \033[0m : build dts"
			echo -e "	\033[1;31m l|L \033[0m : build lk"
			echo -e "	\033[1;31m p|P \033[0m : build preloader"
			echo -e "	\033[1;31m u|U \033[0m : build all(Update)"
			echo -e "	\033[1;31m n|N \033[0m : build all(New)"
			echo -e "	\033[1;31m m|M \033[0m : build modem"
			echo -e "	\033[1;31m mmm \033[0m : mmm one module"
			echo -e "	\033[0;31m 1  : user \033[0m"
			echo -e "	\033[0;31m 2  : userdebug \033[0m"
			echo -e "	\033[0;31m 3  : eng [default] \033[0m"
			echo -n "	 select : "
			read _select_
		else
			_select_=$1
		fi
		
		IS_NEED_BUILD_BOOT=$(echo $_select_ | grep -i k)
		IS_NEED_BUILD_DTS=$(echo $_select_ | grep -i d)
		IS_NEED_BUILD_LK=$(echo $_select_ | grep -i l)
		IS_NEED_BUILD_PRELOADER=$(echo $_select_ | grep -i p)
		IS_NEED_BUILD_NEW_ALL=$(echo $_select_ | grep -i n)
		IS_NEED_BUILD_UPDATE_ALL=$(echo $_select_ | grep -i u)
		IS_NEED_BUILD_MODULE=$(echo $_select_ | grep -i mmm)
		
		if [ x$IS_NEED_BUILD_MODULE = "x" ];then
			IS_NEED_BUILD_MODEM=$(echo $_select_ | grep -i m)
		else
			IS_NEED_BUILD_MODEM=""
		fi			
		
		if [ x$(echo $_select_ | grep -i 1) != "x" ]; then
			BUILD_TYPE="user"
		elif [ x$(echo $_select_ | grep -i 2) != "x" ]; then
			BUILD_TYPE="userdebug"
		else
			BUILD_TYPE="eng"
		fi

		if [ x$IS_NEED_BUILD_BOOT = "x" ] && [ x$IS_NEED_BUILD_DTS = "x" ] &&
		   [ x$IS_NEED_BUILD_LK = "x" ] && [ x$IS_NEED_BUILD_PRELOADER = "x" ] && 
		   [ x$IS_NEED_BUILD_NEW_ALL = "x" ] && [ x$IS_NEED_BUILD_UPDATE_ALL = "x" ] && 
		   [ x$IS_NEED_BUILD_MODULE = "x" ] && [ x$IS_NEED_BUILD_MODEM = "x" ]; then
				echo -e "	\033[35m ERROR :  no match [$_select_] Options \033[0m"
		 		select_build_option
		 fi

}


function select_path()
{
	#$1 描述   2：路径
	path=$2
	echo ""
	echo -e "\033[1;32m$1:\033[0m"

	selects[0]=""
	menu=`find $2 -maxdepth 1 -type d`
	level=0
	filter=""
	for name in ${menu[@]}
	do
		if [ $level -eq 0 ]; then
			filter=$name;
		else
		echo -e "	\033[1;31m$level : $(echo ${name##*$filter})\033[0m"
		selects[$level]=$(echo ${name##*$filter})
		fi
		let level++
	done
	let level--

	echo -e -n "	select : "
	
	read _select_
	case $_select_ in
		[1-$level])
			RETURN_VALUE=${selects[_select_]}
		;;
		*)
			echo -e "\033[35m	ERROR : no match [$_select_] Options \033[0m"
			RETURN_VALUE=""
			select_path $1 $2
		;;
	esac
}
function if_select_old_project_path_config()
{
	array=$PROJECT_PATH
	index=0
	echo "are you building following project:"
	array=(${array//\// })

	for i in ${PROJECT_PATH_ARRAY[@]}
	do
		echo -e "	 $i 	:\033[1;31m ${array[index+2]}\033[0m"
		let index++
	done

	echo -e -n "	select [Y/N]: "
	read _select_
	if [ x$_select_ = "x" ]; then
		_select_="Y"
	fi
	case $_select_ in
		Y|y|yes)
			return 1
		;;
		N|n|no)
			return 0
		;;
		*)	
			echo -e "\033[35m	ERROR : no match [$_select_] Options \033[0m"
			if_select_old_project_path_config
		;;
	esac

}
function select_new_project_path_config()
{
	PROJECT_PATH=$PROJECT_BASE
	for i in ${PROJECT_PATH_ARRAY[@]}
	do
		select_path $i $PROJECT_PATH
		PROJECT_PATH=$PROJECT_PATH$RETURN_VALUE"/"
	done
	
}

function select_project_path()
{
	#获得项目路径
	touch $STORE_PROJECT_PATH_TXT
	PROJECT_PATH=`cat $STORE_PROJECT_PATH_TXT`

	if [ x$PROJECT_PATH = "x" ]; then
		select_new_project_path_config
		echo $PROJECT_PATH >$STORE_PROJECT_PATH_TXT
	else
		if_select_old_project_path_config
		if [ $? = "0" ]; then
			rm $STORE_PROJECT_PATH_TXT
			select_project_path
		fi
	fi
}

function select_lunch_project()
{

	if [  -d out/target/product/ ];then
		LUNCH_PROJECT=`ls out/target/product/`
		echo    ""
		echo -e "now build project :   \033[31m $LUNCH_PROJECT \033[0m"
	else
		for i in ${MTK_DEFAULT_PROJECT_ARRAY[@]}
		do
			if [ -d "device/$i" ];then
					lunch_array=`ls device/$i/`
					lunch_array=(${lunch_array// / })
			fi
		done
		echo ""
		echo "please select project : "
		num=0;
		for project in ${lunch_array[@]}
		do 
			echo -e "\033[1;31m	 $num 	: $project\033[0m"
			let num++
		done
		let num--
		echo -n "	 your choice :  "
		read _select_
		case $_select_ in
			[0-$num])
				LUNCH_PROJECT=${lunch_array[$_select_]}
			;;
			*)
				echo -e "\033[35m	ERROR : no match [$_select_] Options \033[0m"
				select_lunch_project
			;;
		esac
	fi
}

function main()
{

	select_project_path
	# 获得LUNCH_PROJECT
	select_lunch_project

	select_build_option $1

	prebuild_work

	source build/envsetup.sh
	lunch "full_"$LUNCH_PROJECT"-"$BUILD_TYPE

	start_time_s=$(date +%s)

	
	if [ x$IS_NEED_BUILD_BOOT != "x" ];	then
		make bootimage -j$JOBS
		#mmm kernel-3.18:kernel -j$JOBS
	fi

	if [ x$IS_NEED_BUILD_DTS != "x" ]; then
		make odmdtboimage -j$JOBS
	fi

	if [ x$IS_NEED_BUILD_LK != "x" ]; then
		mmm vendor/mediatek/proprietary/bootable/bootloader/lk:lk -j$JOBS
	fi

	if [ x$IS_NEED_BUILD_PRELOADER != "x" ]; then
		mmm vendor/mediatek/proprietary/bootable/bootloader/preloader:pl -j$JOBS
	fi	

	if [ x$IS_NEED_BUILD_NEW_ALL != "x" ]; then
		rm out -rf
		make -j$JOBS
	fi	

	if [ x$IS_NEED_BUILD_UPDATE_ALL != "x" ]; then
		make -j$JOBS
	fi	

	if [ x$IS_NEED_BUILD_MODEM != "x" ]; then
		make update-modem -j$JOBS
	fi	

	if [ x$IS_NEED_BUILD_MODULE != "x" ]; then
		if [ ! -d $2 ] || [ x$2 = "x" ]; then
			echo -e "\033[35m ERROR : cannot access mmm path[$2] \033[0m"
			echo -e "\033[35m Usage ： ./build_project.sh mmm path\033[0m"
		else
			mmm $2
		fi
	fi	

	end_time_s=$(date +%s)
	echo "#############  USE $(($end_time_s - $start_time_s ))########################"
	restore_files
}


main $1 $2

