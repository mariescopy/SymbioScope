// Rotate & crop 2D projection images of Guinardia to align along the vertical
//
// Marie Walde 2024-11, 
// Station Biologique de Roscoff/Sorbonne Université
///////////////////////////////////////////////////////////////////////////////
print("##############################################################################");

// Data paths
	//import_path="Y:/ImageData/2023_GuinardiaBloom/processed/2D_Projections/2023-05-12_reprocessed/";
	import_path = getDirectory("Choose input folder!"); 
	//export_path="Y:/ImageData/2023_GuinardiaBloom/processed/Rotated_Cropped/2023-05-12_reprocessed/";

// THIS IS THE ACTUAL SCRIPT
	print("Processing: " + import_path);
	processFolder(import_path);
	roiManager("Save", import_path+ File.separator+"ROICoordinates.zip");
	roiManager("Delete");

// HERE ARE THE FUNCTIONS
function processFolder(mypath) { // scan folders/subfolders/files to find files with correct suffix
		mylist = getFileList(mypath);
		mylist = Array.sort(mylist);
		for (j = 0; j < mylist.length; j++) {
		//for (j = 0; j < 20; j++) { //DEBUG
			if(File.isDirectory(mypath + File.separator + mylist[j])){
				processFolder(mypath + File.separator + mylist[j]);
				print("==============================================================================");
				print("Processing folder: " + mylist[j]);}
				
			if(endsWith(mylist[j], "_MaxProj_Composite.png")){
				export_path=replace(mypath, "2DProjections", "Rotated_Cropped");
				File.makeDirectory(export_path); 
				processFile(mypath, export_path, mylist[j]);}
		}
}

function processFile(mypath, output, file) {
	print("--------------------------------------------");
	print(file);
	
	// CLEAN UP open windows
		run("Close All");
		
		openwindows = getList("window.titles");
     	for (i=0; i<openwindows.length; i++){
  			winame = openwindows[i]; 
     		if(winame != "Log") {
     			if (winame!= "ROI Manager") {
					selectWindow(winame); run("Close");
				}}}  // Close everything but the Log window
	
	// OPEN FILE
		myfile = File.getName(file); //print("myfile: " + myfile);
		pngfile = replace(myfile, "tif", "png"); //print("pngfile: " + pngfile);
				
		// print("Bio-Formats Importer", "open="+mypath+myfile+" color_mode=Composite rois_import=[ROI manager] split_channels view=Hyperstack stack_order=Default use_virtual_stack");
		// run("Bio-Formats Importer", "open="+mypath+myfile+" color_mode=Composite rois_import=[ROI manager] split_channels view=Hyperstack stack_order=Default use_virtual_stack");
			
	
	if (0) {//Option 1: Detect rotation angle automatically	 DOES NOT WORK WELL ON ENVIRONMENTAL SAMPLES (TOO MUCH MESS)
		chl_channel = replace(myfile, "_MaxProj_Composite.tif", "__MaxProj_Ch2.png"); print("chl_channel: " + chl_channel);

		// Find the dominant angle of Guinardia Orientation (via Fourier spectrum analysis, using the OrientationJ plugin by BIG-EPFL)
		open(mypath+chl_channel);

		// selectWindow(myfile +" - C=2"); // Cholorphyll channel
		// run("Duplicate...", " "); run("8-bit");
	
		run("OrientationJ Dominant Direction");
		DominantAngle_Chl=getResult("Orientation [Degrees]", 0)-90;
		// Load the entire image and rotate to vertical axis
		open(mypath+pngfile);
		run("Rotate... ", "angle="+DominantAngle_Chl+" grid=1 interpolation=Bilinear enlarge");
		wait(1000);
	}
	
	if (1) {// Option 2: Draw a line along the object of interest	
		open(mypath+pngfile);
		setLineWidth(200);setTool(4); //straight line drawing tool
		waitForUser("Draw a line along the cells of interest");
		selectImage(pngfile);
		getLine(x1, y1, x2, y2, lineWidth);
		roiManager("add");
		dx = (x2-x1); dy = (y2-y1);
		mylength = sqrt(dx*dx+dy*dy);
		myalpha=Math.toDegrees(Math.atan(dx/dy));
		print("dx:" + dx + " dy: "+dy+" length: " +mylength+" ,alpha: "+myalpha);
		
		// cut image down to line area
		safetymargin=100;
		topy=Math.max(Math.min(y1, y2)-safetymargin,0);
		leftx=Math.max(Math.min(x1, x2)-safetymargin,0);
		makeRectangle(leftx, topy, Math.abs(dx)+3*safetymargin, Math.abs(dy)+3*safetymargin);	
		run("Crop");
		
		// align image along line
		run("Rotate... ", "angle="+myalpha+" grid=1 interpolation=Bilinear enlarge");
		wait(1000);
		newwidth=getWidth(); // this changes depending on rotation angle & zero padding
		newheight=getHeight();
		

	//Save rotation output
		//export_name=replace(pngfile,"_MaxProj_Composite.png","_2DRot.png");
		//print("Saving to: "+export_path+export_name);
		//saveAs("PNG", export_path + export_name);
	if (1) {
	// Crop central part
		cropwidth=400;
		makeRectangle(newwidth/2-cropwidth/2, 0, cropwidth, newheight);	
		run("Crop");
	}
		

	//Save cropped output
		export_name=replace(pngfile,"_MaxProj_Composite.png","_2DRot_crop.png");
		print("Saving to: "+export_path+ File.separator +export_name);
		saveAs("PNG", export_path + File.separator + export_name);
	}
}