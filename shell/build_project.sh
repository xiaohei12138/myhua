#! /bin/bash

#工程备份路径
BACKUP_CODE_DIR="tmp_backup_dir"
#工程文件路径
PROJECT_PATH="GT_PROJECT/BUILD_MTK_V1/P650/V2.0/gxt/c18/"
#CPU NUM
JOBS=""
let "JOBS=$(grep -r "processor" /proc/cpuinfo |wc -l)/2"
#bootloader 路径
BOOTLOADER_PATH="vendor/mediatek/proprietary/bootable/bootloader/"
#kernel 路径
KERNEL_PATH="kernel-3.18/"
#lunch project
LUNCH_PROJECT=""

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


function main()
{

	Options=$1

	if [ x$Options = "x" ]; then
		echo ""
		echo "Usage : ./build_project.sh [OPTION] ..."
		echo "	[OPTION]: :"
		echo "	 k|K  : build boot"
		echo "	 d|D  : build dts"
		echo "	 l|L  : build lk"
		echo "	 p|P  : build preloader"
		echo "	 u|U  : build all(Update)"
		echo "	 n|N  : build all(New)"
		echo "	 m|M  : build modem"
		echo "	 mmm  : mmm one module"
		echo -n "please input your Options [eng] : "
		read Options
	fi

	if [ $Options = "mmm" ] && [ ! -d $2 ] || [ x$2 = "x" ]; then
		echo "*************************************************************"
		echo "*                                                           *"
		echo "*  please use like this : ./build_project.sh mmm file_path  *"
		echo "*                                                           *"
		echo "*************************************************************"
		exit
	fi

	# new all
	if [ $Options = "N" ] || [ $Options = "n" ]; then
		echo "while project do you like : "
		echo "   1: user"
		echo "   2: userdebug"
		echo "   3: eng"
		echo -n "please input [eng]: "
		read build_type
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

function load_config()
{
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
