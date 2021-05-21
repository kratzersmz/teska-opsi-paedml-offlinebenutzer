' -----------------------------------------------
' Benutzer.vbs
' VBScript fuer die Benutzeran- und abmeldung 
' in der paedML Windows 3.x, 4.x und paedML Linux
' User-Offline-Lösung "UOFF"
'
' -----------------------------------------------
' Version: 	1.0.24
' Datum:	12.07.2016
' Autor: 	Markus Finkenbein
' -----------------------------------------------
' Version: 	1.0.25
' Datum:	25.09.2020
' Angepasst: 	Martin Ewest
' statt Documents -> Eigene Dateien
' statt Pictures  -> Eigene Bilder
' -----------------------------------------------
Option Explicit

Const debugMode = False
' Ordnerumleitung
Const   pAppRoaming  = "AppData\Roaming"
Const	pContacts    = "Contacts"
Const	pDocuments   = "Eigene Dateien"
Const	pDownloads   = "Downloads"
Const	pFavorites   = "Favorites"
Const	pMusic       = "Music"
Const	pVideos      = "Videos"
Const	pPictures    = "Eigene Bilder"
Const	pSearches    = "Searches"
Const	pLinks       = "Links"
Const   pSavedGames  = "Saved Games"


' Logging
Const logfile = "C:\paedML_UOFF\LogFiles\Logfile.txt"
Const flagRobocopy = "C:\paedML_UOFF\LogFiles\PurgedByRobocopy.txt"

' Variablen
Dim	homeDriveShare, homeDriveFolders 
Dim wshNet, wshShell, command, wshShellApp
Dim fso, fsoFile
Dim userName
Dim deviceName
Dim userHomeDirectory
Dim userLocalPath
Dim homeDriveShareName

Main


Sub Main()
	homeDriveFolders = Array(pDocuments, pDownloads, pFavorites, pMusic, pVideos, pPictures, pLinks, pSavedGames)
	Logon 
End Sub

' Hilfsfunktionen

Sub Logon()
	
	Set wshNet = CreateObject("WScript.Network")
	userName   = WshNet.UserName
	If  debugMode Then WriteToLogfile "INFORMATION", "Logon", "userName: " & userName	
	deviceName = wshNet.ComputerName
	If  debugMode Then WriteToLogfile "INFORMATION", "Logon", "deviceName: " & deviceName
	userHomeDirectory = "C:\paedML_UOFF\UserHomeDirectory" & "\" & userName
	If  debugMode Then WriteToLogfile "INFORMATION", "Logon", "userHomeDirectory: " & userHomeDirectory
	userLocalPath = "C:\Users" & "\" & userName
	If  debugMode Then WriteToLogfile "INFORMATION", "Logon", "userLocalPath: " & userLocalPath
	homeDriveShareName = userName & "Share$"
	If  debugMode Then WriteToLogfile "INFORMATION", "Logon", "homeDriveShareName: " & homeDriveShareName
			
	' Sicherheitscheck: Skript darf nicht auf Server laufen
	If ((deviceName = "DC01") Or (deviceName = "SP01")) Then
		WScript.Echo "Dieses Skript darf nicht auf einem Server ausgeführt werden."
		WScript.Quit
	End If
	
	' Laufwerk H: verbinden
	homeDriveShare = "\\" & deviceName & "\" & homeDriveShareName
	MapDrive "h:", "Home_Offline", homeDriveShare

	' Verzeichnisse fuer Umleitung im userHomeDirectory anlegen
	CreateFoldersInHomeDrive
	WScript.Sleep 100
	' Redirect der Verzeichnisstrukturen auf userHomeDirectory:
	SetRedirectionToHome 
	WScript.Sleep 100
	' Umleitung der lokalen Benutzerverzeichnisse auf userHomeDirectory u.a. wegen der Bibliotheken
	SetRedirektionForLocalUserFolders
	
End Sub

