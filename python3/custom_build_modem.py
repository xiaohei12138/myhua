#! /usr/bin/python3

import os

mt6580_o1_platform_info={
	"OrgCore"					: ["make/FISE_O1MP2_K80_BSP_HSPA.mak"],
	"CustomCore"				: ["make/FISE_O1MP2_K80_BSP_HSPA_##project##.mak"],
	"SaveVersionFile"			: "interface/service/nvram/nvram_editor_data_item.h",
	"DefSwitchType"				: 'USE_BOARD_NAME' ,
	"DefProjectRule"			: {'superdir': "make/",'keyword': "FISE_O1MP2_K80_BSP_HSPA_*.mak"},
	"BuildFunction"				: "./make.sh FISE_O1MP2_K80_BSP_HSPA.mak new",
	"CollectModem"				: "../device/mediatek/build/build/tools/modemRenameCopy.pl  .  FISE_O1MP2_K80_BSP_HSPA",
}
mt6739_o1_platform_info={
	"OrgCore"					: ["pcore/custom/modem/","make/projects/TK_MD_BASIC(LWCTG_R2_6739).mak"], 
	"CustomCore"				: ["pcore/custom/modem_##project##/","make/projects/TK_MD_BASIC(LWCTG_R2_6739)_##project##.mak"],
	"SaveVersionFile"			: "common/interface/service/nvram/l4_nvram_def.h",
	"DefSwitchType"				: 'USE_PROJECT_NAME' ,
	"DefProjectRule"			: {'superdir': "pcore/custom/",'keyword': "modem_*"},
	"BuildFunction"				: "./m  TK_MD_BASIC(LWCTG_R2_6739).mak new",
	"CollectModem"				: "../device/mediatek/build/build/tools/modemRenameCopy.pl  . TK_MD_BASIC(LWCTG_R2_6739).mak",

}
mt6737_o1_platform_info={
	"OrgCore"					: ["custom/modem_##project##/","make/FISE_O1MP1_K37TV1_BSP_LWG_DSDS_COTSX_##project##.mak","make/custom_config/FISE_O1MP1_K37TV1_BSP_LWG_DSDS_COTSX_##project##_EXT.mak"],
	"CustomCore"				: ["custom/modem/",	"make/FISE_O1MP1_K37TV1_BSP(LWG_DSDS_COTSX).mak","make/custom_config/FISE_O1MP1_K37TV1_BSP(LWG_DSDS_COTSX)_EXT.mak"],
	"SaveVersionFile"			: "interface/service/nvram/nvram_editor_data_item.h",
	"DefSwitchType"				: 'USE_PROJECT_NAME' ,
	"DefProjectRule"			: {'superdir': "custom/",'keyword': "modem_*"},
	"BuildFunction"				: "./m  FISE_O1MP1_K37TV1_BSP(LWG_DSDS_COTSX).mak  new",
	"CollectModem"				: "../device/mediatek/build/build/tools/modemRenameCopy.pl  .  FISE_O1MP1_K37TV1_BSP(LWG_DSDS_COTSX).mak",
}

AutoJudgePlatFormMaps={
	"modem_list"  : ["modem_80_o1","modem_39_o1","modem_37_o1"],
	"modem_80_o1" : mt6580_o1_platform_info,
	"modem_39_o1" : mt6739_o1_platform_info,
	"modem_37_o1" : mt6737_o1_platform_info,
}

project_info={
	"platformInfo"				: {},
	"BufferList"				: [],
	"FiseDefSwitchStartLine"	: 0,
	"FiseDefSwtichEndLine"		: 0,
	"TargeProject"				: '',
	"TargeSwitch"				: '',
	"TargeVersionLine"			: 0,
	"TargeVerion"				: "",
	"ProjectList"				: [],
	"DefSwitchList"				: [],
	"BackupDir"					: "Fise_backup"
}


def ImportantPrint(str='') :
	print("\033[32m%s\033[0m" %(str))
def ErrorPrint(str='') :
	print("\033[31m%s\033[0m" %(str))
def WarnPrint(str='') :
	print("\033[35m%s\033[0m" %(str))

'''
'''
class FError(Exception):
    pass

def InitInfo() :
	global AutoJudgePlatFormMaps,project_info
	path=""
	if os.access(os.getcwd()+'/../.git/config',os.F_OK) : path=os.getcwd()+'/../.git/config'
	if os.access(os.getcwd()+'/.git/config',os.F_OK) : path=os.getcwd()+'/.git/config'
	if os.access(os.getcwd()+'/../../.git/config',os.F_OK) : path=os.getcwd()+'/../../.git/config'
	if path=="" : raise FError("FAIL: Check to see if the compile script path is correct ")
	f=open(path)
	info=f.read()
	f.close()
	for single in AutoJudgePlatFormMaps["modem_list"]:
		if info.find(single) != -1 : project_info["platformInfo"]=AutoJudgePlatFormMaps[single]		
	print( project_info["platformInfo"]["BuildFunction"])
	
	
