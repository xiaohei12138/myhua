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


#保存编译工程的配置

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
	case $1 in
		k|K|d|D|l|L|p|P|u|U|n|N|m|M|mmm)
			backup_files
			cover_file
			;;
		*)
			echo -e "\033[31m ERROR : no match [$1] Options \033[0m"
			exit 
		;;
	esac
}

function select_build_option()
{
		echo -e ""
		echo -e "Usage : ./build_project.sh [OPTION] ..."
		echo -e "	[OPTION]: :"
		echo -e "	\033[1;31m k|K \033[0m : build boot"
		echo -e "	\033[1;31m d|D \033[0m : build dts"
		echo -e "	\033[1;31m l|L \033[0m : build lk"
		echo -e "	\033[1;31m p|P \033[0m : build preloader"
		echo -e "	\033[1;31m u|U \033[0m : build all(Update)"
		echo -e "	\033[1;31m n|N \033[0m : build all(New)"
		echo -e "	\033[1;31m m|M \033[0m : build modem"
		echo -e "	\033[1;31m mmm \033[0m : mmm one module"
		echo -n "	 select : "
		read Options
		case $Options in
			k|K|d|D|l|L|p|P|u|U|n|N|m|M|mmm)
				RETURN_VALUE=$Options
			;;
			*)
				RETURN_VALUE=""
				echo -e "	\033[35m ERROR : no match [$Options] Options \033[0m"
				select_build_option
			;;
		esac
}
function select_build_type()
{
		echo -e ""
		echo -e "while project do you like : "
		echo -e "	\033[1;31m 1: user \033[0m"
		echo -e "	\033[1;31m 2: userdebug \033[0m"
		echo -e "	\033[1;31m 3: eng \033[0m"
		echo -n "	 select : "
		read Options
		case $Options in
			1|user|2|userdebug|3|eng)
				RETURN_VALUE=$Options
			;;
			*)
				RETURN_VALUE=""
				echo -e "	\033[35m ERROR : no match [$Options] Options \033[0m"
				select_build_type
			;;
		esac
}

function main()
{

	if [ x$1 = "x" ]; then
		select_build_option
		Options=$RETURN_VALUE
	else
		Options=$1
	fi


	if [ $Options = "mmm" ]; then
		if [ ! -d $2 ] || [ x$2 = "x" ]; then
			echo "*************************************************************"
			echo "*                                                           *"
			echo "*  please use like this : ./build_project.sh mmm file_path  *"
			echo "*                                                           *"
			echo "*************************************************************"
			exit
		fi
	fi

	# new all
	if [ $Options = "N" ] || [ $Options = "n" ]; then
		select_build_type
		build_type=$RETURN_VALUE
	fi


	prebuild_work $Options

	source build/envsetup.sh
	case  $build_type in
		user|1)
			lunch "full_"$LUNCH_PROJECT"-user"
		;;
		userdebug|2)
			lunch "full_"$LUNCH_PROJECT"-userdebug"
		;;
		*)
			lunch "full_"$LUNCH_PROJECT"-eng"
		;;
	esac

	case $Options in
	k|K)
		make bootimage -j$JOBS	
	;;
	d|D)
		make odmdtboimage -j$JOBS
	;;
	l|L)
		mmm vendor/mediatek/proprietary/bootable/bootloader/lk:lk -j$JOBS
	;;
	p|P)
		mmm vendor/mediatek/proprietary/bootable/bootloader/preloader:pl -j$JOBS
	;;
	u|U)
		make -j$JOBS
	;;
	n|N)
		rm out -rf
		make -j$JOBS
	;;
	m|M)
		make update-modem -j$JOBS
	;;
	mmm)
		mmm $2
	;;
	esac

	restore_files
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
			if_select_old_config
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

function load_config()
{
	select_project_path

	# 获得LUNCH_PROJECT
	if [  -d out/target/product/ ];then
		LUNCH_PROJECT=`ls out/target/product/`
		echo    "*************************************************************"
		echo    "*                                                           *"
		echo -e "*  now build project :   \033[31m $LUNCH_PROJECT \033[0m"
		echo    "*                                                           *"
		echo    "*************************************************************"
	else 
		lunch_array=`ls device/mediateksample/`
		lunch_array=(${lunch_array// / })
		echo ""
		echo " please select project : "
		num=0;
		for project in ${lunch_array[@]}
		do 
			echo " $num : $project"
			let num++
		done
		echo -n "your choice :  "
		read choice
		case $choice in
			[0-9])
				if [ $choice -lt ${#lunch_array[@]} ] && [ $choice -ge 0 ]; then
					LUNCH_PROJECT=${lunch_array[choice]}
				fi
			;;
		esac
	fi

	if [ x$LUNCH_PROJECT = "x" ]; then
		echo "ERROR :  cannot access your project"
		exit
	fi
}

load_config
main $1 $2

