########################################   LOGS     ############################################################
# Oct 20, 2018: We will start doing logs as of v50. This version gives our pipleine more utility. In the past it was used solely as a one button click to run
# 				a full GSEA pipeline for 1 rank file, or a pair of rank files. But we also want to give the option to use the pipeline peacewise. Here we 
#				add the option for the user to decide whether they would like to run the whole pipeline or run a specific portion.
#				-removed parameters from broad_GSEA_preranked function which were unecessary
#				-fixed the auto find function, to not run if only 1 rank file present
#				-added run examples for using this script to just run a GSEA
# Nov 26, 2018: v53-v55
#				-fixing the "enrichmentMap_annotate_single" function to make it work, and work on the new computer in Latner
#				-fixed bug where "layout" was a variable when it was indeed a function. Chnaged the variable name to "layout.choice"
#				-added "layout.choice" as a input to both cytoscape single and double dataset functions to allow user to choose
#				-fixed a bug where in the single and double cytoscape network functions "commandsGET("autoannotate layout (network=\"Enrichment Map\")")" 
#				which had extra brackets preventing it from working properly. I removed the brackets
#				-interesting observation: when doing cytoscape manually, it will count all nodes not in a cluster as a cluster of 1, thus inflating the number of clusters
#				-interesting observation: autoannotate has different defualts from manual for naming clusers, but actual node clustering is the same b/w manual and command line
#				-for the cytoscape enrichment map and annotaate for 1 dataset, I changed the naming of the created folder to make it easier to identify
#				-for the cytoscape enrichment map and annotate for single dataset i added 3 new variables: "similarity.type,combined.constant,similarity.constant"
#				they do not defualt to the same defualts if you were to build maps manually so they should be set to be the same as manual defualt
#				similarity.type ("COMBINED"),combined.constant(0.5),similarity.constant(0.375)
#				-in this version, the "enrichmentMap_annotate_single" will produce an almost identical output to doing it manually, 
#				except for the autoannoatate naming of clusters (this can be fixed by tweaking parameters but doesnt matter since we rename anyways). Actual clustering is the same
#				-fixed bugs in the pipeline for single datasets as there were changes made over time that affected how these functions work together
# Dec 2-4, 2018: v56-63
#				-added comments to make this script a package
#				-added gdpath function
################################################################################################################
#
#known bugs- when you do a two dataset enrichment map the dataset 1 and 2 get switched. It will also not produce the same result as doing it manually
#because the gmt file only applies to the first dataset, but not the second.



#-ongoing issues: when running GSEA manually you want headers from the make rank file or it wont work correctly. Covnersely, if you want to use automated gsea then you cannot. Should figure out how to deal with this
#another issue is that the input rank file for gsea must not have headers, must not have quotes, must be tab delimited, and not above the path limit 
#when run as a pipe, inputs need to put into script. When run as a piecewise, the functions calling the script can be changed
#corrections made to the piepline for a single dataset need to be made for the double datasets

#to install package
#install("C:/Users/Aaron Wong/Google Drive/Masters/R Custom Packages/AaronGSEAtoolkit")

#this was run with Autoannotate v, wordcloud,enrichmentmap,clustermaker2


#Package Requirements
#library (RCy3)

#knicks and knacks needed to run
#-defualt browser should be microsoft edge
#-no instances of cytoscape, CyREST or microsoft edge can be running when you start this
#-works only on windows

#GSEA Pipeline 

#install.packages("C:/Users/Aaron Wong/Documents/Working/AaronGSEAToolkit",repo=NULL,type="source")
#library(AaronGSEAToolkit)

#this function takes the path starting from within, the google drive folder and modifies the beggining of the path for the appropriate PC. For example
#to access the "Masters" folder, you would write: gdpath("Masters") 

############################################## FUNCTIONS ##############################################

#' This function is used as part of a pipeline. Conducts GSEA given a .rnk file
#known bug here, if you try to input the gsea_output path java won't like it because theres a hyphen in "OneDrive - UHN". BUT if R calls from the directory, java will write it to one drive. Use this trick to make it work. Set GSEA output location to 0 
broad_GSEA_preranked<-function(gsea_soft,gsea_memory,gsea_rnk,gsea_gmt,gsea_output_name,gsea_output_location,timestamp){
	system(paste0("java -cp \"",gsea_soft,"\" ","-Xmx",gsea_memory,"m xtools.gsea.GseaPreranked -gmx ",gsea_gmt," -norm meandiv -nperm ",gsea_nperm," -rnk ",gsea_rnk," -scoring_scheme weighted -rpt_label ",gsea_output_name," -create_svgs false -make_sets true -plot_top_x 20 -rnd_seed ",timestamp," -set_max 500 -set_min 15 -zip_report false -out ",gsea_output_location," -gui false -collapse false"),show.output.on.console = TRUE)
}

#to evaluate a single dataset
#result name is just the file name 
#function outputs to the root, so either manually set it or run this program from the location where you want the output made
enrichmentMap_annotate_single<-function(result_name,EM.AA_analysisType,EM.AA_enrichmentsDataset1,EM.AA_enrichments2Dataset1,EM.AA_ranksDataset1,EM.AA_gmtFile,EM.AA_qvalue,EM.AA_pvalue,layout.choice,similarity.type,combined.constant,similarity.constant){
	#use GSEA timestamp to label cytoscape outputs
	if (timestamp_gsea==0){
		#if a previous GSEA analysis was run check to see if we have the time stamp. If not generate one to label cytoscape output. If we have GSEA timestamp use it.
		#should look into this line, it may never actually occur. Why would we want to make a random seed? -Nov 26, 2018
		id<-paste0("rnd",(paste0(sample( 0:9, 10, replace=TRUE ), collapse="" )))
	}else if(timestamp_gsea=="timestamp"){
		id<-""
	}else{
		id<-timestamp_gsea
	}
	
	#check if cytoscape is open, if not open it
	cytoscape_instance<-length(grep("CYTOSC",readLines(textConnection(system('tasklist',intern=TRUE))),value=TRUE))
	if (cytoscape_instance!=0){
		}else{
			if(Sys.info()["nodename"]=="DESKTOP-KDS5VMG"){
				system('"C:\\Program Files\\Cytoscape_v3.7.0\\Cytoscape.exe"',wait=FALSE)
			}else{
				system('"C:\\Program Files\\Cytoscape_v3.6.1\\Cytoscape.exe"',wait=FALSE)
			}
		t<-1
		time<-0
		while(t!=0){
			cytoscape_opened<-try(cytoscapePing ())
			if (class(cytoscape_opened)=="try-error"){
				time<-time+1
				print(paste0("Cytoscape is still loading. Please wait...","(",time,")"))
				Sys.sleep(1)
			}else{
				t<-0
				print("You are connected to Cytoscape.")
				#give R extra time to load
				Sys.sleep(30)
			}
		}
		
	}
	
	# here commands API is buggy and needs to reopened every time cytoscape is relaunched. Well use old script to close it every time after running.
	
	######partI of pid finding####
	# capture the result of a `tasklist` system call
	before.win.tasklist <- system2( 'tasklist' , stdout = TRUE )
	# store all pids before running the process
	before.pids <- substr( before.win.tasklist[ -(1:3) ] , 27 , 35 )
	######end of part I###
	
	commandsAPI()
	#added extra sleep, if you dont do this the REST API does not load propoerly because it is not given time before R moves on to something else
	Sys.sleep(15)
	
	######partII of pid finding###
	# capture the result of a `tasklist` system call
	after.win.tasklist <- system2( 'tasklist' , stdout = TRUE )
	# store all tasks after running the process
	after.tasks <- substr( after.win.tasklist[ -(1:3) ] , 1 , 25 )
	# store all pids after running the process
	after.pids <- substr( after.win.tasklist[ -(1:3) ] , 27 , 35 )
	# store the number in the task list containing the PIDs you've just initiated
	initiated.pid.positions <- which( !( after.pids %in% before.pids ) )
	# remove whitespace
	after.tasks <- gsub( " " , "" , after.tasks )
	# find the pid position that matches the executable file name. ### EDIT THE NAME TO SUIT NEEDS ###
	correct.pid.position <- 
		intersect(
			which( after.tasks %in% "MicrosoftEdge.exe" ) ,
			initiated.pid.positions 
		)
	# remove whitespace
	correct.pid <- gsub( " " , "" , after.pids[ correct.pid.position ] )
	######end of part II####

	commandsGET(paste0("enrichmentmap build analysisType=\"",EM.AA_analysisType,"\" enrichmentsDataset1=\"",EM.AA_enrichmentsDataset1,"\" enrichments2Dataset1=\"",EM.AA_enrichments2Dataset1,"\" ranksDataset1=\"",EM.AA_ranksDataset1,"\" gmtFile=\"",EM.AA_gmtFile,"\" qvalue=",EM.AA_qvalue," pvalue=",EM.AA_pvalue," coefficients=",similarity.type," combinedConstant=",combined.constant," similaritycutoff=",similarity.constant))
	commandsGET("autoannotate annotate-sizeSorted network=\"Enrichment Map\"")
	if (layout.choice==TRUE){
		commandsGET("autoannotate layout network=\"Enrichment Map\"")
	}
	#the list of autoannotate cluster still needs to be retrieved manually
	dir.create(paste0(root,"/","cyto_",result_name,gsea_output_name_1))
	output_location<<-paste0(root,"/","cyto_",result_name,gsea_output_name_1)
	commandsGET(paste0("session save file=",gsub("/","\\\\",output_location),"\\",Sys.Date(),result_name,id,".cys"))
	commandsGET(paste0("table export OutputFile=",gsub("/","\\\\",output_location),"\\",result_name,"default node"," id ",id,".csv ","table=Enrichment Map default node"))
	commandsGET(paste0("table export OutputFile=",gsub("/","\\\\",output_location),"\\",result_name,"default edge"," id ",id,".csv ","table=Enrichment Map default edge"))
	commandsGET(paste0("table export OutputFile=",gsub("/","\\\\",output_location),"\\",result_name,"default network"," id ",id,".csv ","table=Enrichment Map default network"))
	cyto_version_data<<-getInstalledApps()
	commandsGET("command quit")
	
	#kill CyREST
	#kill the task
	taskkill.cmd <- gsub("\"","\\\"",paste( "taskkill" , "/PID" , correct.pid," /F"))
	print(taskkill.cmd)
	system( taskkill.cmd )
	
	#give time for everything to close
	Sys.sleep(10)
}



