//This script plots overview scans from the Leica SP8 back onto the wells 
// of the imaging chamber from which they were acquired.
// The purpose is to make it easy to compare the images with experimental conditions
// for hybridization screening assays.
//
// Marie Walde, Station Biologique de Roscoff, 2021

// PREAMBLE
	run("Bio-Formats Macro Extensions");
	run("Close All");
	setBatchMode(true) // makes the script considerably faster
	print("**********************************");

// LOCATE THE INDIVIDUAL IMAGES
	myfile = File.openDialog("Select file");
	myname = File.getName(myfile);
	mypath = File.getParent(myfile) + File.separator;
	print("Path: "+mypath); print("File: "+myname); 
	myname_all=substring(myname, 0, indexOf(myname, "Well"));

// LOAD IMAGES & GET THEIR DIMENSIONS
	titles=newArray(8); widths=newArray(8); heights=newArray(8); 
	
	for (U = 0; U < 2; U++) {
		for (V = 0; V < 4; V++) {
			run("Bio-Formats Importer", "open=[" + mypath + myname_all +"Well-U"+U+"-V"+V+".ome.tif] color_mode=Default view=Hyperstack  stack_order=XYCZT use_virtual_stack");
		
			titles[4*U+V] = getTitle; // indices 0 to 7
			print("Image Title of "+(4*U+V)+": "+titles[4*U+V]); // debug sanity check
			
			getDimensions(widths[4*U+V], heights[4*U+V], channels, slices, frames);
			print("Image width: "+widths[4*U+V]+"; Image height: "+heights[4*U+V]); // debug sanity check
			
			getPixelSize(pxlunit, pixelWidth, pixelHeight);
			print("Pixel size: ["+pixelWidth+"; "+pixelHeight+"] "+pxlunit);
		}
	}

// MAKE THEM ALL SQUARE
	Array.getStatistics(widths, wminimum, wmaximum, wmean);
	Array.getStatistics(heights, hminimum, hmaximum, hmean);
	for (U = 0; U < 2; U++) {
		for (V = 0; V < 4; V++) {
			selectWindow(titles[4*U+V]);
			print("Resizing Image"+(4*U+V));
			run("Canvas Size...", "width="+maxOf(wmaximum, hmaximum)+" height="+maxOf(wmaximum, hmaximum)+" position=Center zero");	
		}
	}

// COMBINE INTO A BIG PICTURE
	// final arrangement will look like this:
	//  ____________________
	// │U1V0│U1V1│U1V2│U1V3│ -> myU1
	// │____│____│____│____│
	// │U0V0│U0V1│U0V2│U0V3│ -> myU0
	// │____│____│____│____│
	//
	// The true dimension of the 8-well imaging chamber are 10.9 mm x 8.9 mm
	// The pixel size in "microns" [um] of the chamber is thus
	chamberwidth=round(10900/pixelWidth); chamberheight=round(8900/pixelHeight);
	print("Chamber width: "+chamberwidth+" pxl ; Chamber height: "+chamberheight+" pxl");
	
	// combine all U0 horizontally
	run("Combine...", "stack1="+titles[0]+" stack2="+titles[1]); rename("combi1");
	run("Combine...", "stack1="+titles[2]+" stack2="+titles[3]); rename("combi2");
	run("Combine...", "stack1=combi1 stack2=combi2"); 		 
	rename("myU0");
	//close("combi1"); close("combi2");
	
	// combine all U1 horizontally
	run("Combine...", "stack1="+titles[4]+" stack2="+titles[5]); rename("combi3");
	run("Combine...", "stack1="+titles[6]+" stack2="+titles[7]); rename("combi4");
	run("Combine...", "stack1=combi3 stack2=combi4");            
	rename("myU1");
	
	// combine both rows vertically
	run("Combine...", "stack1=myU0 stack2=myU1 combine"); rename("myOverview");
	close("\\Others");


// ENHANCE BRIGHTNESS AND CONTRAST OF ALL OF THEM TOGETHER
	setBatchMode(false)
	run("Split Channels");
	selectWindow("C1-myOverview");
	run("Enhance Contrast", "saturated=0");
	selectWindow("C2-myOverview");
	run("Enhance Contrast", "saturated=0");

// MERGE CHANNELS AND SAVE OUTPUT (can be slow)
	// OME TIFF with individual channels (for further anaylsis)
	run("Merge Channels...", "c2=C1-myOverview c4=C3-myOverview c6=C2-myOverview create keep"); //2:green, 4:grey, 6:magenta
	print("Saving OME TIFF: "+ mypath + myname_all+"AllWells.ome.tif");
	run("Bio-Formats Exporter", "save=" + mypath + myname_all+"AllWells.ome.tif compression=Uncompressed");
	
	// PNG and TIF with RGB colours (for presentations, publications etc)
	run("Merge Channels...", "c2=C1-myOverview c4=C3-myOverview c6=C2-myOverview");
	print("Saving PNG: "+ mypath + myname_all+"AllWells.png");
	saveAs("PNG", mypath +myname_all+"AllWells.png");
	print("Saving TIF: "+ mypath + myname_all+"AllWells.tif");
	saveAs("TIF", mypath +myname_all+"AllWells.tif");
// DONE :)