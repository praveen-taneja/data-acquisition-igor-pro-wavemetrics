#pragma rtGlobals=1		// Use modern global access method.

Function /S pt_PadZeros2IntNumCopy(Num, LenStr)
// convert a positive integer to a string Prefixed with zeros
Variable Num, LenStr

String ZerosStr= ""
Variable i, NumZeros=LenStr

For (i=0; i<LenStr; i+=1)
	If (Num<10^(i+1))
			NumZeros = LenStr-(i+1) 
			Break
	EndIf
EndFor

If (NumZeros==LenStr)
	DoAlert 0, "Error in pt_PadZeros2IntNum: Number > ZeroPaddedStrLength"
	Return ""
EndIf

For (i=0; i< NumZeros; i+=1)
	ZerosStr += "0"
EndFor

Return  ZerosStr+Num2Str(Num)

End

Function pt_WaveGen() : Panel
// Based on pt_ElectroPhysWaveGen() which was without GUI
// To generate one wave typically for electrophysiology use

//If (!(DataFolderExists(root:WaveGenVars)))
//EndIf
NewDataFolder /O root:WaveGenVars
String 	/G $"root:WaveGenVars:OutWNameStrPrefix" =  "OutW" 
//String 	/G $"root:WaveGenVars:OutWNameStrSuffix" =   ""
String 	/G $"root:WaveGenVars:WNoteStr"=""
String 	/G $"root:WaveGenVars:StimFolder"=StringFromList(0, pt_TrigGenDevsList(""), ";")	// 1st channel
String 	/G $"root:WaveGenVars:StimProtocol" = "NStepsAtFixedFreq"		// Default = first Item showed in the menu
Variable 	/G $"root:WaveGenVars:DCValue"
Variable 	/G $"root:WaveGenVars:YGain" =1
Variable 	/G $"root:WaveGenVars:XOffset"
Variable 	/G $"root:WaveGenVars:XDelta"
Variable 	/G $"root:WaveGenVars:XLength"
//Variable 	/G $"root:WaveGenVars:NSegments"
//Variable 	/G $"root:WaveGenVars:StimTrain" =0 
//Variable 	/G $"root:WaveGenVars:Freq"
//Variable 	/G $"root:WaveGenVars:Width"
//Variable 	/G $"root:WaveGenVars:Amp"
//Variable 	/G $"root:WaveGenVars:StartX0"

Variable 	/G $"root:WaveGenVars:DisplayOutW"=1

Variable /G $"root:WaveGenVars:SealTestCheckBox"
Variable /G $"root:WaveGenVars:SealTestVClampAmp"
Variable /G $"root:WaveGenVars:SealTestIClampAmp"
Variable /G $"root:WaveGenVars:SealTestStartX"
Variable /G $"root:WaveGenVars:SealTestLength"

NewDataFolder /O root:WaveGenVars:NStepsAtFixedFreq
	Variable /G root:WaveGenVars:NStepsAtFixedFreq:StartX0
	Variable /G root:WaveGenVars:NStepsAtFixedFreq:Freq
	Variable /G root:WaveGenVars:NStepsAtFixedFreq:NSegments
	Variable /G root:WaveGenVars:NStepsAtFixedFreq:AmpStart
	Variable /G root:WaveGenVars:NStepsAtFixedFreq:AmpMid
	Variable /G root:WaveGenVars:NStepsAtFixedFreq:AmpEnd
	Variable /G root:WaveGenVars:NStepsAtFixedFreq:Width
	
NewDataFolder /O root:WaveGenVars:NStimsAtFixedAmpDiff
	Variable /G root:WaveGenVars:NStimsAtFixedAmpDiff:StartX0
	Variable /G root:WaveGenVars:NStimsAtFixedAmpDiff:Width
	Variable /G root:WaveGenVars:NStimsAtFixedAmpDiff:NStims
	Variable /G root:WaveGenVars:NStimsAtFixedAmpDiff:Amp0
	Variable /G root:WaveGenVars:NStimsAtFixedAmpDiff:AmpDiff	



//Variable /G DCValue, YGain, XOffset, XDelta, XLength, NSegments
//Variable /G StartX1Val, StartY1Val, EndX1Val, EndY1Val, DisplayOutW

	
	DoWindow WaveGenMain
	If (V_Flag==1)
		DoWindow /K WaveGenMain
	EndIf
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=2/W=(525,75,800,370)
	DoWindow /C WaveGenMain
//	SetDrawEnv fsize= 12,textrgb= (0,9472,39168)
//	DrawText 1,20,"Wavename"
	PopupMenu AllDataFolderList,pos={1,5},size={200,18},title="Channels"	
	PopupMenu AllDataFolderList, mode = 1, value=pt_TrigGenDevsList("AllDataFolderList"), proc = pt_StimFolderSet
	
	SetVariable setvar11,pos={1,35},size={200,18}, title = "Wave Name"
	SetVariable setvar11,value= root:WaveGenVars:OutWNameStrPrefix
//	SetVariable setvar12,pos={75,30},size={170,18}, title = "Suffix"
//	SetVariable setvar12,value= root:WaveGenVars:OutWNameStrSuffix
	
	SetVariable setvar1,pos={1,60},size={100,18}, limits={-inf,inf,0}, title ="Length (s)"
	SetVariable setvar1,value= root:WaveGenVars:XLength
	SetVariable setvar2,pos={135,60},size={100,18}, limits={-inf,inf,0}
	SetVariable setvar2,value=  root:WaveGenVars:DCValue,  title ="DC Value"
	
	SetVariable setvar3,pos={1,90},size={100,18}, limits={-inf,inf,0}, title ="XOffset (s)"
	SetVariable setvar3,value= root:WaveGenVars:XOffset
	SetVariable setvar4,pos={135,90},size={100,18}, limits={-inf,inf,0}, title ="DeltaX (s)"
	SetVariable setvar4,value= root:WaveGenVars:XDelta
	

	SetVariable setvar5,pos={1,120},size={100,18}, limits={-inf,inf,0}, title ="Y Gain"
	SetVariable setvar5,value= root:WaveGenVars:YGain
//	SetVariable setvar6,pos={135,120},size={100,18}, limits={0,inf,1}, title ="# Steps"
//	SetVariable setvar6,value= root:WaveGenVars:NSegments
	
	PopupMenu StimProtocolPopUp,pos={1,240},size={100,18},title="StimProtocol"	
//	PopupMenu StimProtocolPopUp, mode = 1, value="NStepsAtArbitraryFreq;NStepsAtFixedFreq;NStimsAtArbitraryAmps;NStimsAtFixedAmpDiff", proc = pt_StimProtocolPopSelect
	PopupMenu StimProtocolPopUp, mode = 1, value="NStepsAtFixedFreq;NStimsAtFixedAmpDiff", proc = pt_StimProtocolPopSelect
	
//	SetVariable setvar7,pos={1,125},size={100,18}, limits={-inf,inf,0}, title ="StepStart"
//	SetVariable setvar7,value= root:WaveGenVars:StartX0, disable=2
//	SetVariable setvar8,pos={135,125},size={100,18}, limits={0,inf,0}, title ="Freq (Hz)"
//	SetVariable setvar8,value= root:WaveGenVars:Freq, disable=2
	
//	SetVariable setvar9,pos={1,155},size={100,18}, limits={-inf,inf,0}, title ="Amp"
//	SetVariable setvar9,value= root:WaveGenVars:Amp, disable=2
//	SetVariable setvar10,pos={135,155},size={100,18}, limits={0,inf,0}, title ="Width (s)"
//	SetVariable setvar10,value= root:WaveGenVars:Width, disable=2
	
//	CheckBox check0,pos={1,185},size={45,15},value= 0
//	CheckBox check0, title= "StimTrain", variable = root:WaveGenVars:StimTrain, proc = pt_SpikeTrainToggle
	CheckBox check1,pos={135,120},size={45,15},value= 0
	CheckBox check1, title= "Display", variable = root:WaveGenVars:DisplayOutW
	
// Seal Test	
	SetDrawLayer UserBack
	DrawLine 1,145,270,145
	DrawLine 1,235,270,235
	
	CheckBox SealTestCheckBoxCntrl,pos={90,150},size={45,15},value= 0, fsize =16
	CheckBox SealTestCheckBoxCntrl, title= "Seal Test", variable = root:WaveGenVars:SealTestCheckBox
	SetVariable setvar6,pos={1,180},size={130,18}, limits={-inf,inf,0}, title ="VClamp Amp (V)"
	SetVariable setvar6,value= root:WaveGenVars:SealTestVClampAmp
	SetVariable setvar7,pos={135,180},size={140,18}, limits={-inf,inf,0}, title ="IClamp Amp (A)"
	SetVariable setvar7,value= root:WaveGenVars:SealTestIClampAmp
	
	SetVariable setvar8,pos={1,210},size={100,18}, limits={-inf,inf,0}, title ="Start (s)"
	SetVariable setvar8,value= root:WaveGenVars:SealTestStartX
	SetVariable setvar9,pos={135,210},size={100,18}, limits={-inf,inf,0}, title ="Length (s)"
	SetVariable setvar9,value= root:WaveGenVars:SealTestLength
	
	
	
//	Create itself will create Step Values rather than user pressing Step Values first	
//	Button button0,pos={1,270},size={100,20},title="Step Values"	
//	Button button0,proc = pt_WaveGenEdit
	Button button1,pos={90,270},size={100,20},title="Create"
	Button button1,proc = pt_WaveGenCreate
End


Function pt_StimFolderSet(PopupMenuVarName,PopupMenuVarNum,PopupMenuVarStr) : PopupMenuControl
//Function pt_EPhysPopSelect(PopupMenuVarName, PopupMenuVarStr) : PopupMenuControl
String PopupMenuVarName, PopupMenuVarStr
Variable PopupMenuVarNum
SVAR  StimFolder = $"root:WaveGenVars:StimFolder"
StimFolder = PopupMenuVarStr
End 

Function pt_AnalParFolderSet(PopupMenuVarName,PopupMenuVarNum,PopupMenuVarStr) : PopupMenuControl
//Function pt_EPhysPopSelect(PopupMenuVarName, PopupMenuVarStr) : PopupMenuControl
String PopupMenuVarName, PopupMenuVarStr
Variable PopupMenuVarNum
SVAR  AnalParFolder = $"root:AnalyzeDataVars:AnalParFolder"
AnalParFolder = PopupMenuVarStr
End

Function pt_SpikeTrainToggle(CheckBoxVarName, CheckBoxVarVal) : CheckBoxControl
// This function is no longer in use
String CheckBoxVarName
Variable CheckBoxVarVal

NVAR StimTrain = root:WaveGenVars:StimTrain

If (StimTrain)
	SetVariable SetVar7, win = WaveGenMain, disable = 0
	SetVariable SetVar8, win = WaveGenMain, disable = 0
	SetVariable SetVar9, win = WaveGenMain, disable = 0
	SetVariable SetVar10, win = WaveGenMain, disable = 0
Else
	SetVariable SetVar7, win = WaveGenMain, disable = 2
	SetVariable SetVar8, win = WaveGenMain, disable = 2
	SetVariable SetVar9, win = WaveGenMain, disable = 2
	SetVariable SetVar10, win = WaveGenMain, disable = 2
EndIf

End

Function pt_StimProtocolPopSelect(PopupMenuVarName,PopupMenuVarNum,PopupMenuVarStr) : PopupMenuControl
String PopupMenuVarName, PopupMenuVarStr
Variable PopupMenuVarNum

SVAR StimProtocol = root:WaveGenVars:StimProtocol

StrSwitch (PopupMenuVarStr)
//	Case "NStepsAtArbitraryFreq" :
//	StimProtocol = "NStepsAtArbitraryFreq"
//	Break
	Case "NStepsAtFixedFreq" :
	DoWindow NStepsAtFixedFreqPanel
	If (V_Flag==1)
		DoWindow /F NStepsAtFixedFreqPanel
	Else
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1/W=(525,75,790,180)
	DoWindow /C NStepsAtFixedFreqPanel
	EndIf
//	String OldDf = GetDataFolder(1)
//	NewDataFolder /O root:WaveGenVars:NStepsAtFixedFreq
	NVAR StartX0		=$"root:WaveGenVars:NStepsAtFixedFreq:StartX0"
	NVAR Freq			=$"root:WaveGenVars:NStepsAtFixedFreq:Freq"
	NVAR NSegments	=$"root:WaveGenVars:NStepsAtFixedFreq:NSegments"
	NVAR AmpStart		=$"root:WaveGenVars:NStepsAtFixedFreq:AmpStart"
	NVAR AmpMid		=$"root:WaveGenVars:NStepsAtFixedFreq:AmpMid"
	NVAR AmpEnd		=$"root:WaveGenVars:NStepsAtFixedFreq:AmpEnd"
	NVAR Width			=$"root:WaveGenVars:NStepsAtFixedFreq:Width"
	
	SetVariable setvar0,pos={1,15},size={100,18}, limits={-inf,inf,0}, title ="StepStart (s)"
	SetVariable setvar0,value= root:WaveGenVars:NStepsAtFixedFreq:StartX0
	SetVariable setvar1,pos={135,15},size={100,18}, limits={0,inf,0}, title ="Freq (Hz)"
	SetVariable setvar1,value= root:WaveGenVars:NStepsAtFixedFreq:Freq
	SetVariable setvar2,pos={1,50},size={100,18}, limits={0,inf,1}, title ="# Steps"
	SetVariable setvar2,value= root:WaveGenVars:NStepsAtFixedFreq:NSegments
	SetVariable setvar3,pos={135,45},size={100,18}, limits={-inf,inf,0}, title ="AmpStart"
	SetVariable setvar3,value= root:WaveGenVars:NStepsAtFixedFreq:AmpStart
	SetVariable setvar5,pos={135,65},size={100,18}, limits={-inf,inf,0}, title ="AmpMid"
	SetVariable setvar5,value= root:WaveGenVars:NStepsAtFixedFreq:AmpMid
	SetVariable setvar6,pos={135,85},size={100,18}, limits={-inf,inf,0}, title ="AmpEnd"
	SetVariable setvar6,value= root:WaveGenVars:NStepsAtFixedFreq:AmpEnd
	
	SetVariable setvar4,pos={1,80},size={100,18}, limits={0,inf,0}, title ="Width (s)"
	SetVariable setvar4,value= root:WaveGenVars:NStepsAtFixedFreq:Width
	StimProtocol = "NStepsAtFixedFreq"
	
	
//	SetDataFolder OldDf
	Break
	
//	Case "NStimsAtArbitraryAmps" :
//	DoWindow WaveGenMain
//	StimProtocol = "NStimsAtArbitraryAmps"
//	Break
	
	Case "NStimsAtFixedAmpDiff" :
	StimProtocol = "NStimsAtFixedAmpDiff"
	DoWindow NStimsAtFixedAmpDiffPanel
	If (V_Flag==1)
		DoWindow /F NStimsAtFixedAmpDiffPanel
	Else
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1/W=(525,75,790,180)
	DoWindow /C NStimsAtFixedAmpDiffPanel
	EndIf
//	String OldDf = GetDataFolder(1)
//	NewDataFolder /O root:WaveGenVars:NStimsAtFixedAmpDiff
	NVAR	StartX0			=		$"root:WaveGenVars:NStimsAtFixedAmpDiff:StartX0"
	NVAR	Width			=		$"root:WaveGenVars:NStimsAtFixedAmpDiff:Width"
	NVAR	NStims			=		$"root:WaveGenVars:NStimsAtFixedAmpDiff:NStims"
	NVAR	Amp0			=		$"root:WaveGenVars:NStimsAtFixedAmpDiff:Amp0"
	NVAR	AmpDiff			=		$"root:WaveGenVars:NStimsAtFixedAmpDiff:AmpDiff"
	
	SetVariable setvar0,pos={1,15},size={100,18}, limits={-inf,inf,0}, title ="StepStart (s)"
	SetVariable setvar0,value= root:WaveGenVars:NStimsAtFixedAmpDiff:StartX0
	SetVariable setvar1,pos={135,15},size={100,18}, limits={0,inf,0}, title ="Width (s)"
	SetVariable setvar1,value= root:WaveGenVars:NStimsAtFixedAmpDiff:Width
	SetVariable setvar2,pos={1,50},size={100,18}, limits={0,inf,1}, title ="# Stims"
	SetVariable setvar2,value= root:WaveGenVars:NStimsAtFixedAmpDiff:NStims
	SetVariable setvar3,pos={135,50},size={100,18}, limits={-inf,inf,0}, title ="1st Stim Amp"
	SetVariable setvar3,value= root:WaveGenVars:NStimsAtFixedAmpDiff:Amp0
	SetVariable setvar4,pos={1,80},size={100,18}, limits={-inf,inf,0}, title ="Amp Diff"
	SetVariable setvar4,value= root:WaveGenVars:NStimsAtFixedAmpDiff:AmpDiff
	StimProtocol = "NStimsAtFixedAmpDiff"
//	SetDataFolder OldDf
	Break
	
EndSwitch

End 


Function pt_WaveGenEdit(button0) : ButtonControl
String Button0


// For each Segment there is a StartX, StartY and EndX, EndY

// generating a number of segments at a given frequency
SVAR StimProtocol 			= root:WaveGenVars:StimProtocol
NVAR NSegments			= root:WaveGenVars:NSegments

//StimTrain 	= 1
//Freq 		= 10
//Width 		= 0.01
//Amp 		= 2
//StartX0		=1

StrSwitch (StimProtocol)
//	Case "NStepsAtArbitraryFreq" :
//	If (WaveExists($"root:WaveGenVars:StartXW") && WaveExists($"root:WaveGenVars:StartYW") && WaveExists($"root:WaveGenVars:EndXW") && WaveExists($"root:WaveGenVars:EndYW") )
	

