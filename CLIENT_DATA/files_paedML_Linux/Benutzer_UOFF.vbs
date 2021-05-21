' -----------------------------------------------
' Benutzer.vbs
' VBScript fuer die Benutzeranmeldung 
' -----------------------------------------------
' Version: 	1.0.26
' Datum:	27.11.2020
' Autor: 	Markus Finkenbein / Martin Ewest / Soo-Dong Kim
' -----------------------------------------------
' Anpassungen fuer paedML Linux:
'
' - Profilpfad (C:\paedML_UOFF\UserProfile\UOFF.V6) ist leer.
'   Damit gibt es keine Probleme mehr mit temporaeren Profilen!
' - Homepfad (C:\paedML_UOFF\UserHomeDirectory\SuS) wird nicht verwendet.
'   Keine Kopieraktionen mehr bei der Anmeldung!
' - Kein Mapping von HomePfad, stattdessen direkt C:\USERS\SuS

Option Explicit

' Nur auf diesen Benutzer anwenden!
Const   DoOnlyThisUser = "##DoOnlyThisUser##"
' Nur auf diesen Benutzer anwenden!

' Logging
Const   debugMode = False
Const logfile = "C:\paedML_UOFF\LogFiles\Logfile.txt"

' Variablen
Dim	homeDriveShare 
Dim wshNet, wshShell, command, wshShellApp
Dim fso, fsoFile
Dim userName
Dim deviceName

Main

Sub Main()
	LogonLinux
End Sub

' Hilfsfunktionen

Sub LogonLinux()
	Set wshNet = CreateObject("WScript.Network")
	userName   = WshNet.UserName
	' Nur auf diesen Benutzer anwenden!
	If (userName = DoOnlyThisUser) Then
		deviceName = wshNet.ComputerName
		homeDriveShare = "\\localhost\c$\users\" & userName
		' Sicherheitscheck: Skript darf nicht auf Server laufen
		If ((deviceName = "DC01") Or (deviceName = "SP01")) Then
			WScript.Echo "Dieses Skript darf nicht auf einem Server ausgeführt werden."
			WScript.Quit
		End If

		If debugMode Then 
			WriteToLogfile "INFORMATION", "Logon", "userName: " & userName	
			WriteToLogfile "INFORMATION", "Logon", "deviceName: " & deviceName
			WriteToLogfile "INFORMATION", "Logon", "homeDriveShare: " & homeDriveShare
		End If
		
		' Laufwerk H: verbinden
		MapDrive "h:", "Home_Offline", homeDriveShare
	Else
		' Das ist der falsche Benutzer.
		If debugMode Then 
			WriteToLogfile "INFORMATION", "Logon", "userName: " & userName
			WriteToLogfile "INFORMATION", "Logon", "userName ist nicht gleich UOFF_Benutzer (" & DoOnlyThisUser & "), daher bricht das Skript ab."
		End If
	End If 
End Sub


Sub MapDrive(pHomeDriveLetter,pHomeDriveName,pHomeDriveShare)
	On Error Resume Next
	Set wshNet = CreateObject("WScript.Network")
	Set fso = CreateObject("Scripting.FileSystemObject")

	If fso.DriveExists(pHomeDriveLetter) Then
		wshNet.RemoveNetworkDrive pHomeDriveLetter, True, True
	End If	
	wshNet.MapNetworkDrive pHomeDriveLetter, pHomeDriveShare
		
	If Err.number <> 0 Then
		WriteToLogfile "FEHLER", "MapDrive", "Das Laufwerk "  & pHomeDriveLetter & " konnte nicht mit der Freigabe " & pHomeDriveShare & " verbunden werden: " & Err.Description 
		Err.Clear
	Else
		If debugMode Then 
			WriteToLogfile "INFORMATION", "MapDrive", "Das Laufwerk "  & pHomeDriveLetter & " wurde mit der Freigabe " & pHomeDriveShare & " verbunden."		
		End If
		Set wshShellApp = CreateObject("Shell.Application")
		wshShellApp.NameSpace(pHomeDriveLetter).Self.Name = pHomeDriveName
		If Err.number <> 0 Then
			WriteToLogfile "FEHLER", "MapDrive", "Der Laufwerksname "  & pHomeDriveName & " konnte nicht gaendert werden: " & Err.Description 
			Err.Clear
		Else
			WriteToLogfile "INFORMATION", "MapDrive", "Der Laufwerksname "  & pHomeDriveName & " wurde geaendert."
		End if
		
		Set wshShell = CreateObject("Wscript.Shell")		
		command = "attrib.exe +h " & Chr(34) & "H:\AppData" & Chr(34)
		If  debugMode Then WriteToLogfile "INFORMATION", "MapDrive->attrib", command
		wshShell.Run(command)
		If Err.number <> 0 Then
			WriteToLogfile "FEHLER", "MapDrive", "Das Verzeichnis H:\AppData konnte nicht mit der Freigabe " & pHomeDriveShare & " verbunden werden: " & Err.Description 
			Err.Clear
		Else
			WriteToLogfile "INFORMATION", "MapDrive", "Das Verzeichnis H:\AppData wurde auf der Freigabe " & pHomeDriveShare & " versteckt."
		End If
	
	End If
	
	Set wshNet = Nothing
	Set fso = Nothing
	Set wshShellApp = Nothing
	Set wshShell = Nothing
	On Error GoTo 0
End Sub

Sub WriteToLogfile(pType, pSender, pInformation)
	Const ForAppending = 8
	Dim logfileEntry
	
	logfileEntry = Now & Chr(9) & Chr(9) & "Benutzer.vbs: " & pSender & Chr(9) & Chr(9) & "[" & pType & "]" & Chr(9) & Chr(9) & pInformation

	Set fso = CreateObject("Scripting.FileSystemObject")
    Set fsoFile = fso.OpenTextFile(logfile, ForAppending, True)
	fsoFile.WriteLine(logfileEntry)
    fsoFile.Close
	
	Set fsoFile = Nothing
	Set fso = Nothing
End Sub

