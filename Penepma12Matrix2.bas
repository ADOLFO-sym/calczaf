Attribute VB_Name = "CodePenepma12Matrix2"
' (c) Copyright 1995-2015 by John J. Donovan
Option Explicit

Sub Penepma12MatrixNewMDB()
' This routine create a new the Matrix.mdb file

ierror = False
On Error GoTo Penepma12MatrixNewMDBError

Dim response As Integer

Dim MtDb As Database

' Specify the matrix database variables
Dim Matrix As TableDef

Dim MatrixKRatio As TableDef

Dim MatrixIndex As Index

' If file already exists, warn user
If Dir$(MatrixMDBFile$) <> vbNullString Then
msg$ = "Matrix Database: " & vbCrLf
msg$ = msg$ & MatrixMDBFile$ & vbCrLf
msg$ = msg$ & " already exists, are you sure you want to overwrite it?"
response% = MsgBox(msg$, vbYesNo + vbQuestion + vbDefaultButton2, "Penepma12MatrixNewMDB")
If response% = vbNo Then
ierror = True
Exit Sub
End If

' If matrix database exists, delete it
If Dir$(MatrixMDBFile$) <> vbNullString Then
Kill MatrixMDBFile$

' Else inform user
Else
msg$ = "Creating a new Matrix k-ratio database: " & MatrixMDBFile$
MsgBox msg$, vbOKOnly + vbInformation, "Penepma12MatrixNewMDB"
End If
End If

' Open the new database and create the tables
Screen.MousePointer = vbHourglass
Set MtDb = CreateDatabase(MatrixMDBFile$, dbLangGeneral)
If MtDb Is Nothing Or Err <> 0 Then GoTo Penepma12MatrixNewMDBError

' Specify the Matrix database "Matrix" table
Set Matrix = MtDb.CreateTableDef("NewTableDef")
Matrix.Name = "Matrix"

' Create matrix table fields
With Matrix
.Fields.Append .CreateField("BeamTakeOff", dbSingle)
.Fields.Append .CreateField("BeamEnergy", dbSingle)
.Fields.Append .CreateField("EmittingElement", dbInteger)
.Fields.Append .CreateField("EmittingXray", dbInteger)
.Fields.Append .CreateField("MatrixElement", dbInteger)

' Add unique record number for other tables
.Fields.Append .CreateField("MatrixNumber", dbLong)
End With

MtDb.TableDefs.Append Matrix

' Specify the matrix database "MatrixIndexPrimary" index
Set MatrixIndex = Matrix.CreateIndex("MatrixIndexPrimary")

With MatrixIndex
.Fields.Append .CreateField("MatrixNumber")            ' unique record number pointing to Matrix table
.Primary = True
End With

Matrix.Indexes.Append MatrixIndex

' Make k-ratio table
Set MatrixKRatio = MtDb.CreateTableDef("NewTableDef")
MatrixKRatio.Name = "MatrixKratio"

' Create matrix k-ratio table fields
With MatrixKRatio
.Fields.Append .CreateField("MatrixKRatioNumber", dbLong)           ' unique record number pointing to Matrix table
.Fields.Append .CreateField("MatrixKRatioOrder", dbInteger)         ' load order (1 to MAXBINARY%) (always 99 to 1 wt%)
.Fields.Append .CreateField("MatrixKRatio_ZAF_KRatio", dbSingle)    ' Penepma binary k-ratios
End With

MtDb.TableDefs.Append MatrixKRatio

' Specify the matrix database "MatrixIndex" index
Set MatrixIndex = Matrix.CreateIndex("MatrixIndexSecondary")

With MatrixIndex
.Fields.Append .CreateField("MatrixKRatioNumber")      ' unique record number pointing to MatrixKRatio table
End With

MatrixKRatio.Indexes.Append MatrixIndex

' Close the database
MtDb.Close
Screen.MousePointer = vbDefault

' Create new File table for matrix database
Call FileInfoMakeNewTable(Int(9), MatrixMDBFile$)
If ierror Then Exit Sub

msg$ = "New MATRIX.MDB has been created"
MsgBox msg$, vbOKOnly + vbInformation, "Penepma12MatrixNewMDB"

Exit Sub

' Errors
Penepma12MatrixNewMDBError:
Screen.MousePointer = vbDefault
MsgBox Error$, vbOKOnly + vbCritical, "Penepma12MatrixNewMDB"
Call IOStatusAuto(vbNullString)
ierror = True
Exit Sub

End Sub

Sub Penepma12MatrixScanMDB()
' This routine scans for all k-ratio input files and adds them to a new Matrix.mdb file with new k-ratios

