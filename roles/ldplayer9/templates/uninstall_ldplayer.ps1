#This script COMPLETELY removes English 4.x and English 9.x installation: app files, logs, temporary files, registry keys, etc...

# WARNING! This script REQUIRES active user's session (RDP or console), or you have to load/unload user's
# registry hive to delete HKEY_USERS\<user's SID>\...


# Get user info
$SID = (Get-LocalUser -Name {{ ansible_user }}).SID
Write-Host "Running for USER = '{{ ansible_user }}', SID = '$SID'"

Admin = '{{ ansible_user }}';
Write-Host "The current user is Admin"


# STEP #1. Stop all emulators
Write-Host "STEP #1. Stopping all emulators:"

$ldplayerConsoles = @(
  "C:\ChangZhi\dnplayer2\dnconsole.exe", # v. 3.x
  "C:\XuanZhi\LDPlayer\dnconsole.exe", # v. 4.x
  "C:\LDPlayer\LDPlayer9\dnconsole.exe" # v. 9.x
)
ForEach ($dnconsole in $ldplayerConsoles){
  If (Test-Path -Path $dnconsole) {
    Write-Host "- [RUNNING: '$dnconsole quitall' ...]"
    Start-Process -FilePath $dnconsole -ArgumentList "quitall" -Wait
    Start-Sleep 5
  }
  Else {
    Write-Host "- [NOT FOUND: '$dnconsole', skipping...]"
  }
}
Write-Host "done."



# STEP #2. Stop all LDPlayer installer processes
Write-Host "STEP #2. Search & stop all ldplayer installer processes:"

$ldplayerInstallers = @(
  "LDPlayer", # v. 4.x
  "ldinst", # v. 3.x
  "ldplayer_setup" # helper
)
$found = $false
ForEach ($proc in $ldplayerInstallers) {
  Get-Process | ? { $_.Name -like "*${proc}*" } | % {
    $found = $true
    Stop-Process -Id $_.Id -Force
    Write-Host "- [KILLED: ID=$($_.Id), Path=$($_.Path)]"
  }
}
If ($found -eq $false){
  Write-Host "- [NONE FOUND]"
}
Write-Host "done."



# STEP #3. Stop all LDPlayer processes
Write-Host "STEP #3. Search & stop all ldplayer's processes:"

$ldplayerExeLocations = @(
  "C:\XuanZhi", # v. 4.x player
  "C:\Program Files\ldplayerbox", # v. 4.x virtualbox
  "C:\ChangZhi", # v 3.x player
  "C:\Program Files\dnplayerext2", # v. 3.x virtualbox
  "C:\GMC.Packages", # apps
  "C:\ledian\LDPlayer4"
  "C:\LDPlayer\LDPlayer9", # v 9.x
  "C:\LDPlayer\ldmutiplayer", # v 9.x
  "C:\LDPlayer\LDPlayer4.0", # v 9.x
  "D:\LDPlayer\LDPlayer9", # v 9.x
  "D:\LDPlayer\ldmutiplayer", # v 9.x
  "D:\LDPlayer\LDPlayer4.0" # v 9.x
)
$found = $false
ForEach ($proc in $ldplayerExeLocations) {
  Get-Process | ? { $_.Path -like "${proc}*" } | % {
    $found = $true
    Stop-Process -Id $_.Id -Force
    Write-Host "- [KILLED: ID=$($_.Id), Path=$($_.Path)]"
  }
}
If ($found -eq $false){
  Write-Host "- [NONE FOUND]"
}
Write-Host "done."



# STEP #4. LDPlayer's VirtualBox Uninstall
Write-Host "STEP #4. Run VirtualBox driver uninstaller:"

$ldplayerVBoxUninstallers = @(
  "C:\Program Files\dnplayerext2\uninstall.bat", # v. 3.x
  "C:\Program Files\ldplayerbox\uninstall.bat" # v. 4.x
  "C:\Program Files\ldplayer9box\NetLwfUninstall.exe" # v. 9.x Ld9BoxNetLwf
)
ForEach ($virtualboxUninstaller in $ldplayerVBoxUninstallers){
  If (Test-Path -Path $virtualboxUninstaller) {
    Write-Host "- [RUNNING: '$virtualboxUninstaller' ...]"
    Start-Process -FilePath $virtualboxUninstaller -Wait
    Start-Sleep 5
  }
  Else {
    Write-Host "- [NOT FOUND: '$virtualboxUninstaller', skipping...]"
  }
}
Write-Host "done."



# STEP #5. LDPlayer's VirtualBox Uninstall FIX (if step #4 did not delete driver properly)
Write-Host "STEP #5. Run VirtualBox driver uninstall FIX:"