//	Wave StartXW =  	$("root:WaveGenVars:StartXW")
//	Wave StartYW =  	$("root:WaveGenVars:StartYW")
//	Wave EndXW =  	$("root:WaveGenVars:EndXW")
//	Wave EndYW =  	$("root:WaveGenVars:EndYW")
	
//	DoWindow WaveGenParEdit
//	If (V_Flag)
//		DoWindow /K WaveGenParEdit
//	EndIf
//	Edit /K=1 StartXW, StartYW, EndXW, EndYW
//	DoWindow /C WaveGenParEdit

//	Else

//	Make /O/N=0 $("root:WaveGenVars:StartXW")
//	Make /O/N=0 $("root:WaveGenVars:StartYW")
//	Make /O/N=0 $("root:WaveGenVars:EndXW")
//	Make /O/N=0 $("root:WaveGenVars:EndYW")

//	Wave StartXW =  $("root:WaveGenVars:StartXW")
//	Wave StartYW =  $("root:WaveGenVars:StartYW")
//	Wave EndXW =  	$("root:WaveGenVars:EndXW")
//	Wave EndYW =  	$("root:WaveGenVars:EndYW")
	
//	DoWindow WaveGenParEdit
//	If (V_Flag)
//		DoWindow /K WaveGenParEdit
//	EndIf
//		Edit /K=1 StartXW, StartYW, EndXW, EndYW
//		DoWindow /C WaveGenParEdit
//	EndIf
//	Break
	
	Case "NStepsAtFixedFreq" :
	NewDataFolder /O root:WaveGenVars:NStepsAtFixedFreq
	NVAR StartX0		= root:WaveGenVars:NStepsAtFixedFreq:StartX0
	NVAR Freq			= root:WaveGenVars:NStepsAtFixedFreq:Freq
	NVAR NSegments 	= root:WaveGenVars:NStepsAtFixedFreq:NSegments
//  Multiple amplitudes for making ramps
//1. Constant step: 			AmpStart = AmpMid = AmpEnd
//2. Up going ramp: 			AmpStart < AmpEnd
//3. Down going ramp:			AmpStart < AmpEnd
//4. Up and Down going ramp: 	AmpStart = AmpEnd and AmpStart < AmpMid; 

	NVAR AmpStart 		= root:WaveGenVars:NStepsAtFixedFreq:AmpStart 
	NVAR AmpMid 		= root:WaveGenVars:NStepsAtFixedFreq:AmpMid
	NVAR AmpEnd 		= root:WaveGenVars:NStepsAtFixedFreq:AmpEnd
	NVAR Width 		= root:WaveGenVars:NStepsAtFixedFreq:Width
	
	Make /O/N=(NSegments) $("root:WaveGenVars:NStepsAtFixedFreq:StartXW")
	Make /O/N=(NSegments) $("root:WaveGenVars:NStepsAtFixedFreq:StartYW")
	Make /O/N=(NSegments) $("root:WaveGenVars:NStepsAtFixedFreq:MidXW")
	Make /O/N=(NSegments) $("root:WaveGenVars:NStepsAtFixedFreq:MidYW")
	Make /O/N=(NSegments) $("root:WaveGenVars:NStepsAtFixedFreq:EndXW")
	Make /O/N=(NSegments) $("root:WaveGenVars:NStepsAtFixedFreq:EndYW")
	
	Wave StartXW 	= $("root:WaveGenVars:NStepsAtFixedFreq:StartXW")
	Wave StartYW 	= $("root:WaveGenVars:NStepsAtFixedFreq:StartYW")
	Wave MidXW 	= $("root:WaveGenVars:NStepsAtFixedFreq:MidXW")
	Wave MidYW 	= $("root:WaveGenVars:NStepsAtFixedFreq:MidYW")
	Wave EndXW 	= $("root:WaveGenVars:NStepsAtFixedFreq:EndXW")
	Wave EndYW 	= $("root:WaveGenVars:NStepsAtFixedFreq:EndYW")
	
	StartXW 	= StartX0 + p*(1/Freq)
	StartYW 	= AmpStart
	
	MidXW 	= StartX0 + p*(1/Freq)+Width*0.5
	MidYW 	= AmpMid
	
	EndXW 	= StartX0 + p*(1/Freq)+Width
	EndYW 	= AmpEnd
	
	DoWindow WaveGenParEdit
	If (V_Flag)
		DoWindow /K WaveGenParEdit
	EndIf
		Edit /K=1 StartXW, StartYW, MidXW, MidYW, EndXW, EndYW
		DoWindow /C WaveGenParEdit
	Break
	
//	Case "NStimsAtArbitraryAmps" :
	
//	If (WaveExists($"root:WaveGenVars:AmpW"))
//	Wave AmpW = $("root:WaveGenVars:AmpW")
//	DoWindow WaveGenParEdit
//	If (V_Flag)
//		DoWindow /K WaveGenParEdit
//	EndIf
//		Edit /K=1 AmpW
//		DoWindow /C WaveGenParEdit
//	Else
//	NVAR NStims = root:WaveGenVars:NStims
//	Make /O/N=(NStims) $("root:WaveGenVars:AmpW")
//	Wave AmpW = $("root:WaveGenVars:AmpW")
//	AmpW = AmpWStart +p*AmpWDiff

//	DoWindow WaveGenParEdit
//	If (V_Flag)
//		DoWindow /K WaveGenParEdit
//	EndIf
//		Edit /K=1 AmpW
//		DoWindow /C WaveGenParEdit
//	EndIf	
//	Break
	
	Case "NStimsAtFixedAmpDiff" :
//	Variable /G root:WaveGenVars:NStimsAtFixedAmpDiff:StartX0
//	Variable /G root:WaveGenVars:NStimsAtFixedAmpDiff:Width
	NVAR NStims	= root:WaveGenVars:NStimsAtFixedAmpDiff:NStims
	NVAR Amp0		= root:WaveGenVars:NStimsAtFixedAmpDiff:Amp0
	NVAR AmpDiff	= root:WaveGenVars:NStimsAtFixedAmpDiff:AmpDiff
	
	Make /O/N		=(NStims) $("root:WaveGenVars:NStimsAtFixedAmpDiff:AmpW")
	Wave AmpW 	= $("root:WaveGenVars:NStimsAtFixedAmpDiff:AmpW")
	AmpW = Amp0 +p*AmpDiff
	
	DoWindow WaveGenParEdit
	If (V_Flag)
		DoWindow /K WaveGenParEdit
	EndIf
	Edit /K=1 AmpW
	DoWindow /C WaveGenParEdit
	Break

EndSwitch	

	
//If (StimTrain)
//	Make /O/N=(NSegments) $("root:WaveGenVars:StartX")
//	Make /O/N=(NSegments) $("root:WaveGenVars:StartY")
//	Make /O/N=(NSegments) $("root:WaveGenVars:EndX")
//	Make /O/N=(NSegments) $("root:WaveGenVars:EndY")
	
//	Wave StartX = $("root:WaveGenVars:StartX")
//	Wave StartY = $("root:WaveGenVars:StartY")
//	Wave EndX = $("root:WaveGenVars:EndX")
//	Wave EndY = $("root:WaveGenVars:EndY")
	
//	StartX 	= StartX0 + p*(1/Freq)
//	StartY 	= Amp
//	EndX 	= StartX0 + p*(1/Freq)+Width
//	EndY 	= Amp
//EndIf

End

Function pt_WaveGenCreate(button1) : ButtonControl
String Button1

// check that each wave has number of points = number of segments

SVAR OutWNameStrPrefix	= root:WaveGenVars:OutWNameStrPrefix
//SVAR OutWNameStrSuffix	= root:WaveGenVars:OutWNameStrSuffix
SVAR WNoteStr				= root:WaveGenVars:WNoteStr
SVAR StimFolder 			= root:WaveGenVars:StimFolder
SVAR StimProtocol 			= root:WaveGenVars:StimProtocol
NVAR DCValue 				= root:WaveGenVars:DCValue
NVAR YGain					= root:WaveGenVars:YGain
NVAR XOffset 				= root:WaveGenVars:XOffset
NVAR XDelta					= root:WaveGenVars:XDelta
NVAR XLength				= root:WaveGenVars:XLength
//NVAR NSegments			= root:WaveGenVars:NSegments
NVAR DisplayOutW			= root:WaveGenVars:DisplayOutW

NVAR SealTestCheckBox		=root:WaveGenVars:SealTestCheckBox
NVAR SealTestStartX			=root:WaveGenVars:SealTestStartX
NVAR SealTestLength		=root:WaveGenVars:SealTestLength
NVAR SealTestVClampAmp	=root:WaveGenVars:SealTestVClampAmp
NVAR SealTestIClampAmp	=root:WaveGenVars:SealTestIClampAmp

Variable x1,y1,x2,y2, NPnts, i, m

If (StringMatch(StimFolder,""))
	DoAlert 0,"Please select a channel first!"
	Return 1
EndIf

If (DisplayOutW)
	DoWindow WaveGenDisplayWin
If (V_Flag)
	DoWindow /K WaveGenDisplayWin
EndIf
	Display	
	DoWindow /C WaveGenDisplayWin	
//	If (FindListItem(OutWNameStr, TraceNameList("WaveGenDisplayWin", ";", 1), ";")==-1)
//	AppendToGraph /L /W =WaveGenDisplayWin w	
//	EndIf
//	AppendToGraph /L /W =WaveGenDisplayWin w	
EndIf

	WNoteStr = ""
	WNoteStr += "Length(s)"			+":"+	Num2Str(XLength)+";"
	WNoteStr += "DCValue"			+":"+	Num2Str(DCValue)+";"
	WNoteStr += "XOffset(s)"			+":"+	Num2Str(XOffset)+";"
	WNoteStr += "XDelta(s)"			+":"+	Num2Str(XDelta)+";"
	WNoteStr += "YGain"				+":"+	Num2Str(YGain)+";"

StrSwitch (StimProtocol) 
//	Case "NStepsAtArbitraryFreq" :
//	Break
	
	Case "NStepsAtFixedFreq" :
	
	
	NVAR NSegments 	= root:WaveGenVars:NStepsAtFixedFreq:NSegments
	

	
//	If ( !(WaveExists(StartXW) &&  WaveExists(StartYW) &&  WaveExists(EndXW) &&  WaveExists(EndXW) ) )
	pt_WaveGenEdit("")	// If the user hasn't pressed Step Values before pressing Create in WaveGen
	Wave StartXW 	= $("root:WaveGenVars:NStepsAtFixedFreq:StartXW")
	Wave StartYW 	= $("root:WaveGenVars:NStepsAtFixedFreq:StartYW")
	Wave MidXW 	= $("root:WaveGenVars:NStepsAtFixedFreq:MidXW")
	Wave MidYW 	= $("root:WaveGenVars:NStepsAtFixedFreq:MidYW")
	Wave EndXW 	= $("root:WaveGenVars:NStepsAtFixedFreq:EndXW")
	Wave EndYW 	= $("root:WaveGenVars:NStepsAtFixedFreq:EndYW")
//	EndIf		

	// check that each wave has number of points = number of segments
	If  ( (NSegments != NumPnts(StartXW))  || (NSegments != NumPnts (StartYW))  || (NSegments != NumPnts (MidXW))  || (NSegments != NumPnts (MidYW))  || (NSegments != NumPnts (EndXW)) || (NSegments != NumPnts (EndYW))  )
	Abort "Number of values in StartXW, StartYW, MidX, MidY,  EndXW, EndYW should be equal to NSegments"	
	Else
	NPnts=round(XLength/XDelta)
	Make /O/N=(NPnts) $(StimFolder+":"+OutWNameStrPrefix)//+OutWNameStrSuffix)
	Wave w = $(StimFolder+":"+OutWNameStrPrefix)//+OutWNameStrSuffix)
	w = 0
	w = w+DCValue
	SetScale /P X, XOffset, XDelta, w

	ControlInfo /W=WaveGenMain SealTestCheckBoxCntrl
	
	
	If   (V_Value==1) 						// add a seal test step
		NVAR /Z EPhys_VClmp = $(StimFolder+":"+"EPhys_VClmp")
		 
		If (NVAR_Exists(EPhys_VClmp))	// variable defining channel mode (VClamp/IClamp Exists)
		
		If (EPhys_VClmp==1)		// VClamp
		w[x2pnt(w, SealTestStartX), x2pnt(w, SealTestStartX+SealTestLength)]=SealTestVClampAmp
		WNoteStr += "SealTestPresent"	+":"+	Num2Str(1)+";"
		WNoteStr += "SealTestAmp(V)"	+":"+	Num2Str(SealTestVClampAmp)+";"
		WNoteStr += "SealTestStartX(s)"	+":"+	Num2Str(SealTestStartX)+";"
		WNoteStr += "SealTestLength(s)"	+":"+	Num2Str(SealTestLength)+";"
		Else					// IClamp
		w[x2pnt(w, SealTestStartX), x2pnt(w, SealTestStartX+SealTestLength)]=SealTestIClampAmp
		WNoteStr += "SealTestPresent"	+":"+	Num2Str(1)+";"
		WNoteStr += "SealTestAmp(A)"	+":"+	Num2Str(SealTestIClampAmp)+";"
		WNoteStr += "SealTestStartX(s)"	+":"+	Num2Str(SealTestStartX)+";"
		WNoteStr += "SealTestLength(s)"	+":"+	Num2Str(SealTestLength)+";"
		EndIf
		
		Else	// No seal test
		WNoteStr += "SealTestPresent"	+":"+	Num2Str(0)+";"
		WNoteStr += "SealTestAmp"		+":"+	Num2Str(0)+";"
		WNoteStr += "SealTestStartX(s)"	+":"+	Num2Str(SealTestStartX)+";"
		WNoteStr += "SealTestLength(s)"	+":"+	Num2Str(SealTestLength)+";"
		EndIf
		
		
	EndIf
	
	WNoteStr += "StimProtocol"		+":"+	StimProtocol+";"
	
	
	For (i=0; i<(NSegments); i+=1)
	x1=StartXW[i]
	y1=StartYW[i]
//	x2=EndXW[i]
//	y2=EndYW[i]
	x2=MidXW[i]
	y2=MidYW[i]
	
	
	If (y1==y2) // DC Step
		w[x2pnt(w, x1), x2pnt(w, x2)]=y1
//		WNoteStr += "StepStart(s)"		+":"+	Num2Str()+";"
//		WNoteStr += "Width(s)"			+":"+	Num2Str()+";"
	//	WNoteStr += "NStims"+":"+Num2Str(1)+";"
//	WNoteStr += "StimAmp"+":"+Num2Str()+";"
	//	WNoteStr += ""+":"+Num2Str()+";"
	//	WNoteStr += ""+":"+Num2Str()+";"
	//	WNoteStr += ""+":"+Num2Str()+";"
	Else	   // Ramp
		m= (y2-y1)/(x2-x1)
		w[x2pnt(w, x1), x2pnt(w, x2)]=m*(pnt2x(w, p)-x1)+y1
	EndIf
	
	x1=MidXW[i]
	y1=MidYW[i]
	x2=EndXW[i]
	y2=EndYW[i]
	
	If (y1==y2) // DC Step
		w[x2pnt(w, x1), x2pnt(w, x2)]=y1
	Else	   // Ramp
		m= (y2-y1)/(x2-x1)
		w[x2pnt(w, x1), x2pnt(w, x2)]=m*(pnt2x(w, p)-x1)+y1
	EndIf
	EndFor
	
	NVAR StartX0		= root:WaveGenVars:NStepsAtFixedFreq:StartX0
	NVAR Freq			= root:WaveGenVars:NStepsAtFixedFreq:Freq
	NVAR NSegments 	= root:WaveGenVars:NStepsAtFixedFreq:NSegments
	NVAR AmpStart 		= root:WaveGenVars:NStepsAtFixedFreq:AmpStart
	NVAR AmpMid 		= root:WaveGenVars:NStepsAtFixedFreq:AmpMid
	NVAR AmpEnd 		= root:WaveGenVars:NStepsAtFixedFreq:AmpEnd
	NVAR Width 		= root:WaveGenVars:NStepsAtFixedFreq:Width
	
	WNoteStr += "StepStart(s)"		+":"+	Num2Str(StartX0)+";"
	WNoteStr += "Freq (Hz)"			+":"+	Num2Str(Freq)+";"
	WNoteStr += "NSteps"			+":"+	Num2Str(NSegments)+";"
	WNoteStr += "Amp. Start."				+":"+	Num2Str(AmpStart)+";"
	WNoteStr += "Amp. Mid"				+":"+	Num2Str(AmpMid)+";"
	WNoteStr += "Amp. End"				+":"+	Num2Str(AmpEnd)+";"
	WNoteStr += "Width"				+":"+	Num2Str(Width)+";"
	
	w*=YGain
	If (DisplayOutW)
	AppendToGraph /L /W =WaveGenDisplayWin w	
	EndIf
	EndIf
	
	Note w, WNoteStr
//	Print Note(w)
//	DoWindow WaveGenParEdit
//	If (V_Flag)
//		DoWindow /K WaveGenParEdit
//	EndIf
	// Necessary to kill waves at this point else next time when the waves are generated (without pressing step 
	// values first, the existing waves will be used). So don't use /Z
//	KillWaves StartXW, StartYW, EndXW, EndYW		
	
	Break
	
//	Case "NStimsAtArbitraryAmps" :
//	Break
	
	Case "NStimsAtFixedAmpDiff" :
	
	
