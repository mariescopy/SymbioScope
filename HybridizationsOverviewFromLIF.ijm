// Import Leica LIF files of overview scans and create a montage from it
// The acquisition coordinates of the different imaging wells are (U,V)0
// For this analysis it is important not to adjust brightness or contrast!
// Fluorophores/probes can vary between experiments and are to be entered by hand
//
// Input: LIF files from Leica LASX software; in case of tile scans they should already be stitched
// Output: Maximum pro


run("Bio-Formats Macro Extensions");
run("Close All");
//setBatchMode(true)
print("**********************************");

//User input for channel content
	myContentArray=newArray("Chlorophyll", "Transmission", "Probe");
	Dialog.create("Channel content ");
	Dialog.addChoice("Channel 1", myContentArray, "Probe");
	Dialog.addChoice("Channel 2", myContentArray, "Chlorophyll");
	Dialog.addChoice("Channel 3", myContentArray, "Transmission");
	Dialog.show();

	ChannelContent=newArray("Ch1","Ch2","Ch3");
	ChannelContent[0]=Dialog.getChoice; ChannelContent[1]=Dialog.getChoice; ChannelContent[2]=Dialog.getChoice;

// Load the data
	myfile = File.openDialog("Select .LIF file");
	myname = File.getName(myfile);
	mypath = File.getParent(myfile) + File.separator;
	print("File: "+myname);
	print("Path: "+mypath);
	Ext.setId(mypath + myname);
	Ext.getSeriesCount(sercount);
	print("Count: "+sercount);

//for (ser = 1; ser < (sercount+1); ser++) { // for all images in the acquisition series (= for each well)	
for (ser = 1; ser < 2; ser++) { // for testing on one	
	run("Close All");
	run("Bio-Formats Importer", "open=[" + mypath + myname +"] autoscale color_mode=Composite view=Hyperstack stack_order=Default use_virtual_stack series_"+ser);
	getDimensions(width, height, channels, slices, frames);
	print("Num Channels: "+channels);
	run("Split Channels");
	titles=getList("image.titles");
	for (ch = 0; ch < channels; ch++) {print("   "+titles[ch]);}
	
	// Get the UV coordinates of the well
	// This is written for the generic naming format from the Leica MatrixScreener (would be different for other acquisition softwares)
	wellU=substring(titles[0], indexOf(titles[0], "_V ")-1,indexOf(titles[0], "_V "));
	wellV=substring(titles[0], indexOf(titles[0], "_V ")+3,indexOf(titles[0], "_V ")+4);
	print("Processing well U "+wellU+", V "+wellV);


// Reduce the Z dimension by mapping stacks onto 2D projections

	for (i = 0; i < channels; i++) {
		print("Processing channel: "+(i+1));
		//print(sername+" - C="+i);
		selectWindow(titles[i]);
		if (ChannelContent[i]=="Transmission") {
			//run("Subtract Background...", "rolling=400 light sliding stack");
			//run("Z Project...", "projection=[Min Intensity]");
			run("Z Project...", "projection=Median");
			run("Enhance Contrast", "saturated=0");
			rename("Channel_Trans");
		}
		else {
			run("Z Project...", "projection=[Max Intensity]");
			//these names could be generalized or even entered as paremeters...good enough for now
			if (ChannelContent[i]=="Probe") {rename("Channel_Probe");}
			if (ChannelContent[i]=="Chlorophyll") {rename("Channel_Chl");}
		}
		selectWindow(titles[i]);
		close();
		}

//Quantify the amount of hybridized cells
setBatchMode(false)
//if (0) {}

if (0) {
	//Merge channels
		run("Merge Channels...", "c2=Channel_Probe c4=Channel_Chl c6=Channel_Trans create");
		rename("Well U "+wellU+", V "+wellV);
	//write log and output file
		print("Saving: "+ mypath + myname +"_Well-U"+wellU+"-V"+wellV+".ome.tif");
		run("Bio-Formats Exporter", "save=" + mypath + myname +"_Well-U"+wellU+"-V"+wellV+".ome.tif");	
	// TO DO segment and count nb cell
}}