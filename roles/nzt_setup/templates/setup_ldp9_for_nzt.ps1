function Log {
    param ($Message)
    $msg = "emulator $index | $Message"
    Write-Host $msg
    Write-Output $msg | Out-File -Encoding ASCII -FilePath "C:\log_setup_nzt.txt" -Append
}

function StopEmu{
    param( $index )
    Log "Stoping emulator"
    dn quit --index $index
    Start-Sleep 2
}

function StartEmu {
    param ( $index )
    Log "Starting emulator"
    dn launch --index $index
    Start-Sleep 25
    EmuCheck $index
}

function EmuCheck{
    param ( $index )
    while ($status -ne "/"){
        foreach ($attempt in (1..7)) {
            Log "INFO Try to connect to emulator $index..."
            $status = dn adb --index $index --command "shell pwd"
            if ($status -eq "/") {
                Log "INFO Emulator $index is ready"
                break
            }
            elseif ($attempt -eq 7) {
                Log "WARNING Restart emulator $index"
                dn reboot --index $index
                Start-Sleep 10
            }
            else{ Start-Sleep 10 }
        }
    }
}

function SetLocation{
    param ( $index, $gps )
    if ($gps -like "*curl*") {
      Log "Check internet on emulator!!!"
    }
    else {
      Log "Set coordinates $gps ..."
      dn locate --index $index --LLI $gps
    }
}

function GetLocation{
    param ( $index, $iplocation_service )
    if ($iplocation_service -eq "ipwho.is") {
        Log "Getting gps coordinates from ipwho.is"
        $response = dn adb --index $index --command "shell curl -s -m 15 ipwho.is" | ConvertFrom-Json
        $gps = $response.longitude.ToString() + "," + $response.latitude.ToString()
    } else {
        Log "Getting gps coordinates from ipinfo.io/loc"
        $response = dn adb --index $index --command "shell curl -s -m 15 ipinfo.io/loc"
        $coords = $response -split ','
        $gps = "$($coords[1]),$($coords[0])"
    }
    Log "Longitute, Latitute: $gps"
    return $gps
}

function InstallAPK{
    param ( $index )

    Log "Installing apk nzt"
    dn installapp --index $index --filename '{{ nztapk_path.msg | default('') }}'
    Start-Sleep 10
    $package = dn adb --index $index --command "shell pm list package | grep com.nztapk"

    if ($package -like "*nzt*"){
        Log "Pakage NZT $package is installed"
    } else {
        Log "Pakage NZT $package is not installed"
    }

    # Log "Installing apk heropoker"
    # dn installapp --index $index --filename '{{ heroapk_path.msg | default('') }}'
    # Start-Sleep 5

    # $package = dn adb --index $index --command "shell pm list package | grep com.symlgame.pokerhero"

#     if ($package -like "*pokerhero*"){
#         Log "Pakage PokerHero $package is installed"
#     } else {
#         Log "Pakage PokerHero $package is not installed"
#   }

#     Log "Installing apk fishpoker"
#     dn installapp --index $index --filename '{{ fishpokerapk_path.msg | default('') }}'
#     Start-Sleep 5

#     $package = dn adb --index $index --command "shell pm list package | grep com.game.fishpoker"

#     if ($package -like "*fishpoker*"){
#         Log "Pakage FishPoker $package is installed"
#     } else {
#         Log "Pakage FishPoker $package is not installed"
#     }
}

Remove-Item -Force "C:\log_setup_nzt.txt" -ErrorAction SilentlyContinue

Set-Alias -Name dn -Value 'C:\LDPlayer\LDPlayer9\dnconsole.exe'
Set-Alias -Name adb -Value 'C:\LDPlayer\LDPlayer9\adb.exe'


adb start-server;

$index_rotation = {{ index_rotation | default('0') }};

$iplocation_service = "{{ iplocation_service | default('ipwho.is') }}"

$isNeedToInstallAPK = $true

$numbersArray = @(
{% for number in emulator_numbers %}
    {{ number }}{% if not loop.last %},{% endif %}
{% endfor %}
)

foreach ($i in $numbersArray) {

    if ( $i -eq 0 ) { continue }

    if ($index_rotation -ne 0) {
        $index = $index_rotation;
    } else {
        $index = $i
    }

    Log 'Start setup'

    StopEmu $index
    StartEmu $index

    if ( $isNeedToInstallAPK -eq $true ) {
        InstallAPK $index
    }

    $gps = GetLocation $index $iplocation_service
    SetLocation $index $gps
    StopEmu $index

    if($index_rotation -ne 0) {
        break;
    }
}

Log 'End of setup'