'''
'''
def GetProjectList() :
	global project_info
	superdir=project_info['platformInfo']['DefProjectRule']['superdir']
	keyword=project_info['platformInfo']['DefProjectRule']['keyword']
	list=os.listdir(superdir)
	key=keyword.split('*')
	for single in list:
		if key[1]!='' and key[0] !=0 :
			if single.find(key[0]) != -1 and  single.find(key[1]) != -1 :
				single=single.split(key[0])[1]
				single=single.split(key[1])[0]
				project_info['ProjectList'].append(single)
		elif key[0]=='' and key[1]!='' :
			if single.find(key[1]) != -1 : 
				single=single.split(key[1])[0]
				project_info['ProjectList'].append(single)
		elif key[0]!='' and key[1]=='' :
			if single.find(key[0]) !=-1:
				single=single.split(key[0])[1]
				project_info['ProjectList'].append(single)

	if len(project_info['ProjectList']) <= 0 :
		raise FError("FAIL: No project could be detected ")
	project_info['ProjectList'].sort()
'''
'''

def GetDefSwitchLIst():
	global project_info
	if project_info['platformInfo']['DefSwitchType'] == 'USE_PROJECT_NAME':
		project_info['DefSwitchList']=project_info["ProjectList"]
		project_info["TargeSwitch"]=project_info["TargeProject"]
	elif project_info['platformInfo']['DefSwitchType'] == 'USE_BOARD_NAME':
		for single in project_info["ProjectList"]:
			project_info['DefSwitchList'].append(single.split('_')[0])
		project_info["TargeSwitch"]=project_info["TargeProject"].split('_')[0]
	
	project_info['DefSwitchList']=list(set(project_info['DefSwitchList']))
	project_info['DefSwitchList'].sort()
	
	if len(project_info['DefSwitchList']) <= 0:
		raise FError("FAIL: Cannot generate the DefSwitchList automatically")
	if project_info["TargeSwitch"]=='' :
		raise FError("FAIL: Cannot generate the TargeSwitch automatically")	
	#print(project_info['DefSwitchList'])
	#print(project_info['TargeSwitch'])
'''
'''
def ShowProjectList():
	global project_info
	ImportantPrint("\nplease select which project you will build:")
	index=0
	for single in project_info['ProjectList']:
		print("  %d : %s" %(index,single))
		index=index+1
'''
'''
def SelectProject() :
	global project_info
	ShowProjectList()
	while True :
		select=input("  select: ")
		try :
			select=int(select)
			if select>= len(project_info['ProjectList']) or select < 0 :
				ErrorPrint("Invalid input,again")
			else :
				break
		except :
			ErrorPrint("Invalid input,again")
	project_info["TargeProject"]=project_info["ProjectList"][select]
'''
'''
def ParseSaveVersionFile():
	global project_info
	file=project_info['platformInfo']['SaveVersionFile']
	if os.access(file,os.F_OK)==False:
		raise FError("FAIL: cannot access "+file)
	
	fd=open(file)
	project_info['BufferList']=fd.readlines()
	fd.close()
	index=0;
	findTargeSwitchNum=0
	EndDefileLine=0
	StartDefLine=0
	TargeSwitch=project_info['TargeSwitch']
	for single in project_info['BufferList']:
		if single.find('#if')!=-1 and single.find(TargeSwitch)!=-1:
			temp=single[single.find(TargeSwitch)+len(TargeSwitch)]
			if temp=="\t" or temp=='' or temp=="\n" or temp=="\r":
				if findTargeSwitchNum !=0 :
					raise FError("FAIL : %s line(%d,%d)" %(file,StartDefLine+1,index+1))
				else:
					findTargeSwitchNum=findTargeSwitchNum+1
					StartDefLine=index
		elif findTargeSwitchNum!=0 and EndDefileLine == 0 and single.find('#endif')!=-1 :
			if single.find('//') ==-1 or single.find('//')>single.find('#endif'):
				EndDefileLine=index
		elif single.find('fise_project_define_start')!=-1 :
			project_info['FiseDefSwitchStartLine']=index
		elif single.find('fise_project_define_end')!=-1 :
			project_info['FiseDefSwtichEndLine']=index
		elif findTargeSwitchNum !=0 and single.find('#define')!=-1 and single.find("NVRAM_EF_SML_LID_VERNO")!=-1 and EndDefileLine==0:
			if (single.find('//') !=-1 and single.find('#define') < single.find('//')) or (single.find('//') ==-1) :
				if project_info['TargeVersionLine']!=0 :
					raise FError("FAIL : %s line(%d,%d)" %(file,project_info['TargeVersionLine']+1,index+1))
				project_info['TargeVersionLine']=index
				project_info['TargeVerion']=single.split('"')[1]
		index=index+1
	
	if project_info['FiseDefSwitchStartLine']==0 :
		raise FError("please check %s (had add fise_project_define_start tag)" %(file))
	
	if project_info['FiseDefSwtichEndLine']==0 :
		raise FError("please check %s (had add fise_project_define_end tag)" %(file))
	
	if project_info['TargeVersionLine']==0 :
		raise FError("please check %s (can no get %s info)" %(file, TargeSwitch))
	
	if project_info['TargeVerion']=="" :
		raise FError("please check %s (can no get %s version)" %(file, TargeSwitch))