//	If ( !(WaveExists(AmpW) ) )
	pt_WaveGenEdit("")	// If the user hasn't pressed Step Values before pressing Create in WaveGen
	NVAR NStims 	= root:WaveGenVars:NStimsAtFixedAmpDiff:NStims 
	NVAR StartX0 	= root:WaveGenVars:NStimsAtFixedAmpDiff:StartX0
	NVAR Width 	= root:WaveGenVars:NStimsAtFixedAmpDiff:Width
	Wave  AmpW 	= root:WaveGenVars:NStimsAtFixedAmpDiff:AmpW
//	EndIf
	
	// check that each wave has number of points = number of segments
	If  ( (NStims != NumPnts(AmpW)))
	Abort "Number of amplitude values in AmpW should be equal to NStims"
	Else
	NPnts=round(XLength/XDelta)
	String WNoteStrOrig = WNoteStr
	For (i=0; i<NStims; i+=1)
	Make /O/N=(NPnts) $(StimFolder+":"+OutWNameStrPrefix+"_"+pt_PadZeros2IntNumCopy(i, 3))//+OutWNameStrSuffix)
	Wave w = $(StimFolder+":"+OutWNameStrPrefix+"_"+pt_PadZeros2IntNumCopy(i, 3))//+OutWNameStrSuffix)
	w = 0
	w = w+DCValue
	SetScale /P X, XOffset, XDelta, w
	ControlInfo /W=WaveGenMain SealTestCheckBoxCntrl
	If   (V_Value==1) 						// add a seal test step
		NVAR /Z EPhys_VClmp = $(StimFolder+":"+"EPhys_VClmp")
		
		
		If (NVAR_Exists(EPhys_VClmp))	// variable defining channel mode (VClamp/IClamp Exists)
		
		If (EPhys_VClmp==1)		// VClamp
		w[x2pnt(w, SealTestStartX), x2pnt(w, SealTestStartX+SealTestLength)]=SealTestVClampAmp
		WNoteStr += "SealTestPresent"	+":"+	Num2Str(1)+";"
		WNoteStr += "SealTestAmp(V)"	+":"+	Num2Str(SealTestVClampAmp)+";"
		WNoteStr += "SealTestStartX(s)"	+":"+	Num2Str(SealTestStartX)+";"
		WNoteStr += "SealTestLength(s)"	+":"+	Num2Str(SealTestLength)+";"
		Else					// IClamp
		w[x2pnt(w, SealTestStartX), x2pnt(w, SealTestStartX+SealTestLength)]=SealTestIClampAmp
		WNoteStr += "SealTestPresent"	+":"+	Num2Str(1)+";"
		WNoteStr += "SealTestAmp(A)"	+":"+	Num2Str(SealTestIClampAmp)+";"
		WNoteStr += "SealTestStartX(s)"	+":"+	Num2Str(SealTestStartX)+";"
		WNoteStr += "SealTestLength(s)"	+":"+	Num2Str(SealTestLength)+";"
		EndIf
		
		Else	// No seal test
		WNoteStr += "SealTestPresent"	+":"+	Num2Str(0)+";"
		WNoteStr += "SealTestAmp"		+":"+	Num2Str(0)+";"
		WNoteStr += "SealTestStartX(s)"	+":"+	Num2Str(SealTestStartX)+";"
		WNoteStr += "SealTestLength(s)"	+":"+	Num2Str(SealTestLength)+";"
		EndIf
		
		
	EndIf
	
	WNoteStr += "StimProtocol"		+":"+	StimProtocol+";"
	
	w[x2pnt(w, StartX0), x2pnt(w, StartX0+Width)]=AmpW[i]
	
	NVAR Amp0		= root:WaveGenVars:NStimsAtFixedAmpDiff:Amp0
	NVAR AmpDiff	= root:WaveGenVars:NStimsAtFixedAmpDiff:AmpDiff
	
	WNoteStr += "StepStart(s)"		+":"+	Num2Str(StartX0)+";"
	WNoteStr += "Width"				+":"+	Num2Str(Width)+";"
	// Nstims =1 because we are writing a wavenote for each wave separately
	WNoteStr += "NStims"			+":"+	Num2Str(NStims)+";"		
	WNoteStr += "1st Stim Amp."		+":"+	Num2Str(Amp0)+";"
	WNoteStr += "Amp. Diff"			+":"+	Num2Str(AmpDiff)+";"
	WNoteStr += "Stim Amp."			+":"+	Num2Str(AmpW[i])+";"
	
	w*=YGain
	If (DisplayOutW)
	DoWindow WaveGenDisplayWin
	If (V_Flag)
	DoWindow /K WaveGenDisplayWin
	EndIf
	Display	
	DoWindow /C WaveGenDisplayWin	
	AppendToGraph /L /W =WaveGenDisplayWin w	
	EndIf
	Note w, WNoteStr
//	Print Note(w)
	WNoteStr = WNoteStrOrig
	EndFor
	EndIf	
	
	DoWindow WaveGenParEdit
	If (V_Flag)
		DoWindow /K WaveGenParEdit
	EndIf
	
	// Necessary to kill waves at this point else next time when the waves are generated (without pressing step 
	// values first, the existing waves will be used). So don't use /Z
//	KillWaves AmpW	

	
	Break
		
	

	
	EndSwitch

End

Function pt_TraceColor(TraceNum, Red, Green, Blue)
// Use this function to calculate r,g,b values for different traces appended to graph
Variable TraceNum, &Red, &Green, &Blue
String ExcludeColorList =""
Variable NumColors, ColorIsExcluded,i
// to make the colors more distinct skip some colors but of course will need to 
// repeat colors more often
Variable DistinctColorFactor = 2
// Change dbz14 to different colortable for more colors. Use CTabList() to see list
// of colors tables or see via left-clicking on any graph and then pressing teh button
// set as f(z)
ColorTab2Wave dbz14
Wave M_Colors=$(GetDataFolder(1)+"M_Colors")
NumColors = DimSize(M_Colors, 0)
Print NumColors

//TraceNum = mod(TraceNum*DistinctColorFactor, NumColors)
TraceNum = mod(TraceNum, NumColors)

//If color is excluded get next color provided we have not run out of colors
ColorIsExcluded =1
i=0
Do
If ( (ColorIsExcluded ==0) || (i>=(NumColors-1)))
Break
EndIf
For (i=TraceNum; i<NumColors;i+=1)
	If (WhichListItem(Num2Str(i), ExcludeColorList) == -1)	// Color is not in ExcludeColorList
	ColorIsExcluded =0
		Break
	EndIf
EndFor
While (1)

Red		=M_Colors[TraceNum][0]
Green	=M_Colors[TraceNum][1]	
Blue	=M_Colors[TraceNum][2]
Print "(R,G,B)=",Red, Green, Blue
KillWaves /Z M_Colors
End

Function pt_TraceUserColor(TraceNum, Red, Green, Blue)
// Use this function to calculate r,g,b values for different traces appended to graph. Function uses
// the color table provided by user
Variable TraceNum, &Red, &Green, &Blue
Wave UserColorTable = $"root:UserColorTable"
If (!WaveExists(UserColorTable))
	Make /O/N=(6,3) $"root:UserColorTable"
	Wave UserColorTable = $"root:UserColorTable"
	Make /O/N=3 UserColorTableTmp
	
	UserColorTableTmp 	= 	{54998,	0,	0}
	UserColorTable[0,]	=	UserColorTableTmp[q]
	
	UserColorTableTmp 	= 	{0,	0,	63222}
	UserColorTable[1,]	=	UserColorTableTmp[q]
	
	UserColorTableTmp 	= 	{0,	37008,	0}
	UserColorTable[2,]	=	UserColorTableTmp[q]
	
	UserColorTableTmp 	= 	{39321,	21845,	51657}
	UserColorTable[3,]	=	UserColorTableTmp[q]
	
	UserColorTableTmp 	= 	{20560,	20560,	20560}
	UserColorTable[4,]	=	UserColorTableTmp[q]
	
	UserColorTableTmp 	= 	{21074,	8995,	21074}
	UserColorTable[5,]	=	UserColorTableTmp[q]
EndIf
Variable NumColors, ColorIsExcluded,i

NumColors = DimSize(UserColorTable,0)

If (TraceNum > (NumColors-1))
	Print "Colors of traces may not be distinct. Add more colors to root:UserColorTable"
EndIf

TraceNum = mod(TraceNum, NumColors)	// Repeat colors if more traces than colors

Red		=UserColorTable[TraceNum][0]
Green	=UserColorTable[TraceNum][1]	
Blue	=UserColorTable[TraceNum][2]
//Print "(R,G,B)=",Red, Green, Blue
//KillWaves /Z M_Colors
KillWaves /Z UserColorTableTmp
End

Function pt_Test()
Variable Red, Green, Blue
pt_TraceUserColor(6, Red, Green, Blue)
End
//----
Function pt_CopyImage(ButtonVarName) :  ButtonControl
String ButtonVarName
String DestDataFldr = getuserdata("",ButtonVarName,"")
//String OldDf, FileNameNoExt, ImageNameNoExt
//OldDf=GetDataFolder(1)

String TopGraphImages = ImageNameList("",";")
String theImage = StringFromList(0, TopGraphImages)
Wave w = ImageNameToWaveRef("", theImage )
Duplicate /O w, $(DestDataFldr+":CurrentImage")
//If (!StringMatch(DestDataFldr, ""))
//	NewDataFolder /O/S $DestDataFldr
//	DataFolderExists
//	SetDataFolder DestDataFldr
//EndIf
//ImageLoad /T=any/O/Z
// Sometimes ImageNames can be names that are not allowed as waves (eg. all numeric)
// hence duplicating to a generic image name

//ImageNameNoExt = ParseFilePath(3,S_FileName,":",0,0)
//Duplicate /O $S_FileName, $ImageNameNoExt
//KillWaves /Z $S_FileName
//NewImage /K=1  $ImageNameNoExt
//Duplicate /O $S_FileName, CurrentImage
//KillWaves /Z $S_FileName
DoWindow  CurrentImageDisplayWin
If (V_Flag)
DoWindow  /K CurrentImageDisplayWin
EndIf

NewImage /K=1  $(DestDataFldr+":CurrentImage")
DoWindow /C CurrentImageDisplayWin
pt_ScaleOffset("",0,"C")
Print "Copied and centered the top image"
//If (V_Flag)
//Print "Copied image", theImage, "from top graph to", DestDataFldr
//Else
//Print "The image could not be copied!"
//EndIf
//SetDataFolder OldDf
End
//----
Function pt_ImageLoad(ButtonVarName) :  ButtonControl
String ButtonVarName
String DestDataFldr = getuserdata("",ButtonVarName,"")
String OldDf, FileNameNoExt, ImageNameNoExt
OldDf=GetDataFolder(1)
If (!StringMatch(DestDataFldr, ""))
	NewDataFolder /O/S $DestDataFldr
//	DataFolderExists
//	SetDataFolder DestDataFldr
EndIf
ImageLoad /T=any/O/Z
// Sometimes ImageNames can be names that are not allowed as waves (eg. all numeric)
// hence duplicating to a generic image name

//ImageNameNoExt = ParseFilePath(3,S_FileName,":",0,0)
//Duplicate /O $S_FileName, $ImageNameNoExt
//KillWaves /Z $S_FileName
//NewImage /K=1  $ImageNameNoExt
Duplicate /O $S_FileName, CurrentImage
KillWaves /Z $S_FileName
DoWindow  CurrentImageDisplayWin
If (V_Flag)
DoWindow  /K CurrentImageDisplayWin
EndIf
NewImage /K=1  CurrentImage
DoWindow /C CurrentImageDisplayWin
pt_ScaleOffset("",0,"C")
If (V_Flag)
Print "Loaded and centered image", S_FileName, "from", S_Path, "into", DestDataFldr
Else
Print "The image could not be loaded!"
EndIf
SetDataFolder OldDf
End

Function pt_RespnsAmp()
// We need a function for online and offline analysis to measure response amplitude for a trace.
// The window in which to search for the response will be either specified based on the stimulus to 
// presynaptic cell or a window starting at the peak of the action potential in the pre-synaptic cell


// A function will load the required waves into the appropriate data folder
// The user may choose to average N waves after every M waves.
// The user will specify the window

End

Function pt_CalSynResp()
// Based on pt_CalPeak()
// Added TimesSD mainly for use with real time analysis during data acq on 04/20/11
// This is always the latest version
// From PraveensIgorUtilities on 04/19/11
// inserted the smoothing option. default option is binomial smoothing. 9th sept. 2007
// look for par waves in local folder first 	07/23/2007
//// in pt_AnalWInFldrs2("pt_CalPeak") changed the loading of par wave from local folder (if exists) so that renaming of DataWaveMatchStr can be
// seen inside the function.	 07/23/2007
// also check if ParNamesW is present		07/23/2007
//PrintAnalPar("pt_CalPeak")    07/18/2007
// in pt_AnalWInFldrs2("pt_CalPeak") applied If ( StrLen(AnalParW[11])*StrLen(AnalParW[12])!=0)
// before loading FIWNamesW, etc. 07/18/2007
// also killing WNameTemp at the end    07/18/2007
//	removed ":". should be included with data fldr		06/13/2007


String WNameStr, WList, DataWaveMatchStr, DataFldrStr, BaseNameStr, PkWinStart0List

Variable PkWinStart0, PkWinDel, BLDel, AvgWin, ThreshVal, SmthPnts, PkPolr, NStepsPerStim, StepsPerStimDelT, NStims


Variable i, Numwaves, j, X0,PkWinStart, k

String LastUpdatedMM_DD_YYYY=" 04/26/2011"

Print "*********************************************************"
Print "pt_CalSynResp last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW		=	$pt_GetParWave("pt_CalSynResp", "ParNamesW")		// check in local folder first 07/23/2007
Wave /T AnalParW			=	$pt_GetParWave("pt_CalSynResp", "ParW")

If (WaveExists(AnalParW) && WaveExists(AnalParNamesW)==0)			// included AnalParNamesW 07/23/2007
	Abort	"Cudn't find the parameter wave pt_CalSynRespParW!!!"
EndIf

DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
BaseNameStr			=	AnalParW[2]
PkWinStart0List			=	AnalParW[3]
PkWinDel				=	Str2Num(AnalParW[4]);
BLDel			 		= 	Str2Num(AnalParW[5]);
AvgWin					= 	Str2Num(AnalParW[6]);
ThreshVal				= 	Str2Num(AnalParW[7]);
NStepsPerStim			= 	Str2Num(AnalParW[8]);
StepsPerStimDelT		= 	Str2Num(AnalParW[9]);
SmthPnts				= 	Str2Num(AnalParW[10]);
PkPolr					=	Str2Num(AnalParW[11]);



PrintAnalPar("pt_CalSynResp")	// 07/18/2007


NStims = ItemsInList(PkWinStart0List, ";")
Make /O/N=(NStims), $(BaseNameStr+"PkWinStart0W")
Wave PkWinStart0W=$(BaseNameStr+"PkWinStart0W")
PkWinStart0W = Str2Num(StringFromList(p,PkWinStart0List, ";")	)

For (k=0;k<NStims; k+=1)		// Stim #

Make /O/N=0 	$(BaseNameStr+Num2Str(k)+"_"+"BLX")
Make /O/N=0 	$(BaseNameStr+Num2Str(k)+"_"+"BLY")
Wave BLX		= $(BaseNameStr+Num2Str(k)+"_"+"BLX")
Wave BLY		= $(BaseNameStr+Num2Str(k)+"_"+"BLY")

EndFor

Make /O/N=1 	$(BaseNameStr+"BLXTemp")
Make /O/N=1 	$(BaseNameStr+"BLYTemp")
Wave BLXTemp	= $(BaseNameStr+"BLXTemp")
Wave BLYTemp	= $(BaseNameStr+"BLYTemp")

For (k=0;k<NStims; k+=1)		// Stim #
For (j=0;j<NStepsPerStim; j+=1)	// Step # (Multiple steps in a stim)

Make /O/N=0 	$(BaseNameStr+Num2Str(k)+"_"+Num2Str(j)+"PkX")
Make /O/N=0 	$(BaseNameStr+Num2Str(k)+"_"+Num2Str(j)+"AbsPkY")
Make /O/N=0 	$(BaseNameStr+Num2Str(k)+"_"+Num2Str(j)+"RelPkY")
Make /O/N=0 	$(BaseNameStr+Num2Str(k)+"_"+Num2Str(j)+"Boln")		

EndFor
EndFor

Make /O/N=1 		$(BaseNameStr+"PkXTemp")
Make /O/N=1 		$(BaseNameStr+"AbsPkYTemp")
Make /O/N=1 		$(BaseNameStr+"RelPkYTemp")
Make /O/N=1 		$(BaseNameStr+"BolnTemp")		
Wave PkXTemp		= $(BaseNameStr+"PkXTemp")
Wave AbsPkYTemp	= $(BaseNameStr+"AbsPkYTemp")
Wave RelPkYTemp	= $(BaseNameStr+"RelPkYTemp")
Wave BolnTemp		= $(BaseNameStr+"BolnTemp")

WList=pt_SortWavesInFolder(DataWaveMatchStr, GetDataFolder(1)+DataFldrStr)
Numwaves=ItemsInList(WList, ";")

Print "Calculating synaptic response for waves, N =", Numwaves, WList


For (i=0; i<NumWaves; i+=1)
	WNameStr=StringFromList(i, WList, ";")


	Wave w= $(GetDataFolder(1)+DataFldrStr+WNameStr)