#' A function which will take the result of a GSEA and plot the results on enrichment map, cluster the nodes, and plot a drug bank database.
#'
#' @param result_name a string with the name of the .cys file you will be saving
#' @param EM.AA_analysisType a string defining what kind of GSEA analysis you did
#' @param EM.AA_enrichmentsDataset1 the pos.xls file outputted from GSEA
#' @param EM.AA_enrichments2Dataset1t he neg.xls file outputted from GSEA
#' @param EM.AA_ranksDataset1 the .rnk file used for GSEA. You can use your original of the one in the GSEA "edb" folder
#' @param EM.AA_gmtFilehe a .gmt file. You must use the original, and NOT the one in the "edb" folder as this is cut down (processed) by GSEA
#' @param EM.AA_qvalue your false discovery rate cutoff
#' @param EM.AA_pvalue your p-value cutoff 
#enrichmentmap post analysis cannot be done from the command line due, posibliy to bugs. Instead we will do everything up to the last step of running PA. We will also save a copy of the original.  
s.enrichmentMap_annotate_single_drugbank<-function(result_name,EM.AA_analysisType,EM.AA_enrichmentsDataset1,EM.AA_enrichments2Dataset1,EM.AA_ranksDataset1,EM.AA_gmtFile,EM.AA_qvalue,EM.AA_pvalue){
	#use GSEA timestamp to label cytoscape outputs
	if (timestamp_gsea==0){
		#if a previous GSEA analysis was run check to see if we have the time stamp. If not generate one to label cytoscape output. If we have GSEA timestamp use it.
		id<-paste0("rnd",(paste0(sample( 0:9, 10, replace=TRUE ), collapse="" )))
	}else{
		id<-timestamp_gsea
	}
	
	#check if cytoscape is open, if not open it
	cytoscape_instance<-length(grep("CYTOSC",readLines(textConnection(system('tasklist',intern=TRUE))),value=TRUE))
	if (cytoscape_instance!=0){
		}else{
		system('"C:\\Program Files\\Cytoscape_v3.6.1\\Cytoscape.exe"',wait=FALSE)
		t<-1
		time<-0
		while(t!=0){
			cytoscape_opened<-try(cytoscapePing ())
			if (class(cytoscape_opened)=="try-error"){
				time<-time+1
				print(paste0("Cytoscape is still loading. Please wait...","(",time,")"))
				Sys.sleep(1)
			}else{
				t<-0
				print("You are connected to Cytoscape.")
				#give R extra time to load
				Sys.sleep(30)
			}
		}
		
	}
	
	# here commands API is buggy and needs to reopened every time cytoscape is relaunched. Well use old script to close it every time after running.
	
	######partI of pid finding####
	# capture the result of a `tasklist` system call
	before.win.tasklist <- system2( 'tasklist' , stdout = TRUE )
	# store all pids before running the process
	before.pids <- substr( before.win.tasklist[ -(1:3) ] , 27 , 35 )
	######end of part I###
	
	commandsAPI()
	#added extra sleep, if you dont do this the REST API does not load propoerly because it is not given time before R moves on to something else
	Sys.sleep(15)
	
	######partII of pid finding###
	# capture the result of a `tasklist` system call
	after.win.tasklist <- system2( 'tasklist' , stdout = TRUE )
	# store all tasks after running the process
	after.tasks <- substr( after.win.tasklist[ -(1:3) ] , 1 , 25 )
	# store all pids after running the process
	after.pids <- substr( after.win.tasklist[ -(1:3) ] , 27 , 35 )
	# store the number in the task list containing the PIDs you've just initiated
	initiated.pid.positions <- which( !( after.pids %in% before.pids ) )
	# remove whitespace
	after.tasks <- gsub( " " , "" , after.tasks )
	# find the pid position that matches the executable file name. ### EDIT THE NAME TO SUIT NEEDS ###
	correct.pid.position <- 
		intersect(
			which( after.tasks %in% "MicrosoftEdge.exe" ) ,
			initiated.pid.positions 
		)
	# remove whitespace
	correct.pid <- gsub( " " , "" , after.pids[ correct.pid.position ] )
	######end of part II####

	commandsGET(paste0("enrichmentmap build analysisType=\"",EM.AA_analysisType,"\" enrichmentsDataset1=\"",EM.AA_enrichmentsDataset1,"\" enrichments2Dataset1=\"",EM.AA_enrichments2Dataset1,"\" ranksDataset1=\"",EM.AA_ranksDataset1,"\" gmtFile=\"",EM.AA_gmtFile,"\" qvalue=",EM.AA_qvalue," pvalue=",EM.AA_pvalue))
	commandsGET("autoannotate annotate-sizeSorted network=\"Enrichment Map\"")
	if (layout.choice==TRUE){
		commandsGET("autoannotate layout network=\"Enrichment Map\"")
	}
	##the list of autoannotate cluster still needs to be retrieved manually
	#dir.create(paste0(root,"/","cyto ",Sys.Date()))
	#output_location<<-paste0(root,"/","cyto ",Sys.Date())
	commandsGET(paste0("session save file=",gsub("/","\\\\",output_location),"\\",Sys.Date(),result_name,id,".cys"))
	#commandsGET(paste0("table export OutputFile=",gsub("/","\\\\",output_location),"\\",result_name,"default node"," id ",id,".csv ","table=Enrichment Map default node"))
	#commandsGET(paste0("table export OutputFile=",gsub("/","\\\\",output_location),"\\",result_name,"default edge"," id ",id,".csv ","table=Enrichment Map default edge"))
	#commandsGET(paste0("table export OutputFile=",gsub("/","\\\\",output_location),"\\",result_name,"default network"," id ",id,".csv ","table=Enrichment Map default network"))
	#commandsGET("command quit")
	#
	##kill CyREST
	##kill the task
	#taskkill.cmd <- gsub("\"","\\\"",paste( "taskkill" , "/PID" , correct.pid," /F"))
	#print(taskkill.cmd)
	#system( taskkill.cmd )
	#
	##give time for everything to close
	#Sys.sleep(10)
}  


#' This function is used as part of a pipeline when comparing two datasets. It takes the output from GSEA and variables created by the functions "GSEA_to_EM.AA_1" and "GSEA_to_EM.AA_2" to create an enrichment map and do clustering
enrichmentMap_annotate_2<-function(result_name,EM.AA_analysisType,EM.AA_enrichmentsDataset1,EM.AA_enrichments2Dataset1,EM.AA_ranksDataset1,EM.AA_enrichmentsDataset2,EM.AA_enrichments2Dataset2,EM.AA_ranksDataset2,EM.AA_gmtFile,EM.AA_qvalue,EM.AA_pvalue,layout.choice,similarity.type,combined.constant,similarity.constant){
	#use GSEA timestamo to label cytoscape outputs
	if (timestamp_gsea==0){
		#if a previous GSEA analysis was run check to see if we have the time stamp. If not generate one to label cytoscape output. If we have GSEA timestamp use it.
		id<-paste0("rnd",(paste0(sample( 0:9, 10, replace=TRUE ), collapse="" )))
	}else{
		id<-timestamp_gsea
	}
	
	#check if cytoscape is open, if not open it
	cytoscape_instance<-length(grep("CYTOSC",readLines(textConnection(system('tasklist',intern=TRUE))),value=TRUE))
	if (cytoscape_instance!=0){
		}else{
		######partI of pid finding####
		# capture the result of a `tasklist` system call
		before.win.tasklist <- system2( 'tasklist' , stdout = TRUE )
		# store all pids before running the process
		before.pids <- substr( before.win.tasklist[ -(1:3) ] , 27 , 35 )
		######end of part I###
		
		if(Sys.info()["nodename"]=="DESKTOP-KDS5VMG"){
			system('"C:\\Program Files\\Cytoscape_v3.7.0\\Cytoscape.exe"',wait=FALSE)
		}else if(Sys.info()["nodename"]=="LAPTOP-6I4LNRPP"){
			system('"C:\\Program Files\\Cytoscape_v3.7.0\\Cytoscape.exe"',wait=FALSE)
		}else{
			system('"C:\\Program Files\\Cytoscape_v3.6.1\\Cytoscape.exe"',wait=FALSE)
		}
		Sys.sleep(5)
		
		######partII of pid finding###
		# capture the result of a `tasklist` system call
		after.win.tasklist <- system2( 'tasklist' , stdout = TRUE )
		# store all tasks after running the process
		after.tasks <- substr( after.win.tasklist[ -(1:3) ] , 1 , 25 )
		# store all pids after running the process
		after.pids <- substr( after.win.tasklist[ -(1:3) ] , 27 , 35 )
		# store the number in the task list containing the PIDs you've just initiated
		initiated.pid.positions <- which( !( after.pids %in% before.pids ) )
		# remove whitespace
		after.tasks <- gsub( " " , "" , after.tasks )
		# find the pid position that matches the executable file name. ### EDIT THE NAME TO SUIT NEEDS ###
		correct.pid.position <- 
			intersect(
				which( after.tasks %in% "CYTOSC~1.EXE" ) ,
				initiated.pid.positions 
			)
		# remove whitespace
		correct.pid_cytoscape <<- gsub( " " , "" , after.pids[ correct.pid.position ] )
		######end of part II####
		
		t<-1
		time<-0
		while(t!=0){
			cytoscape_opened<-try(cytoscapePing ())
			if (class(cytoscape_opened)=="try-error"){
				time<-time+1
				print(paste0("Cytoscape is still loading. Please wait...","(",time,")"))
				Sys.sleep(1)
			}else{
				t<-0
				print("You are connected to Cytoscape.")
				Sys.sleep(30)
			}
		}
		
	}
	
	# here commands API is buggy and needs to reopened every time cytoscape is relaunched. Well use old script to close it every time after running.
	
	######partI of pid finding####
	# capture the result of a `tasklist` system call
	before.win.tasklist <- system2( 'tasklist' , stdout = TRUE )
	# store all pids before running the process
	before.pids <- substr( before.win.tasklist[ -(1:3) ] , 27 , 35 )
	######end of part I###
	
	commandsAPI()
	Sys.sleep(15)
	
	######partII of pid finding###
	# capture the result of a `tasklist` system call
	after.win.tasklist <- system2( 'tasklist' , stdout = TRUE )
	# store all tasks after running the process
	after.tasks <- substr( after.win.tasklist[ -(1:3) ] , 1 , 25 )
	# store all pids after running the process
	after.pids <- substr( after.win.tasklist[ -(1:3) ] , 27 , 35 )
	# store the number in the task list containing the PIDs you've just initiated
	initiated.pid.positions <- which( !( after.pids %in% before.pids ) )
	# remove whitespace
	after.tasks <- gsub( " " , "" , after.tasks )
	# find the pid position that matches the executable file name. ### EDIT THE NAME TO SUIT NEEDS ###
	correct.pid.position <- 
		intersect(
			which( after.tasks %in% "MicrosoftEdge.exe" ) ,
			initiated.pid.positions 
		)
	# remove whitespace
	correct.pid <- gsub( " " , "" , after.pids[ correct.pid.position ] )
	######end of part II####

	commandsGET(paste0("enrichmentmap build analysisType=\"",EM.AA_analysisType,"\" enrichmentsDataset1=\"",EM.AA_enrichmentsDataset1,"\" enrichments2Dataset1=\"",EM.AA_enrichments2Dataset1,"\" ranksDataset1=\"",EM.AA_ranksDataset1,"\" gmtFile=\"",EM.AA_gmtFile,"\" qvalue=",EM.AA_qvalue," pvalue=",EM.AA_pvalue," enrichmentsDataset2=\"",EM.AA_enrichmentsDataset2,"\" enrichments2Dataset2=\"",EM.AA_enrichments2Dataset2,"\" ranksDataset2=\"",EM.AA_ranksDataset1,"\""," coefficients=",similarity.type," combinedConstant=",combined.constant," similaritycutoff=",similarity.constant))
	commandsGET("autoannotate annotate-sizeSorted network=\"Enrichment Map\"")
	if (layout.choice==TRUE){
		commandsGET("autoannotate layout network= Enrichment Map")
	}
	#the list of autoannotate cluster still needs to be retrieved manually
	dir.create(paste0(root,"/","cyto ",Sys.Date()))
	output_location<<-paste0(root,"/","cyto ",Sys.Date())
	commandsGET(paste0("session save file=",gsub("/","\\\\",output_location),"\\",Sys.Date(),result_name,id,".cys"))
	commandsGET(paste0("table export OutputFile=",gsub("/","\\\\",output_location),"\\",result_name,"default node"," id ",id,".csv ","table=Enrichment Map default node"))
	commandsGET(paste0("table export OutputFile=",gsub("/","\\\\",output_location),"\\",result_name,"default edge"," id ",id,".csv ","table=Enrichment Map default edge"))
	commandsGET(paste0("table export OutputFile=",gsub("/","\\\\",output_location),"\\",result_name,"default network"," id ",id,".csv ","table=Enrichment Map default network"))
	cyto_version_data<<-getInstalledApps()
	commandsGET("command quit")
	
	#check if cytoscape has closed, this may take some time if the network is large and takes several minutes to build. If not wait
	cytoscape_closed<-1
	while(cytoscape_closed!=0){
		Sys.sleep(1)
		# capture the result of a `tasklist` system call
		after.win.tasklist <- system2( 'tasklist' , stdout = TRUE )
		# store all pids after running the process
		after.pids <- substr( after.win.tasklist[ -(1:3) ] , 27 , 35 )	
		# remove whitespace
		after.pids <- gsub( " " , "" , after.pids )
		if (correct.pid_cytoscape %in% after.pids){
		}else{
			cytoscape_closed<-0
		}
	}
	
	#kill CyREST
	#kill the task
	taskkill.cmd <- gsub("\"","\\\"",paste( "taskkill" , "/PID" , correct.pid," /F"))
	system( taskkill.cmd )
	
	
	#give time for everything to close
	Sys.sleep(10)
}

