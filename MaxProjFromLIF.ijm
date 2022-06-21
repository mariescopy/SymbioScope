// Import individual Leica LIF files from Projects and create montages of them
//
// Marie Walde 2020-11, 
// Station Biologique de Roscoff/Sorbonne Université

//OPTIONS
opt_rotation=false;
opt_crop=false;
opt_channelcheck=true; //User input for channel content from the first image


run("Bio-Formats Macro Extensions");
print("+++++++++++++++++++++++++++++++++++++++++++");
run("Close All");

// 1) Load the data
myfile = File.openDialog("Select .LIF file");
myname = File.getName(myfile);
mypath = File.getParent(myfile) + File.separator;
print("File: "+myname);
print("Path: "+mypath);

Ext.setId(mypath + myname);
Ext.getSeriesCount(sercount);
print("Count: "+sercount);

num_channels=4; //written for 4 default channels: "Transmission", "Chlorophyll", "RNA dye", "Hoechst

// Open each series of the project
for (n = 1; n < sercount+1; n++) { //to run the code
//for (n = 2; n < 3; n++) {	 //to test new code
	run("Close All");
	// The image name will also be printed in the Log window for verification
	Ext.setSeries(n-1);
	print("Image number: "+n);
	Ext.getSeriesName(sername)
	print("**********************************");
	print("Image name: "+sername);
		//Ext.getSeries(seriesName)
	
	run("Bio-Formats Importer", "open=[" + mypath + myname +"] autoscale color_mode=Composite split_channels view=Hyperstack stack_order=Default use_virtual_stack series_"+n);
	run("Enhance Contrast", "saturated=0");
	getDimensions(width, height, channels, slices, frames);
	print("Number of channels: "+num_channels);
	titles=getList("image.titles");
	run("Tile");
	
	//User input for channel content
	if(opt_channelcheck){  	
		Dialog.create("Channel content ");
		Dialog.addNumber("Chlorophyll", 4);
		Dialog.addNumber("Transmission", 2);
		Dialog.addNumber("RNA dye", 1);
		Dialog.addNumber("Hoechst", 3);
	
		Dialog.show();
		ch_chl	   = Dialog.getNumber();
	 	ch_trans   = Dialog.getNumber();
		ch_RNA	   = Dialog.getNumber();
		ch_Hoechst = Dialog.getNumber();
		opt_channelcheck=false; //only ask for the first image in a series
	}
	
	//Some notes on commands that might be interesting in the future
		//Ext.getSizeC(sizeC) //Gets the number of channels in the dataset.
		//Ext.getMetadataValue(field, value) //Obtains the specified metadata field's value.
		//Ext.getSeriesMetadataValue(field, value) //Obtains the specified series metadata field's value.
	
// 2) Process each channel
	  for (i = 0; i < num_channels; i++) {
			print("Processing channel: "+(i+1)); // /!\ Channel count in LIF file is 0-based
			print(sername+" - C="+i);
    		selectWindow(titles[i]);
       		print("   "+titles[i]);
       		
       		if ((i+1)==ch_trans) {
				run("Gaussian-based stack focuser", "radius_of_gaussian_blur=3");
				run("Subtract Background...", "rolling=400 light sliding stack");
				run("Bio-Formats Exporter", "save="+mypath+"Export"+File.separator+myname+"_"+sername+"_TransFocusSlice.ome.tif");
			}
			else {run("Z Project...", "projection=[Max Intensity]");}
			run("Enhance Contrast", "saturated=0");
			//if ((i+1)==ch_RNA) {run("Enhance Contrast", "saturated=0.1");}
			rename("Channel_"+(i+1));
			selectWindow(titles[i]);
			close();
		}
		
// 3) Option: Find rotation angle to align cells vertically 
	// this works pretty well on individual elongated cells, but fails if the samples very crowded
	if(opt_rotation){
		run("Set Measurements...", " feret's redirect=None decimal=0");
		//pick the transmission channel
		//selectWindow("Channel_"+ch_trans);
		//selectWindow("Channel_2");
		//run("Duplicate...", " ");
	
		//add chlorophyll and dye together
		imageCalculator("Add create", "Channel_"+ch_chl, "Channel_"+ch_RNA);
		// cut out the cell
		setAutoThreshold("Otsu dark");	run("Convert to Mask");
		run("Dilate");run("Dilate");run("Dilate");
		run("Fill Holes");
		run("Analyze Particles...", "size=3000-Infinity show=Overlay display clear in_situ");
		alpha = getResult("FeretAngle")-90;
		print("Feret Angle: "+alpha);
		run("Rotate... ", "rotate angle = "+alpha+" grid=1 interpolation=Bilinear fill enlarge");
		run("Select Bounding Box"); run("Enlarge...", "enlarge=20");
		roiManager("Add"); 
	}
	else {alpha=0;}

	for (i = 0; i < num_channels; i++) {
		selectWindow("Channel_"+(i+1));
		if (opt_rotation) {
			run("Rotate... ", "rotate angle = "+alpha+" grid=1 interpolation=None  fill enlarge");
		}
		if(opt_crop){
			roiManager("Select", 0);
			run("Crop");
		}
		run("Bio-Formats Exporter", "save=" + mypath + "Export"+File.separator+myname+"_"+sername+"_MaxProj_Ch"+(i+1)+".ome.tif");
		saveAs("PNG", mypath + "Export"+File.separator+myname+"_"+sername+"__MaxProj_Ch"+(i+1)+".png");
		rename("Channel_"+(i+1));
	}
		
// 4) Merge channels
		print("Merge Channels...", "c2=Channel_"+ch_RNA+" c3=Channel_"+ch_Hoechst+" c6=Channel_"+ch_chl);
		run("Merge Channels...", "c2=Channel_"+ch_RNA+" c3=Channel_"+ch_Hoechst+" c6=Channel_"+ch_chl+" create ignore"); //c2:green c3:blue c6:magenta
		
		//write output file
		run("Bio-Formats Exporter", "save=" + mypath + "Export"+File.separator+myname+"_"+sername+"_MaxProj_Composite.ome.tif");
		saveAs("PNG", mypath + "Export"+File.separator+myname+"_"+sername+"_MaxProj_Composite.png");

// 5) Clean up
	if(opt_rotation){run("ROI Manager..."); run("Select All"); roiManager("Delete");}
	run("Close All");
}