//	x0=DimOffset(w,0); dx=DimDelta(w,0)
//	LambdaW=x0+(NumPnts(w))*dx
//	display w
	For (k=0;k<NStims; k+=1)		// Stim #
	PkWinStart0 = PkWinStart0W[k]
	Wavestats /Q /R=(PkWinStart0-BLDel, PkWinStart0) w	// BL before 1st response
	BLYTemp[0]=V_Avg
	BLXTemp[0]=PkWinStart0-0.5*BLDel
	
	Duplicate /O w, w_sm							// inserted the smoothing option. default option is binomial smoothing. 9th sept. 2007
	Smooth SmthPnts, w_sm
	
	For (j=0;j<NStepsPerStim; j+=1)
	PkWinStart = PkWinStart0+j*StepsPerStimDelT
	
	Wavestats /Q /R=(PkWinStart, PkWinStart+PkWinDel) w_sm
	PkXTemp[0]	= (PkPolr==1) ? V_MaxLoc : V_MinLoc
//	wXTemp[0]	+=i*LambdaW
	
	If (PkPolr==1)
	WaveStats /Q/R=(V_MaxLoc-0.5*AvgWin, V_MaxLoc+0.5*AvgWin) w
	Else
	WaveStats /Q/R=(V_MinLoc-0.5*AvgWin, V_MinLoc+0.5*AvgWin) w
	EndIf

	AbsPkYTemp[0] = V_Avg
	RelPkYTemp[0]	-= BLXTemp[0]
	
	BolnTemp = (abs(RelPkYTemp[0]) >= abs(ThreshVal) ) ? 1 : 0
	
	Wave PkX		= $(BaseNameStr+Num2Str(k)+"_"+Num2Str(j)+"PkX")
	Wave AbsPkY	= $(BaseNameStr+Num2Str(k)+"_"+Num2Str(j)+"AbsPkY")
	Wave RelPkY	= $(BaseNameStr+Num2Str(k)+"_"+Num2Str(j)+"RelPkY")
	Wave Boln		= $(BaseNameStr+Num2Str(k)+"_"+Num2Str(j)+"Boln")
	
	Concatenate /NP {BLXTemp}			, BLX
	Concatenate /NP {BLYTemp}			, BLY
	Concatenate /NP {PkXTemp}			, PkX
	Concatenate /NP {AbsPkYTemp}		, AbsPkY
	Concatenate /NP {RelPkYTemp}		, RelPkY
	Concatenate /NP {BolnTemp}			, Boln
	
	EndFor
	EndFor
	KillWaves /Z w_sm
		
EndFor		
Killwaves /Z BLXTemp, BLYTemp, PkXTemp, AbsPkYTemp, RelPkYTemp, BolnTemp// 07/18/2007
End

Function pt_EditFuncPars(FuncName)
String FuncName
String TableName=FuncName+"_Edit"

DoWindow /F $TableName
If	(!V_Flag)
	Edit /K=1/N=$TableName
EndIf
If (WaveExists($("root:AnalyzeDataVars:"+FuncName+"ParNamesW")) && WaveExists($("root:AnalyzeDataVars:"+FuncName+"ParW")))
	AppendToTable  $("root:AnalyzeDataVars:"+FuncName+"ParNamesW"), $("root:AnalyzeDataVars:"+FuncName+"ParW")
	//Edit /N= $TableName $("root:FuncParWaves:"+FuncName+"ParNamesW"), $("root:FuncParWaves:"+FuncName+"ParW")
Else 
	Make /T/N=0 $("root:AnalyzeDataVars:"+FuncName+"ParNamesW"), $("root:AnalyzeDataVars:"+FuncName+"ParW")
	AppendToTable  $("root:AnalyzeDataVars:"+FuncName+"ParNamesW"), $("root:AnalyzeDataVars:"+FuncName+"ParW")
//	Edit /N= $TableName $("root:FuncParWaves:"+FuncName+"ParNamesW"), $("root:FuncParWaves:"+FuncName+"ParW")
EndIf

End

Function pt_TileWindows()

Execute "TileWindows /C/O=1"

End

Function pt_KillGraphsAndTables()

// SealTest windows
DoWindow /K EPhysRsVDisplayWin
DoWindow /K EPhysRInVDisplayWin
DoWindow /K EPhysImVDisplayWin
DoWindow /K EPhysVmVDisplayWin
DoWindow /K pt_RsRinCmVmVclamp2Display
//DoWindow /K pt_RsRinCmVmIclamp2Display

//ChannelDisplay windows
DoWindow /K EPhysDisplayWin
DoWindow /K ScanMirrorDisplayWin
DoWindow /K LaserShutterDisplayWin
DoWindow /K TemperatureDisplayWin
DoWindow /K LaserPowerDisplayWin
DoWindow /K LaserVoltageDisplayWin

//TrigGenChannel window
DoWindow /K TrigGenChEdit

//StimOnClickParEdit window
DoWindow /K StimOnClickParEdit

//WaveGen window
DoWindow /K WaveGenDisplayWin
DoWindow /K WaveGenParEdit

End

Function pt_AnalyzeData() : Panel
// this object will perform several different types of analysis, primarily for real-time analysis during
// data acquisition

//If (!(DataFolderExists(root:WaveGenVars)))
//EndIf
NewDataFolder /O root:AnalyzeDataVars

Variable /G root:AnalyzeDataVars:EPhysSealTestVarVal
Variable /G root:AnalyzeDataVars:EPhysFICurveVarVal
Variable /G root:AnalyzeDataVars:AvgLastNWavesVarVal
Variable /G root:AnalyzeDataVars:EPhysSynRespVarVal
Variable /G root:AnalyzeDataVars:EPhysSRShtrVarVal	// Read from Shutter
Variable /G root:AnalyzeDataVars:EPhysSRRstrVarVal	// Restore orig
Variable /G root:AnalyzeDataVars:EPhysSROWRespVarVal
Variable /G root:AnalyzeDataVars:EPhysSRXYOptScVarVal
Variable /G root:AnalyzeDataVars:EPhysSRAvgReps
Variable /G root:AnalyzeDataVars:AvgLastNWavesNum = 10
String    /G root:AnalyzeDataVars:EPhysSRPrevMode = ""
String 	/G $"root:AnalyzeDataVars:AnalParFolder"=StringFromList(0, pt_TrigGenDevsList(""), ";")	// 1st channel
Variable /G root:AnalyzeDataVars:EPhysPairedRecVarVal=0
String /G root:AnalyzeDataVars:CursorDiffGraphList = ""

NVAR AvgLastNWavesNum = root:AnalyzeDataVars:AvgLastNWavesNum
SVAR CursorDiffGraphList = root:AnalyzeDataVars:CursorDiffGraphList

pt_EPhysSealTestParsCreate()
pt_EPhysSpikeAnalParsCreate()
//pt_AvgLastNWavesParsCreate()
pt_CalSynRespParsCreate()
pt_LoadDataNthWaveParsCreate()
pt_VidMkMovParsCreate()
//pt_PairedRecDispRngParsEdit()


	DoWindow AnalyzeDataMain
	If (V_Flag==1)
		DoWindow /K AnalyzeDataMain
	EndIf
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=2/W=(525,75,800,350)
	DoWindow /C AnalyzeDataMain
//	SetDrawEnv fsize= 12,textrgb= (0,9472,39168)

	CheckBox EPhysSealTestVarName,pos={5,8},size={16,14},title="SealTest",value= 0
	CheckBox EPhysSealTestVarName, variable = root:AnalyzeDataVars:EPhysSealTestVarVal
	Button       EPhysSealTestButton0VarName,pos={95,5},size={75,20},title="Edit VClamp"
//	Button       EPhysSealTestButton0VarName,proc = pt_EPhysSealTestEdit, userdata="pt_CalRsRinCmVmVClamp"
	Button       EPhysSealTestButton0VarName,proc = pt_CallEditFuncPars, userdata="pt_CalRsRinCmVmVClamp"

	Button       EPhysSealTestButton1VarName,pos={185,5},size={75,20},title="Edit IClamp"
//	Button       EPhysSealTestButton1VarName,proc = pt_EPhysSealTestEdit, userdata="pt_CalRsRinCmVmIClamp"
	Button       EPhysSealTestButton1VarName,proc = pt_CallEditFuncPars, userdata="pt_CalRsRinCmVmIClamp"
	
	CheckBox EPhysFICurveVarName,pos={5,28},size={16,14},title="FICurve",value= 0
	CheckBox EPhysFICurveVarName, variable = root:AnalyzeDataVars:EPhysFICurveVarVal
	Button       EPhysFICurveButton2VarName,pos={95,25},size={75,20},title="Edit FICurve"
	Button       EPhysFICurveButton2VarName,proc = pt_CallEditFuncPars, userdata="pt_SpikeAnal"
//	Button       EPhysFICurveButton1VarName,pos={185,5},size={75,20},title="Edit IClamp"
//	Button       EPhysFICurveButton1VarName,proc = pt_EPhysFICurveEdit, userdata="pt_CalRsRinCmVmIClamp"

	Button       AvgLastNWavesButton1VarName,pos={5,48},size={125,20},title="Average last N Waves"
//	Button       EPhysSynRespButton3VarName,proc = pt_CallEditFuncPars, userdata="pt_CalSynResp"
	Button       AvgLastNWavesButton1VarName,proc = pt_AvgLastNWaves, userdata="pt_AvgLastNWaves"
	
//	Button       AvgLastNWavesButton2VarName,pos={185,48},size={75,20},title="Edit Average"
//	Button       AvgLastNWavesButton2VarName,proc = pt_CallEditFuncPars, userdata="pt_AvgLastNWaves"

	SetVariable AvgLastNWavesVarName,pos={183,48},size={80,16},title="N = "
	SetVariable AvgLastNWavesVarName,value= AvgLastNWavesNum, limits={0,inf,1}
	
//	CheckBox  AvgLastNWavesVarName,pos={5,48},size={16,14},title="Average",value= 0
//	CheckBox AvgLastNWavesVarName, variable = root:AnalyzeDataVars:AvgLastNWavesVarVal


//Temporarily hiding some options below because they are not fully implemented yet 10/05/11 Praveen//
// Indicated by //Temporarily hidden
	
 //Temporarily hidden	CheckBox EPhysSynRespVarName,pos={5,98},size={16,14},title="Synaptic Response",value= 0
 //Temporarily hidden	CheckBox EPhysSynRespVarName, variable = root:AnalyzeDataVars:EPhysSynRespVarVal//, proc = pt_SynRespPanel
	
 //Temporarily hidden	Button       EPhysSynRespButton3VarName,pos={185,100},size={75,20},title="Edit SynResp"
//	Button       EPhysSynRespButton3VarName,proc = pt_CallEditFuncPars, userdata="pt_CalSynResp"
 //Temporarily hidden	Button       EPhysSynRespButton3VarName,proc = pt_SynRespParEdit, userdata="pt_CalSynResp"
	
 //Temporarily hidden	PopupMenu AllDataFolderList,pos={10,70},size={200,18},title="Channels"	
 //Temporarily hidden	PopupMenu AllDataFolderList, mode = 1, value=pt_TrigGenDevsList("AllDataFolderList"), proc = pt_AnalParFolderSet
	
 //Temporarily hidden	SetDrawLayer UserBack
 //Temporarily hidden	SetDrawEnv fsize= 11
 //Temporarily hidden	DrawText 5,142,"Update pars from"
	
 //Temporarily hidden	CheckBox EPhysSRShtr,pos={95,128},size={16,14},title="Shutter",value= 0
 //Temporarily hidden	CheckBox EPhysSRShtr, variable = root:AnalyzeDataVars:EPhysSRShtrVarVal, proc = pt_SynRespUpdtPar
	
 //Temporarily hidden	CheckBox EPhysSRRstr,pos={182,128},size={16,14},title="Restore",value= 0
 //Temporarily hidden	CheckBox EPhysSRRstr, variable = root:AnalyzeDataVars:EPhysSRRstrVarVal, proc = pt_SynRespUpdtPar
	
 //Temporarily hidden	Button  VidMkMovVarName,pos={95,220},size={85,20},title="Edit Movie Pars"
 //Temporarily hidden	Button  VidMkMovVarName,proc = pt_CallEditFuncPars, userdata="pt_VidMkMov"
	
 //Temporarily hidden	SetDrawLayer UserBack
 //Temporarily hidden	SetDrawEnv fsize= 11
 //Temporarily hidden	DrawText 5,173,"Last saved response"
// If 	Edit/ Overwrite is checked the calculated synaptic response is overwritten on the last saved response.
// Supposingly the user does a grid scan and gets the map of synaptic responses. The user may then want to go to individual
// positions and check individual synapses but not overwrite the previous ones.

 //Temporarily hidden	CheckBox EPhysSROWResp,pos={140,158},size={16,14},title="Edit/ Overwrite?",value= 0
 //Temporarily hidden	CheckBox EPhysSROWResp, variable = root:AnalyzeDataVars:EPhysSROWRespVarVal, proc = pt_SynRespEditSaved
// If it's an optical XY scan, and we are calculating synaptic response then presence or absence of it is shown on XY grid	
 //Temporarily hidden	CheckBox EPhysSRXYOptSc,pos={5,188},size={16,14},title="XY Optical Scan?",value= 0
 //Temporarily hidden	CheckBox EPhysSRXYOptSc, variable = root:AnalyzeDataVars:EPhysSRXYOptScVarVal, proc = pt_SRXYOptScParEdit
// If Avg. Reps is checked, then before calculating synaptic response, the waveform is averaged with the previous repeats.	
 //Temporarily hidden	CheckBox EPhysSRAvgReps,pos={140,188},size={16,14},title="Avg. Reps?",value= 0
 //Temporarily hidden	CheckBox EPhysSRAvgReps, variable = root:AnalyzeDataVars:EPhysSRAvgReps//, proc = pt_SRXYOptScParEdit
	
	// 
	CheckBox EPhysPairedRecVarName,pos={5,78},size={16,14},title="Paired Rec.",value= 0
	CheckBox EPhysPairedRecVarName, variable = root:AnalyzeDataVars:EPhysPairedRecVarVal
	
	Button       EPhysPairedRecDispRngVarName,pos={95,73},size={75,20},title="Display Range"
	Button       EPhysPairedRecDispRngVarName,proc = pt_PairedRecDispRng, userdata="pt_PairedRecDispRng"
	
	CursorDiffGraphList = pt_ReturnGraphWinList()
	SetVariable	CursorDiffGraphList, pos={5, 100}, size={200,200}, title ="CursorDiff"
	SetVariable	CursorDiffGraphList, value=CursorDiffGraphList
	
	
End

Function /s pt_ReturnGraphWinList()
// return list of graphwin names
Return WinList("*",";","Win:1") // choose graph windows
End

Function pt_SRXYOptScParEdit(CheckBoxVarName, CheckBoxVarVal)  : CheckBoxControl
// Based on  pt_MouseXYLocStimOnClickParEdit
// If it's an optical XY scan, and we are calculating synaptic response then presence or absence of it is shown on XY grid
String CheckBoxVarName
Variable CheckBoxVarVal
DoWindow SRXYOptScParEdit
If (V_Flag)
DoWindow /K SRXYOptScParEdit
EndIf
Edit /K=1
DoWindow /C SRXYOptScParEdit
Wave /T SRXYOptScParNamesW 	= root:AnalyzeDataVars:SRXYOptScParNamesW
Wave /T SRXYOptScParW 		= root:AnalyzeDataVars:SRXYOptScParW

If (WaveExists(SRXYOptScParNamesW) && WaveExists(SRXYOptScParW))
AppendToTable /W=SRXYOptScParEdit  SRXYOptScParNamesW, SRXYOptScParW
Else
Make /T /O/N=3 $"root:AnalyzeDataVars:SRXYOptScParNamesW", $"root:AnalyzeDataVars:SRXYOptScParW"
Wave /T SRXYOptScParNamesW = root:AnalyzeDataVars:SRXYOptScParNamesW
Wave /T SRXYOptScParW = root:AnalyzeDataVars:SRXYOptScParW
// Ultimately the program should figure out how many channels are there for EPhys, ScanMirrors, etc.
SRXYOptScParNamesW[0]	= "XWName"
SRXYOptScParNamesW[1]	= "YWName"
SRXYOptScParNamesW[2]	= "AvgRepeats"

SRXYOptScParW[0]	= "root:ScanMirrorVars1:OutXWaveNamesW"
SRXYOptScParW[1]	= "root:ScanMirrorVars1:OutYWaveNamesW"
SRXYOptScParW[2]	= "1"

AppendToTable /W=SRXYOptScParEdit  SRXYOptScParNamesW, SRXYOptScParW
EndIf
//SetDataFolder OldDF
End
//Function pt_EPhysSealTestEdit(ButtonVarName) :  ButtonControl
//String ButtonVarName
//String FuncName = getuserdata("",ButtonVarName,"")
//pt_EditFuncPars(FuncName)
//End
//-----------

//-----------
Function pt_SynRespEditSaved(CheckBoxVarName, CheckBoxVarVal)  : CheckBoxControl
//Function pt_EPhysModeSelect(CheckBoxVarName)  : CheckBoxControl
String CheckBoxVarName
Variable CheckBoxVarVal

DoWindow /F SavedSynRespEdit
If	(V_Flag)
	DoWindow /K SavedSynRespEdit
EndIf

//+++++++++
// Based on pt_TrigGenStimulusPattern


String SRBolnSavedVWName
Variable i, N
Wave /T IOWName			=root:TrigGenVars:IOWName
Wave /T IODevFldrCopy		=root:TrigGenVars:IODevFldrCopy

Edit /K=1
DoWindow /C SavedSynRespEdit

If (WaveExists(IOWName) && WaveExists(IODevFldrCopy))
N = NumPnts(IOWName)
//OldDf=GetDataFolder(1)
//SetDataFolder root:TrigGenVars
For (i=0; i<N;i+=1)

	If (StringMatch(IOWName[i], "*EPhysVars*In"))
	sscanf IODevFldrCopy[i]+"InSR"+Num2Str(0)+"BolnVSaved", "root:%s", SRBolnSavedVWName
	Wave SRBolnSavedVW = $(IODevFldrCopy[i]+":"+SRBolnSavedVWName)
	If (WaveExists(SRBolnSavedVW))
	AppendToTable SRBolnSavedVW
	Else
	Make /O/N=0 $(IODevFldrCopy[i]+":"+SRBolnSavedVWName)
	AppendToTable $(IODevFldrCopy[i]+":"+SRBolnSavedVWName)
	EndIf
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



