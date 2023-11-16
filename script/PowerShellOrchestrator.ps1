$root = Split-Path -Path $PSScriptRoot -Parent
$hostname = hostname

$PSOconfig = Get-Content "$root\config.pso"

$maintenance_mode = (($PSOconfig | Select-String -Pattern "maintenance_mode=")-Split "=")[-1]
$test_mode = (($PSOconfig | Select-String -Pattern "test_mode=")-Split "=")[-1]
$whitelist = (((($PSOconfig | Select-String -Pattern "whitelist=")-Split "=")[-1]) -Split '"') -Split ","

if($maintenance_mode -eq 0){

    if($whitelist -match $hostname){

        $RegRootPath = "HKLM:\SOFTWARE\PowerShellOrchestrator"
        if(Test-Path $RegRootPath){
        }else{
            New-Item -Path $RegRootPath
        }

        $AllGroups = [regex]::Matches($PSOconfig, '\{(.*?)\}') | ForEach-Object {
            $_.Groups[1].Value
        }

        foreach($Group in $AllGroups){
            $HostGroup = (((($PSOconfig | Select-String -Pattern "{$Group}") -Split "=")[-1]) -Split '"') -Split ","
            $HostGroup
        }

        Set-ItemProperty -Path "HKLM:\SOFTWARE\PowerShellOrchestrator" -Name "GROUPE" -Value $Groupe
    }
}else{
    Write-Host "Nothing happen. Maintenance."
}
