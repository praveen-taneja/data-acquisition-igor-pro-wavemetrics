#pragma rtGlobals=1		// Use modern global access method.
Function pt_PlotCursorDiff(GraphName)
String GraphName
// A quick script to plot response amplitude so that we can check when the
// response is stable.
// logic - Make a new graph.
// Append to graph the difference between cursor B - cursor A from
// a specified graph. The function needs to run after every data aquisition iteration
Variable y2, y1
DoWindow pt_PlotCursorDiff_Display // if window is closed, assume new trace
If (V_Flag ==0)
	Make /O/N=0 CursorDiffW
	Display 
	DoWindow /C pt_PlotCursorDiff_Display
	AppendToGraph /W = pt_PlotCursorDiff_Display CursorDiffW
	ModifyGraph /W = pt_PlotCursorDiff_Display mode=4,marker=19
EndIf
Make /O/N=1 CursorDiffWTemp
y1 = vcsr(A, GraphName)
y2 = vcsr(B, GraphName)
CursorDiffWTemp[0] = y2 - y1
Concatenate /NP {CursorDiffWTemp}, CursorDiffW
End