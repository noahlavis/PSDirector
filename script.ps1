$REG_FODER = ""

param(
    [string]$Scope 
)


if ($Scope -eq "user") {
    $registre=Get-ChildItem -Path Registry::HKEY_CURRENT_USER\SOFTWARE\$REG_FODER\
    $param="user"
}
elseif ($Scope -eq "computer") {
    $registre=Get-ChildItem -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\$REG_FODER\
    $param="computer"
}
else {
    Write-Error "Paramètre invalide. Utilisez 'user' ou 'computer'."
}


foreach($elements in $registre){


    if ($param -eq "user") {
        $path="HKCU:\$elements"
    }
    elseif ($param -eq "computer") {
        $path="HKLM:\$elements"
    }
    else {
        Write-Error "Paramètre invalide. Utilisez 'user' ou 'computer'."
    }


    $config=Get-ItemProperty -Path $path  
    
    $NextRun=$config.NextRun


    while($NextRun.count -ne 0 -or $NextRun.count -ne $null -or $NextRun -ne ""){


        $NextRunList = $NextRun.Split("+")
        $NextRunCommande = $NextRunList[0]


        $NextRunList = $NextRun
        $NextRunList = $NextRun.Split("+")


        if ($NextRunList.Contains($NextRunCommande)) {


            $NewNextRunList = @()
            foreach ($Commande in $NextRunList) {
                if ($Commande -contains $NextRunCommande) {
                    
                } else {$NewNextRunList += $Commande}
            }
            $NextRunList = $NewNextRunList


            $Nextrun = $NextRunList -join "+"
        }
                  
		$today=get-date
                
        if($NextRunCommande -contains "CmdUninstall"){


            if($config.UninstalledFrom){
                $UninstalledFrom=[Datetime]::ParseExact($config.UninstalledFrom, 'dd/MM/yyyy', $null)
                if($today -lt $UninstalledFrom){
                    break
                }
             }


            $verifIsUninstalled=$config.IsUninstalled
            if($verifIsUninstalled -eq "1"){
                
            } else {
                $commandexe=Get-ItemPropertyValue -Path $path -Name $NextRunCommande
                Invoke-Expression $commandexe
            }
        }
        
        if($NextRunCommande -contains "CmdDownload"){
            $verifIsDownloaded=$config.IsDownloaded
            if($verifIsDownloaded -eq "1"){
                
            } else {
                $commandexe=Get-ItemPropertyValue -Path $path -Name $NextRunCommande
                Invoke-Expression $commandexe
            }
        }


        elseif($NextRunCommande -eq "CmdInstall"){
            if($config.InstalledFrom){
                $InstalledFrom=[Datetime]::ParseExact($config.InstalledFrom, 'dd/MM/yyyy', $null)
                if($today -lt $InstalledFrom){
                    break
                }
             }
            
            $verifIsInstalled=$config.IsInstalled
            $verifIsNetworkInstall=$config.NetworkInstall+$config.IsDownloaded
            if($verifIsInstalled -eq "1"){
                
            } else {
                $commandexe=Get-ItemPropertyValue -Path $path -Name $NextRunCommande
                Invoke-Expression $commandexe
            }
        }


        elseif($NextRunCommande -eq "CmdClean"){
            $verifIsDownloaded=$config.IsDownloaded
			$verifIsInstalled=$config.IsInstalled
            if($verifIsDownloaded -eq "0" -and $verifIsInstalled -eq "0"){
                
            } else {
                $commandexe=Get-ItemPropertyValue -Path $path -Name $NextRunCommande
                Invoke-Expression $commandexe
            }
        }


        $listecommandelog+=$NextRunCommande


        if($error[0].length -gt 0){
            New-ItemProperty -Path $path -Name Output -Value "($listecommandelog, $today, $error[0]" -PropertyType String -Force
            break
        }
   
        if($NextRunCommande -eq "CmdUninstall"){
            New-ItemProperty -Path $path -Name IsUninstalled -Value 1 -PropertyType DWORD -Force
        }
        if($NextRunCommande -eq "CmdDownload"){
            New-ItemProperty -Path $path -Name IsDownloaded -Value 1 -PropertyType DWORD -Force
        }
        if($NextRunCommande -eq "CmdInstall" -and $today -gt $InstalledFrom){
            New-ItemProperty -Path $path -Name IsInstalled -Value 1 -PropertyType DWORD -Force
        }


		if($error[0].length -eq 0){
			New-ItemProperty -Path $path -Name Output -Value "($listecommandelog, $today) Il n'y a pas eu d'erreur." -PropertyType String -Force 
		}




        New-ItemProperty -Path $path -Name NextRun -Value $NextRun -PropertyType String -Force 


        
        if($NextRunCommande -eq "" -or $NextRunCommande -eq $null){
            break
        }
    }
}


exit     
