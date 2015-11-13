Attribute VB_Name = "CodePenepma08Plot"
' (c) Copyright 1995-2015 by John J. Donovan
' Written by Gareth Seward under contract for Probe Software
Option Explicit

Sub Penepma08GraphLoad_PE(Index As Integer, tBeamTitle As String)
' Load the specified graph (using Pro Essentials code)

ierror = False
On Error GoTo Penepma08GraphLoad_PEError

' With or w/o log scale
If UseLogScale Then
FormPENEPMA08_PE.Pesgo1.YAxisScaleControl = PEAC_LOG&
Else
FormPENEPMA08_PE.Pesgo1.YAxisScaleControl = PEAC_NORMAL&
End If

' With or w/o gridlines
If UseGridLines Then
FormPENEPMA08_PE.Pesgo1.GridLineControl = PEGLC_BOTH&       ' x and y grid
FormPENEPMA08_PE.Pesgo1.GridBands = True                    ' adds colour banding on background
Else
FormPENEPMA08_PE.Pesgo1.GridLineControl = PEGLC_NONE&
FormPENEPMA08_PE.Pesgo1.GridBands = False                   ' removes colour banding on background
End If

' Axis Titles
If Index% = 0 Then FormPENEPMA08_PE.Pesgo1.YAxisLabel = "Photon Intensity"
If Index% = 1 Then FormPENEPMA08_PE.Pesgo1.YAxisLabel = "Photon Intensity"
If Index% = 2 Then FormPENEPMA08_PE.Pesgo1.YAxisLabel = "Electron Intensity"
FormPENEPMA08_PE.Pesgo1.XAxisLabel = "Energy eV"

' Format X and Y axis location etc. if needed
FormPENEPMA08_PE.Pesgo1.AxisNumberSpacing = 5#
FormPENEPMA08_PE.Pesgo1.ImageAdjustTop = 100                ' for appearance
FormPENEPMA08_PE.Pesgo1.ImageAdjustLeft = 100

FormPENEPMA08_PE.Pesgo1.PlottingMethod = SGPM_BAR&
'FormPENEPMA08_PE.Pesgo1.AxisNumericFormatY = PEANF_EXP_NOTATION_3X&
FormPENEPMA08_PE.Pesgo1.AxisNumericFormatY = PEANF_EXP_NOTATION&

FormPENEPMA08_PE.Pesgo1.SubTitle = vbNullString
FormPENEPMA08_PE.Pesgo1.BorderTypes = PETAB_SINGLE_LINE&
FormPENEPMA08_PE.Pesgo1.AxisBorderType = PEABT_THIN_LINE&

FormPENEPMA08_PE.Pesgo1.DpiX = 450
FormPENEPMA08_PE.Pesgo1.DpiY = 450

FormPENEPMA08_PE.Pesgo1.RenderEngine = PERE_GDIPLUS&

FormPENEPMA08_PE.Pesgo1.PEactions = REINITIALIZE_RESETIMAGE&
Call FormPENEPMA08_PE.Pesgo1.PEreinitialize
Call FormPENEPMA08_PE.Pesgo1.PEresetimage(0, 0)
Call FormPENEPMA08_PE.Pesgo1.PEInvalidate

Exit Sub

' Errors
Penepma08GraphLoad_PEError:
MsgBox Error$, vbOKOnly + vbCritical, "Penepma08GraphLoad_PE"
Close #Temp1FileNumber%
ierror = True
Exit Sub

End Sub

Sub Penepma08GraphUpdate_PE(Index As Integer, tBeamEnergy As Double, tBeamTitle As String, nPoints As Long, xdata() As Double, ydata() As Double)
' Update the specified graph (using Pro Essentials code)

ierror = False
On Error GoTo Penepma08GraphUpdate_PEError

Dim i As Integer
Dim ymin As Single, ymax As Single

' Get graph data
Call Penepma08GraphGetData(Index%)
If ierror Then Exit Sub

If nPoints& < 1 Then Exit Sub
FormPENEPMA08_PE.Pesgo1.Subsets = 1
FormPENEPMA08_PE.Pesgo1.Points = nPoints&

' Load y axis data
ymin! = MAXMINIMUM!
ymax! = MAXMAXIMUM!
For i% = 1 To (nPoints&)
If ydata#(i%) < ymin! And ydata#(i%) > 2E-35 Then ymin! = ydata#(i%) ' prevent logscale being stretched by values (rounding errors?)close to zero
If ydata#(i%) > ymax! Then ymax! = ydata#(i%)

' ProEssentials starts array at 0
FormPENEPMA08_PE.Pesgo1.UsingYDataII = True ' use double precision for PE y axis
FormPENEPMA08_PE.Pesgo1.YDataII(0, i% - 1) = ydata#(i%) ' YDataII is double precision for PE
Next i%

