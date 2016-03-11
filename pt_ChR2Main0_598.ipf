#pragma rtGlobals=1		// Use modern global access method.
// Following include statement can be commented if the amplifiers are not Multiclamp 700A, or 700B	

#include ":More Extensions:Data Acquisition:AxonTelegraphMonitor"

//(Following may also work)
//#include <AxonTelegraphMonitor>

// Initial version is a copy of pt_EegMain27.ipf

// logic

// We want to electrically stimulate/ record from neurons as well as stimulate them with light. Typically, we''ll start a
// regular electrophys experiment and also initiate a waveform for scanning the beam to excite different
// regions of the brain slice. 

// Things to codelk,
// SetUp Boards
// An application to generate output waves
// Start the loop in which waves are output and input to channels corresponding to electrophys
// and just output to channels corresponding to optical stimulation
// Do some real time analysis on acquired waves and save the data

//Menu "SetUpProgram"
//"SetUp Program", pt_ChR2Main()
//End

Menu "pt_DataAcq"
Submenu "Hardware Control"
"EPhys", 		pt_EPhysMain()
"Temperature", 	pt_TemperatureMain()
"ScanMirror", 	pt_ScanMirrorMain()
"LaserShutter", 	pt_LaserShutterMain()
"LaserVoltage", 	pt_LaserVoltageMain()	// Laser Intensity Control
"LaserPower", 	pt_LaserPowerMain()		// Laser Power ReadIn
"Video", 			pt_VideoMain()			// Grab video using sensoray card
"TrigGen",		pt_TrigGenMain()    		// Generate Trig Signal for all hardware
End
Submenu "Utilities"
"WaveGenerator",			pt_WaveGen()			// For making waves
SubMenu "ScanMirror"
"Calibrate",  pt_ScanMirrorCalibrate()
End
 "Mark XY positions" ,		pt_MouseXYLocMain()	// For marking XY positions on image for laser scanning
 "Analyze Data", 			pt_AnalyzeData()			// For Analyzing data
 "Tile Windows", 			pt_TileWindows()
 "Kill Windows",  			pt_KillGraphsAndTables()	
 Submenu "EPhys NoteBook"
 "Open"		, 	pt_OpenEPhysNB() 
 "Kill"		, 	pt_KillEPhysNB()
 End
 Submenu "InVivo NoteBook"
 "Open"		, 	pt_OpenInVivoNB() 
 "Kill"		, 	pt_KillInVivoNB()
 End
 
End
End



Function pt_ScanMirrorMain() : Panel

Variable InstNumL							// Local Copy of ScanMirrorInstNum
String 	FldrNameL							// Local Copy of Folder Name
String 	PanelNameL							// Local Copy of Panel Name

InstNumL = pt_InstanceNum("root:ScanMirrorVars", "ScanMirrorMain")
FldrNameL="root:ScanMirrorVars"+Num2Str(InstNumL)
PanelNameL = "ScanMirrorMain"+Num2Str(InstNumL)

Variable /G root:ScanMirrorInstNum			
//String 	/G root:ScanMirrorFldrName			// Active folder Name
//String 	/G root:ScanMirrorPanelName


NVAR InstNum 		=	root:ScanMirrorInstNum
//SVAR FldrName 		=	root:ScanMirrorFldrName
//SVAR PanelName	=	root:ScanMirrorPanelName

InstNum		= InstNumL
//FldrName 	= FldrNameL				
//PanelName 	= PanelNameL
// Global copy of Folder Name and PanelName for use by other functions. NB. Global copy will change with every new instant creation
// To use variables associated with a particular instant, local values should be used	


NewDataFolder /O $FldrNameL

Variable /G	$FldrNameL+":CurrentXValue"
Variable /G	$FldrNameL+":CurrentYValue"
Variable /G	$FldrNameL+":NewXValue"		
Variable /G	$FldrNameL+":NewYValue"

// waves to be sent for multiple iterations to TrigGen. If less than number of iterations, the last wave is repeated
Make /O/T/N=0 $FldrNameL+":OutXWaveNamesW"
Make /O/T/N=0 $FldrNameL+":OutYWaveNamesW"	

Make /O/N=1 $FldrNameL+":ScanMirrorValTmp"		// for temporarily storing x,y value of the scan mirror out wave
Wave ScanMirrorValTmp = $FldrNameL+":ScanMirrorValTmp"	
ScanMirrorValTmp = Nan

// waves to save
// Enter both X and Y Wave names
// The wave will be made if there is an out wave. No need to make one in the begining
//Make /O/T/N=0 $FldrNameL+":OutWaveToSave"	// saved with the original name
// No InWaves to save



Variable /G	$FldrNameL+":ScanMirrorMaxVoltage" = 10  // No direct user access for this variable

Variable	/G 	$FldrNameL+":Initialize" =0

Variable /G $FldrNameL+":DebugMode" = 0
NVAR        DebugMode = $FldrNameL+":DebugMode"

If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "*************************************"
EndIf	

//Make /T/O/N=5 root:ScanMirrorControlVars:ScanMirrorHWName
//Make /T/O/N=5 root:ScanMirrorControlVars:ScanMirrorHWVal

// possible values (can add more parameters)
// Wave /T w = root:ScanMirrorControlVars:ScanMirrorHWName
//w[0] = "DevID"
//w[1] = "XChNum"
//w[2] = "YChNum"
//w[3] = "XDist2VoltageGain"	//  Definition: XDeltaV = DeltaX*XDist2VoltageGain. Units = Volt/distance. 
////w[4] = "Theta2VGain"		//  Definition: DeltaV   = DeltaTheta*Theta2VGain. Units = V/degree. 
//w[4] = "YDist2VoltageGain"	//  Definition: YDeltaV = DeltaY*YDist2VoltageGain. Units = Volt/distance.
//w[5] = "XOffset"				//  Definition: XDeltaV = (DeltaX-XOffset)*XDist2VoltageGain
//w[6] = "YOffset"				//  Definition: YDeltaV = (DeltaY-YOffset)*YDist2VoltageGain
 

	PauseUpdate; Silent 1		// building window...
	DoWindow $PanelNameL
	If (V_Flag==1)
		DoWindow /K $PanelNameL
	EndIf
	NewPanel /K=2/W=(900,310,1175,445)
	DoWindow /C $PanelNameL
	SetDrawLayer UserBack
//	SetDrawEnv fsize= 14,textrgb= (0,9472,39168)
//	DrawText 100,19,"ScanMirror"
	DrawText 21,110,"(um)"
	DrawText 150,110,"(um)"
//	SetVariable setvar2,pos={60,5},size={70,16},title="Inst#",value=InstNum, limits={1,inf,1}
	Button button0,pos={5,15},size={50,20},title="Initialize", proc = pt_ScanMirrorInitialize, userdata=Num2Str(InstNumL)
	PopupMenu ScanProtocolPopUp,pos={75,15},size={100,18},title="ScanProtocol"	
	PopupMenu ScanProtocolPopUp, mode = 1, value="HorizontalScan;VerticalScan;RandomScan", proc = pt_ScanProtocolPopSelect, userdata=Num2Str(InstNumL)
	ValDisplay valdisp0,pos={5,50},size={120,15},title="CurrentXValue"
	String CX=FldrNameL+":CurrentXValue"
	ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000},value= #CX	// ToDo 
	ValDisplay valdisp1,pos={5,80},size={120,15},title="CurrentYValue"
	String CY=FldrNameL+":CurrentYValue"
	ValDisplay valdisp1,limits={0,0,0},barmisc={0,1000},value=#CY
	SetVariable setvar0,pos={135,50},size={120,16},title="NewXValue",value= $FldrNameL+":NewXValue"
	SetVariable setvar1,pos={135,78},size={120,16},title="NewYValue",value=$FldrNameL+":NewYValue"
	Button button1,pos={210,110},size={50,20},title="Move", proc = pt_ScanMirrorMove, userdata=Num2Str(InstNumL)
	Button button3,pos={110,110},size={50,20},title="Reset", disable =2
	Button button3,proc = pt_ScanMirrorResetMove, userdata=Num2Str(InstNumL)
	Button button2,pos={5,110},size={55,20},title="Hardware", proc = pt_ScanMirrorHWEdit, userdata=Num2Str(InstNumL)
//	PopupMenu popup0,pos={5,115},size={50,20},title="Hardware", proc = pt_ScanMirrorHWEdit
End

Function pt_ScanMirrorHWEdit(ButtonVarName) :  ButtonControl
String ButtonVarName

NVAR ScanMirrorInstNum			=root:ScanMirrorInstNum
//If (!StringMatch(button0, "TrigGen"))
	ScanMirrorInstNum			= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:ScanMirrorVars"+Num2Str(ScanMirrorInstNum)
//String ScanMirrorPanelName 	= "ScanMirrorMain"+Num2Str(ScanMirrorInstNum)

If (WaveExists($(FldrName+":ScanMirrorHWName")) && WaveExists($(FldrName+":ScanMirrorHWVal"))    )
Wave /T ScanMirrorHWName =  	$(FldrName+":ScanMirrorHWName")
Wave /T ScanMirrorHWVal 	= 	$(FldrName+":ScanMirrorHWVal")
Edit /K=1 ScanMirrorHWName, ScanMirrorHWVal
Else
Make /T/O/N=9 $(FldrName+":ScanMirrorHWName")
Make /T/O/N=9 $(FldrName+":ScanMirrorHWVal")
Wave /T ScanMirrorHWName =  	$(FldrName+":ScanMirrorHWName")
Wave /T ScanMirrorHWVal 	= 	$(FldrName+":ScanMirrorHWVal")

ScanMirrorHWName[0] = "DevID"
ScanMirrorHWName[1] = "XChNum"
ScanMirrorHWName[2] = "YChNum"
ScanMirrorHWName[3] = "XDist2VoltageGain (Volt/Distance)"//  Definition: XDeltaV = DeltaX*XDist2VoltageGain. Units = Volt/distance. 
//ScanMirrorHWName[4] = "Theta2VGain (V/degree)"		//  Definition: DeltaV = DeltaTheta*Theta2VGain. Units = V/degree. 
ScanMirrorHWName[4] = "YDist2VoltageGain (Volt/Distance)"//  Definition: YDeltaV = DeltaY*YDist2VoltageGain. Units = Volt/distance. 
ScanMirrorHWName[5] = "XOffset"					//  Definition: XDeltaV = (DeltaX-XOffset)*XDist2VoltageGain
ScanMirrorHWName[6] = "YOffset"					//  Definition: YDeltaV = (DeltaY-YOffset)*YDist2VoltageGain
ScanMirrorHWName[7] = "XOffset_ErrxDivDy (ErrX/DelY)"	//  Definition: 
ScanMirrorHWName[8] = "YOffset_ErryDivDx (ErrY/DelX)"	//  Definition: 

ScanMirrorHWVal[3]= "1"		// Default offset =1
ScanMirrorHWVal[4]= "1"		// Default offset =1

ScanMirrorHWVal[5]= "0"		// Default offset =0
ScanMirrorHWVal[6]= "0"		// Default offset =0
ScanMirrorHWVal[7]= "0"		// Default offset =0
ScanMirrorHWVal[8]= "0"		// Default offset =0	

Edit /K=1 ScanMirrorHWName, ScanMirrorHWVal
EndIf

End

Function pt_ScanMirrorInitialize(ButtonVarName) : ButtonControl
String ButtonVarName

NVAR ScanMirrorInstNum			=root:ScanMirrorInstNum
If (StringMatch(ButtonVarName, "Button0"))
	ScanMirrorInstNum			= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
EndIf
String FldrName 				= "root:ScanMirrorVars"+Num2Str(ScanMirrorInstNum)
String WName=""
//String ScanMirrorPanelName 	= "ScanMirrorMain"+Num2Str(ScanMirrorInstNum)

// It can happen that the signal voltage is not 0, 0 V while the mirrors are at 0, 0 micron or vice versa.
// Initialize will set the current voltage to 0 V. Also copy the OutWaveNames to OutWaveNamesCopy
NVAR	x1	= $(FldrName+":CurrentXValue")
NVAR	y1	= $(FldrName+":CurrentYValue")
NVAR	x2	= $(FldrName+":NewXValue")		
NVAR	y2	= $(FldrName+":NewYValue")

NVAR	Initialize	=  $(FldrName+":Initialize")


If (StringMatch(ButtonVarName, "TrigGen"))
Wave /T 		OutXWaveNamesW = 	$FldrName+":OutXWaveNamesW"
Duplicate /O 	OutXWaveNamesW, 		$FldrName+":OutXWaveNamesWCopy"
Wave /T 		OutYWaveNamesW = 	$FldrName+":OutYWaveNamesW"
Duplicate /O OutYWaveNamesW, 		$FldrName+":OutYWaveNamesWCopy"

sscanf FldrName, "root:%s", WName

	
Wave w = $(FldrName+":"+WName+"XVal")
DeletePoints 0,NumPnts(w), w
Wave w = $(FldrName+":"+WName+"YVal")
DeletePoints 0,NumPnts(w), w
Else
//x1 =0
//y1	=0
// Initialize should take the mirror back to XOffset, YOffset (and the applied voltage should be 0,0) position rather then at 0,0
//x2 =0
//y2	=0
Wave /T ScanMirrorHWName = $(FldrName+":ScanMirrorHWName")
Wave /T ScanMirrorHWVal =    $(FldrName+":ScanMirrorHWVal")
x2				=Str2Num(ScanMirrorHWVal[5]) //XOffset
y2				=Str2Num(ScanMirrorHWVal[6]) //YOffset

Initialize = 1

pt_ScanMirrorMove("")
EndIf
End

Function pt_ScanMirrorMove(ButtonVarName)
String ButtonVarName	// will be called using the button or from TrigGen (to run simultaneously with other channels)

NVAR ScanMirrorInstNum			=root:ScanMirrorInstNum
If (StringMatch(ButtonVarName, "Button1"))
	ScanMirrorInstNum			= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
EndIf
String FldrName 				= "root:ScanMirrorVars"+Num2Str(ScanMirrorInstNum)
String ScanMirrorPanelName 	= "ScanMirrorMain"+Num2Str(ScanMirrorInstNum)

Variable DevID 				= Nan
Variable XChNum 			= Nan
Variable YChNum 			= Nan
Variable XDist2VoltageGain	= Nan		//  Definition: XDeltaV = DeltaX*XDist2VoltageGain. Units = Volt/distance. 
Variable YDist2VoltageGain	= Nan		//  Definition: YDeltaV = DeltaY*YDist2VoltageGain. Units = Volt/distance. 
Variable XOffset				= Nan		//  Definition: XDeltaV = (DeltaX-XOffset)*XDist2VoltageGain
Variable YOffset				= Nan		//  Definition: YDeltaV = (DeltaY-YOffset)*YDist2VoltageGain
Variable XOffset_ErrxDivDy	= Nan
Variable YOffset_ErryDivDx	= Nan

//Variable Theta2VGain 		= Nan		//  Definition: DeltaV = DeltaTheta*Theta2VGain. Units = V/degree. 

NVAR	x1		= $(FldrName+":CurrentXValue")
NVAR	y1		= $(FldrName+":CurrentYValue")
NVAR	x2		= $(FldrName+":NewXValue")		
NVAR	y2		= $(FldrName+":NewYValue")		
NVAR    VMax 	= $(FldrName+":ScanMirrorMaxVoltage")
NVAR	Initialize	= $(FldrName+":Initialize")

String DevIdStr, OutWaveStr, WName, WNoteStr = ""
Variable ThetaX, ThetaY, VX, VY, i, XOffSetTot, YOffSetTot 
Variable VMaxX, VMaxY
//Variable ThetaX, VX, i 


Wave /T ScanMirrorHWName = $(FldrName+":ScanMirrorHWName")
Wave /T ScanMirrorHWVal =    $(FldrName+":ScanMirrorHWVal")

DevID 	 			= Str2Num(ScanMirrorHWVal[0])
XChNum  			= Str2Num(ScanMirrorHWVal[1])
YChNum 			= Str2Num(ScanMirrorHWVal[2])
XDist2VoltageGain	= Str2Num(ScanMirrorHWVal[3])	//  Definition: XDeltaV = DeltaX*XDist2VoltageGain. Units = Volt/distance. 
YDist2VoltageGain	= Str2Num(ScanMirrorHWVal[4])	//  Definition: YDeltaV = DeltaY*YDist2VoltageGain. Units = Volt/distance. 
XOffset				=Str2Num(ScanMirrorHWVal[5]) //  Definition: XDeltaV = (DeltaX-XOffset)*XDist2VoltageGain
YOffset				=Str2Num(ScanMirrorHWVal[6]) //  Definition: YDeltaV = (DeltaY-YOffset)*YDist2VoltageGain
XOffset_ErrxDivDy	=Str2Num(ScanMirrorHWVal[7])
YOffset_ErryDivDx	=Str2Num(ScanMirrorHWVal[8]) 



DevIdStr = "Dev"+Num2Str(DevID)

// Note
// new position is always calculated from 0,0. 

Button button3, disable=0, win=$ScanMirrorPanelName // Enable Reset Move Button
Button button1, disable=2, win=$ScanMirrorPanelName // disable Move Button
Button button0, disable=2, win=$ScanMirrorPanelName // disable Initialize Button	


Print "*************************************************************"

If (StringMatch(ButtonVarName, "TrigGen"))
// copy output wave to root. copy DeviceName, Wavename, ChannelName to IODevNum, IOWName and IOChNum in root:TrigGenVars

// fresh copy of OutWaveNamesW is generated when TrigGen Starts. On each call the topmost wave corresponding to topmost wave name
// is copied to root folder. and if the number of points in OutWaveNamesWCopy>1, then the top most wavename is deleted, so that in the next
// call the wave corresponding to next wavename is copied to root folder.
Wave /T OutXWaveNamesWCopy=$FldrName+":OutXWaveNamesWCopy"	
Wave /T OutYWaveNamesWCopy=$FldrName+":OutYWaveNamesWCopy"
Wave /T IODevFldrCopy 	= root:TrigGenVars:IODevFldrCopy
For (i=0; i<NumPnts(IODevFldrCopy); i+=1)
	If (StringMatch(IODevFldrCopy[i], FldrName))
	
	Wave OutWX = $(FldrName+":"+OutXWaveNamesWCopy[0])
	Wave OutWY = $(FldrName+":"+OutYWaveNamesWCopy[0])
	
	Duplicate /O OutWX, $(FldrName+":OutWXScld")
	Wave OutWXScld = $(FldrName+":OutWXScld")
	XOffSetTot= XOffSet+XOffset_ErrxDivDy*(OutWY-YOffset)// Could add higher order terms
	OutWXScld = (OutWXScld-XOffsetTot)*XDist2VoltageGain	// convert position to voltage
	Duplicate /O OutWXScld, $(FldrName+":OutWXScldAbs")
	Wave OutWXScldAbs = $(FldrName+":OutWXScldAbs")
	OutWXScldAbs = abs(OutWXScld)
	WaveStats /Q OutWXScldAbs
	VMaxX=V_Max
	
	Wave OutWY = $(FldrName+":"+OutYWaveNamesWCopy[0])
	Duplicate /O OutWY, $(FldrName+":OutWYScld")
	Wave OutWYScld = $(FldrName+":OutWYScld")
	YOffSetTot= YOffSet+YOffset_ErryDivDx*(OutWX-XOffset)// Could add higher order terms
	OutWYScld = (OutWYScld-YOffsetTot)*YDist2VoltageGain	// convert position to voltage
	Duplicate /O OutWYScld, $(FldrName+":OutWYScldAbs")
	Wave OutWYScldAbs = $(FldrName+":OutWYScldAbs")
	OutWYScldAbs = abs(OutWYScld)
	WaveStats /Q OutWYScldAbs
	VMaxY=V_Max

	// VMaxX and VMaxY are max values of abs(w). so no need to check if min value is greater than VMin
	If ( (VMaxX<=VMax)  &&  (VMaxY<=VMax))			
	
//	Wave ScanMirrorVWave =  $(FldrName+":ScanMirrorVWave")
//	ScanMirrorVWave = NaN
	
// 	Save the details of output wave to disk. ToDo	
//	Randomize output waves if desired. ToDo
	sscanf FldrName+"XScldOut", "root:%s", WName
	Duplicate /O OutWXScld, $(FldrName+":"+WName)
	sscanf FldrName+"YScldOut", "root:%s", WName
	Duplicate /O OutWYScld, $(FldrName+":"+WName)
	
	sscanf FldrName+"XOut", "root:%s", WName
	Duplicate /O OutWX, $(FldrName+":"+WName)		// for pt_ScanMirrorDisplay()
	sscanf FldrName+"YOut", "root:%s", WName
	Duplicate /O OutWY, $(FldrName+":"+WName)		// for pt_ScanMirrorDisplay()
	
	Wave ScanMirrorValTmp = $(FldrName+":ScanMirrorValTmp")
	
	sscanf FldrName, "root:%s", WName
	
	WNoteStr= Note(OutWX)
	ScanMirrorValTmp[0]	      = Str2Num(StringByKey("Stim Amp.",WNoteStr))
	Concatenate /NP {ScanMirrorValTmp}, $(FldrName+":"+WName+"XVal")
	
	WNoteStr= Note(OutWY)
	ScanMirrorValTmp[0]	      = Str2Num(StringByKey("Stim Amp.",WNoteStr))
	Concatenate /NP {ScanMirrorValTmp}, $(FldrName+":"+WName+"YVal")
	
	Make /T/O/N=2 $FldrName+":OutWaveToSave"		// Overwrite previous wave
	Wave /T OutWaveToSave = $FldrName+":OutWaveToSave"
	OutWaveToSave[0] = OutXWaveNamesWCopy[0]		// for pt_ScanMirrorSave()
	OutWaveToSave[1] = OutYWaveNamesWCopy[0]	// for pt_ScanMirrorSave()

	
	Wave /T IODevNum 	= root:TrigGenVars:IODevNum
	Wave /T IOChNum 	= root:TrigGenVars:IOChNum
	Wave /T IOWName 	= root:TrigGenVars:IOWName
	Wave /T IOEOSH 	= root:TrigGenVars:IOEOSH
	
	IODevNum[i]	= ScanMirrorHWVal[0]
	IOChNum[i]	= ScanMirrorHWVal[1]
	sscanf FldrName+"XScldOut", "root:%s", WName
	IOWName[i]	= FldrName+":"+WName				//OutWaveNamesWCopy[0]
	IOEOSH[i]	= "pt_ScanMirrorEOSH()"
	
	
// For the YScan mirror add an extra entry
	InsertPoints /M=0 (NumPnts(IODevFldrCopy)+1),1, IODevFldrCopy , IODevNum, IOChNum, IOWName, IOEOSH
	i = NumPnts(IODevFldrCopy)-1
	
	IODevFldrCopy[i] = FldrName
	IODevNum[i]	= ScanMirrorHWVal[0]	
	IOChNum[i]	= ScanMirrorHWVal[2]
	sscanf FldrName+"YScldOut", "root:%s", WName
	IOWName[i]	= FldrName+":"+WName					//OutWaveNamesWCopy[0]
	IOEOSH[i]	= "pt_ScanMirrorEOSH()"		// pt_ScanMirrorEOSH() will actually be called just once by TrigGenEOSH(), but two entries are 
											// needed to update both x,y values in panel
//	IOEOSH[i]	= ""						
	
	If ( (NumPnts(OutXWaveNamesWCopy)>1) && (NumPnts(OutYWaveNamesWCopy)>1) )
		DeletePoints 0,1,OutXWaveNamesWCopy
		DeletePoints 0,1,OutYWaveNamesWCopy
	Else
		Print "Warning! Sending the same wave in the next iteration as this iteration, as no more waves are left in OutXWaveNamesWCopy or OutYWaveNamesWCopy"
	EndIf
	


	Else		// Voltage out of range
		Print "ScanMirror voltage out of range for", OutXWaveNamesWCopy[0],"or",OutYWaveNamesWCopy[0], "for", FldrName,"!!","Absolute(VMax)=", VMax
		Button button1, disable=0, win=$ScanMirrorPanelName // Enable Move Button
		Button button0, disable=0, win=$ScanMirrorPanelName // Enable Initialize Button
		Button button3, disable=2, win=$ScanMirrorPanelName // Disable Reset Move Button
		
		
		Abort "Aborting..."
	EndIf
	
	Break	
	EndIf
EndFor
Else

//ThetaX = (X2)	*	Dist2ThetaGain		
//ThetaY = (Y2)*	Dist2ThetaGain

Print "Moving mirrors from", X1,",", Y1, "to", X2, ",",Y2
//Print "Moving mirrors from", X1, "to", X2, "microns. In degrees:", ThetaX

XOffSetTot= XOffSet+XOffset_ErrxDivDy*(Y2-YOffset)// Could add higher order terms
Print "X2=", X2
Print "XOffset=", XOffset
Print "XOffset_ErrxDivDy*(OutWY-YOffset)=", XOffset_ErrxDivDy*(Y2-YOffset)
Print "Corrected X = X2 - XOffset - XOffset_ErrxDivDy*(Y2-YOffset)=", X2-XOffsetTot

YOffSetTot= YOffSet+YOffset_ErryDivDx*(X2-XOffset)// Could add higher order terms
Print "Y2=", Y2
Print "YOffset=", YOffset
Print "YOffset_ErryDivDx*(OutWX-XOffset)=", YOffset_ErryDivDx*(X2-XOffset)
Print "Corrected Y = Y2 - YOffset - YOffset_ErryDivDx*(X2-XOffset)=", Y2-YOffsetTot

VX  = (X2-XOffsetTot)   * XDist2VoltageGain
VY = (Y2-YOffsetTot)  * YDist2VoltageGain

Print "Applying volatge to mirror =", VX,VY, "Volts"

If ( abs(VX) > VMax || abs(VY) > VMax )		// Also check if the resulting position exceeds max deflection. ToDo
//If ( abs(VX) > VMax)		// Also check if the resulting position exceeds max deflection. ToDo
X2=X1
Y2=Y1
Print "Warning!! Voltage to be applied to scan mirror exceeds ScanMirrorMaxVoltage.Mirrors not moved."
pt_ScanMirrorEOSH()

Else

OutWaveStr = ""

Make /T/O/N=2 $FldrName+":OutWaveToSave"		// Overwrite previous wave
Wave /T OutWaveToSave = $FldrName+":OutWaveToSave"

sscanf FldrName+"XOut", "root:%s", WName
Make /O/N=2 $(FldrName+":"+WName)				// for pt_ScanMirrorDisplay()
Wave OutWX = $(FldrName+":"+WName)	
OutWX = X2
Duplicate /O OutWX, 	$(FldrName+":OutWXScld")
Wave 	OutWXScld = $(FldrName+":OutWXScld")
OutWXScld = VX
OutWaveStr += FldrName+":OutWXScld"+","+Num2Str(XChNum)+";"
OutWaveToSave[0] = "XOut"					     // for pt_ScanMirrorSave()

sscanf FldrName+"YOut", "root:%s", WName
Make /O/N=2 $(FldrName+":"+WName)				// for pt_ScanMirrorDisplay()
Wave OutWY= $(FldrName+":"+WName)	
OutWY = Y2
Duplicate /O OutWY, 	$(FldrName+":OutWYScld")
Wave 	OutWYScld = $(FldrName+":OutWYScld")
OutWYScld = VY
OutWaveStr += FldrName+":OutWYScld"+","+Num2Str(YChNum)+";"
OutWaveToSave[1] = "YOut"

//sscanf FldrName+"XOut", "root:%s", WName
//Make /O/N=2 $(FldrName+":"+"TmpOutWX")				// for pt_ScanMirrorDisplay()
//Wave OutWXScld = $(FldrName+":"+"TmpOutWX")	
//OutWXScld = VX
//OutWaveStr += FldrName+":TmpOutWX"+","+Num2Str(XChNum)+";"
//OutWaveToSave[0] = "TmpOutWX"						// for pt_ScanMirrorSave()


//sscanf FldrName+"YOut", "root:%s", WName
//Make /O/N=2 $(FldrName+":"+"TmpOutWY")				// for pt_ScanMirrorDisplay()
//Wave OutWYScld = $(FldrName+":"+"TmpOutWY")	
//OutWYScld = VY
//OutWaveStr += FldrName+":TmpOutWY"+","+Num2Str(XChNum)+";"
//OutWaveToSave[1] = "TmpOutWY"						// for pt_ScanMirrorSave()

	
//Make /O/N=2 VXWave = VX
//Make /O/N=2 VYWave = VY



//If (VX !=0)		

//EndIf

//If (VY !=0)	

//EndIf

If (Initialize ==1)		
Print "Initializing..."
EndIf


//If (StrLen(OutWaveStr) !=0)

Print "Sending to mirrors", OutWaveStr, "on device", DevIdStr
//pt_ScanMirrorEOSHook()
Print "*************************************************************"
// Assign the right trigger
//DAQmx_WaveformGen /DEV= DevIdStr /NPRD=1/TRIG={TrigSrc,1} /ERRH="pt_ErrorHook()" OutWaveStr
DAQmx_WaveformGen /DEV= DevIdStr /NPRD=1/EOSH="pt_ScanMirrorEOSH()" OutWaveStr
String ScanMirrorErr = fDAQmx_ErrorString()
If (!StringMatch(ScanMirrorErr,""))
	Print ScanMirrorErr
	pt_ScanMirrorERRH()
EndIf

//Else

//Print "Scan Mirrors: Final position same as Initial position!! Mirrors not moved."
//Print "*************************************************************"


EndIf
EndIf

End


Function pt_ScanMirrorResetMove(ButtonVarName)
String ButtonVarName	// will be called using the button or from TrigGen (to run simultaneously with other channels)

NVAR ScanMirrorInstNum			=root:ScanMirrorInstNum
If (StringMatch(ButtonVarName, "Button1"))
	ScanMirrorInstNum			= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
EndIf
String FldrName 				= "root:ScanMirrorVars"+Num2Str(ScanMirrorInstNum)
String ScanMirrorPanelName 	= "ScanMirrorMain"+Num2Str(ScanMirrorInstNum)


Button button1, disable=0, win=$ScanMirrorPanelName // Enable Move Button
Button button0, disable=0, win=$ScanMirrorPanelName // Enable Initialize Button
Button button3, disable=2, win=$ScanMirrorPanelName // Disable Reset Move Button

End






Function pt_ScanMirrorERRH()
NVAR ScanMirrorInstNum			=root:ScanMirrorInstNum
//If (!StringMatch(button0, "TrigGen"))
//	ScanMirrorInstNum			= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:ScanMirrorVars"+Num2Str(ScanMirrorInstNum)
//String ScanMirrorPanelName 	= "ScanMirrorMain"+Num2Str(ScanMirrorInstNum)

NVAR ScanMirrorError 	= $FldrName+":ScanMirrorError"
	ScanMirrorError = 1
	Print "*****************************************"
	Print "DataAcquisition Error in", FldrName
	Print "*****************************************"
	pt_ScanMirrorEOSH()
End


Function pt_ScanMirrorEOSH()

NVAR ScanMirrorInstNum			=root:ScanMirrorInstNum
//If (!StringMatch(button0, "TrigGen"))
//	ScanMirrorInstNum			= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:ScanMirrorVars"+Num2Str(ScanMirrorInstNum)
String ScanMirrorPanelName 	= "ScanMirrorMain"+Num2Str(ScanMirrorInstNum)

NVAR	x1	= $(FldrName+":CurrentXValue")
NVAR	y1	= $(FldrName+":CurrentYValue")
NVAR	x2	= $(FldrName+":NewXValue")		
NVAR	y2	= $(FldrName+":NewYValue")	

NVAR	Initialize	= $(FldrName+":Initialize")


Button button1, disable=0, win=$ScanMirrorPanelName // Enable Move Button
Button button0, disable=0, win=$ScanMirrorPanelName // Enable Initialize Button
Button button3, disable=2, win=$ScanMirrorPanelName // Disable Reset Move Button

If (Initialize ==1)
Initialize =0
EndIf


// Update current location

x1 = x2   
y1 = y2

pt_ScanMirrorAnalyze()
pt_ScanMirrorDisplay()
pt_ScanMirrorSave()

End

Function pt_ScanMirrorAnalyze()
NVAR ScanMirrorInstNum			=root:ScanMirrorInstNum
//If (!StringMatch(button0, "TrigGen"))
//	ScanMirrorInstNum			= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:ScanMirrorVars"+Num2Str(ScanMirrorInstNum)
//String ScanMirrorPanelName 	= "ScanMirrorMain"+Num2Str(ScanMirrorInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

End

Function pt_ScanMirrorDisplay()
// display data: Check if the window ScanMirrorDisplayWin exists? 
// if yes, append. If no, create and append
NVAR ScanMirrorInstNum			=root:ScanMirrorInstNum
//If (!StringMatch(button0, "TrigGen"))
//	ScanMirrorInstNum			= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:ScanMirrorVars"+Num2Str(ScanMirrorInstNum)
//String ScanMirrorPanelName 	= "ScanMirrorMain"+Num2Str(ScanMirrorInstNum)

String WXName, WYName

//Wave  ScanMirrorInWave 		=  $(FldrName+":"+FldrName+"In")


sscanf FldrName+"XOut", "root:%s", WXName
Wave ScanMirrorXOutWave = $(FldrName+":"+WXName)

sscanf FldrName+"YOut", "root:%s", WYName
Wave ScanMirrorYOutWave = $(FldrName+":"+WYName)

DoWindow ScanMirrorDisplayWin
If (V_Flag)
// Check if the trace is not on graph
//	Print TraceNameList("ScanMirrorDisplayWin", ";", 1)
	
	If (FindListItem(WYName, TraceNameList("ScanMirrorDisplayWin", ";", 1), ";")==-1)
	AppendToGraph /L /W =ScanMirrorDisplayWin ScanMirrorYOutWave vs ScanMirrorXOutWave
	EndIf
	
//	If (FindListItem(WYName, TraceNameList("ScanMirrorDisplayWin", ";", 1), ";")==-1)
//	AppendToGraph /L /W =ScanMirrorDisplayWin ScanMirrorYOutWave		
//	EndIf

Else
	Display 
	DoWindow /C ScanMirrorDisplayWin
	AppendToGraph /L /W =ScanMirrorDisplayWin ScanMirrorYOutWave vs ScanMirrorXOutWave
//	AppendToGraph /L /W =ScanMirrorDisplayWin ScanMirrorYOutWave	
EndIf
End


Function pt_ScanMirrorSave()
// Save data to disk
Variable N,i
String OldDf, Str, InWaveToSaveAsFull, WName
NVAR ScanMirrorInstNum			=root:ScanMirrorInstNum
//If (!StringMatch(button0, "TrigGen"))
//	ScanMirrorInstNum			= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:ScanMirrorVars"+Num2Str(ScanMirrorInstNum)
//String ScanMirrorPanelName 	= "ScanMirrorMain"+Num2Str(ScanMirrorInstNum)

If (WaveExists($FldrName+":OutWaveToSave"))
OldDF = GetDataFolder(1)
SetDataFolder $FldrName

Wave /T OutWaveToSave = $FldrName+":OutWaveToSave"

//Wave /T InWaveToSave = $(FldrName+":"+FldrName+"In")
PathInfo home
If (V_Flag==0)
	Abort "Please save the experiment first!"
EndIf
NewPath /O DiskDFName,  S_Path
Print "Saving ScanMirror data to",S_Path
//SaveData /Q/D=1/O/L=1  /P=DiskDFName /J =SaveWaveList InWaveToSaveAs+"_"+ Num2Str(IterNum)//T=$EncFName /P=SaveDF
//N=NumPnts(OutWaveToSave)
sscanf FldrName, "root:%s", WName
Str = WName+OutWaveToSave[0]
If (!StringMatch("XOut", OutWaveToSave[0])  )
	Duplicate /O $(FldrName+":"+WName+"XOut"), $(Str)
EndIf
Save /C/O/P=DiskDFName  $(Str)//$OutWaveToSave[i]

Str = WName+OutWaveToSave[1]
If (!StringMatch("YOut", OutWaveToSave[1])  )
	Duplicate /O $(FldrName+":"+WName+"YOut"), $(Str)
EndIf
Save /C/O/P=DiskDFName  $(Str)//$OutWaveToSave[i]
KillWaves OutWaveToSave
KillPath /Z DiskDFName
SetDataFolder OldDf
Else
	Print "No ScanMirror data to save!"
EndIf
End

Function pt_ScanMirrorGridScan(ButtonVarName)  :  ButtonControl
String ButtonVarName
// horizontal scan: for a given row, scan all colums. then go to the next row
// vertical scan: for a given column, scan all rows. then go to the next column

// first make sure that the number of waves for rows = number of waves for columns
// allowing for a rectangular scan. number of rows may not be equal to number of columns April 1st, 2010 Praveen

NVAR ScanMirrorInstNum			=root:ScanMirrorInstNum
//If (!StringMatch(button0, "TrigGen"))
//	ScanMirrorInstNum			= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:ScanMirrorVars"+Num2Str(ScanMirrorInstNum)
//String ScanMirrorPanelName 	= "ScanMirrorMain"+Num2Str(ScanMirrorInstNum)



Wave /T OutXWaveNamesW	= $(FldrName+":OutXWaveNamesW")
Wave /T OutYWaveNamesW	= $(FldrName+":OutYWaveNamesW")

SVAR    OutXWaveMatchStr	= $(FldrName+":OutXWaveMatchStr")
SVAR    OutYWaveMatchStr	= $(FldrName+":OutYWaveMatchStr")

SVAR    ScanProtocol		= $(FldrName+":ScanProtocol")

String OldDf = GetDataFolder(1)
SetDataFolder $FldrName

String OutXWaveList = WaveList(OutXWaveMatchStr, ";", "")
String OutYWaveList = WaveList(OutYWaveMatchStr, ";", "")
Variable NX,NY, i, j

//If (    ItemsInList(OutXWaveList)!=ItemsInList(OutYWaveList)    )
//Abort
//Else
NX = ItemsInList(OutXWaveList)
NY = ItemsInList(OutYWaveList)

//EndIf


	StrSwitch (ScanProtocol)
	
	Case "HorizontalScan" :
	Redimension /N=(NX*NY) OutXWaveNamesW, OutYWaveNamesW
	OutXWaveNamesW = ""
	OutYWaveNamesW = ""
	For (i=0; i<NY; i+=1)
		OutYWaveNamesW[i*NX, NX*(i+1) - 1]=StringFromList(i, OutYWaveList, ";")
		For (j=0; j<NX; j+=1)
		OutXWaveNamesW[j+i*NX]=StringFromList(j, OutXWaveList, ";")
		EndFor
	EndFor
	Print "Generated OutWaveNamesW for horizontal scan (rows vs colums) =", NX, "x",NY
	Break
	
	Case "VerticalScan" :
	Redimension /N=(NX*NY) OutXWaveNamesW, OutYWaveNamesW
	OutXWaveNamesW = ""
	OutYWaveNamesW = ""
	For (i=0; i<NX; i+=1)
		OutXWaveNamesW[i*NY, NY*(i+1) - 1]=StringFromList(i, OutXWaveList, ";")
		For (j=0; j<NY; j+=1)
		OutYWaveNamesW[j+i*NY]=StringFromList(j, OutYWaveList, ";")
		EndFor
	EndFor
	Print "Generated OutWaveNamesW for vertical scan (rows vs colums) =", NX, "x",NY
	Break
	
	Case "RandomScan" :
	// Still to code
	// with and without repetition
	Break
	
	EndSwitch
	
 
SetDataFolder OldDf
End

Function pt_ScanProtocolPopSelect(PopupMenuVarName, PopupMenuVarNum, PopupMenuVarStr)  : PopupMenuControl
String PopupMenuVarName, PopupMenuVarStr
Variable PopupMenuVarNum

NVAR ScanMirrorInstNum			=root:ScanMirrorInstNum
//If (!StringMatch(button0, "TrigGen"))
	ScanMirrorInstNum			= Str2Num(getuserdata("",PopupMenuVarName,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:ScanMirrorVars"+Num2Str(ScanMirrorInstNum)
//String ScanMirrorPanelName 	= "ScanMirrorMain"+Num2Str(ScanMirrorInstNum)

String /G    $(FldrName+":OutXWaveMatchStr") = ""
String /G    $(FldrName+":OutYWaveMatchStr") = ""
String /G    $(FldrName+":ScanProtocol") = ""

SVAR ScanProtocol = $(FldrName+":ScanProtocol")


	DoWindow ScanProtocolPanel
	If (V_Flag==1)
		DoWindow /F ScanProtocolPanel
	Else
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1/W=(525,75,750,180)
	DoWindow /C ScanProtocolPanel
	EndIf
	SetVariable setvar0,pos={1,15},size={210,18}, title ="XWaveMatchStr"
	SetVariable setvar0,value=  $(FldrName+":OutXWaveMatchStr")
	SetVariable setvar1,pos={1,45},size={210,18}, title ="YWaveMatchStr"
	SetVariable setvar1,value= $(FldrName+":OutYWaveMatchStr")
	ScanProtocol = PopupMenuVarStr
	Button button0,pos={81,75},size={85,20},title="GenerateGrid", proc = pt_ScanMirrorGridScan
	
// Button to call pt_ScanMirrorGridScan()
	
End

Function pt_ScanMirrorCalibrate()

NVAR ScanMirrorInstNum			=root:ScanMirrorInstNum
//If (!StringMatch(button0, "TrigGen"))
//	ScanMirrorInstNum			= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:ScanMirrorVars"+Num2Str(ScanMirrorInstNum)
//String ScanMirrorPanelName 	= "ScanMirrorMain"+Num2Str(ScanMirrorInstNum)

Variable /G	$FldrName+":XOffset"
Variable /G	$FldrName+":YOffset"
Variable /G	$FldrName+":Vx"
Variable /G	$FldrName+":XVx"
Variable /G	$FldrName+":YVx"
Variable /G	$FldrName+":Vy"
Variable /G	$FldrName+":XVy"
Variable /G	$FldrName+":YVy"

Variable /G	$FldrName+":ApplyToHW"

//Variable /G XOffset,YOffset, Vx, XVx, YVx, Vy, XVy, YVy


//Prompt XOffset, "Enter X(Vx=0)"
//Prompt YOffset, "Enter Y(Vy=0)"
//Prompt Vx, "Enter Vx"
//Prompt XVx, "Enter X(Vx)"
//Prompt YVx, "Enter Y(Vx)"
//Prompt Vy, "Enter Vy"
//Prompt XVy, "Enter X(Vy)"
//Prompt YVy, "Enter Y(Vy)"
//DoPrompt "Enter the following values (Measured with gains =1 and Offsets =0)", XOffset,YOffset, Vx, Vy, XVx, YVy, XVy, YVx

DoWindow ScanMirrorCalibratePanel
	If (V_Flag==1)
		DoWindow /F ScanMirrorCalibratePanel
	Else
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1/W=(525,75,800,240)
	DoWindow /C ScanMirrorCalibratePanel
	EndIf
	SetVariable setvar0,pos={1,15},size={120,18}, limits={-inf,inf,0}, title ="X(Vx=0, Vy=0)"
	SetVariable setvar0,value=  $FldrName+":XOffset"
	SetVariable setvar1,pos={1,45},size={120,18}, limits={-inf,inf,0}, title ="Vx"
	SetVariable setvar1,value= $FldrName+":Vx"
	SetVariable setvar2,pos={1,75},size={120,18}, limits={-inf,inf,0}, title ="X(Vx, 0)"
	SetVariable setvar2,value=  $FldrName+":XVx"
	SetVariable setvar3,pos={1,105},size={120,18}, limits={-inf,inf,0}, title ="X(0, Vy)"
	SetVariable setvar3,value=  $FldrName+":XVy"
	
	SetVariable setvar4,pos={150,15},size={120,18}, limits={-inf,inf,0}, title ="Y(Vx=0, Vy=0)"
	SetVariable setvar4,value=  $FldrName+":YOffset"
	SetVariable setvar5,pos={150,45},size={120,18}, limits={-inf,inf,0}, title ="Vy"
	SetVariable setvar5,value= $FldrName+":Vy"
	SetVariable setvar6,pos={150,75},size={120,18}, limits={-inf,inf,0}, title ="Y(Vx, 0)"
	SetVariable setvar6,value=  $FldrName+":YVx"
	SetVariable setvar7,pos={150,105},size={120,18}, limits={-inf,inf,0}, title ="Y(0, Vy)"
	SetVariable setvar7,value=  $FldrName+":YVy"
	
	
	Button button0,pos={1,135},size={70,20},title="Calculate", proc = pt_ScanMirrorCalibrateCal
	CheckBox CheckBox0,pos={150,135},size={54,14},title="Apply to hardware",value= 0
	CheckBox CheckBox0,variable= $FldrName+":ApplyToHW"//, userdata=Num2Str(InstNum)

End

Function pt_ScanMirrorCalibrateCal(ButtonVarName) :  ButtonControl
String ButtonVarName

NVAR ScanMirrorInstNum			=root:ScanMirrorInstNum
//If (!StringMatch(button0, "TrigGen"))
//	ScanMirrorInstNum			= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:ScanMirrorVars"+Num2Str(ScanMirrorInstNum)
//String ScanMirrorPanelName 	= "ScanMirrorMain"+Num2Str(ScanMirrorInstNum)

NVAR	XOffset 	= $FldrName+":XOffset"
NVAR	YOffset 	= $FldrName+":YOffset"
NVAR	Vx 		= $FldrName+":Vx"
NVAR	XVx 	= $FldrName+":XVx"
NVAR	YVx 	= $FldrName+":YVx"
NVAR	Vy 		= $FldrName+":Vy"
NVAR	XVy 	= $FldrName+":XVy"
NVAR	YVy 	= $FldrName+":YVy"

NVAR	ApplyToHW = $FldrName+":ApplyToHW"

Wave /T ScanMirrorHWVal =    $(FldrName+":ScanMirrorHWVal")

// Check if Gains =1 and Offset =0
If (  Str2Num(ScanMirrorHWVal[3]) !=1 || Str2Num(ScanMirrorHWVal[4]) !=1  || Str2Num(ScanMirrorHWVal[5]) !=0 || Str2Num(ScanMirrorHWVal[6]) !=0 || Str2Num(ScanMirrorHWVal[7]) !=0 || Str2Num(ScanMirrorHWVal[8]) !=0)
DoAlert 1, "Existing gains not equal to 1 or offsets not equal to 0. Continue?"
If (V_Flag!=1)
Abort "Aborting..."
EndIf
EndIf
DoWindow /H //Bring command window to top of Desktop
Print "                                         "
Print "Values entered:"
Print "X(Vx=0, Vy=0)	=",XOffset, "		Y(Vx=0, Vy=0)	=",YOffset
Print "Vx				=",Vx, "		Vy				=",Vy
Print  "X(Vx, 0)		=",XVx, "		Y(Vx, 0)			=",YVx
Print "X(0, Vy)		=",XVy, "		Y(0, Vy)			=",YVy
Print "**********************************************************************************"
Print "XDist2VoltageGain (Volt/Distance) =",Vx/(XVx-XOffset)
Print "YDist2VoltageGain (Volt/Distance) =",Vy/(YVy-YOffset)
Print "XOffset =", XOffset
Print "YOffset =", YOffset
Print "XOffset_ErrxDivDy (ErrX/DelY) =",(XVy-XOffset)/(YVy-YOffset)
Print "YOffset_ErryDivDx (ErrY/DelX) =", (YVx-YOffset)/(XVx-XOffset)

If (ApplyToHW)
	Print "                                         "
	Print "Applying values to hardware."
	ScanMirrorHWVal[3]	= Num2Str(Vx/(XVx-XOffset))			//XDist2VoltageGain
	ScanMirrorHWVal[4]	= Num2Str(Vy/(YVy-YOffset)) 			//YDist2VoltageGain
	ScanMirrorHWVal[5]	= Num2Str(XOffset) 					//XOffset
	ScanMirrorHWVal[6]	= Num2Str(YOffset) 					//YOffset
	ScanMirrorHWVal[7]	= Num2Str((XVy-XOffset)/(YVy-YOffset)) //XOffset_ErrxDivDy
	ScanMirrorHWVal[8]	= Num2Str((YVx-YOffset)/(XVx-XOffset)) //YOffset_ErryDivDx
	
EndIf
Print "**********************************************************************************"
End

Function pt_LaserShutterMain() : Panel

Variable InstNumL							// Local Copy of LaserShutterInstNum
String 	FldrNameL							// Local Copy of Folder Name
String 	PanelNameL							// Local Copy of Panel Name

InstNumL = pt_InstanceNum("root:LaserShutterVars", "LaserShutterMain")
FldrNameL="root:LaserShutterVars"+Num2Str(InstNumL)
PanelNameL = "LaserShutterMain"+Num2Str(InstNumL)

Variable /G root:LaserShutterInstNum			
//String 	/G root:LaserShutterFldrName			// Active folder Name
//String 	/G root:LaserShutterPanelName


NVAR InstNum 		=	root:LaserShutterInstNum
//SVAR FldrName 		=	root:LaserShutterFldrName
//SVAR PanelName	=	root:LaserShutterPanelName

InstNum		= InstNumL
//FldrName 	= FldrNameL				
//PanelName 	= PanelNameL
// Global copy of Folder Name and PanelName for use by other functions. NB. Global copy will change with every new instant creation
// To use variables associated with a particular instant, local values should be used	

NewDataFolder /O $FldrNameL

Variable /G	$FldrNameL+":CurrentShutterState" 	// Open / Close

// Checking that the wave is made exclusively of 0's and 1's
//Variable /G	$FldrNameL+":LaserShutterMax" = 1  // (Bit value = 1 or 0) No direct user access for this variable

Variable	/G 	$FldrNameL+":Initialize" =0	


// Outwaves to be sent for multiple iterations to TrigGen. If less than number of iterations, the last wave is repeated
Make /O/T/N=0 $FldrNameL+":OutWaveNamesW"	

// waves to save
// The wave will be made if there is an out wave. No need to make one in the begining
//Make /O/T/N=0 $FldrNameL+":OutWaveToSave"	// saved with the original name
// No InWaves to save

Variable /G $FldrNameL+":DebugMode" = 0
NVAR        DebugMode = $FldrNameL+":DebugMode"

If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "*************************************"
EndIf




//Make /T/O/N=3 root:LaserShutterVars:LaserShutterHWName
//Make /T/O/N=3 root:LaserShutterVars:LaserShutterHWVal

// possible values (can add more parameters)
// Wave /T w = root:LaserShutterVars:LaserShutterHWName
//w[0] = "DevID"
//w[1] = "PortID"
//w[2] = "LineID"

	PauseUpdate; Silent 1		// building window...
	DoWindow $PanelNameL
	If (V_Flag==1)
		DoWindow /K $PanelNameL
	EndIf
	NewPanel /K=2/W=(900,490,1175,550)
	DoWindow /C $PanelNameL
//	ShowTools/A
	SetDrawLayer UserBack
//	SetDrawEnv fsize= 14,textrgb= (0,9472,39168)
//	DrawText 100,19,"Shutter"
//	SetVariable setvar0,pos={60,5},size={70,16}, title="Inst#",value=InstNum, limits={1,inf,1}
	Button button0,pos={210,30},size={55,20},title="Toggle", proc = pt_LaserShutterToggle, userdata=Num2Str(InstNumL)
	Button button3,pos={110,30},size={55,20},title="Reset", disable = 2 
	Button button3, proc = pt_LaserShutterResetToggle, userdata=Num2Str(InstNumL)
	
	Button button1,pos={5,30},size={55,20},title="Hardware", proc = pt_LaserShutterHWEdit, userdata=Num2Str(InstNumL)
	Button button2,pos={5,5},size={55,20},title="Initialize", proc = pt_LaserShutterInitialize, userdata=Num2Str(InstNumL)
	ValDisplay valdisp0,pos={110,10},size={60,15},title="Shutter"
	String CSS = FldrNameL+":CurrentShutterState"
	ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000},value= #CSS
EndMacro


End


Function pt_LaserShutterHWEdit(ButtonVarName) :  ButtonControl
String ButtonVarName

NVAR LaserShutterInstNum		=root:LaserShutterInstNum
//If (!StringMatch(button0, "TrigGen"))
	LaserShutterInstNum			= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
//EndIf
String FldrName 					= "root:LaserShutterVars"+Num2Str(LaserShutterInstNum)
//String LaserShutterPanelName 	= "LaserShutterMain"+Num2Str(LaserShutterInstNum)

If (WaveExists($(FldrName+":LaserShutterHWName")) && WaveExists($(FldrName+":LaserShutterHWVal"))    )
Wave /T LaserShutterHWName =  	$(FldrName+":LaserShutterHWName")
Wave /T LaserShutterHWVal 	= 	$(FldrName+":LaserShutterHWVal")
Edit /K=1 LaserShutterHWName, LaserShutterHWVal
Else
Make /T/O/N=3 $(FldrName+":LaserShutterHWName")
Make /T/O/N=3 $(FldrName+":LaserShutterHWVal")
Wave /T LaserShutterHWName =  	$(FldrName+":LaserShutterHWName")
Wave /T LaserShutterHWVal 	= 	$(FldrName+":LaserShutterHWVal")

LaserShutterHWName[0] = "DevID"
LaserShutterHWName[1] = "PortID"
LaserShutterHWName[2] = "LineID"

Edit /K=1 LaserShutterHWName, LaserShutterHWVal
EndIf

End


Function pt_LaserShutterToggle(ButtonVarName) : ButtonControl
String ButtonVarName

NVAR LaserShutterInstNum		=root:LaserShutterInstNum
If (StringMatch(ButtonVarName, "Button0"))
	LaserShutterInstNum			= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
EndIf
String FldrName 					= "root:LaserShutterVars"+Num2Str(LaserShutterInstNum)
String LaserShutterPanelName 		= "LaserShutterMain"+Num2Str(LaserShutterInstNum)

NVAR	CurrentShutterState	= $(FldrName+":CurrentShutterState")
NVAR	Initialize				= $(FldrName+":Initialize")
//NVAR    VMax 				= $(FldrName+":LaserShutterMax")

Variable DevID = Nan
Variable PortID = Nan
Variable LineID = Nan

String DevIdStr, PortIDStr, LineIDStr, DigChStr, WName
Variable i, OutVal, NumPntsOutW, j, InvalidW

Wave /T LaserShutterHWName = $(FldrName+":LaserShutterHWName")
Wave /T LaserShutterHWVal =    $(FldrName+":LaserShutterHWVal")



DevID 	 		= Str2Num(LaserShutterHWVal[0])
PortID			= Str2Num(LaserShutterHWVal[1])
LineID 			= Str2Num(LaserShutterHWVal[2])


DevIdStr = 	"Dev"+Num2Str(DevID)
PortIdStr = 	"Port"+Num2Str(PortID)
LineIdStr = 	"Line"+Num2Str(LineID)

DigChStr = "/"+DevIdStr+"/"+PortIDStr+"/"+LineIDStr//+";"  // semicolon here  causes parsing error in DAQmx_DIO_Config!!

Button button3, disable=0, win=$LaserShutterPanelName // Enable Reset Toggle Button
Button button0, disable=2, win=$LaserShutterPanelName // disable Toggle   Button
Button button2, disable=2, win=$LaserShutterPanelName // disable Initialize Button


If (StringMatch(ButtonVarName, "TrigGen"))
// copy output wave to root. copy DeviceName, Wavename, ChannelName to IODevNum, IOWName and IOChNum in root:TrigGenVars

// fresh copy of OutWaveNamesW is generated when TrigGen Starts. On each call the topmost wave corresponding to topmost wave name
// is copied to root folder. and if the number of points in OutWaveNamesWCopy>1, then the top most wavename is deleted, so that in the next
// call the wave corresponding to next wavename is copied to root folder.

Wave /T OutWaveNamesWCopy=$FldrName+":OutWaveNamesWCopy"
Wave /T IODevFldrCopy 	= root:TrigGenVars:IODevFldrCopy

For (i=0; i<NumPnts(IODevFldrCopy); i+=1)
	If (StringMatch(IODevFldrCopy[i], FldrName))
	
	Wave OutW = $(FldrName+":"+OutWaveNamesWCopy[0])
//	Wavestats /Q OutW
	NumPntsOutW=NumPnts(OutW)
	InvalidW =0
	For (j=0; j<NumPntsOutW; j+=1)
		If (!(OutW[j] ==0 || OutW[j] ==1))
//		Print j, OutW[j]
		InvalidW =1
		Break
		EndIf
	EndFor
//	If ( (V_Max <=VMax) && (V_Min >=0) )		// Ideally one should check that the wave is made of only 1 and 0. ToDo
	If ( InvalidW ==0)	
//	Duplicate /O OutW, OutWScld
	// Scale appropriately for VClmp or IClmp
//	OutWScld = (LaserShutter_VClmp==1) ? OutWScld/LaserShutterOutGain_VClmp : OutWScld/LaserShutterOutGain_IClmp
	Duplicate /O OutW, $(FldrName+"DigOut")
	sscanf FldrName+"Out", "root:%s", WName
	Duplicate /O OutW, $(FldrName+":"+WName)		// for pt_LaserShutterDisplay()
	
	Make /T/O/N=1 $FldrName+":OutWaveToSave"		// Overwrite previous wave
	Wave /T OutWaveToSave = $FldrName+":OutWaveToSave"
	OutWaveToSave[0] = OutWaveNamesWCopy[0]		// for pt_LaserShutterSave()

	Wave /T IODevNum 	= root:TrigGenVars:IODevNum
	Wave /T IOChNum 	= root:TrigGenVars:IOChNum
	Wave /T IOWName 	= root:TrigGenVars:IOWName
	Wave /T IOEOSH 	= root:TrigGenVars:IOEOSH
	
//	Print "IODevNum, IOChNum, IOWName, IOEOSH",  IODevNum, IOChNum, IOWName, IOEOSH
	IODevNum[i]	= LaserShutterHWVal[0]
//	IOChNum[i]	= LaserShutterHWVal[2]
	IOChNum[i]	= DigChStr
	sscanf FldrName+"DigOut", "root:%s", WName
	IOWName[i]	= WName					//OutWaveNamesWCopy[0]
	IOEOSH[i]	= "pt_LaserShutterEOSH()"
//	Print "IODevNum, IOChNum, IOWName, IOEOSH",  IODevNum, IOChNum, IOWName, IOEOSH
	If (NumPnts(OutWaveNamesWCopy)>1)
		DeletePoints 0,1,OutWaveNamesWCopy
	Else
		Print "Warning! Sending the same wave in the next iteration as this iteration, as no more waves are left in OutWaveNamesWCopy"
	EndIf
	
	Else		// Voltage out of range
		Print "Shutter voltage out of range in wave", OutWaveNamesWCopy[0], "for", FldrName,"values should be = to 0 or 1 only."
		Print "The wave should be made of only 0's and 1's (close and open respectively)"
		Button button0, disable=0, win=$LaserShutterPanelName // Enable Toggle Button
		Button button2, disable=0, win=$LaserShutterPanelName // Enable Initialize Button
		Button button3, disable=2, win=$LaserShutterPanelName // Disable Reset Toggle Button
		Abort "Aborting..."
	EndIf
	
	Break
	EndIf
EndFor	
Else


If (Initialize ==0)

Print "*************************************************************"
Print "Toggling laser shutter. (0=Close, 1=Open). Currently", CurrentShutterState
OutVal  = 1-CurrentShutterState//2^(1-CurrentShutterState)
Else
Print "*************************************************************"
Print "Initializing laser shutter..."
OutVal  = 0//1
EndIf


Print "Sending to shutter", OutVal, "on device", DigChStr
//pt_LaserShutterEOSH()
Print "*************************************************************"
// Assign the right trigger

Make /T/O/N=1 $FldrName+":OutWaveToSave"		// Overwrite previous wave
Wave /T OutWaveToSave = $FldrName+":OutWaveToSave"

sscanf FldrName+"Out", "root:%s", WName
Make /O/N=2 $(FldrName+":"+WName)				// for pt_LaserShutterDisplay()
Wave OutW = $(FldrName+":"+WName)		
OutW = OutVal
OutWaveToSave[0] = "Out"

//SetScale /P x, 0,1,OutW



//******************************************************************************************
// only port 0 can be used for buffered wave operations for digital channels. buffered wave operations
// need hardware clock that can be one of the /ai/sampleclock, /ao/sampleclock 
//etc
//How to specify the digital lines? Following is from nidaqtool help on DAQmx_DIO_Config

//When you use /LGRP=0, all lines of a DIO port are represented by a single integer. Thus, if you specify, 
//for instance, "/dev1/port0/line1,/dev1/port0/line3" and both lines are high, when you read the data with
//fDAQmx_DIO_Read the result will be 10 (21 + 23). Because you specified only the two lines, the other
//lines in the port will always be zero in the result, but the bits used to represent the lines are those that
//would be used if all lines in the port were read. On the other hand, if you use /LGRP=1, only the specified
//lines are included in the returned data, in the order in which you listed them. Thus, the example would
//return 3 (20 + 21, with bit 0 representing line 1 and bit 1 representing line 3).
//These considerations of line grouping apply to output (fDAQmx_DIO_Write) as well as input.
//******************************************************************************************




DAQmx_DIO_Config /DEV= DevIdStr /LGRP = 1/DIR=1/ERRH="pt_LaserShutterERRH()"/EOSH="pt_LaserShutterEOSH()" DigChStr
//DAQmx_DIO_Config /DEV= DevIdStr /LGRP = 1/DIR=1/ERRH="pt_LaserShutterERRH()"/EOSH="pt_LaserShutterEOSH()" /CLK={"/Dev1/ai/sampleclock",0}/Wave={$(FldrName+":"+WName)}  DigChStr
//print "DAQmx_DIO_Config error", fDAQmx_ErrorString()
fDAQmx_DIO_Write(DevIdStr, V_DAQmx_DIO_TaskNumber, OutVal)
// without fDAQmx_DIO_Finished the line is not released and successive call to DAQmx_DIO_Config gives an error
// Requested operation could not be performed, because the specified digital lines are either reserved or the device is not present in NI-DAQmx
fDAQmx_DIO_Finished(DevIdStr, V_DAQmx_DIO_TaskNumber)
//print "fDAQmx_DIO_Write error", fDAQmx_ErrorString()

 pt_LaserShutterEOSH() //not getting executed for some reason therefore putting the pt_LaserShutterEOSH() here temporariliy ToDo
String LaserShutterErr = fDAQmx_ErrorString()
If (!StringMatch(LaserShutterErr,""))
	Print LaserShutterErr
	pt_LaserShutterERRH()
EndIf
//If (Initialize ==0)
//CurrentShutterState = 1-CurrentShutterState	// toggle state
//Print "Togged laser shutter. (0=Close, 1=Open). Currently", CurrentShutterState

//Else
//CurrentShutterState = 0
//Print "Initialized laser shutter. (0=Close, 1=Open). Currently", CurrentShutterState
//Initialize =0
//EndIf

EndIf
End


Function pt_LaserShutterResetToggle(ButtonVarName) : ButtonControl
String ButtonVarName

NVAR LaserShutterInstNum		=root:LaserShutterInstNum
If (StringMatch(ButtonVarName, "Button0"))
	LaserShutterInstNum			= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
EndIf
String FldrName 					= "root:LaserShutterVars"+Num2Str(LaserShutterInstNum)
String LaserShutterPanelName 		= "LaserShutterMain"+Num2Str(LaserShutterInstNum)

Button button0, disable=0, win=$LaserShutterPanelName // Enable Toggle Button
Button button2, disable=0, win=$LaserShutterPanelName // Enable Initialize Button
Button button3, disable=2, win=$LaserShutterPanelName // Disable Reset Toggle Button

End


Function pt_LaserShutterEOSH()

NVAR LaserShutterInstNum		=root:LaserShutterInstNum
//If (!StringMatch(button0, "TrigGen"))
//	LaserShutterInstNum			= Str2Num(getuserdata("",button1,""))	// convert Instance Num String to Num
//EndIf
String FldrName 					= "root:LaserShutterVars"+Num2Str(LaserShutterInstNum)
String LaserShutterPanelName 	= "LaserShutterMain"+Num2Str(LaserShutterInstNum)

NVAR	CurrentShutterState	= $(FldrName+":CurrentShutterState")
NVAR	Initialize				= $(FldrName+":Initialize")

// Update current state


Button button0, disable=0, win=$LaserShutterPanelName // Enable Toggle Button
Button button2, disable=0, win=$LaserShutterPanelName // Enable Initialize Button
Button button3, disable=2, win=$LaserShutterPanelName // Disable Reset Toggle Button

If (Initialize ==0)
CurrentShutterState = 1-CurrentShutterState	// toggle state
Print "Toggled laser shutter. (0=Close, 1=Open). Currently", CurrentShutterState

Else
CurrentShutterState = 0
Print "Initialized laser shutter. (0=Close, 1=Open). Currently", CurrentShutterState
Initialize =0
EndIf


pt_LaserShutterDisplay()
pt_LaserShutterSave()

End


Function pt_LaserShutterDisplay()
// display data: Check if the window LaserShutterDisplayWin exists? 
// if yes, append. If no, create and append

NVAR LaserShutterInstNum		=root:LaserShutterInstNum
//If (!StringMatch(button0, "TrigGen"))
//	LaserShutterInstNum			= Str2Num(getuserdata("",button1,""))	// convert Instance Num String to Num
//EndIf
String FldrName 					= "root:LaserShutterVars"+Num2Str(LaserShutterInstNum)
//String LaserShutterPanelName 	= "LaserShutterMain"+Num2Str(LaserShutterInstNum)

String WName

//Wave  LaserShutterInWave 		=  $(FldrName+":"+FldrName+"In")

sscanf FldrName+"Out", "root:%s", WName
Wave LaserShutterOutWave = $(FldrName+":"+WName)


DoWindow LaserShutterDisplayWin
If (V_Flag)
// Check if the trace is not on graph
//	Print TraceNameList("LaserShutterDisplayWin", ";", 1)
	
	If (FindListItem(WName, TraceNameList("LaserShutterDisplayWin", ";", 1), ";")==-1)
	AppendToGraph /L /W =LaserShutterDisplayWin LaserShutterOutWave
	EndIf
	
Else
	Display 
	DoWindow /C LaserShutterDisplayWin
	AppendToGraph /L /W =LaserShutterDisplayWin LaserShutterOutWave	
EndIf
End


Function pt_LaserShutterSave()
// Save data to disk
Variable N,i
String OldDf, Str, InWaveToSaveAsFull, WName

NVAR LaserShutterInstNum		=root:LaserShutterInstNum
//If (!StringMatch(button0, "TrigGen"))
//	LaserShutterInstNum			= Str2Num(getuserdata("",button1,""))	// convert Instance Num String to Num
//EndIf
String FldrName 					= "root:LaserShutterVars"+Num2Str(LaserShutterInstNum)
//String LaserShutterPanelName 	= "LaserShutterMain"+Num2Str(LaserShutterInstNum)


If (WaveExists($FldrName+":OutWaveToSave"))
OldDF = GetDataFolder(1)
SetDataFolder $FldrName

Wave /T OutWaveToSave = $FldrName+":OutWaveToSave"

//Wave /T InWaveToSave = $(FldrName+":"+FldrName+"In")
PathInfo home
If (V_Flag==0)
	Abort "Please save the experiment first!"
EndIf
NewPath /O DiskDFName,  S_Path
Print "Saving LaserShutter data to",S_Path
//SaveData /Q/D=1/O/L=1  /P=DiskDFName /J =SaveWaveList InWaveToSaveAs+"_"+ Num2Str(IterNum)//T=$EncFName /P=SaveDF
N=NumPnts(OutWaveToSave)
For (i=0; i<N; i+=1)	// save outwaves
	sscanf FldrName, "root:%s", WName
	Str = WName+OutWaveToSave[0]
	If (!StringMatch("Out", OutWaveToSave[0])  )
	Duplicate /O $(FldrName+":"+WName+"Out"), $(Str)
	EndIf
	Save /C/O/P=DiskDFName  $(Str)//$OutWaveToSave[i]
	KillWaves OutWaveToSave
EndFor
KillPath /Z DiskDFName
SetDataFolder OldDf
Else
	Print "No LaserShutter data to save!"
EndIf
End




Function pt_LaserShutterERRH()

NVAR LaserShutterInstNum		=root:LaserShutterInstNum
//If (!StringMatch(button0, "TrigGen"))
//	LaserShutterInstNum			= Str2Num(getuserdata("",button1,""))	// convert Instance Num String to Num
//EndIf
String FldrName 					= "root:LaserShutterVars"+Num2Str(LaserShutterInstNum)
//String LaserShutterPanelName 	= "LaserShutterMain"+Num2Str(LaserShutterInstNum)


NVAR LaserShutterError 	= $FldrName+":LaserShutterError"
	LaserShutterError = 1
	Print "*****************************************"
	Print "DataAcquisition Error in", FldrName
	Print "*****************************************"
	pt_LaserShutterEOSH()
End

Function pt_LaserShutterInitialize(ButtonVarName) : ButtonControl
String ButtonVarName

NVAR LaserShutterInstNum		=root:LaserShutterInstNum
If (StringMatch(ButtonVarName, "Button2"))
	LaserShutterInstNum			= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
EndIf
String FldrName 					= "root:LaserShutterVars"+Num2Str(LaserShutterInstNum)
//String LaserShutterPanelName 	= "LaserShutterMain"+Num2Str(LaserShutterInstNum)

// It can happen that the signal voltage is not 0, 0 V while the mirrors are at 0, 0 micron or vice verse.
// Initialize will set the current position to 0,0 V. 
//NVAR	CurrentShutterState	= root:LaserShutterVars:CurrentShutterState
NVAR	Initialize				= $(FldrName+":Initialize")

//CurrentShutterState 	=0
If (StringMatch(ButtonVarName, "TrigGen"))
Wave /T 		OutWaveNamesW = 	$FldrName+":OutWaveNamesW"
Duplicate /O OutWaveNamesW, 	$FldrName+":OutWaveNamesWCopy"
Else
Initialize = 1
pt_LaserShutterToggle("")
EndIf
End

Function /S pt_CreateNew1(DataFolderName)
// Function to create a new instance of DataFolderName
String DataFolderName
Variable i=1
Do 
If (DataFolderExists(DataFolderName+Num2Str(i)) ==0)
Return DataFolderName+Num2Str(i)
Break
EndIf
i +=1
While (1)
End

Function pt_InstanceNum(DataFolderName, PanelName)
// Function to create a new instance of DataFolderName. Also, kill orphan datafolders which don't have associated panels
String DataFolderName, PanelName
String ODF // OrphanDataFolder
Variable i=1
Do 
If (DataFolderExists(DataFolderName+Num2Str(i)) ==0)
Return i
Break
EndIf

// If DataFolder exists but the window doesn't, then kill the data folder and try again

DoWindow $(PanelName + Num2Str(i))
If (V_Flag==0)
	ODF = DataFolderName+Num2Str(i)
	Print "Killing orphan data folder", ODF
	KillDataFolder / Z $ODF
EndIf
i +=1
While (1)
End

Function pt_TemperatureMain() : Panel

Variable InstNumL							// Local Copy of TemperatureInstNum
String 	FldrNameL							// Local Copy of Folder Name
String 	PanelNameL							// Local Copy of Panel Name

InstNumL = pt_InstanceNum("root:TemperatureVars", "TemperatureMain")
FldrNameL="root:TemperatureVars"+Num2Str(InstNumL)
PanelNameL = "TemperatureMain"+Num2Str(InstNumL)

Variable /G root:TemperatureInstNum			
//String 	/G root:TemperatureFldrName			// Active folder Name
//String 	/G root:TemperaturePanelName


NVAR InstNum 		=	root:TemperatureInstNum
//SVAR FldrName 		=	root:TemperatureFldrName
//SVAR PanelName		=	root:TemperaturePanelName

InstNum		= InstNumL
//FldrName 	= FldrNameL				
//PanelName 	= PanelNameL
// Global copy of Folder Name and PanelName for use by other functions. NB. Global copy will change with every new instant creation
// To use variables associated with a particular instant, local values should be used	

NewDataFolder /O $FldrNameL


Variable /G	 $FldrNameL+":CurrentTemperature"
//Make /O/N=2 $FldrNameL+":TemperatureVWave"
Variable /G 	 $FldrNameL+":CellNum" = 1
Variable /G 	 $FldrNameL+":IterNum" = 1
String	/G 	 $FldrNameL+":InWaveBaseName" = "Temp_"

// waves to be sent for multiple iterations to TrigGen. If less than number of iterations, the last wave is repeated
Make /O/T/N=0 $FldrNameL+":InWaveNamesW"		

Variable /G $FldrNameL+":TemperatureError"	=0
Variable /G $FldrNameL+":SamplingFreq" 		=100 //Sampling Freq in Hz for single scan
Variable /G $FldrNameL+":ReSamplingFreq" 	=10  //ReSampling Freq in Hz. This channel is scanned at much 
												 //higher freq (eg. 10KHz) than needed. 

Variable /G $FldrNameL+":DebugMode" = 0
NVAR        DebugMode = $FldrNameL+":DebugMode"

If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "*************************************"
EndIf

// waves to save
//Make /O/T/N=0 $FldrNameL+":OutWaveToSave"	// saved with the original name
//Make /O/T/N=1 $FldrNameL+":InWaveToSave"		// usually the acquired wave, saved as InWaveBaseName_CellNum_IterNum
//Wave /T InWaveToSave = $FldrNameL+":InWaveToSave"
//InWaveToSave[0] = "TemperatureVWave"

//SVAR InWaveToSaveAs = $FldrNameL+":InWaveToSaveAs"
//NVAR CellNum = $FldrNameL+":CellNum"
//NVAR IterNum = $FldrNameL+":IterNum"



//Make /T/O/N=4 $FldrNameL+":TemperatureHWName"
//Make /T/O/N=4 $FldrNameL+":TemperatureHWVal"

// possible values (can add more parameters)
// Wave /T w = root:TemperatureVars:TemperatureHWName
//w[0] = "DevID"
//w[1] = "ChNum"
//w[2] = "TemperatureVGain (Deg/V)"
//w[3] = "TrigSrc"						// value = "NoTrig" OR TriggerName like "/PFI4"

	PauseUpdate; Silent 1		// building window...
	DoWindow $PanelNameL
	If (V_Flag==1)
		DoWindow /K $PanelNameL
	EndIf
	NewPanel /K=2/W=(900,220,1175,280)
	DoWindow /C $PanelNameL
//	ShowTools/A
//	SetDrawEnv fsize= 14,textrgb= (0,9472,39168)
//	DrawText 100,19,"Temperature"
	
//	SetVariable setvar0,pos={50,0},size={70,16},title="Inst#",value=InstNum, limits={1,inf,1}
	Button button2,pos={30,18},size={15,15},title="N", proc = pt_TemperatureNewCell, userdata=Num2Str(InstNumL)
	SetVariable setvar1,pos={50,18},size={80,16},title="Cell#",value=$(FldrNameL+":CellNum" ), limits={1,inf,1}
	SetVariable setvar2,pos={140,18},size={80,16},title = "Iter#",value=$(FldrNameL+":IterNum" ), limits={1,inf,1}
	Button button0,pos={1,35},size={55,20},title="Hardware", proc = pt_TemperatureHWEdit, userdata=Num2Str(InstNumL)
	Button button1,pos={220,35},size={50,20},title="Acquire", proc = pt_TemperatureAcquire, userdata=Num2Str(InstNumL)
	Button button3,pos={120,35},size={50,20},title="Reset", disable =2
	Button button3,proc = pt_TemperatureResetAcquire, userdata=Num2Str(InstNumL) 
	ValDisplay valdisp0,pos={94,2},size={100,25},title="Temperature"
	String CT = FldrNameL+":CurrentTemperature"
	ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000},value=#CT

End

Function pt_TemperatureHWEdit(ButtonVarName) :  ButtonControl
String ButtonVarName

NVAR TemperatureInstNum		=root:TemperatureInstNum
//If (!StringMatch(button0, "TrigGen"))
TemperatureInstNum				= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
//EndIf
String FldrName 					= "root:TemperatureVars"+Num2Str(TemperatureInstNum)
//String TemperaturePanelName 	= "TemperatureMain"+Num2Str(TemperatureInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

If (WaveExists($(FldrName+":TemperatureHWName")) && WaveExists($(FldrName+":TemperatureHWVal"))    )
Wave /T TemperatureHWName =  	$(FldrName+":TemperatureHWName")
Wave /T TemperatureHWVal 	= 	$(FldrName+":TemperatureHWVal")
Edit /K=1 TemperatureHWName, TemperatureHWVal
Else
Make /T/O/N=3 $(FldrName+":TemperatureHWName")
Make /T/O/N=3 $(FldrName+":TemperatureHWVal")
Wave /T TemperatureHWName =  	$(FldrName+":TemperatureHWName")
Wave /T TemperatureHWVal 	= 	$(FldrName+":TemperatureHWVal")

TemperatureHWName[0] = "DevID"
TemperatureHWName[1] = "ChNum"
TemperatureHWName[2] = "TemperatureVGain (Deg/Volt)"
//TemperatureHWName[3] = "TrigSrc"		// value = "NoTrig" OR TriggerName like "/PFI4"
	
Edit /K=1 TemperatureHWName, TemperatureHWVal
EndIf

End

Function pt_TemperatureNewCell(ButtonVarName) : ButtonControl
String ButtonVarName

NVAR TemperatureInstNum		=root:TemperatureInstNum
//If (!StringMatch(button2, "TrigGen"))
TemperatureInstNum				= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
//EndIf
String FldrName 					= "root:TemperatureVars"+Num2Str(TemperatureInstNum)
//String TemperaturePanelName 	= "TemperatureMain"+Num2Str(TemperatureInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

NVAR CellNum 		= $FldrName+":CellNum"
NVAR IterNum 		= $FldrName+":IterNum"

CellNum +=1		// increase cell # by 1
IterNum    =1		// set Iter # =1

End

Function pt_TemperatureAcquire(ButtonVarName) :  ButtonControl
String ButtonVarName	// will be called using the button or from TrigGen (to run simultaneously with other channels )

NVAR TemperatureInstNum		=root:TemperatureInstNum
If (StringMatch(ButtonVarName, "Button1"))
TemperatureInstNum				= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
EndIf
String FldrName 					= "root:TemperatureVars"+Num2Str(TemperatureInstNum)
String TemperaturePanelName 	= "TemperatureMain"+Num2Str(TemperatureInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

Variable DevID = Nan
Variable ChNum = Nan
Variable i

String DevIdStr, InWaveListStr, OldDF, WName
//String TrigSrcStr 				
Wave /T TemperatureHWName =  	$(FldrName+":TemperatureHWName")
Wave /T TemperatureHWVal 	= 	$(FldrName+":TemperatureHWVal")

DevID 	 	= Str2Num(TemperatureHWVal[0])
ChNum  		= Str2Num(TemperatureHWVal[1])
//$(FldrName+":TemperatureHWName")
DevIdStr = "Dev"+Num2Str(DevID)
//TrigSrcStr	= "/"+DevIdStr+(TemperatureHWVal[3])

Button button1, disable=2, win=$TemperaturePanelName // disable
Button button3, disable=0, win=$TemperaturePanelName // Enable Reset button

//Wave TemperatureVWave =  $(FldrName+":TemperatureVWave")
//TemperatureVWave = NaN


If (StringMatch(ButtonVarName, "TrigGen"))
// copy output wave to root. copy DeviceName, Wavename, ChannelName to IODevNum, IOWName and IOChNum in root:TrigGenVars
Wave /T IODevFldrCopy 	= root:TrigGenVars:IODevFldrCopy
Wave /T InWaveNamesWCopy=$(FldrName+":InWaveNamesWCopy")
For (i=0; i<NumPnts(IODevFldrCopy); i+=1)
	If (StringMatch(IODevFldrCopy[i], FldrName))


// If no inwave, create one and scale later according to outwaves or inwaves on other channels
// If no other channels have outwaves or inwaves, abort and ask user to make inwave		
	If (NumPnts(InWaveNamesWCopy)==0)
	Make /O/N=0 $(FldrName+":"+"DummyTemperatureW")
	Make /T/O/N=1 $(FldrName+":"+"InWaveNamesWCopy")	
	Wave /T InWaveNamesWCopy=$(FldrName+":InWaveNamesWCopy")	
	InWaveNamesWCopy[0] = "DummyTemperatureW"
	EndIf
	
	Wave InW = $(FldrName+":"+InWaveNamesWCopy[0])
	InW = Nan
	//In Wave will be scaled after acquisition
//	Duplicate /O InW, $(FldrName+"In")
	sscanf FldrName+"In", "root:%s", WName
	Duplicate /O InW, $(FldrName+":"+WName)		// for pt_TemperatureDisplay()
	

	Wave /T IODevNum 	= root:TrigGenVars:IODevNum
	Wave /T IOChNum 	= root:TrigGenVars:IOChNum
	Wave /T IOWName 	= root:TrigGenVars:IOWName
	Wave /T IOEOSH 	= root:TrigGenVars:IOEOSH
	
	IODevNum[i]	= TemperatureHWVal[0]	
	IOChNum[i]	= TemperatureHWVal[1]
	sscanf FldrName+"In", "root:%s", WName
//	IOWName[i]	= WName
	IOWName[i]	= FldrName+":"+WName
	IOEOSH[i]	= "pt_TemperatureEOSH()"
	
	If (NumPnts(InWaveNamesWCopy)>1)
		DeletePoints 0,1,InWaveNamesWCopy
	Else
		Print "Warning! Sending the same wave in the next iteration as this iteration, as no more waves are left in InWaveNamesWCopy"
	EndIf
	
	Break	
	EndIf
EndFor
Else


// Check whether data already exists on the disk

PathInfo home
If (V_Flag==0)
	Abort "Please save the experiment first!"
EndIf
NewPath /Q/O HDSymbPath,  S_Path


SVAR InWaveBaseName	= $FldrName+":InWaveBaseName"
NVAR CellNum 			= $FldrName+":CellNum"
NVAR IterNum			= $FldrName+":IterNum"
NVAR SamplingFreq		= $FldrName+":SamplingFreq"	// //Sampling Freq in Hz for single scan
String MatchStr = InWaveBaseName +pt_PadZeros2IntNumCopy(CellNum, 4)+"_"+pt_PadZeros2IntNumCopy(IterNum, 4)

If (pt_DataExistsCheck(MatchStr, "HDSymbPath")==1)
	String DoAlertPromptStr = MatchStr+" already exists on disk. Overwrite?"
	DoAlert 1, DoAlertPromptStr
	If (V_Flag==2)
		Abort "Aborting..."
	EndIf
EndIf



InWaveListStr = ""

//Wave /T InWaveNamesW=$FldrName+":InWaveNamesW"
//Wave InW = $(FldrName+":"+InWaveNamesW[0])
//In Wave will be scaled after acquisition
sscanf FldrName+"In", "root:%s", WName
Make /O/N=100 $(FldrName+":"+WName)		// for pt_TemperatureDisplay()
Wave InW = $(FldrName+":"+WName)
SetScale /P x,0,1/SamplingFreq,InW		
InW = Nan

InWaveListStr += FldrName+":"+WName+","+Num2Str(ChNum)+";"
//Print "Reading in wave from Temperature Device", InWaveListStr
// without trigger
//DAQmx_Scan /DEV= DevIdStr /BKG /ERRH="pt_TemperatureERRH()" /EOSH="pt_TemperatureEOSH()" Waves= InWaveListStr		
  
// with trigger. If TRIG="", scan starts immediately (but still has to wait for trigger if one is specified). /STRT=0 means need to use
//  fDAQmx_ScanStart() to start scan. Scan start is not the same as acquisition start if a trigger is specified

DAQmx_Scan /DEV= DevIdStr /BKG=1 /STRT=1/ERRH="pt_TemperatureERRH()" /EOSH="pt_TemperatureEOSH()" Waves= InWaveListStr
String TemperatureErr = fDAQmx_ErrorString()
If (!StringMatch(TemperatureErr,""))
	Print TemperatureErr
	pt_TemperatureERRH()
EndIf
//Print "********Button********"
//Button button1, disable=0, win=$TemperaturePanelName // disable
//pt_TemperatureEOSH()
//	TrigSrcStr = ""		// In case no trigger is specified, empty string causes scan to start without trigger
EndIf

//OldDF = GetDataFolder(1)
//SetDataFolder  root:TemperatureVars


End

Function pt_TemperatureResetAcquire(ButtonVarName) :  ButtonControl
String ButtonVarName	// will be called using the button or from TrigGen (to run simultaneously with other channels )

NVAR TemperatureInstNum		=root:TemperatureInstNum
If (StringMatch(ButtonVarName, "Button3"))
TemperatureInstNum				= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
EndIf
String FldrName 				= "root:TemperatureVars"+Num2Str(TemperatureInstNum)
String TemperaturePanelName 	= "TemperatureMain"+Num2Str(TemperatureInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////


Button button1, disable=0, win=$TemperaturePanelName // Re-enable Acquire button
Button button3, disable=2, win=$TemperaturePanelName // Disable Reset button
End





Function pt_TemperatureEOSH()

NVAR TemperatureInstNum		=root:TemperatureInstNum
//If (!StringMatch(button0, "TrigGen"))
//TemperatureInstNum				= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:TemperatureVars"+Num2Str(TemperatureInstNum)
String TemperaturePanelName 	= "TemperatureMain"+Num2Str(TemperatureInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////


Button button1, disable=0, win=$TemperaturePanelName // Enable scan button
Button button3, disable=2, win=$TemperaturePanelName // Disable Reset button

NVAR Temp 				= $(FldrName+":CurrentTemperature")
NVAR TemperatureError 	= $FldrName+":TemperatureError"
Variable Gain
String WName

sscanf FldrName+"In", "root:%s", WName
Wave TemperatureInWave = $(FldrName+":"+WName)

Wave /T TemperatureHWName =  	$(FldrName+":TemperatureHWName")
Wave /T TemperatureHWVal 	= 	$(FldrName+":TemperatureHWVal")

Gain = Str2Num(TemperatureHWVal[2])
TemperatureInWave *=Gain				// Scale incoming wave

pt_TemperatureAnalyze()
pt_TemperatureDisplay()
pt_TemperatureSave()

WaveStats /Q TemperatureInWave			// Analyse incoming wave
Temp = V_Avg
Print "Current temperature =", Temp
//If (!StringMatch(TemperatureHWVal[3], "NoTrig"))
//	Print "Waiting for next trigger..."
//	pt_TemperatureAcquire("button1")		// if scan was started using a trigger then, set start scan again and wait for new trigger.
//EndIf
End


Function pt_TemperatureSave()
// Save data to disk
Variable N,i
String OldDf, Str, WName

NVAR TemperatureInstNum		=root:TemperatureInstNum
//If (!StringMatch(button0, "TrigGen"))
//TemperatureInstNum				= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 					= "root:TemperatureVars"+Num2Str(TemperatureInstNum)
//String TemperaturePanelName 	= "TemperatureMain"+Num2Str(TemperatureInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

SVAR InWaveBaseName	= $FldrName+":InWaveBaseName"
NVAR CellNum 			= $FldrName+":CellNum"
NVAR IterNum 			= $FldrName+":IterNum"


sscanf FldrName+"In", "root:%s", WName
Wave TemperatureInWave = $(FldrName+":"+WName)

OldDF = GetDataFolder(1)
SetDataFolder $FldrName
//SVAR SaveWaveList	= SaveWaveList
//Wave /T OutWaveToSave = $FldrName+":OutWaveToSave"	No Out Wave to save for temperature
//Wave /T InWaveToSave = $FldrName+":InWaveToSave"			In wave to save is always the acquired wave
PathInfo home
If (V_Flag==0)
	Abort "Please save the experiment first!"
EndIf
NewPath /O DiskDFName,  S_Path
Print "Saving Temperature data to",S_Path
//SaveData /Q/D=1/O/L=1  /P=DiskDFName /J =SaveWaveList InWaveToSaveAs+"_"+ Num2Str(IterNum)//T=$EncFName /P=SaveDF
//N=NumPnts(OutWaveToSave)
//For (i=0; i<N; i+=1)	// save outwaves with the original wave names.
//	Save /C/O/P=DiskDFName  $OutWaveToSave[i]
//EndFor
Str = InWaveBaseName +pt_PadZeros2IntNumCopy(CellNum, 4)+"_"+pt_PadZeros2IntNumCopy(IterNum, 4)
Print "InWaveToSaveAs ", Str
Duplicate /O TemperatureInWave, $(Str)

//InWaveToSaveAsFull = InWaveToSaveAs+ Num2Str(IterNum)
//Duplicate /O TemperatureVWave, $InWaveToSaveAsFull
Save /C/O/P=DiskDFName  $(Str) //as InWaveToSaveAsFull+".ibw"
KillWaves $(Str)
KillPath /Z DiskDFName
SetDataFolder OldDf
IterNum +=1
End




Function pt_TemperatureDisplay()
// display data: Check if the window TemperatureDisplayWin exists? 
// if yes, append. If no, create and append

NVAR TemperatureInstNum		=root:TemperatureInstNum
//If (!StringMatch(button0, "TrigGen"))
//TemperatureInstNum				= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 					= "root:TemperatureVars"+Num2Str(TemperatureInstNum)
//String TemperaturePanelName 	= "TemperatureMain"+Num2Str(TemperatureInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////


String WName

sscanf FldrName+"In", "root:%s", WName
Wave TemperatureInWave = $(FldrName+":"+WName)


DoWindow TemperatureDisplayWin
If (V_Flag)
// Check if the trace is not on graph
//	Print TraceNameList("TemperatureDisplayWin", ";", 1)
	If (FindListItem(WName, TraceNameList("TemperatureDisplayWin", ";", 1), ";")==-1)
	AppendToGraph /W=TemperatureDisplayWin TemperatureInWave
	EndIf
Else
	Display
	DoWindow /C TemperatureDisplayWin
	AppendToGraph /W=TemperatureDisplayWin TemperatureInWave
EndIf

sscanf FldrName+"Avg", "root:%s", WName
Wave TemperatureAvgWave = $(FldrName+":"+WName)


DoWindow TemperatureAvgDisplayWin
If (V_Flag)
// Check if the trace is not on graph
//	Print TraceNameList("TemperatureDisplayWin", ";", 1)
	If (FindListItem(WName, TraceNameList("TemperatureAvgDisplayWin", ";", 1), ";")==-1)
	AppendToGraph /W=TemperatureAvgDisplayWin TemperatureAvgWave
	EndIf
Else
	Display
	DoWindow /C TemperatureAvgDisplayWin
	AppendToGraph /W=TemperatureAvgDisplayWin TemperatureAvgWave
EndIf



End

Function pt_TemperatureAnalyze()
// Analyze data: Resample at low freq


NVAR TemperatureInstNum		=root:TemperatureInstNum
//If (!StringMatch(button0, "TrigGen"))
//TemperatureInstNum				= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 					= "root:TemperatureVars"+Num2Str(TemperatureInstNum)
String TemperatureVWName
//String TemperaturePanelName 	= "TemperatureMain"+Num2Str(TemperatureInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
NVAR 	    ReSamplingFreq		= $FldrName+":ReSamplingFreq"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////


String WName

sscanf FldrName+"In", "root:%s", WName
Wave TemperatureInWave = $(FldrName+":"+WName)
Resample /Rate = (ResamplingFreq) TemperatureInWave	// Resample temperature at 10Hz

Wavestats /Q TemperatureInWave
Make /O/N=1 Temperature_Avg = V_Avg

//String TemperatureVWName
sscanf FldrName+"Avg", "root:%s", TemperatureVWName
If (WaveExists($(FldrName+":"+TemperatureVWName)))
Wave TemperatureVW = $(FldrName+":"+TemperatureVWName)
Concatenate /NP {Temperature_Avg}, TemperatureVW
Else
Make /O/N=0 $(FldrName+":"+TemperatureVWName)
Wave TemperatureVW = $(FldrName+":"+TemperatureVWName)
Concatenate /NP {Temperature_Avg}, TemperatureVW
EndIf

End


Function pt_TemperatureERRH()

NVAR TemperatureInstNum		=root:TemperatureInstNum
//If (!StringMatch(button0, "TrigGen"))
//TemperatureInstNum				= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 					= "root:TemperatureVars"+Num2Str(TemperatureInstNum)
//String TemperaturePanelName 	= "TemperatureMain"+Num2Str(TemperatureInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////


NVAR TemperatureError 	= $FldrName+":TemperatureError"
	TemperatureError = 1
	Print "*****************************************"
	Print "DataAcquisition Error in", FldrName
	Print "*****************************************"
	pt_TemperatureEOSH()
End

Function pt_TemperatureInitialize(TrigGen)
String TrigGen

NVAR TemperatureInstNum			=root:TemperatureInstNum
//If (!StringMatch(button0, "TrigGen"))
//	TemperatureInstNum			= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:TemperatureVars"+Num2Str(TemperatureInstNum)
//String TemperaturePanelName 	= "TemperatureMain"+Num2Str(TemperatureInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////


// Check whether data already exists on the disk

PathInfo home
If (V_Flag==0)
	Abort "Please save the experiment first!"
EndIf
NewPath /Q/O HDSymbPath,  S_Path


SVAR InWaveBaseName	= $FldrName+":InWaveBaseName"
NVAR CellNum 			= $FldrName+":CellNum"
NVAR IterNum			= $FldrName+":IterNum"
NVAR IterTot = root:TrigGenVars:IterTot
NVAR IterLeft = root:TrigGenVars:IterLeft
NVAR RepsTot		= root:TrigGenVars:RepsTot
NVAR RepsLeft		= root:TrigGenVars:RepsLeft
String MatchStr = InWaveBaseName +pt_PadZeros2IntNumCopy(CellNum, 4)+"_"+pt_PadZeros2IntNumCopy(IterNum, 4)

If ((IterLeft == IterTot) && (RepsLeft == RepsTot))	// Do for 1st Iter of 1st Rep
If (pt_DataExistsCheck(MatchStr, "HDSymbPath")==1)
	String DoAlertPromptStr = MatchStr+" already exists on disk. Overwrite?"
	DoAlert 1, DoAlertPromptStr
	If (V_Flag==2)
		Abort "Aborting..."
	EndIf
EndIf
EndIf

Wave /T 		InWaveNamesW = 	$FldrName+":InWaveNamesW"
Duplicate /O InWaveNamesW, 		$FldrName+":InWaveNamesWCopy"

pt_ClearTemperatureAvgW(FldrName)

End

Function pt_ClearTemperatureAvgW(FldrName)
String FldrName

String WName


sscanf FldrName+"Avg", "root:%s", WName
Print FldrName+":"+WName
If (WaveExists($(FldrName+":"+WName)))
Wave w = $(FldrName+":"+WName)
DeletePoints 0,NumPnts(w), w
EndIf

End

//+++++++++++++++++++++++++++++++++++

Function pt_LaserPowerMain() : Panel

Variable InstNumL							// Local Copy of LaserPowerInstNum
String 	FldrNameL							// Local Copy of Folder Name
String 	PanelNameL							// Local Copy of Panel Name

InstNumL = pt_InstanceNum("root:LaserPowerVars", "LaserPowerMain")
FldrNameL="root:LaserPowerVars"+Num2Str(InstNumL)
PanelNameL = "LaserPowerMain"+Num2Str(InstNumL)

Variable /G root:LaserPowerInstNum			
//String 	/G root:LaserPowerFldrName			// Active folder Name
//String 	/G root:LaserPowerPanelName


NVAR InstNum 		=	root:LaserPowerInstNum
//SVAR FldrName 		=	root:LaserPowerFldrName
//SVAR PanelName	=	root:LaserPowerPanelName

InstNum		= InstNumL
//FldrName 	= FldrNameL				
//PanelName 	= PanelNameL
// Global copy of Folder Name and PanelName for use by other functions. NB. Global copy will change with every new instant creation
// To use variables associated with a particular instant, local values should be used	


NewDataFolder /O $FldrNameL


Variable /G	$FldrNameL+":CurrentLaserPower"
//Make /O/N=2 $FldrNameL+":LaserPowerVWave"
Variable /G 	 $FldrNameL+":CellNum" = 1
Variable /G 	 $FldrNameL+":IterNum" = 1
String	/G 	 $FldrNameL+":InWaveBaseName" = "LasPow_"

// waves to be sent for multiple iterations to TrigGen. If less than number of iterations, the last wave is repeated
Make /O/T/N=0 $FldrNameL+":InWaveNamesW"	

Variable /G $FldrNameL+":SamplingFreq" 		=100 //Sampling Freq in Hz for single scan
Variable /G $FldrNameL+":ReSamplingFreq" 	=10  //ReSampling Freq in Hz. This channel is scanned at much 
												 //higher freq (eg. 10KHz) than needed.

Variable /G $FldrNameL+":DebugMode" = 0
NVAR        DebugMode = $FldrNameL+":DebugMode"

If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "*************************************"
EndIf	



// waves to save
//Make /O/T/N=0 $FldrNameL+":OutWaveToSave"	// saved with the original name
//Make /O/T/N=1 $FldrNameL+":InWaveToSave"		// usually the acquired wave, saved as InWaveBaseName_CellNum_IterNum
//Wave /T InWaveToSave = $FldrNameL+":InWaveToSave"
//InWaveToSave[0] = "LaserPowerVWave"

//SVAR InWaveToSaveAs = $FldrNameL+":InWaveToSaveAs"
//NVAR CellNum = $FldrNameL+":CellNum"
//NVAR IterNum = $FldrNameL+":IterNum"


//Make /T/O/N=3 root:LaserPowerVars:LaserPowerHWName
//Make /T/O/N=3 root:LaserPowerVars:LaserPowerHWVal

// possible values (can add more parameters)
// Wave /T w = root:LaserPowerVars:LaserPowerHWName
//w[0] = "DevID"
//w[1] = "ChNum"
//w[2] = "LaserPowerVGain (Watt/Volt)"

	PauseUpdate; Silent 1		// building window...
	DoWindow $PanelNameL
	If (V_Flag==1)
		DoWindow /K $PanelNameL
	EndIf
	NewPanel /K=2/W=(900,710,1175,770)
	DoWindow /C $PanelNameL
//	ShowTools/A

//	SetDrawEnv fsize= 14,textrgb= (0,9472,39168)
//	DrawText 100,19,"LaserPower"

//	SetVariable setvar0,pos={50,0},size={70,16},title="Inst#",value=InstNum, limits={1,inf,1}
	Button button2,pos={30,18},size={15,15},title="N", proc = pt_LaserPowerNewCell, userdata=Num2Str(InstNumL)
	SetVariable setvar1,pos={50,18},size={80,16},title="Cell#",value=$(FldrNameL+":CellNum" ), limits={1,inf,1}
	SetVariable setvar2,pos={140,18},size={80,16},title = "Iter#",value=$(FldrNameL+":IterNum" ), limits={1,inf,1}
	Button button0,pos={1,35},size={55,20},title="Hardware", proc = pt_LaserPowerHWEdit, userdata=Num2Str(InstNumL)
	Button button1,pos={220,35},size={50,20},title="Acquire", proc = pt_LaserPowerAcquire, userdata=Num2Str(InstNumL)
	Button button3,pos={110,35},size={50,20},title="Reset", disable =2
	Button button3,proc = pt_LaserPowerResetAcquire, userdata=Num2Str(InstNumL)
	ValDisplay valdisp0,pos={94,2},size={100,15},title="LaserPower"
	String LP= FldrNameL+":CurrentLaserPower"
	ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000},value=#LP
End

Function pt_LaserPowerHWEdit(ButtonVarName) :  ButtonControl
String ButtonVarName

NVAR LaserPowerInstNum			=root:LaserPowerInstNum
//If (!StringMatch(button0, "TrigGen"))
	LaserPowerInstNum			= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:LaserPowerVars"+Num2Str(LaserPowerInstNum)
//String LaserPowerPanelName 	= "LaserPowerMain"+Num2Str(LaserPowerInstNum)


If (WaveExists($(FldrName+":LaserPowerHWName")) && WaveExists($(FldrName+":LaserPowerHWVal"))    )
Wave /T LaserPowerHWName =  	$(FldrName+":LaserPowerHWName")
Wave /T LaserPowerHWVal 	= 	$(FldrName+":LaserPowerHWVal")
Edit /K=1 LaserPowerHWName, LaserPowerHWVal
Else
Make /T/O/N=3 $(FldrName+":LaserPowerHWName")
Make /T/O/N=3 $(FldrName+":LaserPowerHWVal")
Wave /T LaserPowerHWName =  	$(FldrName+":LaserPowerHWName")
Wave /T LaserPowerHWVal 	= 	$(FldrName+":LaserPowerHWVal")
LaserPowerHWName[0] = "DevID"
LaserPowerHWName[1] = "ChNum"
LaserPowerHWName[2] = "LaserPowerVGain (Watt/Volt)"
Edit /K=1 LaserPowerHWName, LaserPowerHWVal
EndIf

End


Function pt_LaserPowerNewCell(ButtonVarName) : ButtonControl
String ButtonVarName

NVAR LaserPowerInstNum			=root:LaserPowerInstNum
//If (!StringMatch(button0, "TrigGen"))
	LaserPowerInstNum			= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:LaserPowerVars"+Num2Str(LaserPowerInstNum)
//String LaserPowerPanelName 	= "LaserPowerMain"+Num2Str(LaserPowerInstNum)


NVAR CellNum 		= $FldrName+":CellNum"
NVAR IterNum 		= $FldrName+":IterNum"

CellNum +=1		// increase cell # by 1
IterNum    =1		// set Iter # =1

End

Function pt_LaserPowerAcquire(ButtonVarName) :  ButtonControl
String ButtonVarName		// will be called using the button or from TrigGen (to run simultaneously with other channels )

NVAR LaserPowerInstNum			=root:LaserPowerInstNum
If (StringMatch(ButtonVarName, "Button1"))
	LaserPowerInstNum			= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
EndIf
String FldrName 				= "root:LaserPowerVars"+Num2Str(LaserPowerInstNum)
String LaserPowerPanelName 	= "LaserPowerMain"+Num2Str(LaserPowerInstNum)

Variable DevID = Nan
Variable ChNum = Nan
Variable i

String DevIdStr, InWaveListStr, OldDF, WName

Wave /T LaserPowerHWName =  	$(FldrName+":LaserPowerHWName")
Wave /T LaserPowerHWVal 	= 	$(FldrName+":LaserPowerHWVal")

DevID 	 	= Str2Num(LaserPowerHWVal[0])
ChNum  		= Str2Num(LaserPowerHWVal[1])
DevIdStr = "Dev"+Num2Str(DevID)



Button button3, disable=0, win=$LaserPowerPanelName // Enable Reset Acquire button
Button button1, disable=2, win=$LaserPowerPanelName // disable acquire button

//OldDF = GetDataFolder(1)
//SetDataFolder  root:LaserPowerVars

//Wave LaserPowerVWave = $(FldrName+":LaserPowerVWave")
//LaserPowerVWave = NaN

If (StringMatch(ButtonVarName, "TrigGen"))
// copy output wave to root. copy DeviceName, Wavename, ChannelName to IODevNum, IOWName and IOChNum in root:TrigGenVars
Wave /T IODevFldrCopy 	= root:TrigGenVars:IODevFldrCopy
Wave /T InWaveNamesWCopy=$FldrName+":InWaveNamesWCopy"
For (i=0; i<NumPnts(IODevFldrCopy); i+=1)
	If (StringMatch(IODevFldrCopy[i], FldrName))
	
// If no inwave, create one and scale later according to outwaves or inwaves on other channels
// If no other channels have outwaves or inwaves, abort and ask user to G inwave	
	If (NumPnts(InWaveNamesWCopy)==0)
	Make /O/N=0 $(FldrName+":"+"DummyLaserPowerW")
	Make /T/O/N=1 $(FldrName+":"+"InWaveNamesWCopy")	
	Wave /T InWaveNamesWCopy=$(FldrName+":InWaveNamesWCopy")	
	InWaveNamesWCopy[0] = "DummyLaserPowerW"
	EndIf

	
	Wave InW = $(FldrName+":"+InWaveNamesWCopy[0])
	InW = Nan
	//In Wave will be scaled after acquisition
	Duplicate /O InW, $(FldrName+"In")
	sscanf FldrName+"In", "root:%s", WName
	Duplicate /O InW, $(FldrName+":"+WName)		// for pt_LaserPowerDisplay()
	
	Wave /T IODevNum 	= root:TrigGenVars:IODevNum
	Wave /T IOChNum 	= root:TrigGenVars:IOChNum
	Wave /T IOWName 	= root:TrigGenVars:IOWName
	Wave /T IOEOSH 	= root:TrigGenVars:IOEOSH
	
	IODevNum[i]	= LaserPowerHWVal[0]	
	IOChNum[i]	= LaserPowerHWVal[1]
	sscanf FldrName+"In", "root:%s", WName
	IOWName[i]	= WName
	IOEOSH[i]	= "pt_LaserPowerEOSH()"
	
	If (NumPnts(InWaveNamesWCopy)>1)
		DeletePoints 0,1,InWaveNamesWCopy
	Else
		Print "Warning! Sending the same wave in the next iteration as this iteration, as no more waves are left in InWaveNamesWCopy"
	EndIf
	
	Break	
	EndIf
EndFor
Else

// Check whether data already exists on the disk

PathInfo home
If (V_Flag==0)
	Abort "Please save the experiment first!"
EndIf
NewPath /Q/O HDSymbPath,  S_Path


SVAR InWaveBaseName	= $FldrName+":InWaveBaseName"
NVAR CellNum 			= $FldrName+":CellNum"
NVAR IterNum			= $FldrName+":IterNum"
NVAR SamplingFreq		= $FldrName+":SamplingFreq"	// //Sampling Freq in Hz for single scan
String MatchStr = InWaveBaseName +pt_PadZeros2IntNumCopy(CellNum, 4)+"_"+pt_PadZeros2IntNumCopy(IterNum, 4)

If (pt_DataExistsCheck(MatchStr, "HDSymbPath")==1)
	String DoAlertPromptStr = MatchStr+" already exists on disk. Overwrite?"
	DoAlert 1, DoAlertPromptStr
	If (V_Flag==2)
		Abort "Aborting..."
	EndIf
EndIf

InWaveListStr = ""

//Wave /T InWaveNamesW=$FldrName+":InWaveNamesW"
//Wave InW = $(FldrName+":"+InWaveNamesW[0])
//In Wave will be scaled after acquisition
sscanf FldrName+"In", "root:%s", WName
Make /O/N=100 $(FldrName+":"+WName)		// for pt_LaserPowerDisplay()
Wave InW = $(FldrName+":"+WName)
SetScale /P x,0,1/SamplingFreq,InW
InW = Nan

InWaveListStr += FldrName+":"+WName+","+Num2Str(ChNum)+";"

DAQmx_Scan /DEV= DevIdStr /BKG /ERRH="pt_LaserPowerERRH()" /EOSH="pt_LaserPowerEOSH()" Waves= InWaveListStr
EndIf
String LaserPowerErr = fDAQmx_ErrorString()
If (!StringMatch(LaserPowerErr,""))
	Print LaserPowerErr
	pt_LaserPowerERRH()
EndIf

End

Function pt_LaserPowerResetAcquire(ButtonVarName) :  ButtonControl
String ButtonVarName		// will be called using the button or from TrigGen (to run simultaneously with other channels )

NVAR LaserPowerInstNum			=root:LaserPowerInstNum
If (StringMatch(ButtonVarName, "Button1"))
	LaserPowerInstNum			= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
EndIf
String FldrName 				= "root:LaserPowerVars"+Num2Str(LaserPowerInstNum)
String LaserPowerPanelName 	= "LaserPowerMain"+Num2Str(LaserPowerInstNum)

Button button1, disable=0, win=$LaserPowerPanelName // Enable acquire button
Button button3, disable=2, win=$LaserPowerPanelName // Disable Reset Acquire button

End




Function pt_LaserPowerEOSH()

NVAR LaserPowerInstNum			=root:LaserPowerInstNum
//If (!StringMatch(button0, "TrigGen"))
//	LaserPowerInstNum			= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:LaserPowerVars"+Num2Str(LaserPowerInstNum)
String LaserPowerPanelName 	= "LaserPowerMain"+Num2Str(LaserPowerInstNum)

String WName

Button button1, disable=0, win=$LaserPowerPanelName // Enable
Button button3, disable=2, win=$LaserPowerPanelName // Disable

NVAR power = $(FldrName+":CurrentLaserPower")
Variable Gain

sscanf FldrName+"In", "root:%s", WName
Wave LaserPowerInWave = $(FldrName+":"+WName)

Wave /T LaserPowerHWName = $(FldrName+":LaserPowerHWName")
Wave /T LaserPowerHWVal =    $(FldrName+":LaserPowerHWVal")

Gain = Str2Num(LaserPowerHWVal[2])
LaserPowerInWave *=Gain				// Scale incoming wave

pt_LaserPowerAnalyze()
pt_LaserPowerDisplay()
pt_LaserPowerSave()

WaveStats /Q LaserPowerInWave	// Analyse incoming wave

power = V_Avg

Print "Current LaserPower =", power

End

Function pt_LaserPowerERRH()

NVAR LaserPowerInstNum			=root:LaserPowerInstNum
//If (!StringMatch(button0, "TrigGen"))
//	LaserPowerInstNum			= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:LaserPowerVars"+Num2Str(LaserPowerInstNum)
//String LaserPowerPanelName 	= "LaserPowerMain"+Num2Str(LaserPowerInstNum)

NVAR LaserPowerError 	= $FldrName+":LaserPowerError"
	LaserPowerError = 1
	Print "*****************************************"
	Print "DataAcquisition Error in", FldrName
	Print "*****************************************"
	pt_LaserPowerEOSH()
End



Function pt_LaserPowerInitialize(TrigGen)
String TrigGen

NVAR LaserPowerInstNum			=root:LaserPowerInstNum
//If (!StringMatch(button0, "TrigGen"))
//	LaserPowerInstNum			= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:LaserPowerVars"+Num2Str(LaserPowerInstNum)
//String LaserPowerPanelName 	= "LaserPowerMain"+Num2Str(LaserPowerInstNum)

// Check whether data already exists on the disk

PathInfo home
If (V_Flag==0)
	Abort "Please save the experiment first!"
EndIf
NewPath /Q/O HDSymbPath,  S_Path


SVAR InWaveBaseName	= $FldrName+":InWaveBaseName"
NVAR CellNum 			= $FldrName+":CellNum"
NVAR IterNum			= $FldrName+":IterNum"
NVAR IterTot = root:TrigGenVars:IterTot
NVAR IterLeft = root:TrigGenVars:IterLeft
NVAR RepsTot		= root:TrigGenVars:RepsTot
NVAR RepsLeft		= root:TrigGenVars:RepsLeft
String MatchStr = InWaveBaseName +pt_PadZeros2IntNumCopy(CellNum, 4)+"_"+pt_PadZeros2IntNumCopy(IterNum, 4)

If ((IterLeft == IterTot) && (RepsLeft == RepsTot))	// Do for 1st Iter of 1st Rep
If (pt_DataExistsCheck(MatchStr, "HDSymbPath")==1)
	String DoAlertPromptStr = MatchStr+" already exists on disk. Overwrite?"
	DoAlert 1, DoAlertPromptStr
	If (V_Flag==2)
		Abort "Aborting..."
	EndIf
EndIf
EndIf

Wave /T 		InWaveNamesW = 	$FldrName+":InWaveNamesW"
Duplicate /O InWaveNamesW, 		$FldrName+":InWaveNamesWCopy"

pt_ClearLaserPowerAvgW(FldrName)

End

Function pt_ClearLaserPowerAvgW(FldrName)
String FldrName

String WName


sscanf FldrName+"Avg", "root:%s", WName
Print FldrName+":"+WName
If (WaveExists($(FldrName+":"+WName)))
Wave w = $(FldrName+":"+WName)
DeletePoints 0,NumPnts(w), w
EndIf

End



Function pt_LaserPowerSave()
// Save data to disk
Variable N,i
String OldDf, Str, WName

NVAR LaserPowerInstNum			=root:LaserPowerInstNum
//If (!StringMatch(button0, "TrigGen"))
//	LaserPowerInstNum			= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:LaserPowerVars"+Num2Str(LaserPowerInstNum)
//String LaserPowerPanelName 	= "LaserPowerMain"+Num2Str(LaserPowerInstNum)


SVAR InWaveBaseName	= $FldrName+":InWaveBaseName"
NVAR CellNum 			= $FldrName+":CellNum"
NVAR IterNum 			= $FldrName+":IterNum"

sscanf FldrName+"In", "root:%s", WName
Wave LaserPowerInWave = $(FldrName+":"+WName)


OldDF = GetDataFolder(1)
SetDataFolder $FldrName
//SVAR SaveWaveList	= SaveWaveList
//Wave /T OutWaveToSave = $FldrName+":OutWaveToSave"	No Out Wave to save for LaserPower
//Wave /T InWaveToSave = $FldrName+":InWaveToSave"			In wave to save is always the acquired wave
PathInfo home
If (V_Flag==0)
	Abort "Please save the experiment first!"
EndIf
NewPath /O DiskDFName,  S_Path
Print "Saving LaserPower data to",S_Path
//SaveData /Q/D=1/O/L=1  /P=DiskDFName /J =SaveWaveList InWaveToSaveAs+"_"+ Num2Str(IterNum)//T=$EncFName /P=SaveDF
//N=NumPnts(OutWaveToSave)
//For (i=0; i<N; i+=1)	// save outwaves with the original wave names.
//	Save /C/O/P=DiskDFName  $OutWaveToSave[i]
//EndFor
Str = InWaveBaseName +pt_PadZeros2IntNumCopy(CellNum, 4)+"_"+pt_PadZeros2IntNumCopy(IterNum, 4)
Print "InWaveToSaveAs ", Str
Duplicate /O LaserPowerInWave, $(Str)

//InWaveToSaveAsFull = InWaveToSaveAs+ Num2Str(IterNum)
//Duplicate /O LaserPowerVWave, $InWaveToSaveAsFull
Save /C/O/P=DiskDFName  $(Str) //as InWaveToSaveAsFull+".ibw"
KillWaves $(Str)
KillPath /Z DiskDFName
SetDataFolder OldDf
IterNum +=1
End

Function pt_LaserPowerDisplay()
// display data: Check if the window LaserPowerDisplayWin exists? 
// if yes, append. If no, create and append
NVAR LaserPowerInstNum			=root:LaserPowerInstNum
//If (!StringMatch(button0, "TrigGen"))
//	LaserPowerInstNum			= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:LaserPowerVars"+Num2Str(LaserPowerInstNum)
//String LaserPowerPanelName 	= "LaserPowerMain"+Num2Str(LaserPowerInstNum)

String WName

sscanf FldrName+"In", "root:%s", WName
Wave LaserPowerInWave = $(FldrName+":"+WName)

DoWindow LaserPowerDisplayWin
If (V_Flag)
// Check if the trace is not on graph
//	Print TraceNameList("LaserPowerDisplayWin", ";", 1)
	If (FindListItem(WName, TraceNameList("LaserPowerDisplayWin", ";", 1), ";")==-1)
	AppendToGraph /W = LaserPowerDisplayWin LaserPowerInWave
	EndIf
Else
	Display
	DoWindow /C LaserPowerDisplayWin
	AppendToGraph /W = LaserPowerDisplayWin LaserPowerInWave
EndIf

sscanf FldrName+"Avg", "root:%s", WName
Wave LaserPowerAvgWave = $(FldrName+":"+WName)


DoWindow LaserPowerAvgDisplayWin
If (V_Flag)
// Check if the trace is not on graph
//	Print TraceNameList("LaserPowerDisplayWin", ";", 1)
	If (FindListItem(WName, TraceNameList("LaserPowerAvgDisplayWin", ";", 1), ";")==-1)
	AppendToGraph /W=LaserPowerAvgDisplayWin LaserPowerAvgWave
	EndIf
Else
	Display
	DoWindow /C LaserPowerAvgDisplayWin
	AppendToGraph /W=LaserPowerAvgDisplayWin LaserPowerAvgWave
EndIf


End

Function pt_LaserPowerAnalyze()
// Analyze data: Resample at low freq


NVAR LaserPowerInstNum		=root:LaserPowerInstNum
//If (!StringMatch(button0, "TrigGen"))
//LaserPowerInstNum				= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 					= "root:LaserPowerVars"+Num2Str(LaserPowerInstNum)
String LaserPowerVWName
//String LaserPowerPanelName 	= "LaserPowerMain"+Num2Str(LaserPowerInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
NVAR 	    ReSamplingFreq		= $FldrName+":ReSamplingFreq"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////


String WName

sscanf FldrName+"In", "root:%s", WName
Wave LaserPowerInWave = $(FldrName+":"+WName)
Resample /Rate = (ResamplingFreq) LaserPowerInWave	// Resample LaserPower at 10Hz

Wavestats /Q LaserPowerInWave
Make /O/N=1 LaserPower_Avg = V_Avg

//String LaserPowerVWName
sscanf FldrName+"Avg", "root:%s", LaserPowerVWName
If (WaveExists($(FldrName+":"+LaserPowerVWName)))
Wave LaserPowerVW = $(FldrName+":"+LaserPowerVWName)
Concatenate /NP {LaserPower_Avg}, LaserPowerVW
Else
Make /O/N=0 $(FldrName+":"+LaserPowerVWName)
Wave LaserPowerVW = $(FldrName+":"+LaserPowerVWName)
Concatenate /NP {LaserPower_Avg}, LaserPowerVW
EndIf

End

//======================================

Function pt_LaserVoltageMain() : Panel

Variable InstNumL							// Local Copy of LaserInstNum
String 	FldrNameL							// Local Copy of Folder Name
String 	PanelNameL							// Local Copy of Panel Name

InstNumL = pt_InstanceNum("root:LaserVoltageVars", "LaserVoltageMain")
FldrNameL="root:LaserVoltageVars"+Num2Str(InstNumL)
PanelNameL = "LaserVoltageMain"+Num2Str(InstNumL)

Variable /G root:LaserVoltageInstNum			
//String 	/G root:LaserVoltageFldrName			// Active folder Name
//String 	/G root:LaserVoltagePanelName

NVAR InstNum 		=	root:LaserVoltageInstNum
//SVAR FldrName 		=	root:LaserVoltageFldrName
//SVAR PanelName	=	root:LaserVoltagePanelName

InstNum		= InstNumL
//FldrName 	= FldrNameL				
//PanelName 	= PanelNameL
// Global copy of Folder Name and PanelName for use by other functions. NB. Global copy will change with every new instant creation
// To use variables associated with a particular instant, local values should be used	

NewDataFolder /O $FldrNameL

Variable /G	$FldrNameL+":CurrentVValue"
Variable /G	$FldrNameL+":NewVValue"	

// waves to be sent for multiple iterations to TrigGen. If less than number of iterations, the last wave is repeated
Make /O/T/N=0 $FldrNameL+":OutWaveNamesW"	

// waves to save
// The wave will be made if there is an out wave. No need to make one in the begining
//Make /O/T/N=0 $FldrNameL+":OutWaveToSave"	// saved with the original name
// No InWaves to save

//Make /T/O/N=2 $FldrNameL+":LaserVoltageHWName"
//Make /T/O/N=2 $FldrNameL+":LaserVoltageHWVal"

// possible values (can add more parameters)
// Wave /T w = root:LaserVoltageVars:LaserVoltageHWName
//w[0] = "DevID"
//w[1] = "ChNum"
////w[2] = "TrigSrc"

Variable /G	$FldrNameL+":LaserVoltageMaxVoltage" = 5  // No direct user access for this variable. Check Max voltage ToDo

Variable	/G 	$FldrNameL+":Initialize" =0

Variable /G $FldrNameL+":DebugMode" = 0
NVAR        DebugMode = $FldrNameL+":DebugMode"

If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "*************************************"
EndIf	


	PauseUpdate; Silent 1		// building window...
	DoWindow $PanelNameL
	If (V_Flag==1)
		DoWindow /K $PanelNameL
	EndIf
	NewPanel /K=2/W=(900,580,1175,680)
	DoWindow /C $PanelNameL
	SetDrawLayer UserBack
//	SetDrawEnv fsize= 14,textrgb= (0,9472,39168)
//	DrawText 100,19,"LaserVoltage"
//	SetVariable setvar0,pos={60,5},size={70,16},title="Inst#",value=InstNum, limits={1,inf,1}
	Button button0,pos={5,15},size={50,20},title="Initialize", proc = pt_LaserVoltageInitialize, userdata=Num2Str(InstNumL)
	ValDisplay valdisp0,pos={135,25},size={120,15},title="CurrentVValue"
	DrawText 260,40,"V"
	String CV = FldrNameL+":CurrentVValue"
	ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000},value= #CV 	// ToDo
//	CV = FldrNameL+":NewVValue"
	NVAR    VMax = $(FldrNameL+":LaserVoltageMaxVoltage") 
	SetVariable setvar1,pos={135,50},size={120,16},title="NewVValue",value= $(FldrNameL+":NewVValue" ), limits={0,VMax,1}
	DrawText 260,65,"V"
	Button button1,pos={210,75},size={50,20},title="Apply", proc = pt_LaserVoltageApply, userdata=Num2Str(InstNumL)
	Button button3,pos={110,75},size={50,20},title="Reset", disable =2
	Button button3,proc = pt_LaserVoltageResetApply, userdata=Num2Str(InstNumL)
	Button button2,pos={5,75},size={55,20},title="Hardware", proc = pt_LaserVoltageHWEdit, userdata=Num2Str(InstNumL)
End

Function pt_LaserVoltageHWEdit(ButtonVarName) :  ButtonControl
String ButtonVarName

NVAR LaserVoltageInstNum			=root:LaserVoltageInstNum
//If (!StringMatch(button0, "TrigGen"))
	LaserVoltageInstNum			= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:LaserVoltageVars"+Num2Str(LaserVoltageInstNum)
//String LaserVoltagePanelName 	= "LaserVoltageMain"+Num2Str(LaserVoltageInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////


If (WaveExists($(FldrName+":LaserVoltageHWName")) && WaveExists($(FldrName+":LaserVoltageHWVal"))    )
Wave /T LaserVoltageHWName =  	$(FldrName+":LaserVoltageHWName")
Wave /T LaserVoltageHWVal 	= 	$(FldrName+":LaserVoltageHWVal")
Edit /K=1 LaserVoltageHWName, LaserVoltageHWVal
Else
Make /T/O/N=2 $(FldrName+":LaserVoltageHWName")
Make /T/O/N=2 $(FldrName+":LaserVoltageHWVal")
Wave /T LaserVoltageHWName =  	$(FldrName+":LaserVoltageHWName")
Wave /T LaserVoltageHWVal 	= 	$(FldrName+":LaserVoltageHWVal")

LaserVoltageHWName[0] = "DevID"
LaserVoltageHWName[1] = "ChNum"
	
Edit /K=1 LaserVoltageHWName, LaserVoltageHWVal
EndIf

End

Function pt_LaserVoltageInitialize(ButtonVarName) : ButtonControl
String ButtonVarName
// It can happen that the laser voltage is not 0 V while the laser is off or vice versa.
// Initialize will set the current voltage to 0 V. Also copy the OutWaveNames to OutWaveNamesCopy
// so that different out waves can be sent to TrigGen
NVAR LaserVoltageInstNum			=root:LaserVoltageInstNum
If (StringMatch(ButtonVarName, "Button0"))
	LaserVoltageInstNum			= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
EndIf
String FldrName 				= "root:LaserVoltageVars"+Num2Str(LaserVoltageInstNum)
//String LaserVoltagePanelName 	= "LaserVoltageMain"+Num2Str(LaserVoltageInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

NVAR	V2	= $(FldrName+":NewVValue")
NVAR	Initialize	= $(FldrName+":Initialize")

If (StringMatch(ButtonVarName, "TrigGen"))
Wave /T 		OutWaveNamesW = 	$FldrName+":OutWaveNamesW"
Duplicate /O OutWaveNamesW, 	$FldrName+":OutWaveNamesWCopy"
Else
V2 = 0
Initialize = 1

pt_LaserVoltageApply("")
EndIf

End

Function pt_LaserVoltageApply(ButtonVarName)
String ButtonVarName	// will be called using the button or from TrigGen (to run simultaneously with other channels )

NVAR LaserVoltageInstNum		 	=root:LaserVoltageInstNum
If (StringMatch(ButtonVarName, "Button1"))
	LaserVoltageInstNum			= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
EndIf
String FldrName 				= "root:LaserVoltageVars"+Num2Str(LaserVoltageInstNum)
String LaserVoltagePanelName 	= "LaserVoltageMain"+Num2Str(LaserVoltageInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

Variable DevID = Nan
Variable ChNum = Nan
Variable i
String DevIdStr, OutWaveStr, WName

NVAR	V1	= $(FldrName+":CurrentVValue")
NVAR	V2	= $(FldrName+":NewVValue")
NVAR    VMax = $(FldrName+":LaserVoltageMaxVoltage")
NVAR	Initialize	= $(FldrName+":Initialize")


Wave /T LaserVoltageHWName 	= 	$(FldrName+":LaserVoltageHWName")
Wave /T LaserVoltageHWVal 		=    	$(FldrName+":LaserVoltageHWVal")

DevID 	 	= Str2Num(LaserVoltageHWVal[0])
ChNum  		= Str2Num(LaserVoltageHWVal[1])

DevIdStr = "Dev"+Num2Str(DevID)

//TrigSrcStr	= "/"+DevIdStr+(LaserVoltageHWVal[2])

//If (StringMatch(LaserVoltageHWVal[2], ""))
//	TrigSrcStr = ""		// In case no trigger is specified, empty string causes scan to start without trigger
//EndIf
Button button3, disable=0, win=$LaserVoltagePanelName // Enable Reset Apply Button
Button button0, disable=2, win=$LaserVoltagePanelName // disable Initialize Button	
Button button1, disable=2, win=$LaserVoltagePanelName // disable Apply Button	

Print "*************************************************************"


If (StringMatch(ButtonVarName, "TrigGen"))
// copy output wave to root. copy DeviceName, Wavename, ChannelName to IODevNum, IOWName and IOChNum in root:TrigGenVars

// fresh copy of OutWaveNamesW is generated when TrigGen Starts. On each call the topmost wave corresponding to topmost wave name
// is copied to root folder. and if the number of points in OutWaveNamesWCopy>1, then the top most wavename is deleted, so that in the next
// call the wave corresponding to next wavename is copied to root folder.
Wave /T OutWaveNamesWCopy=$FldrName+":OutWaveNamesWCopy"	
Wave /T IODevFldrCopy 	= root:TrigGenVars:IODevFldrCopy
For (i=0; i<NumPnts(IODevFldrCopy); i+=1)
	If (StringMatch(IODevFldrCopy[i], FldrName))
	
	Wave OutW = $(FldrName+":"+OutWaveNamesWCopy[0])
	
	WaveStats /Q OutW
	If ( (V_Max<=VMax) && (V_Min>=0) )
	
//	Wave LaserVoltageVWave =  $(FldrName+":LaserVoltageVWave")
//	LaserVoltageVWave = NaN
	
// 	Save the details of output wave to disk. ToDo	
//	Randomize output waves if desired. ToDo
	Duplicate /O OutW, $(FldrName+"Out")
	sscanf FldrName+"Out", "root:%s", WName
	Duplicate /O OutW, $(FldrName+":"+WName)		// for pt_pt_LaserVoltageDisplay()
	
	Make /T/O/N=1 $FldrName+":OutWaveToSave"		// Overwrite previous wave
	Wave /T OutWaveToSave = $FldrName+":OutWaveToSave"
	OutWaveToSave[0] = OutWaveNamesWCopy[0]		// for pt_LaserVoltageSave()
	
	Wave /T IODevNum 	= root:TrigGenVars:IODevNum
	Wave /T IOChNum 	= root:TrigGenVars:IOChNum
	Wave /T IOWName 	= root:TrigGenVars:IOWName
	Wave /T IOEOSH 	= root:TrigGenVars:IOEOSH
	
	IODevNum[i]	= LaserVoltageHWVal[0]	
	IOChNum[i]	= LaserVoltageHWVal[1]
	sscanf FldrName+"Out", "root:%s", WName
	IOWName[i]	= WName					//OutWaveNamesWCopy[0]
	IOEOSH[i]	= "pt_LaserVoltageEOSH()"
	If (NumPnts(OutWaveNamesWCopy)>1)
		DeletePoints 0,1,OutWaveNamesWCopy
	Else
		Print "Warning! Sending the same wave in the next iteration as this iteration, as no more waves are left in OutWaveNamesWCopy"
	EndIf
	
	Else		// Voltage out of range
		Print "Laser voltage out of range in wave", OutWaveNamesWCopy[0], "for", FldrName,"VMax=", VMax, "VMin=0"
		Abort "Aborting..."
	EndIf
	
	Break	
	EndIf
EndFor
Else

Print "Current laser voltage", V1
Print "Applying volatge to laser =", V2, "Volts"

If ( V2 > VMax || V2 < 0)		// Also check if the resulting position exceeds max deflection. ToDo
V2=V1

Print "Warning!! Voltage to be applied to laser exceeds LaserVoltageMaxVoltage or is smaller than 0V. Voltage not applied."
pt_LaserVoltageEOSH()

Else


OutWaveStr = ""

Make /T/O/N=1 $FldrName+":OutWaveToSave"		// Overwrite previous wave
Wave /T OutWaveToSave = $FldrName+":OutWaveToSave"

//sscanf FldrName+"Out", "root:%s", WName
//Make /O/N=2 $(FldrName+":"+"TmpOutW")				// for pt_LaserVoltageDisplay()
//Wave OutW = $(FldrName+":"+"TmpOutW")		
//OutW = V2
//OutWaveStr += FldrName+":TmpOutW"+","+Num2Str(ChNum)+";"
//OutWaveToSave[0] = "TmpOutW"					     // for pt_LaserVoltageSave()

sscanf FldrName+"Out", "root:%s", WName
Make /O/N=2 $(FldrName+":"+WName)				// for pt_LaserVoltageDisplay()
Wave OutW = $(FldrName+":"+WName)		
OutW = V2
OutWaveStr += FldrName+":"+WName+","+Num2Str(ChNum)+";"
OutWaveToSave[0] = "Out"					     // for pt_LaserVoltageSave()


If (Initialize ==1)		
Print "Initializing..."
EndIf

Print "Sending to laser", OutWaveStr, "on device", DevIdStr
//pt_LaserVoltageEOSH()
Print "*************************************************************"
// Assign the right trigger
//DAQmx_WaveformGen /DEV= DevIdStr /NPRD=1/TRIG={TrigSrc,1} /ERRH="pt_ErrorHook()" OutWaveStr
//DAQmx_WaveformGen /DEV= DevIdStr /STRT=1/TRIG=TrigSrcStr /NPRD=1/EOSH="pt_LaserVoltageEOSH()" OutWaveStr
DAQmx_WaveformGen /DEV= DevIdStr /NPRD=1/ERRH="pt_LaserVoltageERRH()"/EOSH="pt_LaserVoltageEOSH()" OutWaveStr
EndIf
EndIf
String LaserVoltageErr = fDAQmx_ErrorString()
If (!StringMatch(LaserVoltageErr,""))
	Print LaserVoltageErr
	pt_LaserVoltageERRH()
EndIf

End


Function pt_LaserVoltageResetApply(ButtonVarName)
String ButtonVarName	// will be called using the button or from TrigGen (to run simultaneously with other channels )

NVAR LaserVoltageInstNum		 	=root:LaserVoltageInstNum
If (StringMatch(ButtonVarName, "Button1"))
	LaserVoltageInstNum			= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
EndIf
String FldrName 				= "root:LaserVoltageVars"+Num2Str(LaserVoltageInstNum)
String LaserVoltagePanelName 	= "LaserVoltageMain"+Num2Str(LaserVoltageInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

Button button0, disable=0, win=$LaserVoltagePanelName // Enable Initialize Button
Button button1, disable=0, win=$LaserVoltagePanelName // Enable Apply Button
Button button3, disable=2, win=$LaserVoltagePanelName // Disable Reset Apply Button
	
End








Function pt_LaserVoltageEOSH()

NVAR LaserVoltageInstNum			=root:LaserVoltageInstNum
//If (!StringMatch(button0, "TrigGen"))
//	LaserVoltageInstNum			= Str2Num(getuserdata("",button2,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:LaserVoltageVars"+Num2Str(LaserVoltageInstNum)
String LaserVoltagePanelName 	= "LaserVoltageMain"+Num2Str(LaserVoltageInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

NVAR	V1	= $(FldrName+":CurrentVValue")
NVAR	V2	= $(FldrName+":NewVValue")		
NVAR	Initialize	= $(FldrName+":Initialize")

Button button0, disable=0, win=$LaserVoltagePanelName // Enable Initialize Button
Button button1, disable=0, win=$LaserVoltagePanelName // Enable Apply Button
Button button3, disable=2, win=$LaserVoltagePanelName // Disable Reset Apply Button	

If (Initialize ==1)
Initialize =0
EndIf

pt_LaserVoltageDisplay()
pt_LaserVoltageSave()
// Update current voltage

V1 = V2   
End

Function pt_LaserVoltageERRH()

NVAR LaserVoltageInstNum			=root:LaserVoltageInstNum
//If (!StringMatch(button0, "TrigGen"))
//	LaserVoltageInstNum			= Str2Num(getuserdata("",button2,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:LaserVoltageVars"+Num2Str(LaserVoltageInstNum)
//String LaserVoltagePanelName 	= "LaserVoltageMain"+Num2Str(LaserVoltageInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

NVAR LaserVoltageError 	= $FldrName+":LaserVoltageError"
	LaserVoltageError = 1
	Print "*****************************************"
	Print "DataAcquisition Error in", FldrName
	Print "*****************************************"
	pt_LaserVoltageEOSH()
End

Function pt_LaserVoltageDisplay()
// display data: Check if the window LaserVoltageDisplayWin exists? 
// if yes, append. If no, create and append
String WName

NVAR LaserVoltageInstNum			=root:LaserVoltageInstNum
//If (!StringMatch(button0, "TrigGen"))
//	LaserVoltageInstNum			= Str2Num(getuserdata("",button2,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:LaserVoltageVars"+Num2Str(LaserVoltageInstNum)
//String LaserVoltagePanelName 	= "LaserVoltageMain"+Num2Str(LaserVoltageInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

sscanf FldrName+"Out", "root:%s", WName
Wave LaserVoltageOutWave = $(FldrName+":"+WName)

DoWindow LaserVoltageDisplayWin
If (V_Flag)
// Check if the trace is not on graph
//	Print TraceNameList("LaserVoltageDisplayWin", ";", 1)
	If (FindListItem(WName, TraceNameList("LaserVoltageDisplayWin", ";", 1), ";")==-1)
	AppendToGraph /W= LaserVoltageDisplayWin LaserVoltageOutWave
	EndIf
Else
	Display
	DoWindow /C LaserVoltageDisplayWin
	AppendToGraph /W= LaserVoltageDisplayWin LaserVoltageOutWave
EndIf
End

Function pt_LaserVoltageSave()
// Save data to disk
Variable N,i
String OldDf, WName, Str
NVAR LaserVoltageInstNum			=root:LaserVoltageInstNum
//If (!StringMatch(button0, "TrigGen"))
//	LaserVoltageInstNum			= Str2Num(getuserdata("",button2,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:LaserVoltageVars"+Num2Str(LaserVoltageInstNum)
//String LaserVoltagePanelName 	= "LaserVoltageMain"+Num2Str(LaserVoltageInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

//SVAR InWaveBaseName	= $FldrName+":InWaveBaseName"
//NVAR CellNum 			= $FldrName+":CellNum"
//NVAR IterNum 			= $FldrName+":IterNum"
If (WaveExists($FldrName+":OutWaveToSave"))

OldDF = GetDataFolder(1)
SetDataFolder $FldrName
//SVAR SaveWaveList	= SaveWaveList
Wave /T OutWaveToSave = $FldrName+":OutWaveToSave"
//Wave /T InWaveToSave = $FldrName+":InWaveToSave"
PathInfo home
If (V_Flag==0)
	Abort "Please save the experiment first!"
EndIf
NewPath /O DiskDFName,  S_Path
Print "Saving LaserVoltage data to",S_Path
//SaveData /Q/D=1/O/L=1  /P=DiskDFName /J =SaveWaveList InWaveToSaveAs+"_"+ Num2Str(IterNum)//T=$EncFName /P=SaveDF
N=NumPnts(OutWaveToSave)
For (i=0; i<N; i+=1)	// save outwaves
	sscanf FldrName, "root:%s", WName
	Str = WName+OutWaveToSave[0]
	If (!StringMatch("Out", OutWaveToSave[0])  )
	Duplicate /O $(FldrName+":"+WName+"Out"), $(Str)
	EndIf
	Save /C/O/P=DiskDFName  $(Str)//$OutWaveToSave[i]
	KillWaves OutWaveToSave
EndFor
//Str = InWaveBaseName +pt_PadZeros2IntNumCopy(CellNum, 4)+"_"+pt_PadZeros2IntNumCopy(IterNum, 4)
//Print "InWaveToSaveAs ", Str
//Duplicate /O $InWaveToSave[0], $(Str)

//InWaveToSaveAsFull = InWaveToSaveAs+ Num2Str(IterNum)
//Duplicate /O LaserVoltageVWave, $InWaveToSaveAsFull
//Save /C/O/P=DiskDFName  $(Str) //as InWaveToSaveAsFull+".ibw"
//KillWaves $(Str)
KillPath /Z DiskDFName
SetDataFolder OldDf
//IterNum +=1
Else
	Print "No LaserVoltage data to save!"
EndIf
End

//************************************************************

Function pt_EPhysMain() : Panel

Variable InstNumL							// Local Copy of EPhysInstNum
String 	FldrNameL							// Local Copy of Folder Name
String 	PanelNameL							// Local Copy of Panel Name

InstNumL = pt_InstanceNum("root:EPhysVars", "EPhysMain")
FldrNameL="root:EPhysVars"+Num2Str(InstNumL)
PanelNameL = "EPhysMain"+Num2Str(InstNumL)

Variable /G root:EPhysInstNum			
//String 	/G root:EPhysFldrName			// Active folder Name
//String 	/G root:EPhysPanelName


NVAR InstNum 		=	root:EPhysInstNum
//SVAR FldrName 		=	root:EPhysFldrName
//SVAR PanelName	=	root:EPhysPanelName

InstNum		= InstNumL
//FldrName 	= FldrNameL				
//PanelName = PanelNameL

// Global copy of Folder Name and PanelName for use by other functions. NB. Global copy will change with every new instant creation
// To use variables associated with a particular instant, local values should be used	

NewDataFolder /O $FldrNameL

Variable /G 	 $FldrNameL+":CellNum" = 1
Variable /G 	 $FldrNameL+":IterNum" = 1
String	/G 	 $FldrNameL+":InWaveBaseName" = "Cell_"

// Outwaves to be sent for multiple iterations to TrigGen. If less than number of iterations, the last wave is repeated
Make /O/T/N=0 $FldrNameL+":OutWaveNamesW"	

// Inwaves to be sent for multiple iterations to TrigGen. If less than number of iterations, the last wave is repeated
Make /O/T/N=0 $FldrNameL+":InWaveNamesW" // usually the acquired wave, saved as InWaveBaseName_CellNum_IterNum

// waves to save
// The wave will be made if there is an out wave. No need to make one in the begining
//Make /O/T/N=0 $FldrNameL+":OutWaveToSave"	// saved with the original name
// No InWaves to save



//NewDataFolder /O $FldrNameL+":EPhysStims"		// all the OutWaves should be in this folder
// Default mode = None Selected (even if we program so that one mode is selected, saving the file as template doesn't save checkboxes)
Variable /G	$FldrNameL+":EPhys_VClmp" = 0		
Variable /G	$FldrNameL+":EPhys_IClmp"   = 0



// If changing default values also change in pt_EPhysModeSelect
Variable /G	$FldrNameL+":EPhysOutGain_VClmp" = 0.02 	//Units  = (V/V)
Variable /G	$FldrNameL+":EPhysInGain_VClmp"	= 5e8	//Units  = (V/A)
Variable /G	$FldrNameL+":EPhysOutGain_IClmp"	= 4e-10	//Units  = (V/A)
Variable /G	$FldrNameL+":EPhysInGain_IClmp"	= 10		//Units  = (V/V)		// check if it is equal to 1. ToDo

NVAR EPhysOutGain_VClmp =$FldrNameL+":EPhysOutGain_VClmp"
NVAR EPhysInGain_VClmp =$FldrNameL+":EPhysInGain_VClmp"
NVAR EPhysOutGain_IClmp =$FldrNameL+":EPhysOutGain_IClmp"
NVAR EPhysInGain_IClmp =$FldrNameL+":EPhysInGain_IClmp"

// Default mode = None Selected (even if we program so that one mode is selected, saving the file as template doesn't save checkboxes)
Variable /G 	$FldrNameL+":EPhysOutGain" = Nan //EPhysOutGain_VClmp
Variable /G 	$FldrNameL+":EPhysInGain"    = Nan //EPhysInGain_VClmp

Variable /G 	$FldrNameL+":EPhysOutWaveSlctVar" = 0
Variable /G 	$FldrNameL+":EPhysInWaveSlctVar" = 0

String /G $FldrNameL+":EPhysOutWaveName"	= ""
String /G $FldrNameL+":EPhysInWaveName"	= ""
//String /G $FldrNameL+":OutWaveList"			= ""
//String /G $FldrNameL+":InWaveList"			= ""

NVAR EPhysOutWaveSlctVar 	= $FldrNameL+":EPhysOutWaveSlctVar"
NVAR EPhysInWaveSlctVar 	= $FldrNameL+":EPhysInWaveSlctVar"

Variable /G $FldrNameL+":DebugMode" = 0
NVAR        DebugMode = $FldrNameL+":DebugMode"

If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "*************************************"
EndIf

//String /G 	$FldrNameL+":EPhysErrStr" = ""
Variable /G 	$FldrNameL+":EPhysErrVal" = 0
Variable /G	$FldrNameL+":EPhysRndOutWVar" = 0 
Variable /G 	$FldrNameL+":EPhysTelGrVar" = 0
Variable /G 	$FldrNameL+":EPhysLockSetVar" = 1

String /G 	$FldrNameL+":EPhysPrevMode" = ""
String /G 	$FldrNameL+":EPhysPrevDisplayMode" = ""
String /G 	$FldrNameL+":EPhysCurrentDisplayMode" = ""

//String /G $FldrNameL+":OutWaveList" = ""
//String /G $FldrNameL+":InWaveList" = ""
//String /G $FldrNameL+":InDevIdStr" = ""
//String /G $FldrNameL+":OutDevIdStr" = ""
//Variable /G $FldrNameL+":ScanRunning" = 0

//Make /O/N=0 $FldrNameL+":OutW_"
//Make /O/N=0 $FldrNameL+":InW_"
//Variable /G	root:EPhysVars:VClmp1IClmp2 = 1		// Default mode = VClamp
//Variable /G	root:EPhysVars:CurrentYValue
//Variable /G	root:EPhysVars:NewXValue		
//Variable /G	root:EPhysVars:NewYValue

//Variable /G	root:EPhysVars:EPhysMaxVoltage = 10  // No direct user access for this variable

//Variable	/G 	root:EPhysVars:Initialize =0	

//Make /T/O/N=5 root:EPhysVars:EPhysHWName
//Make /T/O/N=5 root:EPhysVars:EPhysHWVal


// possible values (can add more parameters)
// Wave /T w = root:EPhysVars:EPhysHWName
//w[0] = "OutDevID"
//w[1] = "InDevID"
//w[2] = "OutChNum"
//w[3] = "InChNum"
//w[4] = "TrigSrc"		// value = "NoTrig" OR TriggerName like "/PFI4"

//???????????????

//???????????????

	PauseUpdate; Silent 1		// building window...
	DoWindow $PanelNameL
	If (V_Flag==1)
		DoWindow /K $PanelNameL
	EndIf
	NewPanel /K=2/W=(900,50,1175,190)
	DoWindow /C $PanelNameL
	SetDrawLayer UserBack
//	SetDrawEnv fsize= 14,textrgb= (0,9472,39168)
//	DrawText 100,19,"EPhys"
//	DrawText 21,103,"(um)"
//	DrawText 147,104,"(um)"
//	SetVariable setvar0,pos={70,5},size={70,16},title="Inst#",value=InstNum, limits={1,inf,1}
	
	Button button4,pos={30,60},size={15,15},title="N", proc = pt_EPhysNewCell, userdata=Num2Str(InstNumL)
	SetVariable setvar1,pos={50,60},size={80,16},title="Cell#",value=$(FldrNameL+":CellNum" ), limits={1,inf,1}
	SetVariable setvar2,pos={140,60},size={80,16},title = "Iter#",value=$(FldrNameL+":IterNum" ), limits={1,inf,1}
	
	Button button0,pos={5,15},size={55,20},title="ResetDev", proc = pt_EPhysResetDev, userdata=Num2Str(InstNumL)
//	ValDisplay valdisp0,pos={5,50},size={120,15},title="CurrentXValue"
//	ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000},value= #"root:EPhysVars:CurrentXValue"	// ToDo 
//	ValDisplay valdisp1,pos={135,50},size={120,15},title="CurrentYValue"
//	ValDisplay valdisp1,limits={0,0,0},barmisc={0,1000},value=#"root:EPhysVars:CurrentYValue"
//	SetVariable setvar0,pos={5,75},size={120,16},title="NewXValue",value= root:EPhysVars:NewXValue
//	SetVariable setvar1,pos={135,75},size={120,16},title="NewYValue",value=root:EPhysVars:NewYValue
	Button button1,pos={210,115},size={50,20},title="Scan", proc = pt_EPhysScan, userdata=Num2Str(InstNumL)
	Button button3,pos={110,115},size={50,20},title="Reset", disable =2
	Button button3,proc =pt_EPhysResetScan, userdata=Num2Str(InstNumL)
	
	Button EPhysHWEdit,pos={5,115},size={55,20},title="Hardware", proc = pt_EPhysHWEdit, userdata=Num2Str(InstNumL)
//	PopupMenu popup0,pos={5,115},size={50,20},title="Hardware", proc = pt_EPhysHWEdit
	CheckBox EPhysVClmp,pos={60,25},size={54,14},title="VClamp",value= 0
	CheckBox EPhysVClmp,variable= $FldrNameL+":EPhys_VClmp", proc = pt_EPhysModeSelect, userdata=Num2Str(InstNumL)
	CheckBox EPhysIClmp,pos={60,42},size={50,14},title="IClamp",value= 0
	CheckBox EPhysIClmp,variable= $FldrNameL+":EPhys_IClmp", proc = pt_EPhysModeSelect, userdata=Num2Str(InstNumL)
//	SetVariable EPhysOutGainVClmp,pos={109,23},size={88,20},title="OutGain",value= V_Flag
//	SetVariable EPhysOutGainVClmp,value= root:EPhysVars:EPhysOutGain_VClmp, limits={-inf,inf,0}
//	SetVariable EPhysInGainVClmp,pos={117,44},size={80,20},title="InGain",value= V_Flag
//	SetVariable EPhysInGainVClmp,value= root:EPhysVars:EPhysInGain_VClmp, limits={-inf,inf,0}
	SetVariable EPhysOutGain,pos={140,23},size={88,20},title="OutGain"//,value= V_Flag
	SetVariable EPhysOutGain,value= $FldrNameL+":EPhysOutGain", limits={-inf,inf,0}
	SetVariable EPhysInGain,pos={140,44},size={80,20},title="InGain"//,value= V_Flag
	SetVariable EPhysInGain,value= $FldrNameL+":EPhysInGain", limits={-inf,inf,0}
	
	CheckBox EPhysTelGrVarName,pos={255,23},size={16,14},title="TelGr",value= 0, side =1, disable =2
	CheckBox EPhysTelGrVarName, variable = $FldrNameL+":EPhysTelGrVar", proc = pt_EPhysCopyTelGrPars, userdata=Num2Str(InstNumL)//EPhysRndOutWVar
	
	CheckBox EPhysLockSetVarName,pos={255,43},size={16,14},title="Lock",value= 1, side =1//, disable =2
	CheckBox EPhysLockSetVarName, variable = $FldrNameL+":EPhysLockSetVar", proc = pt_EPhysLockSettings, userdata=Num2Str(InstNumL)//EPhysRndOutWVar

// ideally all stim waves should be in a separate folder, but wavelist works only in the current data folder.
// for the time being outwaves are in root data folder. ToDo
	
//	PopupMenu EPhysOutWave,pos={5,75},size={106,21},title="OutWave"	
//	PopupMenu EPhysOutWave, mode = 1, value=WaveList("Out_*", ";", "" ), proc = pt_EPhysPopSelect
//	PopupMenu EPhysOutWave,pos={5,75},size={106,21},title="OutWave"	
	PopupMenu EPhysOutWave,pos={20,75},size={80,21},title="OutWave", bodyWidth=100
	PopupMenu EPhysOutWave, mode = 1, value=pt_EPhysWaveList("EPhysOutWave", "*"), proc = pt_EPhysPopSelect, userdata=Num2Str(InstNumL)
//	CheckBox EPhysOutWaveSlctVarName,pos={125,80},size={16,14},title="",value= 0
	CheckBox EPhysOutWaveSlctVarName,pos={160,80},size={16,14},title="",value= 0
	CheckBox EPhysOutWaveSlctVarName, variable = $FldrNameL+":EPhysOutWaveSlctVar"//EPhysOutWaveSlctVar

	CheckBox EPhysRndOutWVarName,pos={190,80},size={16,14},title="Rnd",value= 0
	CheckBox EPhysRndOutWVarName, variable = $FldrNameL+":EPhysRndOutWVar"//EPhysRndOutWVar
	

	

//	PopupMenu EPhysInWave,pos={150,75},size={98,21},title="InWave"
//	PopupMenu EPhysInWave, mode =1, value=WaveList("In_*", ";", "" ), proc = pt_EPhysPopSelect
//	PopupMenu EPhysInWave,pos={150,75},size={98,21},title="InWave"
	PopupMenu EPhysInWave,pos={20,95},size={80,21},title="InWave   ", bodyWidth=100
	PopupMenu EPhysInWave, mode =1, value=pt_EPhysWaveList("EPhysInWave", "*"), proc = pt_EPhysPopSelect, userdata=Num2Str(InstNumL)	
//	CheckBox EPhysInWaveSlctVarName,pos={255,80},size={16,14},title="",value= 0
	CheckBox EPhysInWaveSlctVarName,pos={160,100},size={16,14},title="",value= 0
	CheckBox EPhysInWaveSlctVarName, variable = $FldrNameL+":EPhysInWaveSlctVar"
End

Function /S pt_EPhysWaveList(PopupMenuVarName, MatchStr)
String PopupMenuVarName
String MatchStr
String ReturnWaveList

NVAR EPhysInstNum			=root:EPhysInstNum
//If (!StringMatch(button0, "TrigGen"))
	EPhysInstNum			= Str2Num(getuserdata("",PopupMenuVarName,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:EPhysVars"+Num2Str(EPhysInstNum)
//String EPhysPanelName 	= "EPhysMain"+Num2Str(EPhysInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

String OldDF
OldDF = GetDataFolder(1)
SetDataFolder FldrName
ReturnWaveList=WaveList(MatchStr, ";", "Text:0")
SetDataFolder OldDF
Return ReturnWaveList
End

Function pt_EPhysModeSelect(CheckBoxVarName, CheckBoxVarVal)  : CheckBoxControl
//Function pt_EPhysModeSelect(CheckBoxVarName)  : CheckBoxControl
String CheckBoxVarName
Variable CheckBoxVarVal

NVAR EPhysInstNum			=root:EPhysInstNum
//If (!StringMatch(button0, "TrigGen"))
	EPhysInstNum			= Str2Num(getuserdata("",CheckBoxVarName,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:EPhysVars"+Num2Str(EPhysInstNum)
//String EPhysPanelName 	= "EPhysMain"+Num2Str(EPhysInstNum)


/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

// This function updates the checkboxes in EPhysMain panel such that  for a channel 
// only one of V-Clamp or I-Clamp is chosen 

SVAR EPhysPrevMode			=$FldrName+":EPhysPrevMode"


NVAR EPhysOutGain_VClmp 	=$FldrName+":EPhysOutGain_VClmp"
NVAR EPhysInGain_VClmp 	=$FldrName+":EPhysInGain_VClmp"
NVAR EPhysOutGain_IClmp 	=$FldrName+":EPhysOutGain_IClmp"
NVAR EPhysInGain_IClmp 	=$FldrName+":EPhysInGain_IClmp"

NVAR EPhys_VClmp			=$FldrName+":EPhys_VClmp"
NVAR EPhys_IClmp			=$FldrName+":EPhys_IClmp"

NVAR 	EPhysOutGain 		= $FldrName+":EPhysOutGain" 
NVAR 	EPhysInGain			= $FldrName+":EPhysInGain"

Variable i

//NVAR    VClmp1IClmp2=root:EPhysVars:VClmp1IClmp2




StrSwitch (CheckBoxVarName)

	case "EPhysVClmp":				
//		VClmp1IClmp2 = 1		// Ch in VClmp
		EPhys_VClmp = 1
		EPhys_IClmp   = 0
		If (StringMatch(CheckBoxVarName, EPhysPrevMode) ==0)	// don't do anything if the box that was checked before is checked again
		// panel is initialized with both VClamp and IClamp unchecked and EPhysOutGain= Nan, EPhysInGain = Nan
		If (        (NumType(EPhysOutGain)==0) && (NumType(EPhysInGain)==0)        )		
		EPhysOutGain_IClmp = EPhysOutGain // store the current clamp gains 
		EPhysInGain_IClmp 	= EPhysInGain
		Else
		EPhysOutGain_IClmp =  4e-10 		// store the gains set at panel initialization
		EPhysInGain_IClmp 	= 10
		EndIf
		
		EPhysOutGain = EPhysOutGain_VClmp
		EPhysInGain = EPhysInGain_VClmp
		EPhysPrevMode = CheckBoxVarName
		EndIf
	break
	
	case "EPhysIClmp":
//		VClmp1IClmp2 = 2		// Ch in IClmp
		EPhys_VClmp = 0
		EPhys_IClmp   = 1
		If (StringMatch(CheckBoxVarName, EPhysPrevMode) ==0)	// don't do anything if the box that was checked before is checked again
		
		// panel is initialized with both VClamp and IClamp unchecked and EPhysOutGain= Nan, EPhysInGain = Nan
		If (        (NumType(EPhysOutGain)==0) && (NumType(EPhysInGain)==0)        )		
		EPhysOutGain_VClmp = EPhysOutGain // store the voltage clamp gains 
		EPhysInGain_VClmp 	= EPhysInGain 
		Else
		EPhysOutGain_VClmp = 0.02 // store the gains set at panel initialization
		EPhysInGain_VClmp 	= 5e8
		EndIf
		
		EPhysOutGain = EPhysOutGain_IClmp
		EPhysInGain = EPhysInGain_IClmp
		EPhysPrevMode = CheckBoxVarName
		EndIf
	break
	
EndSwitch	
// No need setting the values of checkbox var name
//Checkbox EPhysVClmp,	value = EPhys_VClmp == 1
//Checkbox EPhysIClmp, 	value = EPhys_IClmp == 1

//EPhys_VClmp = (VClmp1IClmp2 == 1) ? 1 : 0
//EPhys_IClmp  = (VClmp1IClmp2 == 2) ? 1 : 0


End





Function pt_EPhysCopyTelGrPars(CheckBoxVarName, CheckBoxVarVal)  : CheckBoxControl
//Function pt_EPhysModeSelect(CheckBoxVarName)  : CheckBoxControl
String CheckBoxVarName
Variable CheckBoxVarVal

NVAR EPhysInstNum			=root:EPhysInstNum
//If (!StringMatch(button0, "TrigGen"))
	EPhysInstNum			= Str2Num(getuserdata("",CheckBoxVarName,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:EPhysVars"+Num2Str(EPhysInstNum)
//String EPhysPanelName 	= "EPhysMain"+Num2Str(EPhysInstNum)

NVAR EPhysTelGrVar = $FldrName+":EPhysTelGrVar"
/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

// This function updates the checkboxes in EPhysMain panel such that  for a channel 
// only one of V-Clamp or I-Clamp is chosen 
pt_EPhysHWEdit("EPhysHWEdit")
Wave /T EPhysHWName 		= $FldrName+":EPhysHWName"
Wave /T EPhysHWVal		= $FldrName+":EPhysHWVal"

NVAR currentAxoBusID= root:AxonTelegraphPanel:currentAxoBusID
NVAR currentChannelID = root:AxonTelegraphPanel:currentChannelID
NVAR currentComPortID = root:AxonTelegraphPanel:currentComPortID
NVAR currentSerialNum = root:AxonTelegraphPanel:currentSerialNum
SVAR HardwareType_str = root:AxonTelegraphPanel:HardwareType_str

If (EPhysTelGrVar)


If (NVAR_Exists(currentAxoBusID) && NVAR_Exists(currentChannelID) && NVAR_Exists(currentComPortID) && NVAR_Exists(currentSerialNum) && SVAR_Exists(HardwareType_str))
EPhysHWVal[4] = Num2iStr(currentAxoBusID)		// HWVal = "" if not using telegraph
EPhysHWVal[5] = Num2iStr(currentChannelID)		// HWVal = "" if not using telegraph
EPhysHWVal[6] = Num2iStr(currentComPortID)		// HWVal = "" if not using telegraph
EPhysHWVal[7] = Num2iStr(currentSerialNum)		// HWVal = "" if not using telegraph
EPhysHWVal[8] = HardwareType_str				// HWVal = "" if not using telegraph
Else
DoAlert 0, "To use Axon Telegraph for Multiclamp 700A or B, add the following line, \n #include \":More Extensions:Data Acquisition:AxonTelegraphMonitor\" \n to a procedure file"
EPhysTelGrVar =0
EPhysHWVal[4] = ""
EPhysHWVal[5] = ""
EPhysHWVal[6] = ""
EPhysHWVal[7] = ""
EPhysHWVal[8] = ""
EndIf //If (NVAR_Exists(currentAxoBusID) && NVAR_Exists(currentChannelID) && NVAR_Exists(currentComPortID) && NVAR_Exists(currentSerialNum) && SVAR_Exists(HardwareType_str))

Else
EPhysTelGrVar =0
EPhysHWVal[4] = ""
EPhysHWVal[5] = ""
EPhysHWVal[6] = ""
EPhysHWVal[7] = ""
EPhysHWVal[8] = ""
EndIf //If (EPhysTelGrVar)

End

Function pt_EPhysLockSettings(CheckBoxVarName, CheckBoxVarVal)  : CheckBoxControl
//Function pt_EPhysModeSelect(CheckBoxVarName)  : CheckBoxControl
String CheckBoxVarName
Variable CheckBoxVarVal

NVAR EPhysInstNum			=root:EPhysInstNum
//If (!StringMatch(button0, "TrigGen"))
	EPhysInstNum			= Str2Num(getuserdata("",CheckBoxVarName,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:EPhysVars"+Num2Str(EPhysInstNum)
String EPhysPanelName 		= "EPhysMain"+Num2Str(EPhysInstNum)

NVAR EPhysLockSetVar = $FldrName+":EPhysLockSetVar"

If (EPhysLockSetVar)
CheckBox EPhysTelGrVarName	, disable=2, win=$EPhysPanelName // disable Telegraph Button
Button EPhysHWEdit				, disable=2, win=$EPhysPanelName // disable Telegraph Button

Else
CheckBox EPhysTelGrVarName	, disable=0, win=$EPhysPanelName // disable Telegraph Button
Button EPhysHWEdit				, disable=0, win=$EPhysPanelName // disable Telegraph Button
EndIf


End

Function pt_EPhysPopSelect(PopupMenuVarName,PopupMenuVarNum,PopupMenuVarStr) : PopupMenuControl
//Function pt_EPhysPopSelect(PopupMenuVarName, PopupMenuVarStr) : PopupMenuControl
String PopupMenuVarName, PopupMenuVarStr
Variable PopupMenuVarNum

NVAR EPhysInstNum			=root:EPhysInstNum
//If (!StringMatch(button0, "TrigGen"))
	EPhysInstNum			= Str2Num(getuserdata("",PopupMenuVarName,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:EPhysVars"+Num2Str(EPhysInstNum)
//String EPhysPanelName 	= "EPhysMain"+Num2Str(EPhysInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////


SVAR OutWaveName = $FldrName+":EPhysOutWaveName"
SVAR InWaveName = $FldrName+":EPhysInWaveName"

StrSwitch (PopupMenuVarName)
	Case "EPhysOutWave" :
	OutWaveName = PopupMenuVarStr
	Break
	
	Case "EPhysInWave" :
	InWaveName = PopupMenuVarStr
	Break
	
EndSwitch

End

Function pt_EPhysHWEdit(ButtonVarName) :  ButtonControl
String ButtonVarName

NVAR EPhysInstNum			=root:EPhysInstNum
//If (!StringMatch(button2, "TrigGen"))
	EPhysInstNum			= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:EPhysVars"+Num2Str(EPhysInstNum)
//String EPhysPanelName 	= "EPhysMain"+Num2Str(EPhysInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

If (WaveExists($(FldrName+":EPhysHWName")) && WaveExists($(FldrName+":EPhysHWVal"))    )
Wave /T EPhysHWName =  	$(FldrName+":EPhysHWName")
Wave /T EPhysHWVal 	= 	$(FldrName+":EPhysHWVal")
Edit /K=1 EPhysHWName, EPhysHWVal
Else
Make /T/O/N=9 $(FldrName+":EPhysHWName")
Make /T/O/N=9 $(FldrName+":EPhysHWVal")
Wave /T EPhysHWName =  	$(FldrName+":EPhysHWName")
Wave /T EPhysHWVal 	= 	$(FldrName+":EPhysHWVal")

EPhysHWName[0] = "OutDevID"
EPhysHWName[1] = "InDevID"
EPhysHWName[2] = "OutChNum"
EPhysHWName[3] = "InChNum"
EPhysHWName[4] = "TelGrAxoBusID"		// HWVal = "" if not using telegraph
EPhysHWName[5] = "TelGrChID"			// HWVal = "" if not using telegraph
EPhysHWName[6] = "TelGrComPortID"		// HWVal = "" if not using telegraph
EPhysHWName[7] = "TelGrSerNum"		// HWVal = "" if not using telegraph
EPhysHWName[8] = "TelGrHWTypeStr"	// HWVal = "" if not using telegraph

//EPhysHWName[4] = "TrigSrc"		// value = "NoTrig" OR TriggerName like "/PFI4"

Edit /K=1 EPhysHWName, EPhysHWVal
EndIf

End

Function pt_EPhysNewCell(ButtonVarName) : ButtonControl
String ButtonVarName

NVAR EPhysInstNum			=root:EPhysInstNum
//If (!StringMatch(button3, "TrigGen"))
	EPhysInstNum			= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:EPhysVars"+Num2Str(EPhysInstNum)
//String EPhysPanelName 	= "EPhysMain"+Num2Str(EPhysInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

NVAR CellNum 		= $FldrName+":CellNum"
NVAR IterNum 		= $FldrName+":IterNum"

CellNum +=1		// increase cell # by 1
IterNum    =1		// set Iter # =1

End


Function pt_EPhysResetDev(ButtonVarName) : ButtonControl
String ButtonVarName

NVAR EPhysInstNum			=root:EPhysInstNum
//If (!StringMatch(button0, "TrigGen"))
	EPhysInstNum			= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:EPhysVars"+Num2Str(EPhysInstNum)
//String EPhysPanelName 	= "EPhysMain"+Num2Str(EPhysInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

String OutDevID = ""
String InDevID = ""

Wave /T EPhysHWName 	= $FldrName+":EPhysHWName"
Wave /T EPhysHWVal 	= $FldrName+":EPhysHWVal"

OutDevID 	= "Dev"+EPhysHWVal[0]
InDevID 		= "Dev"+EPhysHWVal[1]

fDAQmx_ResetDevice(OutDevID)
fDAQmx_ResetDevice(InDevID)

Print "-----------------------------------------------------------------------------"
Print "Reset OutDev", OutDevID, time(), "on", Date()
Print "Reset InDev", InDevID, time(), "on", Date()
Print "-----------------------------------------------------------------------------"

// Maybe we should also kill the background job
//Print "Killing background job"
//BackgroundInfo
//If (V_Flag!=0)
//KillBackGround
//EndIf

End

Function pt_EPhysInitialize(TrigGen)
String TrigGen

NVAR EPhysInstNum			=root:EPhysInstNum
//If (!StringMatch(button0, "TrigGen"))
//	EPhysInstNum			= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:EPhysVars"+Num2Str(EPhysInstNum)
//String EPhysPanelName 	= "EPhysMain"+Num2Str(EPhysInstNum)
String DelPntsWList = "", WNameStr, OldDf, WName, InitWList= ""
Variable i,N
/////////////////////////////////////////////////////////////////////////////
NVAR    DebugMode			= $FldrName+":DebugMode"
NVAR	EPhysRndOutWVar	= $FldrName+":EPhysRndOutWVar"

If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

// Check whether data already exists on the disk

PathInfo home
If (V_Flag==0)
	Abort "Please save the experiment first!"
EndIf
NewPath /Q/O HDSymbPath,  S_Path


SVAR InWaveBaseName	= $FldrName+":InWaveBaseName"
NVAR CellNum 			= $FldrName+":CellNum"
NVAR IterNum			= $FldrName+":IterNum"

NVAR IterTot = root:TrigGenVars:IterTot
NVAR IterLeft = root:TrigGenVars:IterLeft
NVAR RepsTot		= root:TrigGenVars:RepsTot
NVAR RepsLeft		= root:TrigGenVars:RepsLeft

String MatchStr = InWaveBaseName +pt_PadZeros2IntNumCopy(CellNum, 4)+"_"+pt_PadZeros2IntNumCopy(IterNum, 4)

If ((IterLeft == IterTot) && (RepsLeft == RepsTot))	// Do for 1st Iter of 1st Rep
If (pt_DataExistsCheck(MatchStr, "HDSymbPath")==1)
	String DoAlertPromptStr = MatchStr+" already exists on disk. Overwrite?"
	DoAlert 1, DoAlertPromptStr
	If (V_Flag==2)
		Abort "Aborting..."
	EndIf
EndIf
EndIf


Wave /T 		OutWaveNamesW = 	$FldrName+":OutWaveNamesW"
Duplicate /O OutWaveNamesW, 	$FldrName+":OutWaveNamesWCopy"
Wave /T		OutWaveNamesWCopy =  $FldrName+":OutWaveNamesWCopy"

If (EPhysRndOutWVar)	// Randomize out waves
	pt_RandomizeTextW(FldrName+":OutWaveNamesW",FldrName+":OutWaveNamesWCopy", NumPnts(OutWaveNamesW))
EndIf

Print OutWaveNamesWCopy

Wave /T 		InWaveNamesW = 	$FldrName+":InWaveNamesW"
Duplicate /O InWaveNamesW, 		$FldrName+":InWaveNamesWCopy"


sscanf FldrName+"In", "root:%s", WName

OldDf = GetDataFolder(1)
SetDataFolder $FldrName
DelPntsWList = WaveList(WName+"SR*", ";", "")
N = ItemsInList(DelPntsWList, ";")
For (i=0; i<N; i+=1)
WNameStr=StringFromList(i, DelPntsWList, ";")
DeletePoints 0,NumPnts($WNameStr), $WNameStr
EndFor

If (RepsLeft ==RepsTot) // 1st repeat
InitWList = WaveList(WName +"Sum*", ";", "")
N = ItemsInList(InitWList, ";")
For (i=0; i<N; i+=1)
WNameStr=StringFromList(i, InitWList, ";")
Wave SumW = $WNameStr
SumW = 0 // Initialize
EndFor
EndIf

SetDataFolder OldDf
pt_ClearSealTestW(FldrName)
pt_ClearFICurveW(FldrName)


End



Function pt_EPhysScan(ButtonVarName) : ButtonControl
String ButtonVarName

NVAR EPhysInstNum			=root:EPhysInstNum
If (StringMatch(ButtonVarName, "Button1"))
	EPhysInstNum			= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
EndIf
String FldrName 				= "root:EPhysVars"+Num2Str(EPhysInstNum)
String EPhysPanelName 	= "EPhysMain"+Num2Str(EPhysInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

Variable i
Variable 	OutDevID = Nan
Variable 	InDevID = Nan
Variable 	OutChNum = Nan
Variable	 InChNum = Nan
//String 	OutWaveListAll = ""
//String 	InWaveListAll = ""
String 	OutWaveStr, InWaveStr, WName

//String /G $FldrName+":OutWaveList" = ""
//String /G $FldrName+":InWaveList" = ""

//SVAR OutWaveList 	= $FldrName+":OutWaveList"
//SVAR InWaveList		= $FldrName+":InWaveList"

String OutWaveList 	= ""
String InWaveList 	= ""

//String /G		$FldrName+":InDevIdStr"
//String /G		$FldrName+":OutDevIdStr"

//SVAR		InDevIdStr 	= $FldrName+":InDevIdStr"
//SVAR		OutDevIdStr 	= $FldrName+":OutDevIdStr"

String InDevIdStr = ""
String OutDevIdStr = ""


SVAR OutWaveName = $FldrName+":EPhysOutWaveName"
SVAR InWaveName 	= $FldrName+":EPhysInWaveName"




NVAR EPhys_VClmp = $FldrName+":EPhys_VClmp"
NVAR EPhys_IClmp = $FldrName+":EPhys_IClmp"


NVAR EPhysOutGain_VClmp 	=$FldrName+":EPhysOutGain_VClmp"
NVAR EPhysInGain_VClmp 	=$FldrName+":EPhysInGain_VClmp"
NVAR EPhysOutGain_IClmp 	=$FldrName+":EPhysOutGain_IClmp"
NVAR EPhysInGain_IClmp 	=$FldrName+":EPhysInGain_IClmp"

NVAR 	EPhysOutGain 		= $FldrName+":EPhysOutGain" 
NVAR 	EPhysInGain			= $FldrName+":EPhysInGain"

NVAR EPhysOutWaveSlctVar	= $FldrName+":EPhysOutWaveSlctVar"
NVAR EPhysInWaveSlctVar 	= $FldrName+":EPhysInWaveSlctVar"

Wave /T EPhysHWName 		= $FldrName+":EPhysHWName"
Wave /T EPhysHWVal		= $FldrName+":EPhysHWVal"

NVAR EPhysTelGrVar = $FldrName+":EPhysTelGrVar"


If (EPhysTelGrVar)	// we are doing telegraph for this channel

NVAR currentAxoBusID= root:AxonTelegraphPanel:currentAxoBusID
NVAR currentChannelID = root:AxonTelegraphPanel:currentChannelID
NVAR currentComPortID = root:AxonTelegraphPanel:currentComPortID
NVAR currentSerialNum = root:AxonTelegraphPanel:currentSerialNum
SVAR HardwareType_str = root:AxonTelegraphPanel:HardwareType_str

NVAR /Z TelGr_currentlyMonitoring = root:AxonTelegraphPanel:currentlyMonitoring

//STRUCT WMButtonAction ba
//Variable ba

if (!NVAR_Exists(TelGr_currentlyMonitoring))
	AxonTelegraphPanel#Initialize()
	NVAR /Z TelGr_currentlyMonitoring = root:AxonTelegraphPanel:currentlyMonitoring
endif

If (!(NVAR_Exists(currentAxoBusID) && NVAR_Exists(currentChannelID) && NVAR_Exists(currentComPortID) && NVAR_Exists(currentSerialNum) && SVAR_Exists(HardwareType_str)))
Abort "Add the following line, \n #include \":More Extensions:Data Acquisition:AxonTelegraphMonitor\" \n to a procedure file"
EndIf
	
If (TelGr_currentlyMonitoring)	// stop monitoring if already monitoring
	
//	if (NVAR_Exists(TelGr_currentlyMonitoring))
				TelGr_currentlyMonitoring = !TelGr_currentlyMonitoring	// stop monitoring
				AxonTelegraphPanel#SetStartStopButtonTitle()
//				STRUCT WMBackgroundStruct s	
//				AxonTelegraphPanel#Background_monitoring(s)
//	endif

EndIf


// Save old vals
Variable currentAxoBusID_S 	= currentAxoBusID
Variable currentChannelID_S 	= currentChannelID
Variable currentComPortID_S	= currentComPortID
Variable currentSerialNum_S 	= currentSerialNum
String 	HardwareType_str_S	= HardwareType_str

currentAxoBusID		= Str2Num(EPhysHWVal[4])
currentChannelID 		= Str2Num(EPhysHWVal[5])
currentComPortID 	= Str2Num(EPhysHWVal[6])
currentSerialNum 	= Str2Num(EPhysHWVal[7])
HardwareType_str 	= 		    EPhysHWVal[8]


//	if (NVAR_Exists(TelGr_currentlyMonitoring))		// start monitoring
If (!TelGr_currentlyMonitoring)	// start monitoring if not already monitoring
		TelGr_currentlyMonitoring = !TelGr_currentlyMonitoring // start monitoring
		AxonTelegraphPanel#SetStartStopButtonTitle()
		STRUCT WMBackgroundStruct s	
		AxonTelegraphPanel#Background_monitoring(s)
endif
	
	
//	Print "Telegraph Status...", TelGr_currentlyMonitoring
//	CtrlNamedBackground axonTelegraph status
//	Print S_Info

	
//	if (NVAR_Exists(TelGr_currentlyMonitoring))
If (TelGr_currentlyMonitoring)	// stop monitoring if already monitoring
				TelGr_currentlyMonitoring = !TelGr_currentlyMonitoring	// stop monitoring
				AxonTelegraphPanel#SetStartStopButtonTitle()
//				STRUCT WMBackgroundStruct s	
//				AxonTelegraphPanel#Background_monitoring(s)
endif

DoWindow pnlAxonTelegraphPanel

If (!v_Flag)
Abort "The AxonTelegraphPanel doesn't exist. Please initialize from the menu Misc->AxonTelegraphPanel. \n\n Aborting. "
EndIF

Notebook pnlAxonTelegraphPanel#NBERROR getdata=2

If (StringMatch(S_Value, ""))

NVAR OperatingMode	= root:AxonTelegraphPanel:OperatingMode	// 0: V-clamp;1: I-clamp;2: I=0 mode 
NVAR Alpha			= root:AxonTelegraphPanel:Alpha
NVAR ScaleFactor	= root:AxonTelegraphPanel:ScaleFactor
NVAR ExtCmdSens	= root:AxonTelegraphPanel:ExtCmdSens

//NVAR 	= root:AxonTelegraphPanel:
//NVAR 	= root:AxonTelegraphPanel:
//NVAR 	= root:AxonTelegraphPanel:
//NVAR 	= root:AxonTelegraphPanel:
If (OperatingMode ==0)
EPhys_VClmp =1
EPhys_IClmp  =0

EPhysOutGain = ExtCmdSens			//	V/V 
EPhysInGain    = Alpha*ScaleFactor*1e9	//	V/A
Print "*************************************"
Print "Operating mode = Voltage Clamp"
Print "Outgain (V/V) =",EPhysOutGain
Print "Ingain (V/A) =",EPhysInGain
Print "*************************************"
EPhysOutGain_VClmp	= EPhysOutGain
EPhysInGain_VClmp		= EPhysInGain
Else
EPhys_VClmp =0
EPhys_IClmp  =1

EPhysOutGain = ExtCmdSens			//	A/V 
EPhysInGain    = Alpha*ScaleFactor	//	V/V
Print "*************************************"
Print "Operating mode = Current Clamp"
Print "Outgain (A/V) =",EPhysOutGain
Print "Ingain (V/V) =",EPhysInGain
Print "*************************************"
EPhysOutGain_IClmp		= EPhysOutGain
EPhysInGain_IClmp		= EPhysInGain
EndIf

Else
Abort S_Value+"\n\n ABORTING..."
EndIf 

//Print "Telegraph Status...", TelGr_currentlyMonitoring

	
//	AxonTelegraphPanel#Button_start_stop_monitoring(ba)		// Stop Monitoring

// Restore old vals	
currentAxoBusID		= currentAxoBusID_S
currentChannelID 		= currentChannelID_S
currentComPortID 	= currentComPortID_S
currentSerialNum 	= currentSerialNum_S
HardwareType_str 	= HardwareType_str_S

EndIf // we are doing telegraph for this channel	

// The checkbox doesn't update always (even with DoUpdate). Better to check the variable associated with checkbox
//ControlInfo /W=$EPhysPanelName EPhysVClmp
If (	(EPhys_VClmp ==1) && (EPhys_IClmp  ==0)	)
//Print V_Flag
//If (V_Value ==1)
EPhysOutGain_VClmp	= EPhysOutGain
EPhysInGain_VClmp		= EPhysInGain
ElseIf  (	(EPhys_VClmp ==0) && (EPhys_IClmp  ==1)	)
//ControlInfo /W=$EPhysPanelName EPhysIClmp
//If (V_Value == 1)
EPhysOutGain_IClmp		= EPhysOutGain
EPhysInGain_IClmp		= EPhysInGain
Else
Abort "Neither VClamp nor IClamp are selected!!"
EndIf

OutDevID 	 	= Str2Num(EPhysHWVal[0])
InDevID  			= Str2Num(EPhysHWVal[1])
OutChNum 		= Str2Num(EPhysHWVal[2])
InChNum 		= Str2Num(EPhysHWVal[3])	

OutDevIdStr = "Dev"+Num2Str(OutDevID)
InDevIdStr = "Dev"+Num2Str(InDevID)

Button button3, disable=0, win=$EPhysPanelName // Enable Reset Scan Button
Button button1, disable=2, win=$EPhysPanelName // disable Scan Button



If (StringMatch(ButtonVarName, "TrigGen"))
// copy output wave to root. copy DeviceName, Wavename, ChannelName to IODevNum, IOWName and IOChNum in root:TrigGenVars

// fresh copy of OutWaveNamesW is generated when TrigGen Starts. On each call the topmost wave corresponding to topmost wave name
// is copied to root folder. and if the number of points in OutWaveNamesWCopy>1, then the top most wavename is deleted, so that in the next
// call the wave corresponding to next wavename is copied to root folder.


Wave /T IODevFldrCopy 	= root:TrigGenVars:IODevFldrCopy
For (i=0; i<NumPnts(IODevFldrCopy); i+=1)
	If (StringMatch(IODevFldrCopy[i], FldrName))
	
	If (EPhysOutWaveSlctVar ==1)		// OutWave is selected for this channel
	Wave /T OutWaveNamesWCopy=$FldrName+":OutWaveNamesWCopy"
	Wave OutW = $(FldrName+":"+OutWaveNamesWCopy[0])
	Duplicate /O OutW, $(FldrName+":OutWScld")
	Wave OutWScld = $(FldrName+":OutWScld")
	// Scale appropriately for VClmp or IClmp
	OutWScld = (EPhys_VClmp==1) ? OutWScld/EPhysOutGain_VClmp : OutWScld/EPhysOutGain_IClmp
//	Duplicate /O OutWScld, $(FldrName+"Out")
	
	sscanf FldrName+"Out", "root:%s", WName
	Duplicate /O OutWScld, $(FldrName+":"+WName)		// for pt_EPhysDisplay()
	
	Make /T/O/N=1 $FldrName+":OutWaveToSave"		// Overwrite previous wave
	Wave /T OutWaveToSave = $FldrName+":OutWaveToSave"
	OutWaveToSave[0] = OutWaveNamesWCopy[0]		// for pt_EPhysSave()
	
	Wave /T IODevNum 	= root:TrigGenVars:IODevNum
	Wave /T IOChNum 	= root:TrigGenVars:IOChNum
	Wave /T IOWName 	= root:TrigGenVars:IOWName
	Wave /T IOEOSH 	= root:TrigGenVars:IOEOSH
	
//	Print "IODevNum, IOChNum, IOWName, IOEOSH",  IODevNum, IOChNum, IOWName, IOEOSH
	IODevNum[i]	= EPhysHWVal[0]
	IOChNum[i]	= EPhysHWVal[2]
	sscanf FldrName+"Out", "root:%s", WName
//	IOWName[i]	= WName					//OutWaveNamesWCopy[0]
	IOWName[i]	= FldrName+":"+WName

	If (EPhysInWaveSlctVar ==1)
	IOEOSH[i]	= ""			// no need to call pt_EPhysEOSH() if inwave is also going to call it
	Else
	IOEOSH[i]	= "pt_EPhysEOSH()"
	EndIf
//	Print "IODevNum, IOChNum, IOWName, IOEOSH",  IODevNum, IOChNum, IOWName, IOEOSH
	If (NumPnts(OutWaveNamesWCopy)>1)
		DeletePoints 0,1,OutWaveNamesWCopy
	Else
		Print "Warning! Sending the same wave in the next iteration as this iteration, as no more waves are left in OutWaveNamesWCopy"
	EndIf
	EndIf	// EndIf for  (If (EPhysOutWaveSlctVar ==1))
	
	If (EPhysInWaveSlctVar ==1)		// InWave is selected for this channel
// 	Save the details of output wave to disk. ToDo	
//	Randomize output waves if desired. ToDo

	If (EPhysOutWaveSlctVar ==1)	 // If OutWave is selected for this channel then InWave should match in dimension
//	Duplicate /O OutW, InW
//	InW = Nan
//	Duplicate /O InW, $(FldrName+"In")
	Duplicate /O OutW, $(FldrName+"In")
	sscanf FldrName+"In", "root:%s", WName
//	Duplicate /O InW, $(FldrName+":"+WName)		// for pt_EPhysDisplay()
	Duplicate /O OutW, $(FldrName+":"+WName)		// for pt_EPhysDisplay()
	Wave InW =	$(FldrName+":"+WName)
	InW = Nan
	Else		// No Output wave
	Wave /T InWaveNamesWCopy=$FldrName+":InWaveNamesWCopy"
	
// If no inwave, create one and scale later according to outwaves or inwaves on other channels
// If no other channels have outwaves or inwaves, abort and ask user to G inwave	
	If (NumPnts(InWaveNamesWCopy)==0)
	Make /O/N=0 $(FldrName+":"+"DummyEPhysW")
	Make /T/O/N=1 $(FldrName+":"+"InWaveNamesWCopy")	
	Wave /T InWaveNamesWCopy=$(FldrName+":InWaveNamesWCopy")	
	InWaveNamesWCopy[0] = "DummyEPhysW"
	EndIf
	
	Wave InW = $(FldrName+":"+InWaveNamesWCopy[0])
	InW = Nan
	//In Wave will be scaled after acquisition
	Duplicate /O InW, $(FldrName+"In")
	sscanf FldrName+"In", "root:%s", WName
	Duplicate /O InW, $(FldrName+":"+WName)		// for pt_EPhysDisplay()
	EndIf
	
	Wave /T IODevNum 	= root:TrigGenVars:IODevNum
	Wave /T IOChNum 	= root:TrigGenVars:IOChNum
	Wave /T IOWName 	= root:TrigGenVars:IOWName
	Wave /T IOEOSH 	= root:TrigGenVars:IOEOSH
	
	
	If (EPhysOutWaveSlctVar ==1)	
//		If (i==0)
 		InsertPoints /M=0 (NumPnts(IODevFldrCopy)+1),1, IODevFldrCopy , IODevNum, IOChNum, IOWName, IOEOSH
//		InsertPoints /M=0 (i+1),1, IODevFldrCopy , IODevNum, IOChNum, IOWName, IOEOSH
//		Else
//		InsertPoints /M=0 i,1, IODevNum, IOChNum, IOWName, IOEOSH
//		EndIf
		i = NumPnts(IODevFldrCopy)-1
		
	EndIf
	IODevFldrCopy[i] = FldrName
	IODevNum[i]	= EPhysHWVal[1]	
	IOChNum[i]	= EPhysHWVal[3]
	sscanf FldrName+"In", "root:%s", WName
//	IOWName[i]	= WName					//OutWaveNamesWCopy[0]
	IOWName[i]	= FldrName+":"+WName
	IOEOSH[i]	= "pt_EPhysEOSH()"			
	If (NumPnts(InWaveNamesWCopy)>1)
		DeletePoints 0,1,InWaveNamesWCopy
	Else
		Print "Warning! Sending the same wave in the next iteration as this iteration, as no more waves are left in InWaveNamesWCopy"
	EndIf
	
	EndIf   // EndIf for (If (EPhysInWaveSlctVar ==1)	)
	
	
//	Else		// Voltage out of range
//		Print "Laser voltage out of range in wave", OutWaveNamesWCopy[0], "for", FldrName,"VMax=", VMax, "VMin=0"
//		Abort "Aborting..."
//	EndIf
	If ( (EPhysOutWaveSlctVar ==0) && (EPhysInWaveSlctVar ==0) )
		String AbortErrStr = "No input/ output is selected for EPhys channel = "+Num2Str(EPhysInstNum)
		Abort AbortErrStr
		Button button1, disable=0, win=$EPhysPanelName // Enable Scan Button
		Button button3, disable=2, win=$EPhysPanelName // Disable Reset Scan Button
	EndIf
	Break
	EndIf
EndFor	
Else

// Check whether data already exists on the disk

PathInfo home
If (V_Flag==0)
	Abort "Please save the experiment first!"
EndIf
NewPath /Q/O HDSymbPath,  S_Path


SVAR InWaveBaseName	= $FldrName+":InWaveBaseName"
NVAR CellNum 			= $FldrName+":CellNum"
NVAR IterNum			= $FldrName+":IterNum"
String MatchStr = InWaveBaseName +pt_PadZeros2IntNumCopy(CellNum, 4)+"_"+pt_PadZeros2IntNumCopy(IterNum, 4)

If (pt_DataExistsCheck(MatchStr, "HDSymbPath")==1)
	String DoAlertPromptStr = MatchStr+" already exists on disk. Overwrite?"
	DoAlert 1, DoAlertPromptStr
	If (V_Flag==2)
		Abort "Aborting..."
	EndIf
EndIf

If (EPhysOutWaveSlctVar ==1)		// OutWave is selected for this channel
//ControlInfo /W=EPhysMain EPhysOutWave
//If (V_Flag == 3)
//OutWaveListAll = WaveList("Out_*", ";", "" )
//OutWaveName = StringFromList(V_Value, OutWaveListAll, ";")
Wave OutW = $(FldrName+":"+OutWaveName)
Duplicate /O OutW, $FldrName+":OutWScld"
Wave OutWScld = $FldrName+":OutWScld"
// Scale appropriately for VClmp or IClmp
OutWScld = (EPhys_VClmp==1) ? OutWScld/EPhysOutGain_VClmp : OutWScld/EPhysOutGain_IClmp
OutWaveList = FldrName+":"+"OutWScld,"+Num2Str(OutChNum)+";"
sscanf FldrName+"Out", "root:%s", WName
Duplicate /O OutW, $(FldrName+":"+WName)		// for pt_EPhysDisplay()

Make /T/O/N=1 $FldrName+":OutWaveToSave"		// Overwrite previous wave
Wave /T OutWaveToSave = $FldrName+":OutWaveToSave"
OutWaveToSave[0] = OutWaveName				// for pt_EPhysSave()

//Else
//Print "No OUT wave selected"
//EndIf
EndIf




sscanf FldrName+"In", "root:%s", WName


If (EPhysInWaveSlctVar ==1)		// InWave is selected for this channel

If (EPhysOutWaveSlctVar ==1)	 // If OutWave is selected for this channel then InWave should match in dimension
//Duplicate /O OutWScld, $FldrName+":InW"
Duplicate /O OutWScld, $(FldrName+":"+WName)
//Wave InW = $FldrName+":InW"
Wave InW = $(FldrName+":"+WName)
InW = Nan
//InWaveList = FldrName+":"+"InW,"+Num2Str(InChNum)+";"
InWaveList   = FldrName+":"+WName+","+Num2Str(InChNum)+";"

Else


Wave InW = $(FldrName+":"+InWaveName)
Duplicate /O InW, $(FldrName+":"+WName)
Wave InW = $(FldrName+":"+WName)
InW = Nan
//In Wave will be scaled after acquisition
//InWaveList = FldrName+":"+"InW,"+Num2Str(InChNum)+";"
InWaveList   = FldrName+":"+WName+","+Num2Str(InChNum)+";"
EndIf

//sscanf FldrName+"In", "root:%s", WName
//Duplicate /O InW, $(FldrName+":"+WName)		// for pt_EPhysDisplay()
EndIf


Print "Sending out waves", OutWaveList, "on Dev", OutDevID
Print "Reading in waves",   InWaveList, "on Dev", InDevID

Print "-------------------------------------------------------------------------------------------------------------------------------------------------------------------"
Print "Starting experiment at", time(), "on", Date()
Print "-------------------------------------------------------------------------------------------------------------------------------------------------------------------"


If (StrLen(OutWaveList)!=0)
//TrigSrcStr	= "/"+OutDevIdStr+(EPhysHWVal[4])
//If (StringMatch(EPhysHWVal[4], "NoTrig"))
//	TrigSrcStr = ""		// In case no trigger is specified, empty string causes scan to start without trigger
//EndIf
If (StrLen(InWaveList)!=0)		// If scanning an inwave then trigger the outwave using the inwave
String TrigSrcStrFull	=	"/"+	InDevIdStr+"/ai/StartTrigger"
DAQmx_WaveformGen /DEV= OutDevIdStr /NPRD=1/STRT=1/TRIG=TrigSrcStrFull							  OutWaveList
Else 
DAQmx_WaveformGen /DEV= OutDevIdStr /NPRD=1/STRT=1						/EOSH="pt_EPhysEOSH()" OutWaveList // EOSH for Out waves ToDo
EndIf
//ScanRunning	 	= 1		// If no EOSH for OUT waves who sets ScanRunning	 	= 0 ToDo
EndIf

If (StrLen(InWaveList)!=0)
//TrigSrcStr	= "/"+InDevIdStr+(EPhysHWVal[4])
//If (StringMatch(EPhysHWVal[4], "NoTrig"))
//	TrigSrcStr = ""		// In case no trigger is specified, empty string causes scan to start without trigger
//EndIf
//DAQmx_Scan /DEV= InDevIdStr /BKG /STRT=1/ERRH="pt_EPhysERRH()"			/EOSH="pt_EPhysEOSH()" Waves= InWaveList
DAQmx_Scan /DEV= InDevIdStr /BKG /STRT=1 								    /EOSH="pt_EPhysEOSH()" Waves= InWaveList
//ScanRunning	 	= 1
EndIf


If (StrLen(OutWaveList)==0 && StrLen(InWaveList)==0)
	Print "No input or output waves to scan on", FldrName
	Button button1, disable=0, win=$EPhysPanelName // Enable Scan Button
	Button button3, disable=2, win=$EPhysPanelName // Disable Reset Scan Button
EndIf

//String EPhysErr = fDAQmx_ErrorString()
//If (!StringMatch(EPhysErr,""))
//	Print EPhysErr
//	pt_EPhysERRH()
//EndIf



//SVAR EPhysErrStr = $FldrName+":EPhysErrStr"
//NVAR EPhysErrVal = $FldrName+":EPhysErrVal" 
//EPhysErrStr = ""
//EPhysErrVal = 0
//EPhysErrStr = fDAQmx_ErrorString()
//If (!StringMatch(EPhysErrStr,""))
//	Print EPhysErrStr
//	EPhysErrVal =1
//	pt_EPhysERRH()
//EndIf


//SetBackGround  pt_StartAcquisition("root:EPhysVars:OutDevIdStr", "root:EPhysVars:OutWaveList", "root:EPhysVars:InDevIdStr", "root:EPhysVars:InWaveList", "pt_EPhysEOSH()")
// somehow had problem passing parameters (OutDevIdStr, OutWaveList, InDevIdStr, InWaveList) through this function so passing through global variables
//SetBackGround  pt_EPhysStartAcquisition()		
//CtrlBackGround start, period = 1, NoBurst=0 // NoBurst = 1 implies don't try to catch-up if missed start time 
// check no burst condition ToDo

//pt_StartAcquisition() Use in case we want the job to run in the foreground
//EndOfExpt    	= 0	
//DoUpdate

//pt_EPhysEOSH()
EndIf
End

Function pt_EPhysResetScan(ButtonVarName) : ButtonControl
String ButtonVarName

NVAR EPhysInstNum			=root:EPhysInstNum
If (StringMatch(ButtonVarName, "Button3"))
	EPhysInstNum			= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
EndIf
String FldrName 			= "root:EPhysVars"+Num2Str(EPhysInstNum)
String EPhysPanelName 	= "EPhysMain"+Num2Str(EPhysInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

Button button1, disable=0, win=$EPhysPanelName // Re-enable Scan Button
Button button3, disable=2, win=$EPhysPanelName // Disable ResetScan Button
End

//Function pt_EPhysStartAcquisition()
// This function is no longer in use


//SVAR FldrName 		=root:EPhysFldrName
//SVAR EPhysPanelName =root:EPhysPanelName
//NVAR EPhysInstNum	=root:EPhysInstNum
//FldrName 				= "root:EPhysVars"+Num2Str(EPhysInstNum)
//EPhysPanelName 	= "EPhysMain"+Num2Str(EPhysInstNum)

//SVAR OutWaveList 	= $FldrName+":OutWaveList"
//SVAR InWaveList 	= $FldrName+":InWaveList"
//NVAR ScanRunning	 = $FldrName+":ScanRunning"

//Wave /T EPhysHWName 		= 	$FldrName+":EPhysHWName"
//Wave /T EPhysHWVal		=	$FldrName+":EPhysHWVal"


//String OutDevIdStr
//String InDevIdStr
//String TrigSrcStr


//Variable OutDevID = Nan
//Variable InDevID = Nan

//OutDevID 	= Str2Num(EPhysHWVal[0])
//InDevID  		= Str2Num(EPhysHWVal[1])
//TrigSrcStr 	= 		    EPhysHWVal[4]

//OutDevIdStr = "Dev"+Num2Str(OutDevID)
//InDevIdStr = "Dev"+Num2Str(InDevID)


//TrigSrc = "/"+DevIdStr+"/ai/starttrigger"
//Print TrigSrc
//BackGroundInfo
//Print "BackGroundInfo", V_Flag
//If (StrLen(OutWaveList)!=0)
//TrigSrcStr	= "/"+OutDevIdStr+(EPhysHWVal[4])
//If (StringMatch(EPhysHWVal[4], "NoTrig"))
//	TrigSrcStr = ""		// In case no trigger is specified, empty string causes scan to start without trigger
//EndIf
//DAQmx_WaveformGen /DEV= OutDevIdStr /NPRD=1/STRT=1/TRIG=TrigSrcStr /ERRH="pt_EPhysErrorHook()" OutWaveList // EOSH for Out waves ToDo
//ScanRunning	 	= 1		// If no EOSH for OUT waves who sets ScanRunning	 	= 0 ToDo
//EndIf
//If (StrLen(InWaveList)!=0)
//TrigSrcStr	= "/"+InDevIdStr+(EPhysHWVal[4])
//If (StringMatch(EPhysHWVal[4], "NoTrig"))
//	TrigSrcStr = ""		// In case no trigger is specified, empty string causes scan to start without trigger
//EndIf
//DAQmx_Scan /DEV= InDevIdStr /BKG /STRT=1/TRIG=TrigSrcStr /ERRH="pt_EPhysErrorHook()" /EOSH="pt_EPhysEOSH()" Waves= InWaveList
//ScanRunning	 	= 1
//EndIf
//Return 1
//End

Function pt_EPhysPreScanCheck()
// Check that 
// either v-clamp or i-clamp is selected
// check that either outwave or inwave or both are selected and the waves exist
// check that the waves are not of zero length
// check that the amplitude of outwave  is in the limits of the board
End

Function pt_EPhysEOSH()

NVAR EPhysInstNum			=root:EPhysInstNum
//If (!StringMatch(button0, "TrigGen"))
//	EPhysInstNum			= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:EPhysVars"+Num2Str(EPhysInstNum)
String EPhysPanelName 	= "EPhysMain"+Num2Str(EPhysInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////


//NVAR ScanRunning	 = $FldrName+":ScanRunning"
//SVAR InWaveList 	= root:EPhysVars:InWaveList
//SVAR InWaveName 	= $FldrName+":EPhysInWaveName"
NVAR EPhys_VClmp = $FldrName+":EPhys_VClmp"

NVAR EPhysInGain_VClmp 	=$FldrName+":EPhysInGain_VClmp"
NVAR EPhysInGain_IClmp 	=$FldrName+":EPhysInGain_IClmp"

NVAR EPhysInWaveSlctVar 	=$FldrName+":EPhysInWaveSlctVar"

String WName

Wave /T EPhysHWName 		= 	$FldrName+":EPhysHWName"
Wave /T EPhysHWVal		=	$FldrName+":EPhysHWVal"

//ScanRunning = 0

Button button1, disable=0, win=$EPhysPanelName // Enable Scan Button
Button button3, disable=2, win=$EPhysPanelName // Disable ResetScan Button

Print "EPhys end of scan hook triggered at t= ", time()//, "Iters. Over= ", TotIter-IterRemain


//NVAR ErrVal	= $FldrName+":EPhysErrVal"
//SVAR ErrStr	= $FldrName+":EPhysErrStr" 
//ErrStr = fDAQmx_ErrorString()
//Print "ErrStr="
//If ( (ErrVal==1) || (StringMatch(ErrStr, "")!=1))
//ErrStr ="" 
//ErrVal =0
//Return 0
//EndIf

// Analyze and save data
// Call function to scale incoming waves

If (EPhysInWaveSlctVar ==1)		// InWave is selected for this channel
//Wave InW = $"InW"
sscanf FldrName+"In", "root:%s", WName
Wave InW = $(FldrName+":"+WName)
//Duplicate /O InW, $(FldrName+":"+FldrName+"InScld")
//Wave InWScld = $(FldrName+":"+FldrName+"InScld")
//InWScld = (EPhys_VClmp==1) ? InWScld/EPhysInGain_VClmp : InWScld/EPhysInGain_IClmp	// scale Inwave with appropriate gain
InW = (EPhys_VClmp==1) ? InW/EPhysInGain_VClmp : InW/EPhysInGain_IClmp	// scale Inwave with appropriate gain
pt_EPhysAnalyze()
pt_EPhysDisplay()
pt_EPhysSave()
Else
pt_EPhysSave()		// we are not displaying outwaves for ephys
EndIf

//If (!StringMatch(EPhysHWVal[3], "NoTrig"))
//	Print "Waiting for next trigger..."
//	BackgroundInfo
//	Print V_Flag
//	KillBackground
//	BackgroundInfo
//	Print V_Flag
//	pt_EPhysScan("button1")	// if scan was started using a trigger then, set start scan again and wait for new trigger.
//EndIf

End


Function pt_EPhysERRH()

NVAR EPhysInstNum	 =root:EPhysInstNum
//If (!StringMatch(button0, "TrigGen"))
//	EPhysInstNum			= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:EPhysVars"+Num2Str(EPhysInstNum)
//String EPhysPanelName 	= "EPhysMain"+Num2Str(EPhysInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

//NVAR EPhysError 	= $FldrName+":EPhysError"
//	EPhysError = 1
	Print "*****************************************"
	Print "DataAcquisition Error in", FldrName
	Print "*****************************************"
//	pt_EPhysEOSH()
End

Function pt_EPhysSave()
// Save data to disk
Variable N,i
String OldDf, Str, InWaveToSaveAsFull, WName

NVAR EPhysInstNum			=root:EPhysInstNum
//If (!StringMatch(button0, "TrigGen"))
//	EPhysInstNum			= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:EPhysVars"+Num2Str(EPhysInstNum)
//String EPhysPanelName 	= "EPhysMain"+Num2Str(EPhysInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////


SVAR InWaveBaseName	= $FldrName+":InWaveBaseName"
NVAR CellNum 			= $FldrName+":CellNum"
NVAR IterNum 			= $FldrName+":IterNum"

NVAR EPhysInWaveSlctVar 	= $FldrName+":EPhysInWaveSlctVar"

OldDF = GetDataFolder(1)
SetDataFolder $FldrName

PathInfo home
If (V_Flag==0)
	Abort "Please save the experiment first!"
EndIf
NewPath /O DiskDFName,  S_Path
Print "Saving EPhys data to",S_Path

If (WaveExists($FldrName+":OutWaveToSave"))	// OutWave is selected for this channel

//SVAR SaveWaveList	= SaveWaveList
Wave /T OutWaveToSave = $FldrName+":OutWaveToSave"
//Wave /T InWaveToSave = $FldrName+":InWaveToSave"

//SaveData /Q/D=1/O/L=1  /P=DiskDFName /J =SaveWaveList InWaveToSaveAs+"_"+ Num2Str(IterNum)//T=$EncFName /P=SaveDF
N=NumPnts(OutWaveToSave)
For (i=0; i<N; i+=1)	// save outwaves
	sscanf FldrName, "root:%s", WName
	Str = WName+OutWaveToSave[0]
	If (!StringMatch("Out", OutWaveToSave[0])  )
	Duplicate /O $(FldrName+":"+WName+"Out"), $(Str)
	EndIf
	Save /C/O/P=DiskDFName  $(Str)//$OutWaveToSave[i]
EndFor
KillWaves /Z OutWaveToSave
KillWaves /Z $(Str)
Else
	Print "No EPhys OutWave to save!!"	// Out Wave doesn't exist
EndIf

If (EPhysInWaveSlctVar ==1)		// InWave is selected for this channel

sscanf FldrName+"In", "root:%s", WName
Wave  InWaveToSave  = $(FldrName+":"+WName)

Str = InWaveBaseName +pt_PadZeros2IntNumCopy(CellNum, 4)+"_"+pt_PadZeros2IntNumCopy(IterNum, 4)
Print "InWaveToSaveAs ", Str
//Duplicate /O $InWaveToSave[0], $(Str)
Duplicate /O InWaveToSave, $(Str)

//InWaveToSaveAsFull = InWaveToSaveAs+ Num2Str(IterNum)
//Duplicate /O EPhysVWave, $InWaveToSaveAsFull
Save /C/O/P=DiskDFName  $(Str) //as InWaveToSaveAsFull+".ibw"
KillWaves /Z $(Str)
IterNum +=1
Else
	Print "No EPhys InWave to save!"
EndIf

KillPath /Z DiskDFName
SetDataFolder OldDf
End

//=========
Function pt_EPhysAnalyze()
// Analyze SealTest, FI, etc. 
// Note: Using //// to comment statements not commented before. // are the statements that were commented already
Variable N,i,j
//String OldDf, Str, InWaveToSaveAsFull, WName
String OldDf, WName 
String WNoteStr = ""
Variable SealTestPresent =0

NVAR EPhysInstNum			=root:EPhysInstNum
//If (!StringMatch(button0, "TrigGen"))
//	EPhysInstNum			= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:EPhysVars"+Num2Str(EPhysInstNum)
//String EPhysPanelName 	= "EPhysMain"+Num2Str(EPhysInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////


////SVAR InWaveBaseName	= $FldrName+":InWaveBaseName"
////NVAR CellNum 			= $FldrName+":CellNum"
////NVAR IterNum 			= $FldrName+":IterNum"

NVAR EPhysInWaveSlctVar 	= $FldrName+":EPhysInWaveSlctVar"
NVAR EPhys_VClmp 				=$FldrName+":EPhys_VClmp"

OldDF = GetDataFolder(1)
SetDataFolder $FldrName


If (EPhysInWaveSlctVar ==1)		// InWave is selected for this channel

sscanf FldrName+"In", "root:%s", WName
//Wave  InWaveToSave  = $(FldrName+":"+WName)
WNoteStr = Note($WName)
SealTestPresent	= Str2Num(StringByKey("SealTestPresent",WNoteStr))
//ControlInfo /W=AnalyzeDataMain EPhysSealTestVarName
NVAR EPhysSealTestVarVal = root:AnalyzeDataVars:EPhysSealTestVarVal

If (EPhysSealTestVarVal && SealTestPresent)		// Carry out seal-test Analsis

String DataWaveMatchStr, DataFldrStr, tBaselineStart0, tBaselineEnd0, tSteadyStateStart0, tSteadyStateEnd0, SealTestAmp_V, SealTestAmp_I, tSealTestStart0
String tExp2FitStart0, tExp2FitEnd0, tExpFitStart0, tExpFitEnd0
String RsVWName, RInVWName, ImVWName, VmVWName
Variable SealTestAmp	, SealTestStartX, SealTestLength

If (EPhys_VClmp==1)	// VClamp

Wave /T AnalParW=$pt_GetParWave("pt_CalRsRinCmVmVClamp", "ParW")

//String DataWaveMatchStr, DataFldrStr, tBaselineStart0, tBaselineEnd0, tSteadyStateStart0, tSteadyStateEnd0, SealTestAmp_V, tSealTestStart0	

DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
tBaselineStart0			=    AnalParW[2]
tBaselineEnd0			=    AnalParW[3]
tSteadyStateStart0		=    AnalParW[4]
tSteadyStateEnd0		=    AnalParW[5]
SealTestAmp_V			=    AnalParW[6]
//SealTestAmp_I			=Str2Num(AnalParW[6])
////NumRepeat				=Str2Num(AnalParW[7])
////RepeatPeriod			=Str2Num(AnalParW[8])
//V_ClampTrue			=Str2Num(AnalParW[10])
//tExp1SteadyStateStart0		=Str2Num(AnalParW[9])
//tExp1SteadyStateEnd0		=Str2Num(AnalParW[10])
//tExp1FitStart0				=Str2Num(AnalParW[9])
//tExp1FitEnd0				=Str2Num(AnalParW[10])
//tExp2SteadyStateStart0		=Str2Num(AnalParW[13])
//tExp2SteadyStateEnd0		=Str2Num(AnalParW[14])
////tSealTestPeakWinDel			= Str2Num(AnalParW[9])
tExp2FitStart0				=AnalParW[10]
tExp2FitEnd0				=AnalParW[11]
// earlier tBaselineEnd0 was at start of seal test but then i moved it to before start of 
// seal test. but still kept using tBaselineEnd0 to extrapolate the exp. to 
// get amplitude at start of seal test. that is wrong. therefore separating tSealTestStart0. bug reported by kiran   // Feb.28th 2008 Praveen
														
tSealTestStart0			=   AnalParW[12]
////AlertMessages			= Str2Num(AnalParW[13])	


WNoteStr = Note($WName)
SealTestAmp	= Str2Num(StringByKey("SealTestAmp(V)",WNoteStr))
SealTestStartX	= Str2Num(StringByKey("SealTestStartX(s)",WNoteStr))
SealTestLength	= Str2Num(StringByKey("SealTestLength(s)",WNoteStr))


//NVAR SealTestAmp 		=$"root:WaveGenVars:SealTestVClampAmp"	
//NVAR SealTestStartX		=$"root:WaveGenVars:SealTestStartX"
//NVAR SealTestLength		=$"root:WaveGenVars:SealTestLength"

AnalParW[0]  = WName +"*"
AnalParW[1]  = ""
AnalParW[2]  = Num2Str(SealTestStartX - 15e-3)
AnalParW[3]  = Num2Str(SealTestStartX -   5e-3)
AnalParW[4]  = Num2Str(SealTestStartX + SealTestLength - 15e-3)
AnalParW[5]  = Num2Str(SealTestStartX + SealTestLength -  5e-3)
AnalParW[6]  = Num2Str(SealTestAmp)
AnalParW[10]= Num2Str(SealTestStartX +  1e-3)
AnalParW[11]= Num2Str(SealTestStartX + 10e-3)
AnalParW[12]= Num2Str(SealTestStartX)


pt_CalRsRinCmVmVClamp()

//String RsVWName
sscanf FldrName+"RsV", "root:%s", RsVWName
If (WaveExists($(RsVWName)))
Wave RsVW = $(RsVWName)
Concatenate /NP {RsV}, RsVW
Else
Make /O/N=0 $(RsVWName)
Wave RsVW = $(RsVWName)
Concatenate /NP {RsV}, RsVW
EndIf

//String RInVWName
sscanf FldrName+"RInV", "root:%s", RInVWName
If (WaveExists($(RInVWName)))
Wave RInVW = $(RInVWName)
Concatenate /NP {RInV}, RInVW
Else
Make /O/N=0 $(RInVWName)
Wave RInVW = $(RInVWName)
Concatenate /NP {RInV}, RInVW
EndIf


//String ImVWName
sscanf FldrName+"ImV", "root:%s", ImVWName
If (WaveExists($(ImVWName)))
Wave ImVW = $(ImVWName)
Concatenate /NP {ImV}, ImVW
Else
Make /O/N=0 $(ImVWName)
Wave ImVW = $(ImVWName)
Concatenate /NP {ImV}, ImVW
EndIf


AnalParW[0]  = DataWaveMatchStr
AnalParW[1]  = DataFldrStr	
AnalParW[2]  = tBaselineStart0
AnalParW[3]  = tBaselineEnd0
AnalParW[4]  = tSteadyStateStart0
AnalParW[5]  = tSteadyStateEnd0
AnalParW[6]  = SealTestAmp_V
AnalParW[10]	= 	tExp2FitStart0
AnalParW[11]	=	tExp2FitEnd0
AnalParW[12]= tSealTestStart0

Else		// IClamp

Wave /T AnalParW=$pt_GetParWave("pt_CalRsRinCmVmIClamp", "ParW")

//String DataWaveMatchStr, DataFldrStr, tBaselineStart0, tBaselineEnd0, tSteadyStateStart0, tSteadyStateEnd0, SealTestAmp_I, tSealTestStart0	

DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
tBaselineStart0			=	AnalParW[2]
tBaselineEnd0			=	AnalParW[3]
tSteadyStateStart0		=	AnalParW[4]
tSteadyStateEnd0		=	AnalParW[5]
SealTestAmp_I			=	AnalParW[6]
//NumRepeat				=Str2Num(AnalParW[7])
//RepeatPeriod			=Str2Num(AnalParW[8])
//tExpSteadyStateStart0	=Str2Num(AnalParW[9])
//tExpSteadyStateEnd0		=Str2Num(AnalParW[10])
tExpFitStart0				=	AnalParW[9]
tExpFitEnd0				=	AnalParW[10]

// earlier tBaselineEnd0 was at start of seal test but then i moved it to before start of 
// seal test. but still kept using tBaselineEnd0 to extrapolate the exp. to 
// get amplitude at start of seal test. that is wrong. therefore separating tSealTestStart0. bug reported by kiran   // Feb.28th 2008 Praveen
														
tSealTestStart0			=	AnalParW[11]	
//AlertMessages			= Str2Num(AnalParW[12])


WNoteStr = Note($WName)
SealTestAmp	= Str2Num(StringByKey("SealTestAmp(A)",WNoteStr))
SealTestStartX	= Str2Num(StringByKey("SealTestStartX(s)",WNoteStr))
SealTestLength	= Str2Num(StringByKey("SealTestLength(s)",WNoteStr))

//NVAR SealTestAmp 	=$"root:WaveGenVars:SealTestIClampAmp"	
//NVAR SealTestStartX	=$"root:WaveGenVars:SealTestStartX"
//NVAR SealTestLength	=$"root:WaveGenVars:SealTestLength"

AnalParW[0]  = WName +"*"
AnalParW[1]  = ""
AnalParW[2]  = Num2Str(SealTestStartX - 15e-3)
AnalParW[3]  = Num2Str(SealTestStartX -   5e-3)
AnalParW[4]  = Num2Str(SealTestStartX + SealTestLength - 15e-3)
AnalParW[5]  = Num2Str(SealTestStartX + SealTestLength -  5e-3)
AnalParW[6]  = Num2Str(SealTestAmp)
AnalParW[9]	 =Num2Str(SealTestStartX + 5e-3)
AnalParW[10]=Num2Str(SealTestStartX + 50e-3)
AnalParW[11]= Num2Str(SealTestStartX)


pt_CalRsRinCmVmIClamp()

//String RsVWName
sscanf FldrName+"RsV", "root:%s", RsVWName
If (WaveExists($(RsVWName)))
Wave RsVW = $(RsVWName)
Concatenate /NP {RsV}, RsVW
Else
Make /O/N=0 $(RsVWName)
Wave RsVW = $(RsVWName)
Concatenate /NP {RsV}, RsVW
EndIf

//String RInVWName
sscanf FldrName+"RInV", "root:%s", RInVWName
If (WaveExists($(RInVWName)))
Wave RInVW = $(RInVWName)
Concatenate /NP {RInV}, RInVW
Else
Make /O/N=0 $(RInVWName)
Wave RInVW = $(RInVWName)
Concatenate /NP {RInV}, RInVW
EndIf


//String VmVWName
sscanf FldrName+"VmV", "root:%s", VmVWName
If (WaveExists($(VmVWName)))
Wave VmVW = $(VmVWName)
Concatenate /NP {VmV}, VmVW
Else
Make /O/N=0 $(VmVWName)
Wave ImVW = $(VmVWName)
Concatenate /NP {VmV}, VmVW
EndIf


AnalParW[0]  = DataWaveMatchStr
AnalParW[1]  = DataFldrStr	
AnalParW[2]  = tBaselineStart0
AnalParW[3]  = tBaselineEnd0
AnalParW[4]  = tSteadyStateStart0
AnalParW[5]  = tSteadyStateEnd0
AnalParW[6]  = SealTestAmp_I
AnalParW[9]	 =	tExpFitStart0	
AnalParW[10]=	tExpFitEnd0	
AnalParW[11]= tSealTestStart0
EndIf
EndIf	// End seal-test Analsis

//ControlInfo /W=AnalyzeDataMain EPhysFICurveVarVal
NVAR EPhysFICurveVarVal = root:AnalyzeDataVars:EPhysFICurveVarVal
If (EPhysFICurveVarVal && EPhys_VClmp==0)		// FI Analysis checked in Analyze Data and we are in current clamp so carry out FI Curve Analsis

String FIDataWaveMatchStr, FIDataFldrStr, FIStartX, FIEndX, BaseNameStr		// Using Suffix FI as some of the strings exist already
String FIFreqVWName, FICurrVWName


Wave /T AnalParW=$pt_GetParWave("pt_SpikeAnal", "ParW")

FIDataWaveMatchStr			= AnalParW[0]
FIDataFldrStr					= AnalParW[1]
FIStartX						= AnalParW[2]
FIEndX						= AnalParW[3]
//SpikeAmpAbsThresh		= AnalParW[4]
//SpikeAmpRelativeThresh		= AnalParW[5]
//SpikePolarity				= AnalParW[6]
//BoxSmoothingPnts			= AnalParW[7]
//RefractoryPeriod			= AnalParW[8]
//SpikeThreshWin				= AnalParW[9]
//SpikeThreshDerivLevel		= AnalParW[10]
//BLPreDelT					= AnalParW[11]
//FIWNamesW				= AnalParW[12]
//FICurrWave					= AnalParW[13]
BaseNameStr				= AnalParW[14]
//FracToPeak				= AnalParW[15]
//EndOfPulseAHPDelT		= AnalParW[16]
//PrePlsBLDelT				= AnalParW[17]
//AlertMessages				= AnalParW[18]
//SpikeThreshDblDeriv			= AnalParW[19]
//ISVDelT					= AnalParW[20]

WNoteStr = Note($WName)
Variable T0 			= Str2Num(StringByKey("StepStart(s)",WNoteStr))
Variable DelT 		= Str2Num(StringByKey("Width",WNoteStr))
Variable StimAmp 	= Str2Num(StringByKey("Stim Amp.",WNoteStr))

Variable T1 = T0 + DelT
AnalParW[0]  = WName +"*"
AnalParW[1]  = ""
AnalParW[2]  = Num2Str(T0)
AnalParW[3]  = Num2Str(T1)
AnalParW[14] = "FIAnal"

pt_SpikeAnal()

Wave FIFreqV = $("FIAnalWNumSpikes")
FIFreqV /= DelT //pt_SpikeAnal calculates number of spikes. Converting it to Freq

Make /O/N	=1 FICurrV = Nan
FICurrV 		= StimAmp

//String FIFreqVWName	// Make new FIFreq and FICurr waves if they don't exist
sscanf FldrName+"FIFreqVW", "root:%s", FIFreqVWName
sscanf FldrName+"FICurrVW", "root:%s", FICurrVWName

If (WaveExists($(FIFreqVWName)) && WaveExists($(FICurrVWName)))
Wave FIFreqVW = $(FIFreqVWName)
Concatenate /NP {FIFreqV}, FIFreqVW
Wave FICurrVW = $(FICurrVWName)
Concatenate /NP {FICurrV}, FICurrVW
Else
Make /O/N=0 $(FIFreqVWName)
Wave FIFreqVW = $(FIFreqVWName)
Concatenate /NP {FIFreqV}, FIFreqVW

Make /O/N=0 $(FICurrVWName)
Wave FICurrVW = $(FICurrVWName)
Concatenate /NP {FICurrV}, FICurrVW

EndIf

AnalParW[0]			=FIDataWaveMatchStr
AnalParW[2]			=FIStartX						
AnalParW[3]			=FIEndX						
//SpikeAmpAbsThresh			= AnalParW[4]
//SpikeAmpRelativeThresh		= AnalParW[5]
//SpikePolarity					= AnalParW[6]
//BoxSmoothingPnts			= AnalParW[7]
//RefractoryPeriod				= AnalParW[8]
//SpikeThreshWin				= AnalParW[9]
//SpikeThreshDerivLevel			= AnalParW[10]
//BLPreDelT					= AnalParW[11]
//AnalParW[12]		=FIWNamesW
//AnalParW[13]		=FICurrWave
AnalParW[14]		=BaseNameStr				
//FracToPeak					= AnalParW[15]
//EndOfPulseAHPDelT			= AnalParW[16]
//PrePlsBLDelT				= AnalParW[17]
//AlertMessages				= AnalParW[18]
//SpikeThreshDblDeriv			= AnalParW[19]
//ISVDelT						= AnalParW[20]

pt_KillWaves("FIAnal*", FldrName)
KillWaves /Z FICurrV
EndIf 			// End FI Curve Analsis

//String CalSynRespOldDf = GetDataFolder(1)
//SetDataFolder $AnalParFolder

NVAR EPhysSynRespVarVal = root:AnalyzeDataVars:EPhysSynRespVarVal

If (EPhysSynRespVarVal)		// SynResp Analysis checked in Analyze Data
//If (EPhys_VClmp==1)	// VClamp
Wave /T AnalParW		=	$pt_GetParWave("pt_CalSynResp", "ParW")		// check in local folder first 07/23/2007



// Save

//String PkWinStart0, PkWinDel, BLDel, AvgWin
//String ThreshVal, RepDelT, SmthPnts, PkPolr, 
String PkWinStart0List
Variable NStepsPerStim, BLDel, StepsPerStimDelT

DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
BaseNameStr			=	AnalParW[2]
//PkWinStart0List			=	AnalParW[3]
//PkWinDel				=	AnalParW[4]
//BLDel					=	Str2Num(AnalParW[5])
//AvgWin				=	AnalParW[6]
//ThreshVal				=	AnalParW[7]
//NStepsPerStim			=	Str2Num(AnalParW[8])
//StepsPerStimDelT		=	Str2Num(AnalParW[9])
//SmthPnts				=	AnalParW[10]
//PkPolr					=	AnalParW[11]


// Change

//Duplicate /O $(WName), $(WName)
NVAR IterTot 		= root:TrigGenVars:IterTot
NVAR IterLeft 		= root:TrigGenVars:IterLeft
NVAR RepsTot		= root:TrigGenVars:RepsTot
NVAR RepsLeft		= root:TrigGenVars:RepsLeft

NVAR EPhysSRAvgReps 		= root:AnalyzeDataVars:EPhysSRAvgReps

//Duplicate /O /R=(PkWinStart0-BLDel, PkWinStart0+NStepsPerStim*StepsPerStimDelT) $WName,  $WName +pt_PadZeros2IntNumCopy(IterTot-IterLeft, 4)
Duplicate /O $WName,  $WName +pt_PadZeros2IntNumCopy(IterTot-IterLeft, 4)

Wave w = $WName +pt_PadZeros2IntNumCopy(IterTot-IterLeft, 4)
If (EPhysSRAvgReps)
Wave SumW = $WName +"Sum"+pt_PadZeros2IntNumCopy(IterTot-IterLeft, 4)

//If (  RepsLeft ==RepsTot-1 && (WaveExists(SumW))	   )// 1st repeat
//SumW = 0 // Initialize
//EndIf

If (WaveExists(SumW))
SumW +=w
Else
Duplicate w,  $WName +"Sum"+pt_PadZeros2IntNumCopy(IterTot-IterLeft, 4)
Wave SumW = $WName +"Sum"+pt_PadZeros2IntNumCopy(IterTot-IterLeft, 4)
EndIf
w = SumW/(RepsTot-RepsLeft) 
EndIf

AnalParW[0]								= WName +pt_PadZeros2IntNumCopy(IterTot-IterLeft, 4)
AnalParW[1]								= ""
AnalParW[2]								= "SR"
//AnalParW[3]							= SRBLStart
//AnalParW[4]							= SRBLEnd
//AnalParW[5]							= SRPeakWinStart
//AnalParW[6]							= SRPeakWinEnd
//AnalParW[7]							= SRAvgWin
//AnalParW[8]							= SRSteadyStateStart
//AnalParW[9]							= SRSteadyStateEnd
//AnalParW[10]							= SRPeakPolarity
//AnalParW[11]							= SRSmoothPnts
//AnalParW[12]							= SDTimes


//Variable SRBLStart = Str2Num(AnalParW[3])	
//Variable SRBLEnd  =  Str2Num(AnalParW[4])	
//Variable SRPeakPolarity = Str2Num(AnalParW[10])
//Variable SRTimesSD = Str2Num(AnalParW[12])
//String CalSynRespOldDf = GetDataFolder(1)
//SetDataFolder $AnalParFolder
pt_CalSynResp()
//SetDataFolder OldDf

For (j=0; j<NStepsPerStim; j+=1)

Wave SRRelPkYV			=	$("SR"+Num2Str(j)+"RelPkY")

//String SRRelPkYVWName
String SRRelPkYVWName

Print WName+"SR"+Num2Str(j)+"RelPkYV"
sscanf WName+"SR"+Num2Str(j)+"RelPkYV", "%s", SRRelPkYVWName
If (WaveExists($(SRRelPkYVWName)))
Wave SRRelPkYVW = $(SRRelPkYVWName)
Concatenate /NP {SRRelPkYV}, SRRelPkYVW
Else
Make /O/N=0 $(SRRelPkYVWName)
Wave SRRelPkYVW = $(SRRelPkYVWName)
Concatenate /NP {SRRelPkYV}, SRRelPkYVW
EndIf

Wave SRBolnV			=	$("SR"+Num2Str(j)+"Boln")

//String SRBolnVWName
String SRBolnVWName
sscanf WName+"SR"+Num2Str(j)+"BolnV", "%s", SRBolnVWName
If (WaveExists($(SRBolnVWName)))
Wave SRBolnVW = $(SRBolnVWName)
Concatenate /NP {SRBolnV}, SRBolnVW
Else
Make /O/N=0 $(SRBolnVWName)
Wave SRBolnVW = $(SRBolnVWName)
Concatenate /NP {SRBolnV}, SRBolnVW
EndIf

EndFor

NVAR IterLeft 		= root:TrigGenVars:IterLeft
NVAR StopExpt		= root:TrigGenVars:StopExpt

If (	(IterLeft*RepsLeft <=0) || (StopExpt==1)	)

NVAR EPhysSROWRespVarVal 		= root:AnalyzeDataVars:EPhysSROWRespVarVal

If (EPhysSROWRespVarVal)

	DoWindow /F SavedSynRespEdit
	If	(!V_Flag)
	Edit /K=1
	DoWindow /C/F SavedSynRespEdit
	EndIf
	
//	Edit /K=1
//	DoWindow /C SavedSynRespEdit

	sscanf WName+"SR"+Num2Str(0)+"BolnV", "%s", SRBolnVWName
	If (WaveExists($(SRBolnVWName)))
	Wave SRBolnVW = $(SRBolnVWName)
	Duplicate /O SRBolnVW, 		$SRBolnVWName+"Saved"
	AppendToTable $SRBolnVWName+"Saved"
	EndIf

	sscanf WName+"SR"+Num2Str(0)+"RelPkYV", "%s", SRRelPkYVWName
	If (WaveExists($(SRRelPkYVWName)))
	Wave SRRelPkYVW = $(SRRelPkYVWName)
	Duplicate /O SRRelPkYVW, $SRRelPkYVWName+"Saved"
	AppendToTable $SRRelPkYVWName+"Saved"
	EndIf



String SRBolnSavedVWName
//Variable i, N
Wave /T IOWName			=root:TrigGenVars:IOWName
Wave /T IODevFldrCopy		=root:TrigGenVars:IODevFldrCopy




If (WaveExists(IOWName) && WaveExists(IODevFldrCopy))
N = NumPnts(IOWName)
//OldDf=GetDataFolder(1)
//SetDataFolder root:TrigGenVars
For (i=0; i<N;i+=1)

//	If (StringMatch(IOWName[i], "EPhysVars*In"))
//	sscanf IODevFldrCopy[i]+"SR"+Num2Str(0)+"BolnVSaved", "root:%s", SRBolnSavedVWName
//	Wave SRBolnVWLastSaved = $(IODevFldrCopy[i]+":"+SRBolnVWLastSaved)
//	If (WaveExists(SRBolnSavedVWName))
//	AppendToTable SRBolnSavedVWName
//	Else
//	Make /T/O/N=0 $SRBolnSavedVWName
//	AppendToTable SRBolnSavedVWName
//	EndIf
//	EndIf

//	If (StringMatch(IOWName[i], "EPhysVars*In"))
//	sscanf IODevFldrCopy[i]+"SR"+Num2Str(0)+"BolnVSaved", "root:%s", SRBolnSavedVWName
//	Wave SRBolnVWLastSaved = $(IODevFldrCopy[i]+":"+SRBolnVWLastSaved)
//	If (WaveExists(SRBolnSavedVWName))
//	AppendToTable SRBolnSavedVWName
//	Else
//	Make /T/O/N=0 $SRBolnSavedVWName
//	AppendToTable SRBolnSavedVWName
//	EndIf
//	EndIf
	
EndFor

EndIf //If (WaveExists(IOWName) && WaveExists(IODevFldrCopy))
EndIf //If (EPhysSROWRespVarVal)
EndIf //If (	(IterLeft <=0) || (StopExpt==1)	)

////String SynRespExistsVWName
//String SynRespExistsVWName
//sscanf FldrName+"SynRespExistsV", "root:%s", SynRespExistsVWName
//If (WaveExists($(SynRespExistsVWName)))
//Wave SynRespExistsVW = $(SynRespExistsVWName)
//Concatenate /NP {SynRespExistsV}, SynRespExistsVW
//Else
//Make /O/N=0 $(SynRespExistsVWName)
//Wave SynRespExistsVW = $(SynRespExistsVWName)
//Concatenate /NP {SynRespExistsV}, SynRespExistsVW
//EndIf

////String SynRespExistsTempVWName
//String SynRespExistsTempVWName
//sscanf FldrName+"SynRespExistsTempV", "root:%s", SynRespExistsTempVWName
//If (WaveExists($(SynRespExistsTempVWName)))
//Wave SynRespExistsTempVW = $(SynRespExistsTempVWName)
////Concatenate /NP {SynRespExistsTempV}, SynRespExistsTempVW
//Else
//Make /O/N=1 $(SynRespExistsTempVWName)
//Wave SynRespExistsTempVW = $(SynRespExistsTempVWName)
////Concatenate /NP {SynRespExistsTempV}, SynRespExistsTempVW
//EndIf


//WaveStats /Q/R=(SRBLStart,SRBLEnd) $WName

//If (SRPeakPolarity ==1)
//SynRespExistsTempVW[0] = (SRRelYV[0] >= V_Avg+SRTimesSD*V_SDev) ? 1 : 0
//Else
//SynRespExistsTempVW[0] = (SRRelYV[0] <= V_Avg-SRTimesSD*V_SDev) ? 1 : 0
//EndIf

//Concatenate /NP {SynRespExistsTempVW}, SynRespExistsVW

// Restore
AnalParW[0]								= DataWaveMatchStr
AnalParW[1]								= DataFldrStr
AnalParW[2]								= BaseNameStr
//AnalParW[3] 							= PkWinStart0 
//AnalParW[4] 							=  PkWinDel 
//AnalParW[5] 							=  BLDel 
//AnalParW[6] 							=  AvgWin 
//AnalParW[7] 							=  ThreshVal 
//AnalParW[8] 							=  NStepsPerStim 
//AnalParW[9] 							=  StepsPerStimDelT 
//AnalParW[10] 							=  SmthPnts 
//AnalParW[11] 							=  PkPolr 


//Else // IClamp
//EndIf
KillWaves /Z SRBLX, SRBLY
For (j=0; j<NStepsPerStim; j+=1)
KillWaves /Z $("SR"+Num2Str(j)+"PkX")
KillWaves /Z $("SR"+Num2Str(j)+"AbsPkY")
KillWaves /Z $("SR"+Num2Str(j)+"RelPkY")
KillWaves /Z $("SR"+Num2Str(j)+"Boln")
EndFor

EndIf // End Synaptic Response Analsis

EndIf

KillPath /Z DiskDFName
SetDataFolder OldDf
End

Function pt_KillWaves(MatchStr, FldrName)
String MatchStr, FldrName
String OldDf, KillWavesList, WNameStr
Variable i,N

OldDF = GetDataFolder(1)
SetDataFolder $FldrName

KillWavesList = Wavelist(MatchStr,";","" )
N = ItemsInList(KillWavesList, ";")
For (i=0; i<N; i+=1)
WNameStr=StringFromList(i, KillWavesList, ";")
KillWaves /Z $WNameStr
EndFor
End

Function pt_ClearSealTestW(FldrName)
String FldrName

String WName

sscanf FldrName+"RsV", "root:%s", WName
Print FldrName+":"+WName
If (WaveExists($(FldrName+":"+WName)))
Wave w = $(FldrName+":"+WName)
DeletePoints 0,NumPnts(w), w
EndIf

sscanf FldrName+"RInV", "root:%s", WName
If (WaveExists($(FldrName+":"+WName)))
Wave w = $(FldrName+":"+WName)
DeletePoints 0,NumPnts(w), w
EndIf

sscanf FldrName+"ImV", "root:%s", WName
If (WaveExists($(FldrName+":"+WName)))
Wave w = $(FldrName+":"+WName)
DeletePoints 0,NumPnts(w), w
EndIf

sscanf FldrName+"VmV", "root:%s", WName
If (WaveExists($(FldrName+":"+WName)))
Wave w = $(FldrName+":"+WName)
DeletePoints 0,NumPnts(w), w
EndIf

End


Function pt_ClearFICurveW(FldrName)
String FldrName

String WName


sscanf FldrName+"FIFreqVW", "root:%s", WName
Print FldrName+":"+WName
If (WaveExists($(FldrName+":"+WName)))
Wave w = $(FldrName+":"+WName)
DeletePoints 0,NumPnts(w), w
EndIf

sscanf FldrName+"FICurrVW", "root:%s", WName
Print FldrName+":"+WName
If (WaveExists($(FldrName+":"+WName)))
Wave w = $(FldrName+":"+WName)
DeletePoints 0,NumPnts(w), w
EndIf

End


//=========

Function pt_CalRsRinCmVmVClamp()
// modified from pt_CalRsRinCmVmVClamp() from PraveensIgorUtilities (06/16/2010)

// curvefitting exponential is difficult for the falling phase of series-resistance transient as it's very fast and only has 2-3 points before
// it gives rise to slower decay due to membrane RIn and Cm. So just for the amplitude of series resistance transient i am switching to
// finding minimum or maximum using wavestats. //07/14/2008

// incorporating display of measurements on seal test. also instead of using pt_ExpFit() using funcfit to fit exponential. one advantage is that it can also
// fit the steady state value. 07/14/2008  (already changed for current clamp on 05/20/2008)
 // incorporated alert message for baseline window, and tExpSteadyState changes 07_14_2008 (already changed for current clamp on 05/13/2008)
 
 
// earlier tBaselineEnd0 was at start of seal test but then i moved it to before start of 
// seal test. but still kept using tBaselineEnd0 to extrapolate the exp. to 
// get amplitude at start of seal test. that is wrong. therefore separating tSealTestStart0. bug reported by kiran   // Feb.28th 2008 Praveen
// pt_GetParWave  will find local or global version of par wave  07/24/2007
// corrected print message 							 07/23/2007
// praveen: corrected i-clamp to v-clamp in print message 06/13/2007
// removed ":" after DataFldrStr 04/23/2009
String DataWaveMatchStr, DataFldrStr, WList, WNameStr
Variable Numwaves, i 
Variable tBaselineStart0,tBaselineEnd0,tSealTestStart0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V, NumRepeat,RepeatPeriod, Rs, Rin, Cm, Im, Tau
//Variable tExp1SteadyStateStart0, tExp1SteadyStateEnd0, tExp1FitStart0, tExp1FitEnd0, tExp2SteadyStateStart0, tExp2SteadyStateEnd0, tExp2FitStart0, tExp2FitEnd0		
Variable tSealTestPeakWinDel, tExp2FitStart0, tExp2FitEnd0		
String LastUpdatedMM_DD_YYYY="07_14_2008"
Variable AlertMessages
String /G CurrentRsRinCmImWName // 07/14/2008


Print "*********************************************************"
// Print "pt_SpikeAnal last updated on", LastUpdatedMM_DD_YYYY
Print "pt_CalRsRinCmVmVClamp last updated on", LastUpdatedMM_DD_YYYY	// corrected print message  07/23/2007
Print "*********************************************************"

Wave /T AnalParW=$pt_GetParWave("pt_CalRsRinCmVmVClamp", "ParW")			// pt_GetParWave  will find local or global version of par wave  07/24/2007

//If ( WaveExists($"pt_CalRsRinCmVmVClamp"+"ParNamesW") && WaveExists($("pt_CalRsRinCmVmVClamp"+"ParW") ) )

//Wave /T AnalParNamesW	=	$"pt_CalRsRinCmVmVClamp"+"ParNamesW"
//Wave /T AnalParW		=	$"pt_CalRsRinCmVmVClamp"+"ParW"
//Print "***Found pt_CalRsRinCmVmVClampParW in", GetDataFolder(-1), "***"

//ElseIf ( WaveExists($"root:FuncParWaves:pt_CalRsRinCmVmVClamp"+"ParNamesW") && WaveExists($"root:FuncParWaves:pt_CalRsRinCmVmVClamp"+"ParW") )

//Wave /T AnalParNamesW	=	$"root:FuncParWaves:pt_CalRsRinCmVmVClamp"+"ParNamesW"
//Wave /T AnalParW		=	$"root:FuncParWaves:pt_CalRsRinCmVmVClamp"+"ParW"

//Else

//	Abort	"Cudn't find the parameter waves  pt_CalRsRinCmVmVClampParW and/or pt_CalRsRinCmVmVClampParNamesW!!!"

//EndIf


DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
tBaselineStart0			=Str2Num(AnalParW[2])
tBaselineEnd0			=Str2Num(AnalParW[3])
tSteadyStateStart0		=Str2Num(AnalParW[4])
tSteadyStateEnd0		=Str2Num(AnalParW[5])
SealTestAmp_V			=Str2Num(AnalParW[6])
//SealTestAmp_I			=Str2Num(AnalParW[6])
NumRepeat				=Str2Num(AnalParW[7])
RepeatPeriod			=Str2Num(AnalParW[8])
//V_ClampTrue			=Str2Num(AnalParW[10])
//tExp1SteadyStateStart0		=Str2Num(AnalParW[9])
//tExp1SteadyStateEnd0		=Str2Num(AnalParW[10])
//tExp1FitStart0				=Str2Num(AnalParW[9])
//tExp1FitEnd0				=Str2Num(AnalParW[10])
//tExp2SteadyStateStart0		=Str2Num(AnalParW[13])
//tExp2SteadyStateEnd0		=Str2Num(AnalParW[14])
tSealTestPeakWinDel			= Str2Num(AnalParW[9])
tExp2FitStart0				=Str2Num(AnalParW[10])
tExp2FitEnd0				=Str2Num(AnalParW[11])
// earlier tBaselineEnd0 was at start of seal test but then i moved it to before start of 
// seal test. but still kept using tBaselineEnd0 to extrapolate the exp. to 
// get amplitude at start of seal test. that is wrong. therefore separating tSealTestStart0. bug reported by kiran   // Feb.28th 2008 Praveen
														
tSealTestStart0				=Str2Num(AnalParW[12])	
AlertMessages			= Str2Num(AnalParW[13])	
														
PrintAnalPar("pt_CalRsRinCmVmVClamp")

If (AlertMessages)    // incorporated alert message for baseline window, and tExpSteadyState changes 07_14_2008
//	DoAlert 1, "Recent changes: baseline window shifted; tExpSteadyState changed CONTINUE?"
	DoAlert 1, "Recent changes: wavestats for Rs transient, using curvefit, baseline window shifted, CONTINUE?"
	If (V_Flag==2)
		Abort "Aborting..."
	EndIf
EndIf


Make /O/N=0  RsV, RinV, CmV, ImV, TauV
Make /O/N=1  RsVTemp, RinVTemp, CmVTemp, ImVTemp, TauVTemp

RsVTemp	= Nan
RinVTemp	= Nan
CmVTemp	= Nan
ImVTemp	= Nan
TauVTemp	= Nan


WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1)+DataFldrStr)
Numwaves=ItemsInList(WList, ";")

//Print "Calculating RsRinCmVm in I-clamp for waves, N =", ItemsInList(WList, ";"), WList		praveen: corrected i-clamp to v-clamp in print message 06/13/2007
Print "Calculating RsRinCmVm in V-clamp for waves, N =", ItemsInList(WList, ";"), WList


For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")
	CurrentRsRinCmImWName = WNameStr			// 07/14/2008
//	Duplicate /O $(GetDataFolder(-1)+DataFldrStr+":"+WNameStr), w				// removed ":" after DataFldrStr 04/23/2009
	Duplicate /O $(GetDataFolder(-1)+DataFldrStr+WNameStr), w
//	If (V_ClampTrue)
//		pt_RsRinCmVclamp(w,tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V,NumRepeat,RepeatPeriod, tExpSteadyStateStart0, tExpSteadyStateEnd0, Rs,Rin,Cm)
//		pt_RsRinCmVmVclamp2(w,tBaselineStart0,tBaselineEnd0,tSealTestStart0, tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V,NumRepeat,RepeatPeriod, tExp1SteadyStateStart0, tExp1SteadyStateEnd0, tExp1FitStart0, tExp1FitEnd0, tExp2SteadyStateStart0, tExp2SteadyStateEnd0, tExp2FitStart0, tExp2FitEnd0, Rs,Rin,Cm, Im, Tau)  
		pt_CalRsRinCmVmVClamp2(w,tBaselineStart0,tBaselineEnd0,tSealTestStart0,  tSealTestPeakWinDel, tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V,NumRepeat,RepeatPeriod, tExp2FitStart0, tExp2FitEnd0, Rs,Rin,Cm, Im, Tau)  
//	Else
//		pt_RsRinCmIclamp(w,tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_I,NumRepeat,RepeatPeriod, Rs,Rin,Cm)	
//		pt_RsRinCmVmIclamp1(w,tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_I,NumRepeat,RepeatPeriod, tExpSteadyStateStart0, tExpSteadyStateEnd0, tExpFitStart0, tExpFitEnd0, Rs,Rin,Cm, Vm, Tau)  

//	EndIf
	
	RsVTemp=Rs; RinVTemp=Rin; CmVTemp=Cm; ImVTemp=Im; TauVTemp=Tau
	Concatenate /NP {RsVTemp}, 	RsV
	Concatenate /NP {RinVTemp},	RinV
	Concatenate /NP {CmVTemp}, 	CmV
	Concatenate /NP {ImVTemp}, 	ImV
	Concatenate /NP {TauVTemp}, TauV
EndFor

KillWaves RsVTemp, RinVTemp, CmVTemp, ImVTemp, TauVTemp, w

End

//==========================================================
Function pt_CalRsRinCmVmIClamp()
// modified from pt_CalRsRinCmVmIClamp() from PraveensIgorUtilities (06/26/2010)

// incorporating display of measurements on seal test. also instead of using pt_ExpFit() using funcfit to fit exponential. one advantage is that it can also
// fit the steady state value. 05/20/2008

 // incorporated alert message for baseline window, and tExpSteadyState changes 05_13_2008
// earlier tBaselineEnd0 was at start of seal test but then i moved it to before start of 
// seal test. but still kept using tBaselineEnd0 to extrapolate the exp. to 
// get amplitude at start of seal test. that is wrong. therefore separating tSealTestStart0. bug reported by kiran   // Feb.28th 2008 Praveen
// pt_GetParWave  will find local or global version of par wave  07/24/2007
// corrected print message  07/23/2007
// removed ":" after DataFldrStr 04/23/2009
String DataWaveMatchStr, DataFldrStr, WList, WNameStr
Variable Numwaves, i 
Variable tBaselineStart0,tBaselineEnd0,tSealTestStart0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_I, NumRepeat,RepeatPeriod, Rs, Rin, Cm, Vm, Tau, tExpFitStart0, tExpFitEnd0	
String LastUpdatedMM_DD_YYYY="02_28_2008"
Variable AlertMessages
String /G CurrentRsRinCmVmWName // 05/22/2008

Print "*********************************************************"
//Print "pt_SpikeAnal last updated on", LastUpdatedMM_DD_YYYY
Print "pt_CalRsRinCmVmIClamp last updated on", LastUpdatedMM_DD_YYYY					// corrected print message  07/23/2007
Print "*********************************************************"


Wave /T AnalParW=$pt_GetParWave("pt_CalRsRinCmVmIClamp", "ParW")			// pt_GetParWave  will find local or global version of par wave  07/24/2007


//If ( WaveExists($"pt_CalRsRinCmVmIClamp"+"ParNamesW") && WaveExists($("pt_CalRsRinCmVmIClamp"+"ParW") ) )

//Wave /T AnalParNamesW	=	$"pt_CalRsRinCmVmIClamp"+"ParNamesW"
//Wave /T AnalParW		=	$"pt_CalRsRinCmVmIClamp"+"ParW"
//Print "***Found pt_CalRsRinCmVmIClampParW in", GetDataFolder(-1), "***"

//ElseIf ( WaveExists($"root:FuncParWaves:pt_CalRsRinCmVmIClamp"+"ParNamesW") && WaveExists($"root:FuncParWaves:pt_CalRsRinCmVmIClamp"+"ParW") )

//Wave /T AnalParNamesW	=	$"root:FuncParWaves:pt_CalRsRinCmVmIClamp"+"ParNamesW"
//Wave /T AnalParW		=	$"root:FuncParWaves:pt_CalRsRinCmVmIClamp"+"ParW"

//Else

//	Abort	"Cudn't find the parameter waves  pt_CalRsRinCmVmIClampParW and/or pt_CalRsRinCmVmIClampParNamesW!!!"

//EndIf


DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
tBaselineStart0			=Str2Num(AnalParW[2])
tBaselineEnd0			=Str2Num(AnalParW[3])
tSteadyStateStart0		=Str2Num(AnalParW[4])
tSteadyStateEnd0		=Str2Num(AnalParW[5])
SealTestAmp_I			=Str2Num(AnalParW[6])
NumRepeat				=Str2Num(AnalParW[7])
RepeatPeriod			=Str2Num(AnalParW[8])
//tExpSteadyStateStart0	=Str2Num(AnalParW[9])
//tExpSteadyStateEnd0		=Str2Num(AnalParW[10])
tExpFitStart0				=Str2Num(AnalParW[9])
tExpFitEnd0				=Str2Num(AnalParW[10])

// earlier tBaselineEnd0 was at start of seal test but then i moved it to before start of 
// seal test. but still kept using tBaselineEnd0 to extrapolate the exp. to 
// get amplitude at start of seal test. that is wrong. therefore separating tSealTestStart0. bug reported by kiran   // Feb.28th 2008 Praveen
														
tSealTestStart0			=Str2Num(AnalParW[11])		
AlertMessages			= Str2Num(AnalParW[12])


PrintAnalPar("pt_CalRsRinCmVmIClamp")
//Print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
//Print "Calculating Rs+Rin instead of the more accurate Rin!!!"
//Print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"

If (AlertMessages)    // incorporated alert message for baseline window, and tExpSteadyState changes 05_13_2008
//	DoAlert 1, "Recent changes: baseline window shifted; tExpSteadyState changed CONTINUE?"
	DoAlert 1, "Recent changes: baseline window shifted; using cuvefit, CONTINUE?"
	If (V_Flag==2)
		Abort "Aborting..."
	EndIf
EndIf

Make /O/N=0  RsV, RinV, CmV, VmV, TauV
Make /O/N=1  RsVTemp, RinVTemp, CmVTemp, VmVTemp, TauVTemp

RsVTemp	= Nan
RinVTemp	= Nan
CmVTemp	= Nan
VmVTemp	= Nan
TauVTemp	= Nan


WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1)+DataFldrStr)
Numwaves=ItemsInList(WList, ";")

Print "Calculating RsRinCmVm in I-clamp for waves, N =", ItemsInList(WList, ";"), WList

For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")
	CurrentRsRinCmVmWName = WNameStr			// 05/22/2008
//	Duplicate /O $(GetDataFolder(-1)+DataFldrStr+":"+WNameStr), w			// removed ":" after DataFldrStr 04/23/2009
	Duplicate /O $(GetDataFolder(-1)+DataFldrStr+WNameStr), w
//	If (V_ClampTrue)
//		pt_RsRinCmVclamp(w,tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V,NumRepeat,RepeatPeriod, tExpSteadyStateStart0, tExpSteadyStateEnd0, Rs,Rin,Cm)
//		pt_RsRinCmVmIclamp1(w,tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V,NumRepeat,RepeatPeriod, tExpSteadyStateStart0, tExpSteadyStateEnd0, tExpFitStart0, tExpFitEnd0, Rs,Rin,Cm, Vm, Tau)  

//	Else
//		pt_RsRinCmIclamp(w,tBaselineStart0,tBaselineEnd0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_I,NumRepeat,RepeatPeriod, Rs,Rin,Cm)	
		pt_RsRinCmVmIclamp2(w,tBaselineStart0,tBaselineEnd0,tSealTestStart0, tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_I,NumRepeat,RepeatPeriod, tExpFitStart0, tExpFitEnd0, Rs,Rin,Cm, Vm, Tau)  

//	EndIf
	
	RsVTemp=Rs; RinVTemp=Rin; CmVTemp=Cm; VmVTemp=Vm; TauVTemp=Tau
	Concatenate /NP {RsVTemp}, 	RsV
	Concatenate /NP {RinVTemp},	RinV
	Concatenate /NP {CmVTemp}, 	CmV
	Concatenate /NP {VmVTemp}, 	VmV
	Concatenate /NP {TauVTemp}, TauV
EndFor

KillWaves RsVTemp, RinVTemp, CmVTemp, VmVTemp, TauVTemp, w

End

//==========================================================
Function pt_RsRinCmVmIclamp2(w,tBaselineStart0, tBaselineEnd0,tSealTestStart0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_I,NumRepeat,RepeatPeriod, tExpFitStart0, tExpFitEnd0, Rs,Rin,Cm, Vm, Tau)
//******************************************************************************
//******************************************************************************
// Set DisplayResults =0 to not display the actual fitting
// //switching from nA to A. Remember to do this when duplicating with a new version of seal test analysis
// Also setting bit 2 of V_FitOptions (suppress CurveFit info window)
// V_FitError =0 to suppress abortion of fit on error
// Also can set V_FitQuitReason (0 = normal termination; 1= iter limit reached; 2 = user stopped fit
//					     3 = limit of passes without decreasing chi-sq reached)
// modified from pt_RsRinCmVmIClamp2() from PraveensIgorUtilities (06/26/2010)
//******************************************************************************
//******************************************************************************


//  if weird value then it should not be used in further calculations (like RIn). 
// Therefore set =Nan.   Earlier weird value of tempRs was getting  used in further calculations		11_02_2008. 
// calculation of RsRinCm in I-clamp		(good for I-Clamp)
// changes in pt_RsRinCmVmIclamp1 to get pt_RsRinCmVmIclamp2
//  incorporating display of measurements on seal test. also instead of using pt_ExpFit() using funcfit to fit exponential. 
//one advantage is that it can also fit the steady state value. plus it will make the seal test stand alone program. 05/20/2008. 


//     changes in RsRinCmIclamp to get pt_RsRinCmVmIclamp1
// 1. the steady state of exponential is not necessarily same as steady state at end of seal test (eg. some voltage and time dependent conductance (eg. Ih) 
//	can change during later part of the seal test). so calculate the steady state of exponential early on (WorkVar3). so use WorkVar3 instead of WorkVar2 
//	for fitting of exponential and calculation of Rs, Cm.
// 2. even for current clamp the time-constant Tau is given by Req*Cm (where Req=Rs*Rin/(Rs+Rin)), just like in V-clamp. However, for good current
//	clamp Rs >> Rin. eventhough, we usually have Rs << Rin, the amp. somehow? realizes the Rs>>Rin so that Tau=Rin*Cm. 
// 3. also output Vm, as we are calculating it anyway.
// 4. also changed the tBaselineEnd0 to 0.0499 s instead of 0.05 s. earlier it was off by 0.1 ms which was causing a small error. correspondingly, 
//	exponential fit starts later. 
// 5. to distinguish the new analysis, the output waves are RsV, RinV, CmV, VmV, TauV instead of RsW, RinW, CmW, VmW, TauV.

variable tBaselineStart0,tBaselineEnd0,tSealTestStart0,tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_I,NumRepeat,RepeatPeriod, tExpFitStart0, tExpFitEnd0,  &Rs,&Rin,&Cm, &Vm, &Tau
wave w
variable i, WorkVar1,WorkVar2,amp,t0,y1, WorkVar3,	negativeWorkVar3,SumRs,SumRin,SumCm, SumVm, SumTau, TempRs,TempRin,TempCm, TempVm, TempTau, TempNumRs, TempNumRin,TempNumCm, TempNumVm, TempNumTau			
variable tBaselineStart, tBaselineEnd, tSealTestStart,tSteadyStateStart, tSteadyStateEnd, tExpFitStart, tExpFitEnd, DisplayResults
SVAR CurrentRsRinCmVmWName=CurrentRsRinCmVmWName

	i=0; 
	WorkVar1=0; WorkVar2=0; WorkVar3=0; 
	amp=0; t0=0; y1=0; 
	SumRs=0; SumRin=0; SumCm=0; SumVm=0; SumTau=0
	Rs=0; Rin=0; Cm=0; Vm=0; Tau=0
	TempRs=0; TempRin=0; TempCm=0; TempVm=0; TempTau=0
	TempNumRs=0; TempNumRin=0; TempNumCm=0; TempNumVm=0; TempNumTau=0
	tBaselineStart=0;tBaselineEnd=0;
	tSealTestStart=0
	tSteadyStateStart=0;tSteadyStateEnd=0
//	tExpSteadyStateStart=0; tExpSteadyStateEnd=0
	tExpFitStart=0; tExpFitEnd=0

	
	duplicate /o w,w1
	Rs=Nan; Rin=Nan; Cm=Nan; Vm=Nan; Tau=Nan		//if calculation gives weird values (basically, cos the curve has an odd shape), then return NaN

//	if (SealTestAmp_I<0)		05_20_2008
//		w1 *= -1
//	endif
	
	For  (i=0;i<NumRepeat;i+=1)	


	tBaselineStart = tBaselineStart0 + i*RepeatPeriod
	tBaselineEnd  = tBaselineEnd0  + i*RepeatPeriod
	WorkVar1 = mean(w1,tBaselineStart,tBaselineEnd)									// WorkVar1 --> Baseline V_m before sealtest [V]
	
	
	tSealTestStart = tSealTestStart0 + i*RepeatPeriod

	
	tExpFitStart	=tExpFitStart0	+ i*RepeatPeriod								//finally this values should be input by user thru the interface.
	tExpFitEnd	=tExpFitEnd0	+ i*RepeatPeriod
	
	tSteadyStateStart = tSteadyStateStart0 + i*RepeatPeriod
	tSteadyStateEnd = tSteadyStateEnd0   +  i*RepeatPeriod
	WorkVar2 = mean(w1,tSteadyStateStart,tSteadyStateEnd)									// WorkVar2 --> V_m at peak value of sealtest [V]
	
//	tExpSteadyStateStart	=	tExpSteadyStateStart0	+	i*RepeatPeriod			05_20_2008
//	tExpSteadyStateEnd  =	tExpSteadyStateEnd0		+	i*RepeatPeriod
//	WorkVar3			=	mean(w1,tExpSteadyStateStart,tExpSteadyStateEnd)	
	
// 	Equation to fit V(t)=V(Inf)+(V(0)-V(Inf))*exp(-t/(Req*C))			
// 	V(t) = voltage across Rs + Rin (or Cm) 
//	Tau=Req*C where Req=Rs*Rin/(Rs+Rin). under good current clamp effectively Rs>> Rin. so that Req=Rin.  	
//	duplicate /o w1, negativeW1													05_20_2008
//	negativeW1=-w1
//	negativeWorkVar3=-WorkVar3
//	pt_expfit(negativeW1,negativeWorkVar3, tExpFitStart, tExpFitEnd, amp, t0) 05_20_2008

Make /D/O/N=3 W_FitCoeff = Nan
Duplicate /O  w1, fit_w1
fit_w1= Nan

Variable V_FitOptions=4  // (suppress CurveFit info window)
Variable V_FitError=0      // (suppress abortion of fit on error)
CurveFit /NTHR=0/TBOX=0/Q exp_XOffset,  kwCWave=W_FitCoeff, w1 (tExpFitStart, tExpFitEnd) /D = fit_w1

WorkVar3	= W_FitCoeff[0]
amp 		= W_FitCoeff[1]
//t0			= W_FitCoeff[3]
t0			= W_FitCoeff[2]   // corrected on 04/19/11 eventhough it doesn't cause an error

If (		(NumType(W_FitCoeff[0])!=0) || (NumType(W_FitCoeff[1])!=0) || (NumType(W_FitCoeff[2])!=0)		)
	Print "																			"
	Print "Fitting error: y0, A, Tau =", WorkVar3, amp,t0, "in", CurrentRsRinCmVmWName
EndIf

// earlier tBaselineEnd0 was at start of seal test but then i moved it to before start of 
// seal test. but still kept using tBaselineEnd0 to extrapolate the exp. to 
// get amplitude at start of seal test. that is wrong. therefore separating tSealTestStart0. bug reported by kiran   // Feb.28th 2008 Praveen	
	
	
//	y1=WorkVar3-amp*exp(-tBaselineEnd/t0)
//	y1=WorkVar3-amp*exp(-tSealTestStart/t0) 05_20_2008
	y1=WorkVar3+amp*exp(-(tSealTestStart- tExpFitStart)/t0)

	
DisplayResults=0
If (DisplayResults)
Display
DoWindow pt_RsRinCmVmIclamp2Display
	If (V_Flag)
		DoWindow /F pt_RsRinCmVmIclamp2Display
//		Sleep 00:00:01
		DoWindow /K pt_RsRinCmVmIclamp2Display
	EndIf
DoWindow /c pt_RsRinCmVmIclamp2Display
	
		AppendToGraph /W=pt_RsRinCmVmIclamp2Display w1, fit_w1
		SetAxis Bottom tBaselineStart, tSteadyStateEnd0
		SetAxis /A=2 Left 
		SetDrawEnv textxjust= 2,textyjust= 2, fsize=08;DelayUpdate
		DrawText 1,0,CurrentRsRinCmVmWName
		ModifyGraph rgb(fit_w1)=(0,0,0)
		ModifyGraph lsize(fit_w1)=2
//		Cursor A w1 0.5*(tBaselineStart+tBaselineEnd), WorkVar1
//		Cursor A w1 WorkVar2, WorkVar1
		Make /O/N=1 RsRinCmVmBLW, RsRinCmVmSSW, RsRinCmVmExpPkW
		Make /O/N=1 RsRinCmVmBLWX, RsRinCmVmSSWX, RsRinCmVmExpPkWX
		RsRinCmVmBLWX		= 0.5*(tBaselineStart+tBaselineEnd)
		RsRinCmVmBLW		= WorkVar1
		
		RsRinCmVmSSWX		= 0.5*(tSteadyStateStart+tSteadyStateEnd)
		RsRinCmVmSSW		= WorkVar2
		
		RsRinCmVmExpPkWX	= tSealTestStart
		RsRinCmVmExpPkW		= y1
		
		AppendToGraph /W=pt_RsRinCmVmIclamp2Display RsRinCmVmBLW		vs RsRinCmVmBLWX
		ModifyGraph mode(RsRinCmVmBLW)=3
		ModifyGraph marker(RsRinCmVmBLW)=19
		ModifyGraph rgb(RsRinCmVmBLW)=(0,15872,65280)
		
		AppendToGraph /W=pt_RsRinCmVmIclamp2Display RsRinCmVmSSW		vs RsRinCmVmSSWX
		ModifyGraph mode(RsRinCmVmSSW)=3
		ModifyGraph marker(RsRinCmVmSSW	)=16
		ModifyGraph rgb(RsRinCmVmSSW)=(0,15872,65280)
		
		AppendToGraph /W=pt_RsRinCmVmIclamp2Display RsRinCmVmExpPkW	vs RsRinCmVmExpPkWX
		ModifyGraph mode(RsRinCmVmExpPkW)=3
		ModifyGraph marker(RsRinCmVmExpPkW)=17
		ModifyGraph rgb(RsRinCmVmExpPkW)=(0,15872,65280)
		
		Legend/C/N=text0/J/F=0/A=RC "\\Z08\\s(RsRinCmVmBLW) BaseLineW\r\\s(RsRinCmVmSSW) SteadyState\r\\s(RsRinCmVmExpPkW) RsTransient"
		DoUpdate
		Sleep /T 30
		
//DoWindow pt_RsRinCmVmIclamp2Display				05_20_2008
//	If (V_Flag)
//		DoWindow /F pt_RsRinCmVmIclamp2Display
//		Sleep 00:00:02
//		DoWindow /K pt_RsRinCmVmIclamp2Display
//	EndIf

EndIf	
	
	
//	TempRs=(y1-WorkVar1)/(abs(SealTestAmp_I)*1e-9)   					05_20_2008
//	TempRs=(y1-WorkVar1)/(     (SealTestAmp_I)*1e-9)					
	TempRs=(y1-WorkVar1)/      (SealTestAmp_I)						//switching from nA to A
	If (numtype(TempRs)==0 && TempRs>0 && TempRs<100e6) 			// weird values shud be avoided...cause probs in data processing later
	SumRs+=TempRs
	TempNumRs+=1
	Else															
//  if weird value then it should not be used in further calculations (like RIn). 
// Therefore set =Nan.   Earlier weird value of tempRs was getting  used in further calculations		11_02_2008. 
	TempRs = Nan																			
	Endif
	
//	TempRin=((WorkVar2-WorkVar1)/(abs(SealTestAmp_I)*1e-9))-TempRs  //05_20_2008
//	TempRin=((WorkVar2-WorkVar1)/(     (SealTestAmp_I)*1e-9))-TempRs
	TempRin=((WorkVar2-WorkVar1)/      (SealTestAmp_I))-TempRs		//switching from nA to A
	If (numtype(TempRin)==0 && TempRin>0 && TempRin<1500e6) 	     // weird values shud be avoided...cause probs in data processing later
	SumRin+=TempRin
	TempNumRin+=1
	Endif
	
//	TempCm =t0/(TempRs*TempRin/(TempRs+TempRin))							In general
//	TempCm=t0/TempRin														// under good I clamp the circuit behaves " as if " Rs>>Rin
//	TempCm=t0/ ( ((WorkVar3-WorkVar1)/(abs(SealTestAmp_I)*1e-9))-TempRs )  	//05_20_2008	// under good I clamp the circuit behaves " as if " Rs>>Rin
//	TempCm=t0/ ( ((WorkVar3-WorkVar1)/(     (SealTestAmp_I)*1e-9))-TempRs ) 
	TempCm=t0/ ( ((WorkVar3-WorkVar1)/      (SealTestAmp_I))-TempRs )		//switching from nA to A
	If (numtype(TempCm)==0 && TempCm>0 && TempCm<1500e-12) 	   			// weird values shud be avoided...cause probs in data processing later
	SumCm+=TempCm
	TempNumCm+=1
	Endif
	
//	TempVm = SealTestAmp_I<0  ? -WorkVar1 : WorkVar1			//05_20_2008
	TempVm = WorkVar1
	If (numtype(TempVm)==0 && TempVm>-200e-3 && TempVm<+200e-3) 	    // weird values shud be avoided...cause probs in data processing later
	SumVm+=TempVm
	TempNumVm+=1
	Endif
	
	TempTau = t0
	If (numtype(TempTau)==0 && TempTau>0 && TempTau<100e-3) 	    // weird values shud be avoided...cause probs in data processing later
	SumTau+=TempTau
	TempNumTau+=1
	EndIf
	
	EndFor
	
	Rs		=	SumRs	/	TempNumRs
	Rin		=	SumRin	/	TempNumRin
	Cm		=	SumCm	/	TempNumCm
	Vm		=	SumVm	/	TempNumVm
	Tau		=	SumTau	/	TempNumTau
//	Print Rs, Rin, Cm, Vm, Tau
	KillWaves /Z w1, fit_w1					//, negativeW1				05_20_2008
	KillWaves/Z RsRinCmVmBLW, RsRinCmVmSSW, RsRinCmVmExpPkW, RsRinCmVmBLWX, RsRinCmVmSSWX, RsRinCmVmExpPkWX
		
return 1
end

//==========================================================
Function pt_SpikeAnal()
//==========================================================
//==========================================================
// Modified from pt_SpikeAnal() in PraveensIgorUtilities on 11/03/10
// Commented out
//  Print "Peak at x=", V_PeakLoc,"relative amp.=", SpikeAmpRelative, "< SpikeAmpRelativeThresh=",SpikeAmpRelativeThresh ," in wave", WNameStr	
//==========================================================
//==========================================================
// This is always the latest version.

// NB. FIWNUMSPIKES IS THE NUM. OF SPIKES IN THE WAVE AND NOT SPIKE FREQUENCY 12/12/2007

// added ISIMidAbsX (ISI mid-point) and ISVY (Interspike voltage calculated at ISIMid point) 03/14/2009
// changing value of BoxSmoothingPnts from 1 to 5 (= box size for sliding average. for smooth operation by itself this corresponds to num & /B=b 
// is number of iterations of smoothing). with BoxSmoothingPnts=1 FindPeak finds spurious peaks. also found box smoothing with num=5
// gave derivatives that followed original derivatives more closely than derivatives of binomially (num =1) smoothened curve. anyways
// findpeak by itself only has sliding average option. included change in alert messages. default BaseNameStr changed from FI to F_I to distinguish cells 
// analysed with old and new parameter	 05/06/5008
// incorporated alert message for SpikeThreshWin increase 05_03_2008
// changing the value of paramerter SpikeThreshWin from 2e-3 (2ms) to 4e-3 (4ms). i noticed that with 2 ms for some spikes 
// SpikeThreshStartX was not past the threshold crossing, so next threshold crossing near peak was getting detected 
//(voltage slope increases and then decreases between threshold and peak) which falsely made the peak very small. 
//default BaseNameStr changed from FI to F_I to distinguish cells analysed with old and new parameter. 05_02_2008. 

// modified so that the parwave is searched locally first and then in FuncParWaves.
// // removed hard coded ":" after DataFldrStr. now if DataFldrStr = "" then the waves in current fldr will be analyzed. 04/23/2007
// EOPAHP was using BL at the end of wave. the voltage might not reach steady state by end of wave. changed to PrePlsBLY (pre pulse BL)
// PrePlsBLY is also being stored separately now, to be able to verify the values later. 
//also changed the averaging window to PrePlsBLDelT from BLPreDelT (spike BL) 03_28_2007

// This function finds spikes in a trace, based on absolute height, relative height, & spike threshold based on slope threshold.
// example: pt_FindSpikes("Cell_001517_0016", 0.5, 20, -30e-3, 30e-3, 1, 5, 1e-3, 2e-3, 10, .5e-3)
// for minimas will need to change sign of SpikeThreshDerivLevel, SpikeAmpAbsThresh, SpikePolarity, 

String WNameStr, WList, DataWaveMatchStr, DataFldrStr, BaseNameStr
Variable StartX, EndX, SpikeAmpAbsThresh, SpikeAmpRelativeThresh, SpikePolarity, BoxSmoothingPnts, RefractoryPeriod
Variable SpikeThreshWin, SpikeThreshDerivLevel, BLPreDelT, Frac, EOPAHPDelT, PrePlsBLDelT, AlertMessages, SpikeThreshDblDeriv, ISVDelT
Variable x0, dx, x1, x2, SpikeThreshStartX, SpikeThreshEndX, BLStartX, BLEndX, SpikeAmpRelative, SpikeThreshCrossX
Variable i, Numwaves, NSpikesInWave, PlusAreaVar, MinusAreaVar,j, FIData, LambdaW
String LastUpdatedMM_DD_YYYY="03_14_2009"

Print "*********************************************************"
Print "pt_SpikeAnal last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"


//Wave /T AnalParNamesW		=	$("root:FuncParWaves:pt_SpikeAnal"+"ParNamesW")
//Wave /T AnalParW			=	$("root:FuncParWaves:pt_SpikeAnal"+"ParW")
//If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
//	Abort	"Cudn't find the parameter wave pt_SpikeAnalParW!!!"
//EndIf


Wave /T AnalParW			=	$pt_GetParWave("pt_SpikeAnal", "ParW")	// wasn't checking locally first. modified 08/21/2007
																		//	First check locally, then in FuncParWaves
																		



PrintAnalPar("pt_SpikeAnal")

DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
StartX					=	Str2Num(AnalParW[2]); 
EndX					=	Str2Num(AnalParW[3]); 
SpikeAmpAbsThresh		=	Str2Num(AnalParW[4])
SpikeAmpRelativeThresh	=	Str2Num(AnalParW[5])
SpikePolarity				=	Str2Num(AnalParW[6])
BoxSmoothingPnts		=	Str2Num(AnalParW[7])
RefractoryPeriod			=	Str2Num(AnalParW[8])
SpikeThreshWin			=	Str2Num(AnalParW[9])
SpikeThreshDerivLevel		= 	Str2Num(AnalParW[10])
BLPreDelT				=	Str2Num(AnalParW[11])
If ( StrLen(AnalParW[12])*StrLen(AnalParW[13])!=0)
//	Wave /T FIWNamesW		=	$(GetDataFolder(-1)+DataFldrStr+":"+AnalParW[12])		// removed ":" 04/23/2007
	Wave /T FIWNamesW		=	$(GetDataFolder(-1)+DataFldrStr+AnalParW[12])
//	Wave     FICurrWave		=	$(GetDataFolder(-1)+DataFldrStr+":"+AnalParW[13])		// removed ":" 04/23/2007
	Wave     FICurrWave		=	$(GetDataFolder(-1)+DataFldrStr+AnalParW[13])	
	FIData=1
Else
	FIData=0
EndIf
BaseNameStr			=	AnalParW[14]
Frac					=	Str2Num(AnalParW[15])
EOPAHPDelT			=	Str2Num(AnalParW[16])		// EndOfPulseAHPDelT
PrePlsBLDelT			= 	Str2Num(AnalParW[17])
AlertMessages			=	Str2Num(AnalParW[18])
SpikeThreshDblDeriv		=	Str2Num(AnalParW[19])		// use double derivative to detect spike threshold instead of threshold crossing
														// of 1st derivative
ISVDelT					= 	Str2Num(AnalParW[20])

If (AlertMessages)    // incorporated alert message for SpikeThreshWin increase 05_03_2008
	DoAlert 1, "Recent changes: Increased SpikeThreshWin; Increased BoxSmoothingPnts. CONTINUE?"
	If (V_Flag==2)
		Abort "Aborting..."
	EndIf
EndIf

Make 	/O/N=0		$(BaseNameStr+"PrePlsBLX")
Make 	/O/N=0		$(BaseNameStr+"PrePlsBLAbsX")
Make 	/O/N=0		$(BaseNameStr+"PrePlsBLY")
Make 	/O/N=0		$(BaseNameStr+"SpkBLAvgX")
Make 	/O/N=0		$(BaseNameStr+"SpkBLAvgAbsX")
Make 	/O/N=0		$(BaseNameStr+"SpkBLAvgY")
Make 	/O/N=0		$(BaseNameStr+"PeakX")
Make 	/O/N=0		$(BaseNameStr+"PeakAbsX")
Make 	/O/N=0		$(BaseNameStr+"PeakAbsY")
Make 	/O/N=0		$(BaseNameStr+"PeakRelY")
Make 	/O/N=0		$(BaseNameStr+"SpikeThreshX")
Make 	/O/N=0		$(BaseNameStr+"SpikeThreshAbsX")
Make 	/O/N=0		$(BaseNameStr+"SpikeThreshY")
Make 	/O/N=0		$(BaseNameStr+"LFracPX")
Make 	/O/N=0		$(BaseNameStr+"LFracPAbsX")
Make 	/O/N=0		$(BaseNameStr+"RFracPX")
Make 	/O/N=0		$(BaseNameStr+"RFracPAbsX")
Make 	/O/N=0		$(BaseNameStr+"FracPAbsY")
Make 	/O/N=0		$(BaseNameStr+"TToFracPeakY")
Make 	/O/N=0		$(BaseNameStr+"FWFracM")
Make 	/O/N=0		$(BaseNameStr+"AHPX")
Make 	/O/N=0		$(BaseNameStr+"AHPAbsX")
Make 	/O/N=0		$(BaseNameStr+"AHPY")
Make 	/O/N=0		$(BaseNameStr+"AHPAbsY")

Make 	/O/N=0		$(BaseNameStr+"ISIMidAbsX")
Make 	/O/N=0		$(BaseNameStr+"ISIMidX")
Make 	/O/N=0		$(BaseNameStr+"ISVY")

Make 	/O/N=0		$(BaseNameStr+"EOPAHPAbsX")
Make 	/O/N=0		$(BaseNameStr+"EOPAHPX")
Make 	/O/N=0		$(BaseNameStr+"EOPAHPAbsY")
Make 	/O/N=0		$(BaseNameStr+"EOPAHPY")
Make 	/O/N=0		$(BaseNameStr+"WNumSpikes")
Make	/O/N=0		$(BaseNameStr+"FICurrW")
Make 	/T/O/N=0	$(BaseNameStr+"WName") 
							
						

Make 	/O/N=1		$(BaseNameStr+"PrePlsBLXTemp")
Make 	/O/N=1		$(BaseNameStr+"PrePlsBLAbsXTemp")
Make 	/O/N=1		$(BaseNameStr+"PrePlsBLYTemp")
Make 	/O/N=1		$(BaseNameStr+"SpkBLAvgXTemp")
Make 	/O/N=1		$(BaseNameStr+"SpkBLAvgAbsXTemp")
Make	/O/N=1		$(BaseNameStr+"SpkBLAvgYTemp")
Make	/O/N=1		$(BaseNameStr+"PeakXTemp")
Make	/O/N=1		$(BaseNameStr+"PeakAbsXTemp")
Make	/O/N=1		$(BaseNameStr+"PeakAbsYTemp")
Make	/O/N=1		$(BaseNameStr+"PeakRelYTemp")
Make	/O/N=1		$(BaseNameStr+"SpikeThreshXTemp")
Make	/O/N=1		$(BaseNameStr+"SpikeThreshAbsXTemp")
Make	/O/N=1		$(BaseNameStr+"SpikeThreshYTemp")
Make 	/O/N=1		$(BaseNameStr+"LFracPXTemp")
Make 	/O/N=1		$(BaseNameStr+"LFracPAbsXTemp")
Make 	/O/N=1		$(BaseNameStr+"RFracPXTemp")
Make 	/O/N=1		$(BaseNameStr+"RFracPAbsXTemp")
Make 	/O/N=1		$(BaseNameStr+"FracPAbsYTemp")
Make 	/O/N=1		$(BaseNameStr+"TToFracPeakYTemp")
Make 	/O/N=1		$(BaseNameStr+"FWFracMTemp")
Make 	/O/N=1		$(BaseNameStr+"AHPXTemp")
Make 	/O/N=1		$(BaseNameStr+"AHPAbsXTemp")
Make 	/O/N=1		$(BaseNameStr+"AHPYTemp")
Make 	/O/N=1		$(BaseNameStr+"AHPAbsYTemp")

Make 	/O/N=1		$(BaseNameStr+"ISIMidAbsXTemp")
Make 	/O/N=1		$(BaseNameStr+"ISIMidXTemp")
Make 	/O/N=1		$(BaseNameStr+"ISVYTemp")

Make 	/O/N=1		$(BaseNameStr+"EOPAHPAbsXTemp")
Make 	/O/N=1		$(BaseNameStr+"EOPAHPXTemp")
Make 	/O/N=1		$(BaseNameStr+"EOPAHPAbsYTemp")
Make 	/O/N=1		$(BaseNameStr+"EOPAHPYTemp")
Make	/O/N=1		$(BaseNameStr+"WNumSpikesTemp")
Make	/O/N=1		$(BaseNameStr+"FICurrWTemp")
Make	/T/O/N=1	$(BaseNameStr+"WNameTemp")



Wave		PrePlsBLX				=		$(BaseNameStr+"PrePlsBLX")
Wave		PrePlsBLAbsX			=		$(BaseNameStr+"PrePlsBLAbsX")
Wave		PrePlsBLY				=		$(BaseNameStr+"PrePlsBLY")
Wave		SpkBLAvgX				=		$(BaseNameStr+"SpkBLAvgX")
Wave		SpkBLAvgAbsX			=		$(BaseNameStr+"SpkBLAvgAbsX")
Wave		SpkBLAvgY				=		$(BaseNameStr+"SpkBLAvgY")
Wave		PeakX					=		$(BaseNameStr+"PeakX")
Wave 		PeakAbsX				=		$(BaseNameStr+"PeakAbsX")
Wave 		PeakAbsY				=		$(BaseNameStr+"PeakAbsY")
Wave 		PeakRelY				=		$(BaseNameStr+"PeakRelY")
Wave 		SpikeThreshX			=		$(BaseNameStr+"SpikeThreshX")
Wave 		SpikeThreshAbsX			=		$(BaseNameStr+"SpikeThreshAbsX")
Wave 		SpikeThreshY			=		$(BaseNameStr+"SpikeThreshY")
Wave 		LFracPX					=		$(BaseNameStr+"LFracPX")
Wave 		LFracPAbsX				=		$(BaseNameStr+"LFracPAbsX")
Wave 		RFracPX					=		$(BaseNameStr+"RFracPX")
Wave 		RFracPAbsX				=		$(BaseNameStr+"RFracPAbsX")
Wave 		FracPAbsY				=		$(BaseNameStr+"FracPAbsY")
Wave 		TToFracPeakY			=		$(BaseNameStr+"TToFracPeakY")
Wave 		FWFracM				=		$(BaseNameStr+"FWFracM")
Wave 		AHPX					=		$(BaseNameStr+"AHPX")
Wave 		AHPAbsX				=		$(BaseNameStr+"AHPAbsX")
Wave 		AHPY					=		$(BaseNameStr+"AHPY")
Wave 		AHPAbsY				=		$(BaseNameStr+"AHPAbsY")

Wave 		ISIMidAbsX				=		$(BaseNameStr+"ISIMidAbsX")
Wave 		ISIMidX					=		$(BaseNameStr+"ISIMidX")
Wave 		ISVY					=		$(BaseNameStr+"ISVY")

Wave		EOPAHPAbsX			=		$(BaseNameStr+"EOPAHPAbsX")
Wave		EOPAHPX				=		$(BaseNameStr+"EOPAHPX")
Wave		EOPAHPAbsY			=		$(BaseNameStr+"EOPAHPAbsY")
Wave		EOPAHPY				=		$(BaseNameStr+"EOPAHPY")
Wave 		WNumSpikes			=		$(BaseNameStr+"WNumSpikes")
Wave		FICurrW					=		$(BaseNameStr+"FICurrW")
Wave	/T	WName					=		$(BaseNameStr+"WName") 


Wave		PrePlsBLXTemp			=		$(BaseNameStr+"PrePlsBLXTemp")
Wave		PrePlsBLAbsXTemp		=		$(BaseNameStr+"PrePlsBLAbsXTemp")
Wave		PrePlsBLYTemp			=		$(BaseNameStr+"PrePlsBLYTemp")
Wave		SpkBLAvgXTemp			=		$(BaseNameStr+"SpkBLAvgXTemp")
Wave		SpkBLAvgAbsXTemp		=		$(BaseNameStr+"SpkBLAvgAbsXTemp")
Wave		SpkBLAvgYTemp			=		$(BaseNameStr+"SpkBLAvgYTemp")
Wave		PeakXTemp				=		$(BaseNameStr+"PeakXTemp")
Wave		PeakAbsXTemp			=		$(BaseNameStr+"PeakAbsXTemp")
Wave		PeakAbsYTemp			=		$(BaseNameStr+"PeakAbsYTemp")
Wave		PeakRelYTemp			=		$(BaseNameStr+"PeakRelYTemp")
Wave		SpikeThreshXTemp		=		$(BaseNameStr+"SpikeThreshXTemp")
Wave		SpikeThreshAbsXTemp	=		$(BaseNameStr+"SpikeThreshAbsXTemp")
Wave		SpikeThreshYTemp		=		$(BaseNameStr+"SpikeThreshYTemp")
Wave		LFracPXTemp			=		$(BaseNameStr+"LFracPXTemp")
Wave 		LFracPAbsXTemp		=		$(BaseNameStr+"LFracPAbsXTemp")
Wave 		RFracPXTemp			=		$(BaseNameStr+"RFracPXTemp")
Wave 		RFracPAbsXTemp		=		$(BaseNameStr+"RFracPAbsXTemp")
Wave 		FracPAbsYTemp			=		$(BaseNameStr+"FracPAbsYTemp")
Wave 		TToFracPeakYTemp		=		$(BaseNameStr+"TToFracPeakYTemp")
Wave 		FWFracMTemp			=		$(BaseNameStr+"FWFracMTemp")
Wave 		AHPXTemp				=		$(BaseNameStr+"AHPXTemp")
Wave 		AHPAbsXTemp			=		$(BaseNameStr+"AHPAbsXTemp")
Wave 		AHPYTemp				=		$(BaseNameStr+"AHPYTemp")
Wave 		AHPAbsYTemp			=		$(BaseNameStr+"AHPAbsYTemp")

Wave 		ISIMidAbsXTemp			=		$(BaseNameStr+"ISIMidAbsXTemp")
Wave 		ISIMidXTemp				=		$(BaseNameStr+"ISIMidXTemp")
Wave 		ISVYTemp				=		$(BaseNameStr+"ISVYTemp")

Wave		EOPAHPAbsXTemp		=		$(BaseNameStr+"EOPAHPAbsXTemp")
Wave		EOPAHPXTemp			=		$(BaseNameStr+"EOPAHPXTemp")
Wave		EOPAHPAbsYTemp		=		$(BaseNameStr+"EOPAHPAbsYTemp")
Wave		EOPAHPYTemp			=		$(BaseNameStr+"EOPAHPYTemp")
Wave		WNumSpikesTemp		=		$(BaseNameStr+"WNumSpikesTemp")
Wave		FICurrWTemp			=		$(BaseNameStr+"FICurrWTemp")
Wave	/T	WNameTemp			=		$(BaseNameStr+"WNameTemp")



WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(-1)+DataFldrStr)
Numwaves=ItemsInList(WList, ";")

Print "Analyzing spikes for waves, N =", ItemsInList(WList, ";"), WList

//Print "TEMPOARILY REDIFINING SPIKE WIDTH TO WHERE THE VOLTAGE CROSSES THE SPIKE THRESHOLD"

For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")
	WNameTemp[0]=WNameStr
	If (FIData)
		For (j=0; j<NumPnts(FIWNamesW); j+=1)
			If (StringMatch(FIWNamesW[j],WNameStr))
//				Print j, WNameStr, FICurrWave[j]
				FICurrWTemp[0]=FICurrWave[j]
				Concatenate /NP 	   {FICurrWTemp}, FICurrW
				break
				print "Couldn't find", WNameStr, "in",AnalParW[11]
			EndIf
		EndFor
	EndIf
	Concatenate /T/NP {WNameTemp}, WName
//	Duplicate /O $(GetDataFolder(-1)+DataFldrStr+":"+WNameStr), w		// removed ":" 04/23/2007
	Duplicate /O $(GetDataFolder(-1)+DataFldrStr+WNameStr), w
//	display w
//	Duplicate /O $(GetDataFolder(-1)+DataFldrStr+":"+WNameStr), Diffw	// removed ":" 04/23/2007
	Duplicate /O $(GetDataFolder(-1)+DataFldrStr+WNameStr), Diffw, DiffDiffw
	//Smooth 1, Diffw
	Differentiate Diffw
	Differentiate Diffw /D=DiffDiffw
	x0=DimOffset(w,0); dx=DimDelta(w,0)
//	LambdaW=x0+(NumPnts(w)-1)*dx
	LambdaW=x0+(NumPnts(w))*dx
	NSpikesInWave=0; x1=StartX; x2=EndX;

	Do
		If (x1>=x2)								// end of pulse reached; now calculate EOPAHP and PrePlsBLY
			Print x1,">=",x2
			WNumSpikesTemp[0]=NSpikesInWave
			Concatenate /NP {WNumSpikesTemp}, WNumSpikes
				If (NSpikesInWave>0)
					AHPAbsXTemp		= NaN
					AHPXTemp			= NaN
					AHPAbsYTemp		= NaN
					AHPYTemp			= NaN
					Concatenate /NP	{AHPAbsXTemp},			AHPAbsX
					Concatenate /NP	{AHPXTemp},			AHPX
					Concatenate /NP	{AHPAbsYTemp},			AHPAbsY
					Concatenate /NP	{AHPYTemp},			AHPY	
					
					ISIMidAbsXTemp			= Nan
					ISIMidXTemp				= Nan
					ISVYTemp				= Nan
					Concatenate /NP {ISIMidAbsXTemp}, 	ISIMidAbsX
					Concatenate /NP {ISIMidXTemp}, 		ISIMidX
					Concatenate /NP {ISVYTemp}, 			ISVY
					
				EndIf
				EOPAHPAbsXTemp			=	NaN
				EOPAHPXTemp				=	NaN
				EOPAHPAbsYTemp			=	NaN
				EOPAHPYTemp				=	NaN
							
				PrePlsBLAbsXTemp			=	NaN
				PrePlsBLXTemp				=	NaN
				PrePlsBLYTemp				=	NaN	

				
				If (NSpikesInWave>0)
					WaveStats /Q/R=(StartX-PrePlsBLDelT, StartX) w 
					PrePlsBLAbsXTemp	= StartX-0.5*PrePlsBLDelT
					PrePlsBLXTemp		= PrePlsBLAbsXTemp + i*LambdaW
					PrePlsBLYTemp		= V_Avg
					WaveStats /Q/R=(EndX, EndX+EOPAHPDelT) w
					EOPAHPAbsXTemp			=	V_MinLoc
					EOPAHPXTemp				=	EOPAHPAbsXTemp+ i*LambdaW
					EOPAHPAbsYTemp			=	V_Min
// for EOPAHP the steady state voltage may not be reached by end of wave. should be taken from before the pulse. 03/28/2007
//					EOPAHPYTemp	=	EOPAHPAbsYTemp-Mean(w, LambdaW-BLPreDelT, LambdaW)		
					EOPAHPYTemp	=	EOPAHPAbsYTemp - PrePlsBLYTemp
				EndIf	
				Concatenate /NP	{EOPAHPAbsXTemp},			EOPAHPAbsX
				Concatenate /NP	{EOPAHPXTemp},			EOPAHPX
				Concatenate /NP	{EOPAHPAbsYTemp},		EOPAHPAbsY
				Concatenate /NP	{EOPAHPYTemp},			EOPAHPY
				
				Concatenate /NP	{PrePlsBLAbsXTemp},			PrePlsBLAbsX
				Concatenate /NP	{PrePlsBLXTemp},			PrePlsBLX
				Concatenate /NP	{PrePlsBLYTemp},			PrePlsBLY
			Break	// finish analyzing this pulse
		EndIf
		If (SpikePolarity==1)
			FindPeak 		/B=(BoxSmoothingPnts) /M=(SpikeAmpAbsThresh) /Q/R=(x1,x2) w
			If (V_Flag==0)
				//y1=mean(V_PeakLoc-BLPreT-BLPreDelT,V_PeakLoc-BLPreT)
				V_PeakLoc=x0+dx*x2pnt(w,V_PeakLoc)	// convert from pt. to x
				x1=V_PeakLoc+RefractoryPeriod
				SpikeThreshStartX=V_PeakLoc-SpikeThreshWin
				SpikeThreshEndX=V_PeakLoc
				SpikeThreshCrossX = Nan
				If (SpikeThreshDblDeriv)
					Wavestats /Q/R=(SpikeThreshStartX, SpikeThreshEndX) DiffDiffw
					SpikeThreshCrossX=V_MaxLoc
				Else
				FindLevel /Q/R=(SpikeThreshStartX, SpikeThreshEndX)  Diffw, SpikeThreshDerivLevel
				If (V_Flag==0)
					SpikeThreshCrossX=V_LevelX
				EndIf
				EndIf
				If (NumType(SpikeThreshCrossX)!=0)			//(V_Flag!=0)
//					Print "Cudn't find spike amp. thresh for spike at", V_PeakLoc,"in wave", WNameStr
				Else 	
					SpikeThreshCrossX=x0+dx*x2pnt(w,SpikeThreshCrossX)
					BLStartX=SpikeThreshCrossX-BLPreDelT
					BLEndX=SpikeThreshCrossX
					SpkBLAvgYTemp		=	mean( w, BLStartX, BLEndX)
					SpkBLAvgAbsXTemp	= 	0.5*(BLStartX + BLEndX)
					SpkBLAvgXTemp		=	SpkBLAvgAbsXTemp + i*LambdaW
					SpikeAmpRelative=V_PeakVal-SpkBLAvgYTemp
//					print mean( w, BLStartX, BLEndX)
					If (SpikeAmpRelative >=SpikeAmpRelativeThresh)
						PeakAbsXTemp	=	V_PeakLoc; PeakAbsYTemp=V_PeakVal; PeakRelYTemp=SpikeAmpRelative

						PeakXTemp		=	PeakAbsXTemp+ i*LambdaW
						
						SpikeThreshAbsXTemp	=	SpikeThreshCrossX; SpikeThreshYTemp=w[x2pnt(w,SpikeThreshCrossX)]
						SpikeThreshXTemp		=	SpikeThreshAbsXTemp+i*LambdaW
						
// LFracPX = x value at which the trace crosses the Frac of  max on left side			
						FracPAbsYTemp	=	SpkBLAvgYTemp+Frac*SpikeAmpRelative	
						FindLevel /Q/R=(PeakAbsXTemp, -inf)  w, 	FracPAbsYTemp	// Frac will usually be 0.5//SpikeThreshAbsXTemp
//						FindLevel /Q/R=(PeakAbsXTemp, -inf)  w, 	SpikeThreshYTemp // temporarily redefining spike width to where the voltage crosses the spike threshold						
						If (V_Flag!=0)
							Print "No left crossing at", frac,"times of peak in wave", WNameStr, "at", PeakAbsXTemp,"between", PeakAbsXTemp, SpikeThreshAbsXTemp
							LFracPAbsXTemp	= 	NaN
							LFracPXTemp		= 	NaN
							TToFracPeakYTemp	=  	NaN
						Else	
							LFracPAbsXTemp	= 	V_LevelX
							LFracPXTemp		= 	LFracPAbsXTemp+ i*LambdaW
							TToFracPeakYTemp	=  	LFracPAbsXTemp-SpikeThreshAbsXTemp
						EndIf	
							
						
// RFracPX = x value at which the trace crosses the Frac of  max on Right side			
			
							FindLevel /Q/R=(PeakAbsXTemp, +inf)  w, FracPAbsYTemp//2*PeakAbsXTemp-SpikeThreshAbsXTemp
//							FindLevel /Q/R=(PeakAbsXTemp, +inf)  w, SpikeThreshYTemp // temporarily redefining spike width to where the voltage crosses the spike threshold							
						If (V_Flag!=0)
							Print "No right crossing at", frac,"times of peak in wave", WNameStr, "at", PeakAbsXTemp, "between",PeakAbsXTemp, 2*PeakAbsXTemp-SpikeThreshAbsXTemp
							RFracPAbsXTemp	= 	NaN
							RFracPXTemp		=  	NaN
							FWFracMTemp		= 	NaN
						Else
							RFracPAbsXTemp	= 	V_LevelX
							RFracPXTemp		=  	RFracPAbsXTemp+ i*LambdaW
							FWFracMTemp		= 	RFracPAbsXTemp - LFracPAbsXTemp								
						EndIf
						
						
//						WaveStats /Q/R=(PeakAbsXTemp, PeakAbsXTemp+AHPDelT) w
						If (NSpikesInWave>0)
//							If (NSpikesInWave==1)
//								DeletePoints Numpnts(AHPAbsX)-1,1,AHPAbsX, AHPX, AHPAbsY, AHPY
//							EndIf
							WaveStats /Q/R=(PeakAbsX[Numpnts(PeakAbsX)-1], PeakAbsXTemp) w
							AHPAbsXTemp		= V_MinLoc
							AHPXTemp			= AHPAbsXTemp + i*LambdaW
							AHPAbsYTemp		= V_Min
							AHPYTemp			= AHPAbsYTemp-SpkBLAvgY[Numpnts(SpkBLAvgY)-1]
							Concatenate /NP	{AHPAbsXTemp},			AHPAbsX
							Concatenate /NP	{AHPXTemp},			AHPX
							Concatenate /NP	{AHPAbsYTemp},			AHPAbsY
							Concatenate /NP	{AHPYTemp},			AHPY
							
							ISIMidAbsXTemp	= 	0.5*(PeakAbsX[Numpnts(PeakAbsX)-1]+ PeakAbsXTemp)
							WaveStats /Q/R	=	(ISIMidAbsXTemp-ISVDelT, ISIMidAbsXTemp+ISVDelT) w
							ISIMidXTemp	 	= 	ISIMidAbsXTemp + i*LambdaW
							ISVYTemp 		= 	V_Avg
							Concatenate /NP {ISIMidAbsXTemp}, 	ISIMidAbsX
							Concatenate /NP {ISIMidXTemp}, 		ISIMidX
							Concatenate /NP {ISVYTemp}, 			ISVY
							
//							If (NumPnts(SpikeThreshY)!=NumPnts(AHPY))	
//								Print "********",SpikeThreshY(NumPnts(SpikeThreshY)-1), AHPY(NumPnts(AHPY)-1),"********"
//							EndIf	
						Else
//							AHPAbsXTemp		= NaN
//							AHPXTemp			= NaN
//							AHPAbsYTemp		= NaN
//							AHPYTemp			= NaN
//							Concatenate /NP	{AHPAbsXTemp},			AHPAbsX
//							Concatenate /NP	{AHPXTemp},			AHPX
//							Concatenate /NP	{AHPAbsYTemp},			AHPAbsY
//							Concatenate /NP	{AHPYTemp},			AHPY	
						EndIf
						Concatenate /NP	{TToFracPeakYTemp},	TToFracPeakY
						Concatenate /NP	{LFracPAbsXTemp},		LFracPAbsX
						Concatenate /NP	{LFracPXTemp},			LFracPX
						Concatenate /NP	{RFracPAbsXTemp},		RFracPAbsX
						Concatenate /NP	{RFracPXTemp},			RFracPX
						Concatenate /NP	{FracPAbsYTemp},		FracPAbsY
						Concatenate /NP	{FWFracMTemp},			FWFracM

						

				
						Concatenate /NP {SpkBLAvgYTemp}, 		SpkBLAvgY
						Concatenate /NP {SpkBLAvgXTemp}, 		SpkBLAvgX
						Concatenate /NP {SpkBLAvgAbsXTemp}, 	SpkBLAvgAbsX		
						Concatenate /NP {PeakXTemp}, 			PeakX
						Concatenate /NP {PeakAbsXTemp}, 		PeakAbsX
						Concatenate /NP {PeakAbsYTemp}, 		PeakAbsY
						Concatenate /NP {PeakRelYTemp}, 		PeakRelY
						Concatenate /NP	{SpikeThreshXTemp}, 		SpikeThreshX
						Concatenate /NP	{SpikeThreshAbsXTemp}, 	SpikeThreshAbsX
						Concatenate /NP	{SpikeThreshYTemp}, 		SpikeThreshY	
						
		

						NSpikesInWave +=1
					Else
//						Print "Peak at x=", V_PeakLoc,"relative amp.=", SpikeAmpRelative, "< SpikeAmpRelativeThresh=",SpikeAmpRelativeThresh ," in wave", WNameStr	
					EndIf
				EndIf	
			Else 				// no more peaks found in the pulse; now calculate EOPAHP and PrePlsBLY
				WNumSpikesTemp[0]=NSpikesInWave
				Concatenate /NP {WNumSpikesTemp}, WNumSpikes
				If (NSpikesInWave>0)
					AHPAbsXTemp		= NaN
					AHPXTemp			= NaN
					AHPAbsYTemp		= NaN
					AHPYTemp			= NaN
					Concatenate /NP	{AHPAbsXTemp},			AHPAbsX
					Concatenate /NP	{AHPXTemp},			AHPX
					Concatenate /NP	{AHPAbsYTemp},			AHPAbsY
					Concatenate /NP	{AHPYTemp},			AHPY
					
					ISIMidAbsXTemp			= Nan
					ISIMidXTemp				= Nan
					ISVYTemp				= Nan
					Concatenate /NP {ISIMidAbsXTemp}, 	ISIMidAbsX
					Concatenate /NP {ISIMidXTemp}, 		ISIMidX
					Concatenate /NP {ISVYTemp}, 			ISVY
					
						
				EndIf
				
				EOPAHPAbsXTemp			=	NaN
				EOPAHPXTemp				=	NaN
				EOPAHPAbsYTemp			=	NaN
				EOPAHPYTemp				=	NaN
				
				PrePlsBLAbsXTemp			=	NaN
				PrePlsBLXTemp				=	NaN
				PrePlsBLYTemp				=	NaN	
				
				If (NSpikesInWave>0)
					WaveStats /Q/R=(StartX-PrePlsBLDelT, StartX) w 
					PrePlsBLAbsXTemp	= StartX-0.5*PrePlsBLDelT
					PrePlsBLXTemp		= PrePlsBLAbsXTemp + i*LambdaW
					PrePlsBLYTemp		= V_Avg
					WaveStats /Q/R=(EndX, EndX+EOPAHPDelT) w
					EOPAHPAbsXTemp			=	V_MinLoc
					EOPAHPXTemp				=	EOPAHPAbsXTemp+ i*LambdaW
					EOPAHPAbsYTemp			=	V_Min
// for EOPAHP the steady state voltage may not be reached by end of wave. should be taken from before the pulse. 03/28/2007
//					EOPAHPYTemp	=	EOPAHPAbsYTemp-Mean(w, LambdaW-BLPreDelT, LambdaW)		
					EOPAHPYTemp	=	EOPAHPAbsYTemp - PrePlsBLYTemp
				EndIf	
					Concatenate /NP	{EOPAHPAbsXTemp},			EOPAHPAbsX
					Concatenate /NP	{EOPAHPXTemp},			EOPAHPX
					Concatenate /NP	{EOPAHPAbsYTemp},		EOPAHPAbsY
					Concatenate /NP	{EOPAHPYTemp},			EOPAHPY
					
					Concatenate /NP	{PrePlsBLAbsXTemp},			PrePlsBLAbsX
					Concatenate /NP	{PrePlsBLXTemp},			PrePlsBLX
					Concatenate /NP	{PrePlsBLYTemp},			PrePlsBLY
				Break	 
			EndIf
		Else
			FindPeak 	/N	/B=(BoxSmoothingPnts) /M=(SpikeAmpAbsThresh) /Q/R=(x1,x2) w
			If (V_Flag==0)
				//y1=mean(V_PeakLoc-BLPreT-BLPreDelT,V_PeakLoc-BLPreT)
				x1=V_PeakLoc+RefractoryPeriod
				SpikeThreshStartX=V_PeakLoc-SpikeThreshWin
				SpikeThreshEndX=V_PeakLoc
				FindLevel /Q/R=(SpikeThreshStartX, SpikeThreshEndX) Diffw, SpikeThreshDerivLevel
				If (V_Flag!=0)
					Print "Cudn't find spike amp. thresh for spike at", V_PeakLoc,"in wave", WNameStr
				Else 	
					BLStartX=V_LevelX-BLPreDelT
					BLEndX=V_LevelX
					SpikeAmpRelative=V_PeakVal-mean( w, BLStartX, BLEndX)
//					print mean( w, BLStartX, BLEndX)
					If (SpikeAmpRelative <=SpikeAmpRelativeThresh)
						PeakAbsXTemp	=	V_PeakLoc; PeakAbsYTemp=V_PeakVal; PeakRelYTemp=SpikeAmpRelative
						PeakXTemp		=	PeakAbsXTemp+ i*LambdaW
						SpikeThreshAbsXTemp	=	V_LevelX; SpikeThreshYTemp=w[x2pnt(w,V_LevelX)]
						SpikeThreshXTemp		=	SpikeThreshAbsXTemp+i*LambdaW
						Concatenate /NP {PeakXTemp}, PeakX
						Concatenate /NP {PeakAbsXTemp}, PeakAbsX
						Concatenate /NP {PeakAbsYTemp}, PeakAbsY
						Concatenate /NP {PeakRelYTemp}, PeakRelY
						Concatenate /NP	{SpikeThreshXTemp}, SpikeThreshX
						Concatenate /NP	{SpikeThreshAbsXTemp}, SpikeThreshAbsX
						Concatenate /NP	{SpikeThreshYTemp}, SpikeThreshY
						NSpikesInWave +=1
					Else
//						Print "Peak at x=", V_PeakLoc,"relative amp.=", SpikeAmpRelative, "> SpikeAmpRelativeThresh=",SpikeAmpRelativeThresh ," in wave", WNameStr	
					EndIf
				EndIf	
			Else 
				WNumSpikesTemp[0]=NSpikesInWave
				Concatenate /NP {WNumSpikesTemp}, WNumSpikes
				Break	 
			EndIf
		EndIf	
	While(1)				
EndFor		
Killwaves /Z PeakXTemp, PeakAbsXTemp, PeakAbsYTemp, PeakRelYTemp, SpikeThreshXTemp, SpikeThreshAbsXTemp, SpikeThreshYTemp, w, DiffW, DiffDiffW, WNumSpikesTemp, WNameTemp, FICurrWTemp
KillWaves /Z LFracPXTemp, LFracPAbsXTemp, RFracPXTemp, RFracPAbsXTemp, FracPAbsYTemp, TToFracPeakYTemp, FWFracMTemp, AHPAbsXTemp, AHPXTemp, AHPAbsYTemp, AHPYTemp					
KillWaves /Z EOPAHPAbsXTemp, EOPAHPXTemp, EOPAHPAbsYTemp, EOPAHPYTemp, SpkBLAvgYTemp, SpkBLAvgXTemp, SpkBLAvgAbsXTemp
KillWaves /Z PrePlsBLAbsXTemp, PrePlsBLXTemp, PrePlsBLYTemp
KillWaves /Z ISIMidAbsXTemp, ISIMidXTemp, ISVYTemp


End

//==========================================================







Function /S pt_GetParWave(AnalFunc, ParDescripStr)	// ParDescripStr=ParNamesW OR ParW
String AnalFunc, ParDescripStr

If ( WaveExists($AnalFunc+ParDescripStr) )
	Print "***Found", AnalFunc+ParDescripStr, GetDataFolder(1), "***"
	Return GetDataFolder(1) +AnalFunc + ParDescripStr

//ElseIf ( WaveExists($"root:FuncParWaves:"+AnalFunc+ParDescripStr) )
ElseIf ( WaveExists($"root:AnalyzeDataVars:"+AnalFunc+ParDescripStr) )
	
	Return "root:AnalyzeDataVars:"+AnalFunc+ParDescripStr

Else

	Abort	"Cudn't find the parameter waves"+  AnalFunc+ ParDescripStr

EndIf

End

Function PrintAnalPar(AnalFunc)
String AnalFunc
Variable i

Print "Analysis parameters"
Print "****************************************************************************************"
Wave /T AnalParW			=  		$pt_GetParWave(AnalFunc, "ParW")
Wave /T AnalParNamesW		=		$pt_GetParWave(AnalFunc, "ParNamesW")

//Print "Analysis parameters"
//Print "****************************************************************************************"
i=0
Do
	If (i>=NumPnts(AnalParW))
		Break
	Else
	 	Print AnalParNamesW[i], "=", AnalParW[i]
	 EndIf	
	 i+=1
While (1)
Print "****************************************************************************************"
End

Function /s pt_SortWavesInFolder(MatchStr, IgorFolderPath)
// ExampleUsage: pt_SortWavesInFolder("CntrlEegW*", "root:LoadedData")
String MatchStr, IgorFolderPath
String OldDf, WaveListStr
OldDf=GetDataFolder(-1)
SetDataFolder $IgorFolderPath
WaveListStr=WaveList(MatchStr, ";", "")
WaveListStr=SortList(WaveListStr, ";", 16)
SetDataFolder OldDf
Return WaveListStr
End

Function pt_ConcatenateWaves(WaveListStr, DestWaveName, IgorFolderPath)
// ExampleUsage: pt_ConcatenateWaves(pt_SortWavesInFolder("CntrlEegW*", "root:LoadedData"), "CntrlEegW", "root:LoadedData")
String WaveListStr, DestWaveName, IgorFolderPath
String OldDf
Variable i
OldDf=GetDataFolder(-1)
SetDataFolder $IgorFolderPath
//For (i=0; i <ItemsInList(WaveListStr); i+=1)
	Concatenate /NP WaveListStr,  $DestWaveName
//EndFor
SetDataFolder OldDf
End



Function pt_CalRsRinCmVmVClamp2(w,tBaselineStart0,tBaselineEnd0,tSealTestStart0, tSealTestPeakWinDel, tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V,NumRepeat,RepeatPeriod, tExp2FitStart0, tExp2FitEnd0, Rs,Rin,Cm, Im, Tau)
//******************************************************************************
//******************************************************************************
// Set DisplayResults =0 to not display the actual fitting
// Also setting bit 2 of V_FitOptions (suppress CurveFit info window)
// V_FitError =0 to suppress abortion of fit on error
// Also can set V_FitQuitReason (0 = normal termination; 1= iter limit reached; 2 = user stopped fit
//					     3 = limit of passes without decreasing chi-sq reached)
// modified from pt_CalRsRinCmVmVClamp2() from PraveensIgorUtilities (06/16/2010)
//******************************************************************************
//******************************************************************************

// modified from: RsRinCmIclamp

// curvefitting exponential is difficult for the falling phase of series-resistance transient as it's very fast and only has 2-3 points before
// it gives rise to slower decay due to membrane RIn and Cm. So just for the amplitude of series resistance transient i am switching to
// finding minimum or maximum using wavestats. //07/14/2008

// changes in pt_RsRinCmVmVclamp1 to get pt_RsRinCmVmVclamp2
//  incorporating display of measurements on seal test. also instead of using pt_ExpFit() using funcfit to fit exponential. 
//one advantage is that it can also fit the steady state value. plus it will make the seal test stand alone program. 07/14/2008 (already did for I clamp on 05/20/2008)


// Modifications
//** earlier tBaselineEnd0 was at start of seal test but then i moved it to before start of seal test. but still kept using tBaselineEnd0 to 
//extrapolate the exp. to get amplitude at start of seal test. that is wrong. therefore separating tSealTestStart0. bug reported by kiran  
// Feb.28th 2008 Praveen
// ** the steady state of exponential is not necessarily same as steady state at end of seal test (eg. some voltage and time dependent conductance (eg. Ih) 
//	can change during later part of the seal test). so calculate the steady state of exponential early on (WorkVar3). so use WorkVar3 instead of WorkVar2 
//	for fitting of exponential and calculation of Rs, Cm.
//** Often in V-clamp seal test two exponential decays can be seen. the first fast decay is charge on pipette capacitance leaking thru the resistors, the second slower 
//decay is due to cell capacitance charge leaking. the 2nd exponential decay should be used for calculation of cell membrane capacitance.
//** also output Vm, as we are calculating it anyway.
//** also changed the tBaselineEnd0 to 0.0499 s instead of 0.05 s. earlier it was off by 0.1 ms which was causing a small error. correspondingly, 
//	exponential fit starts later. 
//** to distinguish the new analysis, the output waves are RsV, RinV, CmV, VmV, TauV instead of RsW, RinW, CmW, VmW, TauV.


variable tBaselineStart0,tBaselineEnd0,tSealTestStart0, tSealTestPeakWinDel, tSteadyStateStart0,tSteadyStateEnd0,SealTestAmp_V,NumRepeat,RepeatPeriod, tExp2FitStart0, tExp2FitEnd0, &Rs,&Rin,&Cm, &Im, &Tau
wave w
variable i, WorkVar1,WorkVar2,amp,t0,y1, WorkVar3,	 WorkVar4, negativeWorkVar3,SumRs,SumRin,SumCm, SumIm, SumTau, TempRs,TempRin, TempRin1, TempCm, TempIm, TempTau, TempNumRs, TempNumRin, TempNumCm, TempNumIm, TempNumTau			
variable tBaselineStart, tBaselineEnd, tSealTestStart, tSteadyStateStart, tSteadyStateEnd, tExp2FitStart, tExp2FitEnd, DisplayResults
SVAR CurrentRsRinCmImWName=CurrentRsRinCmImWName

	i=0; 
	WorkVar1=0; WorkVar2=0; WorkVar3=0; 
	amp=0; t0=0; y1=0; 
	SumRs=0; SumRin=0; SumCm=0; SumIm=0; SumTau=0
	Rs=0; Rin=0; Cm=0; Im=0; Tau=0
	TempRs=0; TempRin=0; TempRin1=0; TempCm=0; TempIm=0; TempTau=0
	TempNumRs=0; TempNumRin=0; TempNumCm=0; TempNumIm=0; TempNumTau=0
	tBaselineStart=0;tBaselineEnd=0;
	tSealTestStart=0
	tSteadyStateStart=0;tSteadyStateEnd=0
//	tExp1SteadyStateStart=0; tExp1SteadyStateEnd=0
//	tExp1FitStart=0; tExp1FitEnd=0
//	tExp2SteadyStateStart=0; tExp2SteadyStateEnd=0
	tExp2FitStart=0; tExp2FitEnd=0
//	tBaselineStart		 =	tBaselineStart0
//	tBaselineEnd			 =	tBaselineEnd0
//	tSteadyStateStart	 =	tSteadyStateStart0
//	tSteadyStateEnd		 =	tSteadyStateEnd0
	
	duplicate /o w,w1
	Rs=Nan; Rin=Nan; Cm=Nan; Im=Nan; Tau=Nan		//if calculation gives weird values (basically, cos the curve has an odd shape), then return NaN

//	if (SealTestAmp_V<0)
//		w1 *= -1
//	endif
	
	For  (i=0;i<NumRepeat;i+=1)	
//	t1 = (SealTestPad1-RT_SealTestWidth)/1000
//	t2 = SealTestPad1/1000

	tBaselineStart = tBaselineStart0 + i*RepeatPeriod
	tBaselineEnd  = tBaselineEnd0  + i*RepeatPeriod
	WorkVar1 = mean(w1,tBaselineStart,tBaselineEnd)									// WorkVar1 --> Baseline V_m before sealtest [V]

	tSealTestStart = tSealTestStart0 + i*RepeatPeriod
//	t3 = (SealTestPad1+SealTestDur-RT_SealTestWidth)/1000
//	t4 = (SealTestPad1+SealTestDur)/1000

//	tStart=tBaselineEnd+0.0001	
//	tExp1FitStart	=tExp1FitStart0	+ i*RepeatPeriod								//finally this values should be input by user thru the interface.
//	tExp1FitEnd	=tExp1FitEnd0	+ i*RepeatPeriod
	
	tExp2FitStart	=tExp2FitStart0	+ i*RepeatPeriod								//finally this values should be input by user thru the interface.
	tExp2FitEnd	=tExp2FitEnd0	+ i*RepeatPeriod
	
	
	tSteadyStateStart = tSteadyStateStart0 + i*RepeatPeriod
	tSteadyStateEnd = tSteadyStateEnd0   +  i*RepeatPeriod
	WorkVar2 = mean(w1,tSteadyStateStart,tSteadyStateEnd)									// WorkVar2 --> V_m at peak value of sealtest [V]
	
//	tExp1SteadyStateStart	=	tExp1SteadyStateStart0		+	i*RepeatPeriod
//	tExp1SteadyStateEnd  	=	tExp1SteadyStateEnd0		+	i*RepeatPeriod
//	WorkVar3			=	mean(w1,tExp1SteadyStateStart,tExp1SteadyStateEnd)	
	
// 	Equation to fit I(t)=I(Inf)+(I(0)-I(Inf))*exp(-t/(Req*C))			
// 	I(t) = current through Rs or Rin+Cm parallel compbination
//	Tau=Req*C where Req=Rs*Rin/(Rs+Rin). under good V clamp effectively Rs<< Rin. so that Req=Rs.  	
//	duplicate /o w1, negativeW1
//	negativeW1=-w1
//	negativeWorkVar3=-WorkVar3
//	pt_expfit(w1,WorkVar3, tExp1FitStart, tExp1FitEnd, amp, t0)

// curvefitting exponential is difficult for the falling phase of series-resistance transient as it's very fast and only has 2-3 points before
// it gives rise to slower decay due to membrane RIn and Cm. So just for the amplitude of series resistance transient i am switching to
// finding minimum or maximum using wavestats. //07/14/2008

Wavestats /Q/R=(tSealTestStart, (tSealTestStart+tSealTestPeakWinDel)) w1


//Make /D/O/N=3 W_FitCoeff = Nan
//Duplicate /O  w1, fit_w1
//fit_w1= Nan

//CurveFit /NTHR=0/TBOX=0/Q exp_XOffset,  kwCWave=W_FitCoeff, w1 (tExp1FitStart, tExp1FitEnd) /D = fit_w1

//WorkVar3	= W_FitCoeff[0]
//amp 		= W_FitCoeff[1]
//t0			= W_FitCoeff[3]

//If (		(NumType(W_FitCoeff[0])!=0) || (NumType(W_FitCoeff[1])!=0) || (NumType(W_FitCoeff[2])!=0)		)
//	Print "																			"
//	Print "Fitting error: y0, A, Tau =", WorkVar3, amp,t0, "in", CurrentRsRinCmImWName
//EndIf

// earlier tBaselineEnd0 was at start of seal test but then i moved it to before start of 
// seal test. but still kept using tBaselineEnd0 to extrapolate the exp. to 
// get amplitude at start of seal test. that is wrong. therefore separating tSealTestStart0. bug reported by kiran   // Feb.28th 2008 Praveen
	
//	y1=WorkVar3+amp*exp(-tBaselineEnd/t0)
//	y1=WorkVar3+amp*exp(-tSealTestStart/t0)
//	y1=WorkVar3+amp*exp(-(tSealTestStart- tExp1FitStart)/t0)		//07/14/2008
	y1 = (SealTestAmp_V > 0) ? V_Max : V_Min
	
//	TempRs=(y1-WorkVar1)/(abs(SealTestAmp_I)*1e-9)			
	TempRs = (SealTestAmp_V)/(y1-WorkVar1)					//07/14/2008
	If (numtype(TempRs)==0 && TempRs>0 && TempRs<100e6) 			// weird values shud be avoided...cause probs in data processing later
	SumRs+=TempRs
	TempNumRs+=1
	Endif
	
//	TempRin=((WorkVar2-WorkVar1)/(abs(SealTestAmp_I)*1e-9))-TempRs
//	TempRin =(abs(SealTestAmp_V)/(WorkVar2-WorkVar1))-TempRs
	TempRin =((SealTestAmp_V)/(WorkVar2-WorkVar1))-TempRs			//07/14/2008
	If (numtype(TempRin)==0 && TempRin>0 && TempRin<1500e6) 	     // weird values shud be avoided...cause probs in data processing later
	SumRin+=TempRin
	TempNumRin+=1
	Endif
	
//	TempCm =t0/(TempRs*TempRin/(TempRs+TempRin))							
//	TempCm=t0/TempRin	
//	pt_expfit(w1,WorkVar2, tExpFitStart+0.0001, tExpFitEnd+0.001, amp, t0)					
//	WorkVar3			=	mean(w1,tExp2SteadyStateStart,tExp2SteadyStateEnd)
//	pt_expfit(w1,WorkVar3, tExp2FitStart, tExp2FitEnd, amp, t0)

Make /D/O/N=3 W_FitCoeff = Nan
Duplicate /O  w1, fit2_w1
fit2_w1= Nan

Variable V_FitOptions=4  // (suppress CurveFit info window)
Variable V_FitError=0      // (suppress abortion of fit on error)
CurveFit /NTHR=0/TBOX=0/Q exp_XOffset,  kwCWave=W_FitCoeff, w1 (tExp2FitStart, tExp2FitEnd) /D = fit2_w1

WorkVar4	= W_FitCoeff[0]
//amp 		= W_FitCoeff[1]
t0			= W_FitCoeff[3]

If (		(NumType(W_FitCoeff[0])!=0) || (NumType(W_FitCoeff[1])!=0) || (NumType(W_FitCoeff[2])!=0)		)
	Print "																			"
	Print "Fitting error: y0, A, Tau =", WorkVar4, amp,t0, "in", CurrentRsRinCmImWName
EndIf
			
	
//	TempRIn1=(abs(SealTestAmp_V)/(WorkVar3-WorkVar1))-TempRs
	TempRIn1=((SealTestAmp_V)/(WorkVar4-WorkVar1))-TempRs
	TempCm=t0/(TempRs*TempRin1/(TempRs+TempRin1))							
	If (numtype(TempCm)==0 && TempCm>0 && TempCm<1500e-12) 	   			// weird values shud be avoided...cause probs in data processing later
	SumCm+=TempCm
	TempNumCm+=1
	Endif
	
//	TempIm = SealTestAmp_V<0  ? -WorkVar1 : WorkVar1
	TempIm = WorkVar1
	If (numtype(TempIm)==0 && TempIm>-200e-3 && TempIm<+200e-3) 	    // weird values shud be avoided...cause probs in data processing later
	SumIm+=TempIm
	TempNumIm+=1
	Endif
	
	TempTau = t0
	If (numtype(TempTau)==0 && TempTau>0 && TempTau<100e-3) 	    // weird values shud be avoided...cause probs in data processing later
	SumTau+=TempTau
	TempNumTau+=1
	EndIf

DisplayResults=0
If (DisplayResults)
Display
DoWindow pt_RsRinCmVmVclamp2Display
	If (V_Flag)
		DoWindow /F pt_RsRinCmVmVclamp2Display
//		Sleep 00:00:01
		DoWindow /K pt_RsRinCmVmVclamp2Display
	EndIf
DoWindow /c pt_RsRinCmVmVclamp2Display
	
//		AppendToGraph /W=pt_RsRinCmVmVclamp2Display w1, fit_w1, fit2_w1
		AppendToGraph /W=pt_RsRinCmVmVclamp2Display w1,  fit2_w1
		SetAxis Bottom tBaselineStart, tSteadyStateEnd
		SetAxis /A=2 Left 
		SetDrawEnv textxjust= 2,textyjust= 2, fsize=08;DelayUpdate
		DrawText 1,0,CurrentRsRinCmImWName
		ModifyGraph rgb(fit2_w1)=(0,0,0)
		ModifyGraph lsize(fit2_w1)=2
//		Cursor A w1 0.5*(tBaselineStart+tBaselineEnd), WorkVar1
//		Cursor A w1 WorkVar2, WorkVar1
		Make /O/N=1 RsRinCmVmBLW, RsRinCmVmSSW, RsRinCmVmExpPkW
		Make /O/N=1 RsRinCmVmBLWX, RsRinCmVmSSWX, RsRinCmVmExpPkWX
		RsRinCmVmBLWX		= 0.5*(tBaselineStart+tBaselineEnd)
		RsRinCmVmBLW		= WorkVar1
		
		RsRinCmVmSSWX		= 0.5*(tSteadyStateStart+tSteadyStateEnd)
		RsRinCmVmSSW		= WorkVar2
		
		RsRinCmVmExpPkWX	= (SealTestAmp_V > 0) ? V_MaxLoc : V_MinLoc
		RsRinCmVmExpPkW		= y1
		
		AppendToGraph /W=pt_RsRinCmVmVclamp2Display RsRinCmVmBLW		vs RsRinCmVmBLWX
		ModifyGraph mode(RsRinCmVmBLW)=3
		ModifyGraph marker(RsRinCmVmBLW)=19
		ModifyGraph rgb(RsRinCmVmBLW)=(0,15872,65280)
		
		AppendToGraph /W=pt_RsRinCmVmVclamp2Display RsRinCmVmSSW		vs RsRinCmVmSSWX
		ModifyGraph mode(RsRinCmVmSSW)=3
		ModifyGraph marker(RsRinCmVmSSW	)=16
		ModifyGraph rgb(RsRinCmVmSSW)=(0,15872,65280)
		
		AppendToGraph /W=pt_RsRinCmVmVclamp2Display RsRinCmVmExpPkW	vs RsRinCmVmExpPkWX
		ModifyGraph mode(RsRinCmVmExpPkW)=3
		ModifyGraph marker(RsRinCmVmExpPkW)=17
		ModifyGraph rgb(RsRinCmVmExpPkW)=(0,15872,65280)
		
		Legend/C/N=text0/J/F=0/A=RC "\\Z08\\s(RsRinCmVmBLW) BaseLineW\r\\s(RsRinCmVmSSW) SteadyState\r\\s(RsRinCmVmExpPkW) RsTransient"
		DoUpdate
		Sleep /T 30
		
//DoWindow pt_RsRinCmVmVclamp2Display				05_20_2008
//	If (V_Flag)
//		DoWindow /F pt_RsRinCmVmVclamp2Display
//		Sleep 00:00:02
//		DoWindow /K pt_RsRinCmVmVclamp2Display
//	EndIf

EndIf


	
	EndFor
	
	Rs		=	SumRs	/	TempNumRs
	Rin		=	SumRin	/	TempNumRin
	Cm		=	SumCm	/	TempNumCm
	Im		=	SumIm	/	TempNumIm
	Tau		=	SumTau	/	TempNumTau
	KillWaves /z w1, fit2_w1							
	KillWaves /z RsRinCmVmBLW, RsRinCmVmSSW, RsRinCmVmExpPkW
	KillWaves /z RsRinCmVmBLWX, RsRinCmVmSSWX, RsRinCmVmExpPkWX
	
return 1
end






Function pt_EPhysDisplay()
// display data: Check if the window EPhysDisplayWin exists? 
// if yes, append. If no, create and append

NVAR EPhysInstNum			=root:EPhysInstNum
//If (!StringMatch(button0, "TrigGen"))
//	EPhysInstNum			= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:EPhysVars"+Num2Str(EPhysInstNum)
//String EPhysPanelName 	= "EPhysMain"+Num2Str(EPhysInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////


String WName

NVAR EPhys_VClmp 				=$FldrName+":EPhys_VClmp"
NVAR EPhysPairedRecVarVal		=root:AnalyzeDataVars:EPhysPairedRecVarVal
SVAR EPhysPrevDisplayMode		=$FldrName+":EPhysPrevDisplayMode"
SVAR EPhysCurrentDisplayMode	=$FldrName+":EPhysCurrentDisplayMode"
SVAR EPhysFldrsList				= root:TrigGenVars:EPhysFldrsList	
SVAR ListEPhysInCh				= root:TrigGenVars:ListEPhysInCh

Variable NumEPhysFldrs = ItemsInList(EPhysFldrsList, ";")

Variable RedInt, GreenInt, BlueInt//, TraceNum
Variable i, NSubWin, EPhysDisplayHostWinXSize=700, EPhysDisplayHostWinYSize=600, SubWinYSize, EPhysChSlctd=0
Variable j,NCursorDiffGraphList
String GraphWinName = ""

String CurrSubWinName
pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)

sscanf FldrName+"In", "root:%s", WName
Wave EPhysInWave = $(FldrName+":"+WName)

//Wave EPhysOutWave 	=  $(FldrName+":"+FldrName+"Out")

String TraceNameStr = WName

If (EPhys_VClmp==0)
	EPhysCurrentDisplayMode = "EPhysIClmp"
Else
	EPhysCurrentDisplayMode = "EPhysVClmp"
EndIf
	
If (StringMatch(EPhysPrevDisplayMode, ""))
	EPhysPrevDisplayMode = EPhysCurrentDisplayMode
EndIf

// logic - figure out how many ephys channels are we scanning
// num of subwindows = num of ephys channels 
// each channel gets added to all subwindows
// user zooms into different parts in each subwindow
If (EPhysPairedRecVarVal)
NSubWin = NumEPhysFldrs
SubWinYSize = EPhysDisplayHostWinYSize/NSubWin
DoWindow EPhysDisplayHostWin
If (!V_Flag)
Display /K=1 /W=(0,0,EPhysDisplayHostWinXSize,EPhysDisplayHostWinYSize)
DoWindow /C EPhysDisplayHostWin 
For (i=0; i<NSubWin; i+=1)
Display /k=1/Host=EPhysDisplayHostWin /W=(0,i*SubWinYSize, EPhysDisplayHostWinXSize, (i+1)*SubWinYSize)/N=$"EPhysDisplaySubWin"+Num2Str(i+1)
EndFor
EndIf
//&&&&&&&&&&&&&&&&&&&&&&&&&&&&
For (i=0; i<NSubWin; i+=1)
	EPhysChSlctd =FindListItem(Num2Str(i+1), ListEPhysInCh, ";")
	If (EPhysChSlctd !=-1)
	CurrSubWinName = "EPhysDisplayHostWin#EPhysDisplaySubWin"+Num2Str(i+1)
	If (FindListItem(WName, TraceNameList("EPhysDisplayHostWin#EPhysDisplaySubWin"+Num2Str(i+1), ";", 1), ";")==-1)
	If (EPhys_VClmp==0)
	AppendToGraph /L /W =$CurrSubWinName EPhysInWave		// I-Clamp
	EPhysPrevDisplayMode = "EPhysIClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0

//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
	ModifyGraph /W =$CurrSubWinName rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
	Label /W =$CurrSubWinName left "Voltage (V)"
	Legend /W =$CurrSubWinName /C/N=text0/F=0/A=RT
	
	If (WaveExists($"root:AnalyzeDataVars:pt_PairedRecDispRngParWX") && WaveExists($"root:AnalyzeDataVars:pt_PairedRecDispRngParWY"))
	Wave /T AnalParWX = $"root:AnalyzeDataVars:pt_PairedRecDispRngParWX"
	Wave /T AnalParWY = $"root:AnalyzeDataVars:pt_PairedRecDispRngParWY"
	SetAxis /W =$CurrSubWinName Bottom Str2Num(AnalParWX[i][0]), Str2Num(AnalParWX[i][1])
	SetAxis /W =$CurrSubWinName Left Str2Num(AnalParWY[i][0]), Str2Num(AnalParWY[i][1])	
	EndIf
	
	Else
	AppendToGraph /R /W =$CurrSubWinName EPhysInWave		// V-Clamp
	EPhysPrevDisplayMode = "EPhysVClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0
//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
	ModifyGraph /W =$CurrSubWinName rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
	Label /W =$CurrSubWinName right "Current (A)"
	Legend /W =$CurrSubWinName /C/N=text0/F=0/A=RT
	
	If (WaveExists($"root:AnalyzeDataVars:pt_PairedRecDispRngParWX") && WaveExists($"root:AnalyzeDataVars:pt_PairedRecDispRngParWY"))
	Wave /T AnalParWX = $"root:AnalyzeDataVars:pt_PairedRecDispRngParWX"
	Wave /T AnalParWY = $"root:AnalyzeDataVars:pt_PairedRecDispRngParWY"
	SetAxis /W =$CurrSubWinName Bottom Str2Num(AnalParWX[i][0]), Str2Num(AnalParWX[i][1])
	SetAxis /W =$CurrSubWinName Right Str2Num(AnalParWY[i][0]), Str2Num(AnalParWY[i][1])	
	EndIf
	
	EndIf

	Else	// trace is there on graph but  V-clamp/ I-Clamp mode may 
			// have changed since last time. 
//	Print TraceNameList("EPhysDisplayWin", ";", 1)

	
	
//	EPhysCurrentDisplayMode = (EPhys_VClmp==0) ? "EPhysIClmp" : "EPhysVClmp"
	If (StringMatch(EPhysCurrentDisplayMode, EPhysPrevDisplayMode) ==0)	// Modes have changed since last display
	RemoveFromGraph /W =$CurrSubWinName $TraceNameStr
	If (EPhys_VClmp==0)
	AppendToGraph /L /W =$CurrSubWinName EPhysInWave		// I-Clamp
	EPhysPrevDisplayMode = "EPhysIClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0
//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
	ModifyGraph /W =$CurrSubWinName rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
	Label /W =$CurrSubWinName left "Voltage (V)"
	Legend /W =$CurrSubWinName /C/N=text0/F=0/A=RT
	
	If (WaveExists($"root:AnalyzeDataVars:pt_PairedRecDispRngParWX") && WaveExists($"root:AnalyzeDataVars:pt_PairedRecDispRngParWY"))
	Wave /T AnalParWX = $"root:AnalyzeDataVars:pt_PairedRecDispRngParWX"
	Wave /T AnalParWY = $"root:AnalyzeDataVars:pt_PairedRecDispRngParWY"
	SetAxis /W =$CurrSubWinName Bottom Str2Num(AnalParWX[i][0]), Str2Num(AnalParWX[i][1])
	SetAxis /W =$CurrSubWinName Left Str2Num(AnalParWY[i][0]), Str2Num(AnalParWY[i][1])	
	EndIf
	
	
	Else
	AppendToGraph /R /W =$CurrSubWinName EPhysInWave		// V-Clamp
	EPhysPrevDisplayMode = "EPhysVClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0
//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
	ModifyGraph /W =$CurrSubWinName rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
	Label /W =$CurrSubWinName right "Current (A)"
	Legend /W =$CurrSubWinName /C/N=text0/F=0/A=RT
	
	If (WaveExists($"root:AnalyzeDataVars:pt_PairedRecDispRngParWX") && WaveExists($"root:AnalyzeDataVars:pt_PairedRecDispRngParWY"))
	Wave /T AnalParWX = $"root:AnalyzeDataVars:pt_PairedRecDispRngParWX"
	Wave /T AnalParWY = $"root:AnalyzeDataVars:pt_PairedRecDispRngParWY"
	SetAxis /W =$CurrSubWinName Bottom Str2Num(AnalParWX[i][0]), Str2Num(AnalParWX[i][1])
	SetAxis /W =$CurrSubWinName Right Str2Num(AnalParWY[i][0]), Str2Num(AnalParWY[i][1])	
	EndIf
	
	EndIf
	EndIf
	EndIf
	EndIf //	If (StringMatch(ListEPhysInCh, Num2Str(i+1))
EndFor	
//&&&&&&&&&&&&&&&&&&&&&&&&&&&&
Else	//If (EPhysPairedRecVarVal)

DoWindow EPhysDisplayWin
If (V_Flag)

// Check if the trace is not on graph
//	Print TraceNameList("EPhysDisplayWin", ";", 1)
	If (FindListItem(WName, TraceNameList("EPhysDisplayWin", ";", 1), ";")==-1)
	If (EPhys_VClmp==0)
	AppendToGraph /L /W =EPhysDisplayWin EPhysInWave		// I-Clamp
	EPhysPrevDisplayMode = "EPhysIClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0

//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
	ModifyGraph /W =EPhysDisplayWin rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
	Label /W =EPhysDisplayWin left "Voltage (V)"
	Legend /W =EPhysDisplayWin /C/N=text0/F=0/A=RT
	Else
	AppendToGraph /R /W =EPhysDisplayWin EPhysInWave		// V-Clamp
	EPhysPrevDisplayMode = "EPhysVClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0
//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
	ModifyGraph /W =EPhysDisplayWin rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
	Label /W =EPhysDisplayWin right "Current (A)"
	Legend /W =EPhysDisplayWin /C/N=text0/F=0/A=RT
	EndIf

	Else	// trace is there on graph but  V-clamp/ I-Clamp mode may 
			// have changed since last time. 
//	Print TraceNameList("EPhysDisplayWin", ";", 1)

	
	
//	EPhysCurrentDisplayMode = (EPhys_VClmp==0) ? "EPhysIClmp" : "EPhysVClmp"
	If (StringMatch(EPhysCurrentDisplayMode, EPhysPrevDisplayMode) ==0)	// Modes have changed since last display
	RemoveFromGraph /W =EPhysDisplayWin $TraceNameStr
	If (EPhys_VClmp==0)
	AppendToGraph /L /W =EPhysDisplayWin EPhysInWave		// I-Clamp
	EPhysPrevDisplayMode = "EPhysIClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0
//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
	ModifyGraph /W =EPhysDisplayWin rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
	Label /W =EPhysDisplayWin left "Voltage (V)"
	Legend /W =EPhysDisplayWin /C/N=text0/F=0/A=RT
	Else
	AppendToGraph /R /W =EPhysDisplayWin EPhysInWave		// V-Clamp
	EPhysPrevDisplayMode = "EPhysVClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0
//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
	ModifyGraph /W =EPhysDisplayWin rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
	Label /W =EPhysDisplayWin right "Current (A)"
	Legend /W =EPhysDisplayWin /C/N=text0/F=0/A=RT
	EndIf
	EndIf
	EndIf
//	DoWindow /K EPhysDisplayWin
	
Else
	Display 
	DoWindow /C EPhysDisplayWin
	If (EPhys_VClmp==0)
	AppendToGraph /L /W =EPhysDisplayWin EPhysInWave		// I-Clamp
	EPhysPrevDisplayMode 		= "EPhysIClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0
//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
	ModifyGraph /W =EPhysDisplayWin rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
	Label /W =EPhysDisplayWin left "Voltage (V)"
	Legend /W =EPhysDisplayWin /C/N=text0/F=0/A=RT
	Else
	AppendToGraph /R /W =EPhysDisplayWin EPhysInWave		// V-Clamp
	EPhysPrevDisplayMode 		= "EPhysVClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0
//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
	ModifyGraph /W =EPhysDisplayWin rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
	Label /W =EPhysDisplayWin right "Current (A)"
	Legend /W =EPhysDisplayWin /C/N=text0/F=0/A=RT
	EndIf
	
//	AppendToGraph /R /W =EPhysDisplayWin EPhysOutWave
EndIf
EndIf //If (EPhysPairedRecVarVal)


//ControlInfo /W=AnalyzeDataMain EPhysSealTestVarName
//If (V_Value)		// Carry out seal-test Analsis

//ControlInfo /W=AnalyzeDataMain EPhysSealTestVarName
NVAR EPhysSealTestVarVal = root:AnalyzeDataVars:EPhysSealTestVarVal

If (EPhysSealTestVarVal)		// Carry out seal-test Analsis

 
String RsVWName
sscanf FldrName+"RsV", "root:%s", RsVWName
pt_EPhysDisplayScalarParWWin("RsV", "Ohms", FldrName, RedInt, GreenInt, BlueInt)		// like Rs, RIn, Im, Vm, EPSP, EPSC (Wave of a scalar parameter calculated once per acquisition)

String RInVWName
sscanf FldrName+"RInV", "root:%s", RInVWName
pt_EPhysDisplayScalarParWWin("RInV", "Ohms", FldrName, RedInt, GreenInt, BlueInt)		// like Rs, RIn, Im, Vm, EPSP, EPSC (Wave of a scalar parameter calculated once per acquisition)

If (EPhys_VClmp==0)	// Current clamp
String VmVWName
sscanf FldrName+"VmV", "root:%s", VmVWName
pt_EPhysDisplayScalarParWWin("VmV", "V", FldrName, RedInt, GreenInt, BlueInt)		// like Rs, RIn, Im, Vm, EPSP, EPSC (Wave of a scalar parameter calculated once per acquisition)
Else				// VClamp
String ImVWName
sscanf FldrName+"ImV", "root:%s", ImVWName
pt_EPhysDisplayScalarParWWin("ImV", "A", FldrName, RedInt, GreenInt, BlueInt)		// like Rs, RIn, Im, Vm, EPSP, EPSC (Wave of a scalar parameter calculated once per acquisition)
EndIf

EndIf

NVAR EPhysFICurveVarVal = root:AnalyzeDataVars:EPhysFICurveVarVal
If (EPhysFICurveVarVal)	// Carry out FI Curve Analsis

//String  FIFreqVWName, FICurrVWName

//sscanf FldrName+"FIFreqVW", "root:%s", FIFreqVWName
//sscanf FldrName+"FICurrVW", "root:%s", FICurrVWName
 
//String RsVWName
//sscanf FldrName+"RsV", "root:%s", RsVWName
pt_EPhysDisplayScalarXYParWWin("FIFreqVW","FICurrVW", "Hz","Amp",FldrName, RedInt, GreenInt, BlueInt)		// like Rs, RIn, Im, Vm, EPSP, EPSC (Wave of a scalar parameter calculated once per acquisition)

EndIf

NVAR EPhysSynRespVarVal = root:AnalyzeDataVars:EPhysSynRespVarVal
String YUnitsStr
If (EPhysSynRespVarVal)	// Carry out Synaptic response Analsis

//String  FIFreqVWName, FICurrVWName

//sscanf FldrName+"FIFreqVW", "root:%s", FIFreqVWName
//sscanf FldrName+"FICurrVW", "root:%s", FICurrVWName
 
//String RsVWName
//sscanf FldrName+"RsV", "root:%s", RsVWName
If (EPhys_VClmp==0) // IClamp
YUnitsStr =  "V"
Else
YUnitsStr=	"I"		// VClamp
EndIf
// Displaying only the 1st response for the time being
pt_EPhysDisplayScalarParWWin("InSR0RelPkYV", YUnitsStr, FldrName, RedInt, GreenInt, BlueInt)			// like Rs, RIn, Im, Vm, EPSP, EPSC (Wave of a scalar parameter calculated once per acquisition)

EndIf

NVAR EPhysSRXYOptScVarVal = root:AnalyzeDataVars:EPhysSRXYOptScVarVal

If (EPhysSRXYOptScVarVal)	// Display Synaptic response for XY Opt Scan
pt_EPhysDisplayScalarXYZParWWin("XVal", "YVal", "InSR0BolnV", "root:ScanMirrorVars1", "root:ScanMirrorVars1", FldrName,TraceNameStr,"CurrentImageDisplayWin", RedInt, GreenInt, BlueInt)
EndIf // If (EPhysSynRespVarVal)

//pt_PlotCursorDiff
SVAR CursorDiffGraphList = root:AnalyzeDataVars:CursorDiffGraphList
NCursorDiffGraphList = ItemsInList(CursorDiffGraphList)
If (NCursorDiffGraphList > 0)
//For (j =0; j< NCursorDiffGraphList; j +=1) // we want to call only once per instance 02/10/14
	GraphWinName = StringFromList(EPhysInstNum - 1, CursorDiffGraphList, ";")	// assume 1st graph in list is for channel 1 and so on
	DoWindow $GraphWinName
	If (V_Flag)
		pt_PlotCursorDiff(GraphWinName, 3e-4)
	EndIf
//EndFor
EndIf

End


Function pt_EPhysDisplayScalarParWWin(ParName, ParUnits, FldrName, RedInt, GreenInt, BlueInt)
String ParName, ParUnits, FldrName
Variable RedInt, GreenInt, BlueInt

String ParVWName
sscanf FldrName+ParName, "root:%s", ParVWName
Wave ParWave = $(FldrName+":"+ParVWName)

String TraceNameStr = ParVWName

String DisplayWinName = "EPhys"+ParName+"DisplayWin"
DoWindow $(DisplayWinName)
If (V_Flag)

// Check if the trace is not on graph
//	Print TraceNameList("EPhysDisplayWin", ";", 1)
	If (FindListItem(ParVWName, TraceNameList(DisplayWinName, ";", 1), ";")==-1)
//	If (EPhys_VClmp==0)
	AppendToGraph /L /W =$(DisplayWinName) ParWave		// I-Clamp
//	EPhysPrevDisplayMode = "EPhysIClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0

//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
	ModifyGraph /W =$(DisplayWinName) rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
	Label /W =$(DisplayWinName) left ParName+"("+ParUnits+")"
	Legend /W =$(DisplayWinName) /C/N=text0/F=0/A=RT
//	Else
//	AppendToGraph /R /W =EPhysDisplayWin EPhysInWave		// V-Clamp
//	EPhysPrevDisplayMode = "EPhysVClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0
//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
//	ModifyGraph /W =EPhysDisplayWin rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
//	Label /W =EPhysDisplayWin right "Current (A)"
//	Legend /W =EPhysDisplayWin /C/N=text0/F=0/A=RT
//	EndIf

//	Else	// trace is there on graph but  V-clamp/ I-Clamp mode may 
			// have changed since last time. 
//	Print TraceNameList("EPhysDisplayWin", ";", 1)

	
	
//	EPhysCurrentDisplayMode = (EPhys_VClmp==0) ? "EPhysIClmp" : "EPhysVClmp"
//	If (StringMatch(EPhysCurrentDisplayMode, EPhysPrevDisplayMode) ==0)	// Modes have changed since last display
//	RemoveFromGraph /W =EPhysDisplayWin $TraceNameStr
//	If (EPhys_VClmp==0)
//	AppendToGraph /L /W =EPhysDisplayWin EPhysInWave		// I-Clamp
//	EPhysPrevDisplayMode = "EPhysIClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0
//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
//	ModifyGraph /W =EPhysDisplayWin rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
//	Label /W =EPhysDisplayWin left "Voltage (V)"
//	Legend /W =EPhysDisplayWin /C/N=text0/F=0/A=RT
//	Else
//	AppendToGraph /R /W =EPhysDisplayWin EPhysInWave		// V-Clamp
//	EPhysPrevDisplayMode = "EPhysVClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0
//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
//	ModifyGraph /W =EPhysDisplayWin rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
//	Label /W =EPhysDisplayWin right "Current (A)"
//	Legend /W =EPhysDisplayWin /C/N=text0/F=0/A=RT
//	EndIf
//	EndIf
	EndIf
//	DoWindow /K EPhysDisplayWin
	
Else
	Display 
	DoWindow /C $(DisplayWinName)
//	If (EPhys_VClmp==0)
	AppendToGraph /L /W =$(DisplayWinName) ParWave	// I-Clamp
//	EPhysPrevDisplayMode 		= "EPhysIClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0
//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
	ModifyGraph /W =$(DisplayWinName) rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
	Label /W =$(DisplayWinName) left ParName+"("+ParUnits+")"
	Legend /W =$(DisplayWinName) /C/N=text0/F=0/A=RT
//	Else
//	AppendToGraph /R /W =EPhysDisplayWin EPhysInWave		// V-Clamp
//	EPhysPrevDisplayMode 		= "EPhysVClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0
//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
//	ModifyGraph /W =EPhysDisplayWin rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
//	Label /W =EPhysDisplayWin right "Current (A)"
//	Legend /W =EPhysDisplayWin /C/N=text0/F=0/A=RT
//	EndIf
	
//	AppendToGraph /R /W =EPhysDisplayWin EPhysOutWave
EndIf



End

Function pt_EPhysDisplayScalarXYParWWin(YParName, XParName, YParUnits, XParUnits, FldrName, RedInt, GreenInt, BlueInt)
String YParName, XParName, YParUnits, XParUnits, FldrName
Variable RedInt, GreenInt, BlueInt

String YParVWName
sscanf FldrName+YParName, "root:%s", YParVWName
Wave YParWave = $(FldrName+":"+YParVWName)

String XParVWName
sscanf FldrName+XParName, "root:%s", XParVWName
Wave XParWave = $(FldrName+":"+XParVWName)

String TraceNameStr = YParVWName

String DisplayWinName = "EPhys"+YParName+"DisplayWin"
DoWindow $(DisplayWinName)
If (V_Flag)

// Check if the trace is not on graph
//	Print TraceNameList("EPhysDisplayWin", ";", 1)
	If (FindListItem(YParVWName, TraceNameList(DisplayWinName, ";", 1), ";")==-1)
//	If (EPhys_VClmp==0)
	AppendToGraph /L /W =$(DisplayWinName) YParWave vs XParWave		// I-Clamp
//	EPhysPrevDisplayMode = "EPhysIClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0

//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
	ModifyGraph /W =$(DisplayWinName) rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	ModifyGraph /W =$(DisplayWinName) mode =3
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
	Label /W =$(DisplayWinName) left 		YParName +"("+YParUnits+")"
	Label /W =$(DisplayWinName) Bottom 	XParName +"("+XParUnits+")"
	Legend /W =$(DisplayWinName) /C/N=text0/F=0/A=RT
//	Else
//	AppendToGraph /R /W =EPhysDisplayWin EPhysInWave		// V-Clamp
//	EPhysPrevDisplayMode = "EPhysVClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0
//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
//	ModifyGraph /W =EPhysDisplayWin rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
//	Label /W =EPhysDisplayWin right "Current (A)"
//	Legend /W =EPhysDisplayWin /C/N=text0/F=0/A=RT
//	EndIf

//	Else	// trace is there on graph but  V-clamp/ I-Clamp mode may 
			// have changed since last time. 
//	Print TraceNameList("EPhysDisplayWin", ";", 1)

	
	
//	EPhysCurrentDisplayMode = (EPhys_VClmp==0) ? "EPhysIClmp" : "EPhysVClmp"
//	If (StringMatch(EPhysCurrentDisplayMode, EPhysPrevDisplayMode) ==0)	// Modes have changed since last display
//	RemoveFromGraph /W =EPhysDisplayWin $TraceNameStr
//	If (EPhys_VClmp==0)
//	AppendToGraph /L /W =EPhysDisplayWin EPhysInWave		// I-Clamp
//	EPhysPrevDisplayMode = "EPhysIClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0
//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
//	ModifyGraph /W =EPhysDisplayWin rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
//	Label /W =EPhysDisplayWin left "Voltage (V)"
//	Legend /W =EPhysDisplayWin /C/N=text0/F=0/A=RT
//	Else
//	AppendToGraph /R /W =EPhysDisplayWin EPhysInWave		// V-Clamp
//	EPhysPrevDisplayMode = "EPhysVClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0
//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
//	ModifyGraph /W =EPhysDisplayWin rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
//	Label /W =EPhysDisplayWin right "Current (A)"
//	Legend /W =EPhysDisplayWin /C/N=text0/F=0/A=RT
//	EndIf
//	EndIf
	EndIf
//	DoWindow /K EPhysDisplayWin
	
Else
	Display 
	DoWindow /C $(DisplayWinName)
//	If (EPhys_VClmp==0)
	AppendToGraph /L /W =$(DisplayWinName) YParWave	vs XParWave// I-Clamp
//	EPhysPrevDisplayMode 		= "EPhysIClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0
//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
	ModifyGraph /W =$(DisplayWinName) rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	ModifyGraph /W =$(DisplayWinName) mode =3
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
	Label /W =$(DisplayWinName) left 		YParName +"("+YParUnits+")"
	Label /W =$(DisplayWinName) Bottom 	XParName +"("+XParUnits+")"
	Legend /W =$(DisplayWinName) /C/N=text0/F=0/A=RT
//	Else
//	AppendToGraph /R /W =EPhysDisplayWin EPhysInWave		// V-Clamp
//	EPhysPrevDisplayMode 		= "EPhysVClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0
//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
//	ModifyGraph /W =EPhysDisplayWin rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
//	Label /W =EPhysDisplayWin right "Current (A)"
//	Legend /W =EPhysDisplayWin /C/N=text0/F=0/A=RT
//	EndIf
	
//	AppendToGraph /R /W =EPhysDisplayWin EPhysOutWave
EndIf



End

//--------
Function pt_EPhysDisplayScalarXYZParWWin(XParName, YParName, ZParName, XParFldrName, YParFldrName, ZParFldrName, TraceNameStr, DisplayWinName, RedInt, GreenInt, BlueInt)
String XParName, YParName, ZParName, XParFldrName, YParFldrName, ZParFldrName, TraceNameStr, DisplayWinName
Variable RedInt, GreenInt, BlueInt

String XParVWName
sscanf XParFldrName+XParName, "root:%s", XParVWName
Wave XParWave = $(XParFldrName+":"+XParVWName)

String YParVWName
sscanf YParFldrName+YParName, "root:%s", YParVWName
Wave YParWave = $(YParFldrName+":"+YParVWName)

String ZParVWName
sscanf ZParFldrName+ZParName, "root:%s", ZParVWName
Wave ZParWave = $(ZParFldrName+":"+ZParVWName)

Print "XParWave, YParWave, ZParWave", XParWave, YParWave, ZParWave
//String TraceNameStr = YParVWName+"#"+Num2Str(TraceInstanceNum)
Print XParFldrName, YParFldrName, ZParFldrName
//String DisplayWinName = "EPhys"+ZParName+"DisplayWin"
DoWindow $(DisplayWinName)
If (V_Flag)

// Check if the trace is not on graph
//	Print TraceNameList("EPhysDisplayWin", ";", 1)
	If (FindListItem(TraceNameStr, TraceNameList(DisplayWinName, ";", 1), ";")==-1)
//	If (EPhys_VClmp==0)
	//AppendToGraph /L/T/W =$(DisplayWinName) YParWave vs XParWave/TN=$TraceNameStr		// I-Clamp
	AppendToGraph  /L/T/W =$(DisplayWinName) YParWave/TN=$TraceNameStr vs XParWave		// I-Clamp
	Print TraceNameStr
//	EPhysPrevDisplayMode = "EPhysIClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0

//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
	ModifyGraph /W =$(DisplayWinName) rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	ModifyGraph /W =$(DisplayWinName) mode($TraceNameStr) =3
	ModifyGraph /W =$(DisplayWinName) zmrkNum($TraceNameStr)={$(ZParFldrName+":"+ZParVWName)}
	Legend /W =$(DisplayWinName) /C/N=text0/F=0/A=RT
// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
////	Label /W =$(DisplayWinName) left 		YParName +"("+YParUnits+")"
////	Label /W =$(DisplayWinName) Bottom 	XParName +"("+XParUnits+")"
////	Legend /W =$(DisplayWinName) /C/N=text0/F=0/A=RT
//	Else
//	AppendToGraph /R /W =EPhysDisplayWin EPhysInWave		// V-Clamp
//	EPhysPrevDisplayMode = "EPhysVClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0
//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
//	ModifyGraph /W =EPhysDisplayWin rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
//	Label /W =EPhysDisplayWin right "Current (A)"
//	Legend /W =EPhysDisplayWin /C/N=text0/F=0/A=RT
///	EndIf

//	Else	// trace is there on graph but  V-clamp/ I-Clamp mode may 
			// have changed since last time. 
//	Print TraceNameList("EPhysDisplayWin", ";", 1)

	
	
//	EPhysCurrentDisplayMode = (EPhys_VClmp==0) ? "EPhysIClmp" : "EPhysVClmp"
//	If (StringMatch(EPhysCurrentDisplayMode, EPhysPrevDisplayMode) ==0)	// Modes have changed since last display
//	RemoveFromGraph /W =EPhysDisplayWin $TraceNameStr
//	If (EPhys_VClmp==0)
//	AppendToGraph /L /W =EPhysDisplayWin EPhysInWave		// I-Clamp
//	EPhysPrevDisplayMode = "EPhysIClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0
//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
//	ModifyGraph /W =EPhysDisplayWin rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
//	Label /W =EPhysDisplayWin left "Voltage (V)"
//	Legend /W =EPhysDisplayWin /C/N=text0/F=0/A=RT
//	Else
//	AppendToGraph /R /W =EPhysDisplayWin EPhysInWave		// V-Clamp
//	EPhysPrevDisplayMode = "EPhysVClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0
//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
//	ModifyGraph /W =EPhysDisplayWin rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
//	Label /W =EPhysDisplayWin right "Current (A)"
//	Legend /W =EPhysDisplayWin /C/N=text0/F=0/A=RT
//	EndIf
//	EndIf
	EndIf
//	DoWindow /K EPhysDisplayWin
	
Else
	DisplayWinName = "XYZDisplayWin"
	DoWindow $(DisplayWinName)
	If (V_Flag)
	If (FindListItem(YParVWName, TraceNameList(DisplayWinName, ";", 1), ";")==-1)
//	Display 
//	DoWindow /C $(DisplayWinName)
//	If (EPhys_VClmp==0)
	AppendToGraph /L/T/W =$(DisplayWinName) YParWave	vs XParWave// I-Clamp
	SetAxis /W =$(DisplayWinName)/A/R left
//	EPhysPrevDisplayMode 		= "EPhysIClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0
//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
	ModifyGraph /W =$(DisplayWinName) rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	ModifyGraph /W =$(DisplayWinName) mode =3
	ModifyGraph /W =$(DisplayWinName) zmrkNum($TraceNameStr)={$(ZParFldrName+":"+ZParVWName)}
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
////	Label /W =$(DisplayWinName) left 		YParName +"("+YParUnits+")"
////	Label /W =$(DisplayWinName) Bottom 	XParName +"("+XParUnits+")"
////	Legend /W =$(DisplayWinName) /C/N=text0/F=0/A=RT
//	Else
//	AppendToGraph /R /W =EPhysDisplayWin EPhysInWave		// V-Clamp
//	EPhysPrevDisplayMode 		= "EPhysVClmp"
//	TraceNum =ItemsInList(TraceNameList("EPhysDisplayWin", ";", 1)) -1	// count from 0
//	pt_TraceUserColor(EPhysInstNum-1, RedInt, GreenInt, BlueInt)
//	ModifyGraph /W =EPhysDisplayWin rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	// Temporary code start
//	SetAxis /W =EPhysDisplayWin bottom 0.5,0.8
//	SetAxis /W =EPhysDisplayWin right -150e-12,0e-12
	// Temporary code end
//	Label /W =EPhysDisplayWin right "Current (A)"
//	Legend /W =EPhysDisplayWin /C/N=text0/F=0/A=RT
//	EndIf
	
//	AppendToGraph /R /W =EPhysDisplayWin EPhysOutWave
	EndIf
	Else //If (V_Flag)
	Display
	DoWindow /C $(DisplayWinName)
	AppendToGraph /L/T/W =$(DisplayWinName) YParWave	vs XParWave// I-Clamp
	ModifyGraph /W =$(DisplayWinName) rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	ModifyGraph /W =$(DisplayWinName) mode =3
	ModifyGraph /W =$(DisplayWinName) zmrkNum($TraceNameStr)={$(ZParFldrName+":"+ZParVWName)}
	EndIf
EndIf




End
//--------

Function pt_TrigGenMain() : Panel

NewDataFolder /O root:TrigGenVars
Variable /G root:TrigGenVars:TicksFreq =60		// 60 ticks/s for windows; 60.15 ticks/s for mac. use msTimer for more accuracy.
Variable /G root:TrigGenVars:ISI = 60		// In secs
Variable /G root:TrigGenVars:ScanRunning = 0
Variable /G root:TrigGenVars:IterTot = 0
Variable /G root:TrigGenVars:IterLeft = 0
Variable /G root:TrigGenVars:RepsTot = 1
Variable /G root:TrigGenVars:RepsLeft = 0
Variable /G root:TrigGenVars:StopExpt = 0			// experiment stopped through stop button in TrigGenMain
Variable /G root:TrigGenVars:PauseExpt = 0			// experiment paused through pause button in TrigGenMain
//Variable /G root:TrigGenVars:NumEPhysInCh=0


String /G    root:TrigGenVars:WMatchStr=""
String /G    root:TrigGenVars:ListEPhysInCh=""
String /G    root:TrigGenVars:EPhysFldrsList=""

	

// =1 means all channels in demo mode. No DAQ command sent. Useful for debugging on a machine without NI cards.
// Still the NI drivers and NiDaqTools should be installed else the program won't compile
//Variable /G root:TrigGenVars:DemoMode = 0		


NVAR ISI 			= root:TrigGenVars:ISI
NVAR ScanRunning	= root:TrigGenVars:ScanRunning
NVAR IterTot 		= root:TrigGenVars:IterTot
NVAR IterLeft 		= root:TrigGenVars:IterLeft
NVAR RepsTot		= root:TrigGenVars:RepsTot
NVAR RepsLeft		= root:TrigGenVars:RepsLeft


Variable /G root:TrigGenVars:DebugMode = 0
NVAR        DebugMode = root:TrigGenVars:DebugMode

If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "*************************************"
EndIf

//NVAR DemoMode	= root:TrigGenVars:DemoMode

//Make /T/O/N=3 root:TrigGenVars:TrigGenHWName
//Make /T/O/N=3 root:TrigGenVars:TrigGenHWVal

// possible values (can add more parameters)
// Wave /T w = root:TrigGenVars:TrigGenHWName
//w[0] = "DevID"		Eg. Dev1;Dev2			// Number of devices should be equal to number of TrigSrc
//w[1] = "TrigSrc"      Eg. /PFI4					
//w[2] = "ClkSrc"      Eg. /20MHzTimeBase



	PauseUpdate; Silent 1		// building window...
//	NewPanel /W=(615,50,890,145)//(900,220,1175,280)
	NewPanel /W=(615,50,920,250)
	DoWindow /C TrigGenMain
	SetVariable setvar0,pos={5,37},size={80,16},title="ISI (s)"
	SetVariable setvar0,value= ISI
	SetVariable setvar1,pos={90,37},size={100,16},title="Iters/ Rep"
	SetVariable setvar1,value= IterTot, limits={0,inf,1}
	SetVariable setvar3,pos={195,37},size={105,16},title="Reps Tot"
	SetVariable setvar3,value= RepsTot,limits={0,inf,1}
	
	ValDisplay valdisp0,pos={89,65},size={90,16},title="Iter Left"
	ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000},value= #"root:TrigGenVars:IterLeft"//, disable =1
	ValDisplay valdisp1,pos={194,65},size={97,16},title="Reps Left"
	ValDisplay valdisp1,limits={0,0,0},barmisc={0,1000},value= #"root:TrigGenVars:RepsLeft"//, disable =1
	
	
	
	SetDrawLayer UserBack
	DrawLine 1,90,280,90
	DrawLine 1,155,280,155

	SetVariable setvar2,pos={1,100},size={210,48}, title ="StimWMatchStr"
	SetVariable setvar2,value=  $("root:TrigGenVars:WMatchStr")
	
	Button button4,pos={5,130},size={80,20},title="Stimulus Pattern"
	Button button4,proc = pt_TrigGenStimulusPattern
	Button button5,pos={216,130},size={50,20},title="Update"
	Button button5,proc = pt_TrigGenStimulusPatternUpdate
	
	Button button6,pos={110,130},size={50,20},title="Search"
	Button button6,proc = pt_TrigGenChInOutSearch
	
	
//	Button button0,pos={216,70},size={50,20},title="Start"
	Button button0,pos={216,170},size={50,20},title="Start"
	Button button0,proc = pt_TrigGenStart
//	Button button1,pos={5,70},size={50,20},title="Stop"
	Button button1,pos={5,170},size={50,20},title="Stop"
	Button button1,proc = pt_TrigGenStop
	Button button7,pos={65,170},size={50,20},title="Pause"
	Button button7,proc = pt_TrigGenPause
//	Button button2,pos={110,70},size={50,20},title="Reset", disable=2
	Button button2,pos={155,170},size={50,20},title="Reset", disable=2
	Button button2,proc = pt_TrigGenResetStart
	Button button3,pos={5,5},size={60,20},title="ResetDev"
	Button button3,proc = pt_TrigGenResetDev
//	Button button3,pos={1,72},size={50,20},title="Hardware"
//	Button button3,proc = pt_TrigGenHWEdit
//	Button button4,pos={1,5},size={50,20},title="Devices"
//	Button button4,proc = pt_TrigGenDevsEdit
//	Button button4,pos={1,5},size={50,20},title="Devices"
//	Button button4,proc = pt_TrigGenDevsEdit
	PopupMenu TrigGenChTogl,pos={75,5},size={50,21},title="Channels"	
	PopupMenu TrigGenChTogl, mode = 1, value="ShowAll;"+pt_TrigGenDevsList("TrigGenChTogl"), proc = pt_TrigGenChTogl
//	CheckBox DemoMode, pos={1,70},size={80,15}, title="DemoMode "
//	CheckBox DemoMode, variable = DemoMode//, proc = pt_UpdateEPhysChSelect
End


//Function pt_TrigGenDevsEdit(Button4) : ButtonControl
//String Button4
Function pt_TrigGenDevsEdit()

Variable i

// Eventually lot of the information enetered here will be gathered from individual device folder. ToDo

// All the following waves are text waves even when the information to be conveyed is numerical

Wave /T IODevFldr			=root:TrigGenVars:IODevFldr
Wave /T IOVidDevFldr			=root:TrigGenVars:IOVidDevFldr
//Wave /T IOStepNum			=root:TrigGenVars:IOStepNum		// May be useful to randomize steps
Wave /T IODevNum			=root:TrigGenVars:IODevNum
Wave /T IOChNum			=root:TrigGenVars:IOChNum
Wave /T IOWName			=root:TrigGenVars:IOWName
//Wave /T IONumRepeats		=root:TrigGenVars:IONumRepeats		// Repeats for each step
//Wave /T IOISIInSec			=root:TrigGenVars:IOISIInSec
//Wave /T IOERRH			=root:TrigGenVars:IOERRH
Wave /T IOEOSH				=root:TrigGenVars:IOEOSH

Edit /K=1
DoWindow /C TrigGenChEdit

If (WaveExists(IOVidDevFldr))
AppendToTable  IOVidDevFldr
Else
Make /T/O/N=0 root:TrigGenVars:IOVidDevFldr
Wave /T IOVidDevFldr = root:TrigGenVars:IOVidDevFldr
AppendToTable  IOVidDevFldr
EndIf


If (WaveExists(IODevFldr))
AppendToTable  IODevFldr
Else
Make /T/O/N=0 root:TrigGenVars:IODevFldr
Wave /T IODevFldr = root:TrigGenVars:IODevFldr
AppendToTable  IODevFldr
EndIf

If (WaveExists(IODevFldrCopy))
AppendToTable  IODevFldrCopy
Else
Make /T/O/N=0 root:TrigGenVars:IODevFldrCopy
Wave /T IODevFldrCopy = root:TrigGenVars:IODevFldrCopy
AppendToTable  IODevFldrCopy
EndIf


//If (WaveExists(IOStepNum))
//AppendToTable  IOStepNum
//Else
//Make /T/O/N=0 root:TrigGenVars:IOStepNum
//Wave /T IOStepNum = root:TrigGenVars:IOStepNum
//AppendToTable  IOStepNum
//EndIf

If (WaveExists(IODevNum))
AppendToTable  IODevNum			
//TrigGenDevNum = pt_ParFrmDevFldr()									// Read parameter from Dev Folder
Else
Make /T/O/N=0 root:TrigGenVars:IODevNum
Wave /T IODevNum = root:TrigGenVars:IODevNum
AppendToTable  IODevNum
EndIf

If (WaveExists(IOChNum))
AppendToTable  IOChNum
Else
Make /T/O/N=0 root:TrigGenVars:IOChNum
Wave /T IOChNum = root:TrigGenVars:IOChNum
AppendToTable  IOChNum
EndIf

If (WaveExists(IOWName))
AppendToTable  IOWName
Else
Make /T/O/N=0 root:TrigGenVars:IOWName
Wave /T IOWName = root:TrigGenVars:IOWName
AppendToTable  IOWName
EndIf

//If (WaveExists(IOInWName))
//AppendToTable  IOInWName
//Else
//Make /T/O/N=0 root:TrigGenVars:IOInWName
//Wave /T IOInWName = root:TrigGenVars:IOInWName
//AppendToTable  IOInWName
//EndIf

//If (WaveExists(IONumRepeats))
//AppendToTable  IONumRepeats
//Else
//Make /T/O/N=0 root:TrigGenVars:IONumRepeats
//Wave /T IONumRepeats = root:TrigGenVars:IONumRepeats
//AppendToTable  IONumRepeats
//EndIf

//If (WaveExists(IOISIInSec))
//AppendToTable  IOISIInSec
//Else
//Make /T/O/N=0 root:TrigGenVars:IOISIInSec
//Wave /T IOISIInSec = root:TrigGenVars:IOISIInSec
//AppendToTable  IOISIInSec
//EndIf

//If (WaveExists(IOERRH))
//AppendToTable  IOERRH
//Else
//Make /T/O/N=0 root:TrigGenVars:IOERRH
//Wave /T IOERRH = root:TrigGenVars:IOERRH
//AppendToTable  IOERRH
//EndIf

If (WaveExists(IOEOSH))
AppendToTable  IOEOSH
Else
Make /T/O/N=0 root:TrigGenVars:IOEOSH
Wave /T IOEOSH = root:TrigGenVars:IOEOSH
AppendToTable  IOEOSH
EndIf

End

Function /S pt_TrigGenDevsList(Button4) : ButtonControl
String Button4
// popup all the available channels
String OldDataFolder, AllDataFolderList, DevDataFolderList, Str
Variable N,i
OldDataFolder 	= GetDataFolder(1)
SetDataFolder root:
AllDataFolderList = DataFolderDir(1)
AllDataFolderList=AllDataFolderList[8,strlen(AllDataFolderList)-3]
DevDataFolderList = ""
//DevDataFolderList = "Show All;"			// option to just show all channels so that the user can see the list
										// without toggling a channel
N=ItemsInList(AllDataFolderList, ",")
For (i=0; i<N; i+=1)
	Str = StringFromList(i, AllDataFolderList, ",")
	If (StringMatch(Str, "EPhysVars*"))
		DevDataFolderList +="root:"+Str+";"
	EndIf
	If (StringMatch(Str, "TemperatureVars*"))
		DevDataFolderList +="root:"+Str+";"
	EndIf
	If (StringMatch(Str, "LaserShutterVars*"))
		DevDataFolderList +="root:"+Str+";"
	EndIf
	If (StringMatch(Str, "LaserVoltageVars*"))
		DevDataFolderList +="root:"+Str+";"
	EndIf
	If (StringMatch(Str, "LaserPowerVars*"))
		DevDataFolderList +="root:"+Str+";"
	EndIf
	If (StringMatch(Str, "ScanMirrorVars*"))
		DevDataFolderList +="root:"+Str+";"
	EndIf
	If (StringMatch(Str, "VideoVars*"))
		DevDataFolderList +="root:"+Str+";"
	EndIf
EndFor
SetDataFolder OldDataFolder
Return DevDataFolderList
End

Function pt_TrigGenChTogl(PopupMenuVarName,PopupMenuVarNum,PopupMenuVarStr) : PopupMenuControl
//Function pt_EPhysPopSelect(PopupMenuVarName, PopupMenuVarStr) : PopupMenuControl
String PopupMenuVarName, PopupMenuVarStr
Variable PopupMenuVarNum

//String Str
Variable N, i, ChSlcted
DoWindow TrigGenChEdit
If (V_Flag)
DoWindow /K TrigGenChEdit
EndIf
pt_TrigGenDevsEdit()

If (!StringMatch(PopupMenuVarStr, "ShowAll"))
Wave /T IODevFldr			=root:TrigGenVars:IODevFldr
Wave /T IOVidDevFldr			=root:TrigGenVars:IOVidDevFldr
Duplicate /T/O IODevFldr, IODevFldr1
Duplicate /T/O IOVidDevFldr, IOVidDevFldr1

If (StringMatch(PopupMenuVarStr, "root:VideoVars*"))	// it's a video channel

N = NumPnts(IOVidDevFldr1)
For (i=0; i<N; i+=1)
//	Str = IOVidDevFldr1[i]
	If (StringMatch(IOVidDevFldr1[i], PopupMenuVarStr))
		ChSlcted = 1
		DeletePoints i,1, IOVidDevFldr
	EndIf	
EndFor
If (ChSlcted==0)
InsertPoints NumPnts(IOVidDevFldr),1, IOVidDevFldr
IOVidDevFldr[NumPnts(IOVidDevFldr)-1]=PopupMenuVarStr
EndIf

// Can add more ElseIf's in future for other non National-Instrument channels
Else	// It's a National Instruments channel 


N = NumPnts(IODevFldr1)
For (i=0; i<N; i+=1)
//	Str = IODevFldr1[i]
	If (StringMatch(IODevFldr1[i], PopupMenuVarStr))
		ChSlcted = 1
		DeletePoints i,1, IODevFldr
	EndIf	
EndFor
If (ChSlcted==0)
InsertPoints NumPnts(IODevFldr),1, IODevFldr
IODevFldr[NumPnts(IODevFldr)-1]=PopupMenuVarStr
EndIf


EndIf
KillWaves /Z IODevFldr1, IOVidDevFldr1
EndIf
End


Function pt_TrigGenStimulusPattern(ButtonVarName) :  ButtonControl
String ButtonVarName

String ChannelName
Variable i, N
Wave /T IODevFldr			=root:TrigGenVars:IODevFldr
Wave /T IOVidDevFldr			=root:TrigGenVars:IOVidDevFldr

DoWindow TrigGenStimPatternEdit
If (V_Flag)
DoWindow /K TrigGenStimPatternEdit
EndIf

Edit /K=1
DoWindow /C TrigGenStimPatternEdit

If (WaveExists(IODevFldr))
N = NumPnts(IODevFldr)
//OldDf=GetDataFolder(1)
//SetDataFolder root:TrigGenVars
For (i=0; i<N;i+=1)
	sscanf IODevFldr[i], "root:%s", ChannelName
	
	If (WaveExists($(IODevFldr[i]+":OutWaveNamesW")))
	Wave /T OutWaveNamesW=$(IODevFldr[i]+":OutWaveNamesW")
	Duplicate /O OutWaveNamesW, $("root:TrigGenVars:"+"OutW"+ChannelName)
	AppendToTable $("root:TrigGenVars:"+"OutW"+ChannelName)
	EndIf
	
	If (WaveExists($(IODevFldr[i]+":OutXWaveNamesW")))
	Wave /T OutXWaveNamesW=$(IODevFldr[i]+":OutXWaveNamesW")
	Duplicate /O OutXWaveNamesW, $("root:TrigGenVars:"+"OutXW"+ChannelName)
	AppendToTable $("root:TrigGenVars:"+"OutXW"+ChannelName)
	EndIf
	
	If (WaveExists($(IODevFldr[i]+":OutYWaveNamesW")))
	Wave /T OutYWaveNamesW=$(IODevFldr[i]+":OutYWaveNamesW")
	Duplicate /O OutYWaveNamesW, $("root:TrigGenVars:"+"OutYW"+ChannelName)
	AppendToTable $("root:TrigGenVars:"+"OutYW"+ChannelName)
	EndIf
	
	If (WaveExists($(IODevFldr[i]+":InWaveNamesW")))
	Wave /T InWaveNamesW=$(IODevFldr[i]+":InWaveNamesW")
	Duplicate /O InWaveNamesW, $("root:TrigGenVars:"+"InW"+ChannelName)
	AppendToTable $("root:TrigGenVars:"+"InW"+ChannelName)
	EndIf

EndFor

//DoWindow TrigGenChInOutAssignPanel
//	If (V_Flag==1)
//		DoWindow /F TrigGenChInOutAssignPanel
//	Else
//	PauseUpdate; Silent 1		// building window...
//	NewPanel /K=1/W=(525,75,790,180)
//	DoWindow /C TrigGenChInOutAssignPanel
///	EndIf
	
//	String /G root:TrigGenVars:WMatchStr
	
//	SVAR OutWMatchStr = root:TrigGenVars:OutWMatchStr
//	SVAR InWMatchStr 	= root:TrigGenVars:InWMatchStr
//	SetVariable setvar0,pos={1,15},size={210,18}, limits={-inf,inf,0}, title ="WMatchStr"
//	SetVariable setvar0,value=  $("root:TrigGenVars:WMatchStr")
	
//	Button button0,pos={50,35},size={50,20},title="Search"
//	Button button0,proc = pt_TrigGenChInOutSearch

//SetDataFolder OldDf
EndIf

If (WaveExists(IOVidDevFldr))
N = NumPnts(IOVidDevFldr)
//OldDf=GetDataFolder(1)
//SetDataFolder root:TrigGenVars
For (i=0; i<N;i+=1)
	sscanf IOVidDevFldr[i], "root:%s", ChannelName
	
	If (WaveExists($(IOVidDevFldr[i]+":InWaveNamesW")))
	Wave /T InWaveNamesW=$(IOVidDevFldr[i]+":InWaveNamesW")
	Duplicate /O InWaveNamesW, $("root:TrigGenVars:"+"InW"+ChannelName)
	AppendToTable $("root:TrigGenVars:"+"InW"+ChannelName)
	EndIf

EndFor

//DoWindow TrigGenChInOutAssignPanel
//	If (V_Flag==1)
//		DoWindow /F TrigGenChInOutAssignPanel
//	Else
//	PauseUpdate; Silent 1		// building window...
//	NewPanel /K=1/W=(525,75,790,180)
//	DoWindow /C TrigGenChInOutAssignPanel
///	EndIf
	
//	String /G root:TrigGenVars:WMatchStr
	
//	SVAR OutWMatchStr = root:TrigGenVars:OutWMatchStr
//	SVAR InWMatchStr 	= root:TrigGenVars:InWMatchStr
//	SetVariable setvar0,pos={1,15},size={210,18}, limits={-inf,inf,0}, title ="WMatchStr"
//	SetVariable setvar0,value=  $("root:TrigGenVars:WMatchStr")
	
//	Button button0,pos={50,35},size={50,20},title="Search"
//	Button button0,proc = pt_TrigGenChInOutSearch

//SetDataFolder OldDf
EndIf

End

Function pt_TrigGenChInOutSearch(ButtonVarName) :  ButtonControl
String ButtonVarName

SVAR WMatchStr = root:TrigGenVars:WMatchStr
String TableName, InOutWName, FldrName, OldDf, WaveListStr
Variable , N,M,i
TableName=StringByKey("TableName",TableInfo("",-2), ":")
GetSelection Table, $TableName, 1
InOutWName=StringByKey("Wave", TableInfo("",V_StartCol), ":")

If (StringMatch(InOutWName, "root:TrigGenVars:OutW*"))
sscanf InOutWName, "root:TrigGenVars:OutW%s", FldrName
ElseIf (StringMatch(InOutWName, "root:TrigGenVars:OutXW*"))
sscanf InOutWName, "root:TrigGenVars:OutXW%s", FldrName
ElseIf (StringMatch(InOutWName, "root:TrigGenVars:OutYW*"))
sscanf InOutWName, "root:TrigGenVars:OutYW%s", FldrName
Else
sscanf InOutWName, "root:TrigGenVars:InW%s", FldrName
EndIf

FldrName = "root:"+FldrName

OldDf = GetDataFolder(1)
SetDataFolder $FldrName
WaveListStr=WaveList(WMatchStr, ";","TEXT:0")	// Only non-text waves
WaveListStr=SortList(WaveListStr, ";", 16)
SetDataFolder OldDf
Wave /T InOutW = $InOutWName
N=NumPnts(InOutW)
DeletePoints 0,N,InOutW
M= ItemsInList(WaveListStr, ";")
Make /O/N=1/T TmpInOutW=""
For (i=0;i<M; i+=1)
	TmpInOutW[0]=StringFromList(i, WaveListStr, ";")
	Concatenate /NP/T {TmpInOutW}, InOutW
EndFor
// earlier the search and update were separate functions. Now search will also call update
pt_TrigGenStimulusPatternUpdate("")	

End


//==========
Function pt_TrigGenStimulusPatternUpdate(ButtonVarName) :  ButtonControl
String ButtonVarName

String ChannelName
Variable i, N
Wave /T IODevFldr			=root:TrigGenVars:IODevFldr
Wave /T IOVidDevFldr			=root:TrigGenVars:IOVidDevFldr

//DoWindow TrigGenStimPatternEdit
//If (V_Flag)
//DoWindow /K TrigGenStimPatternEdit
//EndIf

//Edit /K=1
//DoWindow /C TrigGenStimPatternEdit

If (WaveExists(IODevFldr))
N = NumPnts(IODevFldr)
//OldDf=GetDataFolder(1)
//SetDataFolder root:TrigGenVars
For (i=0; i<N;i+=1)
	sscanf IODevFldr[i], "root:%s", ChannelName
	
	If (StringMatch(ChannelName, "ScanMirrorVars*"))
	
	Wave /T OutXWaveNamesW=$(IODevFldr[i]+":OutXWaveNamesW")
	If (WaveExists($(IODevFldr[i]+":OutXWaveNamesW")))
	Duplicate /O/T $("root:TrigGenVars:"+"OutXW"+ChannelName), OutXWaveNamesW
	EndIf
	
	Wave /T OutYWaveNamesW=$(IODevFldr[i]+":OutYWaveNamesW")
	If (WaveExists($(IODevFldr[i]+":OutYWaveNamesW")))
	Duplicate /O/T $("root:TrigGenVars:"+"OutYW"+ChannelName), OutYWaveNamesW
	EndIf
	
	
	Else
	
	Wave /T OutWaveNamesW=$(IODevFldr[i]+":OutWaveNamesW")
	If (WaveExists($(IODevFldr[i]+":OutWaveNamesW")))
	Duplicate /O/T $("root:TrigGenVars:"+"OutW"+ChannelName), OutWaveNamesW
	EndIf
	
	If (WaveExists($(IODevFldr[i]+":InWaveNamesW")))
	Wave /T InWaveNamesW=$(IODevFldr[i]+":InWaveNamesW")
	Duplicate /O/T $("root:TrigGenVars:"+"InW"+ChannelName), InWaveNamesW
	EndIf
	
	EndIf
	
	
EndFor
//SetDataFolder OldDf
EndIf


If (WaveExists(IOVidDevFldr))
N = NumPnts(IOVidDevFldr)
//OldDf=GetDataFolder(1)
//SetDataFolder root:TrigGenVars
For (i=0; i<N;i+=1)
	sscanf IOVidDevFldr[i], "root:%s", ChannelName
	
	If (WaveExists($(IOVidDevFldr[i]+":InWaveNamesW")))
	Wave /T InWaveNamesW=$(IOVidDevFldr[i]+":InWaveNamesW")
	Duplicate /O/T $("root:TrigGenVars:"+"InW"+ChannelName), InWaveNamesW
	EndIf
	
	
	
	
EndFor
//SetDataFolder OldDf
EndIf


End

//==========







Function pt_TrigGenReadScanPars()

// analog channels
String DevName
String NameIODev = ""

// digital channels
//String DigDevName
//String DigNameIODev = ""

Variable NumIODev, NumIOVidDev, DigNumIODev, iLast
Variable  i, N, NVid, NumOutPnts, FirstWaveFound, DeltaOutPnts
Variable KillDataFolderErr=0


Wave /T IODevFldrCopy	=root:TrigGenVars:IODevFldrCopy
//Wave /T IOStepNum		=root:TrigGenVars:IOStepNum			// May be useful to randomize steps
Wave /T IODevNum		=root:TrigGenVars:IODevNum
Wave /T IOChNum		=root:TrigGenVars:IOChNum
Wave /T IOWName		=root:TrigGenVars:IOWName
//Wave /T IOInWName		=root:TrigGenVars:IOInWName
//Wave /T IONumRepeats	=root:TrigGenVars:IONumRepeats		// Repeats for each step
//Wave /T IOISIInSec		=root:TrigGenVars:IOISIInSec
//Wave /T IOERRH		=root:TrigGenVars:IOERRH
Wave /T IOEOSH			=root:TrigGenVars:IOEOSH

Wave /T IOVidDevFldrCopy	=root:TrigGenVars:IOVidDevFldrCopy
//Wave /T IOStepNum		=root:TrigGenVars:IOStepNum			// May be useful to randomize steps
Wave /T IOVidDevNum		=root:TrigGenVars:IOVidDevNum
Wave /T IOVidChNum		=root:TrigGenVars:IOVidChNum
Wave /T IOVidWName		=root:TrigGenVars:IOVidWName
//Wave /T IOInWName		=root:TrigGenVars:IOInWName
//Wave /T IONumRepeats	=root:TrigGenVars:IONumRepeats		// Repeats for each step
//Wave /T IOISIInSec		=root:TrigGenVars:IOISIInSec
//Wave /T IOERRH		=root:TrigGenVars:IOERRH
Wave /T IOVidEOSH			=root:TrigGenVars:IOVidEOSH

// Kill older parameters

If (DataFolderExists("root:TrigGenVars:IOPars"))
KillDataFolder /Z	root:TrigGenVars:IOPars
KillDataFolderErr = V_Flag
EndIf
If (KillDataFolderErr!=0)
Abort	"Can't kill folder root:TrigGenVars:IOPars. Waves may be in use"
EndIf
NewDataFolder 	root:TrigGenVars:IOPars

N = NumPnts(IODevFldrCopy)		// N = Number of rows in the waves
NVid = NumPnts(IOVidDevFldrCopy)		// N = Number of rows in the waves

/// Check all IOPars waves have same number of points

If ( (N!=NumPnts(IODevFldrCopy))  || (N!=NumPnts(IODevNum))  || (N!=NumPnts(IOChNum)) || (N!=NumPnts(IOWName)) || (N!=NumPnts(IOEOSH)) ) 
Abort "IO waves in root:TrigGenVars should have the same number of points"
EndIf

If ( (NVid!=NumPnts(IOVidDevFldrCopy))  || (NVid!=NumPnts(IOVidDevNum))  || (NVid!=NumPnts(IOVidChNum)) || (NVid!=NumPnts(IOVidWName)) || (NVid!=NumPnts(IOVidEOSH)) ) 
Abort "Video IO waves in root:TrigGenVars should have the same number of points"
EndIf

// check all waves have same number of points. If not true for outwaves, Abort. If not true for in waves, make new, and set the wave scaling
NumOutPnts=0
FirstWaveFound =0
DeltaOutPnts =1
For (i=0; i<N; i+=1)
	If 	(!	(StringMatch(IOWName[i], "")		)	)
	If (StringMatch(IOWName[i], "*Out*"))	// it's an out wave
//	Wave OutW =$("root:"+IOWName[i])
	Wave OutW =$(IOWName[i])
	
	If (FirstWaveFound==1)
		If  (     (NumOutPnts!=NumPnts(OutW))  ||  (DeltaOutPnts !=DimDelta(OutW, 0))      )
		Print "Number of points in outwave", "root:"+IOWName[i],"=",NumPnts(OutW), "is not equal to other out waves = ", NumOutPnts
		Print "Or the wave X-scaling is different. "
		Abort "Aborting..."
		EndIf
	Else
	NumOutPnts=NumPnts(OutW)
	DeltaOutPnts= DimDelta(OutW, 0)
	FirstWaveFound=1
	EndIf
	
	EndIf
	EndIf
EndFor

//NumOutPnts=0
//FirstWaveFound =0


// If no Outwave find an inwave which is not a dummy wave (wave generated by the program as the user didn't specify one) or a user specified wave with zero points
// This will be used to scale all inwaves
If (FirstWaveFound==0)		// No outwave
For (i=0; i<N; i+=1)
	If 	(!	(StringMatch(IOWName[i], "")		)	)
	If (StringMatch(IOWName[i], "*In*"))	// it's an In wave
//	Wave InW =$("root:"+IOWName[i])
	Wave InW =$(IOWName[i])
//	Print "IOWName[i]",IOWName[0]
	If (NumPnts(InW)!=0)		// Not a dummy wave or a user generated wave with zero points.
		NumOutPnts=NumPnts(InW)			// No OutWave and this is the first InWave
		DeltaOutPnts= DimDelta(InW, 0)
		FirstWaveFound=1
	EndIf
	EndIf
	EndIf
EndFor	
EndIf
//print "InW=",InW
If (FirstWaveFound==0)			
Abort "No Outwaves on any channels and Inwaves are either not specified on any channel or have zero length. Aborting..."
EndIf

For (i=0; i<N; i+=1)
	If 	(!	(StringMatch(IOWName[i], "")		)	)
	If (StringMatch(IOWName[i], "*In*"))	// it's an In wave
//	Wave InW =$("root:"+IOWName[i])
	Wave InW =$(IOWName[i])
	
	
//	If (FirstWaveFound==1)				// Either because there is an outwave or the first InWave has been found. Number of points = NumOutPnts
		If  (   (NumOutPnts!=NumPnts(InW))  ||  (DeltaOutPnts !=DimDelta(InW, 0))    )
		Print "Number of points in Inwave", "root:"+IOWName[i], "not equal to outwaves or other In waves"
		Print "Or the wave X-scaling is different."
		Print "Warning!! Remaking", "root:"+IOWName[i], "with", NumOutPnts, "number of points and X-scaling=", DeltaOutPnts
//		Make /O/N=(NumOutPnts) $("root:"+IOWName[i])
		Make /O/N=(NumOutPnts) $(IOWName[i])
//		Wave InW = $("root:"+IOWName[i])
		Wave InW = $(IOWName[i])
		InW = Nan
		SetScale /P x,0, DeltaOutPnts, InW
		EndIf
//	Else
//	NumOutPnts=NumPnts(InW)			// No OutWave and this is the first InWave
//	DeltaOutPnts= DimDelta(InW, 0)
//	EndIf
	
	EndIf
	EndIf
EndFor

For (i=0; i<NVid; i+=1)
	If 	(!	(StringMatch(IOVidWName[i], "")		)	)
	If (StringMatch(IOVidWName[i], "*In*"))	// it's an In wave
//	Wave InW =$("root:"+IOVidWName[i])
	Wave InW =$(IOVidWName[i])	
	
//	If (FirstWaveFound==1)				// Either because there is an outwave or the first InWave has been found. Number of points = NumOutPnts
		If  (   (NumOutPnts!=NumPnts(InW))  ||  (DeltaOutPnts !=DimDelta(InW, 0))    )
		Print "Number of points in Inwave", "root:"+IOVidWName[i], "not equal to outwaves or other In waves"
		Print "Or the wave X-scaling is different."
		Print "Warning!! Remaking", "root:"+IOVidWName[i], "with", NumOutPnts, "number of points and X-scaling=", DeltaOutPnts
//		Make /O/N=(NumOutPnts) $("root:"+IOVidWName[i])
//		Wave InW = $("root:"+IOVidWName[i])
		Make /O/N=(NumOutPnts) $(IOVidWName[i])
		Wave InW = $(IOVidWName[i])
		InW = Nan
		SetScale /P x,0, DeltaOutPnts, InW
		EndIf
//	Else
//	NumOutPnts=NumPnts(InW)			// No OutWave and this is the first InWave
//	DeltaOutPnts= DimDelta(InW, 0)
//	EndIf
	
	EndIf
	EndIf
EndFor

Make /O/N=(NumOutPnts) 		$("root:DummyWave")=0	// to be used if there are no analog i/o operations to trigger digital i/o
SetScale /P x,0, DeltaOutPnts, 	$("root:DummyWave")


// Now figure out number of distinct Analog device entries

//NumIODev= (( N>0) && ) ? 1 : 0		// If Number of entries is > 0 then there is at least 1 distinct device

NumIODev 		= 0
DigNumIODev 	= 0
NumIOVidDev	= 0

//If  ( (N>0) && () )
//	NumIODev=1
//EndIf

If (N==1)
	If (StringMatch(IOWName[i], "*DigOut*") || (StringMatch(IOWName[i], "*DigIn*")) )		// it's a digital channel
		DigNumIODev 	= 1
	Else	
		NumIODev 		= 1
	EndIf
Else  // N>1

For (i=0; i<(N-1); i+=1)		// N-1 instead of N because we are comparing (i+1)th entry with ith entry
	Duplicate /T/O IODevNum, IODevNumSrt
	Duplicate /T/O IOChNum,  IOChNumSrt
	Sort IODevNumSrt, IODevNumSrt, IOChNumSrt
	
	If (!(StringMatch(IODevNumSrt[i], IODevNumSrt[i+1])))
	
	If (StringMatch(IOWName[i+1], "*DigOut*") || (StringMatch(IOWName[i+1], "*DigIn*")) )		// it's a digital channel
		DigNumIODev 	+= 1
	Else	
		NumIODev 		+= 1
	EndIf

	EndIf	
	
EndFor

EndIf // EndIf for (N==1)

// ToDo Video : 
// Not yet finding distinct devices for video (like we did for National Instruments cards). Not sure about the following yet.

//1. Can the card record simultaneously from more than 1 channels? Otherwise, entries with same device
//should be removed from IOVidDevFldrCopy. 
//2. Can we have more than 1 video card? Otherwise entries with just 1 device should be kept. 
//3. Also there is a trigger input possible. Maybe the NIDAQ trigger could be sent to the camera, just like
// it is sent to the shutter


// For the time being assuming user is going to put just 1 entry in IOVidDevFldr
NumIOVidDev = NVid		

KillWaves /Z IODevNumSrt, IOChNumSrt

// IOPars for analog channels

Make /O/T/N=0 $("root:TrigGenVars:IOPars:OutWPar")
Make /O/T/N=0 $("root:TrigGenVars:IOPars:InWPar")
Make /O/T/N=0 $("root:TrigGenVars:IOPars:NameIODevWPar")

Wave /T OutWPar		= $("root:TrigGenVars:IOPars:OutWPar")
Wave /T InWPar	 		= $("root:TrigGenVars:IOPars:InWPar")
Wave /T NameIODevWPar	= $("root:TrigGenVars:IOPars:NameIODevWPar")


// IOPars for digital channels

Make /O/T/N=0 $("root:TrigGenVars:IOPars:DigOutWPar")
Make /O/T/N=0 $("root:TrigGenVars:IOPars:DigInWPar")
// for digital IO wave and channel num are used as separate strings by the DAQmx_DIO_Config
Make /O/T/N=0 $("root:TrigGenVars:IOPars:DigOutChNumPar	")
Make /O/T/N=0 $("root:TrigGenVars:IOPars:DigInChNumPar	")		
Make /O/T/N=0 $("root:TrigGenVars:IOPars:DigNameIODevWPar")


Wave /T DigOutWPar			= $("root:TrigGenVars:IOPars:DigOutWPar")
Wave /T DigInWPar	 		= $("root:TrigGenVars:IOPars:DigInWPar")
Wave /T DigOutChNumPar	 	= $("root:TrigGenVars:IOPars:DigOutChNumPar")
Wave /T DigInChNumPar	 	= $("root:TrigGenVars:IOPars:DigInChNumPar")
Wave /T DigNameIODevWPar	= $("root:TrigGenVars:IOPars:DigNameIODevWPar")

// IOPars for video channels

//Make /O/T/N=0 $("root:TrigGenVars:IOPars:VidOutWPar")
Make /O/T/N=0 $("root:TrigGenVars:IOPars:VidInWPar")
Make /O/T/N=0 $("root:TrigGenVars:IOPars:NameIOVidDevWPar")

//Wave /T VidOutWPar			= $("root:TrigGenVars:IOPars:VidOutWPar")
Wave /T VidInWPar	 		= $("root:TrigGenVars:IOPars:VidInWPar")
Wave /T NameIOVidDevWPar	= $("root:TrigGenVars:IOPars:NameIOVidDevWPar")



For (i=0; i<N; i+=1)					// do this for all entries
	
	If (!(StringMatch(IOWName[i], "")))


	If (StringMatch(IOWName[i], "*DigOut*"))			// Digital Out Channel
	
// for digital IO wave and channel num are used as separate strings by the DAQmx_DIO_Config

	DevName= "Dev"+IODevNum[i]
// index of last occurance of this channel in DigNameIODevWPar
	iLast=pt_FindLastIndex(DigNameIODevWPar,	DevName)
	If (iLast > (NumPnts(DigNameIODevWPar) -1)   )
		InsertPoints iLast,1, DigNameIODevWPar, DigOutWPar, DigInWPar, DigOutChNumPar, DigInChNumPar
	EndIf

	DigNameIODevWPar[iLast]=	"Dev"+IODevNum[i]
	DigOutWPar[iLast] 	+=		IOWName[i]	 			// actually waves should be separated by a comma
	DigOutChNumPar[iLast] 	+=		IOChNum[i]				// actually channel numbers should be separated by a comma
//	Print DigNameIODevWPar
	
	ElseIf (StringMatch(IOWName[i], "*DigIn*"))			// Digital In Channel
	
// for digital IO wave and channel num are used as separate strings by the DAQmx_DIO_Config

	DevName= "Dev"+IODevNum[i]
// index of last occurance of this channel in DigNameIODevWPar
	iLast=pt_FindLastIndex(DigNameIODevWPar,	DevName)
	If (iLast > (NumPnts(DigNameIODevWPar) -1)   )
		InsertPoints iLast,1, DigNameIODevWPar, DigOutWPar, DigInWPar, DigOutChNumPar, DigInChNumPar
	EndIf
	DigNameIODevWPar[iLast]=	"Dev"+IODevNum[i]
	DigInWPar[iLast] 		+=		IOWName[i]	 			// actually waves should be separated by a comma
	DigInChNumPar[iLast] 	+=		IOChNum[i]				// actually channel numbers should be separated by a comma
//	Print DigNameIODevWPar
	
	
	
	ElseIf	(StringMatch(IOWName[i], "*Out*"))			// Analog Out Channel
	
	DevName= "Dev"+IODevNum[i]
// index of last occurance of this channel in NameIODevWPar
	iLast=pt_FindLastIndex(NameIODevWPar,	DevName)
	If (iLast > (NumPnts(NameIODevWPar) -1)   )
		InsertPoints iLast,1, NameIODevWPar, OutWPar, InWPar
	EndIf
	NameIODevWPar[iLast]=		"Dev"+IODevNum[i]
	OutWPar[iLast] 		+=		IOWName[i]+","+IOChNum[i]+";"	 		
//	Print NameIODevWPar	
	ElseIf (StringMatch(IOWName[i], "*In*"))			// Analog In Channel
	
	DevName= "Dev"+IODevNum[i]
// index of last occurance of this channel in NameIODevWPar
	iLast=pt_FindLastIndex(NameIODevWPar, 	DevName)
	If (iLast > (NumPnts(NameIODevWPar) -1)   )
		InsertPoints iLast,1, NameIODevWPar, OutWPar, InWPar
	EndIf
	NameIODevWPar[iLast]=		"Dev"+IODevNum[i]
	InWPar[iLast] 		+=		IOWName[i]+","+IOChNum[i]+";"	 			
//	Print NameIODevWPar
	EndIf
	
	EndIf
	
EndFor


//-------------
For (i=0; i<NumIOVidDev; i+=1)					// do this for all entries
	
	If (!(StringMatch(IOVidWName[i], "")))

	If (StringMatch(IOVidWName[i], "*In*"))			// Video In Channel
	
	DevName= "Dev"+IOVidDevNum[i]
// index of last occurance of this channel in NameIOVidDevWPar
	iLast=pt_FindLastIndex(NameIOVidDevWPar, 	DevName)
	If (iLast > (NumPnts(NameIOVidDevWPar) -1)   )
		InsertPoints iLast,1, NameIOVidDevWPar, VidInWPar
	EndIf
	NameIOVidDevWPar[iLast]=		"Dev"+IOVidDevNum[i]
	Print IOVidDevNum[i]
	VidInWPar[iLast] 		+=		IOVidWName[i]+","+IOVidChNum[i]+";"	 			
//	Print NameIOVidDevWPar
	EndIf
	
	EndIf
	
EndFor
//-------------


//If (!(StringMatch(IOInWName[i], "")))
//	SVAR InWParStr = $("root:TrigGenVars:IOPars:InWPar"+IODevNum[i])		// Device Numbers start from 1
//	InWPar[Str2Num(IODevNum[i])-1] +=IOInWName[i]+","+IOChNum[i]+";"
//	InWParStr +=IOInWName[i]+","+IOChNum[i]+";"
//	DevName= "Dev"+IODevNum[i]
//	If (FindListItem(DevName, NameIODev, ";")==-1)
//	NameIODev +=DevName+";"
//	EndIf
//EndIf

//If (ItemsInList(NameIODev)!=NumIODev)
//	Abort "Number of distinct devices is not equal to number of distinct device names"
//EndIf


// Convert "NameIODev" to a wave
//For (i=0; i<NumIODev; i+=1)
//	NameIODevWPar[i] 		= StringFromList(i,NameIODev,";")
//	DigNameIODevWPar[i]	= StringFromList(i,DigNameIODev,";")
//EndFor

Sort /A NameIODevWPar, NameIODevWPar, OutWPar, InWPar
Sort /A DigNameIODevWPar, DigNameIODevWPar, DigOutChNumPar, DigInChNumPar, DigOutWPar, DigInWPar
Sort /A NameIOVidDevWPar, NameIOVidDevWPar, VidInWPar


Print "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"

Print "Analog I/O"
N = NumPnts(NameIODevWPar) 
For (i=0; i<N; i+=1)
	
	Print "Sending to device", NameIODevWPar[i]
	Print "OutWaves", 		OutWPar[i]
	Print "InWaves", 			InWPar[i]
EndFor
Print "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
Print "Digital I/O"
N = NumPnts(DigNameIODevWPar) 
For (i=0; i<N; i+=1)
	Print "Sending to device", 	DigNameIODevWPar[i]
	Print "Out Channel Num", 	DigOutChNumPar[i]	
	Print "In Channel Num", 	DigInChNumPar[i]	
	Print "OutWaves", 		DigOutWPar[i]
	Print "InWaves", 			DigInWPar[i]
EndFor


Print "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"

Print "Video I/O"
N = NumPnts(NameIOVidDevWPar) 
For (i=0; i<N; i+=1)
	
	Print "Acquiring from device", 	NameIOVidDevWPar[i]
//	Print "Out Channel Num", 		VidOutWPar[i]		
	Print "In Waves", 		VidInWPar[i]			
EndFor
Print "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"


//Print "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
//Print "Using devices", NameIODev
//For (i=0; i<NumIODev; i+=1)
//SVAR OutWParStr = $("root:TrigGenVars:IOPars:OutWPar"+Num2Str(i+1))
//Print "Sending on device",i+1,OutWParStr
//SVAR InWParStr = $("root:TrigGenVars:IOPars:InWPar"+Num2Str(i+1))
//Print "Sending on device",i+1,InWParStr
//EndFor
//Print "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
//Abort
End


Function pt_FindLastIndex(w, DevNum)	// Find index of last occurance of DevNum
String DevNum
Wave /T w

Variable i0=0
Variable i, N

//Wave /T w = $WName
N=NumPnts(w)
//Print w
For (i=0; i<N; i+=1)
	If (StringMatch(w[i], DevNum) )
	Break
	EndIf
EndFor
i0=i
Return i0
End


Function pt_TrigGenHWEdit(button3) : ButtonControl
// This function is no longer in use
String button3

Wave /T TrigGenHWName		=root:TrigGenVars:TrigGenHWName
Wave /T TrigGenHWVal		=root:TrigGenVars:TrigGenHWVal

If (WaveExists(root:TrigGenVars:TrigGenHWName) && WaveExists(root:TrigGenVars:TrigGenHWVal)    )
Wave /T TrigGenHWName	=root:TrigGenVars:TrigGenHWName
Wave /T TrigGenHWVal		=root:TrigGenVars:TrigGenHWVal
Edit /K=1 TrigGenHWName, TrigGenHWVal
Else
Make /T/O/N=3 root:TrigGenVars:TrigGenHWName
Make /T/O/N=3 root:TrigGenVars:TrigGenHWVal
Wave /T TrigGenHWName	=root:TrigGenVars:TrigGenHWName
Wave /T TrigGenHWVal		=root:TrigGenVars:TrigGenHWVal

TrigGenHWName[0] = "DevID"
TrigGenHWName[1] = "TrigSrc"
TrigGenHWName[2] = "ClkSrc"


Edit /K=1 TrigGenHWName, TrigGenHWVal

EndIf


End



Function pt_TrigGenStart(ButtonVarName) :  ButtonControl
String ButtonVarName


NVAR TicksFreq		= root:TrigGenVars:TicksFreq 
NVAR ISI			= root:TrigGenVars:ISI
NVAR IterTot 		= root:TrigGenVars:IterTot
NVAR IterLeft 		= root:TrigGenVars:IterLeft
NVAR RepsTot		= root:TrigGenVars:RepsTot
NVAR RepsLeft		= root:TrigGenVars:RepsLeft
NVAR StopExpt		= root:TrigGenVars:StopExpt
NVAR PauseExpt	= root:TrigGenVars:PauseExpt
//NVAR NumEPhysInCh = root:TrigGenVars:NumEPhysInCh
SVAR ListEPhysInCh = root:TrigGenVars:ListEPhysInCh
SVAR EPhysFldrsList = root:TrigGenVars:EPhysFldrsList


Wave /T IODevFldr			=root:TrigGenVars:IODevFldr
Wave /T IODevNum			=root:TrigGenVars:IODevNum
Wave /T IOChNum			=root:TrigGenVars:IOChNum
Wave /T IOWName			=root:TrigGenVars:IOWName
Wave /T IOEOSH				=root:TrigGenVars:IOEOSH

Wave /T IOVidDevFldr			=root:TrigGenVars:IOVidDevFldr
Wave /T IOVidDevNum		=root:TrigGenVars:IOVidDevNum
Wave /T IOVidChNum			=root:TrigGenVars:IOVidChNum
Wave /T IOVidWName		=root:TrigGenVars:IOVidWName
Wave /T IOVidEOSH			=root:TrigGenVars:IOVidEOSH

Wave 	IODevFldrPrePause	=root:TrigGenVars:IODevFldrPrePause
//String Str, AllRootFldrsList
Variable NumIODevFldr 		= NumPnts(IODevFldr)
Variable NumIODevFldrPrePause = NumPnts(IODevFldrPrePause)
// check if the experiment has been saved first. Else we can't save the data.
PathInfo home
If (V_Flag==0)
	Abort "Please save the experiment first!"
EndIf

If (PauseExpt)	// If restarting a paused experiment make sure that no new channels are being scanned. Channels can be removed 
				// but not added. 
	If (NumIODevFldr>NumIODevFldrPrePause)
	Abort "Additional channels cannot be scanned while resuming a paused experiment. Please stop the experiment first."
	EndIf
EndIf


Wave 	IOVidDevFldrPrePause	=root:TrigGenVars:IOVidDevFldrPrePause
Variable NumIOVidDevFldr 		= NumPnts(IOVidDevFldr)
Variable NumIOVidDevFldrPrePause = NumPnts(IOVidDevFldrPrePause)
// check if the experiment has been saved first. Else we can't save the data.
PathInfo home
If (V_Flag==0)
	Abort "Please save the experiment first!"
EndIf

If (PauseExpt)	// If restarting a paused experiment make sure that no new channels are being scanned. Channels can be removed 
				// but not added. 
	If (NumIOVidDevFldr>NumIOVidDevFldrPrePause)
	Abort "Additional channels cannot be scanned while resuming a paused experiment. Please stop the experiment first."
	EndIf
EndIf

If ((IterTot<=0) || (RepsTot<=0))
Abort "Total number of iterations per repeat AND the number of repeats should be >0. No scan started."
EndIf


If (!PauseExpt)					// If we are not starting from a paused experiment
//IterLeft 		= 0
RepsLeft		= RepsTot
IterLeft 		= IterTot 
EndIf

Button Button2, disable=0, win=TrigGenMain // Enable Reset Start Button
Button Button0, disable=2, win=TrigGenMain // Disable Start Button

// As IODevFldr gets modified (channels like EPhys add extra entry), make copy for modification
Duplicate /T/O IODevFldr, $("root:TrigGenVars:IODevFldrCopy")
Duplicate /T/O IOVidDevFldr, $("root:TrigGenVars:IOVidDevFldrCopy")
StopExpt 	= 0
PauseExpt 	= 0

// pt_NumIOForCh gets only channels that are currently being scanned

//given IODevFldr calculate number of input or output channels we are scanning
 // to be used for determing how many subwindows to make for paired rec display
//NumEPhysInCh = pt_NumIOForCh("root:TrigGenVars:IODevFldr", "*EPhysVars*", ":EPhysInWaveSlctVar")
//Print "NumEPhysInCh=",NumEPhysInCh
ListEPhysInCh= pt_InstListIOForCh("root:TrigGenVars:IODevFldr", "EPhysVars", ":EPhysInWaveSlctVar")
EPhysFldrsList = ""
EPhysFldrsList =pt_FldrsListInDfr("root:", "EPhysVars", 4)
//AllRootFldrsList = DataFolderDir(1,dfr)

 
//Print ISI*TicksFreq
If (!( (IterLeft <0) && (RepsLeft <1)  ))

SetBackGround  pt_TrigGenStartAcquis()
//pt_TrigGenStartAcquis()
CtrlBackGround start, period = round(ISI*TicksFreq), NoBurst=0 // NoBurst = 1 implies don't try to catch-up if missed start time

//CtrlNamedBackground pt_TrigGenBkGrnd, start, period = round(ISI*TicksFreq), Burst=1, proc =pt_TrigGenStartAcquis  // Burst = 0 implies don't try to catch-up if missed start time
//CtrlNamedBackground pt_TrigGenBkGrnd, status
//Print "Info pt_TrigGenBkGrnd", S_Info


//pt_StartAcquisition() Use in case we want the job to run in the foreground
//EndOfExpt    	= 0	
Print "-------------------------------------------------------------------------------------------------------------------------------------------------------------------"
Print "Starting TrigGen at", time(), "on", Date()
Print "-------------------------------------------------------------------------------------------------------------------------------------------------------------------"
Else
Print "Either iterations left are <0 or Reps left is <1. No Scan started!"
EndIf
End

Function pt_TrigGenStartAcquis()

NVAR ScanRunning	= root:TrigGenVars:ScanRunning
NVAR IterTot 		= root:TrigGenVars:IterTot
NVAR IterLeft 		= root:TrigGenVars:IterLeft
NVAR RepsTot		= root:TrigGenVars:RepsTot
NVAR RepsLeft		= root:TrigGenVars:RepsLeft
NVAR StopExpt		= root:TrigGenVars:StopExpt
NVAR PauseExpt	= root:TrigGenVars:PauseExpt

// Related to devices and channels to be triggered
String	TrigDevIDStr, TrigSrcStr, TrigSrcStrFull//, ClkSrcStr//, ClkSrcStrFull	//,TrigDevIDList, TrigDestList
String ClkSrcStrFull = ""
// Variable NumTrigDev, NumTrigDest
// Related to devices and channels sent output waves and read input waves on receving the trigger 
//String 	  IODevIDStr, IOOutWaveParStr, IOInWaveParStr	, IOOutDevIdStr, IOInDevIdStr, IOOutTrigDestStr, IOInTrigDestStr															
Variable	  NumIODev//, IOChNumDev
//String 	  DevIdStrList, DevIdStr, TrigDest
Variable   i, NumIODevFldr, NumIOVidDevFldr//, NumCh, NumDev
Variable   OutVal = 1
Variable TrigNClkSrcFound=0
Variable i0 =0, IOVidInWL
String OldDf, WNoteStr


If (StopExpt==1)

//	If (RepsLeft>0)
	Print "-------------------------------------------------------------------------------------------------------------------------------------------------------------------"
	Print "Scan stopped by user at", time(), "on", Date(),". Iterations left=", IterLeft
	Print "-------------------------------------------------------------------------------------------------------------------------------------------------------------------"
	Button button0, disable=0, win=TrigGenMain // Enable Start Button
	Button button2, disable=2, win=TrigGenMain // Disable Reset Start Button
//	StopExpt   = 1
//	PauseExpt = 0	// Most likely redundant as Stop experiment should have done this already
	Return 1
//	EndIf
EndIf

If (PauseExpt==1)
	Print "-------------------------------------------------------------------------------------------------------------------------------------------------------------------"
	Print "Scan paused by user at", time(), "on", Date(),". Iterations left=", IterLeft
	Print "-------------------------------------------------------------------------------------------------------------------------------------------------------------------"
	Button button0, disable=0, win=TrigGenMain // Enable Start Button
	Button button2, disable=2, win=TrigGenMain // Disable Reset Start Button
	Return 1
EndIf

If (RepsLeft == RepsTot)	// 1st repeat
Print "Starting/ continuing repeat # 1"
//If (IterLeft == IterTot)		// 1st Iter of 1st repeat
//pt_TrigGenIntializeChan()			// initialize Channels
//EndIf
//RepsLeft -=1
EndIf

//RepsLeft -=1

If ((IterLeft == IterTot) && (RepsLeft >0))	// initialize when starting a new repeat
pt_TrigGenIntializeChan()			// initialize Channels
EndIf



//Wave /T TrigGenHWName		=root:TrigGenVars:TrigGenHWName
//Wave /T TrigGenHWVal		=root:TrigGenVars:TrigGenHWVal

//TrigDevIdStr 		= TrigGenHWVal[0]
//TrigSrcStr 		= TrigGenHWVal[1]
//ClkSrcStr		= TrigGenHWVal[2]


//NumTrigDev		= ItemsInList(TrigDevIdList, ";")
//NumTrigDest 	= ItemsInList(TrigDestList, ";")

//If (NumTrigDev == NumTrigDest)
//Else
//Print "Number of devices is not equal to number of Trig Dest. Please edit root:TrigGenVars:TrigGenHWVal!!"
//ScanRunning = 1
//EndIf


//Wave /T TrigGenStepNum	=root:TrigGenVars:TrigGenStepNum		// May be useful to randomize steps
//Wave /T TrigGenDevNum		=root:TrigGenVars:TrigGenDevNum
//Wave /T TrigGenChNum		=root:TrigGenVars:TrigGenChNum
//Wave /T TrigGenOutWName	=root:TrigGenVars:TrigGenOutWName
//Wave /T TrigGenNumRepeats	=root:TrigGenVars:TrigGenNumRepeats		// Repeats for each step
//Wave /T TrigGenISIInSec		=root:TrigGenVars:TrigGenISIInSec
//Wave /T TrigGenERRH		=root:TrigGenVars:TrigGenERRH
//Wave /T TrigGenEOSH		=root:TrigGenVars:TrigGenEOSH

// Check all waves have same number of entries.Done

// Remake waves IODevNum, IOChNum, IODevNum, IOWName, IOEOSH 
//so that they have the same number of points as  IODevFldrCopy because else
// we will need to redimensison them when using pt_TrigGenUpdateScanPars()



Wave /T IODevFldr 			= root:TrigGenVars:IODevFldr
Wave /T IODevFldrCopy		=root:TrigGenVars:IODevFldrCopy

Wave /T IOVidDevFldr 			= root:TrigGenVars:IOVidDevFldr
Wave /T IOVidDevFldrCopy		=root:TrigGenVars:IOVidDevFldrCopy

NumIODevFldr = NumPnts(IODevFldr)
Print "NumIODevFldr", NumIODevFldr

Make /T/O/N=(NumIODevFldr)  $("root:TrigGenVars:IODevNum")	= ""		//Initialize because Make /O retains previous values
Make /T/O/N=(NumIODevFldr) 	$("root:TrigGenVars:IOChNum")	= ""		//Initialize because Make /O retains previous values
Make /T/O/N=(NumIODevFldr) 	$("root:TrigGenVars:IOWName")	= ""		//Initialize because Make /O retains previous values
Make /T/O/N=(NumIODevFldr) 	$("root:TrigGenVars:IOEOSH")		= ""		//Initialize because Make /O retains previous values

//Wave /T IODevNum = $("root:TrigGenVars:IODevNum")
//Wave /T IOChNum = $("root:TrigGenVars:IOChNum")
//Wave /T IOWName = $("root:TrigGenVars:IOWName")
//Wave /T IOEOSH = $("root:TrigGenVars:IOEOSH")

// Re-Initialize because Make /O retains previous values

//IODevNum 	= ""
//IOChNum 	= ""
//IOWName 	= ""
//IOEOSH 	= ""


//Edit $("root:TrigGenVars:IODevNum"), $("root:TrigGenVars:IOChNum"),$("root:TrigGenVars:IOWName"),$("root:TrigGenVars:IOEOSH")

Duplicate /T/O IODevFldr, IODevFldrCopy// $("root:TrigGenVars:IODevFldrCopy")

//----
NumIOVidDevFldr = NumPnts(IOVidDevFldr)
Print "NumIOVidDevFldr", NumIOVidDevFldr

Make /T/O/N=(NumIOVidDevFldr)  $("root:TrigGenVars:IOVidDevNum")			= ""		//Initialize because Make /O retains previous values
Make /T/O/N=(NumIOVidDevFldr) 	$("root:TrigGenVars:IOVidChNum")			= ""		//Initialize because Make /O retains previous values
Make /T/O/N=(NumIOVidDevFldr) 	$("root:TrigGenVars:IOVidFramesPerSec")	= ""		//Initialize because Make /O retains previous values
Make /T/O/N=(NumIOVidDevFldr) 	$("root:TrigGenVars:IOVidWName")			= ""		//Initialize because Make /O retains previous values
Make /T/O/N=(NumIOVidDevFldr) 	$("root:TrigGenVars:IOVidEOSH")			= ""		//Initialize because Make /O retains previous values

//Wave /T IODevNum = $("root:TrigGenVars:IODevNum")
//Wave /T IOChNum = $("root:TrigGenVars:IOChNum")
//Wave /T IOWName = $("root:TrigGenVars:IOWName")
//Wave /T IOEOSH = $("root:TrigGenVars:IOEOSH")

// Re-Initialize because Make /O retains previous values

//IODevNum 	= ""
//IOChNum 	= ""
//IOWName 	= ""
//IOEOSH 	= ""


//Edit $("root:TrigGenVars:IODevNum"), $("root:TrigGenVars:IOChNum"),$("root:TrigGenVars:IOWName"),$("root:TrigGenVars:IOEOSH")

Duplicate /T/O IOVidDevFldr, IOVidDevFldrCopy// $("root:TrigGenVars:IODevFldrCopy")
//----

pt_TrigGenUpdateScanPars()			// initialize Channels

pt_TrigGenReadScanPars()			// get scan parameters (devices, channels, waves, EOSH's, etc.)

//Abort "Aborting!!"



//NVAR NumIODev 	= root:TrigGenVars:IOPars:NumIODev
//SVAR NameIODev 	= root:TrigGenVars:IOPars:NameIODev
Wave /T OutWPar 		= root:TrigGenVars:IOPars:OutWPar
Wave /T InWPar 			= root:TrigGenVars:IOPars:InWPar
Wave /T NameIODevWPar	= root:TrigGenVars:IOPars:NameIODevWPar

Wave /T DigOutWPar 			= root:TrigGenVars:IOPars:DigOutWPar
Wave /T DigInWPar 			= root:TrigGenVars:IOPars:DigInWPar
Wave /T DigInChNumPar		= root:TrigGenVars:IOPars:DigInChNumPar
Wave /T DigOutChNumPar		= root:TrigGenVars:IOPars:DigOutChNumPar
Wave /T DigNameIODevWPar	= root:TrigGenVars:IOPars:DigNameIODevWPar

//Wave /T OutWPar 		= root:TrigGenVars:IOPars:OutWPar
Wave /T VidInWPar 			= root:TrigGenVars:IOPars:VidInWPar
Wave /T NameIOVidDevWPar	= root:TrigGenVars:IOPars:NameIOVidDevWPar


Make /O/N=0 			root:TrigGenVars:IOPars:DIOTaskNumW
Make /O/N=1 			root:TrigGenVars:IOPars:DIOTaskNumWTmp

Make /T/O/N=0 			root:TrigGenVars:IOPars:DIODevTaskNumW
Make /T/O/N=1 			root:TrigGenVars:IOPars:DIODevTaskNumWTmp

Wave DIOTaskNumW 			= 	root:TrigGenVars:IOPars:DIOTaskNumW
Wave DIOTaskNumWTmp 			= 	root:TrigGenVars:IOPars:DIOTaskNumWTmp

Wave /T DIODevTaskNumW		= 	root:TrigGenVars:IOPars:DIODevTaskNumW
Wave /T DIODevTaskNumWTmp 	= 	root:TrigGenVars:IOPars:DIODevTaskNumWTmp



//IODevIDStr = ""

//TrigDevIdStr		= 	"Dev"+ TrigDevIdStr //(StringFromList(i, TrigDevIdList, ";" ))
//TrigSrcStrFull	=	"/"+TrigDevIdStr+TrigSrcStr
//ClkSrcStrFull		=	"/"+TrigDevIdStr+ClkSrcStr

// Ideally, we would like to use a clock and trigger that is separate from which device and channels we are scanning, so that it will not depend on scanning configuration
// however, nidaqtools from wavemetrics currently doesn't allow exporting triggers and clocks to RTSI bus and so that all devices can use it as a common source.
// So for now, the clock and trigger will be used from scanning operations	


//******************************************************************************************
// only port 0 can be used for buffered wave operations for digital channels. buffered wave operations
// need hardware clock that can be one of the /ai/sampleclock, /ao/sampleclock 
//etc
//How to specify the digital lines? Following is from nidaqtool help on DAQmx_DIO_Config

//When you use /LGRP=0, all lines of a DIO port are represented by a single integer. Thus, if you specify, 
//for instance, "/dev1/port0/line1,/dev1/port0/line3" and both lines are high, when you read the data with
//fDAQmx_DIO_Read the result will be 10 (21 + 23). Because you specified only the two lines, the other
//lines in the port will always be zero in the result, but the bits used to represent the lines are those that
//would be used if all lines in the port were read. On the other hand, if you use /LGRP=1, only the specified
//lines are included in the returned data, in the order in which you listed them. Thus, the example would
//return 3 (20 + 21, with bit 0 representing line 1 and bit 1 representing line 3).
//These considerations of line grouping apply to output (fDAQmx_DIO_Write) as well as input.
//******************************************************************************************

NumIODev = NumPnts(NameIODevWPar)
OldDf=GetDataFolder(1)
SetDataFolder root:


For (i=0; i<NumIODev; i+=1)	// For all devices

//	If there is an Input for this device, then set input to wait for trigger

If 	(!	(StringMatch(InWPar[i], "")		)	)
// use the 1st scan operation as the source for trigger and clock. If no scan, use the first WaveformGen operation as the source for trigger and clock
	If (TrigNClkSrcFound==0)			// 0 = not found; 1 = Scan Operation; 2 = WaveFormGen Operation
	TrigNClkSrcFound =1 						
	TrigDevIdStr		= 		NameIODevWPar[i]
	TrigSrcStrFull	=	"/"+	NameIODevWPar[i]+"/ai/StartTrigger"
	ClkSrcStrFull		=	"/"+	NameIODevWPar[i]+"/ai/SampleClock"
	i0=i
// 	the operation starting the trigger should be set up last
	Else
	DAQmx_Scan 		  /DEV= NameIODevWPar[i] /BKG      /STRT=1/TRIG=TrigSrcStrFull	/ERRH="pt_TrigGenERRH()" Waves= InWPar[i]
	EndIf
	Print fDAQmx_ErrorString()
EndIf
EndFor	

For (i=0; i<NumIODev; i+=1)	// For all devices
//	If there an Output for this device, then set output to wait for trigger
If 	(!	(StringMatch(OutWPar[i], "")		)	)
// use the 1st scan operation as the source for trigger and clock. If no scan, use the first WaveformGen operation as the source for trigger and clock
	If (TrigNClkSrcFound==0)		// 0 = not found; 1 = Scan Operation; 2 = WaveFormGen Operation; 3 = Dummy scan operation for digital triggering
	TrigNClkSrcFound =2 					
	TrigDevIdStr		= 		NameIODevWPar[i]
	TrigSrcStrFull	=	"/"+	NameIODevWPar[i]+"/ao/StartTrigger"
	ClkSrcStrFull		=	"/"+	NameIODevWPar[i]+"/ao/SampleClock"
	i0=i
// 	the operation starting the trigger should be set up last
	Else
	DAQmx_WaveformGen /DEV= NameIODevWPar[i] /NPRD=1/STRT=1/TRIG=TrigSrcStrFull /ERRH="pt_TrigGenERRH()" OutWPar[i]
	EndIf
	Print fDAQmx_ErrorString() 
EndIf
EndFor

// Digital I/O

//	Digital devices use the clock signal from analog devices. They don't act as primary triggering source for other devices

// InPut

NumIODev = NumPnts(DigNameIODevWPar)

For (i=0; i<NumIODev; i+=1)	// For all devices

If 	(!	(StringMatch(DigInWPar[i], "")		)	)
//DAQmx_DIO_Config /DEV= DevIdStr /LGRP = 1/DIR=1/ERRH="pt_LaserShutterERRH()"/EOSH="pt_LaserShutterEOSH()" DigChStr
	If (TrigNClkSrcFound==0)		// 0 = not found; 1 = Scan Operation; 2 = WaveFormGen Operation; 3 = Dummy scan operation for digital triggering
	TrigNClkSrcFound =3 					
	TrigDevIdStr		= 	  DigNameIODevWPar[i]
//	TrigSrcStrFull	=	"/"+	NameIODevWPar[i]+"/ao/StartTrigger"
	ClkSrcStrFull		=	"/"+	DigNameIODevWPar[i]+"/ai/SampleClock"		
	i0=i
	EndIf
	DAQmx_DIO_Config /DEV= DigNameIODevWPar[i] /LGRP = 1/DIR=0/ERRH="pt_TrigGenERRH()"/CLK={ClkSrcStrFull,1} /Wave={$(DigInWPar[i])}  DigInChNumPar[i]
DIODevTaskNumWTmp 	= DigNameIODevWPar[i]
DIOTaskNumWTmp 		= V_DAQmx_DIO_TaskNumber

Concatenate /NP {DIOTaskNumWTmp}, DIOTaskNumW			// Store task numbers so that fDAQmx_DIO_Finished can be used in pt_TrigGenEOSH()
Concatenate /T/NP {DIODevTaskNumWTmp}, DIODevTaskNumW	// Store Dev Names for task numbers so that fDAQmx_DIO_Finished can be used in pt_TrigGenEOSH()

print "DAQmx_DIO_Config error", fDAQmx_ErrorString()
// without fDAQmx_DIO_Finished the line is not released and successive call to DAQmx_DIO_Config gives an error
// Requested operation could not be performed, because the specified digital lines are either reserved or the device is not present in NI-DAQmx
//fDAQmx_DIO_Finished(DigNameIODevWPar[i], V_DAQmx_DIO_TaskNumber)
print "fDAQmx_DIO_Write error", fDAQmx_ErrorString()
EndIf
EndFor

// OutPut

For (i=0; i<NumIODev; i+=1)	// For all devices

If 	(!	(StringMatch(DigOutWPar[i], "")		)	)
//DAQmx_DIO_Config /DEV= DevIdStr /LGRP = 1/DIR=1/ERRH="pt_LaserShutterERRH()"/EOSH="pt_LaserShutterEOSH()" DigChStr
//Print DigNameIODevWPar, ClkSrcStrFull, DigOutWPar, DigOutChNumPar
	If (TrigNClkSrcFound==0)		// 0 = not found; 1 = Scan Operation; 2 = WaveFormGen Operation; 3 = Dummy scan operation for digital triggering
	TrigNClkSrcFound =3 					
	TrigDevIdStr		= 	  DigNameIODevWPar[i]
//	TrigSrcStrFull	=	"/"+	NameIODevWPar[i]+"/ao/StartTrigger"
	ClkSrcStrFull		=	"/"+	DigNameIODevWPar[i]+"/ai/SampleClock"		
	i0=i
	EndIf

DAQmx_DIO_Config /DEV= DigNameIODevWPar[i] /LGRP = 1/DIR=1/ERRH="pt_TrigGenERRH()"/CLK={ClkSrcStrFull,1} /Wave={$(DigOutWPar[i])}  DigOutChNumPar[i]
DIODevTaskNumWTmp 	= DigNameIODevWPar[i]
DIOTaskNumWTmp 		= V_DAQmx_DIO_TaskNumber

Concatenate /NP {DIOTaskNumWTmp}, DIOTaskNumW			// Store task numbers so that fDAQmx_DIO_Finished can be used in pt_TrigGenEOSH()
Concatenate /T/NP {DIODevTaskNumWTmp}, DIODevTaskNumW	// Store Dev Names for task numbers so that fDAQmx_DIO_Finished can be used in pt_TrigGenEOSH()

print "DAQmx_DIO_Config error", fDAQmx_ErrorString()
// without fDAQmx_DIO_Finished the line is not released and successive call to DAQmx_DIO_Config gives an error
// Requested operation could not be performed, because the specified digital lines are either reserved or the device is not present in NI-DAQmx
//fDAQmx_DIO_Finished(DigNameIODevWPar[i], V_DAQmx_DIO_TaskNumber)
print "fDAQmx_DIO_Write error", fDAQmx_ErrorString()
EndIf
EndFor

NumIOVidDevFldr = NumPnts(NameIOVidDevWPar)

	Print "Acquiring from device", 	NameIOVidDevWPar[i]
//	Print "Out Channel Num", 		VidOutWPar[i]		
	Print "In Waves", 		VidInWPar[i]			


Wave /T IOVidWName		=root:TrigGenVars:IOVidWName
Wave /T IOVidFramesPerSec	=root:TrigGenVars:IOVidFramesPerSec

NVAR ISI			= root:TrigGenVars:ISI
Wave /T IOVidDevNum		=root:TrigGenVars:IOVidDevNum
Wave /T IOVidChNum		=root:TrigGenVars:IOVidChNum

		WNoteStr = ""
//		WNoteStr += "" + ":"+Num2Str()+";"
//		WNoteStr += "Date" 				+ ":"+		Date()+";"
//		WNoteStr += "Time" 				+ ":"+		Time()+";"
//		WNoteStr += "DevNum" 			+ ":"+		IODevNum[i]+";"
//		WNoteStr += "ChNum" 			+ ":"+		IOChNum[i]+";"
		WNoteStr += "ISI" 				+ ":"+		Num2Str(ISI)+";"
		WNoteStr += "TotalIterations" 		+ ":"+		Num2Str(IterTot)+";"
		WNoteStr += "IterationNum" 		+ ":"+		Num2Str(IterTot-IterLeft)+";"
		
		
//-----------
Wave /T IOVidWName		=root:TrigGenVars:IOVidWName
//Wave /T IOVidEOSH			=root:TrigGenVars:IOVidEOSH
//Wave /T IOVidDevNum		=root:TrigGenVars:IOVidDevNum
//Wave /T IOVidChNum			=root:TrigGenVars:IOVidChNum
//Wave /T IOVidDevFldrCopy	=root:TrigGenVars:IOVidDevFldrCopy

//N = NumPnts(IOVidEOSH)

//Abort "Aborting..."
//OldDf = GetDataFolder(1)
//SetDataFolder root
//For (i=0; i<N; i+=1)
// Instead of storing acquired waves in root folder and later using EOSH to copy to individual channel folder, storing directly
// to channel folder to save space. 
				
//		VidWList = Wavelist(IOVidWName[i], ";", "")
//		NVid = ItemsInList(VidWList, "")
//		For (j=0; j<NVid, j+=1)
//		VidWName = StringFromList(VidWList)
//		EndFor
//		InWaveListStr += FldrName+":"+WName
// Copy final frame to channel folder for display
//		Duplicate /O $(IOVidDevFldrCopy[i]+":"+"M_Frame"), $(IOVidDevFldrCopy[i]+":"+IOVidWName[i])
//		SVAR FldrName 		=root:VideoFldrName
		NVAR InstNum 		= root:VideoInstNum
//		SScanf IOVidDevFldrCopy[i], "root:VideoVars%d",InstNum
		
//		No need to update current value, as EOSH does that by itself.
//		NVAR Temp 			= $(IODevFldrCopy[i]+":CurrentVideo")
//		Wave w 	= $("root:"+IOWName[i])
//		Temp	= w[NumPnts(w)-1]								// new value = last value of wave
//		Print "pt_VideoEOSH()"//, Temp
//		Execute IOVidEOSH[i]
//EndFor		
//-----------		
		

Switch (TrigNClkSrcFound)
	Case 1:
	Print "Triggering using Input on", NameIODevWPar[i0]
		DAQmx_Scan 		  /DEV= NameIODevWPar[i0] /BKG      /STRT=1 	/EOSH="pt_TrigGenEOSH()"	/ERRH="pt_TrigGenERRH()" Waves= InWPar[i0]
		
		For (i=0; i<NumIOVidDevFldr; i+=1)
//		IOVidWName[i] has the name of the wave and IOVidChNum[i] has the channel number
		Wave IOVidInW =$("root:"+IOVidWName[i])
		IOVidInWL = DimDelta(IOVidInW,0)*(NumPnts(IOVidInW)-1)		// Total length of 1 video in s (= length of other scanned waves on National Instrument boards)
		Print IOVidInWL, Str2Num(IOVidFramesPerSec[i])
// Instead of storing acquired waves in root folder and later using EOSH to copy to individual channel folder, storing directly
// to channel folder to save space. 
		//pt_CaptureVideo("root:"+IOVidWName[i], IOVidInWL, Str2Num(IOVidFramesPerSec[i]))
		WNoteStr += "DevNum" 			+ ":"+		IOVidDevNum[i]+";"
		WNoteStr += "ChNum" 			+ ":"+		IOVidChNum[i]+";"
		SScanf IOVidDevFldrCopy[i], "root:VideoVars%d",InstNum
		pt_CaptureVideo(IOVidDevFldrCopy[i]+":"+IOVidWName[i], IOVidInWL, Str2Num(IOVidFramesPerSec[i]), WNoteStr)
	
		EndFor
		
	Break
	Case 2:
	Print Time()
	Print "Triggering using Output on", NameIODevWPar[i0]
		DAQmx_WaveformGen /DEV= NameIODevWPar[i0] /NPRD=1/STRT=1	/EOSH="pt_TrigGenEOSH()"	/ERRH="pt_TrigGenERRH()" OutWPar[i0]
		
		For (i=0; i<NumIOVidDevFldr; i+=1)
//		IOVidWName[i] has the name of the wave and IOVidChNum[i] has the channel number
		Wave IOVidInW =$("root:"+IOVidWName[i])
		IOVidInWL = DimDelta(IOVidInW,0)*(NumPnts(IOVidInW)-1)		// Total length of 1 video in s (= length of other scanned waves on National Instrument boards)
		Print IOVidInWL, Str2Num(IOVidFramesPerSec[i])
// Instead of storing acquired waves in root folder and later using EOSH to copy to individual channel folder, storing directly
// to channel folder to save space. 
		//pt_CaptureVideo("root:"+IOVidWName[i], IOVidInWL, Str2Num(IOVidFramesPerSec[i]))
		WNoteStr += "DevNum" 			+ ":"+		IOVidDevNum[i]+";"
		WNoteStr += "ChNum" 			+ ":"+		IOVidChNum[i]+";"
		SScanf IOVidDevFldrCopy[i], "root:VideoVars%d",InstNum
		pt_CaptureVideo(IOVidDevFldrCopy[i]+":"+IOVidWName[i], IOVidInWL, Str2Num(IOVidFramesPerSec[i]), WNoteStr)
		EndFor
		
	Break
	Case 3:
	Print "Dummy triggering using Input on", DigNameIODevWPar[i0]
		String DummyParString = "root:DummyWave,0;"
		DAQmx_Scan 		  /DEV= DigNameIODevWPar[i0] /BKG      /STRT=1 	/EOSH="pt_TrigGenEOSH()"	/ERRH="pt_TrigGenERRH()" Waves= DummyParString//InWPar[i0]
		
		For (i=0; i<NumIOVidDevFldr; i+=1)
//		IOVidWName[i] has the name of the wave and IOVidChNum[i] has the channel number
		Wave IOVidInW =$("root:"+IOVidWName[i])
		IOVidInWL = DimDelta(IOVidInW,0)*(NumPnts(IOVidInW)-1)		// Total length of 1 video in s (= length of other scanned waves on National Instrument boards)
		Print IOVidInWL, Str2Num(IOVidFramesPerSec[i])
// Instead of storing acquired waves in root folder and later using EOSH to copy to individual channel folder, storing directly
// to channel folder to save space. 
		//pt_CaptureVideo("root:"+IOVidWName[i], IOVidInWL, Str2Num(IOVidFramesPerSec[i]))
		WNoteStr += "DevNum" 			+ ":"+		IOVidDevNum[i]+";"
		WNoteStr += "ChNum" 			+ ":"+		IOVidChNum[i]+";"
		SScanf IOVidDevFldrCopy[i], "root:VideoVars%d",InstNum
		pt_CaptureVideo(IOVidDevFldrCopy[i]+":"+IOVidWName[i], IOVidInWL, Str2Num(IOVidFramesPerSec[i]), WNoteStr)
		EndFor
		
	Break
	Default:
	Abort "No Input or output operation to generate trigger"
EndSwitch

//pt_CaptureVideo(TotalTime, FramesPerSec)
//Make /T/O/N=(NumIOVidDevFldr)  $("root:TrigGenVars:IOVidDevNum")	= ""		//Initialize because Make /O retains previous values
//Make /T/O/N=(NumIOVidDevFldr) 	$("root:TrigGenVars:IOVidChNum")	= ""		//Initialize because Make /O retains previous values
//Make /T/O/N=(NumIOVidDevFldr) 	$("root:TrigGenVars:IOVidWName")	= ""		//Initialize because Make /O retains previous values
//Make /T/O/N=(NumIOVidDevFldr) 	$("root:TrigGenVars:IOVidEOSH")		= ""		//Initialize because Make /O retains previous values


//IOChNumDev = NumPnts(TrigGenDevNum)
//NumIODev = 1
//Make /T/O/N=3 IOOutDevIdW, IOInDevIdW, IOOutTrigDestW, IOInTrigDestW, IOOutWaveParW, IOInWaveParW
//IOOutDevIdW = {"Dev1", "Dev2", "Dev3"}
//IOInDevIdW	 = {"Dev1", "", ""}
//IOOutTrigDestW =  {"/Dev1/PFI4", "/Dev2/PFI4", "/Dev3/PFI4"}
//IOInTrigDestW    = {"/Dev1/PFI4", "", ""}
//IOOutWaveParW = {"Out_1,0", "", ""}
//IOInWaveParW    = {"In_1,0", "", ""}

//IOOutDevIdW 	= 	{"Dev1", "Dev3", "Dev3"}
//IOInDevIdW	 	= 	{"Dev1", "Dev3", "Dev3"}
//IOOutTrigDestW 	=  	{"/Dev1/PFI4", "/Dev3/PFI4", "/Dev1/PFI4"}
//IOInTrigDestW    	= 	{"/Dev1/PFI4", "/Dev3/PFI4", "/Dev1/PFI4"}
//IOOutWaveParW = 	{"Out_1,0;", "Out_2,0;", ""}
//IOInWaveParW    =	{"In_1,0;In_2,4", "", ""}


// For each device set the acquisition waiting for trigger. 
//For (i=0;i<NumIODev; i+=1)
//	Print IOOutDevIdW[i], IOOutTrigDestW[i], IOOutWaveParW[i]
//	Print IOInDevIdW[i], IOInTrigDestW[i], IOInWaveParW[i]
	
//	IOOutDevIdStr 		= 	IOOutDevIdW[i]
//	IOInDevIdStr	 		= 	IOInDevIdW[i]
//	IOOutTrigDestStr 		=  	IOOutTrigDestW[i]
//	IOInTrigDestStr    	=	IOInTrigDestW[i]	
//	IOOutWaveParStr 	= 	IOOutWaveParW[i]
//	IOInWaveParStr   	=	IOInWaveParW[i]

//If (!StringMatch(IOOutWaveParStr, ""))
//	DAQmx_WaveformGen /DEV= IOOutDevIdStr /NPRD=1/STRT=1/TRIG=IOOutTrigDestStr /ERRH="pt_EPhysErrorHook()" IOOutWaveParStr // EOSH for Out waves ToDo
//EndIf	
//If (!StringMatch(IOInWaveParStr, ""))
//	DAQmx_Scan /DEV= IOInDevIdStr /BKG /STRT=1/TRIG=IOInTrigDestStr /ERRH="pt_EPhysErrorHook()" /EOSH="" Waves= IOOutWaveParStr
//EndIf	
//EndFor

//DAQmx_WaveformGen /DEV= "Dev1" /NPRD=1/STRT=1/TRIG="/Dev1/PFI4" /ERRH="pt_EPhysErrorHook()" "Out_1,0;"
//DAQmx_Scan /DEV= "Dev1" /BKG /STRT=1/TRIG="/Dev1/PFI4" /ERRH="pt_EPhysErrorHook()" /EOSH="" Waves= "In_1,0;In_2,4;"
//DAQmx_DIO_Config /DEV= "Dev3" /LGRP = 1/DIR=0/ERRH="pt_TrigGenERRH()" "/Dev3/PFI0"

//DAQmx_WaveformGen /DEV= "Dev3" /NPRD=1/STRT=1/TRIG= "/Dev3/PFI0" /ERRH="pt_EPhysErrorHook()" "Out_2,0;"
//DAQmx_Scan /DEV= IOInDevIdStr /BKG /STRT=1/TRIG=IOInTrigDestStr /ERRH="pt_EPhysErrorHook()" /EOSH="" Waves= IOOutWaveParStr

//We can use the following logic for now: Later we can generalize it. ToDo
// If there is a analog scanning operation, then use the clock from that
// If not, if there is a analog waveform generation event, event use the clock from that
// We could also use the trigger from scanning (or if no scanning, waveform generation). In that case, the operation generating the trigger (scanning or generation) should be started
// last. It seems cleaner to generate the trigger independently and all events operations listen to that trigger.


// All waves for scanning should have the same number of points (the rate is set up by the scaling of the first wave). Same holds true for waveform generation


// For the time being assume that the main clock is taken from scanning or waveform generation on Dev1, routed to RTSI and is used by all devices including the initiating device.
// The scanning and wvaeform generation clocks are derived (see M Series User Manual).Similarly the trigger goes to RTSI and then to all devices.
// READ DIGITAL ROUTING AND CLOCK GENERATION
 
// from the same master clock, which means they are in synch (on the same device). The actual scanning and waveform generation rate (which need not be the same. What needs to be the same is
//the total number of points) that is set by wavescaling of first wave is 'probably' the converter clock which periodically cause analog to digital conversions to occur.
// Thus,

//DAQmx_WaveformGen /DEV= "Dev1" /NPRD=1/STRT=1/TRIG="/Dev1/PFI4" /ERRH="pt_EPhysErrorHook()" "Out_1,0;"
//DAQmx_Scan /DEV= "Dev1" /BKG /STRT=1/TRIG="/Dev1/PFI4" /ERRH="pt_EPhysErrorHook()" /EOSH="" Waves= "In_1,0;In_2,4;"

// (now the waveform generation and scanning both use the same clock so no need to specify. )

//For (i=0;i<NumTrigDev; i+=1)
//	TrigDevIdStr	= "Dev"+ TrigDevIdStr //(StringFromList(i, TrigDevIdList, ";" ))
//	TrigDestStr 	=		StringFromList(i, TrigDestList, ";")
//	TrigSrcStrFull	="/"+TrigDevIdStr+TrigSrcStr
	// Assuming it's a digital source for now. ToDo: Allow for any source.
	// Should DIR be =0 or 1. Is the port reading in the value or reading out the value
	// TrigDest should also contain the dev name
	// End Of Hook Scan works only with /Wave = Buffered wave
//	Print "Triggering device",TrigDevIdStr,"at", TrigSrcStr,"at", time(), "on", Date()
//	DAQmx_DIO_Config /DEV= DevIdStr /LGRP = 1/DIR=1/ERRH="pt_TrigGenERRH()"/EOSH="pt_TrigGenEOSH()" TrigDest
//	DAQmx_DIO_Config /DEV= TrigDevIdStr /LGRP = 1/DIR=1/ERRH="pt_TrigGenERRH()" /EOSH= "pt_TrigGenEOSH()" TrigSrcStrFull
//	print "DAQmx_DIO_Config error", fDAQmx_ErrorString()
// 	Set to High
//	fDAQmx_DIO_Write(TrigDevIdStr, V_DAQmx_DIO_TaskNumber, OutVal)
// 	Set back to low
//	OutVal=0
//	fDAQmx_DIO_Write(TrigDevIdStr, V_DAQmx_DIO_TaskNumber, OutVal)
	// without fDAQmx_DIO_Finished the line is not released and successive call to DAQmx_DIO_Config gives an error
	// Requested operation could not be performed, because the specified digital lines are either reserved or the device is not present in NI-DAQmx
//	fDAQmx_DIO_Finished(TrigDevIdStr, V_DAQmx_DIO_TaskNumber)	
//	print "fDAQmx_DIO_Write error", fDAQmx_ErrorString()

//EndFor
	IterLeft -=1
//BackgroundInfo
//Print V_flag
// Return 0 otherwise the background function will not run again
SetDataFolder OldDf

String TrigGenErr = fDAQmx_ErrorString()
If (!StringMatch(TrigGenErr,""))
	Print TrigGenErr
	pt_TrigGenERRH()
EndIf

If ((IterLeft ==0) && (RepsLeft >0))	// initialize when starting a new repeat
//IterLeft = IterTot
RepsLeft -=1
//Print "Starting repeat #", RepsTot - RepsLeft + 1
//pt_TrigGenIntializeChan()			// initialize Channels
EndIf

If (RepsLeft <1)
	Print "-------------------------------------------------------------------------------------------------------------------------------------------------------------------"
	Print "Starting final iteration at", time(), "on", Date(),". Iterations left=", IterLeft
	Print "-------------------------------------------------------------------------------------------------------------------------------------------------------------------"
	Button button0, disable=0, win=TrigGenMain // Enable Start Button
	Button button2, disable=2, win=TrigGenMain // Disable Reset Start Button
	StopExpt   = 1
	PauseExpt = 0	// In case pause experiment was pressed just before the experiement was going to end anyway.
	Return 1
EndIf

If ((IterLeft ==0) && (RepsLeft >0))	// initialize when starting a new repeat
IterLeft = IterTot
//RepsLeft -=1
Print "Starting repeat #", RepsTot - RepsLeft + 1
//pt_TrigGenIntializeChan()			// initialize Channels
EndIf




Return 0
End

Function pt_TrigGenERRH()
SVAR FldrName 			=  root:TrigGenFldrName
NVAR TrigGenError 	= $FldrName+":TrigGenError"
	TrigGenError = 1
	Print "*****************************************"
	Print "DataAcquisition Error in", FldrName
	Print "*****************************************"
	pt_TrigGenEOSH()
End




Function pt_TrigGenEOSH()
// From here call EOSH for different channels. The input and output can have different EOSH also.

//EOSH can perform stuff like postprocessing, display, analysis , save,  and maybe prepare the next stimulus. + we can add stuff to do in future. 
// before starting the scan at least for the first time , each  channel should set up the stim. 
NVAR IterTot 		= root:TrigGenVars:IterTot
NVAR IterLeft 		= root:TrigGenVars:IterLeft
NVAR ISI			= root:TrigGenVars:ISI

String WNoteStr
Variable i, N, DIO_TaskNumber

//Wave DIOTaskNumW 		=root:TrigGenVars:DIOTaskNumW
Wave DIOTaskNumW 		=root:TrigGenVars:IOPars:DIOTaskNumW	//02/05/14 Praveen
//Wave /T DIODevTaskNumW 	=root:TrigGenVars:DIODevTaskNumW
Wave /T DIODevTaskNumW 	=root:TrigGenVars:IOPars:DIODevTaskNumW	//02/05/14 Praveen


Wave /T IOWName		=root:TrigGenVars:IOWName
Wave /T IOEOSH			=root:TrigGenVars:IOEOSH
Wave /T IODevNum		=root:TrigGenVars:IODevNum
Wave /T IOChNum		=root:TrigGenVars:IOChNum
Wave /T IODevFldrCopy	=root:TrigGenVars:IODevFldrCopy

N= NumPnts(DIOTaskNumW)
For (i=0; i<N; i+=1)
	fDAQmx_DIO_Finished(DIODevTaskNumW[i], DIOTaskNumW[i])
EndFor

N = NumPnts(IOEOSH)

//Abort "Aborting..."
For (i=0; i<N; i+=1)

StrSwitch (IOEOSH[i])

	Case "pt_EPhysEOSH()" :
//		SVAR FldrName 		=root:EPhysFldrName
		NVAR InstNum 		= root:EPhysInstNum
		
		
		SScanf IODevFldrCopy[i], "root:EPhysVars%d",InstNum
		If (StringMatch(IOWName[i], "*In"))
		
		WNoteStr = ""
//		WNoteStr += "" + ":"+Num2Str()+";"
		WNoteStr += "Date" 				+ ":"+		Date()+";"
		WNoteStr += "Time" 				+ ":"+		Time()+";"
		WNoteStr += "DevNum" 			+ ":"+		IODevNum[i]+";"
		WNoteStr += "ChNum" 			+ ":"+		IOChNum[i]+";"
		WNoteStr += "ISI" 				+ ":"+		Num2Str(ISI)+";"
		WNoteStr += "TotalIterations" 		+ ":"+		Num2Str(IterTot)+";"
		WNoteStr += "IterationNum" 		+ ":"+		Num2Str(IterTot-IterLeft)+";"
//		Note $("root:"+IOWName[i]), WNoteStr
		Note $(IOWName[i]), WNoteStr
		
//		Duplicate /O $("root:"+IOWName[i]), $(IODevFldrCopy[i]+":"+IOWName[i])
		EndIf
		Print "pt_EPhysEOSH()"
		Execute IOEOSH[i]
	Break
	Case "pt_TemperatureEOSH()" :
//		Duplicate /O $("root:"+IOWName[i]), $(IODevFldrCopy[i]+":"+IOWName[i])
//		SVAR FldrName 		=root:TemperatureFldrName
		NVAR InstNum 		= root:TemperatureInstNum
		SScanf IODevFldrCopy[i], "root:TemperatureVars%d",InstNum
		
//		No need to update current value, as EOSH does that by itself.
//		NVAR Temp 			= $(IODevFldrCopy[i]+":CurrentTemperature")
//		Wave w 	= $("root:"+IOWName[i])
//		Temp	= w[NumPnts(w)-1]								// new value = last value of wave
		Print "pt_TemperatureEOSH()"//, Temp
		Execute IOEOSH[i]
	Break
	Case "pt_ScanMirrorEOSH()" :
//		Duplicate /O $("root:"+IOWName[i]), $(IODevFldrCopy[i]+":ScanMirrorWave")
//		SVAR FldrName 		=root:ScanMirrorFldrName
		NVAR InstNum 		= root:ScanMirrorInstNum
		SScanf IODevFldrCopy[i], "root:ScanMirrorVars%d",InstNum
		
		
		Wave /T ScanMirrorHWName = $(IODevFldrCopy[i]+":ScanMirrorHWName")
		Wave /T ScanMirrorHWVal =    $(IODevFldrCopy[i]+":ScanMirrorHWVal")
		
		Variable XDist2VoltageGain	= Str2Num(ScanMirrorHWVal[3])
		Variable YDist2VoltageGain	= Str2Num(ScanMirrorHWVal[4])
		Variable XOffset				= Str2Num(ScanMirrorHWVal[5])
		Variable YOffset				= Str2Num(ScanMirrorHWVal[6])
		
//		Wave 	w = $("root:"+IOWName[i])
//		Wave 	w = $(IOWName[i])
		If (StringMatch(IOWName[i], "*XScldOut"))		// X-Channel		// new value = last value of wave
		NVAR	x2	= $(IODevFldrCopy[i]+":NewXValue")
//		Wave 	w = $("root:"+IOWName[i])	
		Wave 	w = $(IOWName[i])	
		x2 = XOffset + (w[NumPnts(w)-1]/(XDist2VoltageGain)	)	
		Else 									// Y-Channel
		NVAR	y2	= $(IODevFldrCopy[i]+":NewYValue")
		Wave 	w = $(IOWName[i])
		y2 = YOffset+ (w[NumPnts(w)-1]/(YDist2VoltageGain))		// new value = last value of wave
//		Wave 	w = $("root:"+IOWName[i])	
//		Wave 	w = $(IOWName[i])	
		Print "pt_ScanMirrorEOSH()"//, X2, Y2				// pt_ScanMirrorEOSH() is called just once
		Execute IOEOSH[i]
		EndIf
		
	Break
	Case "pt_LaserShutterEOSH()" :
//		Duplicate /O $("root:"+IOWName[i]), $(IODevFldrCopy[i]+":LaserShutterVWave")
//		SVAR FldrName 		=root:LaserShutterFldrName
		NVAR InstNum 		= root:LaserShutterInstNum
		SScanf IODevFldrCopy[i], "root:LaserShutterVars%d",InstNum
		
		NVAR CurrentShutterState	= $(IODevFldrCopy[i]+":CurrentShutterState")
//		Wave w = $("root:"+IOWName[i])
		Wave w = $(IOWName[i])
//		CurrentShutterState = w[NumPnts(w)-1]					// new value = last value of wave
// 		Since the EOSH toggles anyway, we should set the current value to be =1- the new value
		CurrentShutterState = 1-w[NumPnts(w)-1]					// new value = last value of wave
		Print "pt_LaserShutterEOSH()"//, CurrentShutterState
		Execute IOEOSH[i]
	Break
	Case "pt_LaserVoltageEOSH()" :
//		Duplicate /O $("root:"+IOWName[i]), $(IODevFldrCopy[i]+":LaserPowerVWave")
//		SVAR FldrName 		=root:LaserVoltageFldrName
		NVAR InstNum 		= root:LaserVoltageInstNum
		SScanf IODevFldrCopy[i], "root:LaserVoltageVars%d",InstNum
		NVAR	V2	= $(IODevFldrCopy[i]+":NewVValue")
//		Wave w = $("root:"+IOWName[i])
		Wave w = $(IOWName[i])
		V2 = w[NumPnts(w)-1]								// new value = last value of wave
		Print "pt_LaserVoltageEOSH()"//, V2
		Execute IOEOSH[i]
	Break
	Case "pt_LaserPowerEOSH()" :
//		Duplicate /O $("root:"+IOWName[i]), $(IODevFldrCopy[i]+":"+IOWName[i])
//		SVAR FldrName 		=root:LaserPowerFldrName
		NVAR InstNum 		= root:LaserPowerInstNum
		SScanf IODevFldrCopy[i], "root:LaserPowerVars%d",InstNum
//		No need to update current value, as EOSH does that by itself.		
//		NVAR	power = $(IODevFldrCopy[i]+":CurrentLaserPower")
//		Wave w 	= $("root:"+IOWName[i])
//		power 	= w[NumPnts(w)-1]							// new value = last value of wave
		Print "pt_LaserPowerEOSH()"//, power
		Execute IOEOSH[i]
	Break



EndSwitch

EndFor


Wave /T IOVidWName		=root:TrigGenVars:IOVidWName
Wave /T IOVidEOSH			=root:TrigGenVars:IOVidEOSH
Wave /T IOVidDevNum		=root:TrigGenVars:IOVidDevNum
Wave /T IOVidChNum			=root:TrigGenVars:IOVidChNum
Wave /T IOVidDevFldrCopy	=root:TrigGenVars:IOVidDevFldrCopy

N = NumPnts(IOVidEOSH)

//Abort "Aborting..."
//OldDf = GetDataFolder(1)
//SetDataFolder root
For (i=0; i<N; i+=1)
// Instead of storing acquired waves in root folder and later using EOSH to copy to individual channel folder, storing directly
// to channel folder to save space. 
				
//		VidWList = Wavelist(IOVidWName[i], ";", "")
//		NVid = ItemsInList(VidWList, "")
//		For (j=0; j<NVid, j+=1)
//		VidWName = StringFromList(VidWList)
//		EndFor
//		InWaveListStr += FldrName+":"+WName
// Copy final frame to channel folder for display
//		Duplicate /O $(IOVidDevFldrCopy[i]+":"+"M_Frame"), $(IOVidDevFldrCopy[i]+":"+IOVidWName[i])
//		SVAR FldrName 		=root:VideoFldrName
//		NVAR InstNum 		= root:VideoInstNum
//		SScanf IOVidDevFldrCopy[i], "root:VideoVars%d",InstNum
		
//		No need to update current value, as EOSH does that by itself.
//		NVAR Temp 			= $(IODevFldrCopy[i]+":CurrentVideo")
//		Wave w 	= $("root:"+IOWName[i])
//		Temp	= w[NumPnts(w)-1]								// new value = last value of wave
		Print "pt_VideoEOSH()"//, Temp
//		Execute IOVidEOSH[i]
		pt_VideoEOSH("VideoCall")
EndFor		
End

Function pt_TrigGenIntializeChan()
String	ChannelName
Variable i, N
// Some parameters need to be updated once and some need to be updated before every iteration.
// Here we update paramertes that need to be updated just once before the scan
Wave /T IODevFldr		=root:TrigGenVars:IODevFldr
Wave /T IOVidDevFldr		=root:TrigGenVars:IOVidDevFldr

N= NumPnts(IODevFldr) 
For (i=0; i<N; i+=1)	
	ChannelName = ""
//	Print "Initializing", IODevFldr[i], "using", 

	If (StrSearch(IODevFldr[i],"EPhys",0)!=-1)
		Print "Initializing", IODevFldr[i], "using", "pt_EPhysInitialize()"
//		SVAR FldrName = root:EPhysFldrName
//		FldrName = IODevFldr[i]
		NVAR InstNum = root:EPhysInstNum
		SScanf IODevFldr[i], "root:EPhysVars%d",InstNum
		pt_EPhysInitialize("TrigGen")
//		pt_EPhysScan("TrigGen")
	EndIf
	
	If (StrSearch(IODevFldr[i],"Temperature",0)!=-1)
		Print "Initializing", IODevFldr[i], "using", "pt_TemperatureInitialize()"
//		SVAR FldrName = root:TemperatureFldrName
//		FldrName = IODevFldr[i]
		NVAR InstNum = root:TemperatureInstNum
		SScanf IODevFldr[i], "root:TemperatureVars%d",InstNum
		pt_TemperatureInitialize("TrigGen")
//		pt_TemperatureAcquire("TrigGen")
	EndIf
	
	If (StrSearch(IODevFldr[i],"Video",0)!=-1)
		Print "Initializing", IODevFldr[i], "using", "pt_VideoInitialize()"
//		SVAR FldrName = root:VideoFldrName
//		FldrName = IODevFldr[i]
		NVAR InstNum = root:VideoInstNum
		SScanf IODevFldr[i], "root:VideoVars%d",InstNum
		pt_VideoInitialize("TrigGen")
//		pt_VideoAcquire("TrigGen")
	EndIf
	
	If (StrSearch(IODevFldr[i],"ScanMirror",0)!=-1)
		Print "Initializing", IODevFldr[i], "using", "pt_ScanMirrorInitialize()"
//		SVAR FldrName = root:ScanMirrorFldrName
//		FldrName = IODevFldr[i]
		NVAR InstNum = root:ScanMirrorInstNum
		SScanf IODevFldr[i], "root:ScanMirrorVars%d",InstNum
		pt_ScanMirrorInitialize("TrigGen")
//		pt_ScanMirrorMove("TrigGen")
	EndIf
	
	If (StrSearch(IODevFldr[i],"LaserShutter",0)!=-1)
		Print "Initializing", IODevFldr[i], "using", "pt_LaserShutterInitialize()"
//		SVAR FldrName = root:LaserShutterFldrName
//		FldrName = IODevFldr[i]
		NVAR InstNum = root:LaserShutterInstNum
		SScanf IODevFldr[i], "root:LaserShutterVars%d",InstNum
		pt_LaserShutterInitialize("TrigGen")
//		pt_LaserShutterToggle("TrigGen")
	EndIf
	
	If (StrSearch(IODevFldr[i],"LaserVoltage",0)!=-1)
		Print "Initializing", IODevFldr[i], "using", "pt_LaserVoltageInitialize()"
//		SVAR FldrName = root:LaserVoltageFldrName
//		FldrName = IODevFldr[i]
		NVAR InstNum = root:LaserVoltageInstNum
		SScanf IODevFldr[i], "root:LaserVoltageVars%d",InstNum
		pt_LaserVoltageInitialize("TrigGen")
//		pt_LaserVoltageApply("TrigGen")
	EndIf
	
	If (StrSearch(IODevFldr[i],"LaserPower",0)!=-1)
		Print "Initializing", IODevFldr[i], "using", "pt_LaserPowerInitialize()"
//		SVAR FldrName = root:LaserPowerFldrName
//		FldrName = IODevFldr[i]
		NVAR InstNum = root:LaserPowerInstNum
		SScanf IODevFldr[i], "root:LaserPowerVars%d",InstNum
		pt_LaserPowerInitialize("TrigGen")
//		pt_LaserPowerAcquire("TrigGen")
	EndIf
	
EndFor


//===
N= NumPnts(IOVidDevFldr) 
For (i=0; i<N; i+=1)	
	ChannelName = ""	

	If (StrSearch(IOVidDevFldr[i],"Video",0)!=-1)
		Print "Initializing", IOVidDevFldr[i], "using", "pt_VideoInitialize()"
//		SVAR FldrName = root:VideoFldrName
//		FldrName = IOVidDevFldr[i]
		NVAR InstNum = root:VideoInstNum
		SScanf IOVidDevFldr[i], "root:VideoVars%d",InstNum
		pt_VideoInitialize("TrigGen")
//		pt_VideoAcquire("TrigGen")
	EndIf
	
EndFor
//===

End


Function pt_TrigGenUpdateScanPars()
String	ChannelName
Variable i, N
// Some parameters need to be updated once and some need to be updated before every iteration.
// Here we update paramertes that need to be updated before every iteration
Wave /T IODevFldrCopy		=root:TrigGenVars:IODevFldrCopy
Wave /T IOVidDevFldrCopy	=root:TrigGenVars:IOVidDevFldrCopy

N= NumPnts(IODevFldrCopy) 
For (i=0; i<N; i+=1)	
	ChannelName = ""
//	Print "Initializing", IODevFldrCopy[i], "using", 

	If (StrSearch(IODevFldrCopy[i],"EPhys",0)!=-1)
		Print "Updating parameters", IODevFldrCopy[i], "using", "pt_EPhysScan(TrigGen)"
//		SVAR FldrName = root:EPhysFldrName
//		FldrName = IODevFldrCopy[i]
		NVAR InstNum = root:EPhysInstNum
		SScanf IODevFldrCopy[i], "root:EPhysVars%d",InstNum
//		pt_EPhysInitialize("TrigGen")
		pt_EPhysScan("TrigGen")
	EndIf
	
	If (StrSearch(IODevFldrCopy[i],"Temperature",0)!=-1)
		Print "Updating parameters", IODevFldrCopy[i], "using", "pt_TemperatureAcquire(TrigGen)"
//		SVAR FldrName = root:TemperatureFldrName
//		FldrName = IODevFldrCopy[i]
		NVAR InstNum = root:TemperatureInstNum
		SScanf IODevFldrCopy[i], "root:TemperatureVars%d",InstNum
//		pt_TemperatureInitialize("TrigGen")
		pt_TemperatureAcquire("TrigGen")
	EndIf
	
	If (StrSearch(IODevFldrCopy[i],"Video",0)!=-1)
		Print "Updating parameters", IODevFldrCopy[i], "using", "pt_VideoSnapShot(TrigGen)"
//		SVAR FldrName = root:VideoFldrName
//		FldrName = IODevFldrCopy[i]
		NVAR InstNum = root:VideoInstNum
		SScanf IODevFldrCopy[i], "root:VideoVars%d",InstNum
//		pt_VideoInitialize("TrigGen")
		pt_VideoSnapShot("TrigGen")
	EndIf
	
	If (StrSearch(IODevFldrCopy[i],"ScanMirror",0)!=-1)
		Print "Updating parameters", IODevFldrCopy[i], "using", "pt_ScanMirrorMove(TrigGen)"
//		SVAR FldrName = root:ScanMirrorFldrName
//		FldrName = IODevFldrCopy[i]
		NVAR InstNum = root:ScanMirrorInstNum
		SScanf IODevFldrCopy[i], "root:ScanMirrorVars%d",InstNum
//		pt_ScanMirrorInitialize("TrigGen")
		pt_ScanMirrorMove("TrigGen")
	EndIf
	
	If (StrSearch(IODevFldrCopy[i],"LaserShutter",0)!=-1)
		Print "Updating parameters", IODevFldrCopy[i], "using", "pt_LaserShutterToggle(TrigGen)"
//		SVAR FldrName = root:LaserShutterFldrName
//		FldrName = IODevFldrCopy[i]
		NVAR InstNum = root:LaserShutterInstNum
		SScanf IODevFldrCopy[i], "root:LaserShutterVars%d",InstNum
//		pt_LaserShutterInitialize("TrigGen")
		pt_LaserShutterToggle("TrigGen")
	EndIf
	
	If (StrSearch(IODevFldrCopy[i],"LaserVoltage",0)!=-1)
		Print "Updating parameters", IODevFldrCopy[i], "using", "pt_LaserVoltageApply(TrigGen)"
//		SVAR FldrName = root:LaserVoltageFldrName
//		FldrName = IODevFldrCopy[i]
		NVAR InstNum = root:LaserVoltageInstNum
		SScanf IODevFldrCopy[i], "root:LaserVoltageVars%d",InstNum
//		pt_LaserVoltageInitialize("TrigGen")
		pt_LaserVoltageApply("TrigGen")
	EndIf
	
	If (StrSearch(IODevFldrCopy[i],"LaserPower",0)!=-1)
		Print "Updating parameters", IODevFldrCopy[i], "using", "pt_LaserPowerAcquire(TrigGen)"
//		SVAR FldrName = root:LaserPowerFldrName
//		FldrName = IODevFldrCopy[i]
		NVAR InstNum = root:LaserPowerInstNum
		SScanf IODevFldrCopy[i], "root:LaserPowerVars%d",InstNum
//		pt_LaserPowerInitialize("TrigGen")
		pt_LaserPowerAcquire("TrigGen")
	EndIf
	
EndFor

//======

N= NumPnts(IOVidDevFldrCopy) 
For (i=0; i<N; i+=1)	
	ChannelName = ""
//	Print "Initializing", IOVidDevFldrCopy[i], "using", 

If (StrSearch(IOVidDevFldrCopy[i],"Video",0)!=-1)
		Print "Updating parameters", IOVidDevFldrCopy[i], "using", "pt_VideoSnapShot(TrigGen)"
//		SVAR FldrName = root:VideoFldrName
//		FldrName = IOVidDevFldrCopy[i]
		NVAR InstNum = root:VideoInstNum
		SScanf IOVidDevFldrCopy[i], "root:VideoVars%d",InstNum
//		pt_VideoInitialize("TrigGen")
		pt_VideoSnapShot("TrigGen")
	EndIf

EndFor

//======

End


//Function pt_TrigGenEOSH()
//NVAR IterLeft 		= root:TrigGenVars:IterLeft
//Print " TrigGen EOSH triggered"
//IterLeft -=1
//End


Function pt_TrigGenStop(Button1) : ButtonControl
String Button1
NVAR StopExpt		= root:TrigGenVars:StopExpt
NVAR PauseExpt		= root:TrigGenVars:PauseExpt
Print "Stopping TrigGen..."
StopExpt = 1
PauseExpt = 0	// In case the user paused the expt and then stopped it. Setting PauseExpt = 0, allows Start button to re-initialize.
End

Function pt_TrigGenPause(Button7) : ButtonControl
String Button7
NVAR StopExpt			= root:TrigGenVars:StopExpt
NVAR PauseExpt		= root:TrigGenVars:PauseExpt
NVAR ISI				= root:TrigGenVars:ISI

Wave /T IODevFldr			=root:TrigGenVars:IODevFldr

If (StopExpt)
Print "You can't pause a stopped experiment. Please start the experiment first." 
ElseIf (PauseExpt)
	Print "Did you wait for",ISI,"seconds for the Scan paused by user message? If yes, Either stop the experimement or start it again."
Else
Print "Pausing TrigGen temporarily...Please wait for nearly",ISI,"seconds"
PauseExpt = 1
Duplicate /O IODevFldr, root:TrigGenVars:IODevFldrPrePause
EndIf
End

Function pt_TrigGenResetStart(ButtonVarName) :  ButtonControl
String ButtonVarName

Button Button0, disable=0, win=TrigGenMain // Enable Start Button
Button Button2, disable=2, win=TrigGenMain // Disable Reset Start Button

End


Function pt_TrigGenResetDev(Button2) : ButtonControl
String Button2

//String DevIdStr, DevIdStrList
Variable NumDev, i  

//Wave /T TrigGenHWName	=root:TrigGenVars:TrigGenHWName
//Wave /T TrigGenHWVal		=root:TrigGenVars:TrigGenHWVal
Wave /T NameIODevWPar	= root:TrigGenVars:IOPars:NameIODevWPar

//DevIdStrList  = TrigGenHWVal[0]
NumDev		=NumPnts(NameIODevWPar)	

//Print "-------------------------------------------------------------------------------------------------------------------------------------------------------------------"
//Print "Resetting TrigGen devices",DevIdStrList, "at", time(), "on", Date()
//Print "-------------------------------------------------------------------------------------------------------------------------------------------------------------------"

For (i = 0; i<NumDev; i+=1)
Print "Resetting TrigGen devices",NameIODevWPar[i], "at", time(), "on", Date()
fDAQmx_ResetDevice(NameIODevWPar[i])
EndFor

Print "Killing background Trigger generation job"
KIllBackground //pt_TrigGenBkGrnd kill =1
//Button button0, disable=0, win=TrigGenMain // enable 

End

Function pt_TrigGenSaveConfig1()
// Save a configuration. Will allow user to quickly change between different configurations
// What to save.
// EPhys - VClamp/IClamp; OutGain; InGain; OutWave CheckBox; InWave CheckBox; Rnd CheckBox; 
// TrigGen - Channels to scan; IterTot; Stim Pattern for scanned channels; 
// Save & Load configs from HardDisk. 
// Data to save are variables, strings, and waves. Essentially everything can be stored as waves. 

End

Function pt_TrigGenLoadConfig()
// Load a configuration
End

 Function pt_MouseXYLocMain()
 NewDataFolder /O root:MouseXYLocVars
  Variable /G root:MouseXYLocVars:StimOnClick=0
 Variable /G root:MouseXYLocVars:CurrentXLoc=0
 Variable /G root:MouseXYLocVars:CurrentYLoc=0
 
 Variable /G root:MouseXYLocVars:NewXOrigin=0
 Variable /G root:MouseXYLocVars:NewYOrigin=0
 //Variable /G root:MouseXYLocVars:StartPosClickVar=0
 
 //Variable /G root:MouseXYLocVars:XAxisReversed=0
 //Variable /G root:MouseXYLocVars:YAxisReversed=1
 
Make /O/N=0 root:MouseXYLocVars:XLocW
Make /O/N=0 root:MouseXYLocVars:YLocW

 DoWindow MouseXYLocMain
	If (V_Flag==1)
		DoWindow /K MouseXYLocMain
	EndIf
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(525,75,790,175)
	DoWindow /C MouseXYLocMain
	SetDrawLayer UserBack
	Button button6,pos={8,10},	size={70,20},	title="Copy Image", proc = pt_CopyImage, userdata="root:MouseXYLocVars"
	Button button4,pos={88,10},	size={70,20},	title="Load Image", 	proc = pt_ImageLoad, userdata="root:MouseXYLocVars"
	PopupMenu MouseXYLocPopUp0, pos={168,10},size={70,16},title="New Origin"	
	PopupMenu MouseXYLocPopUp0, mode = 0, value="LT;LB;C;RT;RB", proc = pt_ScaleOffset

//	SetVariable setvar0,pos={112,10},size={70,16},title="X0", value=$"root:MouseXYLocVars:NewXOrigin", limits={-inf, inf, 0 }, proc = pt_ScaleOffset
//	SetVariable setvar1,pos={192,10},size={70,16},title="Y0", value=$"root:MouseXYLocVars:NewYOrigin", limits={-inf, inf, 0 }, proc = pt_ScaleOffset
//	DrawText 15,50,"Invert Axis"
	DrawText 15,50,"Left click on image"
	DrawText 15,65,"to add points"
//	Button button1,pos={130,35},	size={50,20},	title="X", 	proc = pt_ScaleAxisPolarity
//	Button button2,pos={210,35},	size={50,20},	title="Y", 	proc = pt_ScaleAxisPolarity
	Button button3,pos={5,70},		size={50,20},	title="Clear", 	proc = pt_MouseXYLocClear
	Button button0,pos={130,70},	size={50,20},	title="Add",  proc = pt_MouseXYLocStartStop
	Button button5,pos={68,70},	size={50,20},	title="Reset",  disable =2
	Button button5,proc = pt_MouseXYLocResetStartStop
	CheckBox StimOnClick,pos={130,45},size={54,14},title="Auto Stim",value= 0
	CheckBox StimOnClick,variable= $("root:MouseXYLocVars:StimOnClick"), proc = pt_MouseXYLocStimOnClickParEdit
	
	ValDisplay valdisp0,pos={195,53},size={50,15},title="X"
	String Cxl = "root:MouseXYLocVars:CurrentXLoc"
	ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000},value= #Cxl
	ValDisplay valdisp1,pos={195,73},size={50,15},title="Y"
	String Cyl = "root:MouseXYLocVars:CurrentYLoc"
	ValDisplay valdisp1,limits={0,0,0},barmisc={0,1000},value= #Cyl
 End

Function pt_MouseXYLocClear(ButtonVarName) : ButtonControl
String ButtonVarName
Wave XLocW = root:MouseXYLocVars:XLocW
Wave YLocW = root:MouseXYLocVars:YLocW
If ( (NumPnts(XLocW) >0) && (NumPnts(YLocW) >0 ) )
DeletePoints NumPnts(XLocW)-1, 1, XLocW
DeletePoints NumPnts(YLocW)-1, 1, YLocW
EndIf
End

Function pt_MouseXYLocStartStop(ButtonVarName) : ButtonControl
String ButtonVarName
String OldDf
//NVAR StartPosClickVar= root:MouseXYLocVars:StartPosClickVar
// This procedure will create a MainWindowName which will be used by PauseForUser
//StartPosClickVar = 1		//-StartPosClickVar // toggle
//Do
//	If  (StartPosClickVar==0)
//		Break
//	EndIf
OldDf = GetDataFolder(1)
SetDataFolder root:MouseXYLocVars
	pt_MouseXYLocInPixel(0)
SetDataFolder OldDf	
//	PauseForUser
//	String s ="00"
//	do
//		Print "Waiting for mouse click"
//		s = MouseState("")
//		Print "s=", s			
//		if (StringMatch(s[0], "1"))		// left button clicked => Add another point
//			break
//		endif
//		if (StringMatch(s[1], "1"))		// right button clicked => Stop 
//			StartPosClickVar =0	
//			break
//		endif
//		
//	while (1)	
//	Print "Mouse was clicked"
//While (1)
End


Function pt_MouseXYLocResetStartStop(ButtonVarName) : ButtonControl
String ButtonVarName
//String OldDf
//NVAR StartPosClickVar= root:MouseXYLocVars:StartPosClickVar
// This procedure will create a MainWindowName which will be used by PauseForUser
//StartPosClickVar = 1		//-StartPosClickVar // toggle
//Do
//	If  (StartPosClickVar==0)
//		Break
//	EndIf
//OldDf = GetDataFolder(1)
//SetDataFolder root:MouseXYLocVars
	Button button0, disable=0, win=MouseXYLocMain	// Enable Add Button
	Button button5, disable=2, win=MouseXYLocMain	// Disable Reset Add Button
//SetDataFolder OldDf	
//	PauseForUser
//	String s ="00"
//	do
//		Print "Waiting for mouse click"
//		s = MouseState("")
//		Print "s=", s			
//		if (StringMatch(s[0], "1"))		// left button clicked => Add another point
//			break
//		endif
//		if (StringMatch(s[1], "1"))		// right button clicked => Stop 
//			StartPosClickVar =0	
//			break
//		endif
//		
//	while (1)	
//	Print "Mouse was clicked"
//While (1)
End

//Function PrintMouseClickPosition(coordSystem)
Function pt_MouseXYLocInPixel(coordSystem)
// from get input state help
	Variable coordSystem		// 0 = local, 1 = global

	// First wait for click.
	String s
	do
		s = MouseState("")
		if (cmpstr(s[0], "1") == 0)
			break
		endif
	while(1)	

	// Now get and print mouse position.
	Variable/C mousePos
	Variable hPos, vPos
	String optionsStr
	if (coordSystem == 0)
		optionsStr = "coords=local"
	else
		optionsStr = "coords=global"
	endif
	mousePos = MousePosition(optionsStr)
	hPos = real(mousePos)
	vPos = imag(mousePos)
//	Printf "Horiz position: %d, vert position: %d\r", hPos, vPos
	pt_MouseXYLoc(hpos, vpos)
End

Function pt_MouseXYLoc(XLocInPixel, YLocInPixel)
// To get the XY coordinates of the mouse click position on a graph
// logic
// get mouse x, y mouse click position using PrintMouseClickPosition(coordSystem) from get input state help
// use logic from "print ROI coordinates in 2D image plots using the Marquee tool as input device" posted by 
// harneit to http://www.igorexchange.com/node/1217

Variable XLocInPixel, YLocInPixel
String s1, s2

String OldDf = GetDataFolder(1)
SetDataFolder root:MouseXYLocVars

GetWindow kwTopWin, psizeDC
Variable ppL = V_left, ppR = V_right, ppT = V_top, ppB = V_bottom
// 3. get the axis limits
// get limits of axes that image is displayed against
	String TopGraphImages = ImageNameList("",";")
	String theImage = StringFromList(0, TopGraphImages)
	Wave w = $theImage
	String XAxis = StringByKey( "XAXIS", ImageInfo("", theImage, 0) )
	String YAxis = StringByKey( "YAXIS", ImageInfo("", theImage, 0) )
	String XAxisLimits = StringFromList(2, StringByKey( "SETAXISCMD", axisinfo("", XAxis) ), " " )
	If (StringMatch(XAxisLimits,  ""))
		
		s1 = Num2Str(DimOffset(w,0))
		s2 = Num2Str(DimOffset(w,0)+DimDelta(w,0)*(DimSize(w,0)-1))
		
		XAxisLimits = s1+","+s2
	EndIf
	String YAxisLimits = StringFromList(2, StringByKey( "SETAXISCMD", axisinfo("", YAxis) ), " " )
	If (StringMatch(YAxisLimits,  ""))
		
		s1 = Num2Str(DimOffset(w,1))
		s2 = Num2Str(DimOffset(w,1)+DimDelta(w,1)*(DimSize(w,1)-1))
		YAxisLimits = s1+","+s2
	EndIf
// order left/right correctly, remember whether a swap occurred
	Variable axMin = str2num( StringFromList(0, XAxisLimits, ",") ), axMax = str2num( StringFromList(1, XAxisLimits, ",") )
	Variable paL = min(axMin, axMax), paR = max(axMin, axMax), xSwap = (paL != axMin)
// order top/bottom correctly, remember whether a swap occurred
	axMin = str2num( StringFromList(0, YAxisLimits, ",") ); axMax = str2num( StringFromList(1, YAxisLimits, ",") )
	Variable paT = max(axMin, axMax), paB = min(axMin, axMax), ySwap = (paB != axMin)
//	print "plot area in axis units (left, top, right, bottom) =", paL, paT, paR, paB; print xSwap, ySwap

// 4. express the marquee coordinates in axis units
// x=x_Min + (xInPoints-GraphXInPoints)*(AxisLength)/(GraphLengthInPoints)
//	Variable maL = paL + (mpL - ppL) * (paR - paL)/(ppR - ppL), maR = paL + (mpR - ppL) * (paR - paL)/(ppR - ppL), swap
//	if( xSwap )
//		swap = maL; maL = maR; maR = swap
//	endif
//	Variable maT = paT + (mpT - ppT) * (paB - paT)/(ppB - ppT), maB = paT + (mpB - ppT) * (paB - paT)/(ppB - ppT)
//	if( ySwap )
//		swap = maT; maT = maB; maB = swap
//	endif
//	print "marquee in axis units (left, top, right, bottom) =", maL, maT, maR, maB

	Variable	XLoc =  paL +(XLocInPixel-ppL)*(paR-paL)/(ppR-ppL)

	Variable YLoc =  paB +(YLocInPixel-ppT)*(paT-paB)/(ppB-ppT)


Print XLoc, YLoc
NVAR CurrentXLoc = $"root:MouseXYLocVars:CurrentXLoc"
NVAR CurrentYLoc = $"root:MouseXYLocVars:CurrentYLoc"
CurrentXLoc = XLoc
CurrentYLoc = YLoc

Wave XLocW = root:MouseXYLocVars:XLocW
Wave YLocW = root:MouseXYLocVars:YLocW
If (FindListItem("YLocW", TraceNameList("", ";", 1), ";")==-1)
AppendToGraph /l/t YLocW vs XLocW
ModifyGraph mode=3,marker=19,rgb=(65280,0,52224)
EndIf
InsertPoints NumPnts(XLocW), 1, XLocW
XLocW[NumPnts(XLocW)-1]= XLoc
InsertPoints NumPnts(YLocW), 1, YLocW
YLocW[NumPnts(YLocW)-1]= YLoc

NVAR StimOnClick = root:MouseXYLocVars:StimOnClick

If (StimOnClick)
	pt_MouseXYLocStimOnClick()
EndIf

SetDataFolder OldDf
End



Function pt_ScaleAxisPolarity(ButtonVarName) : ButtonControl
// This function is no longer in use
String ButtonVarName
Variable N, S, Del, E

String OldDf = GetDataFolder(1)
SetDataFolder root:MouseXYLocVars

// Remove file extension
String TopGraphImages = ImageNameList("",";")
String theImage = StringFromList(0, TopGraphImages)
String XAxis = StringByKey( "XAXIS", ImageInfo("", theImage, 0) )
String YAxis = StringByKey( "YAXIS", ImageInfo("", theImage, 0) )
Wave w = $(theImage)
StrSwitch (ButtonVarName)
case "Button1" :
//NVAR XAxisReversed = root:MouseXYLocVars:XAxisReversed
S=DimOffset(w, 0)
Del=DimDelta(w, 0)
E=S+Del*((DimSize(w,0))-1)
SetScale /P x,E, -Del, w
SetAxis $XAxis E,S
//If (XAxisReversed==0)		// toggle axis
//SetAxis /A/R $XAxis
//XAxisReversed =1
//Else
//SetAxis /A $XAxis
//XAxisReversed =0
//EndIf

break


case "Button2" :
//NVAR YAxisReversed = root:MouseXYLocVars:YAxisReversed
S=DimOffset(w, 1)
Del=DimDelta(w, 1)
E=S+Del*((DimSize(w,1))-1)
SetScale /P y,E, -Del, w
SetAxis $YAxis S,E
//If (YAxisReversed==0)		// toggle axis
//SetAxis /A/R $YAxis
//YAxisReversed =1
//Else
//SetAxis /A $YAxis
//YAxisReversed =0
//EndIf

break
EndSwitch
SetDataFolder OldDf
End
//Function pt_ScaleOffset(SetVarCntrlName, SetVarNum, SetVarStr, SetVarName) : SetVariableControl
// Use this function when coordinates of new origin are specified
//String SetVarCntrlName
//Variable SetVarNum
//String SetVarStr, SetVarName
//Variable N, S, Del, E
// Remove file extension
//String TopGraphImages = ImageNameList("",";")
//String theImage = StringFromList(0, TopGraphImages)
//Wave w = $(theImage)
//StrSwitch (SetVarCntrlName)
//case "SetVar0" :
//S=DimOffset(w, 0)
//Del=DimDelta(w, 0)
//E=S+Del*((DimSize(w,0))-1)
//SetScale /P x,E, -Del, w
//SetScale /P x,S+0.5*(E-S), Del, w
//SetScale /P x,S-SetVarNum, Del, w
//break
//case "SetVar1" :
//S=DimOffset(w, 1)
//Del=DimDelta(w, 1)
//E=S+Del*((DimSize(w,1))-1)
//SetScale /P y,E, -Del, w
//SetScale /P y,S-SetVarNum, Del, w
//break
//EndSwitch

//End

Function pt_ScaleOffset(PopupMenuVarName,PopupMenuVarNum,PopupMenuVarStr) : PopupMenuControl
String PopupMenuVarName, PopupMenuVarStr
Variable PopupMenuVarNum

Variable Sx, Delx, Ex, XScalingReversed, XAxisReversed, SxNew, ExNew
Variable Sy, Dely, Ey, YScalingReversed, YAxisReversed, SyNew, EyNew
Variable Tmp


String OldDf = GetDataFolder(1)
SetDataFolder root:MouseXYLocVars

// Remove file extension

// Axis can be plotted in reverse either by using SetAxis/R or by changing SetAxis a,b to SetAxis b, a
// We need to know if the axis are plotted in reverse

//DoWindow pt_MouseXYLocDisplay
//If (V_Flag==0)	
//	DoWindow /C pt_MouseXYLocDisplay
//EndIf
String TopGraphImages = ImageNameList("",";")
String theImage = StringFromList(0, TopGraphImages)
Wave w = $theImage
String XAxis = StringByKey( "XAXIS", ImageInfo("", theImage, 0) )
String YAxis = StringByKey( "YAXIS", ImageInfo("", theImage, 0) )
//Print StringByKey( "SETAXISCMD", axisinfo("", XAxis) )
If (StringMatch(StringByKey( "SETAXISCMD", axisinfo("", XAxis) ), "*/R*"))
XAxisReversed =1							// plotting axis is reversed
EndIf
If (StringMatch(StringByKey( "SETAXISCMD", axisinfo("", YAxis) ), "*/R*"))
YAxisReversed =1							// plotting axis is reversed
EndIf


String XAxisLimits = StringFromList(2, StringByKey( "SETAXISCMD", axisinfo("", XAxis) ), " " )
String YAxisLimits = StringFromList(2, StringByKey( "SETAXISCMD", axisinfo("", YAxis) ), " " )

If (StringMatch(XAxisLimits, "")==0)

// order left/right correctly, remember whether a swap occurred
	Variable axMin = str2num( StringFromList(0, XAxisLimits, ",") ), axMax = str2num( StringFromList(1, XAxisLimits, ",") )
	Variable paL = min(axMin, axMax), paR = max(axMin, axMax)
	
	XAxisReversed = (paL < paR) ? 0 : 1		// reverse scaling
EndIf	
If (StringMatch(YAxisLimits, "")==0)	
// order top/bottom correctly, remember whether a swap occurred
	axMin = str2num( StringFromList(0, YAxisLimits, ",") ); axMax = str2num( StringFromList(1, YAxisLimits, ",") )
	Variable paT = max(axMin, axMax), paB = min(axMin, axMax)
	YAxisReversed = (paT < paB) ? 0 : 1		// reverse scaling
EndIf	

Sx=DimOffset(w, 0)
Delx=DimDelta(w, 0)
Ex=Sx+Delx*((DimSize(w,0))-1)
XScalingReversed = (Sx<Ex) ? XScalingReversed : 1-XScalingReversed			// reverse scaling

Sy=DimOffset(w, 1)
Dely=DimDelta(w, 1)
Ey=Sy+Dely*((DimSize(w,1))-1)
YScalingReversed = (Sy<Ey) ? YScalingReversed : 1-YScalingReversed		// reverse scaling

//Print Sx+0.5*(Ex-Sx), Sy+0.5*(Ey-Sy)

// to transform the origin we need the coordinates of new origin in the old coordinates
// for transforming origin to center the coordinates of the origin are 
// offset - (distance between center and current origin)
// offset - (offset+0.5*(End-Offset))
//current x-axis start + 0.5*(End-Offset)

//If (XAxisReversed)
//	Tmp=Sx
//	Sx = Ex
//	Ex=Tmp
//EndIf

//If (YAxisReversed)
//	Tmp=Sy
//	Sy = Ey
//	Ey=Tmp
//EndIf

//Abort


StrSwitch (PopupMenuVarStr)
	Case "LT":
	
	Break

	Case "LB":

	Break 
	
	Case "C":
	If (XScalingReversed)
// example
// Sx = 500; Ex = 100; Delx = -1
// SxNew = 500-(500-200) = 200
// ExNew = 200-Range = -200		
	SxNew = Sx-(Sx+ 0.5*(Ex-Sx))
	ExNew = SxNew+Delx*((DimSize(w,0))-1)
	SetScale /P x,SxNew, Delx, w
	Else
// example
// Sx = 100; Ex = 500; Delx = 1
// SxNew = 100-(100+200) = -200
// ExNew = -200+Range = 200	
	SxNew = Sx-(Sx+ 0.5*(Ex-Sx))
	ExNew = SxNew+Delx*((DimSize(w,0))-1)
	SetScale /P x,SxNew, Delx, w
	EndIf
	
	If (XAxisReversed)
		SetAxis $XAxis ExNew, SxNew
	Else 
		SetAxis $XAxis SxNew, ExNew
	EndIf	 
	
	
	If (YScalingReversed)
	SyNew = Sy-(Sy+ 0.5*(Ey-Sy))
	EyNew = SyNew+Dely*((DimSize(w,1))-1)
	SetScale /P y,SyNew, Dely, w
	Else
	SyNew = Sy-(Sy+ 0.5*(Ey-Sy))
	EyNew = SyNew+Dely*((DimSize(w,1))-1)
	SetScale /P y,SyNew, Dely, w
	EndIf
	
	If (YAxisReversed)
		SetAxis $YAxis EyNew, SyNew
	Else 
		SetAxis $YAxis SyNew, EyNew
	EndIf	
	
	Break 

	Case "RT":

	Break 

	Case "RB":

	Break 

EndSwitch

SetDataFolder OldDf
End

Function pt_MouseXYLocStimOnClickParEdit(CheckBoxVarName, CheckBoxVarVal)  : CheckBoxControl
String CheckBoxVarName
Variable CheckBoxVarVal

If (CheckBoxVarVal)
String OldDf = GetDataFolder(1)
SetDataFolder root:MouseXYLocVars

DoWindow StimOnClickParEdit
If (V_Flag)
DoWindow /K StimOnClickParEdit
EndIf
Edit /K=1
DoWindow /C StimOnClickParEdit
If (WaveExists(StimOnClickParNamesW) && WaveExists(StimOnClickParW))
AppendToTable /W=StimOnClickParEdit  StimOnClickParNamesW, StimOnClickParW
Else
Make /T /O/N=6 StimOnClickParNamesW, StimOnClickParW
Wave /T StimOnClickParNamesW = root:MouseXYLocVars:StimOnClickParNamesW
// Ultimately the program should figure out how many channels are there for EPhys, ScanMirrors, etc.
StimOnClickParNamesW[0]	= "StimLength(s)"
StimOnClickParNamesW[1]	= "StimDeltaX(s)"
StimOnClickParNamesW[2]	= "LaserShutterStepStart(s)"
StimOnClickParNamesW[3]	= "LaserShutterStepFreq(Hz)"
StimOnClickParNamesW[4]	= "LaserShutterNumSteps"
StimOnClickParNamesW[5]	= "LaserShutterStepWidth"
AppendToTable /W=StimOnClickParEdit  StimOnClickParNamesW, StimOnClickParW
EndIf
SetDataFolder OldDF
EndIf
End

Function pt_MouseXYLocStimOnClick()

String OldDf = GetDataFolder(1)
Variable i,j, N, M

SetDataFolder root:MouseXYLocVars
// this function will use the x-y coordinates of the mouse to make waves for scan mirror, shutter, laser voltage,
// EPhysChannels so that when the user clicks on a position on the image triggen will scan once. 
// now the interface for all the variables needed is there with the respective panels. So that either the user can 
// asked to change variables from the separate interface or we can provide a new interface where
// all the variables are in one place. for the time being this function will just make the waves required for
// ScanMirrors, Shutter, EPhys, update them in OutWaveNamesW, InWaveNamesW and run trig gen once. 
// The other settings like which channels to scan, what gains etc. will be manually set by user for each channel.

// Get Names of channels to be scanned from root:TrigGenVars:IODevFldr
// Make Wave for the shutter
// LaserVoltage can be fixed and need not be scanned
// Make Waves for the Scan Mirrors
// Make Waves for EPhysChannels
// Save old OutWaveNames
// Copy WaveNames to OutWaveNames
// Initiate TrigGen
// Restore OutWaveNames

NVAR CurrentXLoc = root:MouseXYLocVars:CurrentXLoc
NVAR CurrentYLoc = root:MouseXYLocVars:CurrentYLoc

Wave /T IODevFldr = root:TrigGenVars:IODevFldr
Make /T/O/N=0 ScanMirrorChW, LaserShutterChW, EPhysChW
Make /T/O/N=1 ChWTmp


N = NumPnts(IODevFldr)
For (i=0; i<N; i+=1)
	Print IODevFldr[i]
	If (StringMatch(IODevFldr[i], "root:ScanMirrorVars*"))
	ChWTmp[0] = IODevFldr[i]		
	Concatenate /T/NP {ChWTmp}, ScanMirrorChW
	EndIf
	
	If (StringMatch(IODevFldr[i], "root:LaserShutterVars*"))
	ChWTmp[0] = IODevFldr[i]		
	Concatenate /T/NP {ChWTmp}, LaserShutterChW
	EndIf
	
	If (StringMatch(IODevFldr[i], "root:EPhysVars*"))
	ChWTmp[0] = IODevFldr[i]		
	Concatenate /T/NP {ChWTmp}, EPhysChW
	EndIf
EndFor

M = NumPnts(ScanMirrorChW)				// at the minimum one scan mirrors channel should be selected in TrigGen
If (M>0)
//StimOnClickParNamesW[0]	= "StimLength(s)"
//StimOnClickParNamesW[1]	= "StimDeltaX(s)"
//StimOnClickParNamesW[2]	= "LaserShutterStepStart(s)"
//StimOnClickParNamesW[3]	= "LaserShutterStepFreq(Hz)"
//StimOnClickParNamesW[4]	= "LaserShutterNumSteps"
//StimOnClickParNamesW[5]	= "LaserShutterStepWidth"
	
	
		Wave  /T StimOnClickParW	= root:MouseXYLocVars:StimOnClickParW
		SVAR OutWNameStrPrefix	= root:WaveGenVars:OutWNameStrPrefix
		SVAR StimFolder 			= root:WaveGenVars:StimFolder
//		SVAR OutWNameStrSuffix	= root:WaveGenVars:OutWNameStrSuffix
		SVAR StimProtocol 			= root:WaveGenVars:StimProtocol
		NVAR DCValue 				= root:WaveGenVars:DCValue
		NVAR YGain					= root:WaveGenVars:YGain
		NVAR XOffset 				= root:WaveGenVars:XOffset
		NVAR XDelta					= root:WaveGenVars:XDelta
		NVAR XLength				= root:WaveGenVars:XLength
		//NVAR NSegments			= root:WaveGenVars:NSegments
		NVAR DisplayOutW			= root:WaveGenVars:DisplayOutW

	OutWNameStrPrefix   = "StimOnClickW"
//	OutWNameStrSuffix   = ""
	StimProtocol 		= "NStepsAtFixedFreq"
	DCValue				= 0
	YGain				= 1
	XOffset 				= 0
	XLength				= Str2Num(StimOnClickParW[0])
	XDelta				= Str2Num(StimOnClickParW[1])
	DisplayOutW			= 0
	
	Print StimOnClickParW
	NVAR StartX0		= root:WaveGenVars:NStepsAtFixedFreq:StartX0
	NVAR Freq			= root:WaveGenVars:NStepsAtFixedFreq:Freq
	NVAR NSegments 	= root:WaveGenVars:NStepsAtFixedFreq:NSegments
	NVAR Amp 			= root:WaveGenVars:NStepsAtFixedFreq:Amp
	NVAR Width 		= root:WaveGenVars:NStepsAtFixedFreq:Width
	
	
	StartX0		= Str2Num(StimOnClickParW[2])
	Freq 		= Str2Num(StimOnClickParW[3])
	NSegments 	= Str2Num(StimOnClickParW[4])
	Amp 		= 1	// Shutter amplitude is one or zero
	Width		= Str2Num(StimOnClickParW[5])
	
	
	
	
	For (j=0; j<M; j+=1)
	
	OutWNameStrPrefix   = "StimOnClickXW"
	Amp = CurrentXLoc
	StartX0 = 0
	Width = XLength
	NSegments = 1
	StimFolder = ScanMirrorChW[j]
	
//	pt_WaveGenEdit("")
//	DoWindow WaveGenParEdit
//	If (V_Flag)
//		DoWindow /K WaveGenParEdit
//	EndIf
	pt_WaveGenCreate("")
//	Duplicate /O StimOnClickXW, $(ScanMirrorChW[j]+":"+"StimOnClickXW")
//	Wave /T OutXWaveNamesW = $(ScanMirrorChW[j]+":"+"OutXWaveNamesW")
	Duplicate /O/T $(ScanMirrorChW[j]+":"+"OutXWaveNamesW"), $(ScanMirrorChW[j]+":"+"OldOutXWaveNamesW")
	Make /O/T/N=1 $(ScanMirrorChW[j]+":"+"OutXWaveNamesW")
	Wave /T OutXWaveNamesW = $(ScanMirrorChW[j]+":"+"OutXWaveNamesW")
	OutXWaveNamesW[0] = "StimOnClickXW"
	
	
	OutWNameStrPrefix   = "StimOnClickYW"
	Amp = CurrentYLoc
//	StartX0 = 0
//	Width = XLength
//	NSegments = 1
	
//	pt_WaveGenEdit("")
//	DoWindow WaveGenParEdit
//	If (V_Flag)
//		DoWindow /K WaveGenParEdit
//	EndIf
	pt_WaveGenCreate("")
//	Duplicate /O StimOnClickYW, $(ScanMirrorChW[j]+":"+"StimOnClickYW")
//	Wave /T OutYWaveNamesW = $(ScanMirrorChW[j]+":"+"OutYWaveNamesW")
	Duplicate /O/T $(ScanMirrorChW[j]+":"+"OutYWaveNamesW"), $(ScanMirrorChW[j]+":"+"OldOutYWaveNamesW")
	Make /O/T/N=1 $(ScanMirrorChW[j]+":"+"OutYWaveNamesW")
	Wave /T OutYWaveNamesW = $(ScanMirrorChW[j]+":"+"OutYWaveNamesW")
	OutYWaveNamesW[0] = "StimOnClickYW"
	
	EndFor 
	
	M = NumPnts(LaserShutterChW)				
	If (M>0)							// Laser Shutter channel is selected
	
	OutWNameStrPrefix   = "StimOnClickW"
	StartX0		= Str2Num(StimOnClickParW[2])
	Freq 		= Str2Num(StimOnClickParW[3])
	NSegments 	= Str2Num(StimOnClickParW[4])
	Amp 		= 1	// Shutter amplitude is one or zero
	Width		= Str2Num(StimOnClickParW[5])
	StimFolder = LaserShutterChW[j]
//	pt_WaveGenEdit("")
//	DoWindow WaveGenParEdit
//	If (V_Flag)
//		DoWindow /K WaveGenParEdit
//	EndIf
	pt_WaveGenCreate("")

	For (j=0; j<M; j+=1)
//	Duplicate /O StimOnClickW, $(LaserShutterChW[j]+":"+"StimOnClickW")
//	Wave /T OutWaveNamesW = $(LaserShutterChW[j]+":"+"OutWaveNamesW")
	Duplicate /O/T $(LaserShutterChW[j]+":"+"OutWaveNamesW"), $(LaserShutterChW[j]+":"+"OldOutWaveNamesW")
	Make /O/T/N=1 $(LaserShutterChW[j]+":"+"OutWaveNamesW")
	Wave /T OutWaveNamesW = $(LaserShutterChW[j]+":"+"OutWaveNamesW")
	OutWaveNamesW[0] = "StimOnClickW"
	EndFor 
	EndIf							// Laser Shutter channel 
	
	M = NumPnts(EPhysChW)				
	If (M>0)							// EPhys channel is selected
	
	OutWNameStrPrefix   = "StimOnClickW"
	Amp = 0
	StartX0 = 0
	Width = XLength
	NSegments = 1
	
//	pt_WaveGenEdit("")
//	DoWindow WaveGenParEdit
//	If (V_Flag)
//		DoWindow /K WaveGenParEdit
//	EndIf
	StimFolder = EPhysChW[j]
	pt_WaveGenCreate("")
	
	
	For (j=0; j<M; j+=1)
//	Duplicate /O StimOnClickW, $(EPhysChW[j]+":"+"StimOnClickW")
//	Wave /T InWaveNamesW = $(EPhysChW[j]+":"+"InWaveNamesW")
	Duplicate /O/T $(EPhysChW[j]+":"+"InWaveNamesW"), $(EPhysChW[j]+":"+"OldInWaveNamesW")
	Make /O/T/N=1 $(EPhysChW[j]+":"+"InWaveNamesW")
	Wave /T InWaveNamesW = $(EPhysChW[j]+":"+"InWaveNamesW")
	InWaveNamesW[0] = "StimOnClickW"
	EndFor 
	EndIf							// EPhys channel 
	
	NVAR IterTot 		= root:TrigGenVars:IterTot
	IterTot =1
	Button button5, disable=0, win=MouseXYLocMain	// Enable Reset Add Button
	Button button0, disable=2, win=MouseXYLocMain	// Disable Add button
	pt_TrigGenStart ("Button0")								// Call TrigGen
	Button button0, disable=0, win=MouseXYLocMain	// Enable Add Button
	Button button5, disable=2, win=MouseXYLocMain	// Disable Reset Add Button
	
	// Restore the OutWaveNamesW and InWaveNamesW
	M = NumPnts(ScanMirrorChW)				// at the minimum one scan mirrors channel should be selected in TrigGen
	If (M>0)
	For (j=0; j<M; j+=1)
		Duplicate /O/T 	$(ScanMirrorChW[j]+":"+"OldOutXWaveNamesW"), $(ScanMirrorChW[j]+":"+"OutXWaveNamesW")
		Duplicate /O/T 	$(ScanMirrorChW[j]+":"+"OldOutYWaveNamesW"), $(ScanMirrorChW[j]+":"+"OutYWaveNamesW")
		KillWaves /Z 		$(ScanMirrorChW[j]+":"+"OldOutXWaveNamesW"), $(ScanMirrorChW[j]+":"+"OldOutYWaveNamesW")
	EndFor
	EndIf
	
	M = NumPnts(LaserShutterChW)			// Laser Shutter channel is selected
	If (M>0)
	For (j=0; j<M; j+=1)
		Duplicate /O/T 	$(LaserShutterChW[j]+":"+"OldOutWaveNamesW"), $(LaserShutterChW[j]+":"+"OutWaveNamesW")
		KillWaves /Z 		$(LaserShutterChW[j]+":"+"OldOutWaveNamesW")
	EndFor
	EndIf	
	
	M = NumPnts(EPhysChW)		// EPhys channel is selected
	If (M>0)
	For (j=0; j<M; j+=1)
		Duplicate /O/T 	$(EPhysChW[j]+":"+"OldInWaveNamesW"), $(EPhysChW[j]+":"+"InWaveNamesW")
		KillWaves /Z 		$(EPhysChW[j]+":"+"OldInWaveNamesW")
	EndFor
	EndIf	

	
Else
	Print "Warning!!! At the minimum ScanMirror channel should be selected in TrigGen!!"
EndIf
SetDataFolder OldDF
End


Structure pt_EPhysExptStruc		// To store Expt. Details
//Variable xx
String DateS
String TimeS
String AnimIDS
String AnimAgeS
String AnimGenderS
String AnimGentyp
String AnimPhentyp
String ExperimenterNameS
String ExpNameS
String SlicingACSFS
String IncubatingACSFS
String RecordingACSFS
String InternalSolnS
String RecordingTempS
String DrugPerfusedS
EndStructure

Function pt_TestStruct()
Struct pt_EPhysExptStruc pt_EPhysExptStruc1
 
pt_EPhysExptStruc1.DateS=Date()
pt_EPhysExptStruc1.TimeS=Time()
pt_EPhysExptStruc1.AnimIDS=""
pt_EPhysExptStruc1.AnimAgeS=""
pt_EPhysExptStruc1.AnimGenderS=""
pt_EPhysExptStruc1.AnimGentyp=""
pt_EPhysExptStruc1.AnimPhentyp=""
pt_EPhysExptStruc1.ExperimenterNameS="Praveen"
pt_EPhysExptStruc1.ExpNameS=""
pt_EPhysExptStruc1.SlicingACSFS=""
pt_EPhysExptStruc1.IncubatingACSFS=""
pt_EPhysExptStruc1.RecordingACSFS=""
pt_EPhysExptStruc1.InternalSolnS=""
pt_EPhysExptStruc1.RecordingTempS=""
pt_EPhysExptStruc1.DrugPerfusedS=""

Print pt_EPhysExptStruc1.DateS
Print pt_EPhysExptStruc1.TimeS
Print pt_EPhysExptStruc1.AnimIDS
Print pt_EPhysExptStruc1.AnimAgeS
Print pt_EPhysExptStruc1.AnimGenderS
Print pt_EPhysExptStruc1.AnimGentyp
Print pt_EPhysExptStruc1.AnimPhentyp
Print pt_EPhysExptStruc1.ExperimenterNameS
Print pt_EPhysExptStruc1.ExpNameS
Print pt_EPhysExptStruc1.SlicingACSFS
Print pt_EPhysExptStruc1.IncubatingACSFS
Print pt_EPhysExptStruc1.RecordingACSFS
Print pt_EPhysExptStruc1.InternalSolnS
Print pt_EPhysExptStruc1.RecordingTempS
Print pt_EPhysExptStruc1.DrugPerfusedS

//Struct pt_EPhysWStruc pt_EPhysWStruc1
//pt_EPhysWStruc1.DateS=Date()
//pt_EPhysWStruc1.TimeS=Time()
//pt_EPhysWStruc1.ProtocolS="FI"

//Print pt_EPhysWStruc1.DateS
//Print pt_EPhysWStruc1.TimeS
//Make /O/N=10 InWave
//InWave = p
//Wave pt_EPhysWStruc1.InWave
//Display  pt_EPhysWStruc1.InWave
End


Function pt_TrigGenConfig1()
// Here we define what is saved for each kind of channel

End

// Structures are available only during the existance of a function and cannot be copied as waves and variables
// into data folders. They must be converted back to waves and variables to save. On the hard disk they can be
// stored as structures but Structure doesn't allow the arraysize to be > 400 (which we might easily have) and FBinWrite
// has some problem writing structures with waves as members to diskStructure pt_EPhysConfig

//Variable EPhys_VClmp
//Variable EPhysOutGain
//Variable EPhysInGain
//Variable EPhysOutWaveSlctVar
//Variable EPhysInWaveSlctVar
//Variable EPhysRndOutWVar
// Structure doesn't allow the arraysize to be > 400 (which we might easily have) and FBinWrite
// has some problem writing structures with waves as members to disk. Thus storing the waves
// separately from structures.
//Wave /T	OutWaveNamesW
//Wave /T	InWaveNamesW
//EndStructure

Structure pt_TrigGenConfig
Variable ISI
Variable IterTotal
Variable StopExpt
Variable PauseExpt
// Structure doesn't allow the arraysize to be > 400 (which we might easily have) and FBinWrite
// has some problem writing structures with waves as members to disk. Thus storing the waves
// separately from structures.
//Wave 	IODevFldr
EndStructure

Function pt_TrigGenSaveConfig()
// Save a configuration. Will allow user to quickly change between different configurations
// What to save.
// TrigGen - Channels to scan; ISI; IterTot; Reps Total, Stim Pattern for scanned channels; 
// EPhys - VClamp/IClamp; OutGain; InGain; OutWave CheckBox; InWave CheckBox; Rnd CheckBox; 
// OutWaveNames, InWaveNames, OutWaves and InWaves listed in OutWaveNames, InWaveNames
// ScanMirror - XDist2VoltageGain, YDist2VoltageGain, XOffset, YOffset, OutXWaveNamesW, 
// OutYWaveNamesW, OutXWaves and OutYWaves listed in OutXWaveNamesW, OutYWaveNamesW
// LaserShutter - OutWaveNames and OutWaves
// Temperature - TemperatureVGain, InWaveNames and InWaves
//  LaserPower - LaserPowerVGain, InWaveNames and InWaves
// Save & Load configs from HardDisk. 
// Data to save are variables, strings, and waves. Essentially everything can be stored as waves. 
String FldrName, TrigGenConfigFolder, DFName, CurrDFName, OldDF
Variable i, N, InstNum, FRefNum, NWaveNames, j
Wave /T IODevFldr =root:TrigGenVars:IODevFldr


PathInfo home
If (V_Flag==0)
	Abort "Please save the experiment first!"
EndIf
NewPath /O DiskDFName,  S_Path
Prompt TrigGenConfigFolder, "Enter configuration folder name "
DoPrompt "Save configuration", TrigGenConfigFolder
Print TrigGenConfigFolder
//DFName = "root:TrigGenVars:"+TrigGenConfigFolder
If (DataFolderExists("root:TrigGenVars:"+TrigGenConfigFolder))
	KillDataFolder $("root:TrigGenVars:"+TrigGenConfigFolder)
	Print "Deleted previous configuration in root:TrigGenVars:", TrigGenConfigFolder, "folder"
EndIf
NewDataFolder /O $"root:TrigGenVars:"+TrigGenConfigFolder

N = NumPnts(IODevFldr)

// Save config for TrigGenVars
//TrigGen - Channels to scan; ISI; IterTot; Stim Pattern for scanned channels; 
If (N>0)		
//	If (StrSearch(FldrName,"TrigGen",0)!=-1)
//	SScanf FldrName, "root:TrigGenVars%d",InstNum
	
	FldrName = "root:TrigGenVars"
	Print "Saving configuration for root:TrigGenVars"
	
	NVAR ISI			=$FldrName+":ISI"
	NVAR IterTot			=$FldrName+":IterTot"
	NVAR RepsTot		=$FldrName+":RepsTot"
	
	CurrDFName = "root:TrigGenVars:"+TrigGenConfigFolder+":TrigGenVars"//+Num2Str(InstNum)
	Print CurrDFName
	NewDataFolder /O $CurrDFName
	Variable /G $(CurrDFName+":ISI")			= ISI
	Variable /G $(CurrDFName+":IterTot")		= IterTot
	Variable /G $(CurrDFName+":RepsTot")		= RepsTot
	Duplicate /O $(FldrName+":IODevFldr"),		$(CurrDFName+":IODevFldr")
EndIf

For (i=0; i<N; i+=1)
	FldrName = IODevFldr[i]
	
//=========================================================//
// EPhys - VClamp/IClamp; OutGain; InGain; OutWave CheckBox; InWave CheckBox; Rnd CheckBox; 
// OutWaveNames, InWaveNames, OutWaves and InWaves listed in OutWaveNames, InWaveNames
	
	If (StrSearch(FldrName,"EPhys",0)!=-1)
	Print "Saving configuration for", IODevFldr[i]
	SScanf FldrName, "root:EPhysVars%d",InstNum

	NVAR EPhys_VClmp			=$FldrName+":EPhys_VClmp"
	NVAR EPhys_IClmp			=$FldrName+":EPhys_IClmp"
	NVAR EPhysOutGain			=$FldrName+":EPhysOutGain"
	NVAR EPhysInGain			=$FldrName+":EPhysInGain"
	NVAR EPhysOutWaveSlctVar	=$FldrName+":EPhysOutWaveSlctVar"
	NVAR EPhysInWaveSlctVar	=$FldrName+":EPhysInWaveSlctVar"
	NVAR EPhysRndOutWVar	=$FldrName+":EPhysRndOutWVar"

	CurrDFName = "root:TrigGenVars:"+TrigGenConfigFolder+":EPhysVars"+Num2Str(InstNum)
	Print CurrDFName
	NewDataFolder /O $CurrDFName
	
	Variable /G $(CurrDFName+":EPhys_VClmp")			= EPhys_VClmp
	Variable /G $(CurrDFName+":EPhys_IClmp")			= EPhys_IClmp
	Variable /G $(CurrDFName+":EPhysOutGain")			= EPhysOutGain
	Variable /G $(CurrDFName+":EPhysInGain")				= EPhysInGain
	Variable /G $(CurrDFName+":EPhysOutWaveSlctVar")	= EPhysOutWaveSlctVar
	Variable /G $(CurrDFName+":EPhysInWaveSlctVar")		= EPhysInWaveSlctVar	
	Variable /G $(CurrDFName+":EPhysRndOutWVar")		= EPhysRndOutWVar
	Duplicate /O $(FldrName+":OutWaveNamesW"),			$(CurrDFName+":OutWaveNamesW")
	Duplicate /O $(FldrName+":InWaveNamesW"),			$(CurrDFName+":InWaveNamesW")
	
//	Save the Out and InWaves
	NWaveNames =  NumPnts($(FldrName+":OutWaveNamesW"))
	For (j=0; j<NWaveNames; j+=1)
		Wave /T OutWaveNamesW = $(FldrName+":OutWaveNamesW")
		Duplicate /O $(FldrName+":"+OutWaveNamesW[j]), $(CurrDFName+":"+OutWaveNamesW[j])
		
		Wave /T InWaveNamesW = $(FldrName+":InWaveNamesW")
		Duplicate /O $(FldrName+":"+InWaveNamesW[j]), $(CurrDFName+":"+InWaveNamesW[j])
	EndFor
	EndIf
//=========================================================//
// ScanMirror - XDist2VoltageGain, YDist2VoltageGain, XOffset, YOffset, OutXWaveNamesW, 
// OutYWaveNamesW, OutXWaves and OutYWaves listed in OutXWaveNamesW, OutYWaveNamesW

	If (StrSearch(FldrName,"ScanMirror",0)!=-1)
	Print "Saving configuration for", IODevFldr[i]
	SScanf FldrName, "root:ScanMirrorVars%d",InstNum

	NVAR XDist2VoltageGain			=$FldrName+":XDist2VoltageGain"
	NVAR YDist2VoltageGain			=$FldrName+":YDist2VoltageGain"
	NVAR XOffset					=$FldrName+":XOffset"
	NVAR YOffset					=$FldrName+":YOffset"

	CurrDFName = "root:TrigGenVars:"+TrigGenConfigFolder+":ScanMirrorVars"+Num2Str(InstNum)
	Print CurrDFName
	NewDataFolder /O $CurrDFName
	
	Variable /G $(CurrDFName+":XDist2VoltageGain")			= XDist2VoltageGain
	Variable /G $(CurrDFName+":YDist2VoltageGain")			= YDist2VoltageGain
	Variable /G $(CurrDFName+":XOffset")						= XOffset
	Variable /G $(CurrDFName+":YOffset")						= YOffset
	Duplicate /O $(FldrName+":OutXWaveNamesW"),			$(CurrDFName+":OutXWaveNamesW")
	Duplicate /O $(FldrName+":OutYWaveNamesW"),			$(CurrDFName+":OutYWaveNamesW")
	
//	Save the OutXWaves and OutYWaves
	NWaveNames =  NumPnts($(FldrName+":OutXWaveNamesW"))
	For (j=0; j<NWaveNames; j+=1)
		Wave /T OutXWaveNamesW = $(FldrName+":OutXWaveNamesW")
		Print OutXWaveNamesW[j], CurrDFName+":"+OutXWaveNamesW[j]
		Duplicate /O $(FldrName+":"+OutXWaveNamesW[j]), $(CurrDFName+":"+OutXWaveNamesW[j])
		
		Wave /T OutYWaveNamesW = $(FldrName+":OutYWaveNamesW")
		Duplicate /O $(FldrName+":"+OutYWaveNamesW[j]), $(CurrDFName+":"+OutYWaveNamesW[j])
		
	EndFor
	EndIf	
//=========================================================//
// LaserShutter - OutWaveNames and OutWaves
	If (StrSearch(FldrName,"LaserShutter",0)!=-1)
	Print "Saving configuration for", IODevFldr[i]
	SScanf FldrName, "root:LaserShutterVars%d",InstNum

	CurrDFName = "root:TrigGenVars:"+TrigGenConfigFolder+":LaserShutterVars"+Num2Str(InstNum)
	Print CurrDFName
	NewDataFolder /O $CurrDFName
	
	Duplicate /O $(FldrName+":OutWaveNamesW"),			$(CurrDFName+":OutWaveNamesW")
	
//	Save the OutWaves
	NWaveNames =  NumPnts($(FldrName+":OutWaveNamesW"))
	For (j=0; j<NWaveNames; j+=1)
		Wave /T OutWaveNamesW = $(FldrName+":OutWaveNamesW")
		Duplicate /O $(FldrName+":"+OutWaveNamesW[j]), $(CurrDFName+":"+OutWaveNamesW[j])
	EndFor
	EndIf
//=========================================================//
// Temperature - TemperatureVGain, InWaveNames and InWaves
If (StrSearch(FldrName,"Temperature",0)!=-1)
	Print "Saving configuration for", IODevFldr[i]
	SScanf FldrName, "root:TemperatureVars%d",InstNum

	NVAR TemperatureVGain			=$FldrName+":TemperatureVGain"

	CurrDFName = "root:TrigGenVars:"+TrigGenConfigFolder+":TemperatureVars"+Num2Str(InstNum)
	Print CurrDFName
	NewDataFolder /O $CurrDFName
	
	Variable /G $(CurrDFName+":TemperatureVGain")		= TemperatureVGain
	Duplicate /O $(FldrName+":InWaveNamesW"),			$(CurrDFName+":InWaveNamesW")
	
//	Save the InWaves
	NWaveNames =  NumPnts($(FldrName+":InWaveNamesW"))
	For (j=0; j<NWaveNames; j+=1)
		Wave /T InWaveNamesW = $(FldrName+":InWaveNamesW")
		Duplicate /O $(FldrName+":"+InWaveNamesW[j]), $(CurrDFName+":"+InWaveNamesW[j])
	EndFor
	EndIf
//=========================================================//
// LaserPower - LaserPowerVGain, InWaveNames and InWaves
If (StrSearch(FldrName,"LaserPower",0)!=-1)
	Print "Saving configuration for", IODevFldr[i]
	SScanf FldrName, "root:LaserPowerVars%d",InstNum

	NVAR LaserPowerVGain			=$FldrName+":LaserPowerVGain"

	CurrDFName = "root:TrigGenVars:"+TrigGenConfigFolder+":LaserPowerVars"+Num2Str(InstNum)
	Print CurrDFName
	NewDataFolder /O $CurrDFName
	
	Variable /G $(CurrDFName+":LaserPowerVGain")		= LaserPowerVGain
	Duplicate /O $(FldrName+":InWaveNamesW"),			$(CurrDFName+":InWaveNamesW")
	
//	Save the InWaves
	NWaveNames =  NumPnts($(FldrName+":InWaveNamesW"))
	For (j=0; j<NWaveNames; j+=1)
		Wave /T InWaveNamesW = $(FldrName+":InWaveNamesW")
		Duplicate /O $(FldrName+":"+InWaveNamesW[j]), $(CurrDFName+":"+InWaveNamesW[j])
	EndFor
	EndIf
//=========================================================//	
//	Struct pt_EPhysConfig pt_EPhysConfigL
//	NVAR 			=$FldrName+":"
//	pt_EPhysConfigL.EPhys_VClmp 				= EPhys_VClmp
//	pt_EPhysConfigL.EPhysOutGain				= EPhysOutGain
//	pt_EPhysConfigL.EPhysInGain					= EPhysInGain
//	pt_EPhysConfigL.EPhysOutWaveSlctVar		= EPhysOutWaveSlctVar
//	pt_EPhysConfigL.EPhysInWaveSlctVar			= EPhysInWaveSlctVar
//	pt_EPhysConfigL.EPhysRndOutWVar			= EPhysRndOutWVar
//	Wave /T	pt_EPhysConfigL.OutWaveNamesW	= $(FldrName+":OutWaveNamesW")
//	Wave /T	pt_EPhysConfigL.InWaveNamesW		= $(FldrName+":InWaveNamesW")

	
//	Print pt_EPhysConfigL.EPhys_VClmp
//	Print pt_EPhysConfigL.EPhysOutGain
//	Print pt_EPhysConfigL.EPhysInGain
//	Print pt_EPhysConfigL.EPhysOutWaveSlctVar
//	Print pt_EPhysConfigL.EPhysInWaveSlctVar	
//	Print pt_EPhysConfigL.EPhysRndOutWVar
//	Print pt_EPhysConfigL.OutWaveNamesW
//	Print pt_EPhysConfigL.InWaveNamesW	
//	NVAR EPhys_VClmpS = $(CurrDFName+":EPhys_VClmpS")
//	Open /P=DiskDFName /T=TrigGenConfigFolder FRefNum as ":TrigGenVars:"+"EPhysConfigStuc"
//	FBinWrite FRefNum, pt_EPhysConfigL
//	Close FRefNum
	
EndFor

If (N>0)	// Save Config to Disk
	OldDF = GetDataFolder(1)
	SetDataFolder  $"root:TrigGenVars:"+TrigGenConfigFolder
	SaveData /D/O/R/P=DiskDFName /T=TrigGenConfigFolder 
	SetDataFolder OldDF
EndIf
End


Function pt_TrigLoadConfig()
Variable FRefNum
//	Struct pt_EPhysConfig pt_EPhysConfigL
	PathInfo home
	If (V_Flag==0)
	Abort "Please save the experiment first!"
	EndIf
	NewPath /O DiskDFName,  S_Path
	Open /P=DiskDFName  /R FRefNum as "Config"
//	FBinRead FRefNum, pt_EPhysConfigL
//	Print pt_EPhysConfigL.EPhys_VClmp
//	Print pt_EPhysConfigL.EPhysOutGain
//	Print pt_EPhysConfigL.EPhysInGain
//	Print pt_EPhysConfigL.EPhysOutWaveSlctVar
//	Print pt_EPhysConfigL.EPhysInWaveSlctVar	
//	Print pt_EPhysConfigL.EPhysRndOutWVar
End

//=======================
Function pt_VideoMain() : Panel

// Following is modification from pt_TemperatureMain() and Sensoray.ipf which comes as part of
// Igor Pro Folder\More Extensions\Data Acquisition\Frame Grabbers\Sensoray\Sensoray.pxp
// Mainly, pt_VideoMain() will have a design similar to other channels in ChR2 program but use
// actual functions and logic from Sensoray.ipf

Variable InstNumL							// Local Copy of VideoInstNum
String 	FldrNameL							// Local Copy of Folder Name
String 	PanelNameL							// Local Copy of Panel Name

InstNumL = pt_InstanceNum("root:VideoVars", "VideoMain")
FldrNameL="root:VideoVars"+Num2Str(InstNumL)
PanelNameL = "VideoMain"+Num2Str(InstNumL)

Variable /G root:VideoInstNum			
//String 	/G root:VideoFldrName			// Active folder Name
//String 	/G root:VideoPanelName


NVAR InstNum 		=	root:VideoInstNum
//SVAR FldrName 		=	root:VideoFldrName
//SVAR PanelName		=	root:VideoPanelName

InstNum		= InstNumL
//FldrName 	= FldrNameL				
//PanelName 	= PanelNameL
// Global copy of Folder Name and PanelName for use by other functions. NB. Global copy will change with every new instant creation
// To use variables associated with a particular instant, local values should be used	

NewDataFolder /O $FldrNameL


//Variable /G	 $FldrNameL+":CurrentVideo"
//Make /O/N=2 $FldrNameL+":VideoVWave"
Variable /G 	 $FldrNameL+":CellNum" = 1
Variable /G 	 $FldrNameL+":IterNum" = 1
String	/G 	 $FldrNameL+":InWaveBaseName" = "Video_"

// waves to be sent for multiple iterations to TrigGen. If less than number of iterations, the last wave is repeated
Make /O/T/N=0 $FldrNameL+":InWaveNamesW"		

Variable /G $FldrNameL+":VideoError"	=0
Variable /G $FldrNameL+":SamplingFreq" 		=100 //Sampling Freq in Hz for single scan
Variable /G $FldrNameL+":ReSamplingFreq" 	=10  //ReSampling Freq in Hz. This channel is scanned at much 
												 //higher freq (eg. 10KHz) than needed. 

Variable /G $FldrNameL+":DebugMode" = 0
NVAR        DebugMode = $FldrNameL+":DebugMode"

If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "*************************************"
EndIf

// waves to save
//Make /O/T/N=0 $FldrNameL+":OutWaveToSave"	// saved with the original name
//Make /O/T/N=1 $FldrNameL+":InWaveToSave"		// usually the acquired wave, saved as InWaveBaseName_CellNum_IterNum
//Wave /T InWaveToSave = $FldrNameL+":InWaveToSave"
//InWaveToSave[0] = "VideoVWave"

//SVAR InWaveToSaveAs = $FldrNameL+":InWaveToSaveAs"
//NVAR CellNum = $FldrNameL+":CellNum"
//NVAR IterNum = $FldrNameL+":IterNum"



//Make /T/O/N=4 $FldrNameL+":VideoHWName"
//Make /T/O/N=4 $FldrNameL+":VideoHWVal"

// possible values (can add more parameters)
// Wave /T w = root:VideoVars:VideoHWName
//w[0] = "DevID"
//w[1] = "ChNum"
//w[2] = "VideoVGain (Deg/V)"
//w[3] = "TrigSrc"						// value = "NoTrig" OR TriggerName like "/PFI4"

	PauseUpdate; Silent 1		// building window...
	DoWindow $PanelNameL
	If (V_Flag==1)
		DoWindow /K $PanelNameL
	EndIf
	NewPanel /K=2/W=(900,220,1175,280)
	DoWindow /C $PanelNameL
//	ShowTools/A
//	SetDrawEnv fsize= 14,textrgb= (0,9472,39168)
//	DrawText 100,19,"Video"
	
//	SetVariable setvar0,pos={50,0},size={70,16},title="Inst#",value=InstNum, limits={1,inf,1}
	Button button2,pos={30,10},size={15,15},title="N", proc = pt_VideoNewCell, userdata=Num2Str(InstNumL)
	SetVariable setvar1,pos={50,10},size={80,16},title="Cell#",value=$(FldrNameL+":CellNum" ), limits={1,inf,1}
	SetVariable setvar2,pos={140,10},size={80,16},title = "Iter#",value=$(FldrNameL+":IterNum" ), limits={1,inf,1}
	Button button0,pos={1,35},size={55,20},title="Hardware", proc = pt_VideoHWEdit, userdata=Num2Str(InstNumL)
	Button button1,pos={143,35},size={50,20},title="Snapshot", proc = pt_VideoSnapShot, userdata=Num2Str(InstNumL)
	Button button3,pos={62,35},size={70,20},title="Start Preview", proc = pt_VideoStartPreview, userdata=Num2Str(InstNumL)//, disable =2
//	Button button4,pos={143,35},size={70,20},title="End Preview", proc = pt_VideoEndPreview, userdata=Num2Str(InstNumL)//, disable =2
	Button button4,pos={203,35},size={70,20},title="Make Movie", proc = pt_VidMkMov, userdata=Num2Str(InstNumL)//, disable =2
//	Button button3,proc = pt_VideoResetAcquire, userdata=Num2Str(InstNumL) 
//	ValDisplay valdisp0,pos={94,2},size={100,25},title="Video"
//	String CT = FldrNameL+":CurrentVideo"
//	ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000},value=#CT

End



//=======================
Function pt_VideoHWEdit(ButtonVarName) :  ButtonControl
// Based on pt_TemperatureHWEdit

String ButtonVarName

NVAR VideoInstNum		=root:VideoInstNum
//If (!StringMatch(button0, "TrigGen"))
VideoInstNum				= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
//EndIf
String FldrName 					= "root:VideoVars"+Num2Str(VideoInstNum)
//String VideoPanelName 	= "VideoMain"+Num2Str(VideoInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

If (WaveExists($(FldrName+":VideoHWName")) && WaveExists($(FldrName+":VideoHWVal"))    )
Wave /T VideoHWName =  	$(FldrName+":VideoHWName")
Wave /T VideoHWVal 	= 	$(FldrName+":VideoHWVal")
Edit /K=1 VideoHWName, VideoHWVal
Else
Make /T/O/N=3 $(FldrName+":VideoHWName")
Make /T/O/N=3 $(FldrName+":VideoHWVal")
Wave /T VideoHWName =  	$(FldrName+":VideoHWName")
Wave /T VideoHWVal 	= 	$(FldrName+":VideoHWVal")

VideoHWName[0] = "DevID"
VideoHWName[1] = "ChNum"
VideoHWName[2] = "FramesPerSec"
//VideoHWName[2] = "VideoVGain (Deg/Volt)"
//VideoHWName[3] = "TrigSrc"		// value = "NoTrig" OR TriggerName like "/PFI4"
	
Edit /K=1 VideoHWName, VideoHWVal
EndIf

End


//=======================


Function pt_VideoNewCell(ButtonVarName) : ButtonControl
// Based on pt_TemperatureNewCell
String ButtonVarName

NVAR VideoInstNum		=root:VideoInstNum
//If (!StringMatch(button2, "TrigGen"))
VideoInstNum				= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
//EndIf
String FldrName 					= "root:VideoVars"+Num2Str(VideoInstNum)
//String VideoPanelName 	= "VideoMain"+Num2Str(VideoInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

NVAR CellNum 		= $FldrName+":CellNum"
NVAR IterNum 		= $FldrName+":IterNum"

CellNum +=1		// increase cell # by 1
IterNum    =1		// set Iter # =1

End


//=======================


Function pt_VideoSnapShot(ButtonVarName) :  ButtonControl

// Based on pt_TemperatureAcquire
String ButtonVarName	// will be called using the button or from TrigGen (to run simultaneously with other channels )

NVAR VideoInstNum		=root:VideoInstNum
If (StringMatch(ButtonVarName, "Button1"))
VideoInstNum				= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
EndIf
String FldrName 					= "root:VideoVars"+Num2Str(VideoInstNum)
String VideoPanelName 	= "VideoMain"+Num2Str(VideoInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

Variable DevID 			= Nan
Variable ChNum 			= Nan
Variable FramesPerSec 	= Nan
Variable i

String DevIdStr, InWaveListStr, OldDF, WName
//String TrigSrcStr 				
Wave /T VideoHWName =  	$(FldrName+":VideoHWName")
Wave /T VideoHWVal 	= 	$(FldrName+":VideoHWVal")

DevID 	 		= Str2Num(VideoHWVal[0])
ChNum  			= Str2Num(VideoHWVal[1])
FramesPerSec 	= Str2Num(VideoHWVal[2])
//$(FldrName+":VideoHWName")
//DevIdStr = "Dev"+Num2Str(DevID)
//TrigSrcStr	= "/"+DevIdStr+(VideoHWVal[3])

//Button button1, disable=2, win=$VideoPanelName // disable
//Button button3, disable=0, win=$VideoPanelName // Enable Reset button

//Wave VideoVWave =  $(FldrName+":VideoVWave")
//VideoVWave = NaN


If (StringMatch(ButtonVarName, "TrigGen"))
// copy output wave to root. copy DeviceName, Wavename, ChannelName to IOVidDevNum, IOVidWName and IOVidChNum in root:TrigGenVars
Wave /T IOVidDevFldrCopy 	= root:TrigGenVars:IOVidDevFldrCopy
Wave /T InWaveNamesWCopy=$(FldrName+":InWaveNamesWCopy")
For (i=0; i<NumPnts(IOVidDevFldrCopy); i+=1)
	If (StringMatch(IOVidDevFldrCopy[i], FldrName))


// If no inwave, create one and scale later according to outwaves or inwaves on other channels
// If no other channels have outwaves or inwaves, abort and ask user to make inwave		
	If (NumPnts(InWaveNamesWCopy)==0)
	Make /O/N=0 $(FldrName+":"+"DummyVideoW")
	Make /T/O/N=1 $(FldrName+":"+"InWaveNamesWCopy")	
	Wave /T InWaveNamesWCopy=$(FldrName+":InWaveNamesWCopy")	
	InWaveNamesWCopy[0] = "DummyVideoW"
	EndIf
	
	Wave InW = $(FldrName+":"+InWaveNamesWCopy[0])
	InW = Nan
	//In Wave will be scaled after acquisition
	Duplicate /O InW, $(FldrName+"In")
	sscanf FldrName+"In", "root:%s", WName
	Duplicate /O InW, $(FldrName+":"+WName)		// for pt_VideoDisplay()
	

	Wave /T IOVidDevNum 	= root:TrigGenVars:IOVidDevNum
	Wave /T IOVidChNum 	= root:TrigGenVars:IOVidChNum
	Wave /T IOVidFramesPerSec = root:TrigGenVars:IOVidFramesPerSec
	Wave /T IOVidWName 	= root:TrigGenVars:IOVidWName
	Wave /T IOVidEOSH 		= root:TrigGenVars:IOVidEOSH
	
	IOVidDevNum[i]				= VideoHWVal[0]	
	IOVidChNum[i]				= VideoHWVal[1]
	IOVidFramesPerSec[i]		= VideoHWVal[2]
	sscanf FldrName+"In", "root:%s", WName
	IOVidWName[i]	= WName
	IOVidEOSH[i]	= "pt_VideoEOSH()"
	
	If (NumPnts(InWaveNamesWCopy)>1)
		DeletePoints 0,1,InWaveNamesWCopy
	Else
		Print "Warning! Sending the same wave in the next iteration as this iteration, as no more waves are left in InWaveNamesWCopy"
	EndIf
	
	Break	
	EndIf
EndFor
Else


// Check whether data already exists on the disk

PathInfo home
If (V_Flag==0)
	Abort "Please save the experiment first!"
EndIf
NewPath /Q/O HDSymbPath,  S_Path


SVAR InWaveBaseName	= $FldrName+":InWaveBaseName"
NVAR CellNum 			= $FldrName+":CellNum"
NVAR IterNum			= $FldrName+":IterNum"
NVAR SamplingFreq		= $FldrName+":SamplingFreq"	// //Sampling Freq in Hz for single scan
String MatchStr = InWaveBaseName +pt_PadZeros2IntNumCopy(CellNum, 4)+"_"+pt_PadZeros2IntNumCopy(IterNum, 4)

If (pt_DataExistsCheck(MatchStr, "HDSymbPath")==1)
	String DoAlertPromptStr = MatchStr+" already exists on disk. Overwrite?"
	DoAlert 1, DoAlertPromptStr
	If (V_Flag==2)
		Abort "Aborting..."
	EndIf
EndIf



InWaveListStr = ""

//Wave /T InWaveNamesW=$FldrName+":InWaveNamesW"
//Wave InW = $(FldrName+":"+InWaveNamesW[0])
//In Wave will be scaled after acquisition
sscanf FldrName+"In", "root:%s", WName
Make /O/N=100 $(FldrName+":"+WName)		// for pt_VideoDisplay()
Wave InW = $(FldrName+":"+WName)
SetScale /P x,0,1/SamplingFreq,InW		
InW = Nan

InWaveListStr += FldrName+":"+WName//+","+Num2Str(ChNum)+";"

//string cmd="Grabber color=0"
//Execute cmd

string cmd="Grabber GrabFrame"
Execute cmd
Duplicate /O M_Frame, $(FldrName+":"+WName)
pt_VideoEOSH("")


//Print "Reading in wave from Video Device", InWaveListStr
// without trigger
//DAQmx_Scan /DEV= DevIdStr /BKG /ERRH="pt_VideoERRH()" /EOSH="pt_VideoEOSH()" Waves= InWaveListStr		
  
// with trigger. If TRIG="", scan starts immediately (but still has to wait for trigger if one is specified). /STRT=0 means need to use
//  fDAQmx_ScanStart() to start scan. Scan start is not the same as acquisition start if a trigger is specified

//DAQmx_Scan /DEV= DevIdStr /BKG=1 /STRT=1/ERRH="pt_VideoERRH()" /EOSH="pt_VideoEOSH()" Waves= InWaveListStr
//String VideoErr = fDAQmx_ErrorString()
//If (!StringMatch(VideoErr,""))
//	Print VideoErr
//	pt_VideoERRH()
//EndIf
//Print "********Button********"
//Button button1, disable=0, win=$VideoPanelName // disable
//pt_VideoEOSH()
//	TrigSrcStr = ""		// In case no trigger is specified, empty string causes scan to start without trigger
EndIf

//OldDF = GetDataFolder(1)
//SetDataFolder  root:VideoVars


End
//=======================

Function pt_VideoStartPreview(ButtonVarName) :  ButtonControl

// Based on pt_TemperatureAcquire
String ButtonVarName	// will be called using the button or from TrigGen (to run simultaneously with other channels )

NVAR VideoInstNum		=root:VideoInstNum
If (StringMatch(ButtonVarName, "Button3"))
VideoInstNum				= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
EndIf
String FldrName 					= "root:VideoVars"+Num2Str(VideoInstNum)
String VideoPanelName 	= "VideoMain"+Num2Str(VideoInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

Variable DevID = Nan
Variable ChNum = Nan
Variable i

String DevIdStr, InWaveListStr, OldDF, WName
//String TrigSrcStr 				
Wave /T VideoHWName =  	$(FldrName+":VideoHWName")
Wave /T VideoHWVal 	= 	$(FldrName+":VideoHWVal")

DevID 	 	= Str2Num(VideoHWVal[0])
ChNum  		= Str2Num(VideoHWVal[1])
//$(FldrName+":VideoHWName")
//DevIdStr = "Dev"+Num2Str(DevID)
//TrigSrcStr	= "/"+DevIdStr+(VideoHWVal[3])

//Button button1, disable=2, win=$VideoPanelName // disable
//Button button3, disable=0, win=$VideoPanelName // Enable Reset button

//Wave VideoVWave =  $(FldrName+":VideoVWave")
//VideoVWave = NaN

//string cmd="Grabber color=0"
//Execute cmd

string cmd="Grabber StartPreview"
Execute cmd

cmd = "Grabber SetInputChannel="+Num2Str(ChNum)
Execute cmd

End
//=======================
Function pt_VideoEndPreview(ButtonVarName) :  ButtonControl

// Based on pt_TemperatureAcquire
String ButtonVarName	// will be called using the button or from TrigGen (to run simultaneously with other channels )

NVAR VideoInstNum		=root:VideoInstNum
If (StringMatch(ButtonVarName, "Button4"))
VideoInstNum				= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
EndIf
String FldrName 					= "root:VideoVars"+Num2Str(VideoInstNum)
String VideoPanelName 	= "VideoMain"+Num2Str(VideoInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

Variable DevID = Nan
Variable ChNum = Nan
Variable i, NumMovies

String DevIdStr, InWaveListStr, OldDF, WName
//String TrigSrcStr 				
Wave /T VideoHWName =  	$(FldrName+":VideoHWName")
Wave /T VideoHWVal 	= 	$(FldrName+":VideoHWVal")

DevID 	 	= Str2Num(VideoHWVal[0])
ChNum  		= Str2Num(VideoHWVal[1])
//$(FldrName+":VideoHWName")
//DevIdStr = "Dev"+Num2Str(DevID)
//TrigSrcStr	= "/"+DevIdStr+(VideoHWVal[3])

//Button button1, disable=2, win=$VideoPanelName // disable
//Button button3, disable=0, win=$VideoPanelName // Enable Reset button

//Wave VideoVWave =  $(FldrName+":VideoVWave")
//VideoVWave = NaN

//string cmd="Grabber color=0"
//Execute cmd

String cmd="Grabber EndPreview"
Execute cmd

cmd = "Grabber SetInputChannel="+Num2Str(ChNum)
Execute cmd

End

//=======================


Function pt_VidMkMov(ButtonVarName) :  ButtonControl

// Based on pt_TemperatureAcquire
String ButtonVarName	// will be called using the button or from TrigGen (to run simultaneously with other channels )

NVAR VideoInstNum		=root:VideoInstNum
If (StringMatch(ButtonVarName, "Button4"))
VideoInstNum				= Str2Num(getuserdata("",ButtonVarName,""))	// convert Instance Num String to Num
EndIf
String FldrName 					= "root:VideoVars"+Num2Str(VideoInstNum)
String VideoPanelName 	= "VideoMain"+Num2Str(VideoInstNum)
String ListStr, AllListStr, OldDf
Variable i, NumWaves, NMovies
String VMatchStr, VMatchExtn, VDataIsImage, VMovieName, VStartFrameNum, VNFramesPerMovie, VAllFrames, VAppendGraphW
String OldMatchStr, OldHDFolderPath, OldMatchExtn, OldDataIsImage, OldIgorFolderPath, OldN0, OldNDel, OldNTot

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////
//DoWindow VidMkMovParEdit
//If (V_Flag)
//DoWindow /K VidMkMovParEdit
//EndIf

//Edit /K=1
//DoWindow /C VidMkMovParEdit

//If (WaveExists($(FldrName+":VidMkMovParName")) && WaveExists($(FldrName+":VidMkMovParVal"))    )
//Wave /T VidMkMovParName =  	$(FldrName+":VidMkMovParName")
//Wave /T VidMkMovParVal 	= 	$(FldrName+":VidMkMovParVal")
//AppendToTable /W=VidMkMovParEdit VidMkMovParName, VidMkMovParVal
//Else
//Make /T/O/N=7 $(FldrName+":VidMkMovParName")
//Make /T/O/N=7 $(FldrName+":VidMkMovParVal")
//Wave /T VidMkMovParName =  	$(FldrName+":VidMkMovParName")
//Wave /T VidMkMovParVal 	= 	$(FldrName+":VidMkMovParVal")

//VidMkMovParName[0] = "MatchStr"
//VidMkMovParName[1] = "MatchExtn"
//VidMkMovParName[2] = "DataIsImage"
//VidMkMovParName[3] = "MovieName"
//VidMkMovParName[4] = "StartFrameNum"
//VidMkMovParName[5] = "NFramesPerMovie"
//VidMkMovParName[6] = "AllFrames"
//VideoHWName[2] = "VideoVGain (Deg/Volt)"
//VideoHWName[3] = "TrigSrc"		// value = "NoTrig" OR TriggerName like "/PFI4"
//AppendToTable /W=VidMkMovParEdit VidMkMovParName, VidMkMovParVal

// logic load matching waves in a temporary folder
// Use logic from pt_MakeMovie to make movies

//EndIf

Wave /T VidMkMovParNamesW	=	$pt_GetParWave("pt_VidMkMov", "ParNamesW")
Wave /T VidMkMovParW			=	$pt_GetParWave("pt_VidMkMov", "ParW")

VMatchStr 			= VidMkMovParW[0]
VMatchExtn 			= VidMkMovParW[1]
VDataIsImage 		= VidMkMovParW[2]
VMovieName 		= VidMkMovParW[3]
VStartFrameNum 	= VidMkMovParW[4]
VNFramesPerMovie 	= VidMkMovParW[5]
VAllFrames 			= VidMkMovParW[6]
VAppendGraphW 	= VidMkMovParW[7]

PathInfo home
If (V_Flag==0)
	Abort "Please save the experiment first!"
EndIf
//NewPath /O DiskDFName,  S_Path

Wave /T LDAnalParNamesW	=	$pt_GetParWave("pt_LoadDataNthWave", "ParNamesW")
Wave /T LDAnalParW			=	$pt_GetParWave("pt_LoadDataNthWave", "ParW")

If (WaveExists(LDAnalParW)*WaveExists(LDAnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_LoadDataNthWave!!!"
EndIf
	
// save pars
OldMatchStr			= LDAnalParW[0]
OldMatchExtn 		= LDAnalParW[1]
OldDataIsImage		= LDAnalParW[2]
OldHDFolderPath		= LDAnalParW[3]
OldIgorFolderPath	= LDAnalParW[4]
OldN0				= LDAnalParW[5]
OldNDel				= LDAnalParW[6]
OldNTot				= LDAnalParW[7]

NewPath /O/Q/C SymblkHDFolderPath, S_Path
AllListStr= IndexedFile(SymblkHDFolderPath, -1, VMatchExtn)
ListStr = ListMatch(AllListStr, VMatchStr)
NumWaves = ItemsinList(ListStr)

NMovies = floor((NumWaves-Str2Num(VStartFrameNum))/Str2Num(VNFramesPerMovie))
If (!(Str2Num(VAllFrames) == 1) && (NMovies >1))	// All Frames
NMovies = 1
EndIf

LDAnalParW[0] = VMatchStr
LDAnalParW[1] = VMatchExtn 
LDAnalParW[2] = VDataIsImage
LDAnalParW[3] = S_Path
LDAnalParW[4] = FldrName+":TmpVideoFldr"
//LDAnalParW[3] = VidMkMovParVal[2]
LDAnalParW[6] = "1"
LDAnalParW[7] = VNFramesPerMovie

If (!StringMatch(VAppendGraphW, "")) 	// Append a graph to the movie
OldDf = GetDataFolder(1)
NewDataFolder /S $(FldrName+":TmpVideoFldr")
LoadWave /P=SymblkHDFolderPath VAppendGraphW

LDAnalParW[5] = Num2Str(Str2Num(VStartFrameNum)+0*Str2Num(VNFramesPerMovie))
pt_LoadDataNthWave()
pt_MakeMovieWGraph(S_Path+VMovieName+"_"+pt_PadZeros2IntNumCopy(i, 5), VMatchStr, VAppendGraphW)
SetDataFolder OldDf
KillDataFolder /Z $(FldrName+":TmpVideoFldr")
Else
For (i=0; i<NMovies; i+=1)
LDAnalParW[5] = Num2Str(Str2Num(VStartFrameNum)+i*Str2Num(VNFramesPerMovie))
pt_LoadDataNthWave()
OldDf = GetDataFolder(1)
SetDataFolder $(FldrName+":TmpVideoFldr")
pt_MakeMovie(S_Path+VMovieName+"_"+pt_PadZeros2IntNumCopy(i, 5), VMatchStr)
SetDataFolder OldDf
KillDataFolder /Z $(FldrName+":TmpVideoFldr")

Endfor
EndIf
// restore pars
LDAnalParW[0] = OldMatchStr
LDAnalParW[1] = OldMatchExtn
LDAnalParW[2] = OldDataIsImage 
LDAnalParW[3] = OldHDFolderPath
LDAnalParW[4] = OldIgorFolderPath
LDAnalParW[5] = OldN0
LDAnalParW[6] = OldNDel
LDAnalParW[7] = OldNTot

//Variable DevID = Nan
//Variable ChNum = Nan


//String DevIdStr, InWaveListStr, OldDF, WName
//String TrigSrcStr 				
//Wave /T VideoHWName =  	$(FldrName+":VideoHWName")
//Wave /T VideoHWVal 	= 	$(FldrName+":VideoHWVal")

//DevID 	 	= Str2Num(VideoHWVal[0])
//ChNum  		= Str2Num(VideoHWVal[1])
//$(FldrName+":VideoHWName")
//DevIdStr = "Dev"+Num2Str(DevID)
//TrigSrcStr	= "/"+DevIdStr+(VideoHWVal[3])

//Button button1, disable=2, win=$VideoPanelName // disable
//Button button3, disable=0, win=$VideoPanelName // Enable Reset button

//Wave VideoVWave =  $(FldrName+":VideoVWave")
//VideoVWave = NaN

//string cmd="Grabber color=0"
//Execute cmd

//String cmd="Grabber EndPreview"
//Execute cmd

//cmd = "Grabber SetInputChannel="+Num2Str(ChNum)
//Execute cmd

End

//=======================
Function pt_VideoEOSH(CallSource)
String CallSource
// Based on pt_TemperatureEOSH()
NVAR VideoInstNum		=root:VideoInstNum
//If (!StringMatch(button0, "TrigGen"))
//VideoInstNum				= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 			= "root:VideoVars"+Num2Str(VideoInstNum)
String VideoPanelName 	= "VideoMain"+Num2Str(VideoInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////


//Button button1, disable=0, win=$VideoPanelName // Enable scan button
//Button button3, disable=2, win=$VideoPanelName // Disable Reset button

//NVAR Temp 				= $(FldrName+":CurrentVideo")
//NVAR VideoError 	= $FldrName+":VideoError"
//Variable Gain
//String WName

//sscanf FldrName+"In", "root:%s", WName
//Wave VideoInWave = $(FldrName+":"+WName)

//Wave /T VideoHWName =  	$(FldrName+":VideoHWName")
//Wave /T VideoHWVal 	= 	$(FldrName+":VideoHWVal")

//Gain = Str2Num(VideoHWVal[2])
//VideoInWave *=Gain				// Scale incoming wave

//pt_VideoAnalyze()	// nothing to analyze yet
//pt_VideoDisplay()		// in case of video last frame is displayed
pt_VideoSave(CallSource)

//WaveStats /Q VideoInWave			// Analyse incoming wave
//Temp = V_Avg
//Print "Current Video =", Temp
//If (!StringMatch(VideoHWVal[3], "NoTrig"))
//	Print "Waiting for next trigger..."
//	pt_VideoAcquire("button1")		// if scan was started using a trigger then, set start scan again and wait for new trigger.
//EndIf
End

//=======================
Function pt_VideoDisplay()
// Based on pt_TemperatureDisplay()
// display data: Check if the window VideoDisplayWin exists? 
// if yes, append. If no, create and append

NVAR VideoInstNum		=root:VideoInstNum
//If (!StringMatch(button0, "TrigGen"))
//VideoInstNum				= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 					= "root:VideoVars"+Num2Str(VideoInstNum)
//String VideoPanelName 	= "VideoMain"+Num2Str(VideoInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////


String WName

sscanf FldrName+"In", "root:%s", WName
Wave VideoInWave = $(FldrName+":"+WName)
//edit VideoInWave
//abort

DoWindow VideoDisplayWin
If (!V_Flag)
// Check if the trace is not on graph
//	Print TraceNameList("VideoDisplayWin", ";", 1)
//	If (FindListItem(WName, TraceNameList("VideoDisplayWin", ";", 1), ";")==-1)
//	NewImage /HOST=VideoDisplayWin VideoInWave
//	EndIf
//Else
	NewImage /k =1 VideoInWave
	DoWindow /C VideoDisplayWin
//	ModifyImage /W=VideoDisplayWin  VideoInWave ctab= {*,*,Grays,0}
//	AppendToGraph /W=VideoDisplayWin VideoInWave
EndIf

//sscanf FldrName+"Avg", "root:%s", WName
//Wave VideoAvgWave = $(FldrName+":"+WName)


//DoWindow VideoAvgDisplayWin
//If (V_Flag)
// Check if the trace is not on graph
//	Print TraceNameList("VideoDisplayWin", ";", 1)
//	If (FindListItem(WName, TraceNameList("VideoAvgDisplayWin", ";", 1), ";")==-1)
//	AppendToGraph /W=VideoAvgDisplayWin VideoAvgWave
//	EndIf
//Else
//	Display
//	DoWindow /C VideoAvgDisplayWin
//	AppendToGraph /W=VideoAvgDisplayWin VideoAvgWave
//EndIf



End
//=======================
Function pt_VideoSave(CallSource)
String CallSource
// Based on pt_TemperatureSave()
// Save data to disk
Variable N,i
String OldDf, Str, WName, WList

NVAR VideoInstNum		=root:VideoInstNum
//If (!StringMatch(button0, "TrigGen"))
//VideoInstNum				= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 					= "root:VideoVars"+Num2Str(VideoInstNum)
//String VideoPanelName 	= "VideoMain"+Num2Str(VideoInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////

SVAR InWaveBaseName	= $FldrName+":InWaveBaseName"
NVAR CellNum 			= $FldrName+":CellNum"
NVAR IterNum 			= $FldrName+":IterNum"

sscanf FldrName+"In", "root:%s", WName
//Wave VideoInWave = $(FldrName+":"+WName)

OldDF = GetDataFolder(1)
SetDataFolder $FldrName
//SVAR SaveWaveList	= SaveWaveList
//Wave /T OutWaveToSave = $FldrName+":OutWaveToSave"	No Out Wave to save for Video
//Wave /T InWaveToSave = $FldrName+":InWaveToSave"			In wave to save is always the acquired wave
PathInfo home
If (V_Flag==0)
	Abort "Please save the experiment first!"
EndIf
NewPath /O DiskDFName,  S_Path
Print "Saving Video data to",S_Path
//SaveData /Q/D=1/O/L=1  /P=DiskDFName /J =SaveWaveList InWaveToSaveAs+"_"+ Num2Str(IterNum)//T=$EncFName /P=SaveDF
//N=NumPnts(OutWaveToSave)
//For (i=0; i<N; i+=1)	// save outwaves with the original wave names.
//	Save /C/O/P=DiskDFName  $OutWaveToSave[i]
//EndFor
If (StringMatch(CallSource, "VideoCall"))
WList=Wavelist(WName+"_*",";","" )
N = ItemsInList(WList,";")
For (i=0; i<N; i+=1)
// OldCode
//Wave VideoInWave = $(StringFromList(i, WList, ";"))
Str = InWaveBaseName +pt_PadZeros2IntNumCopy(CellNum, 4)+"_"+pt_PadZeros2IntNumCopy(IterNum, 5)+"_"+pt_PadZeros2IntNumCopy(i, 5)+".jpg"
NewImage $(StringFromList(i, WList, ";"))
DoWindow /C TmpImageWindow
SavePICT/P=DiskDFName/Q=0.1/T="JPEG"/B=72 as Str
DoWindow /K TmpImageWindow
//Duplicate /O VideoInWave, $(Str)
//Save /C/O/P=DiskDFName  $(Str)
// OldCode
//IterNum +=1
KillWaves /Z $(Str)
EndFor
IterNum +=1
Else
sscanf FldrName+"In", "root:%s", WName
Wave VideoInWave = $(FldrName+":"+WName)
Str = InWaveBaseName +pt_PadZeros2IntNumCopy(CellNum, 4)+"_"+pt_PadZeros2IntNumCopy(IterNum, 4)
Duplicate /O VideoInWave, $(Str)
Save /C/O/P=DiskDFName  $(Str) //as InWaveToSaveAsFull+".ibw"
IterNum +=1
KillWaves /Z $(Str)
EndIf
//Str = InWaveBaseName +pt_PadZeros2IntNumCopy(CellNum, 4)+"_"+pt_PadZeros2IntNumCopy(IterNum, 4)
//Print "InWaveToSaveAs ", Str
//Duplicate /O VideoInWave, $(Str)

//InWaveToSaveAsFull = InWaveToSaveAs+ Num2Str(IterNum)
//Duplicate /O VideoVWave, $InWaveToSaveAsFull
//Save /C/O/P=DiskDFName  $(Str) //as InWaveToSaveAsFull+".ibw"
//KillWaves $(Str)
KillPath /Z DiskDFName
SetDataFolder OldDf

End
//=======================

Function pt_VideoAnalyze()
// Based on pt_TemperatureAnalyze()
// Analyze data: Resample at low freq


NVAR VideoInstNum		=root:VideoInstNum
//If (!StringMatch(button0, "TrigGen"))
//VideoInstNum				= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 					= "root:VideoVars"+Num2Str(VideoInstNum)
String VideoVWName
//String VideoPanelName 	= "VideoMain"+Num2Str(VideoInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
//NVAR 	    ReSamplingFreq		= $FldrName+":ReSamplingFreq"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////


String WName

sscanf FldrName+"In", "root:%s", WName
Wave VideoInWave = $(FldrName+":"+WName)
//Resample /Rate = (ResamplingFreq) VideoInWave	// Resample Video at 10Hz

//Wavestats /Q VideoInWave
//Make /O/N=1 Video_Avg = V_Avg

//String VideoVWName
//sscanf FldrName+"Avg", "root:%s", VideoVWName
//If (WaveExists($(FldrName+":"+VideoVWName)))
//Wave VideoVW = $(FldrName+":"+VideoVWName)
//Concatenate /NP {Video_Avg}, VideoVW
//Else
//Make /O/N=0 $(FldrName+":"+VideoVWName)
//Wave VideoVW = $(FldrName+":"+VideoVWName)
//Concatenate /NP {Video_Avg}, VideoVW
//EndIf

End

//=======================

Function pt_VideoInitialize(TrigGen)

// based on pt_TemperatureInitialize

String TrigGen

NVAR VideoInstNum			=root:VideoInstNum
//If (!StringMatch(button0, "TrigGen"))
//	VideoInstNum			= Str2Num(getuserdata("",button0,""))	// convert Instance Num String to Num
//EndIf
String FldrName 				= "root:VideoVars"+Num2Str(VideoInstNum)
//String VideoPanelName 	= "VideoMain"+Num2Str(VideoInstNum)

/////////////////////////////////////////////////////////////////////////////
NVAR        DebugMode = $FldrName+":DebugMode"
If (DebugMode)
Print "*************************************"
Print "Debug Mode"
// Information to be printed out while debugging
Print "FolderName =", FldrName
Print "*************************************"
EndIf
/////////////////////////////////////////////////////////////////////////////


// Check whether data already exists on the disk

PathInfo home
If (V_Flag==0)
	Abort "Please save the experiment first!"
EndIf
NewPath /Q/O HDSymbPath,  S_Path


SVAR InWaveBaseName	= $FldrName+":InWaveBaseName"
NVAR CellNum 			= $FldrName+":CellNum"
NVAR IterNum			= $FldrName+":IterNum"
NVAR IterTot = root:TrigGenVars:IterTot
NVAR IterLeft = root:TrigGenVars:IterLeft
NVAR RepsTot		= root:TrigGenVars:RepsTot
NVAR RepsLeft		= root:TrigGenVars:RepsLeft
String MatchStr = InWaveBaseName +pt_PadZeros2IntNumCopy(CellNum, 4)+"_"+pt_PadZeros2IntNumCopy(IterNum, 4)

If ((IterLeft == IterTot) && (RepsLeft == RepsTot))	// Do for 1st Iter of 1st Rep
If (pt_DataExistsCheck(MatchStr, "HDSymbPath")==1)
	String DoAlertPromptStr = MatchStr+" already exists on disk. Overwrite?"
	DoAlert 1, DoAlertPromptStr
	If (V_Flag==2)
		Abort "Aborting..."
	EndIf
EndIf
EndIf

Wave /T 		InWaveNamesW = 	$FldrName+":InWaveNamesW"
Duplicate /O InWaveNamesW, 		$FldrName+":InWaveNamesWCopy"

//pt_ClearVideoAvgW(FldrName)

End


//=======================


Function pt_PlotCursorDiff(GraphName, DelWinSec)
String GraphName
Variable DelWinSec
// modified to plot for multiple graphs 02/10/14
// A quick script to plot response amplitude so that we can check when the
// response is stable.
// logic - Make a new graph.
// Append to graph the difference between cursor B - cursor A from
// a specified graph. The function needs to run after every data aquisition iteration

String TraceName
Variable y2, y1, x2, x1, BLWinStart, BLWinEnd, PkWinStart, PkWinEnd

DoWindow $GraphName +"CursorDiff" // if window is closed, assume new trace
If (V_Flag ==0)
	Make /O/N=0 $GraphName +"CursorDiffW"
	Display 
	DoWindow /C $GraphName +"CursorDiff"
	AppendToGraph /W = $GraphName +"CursorDiff" $GraphName +"CursorDiffW"
	ModifyGraph /W = $GraphName +"CursorDiff" mode=4,marker=19
EndIf
Make /O/N=1 CursorDiffWTemp

x1 = hcsr(A, GraphName)
x2 = hcsr(B, GraphName)

TraceName = StringByKey("TName", CsrInfo(A, GraphName))
Print "Wave name for",GraphName,"=", TraceName

BLWinStart = x1-0.5*DelWinSec
BLWinEnd = x1+0.5*DelWinSec
//Duplicate /O /R=(BLWinStart, BLWinEnd) CsrWaveRef(A, GraphName), BLWave
//Print BLWave
Wavestats  /Q/R=(BLWinStart, BLWinEnd) CsrWaveRef(A, GraphName)
Print "NumPnts BL", V_NPnts
y1 = V_Avg

PkWinStart = x2-0.5*DelWinSec
PkWinEnd = x2+0.5*DelWinSec

//Duplicate /O /R=(PkWinStart, PkWinEnd) CsrWaveRef(A, GraphName), PkWave
//Print PkWave

Wavestats  /Q/R=(PkWinStart, PkWinEnd) CsrWaveRef(A, GraphName)
Print "NumPnts Pk", V_NPnts
y2 = V_Avg

Print "BL, Peak =", y1, y2
CursorDiffWTemp[0] = y2 - y1
Concatenate /NP {CursorDiffWTemp}, $GraphName +"CursorDiffW"
End

//=======================


Function pt_PlotCursorDiff1(GraphName, DelWinSec)
String GraphName
Variable DelWinSec
// A quick script to plot response amplitude so that we can check when the
// response is stable.
// logic - Make a new graph.
// Append to graph the difference between cursor B - cursor A from
// a specified graph. The function needs to run after every data aquisition iteration

String TraceName
Variable y2, y1, x2, x1, BLWinStart, BLWinEnd, PkWinStart, PkWinEnd

DoWindow pt_PlotCursorDiff_Display // if window is closed, assume new trace
If (V_Flag ==0)
	Make /O/N=0 CursorDiffW
	Display 
	DoWindow /C pt_PlotCursorDiff_Display
	AppendToGraph /W = pt_PlotCursorDiff_Display CursorDiffW
	ModifyGraph /W = pt_PlotCursorDiff_Display mode=4,marker=19
EndIf
Make /O/N=1 CursorDiffWTemp

x1 = hcsr(A, GraphName)
x2 = hcsr(B, GraphName)

TraceName = StringByKey("TName", CsrInfo(A, GraphName))
Print "Wave name for pt_PlotCursorDiff_Display", TraceName

BLWinStart = x1-0.5*DelWinSec
BLWinEnd = x1+0.5*DelWinSec
//Duplicate /O /R=(BLWinStart, BLWinEnd) CsrWaveRef(A, GraphName), BLWave
//Print BLWave
Wavestats  /Q/R=(BLWinStart, BLWinEnd) CsrWaveRef(A, GraphName)
Print "NumPnts BL", V_NPnts
y1 = V_Avg

PkWinStart = x2-0.5*DelWinSec
PkWinEnd = x2+0.5*DelWinSec

//Duplicate /O /R=(PkWinStart, PkWinEnd) CsrWaveRef(A, GraphName), PkWave
//Print PkWave

Wavestats  /Q/R=(PkWinStart, PkWinEnd) CsrWaveRef(A, GraphName)
Print "NumPnts Pk", V_NPnts
y2 = V_Avg

Print "BL, Peak =", y1, y2
CursorDiffWTemp[0] = y2 - y1
Concatenate /NP {CursorDiffWTemp}, CursorDiffW
End