#' This function is used as part of a pipeline when you are comparing two datasets. It converts the latest output from the broad_GSEA_preranked and stores variables as the "first dataset" for the "enrichmentMap_annotate_2" function can run
GSEA_to_EM.AA_1<-function(cutoff){
	if (cutoff==0){
		folder_name<-grep(gsea_output_name_1,list.files(gsub("\\\\","/",gsea_output_location)),value=TRUE)
		folder_path<-paste0(gsub("\\\\","/",gsea_output_location),"/",folder_name)
		timestamp_gsea_1<<-strsplit(folder_name,"Preranked.")[[1]][2]
		EM.AA_enrichmentsDataset1<<-paste0(gsub("/","\\\\",paste0(folder_path,"/","gsea_report_for_na_pos_",timestamp_gsea_1,".xls")))
		EM.AA_enrichments2Dataset1<<-paste0(gsub("/","\\\\",paste0(folder_path,"/","gsea_report_for_na_neg_",timestamp_gsea_1,".xls")))
		EM.AA_ranksDataset1<<-gsea_rnk_1
		EM.AA_gmtFile<<-gsea_gmt
	}else{
		folder_name<-grep(gsea_output_name_1,list.files(gsub("\\\\","/",gsea_output_location)),value=TRUE)
		folder_path<-paste0(gsub("\\\\","/",gsea_output_location),"/",folder_name)
		timestamp_gsea_1<<-strsplit(folder_name,"Preranked.")[[1]][2]
		EM.AA_enrichmentsDataset1<<-paste0(gsub("/","\\\\",paste0(folder_path,"/","gsea_report_for_na_pos_",timestamp_gsea_1,".xls")))
		EM.AA_enrichments2Dataset1<<-paste0(gsub("/","\\\\",paste0(folder_path,"/","gsea_report_for_na_neg_",timestamp_gsea_1,".xls")))
		EM.AA_ranksDataset1<<-gsea_rnk_1
		EM.AA_gmtFile<<-gsea_gmt
		
		#create folder to hold pos and neg files that we will screen
		dir.create(paste0(root,"/","GSEA Cutoffs_1"))
		newgsea_folder_name<-paste0(root,"/","GSEA Cutoffs_1")
		file.copy(paste0(folder_path,"/","gsea_report_for_na_neg_",timestamp_gsea_1,".xls"), to=newgsea_folder_name)
		file.copy(paste0(folder_path,"/","gsea_report_for_na_pos_",timestamp_gsea_1,".xls"), to=newgsea_folder_name)
		
		#make the fdr0.05 file for pos
		orig.data<-read.delim(paste0(newgsea_folder_name,"/","gsea_report_for_na_pos_",timestamp_gsea_1,".xls"),stringsAsFactors = FALSE,header = FALSE)
		data<-orig.data[-1,]
		data2<-data[(as.numeric(data[,8])<=0.05),]
		data2<-rbind(orig.data[1,],data2)
		data2<-data2[,-12]
		name.edit<-paste0(newgsea_folder_name,"/",timestamp_gsea_1," pos fdr0.05.xls")
		write.table(data2,name.edit,sep="\t",quote=FALSE,row.names=FALSE,col.names=FALSE)
		EM.AA_enrichmentsDataset1q.05<<-paste0(gsub("/","\\\\",name.edit))
		
		#make the fdr0.10 file for pos
		orig.data<-read.delim(paste0(newgsea_folder_name,"/","gsea_report_for_na_pos_",timestamp_gsea_1,".xls"),stringsAsFactors = FALSE,header = FALSE)
		data<-orig.data[-1,]
		data2<-data[(as.numeric(data[,8])<=0.10),]
		data2<-rbind(orig.data[1,],data2)
		data2<-data2[,-12]
		name.edit<-paste0(newgsea_folder_name,"/",timestamp_gsea_1," pos fdr0.10.xls")
		write.table(data2,name.edit,sep="\t",quote=FALSE,row.names=FALSE,col.names=FALSE)
		EM.AA_enrichmentsDataset1q.10<<-paste0(gsub("/","\\\\",name.edit))
		
		#make the fdr0.05 file for neg
		orig.data<-read.delim(paste0(newgsea_folder_name,"/","gsea_report_for_na_neg_",timestamp_gsea_1,".xls"),stringsAsFactors = FALSE,header = FALSE)
		data<-orig.data[-1,]
		data2<-data[(as.numeric(data[,8])<=0.05),]
		data2<-rbind(orig.data[1,],data2)
		data2<-data2[,-12]
		name.edit<-paste0(newgsea_folder_name,"/",timestamp_gsea_1," neg fdr0.05.xls")
		write.table(data2,name.edit,sep="\t",quote=FALSE,row.names=FALSE,col.names=FALSE)
		EM.AA_enrichments2Dataset1q.05<<-paste0(gsub("/","\\\\",name.edit))
		
		#make the fdr0.10 file for neg
		orig.data<-read.delim(paste0(newgsea_folder_name,"/","gsea_report_for_na_neg_",timestamp_gsea_1,".xls"),stringsAsFactors = FALSE,header = FALSE)
		data<-orig.data[-1,]
		data2<-data[(as.numeric(data[,8])<=0.10),]
		data2<-rbind(orig.data[1,],data2)
		data2<-data2[,-12]
		name.edit<-paste0(newgsea_folder_name,"/",timestamp_gsea_1," neg fdr0.10.xls")
		write.table(data2,name.edit,sep="\t",quote=FALSE,row.names=FALSE,col.names=FALSE)
		EM.AA_enrichments2Dataset1q.10<<-paste0(gsub("/","\\\\",name.edit))
	}
}
#' This function is used as part of a pipeline when you are comparing two datasets. It converts the latest output from the broad_GSEA_preranked and stores variables as the "second dataset" for the "enrichmentMap_annotate_2" function can run
GSEA_to_EM.AA_2<-function(cutoff){
	if (cutoff==0){
		folder_name<-grep(gsea_output_name_2,list.files(gsub("\\\\","/",gsea_output_location)),value=TRUE)
		folder_path<-paste0(gsub("\\\\","/",gsea_output_location),"/",folder_name)
		timestamp_gsea_2<<-strsplit(folder_name,"Preranked.")[[1]][2]
		EM.AA_enrichmentsDataset2<<-paste0(gsub("/","\\\\",paste0(folder_path,"/","gsea_report_for_na_pos_",timestamp_gsea_2,".xls")))
		EM.AA_enrichments2Dataset2<<-paste0(gsub("/","\\\\",paste0(folder_path,"/","gsea_report_for_na_neg_",timestamp_gsea_2,".xls")))
		EM.AA_ranksDataset1<<-gsea_rnk_2
		EM.AA_gmtFile<<-gsea_gmt
		timestamp_gsea<<-paste(timestamp_gsea_1, timestamp_gsea_2)
	}else{
		folder_name<-grep(gsea_output_name_2,list.files(gsub("\\\\","/",gsea_output_location)),value=TRUE)
		folder_path<-paste0(gsub("\\\\","/",gsea_output_location),"/",folder_name)
		timestamp_gsea_2<<-strsplit(folder_name,"Preranked.")[[1]][2]
		EM.AA_enrichmentsDataset2<<-paste0(gsub("/","\\\\",paste0(folder_path,"/","gsea_report_for_na_pos_",timestamp_gsea_2,".xls")))
		EM.AA_enrichments2Dataset2<<-paste0(gsub("/","\\\\",paste0(folder_path,"/","gsea_report_for_na_neg_",timestamp_gsea_2,".xls")))
		EM.AA_ranksDataset2<<-gsea_rnk_2
		
		dir.create(paste0(root,"/","GSEA Cutoffs_2"))
		newgsea_folder_name<-paste0(root,"/","GSEA Cutoffs_2")
		file.copy(paste0(folder_path,"/","gsea_report_for_na_neg_",timestamp_gsea_2,".xls"), to=newgsea_folder_name)
		file.copy(paste0(folder_path,"/","gsea_report_for_na_pos_",timestamp_gsea_2,".xls"), to=newgsea_folder_name)
		
		#make the fdr0.05 file for pos
		orig.data<-read.delim(paste0(newgsea_folder_name,"/","gsea_report_for_na_pos_",timestamp_gsea_2,".xls"),stringsAsFactors = FALSE,header = FALSE)
		data<-orig.data[-1,]
		data2<-data[(as.numeric(data[,8])<=0.05),]
		data2<-rbind(orig.data[1,],data2)
		data2<-data2[,-12]
		name.edit<-paste0(newgsea_folder_name,"/",timestamp_gsea_2," pos fdr0.05.xls")
		write.table(data2,name.edit,sep="\t",quote=FALSE,row.names=FALSE,col.names=FALSE)
		EM.AA_enrichmentsDataset2q.05<<-paste0(gsub("/","\\\\",name.edit))

		
		#make the fdr0.10 file for pos
		orig.data<-read.delim(paste0(newgsea_folder_name,"/","gsea_report_for_na_pos_",timestamp_gsea_2,".xls"),stringsAsFactors = FALSE,header = FALSE)
		data<-orig.data[-1,]
		data2<-data[(as.numeric(data[,8])<=0.10),]
		data2<-rbind(orig.data[1,],data2)
		data2<-data2[,-12]
		name.edit<-paste0(newgsea_folder_name,"/",timestamp_gsea_2," pos fdr0.10.xls")
		write.table(data2,name.edit,sep="\t",quote=FALSE,row.names=FALSE,col.names=FALSE)
		EM.AA_enrichmentsDataset2q.10<<-paste0(gsub("/","\\\\",name.edit))
		
		#make the fdr0.05 file for neg
		orig.data<-read.delim(paste0(newgsea_folder_name,"/","gsea_report_for_na_neg_",timestamp_gsea_2,".xls"),stringsAsFactors = FALSE,header = FALSE)
		data<-orig.data[-1,]
		data2<-data[(as.numeric(data[,8])<=0.05),]
		data2<-rbind(orig.data[1,],data2)
		data2<-data2[,-12]
		name.edit<-paste0(newgsea_folder_name,"/",timestamp_gsea_2," neg fdr0.05.xls")
		write.table(data2,name.edit,sep="\t",quote=FALSE,row.names=FALSE,col.names=FALSE)
		EM.AA_enrichments2Dataset2q.05<<-paste0(gsub("/","\\\\",name.edit))
		
		#make the fdr0.10 file for neg
		orig.data<-read.delim(paste0(newgsea_folder_name,"/","gsea_report_for_na_neg_",timestamp_gsea_2,".xls"),stringsAsFactors = FALSE,header = FALSE)
		data<-orig.data[-1,]
		data2<-data[(as.numeric(data[,8])<=0.10),]
		data2<-rbind(orig.data[1,],data2)
		data2<-data2[,-12]
		name.edit<-paste0(newgsea_folder_name,"/",timestamp_gsea_2," neg fdr0.10.xls")
		write.table(data2,name.edit,sep="\t",quote=FALSE,row.names=FALSE,col.names=FALSE)
		EM.AA_enrichments2Dataset2q.10<<-paste0(gsub("/","\\\\",name.edit))
		
		timestamp_gsea<<-paste(timestamp_gsea_1, timestamp_gsea_2)
	}
}

