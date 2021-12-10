//Test macro to automate the identification of Minidicus comicus cells in overview images 
// acquired with the 10x objective on the Leica SP8 confocal microscope
//
// Marie Walde 02-2020

//run("Close All");

//Load raw data
open("P:/2020-01-20_RCC_Nathalie/Minidiscus infection/Minidiscus_infection_Overview_10x_100h-control_SNRadj_ch04.tif");
run("8-bit");
run("Enhance Contrast", "saturated=0.01");
run("Apply LUT");

open("P:/2020-01-20_RCC_Nathalie/Minidiscus infection/Minidiscus_infection_Overview_10x_100h-control_SNRadj_ch01.tif");
run("8-bit");
run("Enhance Contrast", "saturated=0.01");
run("Apply LUT");

// Merge them into one image
imageCalculator("Add create", "Minidiscus_infection_Overview_10x_100h-control_SNRadj_ch01.tif","Minidiscus_infection_Overview_10x_100h-control_SNRadj_ch04.tif");
selectWindow("Minidiscus_infection_Overview_10x_100h-control_SNRadj_ch01.tif");
close();
selectWindow("Minidiscus_infection_Overview_10x_100h-control_SNRadj_ch04.tif");
close();

if (0) {
	// crop the center part (for now)
	selectWindow("Result of Minidiscus_infection_Overview_10x_100h-control_SNRadj_ch01.tif");
	makeRectangle(2280, 2520, 3924, 3924);
	run("Crop");
}

selectWindow("Result of Minidiscus_infection_Overview_10x_100h-control_SNRadj_ch01.tif");
// backup duplicate
selectWindow("Result of Minidiscus_infection_Overview_10x_100h-control_SNRadj_ch01.tif");
run("Duplicate...", " ");

// pre-filtering and thresholding
run("Median...", "radius=7");
setAutoThreshold("Otsu dark");
run("Convert to Mask");
run("Dilate");
run("Fill Holes");
run("Watershed");

// Filter and analyze
// each detected object will be recorded again with the 63x oil objective
run("Analyze Particles...", "size=100-3000 pixel circularity=0.30-1.00 show=[Count Masks] display exclude clear include summarize add");