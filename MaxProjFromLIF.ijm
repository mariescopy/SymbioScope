// Import individual Leica LIF files from Projects and create montages of them
//
// Marie Walde 2020-11, 
// Station Biologique de Roscoff/Sorbonne Université

run("Bio-Formats Macro Extensions");
print("+++++++++++++++++++++++++++++++++++++++++++");

// 1) Load the data
myfile = File.openDialog("Select .LIF file");
myname = File.getName(myfile);
mypath = File.getParent(myfile) + File.separator;
print("File: "+myname);
print("Path: "+mypath);

Ext.setId(mypath + myname);
Ext.getSeriesCount(sercount);
print("Count: "+sercount);

//written for 4 channels: "Transmission", "Chlorophyll", "RNA dye", "Hoechst
num_channels=4;

// open each series of the project
for (n = 1; n < sercount; n++) {
//for (n = 1; n < 2; n++) {	
	run("Close All");
	// The image name will also be printed in the Log window for verification
	Ext.setSeries(n-1);
	print("Image number: "+n);
	Ext.getSeriesName(sername)
	print("**********************************");
	print("Image name: "+sername);
		//Ext.getSeries(seriesName)
	
	run("Bio-Formats Importer", "open=[" + mypath + myname +"] autoscale color_mode=Composite split_channels view=Hyperstack stack_order=Default use_virtual_stack series_"+n);
	getDimensions(width, height, channels, slices, frames);
	print("Number of channels: "+num_channels);
	titles=getList("image.titles");
	run("Tile");
	
	//User input for channel content
	Dialog.create("Channel content ");
	Dialog.addNumber("Chlorophyll", 1);
	Dialog.addNumber("Transmission", 2);
	Dialog.addNumber("RNA dye", 3);
	Dialog.addNumber("Hoechst", 4);

	Dialog.show();
	ch_chl	   = Dialog.getNumber();
 	ch_trans   = Dialog.getNumber();
	ch_RNA	   = Dialog.getNumber();
	ch_Hoechst = Dialog.getNumber();
	
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
			
			rename("Channel_"+(i+1));
			run("Enhance Contrast", "saturated=0");
			run("Bio-Formats Exporter", "save=" + mypath + "Export"+File.separator+myname+"_"+sername+"_MaxProj_Ch"+(i+1)+".ome.tif");
			selectWindow(titles[i]);
			close();
		}
		
//Merge channels //ADJUST MANUALLY
		print("Merge Channels...", "c2=Channel_"+ch_RNA+" c3=Channel_"+ch_Hoechst+" c6=Channel_"+ch_chl);
		run("Merge Channels...", "c2=Channel_"+ch_RNA+" c3=Channel_"+ch_Hoechst+" c6=Channel_"+ch_chl+" create ignore"); //c2:green c3:blue c6:magenta
		//run("Merge Channels...", "c2=Channel_3 c3=Channel_4 c4=Channel_2 c6=Channel_1 c7=Channel_5 create");
		//write log and output file
		run("Bio-Formats Exporter", "save=" + mypath + "Export"+File.separator+myname+"_"+sername+"_MaxProj_Composite.ome.tif");
	}