#this function assumes there is only one node file in the "output location" and conducts a post cytoscape analysis on it. 
cytoscape_analysis_2<-function(){
	cyto_output<-list.files(output_location)
	data_for_analysis<-cyto_output[grep("node",cyto_output)]
	
	for (x in 1:length(data_for_analysis)){
		data<-read.csv(paste0(output_location,"/",data_for_analysis[x]))
		#list of columns to extract from raw cytoscape table
		names<-list("shared.name","name","EM1_GS_DESCR","X__mclCluster","EM1_fdr_qvalue..Dataset.1.","EM1_fdr_qvalue..Dataset.2.","EM1_NES..Dataset.1.","EM1_NES..Dataset.2.")
		tot<-list()
		count<-1
		for (a in names){
			col<-data[,which(colnames(data)==a)]
			tot[[count]]<-col
			count<-count+1
			print(which(colnames(data)==a))
		}
		df<-data.frame(tot)
		colnames(df)<-unlist(list("shared.name","name" ,"em1.GS.descr","cluster", "inner","outer","NES.inner","NES.outer"))
		
		#One modification is that we have to make a dummy table of cluster names since we cannot pull thar from cytoscape. 
		number_clusters<-range(na.omit(df[,"cluster"]))[2]
		dummy_clusters<-list()
		dummy_clusters[[1]]<-do.call(paste0,args=list(rep("Cluster ",number_clusters),1:number_clusters))
		dummy_clusters[[2]]<-1:number_clusters
		dummy_clusters<-data.frame(dummy_clusters)
		colnames(dummy_clusters)<-unlist(list("Cluster name","Cluster Number"))
		
		#ripped from my cluster analysis script. 
		#read in cluster names
		cluster.names<-dummy_clusters
		node.list<-df
		
		#add columns to define whether statistically significant in category
		#generate the node list by using the GSEA export function for the cluster list. The numbers do not match up correctly if you copy and paste the cluster list after sorting by cluster number, because clusters with the same number of nodes may switch places. Only, the exported version has the clusters in the correct order.
		node.list$inner.binary<-node.list$inner!="NA"
		node.list$inner.binary<-node.list$inner.binary %in% "TRUE"
		node.list$outer.binary<-node.list$outer!="NA"
		node.list$outer.binary<-node.list$outer.binary %in% "TRUE"
		
		#classify each gene set 
		classifier<-list()
		for (i in 1:nrow(node.list)){
			if (node.list[i,"inner.binary"]=="TRUE" & node.list[i,"outer.binary"]=="TRUE"){
				hold<-"common"
			} else if (node.list[i,"inner.binary"]=="TRUE" & node.list[i,"outer.binary"]=="FALSE"){
				hold<-"inner"
			} else if (node.list[i,"inner.binary"]=="FALSE" & node.list[i,"outer.binary"]=="TRUE"){
				hold<-"outer"
			} else if (node.list[i,"inner.binary"]=="FALSE" & node.list[i,"outer.binary"]=="FALSE"){
				hold<-"error"
			}
			classifier[i]<-hold
		}
		
		classifier<-unlist(classifier)
			
		# put the classifier and raw table together
		master<-cbind(node.list,classifier)
		master<-master[!is.na(master$cluster),]
		
		#decision to tree that categorizes
		cluster.genesets<-list()
		class<-list("inner","outer","common")
		cluster.classifier<-list()
		common<-0
		outer<-0
		inner<-0
		inner.count<-0
		outer.count<-0
		#Sort cluster
		for (i in 1:max(na.omit(node.list$cluster))){
			table.hold<-master[master$cluster==i,]
			cluster.genesets[i]<-nrow(table.hold)
			tally<-data.matrix(table(table.hold$classifier))
			#add EVLP,both or LTx to the tally table if it wasnt in the cluster
			if ((sum(class %in% unlist(row.names(tally))))<3){
				if ("common" %in% unlist(row.names(tally))=="FALSE"){
					tally<-rbind(tally, common)
				}
				if ("outer" %in% unlist(row.names(tally))=="FALSE"){
					tally<-rbind(tally, outer)
				} 
				if ("inner" %in% unlist(row.names(tally))=="FALSE"){
					tally<-rbind(tally, inner)
				}
			}
			
			#change the two rows with 0.75 in them to manipulate the sorting criteria
			if (tally["inner",1]/nrow(table.hold)>=0.75){
				cat.hold<-"Inner Specific"
			}else if (tally["outer",1]/nrow(table.hold)>=0.75){
				cat.hold<-"Outer Specific"
			} else {
				cat.hold<-"Common"
			}
			
			inner.count[i]<-tally["inner",1]
			outer.count[i]<-tally["outer",1]
			cluster.classifier[i]<-cat.hold
			print(i)
		}
		
		
		#creates the output
		output1<-cbind(cluster.classifier,inner.count,outer.count,cluster.genesets)
		output1<-cbind(cluster.names,output1)
		final.output<-output1[order(unlist(output1[,"cluster.classifier"])),]
		final.output.nodecut<-final.output[(final.output[,"cluster.genesets"]>=3),]
		table(as.character(final.output.nodecut[,"cluster.classifier"]))
			
		# number of positive and negative nodes for common
		#this get the row names from final.output.nodecut which represent the cluster numbers
		common.clusternum<-rownames(final.output.nodecut[((as.character(final.output.nodecut[,"cluster.classifier"])=="Common")),])
		common.nodes.pos<-sum(na.omit((master[,"cluster"] %in% common.clusternum)& (master[,"NES.inner"]>=0) & (master[,"NES.outer"]>=0))) + (sum(na.omit((master[,"cluster"] %in% common.clusternum)& (master[,"NES.inner"]>=0) & (is.na(master[,"NES.outer"]))))) + (sum(na.omit((master[,"cluster"] %in% common.clusternum)& (is.na(master[,"NES.inner"])) & (master[,"NES.outer"]>=0))))
		common.nodes.neg<-sum(na.omit((master[,"cluster"] %in% common.clusternum)& (master[,"NES.inner"]<=0) & (master[,"NES.outer"]<=0))) + (sum(na.omit((master[,"cluster"] %in% common.clusternum)& (master[,"NES.inner"]<=0) & (is.na(master[,"NES.outer"]))))) + (sum(na.omit((master[,"cluster"] %in% common.clusternum)& (is.na(master[,"NES.inner"])) & (master[,"NES.outer"]<=0))))
		common.nodes.opp<-sum(na.omit((master[,"cluster"] %in% common.clusternum)& (master[,"NES.inner"]<=0) & (master[,"NES.outer"]>=0))) + sum(na.omit((master[,"cluster"] %in% common.clusternum)& (master[,"NES.inner"]>=0) & (master[,"NES.outer"]<=0)))
		total.nodes.common<-sum(master[,"cluster"] %in% common.clusternum)
		print(c(common.nodes.pos,common.nodes.neg,common.nodes.opp))
		
		# number of positive and negative nodes for inner
		#this get the row names from final.output.nodecut which represent the cluster numbers
		inner.clusternum<-rownames(final.output.nodecut[((as.character(final.output.nodecut[,"cluster.classifier"])=="Inner Specific")),])
		inner.nodes.pos<-sum(na.omit((master[,"cluster"] %in% inner.clusternum)& (master[,"NES.inner"]>=0) & (master[,"NES.outer"]>=0))) + (sum(na.omit((master[,"cluster"] %in% inner.clusternum)& (master[,"NES.inner"]>=0) & (is.na(master[,"NES.outer"]))))) + (sum(na.omit((master[,"cluster"] %in% inner.clusternum)& (is.na(master[,"NES.inner"])) & (master[,"NES.outer"]>=0))))
		inner.nodes.neg<-sum(na.omit((master[,"cluster"] %in% inner.clusternum)& (master[,"NES.inner"]<=0) & (master[,"NES.outer"]<=0))) + (sum(na.omit((master[,"cluster"] %in% inner.clusternum)& (master[,"NES.inner"]<=0) & (is.na(master[,"NES.outer"]))))) + (sum(na.omit((master[,"cluster"] %in% inner.clusternum)& (is.na(master[,"NES.inner"])) & (master[,"NES.outer"]<=0))))
		inner.nodes.opp<-sum(na.omit((master[,"cluster"] %in% inner.clusternum)& (master[,"NES.inner"]<=0) & (master[,"NES.outer"]>=0))) + sum(na.omit((master[,"cluster"] %in% inner.clusternum)& (master[,"NES.inner"]>=0) & (master[,"NES.outer"]<=0)))
		total.nodes.inner<-sum(master[,"cluster"] %in% inner.clusternum)
		print(c(inner.nodes.pos,inner.nodes.neg,inner.nodes.opp))
		
		# number of positive and negative nodes for outer
		outer.clusternum<-rownames(final.output.nodecut[((as.character(final.output.nodecut[,"cluster.classifier"])=="Outer Specific")),])
		outer.nodes.pos<-sum(na.omit((master[,"cluster"] %in% outer.clusternum)& (master[,"NES.inner"]>=0) & (master[,"NES.outer"]>=0))) + (sum(na.omit((master[,"cluster"] %in% outer.clusternum)& (master[,"NES.inner"]>=0) & (is.na(master[,"NES.outer"]))))) + (sum(na.omit((master[,"cluster"] %in% outer.clusternum)& (is.na(master[,"NES.inner"])) & (master[,"NES.outer"]>=0))))
		outer.nodes.neg<-sum(na.omit((master[,"cluster"] %in% outer.clusternum)& (master[,"NES.inner"]<=0) & (master[,"NES.outer"]<=0))) + (sum(na.omit((master[,"cluster"] %in% outer.clusternum)& (master[,"NES.inner"]<=0) & (is.na(master[,"NES.outer"]))))) + (sum(na.omit((master[,"cluster"] %in% outer.clusternum)& (is.na(master[,"NES.inner"])) & (master[,"NES.outer"]<=0))))
		outer.nodes.opp<-sum(na.omit((master[,"cluster"] %in% outer.clusternum)& (master[,"NES.inner"]<=0) & (master[,"NES.outer"]>=0))) + sum(na.omit((master[,"cluster"] %in% outer.clusternum)& (master[,"NES.inner"]>=0) & (master[,"NES.outer"]<=0)))
		total.nodes.outer<-sum(master[,"cluster"] %in% outer.clusternum)
		print(c(outer.nodes.pos,outer.nodes.neg,outer.nodes.opp))
		
		fileConn<-file(paste0("report for ",data_for_analysis[x],".txt"))
		writeLines(c(paste0("of the common clusters that met cutoff there are:",common.nodes.pos,"-that are positive ",common.nodes.neg,"-that are negative ",common.nodes.opp,"-that are opposite"),paste0("of the inner clusters that met cutoff there are:",inner.nodes.pos,"-that are positive ",inner.nodes.neg,"-that are negative ",inner.nodes.opp,"-that are opposite"),paste0("of the outer clusters that met cutoff there are:",outer.nodes.pos,"-that are positive ",outer.nodes.neg,"-that are negative ",outer.nodes.opp,"-that are opposite")),fileConn)
		close(fileConn)
		
		lone.nodes<-sum(is.na(node.list[,"cluster"]))
		print(paste("number of nodes not in a cluster is ",lone.nodes,sep=""))
		print(paste("The total number of nodes in this dataset is ",nrow(node.list),sep=""))
		
		
		#the script above calculates the node composition for clusters with a specific size (cutoff) we should recalculate with all cluster regardless of how small and add them all up to make sure we have accounted for all nodes
		#because im super lazy im just going to rerun the same script again without changing the names of variables. Instead of referencing the the cut down table of nodes i will reference the full table of nodes
		#IF TROUBLE SHOOTING REMEMBER THAT THE VARIABLES BELOW THIS PART ARE A RERUN OF ABOVE TO CHECK TOTAL NODE NUMBER ON THE NON CUT DOWN TABLE. need to comment below out if trouble shooting
		
		# number of positive and negative nodes for common
		#this get the row names from final.output.nodecut which represent the cluster numbers
		common.clusternum<-rownames(final.output[((as.character(final.output[,"cluster.classifier"])=="Common")),])
		common.nodes.pos<-sum(na.omit((master[,"cluster"] %in% common.clusternum)& (master[,"NES.inner"]>=0) & (master[,"NES.outer"]>=0))) + (sum(na.omit((master[,"cluster"] %in% common.clusternum)& (master[,"NES.inner"]>=0) & (is.na(master[,"NES.outer"]))))) + (sum(na.omit((master[,"cluster"] %in% common.clusternum)& (is.na(master[,"NES.inner"])) & (master[,"NES.outer"]>=0))))
		common.nodes.neg<-sum(na.omit((master[,"cluster"] %in% common.clusternum)& (master[,"NES.inner"]<=0) & (master[,"NES.outer"]<=0))) + (sum(na.omit((master[,"cluster"] %in% common.clusternum)& (master[,"NES.inner"]<=0) & (is.na(master[,"NES.outer"]))))) + (sum(na.omit((master[,"cluster"] %in% common.clusternum)& (is.na(master[,"NES.inner"])) & (master[,"NES.outer"]<=0))))
		common.nodes.opp<-sum(na.omit((master[,"cluster"] %in% common.clusternum)& (master[,"NES.inner"]<=0) & (master[,"NES.outer"]>=0))) + sum(na.omit((master[,"cluster"] %in% common.clusternum)& (master[,"NES.inner"]>=0) & (master[,"NES.outer"]<=0)))
		total.nodes.common<-sum(master[,"cluster"] %in% common.clusternum)
		print(total.nodes.common)
		
		
		# number of positive and negative nodes for inner
		#this get the row names from final.output which represent the cluster numbers
		inner.clusternum<-rownames(final.output[((as.character(final.output[,"cluster.classifier"])=="Inner Specific")),])
		inner.nodes.pos<-sum(na.omit((master[,"cluster"] %in% inner.clusternum)& (master[,"NES.inner"]>=0) & (master[,"NES.outer"]>=0))) + (sum(na.omit((master[,"cluster"] %in% inner.clusternum)& (master[,"NES.inner"]>=0) & (is.na(master[,"NES.outer"]))))) + (sum(na.omit((master[,"cluster"] %in% inner.clusternum)& (is.na(master[,"NES.inner"])) & (master[,"NES.outer"]>=0))))
		inner.nodes.neg<-sum(na.omit((master[,"cluster"] %in% inner.clusternum)& (master[,"NES.inner"]<=0) & (master[,"NES.outer"]<=0))) + (sum(na.omit((master[,"cluster"] %in% inner.clusternum)& (master[,"NES.inner"]<=0) & (is.na(master[,"NES.outer"]))))) + (sum(na.omit((master[,"cluster"] %in% inner.clusternum)& (is.na(master[,"NES.inner"])) & (master[,"NES.outer"]<=0))))
		inner.nodes.opp<-sum(na.omit((master[,"cluster"] %in% inner.clusternum)& (master[,"NES.inner"]<=0) & (master[,"NES.outer"]>=0))) + sum(na.omit((master[,"cluster"] %in% inner.clusternum)& (master[,"NES.inner"]>=0) & (master[,"NES.outer"]<=0)))
		total.nodes.inner<-sum(master[,"cluster"] %in% inner.clusternum)
		print(total.nodes.inner)
		
		
		# number of positive and negative nodes for outer
		outer.clusternum<-rownames(final.output[((as.character(final.output[,"cluster.classifier"])=="Outer Specific")),])
		outer.nodes.pos<-sum(na.omit((master[,"cluster"] %in% outer.clusternum)& (master[,"NES.inner"]>=0) & (master[,"NES.outer"]>=0))) + (sum(na.omit((master[,"cluster"] %in% outer.clusternum)& (master[,"NES.inner"]>=0) & (is.na(master[,"NES.outer"]))))) + (sum(na.omit((master[,"cluster"] %in% outer.clusternum)& (is.na(master[,"NES.inner"])) & (master[,"NES.outer"]>=0))))
		outer.nodes.neg<-sum(na.omit((master[,"cluster"] %in% outer.clusternum)& (master[,"NES.inner"]<=0) & (master[,"NES.outer"]<=0))) + (sum(na.omit((master[,"cluster"] %in% outer.clusternum)& (master[,"NES.inner"]<=0) & (is.na(master[,"NES.outer"]))))) + (sum(na.omit((master[,"cluster"] %in% outer.clusternum)& (is.na(master[,"NES.inner"])) & (master[,"NES.outer"]<=0))))
		outer.nodes.opp<-sum(na.omit((master[,"cluster"] %in% outer.clusternum)& (master[,"NES.inner"]<=0) & (master[,"NES.outer"]>=0))) + sum(na.omit((master[,"cluster"] %in% outer.clusternum)& (master[,"NES.inner"]>=0) & (master[,"NES.outer"]<=0)))
		total.nodes.outer<-sum(master[,"cluster"] %in% outer.clusternum)
		print(total.nodes.outer)
		
		print(paste("The total number of nodes accounted for in this analysis is ",sum(common.nodes.pos,common.nodes.neg,common.nodes.opp,inner.nodes.pos,inner.nodes.neg,inner.nodes.opp,outer.nodes.pos,outer.nodes.neg,outer.nodes.opp,lone.nodes),sep=""))
	}
}

