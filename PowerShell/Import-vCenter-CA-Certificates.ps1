#Remove downloaded certs if they were downloaded previously
Remove-Item $PSScriptRoot\vcsa-certs -Force -Recurse | Out-Null

#Function for unzipping
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}


# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
 
# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
 
# Check to see if we are currently running "as Administrator"
if ($myWindowsPrincipal.IsInRole($adminRole))
   {
   # If session is elevated or user is an admin, then continue running.
   $Host.UI.RawUI.WindowTitle = "Import vCenter CA Certificates - (Elevated)"
   $Host.UI.RawUI.ForegroundColor = "Green" 
   Clear-Host
   }
else
   {
   # If session not elevated, quit.
   Clear-Host
   Write-Host "Need to be run as administrator!"
   $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
   Exit
   }

$vCenter = Read-Host -Prompt 'Enter your vCenter FQDN or IP address'   
Write-Host ""
$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent

#Download Certs
Write-Host "Attempting to download CA certificates from vCenter"
$url = "https://$vCenter/certs/download"
$output = "$PSScriptRoot\certs.zip"
[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$webClient = new-object System.Net.WebClient
Try{$webClient.DownloadFile( $url, $output )}
Catch{
Write-Warning -Message "Download failed! Please check vCenter FQDN or IP and try again." 
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Exit
}

#Unzip certificates
Write-Host "Unzipping CA certificates"
Try{Unzip "$PSScriptRoot\certs.zip" "$PSScriptRoot\vcsa-certs"}
Catch{
Write-Warning -Message "Unable to extract certificates, please ensure they downloaded properly and try again." 
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Exit
}

#Install Certs 
$certs = Get-ChildItem "$PSScriptRoot\vcsa-certs\certs"
ForEach ($cert in $certs) { 
$ca = "$PSScriptRoot\vcsa-certs\$cert"
Write-Output "Importing downloaded vCenter certificates into Trusted Root Store"
	Try{
		$ImportError = certutil -addstore -enterprise -f -v root "$ca"
	}
	Catch{
		Write-Output "certutil failed to import certificate: $ImportError"
	}
}

