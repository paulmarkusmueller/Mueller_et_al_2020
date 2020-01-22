////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
// FRET_RATIO_ANALYSIS for ratiometric FRET images
// AUTHOR: 		Paul Markus Müller
// CONTACT: 	PaulMarkus.Mueller@fu-berlin.de
// DATE:		23.06:2016
// VERSION:		2.0
// INPUT DATA:	
//				- FRET-DONOR CHANNEL Images (called CFP)
//				- FRET-ACCEPTOR CHANNEL Images (called FRET)
//				- ACCEPTOR CHANNEL Images (called YFP)
//				- COTRANSFECTION CHANNEL Images (called Cherry)
//				- BACKGROUND IMAGES FOR ALL CHANNELS
// NOTE:		images need to be numered consecutively 1NAME.tif, 2NAME.tif, ... nNAME.tif for each channel
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

//================== CLEANUP, CLOSE ALL WINDOWS, EMPTY LISTS =================//
cleanup();

//================== GUI TO DEFINE PARAMETERS =================//
/* parameter[0] = first image number to be analysed
 * parameter[1] = last image number to be analysed
 * parameter[2] = Gaussian Blur Filter: Sigma (Radius) - set to 0 to skip filtering
 * parameter[3] = Minimal size of particles to be excluded from the ROI in µm^2
 * parameter[4] = Lower threshold of acceptor channel for ROI creation
 * parameter[5] = Lower threshold of cotransfection channel for ROI creation
 * parameter[6] = Name of the CFP image
 * parameter[7] = Name of the FRET image
 * parameter[8] = Name of the YFP image
 * parameter[9] = Name of the Cherry image
 * parameter[10] = Upper threshold of acceptor channel for ROI creation
 */
 
parameter=GUI();
	print("First image number to be analysed: "+parameter[0]);
	print("Last image number to be analysed: "+parameter[1]);
	print("Gaussian Blur Filter: Sigma (Radius) - set to 0 to skip filtering: "+parameter[2]);
	print("Minimal size of particles to be excluded from the ROI in µm^2: "+parameter[3]);
	print("Lower threshold of acceptor channel for ROI creation: "+parameter[4]);
	print("Lower threshold of cotransfection channel for ROI creation: "+parameter[5]);
	print("Name of the CFP image: "+parameter[6])
	print("Name of the FRET image: "+parameter[7])
	print("Name of the YFP image: "+parameter[8])
	print("Name of the Cherry image: "+parameter[9])
	print("Upper threshold of YFP channel for ROI creation: "+parameter[10])



//================== SELECT DIRECTORIES AND OPEN BACKGROUND IMAGES =================//
waitForUser("Image Directory", "Select directory with images after hitting 'OK' ");
directory=getDirectory("Choose directory to load images");

waitForUser("Saving Directory", "Select directory to save results after hitting 'OK' ");
saveDirectory=getDirectory("Choose directory to save results");

//================== OPEN BACKGROUND IMAGES AND APPLY GAUSSIAN BLUR =================//
waitForUser("Background Image Directory", "Select directory with background images after hitting 'OK' (background images have to be in the format 'AVG_channelname_backgr.tif') ");
backgrDirectory=getDirectory("Choose directory with background images");
for (u=6;u<=9;u++){
	run("Bio-Formats Importer", "open=["+backgrDirectory+"AVG_"+parameter[u]+"_backgr.tif] autoscale color_mode=Grayscale view=Hyperstack stack_order=XYCZT");
	run("Gaussian Blur...", "sigma="+parameter[2]);
}

//This crates an empty Results table, otherwise the first measurements would get lost, somehow ...
run("Measure");
run("Clear Results");
IJ.renameResults("Results","RatioPixelValues");
run("Measure");
run("Clear Results");

//////////////////////////////////////////////////////////////////////////
setBatchMode(true);
//////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////
//================== FOR LOOP THROUGH ALL IMAGES =================//
////////////////////////////////////////////////////////////////////