#major inconsistency in how "EM.AA_enrichmentsDataset1" vs "EM.AA_enrichmentsDataset1q.05" is generated. One uses the deault gsea_output_location while the other uses root. This needs to be fixed in this function and likely all the othe EM_AA functions, although the script seems to operate fine with the defualt apply function is used.
#' This function is used as part of a pipeline. It converts the output from GSEA so that the "enrichmentMap_annotate_single" function can follow up for further analysis
#fixed a major bug here that was a result of having to use R as the working directory to point the output of GSEA. Likely have to fix in other EM.AA functions
GSEA_to_EM.AA_single<-function(cutoff,gsea_output_is_root){
	if (cutoff==0){
		folder_name<<-grep(gsea_output_name_1,list.files(gsub("\\\\","/",gsea_output_location)),value=TRUE)
		folder_path<<-paste0(gsub("\\\\","/",gsea_output_location),"/",folder_name)
		timestamp_gsea<<-strsplit(folder_name,"Preranked.")[[1]][2]
		EM.AA_enrichmentsDataset1<<-paste0(gsub("/","\\\\",paste0(folder_path,"/","gsea_report_for_na_pos_",timestamp_gsea_1,".xls")))
		EM.AA_enrichments2Dataset1<<-paste0(gsub("/","\\\\",paste0(folder_path,"/","gsea_report_for_na_neg_",timestamp_gsea_1,".xls")))
		EM.AA_ranksDataset1<<-gsea_rnk_1
		EM.AA_gmtFile<<-gsea_gmt
	}else{
		if (gsea_output_is_root==TRUE){
			#when gsea makes a file in R's working directory it will make a folder with the gsea_out_name (which we ususally name as "0"), and then put the gsea result in that folder
			folder_name<<-grep(gsea_output_name_1,list.files(paste0(gsub("\\\\","/",gsea_output_location),"/0")),value=TRUE)
			folder_path<<-paste0(gsub("\\\\","/",gsea_output_location),"/0","/",folder_name)
		}else{
			#lets find the gsea name. We need to grep twice, once for the gsea_output_name and the second for the string "GseaPreranked". if we only do the first other files also have the same gsea_output_name contained
			folder_name<<-grep("GseaPreranked",grep(gsea_output_name_1,list.files(gsub("\\\\","/",gsea_output_location)),value=TRUE),value=TRUE)
			folder_path<<-paste0(gsub("\\\\","/",gsea_output_location),"/",folder_name)
		}

		timestamp_gsea_1<<-strsplit(folder_name,"Preranked.")[[1]][2]
		timestamp_gsea<<-strsplit(folder_name,"Preranked.")[[1]][2]
		EM.AA_enrichmentsDataset1<<-paste0(gsub("/","\\\\",paste0(folder_path,"/","gsea_report_for_na_pos_",timestamp_gsea_1,".xls")))
		EM.AA_enrichments2Dataset1<<-paste0(gsub("/","\\\\",paste0(folder_path,"/","gsea_report_for_na_neg_",timestamp_gsea_1,".xls")))
		EM.AA_ranksDataset1<<-gsea_rnk_1
		EM.AA_gmtFile<<-gsea_gmt
		
		#create folder to hold pos and neg files that we will screen
		dir.create(paste0(root,"/","GSEA Cutoffs_1",gsea_output_name_1))
		newgsea_folder_name<-paste0(root,"/","GSEA Cutoffs_1",gsea_output_name_1)
		file.copy(paste0(folder_path,"/","gsea_report_for_na_neg_",timestamp_gsea_1,".xls"), to=newgsea_folder_name)
		file.copy(paste0(folder_path,"/","gsea_report_for_na_pos_",timestamp_gsea_1,".xls"), to=newgsea_folder_name)
		
		#make the fdr0.05 file for pos
		orig.data<-read.delim(paste0(newgsea_folder_name,"/","gsea_report_for_na_pos_",timestamp_gsea_1,".xls"),stringsAsFactors = FALSE,header = FALSE)
		data<-orig.data[-1,]
		data2<-data[(as.numeric(data[,8])<=0.05),]
		data2<-rbind(orig.data[1,],data2)
		data2<-data2[,-12]
		name.edit<-paste0(newgsea_folder_name,"/",timestamp_gsea_1," pos fdr0.05.xls")
		write.table(data2,name.edit,sep="\t",quote=FALSE,row.names=FALSE,col.names=FALSE)
		EM.AA_enrichmentsDataset1q.05<<-paste0(gsub("/","\\\\",name.edit))
		
		#make the fdr0.10 file for pos
		orig.data<-read.delim(paste0(newgsea_folder_name,"/","gsea_report_for_na_pos_",timestamp_gsea_1,".xls"),stringsAsFactors = FALSE,header = FALSE)
		data<-orig.data[-1,]
		data2<-data[(as.numeric(data[,8])<=0.10),]
		data2<-rbind(orig.data[1,],data2)
		data2<-data2[,-12]
		name.edit<-paste0(newgsea_folder_name,"/",timestamp_gsea_1," pos fdr0.10.xls")
		write.table(data2,name.edit,sep="\t",quote=FALSE,row.names=FALSE,col.names=FALSE)
		EM.AA_enrichmentsDataset1q.10<<-paste0(gsub("/","\\\\",name.edit))
		
		#make the fdr0.05 file for neg
		orig.data<-read.delim(paste0(newgsea_folder_name,"/","gsea_report_for_na_neg_",timestamp_gsea_1,".xls"),stringsAsFactors = FALSE,header = FALSE)
		data<-orig.data[-1,]
		data2<-data[(as.numeric(data[,8])<=0.05),]
		data2<-rbind(orig.data[1,],data2)
		data2<-data2[,-12]
		name.edit<-paste0(newgsea_folder_name,"/",timestamp_gsea_1," neg fdr0.05.xls")
		write.table(data2,name.edit,sep="\t",quote=FALSE,row.names=FALSE,col.names=FALSE)
		EM.AA_enrichments2Dataset1q.05<<-paste0(gsub("/","\\\\",name.edit))
		
		#make the fdr0.10 file for neg
		orig.data<-read.delim(paste0(newgsea_folder_name,"/","gsea_report_for_na_neg_",timestamp_gsea_1,".xls"),stringsAsFactors = FALSE,header = FALSE)
		data<-orig.data[-1,]
		data2<-data[(as.numeric(data[,8])<=0.10),]
		data2<-rbind(orig.data[1,],data2)
		data2<-data2[,-12]
		name.edit<-paste0(newgsea_folder_name,"/",timestamp_gsea_1," neg fdr0.10.xls")
		write.table(data2,name.edit,sep="\t",quote=FALSE,row.names=FALSE,col.names=FALSE)
		EM.AA_enrichments2Dataset1q.10<<-paste0(gsub("/","\\\\",name.edit))
	}
}


