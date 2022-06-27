#Check if Azure CLI is installed if so skip to next
if($null -ne (Get-WmiObject -Class Win32_Product | Where-Object name -like "*Azure CLI*"))
{
    Write-Host "DHCP Server installation already complete"
} else {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
    Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
    Remove-Item .\AzureCLI.msi
}

#Check if DHCP Server is installed if so skip to next
if((Get-WindowsFeature DHCP).Installed)
{
    Write-Host "DHCP Server installation already complete"
} else {
    #Install DHCP Server
    Install-WindowsFeature DHCP -IncludeManagementTools

    #Create the DHCP Administrators and DHCP Users security Groups in Local Users and Groups
    netsh dhcp add securitygroups

    #Restart the DHCP Service
    Restart-Service dhcpserver
}

#Check if vm-builds DHCP Scope exists if so skip to next
if($null -ne (Get-DhcpServerv4Scope -ScopeId 192.168.250.0))
{
    Write-Host "vm-builds DHCP scope exists"
} else {
    #Retrieve upstream DNS Server IP address(es)
    $hostDnsServers = Get-DnsClientServerAddress | Where-Object {$_.InterfaceAlias -eq "vEthernet (Microsoft Hyper-V Network Adapter - Virtual Switch)" -and $_.AddressFamily -eq 2} | Select-Object -ExpandProperty ServerAddresses

    #Configure a DHCP Scope with Scope Options for Default Gateway and DNS
    Add-DhcpServerv4Scope -name "vm-builds" -StartRange 192.168.250.50 -EndRange 192.168.250.100 -SubnetMask 255.255.255.0 -State Active
    Set-DhcpServerv4OptionValue -ScopeID 192.168.250.0 -Router 192.168.250.1 -DnsServer $hostDnsServers
}

#Check if Hyper-V is installed if so skip to next
if((Get-WindowsFeature Hyper-V).Installed)
{
    Write-Host "Hyper-V installation already complete"
} else {
    #Install Hyper-V
    Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart
}

#Check if vm-builds VMSwitch exists if so skip to next
if($null -ne (Get-VMSwitch -name vm-builds))
{
    Write-Host "vm-builds VMSwitch exists"
} else {
    #Create a vSwitch
    New-VMSwitch -SwitchName "vm-builds" -SwitchType Internal
}

#Check if vm-builds-nat NetNat exists if so skip to next
if($null -ne (Get-NetNat -name vm-builds-nat))
{
    Write-Host "vm-builds-nat NetNat exists"
} else {
    #Get the Network Adapter interface index
    $interfaceIndex = Get-NetAdapter | Where-Object {$_.Name -eq "vEthernet (Microsoft Hyper-V Network Adapter - Virtual Switch)"} | Select-Object -ExpandProperty ifIndex

    #Setup NAT for the vm-build network
    New-NetIPAddress -IPAddress 192.168.250.1 -PrefixLength 24 -InterfaceIndex $interfaceIndex
    New-NetNat -Name vm-builds-nat -InternalIPInterfaceAddressPrefix 192.168.250.0/24
}

# If you want to add additional bootstraping do it below here
#   - for example setup a VM with the proper resources like Disk(s), NIC(s), Memory, CPU etc (and disable Checkpoints)
#   - download your 3rd party ISO image and mount to VM