$ldVBoxDrivers = @{
  "C:\Program Files\dnplayerext2\dpinst.exe" = "LdBoxDrv"; # v. 3.x
  "C:\Program Files\ldplayerbox\dpinst_64.exe" = "LdVBoxDrv"; # v.4.x x64
  "C:\Program Files\ldplayer9box\dpinst_64.exe" = "Ld9BoxSup" # v 9.x
}
ForEach ($ldVBoxDriver in $ldVBoxDrivers.GetEnumerator()){
  $ldVBoxDriverUninstaller = $ldVBoxDriver.Key
  $ldVBoxDriverName = $ldVBoxDriver.Value
  $ldVBoxDriverPath = Split-Path -Path $ldVBoxDriverUninstaller -Parent

  If ((((& C:\Windows\System32\sc.exe query $ldVBoxDriverName 2>&1) -match $ldVBoxDriverName) | Measure-Object -Line).Lines -gt 0){
    Write-Host "- [FOUND: '$ldVBoxDriverName' driver, starting uninstall ...]"
    Start-Process -FilePath "C:\Windows\System32\sc.exe" -ArgumentList "stop $ldVBoxDriverName" -Wait
    Start-Process -FilePath "C:\Windows\System32\sc.exe" -ArgumentList "delete $ldVBoxDriverName" -Wait
    Start-Sleep 5
    Start-Process -FilePath $ldVBoxDriverUninstaller -ArgumentList "/SW /U `"$ldVBoxDriverPath\$ldVBoxDriverName.inf`"" -Wait
    Start-Sleep 5
  } Else {
    Write-Host "- [NOT FOUND: '$ldVBoxDriverName', skipping...]"
  }
}
Write-Host "done."



# STEP #6. Remove files and registry keys
Write-Host "STEP #6. Removing ldplayer's filesystem & registry items:"

$ldplayerItems = @(
  # LDPlayer v 4.x (english) specific items
  "C:\XuanZhi",
  "D:\XuanZhi",
  "C:\ledian",
  "D:\ledian",
  "C:\Program Files\ldplayerbox",
  "C:\Users\Admin\AppData\Roaming\XuanZhi",
  "C:\Users\Admin\.Ld2VirtualBox",
  "C:\Users\Admin\Documents\XuanZhi",
  "C:\Users\Admin\Desktop\LDPlayer4.lnk",
  "C:\Users\Admin\Desktop\LDMultiPlayer4.lnk",
  "C:\Users\Admin\AppData\Roaming\Microsoft\Windows\Start Menu\LDPlayer4.lnk",
  "C:\Users\Admin\AppData\Roaming\Microsoft\Windows\Start Menu\LDMultiPlayer4.lnk",
  "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\LDPlayer4",
  "Registry::HKEY_USERS\$SID\Software\XuanZhi"
  # LDPlayer v 3.x (chinese) specific items
  "C:\ChangZhi",
  "D:\ChangZhi",
  "C:\Program Files\dnplayerext2",
  "C:\Users\Admin\AppData\Roaming\ChangZhi2",
  "C:\Users\Admin\.LdVirtualBox",
  "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\dnplayer",
  "Registry::HKEY_USERS\$SID\Software\ChangZhi2",
  # common items
  "C:\Users\Admin\.android",
  "C:\Users\Admin\AppData\Roaming\changzhi_leidian.data",
  "C:\Users\Admin\AppData\Roaming\changzhi_mplayer.data",
  "C:\Users\Admin\AppData\Local\Temp\adb.log",
  "C:\ldplayer_setup_log.txt",
  # app data
  "C:\emulatorStatusDirectory\*.*",
  # ld9
  "C:\Users\Admin\Documents\XuanZhi9",
  "C:\LDPlayer",
  "D:\LDPlayer",
  "C:\Users\Admin\.Ld9VirtualBox",
  "C:\Users\admin\.Ld9VirtualBox",
  "C:\Program Files\ldplayer9box",
  "C:\Users\Admin\Desktop\LDMultiPlayer.lnk",
  "C:\Users\Admin\Desktop\LDPlayer9.lnk",
  "C:\Users\Admin\AppData\Roaming\XuanZhi9",
  "C:\Users\Admin\AppData\Roaming\Microsoft\Windows\Start Menu\LDMultiPlayer.lnk",
  "C:\Users\Admin\AppData\Roaming\Microsoft\Windows\Start Menu\LDPlayer9.lnk",
  "C:\Users\admin\Desktop\LDMultiPlayer.lnk",
  "C:\Users\admin\Desktop\LDPlayer9.lnk",
  "C:\Users\admin\AppData\Roaming\XuanZhi9",
  "C:\Users\admin\AppData\Roaming\Microsoft\Windows\Start Menu\LDMultiPlayer.lnk",
  "C:\Users\admin\AppData\Roaming\Microsoft\Windows\Start Menu\LDPlayer9.lnk",
  "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\LDPlayer9"
  # "Registry::HKEY_USERS\$SID\Software\XuanZhi\ldmultiplay",
  # "Registry::HKEY_USERS\$SID\Software\XuanZhi\LDPlayer9"
)
ForEach ($item in $ldplayerItems) {
  If (Test-Path -Path $item) {
    Remove-Item -Path $item -Recurse -Force -ErrorAction Continue
    Write-Host "- [DELETED: Path=$item]"
  }
  Else {
    Write-Host "- [NOT FOUND: Path=$item]"
  }
}
Write-Host "done."

Write-Host "Uninstall completed."
