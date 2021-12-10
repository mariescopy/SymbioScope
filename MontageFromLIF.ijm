// Import Leica LIF files of overview scans and create a montage from it

run("Bio-Formats Macro Extensions");
//run("Close All");
print("**********************************");
// 1) Load the data
myfile = File.openDialog("Select .LIF file");
myname = File.getName(myfile);
mypath = File.getParent(myfile) + File.separator;
print("File: "+myname);
print("Path: "+mypath);
//mypath ="D:/users/Marie Walde/Astan/";
//myfile = "2020-08-07_NetSample_2020-06_eHCFM.lif";

Ext.setId(mypath + myname);
Ext.getSeriesCount(sercount);
print("Count: "+sercount);

// The last image of the LIF series is typically the auto-montage image
// The image name will also be printed in the Log window for verification
Ext.setSeries(sercount-1);
Ext.getSeriesName(sername)
print("Image name: "+sername);

//Ext.getSeries(seriesName)
run("Bio-Formats Importer", "open=[" + mypath + myname +"] autoscale color_mode=Composite split_channels view=Hyperstack stack_order=Default use_virtual_stack series_"+sercount);
getDimensions(width, height, channels, slices, frames);

// 2) Process each channel
// Channel 1: Chlorophyll autofluorence (C=0) 	magenta
// Channel 2: Transmission (C=1)				gray
// Channel 3: membranes, DiO(6)3 (C=2)			green
// Channel 4: DNA, Hoechst 33342 (C=3)			cyan
// Channel 5: Surfaces, PLL-A546 (C=4)			yellow

for (i = 0; i < 5; i++) {
	print("Processing channel: "+(i+1));
	print(sername+" - C="+i);
	selectWindow(myname+" - "+sername+" - C="+i);
	if (i==1) {
		run("Subtract Background...", "rolling=400 light sliding stack");
		run("Z Project...", "projection=[Min Intensity]");
		//run("Invert LUT");
	}
	else {run("Z Project...", "projection=[Max Intensity]");}
	
	rename("Channel_"+(i+1));
	run("Enhance Contrast", "saturated=0.1");
	selectWindow(myname+" - "+sername+" - C="+i);
	close();
	}
//Merge channels
run("Merge Channels...", "c2=Channel_3 c4=Channel_2 c5=Channel_4 c6=Channel_1 c7=Channel_5 create");
//write log and output file
run("Bio-Formats Exporter", "save=" + mypath + myname +"_Montage.ome.tif");	
// TO DO segment and count nb cells -> new macro


