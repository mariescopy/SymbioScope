// Import individual Leica LIF files from Projects and create montages of them
//
// Marie Walde 2023-06 
// Station Biologique de Roscoff / Sorbonne Université & CNRS

//OPTIONS
opt_channelcheck=true; //User input for channel content from the first image
opt_DNAcorr=true; //apply gamma correction to DNA channel if signal is very noisy
opt_surfacecorr=true; //apply gamma correction to surface channel if signal is very bright or saturated

run("Bio-Formats Macro Extensions");
print("+++++++++++++++++++++++++++++++++++++++++++");
run("Close All");

// 1) Load the data
myfile = File.openDialog("Select .LIF file");
myname = File.getName(myfile);
mypath = File.getParent(myfile)+ File.separator;
//outputpath=mypath + "Export"+File.separator;
outputpath = getDir("");
print("File: "+myname);print("Path: "+mypath);print("Path: "+outputpath);

Ext.setId(mypath + myname);
Ext.getSeriesCount(sercount);
print("Count: "+sercount);

num_channels=5; //adapted for 5 channels

// Open each series of the project
for (n = 1; n < sercount+1; n++) { //to run the code
//for (n = 6; n < 7; n++) {	 //to test new code
	run("Close All");
	// The image name will also be printed in the Log window for verification
	Ext.setSeries(n-1);
	print("Image number: "+n);
	Ext.getSeriesName(sername)
	print("**********************************");
	print("Image name: "+sername);
		//Ext.getSeries(seriesName)
	
	run("Bio-Formats Importer", "open=[" + mypath + myname +"] autoscale color_mode=Composite split_channels view=Hyperstack stack_order=Default use_virtual_stack series_"+n);
	getDimensions(gwidth, gheight, gchannels, gslices, gframes);
	//print("getDimensions: width="+gwidth+", height="+gheight+", channels="+gchannels+", slices="+gslices+", frames="+gframes);
	//print("Number of channels: "+num_channels);
	titles=getList("image.titles");
	for (j = 0; j < num_channels; j++) {
		//print(j+" | "+titles[j]);
		selectWindow(titles[j]);
		setSlice(Math.floor(gslices/2)); wait(2);
		run("Enhance Contrast", "saturated=0.1");
	}
	run("Tile");
	
	//User input for channel content
	if(opt_channelcheck){  	
		Dialog.create("Channel content ");
		Dialog.addNumber("Dioc6-membranes", 1);
		Dialog.addNumber("Chlorophyll", 2);
		Dialog.addNumber("Transmission", 3);
		Dialog.addNumber("Hoechst-DNA", 4);
		Dialog.addNumber("A546-PLL", 5);
	
		Dialog.show();
		ch_membranes = Dialog.getNumber();
		ch_chl	     = Dialog.getNumber();
	 	ch_trans     = Dialog.getNumber();
		ch_DNA 		 = Dialog.getNumber();
		ch_surfaces  = Dialog.getNumber();
		opt_channelcheck=false; //only ask for the first image in a series
	}
	
	//Some notes on commands that might be interesting in the future
		//Ext.getSizeC(sizeC) //Gets the number of channels in the dataset.
		//Ext.getMetadataValue(field, value) //Obtains the specified metadata field's value.
		//Ext.getSeriesMetadataValue(field, value) //Obtains the specified series metadata field's value.
	
// 2) Process each channel
	  for (i = 0; i < num_channels; i++) {
	  		print("Processing channel: "+(i+1)); // /!\ Channel count in LIF file is 0-based
			print(sername+" - C="+(i));
    		selectWindow(titles[i]);
       		print("   "+titles[i]);
       		
       		if ((i+1)==ch_trans) {
				run("Gaussian-based stack focuser", "radius_of_gaussian_blur=3");
				//run("Subtract Background...", "rolling=400 light sliding stack");
				//run("Bio-Formats Exporter", "save="+mypath+"Export"+File.separator+myname+"_"+sername+"_TransFocusSlice.ome.tif");
				} 
			else {
				run("Enhance Contrast...", "saturated=0.1 normalize use");
       			selectWindow(titles[i]);
				run("Z Project...", "projection=[Max Intensity]");
				if ((i+1)==ch_DNA && opt_DNAcorr) {run("Gamma...", "value=1.3");}
				if ((i+1)==ch_surfaces && opt_surfacecorr) {
					run("Gamma...", "value=0.8");
					run("JDM Grays g=1.75 ");}
				}
				run("Gaussian Blur...", "sigma=0.5");
									
			run("Enhance Contrast", "saturated=0.1");
			rename("Channel_"+(i+1));
			selectWindow(titles[i]);
			close();
	
		//run("Bio-Formats Exporter", "save="+outputpath+myname+"_"+sername+"_MaxProj_Ch"+(i+1)+".ome.tif");
		saveAs("PNG", outputpath + myname+"_"+sername+"__MaxProj_Ch"+(i+1)+".png"); //save with Gamma=1
		wait(100);
		rename("Channel_"+(i+1));
	}
		
// 4) Merge channels
	if (1){
	// A composite view with original lookup tables
		print("Merge Channels...", "c2=Channel_"+ch_membranes+" c4=Channel_"+ch_surfaces+" c5=Channel_"+ch_DNA+" c6=Channel_"+ch_chl);
		run("Merge Channels...", "c2=Channel_"+ch_membranes+" c4=Channel_"+ch_surfaces+" c5=Channel_"+ch_DNA+" c6=Channel_"+ch_chl+" create keep"); //c2:green c4:grey c5:cyan c6:magenta
		//write output file
		run("Bio-Formats Exporter", "save="+outputpath+myname+"_"+sername+"_MaxProj_Composite.ome.tif");
		saveAs("Tiff", outputpath+myname+"_"+sername+"_MaxProj_Composite.tif");
		saveAs("PNG", outputpath+myname+"_"+sername+"_MaxProj_Composite.png");
		
		rename("myComposite"); //membranes; DNA; surfaces; chlorophyll
	}
	
	// B Composite with patially inverted LUT
	if(1){
		print("Inverting Channels");
		
	//if (opt_invertedLUT) {
		Stack.setChannel(1); // membranes
		//run("CRL BOP orange "); 
		run("CRL I Magenta ");
		run("Enhance Contrast", "saturated=0.1");
	 	
	 	Stack.setChannel(2); // surfaces
		//run("JDM Grays g=1.25 inverted ");
		run("JDM Grays g=1.50 inverted "); //gamma LUT can be adjusted to compensate for variations in surface staining 
		run("Enhance Contrast", "saturated=0");
		//setMinAndMax(10, 100);
	 	
	 	Stack.setChannel(3); // DNA
	 	//run("CRL BOP blue "); 
		run("CRL I Blue ");
		run("Enhance Contrast", "saturated=0.1");
	 	//setMinAndMax(10, 180);
		run("Gamma...", "value=1.3");
		
   	 	Stack.setChannel(4); // chlorophyll
   	 	//run("CRL BOP purple "); 
		run("CRL I Forest ");
		//setMinAndMax(10, 180);
		run("Enhance Contrast", "saturated=0.1");
		
		Property.set("CompositeProjection", "Min");
		Stack.setDisplayMode("composite");
		
		//write output file
		run("Bio-Formats Exporter", "save=" +outputpath+myname+"_"+sername+"_MaxProj_Composite_inverted.ome.tif");
		saveAs("PNG", outputpath+myname+"_"+sername+"_MaxProj_Composite_inverted.png");
		saveAs("Tiff", outputpath+myname+"_"+sername+"_MaxProj_Composite_inverted.tif");
	}   	   
	
	
// 5) Clean up
run("Close All");
openwindows = getList("window.titles");
for (i=0; i<openwindows.length; i++){
	winame = openwindows[i]; 
	if(winame != "Log") {
		selectWindow(winame); run("Close");
	}}  // Close everything but the Log window
}