//+++++++++

//If (WaveExists($("root:AnalyzeDataVars:"+FuncName+"ParNamesW")) && WaveExists($("root:AnalyzeDataVars:"+FuncName+"ParW")))
//	AppendToTable  $("root:AnalyzeDataVars:"+FuncName+"ParNamesW"), $("root:AnalyzeDataVars:"+FuncName+"ParW")
//	//Edit /N= $TableName $("root:FuncParWaves:"+FuncName+"ParNamesW"), $("root:FuncParWaves:"+FuncName+"ParW")
//Else 
//	Make /T/N=0 $("root:AnalyzeDataVars:"+FuncName+"ParNamesW"), $("root:AnalyzeDataVars:"+FuncName+"ParW")
//	AppendToTable  $("root:AnalyzeDataVars:"+FuncName+"ParNamesW"), $("root:AnalyzeDataVars:"+FuncName+"ParW")
//	Edit /N= $TableName $("root:FuncParWaves:"+FuncName+"ParNamesW"), $("root:FuncParWaves:"+FuncName+"ParW")
//EndIf

End
//-----------
Function pt_SynRespUpdtPar(CheckBoxVarName, CheckBoxVarVal)  : CheckBoxControl
//Function pt_EPhysModeSelect(CheckBoxVarName)  : CheckBoxControl
String CheckBoxVarName
Variable CheckBoxVarVal

//NVAR EPhysInstNum			=root:EPhysInstNum
//If (!StringMatch(button0, "TrigGen"))
//	EPhysInstNum			= Str2Num(getuserdata("",CheckBoxVarName,""))	// convert Instance Num String to Num
//EndIf
//String FldrName 				= "root:EPhysVars"+Num2Str(EPhysInstNum)
//String EPhysPanelName 	= "EPhysMain"+Num2Str(EPhysInstNum)


/////////////////////////////////////////////////////////////////////////////
//NVAR        DebugMode = $FldrName+":DebugMode"
//If (DebugMode)
//Print "*************************************"
//Print "Debug Mode"
// Information to be printed out while debugging
//Print "FolderName =", FldrName
//Print "*************************************"
//EndIf
/////////////////////////////////////////////////////////////////////////////

// This function updates the checkboxes for Synaptic Response AnalyzeDataMain panel such that only one of the two checkboxes 
// Shtr (shutter) or Rstr (Restore) are selected and also updates the par wave accordingly

SVAR EPhysSRPrevMode			=$"root:AnalyzeDataVars:EPhysSRPrevMode"
NVAR EPhysSRShtrVarVal 		= $"root:AnalyzeDataVars:EPhysSRShtrVarVal"
NVAR EPhysSRRstrVarVal 		= $"root:AnalyzeDataVars:EPhysSRRstrVarVal"

Variable i
String WNoteStr = ""

SVAR AnalParFolder = root:AnalyzeDataVars:AnalParFolder

If (StringMatch(AnalParFolder,""))
	DoAlert 0,"Please select a channel first!"
	Return 1
EndIf

//Wave /T AnalParW			=	$pt_GetParWave("pt_CalSynResp", "ParW")
Wave /T AnalParW			=	$AnalParFolder+":pt_CalSynRespParW"




StrSwitch (CheckBoxVarName)

	case "EPhysSRShtr":
		EPhysSRShtrVarVal	= 1
		EPhysSRRstrVarVal  = 0			
		If (StringMatch(CheckBoxVarName, EPhysSRPrevMode) ==0)	// don't do anything if the box that was checked before is checked again
		// panel is initialized with both modes unchecked
		Wave /T OutWaveNamesW=$"root:LaserShutterVars1:OutWaveNamesW"
		If (WaveExists(OutWaveNamesW))
		
		If (WaveExists($"root:LaserShutterVars1:"+OutWaveNamesW[0]))
		
		WNoteStr = Note($"root:LaserShutterVars1:"+OutWaveNamesW[0])
		
//		String /G root:AnalyzeDataVars:OldSRPkWinStart0		=AnalParW[3]	
//		String /G root:AnalyzeDataVars:OldSRNReps			=AnalParW[8]	
//		String /G root:AnalyzeDataVars:OldSRRepDelT			=AnalParW[9]
		String /G $AnalParFolder+":OldSRPkWinStart0"		=AnalParW[3]	
		String /G $AnalParFolder+":OldSRNReps"			=AnalParW[8]	
		String /G $AnalParFolder+":OldSRRepDelT"			=AnalParW[9]	

		AnalParW[3]		= StringByKey("StepStart(s)",WNoteStr)	//PkWinStart0
		AnalParW[8]		= StringByKey("NSteps",WNoteStr)	// NReps
		AnalParW[9]		= Num2Str(1/Str2Num(StringByKey("Freq (Hz)",WNoteStr)))	// RepDelT
		EPhysSRPrevMode = CheckBoxVarName
		Else
		DoAlert 0, "Wave specified in root:LaserShutterVars1:OutWaveNamesW[0] doesn't exist! Parameters not changed."
		EndIf
		
		
		Else
		DoAlert 0, "root:LaserShutterVars1:OutWaveNamesW doesn't exist! Parameters not changed."
		EndIf
		
		EndIf
	break
	
	case "EPhysSRRstr":
		EPhysSRShtrVarVal	= 0
		EPhysSRRstrVarVal  = 1						
		If (StringMatch(CheckBoxVarName, EPhysSRPrevMode) ==0)	// don't do anything if the box that was checked before is checked again
//		SVAR OldSRPkWinStart0	= root:AnalyzeDataVars:OldSRPkWinStart0
//		SVAR OldSRNReps 		= root:AnalyzeDataVars:OldSRNReps
//		SVAR OldSRRepDelT	 	= root:AnalyzeDataVars:OldSRRepDelT
		SVAR OldSRPkWinStart0	= $AnalParFolder+":OldSRPkWinStart0"
		SVAR OldSRNReps 		= $AnalParFolder+":OldSRNReps"
		SVAR OldSRRepDelT	 	= $AnalParFolder+":OldSRRepDelT"
		If (SVAR_Exists(OldSRPkWinStart0) && SVAR_Exists(OldSRNReps)	&& SVAR_Exists(OldSRRepDelT)		)
		AnalParW[3]		= OldSRPkWinStart0	//PkWinStart0
		AnalParW[8]		= OldSRNReps 		// NReps
		AnalParW[9]		= OldSRRepDelT		// RepDelT
		Else
		AnalParW[3]		= ""		//PkWinStart0
		AnalParW[8]		= "" 	// NReps
		AnalParW[9]		= ""		// RepDelT
		EndIf
		// panel is initialized with both modes unchecked
		EPhysSRPrevMode = CheckBoxVarName
		EndIf
	break
	
EndSwitch	
// No need setting the values of checkbox var name
//Checkbox EPhysVClmp,	value = EPhys_VClmp == 1
//Checkbox EPhysIClmp, 	value = EPhys_IClmp == 1

//EPhys_VClmp = (VClmp1IClmp2 == 1) ? 1 : 0
//EPhys_IClmp  = (VClmp1IClmp2 == 2) ? 1 : 0


End
//-----------

Function pt_SynRespPanel()

//NVAR SRBLStart = root:AnalyzeDataVars:SRBLStart
NVAR SRBLDel 		= root:AnalyzeDataVars:SynResp:SRBLDel
NVAR SRPkWinStart = root:AnalyzeDataVars:SynResp:SRPkWinStart
NVAR SRPkWinDel 	= root:AnalyzeDataVars:SynResp:SRPkWinDel
NVAR SRSDThresh 	= root:AnalyzeDataVars:SynResp:SRSDThresh
NVAR SRNumReps	= root:AnalyzeDataVars:SynResp:SRNumReps
NVAR SRRepDelT 	= root:AnalyzeDataVars:SynResp:SRRepDelT
NVAR SRPkPolr 		= root:AnalyzeDataVars:SynResp:SRPkPolr
NVAR SRAvgWin 	= root:AnalyzeDataVars:SynResp:SRAvgWin

DoWindow SynRespPanel
	If (V_Flag==1)
		DoWindow /F SynRespPanel
	Else
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=2/W=(525,75,790,175)
	DoWindow /C SynRespPanel
//	SetDrawEnv fsize= 12,textrgb= (0,9472,39168)
//	SetVariable setvar0,pos={0,0},size={120,16},title="BL Start",value= SRBLStart
	SetVariable setvar0,pos={135,50},size={120,16},title="BL Del",value= SRBLEDel
	SetVariable setvar1,pos={0,100},size={120,16},title="Pk Win Start",value= SRPkWinStart
	SetVariable setvar2,pos={135,50},size={120,16},title="Pk Win Del",value= SRPkWinDel
	SetVariable setvar3,pos={135,50},size={120,16},title="Pk SD thresh",value= SRSDThresh
	SetVariable setvar4,pos={135,50},size={120,16},title="Num Reps",value= SRNumReps
	SetVariable setvar5,pos={135,50},size={120,16},title="Rep DelT",value= SRRepDelT
	
	
	CheckBox EPhysSealTestVarName,pos={5,8},size={16,14},title="SealTest",value= 0
	CheckBox EPhysSealTestVarName, variable = root:AnalyzeDataVars:EPhysSealTestVarVal
	Button       EPhysSealTestButton0VarName,pos={95,5},size={75,20},title="Edit VClamp"
//	Button       EPhysSealTestButton0VarName,proc = pt_EPhysSealTestEdit, userdata="pt_CalRsRinCmVmVClamp"
	Button       EPhysSealTestButton0VarName,proc = pt_CallEditFuncPars, userdata="pt_CalRsRinCmVmVClamp"
	EndIf

End

Function pt_CallEditFuncPars(ButtonVarName) :  ButtonControl
String ButtonVarName
String FuncName = getuserdata("",ButtonVarName,"")
pt_EditFuncPars(FuncName)
End

Function pt_EPhysSealTestParsCreate()
// Create initial seal test parameter waves that the user can modify

Make /T/O/N=14 $"root:AnalyzeDataVars:pt_CalRsRinCmVmVClampParNamesW", $"root:AnalyzeDataVars:pt_CalRsRinCmVmVClampParW"
Wave /T AnalParNamesW 		= $"root:AnalyzeDataVars:pt_CalRsRinCmVmVClampParNamesW"
Wave /T AnalParW 			= $"root:AnalyzeDataVars:pt_CalRsRinCmVmVClampParW"

AnalParNamesW[0]		=	"DataWaveMatchStr"
AnalParNamesW[1]		=	"DataFldrStr"
AnalParNamesW[2]		=	"tBaselineStart0"
AnalParNamesW[3]		=	"tBaselineEnd0"
AnalParNamesW[4]		=	"tSteadyStateStart0"
AnalParNamesW[5]		=	"tSteadyStateEnd0"
AnalParNamesW[6]		=	"SealTestAmp_V"
AnalParNamesW[7]		=	"NumRepeat"
AnalParNamesW[8]		=	"RepeatPeriod"
AnalParNamesW[9]		=	"tSealTestPeakWinDel"
AnalParNamesW[10]		=	"tExp2FitStart0"
AnalParNamesW[11]		=	"tExp2FitEnd0"
AnalParNamesW[12]		=	"tSealTestStart0"
AnalParNamesW[13]		=	"AlertMessages"

AnalParW[0]				=	"Cell_00*"
AnalParW[1]				=	"RawData:"
AnalParW[2]				=	"0.01"
AnalParW[3]				=	"0.04"
AnalParW[4]				=	"0.4"
AnalParW[5]				=	"0.475"
AnalParW[6]				=	"-0.005"
AnalParW[7]				=	"1"
AnalParW[8]				=	"0.15"
AnalParW[9]				=	"1e-3"
AnalParW[10]			=	"0.051"
AnalParW[11]			=	"0.06"
AnalParW[12]			=	"0.05"
AnalParW[13]			=	"0"




Make /T/O/N=13 $"root:AnalyzeDataVars:pt_CalRsRinCmVmIClampParNamesW", $"root:AnalyzeDataVars:pt_CalRsRinCmVmIClampParW"
Wave /T AnalParNamesW 		= $"root:AnalyzeDataVars:pt_CalRsRinCmVmIClampParNamesW"
Wave /T AnalParW 			= $"root:AnalyzeDataVars:pt_CalRsRinCmVmIClampParW"

AnalParNamesW[0]		=	"DataWaveMatchStr"
AnalParNamesW[1]		=	"DataFldrStr"
AnalParNamesW[2]		=	"tBaselineStart0"
AnalParNamesW[3]		=	"tBaselineEnd0"
AnalParNamesW[4]		=	"tSteadyStateStart0"
AnalParNamesW[5]		=	"tSteadyStateEnd0"
AnalParNamesW[6]		=	"SealTestAmp_I"
AnalParNamesW[7]		=	"NumRepeat"
AnalParNamesW[8]		=	"RepeatPeriod"
AnalParNamesW[9]		=	"tExpFitStart0"
AnalParNamesW[10]		=	"tExpFitEnd0"
AnalParNamesW[11]		=	"tSealTestStart0"
AnalParNamesW[12]		=	"AlertMessages"

AnalParW[0]				=	"Cell_00*"
AnalParW[1]				=	"RawData:"
AnalParW[2]				=	"0.025"
AnalParW[3]				=	"0.045"
AnalParW[4]				=	"0.45"
AnalParW[5]				=	"0.475"
AnalParW[6]				=	"-0.01"
AnalParW[7]				=	"1"
AnalParW[8]				=	"0.15"
AnalParW[9]				=	"0.055"
AnalParW[10]			=	"0.1"
AnalParW[11]			=	"0.05"
AnalParW[12]			=	"0"

End

Function pt_EPhysSpikeAnalParsCreate()
// Create initial seal test parameter waves that the user can modify

Make /T/O/N=21 $"root:AnalyzeDataVars:pt_SpikeAnalParNamesW", $"root:AnalyzeDataVars:pt_SpikeAnalParW"
Wave /T AnalParNamesW 		= $"root:AnalyzeDataVars:pt_SpikeAnalParNamesW"
Wave /T AnalParW 			= $"root:AnalyzeDataVars:pt_SpikeAnalParW"

AnalParNamesW[0]		=	"DataWaveMatchStr"
AnalParNamesW[1]		=	"DataFldrStr"
AnalParNamesW[2]		=	"StartX"
AnalParNamesW[3]		=	"EndX"
AnalParNamesW[4]		=	"SpikeAmpAbsThresh"
AnalParNamesW[5]		=	"SpikeAmpRelativeThresh"
AnalParNamesW[6]		=	"SpikePolarity"
AnalParNamesW[7]		=	"BoxSmoothingPnts"
AnalParNamesW[8]		=	"RefractoryPeriod"
AnalParNamesW[9]		=	"SpikeThreshWin"
AnalParNamesW[10]		=	"SpikeThreshDerivLevel"
AnalParNamesW[11]		=	"BLPreDelT"
AnalParNamesW[12]		=	"FIWNamesW"
AnalParNamesW[13]		=	"FICurrWave"
AnalParNamesW[14]		=	"BaseNameStr"
AnalParNamesW[15]		=	"FracToPeak"
AnalParNamesW[16]		=	"EndOfPulseAHPDelT"
AnalParNamesW[17]		=	"PrePlsBLDelT"
AnalParNamesW[18]		=	"AlertMessages"
AnalParNamesW[19]		=	"SpikeThreshDblDeriv"
AnalParNamesW[20]		=	"ISVDelT"



AnalParW[0]				=	"Cell_00*"
AnalParW[1]				=	"RawData:"
AnalParW[2]				=	"1"
AnalParW[3]				=	"2"
AnalParW[4]				=	"-30e-3"
AnalParW[5]				=	"10e-3"
AnalParW[6]				=	"1"
AnalParW[7]				=	"5"
AnalParW[8]				=	"1e-3"
AnalParW[9]				=	"4e-3"
AnalParW[10]			=	"10"
AnalParW[11]			=	"5e-4"
AnalParW[12]			=	""
AnalParW[13]			=	""
AnalParW[14]			=	"FI"
AnalParW[15]			=	"0.5"
AnalParW[16]			=	"+inf"
AnalParW[17]			=	"1e-2"
AnalParW[18]			=	"0"
AnalParW[19]			=	"1"
AnalParW[20]			=	"1e-3"

End

Function pt_SynRespParsCreate1()
NewDataFolder /O root:AnalyzeDataVars:SynResp

Variable /G root:AnalyzeDataVars:SynResp:SRBLDel
Variable /G root:AnalyzeDataVars:SynResp:SRPkWinStart
Variable /G root:AnalyzeDataVars:SynResp:SRPkWinDel
Variable /G root:AnalyzeDataVars:SynResp:SRSDThresh
Variable /G root:AnalyzeDataVars:SynResp:SRNumReps
Variable /G root:AnalyzeDataVars:SynResp:SRRepDelT
Variable /G root:AnalyzeDataVars:SynResp:SRPkPolr
Variable /G root:AnalyzeDataVars:SynResp:SRAvgWin

End


Function pt_VidMkMovParsCreate()
// Create initial VidMkMov par waves that the user can modify

Make /T/O/N=8 $"root:AnalyzeDataVars:pt_VidMkMovParNamesW", $"root:AnalyzeDataVars:pt_VidMkMovParW"
Wave /T AnalParNamesW 		= $"root:AnalyzeDataVars:pt_VidMkMovParNamesW"
Wave /T AnalParW 			= $"root:AnalyzeDataVars:pt_VidMkMovParW"


