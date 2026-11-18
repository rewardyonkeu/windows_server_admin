# 01-windows-server-baseline.md #

### Welcome to my IT System Engineer journey!

In this series, I’ll be documenting the practical steps, configurations, and architectural decisions for managing VMware, Linux, and Windows Server environments.

This guide covers the foundational phase: Deploying Windows Server 2016 on a VMware ESXi VM and applying a strict post-installation baseline configuration.

While these steps focus on Server 2016 on ESXi, the exact workflow applies to newer versions (2019/2022/2025) and other hypervisors.

Part 1: Installing Windows Server on a Virtual Machine
Step 1: Download the ISO
Action: Download the 64-bit ISO from the Microsoft Evaluation Center.

Why: You need installation media. For a home lab or testing environment, the Evaluation Center is the best place to grab official, unmodified ISOs without a license key upfront.

Step 2: Mount the ISO to the VM
Action: Upload the ISO to your VMware datastore, create a new VM, and attach the ISO via the virtual CD/DVD drive. Make sure to check "Connect at power on."

Why: A VM doesn't have physical media. By connecting the ISO at the virtual hardware level, the VM's BIOS/UEFI will recognize it as a bootable device.

Step 3: Boot and Initial Setup
Action: Power on the VM, press any key to boot from CD/DVD, and wait for the Windows Setup window. Select your language, time, and keyboard preferences.

Why: Ensure your keyboard layout matches your physical hardware to avoid typing headaches later, especially for strong passwords.

Step 4: Choose the OS Edition
Action: Select Windows Server 2019 Standard Evaluation (Desktop Experience).

Why: You can choose Server Core (command-line only) for maximum performance and a smaller attack surface. However, for learning and baseline administration, Desktop Experience provides a GUI (Server Manager), making it much easier to learn the OS, especially if you are just starting out.

Step 5: Installation Type and Disk Partitioning
Action: Select "Custom: Install Windows only (advanced)." Select the unallocated space on your 100GB virtual drive and click Next.

Why: Since this is a fresh VM, you are not upgrading. Selecting the unallocated space allows Windows Setup to automatically format the drive and create the necessary system partitions.

Step 6: First Login
Action: After the installation finishes and the server reboots (sometimes several times), you will be prompted to set a password for the built-in Administrator account. Press Ctrl+Alt+Delete to unlock, and sign in.

Why: Setting a strong password immediately is a critical security baseline. Once you are signed in, Server Manager will launch automatically.

Part 2: Post-Installation Baseline Configuration
Never deploy a server directly out of the box. Use a checklist to ensure it is secure, identifiable, and ready for production workloads. Here is my standard post-install checklist.

1. Disable Automatic Server Manager Startup
Action: Go to Manage > Server Manager Properties > Check "Do not start Server Manager automatically at logon."

Why: Server Manager is a resource-heavy console. Once you configure the server, you rarely need to look at it constantly. Disabling it saves CPU/RAM (especially on VMs) and prevents a cluttered desktop. You can always launch it manually when needed.

2. Turn Off IE Enhanced Security Configuration
Action: In Server Manager > Local Server, click on "IE Enhanced Security Configuration" and turn it off for both Administrators and Users.

Why: Windows Server is incredibly restrictive by default. IE Enhanced Security blocks almost all web browsing. While you shouldn't use a server for browsing the web, this setting will block standard Microsoft tools, help menus, and downloads.

3. Set the Correct Time Zone
Action: Right-click the clock in the taskbar > Adjust date/time > Set your correct Time Zone.

Why: Accurate timekeeping is critical for logging (correlating events across servers), and it is mandatory for Active Directory authentication (Kerberos protocol). If the time drifts too far, AD will break.

4. Change the Computer Name
Action: In Server Manager > Local Server, click the computer name. Change it to something identifiable (e.g., IAD00-2019) and reboot.

Why: Default names like WIN-QJ4K9... are meaningless. A naming convention (like identifying it as a Domain Controller or Web Server) makes network management and monitoring vastly easier.

5. Configure a Static IP Address
Action: Open PowerShell and run Get-NetIPConfiguration to check your current settings. Then, rename your network adapter to something descriptive (e.g., Network-192x). Finally, go to the adapter's IPv4 properties and set a static IP, subnet mask, gateway, and DNS servers (e.g., Google DNS 8.8.8.8).

Why: Servers should never use DHCP. If a server's IP changes, clients won't be able to find it, DNS records will break, and the entire network will suffer. A static IP is a non-negotiable requirement for infrastructure.

6. Enable Remote Desktop (RDP)
Action: Go to System Properties > Remote > Select "Allow remote connections to this computer."

Why: In a real-world environment, you won't be sitting in front of the server (or the ESXi console) to manage it. RDP allows you to securely connect from your local workstation, saving time and enabling remote administration.

7. Configure Windows Firewall to Allow Pings
Action: Search for Windows Defender Firewall with Advanced Security > Inbound Rules. Enable "File and Printer Sharing (Echo Request - ICMPv4-In)" and "ICMPv6-In."

