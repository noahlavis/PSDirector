param(
    [string]$scope 
)

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
        }
        elseif ($scope -eq "computer") {
            $RegRootPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\PowerShellOrchestrator\"
            if(Test-Path $RegRootPath){
            } else{
                New-Item -Path $RegRootPath
                Set-ItemProperty -Path "HKLM:\SOFTWARE\PowerShellOrchestrator" -Name "first_execution" -Value $(date -Format "dd/MM/yyyy HH:mm:ss")
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
                
                foreach($lines in $AppInfo){

                    if($lines.Split(" ")[0] -match "logs"){
                        $logs = (($AppInfo | Select-String -Pattern "logs ")[0]) -replace '.*\((.*?)\).*', '$1'
                        $logs
                    }
                    if($lines.Split(" ")[0] -match "date"){
                        $date = (($AppInfo | Select-String -Pattern "date ")[0]) -replace '.*\((.*?)\).*', '$1'
                        $date
                    }
                    if($lines.Split(" ")[0] -match "execute"){
                        $execute = (($AppInfo | Select-String -Pattern "execute ")[0]) -replace '.*\((.*?)\).*', '$1'
                        $execute
                    }
                    if($lines.Split(" ")[0] -match "install"){
                        $install = (($AppInfo | Select-String -Pattern "install ")[0]) -replace '.*\((.*?)\).*', '$1'
                        $install
                    }
                    if($lines.Split(" ")[0] -match "clean"){
                        $clean = (($AppInfo | Select-String -Pattern "clean ")[0]) -replace '.*\((.*?)\).*', '$1'
                        $clean
                    }
                }
            }
        }
    }
} else{
    Write-Host "Nothing happen. Maintenance."
}