AnalParNamesW[0] = "MatchStr"
AnalParNamesW[1] = "MatchExtn"
AnalParNamesW[2] = "DataIsImage"
AnalParNamesW[3] = "MovieName"
AnalParNamesW[4] = "StartFrameNum"
AnalParNamesW[5] = "NFramesPerMovie"
AnalParNamesW[6] =  "AllFrames"
AnalParNamesW[7] =  "AppendGraphW"

// The parameters that are enetered by user are left empty in newly created parW

AnalParW[0] = ""
AnalParW[1] = ""
AnalParW[2] = ""
AnalParW[3] = ""
AnalParW[4] = ""
AnalParW[5] = ""
AnalParW[6] = ""
AnalParW[7] = ""


End

Function pt_LoadDataNthWaveParsCreate()
// Create initial VidMkMov par waves that the user can modify

Make /T/O/N=8 $"root:AnalyzeDataVars:pt_LoadDataNthWaveParNamesW", $"root:AnalyzeDataVars:pt_LoadDataNthWaveParW"
Wave /T AnalParNamesW 		= $"root:AnalyzeDataVars:pt_LoadDataNthWaveParNamesW"
Wave /T AnalParW 			= $"root:AnalyzeDataVars:pt_LoadDataNthWaveParW"

AnalParNamesW[0] = "MatchStr"
AnalParNamesW[1] = "MatchExtn"
AnalParNamesW[2] = "DataIsImage"
AnalParNamesW[3] = "HDFolderPath"
AnalParNamesW[4] = "IgorFolderPath"
AnalParNamesW[5] = "N0"
AnalParNamesW[6] =  "NDel"
AnalParNamesW[7] =  "NTot"

// The parameters that are enetered by user are left empty in newly created parW

AnalParW[0] = ""
AnalParW[1] = ""
AnalParW[2] = ""
AnalParW[3] = ""
AnalParW[4] = ""
AnalParW[5] = ""
AnalParW[6] = ""
AnalParW[7] = ""


End

Function pt_SynRespParEdit(EPhysSynRespButton3VarName) : ButtonControl
String EPhysSynRespButton3VarName
String FuncName="pt_CalSynResp"
String TableName=FuncName+"_Edit"

SVAR AnalParFolder = root:AnalyzeDataVars:AnalParFolder

If (StringMatch(AnalParFolder,""))
	DoAlert 0,"Please select a channel first!"
	Return 1
EndIf

DoWindow /F $TableName
If	(!V_Flag)
	Edit /N=$TableName
EndIf
If (WaveExists($(AnalParFolder+":"+FuncName+"ParNamesW")) && WaveExists($(AnalParFolder+":"+FuncName+"ParW")))
	AppendToTable  $(AnalParFolder+":"+FuncName+"ParNamesW"), $(AnalParFolder+":"+FuncName+"ParW")
	//Edit /N= $TableName $("root:FuncParWaves:"+FuncName+"ParNamesW"), $("root:FuncParWaves:"+FuncName+"ParW")
Else
Make /T/O/N=12 $(AnalParFolder+":"+FuncName+"ParNamesW"), $(AnalParFolder+":"+FuncName+"ParW")
Wave /T AnalParNamesW 		= $(AnalParFolder+":"+FuncName+"ParNamesW")
Wave /T AnalParW 			= $(AnalParFolder+":"+FuncName+"ParW")
AppendToTable  AnalParNamesW, AnalParW

AnalParNamesW[0] = "DataWaveMatchStr"
AnalParNamesW[1] = "DataFldrStr"
AnalParNamesW[2] = "BaseNameStr"
//AnalParNamesW[3] = "NStims"
//AnalParNamesW[4] = "StimsRepDelT"
AnalParNamesW[3] = "PkWinStart0List"	// can add more than one values separated by semi-colon. eg 500e-3; 1000e-3; 1500e-3
AnalParNamesW[4] = "PkWinDel"
AnalParNamesW[5] = "BLDel"
AnalParNamesW[6] = "AvgWin"
AnalParNamesW[7] = "ThreshVal"
AnalParNamesW[8] = "NStepsPerStim"	
AnalParNamesW[9] = "StepsPerStimDelT"
AnalParNamesW[10] = "SmthPnts"
AnalParNamesW[11] = "PkPolr"


AnalParW[0] = "Cell_00*"
AnalParW[1] = "RawData:"
AnalParW[2] = "SR"
// The parameters that are enetered by user are left empty in newly created parW

AnalParW[3] = ""
AnalParW[4] = ""
AnalParW[5] = ""
AnalParW[6] = ""
AnalParW[7] = ""
AnalParW[8] = ""
AnalParW[9] = ""
AnalParW[10] = ""
AnalParW[11] = ""

 
EndIf
End

Function pt_CalSynRespParsCreate()
// Create initial SynResp par waves that the user can modify

Make /T/O/N=12 $"root:AnalyzeDataVars:pt_CalSynRespParNamesW", $"root:AnalyzeDataVars:pt_CalSynRespParW"
Wave /T AnalParNamesW 		= $"root:AnalyzeDataVars:pt_CalSynRespParNamesW"
Wave /T AnalParW 			= $"root:AnalyzeDataVars:pt_CalSynRespParW"


AnalParNamesW[0] = "DataWaveMatchStr"
AnalParNamesW[1] = "DataFldrStr"
AnalParNamesW[2] = "BaseNameStr"
//AnalParNamesW[3] = "NStims"
//AnalParNamesW[4] = "StimsRepDelT"
AnalParNamesW[3] = "PkWinStart0List"	// can add more than one values separated by semi-colon. Eg 500e-3; 1000e-3; 1500e-3
AnalParNamesW[4] = "PkWinDel"
AnalParNamesW[5] = "BLDel"
AnalParNamesW[6] = "AvgWin"
AnalParNamesW[7] = "ThreshVal"
AnalParNamesW[8] = "NStepsPerStim"	// could be used for analyzing multiple steps in a single stim
AnalParNamesW[9] = "StepsPerStimDelT"
AnalParNamesW[10] = "SmthPnts"
AnalParNamesW[11] = "PkPolr"


AnalParW[0] = "Cell_00*"
AnalParW[1] = "RawData:"
AnalParW[2] = "SR"
// The parameters that are enetered by user are left empty in newly created parW

AnalParW[3] = ""
AnalParW[4] = ""
AnalParW[5] = ""
AnalParW[6] = ""
AnalParW[7] = ""
AnalParW[8] = ""
AnalParW[9] = ""
AnalParW[10] = ""
AnalParW[11] = ""


End

Function pt_PairedRecDispRng(ButtonVarName) :  ButtonControl
String ButtonVarName
// Actually create and edit
SVAR EPhysFldrsList	 = root:TrigGenVars:EPhysFldrsList	
String TableName, FuncName
Variable i
Variable NEPhysFldrs= ItemsInList(EPhysFldrsList, ";")
Make /T/O/N=(NEPhysFldrs) $"root:AnalyzeDataVars:pt_PairedRecDispRngParNamesW"
Make /T/O/N=(NEPhysFldrs,2) $"root:AnalyzeDataVars:pt_PairedRecDispRngParWX", $"root:AnalyzeDataVars:pt_PairedRecDispRngParWY"
Wave /T AnalParNamesW 	= $"root:AnalyzeDataVars:pt_PairedRecDispRngParNamesW"
Wave /T AnalParWX 		= $"root:AnalyzeDataVars:pt_PairedRecDispRngParWX"
Wave /T AnalParWY 		= $"root:AnalyzeDataVars:pt_PairedRecDispRngParWY"

For (i=0; i<NEPhysFldrs; i+=1)
AnalParNamesW[i] = StringFromList(i, EPhysFldrsList	, ";")
EndFor

FuncName = "pt_PairedRecDispRng"
TableName = "pt_PairedRecDispRngParsEdit"
DoWindow  $TableName
If	(V_Flag)
	DoWindow  /K $TableName	
EndIf
Edit /K=1 $("root:AnalyzeDataVars:"+FuncName+"ParNamesW"), $("root:AnalyzeDataVars:"+FuncName+"ParWX"), $("root:AnalyzeDataVars:"+FuncName+"ParWY")
DoWindow  /C/F$TableName

//If (WaveExists($("root:AnalyzeDataVars:"+FuncName+"ParNamesW")) && WaveExists($("root:AnalyzeDataVars:"+FuncName+"ParW")))
//	AppendToTable  $("root:AnalyzeDataVars:"+FuncName+"ParNamesW"), $("root:AnalyzeDataVars:"+FuncName+"ParW")
	//Edit /N= $TableName $("root:FuncParWaves:"+FuncName+"ParNamesW"), $("root:FuncParWaves:"+FuncName+"ParW")
//Else 
//	Make /T/N=0 $("root:AnalyzeDataVars:"+FuncName+"ParNamesW"), $("root:AnalyzeDataVars:"+FuncName+"ParW")
//	Edit /N= $TableName $("root:FuncParWaves:"+FuncName+"ParNamesW"), $("root:FuncParWaves:"+FuncName+"ParW")
//EndIf

End

Function pt_AvgLastNWavesParsCreate()
// Create initial par waves that the user can modify

Make /T/O/N=2 $"root:AnalyzeDataVars:pt_AvgLastNWavesParNamesW", $"root:AnalyzeDataVars:pt_AvgLastNWavesParW"
Wave /T AnalParNamesW 		= $"root:AnalyzeDataVars:pt_AvgLastNWavesParNamesW"
Wave /T AnalParW 			= $"root:AnalyzeDataVars:pt_AvgLastNWavesParW"


AnalParNamesW[0] = "DataWaveMatchStr"
AnalParNamesW[1] = "NumWaves"

AnalParW[0] = "Cell_00*"
AnalParW[0] = ""
End

Structure pt_EPhysWStruc
//for output wave just description is enough. for incoming wave the raw data needs to saved and also
// Description of the stimulus (will depend on the protocol eg. FI, IV, Mini, Evoked, Spont)
//parameters for FI
// essentially, what is needed while generating the stim wave
String DateS
String TimeS
String ModeS 		//VClamp Or IClamp
String StimAmp		//Volts OR Amps for VClamp and IClamp respectively	
String SealTestAmp  //Volts OR Amps for VClamp and IClamp respectively	
Wave InWave
EndStructure

Function pt_RandomizeTextW(OrigWName,DestWName, Num)
// Based on Ken's util_randomSelectA. This function will take a text wave and generate a new text wave with Num entries 
// with random entries from OrigW. Num should be smaller than or equal to NumPnts(OrigW)
	String OrigWName, DestWName
	Variable Num
	
	Wave /T 		w1 				= 	$OrigWName
	Make /T/O/N	=(NumPnts(w1)) 		$DestWName
	Wave /T 		w2 				= 	$DestWName
	w2 = w1
	If (Num<=NumPnts(w1)) 
	
	Make /O/N=(Numpnts(w1)) TmpW, Tmpi
	TmpW 	= enoise(1)		// enoise generates uniformly distributed random numbers between -num and + num
	Tmpi 	= p				// wave = p assignment assigns the successive elements, the successive index number

//	Arrange the index wave according  to random number wave
	Sort TmpW, Tmpi     // sorts the indexes in tmpi ascending order according to the value in tmpw 
	Redimension /N=(Num) w2
	w2 = w1[Tmpi[p]]     
	
	
	Else
		Print "Maximum number of points in the DestW cannot be greater than OrigW. Wave not randomized"
	EndIf
	Killwaves /Z Tmpi, TmpW
End



Function pt_DataExistsCheck(MatchStr, HDSymbPath)
// Check whether data already exists on the disk
String MatchStr, HDSymbPath

String AllListStr, MatchListStr

AllListStr= IndexedFile(HDSymbPath, -1, ".ibw")
MatchListStr = ListMatch(AllListStr, MatchStr+"*")
Print MatchListStr

If (StrLen(MatchListStr) !=0)
Return 1
Else
Return 0
EndIf
End

Function pt_OpenEPhysNB()
DoWindow EPhysNB
If (V_Flag ==1)
	DoWindow /F EPhysNB
Else
	NewNoteBook /F=0 /N=EPhysNB
	NoteBook EPhysNB, Text = Date()+"\r"
	NoteBook EPhysNB, Text = Time()+"\r\r"

	NoteBook EPhysNB, Text = "Experiment's Aim\r\r\r\r"
	NoteBook EPhysNB, Text = "______________________________________\r"
	NoteBook EPhysNB, Text = "Experiment Protocol\r\r\r\r"
	NoteBook EPhysNB, Text = "______________________________________\r"
	NoteBook EPhysNB, Text = "Experimenter's Name\r\r"
	NoteBook EPhysNB, Text = "______________________________________\r"
	NoteBook EPhysNB, Text = "Animal's ID\r"
	NoteBook EPhysNB, Text = "______________________________________\r"
	NoteBook EPhysNB, Text = "Animal's Age\r"
	NoteBook EPhysNB, Text = "______________________________________\r"
	NoteBook EPhysNB, Text = "Animal's Gender\r"
	NoteBook EPhysNB, Text = "______________________________________\r"
	NoteBook EPhysNB, Text = "Animal's Genotype\r"
	NoteBook EPhysNB, Text = "______________________________________\r"
	NoteBook EPhysNB, Text = "Animal's Phenotype\r\r\r"
	NoteBook EPhysNB, Text = "______________________________________\r"
	NoteBook EPhysNB, Text = "Recording Temperature\r"
	NoteBook EPhysNB, Text = "______________________________________\r"
	NoteBook EPhysNB, Text = "Internal Solution\r\r"
	NoteBook EPhysNB, Text = "______________________________________\r"
	NoteBook EPhysNB, Text = "Slicing ACSF\r\r"
	NoteBook EPhysNB, Text = "______________________________________\r"
	NoteBook EPhysNB, Text = "Incubating ACSF\r\r"
	NoteBook EPhysNB, Text = "______________________________________\r"
	NoteBook EPhysNB, Text = "Recording ACSF\r\r"
	NoteBook EPhysNB, Text = "______________________________________\r"
	NoteBook EPhysNB, Text = "Drugs Perfused\r\r"
	NoteBook EPhysNB, Text = "______________________________________\r"
	NoteBook EPhysNB, Text = "Comments\r\r\r\r"
	NoteBook EPhysNB, Text = "______________________________________\r"
	DoWindow /F EPhysNB
EndIf
End

Function pt_KillEPhysNB()
DoWindow EPhysNB
If (V_Flag ==1)
	DoWindow /K EPhysNB
EndIf
End


Function pt_OpenInVivoNB()
DoWindow InVivoNB
If (V_Flag ==1)
	DoWindow /F InVivoNB
Else
	NewNoteBook /F=0 /N=InVivoNB
	NoteBook InVivoNB, Text = Date()+"\r"
	NoteBook InVivoNB, Text = Time()+"\r\r"

	NoteBook InVivoNB, Text = "Experiment's Aim\r\r\r\r"
	NoteBook InVivoNB, Text = "______________________________________\r"
	NoteBook InVivoNB, Text = "Experiment Protocol\r\r\r\r"
	NoteBook InVivoNB, Text = "______________________________________\r"
	NoteBook InVivoNB, Text = "Experimenter's Name\r\r"
	NoteBook InVivoNB, Text = "______________________________________\r"
	NoteBook InVivoNB, Text = "Date of Surgery\r"
	NoteBook InVivoNB, Text = "______________________________________\r"	
	NoteBook InVivoNB, Text = "Animal's ID\r"
	NoteBook InVivoNB, Text = "______________________________________\r"
	NoteBook InVivoNB, Text = "Animal's Age\r"
	NoteBook InVivoNB, Text = "______________________________________\r"
	NoteBook InVivoNB, Text = "Animal's Gender\r"
	NoteBook InVivoNB, Text = "______________________________________\r"
	NoteBook InVivoNB, Text = "Animal's Genotype\r"
	NoteBook InVivoNB, Text = "______________________________________\r"
	NoteBook InVivoNB, Text = "Animal's Phenotype\r\r\r"
	NoteBook InVivoNB, Text = "______________________________________\r"
	NoteBook InVivoNB, Text = "Surgery Coordinates\r\r"
	NoteBook InVivoNB, Text = "______________________________________\r"
	NoteBook InVivoNB, Text = "Surgery Details\r\r\r\r"
	NoteBook InVivoNB, Text = "______________________________________\r"
	NoteBook InVivoNB, Text = "Animal Recovery and Care\r\r\r\r"
	NoteBook InVivoNB, Text = "______________________________________\r"	
	NoteBook InVivoNB, Text = "Comments\r\r\r\r"
	NoteBook InVivoNB, Text = "______________________________________\r"
	DoWindow /F InVivoNB
EndIf
End

Function pt_KillInVivoNB()
DoWindow InVivoNB
If (V_Flag ==1)
	DoWindow /K InVivoNB
EndIf
End

Function pt_LoadDataRecursive(MatchStr, HDFolderPath, IgorFolderPath)	// from PraveensIgorUtilities
String MatchStr, HDFolderPath, IgorFolderPath
// To load waves having a "StringExpression" from a folder on disk. Load all files in a TempLoadData Folder and then select from there.
// Example Usage: pt_LoadData("*EPSP*", "D:users:taneja:data1:PresynapticNmda:NmdaEvoked:07_19_2004 Folder:Cell1326To1325Anal08_11_2004 Folder",  "root:EPSP")
String OldDf, ListStr, WaveStr
Variable i, NumWaves

