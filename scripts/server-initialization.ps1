<#
.SYNOPSIS
    Baseline Configuration for Windows Server
.DESCRIPTION
    Automates post-installation tasks for a new Windows Server VM.
.PARAMETER ComputerName
    The new name for the server (e.g., IAD00)
.PARAMETER IPAddress
    The static IP address
.PARAMETER PrefixLength
    The subnet mask prefix (e.g., 24 for 255.255.255.0)
.PARAMETER Gateway
    The default gateway
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ComputerName,

    [Parameter(Mandatory=$true)]
    [string]$IPAddress,

    [Parameter(Mandatory=$true)]
    [int]$PrefixLength,

    [Parameter(Mandatory=$true)]
    [string]$Gateway
)

Write-Host "Starting Baseline Configuration..." -ForegroundColor Cyan

# 1. Disable Server Manager Auto-Start
Set-ItemProperty -Path "HKCU:\Software\Microsoft\ServerManager" -Name "DoNotOpenServerManagerAtLogon" -Value 1 -Type DWord
Write-Host "[-] Disabled Server Manager Auto-Start" -ForegroundColor Green

# 2. Disable IE Enhanced Security
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0
Write-Host "[-] Disabled IE Enhanced Security Configuration" -ForegroundColor Green

# 3. Set Time Zone (Change as needed)
Set-TimeZone -Id "Eastern Standard Time"
Write-Host "[-] Time Zone set to Eastern Standard Time" -ForegroundColor Green

# 4. Configure Static IP
$Adapter = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1
Rename-NetAdapter -Name $Adapter.Name -NewName "Network-Primary" -ErrorAction SilentlyContinue
New-NetIPAddress -InterfaceAlias "Network-Primary" -IPAddress $IPAddress -PrefixLength $PrefixLength -DefaultGateway $Gateway -ErrorAction SilentlyContinue
Set-DnsClientServerAddress -InterfaceAlias "Network-Primary" -ServerAddresses ("8.8.8.8","8.8.4.4")
Write-Host "[-] Configured Static IP: $IPAddress" -ForegroundColor Green

# 5. Enable Remote Desktop
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Write-Host "[-] Enabled Remote Desktop" -ForegroundColor Green

# 6. Allow Pings (ICMP)
Enable-NetFirewallRule -Name "FPS-ICMP4-ERQ-In","FPS-ICMP6-ERQ-In"
Write-Host "[-] Enabled Firewall ICMP rules" -ForegroundColor Green

# 7. Rename Computer (Requires Reboot)
Write-Host "Renaming computer to $ComputerName..." -ForegroundColor Yellow
Rename-Computer -NewName $ComputerName -Force
Write-Host "[-] Computer rename staged. A reboot is required." -ForegroundColor Green

Write-Host "Baseline Configuration Complete!" -ForegroundColor Cyan
Write-Host "Please run 'Restart-Computer' to finalize changes." -ForegroundColor Yellow