' Y axis format
If nPoints& > 0 Then
FormPENEPMA08_PE.Pesgo1.ManualScaleControlY = PEMSC_MINMAX&
FormPENEPMA08_PE.Pesgo1.ManualMinY = ymin!
FormPENEPMA08_PE.Pesgo1.ManualMaxY = ymax!
End If

' Load x axis data
For i% = 1 To (nPoints&)
FormPENEPMA08_PE.Pesgo1.xdata(0, i% - 1) = xdata#(i%)
Next i%

FormPENEPMA08_PE.Pesgo1.ManualScaleControlX = PEMSC_MINMAX&
FormPENEPMA08_PE.Pesgo1.ManualMinX = 0#
FormPENEPMA08_PE.Pesgo1.ManualMaxX = tBeamEnergy#

If Index% = 0 Then FormPENEPMA08_PE.Pesgo1.YAxisLabel = "Photon Intensity"
If Index% = 1 Then FormPENEPMA08_PE.Pesgo1.YAxisLabel = "Photon Intensity"
If Index% = 2 Then FormPENEPMA08_PE.Pesgo1.YAxisLabel = "Electron Intensity"
FormPENEPMA08_PE.Pesgo1.MainTitle = tBeamTitle$

FormPENEPMA08_PE.Pesgo1.SubsetColors(0) = FormPENEPMA08_PE.Pesgo1.PEargb(255, 205, 0, 0)

' Enable zoom
FormPENEPMA08_PE.Pesgo1.AllowZooming = PEAZ_HORZANDVERT&
FormPENEPMA08_PE.Pesgo1.ZoomStyle = PEZS_RO2_NOT&

' allow scroll after zoom
FormPENEPMA08_PE.Pesgo1.ScrollingHorzZoom = True
FormPENEPMA08_PE.Pesgo1.ScrollingVertZoom = True
FormPENEPMA08_PE.Pesgo1.MouseDraggingX = True
FormPENEPMA08_PE.Pesgo1.MouseDraggingY = True
FormPENEPMA08_PE.Pesgo1.ZoomWindow = True

FormPENEPMA08_PE.Pesgo1.AdjoinBars = True               ' bars full bin-width, yes or no?
FormPENEPMA08_PE.Pesgo1.DataShadows = PEDS_NONE&        ' no data shadows

' Show plot
FormPENEPMA08_PE.Pesgo1.PEactions = REINITIALIZE_RESETIMAGE&
Call FormPENEPMA08_PE.Pesgo1.PEreinitialize
Call FormPENEPMA08_PE.Pesgo1.PEresetimage(0, 0)
Call FormPENEPMA08_PE.Pesgo1.PEInvalidate

Exit Sub

' Errors
Penepma08GraphUpdate_PEError:
MsgBox Error$, vbOKOnly + vbCritical, "Penepma08GraphUpdate_PE"
Close #Temp1FileNumber%
ierror = True
Exit Sub

End Sub

Sub Penepma08GraphClear_PE()
' Clear the specified graph (using Pro Essentials code)

ierror = False
On Error GoTo Penepma08GraphClear_PEError

' Clear graph -  this plots blank graph!
FormPENEPMA08_PE.Pesgo1.Subsets = 1
FormPENEPMA08_PE.Pesgo1.Points = 1
FormPENEPMA08_PE.Pesgo1.xdata(0, 0) = 0                     ' empty subset
FormPENEPMA08_PE.Pesgo1.ydata(0, 0) = 0

FormPENEPMA08_PE.Pesgo1.MainTitle = "  "                    ' blank Chart title
FormPENEPMA08_PE.Pesgo1.SubTitle = " "
FormPENEPMA08_PE.Pesgo1.ManualScaleControlY = PEMSC_MINMAX& ' Manually Control Y Axis
FormPENEPMA08_PE.Pesgo1.ManualMinY = 0
FormPENEPMA08_PE.Pesgo1.ManualMaxY = 100
FormPENEPMA08_PE.Pesgo1.ManualScaleControlX = PEMSC_MINMAX& ' Manually Control X Axis
FormPENEPMA08_PE.Pesgo1.ManualMinX = 0
FormPENEPMA08_PE.Pesgo1.ManualMaxX = 15000

FormPENEPMA08_PE.Pesgo1.YAxisLabel = "Intensity"            ' Axis labels
FormPENEPMA08_PE.Pesgo1.XAxisLabel = "Energy eV"

FormPENEPMA08_PE.Pesgo1.ImageAdjustRight = 100              ' layout formatting
FormPENEPMA08_PE.Pesgo1.PlottingMethod = SGPM_BAR&          ' bargraph
FormPENEPMA08_PE.Pesgo1.PEactions = REINITIALIZE_RESETIMAGE&

Exit Sub

' Errors
Penepma08GraphClear_PEError:
MsgBox Error$, vbOKOnly + vbCritical, "Penepma08GraphClear_PE"
ierror = True
Exit Sub

End Sub