for (i=parameter[0];i<=parameter[1];i++){
	//================== CLEAR ROI MANAGER =================//

	
	//================== OPEN IMAGES =================//
	run("Bio-Formats Importer", "open=["+directory+toString(i)+parameter[6]+".tif] autoscale color_mode=Grayscale view=Hyperstack stack_order=XYCZT");
	run("Bio-Formats Importer", "open=["+directory+toString(i)+parameter[7]+".tif] autoscale color_mode=Grayscale view=Hyperstack stack_order=XYCZT");
	run("Bio-Formats Importer", "open=["+directory+toString(i)+parameter[8]+".tif] autoscale color_mode=Grayscale view=Hyperstack stack_order=XYCZT");
	run("Bio-Formats Importer", "open=["+directory+toString(i)+parameter[9]+".tif] autoscale color_mode=Grayscale view=Hyperstack stack_order=XYCZT");
	
	//================== PRE-PROCESSING =================//
	for (u=6;u<=9;u++){
		selectWindow(""+toString(i)+parameter[u]+".tif");
		run("Gaussian Blur...", "sigma="+parameter[2]);
	}

	//================== ROIs TO EXCLUDE SATURATION =================//
	// 	in CFP, FRET and YFP image
	for (u=6;u<=8;u++){
		selectWindow(""+toString(i)+parameter[u]+".tif");
		setThreshold(0, 65534);
		run("Create Selection");
		run("ROI Manager...");
		roiManager("Add");
		roiManager("Select", u-6);
		roiManager("Rename", ""+parameter[u]+"1");
	}

	//================== SUBTRACT BACKGROUND IMAGES =================//
	for (u=6;u<=9;u++){
		selectWindow(""+toString(i)+parameter[u]+".tif");
		imageCalculator("Subtract",""+toString(i)+parameter[u]+".tif","AVG_"+parameter[u]+"_backgr.tif");
	}
	
	//================== ROI ACCEPTOR CHANNEL, EXCLUDING PARTICLES LARGER THAN 50000 µm^2 (DEFAULT VALUE) =================//
	selectWindow(""+toString(i)+parameter[8]+".tif");
	setAutoThreshold("Default dark");
	setThreshold(parameter[4], parameter[10]);
	
	run("Analyze Particles...", "size=0-"+parameter[3]+" show=Masks");
	// somehow this is returning a result in the results window in the first loop!!!!!!!!!!!!
	// this is why I delete this result again in the first loop...
	if (i<=parameter[0]) {
      run("Clear Results");
   }

	selectWindow("Mask of "+toString(i)+parameter[8]+".tif");
	setAutoThreshold("Default dark");
	setThreshold(254, 255);
	run("Create Selection");
	roiManager("Add");
	roiManager("Select", 3);
	roiManager("Rename", ""+parameter[8]+"2");
	

	//================== ROI FRET-DONOR CHANNEL, EXCLUDING 0 VALUES FROM THE ROI =================//
	selectWindow(""+toString(i)+parameter[6]+".tif");
	setThreshold(1, 65535);
	run("Create Selection");
	run("ROI Manager...");
	roiManager("Add");
	roiManager("Select", 4);
	roiManager("Rename", ""+parameter[6]+"2");
	
	//================== ROI FRET-ACCEPTOR CHANNEL, EXCLUDING 0 VALUES FROM THE ROI =================//
	selectWindow(""+toString(i)+parameter[7]+".tif");
	setThreshold(1, 65535);
	run("Create Selection");
	run("ROI Manager...");
	roiManager("Add");
	roiManager("Select", 5);
	roiManager("Rename", ""+parameter[7]+"2");

	//================== ROI COTRANSFECTION CHANNEL, EXCLUDING 0 VALUES FROM THE ROI =================//
	selectWindow(""+toString(i)+parameter[9]+".tif");
	setThreshold(parameter[5], 65534);
	run("Create Selection");
	run("ROI Manager...");
	roiManager("Add");
	roiManager("Select", 6);
	roiManager("Rename", ""+parameter[9]+"2");

	//================== COMBINE ROIS =================//
	roiManager("Deselect");
	roiManager("AND");
	roiManager("Add");
	roiManager("Select", 7);
	roiManager("Rename", "AND ROI");

	//================== FOR LOOP MEASURE MEASURE MEASURE =================//
	for (u=6;u<=9;u++){
		selectWindow(""+toString(i)+parameter[u]+".tif");
		roiManager("Select", 7);
		roiManager("Measure");
	}
	wait(50);
	IJ.renameResults("Results","Average")
	
	//IJ.renameResults("Average");
	
	//================== CREATE RATIO IMAGE =================//
	//selectWindow("RatioPixelValues");
	wait(50);
	IJ.renameResults("RatioPixelValues","Results");
	selectWindow(""+toString(i)+parameter[6]+".tif");
	run("32-bit");
	selectWindow(""+toString(i)+parameter[7]+".tif");
	run("32-bit");
	roiManager("Select", 7);
	run("Make Inverse");
	run("Set...", "value=NaN");
	imageCalculator("Divide create", ""+toString(i)+parameter[7]+".tif",""+toString(i)+parameter[6]+".tif");
	rename(""+toString(i)+"FRET-Ratio.tif");

	run("Measure");
	
	//selectWindow("Results");
	wait(50);
	IJ.renameResults("Results","RatioPixelValues");


	
	//================== SAVING =================//
	selectWindow(""+toString(i)+"FRET-Ratio.tif");
	saveAs("Tiff", saveDirectory+toString(i)+"FRET-Ratio.tif");
	roiManager("deselect");
	roiManager("save", saveDirectory+toString(i)+"RoiSet.zip");
	selectWindow("Average");
	saveAs("Results", saveDirectory+toString(i)+"AverageIntensities_Results.csv");
	selectWindow("RatioPixelValues");
	saveAs("Results", saveDirectory+toString(i)+"RatioPixelValues_Results.csv");
	
	//================== CLEANUP =================//
	wait(50);
	IJ.renameResults(toString(i)+"AverageIntensities_Results.csv","Results")
	wait(50);
	IJ.renameResults(toString(i)+"RatioPixelValues_Results.csv","RatioPixelValues")
	//selectWindow("Average");
	//IJ.renameResults("Results");
	//IJ.renameResults("Average","Results");
	roiManager("reset");


	//================== CLOSE IMAGES =================//
	for (u=6;u<=9;u++){
		selectWindow(""+toString(i)+parameter[u]+".tif");
		run("Close");
	}
	selectWindow(""+toString(i)+"FRET-Ratio.tif");
	run("Close");
	selectWindow("Mask of "+toString(i)+parameter[8]+".tif");
	run("Close");

	
}

