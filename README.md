Explication
Les paramètres de commande
Un paramètre de commande correspond à une valeur chaîne dans une clé regedit. Cette valeur aura un nom du type « CmdXXXXX » où XXXXX correspond à l’action de la donnée de cette valeur.  

Le script devra être capable de répondre à ces paramètres de commande (valeur chaîne) :
CmdDownload : Télécharge la ou les sources d’un logiciel ou autre en local.
CmdInstall : Procède à l’installation de la ou les sources.
CmdClean : Procède à la suppression des sources en local.
CmdUninstall : Procède à la désinstallation d’un logiciel.
CmdConfig : Procède à une configuration (cas spécifique).
Un paramètre ne devra pas être dépendant d’un autre.

Voici un exemple de ce qu’une valeur peut contenir comme données :
Nom
Type
Données
CmdDownload
REG_SZ
Copy \\srva-file\app\google\* C:\Temp\google\
CmdInstall
REG_SZ
Cmd.exe /c C:\Temp\google\install.bat
CmdClean
REG_SZ
Remove-item C:\Temp\google\*
CmdUninstall
REG_SZ
MsiExec.exe /X{2505676D-0245-4775-B7BE-F4C1DDC902D8}
CmdConfig
REG_SZ
wuauclt /updatenow


Les paramètres de temps
Un paramètre de temps correspond à une valeur chaîne dans une clé regedit. Cette valeur aura un nom du type « XXXXXFrom » où XXXXX correspond à l’action de la donnée de cette valeur.  


Le script devra être capable de répondre à ces paramètres de temps (valeur chaîne) :
UninstalledFrom : Bloque CmdClean si la date n’est pas atteinte (dd/MM/yyyy).
InstalledFrom : Bloque CmdInstall si la date n’est pas atteinte (dd/MM/yyyy).

Voici un exemple de ce qu’une valeur peut contenir comme données :
Nom
Type
Données
InstalledFrom
REG_SZ
01/05/2023
UninstalledFrom
REG_SZ
31/05/2023


Les paramètres de temps n’ont aucune incidence sur le script s’ils ne sont pas présents dans la clé. En d’autres termes, ces paramètres doivent être définis uniquement si le besoin est. Si un ou plusieurs paramètres de temps existent, le script le prendra en compte.

La valeur « NextRun »
Le script exécute un à un les paramètres de commande présents dans la valeur « NextRun » jusqu’à ce que la valeur soit vide. À défaut, si la valeur « NextRun » n’est pas présente dans la clé, le script passera à la clé suivante.

Cette valeur a trois règles : 
Doit être composé de paramètre commande existant.
Les paramètres doivent être séparés par le délimiteur « + ».
Les paramètres devront se vider de la valeur de NextRun un à un avec une mise à jour en direct.

Voici l’exemple d’une valeur chaîne de « NextRun » : 
Nom
Type
Données
NextRun
REG_SZ
CmdUninstall+CmdDownload+CmdInstall+CmdClean

La valeur NextRun ne peut pas prendre en compte les paramètres de temps.

Les valeurs de vérifications
Le script devra vérifier si les paramètres suivants ont déjà été exécuté : CmdDownload, CmdInstall, CmdUninstall. On ignore les autres paramètres. Pour cela, le script devra créer une valeur DWORD avec comme valeur 1 si le paramètre a été lancé avec succès. 

Le nom de valeur DWORD correspondra au paramètre : 
IsDownloaded pour CmdDownload.
IsInstalled pour CmdInstall.
IsUninstalled pour CmdUninstall.

Voici l’exemple d’une valeur DWORD de « NextRun » : 
Nom
Type
Données
IsDownloaded
REG_DWORD
0x00000001 (1)
IsInstalled
REG_DWORD
0x00000001 (1)
IsUninstalled
REG_DWORD
0x00000001 (1)

Par défaut, cette valeur DWORD n’est pas créée, l’existence de ces valeurs signifie donc que le script a bien tourné.





La gestion d’erreur
Le script devra avoir une gestion d’erreur. Le script devra s’arrêter dès la première erreur qu’il rencontre tout en sauvegardant dans une valeur nommé « Output » le code d’erreur détaillé.

Si l’erreur interviens au milieu du lancement d’un paramètre, le script ne devra pas supprimer le paramètre en question de la valeur « NextRun ».
S’il n’y a pas eu d’erreur, la valeur « Output » correspondra au moment exact d’exécution du script avec un message disant qu’aucune erreur ne s’est déclarée.

Voici l’exemple d’une valeur chaîne de « Output » : 
Nom
Type
Données
Output
REG_SZ
(mercredi 12 avril 2023 19:33:42), Il n’y a pas eu d’erreur.


Le contexte du script
Le script devra également s’exécuter selon un contexte avec le paramètre « -Scope ». Les deux contextes à configurés sont utilisateur et ordinateur.
Contexte Utilisateur
Le lancement du script dans le contexte utilisateur occasionne deux changements au niveau du script :
$registre=Get-ChildItem -Path Registry::HKEY_CURRENT_USER\SOFTWARE\$REG_FOLDER\
$path="HKCU:\$elements"

Étant dans le contexte utilisateur, le script agit dans la partie HKEY_CURRENT_USER .

Pour lancer le script dans ce contexte il suffit d’executer cette commande :
Script.ps1  -Scope user

Contexte Ordinateur
Le lancement du script dans le contexte ordinateur occasionne deux changements au niveau du script :
$registre=Get-ChildItem -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\$REG_FOLDER\ 
$path="HKLM:\$elements"

Étant dans le contexte utilisateur, le script agit dans la partie HKEY_LOCAL_MACHINE.

Pour lancer le script dans ce contexte il suffit d’executer cette commande :
Script.ps1  -Scope computer
