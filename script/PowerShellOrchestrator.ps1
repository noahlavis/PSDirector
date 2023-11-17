$root = Split-Path -Path $PSScriptRoot -Parent
$PSOconfig = Get-Content "$root\config.pso"
$maintenance_mode = (($PSOconfig | Select-String -Pattern "maintenance_mode=")-Split "=")[-1]
$test_mode = (($PSOconfig | Select-String -Pattern "test_mode=")-Split "=")[-1]
$whitelist = (((($PSOconfig | Select-String -Pattern "whitelist=")-Split "=")[-1]) -Split '"') -Split ","

if($maintenance_mode -eq 0){

    $hostname = hostname
    if($whitelist -match $hostname -or $whitelist.Length -eq 1){

        $RegRootPath = "HKLM:\SOFTWARE\PowerShellOrchestrator"
        if(Test-Path $RegRootPath){
        } else{
            New-Item -Path $RegRootPath
        }

        $AppsRootFolder = Get-ChildItem "$root\apps\"
        foreach($AppFolder in $AppsRootFolder){

            $AppInfo = Get-Content "$root\apps\$($AppFolder.Name)\instruction.pso"
            $AppGroup = [regex]::Matches($AppInfo, '\{(.*?)\}') | ForEach-Object {$_.Groups[1].Value}
            $PSOgroup = (((([regex]::Matches($PSOconfig, "{$AppGroup}")).Value) -Split "{") -Split "}")[1]
            
            if($AppGroup -eq $PSOgroup){
                foreach($lines in $AppInfo){
                    if($lines.Split(" ")[0] -match "install"){
                        $install
                        $install = (($($lines.Split(" ")[1])) -Split ('"'))[1]
                        Start-Process -FilePath "$root\apps\$AppsRootFolder\$install"
                    }
                }
            }
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\PowerShellOrchestrator" -Name "GROUP" -Value $Group
    }
} else{
    Write-Host "Nothing happen. Maintenance."
}