Sub CreateFoldersInHomeDrive()

	Dim homeDriveFolder
	
	On Error Resume Next
	Set fso = CreateObject("Scripting.FileSystemObject")
	Set wshShell = CreateObject("Wscript.Shell")

	' If Not fso.FolderExists(userHomeDirectory & "\AppData\") Then fso.CreateFolder userHomeDirectory & "\AppData"
	' If Not fso.FolderExists(userHomeDirectory & "\AppData") Then WriteToLogfile "FEHLER", "CreateFoldersInHomeDrive -> CreateFolder", "Folgendes Verzeichnis konnte nicht angelegt werden: " & userHomeDirectory & "\AppData"
	' If Not fso.FolderExists(userHomeDirectory & "\AppData\Roaming\") Then fso.CreateFolder userHomeDirectory & "\AppData\Roaming"
	' If Not fso.FolderExists(userHomeDirectory & "\AppData\Roaming") Then WriteToLogfile "FEHLER", "CreateFoldersInHomeDrive -> CreateFolder", "Folgendes Verzeichnis konnte nicht angelegt werden: " & userHomeDirectory & "\AppData\Roaming"	
	' Die im Array homeDriveFolders angegebenen Verzeichnisse werden angelegt
	
			
	For each homeDriveFolder in homeDriveFolders
		If fso.FolderExists(userHomeDirectory & "\" & homeDriveFolder & "\") Then 
			If debugMode Then WriteToLogfile "INFORMATION", "CreateFoldersInHomeDrive -> CreateFolder", "Der Ordner exisitiert bereits: " & userHomeDirectory & "\" & homeDriveFolder
		Else
			If  debugMode Then WriteToLogfile "INFORMATION", "CreateFoldersInHomeDrive -> CreateFolder", "Anzulegender Ordner: " & userHomeDirectory & "\" & homeDriveFolder
			fso.CreateFolder userHomeDirectory & "\" & homeDriveFolder			
			If FolderExists(userLocalPath & "\" & homeDriveFolder & "\") Then 
				command = "RoboCopy.Exe " & Chr(34) & userLocalPath & "\" & homeDriveFolder & Chr(34) & " " & Chr(34) & userHomeDirectory & "\" & homeDriveFolder & Chr(34) & " /purge /r:3 /w:1 /xJ"
				If  debugMode Then WriteToLogfile "INFORMATION", "CreateFoldersInHomeDrive -> Robocopy purge", command 
				wshShell.Run(command)								
			End If			
		End If				
	Next
	
	If Err.Number <> 0 Then
		WriteToLogfile "WARNUNG", "CreateFoldersInHomeDrive", "Es konnten zu diesem Zeitpunkt nicht alle Verzeichnisse angelegt werden! Dies kann spaeter noch erfolgen." 
	End if
		
	Set fso = Nothing
	Err.Clear
	On Error Goto 0
	
End Sub

Sub SetRedirectionToHome()
	
	' Redirect der Verzeichnisstrukturen auf das UserHomeDirectory:
	On Error Resume Next
	'	FolderRedirectInRegistry "AppData" , 								  True, userHomeDirectory & "\" & pAppRoaming
	'	FolderRedirectInRegistry "{56784854-C6CB-462B-8169-88E350ACB882}" , False, userHomeDirectory & "\" & pContacts
	FolderRedirectInRegistry "Personal" , 							  True, userHomeDirectory & "\" & pDocuments
	FolderRedirectInRegistry "{374DE290-123F-4565-9164-39C4925E467B}" , True, userHomeDirectory & "\" & pDownloads
	FolderRedirectInRegistry "Favorites" , 							  True, userHomeDirectory & "\" &pFavorites
	FolderRedirectInRegistry "My Music" , 							  True, userHomeDirectory & "\" &pMusic
	FolderRedirectInRegistry "My Video" , 							  True, userHomeDirectory & "\" &pVideos
	FolderRedirectInRegistry "My Pictures" , 							  True, userHomeDirectory & "\" &pPictures
	'	FolderRedirectInRegistry "{7D1D3A04-DEBB-4115-95CF-2F29DA2920DA}" , False, userHomeDirectory & "\" &pSearches
	FolderRedirectInRegistry "{BFB9D5E0-C6A9-404C-B2B2-AE6DB6AF4968}" , False, userHomeDirectory & "\" &pLinks
	FolderRedirectInRegistry "{4C5C32FF-BB9D-43B0-B5B4-2D72E54EAAA4}" , False, userHomeDirectory & "\" &pSavedGames
	
	If Err.Number <> 0 Then
		WriteToLogfile "FEHLER", "SetRedirectionToHome", "Es konnte nicht alle Verzeichnisse umgeleitet werden!" 
	End if
	
	Err.Clear
	On Error Goto 0
End Sub


Sub FolderRedirectInRegistry(pUserShellFolder,pUserBothRegHives,pTargetFolder)
	
	Dim userShellRegPath, shellRegPath, wshShell
	
	On Error Resume Next
	userShellRegPath ="HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders\" & pUserShellFolder
	shellRegPath ="HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders\" & pUserShellFolder
	Set wshShell = CreateObject("Wscript.Shell")
	
	wshShell.RegWrite userShellRegPath, pTargetFolder, "REG_EXPAND_SZ"
	If (pUserBothRegHives) Then
		wshShell.RegWrite shellRegPath, pTargetFolder, "REG_SZ"
	End If
	
	If Err.Number <> 0 Then
		WriteToLogfile "FEHLER", "MakeRedirectionToHome", "Es konnte nicht alle Verzeichnisse umgeleitet werden!" 
	End if
	
	Set wshShell = Nothing
	Err.Clear
	On Error Goto 0	
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
		Set wshShellApp = CreateObject("Shell.Application")
		wshShellApp.NameSpace(pHomeDriveLetter).Self.Name = pHomeDriveName
		If Err.number <> 0 Then
			WriteToLogfile "FEHLER", "MapDrive", "Der Laufwerksname "  & pHomeDriveName & " konnte nicht gaendert werden: " & Err.Description 
			Err.Clear
		End if
		
		Set wshShell = CreateObject("Wscript.Shell")		
		command = "attrib.exe +h " & Chr(34) & "H:\AppData" & Chr(34)
		If  debugMode Then WriteToLogfile "INFORMATION", "MapDrive -> attrib", command
		wshShell.Run(command)
		If Err.number <> 0 Then
			WriteToLogfile "FEHLER", "MapDrive", "Das Verzeichnis H:\AppData konnte nicht mit der Freigabe " & pHomeDriveShare & " verbunden werden: " & Err.Description 
			Err.Clear
		End If
	
	End If
	
	Set wshNet = Nothing
	Set fso = Nothing
	Set wshShellApp = Nothing
	Set wshShell = Nothing
	On Error GoTo 0
End Sub

Sub SetRedirektionForLocalUserFolders()

	Dim homeDriveFolder
	
	On Error Resume Next
	Set fso = CreateObject("Scripting.FileSystemObject")
	Set wshShell = CreateObject("Wscript.Shell")
	
	For each homeDriveFolder in homeDriveFolders
		command = "RoboCopy.Exe " & Chr(34) & userLocalPath & "\" & homeDriveFolder & Chr(34) & " " & Chr(34) & userHomeDirectory & "\" & homeDriveFolder & Chr(34) & " /copy:DATSO /r:3 /w:1 /xJ"
		If  debugMode Then WriteToLogfile "INFORMATION", "SetRedirektionForLocalUserFolders -> Robocopy copyall", command 
		wshShell.Run(command)
		If Err.number <> 0 Then
			WriteToLogfile "FEHLER", "SetRedirektionForLocalUserFolders", "Robocopy konnte nicht folgendes Kommando ausfuehren: " & command & Err.Description 
			Err.Clear
		End If
	Next
			
	Set fsoFile = Nothing
	Set fso = Nothing
	
	For each homeDriveFolder in homeDriveFolders
		command = "cmd /c rd " & Chr(34) & userLocalPath & "\" & homeDriveFolder & Chr(34) & " /S /Q"
		If  debugMode Then WriteToLogfile "INFORMATION", "SetRedirektionForLocalUserFolders -> delete local user folders", command
		wshShell.Run(command)
		If Err.number <> 0 Then
			WriteToLogfile "FEHLER", "SetRedirektionForLocalUserFolders", "Es konnten die lokalen Benutzerverzeichnisse nicht geloescht werden: " & command & Err.Description 
			Err.Clear
		End If
	Next
	
	For each homeDriveFolder in homeDriveFolders
		command = "cmd /c mklink " & Chr(34) & userLocalPath & "\" & homeDriveFolder & Chr(34) & " " & Chr(34) & userHomeDirectory & "\"  & homeDriveFolder & Chr(34) & " /J"
		If  debugMode Then WriteToLogfile "INFORMATION", "SetRedirektionForLocalUserFolders -> mklink", command 
		wshShell.Run(command)
		If Err.number <> 0 Then
			WriteToLogfile "FEHLER", "SetRedirektionForLocalUserFolders", "Es konnten keine Junction gesetzt werden: " & command & Err.Description 
			Err.Clear
		End If
	Next
	
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