//////////////////////////////////////////////////////////////////////////
setBatchMode(false);
//////////////////////////////////////////////////////////////////////////

//================== SAVE RESULTS AND LOG FILES =================//
selectWindow("Log");
saveAs("Text", saveDirectory+"Log.txt");
selectWindow("Results");
saveAs("Results", saveDirectory+"AverageIntensities_Results.csv");
selectWindow("RatioPixelValues");
saveAs("Results", saveDirectory+"RatioPixelValues_Results.csv");
run("Close");


//////////////////////////////////////////////////////////////////////////
//================== FUNCTIONS - FUNCTIONS - FUNCTIONS =================//
//////////////////////////////////////////////////////////////////////////

//___________________________________________________________
function cleanup(){
	run("Close All");
	run("Clear Results");
	run("ROI Manager...");
	roiManager("reset");
	print("\\Clear");//clears the log window
}
//___________________________________________________________
function GUI(){	
	Dialog.create("Parameters");
	Dialog.addNumber("First image number to be analysed ",1)
	Dialog.addNumber("Last image number to be analysed ",480)
	Dialog.addNumber("Gaussian Blur Filter: Sigma (Radius) - set to 0 to skip filtering ",0.5)
	Dialog.addNumber("Minimal size of particles to be excluded from the ROI in µm^2 ",50000)
	Dialog.addNumber("Lower threshold level of acceptor channel for ROI creation ",500)
	Dialog.addNumber("Lower threshold level of cotransfection channel for ROI creation ",100)	
	Dialog.addString("Name of the CFP image ", "CFP")
	Dialog.addString("Name of the FRET image ", "FRET")
	Dialog.addString("Name of the YFP image ", "YFP")
	Dialog.addString("Name of the Cherry image ", "Cherry")
	Dialog.addString("Upper threshold level of acceptor channel for ROI creation ",65534)
	Dialog.show();


	firstImage=Dialog.getNumber();
	lastImage=Dialog.getNumber();
	radGauss=Dialog.getNumber();
	excludeParticle=Dialog.getNumber();
	lowerThresholdAcceptor=Dialog.getNumber();
	lowerThresholdCotrans=Dialog.getNumber();
	nameCFP=Dialog.getString();
	nameFRET=Dialog.getString();
	nameYFP=Dialog.getString();
	nameCherry=Dialog.getString();
	upperThresholdAcceptor=Dialog.getString();
	param=newArray(firstImage, lastImage, radGauss, excludeParticle, lowerThresholdAcceptor, lowerThresholdCotrans, nameCFP, nameFRET, nameYFP, nameCherry, upperThresholdAcceptor);
	
	return param;
}