'''
'''	
def SetVersion():
	global project_info
	print("NVRAM_EF_SML_LID_VERNO : \033[31m%s\033[0m " %(project_info['TargeVerion']),end=" ")
	while True :
		select=input(" change[ Y / N ],defaule[N]: ")
		if select == 'Y' or select == 'y' :
			break
		elif select == 'N' or select == 'n' or select == '':
			break
		else :
			ErrorPrint("Invalid input,again %s" %select);

	if select == 'Y' or select == 'y' :
		while True :
			version=input(" please input version values : ")
			try :
				select=int(version)
				if select < 4 or select > 100 :
					ErrorPrint("Invalid input,again");
					continue
				break
			except :
				ErrorPrint("Invalid input,again");
				continue
	
	if select != 'N' and select != 'n' and select != '':
		notes=input(" please add your notes :  ")
		info='//'+project_info["BufferList"][project_info["TargeVersionLine"]]
		project_info["BufferList"][project_info["TargeVersionLine"]]=info
		info='#define NVRAM_EF_SML_LID_VERNO		"'+version+'"	//'+notes+"\n"
		project_info["BufferList"].insert(project_info["TargeVersionLine"]+1,info)


	start=project_info['FiseDefSwitchStartLine']
	end=project_info['FiseDefSwtichEndLine']
	
	while True:
		end=end-1
		if end == start:
			break
		del project_info["BufferList"][end]

	for single in project_info['DefSwitchList']:
		if single == project_info['TargeSwitch'] :
			info='#define 	'+single+"	1\n"
		else:
			info='#define 	'+single+"	0\n"
		project_info["BufferList"].insert(start+1,info)

'''
'''
def SaveVersion():
	global project_info
	file=project_info["platformInfo"]["SaveVersionFile"]
	fd = open(file,"w")
	for single in project_info["BufferList"]:
		fd.write(single);
	fd.close()
'''
'''

def RunBashCmd(cmd):
	cmd=cmd.replace('(','\(').replace(')','\)')
	os.system(cmd)
'''
'''
def CleanLastOutput():
	global project_info
	RunBashCmd("rm "+project_info['BackupDir']+" -rf")
	RunBashCmd("rm "+project_info['BackupDir']+" -rf")
	RunBashCmd("rm build/ -rf")
	RunBashCmd("rm build_internal/ -rf")
	RunBashCmd("rm temp_modem/ -rf")
	
'''
'''
def BackupOrgCode(file):
	global project_info
	if os.path.isdir(file) :
		dir=project_info['BackupDir']+'/'+file
		os.makedirs(dir)
		RunBashCmd("cp "+file+'/*'+" "+dir+'/ -rf')
	else:
		dir=project_info['BackupDir']+'/'+os.path.dirname(file)
		os.makedirs(dir)
		RunBashCmd("cp "+file+" "+dir+'/')
'''
'''
def ReStoreOrgCode():
	global project_info
	dir=project_info['BackupDir']+'/'
	RunBashCmd("cp "+project_info['BackupDir']+'/* . -rf')
	RunBashCmd("rm "+project_info['BackupDir']+" -rf")
	
'''
'''	
def EnableProjectFile():
	global project_info
	if len(project_info["platformInfo"]["CustomCore"]) != len(project_info["platformInfo"]["OrgCore"]) :
		raise FError("Error:CustomCore not match OrgCore")
	index=0
	for single in project_info["platformInfo"]["CustomCore"] :
		if single.find('##project##')!=-1 :
			project_info["platformInfo"]["CustomCore"][index]=single.replace("##project##",project_info["TargeProject"])
		index=index+1
	index=0
	for single in project_info["platformInfo"]["CustomCore"] :
		orgfile=project_info["platformInfo"]["OrgCore"][index]
		index=index+1
		if os.access(single,os.F_OK)==False:
			ErrorPrint("FAIL: cannot access "+single)
			select=input("Use defaule? continue[Y] or input other key exit ")
			if select != 'Y' and select != 'y' :
				raise FError("");
		if os.access(orgfile,os.F_OK)==False:
			raise FError("FAIL: cannot access "+orgfile)
		
		BackupOrgCode(orgfile)
		
		if os.path.isdir(single):
			print("cp "+single+'/*'+" "+orgfile+" -rf")
			RunBashCmd("cp "+single+'/*'+" "+orgfile+" -rf")
		else:
			print("cp "+single+" "+orgfile+" -rf")
			RunBashCmd("cp "+single+" "+orgfile+" -rf")
'''
'''
def BuildModem():
	global project_info
	RunBashCmd(project_info["platformInfo"]["BuildFunction"])
	RunBashCmd(project_info["platformInfo"]["CollectModem"])
	ReStoreOrgCode()

def main() :
	try:
		InitInfo()
		GetProjectList()
		SelectProject()
		GetDefSwitchLIst()
		ParseSaveVersionFile()
		SetVersion()
		SaveVersion()
		CleanLastOutput()
		EnableProjectFile()
		BuildModem()
	except FError as e:
		ErrorPrint("%s" %(e))
	except:
		ErrorPrint("exit")
'''
'''
main()