OldDf = GetDataFolder(1)
NewDataFolder /O  $(IgorFolderPath)		// No : at end)
NewDataFolder /O/S  $(IgorFolderPath+"Temp")
LoadData /Q/O/D/L=1/R HDFolderPath
ListStr= WaveList(MatchStr, ";", "")
NumWaves = ItemsinList(ListStr)

	For (i=0; i< NumWaves; i+=1)
		WaveStr = StringFromList(i, ListStr, ";")
		Duplicate /o $WaveStr, $(IgorFolderPath + ":" +WaveStr)
	EndFor
	KillDataFolder $(IgorFolderPath+"Temp")
Return 1	
End
End

Function pt_AverageWavesEasy() 		// from PraveensIgorUtilities
// This is always the latest version. 

// instead of appending "_Avg", just append "Avg" 30th Sept. 2007

// so far i was generating temporary wave with PntsPerBin*NumWaves for each point of the destination wave and averaging that. a much more simpler and 
// faster wave is first average all waves 1 pnt at a time and then coarse bin it because,
//	

// renamed version last modified on 03_22_2007 to pt_AverageWaves2() on 23rd, Sept. 2007.

// separated the finding of largest dimension as a separate function pt_MaxWDim  03_22_2007
// also added an DoAlert if we got an empty string 03_22_2007
// adding underscore to distinguish output of this version (modified 03_01_2007) from earlier version. Earlier version had problem if any wave was
// shorter than the longest wave. 
// pt_AverageWFrmFldrs was unnecessary. merged functionality with pt_AverageWaves (modified 03_02_2007)
// This function averages waves taken from the top window or matching a string. To calculate the final  average waves it  takes "PntsPerBin" 
// number of pnts from each wave for each pnt. Also dimensionality and scaling of final wave is set by longest wave

Variable DisplayAvg
String DataWaveMatchStr, DataFldrStr, BaseNameStr, ExcludeWNamesWStr

Variable NumPntsSrcWave, i, j, NumWaves, NumPntsW1, DeltaSrcWave, OffsetSrcWave, DestWaveDimOffset 
Variable DestWaveDimDelta, LongestWIndex, NPnts
String wavlist, WaveNameStr
String LastUpdatedMM_DD_YYYY="09_30_2007"

Print "*********************************************************"
Print "pt_AverageWavesEasy last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"

Wave /T AnalParNamesW	=	$("root:FuncParWaves:pt_AverageWavesEasy"+"ParNamesW")

Wave /T AnalParW		=	$("root:FuncParWaves:pt_AverageWavesEasy"+"ParW")

If (WaveExists(AnalParNamesW) &&  WaveExists(AnalParW) == 0)
	Abort	"Cudn't find the parameter waves  pt_AverageWavesEasyParW and/or pt_AverageWavesEasyParNamesW!!!"
EndIf

DataWaveMatchStr		=	AnalParW[0]
DataFldrStr				=	AnalParW[1]
BaseNameStr			=	AnalParW[2]
//PntsPerBin				=	Str2Num(AnalParW[3])
ExcludeWNamesWStr	=	AnalParW[3]
DisplayAvg				=	Str2Num(AnalParW[4])

PrintAnalPar("pt_AverageWavesEasy")

If (StrLen(DataWaveMatchStr)==0)
wavlist = wavelist("*",";","WIN:")
Else
wavlist = wavelist(DataWaveMatchStr,";","")
EndIf
wavlist = pt_ExcludeFromWList(ExcludeWNamesWStr, wavlist)



NumWaves = ItemsInList(WavList,";")
If (!NumWaves>0)
Print "NumWaves <=0. No Waves to average!!"
Return -1
EndIf
print "Averaging waves...N=", NumWaves, wavlist

// Check all waves have same num of points and no NAN's
WaveNameStr= StringFromList (0,wavlist,";")
wave w = $WaveNameStr
NPnts= NumPnts(w)

// Check all waves have same num of points and no NAN's
For (i=0; i<NumWaves; i+=1)
	WaveNameStr= StringFromList (i,wavlist,";")
	
	 	if (strlen(WaveNameStr)== 0)
  			Print "While finding average of waves could not find wave #", i
  			DoAlert 0, "Exiting without finishing!!"
 			break
 		endif
	
	wave w = $WaveNameStr
	If (NumPnts(w) != NPnts)
		Print "NumPoints", WaveNameStr, "not equal to", NPnts
		DoAlert 0, "Use pt_AverageWaves instead!!"
 		Abort
	EndIf
	For (j=0; j<NPnts; j+=1)
		If (NumType(w(j)) != 0)
		Print "NumType",  WaveNameStr,"(",j,")  a normal-number'"
		DoAlert 0, "Waves contains a non-normal number. Use pt_AverageWaves instead!!"
 		Abort
	EndIf
	EndFor	
EndFor


Make /O/N=(NPnts) $(BaseNameStr+"Avg")
Wave w2= $(BaseNameStr+"Avg")
WaveNameStr= StringFromList (0,wavlist,";")
wave w = $WaveNameStr
SetScale /p x,DimOffset(w,0),DimDelta(w,0), w2
w2 = 0


	
For (i=0; i< NumWaves; i+=1)
	
		WaveNameStr= StringFromList (i,wavlist,";") 		
 		wave w = $WaveNameStr
		w2 +=w
EndFor

w2 /=NumWaves

If (DisplayAvg)
	Display
	DoWindow pt_AverageWavesEasyDisplay
	If (V_Flag)
		DoWindow /F pt_AverageWavesEasyDisplay
//		Sleep 00:00:02
		DoWindow /K pt_AverageWavesEasyDisplay
	EndIf
	DoWindow /C pt_AverageWavesEasyDisplay
	For (i=0; i< NumWaves; i+=1)
	
		WaveNameStr= StringFromList (i,wavlist,";")
//		if (strlen(WaveNameStr)== 0)
 //			break
 //		endif
 	 if (strlen(WaveNameStr)== 0)
  			Print "While finding average of waves could not find wave #", i
  			DoAlert 0, "Exiting without finishing!!"
 			break
 	endif	
 		
 	wave w = $WaveNameStr
 	AppendToGraph /W=pt_AverageWavesEasyDisplay w
 	ModifyGraph /W=pt_AverageWavesEasyDisplay mode=4
 	EndFor
 	AppendToGraph /W=pt_AverageWavesEasyDisplay w2
 	ModifyGraph rgb($(BaseNameStr+"Avg"))=(0,0,0)
	ModifyGraph /W=pt_AverageWavesEasyDisplay mode=4
	ModifyGraph /W=pt_AverageWavesEasyDisplay marker($(BaseNameStr+"Avg"))=41
	DoUpdate
	Sleep /T 30
EndIf
End

Function/S pt_ExcludeFromWList(ExcludeWNamesWStr, WList)	// from PraveensIgorUtilities
String ExcludeWNamesWStr, WList
String NewWList, ExcludeWList, WStr
Variable Overwrite, N, i 
NewWList=WList
If (!StringMatch(ExcludeWNamesWStr, ""))
	Wave /T w=$ExcludeWNamesWStr
	N=NumPnts(w)
	ExcludeWList=""
	For (i=0; i<N; i+=1)
		WStr=w[i]
		ExcludeWList     +=ListMatch(NewWList, WStr, ";")
		NewWList		=ListMatch(NewWList, "!"+WStr, ";")
	EndFor
	Print "**Excluded Waves:** N=",ItemsInList(ExcludeWList, ";"), ExcludeWList
Else
	Print "ExcludeWNamesWStr is empty, No waves Excluded"
EndIf	
Return NewWList
End

Function pt_AvgLastNWaves(ButtonVarName) :  ButtonControl
String ButtonVarName
// Function to average last N EPhys waves (for eg. to see if there is a synaptic response present)
// Logic - for channels selected by user, load the last N waves, average and plot for each channel
// use pt_AverageWavesEasy and pt_LoadDataRecursive
// convert ChanneflName to MatchStr
//String DataWaveMatchStr
//Variable NumWaves

NVAR NumWaves2Avg = root:AnalyzeDataVars:AvgLastNWavesNum
NVAR EPhysPairedRecVarVal		=root:AnalyzeDataVars:EPhysPairedRecVarVal
SVAR EPhysFldrsList				= root:TrigGenVars:EPhysFldrsList	
//SVAR ListEPhysInCh				= root:TrigGenVars:ListEPhysInCh

Variable NumEPhysFldrs = ItemsInList(EPhysFldrsList, ";")

Variable i,NumCh, NumWavesAll, j,jStart, InstNum,NPnts, k//, WOffset, WDelta 
Variable RedInt, GreenInt, BlueInt//, TraceNum
String TraceNameStr = ""
String FldrName, DataWaveMatchStr, HDFolderPath, IgorFolderPath, OldDF, WList, WListAvg, WNameStr
String OldMatchStr, OldHDFolderPath, OldMatchExtn, OldDataIsImage, OldIgorFolderPath, OldN0, OldNDel, OldNTot

String AllListStr, ListStr, CurrSubWinName, ListEPhysInCh
Variable NumWavesMatch, NumWavesLoad, NWaves
Variable NSubWin, SubWinYSize, AvgLastNWavesHostWinXSize=700, AvgLastNWavesHostWinYSize=600, EPhysChSlctd=0


//String LastUpdatedMM_DD_YYYY=" 09/30/2011"

//Print "*********************************************************"
//Print "pt_AvgLastNWaves last updated on", LastUpdatedMM_DD_YYYY
//Print "*********************************************************"

//Wave /T AnalParNamesW		=	$pt_GetParWave("pt_AvgLastNWaves", "ParNamesW")		// check in local folder first 07/23/2007
//Wave /T AnalParW			=	$pt_GetParWave("pt_AvgLastNWaves", "ParW")

//If (WaveExists(AnalParW) && WaveExists(AnalParNamesW)==0)			// included AnalParNamesW 07/23/2007
//	Abort	"Cudn't find the parameter wave pt_AvgLastNWavesParW!!!"
//EndIf

//DataWaveMatchStr		=	AnalParW[0]
//NumWaves				=	Str2Num(AnalParW[1])

//PrintAnalPar("pt_AvgLastNWaves")	

NewDataFolder /O root:AnalyzeDataVars:AvgLastNWaves
IgorFolderPath = "root:AnalyzeDataVars:AvgLastNWaves"

Make /T/O/N=0 $(IgorFolderPath+":SlctChW")
Wave /T SlctChW		= $(IgorFolderPath+":SlctChW")

Make /T/O/N=1 $(IgorFolderPath+":TmpSlctChW")
Wave /T TmpSlctChW		= $(IgorFolderPath+":TmpSlctChW")

Wave /T IODevFldr	=root:TrigGenVars:IODevFldr
//Wave /T IOWName	=root:TrigGenVars:IOWName

//If (NumPnts(IODevFldr) != NumPnts(IOWName))
//	Abort ""
//EndIf

//##########
// Temporarily Commented NumCh = NumPnts(IODevFldr)
// Temporarily Commented For (i=0;i<NumCh; i+=1)
// If It's EPhys folder and in wave is scanned, then add to SlctChW
// Temporarily Commented FldrName = IODevFldr[i]
// Temporarily Commented NVAR EPhysInWaveSlctVar = $(FldrName+":EPhysInWaveSlctVar")
// Temporarily Commented If ((StrSearch(FldrName,"EPhys",0)!=-1) && (EPhysInWaveSlctVar==1))	
// Temporarily Commented TmpSlctChW[0] = FldrName
// Temporarily Commented Concatenate /NP /T {TmpSlctChW}, SlctChW
//	SScanf FldrName, "root:EPhysVars%d",InstNum
// Temporarily Commented EndIf	
// Temporarily Commented EndFor

ListEPhysInCh= pt_InstListIOForCh("root:TrigGenVars:IODevFldr", "EPhysVars", ":EPhysInWaveSlctVar")
NumCh = ItemsInList(ListEPhysInCh, ";")
//##########

OldDF = GetDataFolder(1)
SetDataFolder root:AnalyzeDataVars:AvgLastNWaves
If (NumCh>0)
	If (EPhysPairedRecVarVal)		// from pt_EPhysDisplay(). Eventually should be written as a separate function
	NSubWin = NumEPhysFldrs//NumCh
	SubWinYSize = AvgLastNWavesHostWinYSize/NSubWin
	DoWindow AvgLastNWavesHostWin
	If (!V_Flag)
	Display /K=1 /W=(0,0,AvgLastNWavesHostWinXSize,AvgLastNWavesHostWinYSize)
	DoWindow /C AvgLastNWavesHostWin 
	For (i=0; i<NSubWin; i+=1)
	Display /k=1/Host=AvgLastNWavesHostWin /W=(0,i*SubWinYSize, AvgLastNWavesHostWinXSize, (i+1)*SubWinYSize)/N=$"AvgLastNWavesSubWin"+Num2Str(i+1)
	EndFor
	EndIf	// If (!V_Flag)
	Else	//If (EPhysPairedRecVarVal)
	DoWindow AvgLastNWavesWin
	If (V_Flag)
	DoWindow /k AvgLastNWavesWin
	EndIf
	Display /K=1
	DoWindow /C AvgLastNWavesWin
	EndIf
	Print "--------------------------------------------------------------------------------------"
For (i=0; i<NumCh; i+=1)
	FldrName = "root:EPhysVars"+StringFromList(i, ListEPhysInCh,";")
	InstNum = Str2Num(StringFromList(i, ListEPhysInCh,";"))
//	SScanf FldrName, "root:EPhysVars%d",InstNum
	pt_TraceUserColor(InstNum-1, RedInt, GreenInt, BlueInt)
	SVAR InWaveBaseName	=$FldrName+":InWaveBaseName"
	NVAR CellNum			=$FldrName+":CellNum"
//	Str = InWaveBaseName +pt_PadZeros2IntNumCopy(CellNum, 4)+"_"+pt_PadZeros2IntNumCopy(IterNum, 4)
	DataWaveMatchStr = InWaveBaseName +pt_PadZeros2IntNumCopy(CellNum, 4)+"_*"
	PathInfo home
	If (V_Flag==0)
	Abort "Please save the experiment first!"
	EndIf
	HDFolderPath=  S_Path
//	Print "Saving EPhys data to",S_Path
	
PathInfo home
If (V_Flag==0)
	Abort "Please save the experiment first!"
EndIf
	
	
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
AllListStr= IndexedFile(SymblkHDFolderPath, -1, ".ibw")
ListStr = ListMatch(AllListStr, DataWaveMatchStr)
NumWavesMatch = ItemsinList(ListStr)


LDAnalParW[0] = DataWaveMatchStr
LDAnalParW[1] = ".ibw"
LDAnalParW[2] = "0"
LDAnalParW[3] = S_Path
LDAnalParW[4] = "root:AnalyzeDataVars:AvgLastNWaves"
If ((NumWavesMatch - NumWaves2Avg) <0)	// in
jStart = 0
NumWavesLoad = NumWavesMatch
Else
jStart = NumWavesMatch - NumWaves2Avg
NumWavesLoad = NumWaves2Avg
EndIf
//jStart = ((NumWavesMatch - NumWaves2Avg) <0)  ? 0 : (NumWavesMatch - NumWaves2Avg)
LDAnalParW[5] = Num2Str(jStart)
//LDAnalParW[3] = VidMkMovParVal[2]
LDAnalParW[6] = "1"
LDAnalParW[7] = Num2Str(NumWavesLoad)

pt_LoadDataNthWave()

// restore pars
LDAnalParW[0] = OldMatchStr
LDAnalParW[1] = OldMatchExtn
LDAnalParW[2] = OldDataIsImage 
LDAnalParW[3] = OldHDFolderPath
LDAnalParW[4] = OldIgorFolderPath
LDAnalParW[5] = OldN0
LDAnalParW[6] = OldNDel
LDAnalParW[7] = OldNTot
//Abort	
//	pt_LoadDataRecursive(DataWaveMatchStr, HDFolderPath, IgorFolderPath)	// doesn't restore original folder?
//	SetDataFolder root:AnalyzeDataVars:AvgLastNWaves
	
	WList= WaveList(DataWaveMatchStr, ";", "")
	NWaves = ItemsInList(WList, ";")
//	NumWavesAll= ItemsInList(WList, ";")
//	jStart = ((NumWavesAll - NumWaves2Avg) <0)  ? 0 : (NumWavesAll - NumWaves2Avg)
	WNameStr= StringFromList (0,WList,";") 	// 1st wave	
 	wave w = $WNameStr
	NPnts = NumPnts(w)
//	WOffset =DimOffset(w,0)
//	WDelta	=DimDelta(w,0)
	If (NPnts>0)
	Duplicate /O w, $("Ch"+Num2Str(InstNum)+"Avg")
