/////////////////////////////////////////////////////////
// Radial Focal Adhesion Localization Analysis
// AUTHOR: 	Paul Markus Müller
// CONTACT:	PaulMarkus.Mueller@fu-berlin.de
// DATE: 	12.03.2019
// VERSION: 1
// INPUT: 
//			- 3 channel image (3 Channel image, can be timelapse)
// 			- AVG_dark (dark image, with closed camera aperture, no illumination)
//			- AVG_C1 (Average background image w no cells, channel 1)
//			- AVG_C2 (Average background image w no cells, channel 2)
//			- AVG_C3 (Average background image w no cells, channel 3)
// NOTE: 	this is written for images from 3i (intelligent imaging innovation) slidebook .sld format
/////////////////////////////////////////////////////////


//====================================================================================//
//================== CLEANUP, CLOSE ALL WINDOWS, EMPTY LISTS =========================//
cleanup();

//====================================================================================//
//================== GUI GUI GUI GUI GUI GUI GUI GUI GUI GUI =========================//

/* GUI PARAMETER
 * parameter[0] = Number of image series to be analyzed
 * parameter[1] = Number of channels
 * parameter[2] = FA marker channel
 * parameter[3] = Cell outline channel
 * parameter[4] = Sigma for Gaussian blur filter (pixel unit) for calculation of high pass image
 * parameter[5] = Sigma for Gaussian blur filter (pixel unit) for noise correction of background images
 * parameter[6] = Enlarge FA ROI (pixel unit)
 * parameter[7] = Step size for discrete cell region diminishment (pixel unit) 
 * parameter[8] = Number of consecutive diminishment steps (pixel unit)
 * parameter[9] = Title of experiment .sld file
 * parameter[10] = GEF/GAP channel
 */


parameter=GUI();
	print("Title of experiment .sld file "+ parameter[9]);
	print("Number of image series to be analyzed: "+parameter[0]);
	print("Number of channels: "+parameter[1]);
	print("GEF/GAP channel: "+parameter[10]);
	print("FA marker channel: "+parameter[2]);
	print("Cell outline channel: "+parameter[3]);
	print("Sigma for Gaussian blur filter (pixel unit) for calculation of high pass image: "+parameter[4]);
	print("Sigma for Gaussian blur filter (pixel unit) for noise correction of background images: "+parameter[5]);
	print("Enlarge FA ROI (pixel unit): "+parameter[6]);
	print("Step size for discrete cell ROI diminishment (pixel unit) : "+parameter[7]);
	print("Number of consecutive ROI diminishment steps (pixel unit): "+parameter[8]);


//====================================================================================//
//========== OPEN IMAGES AND BACKGR IMAGES AND DARK NOISE IMAGE ======================//

directory = getDirectory("Choose an input directory");
output = getDirectory("Choose an output directory"); 

