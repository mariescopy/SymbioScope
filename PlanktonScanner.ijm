//// PLANKTONSCANNER
//
// A two-step confocal scan procedure
// based on previous work by Sebastien Tosi (RegionsScanner, 2012)
// upgraded to work with BioFormats and
// adapted for the Leica SP8 confocal microscope with LASAF module 
// at the Station Biologique de Roscoff
//
// Date: 11-03-2020
// Author: Marie Walde, SBR

// PARAMETERS /////////////////////////////////////////
	xyFlip = 0; 	
	xSign = 1; 	
	ySign = 1;  	
	DefaultLasafIP = "127.000.000.001";
	DefaultLasafPort = 8895;
	DefaultJobHigh = "HiResScan";
	DefaultJobAF = "AF"; // /cli:marie /app:matrix /cmd:autofocusscan

	//	I should be able to get these parameters out of the metadata, but for now it's ok to enter them manually
	tile_size_overview=1024; // tile size in pxl
	tile_overlap=0.05; // precentage of overlap between tiles
	num_tiles=3;
	num_channels=2;
	num_zplanes=5;
	LowResScale=180.38; // [nm/pxl]
	TypicalCellSize=5000; //[nm]

// INITIALISATION /////////////////////////////////////
	// Macro parameters dialog box
	ExpPath = getDirectory("Path to the LASAF experiment folder");
	Dialog.create("PlanktonScanner setup");
	Dialog.addMessage("LASAF configuration");
	Dialog.addString("LASAF server IP", DefaultLasafIP);
	Dialog.addNumber("LASAF server port", DefaultLasafPort);
	Dialog.addString("Name of job for high resolution scan", DefaultJobHigh);
	Dialog.addMessage("Scans");
	Dialog.addCheckbox("Perform low resolution scan?", true);
	Dialog.addCheckbox("Send CAM script?", true);
	Dialog.addMessage("Overview scan parameters");
	Dialog.addNumber("Tiles size [pxl]",tile_size_overview); 
	Dialog.addNumber("Tiles overlap [%]",tile_overlap); 
	Dialog.addNumber("Number of tiles [only square]",num_tiles); 
	Dialog.addNumber("Number of channels",num_channels); 
	Dialog.addNumber("Number of z-steps",num_zplanes); 
	Dialog.show();

	// Recover parameters from dialog box
	LasafIP = Dialog.getString();
	LasafPort = Dialog.getNumber();
	JobHigh = Dialog.getString();
	LowScan = Dialog.getCheckbox();
	CAMEnable = Dialog.getCheckbox();

	tile_size_overview = Dialog.getNumber();
	tile_overlap = Dialog.getNumber();
	num_tiles = Dialog.getNumber();
	num_channels = Dialog.getNumber();
	num_zplanes = Dialog.getNumber();

	//selectWindow("Log");
	print("performing overview scan with the following parameters: tile size "+tile_size_overview+"| overlap "+tile_overlap+"| #tiles "+num_tiles+"| #channels "+num_channels+"| #zsteps "+num_zplanes);
	
	// Close all opened images
	run("Close All");


// 1 - OVERVIEW SCAN //////////////////////////////////////
	// Launch primary scan (low resolution)
	if (1) { //0: no need to make a new scan for now
	if(LowScan==1){
		showMessage("Lauch the low resolution scan? \n \nMake sure the main scan is correctly set!");
	
		// Generate the low resolution CAM script in log window
		if(isOpen("Log")){
			selectWindow("Log");
			run("Close");
		}

		print("/cli:marie /app:matrix /cmd:startscan");
		selectWindow("Log");
		ScriptName1 = ExpPath+"CAMScript1.txt";
		
		// Save log window to file
		run("Text...", "save=["+ScriptName1+"]");
		run("Close");
		
		// Send CAM script
		if(CAMEnable==1){
			run("LASAFClient","filepath=["+ScriptName1+"] serverip="+LasafIP+" serverport=[LasafPort]");}
	}}

	selectWindow("Log"); print("Finished the low res scan!");

