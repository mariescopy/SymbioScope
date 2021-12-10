// CAM macro to launch a Mark & Find experiment at the positions found from a low-res overview mosaic
// Marie Walde, SBR 12/2020

//PARAMETRS
	xSign = 1; 	
	ySign = 1;  

// 1) Read-in the mosaic scan and find the cells of interest ///////////////////////////////////////////
// First version: Open stitched mosaic manually
	myfile = File.openDialog("Select overview scan mosaic");
	myname = File.getName(myfile);
	mypath = File.getParent(myfile) + File.separator;
	print("File: "+myname); print("Path: "+mypath);

	//
	run("Bio-Formats Importer", "open=[" + mypath + myname +"] autoscale color_mode=Composite view=Hyperstack stack_order=Default use_virtual_stack series_"+n);
	rename("MyMontage");

	// Maximum projection along z
	run("Z Project...", "projection=[Max Intensity]");

	// Merge colour channels
	if (num_channels==3) {
		run("Split Channels");
		//selectWindow("MyMontage"); close();
		for (i = 1; i < (num_channels+1); i++) {
			selectWindow("C"+i+"-MAX_MyMontage");
			run("Enhance Contrast", "saturated=0.1");
		}
		run("Merge Channels...", "c2=C2-MAX_MyMontage c3=C1-MAX_MyMontage c6=C3-MAX_MyMontage keep");
	}
	rename("OverviewScan");

// Chose how to find the cells - automatically or manually  ///////////////////////////////////////////
	selectWindow("OverviewScan");
	run("Point Tool...", "mark=0 label selection=yellow");
		setTool("multipoint");	
	
		if(selectionType()==10){
			run("Clear Results");
			run("Set Measurements...", "centroid redirect=None decimal=2");
			run("Measure");
		}
	
		waitForUser("You can now edit the selected positions:\n \n - Left click to create a new point\n - Drag a point to move it\n - Alt+ left click to remove a point\n - Zoom with shift+up/down arrows\n - Hold space and drag the view to move around\n");
	
		// Measure position of the points of interest
		run("Clear Results");
		run("Measure");

// 2) Calculate the positions to send and write the CAM script  ///////////////////////////////////////////

// 3) Launch the M&F experiment  ///////////////////////////////////////////
	waitForUser("> Load the MAF app in MatrixScanner\n > Keep the load position\n > Run a focus map");
	
	for
		//Delete the current MAF list
		/cli:test/app:matrix /sys:1 /cmd:maf /scmd:delete
		
		//Add a new X,Y Position to the MAF list
		/cli:test/app:matrix /sys:1 /cmd:maf /scmd:addxy /xpos:34.1 /ypos:438.7
	
	
		// Compute the X/Y offsets of the points of interest with respect to the scan field centers
		if(selectionType!=-1){
			xList = newArray(nResults);
			yList = newArray(nResults);		
			SFieldxList = newArray(nResults);
			SFieldyList = newArray(nResults);
			tPos = 0;
		
			for(i=0;i<nResults;i++){
				if((getResult("X",i)>-1)&&(getResult("Y",i)>-1)&&(getResult("X",i)<getWidth())&&(getResult("Y",i)<getHeight())){
					SFieldxList[tPos] = floor(getResult("X",i)/tile_size_overview)+1;
					SFieldyList[tPos] = floor(getResult("Y",i)/tile_size_overview)+1;
					xList[tPos] = round(tile_size_overview/2)-(getResult("X",i)%tile_size_overview);
					yList[tPos] = round(tile_size_overview/2)-(getResult("Y",i)%tile_size_overview);
					tPos++;
				}
			}
		
			aPos = getNumber("How many positions should be sent?",tPos);
			showMessage("Lauch the high resolution scan?\n \nIn total "+d2s(aPos,0)+" positions will be sent\n \nYou can assign a dummy job to the main scan");
		
			// Generate the MAF scan CAM script in log window
			if(isOpen("Log")){
				selectWindow("Log");
				run("Close");
			}
			
			print("/cli:marie /app:matrix /cmd:startscan");
			// TO DO: Can I avoid the 2nd overview scan here??
			print("/cli:marie /app:matrix /cmd:deletelist");
			for(i=0;i<aPos;i++){
				offx = -xSign*xList[i]-BBOffset;
				offy = -ySign*yList[i]-BBOffset;
	
				print("/cli:marie /app:matrix /cmd:add /tar:camlist /exp:"+JobHigh+" /ext:none /slide:0 /wellx:1 /welly:1 /fieldx:"+d2s(SFieldxList[i],0)+" /fieldy:"+d2s(SFieldyList[i],0)+" /dxpos:"+d2s(offx,0)+" /dypos:"+d2s(offy,0));
			}
			print("/cli:marie /app:matrix /cmd:startcamscan /runtime:9999 /repeattime:9999"); 			
			// runtime is set to a large value since CAM list scan should stop only once fully done 
			
			// Write log window to file
			selectWindow("Log");
			ScriptName2 = ExpPath+"CAMScript2.txt";
			run("Text...", "save=["+ScriptName2+"]");
			run("Close");
			
			// Send CAM script
			//if(CAMEnable==1){
				run("LASAFClient","filepath=["+ScriptName2+"] serverip="+LasafIP+" serverport=[LasafPort]");
			//}
		}
	}