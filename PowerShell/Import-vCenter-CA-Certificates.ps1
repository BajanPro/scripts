



################################################################
#          Do not modify anything under this line              #
################################################################


#Remove downloaded certs if they were downloaded previously
Remove-Item $PSScriptRoot\certs -Force -Recurse 

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
   # If session is elevated or user is admin, then continue running.
   $Host.UI.RawUI.WindowTitle = "Install vCenter Self Signed Certs - (Elevated)"
   $Host.UI.RawUI.ForegroundColor = "Green" 
   
   }
else
   {
   # If session not elevated, quit.
   Clear-Host
   Write-host "Need to be run as administrator!"
   $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
   Exit
   }
   
$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent

#Download Certs

$url = "https://10.0.0.10/certs/download"
$output = "$PSScriptRoot\certs.zip"
[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$webClient = new-object System.Net.WebClient
$webClient.DownloadFile( $url, $output )

#Unzip certificates
Unzip "$PSScriptRoot\certs.zip" "$PSScriptRoot"

#Install Certs 
$certs = Get-ChildItem "$PSScriptRoot\certs"
ForEach ($cert in $certs) { 
$ca = "$PSScriptRoot\certs\$cert"
Write-Output "Importing downloaded vCenter certificates into Store"
	try{
		$ImportError = certutil -addstore -enterprise -f -v root "$ca"
	}
	catch{
		Write-Output "certutil failed to import certificate: $ImportError"
	}
}