ierror = False
On Error GoTo Penepma12MatrixScanMDBError

Dim i As Integer, l As Integer, m As Integer, n As Integer
Dim nrec As Long, k As Long, kk As Long
Dim tfilename As String, tfolder As String
Dim astring As String, bstring As String
Dim eng As Single, edg As Single
Dim temp As Single, tovervoltage As Single
Dim temp_f As Single, temp_za As Single
Dim response As Integer, tfilenumber As Integer
Dim errorsfound As Boolean

Dim tfilename2 As String
Dim tfilename3 As String
Dim tfilename4 As String

Dim filearray() As String

Dim BeamTakeOff As Single
Dim BeamEnergy As Single
Dim EmittingElement As Integer
Dim EmittingXray As Integer
Dim MatrixElement As Integer

Dim t1 As Single, t2 As Single

Dim MtDb As Database
Dim MtDt As Recordset

icancelauto = False
errorsfound = False

' Warn if less than 1.0 keV minimum energy
If PenepmaMinimumElectronEnergy! < 1# And FormPENEPMA12.CheckAutoAdjustMinimumEnergy.Value = vbUnchecked Then
msg$ = "The minimum electron energy for Penepma kratio extractions is less than 1 keV. Since Penfluor only calculates down to 1 keV by default, this might be problematic. Do you want to continue?"
response% = MsgBox(msg$, vbOKCancel + vbQuestion + vbDefaultButton2, "Penepma12MatrixScanMDB")
If response% = vbCancel Then Exit Sub
End If

' If file does not exist, warn user
If Dir$(MatrixMDBFile$) = vbNullString Then
msg$ = "Matrix Database: " & vbCrLf
msg$ = msg$ & MatrixMDBFile$ & vbCrLf
msg$ = msg$ & " does not exist. Please create a new Matrix.MDB file try updating again."
MsgBox msg$, vbOKOnly + vbExclamation, "Penepma12MatrixScanMDB"
ierror = True
Exit Sub
End If

' Check for Fanal\matrix folder
tfolder$ = PENEPMA_Root$ & "\Fanal\matrix"
If Dir$(tfolder$, vbDirectory) = vbNullString Then GoTo Penepma12MatrixScanMDBNoDirectory

' Delete existing binary matrix histogram calculation files
tfilename2$ = OriginalCalcZAFDATDirectory$ & "\Penepma12_Exper_kratios_flu.dat"
If Dir$(tfilename2$) <> vbNullString Then Kill tfilename2$
tfilename3$ = OriginalCalcZAFDATDirectory$ & "\Penepma12_Exper_kratios_za.dat"
If Dir$(tfilename3$) <> vbNullString Then Kill tfilename3$
tfilename4$ = OriginalCalcZAFDATDirectory$ & "\Penepma12_Exper_kratios_all.dat"
If Dir$(tfilename4$) <> vbNullString Then Kill tfilename4$

