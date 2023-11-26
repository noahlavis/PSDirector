#param(
#    [string]$scope 
#)

$scope = "computer"

$root = Split-Path -Path $PSScriptRoot -Parent
$PSOconfig = Get-Content "$root\config.pso"
$maintenance_mode = (($PSOconfig | Select-String -Pattern "maintenance_mode=")-Split "=")[-1]
$whitelist = (((($PSOconfig | Select-String -Pattern "whitelist=")-Split "=")[-1]) -Split '"') -Split ","


if($maintenance_mode -eq 0){

    $hostname = hostname
    if($whitelist -match $hostname -or $whitelist.Length -eq 1){

        if ($scope -eq "user") {
            $RegRootPath = "Registry::HKEY_CURRENT_USER\SOFTWARE\PowerShellOrchestrator\"
            if(Test-Path $RegRootPath){
            } else{
                New-Item -Path $RegRootPath
                Set-ItemProperty -Path "HKLM:\SOFTWARE\PowerShellOrchestrator" -Name "first_execution" -Value $(date -Format "dd/MM/yyyy HH:mm:ss")
            }
            $PSORootPath = "C:\Users\$((whoami).Split("\")[-1])\AppData\Local\PowerShellOrchestrator"
            if(Test-Path $PSORootPath){
            } else{
                mkdir -Path $PSORootPath
            }
        }
        elseif ($scope -eq "computer") {
            $RegRootPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\PowerShellOrchestrator\"
            if(Test-Path $RegRootPath){
            } else{
                New-Item -Path $RegRootPath
                Set-ItemProperty -Path "HKLM:\SOFTWARE\PowerShellOrchestrator" -Name "first_execution" -Value $(date -Format "dd/MM/yyyy HH:mm:ss")
            }
            $PSORootPath = "C:\Program Files\PowerShellOrchestrator"
            if(Test-Path $PSORootPath){
            } else{
                mkdir -Path $PSORootPath
            }
        }
        else {
            Write-Error "Use 'user' or 'computer'."
            exit
        }
       
        $AppsRootFolder = Get-ChildItem "$root\apps\"
        foreach($AppFolder in $AppsRootFolder){

            if(Test-Path "$root\apps\$($AppFolder.Name)\instruction.pso"){
                $AppInfo = Get-Content "$root\apps\$($AppFolder.Name)\instruction.pso"
            }else{
                Write-Error "intruction.pso not exist for $($AppFolder)"
                continue 
            }
            
            $AppGroup = [regex]::Matches($AppInfo, '\{(.*?)\}') | ForEach-Object {$_.Groups[1].Value}
            $PSOgroup = (((([regex]::Matches($PSOconfig, "{$AppGroup}")).Value) -Split "{") -Split "}")[1]
            if($AppGroup -eq $PSOgroup){

                
                if((($AppInfo | Select-String -Pattern "for ")[0]) -replace '.*\((.*?)\).*', '$1' -notlike $scope){
                    continue
                }

                if(Test-Path $RegRootPath\$($AppFolder.Name)){
                } else{
                    New-Item -Path $RegRootPath\$($AppFolder.Name)
                }
                
                $continue = 1
                $conf_order = ""
                foreach($lines in $AppInfo){
                    
                    if($lines -match "^date_execute_online \((.*?)\)"){
                        $date_execute_online = (($AppInfo | Select-String -Pattern "date_execute_online ")[0]) -replace '.*\((.*?)\).*', '$1'
                        Set-ItemProperty -Path "$RegRootPath\$($AppFolder.Name)" -Name "date_execute_online" -Value $date_execute_online
                        $conf_order += "date_execute_online, "

                        $date_execute_online
                        if($date_execute_online -gt $(date -Format "dd/MM/yyyy HH:mm:ss")){
                            $continue = 0
                        }
                    }
                    if($lines -match "^date_execute_offline \((.*?)\)"){
                        $date_execute_offline = (($AppInfo | Select-String -Pattern "date_execute_offline ")[0]) -replace '.*\((.*?)\).*', '$1'
                        Set-ItemProperty -Path "$RegRootPath\$($AppFolder.Name)" -Name "date_execute_offline" -Value $date_execute_offline
                        $conf_order += "date_execute_offline, "

                        $date_execute_offline
                        if($date_execute_offline -gt $(date -Format "dd/MM/yyyy HH:mm:ss")){
                            $continue = 0
                        }
                    }
                    if($lines -match "^date_download \((.*?)\)"){
                        $date_download = (($AppInfo | Select-String -Pattern "date_download ")[0]) -replace '.*\((.*?)\).*', '$1'
                        Set-ItemProperty -Path "$RegRootPath\$($AppFolder.Name)" -Name "date_download" -Value $date_download
                        $conf_order += "date_download, "

                        $date_download
                        if($date_download -gt $(date -Format "dd/MM/yyyy HH:mm:ss")){
                            $continue = 0
                        }
                    }
                    if($lines -match "^date_install_msi \((.*?)\)"){
                        $date_install_msi = (($AppInfo | Select-String -Pattern "date_install_msi ")[0]) -replace '.*\((.*?)\).*', '$1'
                        Set-ItemProperty -Path "$RegRootPath\$($AppFolder.Name)" -Name "date_install_msi" -Value $date_install_msi
                        $conf_order += "date_install_msi, "

                        $date_install_msi
                        if($date_install -gt $(date -Format "dd/MM/yyyy HH:mm:ss")){
                            $continue = 0
                        }
                    }
                    if($lines -match "^execute_script \((.*?)\)" -and $continue -eq 1){
                        $execute_script = (($AppInfo | Select-String -Pattern "execute_script \((.*?)\)")[0]) -replace '.*\((.*?)\).*', '$1'
                        Set-ItemProperty -Path "$RegRootPath\$($AppFolder.Name)" -Name "execute_script" -Value $execute_script
                        $conf_order += "execute_script, "

                        $execute_script
                    }
                    if($lines -match "^clean \((.*?)\)" -and $continue -eq 1){
                        $clean = (($AppInfo | Select-String -Pattern "clean ")[0]) -replace '.*\((.*?)\).*', '$1'
                        Set-ItemProperty -Path "$RegRootPath\$($AppFolder.Name)" -Name "clean" -Value $clean
                        Set-ItemProperty -Path "$RegRootPath\$($AppFolder.Name)" -Name "is_clean" -Value 0 -Type QWord
                        $conf_order += "clean, "

                        $clean
                    }     
                }
                Set-ItemProperty -Path "$RegRootPath\$($AppFolder.Name)" -Name "(conf)_order" -Value $conf_order
                Set-ItemProperty -Path "$RegRootPath\$($AppFolder.Name)" -Name "(conf)_hostname" -Value $(hostname)
            }
        }
    }
} else{
    Write-Host "Nothing happen. Maintenance."
}