//	Make /O/N=(NPnts)		$("Ch"+Num2Str(InstNum)+"Avg")
	Wave AvgW			= 	$("Ch"+Num2Str(InstNum)+"Avg")
	AvgW =0
	WListAvg = ""
	For (j=0; j< NWaves; j+=1)
		WNameStr= StringFromList (j,WList,";")
		WListAvg +=	WNameStr+";"
 		wave w = $WNameStr
		AvgW +=w
	EndFor
	
	Print "EPhysCh,", InstNum, ".Averaged waves, N =", ItemsInList(WListAvg, ";"), WListAvg
	
	AvgW /=NWaves



	For (j=0; j<NWaves; j+=1)
	WNameStr= StringFromList (j,WList,";") 	// 1st wave	
 	KillWaves /Z $WNameStr
	EndFor
	TraceNameStr = "Ch"+Num2Str(InstNum)+"Avg"
	If (EPhysPairedRecVarVal)
	For (k=0; k<NSubWin; k+=1)
	EPhysChSlctd =FindListItem(Num2Str(k+1), ListEPhysInCh, ";")
	If (EPhysChSlctd !=-1)
	CurrSubWinName = "AvgLastNWavesHostWin#AvgLastNWavesSubWin"+Num2Str(k+1)
	If (FindListItem(TraceNameStr, TraceNameList("AvgLastNWavesHostWin#AvgLastNWavesSubWin"+Num2Str(k+1), ";", 1), ";")==-1)
	AppendToGraph /L /W =$CurrSubWinName $("Ch"+Num2Str(InstNum)+"Avg")
	ModifyGraph /W =$CurrSubWinName rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	Legend /W =$CurrSubWinName /C/N=text0/F=0/A=RT
	EndIf
	If (WaveExists($"root:AnalyzeDataVars:pt_PairedRecDispRngParWX") && WaveExists($"root:AnalyzeDataVars:pt_PairedRecDispRngParWY"))
	Wave /T AnalParWX = $"root:AnalyzeDataVars:pt_PairedRecDispRngParWX"
	Wave /T AnalParWY = $"root:AnalyzeDataVars:pt_PairedRecDispRngParWY"
	SetAxis /W =$CurrSubWinName Bottom Str2Num(AnalParWX[k][0]), Str2Num(AnalParWX[k][1])
	SetAxis /W =$CurrSubWinName Left Str2Num(AnalParWY[k][0]), Str2Num(AnalParWY[k][1])	
	EndIf
	EndIf
	EndFor
	Else	//If (EPhysPairedRecVarVal)
	AppendToGraph /W=AvgLastNWavesWin $("Ch"+Num2Str(InstNum)+"Avg")
	ModifyGraph /W =AvgLastNWavesWin rgb($TraceNameStr)=(RedInt, GreenInt, BlueInt)
	Legend /W =AvgLastNWavesWin /C/N=text0/F=0/A=RT
//	Else
//	Display /k=1
//	DoWindow /C AvgLastNWavesDisplayWin
//	Display /Host=AvgLastNWavesDisplayWin
//	Display /L /Host =AvgLastNWavesDisplayWin#AvgLastNWavesDisplayWin#Sub1 AvgW
//	Legend /W =AvgLastNWavesDisplayWin#Sub1 /C/N=text0/F=0/A=RT
//	EndIf
	EndIf //If (EPhysPairedRecVarVal)
	
	
	EndIf
	
	
	EndFor // NumCh
	Print "--------------------------------------------------------------------------------------"
Else
	Print "No EPhys channels for which inwave was scanned are selected"
EndIf
KillWaves /Z TmpSlctChW, SlctChW
SetDataFolder OldDF
End

Function pt_LoadDataNthWave()	// see pt_LoadDataRecursive for recursive loading of data
// From Praveens Igor Utilities. Modified to allow NDel = "" implying load all waves
String MatchStr, MatchExtn, HDFolderPath, IgorFolderPath
Variable DataIsImage, N0,NDel, NTot	// N0 = First Wave, NDel = Difference between Wave numbers

// Adapted from pt_LoadData
// This is always the latest version

// added the option so that only every nth wave starting from N0 Waves is loaded. Useful, when the waves are big (like EEG or Video) and we don't want to 
// load all the waves

// Previous version was pt_LoadData1 where all files were loaded first and then only matching files were kept. with "IndexedFile" you can get
// names all files in a folder and then load only the ones needed.  6th August, 2007

// To load waves having a "StringExpression" from a folder on disk. Load all files in a TempLoadData Folder and then select from there.
// Example Usage: pt_LoadData("*EPSP*", "D:users:taneja:data1:PresynapticNmda:NmdaEvoked:07_19_2004 Folder:Cell1326To1325Anal08_11_2004 Folder",  "root:EPSP")
String OldDf, ListStr, WaveStr, AllListStr
Variable i, NumWaves
String LastUpdatedMM_DD_YYYY="03/28/2011"

Print "*********************************************************"
Print "pt_LoadDataNthWave last updated on", LastUpdatedMM_DD_YYYY
Print "*********************************************************"


Wave /T AnalParNamesW	=	$pt_GetParWave("pt_LoadDataNthWave", "ParNamesW")
Wave /T AnalParW			=	$pt_GetParWave("pt_LoadDataNthWave", "ParW")

If (WaveExists(AnalParW)*WaveExists(AnalParNamesW) ==0 )
	Abort	"Cudn't find the parameter wave pt_LoadDataNthWave!!!"
EndIf

PrintAnalPar("pt_LoadDataNthWave")

MatchStr			= AnalParW[0]
MatchExtn			= AnalParW[1]
DataIsImage			= Str2Num(AnalParW[2])
HDFolderPath		= AnalParW[3]
IgorFolderPath		= AnalParW[4]
N0					= Str2Num(AnalParW[5])	// To start with first wave, N0=0
//If (!StringMatch(AnalParW[4], ""))
NDel				= Str2Num(AnalParW[6])
//EndIf
If (!StringMatch(AnalParW[7], ""))
NTot				= Str2Num(AnalParW[7])
EndIf


OldDf = GetDataFolder(1)
NewDataFolder /O/S  $(IgorFolderPath)		// No : at end)

NewPath /O/Q/C SymblkHDFolderPath, HDFolderPath
AllListStr= IndexedFile(SymblkHDFolderPath, -1, MatchExtn)
ListStr = ListMatch(AllListStr, MatchStr)
NumWaves = ItemsinList(ListStr)

//	For (i=0; i< NumWaves; i+=1)
//		WaveStr = StringFromList(i, ListStr, ";")
//		LoadWave /O/Q/P=SymblkHDFolderPath WaveStr
//	EndFor
//If (!StringMatch(AnalParW[4], ""))
NumWaves=  floor((NumWaves-N0)/NDel)
//EndIf
If (!StringMatch(AnalParW[7], ""))
NumWaves = (NumWaves> NTot) ? NTot : NumWaves
EndIf

For (i=0; i< NumWaves; i+=1)
	WaveStr = StringFromList(i*NDel+N0, ListStr, ";")
	If (DataIsImage)
	ImageLoad /O/Q/P=SymblkHDFolderPath WaveStr
	Else
	LoadWave /O/Q/P=SymblkHDFolderPath WaveStr
	EndIf	
EndFor

Print "Pt_LoadData: Loaded waves, N= ", NumWaves	
SetDataFolder OldDf	
KillPath /Z SymblkHDFolderPath
Return 1	
End

Function pt_CaptureVideo(WBaseNameStr, TotalTime, FramesPerSec, WNoteStr)
//pt_CaptureVideo("root:videovars1:VideoVars1In", 1, 16, "ISI:5;")
// Function to capture video at a given sample frequency and length of time
String WBaseNameStr, WNoteStr
Variable TotalTime, FramesPerSec
//STRUCT MyBGStruct MyBGStructL
NVAR VideoInstNum		=root:VideoInstNum
String FldrName 	= "root:VideoVars"+Num2Str(VideoInstNum)

String /G $(FldrName+":WBaseNameStrVar") = WBaseNameStr
String /G $(FldrName+":WNoteStrVar") = WNoteStr
//String /G VidFldrName = FldrNameL
Variable /G $(FldrName+":CurrFrameNum") =0
NVAR TicksFreq		= root:TrigGenVars:TicksFreq 

Variable /G NFrames = Ceil(TotalTime*FramesPerSec)
//Variable /G NFrames = Ceil((TotalTime-45)*FramesPerSec)
//Print CurrFrameNum, NFrames
//MyBGStructL.WBaseNameStr = WBaseNameStr
//MyBGStructL.WNoteStr = WNoteStr
//string cmd="Grabber Init"
//Execute cmd


//cmd = "Grabber SetWinScale=0"
//Execute cmd

//cmd="Grabber Init"
//Execute cmd

//String cmd="Grabber StartPreview"
//Execute cmd

//cmd = "Grabber SetInputChannel=1"
//Execute cmd
//SetBackGround pt_CaptureVideo1Frame()
//CtrlBackGround start, period =round(TicksFreq/FramesPerSec), NoBurst =1
CtrlNamedBackground VidBGTask, Start, period =round(TicksFreq/FramesPerSec), proc = pt_CaptureVideo1Frame, burst =0
//cmd="Grabber EndPreview"
//Execute cmd
End

Function pt_CaptureVideo1Frame(s)
//STRUCT WMBackgroundStruct &s
STRUCT VidBGStruct &s

//Function pt_CaptureVideo1Frame()
//NVAR IterNum = IterNum
NVAR NFrames = NFrames
//String FldrName = s.name
NVAR VideoInstNum		=root:VideoInstNum
String FldrName 	= "root:VideoVars"+Num2Str(VideoInstNum)
SVAR WBaseNameStr	=$(FldrName+":WBaseNameStrVar")
SVAR WNoteStr			=$(FldrName+":WNoteStrVar")
NVAR CurrFrameNum = $(FldrName+":CurrFrameNum")
NVAR IterNum = $(FldrName+":IterNum")
String WNoteStr1=WNoteStr
//String WNoteStr, WBaseNameStr
//Print s.Name
//Print s.WNoteStr
//string cmd="Grabber color=0"
//Execute cmd
String cmd="Grabber GrabFrame"
Execute cmd
//MyBGStruct1.WNoteStr = ""
//Print MyBGStructL.WNoteStr
//Print MyBGStructL.WBaseNameStr
//MyBGStructL.WNoteStr += "Date" 				+ ":"+		Date()+";"
//MyBGStructL.WNoteStr += "Time" 				+ ":"+		Time()+";"
WNoteStr1 +="Date" 					+ ":"+		Date()+";"
WNoteStr1 +="Time" 					+ ":"+		Time()+";"

//WNoteStr = MyBGStructL.WNoteStr
//WBaseNameStr = MyBGStructL.WBaseNameStr
Redimension/N=(-1,-1) M_Frame	// convert to monochrome
Note M_Frame, WNoteStr1
Duplicate /O M_Frame, $(WBaseNameStr+"_"+pt_PadZeros2IntNumCopy(CurrFrameNum, 5))

CurrFrameNum+=1
//Print CurrFrameNum, time()
If (CurrFrameNum<NFrames)
	Return 0
Else
// Copy final frame to channel folder for display
	Duplicate /O M_Frame, $(WBaseNameStr)
// Call pt_VideoEOSH()
//	pt_VideoEOSH("VideoCall")
	Return 1
EndIf
End

// Somehow couldn't make the arbitrary structure with 1st element as an instance of WMBackgroundStruct
// to work
Structure VidBGStruct
	STRUCT WMBackgroundStruct b
//	String WBaseNameStr
//	String WNoteStr
EndStructure

Function pt_MakeMovie(MovieFileName, FrameMatchStr)
//pt_MakeMovie("AMovie", "Video_0001_*")
String MovieFileName, FrameMatchStr
String FramesList, FrameNameStr
Variable NumFrames, i
FramesList = Wavelist(FrameMatchStr,";","")
NumFrames = ItemsInList(FramesList, ";")

Print NumFrames, i
For (i=0; i<NumFrames; i+=1)
	FrameNameStr=StringFromList(i, FramesList, ";")
//	ImageSave /IGOR /O $FrameNameStr as "TmpFrameImage"
	NewImage $FrameNameStr
	DoWindow /C TmpImageWindow
//	AppendImage /W=TmpImageWindow $FrameNameStr
	If (i==0)
	NewMovie /A/F=16 /O as MovieFileName
	EndIf
	AddMovieFrame
	DoWindow /K TmpImageWindow
EndFor
CloseMovie
End

Function pt_MakeMovieWGraph(MovieFileName, FrameMatchStr, GraphWMatchStr)
//pt_MakeMovie("AMovie", "Video_0001_*")
String MovieFileName, FrameMatchStr, GraphWMatchStr
String FramesList, FrameNameStr, ExecuteStr
Variable NumFrames, i
FramesList = Wavelist(FrameMatchStr,";","")
NumFrames = ItemsInList(FramesList, ";")


PathInfo home
If (V_Flag==0)
	Abort "Please save the experiment first!"
EndIf
NewPath /O/Q/C SymblkHDFolderPath, S_Path
Print NumFrames, i
For (i=0; i<NumFrames; i+=1)
	FrameNameStr=StringFromList(i, FramesList, ";")
//	ImageSave /IGOR /O $FrameNameStr as "TmpFrameImage"
	DoWindow TmpImageWindow
	If (V_flag)
	DoWindow /K TmpImageWindow
	EndIf
	NewImage $FrameNameStr
	DoWindow /C TmpImageWindow
	ModifyGraph /W=TmpImageWindow minor=0
	ModifyGraph /W=TmpImageWindow nolabel=2
	ModifyGraph /W=TmpImageWindow axThick=0
	
	DoWindow TmpGraphWindow
	If (V_flag)
	DoWindow /K TmpGraphWindow
	EndIf
	Display $GraphWMatchStr
	DoWindow /C TmpGraphWindow
	SetAxis /W=TmpGraphWindow left -0.0006,0.0006
	SetAxis /W=TmpGraphWindow bottom 0+(1/16)*i,2+(1/16)*i //(1/16)*i,  (1/16)*(i+1)
	
	DoWindow TmpVideoFrameLayout
	If (V_flag)
	DoWindow /K TmpVideoFrameLayout
	EndIf
	NewLayOut
	DoWindow /C  TmpVideoFrameLayout
	AppendLayOutObject /F=0/W= TmpVideoFrameLayout graph TmpImageWindow
	AppendLayOutObject /F=0/W= TmpVideoFrameLayout graph TmpGraphWindow
	ExecuteStr="Tile TmpImageWindow,TmpGraphWindow"
	Execute ExecuteStr
	
	SavePICT/O/Q=1.0/P=SymblkHDFolderPath/T="JPEG"/B=72 as "TmpVideoFrameLayout.jpg"
	ImageLoad /Q/O/P=SymblkHDFolderPath/T=jpeg "TmpVideoFrameLayout.jpg"
	Print i
	DoWindow TmpVideoFrameWin
	If (V_flag)
	DoWindow /K TmpVideoFrameWin
	EndIf
	NewImage 'TmpVideoFrameLayout.jpg'
	DoWindow /C TmpVideoFrameWin
	ModifyGraph /W=TmpVideoFrameWin minor=0
	ModifyGraph /W=TmpVideoFrameWin nolabel=2
	ModifyGraph /W=TmpVideoFrameWin axThick=0
	
//	AppendImage /W=TmpImageWindow $FrameNameStr
	If (i==0)
	NewMovie /A/F=16 /O as MovieFileName
	EndIf
	AddMovieFrame
	DoWindow /K TmpVideoFrameWin
	KillWaves /Z 'TmpVideoFrameLayout.jpg'
EndFor
CloseMovie
DoWindow /K TmpImageWindow
DoWindow /K TmpGraphWindow
DoWindow /K TmpVideoFrameLayout
End

Function pt_NStrMatchInW(MatchStr, WNameStr)
// use for example to calculate number of EPhys input channels in IOWName
//Print pt_NStrMatchInW("*EPhysVars*In", "IOWName")
String MatchStr, WNameStr
Wave /T w 	= $WNameStr
Variable i, NStrMatch=0
Variable Nw = NumPnts(w)
For (i=0; i<Nw; i+=1)
If (StringMatch(w[i], MatchStr))
NStrMatch +=1
EndIf
EndFor
// function to calculate how many channels of a particular type are being scanned
Return NStrMatch
End

Function pt_NumIOForCh(IODevFldrNameW, MatchStr, SlctVarName)
String IODevFldrNameW, MatchStr, SlctVarName
// pt_NumIOForCh("IODevFldr", "EPhysVars", ":EPhysInWaveSlctVar")
String ChNameStr
Variable i, NumIODevFldr, NumChSlct=0
Wave /T IODevFldr = $(IODevFldrNameW)
NumIODevFldr = NumPnts(IODevFldr)
For (i=0; i<NumIODevFldr; i+=1)
ChNameStr = IODevFldr[i]
//If (StringMatch(ChNameStr, MatchStr))
If (StringMatch(ChNameStr, "root:"+MatchStr+"*"))
NVAR EPhysInWaveSlctVar 	=$ChNameStr+SlctVarName
If (EPhysInWaveSlctVar==1)
NumChSlct +=1
EndIf
EndIf
EndFor
Return NumChSlct
End

Function /s pt_InstListIOForCh(IODevFldrNameW, MatchStr, SlctVarName)
String IODevFldrNameW, MatchStr, SlctVarName
// pt_NumIOForCh("IODevFldr", "EPhysVars", ":EPhysInWaveSlctVar")
String ChNameStr, InstListChSlct="", ChInstStr
Variable i, NumIODevFldr
Wave /T IODevFldr = $(IODevFldrNameW)
NumIODevFldr = NumPnts(IODevFldr)
For (i=0; i<NumIODevFldr; i+=1)
ChNameStr = IODevFldr[i]
//If (StringMatch(ChNameStr, MatchStr))
If (StringMatch(ChNameStr, "root:"+MatchStr+"*"))
NVAR EPhysInWaveSlctVar 	=$ChNameStr+SlctVarName
If (EPhysInWaveSlctVar==1)
sscanf ChNameStr, "root:EPhysVars%s", ChInstStr
InstListChSlct +=ChInstStr+";"
EndIf
EndIf
EndFor
Return InstListChSlct
End

Function /s pt_FldrsListInDfr(IgorParentFolderPath, IgorChildObjNameMatchStr, ObjType)
String IgorParentFolderPath, IgorChildObjNameMatchStr
Variable ObjType

DFREF dfr = $IgorParentFolderPath
String ObjList="", Str
Variable NumChildObjs,i
NumChildObjs = CountObjectsDFR(dfr,ObjType)
For (i=0; i<NumChildObjs; i+=1)
Str = GetIndexedObjNameDFR(dfr, ObjType, i)
If (StringMatch(Str, IgorChildObjNameMatchStr+"*"))
ObjList += Str+";" 
EndIf
EndFor
Return ObjList
End