Attribute VB_Name = "CodeXRAYPlot"
' (c) Copyright 1995-2015 by John J. Donovan
Option Explicit
' Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal
' in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
' copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
'
' The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

' THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
' FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
' IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Sub XrayPlotConvert(tForm As Form, dx As Double, dy As Double, convdx As Double, convdy As Double)
' Generic code for plot unit conversions (data units to graph units)

ierror = False
On Error GoTo XrayPlotConvertError

If Not UseProEssentialsGraphics Then
Call XrayPlotConvert_GS(tForm, dx#, dy#, convdx#, convdy#)
If ierror Then Exit Sub
End If

Exit Sub

' Errors
XrayPlotConvertError:
MsgBox Error$, vbOKOnly + vbCritical, "XrayPlotConvert"
ierror = True
Exit Sub

End Sub

Sub XrayPlotConvert_GS(tForm As Form, dx As Double, dy As Double, convdx As Double, convdy As Double)
' Convert data units to Graph SDK units for drawing stage coordinates on graph (Graphics Server code)

ierror = False
On Error GoTo XrayPlotConvert_GSError

Dim xorg As Double, xlen As Double  ' in graph units
Dim xmin As Double, xmax As Double  ' in data units
Dim xoffset As Double, xscale As Double ' from data to graph units

Dim yorg As Double, ylen As Double  ' in graph units
Dim ymin As Double, ymax As Double  ' in data units
Dim yoffset As Double, yscale As Double ' from data to graph units

xorg# = tForm.Graph1.SDKInfo(7)
xlen# = tForm.Graph1.SDKInfo(5)
xmin# = tForm.Graph1.SDKInfo(2)
xmax# = tForm.Graph1.SDKInfo(1)

yorg# = tForm.Graph1.SDKInfo(8)
ylen# = tForm.Graph1.SDKInfo(6)
ymin# = tForm.Graph1.SDKInfo(4)
ymax# = tForm.Graph1.SDKInfo(3)

' Calculate scale factors
If xmax# - xmin# = 0 Then Exit Sub
If ymax# - ymin# = 0 Then Exit Sub
xscale# = xlen# / (xmax# - xmin#)
yscale# = ylen# / (ymax# - ymin#)

' X-axis is all negative
If xmax# < 0# Then
xoffset# = xorg# - (xmax# * xscale#)

' X-axis is all positive
ElseIf xmin# > 0# Then
xoffset# = xorg# - (xmin# * xscale#)

' Normal
Else
xoffset# = xorg#
End If

' Y-axis is all negative
If ymax# < 0# Then
yoffset# = yorg# - (ymax# * yscale#)

' Y-axis is all positive
ElseIf ymin# > 0# Then
yoffset# = yorg# - (ymin# * yscale#)

' Normal
Else
yoffset# = yorg#
End If

' Calculate converted values
convdx# = dx# * xscale# + xoffset#
convdy# = dy# * yscale# + yoffset#

Exit Sub

' Errors
XrayPlotConvert_GSError:
MsgBox Error$, vbOKOnly + vbCritical, "XrayPlotConvert_GS"
ierror = True
Exit Sub

End Sub

Sub XrayPlotConvert2(tForm As Form, dx As Double, dy As Double, convdx As Double, convdy As Double)
' Generic code for plot unit conversions  (graph units to data units)

ierror = False
On Error GoTo XrayPlotConvert2Error

If Not UseProEssentialsGraphics Then
Call XrayPlotConvert2_GS(tForm, dx#, dy#, convdx#, convdy#)
If ierror Then Exit Sub
End If

Exit Sub

' Errors
XrayPlotConvert2Error:
MsgBox Error$, vbOKOnly + vbCritical, "XrayPlotConvert2"
ierror = True
Exit Sub

End Sub

Sub XrayPlotConvert2_GS(tForm As Form, dx As Double, dy As Double, convdx As Double, convdy As Double)
' Convert Graph SDK units to data units (Graphics Server code)

ierror = False
On Error GoTo XrayPlotConvert2_GSError

Dim xorg As Double, xlen As Double  ' in graph units
Dim xmin As Double, xmax As Double  ' in data units
Dim xoffset As Double, xscale As Double ' from data to graph units

Dim yorg As Double, ylen As Double  ' in graph units
Dim ymin As Double, ymax As Double  ' in data units
Dim yoffset As Double, yscale As Double ' from data to graph units

xorg# = tForm.Graph1.SDKInfo(7)
xlen# = tForm.Graph1.SDKInfo(5)
xmin# = tForm.Graph1.SDKInfo(2)
xmax# = tForm.Graph1.SDKInfo(1)

yorg# = tForm.Graph1.SDKInfo(8)
ylen# = tForm.Graph1.SDKInfo(6)
ymin# = tForm.Graph1.SDKInfo(4)
ymax# = tForm.Graph1.SDKInfo(3)

' Calculate scale factors
If xmax# - xmin# = 0 Then Exit Sub
If ymax# - ymin# = 0 Then Exit Sub
xscale# = xlen# / (xmax# - xmin#)
yscale# = ylen# / (ymax# - ymin#)

' X-axis is all negative
If xmax# <= 0# Then
xoffset# = xorg# - (xmax# * xscale#)

' X-axis is all positive
ElseIf xmin# > 0# Then
xoffset# = xorg# - (xmin# * xscale#)

' Normal
Else
xoffset# = xorg#
End If

' Y-axis is all negative
If ymax# <= 0# Then
yoffset# = yorg# - (ymax# * yscale#)

' Y-axis is all positive
ElseIf ymin# > 0# Then
yoffset# = yorg# - (ymin# * yscale#)

' Normal
Else
yoffset# = yorg#
End If

' Calculate converted values
If xscale# <> 0# Then convdx# = (dx# - xoffset#) / xscale#
If yscale# <> 0# Then convdy# = (dy# - yoffset#) / yscale#

Exit Sub

' Errors
XrayPlotConvert2_GSError:
MsgBox Error$, vbOKOnly + vbCritical, "XrayPlotConvert2_GS"
ierror = True
Exit Sub

End Sub

Sub XrayPlotConvertGraph(tGraph As Graph, dx As Double, dy As Double, convdx As Double, convdy As Double)
' Generic code for plot unit conversions (data units to graph units)

ierror = False
On Error GoTo XrayPlotConvertGraphError

If Not UseProEssentialsGraphics Then
Call XrayPlotConvertGraph_GS(tGraph, dx#, dy#, convdx#, convdy#)
If ierror Then Exit Sub
End If

Exit Sub

' Errors
XrayPlotConvertGraphError:
MsgBox Error$, vbOKOnly + vbCritical, "XrayPlotConvertGraph"
ierror = True
Exit Sub

End Sub

Sub XrayPlotConvertGraph_GS(tGraph As Graph, dx As Double, dy As Double, convdx As Double, convdy As Double)
' Convert data units to Graph SDK units for drawing stage coordinates on graph (Graphics Server code)

ierror = False
On Error GoTo XrayPlotConvertGraph_GSError

Dim xorg As Double, xlen As Double  ' in graph units
Dim xmin As Double, xmax As Double  ' in data units
Dim xoffset As Double, xscale As Double ' from data to graph units

Dim yorg As Double, ylen As Double  ' in graph units
Dim ymin As Double, ymax As Double  ' in data units
Dim yoffset As Double, yscale As Double ' from data to graph units

xorg# = tGraph.SDKInfo(7)
xlen# = tGraph.SDKInfo(5)
xmin# = tGraph.SDKInfo(2)
xmax# = tGraph.SDKInfo(1)

yorg# = tGraph.SDKInfo(8)
ylen# = tGraph.SDKInfo(6)
ymin# = tGraph.SDKInfo(4)
ymax# = tGraph.SDKInfo(3)

' Calculate scale factors
If xmax# - xmin# = 0 Then Exit Sub
If ymax# - ymin# = 0 Then Exit Sub
xscale# = xlen# / (xmax# - xmin#)
yscale# = ylen# / (ymax# - ymin#)

' X-axis is all negative
If xmax# < 0# Then
xoffset# = xorg# - (xmax# * xscale#)

' X-axis is all positive
ElseIf xmin# > 0# Then
xoffset# = xorg# - (xmin# * xscale#)

' Normal
Else
xoffset# = xorg#
End If

' Y-axis is all negative
If ymax# < 0# Then
yoffset# = yorg# - (ymax# * yscale#)

' Y-axis is all positive
ElseIf ymin# > 0# Then
yoffset# = yorg# - (ymin# * yscale#)

' Normal
Else
yoffset# = yorg#
End If

' Calculate converted values
convdx# = dx# * xscale# + xoffset#
convdy# = dy# * yscale# + yoffset#

Exit Sub

' Errors
XrayPlotConvertGraph_GSError:
MsgBox Error$, vbOKOnly + vbCritical, "XrayPlotConvertGraph_GS"
ierror = True
Exit Sub

End Sub

Sub XrayPlotGetGraphExtents_GS(tForm As Form, xstart As Single, xstop As Single)
' Return the graph extents for the passed form (Graphics Server code)
' .SDKInfo(1)   X axis maximum (your data units)
' .SDKInfo(2)   X axis minimum (your data units)
' .SDKInfo(3)   Y axis maximum (your data units)
' .SDKInfo(4)   Y axis minimum (your data units)
' .SDKInfo(5)   X axis length (GS units)
' .SDKInfo(6)   Y axis length (GS units)
' .SDKInfo(7)   X origin (GS units)
' .SDKInfo(8)   Y origin (GS units)

ierror = False
On Error GoTo XrayPlotGetGraphExtents_GSError

xstart! = tForm.Graph1.SDKInfo(2)
xstop! = tForm.Graph1.SDKInfo(1)

Exit Sub

' Errors
XrayPlotGetGraphExtents_GSError:
MsgBox Error$, vbOKOnly + vbCritical, "XrayPlotGetGraphExtents_GS"
ierror = True
Exit Sub

End Sub

Sub XrayPlotGetGraphExtents_PE(tForm As Form, xstart As Single, xstop As Single)
' Return the graph extents for the passed form (Pro Essentials code)

ierror = False
On Error GoTo XrayPlotGetGraphExtents_PEError

xstart! = tForm.Pesgo1.ManualMinX
xstop! = tForm.Pesgo1.ManualMaxX

Exit Sub

' Errors
XrayPlotGetGraphExtents_PEError:
MsgBox Error$, vbOKOnly + vbCritical, "XrayPlotGetGraphExtents_PE"
ierror = True
Exit Sub

End Sub

Sub XrayPlotShowDateStamp_GS(tForm As Form, sample() As TypeSample)
' Show a date time file stamp in the corner (Graphics Server code)
' .SDKInfo(1)   X axis maximum (your data units)
' .SDKInfo(2)   X axis minimum (your data units)
' .SDKInfo(3)   Y axis maximum (your data units)
' .SDKInfo(4)   Y axis minimum (your data units)
' .SDKInfo(5)   X axis length (GS units)
' .SDKInfo(6)   Y axis length (GS units)
' .SDKInfo(7)   X origin (GS units)
' .SDKInfo(8)   Y origin (GS units)

ierror = False
On Error GoTo XrayPlotShowDateStamp_GSError

Dim r As Long
Dim xpos As Double, ypos As Double

' Display the filename and current time
xpos# = (tForm.Graph1.SDKInfo(7) + tForm.Graph1.SDKInfo(5)) / 2
ypos# = tForm.Graph1.SDKInfo(8) + tForm.Graph1.SDKInfo(6) + 50
r& = GSRText(xpos#, ypos#, 2, GSR_TXMID% + GSR_TXTOP% + GSR_TXTRANS%, 0, ProbeDataFile$ & ", " & Format$(CDate(sample(1).DateTimes(1))))

Exit Sub

' Errors
XrayPlotShowDateStamp_GSError:
MsgBox Error$, vbOKOnly + vbCritical, "XrayPlotShowDateStamp_GS"
ierror = True
Exit Sub

End Sub

Sub XrayPlotShowDateStamp_PE(tForm As Form, sample() As TypeSample)
' Show a date time file stamp in the corner (Pro Essentials code)

ierror = False
On Error GoTo XrayPlotShowDateStamp_PEError

Dim r As Long
Dim xpos As Double, ypos As Double

' Display the filename and current time
xpos# = (tForm.Graph1.SDKInfo(7) + tForm.Graph1.SDKInfo(5)) / 2
ypos# = tForm.Graph1.SDKInfo(8) + tForm.Graph1.SDKInfo(6) + 50
r& = GSRText(xpos#, ypos#, 2, GSR_TXMID% + GSR_TXTOP% + GSR_TXTRANS%, 0, ProbeDataFile$ & ", " & Format$(CDate(sample(1).DateTimes(1))))

Exit Sub

' Errors
XrayPlotShowDateStamp_PEError:
MsgBox Error$, vbOKOnly + vbCritical, "XrayPlotShowDateStamp_PE"
ierror = True
Exit Sub

End Sub


