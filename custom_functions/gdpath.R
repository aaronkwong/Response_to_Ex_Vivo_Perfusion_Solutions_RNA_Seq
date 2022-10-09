#this function takes the path starting from within, the google drive folder and modifies the beggining of the path for the appropriate PC. For example
#to access the "Masters" folder, you would write: gdpath("Masters") 
#external defines whether the file specified is in the cloud folder. If external=TRUE, then the root is simply prepended to x and returned (without any other modification)
gdpath<-function(x,root,external=FALSE){
	if (x==""){
		stop("Error: no path specified.")
	}
	#prepend the root if provided
	if (missing(root)){
		prepend<-""
	}else{
		#if the root doesn't end in a slash, we should add one
		if(substr(root,nchar(root),nchar(root))!="/"){
			root<-paste0(root,"/")
		}
		prepend=root
	}

	if(external==TRUE){
		return(paste0(prepend,x,sep=""))
	}else{
		#identify the computer gdpath is being run on
		#acer laptop
		if(Sys.info()["nodename"]=="DESKTOP-V66FFA0"){
			start<-"C:/Users/aaaar/OneDrive - UHN/"
		#lenovo laptop
		}else if(Sys.info()["nodename"]=="DESKTOP-KFPRD8U"){
			start<-"D:/OneDrive - UHN/"
		#gaming rig 
		}else if(Sys.info()["nodename"]=="DESKTOP-8IBP4G0"){
			if(Sys.info()["sysname"]=="Linux"){
				start<-"/mnt/d/OneDrive - UHN/"
			}else{
				start<-"D:/OneDrive - UHN/"
			}
		#Latner PC 
		}else if(Sys.info()["nodename"]=="DESKTOP-KDS5VMG"){
			start<-"C:/Users/Aaron Wong/OneDrive - UHN/"
		#xps 15
		}else if(Sys.info()["nodename"]=="DESKTOP-H7N6HGL"){
			if(Sys.info()["sysname"]=="Linux"){
				start<-"/mnt/c/Users/Aaron Wong/OneDrive - UHN/"
			}else{
				start<-"C:/Users/Aaron Wong/OneDrive - UHN/"
			}
		#xps 15_new
		}else if(Sys.info()["nodename"]=="XPS_AW"){
			if(Sys.info()["sysname"]=="Linux"){
				start<-"/mnt/c/Users/wonga/OneDrive - UHN/"
			}else{
				start<-"C:/Users/wonga/OneDrive - UHN/"
			}
		}else{
			print("error setting directory")
		}
		return(paste0(start,prepend,x,sep=""))
	}
}

#this function can souce libraries just by their name from the Rscript library
#example of use: gdlib(c("win_slash","encryption_utilities"))
#to list libraries available use gdlib("lib")
gdlib<-function(x,script_library_path=gdpath("Masters/R Script Folder/lib"),script_library_database=gdpath("Masters/R Script Folder/Script_Manager/Script_Management_Data/Master_Script_Data.txt")){
	if(length(x)>1){
		for (package in x){
			source(paste0(script_library_path,"/",package,".R"))
		}
	}else if (length(x)==1 & x!="lib"){
		source(paste0(script_library_path,"/",x,".R"))
	}else if (x=="lib"){
		library_data<-read.delim(script_library_database,stringsAsFactors=F)
		print(library_data$Script_Name)
	}
}