' Make a list of all input files (must do this way to avoid reentrant Dir$ calls)
tfilename$ = Dir$(PENEPMA_Root$ & "\Fanal\Matrix\" & "\*.TXT")  ' get first file
kk& = 0
Do While tfilename$ <> vbNullString
If tfilename$ <> "temp.txt" Then
kk& = kk& + 1
ReDim Preserve filearray(1 To kk&) As String
filearray$(kk&) = tfilename$
End If
tfilename$ = Dir$
Loop

' Delete Standard.txt file if present
If Dir$(ProbeTextLogFile$) <> vbNullString Then
Kill ProbeTextLogFile$
End If

' Open the matrix.mdb
Set MtDb = OpenDatabase(MatrixMDBFile$, MatrixDatabaseExclusiveAccess%, False)

' Check if database already has entries
Set MtDt = MtDb.OpenRecordset("Matrix", dbOpenTable)
If Not (MtDt.BOF And MtDt.EOF) Then GoTo Penepma12MatrixScanMDBNotEmpty
MtDt.Close

' Load filenumber for testing output
tfilenumber% = FreeFile()

' Loop through all input files
nrec& = 0
For k& = 1 To kk&
tfilename$ = filearray$(k&)

' Determine the emitting element and matrix element from the filename
astring$ = MiscGetFileNameOnly$(tfilename$)
Call MiscParseStringToStringA(astring$, "-", bstring$)
EmittingElement% = Val(bstring$)
Call MiscParseStringToStringA(astring$, "_", bstring$)
MatrixElement% = Val(bstring$)

' Check for Li, Be, B, C, N, O, F or Ne and adjust minimum energy if so
If FormPENEPMA12.CheckAutoAdjustMinimumEnergy.Value = vbChecked Then
Call Penepma12AdjustMinimumEnergy2(Symlo$(EmittingElement%))
If ierror Then Exit Sub
End If

' Check for takeoff angle (usually 40 or 52.5)
n% = InStr(astring$, ".txt")
BeamTakeOff! = Val(Left$(astring$, n% - 1))

' Loop on each possible energy
For m% = 5 To 50         ' Fanal calculations are only good down to 5 keV at this time
'For m% = 1 To 50
'For m% = 15 To 15       ' testing purposes (15 keV only)
BeamEnergy! = CSng(m%)

' Read binary k-ratio data to file for the specified beam energy
Call Penepma12CalculateReadWriteBinaryDataMatrix(Int(1), tfolder$, tfilename$, CSng(m%))
If ierror Then Exit Sub

' Loop on each valid x-ray
For l% = 1 To MAXRAY_OLD%       'only original x-ray lines for now
'For l% = 1 To 1                 ' testing purposes (Ka only)
EmittingXray% = l%

Call XrayGetEnergy(EmittingElement%, EmittingXray%, eng!, edg!)
If ierror Then Exit Sub

' Load minimum overvoltage, 0 = 2%, 1 = 10%, 2 = 20%, 3 = 40%
If MinimumOverVoltageType% = 0 Then tovervoltage! = MINIMUMOVERVOLTFRACTION_02!
If MinimumOverVoltageType% = 1 Then tovervoltage! = MINIMUMOVERVOLTFRACTION_10!
If MinimumOverVoltageType% = 2 Then tovervoltage! = MINIMUMOVERVOLTFRACTION_20!
If MinimumOverVoltageType% = 3 Then tovervoltage! = MINIMUMOVERVOLTFRACTION_40!

' Check for valid x-ray line (excitation energy (plus a buffer to avoid ultra low overvoltage issues) must be less than beam energy) (and greater than PenepmaMinimumElectronEnergy!)
If eng! <> 0# And edg! <> 0# And (edg! * (1# + tovervoltage!) < BeamEnergy!) And edg! > PenepmaMinimumElectronEnergy! Then

' Double check that specific transition exists
' "K L3" l% = 1          ' (Ka) (see table 6.2 in Penelope-2006-NEA-pdf)
' "K M3" l% = 2          ' (Kb)
' "L3 M5" l% = 3         ' (La)
' "L2 M4" l% = 4         ' (Lb)
' "M5 N7" l% = 5         ' (Ma)
' "M4 N6" l% = 6         ' (Mb)
Call PenepmaGetPDATCONFTransition(EmittingElement%, EmittingXray%, t1!, t2!)
If ierror Then Exit Sub

' If both shells have ionization energies, it is ok
If t1! <> 0# And t2! <> 0# Then

' Check for valid k-ratios (less than or equal to zero)
For i% = 1 To MAXBINARY%
If Binary_ZAF_Kratios#(l%, i%) <= 0# Then
errorsfound = True
msg$ = "Penepma12MatrixScanMDB: K-ratio number " & Format$(i%) & " (" & Format$(Binary_ZAF_Kratios#(l%, i%)) & ") is less than or equal to zero for " & Symup$(EmittingElement%) & " " & Xraylo$(EmittingXray%) & " in " & Symup$(MatrixElement%) & " at " & Format$(BeamEnergy!) & " keV : " & tfilename$ & " (skipping this binary record)..."
If DebugMode Then MiscMsgBoxTim FormMSGBOXTIME, "Penepma12MatrixScanMDB", msg$, 5#
Call IOWriteError(msg$, "Penepma12MatrixScanMDB")
If ierror Then Exit Sub
GoTo SkipThisRecord         ' skip saving all MAXBINARY% k-ratios for this beam energy and x-ray line situation
End If

' Warn if very large ZAF correction
temp! = BinaryRanges!(i%) / CSng(Binary_ZAF_Kratios#(l%, i%))
If temp! < 0.6 Or temp! > 5# Then
If DebugMode Then
msg$ = "Warning: very large matrix correction (ZAF=" & MiscAutoFormat$(temp!) & ", K=" & MiscAutoFormat$(CSng(Binary_ZAF_Kratios#(l%, i%))) & ", C=" & Format$(BinaryRanges!(i%)) & ") for " & Symup$(EmittingElement%) & " " & Xraylo$(EmittingXray%) & " in " & Symup$(MatrixElement%) & " at " & Format$(BeamEnergy!) & " keV : " & tfilename$ & "..."
Call IOWriteLog(msg$)
Else
If m% >= 5 And m% <= 30 Then    ' only print problematic matrix corrections if between 5 and 30 keV
msg$ = "Warning: very large matrix correction (ZAF=" & MiscAutoFormat$(temp!) & ", K=" & MiscAutoFormat$(CSng(Binary_ZAF_Kratios#(l%, i%))) & ", C=" & Format$(BinaryRanges!(i%)) & ") for " & Symup$(EmittingElement%) & " " & Xraylo$(EmittingXray%) & " in " & Symup$(MatrixElement%) & " at " & Format$(BeamEnergy!) & " keV : " & tfilename$ & "..."
Call IOWriteText(msg$)
Call IOWriteLog(msg$)
End If
End If
End If

' Now check for binary output suitable for error histogram calculations in CalcZAF
' Data file format assumes one line for each binary. The first two columns are the atomic numbers of the two binary components
' to be calculated. The second two columns are the xray lines to use. ( 1 = Ka, 2 = Kb, 3 = La, 4 = Lb, 5 = Ma, 6 = Mb, 7 = by difference). The next
' two columns are the operating voltage and take-off angle. The next two columns are the wt. fractions of the binary components. The
' last two columns contains the k-exp values for calculation of k-calc/k-exp.
'
'       79     29     5    7    15.     52.5    .8015   .1983   .7400   .0
'       79     29     5    7    15.     52.5    .6036   .3964   .5110   .0
'       79     29     5    7    15.     52.5    .4010   .5992   .3120   .0
'       79     29     5    7    15.     52.5    .2012   .7985   .1450   .0

' Only concentration greater than 5% and overvoltages greater than 1.5 for resonable precision
If BinaryRanges!(i%) > 5# And BeamEnergy! / edg! >= 1.5 Then

' Output only 5, 10, 15 and 20 keV
If m% = 5 Or m% = 10 Or m% = 15 Or m% = 20 Then

' Check for non zero F and ZA k-ratios
If Binary_F_Kratios#(l%, i%) > 0# And Binary_ZA_Kratios#(l%, i%) > 0# Then

' Calculate F and ZA correction factors
temp_f! = BinaryRanges!(i%) / CSng(Binary_F_Kratios#(l%, i%))
temp_za! = BinaryRanges!(i%) / CSng(Binary_ZA_Kratios#(l%, i%))

' If correction meets criteria, output normal (ZAF) k-ratio for binary histogram calculation
If temp_f! < 0.9 Then
tfilename2$ = OriginalCalcZAFDATDirectory$ & "\Penepma12_Exper_kratios_flu.dat"
Open tfilename2$ For Append As #tfilenumber%
Print #tfilenumber%, Format$(EmittingElement%), Format$(MatrixElement%), Format$(EmittingXray%), Format$(MAXRAY%), Format$(BeamEnergy!), Format$(BeamTakeOff!), Format$(BinaryRanges!(i%) / 100#), Format$((100# - BinaryRanges!(i%)) / 100#), Format$(CSng(Binary_ZAF_Kratios#(l%, i%) / 100#), f86$), Format$(0#, f86$)
Close #tfilenumber%
End If

If temp_za! > 1.1 Then
tfilename3$ = OriginalCalcZAFDATDirectory$ & "\Penepma12_Exper_kratios_za.dat"
Open tfilename3$ For Append As #tfilenumber%
Print #tfilenumber%, Format$(EmittingElement%), Format$(MatrixElement%), Format$(EmittingXray%), Format$(MAXRAY%), Format$(BeamEnergy!), Format$(BeamTakeOff!), Format$(BinaryRanges!(i%) / 100#), Format$((100# - BinaryRanges!(i%)) / 100#), Format$(CSng(Binary_ZAF_Kratios#(l%, i%) / 100#), f86$), Format$(0#, f86$)
Close #tfilenumber%
End If

tfilename4$ = OriginalCalcZAFDATDirectory$ & "\Penepma12_Exper_kratios_all.dat"
Open tfilename4$ For Append As #tfilenumber%
Print #tfilenumber%, Format$(EmittingElement%), Format$(MatrixElement%), Format$(EmittingXray%), Format$(MAXRAY%), Format$(BeamEnergy!), Format$(BeamTakeOff!), Format$(BinaryRanges!(i%) / 100#), Format$((100# - BinaryRanges!(i%)) / 100#), Format$(CSng(Binary_ZAF_Kratios#(l%, i%) / 100#), f86$), Format$(0#, f86$)
Close #tfilenumber%

End If
End If
End If
Next i%

' Add new records to "Matrix" table
Set MtDt = MtDb.OpenRecordset("Matrix", dbOpenTable)
nrec& = nrec& + 1
Call IOStatusAuto("Adding record " & Format$(nrec&) & ", " & Format$(m%) & " keV, " & Symup$(EmittingElement%) & " " & Xraylo$(EmittingXray%) & " to Matrix.MDB with input file, " & tfilename$ & "...")
DoEvents

' Add new record
MtDt.AddNew
MtDt("BeamTakeOff") = BeamTakeOff!
MtDt("BeamEnergy") = BeamEnergy!
MtDt("EmittingElement") = EmittingElement%
MtDt("EmittingXray") = EmittingXray%
MtDt("MatrixElement") = MatrixElement%

' Add unique record number for other tables
MtDt("MatrixNumber") = nrec&
MtDt.Update
MtDt.Close

' Add new records to "Kratios" table
Set MtDt = MtDb.OpenRecordset("MatrixKratio", dbOpenTable)
For i% = 1 To MAXBINARY%
MtDt.AddNew
MtDt("MatrixKRatioNumber") = nrec&                                      ' unique record number pointing to Matrix table
MtDt("MatrixKRatioOrder") = i%                                          ' load order (1 to MAXBINARY%) (always 99 to 1 wt%)
MtDt("MatrixKRatio_ZAF_KRatio") = CSng(Binary_ZAF_Kratios#(l%, i%))     ' Penepma binary k-ratio
MtDt.Update
Next i%
MtDt.Close

' Check for user cancel
DoEvents
If icancelauto Then
ierror = True
Exit Sub
End If

' Check for Pause button
Do Until Not RealTimePauseAutomation
DoEvents
Sleep 200
Loop

SkipThisRecord:
End If
End If
Next l%
Next m%

' Get next input filename
Next k&

MtDb.Close
Call IOStatusAuto(vbNullString)

If nrec& > 0 Then
msg$ = "MATRIX.MDB has been updated with " & Format$(nrec&) & " matrix records"
MsgBox msg$, vbOKOnly + vbInformation, "Penepma12MatrixScanMDB"

Else
msg$ = "No Matrix.MDB k-ratio input .TXT files were found in the Fanal\Matrix folder"
MsgBox msg$, vbOKOnly + vbInformation, "Penepma12MatrixScanMDB"
End If

' Warn if errors found
If errorsfound Then
msg$ = "Some bad k-ratio values (<= zero) were found in some Fanal matrix .TXT files. This is usually caused by statistical issues at low overvoltages or with very weak emission lines." & vbCrLf & vbCrLf
msg$ = msg$ & "See the error file " & ProbeErrorLogFile$ & " for more details."
MsgBox msg$, vbOKOnly + vbInformation, "Penepma12MatrixScanMDB"
End If

Exit Sub

' Errors
Penepma12MatrixScanMDBError:
Screen.MousePointer = vbDefault
MsgBox Error$ & ", keV= " & Format$(m%) & ", " & Symup$(EmittingElement%) & " " & Xraylo$(l%) & " in " & Symup$(MatrixElement%) & ", binary num= " & Format$(i%), vbOKOnly + vbCritical, "Penepma12MatrixScanMDB"
Call IOStatusAuto(vbNullString)
Close #tfilenumber%
ierror = True
Exit Sub

Penepma12MatrixScanMDBNoDirectory:
msg$ = "The matrix data folder " & tfolder$ & " was not found"
MsgBox msg$, vbOKOnly + vbExclamation, "Penepma12MatrixScanMDB"
Call IOStatusAuto(vbNullString)
ierror = True
Exit Sub

Penepma12MatrixScanMDBNotEmpty:
msg$ = "The matrix database already contains intensity entires. Please create a new matrix.mdb file and try updating it again."
MsgBox msg$, vbOKOnly + vbExclamation, "Penepma12MatrixScanMDB"
Call IOStatusAuto(vbNullString)
ierror = True
Exit Sub

End Sub

Sub Penepma12PureNewMDB()
' This routine creates a new Pure.mdb file

ierror = False
On Error GoTo Penepma12PureNewMDBError

Dim response As Integer

Dim PrDb As Database

' Specify the pure database variables
Dim Pure As TableDef
Dim PureIntensity As TableDef
Dim PureIndex As Index

' If file already exists, warn user
If Dir$(PureMDBFile$) <> vbNullString Then
msg$ = "Pure Database: " & vbCrLf
msg$ = msg$ & PureMDBFile$ & vbCrLf
msg$ = msg$ & " already exists, are you sure you want to overwrite it?"
response% = MsgBox(msg$, vbYesNo + vbQuestion + vbDefaultButton2, "Penepma12PureNewMDB")
If response% = vbNo Then
ierror = True
Exit Sub
End If

' If pure database exists, delete it
If Dir$(PureMDBFile$) <> vbNullString Then
Kill PureMDBFile$

' Else inform user
Else
msg$ = "Creating a new Pure element intensity database: " & PureMDBFile$
MsgBox msg$, vbOKOnly + vbInformation, "Penepma12PureNewMDB"
End If
End If

' Open the new database and create the tables
Screen.MousePointer = vbHourglass
Set PrDb = CreateDatabase(PureMDBFile$, dbLangGeneral)
If PrDb Is Nothing Or Err <> 0 Then GoTo Penepma12PureNewMDBError

' Specify the Pure database "Pure" table
Set Pure = PrDb.CreateTableDef("NewTableDef")
Pure.Name = "Pure"

' Create pure table fields
With Pure
.Fields.Append .CreateField("BeamTakeOff", dbSingle)
.Fields.Append .CreateField("BeamEnergy", dbSingle)
.Fields.Append .CreateField("EmittingElement", dbInteger)
.Fields.Append .CreateField("EmittingXray", dbInteger)
.Fields.Append .CreateField("PureNumber", dbLong)                 ' unique record number pointing to Pure table
End With

PrDb.TableDefs.Append Pure

' Specify the pure database "PureIndexPrimary" index
Set PureIndex = Pure.CreateIndex("PureIndexPrimary")

With PureIndex
.Fields.Append .CreateField("PureNumber")            ' unique record number pointing to Pure table
.Primary = True
End With

Pure.Indexes.Append PureIndex

' Make PureIntensity table
Set PureIntensity = PrDb.CreateTableDef("NewTableDef")
PureIntensity.Name = "PureIntensity"

' Create pure element intensity table fields
With PureIntensity
.Fields.Append .CreateField("PureIntensityNumber", dbLong)                 ' unique record number pointing to Pure table
.Fields.Append .CreateField("PureIntensityGenerated", dbSingle)            ' Penepma pure element generated intensities
.Fields.Append .CreateField("PureIntensityEmitted", dbSingle)              ' Penepma pure element emitted intensities
End With

PrDb.TableDefs.Append PureIntensity

' Close the database
PrDb.Close
Screen.MousePointer = vbDefault

' Create new File table for pure database
Call FileInfoMakeNewTable(Int(11), PureMDBFile$)
If ierror Then Exit Sub

msg$ = "New Pure.MDB has been created"
MsgBox msg$, vbOKOnly + vbInformation, "Penepma12PureNewMDB"

Exit Sub

' Errors
Penepma12PureNewMDBError:
Screen.MousePointer = vbDefault
MsgBox Error$, vbOKOnly + vbCritical, "Penepma12PureNewMDB"
Call IOStatusAuto(vbNullString)
ierror = True
Exit Sub

End Sub

Sub Penepma12PureScanMDB()
' This routine scans for all pure element intensities input files and adds them to a new Pure.mdb file

ierror = False
On Error GoTo Penepma12PureScanMDBError

Dim l As Integer, m As Integer, n As Integer
Dim nrec As Long, k As Long, kk As Long
Dim tfilename As String, tfolder As String
Dim astring As String, bstring As String
Dim eng As Single, edg As Single, tovervoltage As Single
Dim response As Integer, tfilenumber As Integer
Dim errorsfound As Boolean

Dim filearray() As String

Dim BeamTakeOff As Single
Dim BeamEnergy As Single
Dim EmittingElement As Integer
Dim EmittingXray As Integer

Dim t1 As Single, t2 As Single

Dim PrDb As Database
Dim PrDt As Recordset

icancelauto = False
errorsfound = False

' Warn if less than 1.0 keV minimum energy
If PenepmaMinimumElectronEnergy! < 1# And FormPENEPMA12.CheckAutoAdjustMinimumEnergy.Value = vbUnchecked Then
msg$ = "The minimum electron energy for Penepma intensity extractions is less than 1 keV. Since Penfluor only calculates down to 1 keV by default, this might be problematic. Do you want to continue?"
response% = MsgBox(msg$, vbOKCancel + vbQuestion + vbDefaultButton2, "Penepma12PureScanMDB")
If response% = vbCancel Then Exit Sub
End If

' If file does not exist, warn user
If Dir$(PureMDBFile$) = vbNullString Then
msg$ = "Pure Database: " & vbCrLf
msg$ = msg$ & PureMDBFile$ & vbCrLf
msg$ = msg$ & " does not exist. Please create a new Pure.MDB file try updating again."
MsgBox msg$, vbOKOnly + vbExclamation, "Penepma12PureScanMDB"
ierror = True
Exit Sub
End If

' Check for Fanal\Pure folder
tfolder$ = PENEPMA_Root$ & "\Fanal\Pure"
If Dir$(tfolder$, vbDirectory) = vbNullString Then GoTo Penepma12PureScanMDBNoDirectory

' Make a list of all input files (must do this way to avoid reentrant Dir$ calls)
tfilename$ = Dir$(PENEPMA_Root$ & "\Fanal\Pure\" & "\*.TXT")  ' get first file
kk& = 0
Do While tfilename$ <> vbNullString
If tfilename$ <> "temp.txt" Then
kk& = kk& + 1
ReDim Preserve filearray(1 To kk&) As String
filearray$(kk&) = tfilename$
End If
tfilename$ = Dir$
Loop

' Delete Standard.txt file if present
If Dir$(ProbeTextLogFile$) <> vbNullString Then
Kill ProbeTextLogFile$
End If

' Open the pure.mdb
Set PrDb = OpenDatabase(PureMDBFile$, PureDatabaseExclusiveAccess%, False)

' Check if database already has entries
Set PrDt = PrDb.OpenRecordset("Pure", dbOpenTable)
If Not (PrDt.BOF And PrDt.EOF) Then GoTo Penepma12PureScanMDBNotEmpty
PrDt.Close

' Load filenumber for testing output
tfilenumber% = FreeFile()

' Loop through all input files
nrec& = 0
For k& = 1 To kk&
tfilename$ = filearray$(k&)

' Determine the emitting element from the filename
astring$ = MiscGetFileNameOnly$(tfilename$)
Call MiscParseStringToStringA(astring$, "_", bstring$)
EmittingElement% = Val(bstring$)

' Check for Li, Be, B, C, N, O, F or Ne and adjust minimum energy if so
If FormPENEPMA12.CheckAutoAdjustMinimumEnergy.Value = vbChecked Then
Call Penepma12AdjustMinimumEnergy2(Symlo$(EmittingElement%))
If ierror Then Exit Sub
End If

' Check for takeoff angle (usually 40 or 52.5)
n% = InStr(astring$, ".txt")
BeamTakeOff! = Val(Left$(astring$, n% - 1))

' Loop on each possible energy
For m% = 1 To 50
'For m% = 5 To 5       ' testing purposes (5 keV only)
BeamEnergy! = CSng(m%)

' Read pure element intensity data to file for the specified beam energy
Call Penepma12CalculateReadWritePureElement(Int(1), tfolder$, tfilename$, CSng(m%))
If ierror Then Exit Sub

' Loop on each valid x-ray
For l% = 1 To MAXRAY_OLD%
'For l% = 1 To 1         ' testing purposes (Ka only)
EmittingXray% = l%

Call XrayGetEnergy(EmittingElement%, EmittingXray%, eng!, edg!)
If ierror Then Exit Sub

' Load minimum overvoltage, 0 = 2%, 1 = 10%, 2 = 20%, 3 = 40%
If MinimumOverVoltageType% = 0 Then tovervoltage! = MINIMUMOVERVOLTFRACTION_02!
If MinimumOverVoltageType% = 1 Then tovervoltage! = MINIMUMOVERVOLTFRACTION_10!
If MinimumOverVoltageType% = 2 Then tovervoltage! = MINIMUMOVERVOLTFRACTION_20!
If MinimumOverVoltageType% = 3 Then tovervoltage! = MINIMUMOVERVOLTFRACTION_40!

' Check for valid x-ray line (excitation energy (plus a buffer to avoid ultra low overvoltage issues) must be less than beam energy) (and greater than PenepmaMinimumElectronEnergy!)
If eng! <> 0# And edg! <> 0# And (edg! * (1# + tovervoltage!) < BeamEnergy!) And edg! > PenepmaMinimumElectronEnergy! Then

' Double check that specific transition exists
' "K L3" l% = 1          ' (Ka) (see table 6.2 in Penelope-2006-NEA-pdf)
' "K M3" l% = 2          ' (Kb)
' "L3 M5" l% = 3         ' (La)
' "L2 M4" l% = 4         ' (Lb)
' "M5 N7" l% = 5         ' (Ma)
' "M4 N6" l% = 6         ' (Mb)
Call PenepmaGetPDATCONFTransition(EmittingElement%, EmittingXray%, t1!, t2!)
If ierror Then Exit Sub

' If both shells have ionization energies, it is ok
If t1! <> 0# And t2! <> 0# Then

' Check for valid intensities (less than or equal to zero)
If PureGenerated_Intensities#(l%) <= 0# Or PureGenerated_Intensities#(l%) > MAXSINGLE! Then
errorsfound = True
msg$ = "Penepma12PureScanMDB: Pure element (" & Format$(PureGenerated_Intensities#(l%)) & ") is less than or equal to zero (or greater than single precision) for " & Symup$(EmittingElement%) & " " & Xraylo$(EmittingXray%) & " at " & Format$(BeamEnergy!) & " keV : " & tfilename$ & " (skipping this pure element record)..."
If DebugMode Then MiscMsgBoxTim FormMSGBOXTIME, "Penepma12PureScanMDB", msg$, 5#
Call IOWriteError(msg$, "Penepma12PureScanMDB")
If ierror Then Exit Sub
GoTo SkipThisRecord         ' skip saving intensities for this beam energy and x-ray line situation
End If

End If
End If

' Add new records to "Pure" table
Set PrDt = PrDb.OpenRecordset("Pure", dbOpenTable)
nrec& = nrec& + 1
Call IOStatusAuto("Adding record " & Format$(nrec&) & ", " & Format$(m%) & " keV, " & Symup$(EmittingElement%) & " " & Xraylo$(EmittingXray%) & " to Pure.MDB with input file, " & tfilename$ & "...")
DoEvents

' Add new record
PrDt.AddNew
PrDt("BeamTakeOff") = BeamTakeOff!
PrDt("BeamEnergy") = BeamEnergy!
PrDt("EmittingElement") = EmittingElement%
PrDt("EmittingXray") = EmittingXray%

' Add unique record number for other tables
PrDt("PureNumber") = nrec&
PrDt.Update
PrDt.Close

' Add new records to "PureIntensity" table
Set PrDt = PrDb.OpenRecordset("PureIntensity", dbOpenTable)
PrDt.AddNew
PrDt("PureIntensityNumber") = nrec&                                     ' unique record number pointing to Pure table
PrDt("PureIntensityGenerated") = CSng(PureGenerated_Intensities#(l%))      ' Penepma generated intensity
PrDt("PureIntensityEmitted") = CSng(PureEmitted_Intensities#(l%))          ' Penepma emitted intensity
PrDt.Update
PrDt.Close

' Check for user cancel
DoEvents
If icancelauto Then
ierror = True
Exit Sub
End If

' Check for Pause button
Do Until Not RealTimePauseAutomation
DoEvents
Sleep 200
Loop

SkipThisRecord:
Next l%
Next m%

' Get next input filename
Next k&

PrDb.Close
Call IOStatusAuto(vbNullString)

If nrec& > 0 Then
msg$ = "PURE.MDB has been updated with " & Format$(nrec&) & " pure element records"
MsgBox msg$, vbOKOnly + vbInformation, "Penepma12PureScanMDB"

Else
msg$ = "No Pure.MDB intensity input .TXT files were found in the Fanal\Pure folder"
MsgBox msg$, vbOKOnly + vbInformation, "Penepma12PureScanMDB"
End If

' Warn if errors found
If errorsfound Then
msg$ = "Some bad intensity values (<= zero) were found in some Fanal pure element .TXT files. This is usually caused by statistical issues at low overvoltages or with very weak emission lines." & vbCrLf & vbCrLf
msg$ = msg$ & "See the error file " & ProbeErrorLogFile$ & " for more details."
MsgBox msg$, vbOKOnly + vbInformation, "Penepma12PureScanMDB"
End If

Exit Sub

' Errors
Penepma12PureScanMDBError:
Screen.MousePointer = vbDefault
MsgBox Error$ & ", keV= " & Format$(m%) & ", " & Symup$(EmittingElement%) & " " & Xraylo$(l%), vbOKOnly + vbCritical, "Penepma12PureScanMDB"
Call IOStatusAuto(vbNullString)
Close #tfilenumber%
ierror = True
Exit Sub

Penepma12PureScanMDBNoDirectory:
msg$ = "The pure data folder " & tfolder$ & " was not found"
MsgBox msg$, vbOKOnly + vbExclamation, "Penepma12PureScanMDB"
Call IOStatusAuto(vbNullString)
ierror = True
Exit Sub

Penepma12PureScanMDBNotEmpty:
msg$ = "The pure database already contains intensity entires. Please create a new Pure.mdb file and try updating it again."
MsgBox msg$, vbOKOnly + vbExclamation, "Penepma12PureScanMDB"
Call IOStatusAuto(vbNullString)
ierror = True
Exit Sub

End Sub

