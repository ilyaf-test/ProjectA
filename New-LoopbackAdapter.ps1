<#  
.SYNOPSIS  
   	Installs the Microsoft Loopback Adapter and configures the server for Direct Service Return method of Hardware Load Balancing. Designed and tested on Windows Server 2008 R2.

.DESCRIPTION  
    Installs and configures the loopback adapter; renames existing adapter; configures strong host send and receive for both. The script uses two utilities. It will automatically download the needed files.

.NOTES  
    Version      	   	: v1.0 - 07/26/2011 - initial version
		Wish list					: Need to handle servers with multiple NICs
    Rights Required		: Local administrator on server
    Sched Task Req'd	: No
    Exchange Version	: 2010 and later
    Lync Version			: 2010 and later
    Author       			: Pat Richard, Exchange MVP
    Email / Blog 			: pat@innervation.com 	http://exchangeblogs.com
    Dedicated Post		: 
    Disclaimer   			: You running this script means you won't blame me if this breaks your stuff.
    Info Stolen from 	: http://social.technet.microsoft.com/Forums/en-US/winserverpowershell/thread/f6a4c454-6088-4022-8f0d-d73181247856/
    									: (loopback requirements) http://marksmith.netrends.com/Lists/Posts/Post.aspx?ID=111
    									: (devcon) http://munashiku.slightofmind.net/20090621/sometimes-64-bit-is-a-pain
    									: (nvspbind) http://archive.msdn.microsoft.com/nvspbind
    									: (shortcut to network interfaces) http://powershell.com/cs/blogs/tips/archive/2011/07/26/shortcut-to-network-cards.aspx
    									: (Regex to match IP addresses) http://stackoverflow.com/questions/106179/regular-expression-to-match-hostname-or-ip-address

.LINK  
	http://exchangeblogs.net

.EXAMPLE
	.\New-LoopbackAdapter.ps1
	
		Description
		-----------
		Adds and configures the loopback adapter, prompting for the VIP IP and subnet mask.
		
.EXAMPLE
	.\New-LoopbackAdapter.ps1 -vipip [ip address] -vipsm [subnet mask]
	
		Description
		-----------
		Adds and configures the loopback adapter with the values supplied in the pipeline
		
.INPUTS
	None. You cannot pipe objects to this script.
#>
#Requires -Version 2.0
param (
		[parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$false, HelpMessage="No VIP IP address specified")] 
		[string]$vipip,
    [parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$false, HelpMessage="No VIP subnet mask specified")] 
    [string]$vipsm
	)
[string] $strFilenameTranscript = $MyInvocation.MyCommand.Name + " " + (hostname)+ " {0:yyyy-MM-dd hh-mmtt}.log" -f (Get-Date)
Start-Transcript -path .\$strFilenameTranscript | Out-Null
$error.clear()

# Detect correct OS here and exit if no match (we intentionally truncate the last character to account for service packs)
#if ((Get-WMIObject win32_OperatingSystem).Version -notmatch '6.1.760'){
#	Write-Host "`nThis script requires a version of Windows Server 2008 R2, which this is not. Exiting...`n" -ForegroundColor Red
#	Stop-Transcript
#	Exit
#} #end OS detection
Clear-Host
pushd
[string] $TargetFolder = $env:temp
[bool] $HasInternetAccess = ([Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]'{DCB00C01-570F-4A9B-8D69-199FDBA5723B}')).IsConnectedToInternet)

function New-FileDownload {
	param (
		[parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true, HelpMessage="No source file specified")] 
		[string]$SourceFile,
    [parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$false, HelpMessage="No destination folder specified")] 
    [string]$DestFolder,
    [parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$false, HelpMessage="No destination file specified")] 
    [string]$DestFile
	)
	# I should clean up the display text to be consistent with other functions
	$error.clear()
	if (!($DestFolder)){$DestFolder = $TargetFolder}
	Get-ModuleStatus -name BitsTransfer
	if (!($DestFile)){[string] $DestFile = $SourceFile.Substring($SourceFile.LastIndexOf("/") + 1)}
	if (Test-Path $DestFolder){
		Write-Host "Folder: `"$DestFolder`" exists."
	} else{
		Write-Host "Folder: `"$DestFolder`" does not exist, creating..." -NoNewline
		New-Item $DestFolder -type Directory
		Write-Host "Done! " -ForegroundColor Green
	}
	if (Test-Path "$DestFolder\$DestFile"){
		Write-Host "File: $DestFile exists."
	}else{
		if ($HasInternetAccess){
			Write-Host "File: $DestFile does not exist, downloading..." -NoNewLine
			Start-BitsTransfer -Source "$SourceFile" -Destination "$DestFolder\$DestFile"
			Write-Host "Done! " -ForegroundColor Green
		}else{
			Write-Host "Internet access not detected. Please resolve and try again." -ForegroundColor red
		}
	}
} # end function New-FileDownload

function New-UnzippedFile	{
	param (
		[parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true, HelpMessage="No zip file specified")] 
		[string]$ZipFile,
    [parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true, HelpMessage="No file to unzip specified")] 
    [string]$UnzipFile,
    [parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true, HelpMessage="No location to unzip file specified")] 
    [string]$UnzipFileLocation
	)
	$error.clear()
	Write-Host "Zip File........................................................[" -NoNewLine
	Write-Host "Unzipping" -ForegroundColor yellow -NoNewLine
	Write-Host "]" -NoNewLine
	if (Get-Item $zipfile){    
		$objShell = new-object -com shell.application
		# where the .zip is
		$FuncZipFolder = $objShell.namespace($ZipFile) 
		# the item in the zip
		$FuncFile = $FuncZipFolder.parsename($UnzipFile)      
		# where the item is to go
		$FuncTargetFolder = $objShell.namespace($UnzipFileLocation)       
		# do the copy of zipfile item to target folder
		$FuncTargetFolder.copyhere($FuncFile)
	}
	if ($error){
		Write-Host "`b`b`b`b`b`b`b`b`b`bfailed!" -ForegroundColor red -NoNewLine
	}else{
		Write-Host "`b`b`b`b`b`b`b`b`b`bdone!" -ForegroundColor green -NoNewLine
	}		
	Write-Host "]    "
} # end function New-UnzippedFile

