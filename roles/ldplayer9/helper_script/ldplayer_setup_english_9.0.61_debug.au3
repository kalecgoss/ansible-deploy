#include <AutoItConstants.au3>
#include <Date.au3>

Func _WinWaitActivate($title, $text, $timeout)
  $w = WinWait($title, $text, $timeout)
  If Not WinActive($title, $text) Then WinActivate($title, $text)
	Return $w
EndFunc

Func FindStringInFile($filePath, $string)
  $fd = FileOpen($filePath, 0)
  If $fd = -1 Then
    Return 2
  EndIf
  $buffer = FileRead($fd)
  If @error = -1 Then
    FileClose($fd)
    Return 3
  EndIf
  FileClose($fd)
  If StringRegExp($buffer, $string) Then
    Return 0
  Else
    Return 1
  EndIf
EndFunc

Func WaitForStringInFile($filePath, $string, $timeout)
  $found = False
  $count = 0
  Do
    If (FindStringInFile($filePath, $string) == 0) Then
      $found = True
      ExitLoop
    EndIf
    $count += 1
    Sleep(1000)
  Until $found Or ($count > $timeout)
  Return $found
EndFunc

Func LogStepByStep($message)
  $logFile = "C:\ldplayer_setup_log.txt"
  FileWriteLine($logFile, "[" & _NowCalcDate() & " " & _NowTime(5) & "] " & $message)
EndFunc

; ---------------------------------------------------------------------------------------------------------

$ldpSupportedInstaller = "ENGLISH v.9.0.55" ; Only this version is supported! For other versions you STRONGLY need code review, calculate new rectangle checksums, etc...

If $CmdLine[0] <> 2 Then
  MsgBox(0, "LDPlayer installation helper", "Usage: " & @ScriptName & _
            " <C:\path\to\ldplayer_setup.exe> <username>" & @CRLF & @CRLF & _
            "Supported LDPLayer installer: " & $ldpSupportedInstaller)
  Exit
EndIf

$logFileInstall = "C:\Users\" & $CmdLine[2] & "\AppData\Roaming\XuanZhi9\log\dninstall.log" ; main installation log file
$logFileStart = "C:\Users\" & $CmdLine[2] & "\AppData\Roaming\XuanZhi9\log\leidian0.log" ; first startup log file

$logStringStage0 = "SetupUI::showSetupMainUI" & @TAB & "\(58\):install path = C:/LDPlayer/LDPlayer9/"
$logStringStage1 = "SetupUI::onDecompressFinish" & @TAB & "\(154\):install decompress finish."
;~ $logStringStage2 = "SimulatorSetupCore::_runMainFrame" & @TAB & "\(288\):install run C:\\XuanZhi\\LDPlayer\\dnplayer.exe. ret: 0  lasterror = 0"
;~ $logStringStage3 = "CPlayerImpl::onPackageAdded" & @TAB & "\(1047\):onPackageAdded package is com.google.android.gms, fromHost:0"

; BEGIN
LogStepByStep("1: set mouse & pixel mode")
AutoItSetOption("MouseCoordMode", 2) ; set "relative" mode for mouse clicks
AutoItSetOption("PixelCoordMode", 2) ; set "relative" mode for pixel functions

LogStepByStep("2: launch ldplayer installer")
Run($CmdLine[1]) ; launch LDPlayer installer with user environment
LogStepByStep("3: wait 2 sec")
Sleep(2000)

; STAGE 0
LogStepByStep("4: wait for string in installation log file: " & $logStringStage0)
WaitForStringInFile($logFileInstall,$logStringStage0,80) ; wait for message in log file
LogStepByStep("5: wait for main window")
$ldpMainWindow = _WinWaitActivate("[TITLE:LDPlayer; CLASS:SetupMainWindow]","",30) ; wait for main window
LogStepByStep("6: show main installer window & set it on top")
WinSetState($ldpMainWindow, "", @SW_SHOW)
WinSetOnTop($ldpMainWindow, "", $WINDOWS_ONTOP)
Sleep(80000)
LogStepByStep("7: click Next button")
MouseClick("left",320,255) ; click "Next"
LogStepByStep("8: wait 2 sec")
Sleep(2000)

;~ ; STAGE 1
LogStepByStep("9: wait for string in installation log file: " & $logStringStage1)
WaitForStringInFile($logFileInstall,$logStringStage1,140) ; wait for message in log file
LogStepByStep("10: wait for main window")
$ldpMainWindow = _WinWaitActivate("[TITLE:LDPlayer; CLASS:SetupMainWindow]","",30) ; wait for main window
LogStepByStep("11: show main installer window & set it on top")
WinSetState($ldpMainWindow, "", @SW_SHOW)
WinSetOnTop($ldpMainWindow, "", $WINDOWS_ONTOP)
LogStepByStep("12: click Close button")
MouseClick("left",620,20) ; click "Close", wait for second stage to complete
LogStepByStep("13: wait 2 sec")
Sleep(2000)
