#Script to configure IPv6 on the mgmt network (vlan 90), and the data networks (vlans 160/161)
#Snag the mgmt interface
$interface = (Get-NetIPAddress -IPAddress 10.*).InterfaceAlias

#Figure out which node position we are
$device = (Get-NetIPAddress -IPAddress 10.*).IPv4Address.Substring(8)

#Configure IPv6 on VLAN90
new-netipaddress -InterfaceAlias $interface  -IPAddress FD61:6262:6101:0090:f000::5:$device -PrefixLength 64
set-dnsclientserveraddress -interfacealias $interface -serveraddress fd61:6262:6101:90:f000::2

#Do magic to create the virt network
#Grab the Emulex interfaces
$10ginterface = (Get-NetAdapter -InterfaceDescription *Emulex*).InterfaceAlias

#Put them in a NIC Team
New-NetLbfoTeam -Name Team1 -TeamMember $10ginterface -TeamingMode LACP -LoadBalancingAlgorithm HyperVPort -a

#Set the vlan of the default interface and create a new one for vlan 161
Set-NetlbfoTeamNIC -Name Team1 -VlanID 160
Add-NetLbfoTeamNic -Team Team1 -VlanID 161 -a

#Create the vswitch for both vlans and enable sr-iov
New-VMSwitch -Name "openstack-br-160" -NetAdapterName "Team1 - VLAN 160" -AllowManagementOS $True -EnableIov $True
New-VMSwitch -Name "openstack-br-161" -NetAdapterName "Team1 - VLAN 161" -AllowManagementOS $True -EnableIov $True

#Set the vlan on the vswitches
Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "openstack-br-160" -Access -VlanID 160
Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "openstack-br-161" -Access -VlanID 161

#Create IPv4 and IPv6 addresses on the vswitches
New-NetIPAddress -InterfaceAlias "vEthernet (openstack-br-160)" -IPAddress 10.160.0.$device -PrefixLength "16"
New-NetIPAddress -InterfaceAlias "vEthernet (openstack-br-161)" -IPAddress 10.161.0.$device -PrefixLength "16"

new-netipaddress -InterfaceAlias "vEthernet (openstack-br-160)" -IPAddress FD61:6262:6101:0160:f000::5:$device -PrefixLength 64
new-netipaddress -InterfaceAlias "vEthernet (openstack-br-161)" -IPAddress FD61:6262:6101:0161:f000::5:$device -PrefixLength 64

w32tm /config /manualpeerlist:10.90.0.2 /update /syncfromflags:manual