Why: Windows Firewall blocks pings by default for security. However, as an administrator, troubleshooting network connectivity starts with ping. Do not disable the firewall entirely (that's a bad habit); simply allow the specific ICMP rules required for network diagnostics.

8. Update Windows Server
Action: Go to Settings > Windows Update and install all available updates. Reboot and search again until you see "You're up to date."

Why: Servers are prime targets for exploits. Out-of-the-box installations lack critical security patches. Always update before adding production roles or applications.

9. Activate Windows Server
Action: Go to Settings > Activation and enter your product key or activate via your licensing method.

Why: Unactivated servers will eventually restart automatically (usually during the middle of the night) and lose access to certain Windows updates.

========================================================================================

Windows Server Administration (CLI Edition): Deployment & Baseline Configuration via PowerShell

In the previous chapter, we deployed Windows Server using the standard GUI (Desktop Experience).

However, as you progress in your career—especially when managing VMware and Linux environments—you realize that GUIs are for humans, but CLIs are for scale. Graphical interfaces are great for learning, but if you manage 10, 50, or 500 servers, clicking through wizards is inefficient and prone to human error.

This chapter is the PowerShell Edition. We are going to cover the exact same deployment and post-installation checklist, but we will do it entirely through the command line.

Note: For the initial OS installation (Disk partitioning, EULA, etc.), you still generally use the Windows Setup wizard on the VM console. For true zero-touch deployments, you would use an unattend.xml file. But once you log in to the server, the real work begins in PowerShell.

Here is how to automate your baseline configuration.

Post-Installation Baseline Configuration via PowerShell
Launch PowerShell as an Administrator and let's knock out the checklist.

Disable Automatic Server Manager Startup
Action:
Set-ItemProperty -Path "HKCU:\Software\Microsoft\ServerManager" -Name "DoNotOpenServerManagerAtLogon" -Value 1 -Type DWord
Why: Server Manager is a heavy GUI tool. By modifying this registry key, you prevent it from popping up every time you log in. In a CLI-driven workflow, you don't need it, and this saves valuable RAM and CPU cycles.
Turn Off IE Enhanced Security Configuration
Action:
For Administrators
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0

For Users
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0

Why: This blocks the incredibly restrictive Internet Explorer security prompts that prevent you from downloading tools or viewing internal web pages.
Set the Correct Time Zone
Action:
First, view available time zones
Get-TimeZone -ListAvailable

Set your specific time zone (example: US Eastern)
Set-TimeZone -Id "Eastern Standard Time"

Why: Kerberos authentication (Active Directory) requires server times to be within 5 minutes of each other. If time drifts, AD breaks. Setting this via CLI ensures it's done immediately upon deployment.
Change the Computer Name
Action:
Rename-Computer -NewName "IAD00-2019" -Force -Restart
Why: Default names like WIN-QJ4K... mean nothing. Naming conventions map to your infrastructure (e.g., IAD00 = Domain Controller 1). Note: A reboot is required to apply the name change, so the -Restart flag handles that automatically.
Check and Rename Network Adapters
Action:
Get the current network configuration
Get-NetIPConfiguration

Rename the adapter
Rename-NetAdapter -Name "Ethernet0" -NewName "Network-192.x.x.x"
Rename-NetAdapter -Name "Ethernet1" -NewName "Network-WAN"

Why: Servers often have multiple NICs (Management, DMZ, Storage). Renaming them via CLI forces you to be explicit about which interface you are configuring.
Configure a Static IP Address
Action:
Apply the static IP, Subnet, and Gateway
New-NetIPAddress -InterfaceAlias "Network-192.x.x.x" -IPAddress 192.x.x.x -PrefixLength 24 -DefaultGateway 192.x.x.x

Set the DNS Servers
Set-DnsClientServerAddress -InterfaceAlias "Network-192.x.x.x" -ServerAddresses ("8.8.8.8","8.8.4.4")

Why: Infrastructure servers cannot use DHCP. If a server's IP changes, DNS records break, and clients lose connection. A static IP is mandatory.
Turn on Remote Desktop (RDP)
Action:
Enable RDP in the registry
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0

Open the firewall for RDP
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

Why: In a VMware environment, connecting directly to the VM console is slow. Enabling RDP allows you to connect from your local workstation, which is much faster and more efficient.
Configure Windows Firewall to Allow Pings
Action:
Enable-NetFirewallRule -Name "FPS-ICMP4-ERQ-In","FPS-ICMP6-ERQ-In"
Why: Windows Firewall blocks ICMP (ping) by default. As a SysAdmin, ping is your first troubleshooting step. This command enables the specific firewall rules to allow ping requests (both IPv4 and IPv6) without turning off the entire firewall.
Update Windows Server
Action:
If the PSWindowsUpdate module isn't installed, install it
Install-Module -Name PSWindowsUpdate -Force -Confirm:$false

Search, install, and auto-reboot if needed
Get-WindowsUpdate -Install -AcceptAll -AutoReboot

Why: A fresh server is full of unpatched vulnerabilities. Doing this via CLI allows you to run this command across 50 servers simultaneously, whereas clicking "Check for updates" in the GUI is a manual, time-consuming nightmare.
Activate Windows Server
Action:
Input the product key
slmgr.vbs /ipk XXXXX-XXXXX-XXXXX-XXXXX-XXXXX

Activate over the internet
slmgr.vbs /ato

Why: Unactivated Windows Servers will eventually throttle performance and reboot automatically. Activating via CLI is instant and doesn't require navigating the Settings menu.
PRO-TIP: By putting these commands into a script, your workflow for a new server becomes:

Spin up the VM in VMware.

Install Windows via the ISO.

Open PowerShell and run \FileServer\Share\Initialize-Server.ps1 -IP 192.x.x.x -Name "IAD00".

Walk away and get a coffee.