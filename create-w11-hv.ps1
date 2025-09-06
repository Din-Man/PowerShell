$VMName = Read-Host -Prompt "Please provide the Virtual Machine Name"
$SwitchName = Read-Host -Prompt "Please provide the name of the Virtual Switch to be used"
$ISOFile = Read-Host -Prompt "Please provide the full path for the Windows 11 install media (ISO file)"
#$VMPath = Read-Host -Prompt "Please provide the path to store the VM"
$HyperVPath = Read-Host -Prompt "Please provide the Hyper V base path"
New-VM -Name $VMName -Generation 2 -MemoryStartupBytes 4096MB -SwitchName $SwitchName -Path $HyperVPath\"Virtual Machines"\$VMName -NewVHDPath $HyperVPath\"Virtual Hard Disks"\$VMName".vhdx" -NewVHDSizeBytes 127000MB
Set-VM -Name $VMName -ProcessorCount 4 -AutomaticCheckpointsEnabled $false
Add-VMDvdDrive -VMName $VMName -Path $ISOFile
$DVDDrive = Get-VMDvdDrive -VMName $VMName
Set-VMFirmware -BootOrder $DVDDrive -VMName $VMName
Set-VMKeyProtector -VMName $VMName -NewLocalKeyProtector
Enable-VMTPM -VMName $VMName