$filePath = "debian-11.1.0-amd64-netinst.iso"
$debianURL = "https://cdimage.debian.org/debian-cd/11.5.0/amd64/iso-cd/debian-11.5.0-amd64-netinst.iso"

function CreateVMUnattended {

  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [string]$filePath,
    [Parameter(Mandatory)]
    [string]$debianURL,
    [Parameter(Mandatory)]
    [string]$machineName,    
    [Parameter(Mandatory)]
    [string]$template    
  )
  
  Write-Host '================================================================================'
  Write-Host '=== Creating and Installing '$machineName
  Write-Host '================================================================================'

  # Download installation meddium if necessary
  if (Test-Path($filePath)) {
    Write-Host 'Skipping download,'$filePath' already exists'
  }
  else {
    Import-Module BitsTransfer
    Write-Host 'Downloading Debian ISO-Image '$debianURL
    Start-BitsTransfer -Source $debianURL -Destination $filePath
  }
  # Create and configure the machine
  Write-Host '=== Creating VM '$machineName
  VBoxManage createvm --name $machineName --ostype Debian_64 --register 
  Write-Host '=== Turning ioapic on'
  VBoxManage modifyvm $machineName --ioapic on 
  Write-Host '=== Setting memory to 1G for installation'
  VBoxManage modifyvm $machineName --memory 1024 --vram 16 
  Write-Host '=== Adding a NAT network to the machine'
  VBoxManage modifyvm $machineName --nic1 nat 
  Write-Host '=== Adding a SATA controller to the machine'
  VBoxManage storagectl $machineName --name SATA  --add sata --controller IntelAhci
  Write-Host '=== Creating virual system disk'
  VBoxManage createmedium disk --filename "$home\VirtualBox VMs\$machineName\$machineName-SATA0.vdi"  --format VDI --size 8192
  Write-Host '=== Attaching disk to SATA interface'
  VBoxManage storageattach $machineName --storagectl SATA --port 0 --device 0 --type hdd --medium "$home\VirtualBox VMs\$machineName\$machineName-SATA0.vdi"
  Write-Host '=== Preparing unattended Debian installation'
  $tempPath = ([System.IO.Path]::GetTempPath()+'~'+([System.IO.Path]::GetRandomFileName()))
  mkdir $tempPath
  VBoxManage unattended install $machineName --auxiliary-base-path $tempPath/ --user=sysadmin --password=abc123 --country=CH --time-zone=UTC --hostname=$machineName.local --iso=$filePath --package-selection-adjustment=minimal --post-install-template $template
  (Get-Content -Path $tempPath\isolinux-isolinux.cfg) -replace "^default vesa.*","default install" | Set-Content $tempPath\isolinux-isolinux.cfg
  Write-Host '=== Starting vm'
  
  # Engage the unattended installation
  VBoxManage startvm $machineName
  Write-Host '=== Waiting for installation to complete'
}

function WaitVMShutdown {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [string]$machineName
  )
  
  # Poll machine state until everything is finished and the machine is shut down completely!
  while((VBoxManage showvminfo $machineName | findstr State).split(" ")[23] -eq "running") {
    Start-Sleep -Seconds 1
  }
  while((VBoxManage showvminfo $machineName | findstr State).split(" ")[23] -ne "powered") {
    Start-Sleep -Seconds 1
  }
  
  Write-Host '================================================================================'
  Write-Host '=== Provisioning of '$machineName' done!'
  Write-Host '================================================================================'
}

# Create and install all machines in parallel
CreateVMUnattended -filePath $filePath -debianURL $debianURL -machineName "proxy-client" -template proxy-client-install.sh
CreateVMUnattended -filePath $filePath -debianURL $debianURL -machineName "proxy" -template proxy-install.sh

# Just for safety ...
Start-Sleep -Seconds 10

WaitVMShutdown -machineName "proxy-client"
WaitVMShutdown -machineName "proxy"

# Just for safety ...
Start-Sleep -Seconds 10

# Configure our local client
VBoxManage modifyvm proxy-client --nic1 intnet
VBoxManage modifyvm proxy-client --intnet1 proxy_local
VBoxManage modifyvm proxy-client --memory 512 --vram 16 

# Configure the main firewall
VBoxManage modifyvm proxy --nic1 intnet
VBoxManage modifyvm proxy --intnet1 proxy_local
VBoxManage modifyvm proxy --nic2 nat
VBoxManage modifyvm proxy --memory 256 --vram 16 
