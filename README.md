# azure-hyper-v-build-vm
Creates a Windows Server that runs Hyper-V with nested virtualization including a NAT'd vSwitch and DHCP configuration. This allows for the creation and configuration of Virtual Machines using 3rd party images that can be used to create virtual disks (VHD) and images for future server builds.

## GOAL
Create a VM with minimum resrouces to control cost as well as offer a disposible option for automating VHD creation from supplied disk images where configuration and setup is required prior to using the VHD to create additional Azure VMs.