//GUI
run("Bio-Formats Importer", "open=["+directory+parameter[9]+"] autoscale color_mode=Grayscale rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"+parameter[0]+"");
title = getTitle();
run("Bio-Formats Importer", "open=["+directory+"AVG_C1.tif] autoscale color_mode=Grayscale rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
run("Bio-Formats Importer", "open=["+directory+"AVG_C2.tif] autoscale color_mode=Grayscale rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
run("Bio-Formats Importer", "open=["+directory+"AVG_C3.tif] autoscale color_mode=Grayscale rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
run("Bio-Formats Importer", "open=["+directory+"AVG_dark.tif] autoscale color_mode=Grayscale rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");


//====================================================================================//
//============= SPLIT CHANNELS =======================================================//
selectWindow(title);
run("Z Project...", "projection=[Average Intensity]");
selectWindow(title);
close();
selectWindow("AVG_"+title);
newTitle = getTitle();
run("Split Channels");


//====================================================================================//
//============= BACKGROUND CORRECTION and DUPLICATION ================================//
//selectWindow("AVG_dark.tif");
//run("Measure");
	// Results Window
	// Line 0 dark noise
//AVGDark = getResult("Mean", 0)

//-------- Subtraction of dark noise from background images and Gaussian blurring 
// GUI
for (i = 1; i <= parameter[1]; i++) {
	imageCalculator("Subtract create 32-bit", "AVG_C"+i+".tif","AVG_dark.tif");
	selectWindow("AVG_C"+i+".tif");
	close();
	wait(100);
	selectWindow("Result of AVG_C"+i+".tif");
	rename("AVG_C"+i+".tif");
	//run("Add...", "value="+AVGDark);
// GUI
	run("Gaussian Blur...", "sigma="+parameter[5]+"");
	resetMinAndMax();
}

//-------- Subtraction of dark noise from object images
// GUI
for (i = 1; i <= parameter[1]; i++) {
	imageCalculator("Subtract", "C"+i+"-"+newTitle+"","AVG_dark.tif");
	selectWindow("C"+i+"-"+newTitle+"");
	run("32-bit");
	//run("Add...", "value="+AVGDark);
	resetMinAndMax();
}

//-------- Normalization to field illumination
// GUI
for (i = 1; i <= parameter[1]; i++) {
	imageCalculator("Divide create 32-bit", "C"+i+"-"+newTitle+"","AVG_C"+i+".tif");
	selectWindow("C"+i+"-"+newTitle+"");
	close();
}

//-------- Subtraction of background region
// GUI
for (i = 1; i <= parameter[1]; i++) {
	selectWindow("Result of C"+i+"-"+newTitle);
	makeOval(358, 39, 112, 112);
	run("Enhance Contrast", "saturated=0.35");
	run("Tile");
}
setTool("rectangle");
waitForUser("Background Subtraction", "Drag the circular ROI to a small area away from the \ncell where there is no background debris \nmake sure to check all channels \n \nthen press 'OK' to continue");
roiManager("Add");

for (i = 1; i <= parameter[1]; i++) {
	selectWindow("Result of C"+i+"-"+newTitle);
	resetMinAndMax();
	roiManager("select", 0);
	run("Measure");
	MeanBackgr = getResult("Mean", i-1);
	run("Select None");
	run("Subtract...", "value="+MeanBackgr);
	resetMinAndMax();
}
//waitForUser("test");
wait(100);
roiManager("reset");
run("Clear Results");

//-------- Duplicate
for (i = 1; i <= parameter[1]; i++) {
	selectWindow("Result of C"+i+"-"+newTitle);
	run("Select None");
	run("Duplicate...", "title=C"+i+"");
}


//====================================================================================//
//=========== CREATE WHOLE CELL ROI AND CONSECUTIVE DIMINISHMENT ROIs ================//

// GUI
selectWindow("Result of C"+parameter[3]+"-"+newTitle);
	//run("In [+]");
resetMinAndMax();
setAutoThreshold("Otsu dark");
wait(100);
//IsoData threshold also works
run("Create Selection");
setTool("brush");
waitForUser("Cell Outline Definition", "Refine cell outline if necessary by \nusing the selection brush tool \n \nthen press 'OK' to continue");
selectWindow("Result of C"+parameter[3]+"-"+newTitle);
roiManager("Add");
roiManager("Select", 0);
roiManager("Rename", "WholeCell");

//-------- CONSECUTIVE DIMINISHMENT ROIs
// GUI
for (i = 0; i < parameter[8]; i++) {
	if (i == 0) {
    	roiManager("select", 0);
    	//print("ROI 0");
   } else {
   		selROI = i + i - 1;
   		//print("ROI "+selROI);
    	roiManager("select", selROI);
   } 
	run("Enlarge...", "enlarge=-"+parameter[7]+" pixel");
	roiManager("Add");
	roiManager("Select", roiManager("count")-1);
	if (i == parameter[8]-1) {
	  roiManager("Rename", "Center");
	} else {
	  roiManager("Rename", "WholeCell-"+i);		
	}
	
	if (i == 0) {
    	array=newArray(0, 1);
   } else {
   		selROI2 = selROI + 2;
		array=newArray(selROI, selROI2);
   } 
	roiManager("Select", array);
	roiManager("XOR");
	roiManager("Add");
	roiManager("Select", roiManager("count")-1);
	roiManager("Rename", "FARegion-"+i);
	//waitForUser("blabla");
}


//====================================================================================//
//=========== HIGH PASS FILTER FA MARKER =============================================//
// GUI
selectWindow("Result of C"+parameter[2]+"-"+newTitle);
run("Duplicate...", " ");
// GUI
selectWindow("Result of C"+parameter[2]+"-"+newTitle+"-1");
// GUI
run("Gaussian Blur...", "sigma="+parameter[4]+"");
// GUI  // GUI
imageCalculator("Subtract create", "Result of C"+parameter[2]+"-"+newTitle,"Result of C"+parameter[2]+"-"+newTitle+"-1");
// GUI
selectWindow("Result of C"+parameter[2]+"-"+newTitle+"-1");
close();
// GUI
selectWindow("Result of Result of C"+parameter[2]+"-"+newTitle);
	run("In [+]");
	run("In [+]");	
resetMinAndMax();
setAutoThreshold("Otsu dark");
waitForUser("refine FA region if necessary");
selectWindow("Result of Result of C"+parameter[2]+"-"+newTitle);
run("Create Selection");
// GUI
run("Enlarge...", "enlarge="+parameter[6]+" pixel");
roiManager("Add");
roiManager("Select", roiManager("count")-1);
roiManager("Rename", "FAROI");

roiManager("Select", newArray(0, roiManager("count")-1));
roiManager("AND");
roiManager("Add");
roiManager("Select", roiManager("count")-1);
roiManager("Rename", "FAFinal");


//================================================================================================//
//================ set outside FA to NaN, normalize FA region to 1, apply LUT ====================//

//for (i = 1; i <= parameter[1]; i++) {
//	selectWindow("Result of C"+i+"-"+newTitle);
//	run("Select None");
//	run("Duplicate...", "title=C"+i+"");
//}

// GUI
for (i = 1; i <= parameter[1]; i++) {
	selectWindow("Result of C"+i+"-"+newTitle);
	roiManager("Select", roiManager("count")-1);
	run("Make Inverse");
	run("Set...", "value=NaN");
	roiManager("Select", roiManager("count")-1);
	run("Measure");
	// Results Window 
	// Line 0 Channel 1
	// Line 1 Channel 2
	// Line 2 Channel 3
	Mean = getResult("Mean", i-1);
	//print(Mean);
	run("Divide...", "value="+Mean);
	run("BlueWhiteRed_spline");
	setMinAndMax(0.2, 1.8);
	run("Select None");
	run("In [+]");
	run("In [+]");
	run("In [+]");
}
wait(100);
run("Clear Results");

//====================================================================================//
//============================ MEAUSRE and SAVE ======================================//

waitForUser("Take your time", "Take your to inspect the images \nproceed measurement of intensities by pressing 'OK'")

//outputfolder = output+"series"+parameter[0]+File.separator;
//File.makeDirectory(outputfolder);

//----------Measure and Save Results

for (u = 1; u <= parameter[1]; u++) {
	selectWindow("Result of C"+u+"-"+newTitle);
	for (i = 0; i < parameter[8]; i++) {
		selectROI = roiManager("count")-1-parameter[8]*2+i*2;
		//print(selectROI);
		roiManager("Select", selectROI);
		wait(50);
		run("Measure");
	}
	roiManager("Select", roiManager("count")-4);
	wait(50);
	run("Measure");
}

for (u = 1; u <= parameter[1]; u++) {
	selectWindow("Result of C"+u+"-"+newTitle);
	//saveAs("Tiff", outputfolder+"C"+u+".tif");
	saveAs("Tiff", output+"series"+parameter[0]+"_C"+u+".tif");
	run("RGB Color");
	run("Line Width...", "line=1");
	roiManager("Select", 0);
	setForegroundColor(255, 255, 255);
	run("Draw");
	saveAs("Tiff", output+"series"+parameter[0]+"_C"+u+"_RGB.tif");
	//saveAs("Tiff", outputfolder+"C"+u+"_RGB.tif");
}

wait(50)

selectWindow("Results");
saveAs("Results", output+"series"+parameter[0]+"_Results.csv");
selectWindow("Log");
saveAs("Text", output+"series"+parameter[0]+"_Log.txt");
	

//////////////////////////////////////////////////////////////////////////////////////////
////// FUNCTIONS ////////// FUNCTIONS //////////// FUNCTIONS /////////// FUNCTIONS ///////
//////////////////////////////////////////////////////////////////////////////////////////

//___________________________________________________________
function cleanup(){
	run("Set Measurements...", "area mean standard min median display redirect=None decimal=9");
	run("Close All");
	run("Clear Results");
	run("ROI Manager...");
	roiManager("reset");
	print("\\Clear");//clears the log window
}
//___________________________________________________________ 
function GUI(){	
	Dialog.create("Parameters");
	Dialog.addString("Title of experiment .sld file ", "190322_MM_FN_spreadingREF52_dish1-6.sld");
	Dialog.addNumber("Number of image series to be analyzed ",78);
	Dialog.addNumber("Number of channels ",3);
	Dialog.addNumber("GEF/GAP channel ",1);
	Dialog.addNumber("FA marker channel ",2);
	Dialog.addNumber("Cell outline channel ",3);
	Dialog.addNumber("Sigma for Gaussian blur filter (pixel unit) for calculation of high pass image ",3);
	Dialog.addNumber("Sigma for Gaussian blur filter (pixel unit) for noise correction of background images ",10);
	Dialog.addNumber("Enlarge FA ROI (pixel unit) ",0);
	Dialog.addNumber("Step size for discrete cell ROI diminishment (pixel unit) ",3);
	Dialog.addNumber("Number of consecutive ROI diminishment steps (pixel unit) ",14);
	Dialog.show();

	ExpTitle=Dialog.getString();
	SeriesNumber=Dialog.getNumber();
	nChannel=Dialog.getNumber();
	GEFGAPChannel=Dialog.getNumber();
	FAChannel=Dialog.getNumber();
	OutlineChannel=Dialog.getNumber();
	GausBlrHighPass=Dialog.getNumber();
	GausBlrBackgr=Dialog.getNumber();
	EnlargeFA=Dialog.getNumber();
	StepSize=Dialog.getNumber();
	nSteps=Dialog.getNumber();
	
	param=newArray(SeriesNumber, nChannel, FAChannel, OutlineChannel, GausBlrHighPass, GausBlrBackgr, EnlargeFA, StepSize, nSteps, ExpTitle, GEFGAPChannel);
	
	return param;
}