#' this function tries to find what you are trying to do and guess what analysis you want based on the files in the working directory
auto_find<-function(){
	files<-list.files()
	rank_files<-files[grep(".rnk",files)]
	if((length(rank_files)>=2)){
	loop_exit<-0
	while(loop_exit!=1){
			cor<-readline(prompt=paste0("Do you want to compare ",rank_files[1],"/",rank_files[2],"  (y/n) Press enter \"n\" to switch"))
			if(cor=="y"){
				gsea_rnk_1<<-rank_files[1]
				gsea_rnk_2<<-rank_files[2]
				print(paste0("gsea_rnk_1: \"",gsea_rnk_1,"\".  gsea_rnk_2: \"",gsea_rnk_2,"g\" ",".  Used for Comparison."))
				comp<<-paste0("gsea_rnk_1: \"",gsea_rnk_1,"\".  gsea_rnk_2: \"",gsea_rnk_2,"\" ",".  Used for Comparison.")
				fileConn<-file(paste0("GSEA Run Param.txt"))
				writeLines(paste0(comp),fileConn)
				close(fileConn) 
				loop_exit<-1
				Sys.sleep(3)
			}else if(cor=="n"){
				gsea_rnk_1<<-rank_files[2]
				gsea_rnk_2<<-rank_files[1]
				print(paste0("gsea_rnk_1: \"",gsea_rnk_1,"\".  gsea_rnk_2: \"",gsea_rnk_2,"g\" ",".  Used for Comparison."))
				comp<<-paste0("gsea_rnk_1: \"",gsea_rnk_1,"\".  gsea_rnk_2: \"",gsea_rnk_2,"\" ",".  Used for Comparison.")
				fileConn<-file(paste0("GSEA Run Param.txt"))
				writeLines(paste0(comp),fileConn)
				close(fileConn)
				loop_exit<-1
				Sys.sleep(3)
			}else{
				print("dude theres only two options")
			}
		}
	}
}

#' A function which will compute broad Pre-Ranked GSEA on a .rnk file
#'
#' @param gsea_soft a file path to where the GSEA .jar file is stored
#' @param gsea_memory speify the ram that should be allocated to run GSEA
#' @param gsea_rnk a .rnk file which will be used as input for preranked gsea. Make sure the that both the column of gene names and column of scores both have headers 
#' @param gsea_gmt a .gmt file which hold the database which will be used 
#' @param gsea_output_name a string with the name you would like the output folder to be named. NO SPACES ALLOWED.
#' @param gsea_output_location a file path a path to where the output file should be saved. R passes a string to GSEA to define the path. Therefore your path must in the format "C://Users//Aaron Wong//Google Drive//Masters//Curiosity//"
#' @param timestamp a timestamp for permutation
s.broad_GSEA_preranked<-function(s.gsea_soft,s.gsea_memory,s.gsea_nperm,s.gsea_rnk,s.gsea_gmt,s.gsea_output_name,s.gsea_output_location,s.timestamp,s.set_max=500,s.set_min=15,wait=TRUE){
	system(paste0("java -cp \"",s.gsea_soft,"\" ","-Xmx",s.gsea_memory,"m xtools.gsea.GseaPreranked -gmx ",s.gsea_gmt," -norm meandiv -nperm ",s.gsea_nperm," -rnk ",s.gsea_rnk," -scoring_scheme weighted -rpt_label ",s.gsea_output_name," -create_svgs false -make_sets true -plot_top_x 20 -rnd_seed ",s.timestamp," -set_max ",s.set_max," -set_min ",s.set_min," -zip_report false -out ",s.gsea_output_location," -gui false -collapse false"),wait=wait,show.output.on.console = FALSE)
}

# Change log:
# v70-73: removed gsea_output_name1 argument as this was used when the version of this function which was used as part of a pipeline.
# 		  

#' A function which will take the result of a GSEA and plot the results on enrichment map and cluster the nodes
#'
#' @param result_name a string with the name of the .cys file you will be saving
#' @param EM.AA_analysisType a string defining what kind of GSEA analysis you did
#' @param EM.AA_enrichmentsDataset1 the pos.xls file outputted from GSEA
#' @param EM.AA_enrichments2Dataset1 he neg.xls file outputted from GSEA
#' @param EM.AA_ranksDataset1 the .rnk file used for GSEA. You can use your original of the one in the GSEA "edb" folder
#' @param EM.AA_gmtFilehe a .gmt file. You must use the original, and NOT the one in the "edb" folder as this is cut down (processed) by GSEA
#' @param EM.AA_qvalue your false discovery rate cutoff
#' @param EM.AA_pvalue your p-value cutoff
#' @param layout.choice parameter that specifies whether clusters should be laid out after clustering. set to TRUE to layout.
#' @param similarity.type a string selecting the algorithm to calculate node similartiy. Your options are "JACCORD|OVERLAP|COMBINED"
#' @param combined.constant in the case that you chose combined, you need to define the combined constant that should be used. If you chose another algorithim input this as "0"
#' @param similarity.constant similarity constant cutoff
#' @param id a name for the outputs of the node, network and name tables from cytoscape
#to evaluate a single dataset
#result name is just the file name 
#function outputs to the root, so either manually set it or run this program from the location where you want the output made
s.enrichmentMap_annotate_single<-function(s.result_name,s.EM.AA_analysisType,s.EM.AA_enrichmentsDataset1,s.EM.AA_enrichments2Dataset1,s.EM.AA_ranksDataset1,s.EM.AA_gmtFile,s.EM.AA_qvalue,s.EM.AA_pvalue,s.layout.choice,s.similarity.type,s.combined.constant,s.similarity.constant,s.id,output_dir){

	#check if cytoscape is open, if not open it
	cytoscape_instance<-length(grep("CYTOSC",readLines(textConnection(system('tasklist',intern=TRUE))),value=TRUE))
	if (cytoscape_instance!=0){
		}else{
			if(Sys.info()["nodename"]=="DESKTOP-KDS5VMG"){
				system('"C:\\Program Files\\Cytoscape_v3.7.0\\Cytoscape.exe"',wait=FALSE)
			}else if(Sys.info()["nodename"]=="LAPTOP-6I4LNRPP"){
				system('"C:\\Program Files\\Cytoscape_v3.7.0\\Cytoscape.exe"',wait=FALSE)
			}else if (Sys.info()["nodename"]=="DESKTOP-H7N6HGL"){
				system('"C:\\Program Files\\Cytoscape_v3.8.2\\Cytoscape.exe"',wait=FALSE)
			}else{
				system('"C:\\Program Files\\Cytoscape_v3.6.1\\Cytoscape.exe"',wait=FALSE)
			}
		t<-1
		time<-0
		while(t!=0){
			cytoscape_opened<-try(cytoscapePing ())
			if (class(cytoscape_opened)=="try-error"){
				time<-time+1
				print(paste0("Cytoscape is still loading. Please wait...","(",time,")"))
				Sys.sleep(1)
			}else{
				t<-0
				print("You are connected to Cytoscape.")
				#give R extra time to load
				Sys.sleep(5)
			}
		}
		
	}
	
	# here commands API is buggy and needs to reopened every time cytoscape is relaunched. Well use old script to close it every time after running.
	
	######partI of pid finding####
	# capture the result of a `tasklist` system call
	before.win.tasklist <- system2( 'tasklist' , stdout = TRUE )
	# store all pids before running the process
	before.pids <- substr( before.win.tasklist[ -(1:3) ] , 27 , 35 )
	######end of part I###
	
	# commandsAPI()
	#added extra sleep, if you dont do this the REST API does not load propoerly because it is not given time before R moves on to something else
	Sys.sleep(15)
	
	######partII of pid finding###
	# capture the result of a `tasklist` system call
	after.win.tasklist <- system2( 'tasklist' , stdout = TRUE )
	# store all tasks after running the process
	after.tasks <- substr( after.win.tasklist[ -(1:3) ] , 1 , 25 )
	# store all pids after running the process
	after.pids <- substr( after.win.tasklist[ -(1:3) ] , 27 , 35 )
	# store the number in the task list containing the PIDs you've just initiated
	initiated.pid.positions <- which( !( after.pids %in% before.pids ) )
	# remove whitespace
	after.tasks <- gsub( " " , "" , after.tasks )
	# find the pid position that matches the executable file name. ### EDIT THE NAME TO SUIT NEEDS ###
	correct.pid.position <- 
		intersect(
			which( after.tasks %in% "chrome.exe" ) ,
			initiated.pid.positions 
		)
	# remove whitespace
	correct.pid <- gsub( " " , "" , after.pids[ correct.pid.position ] )
	######end of part II####
	print(paste0("enrichmentmap build analysisType=\"",s.EM.AA_analysisType,"\" enrichmentsDataset1=\"",s.EM.AA_enrichmentsDataset1,"\" enrichments2Dataset1=\"",s.EM.AA_enrichments2Dataset1,"\" ranksDataset1=\"",s.EM.AA_ranksDataset1,"\" gmtFile=\"",s.EM.AA_gmtFile,"\" qvalue=",s.EM.AA_qvalue," pvalue=",s.EM.AA_pvalue," coefficients=",s.similarity.type," combinedConstant=",s.combined.constant," similaritycutoff=",s.similarity.constant))
	print(s.EM.AA_analysisType)
	print(s.EM.AA_enrichmentsDataset1)
	print(s.EM.AA_enrichments2Dataset1)
	print(s.EM.AA_ranksDataset1)
	print(s.EM.AA_gmtFile)
	print(s.EM.AA_qvalue)
	print(s.EM.AA_pvalue)
	print(s.similarity.type)
	print(s.combined.constant)
	print(s.similarity.constant)
	# need a try in case there were no genesets of significance
	try(commandsGET(paste0("enrichmentmap build analysisType=\"",s.EM.AA_analysisType,"\" enrichmentsDataset1=\"",s.EM.AA_enrichmentsDataset1,"\" enrichments2Dataset1=\"",s.EM.AA_enrichments2Dataset1,"\" ranksDataset1=\"",s.EM.AA_ranksDataset1,"\" gmtFile=\"",s.EM.AA_gmtFile,"\" qvalue=",s.EM.AA_qvalue," pvalue=",s.EM.AA_pvalue," coefficients=",s.similarity.type," combinedConstant=",s.combined.constant," similaritycutoff=",s.similarity.constant)))
	# need try in case there are nodes, but too few for clustering
	try(commandsGET("autoannotate annotate-sizeSorted network=\"Enrichment Map\""))
	if (s.layout.choice==TRUE){
		try.layout<-try(commandsGET("autoannotate layout network=Enrichment Map"))
		if (class(try.layout)=="try-error"){
			print("Could not layout clusters")
		}
	}
	#the list of autoannotate cluster still needs to be retrieved manually
	#output_dir already contains a slash at the end
	dir.create(paste0(output_dir,"cyto_",s.result_name,"fdr",s.EM.AA_qvalue))
	output_location<-paste0(output_dir,"cyto_",s.result_name,"fdr",s.EM.AA_qvalue)
	#export tables which may be useful
	commandsGET(paste0("session save file=",gsub("/","\\\\",output_location),"\\",Sys.Date(),"_",s.result_name,"_",s.id,".cys"))
	commandsGET(paste0("table export OutputFile=",gsub("/","\\\\",output_location),"\\",s.result_name,"default node"," id ",s.id,".csv ","table=Enrichment Map default node"))
	commandsGET(paste0("table export OutputFile=",gsub("/","\\\\",output_location),"\\",s.result_name,"default edge"," id ",s.id,".csv ","table=Enrichment Map default edge"))
	commandsGET(paste0("table export OutputFile=",gsub("/","\\\\",output_location),"\\",s.result_name,"default network"," id ",s.id,".csv ","table=Enrichment Map default network"))
	#close cytoscape
	closeSession(save.before.closing = FALSE)
	commandsGET("command quit")
	
	#kill CyREST
	#kill the tasks which were spawned (there may be more than one)
	for (task_to_kill in correct.pid){
		taskkill.cmd <- gsub("\"","\\\"",paste( "taskkill" , "/PID" , task_to_kill," /F"))
		print(taskkill.cmd)
		system( taskkill.cmd )
	}
	
	
	#give time for everything to close
	Sys.sleep(5)
}