// SCAN IMPORT & MONTAGE	
	// Find out images path (last folder in the experiment folder)
	MyList 	= getFileList(ExpPath);
	Array.sort(MyList);
	for(i=0;i<lengthOf(MyList);i++){
		if(endsWith(MyList[i],"/")){
			ImagesPath = ExpPath+MyList[i];	
	}}
	selectWindow("Log");
	print("ImagesPath: "+ImagesPath);

	// Import montage from Leica MatrixScreener
	run("Bio-Formats Importer", "open="+ImagesPath+"/image--L0000--S00--U00--V00--J00--X00--Y00--T0000--Z00--C00.ome.tif autoscale color_mode=Default group_files open_all_series rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT dimensions axis_1_number_of_images="+num_zplanes+" axis_1_axis_first_image=0 axis_1_axis_increment=1 axis_2_number_of_images="+num_channels+" axis_2_axis_first_image=0 axis_2_axis_increment=1 contains=[] name=D:/MatrixScreenerImages/EHux/experiments/scan--2020_06_04_08_48_14/image--L0000--S00--U00--V00--J00--X00--Y00--T0000--Z0<0-"+(num_zplanes-1)+">--C0<0-"+(num_channels-1)+">.ome.tif");
	rename("MyMontage");

	// Maximum projection along z
	run("Z Project...", "projection=[Max Intensity]");

	// Merge colour channels
	run("Split Channels");
	selectWindow("MyMontage"); close();
	run("Merge Channels...", "c5=C1-MAX_MyMontage c6=C2-MAX_MyMontage create ignore");
	run("Enhance Contrast", "saturated=0.1");
	rename("OverviewScan");

// Remove scale
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");

// SELECTION STEP //////////////////////////////////////////////
// Let's start with the easiest case: hand-picking
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


// 2- HIRES SCAN /////////////////////////////////////////
if(1){  //OFF for now
	// Compute a square bounding box around the selected objects
	BBLength=TypicalCellSize/LowResScale; // [pxl]
	BBOffset=round(sqrt(BBLength/2)); // good ol Pythagoras
	
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
	
		// Generate the secondary scan CAM script in log window
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
			if(xyFlip==1){
//print("/cli:marie /app:matrix /cmd:add /tar:camlist /exp:"+JobHigh+" /ext:none /slide:0 /wellx:"+d2s(WellxList[i],0)+" /welly:"+d2s(WellyList[i],0)+" /fieldx:1 /fieldy:1 /dxpos:"+d2s(offy,0)+" /dypos:"+d2s(offx,0));
			}
			else {	//			print("/cli:marie /app:matrix /cmd:add /tar:camlist /exp:"+JobHigh+" /ext:none /slide:0 /wellx:"+d2s(WellxList[i],0)+" /welly:"+d2s(WellyList[i],0)+" /fieldx:1 /fieldy:1 /dxpos:"+d2s(offx,0)+" /dypos:"+d2s(offy,0));
			}

			if(xyFlip==1){
				print("/cli:marie /app:matrix /cmd:add /tar:camlist /exp:"+JobHigh+" /ext:none /slide:0 /wellx:1 /welly:1 /fieldx:"+d2s(SFieldxList[i],0)+" /fieldy:"+d2s(SFieldyList[i],0)+" /dxpos:"+d2s(offy,0)+" /dypos:"+d2s(offx,0));
			}
			else {
				print("/cli:marie /app:matrix /cmd:add /tar:camlist /exp:"+JobHigh+" /ext:none /slide:0 /wellx:1 /welly:1 /fieldx:"+d2s(SFieldxList[i],0)+" /fieldy:"+d2s(SFieldyList[i],0)+" /dxpos:"+d2s(offx,0)+" /dypos:"+d2s(offy,0));
			}
		}
		print("/cli:marie /app:matrix /cmd:startcamscan /runtime:9999 /repeattime:9999"); 			
		// runtime is set to a large value since CAM list scan should stop only once fully done 
		
		// Write log window to file
		selectWindow("Log");
		ScriptName2 = ExpPath+"CAMScript2.txt";
		run("Text...", "save=["+ScriptName2+"]");
		run("Close");
		
		// Send CAM script
		if(CAMEnable==1){
			run("LASAFClient","filepath=["+ScriptName2+"] serverip="+LasafIP+" serverport=[LasafPort]");
		}
	}
}