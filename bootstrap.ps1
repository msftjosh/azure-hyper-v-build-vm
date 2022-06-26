#Install DHCP Server
Install-WindowsFeature DHCP -IncludeManagementTools

#Create the DHCP Administrators and DHCP Users security Groups in Local Users and Groups
netsh dhcp add securitygroups

#Restart the DHCP Service
Restart-Service dhcpserver

#Retrieve upstream DNS Server IP address(es)
$hostDnsServers = Get-DnsClientServerAddress | Where-Object {$_.InterfaceAlias -eq "vEthernet (Microsoft Hyper-V Network Adapter - Virtual Switch)" -and $_.AddressFamily -eq 2} | Select-Object -ExpandProperty ServerAddresses

#Configure a DHCP Scope with Scope Options for Default Gateway and DNS
Add-DhcpServerv4Scope -name "vm-builds" -StartRange 192.168.250.50 -EndRange 192.168.250.100 -SubnetMask 255.255.255.0 -State Active
Set-DhcpServerv4OptionValue -ScopeID 192.168.250.0 -Router 192.168.250.1 -DnsServer $hostDnsServers

#Install Hyper-V
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart

#Create a vSwitch
New-VMSwitch -SwitchName "vm-builds" -SwitchType Internal

#Get the Network Adapter interface index
$interfaceIndex = Get-NetAdapter | Where-Object {$_.Name -eq "vEthernet (Microsoft Hyper-V Network Adapter - Virtual Switch)"} | Select-Object -ExpandProperty ifIndex

#Setup NAT for the vm-build network
New-NetIPAddress -IPAddress 192.168.250.1 -PrefixLength 24 -InterfaceIndex $interfaceIndex
New-NetNat -Name vm-builds-nat -InternalIPInterfaceAddressPrefix 192.168.250.0/24