#' A function which will take the result of a GSEA and plot the results on enrichment map and cluster the nodes. Does not kill cyrest. 
#'
#' @param result_name a string with the name of the .cys file you will be saving
#' @param EM.AA_analysisType a string defining what kind of GSEA analysis you did
#' @param EM.AA_enrichmentsDataset1 the pos.xls file outputted from GSEA
#' @param EM.AA_enrichments2Dataset1 he neg.xls file outputted from GSEA
#' @param EM.AA_ranksDataset1 the .rnk file used for GSEA. You can use your original of the one in the GSEA "edb" folder
#' @param EM.AA_gmtFilehe a .gmt file. You must use the original, and NOT the one in the "edb" folder as this is cut down (processed) by GSEA
#' @param EM.AA_qvalue your false discovery rate cutoff
#' @param EM.AA_pvalue your p-value cutoff
#' @param layout.choice parameter that specifies whether clusters should be laid out after clustering. set to TRUE to layout.
#' @param similarity.type a string selecting the algorithm to calculate node similartiy. Your options are "JACCORD|OVERLAP|COMBINED"
#' @param combined.constant in the case that you chose combined, you need to define the combined constant that should be used. If you chose another algorithim input this as "0"
#' @param similarity.constant similarity constant cutoff
#' @param id a name for the outputs of the node, network and name tables from cytoscape
#to evaluate a single dataset
#result name is just the file name 
#function outputs to the root, so either manually set it or run this program from the location where you want the output made
s.enrichmentMap_annotate_single_no_kill_cyrest<-function(s.result_name,s.EM.AA_analysisType,s.EM.AA_enrichmentsDataset1,s.EM.AA_enrichments2Dataset1,s.EM.AA_ranksDataset1,s.EM.AA_gmtFile,s.EM.AA_qvalue,s.EM.AA_pvalue,s.layout.choice,s.similarity.type,s.combined.constant,s.similarity.constant,s.id,output_dir){

	#check if cytoscape is open, if not open it
	cytoscape_instance<-length(grep("CYTOSC",readLines(textConnection(system('tasklist',intern=TRUE))),value=TRUE))
	if (cytoscape_instance!=0){
		}else{
			if(Sys.info()["nodename"]=="DESKTOP-KDS5VMG"){
				system('"C:\\Program Files\\Cytoscape_v3.7.0\\Cytoscape.exe"',wait=FALSE)
			}else if(Sys.info()["nodename"]=="LAPTOP-6I4LNRPP"){
				system('"C:\\Program Files\\Cytoscape_v3.7.0\\Cytoscape.exe"',wait=FALSE)
			}else if (Sys.info()["nodename"]=="DESKTOP-H7N6HGL"){
				system('"C:\\Program Files\\Cytoscape_v3.8.2\\Cytoscape.exe"',wait=FALSE)
			}else{
				system('"C:\\Program Files\\Cytoscape_v3.6.1\\Cytoscape.exe"',wait=FALSE)
			}
		t<-1
		time<-0
		while(t!=0){
			cytoscape_opened<-try(cytoscapePing ())
			if (class(cytoscape_opened)=="try-error"){
				time<-time+1
				print(paste0("Cytoscape is still loading. Please wait...","(",time,")"))
				Sys.sleep(1)
			}else{
				t<-0
				print("You are connected to Cytoscape.")
				#give R extra time to load
				Sys.sleep(5)
			}
		}
		
	}
	######end of part II####
	print(paste0("enrichmentmap build analysisType=\"",s.EM.AA_analysisType,"\" enrichmentsDataset1=\"",s.EM.AA_enrichmentsDataset1,"\" enrichments2Dataset1=\"",s.EM.AA_enrichments2Dataset1,"\" ranksDataset1=\"",s.EM.AA_ranksDataset1,"\" gmtFile=\"",s.EM.AA_gmtFile,"\" qvalue=",s.EM.AA_qvalue," pvalue=",s.EM.AA_pvalue," coefficients=",s.similarity.type," combinedConstant=",s.combined.constant," similaritycutoff=",s.similarity.constant))
	print(s.EM.AA_analysisType)
	print(s.EM.AA_enrichmentsDataset1)
	print(s.EM.AA_enrichments2Dataset1)
	print(s.EM.AA_ranksDataset1)
	print(s.EM.AA_gmtFile)
	print(s.EM.AA_qvalue)
	print(s.EM.AA_pvalue)
	print(s.similarity.type)
	print(s.combined.constant)
	print(s.similarity.constant)
	closeSession(save.before.closing = FALSE)
	commandsGET(paste0("enrichmentmap build analysisType=\"",s.EM.AA_analysisType,"\" enrichmentsDataset1=\"",s.EM.AA_enrichmentsDataset1,"\" enrichments2Dataset1=\"",s.EM.AA_enrichments2Dataset1,"\" ranksDataset1=\"",s.EM.AA_ranksDataset1,"\" gmtFile=\"",s.EM.AA_gmtFile,"\" qvalue=",s.EM.AA_qvalue," pvalue=",s.EM.AA_pvalue," coefficients=",s.similarity.type," combinedConstant=",s.combined.constant," similaritycutoff=",s.similarity.constant))
	commandsGET("autoannotate annotate-sizeSorted network=\"Enrichment Map\"")
	if (s.layout.choice==TRUE){
		try.layout<-try(commandsGET("autoannotate layout network=Enrichment Map"))
		if (class(try.layout)=="try-error"){
			print("Could not layout clusters")
		}
	}
	Sys.sleep(1)
	#the list of autoannotate cluster still needs to be retrieved manually
	#output_dir already contains a slash at the end
	dir.create(paste0(output_dir,"cyto_",s.result_name,"fdr",s.EM.AA_qvalue))
	Sys.sleep(0.5)
	output_location<-paste0(output_dir,"cyto_",s.result_name,"fdr",s.EM.AA_qvalue)
	#export tables which may be useful
	commandsGET(paste0("session save file=",gsub("/","\\\\",output_location),"\\",Sys.Date(),"_",s.result_name,"_",s.id,".cys"))
	commandsGET(paste0("table export OutputFile=",gsub("/","\\\\",output_location),"\\",s.result_name,"default node"," id ",s.id,".csv ","table=Enrichment Map default node"))
	commandsGET(paste0("table export OutputFile=",gsub("/","\\\\",output_location),"\\",s.result_name,"default edge"," id ",s.id,".csv ","table=Enrichment Map default edge"))
	commandsGET(paste0("table export OutputFile=",gsub("/","\\\\",output_location),"\\",s.result_name,"default network"," id ",s.id,".csv ","table=Enrichment Map default network"))
	Sys.sleep(1)
}