function Get-ModuleStatus { 
	param	(
		[parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true, HelpMessage="No module name specified!")] 
		[string]$name
	)
	if(!(Get-Module -name "$name")) { 
		if(Get-Module -ListAvailable | ? {$_.name -eq "$name"}) { 
			Import-Module -Name "$name" 
			# module was imported
			return $true
		} else {
			# module was not available
			return $false
		}
	}else {
		# module was already imported
		# Write-Host "$name module already imported"
		return $true
	}
} # end function Get-ModuleStatus

function Remove-ScriptVariables($path) {  
	$result = Get-Content $path |  
	ForEach { if ( $_ -match '(\$.*?)\s*=') {      
			$matches[1]  | ? { $_ -notlike '*.*' -and $_ -notmatch 'result' -and $_ -notmatch 'env:'}  
		}  
	}  
	ForEach ($v in ($result | Sort-Object | Get-Unique)){		
		# Write-Host "Removing" $v.replace("$","")
		Remove-Variable ($v.replace("$","")) -ErrorAction SilentlyContinue
	}
} # end function Get-ScriptVariables

function Test-IP{
    param (
		[parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true, HelpMessage="No prompt text specified")] 
		[string]$text
    )
    # Do {$x = Read-Host $text} while (($X -notmatch "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$") -and ($x -ne ""))
    Do {$x = Read-Host $text} while ($X -notmatch "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$")
    return $x
} # end function Test-IP

	New-FileDownload -SourceFile "http://munashiku.slightofmind.net/downloads/1" $TargetFolder "devcon_x64.zip"
	New-UnzippedFile -zipfile $TargetFolder\devcon_x64.zip -unzipfile devcon.exe -unzipfilelocation $TargetFolder
	# archive.msdn.microsoft.com XP_Nvspbind_package.EXE
	New-FileDownload -SourceFile "http://www.innervation.com/crap/scripts/new-loopbackadapter.ps1/XP_Nvspbind_package.EXE"
	Invoke-Expression "$TargetFolder\XP_Nvspbind_package.EXE /t:$TargetFolder /c /q"
	Set-Location $TargetFolder

	# rename the existing NIC to "net"
	$id = (Get-WmiObject Win32_NetworkAdapter -Filter "ServiceName='netvsc'").NetConnectionID
	netsh int set int name = $id newname = "net"

	# http://support.microsoft.com/kb/311272/en-us
	# http://munashiku.slightofmind.net/20090621/sometimes-64-bit-is-a-pain
	.\devcon.exe -r install $env:windir\Inf\Netloop.inf *MSLOOP | Out-Null

	# rename the loopback NIC to "loopback"
	$id = (Get-WmiObject Win32_NetworkAdapter -Filter "Description='Microsoft Loopback Adapter'").NetConnectionID
	netsh int set int name = $id newname = "loopback"
  
	$nic = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "Description='Microsoft Loopback Adapter'"

	# Set the metric to 254
	# $nic.SetIPConnectionMetric(254)	
	netsh int ip set interface "Loopback" metric=254 | Out-Null

	# Set the "Register this connection's address in DNS" to unchecked
	$nic.SetDynamicDNSRegistration($false) | Out-Null

	# disable bindings
	# http://archive.msdn.microsoft.com/nvspbind
	.\nvspbind /d "net" ms_tcpip6 | Out-Null
	.\nvspbind /d "loopback" ms_msclient | Out-Null
	.\nvspbind /d "loopback" ms_pacer | Out-Null
	.\nvspbind /d "loopback" ms_server | Out-Null
	.\nvspbind /d "loopback" ms_tcpip6 | Out-Null
	.\nvspbind /d "loopback" ms_lltdio | Out-Null
	.\nvspbind /d "loopback" ms_rspndr | Out-Null
	
	if (!$vipip){
		$vipip = Test-IP -text "Please enter valid IP address"
	}
	if (!$vipsm){
		$vipsm = Test-IP -text "Please enter valid subnet mask"
	}
	
	$nic.EnableStatic($vipip,$vipsm) | Out-Null

	# set the binding order
	.\nvspbind /++ "net" * | Out-Null

	# disable IPv6 globally (requires reboot)
	# Set-ItemProperty -path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters -name DisabledComponents -value 0xffffffff -type dword

	# configure weak host send and weak host receive
	netsh interface ipv4 set interface "net" weakhostreceive=enabled | Out-Null
	netsh interface ipv4 set interface "Loopback" weakhostreceive=enabled | Out-Null
	netsh interface ipv4 set interface "Loopback" weakhostsend=enabled | Out-Null

# let's see how we did
explorer.exe '::{7007ACC7-3202-11D1-AAD2-00805FC1270E}'

popd
Stop-Transcript

# let's clean up after ourselves per http://www.ucblogs.net/blogs/exchange/archive/2011/07/08/Cleaning-up-script-variables-in-PowerShell.aspx
Remove-ScriptVariables($MyInvocation.MyCommand.Name)