#' A function which will take two GSEA results and create an enrichment map and cluster the nodes
#'
#' @param result_name a string with the name of the .cys file you will be saving
#' @param EM.AA_analysisType a string defining what kind of GSEA analysis you did
#' @param EM.AA_enrichmentsDataset1 the pos.xls file outputed from GSEA for dataset 1
#' @param EM.AA_enrichments2Dataset1 he neg.xls file outputed from GSEA for dataset 1
#' @param EM.AA_enrichmentsDataset2 the pos.xls file outputed from GSEA for dataset 2
#' @param EM.AA_enrichments2Dataset2 he neg.xls file outputed from GSEA for dataset 2
#' @param EM.AA_ranksDataset1 the .rnk file used for GSEA. You can use your original of the one in the GSEA "edb" folder
#' @param EM.AA_gmtFilehe a .gmt file. You must use the original, and NOT the one in the "edb" folder as this is cut down (processed) by GSEA
#' @param EM.AA_qvalue your false discovery rate cutoff
#' @param EM.AA_pvalue your p-value cutoff
#' @param layout.choice parameter that specifies whether clusters should be laid out after clustering. set to TRUE to layout.
#' @param similarity.type a string selecting the algorithm to calculate node similartiy. Your options are "JACCORD|OVERLAP|COMBINED"
#' @param combined.constant in the case that you chose combined, you need to define the combined constant that should be used. If you chose another algorithim input this as "0"
#' @param similarity.constant similarity constant cutoff
#' @param id a name for the outputs of the node, network and name tables from cytoscape
s.enrichmentMap_annotate_2<-function(result_name,EM.AA_analysisType,EM.AA_enrichmentsDataset1,EM.AA_enrichments2Dataset1,EM.AA_ranksDataset1,EM.AA_enrichmentsDataset2,EM.AA_enrichments2Dataset2,EM.AA_ranksDataset2,EM.AA_gmtFile,EM.AA_qvalue,EM.AA_pvalue,layout.choice,similarity.type,combined.constant,similarity.constant,id){
	
	#check if cytoscape is open, if not open it
	cytoscape_instance<-length(grep("CYTOSC",readLines(textConnection(system('tasklist',intern=TRUE))),value=TRUE))
	if (cytoscape_instance!=0){
		}else{
		######partI of pid finding####
		# capture the result of a `tasklist` system call
		before.win.tasklist <- system2( 'tasklist' , stdout = TRUE )
		# store all pids before running the process
		before.pids <- substr( before.win.tasklist[ -(1:3) ] , 27 , 35 )
		######end of part I###
		
		system('"C:\\Program Files\\Cytoscape_v3.6.1\\Cytoscape.exe"',wait=FALSE)
		Sys.sleep(5)
		
		######partII of pid finding###
		# capture the result of a `tasklist` system call
		after.win.tasklist <- system2( 'tasklist' , stdout = TRUE )
		# store all tasks after running the process
		after.tasks <- substr( after.win.tasklist[ -(1:3) ] , 1 , 25 )
		# store all pids after running the process
		after.pids <- substr( after.win.tasklist[ -(1:3) ] , 27 , 35 )
		# store the number in the task list containing the PIDs you've just initiated
		initiated.pid.positions <- which( !( after.pids %in% before.pids ) )
		# remove whitespace
		after.tasks <- gsub( " " , "" , after.tasks )
		# find the pid position that matches the executable file name. ### EDIT THE NAME TO SUIT NEEDS ###
		correct.pid.position <- 
			intersect(
				which( after.tasks %in% "CYTOSC~1.EXE" ) ,
				initiated.pid.positions 
			)
		# remove whitespace
		correct.pid_cytoscape <<- gsub( " " , "" , after.pids[ correct.pid.position ] )
		######end of part II####
		
		t<-1
		time<-0
		while(t!=0){
			cytoscape_opened<-try(cytoscapePing ())
			if (class(cytoscape_opened)=="try-error"){
				time<-time+1
				print(paste0("Cytoscape is still loading. Please wait...","(",time,")"))
				Sys.sleep(1)
			}else{
				t<-0
				print("You are connected to Cytoscape.")
				Sys.sleep(30)
			}
		}
		
	}
	
	# here commands API is buggy and needs to reopened every time cytoscape is relaunched. Well use old script to close it every time after running.
	
	######partI of pid finding####
	# capture the result of a `tasklist` system call
	before.win.tasklist <- system2( 'tasklist' , stdout = TRUE )
	# store all pids before running the process
	before.pids <- substr( before.win.tasklist[ -(1:3) ] , 27 , 35 )
	######end of part I###
	
	commandsAPI()
	Sys.sleep(15)
	
	######partII of pid finding###
	# capture the result of a `tasklist` system call
	after.win.tasklist <- system2( 'tasklist' , stdout = TRUE )
	# store all tasks after running the process
	after.tasks <- substr( after.win.tasklist[ -(1:3) ] , 1 , 25 )
	# store all pids after running the process
	after.pids <- substr( after.win.tasklist[ -(1:3) ] , 27 , 35 )
	# store the number in the task list containing the PIDs you've just initiated
	initiated.pid.positions <- which( !( after.pids %in% before.pids ) )
	# remove whitespace
	after.tasks <- gsub( " " , "" , after.tasks )
	# find the pid position that matches the executable file name. ### EDIT THE NAME TO SUIT NEEDS ###
	correct.pid.position <- 
		intersect(
			which( after.tasks %in% "MicrosoftEdge.exe" ) ,
			initiated.pid.positions 
		)
	# remove whitespace
	correct.pid <- gsub( " " , "" , after.pids[ correct.pid.position ] )
	######end of part II####

	commandsGET(paste0("enrichmentmap build analysisType=\"",EM.AA_analysisType,"\" enrichmentsDataset1=\"",EM.AA_enrichmentsDataset1,"\" enrichments2Dataset1=\"",EM.AA_enrichments2Dataset1,"\" ranksDataset1=\"",EM.AA_ranksDataset1,"\" gmtFile=\"",EM.AA_gmtFile,"\" qvalue=",EM.AA_qvalue," pvalue=",EM.AA_pvalue," enrichmentsDataset2=\"",EM.AA_enrichmentsDataset2,"\" enrichments2Dataset2=\"",EM.AA_enrichments2Dataset2,"\" ranksDataset2=\"",EM.AA_ranksDataset1,"\""," coefficients=",similarity.type," combinedConstant=",combined.constant," similaritycutoff=",similarity.constant))
	commandsGET("autoannotate annotate-sizeSorted network=\"Enrichment Map\"")
	if (layout.choice==TRUE){
		commandsGET("autoannotate layout network=\"Enrichment Map\"")
	}
	#the list of autoannotate cluster still needs to be retrieved manually
	dir.create(paste0(root,"/","cyto ",Sys.Date()))
	output_location<<-paste0(root,"/","cyto ",Sys.Date())
	commandsGET(paste0("session save file=",gsub("/","\\\\",output_location),"\\",Sys.Date(),result_name,id,".cys"))
	commandsGET(paste0("table export OutputFile=",gsub("/","\\\\",output_location),"\\",result_name,"default node"," id ",id,".csv ","table=Enrichment Map default node"))
	commandsGET(paste0("table export OutputFile=",gsub("/","\\\\",output_location),"\\",result_name,"default edge"," id ",id,".csv ","table=Enrichment Map default edge"))
	commandsGET(paste0("table export OutputFile=",gsub("/","\\\\",output_location),"\\",result_name,"default network"," id ",id,".csv ","table=Enrichment Map default network"))
	cyto_version_data<<-getInstalledApps()
	commandsGET("command quit")
	
	#check if cytoscape has closed, this may take some time if the network is large and takes several minutes to build. If not wait
	cytoscape_closed<-1
	while(cytoscape_closed!=0){
		Sys.sleep(1)
		# capture the result of a `tasklist` system call
		after.win.tasklist <- system2( 'tasklist' , stdout = TRUE )
		# store all pids after running the process
		after.pids <- substr( after.win.tasklist[ -(1:3) ] , 27 , 35 )	
		# remove whitespace
		after.pids <- gsub( " " , "" , after.pids )
		if (correct.pid_cytoscape %in% after.pids){
		}else{
			cytoscape_closed<-0
		}
	}
	
	#kill CyREST
	#kill the task
	taskkill.cmd <- gsub("\"","\\\"",paste( "taskkill" , "/PID" , correct.pid," /F"))
	system( taskkill.cmd )

	#give time for everything to close
	Sys.sleep(10)
}

cyto_versions<-function(){
	fileConn<-file(paste0(root,"/",Sys.Date(),"Cyto_app_versions",".txt"))
	writeLines(cyto_version_data, fileConn)
	close(fileConn)
}


#' This function will apply any defualts which have not been enetered
apply_defaults<-function(){
	########################################################################################################################################################################################
	#Defualt Parameters

	#Broad Gene Set Enrichment Analysis Parameters (the input is java format, need to escape backslashes since for R since it sends out commands). Parameters not listed are GSEA defualt.
	###################################

	#if (gsea_rnk_1!=0 & gsea_rnk_2!=0){
	#	gsea_rnk_1<<-paste0(gsub("/","\\\\",paste0(root,"/",gsea_rnk_1)))
	#	gsea_rnk_2<<-paste0(gsub("/","\\\\",paste0(root,"/",gsea_rnk_2)))
	#}else if (gsea_rnk_1==0 & gsea_rnk_2==0){
	##	auto_find()
	#	#so far the input of gsea_rnk_X has only been the file name. We need a path
	#}

	###TOMAKE THE PROGRAM WORK COMMENTED THIS OUT, FORGOT WHY I NEEDED THIS
	#gsea_rnk_1<-paste0(gsub("/","\\\\",paste0(getwd(),"/",gsea_rnk_1)))
	#gsea_rnk_2<-paste0(gsub("/","\\\\",paste0(getwd(),"/",gsea_rnk_2)))

		

	files<-list.files()
	#if (length(grep("gmt",files))==1){
	#	gmt_file<-paste0(files[grep("gmt",files)])
	#	gsea_gmt<<-paste0(getwd(),"/",gmt_file)
	#}

	gsea_output_location<<-root
	if(timestamp_gsea==0){
		timestamp_gsea<<-"timestamp"
	}

	#load defualt values if they have been left 
	if (gsea_memory==0){
		gsea_memory<<-4096
	}
	if (gsea_nperm==0){
		gsea_nperm<<-1000
	}
	if (gsea_output_name_1==0){
		gsea_output_name_1<<-"My_Analysis_1"
	}
	if (gsea_output_name_2==0){
		gsea_output_name_2<<-"My_Analysis_2"
	}
	##################################

	#Visualize in Cytoscape
	#######################
	commands_API_launched<-0

	if (EM.AA_qvalue==0){
		EM.AA_qvalue<<-0.05
	}
	if (EM.AA_pvalue==0){
		EM.AA_pvalue<<-0.001
	}
}


#this function generates a 10-digit seed (which can be used as a seed to run GSEA)
generate_seed<-function(){
	a<-as.numeric(paste(sample(0:9,10,replace=T), collapse = ""))
	return(a)
}

#functions to convert from fold to log2ratio and vice versa
log2ratio2fold <- function (l2r) {
	options(warn = -1);
	fold <- ifelse(
		l2r >= 0,
		2^l2r,
		-1/2^l2r
	);
	return(fold);
}

fold2log2ratio <- function (fold) {
	options(warn = -1);
	l2r <- ifelse(
		fold > 0,
		log2(fold),
		log2(-1/fold)
	);
	return(l2r);
}

ratio2fold <- function (r) {
	fold <- ifelse(
		r >= 1,
		r,
		-1/r
	);
	return(fold);
}

fold2ratio <- function (fold) {
	r <- ifelse(
		fold > 0,
		fold,
		-1/fold
	);
	return(r);
}
