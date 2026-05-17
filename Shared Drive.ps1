$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
if ((Get-ItemProperty $RegPath).EnableLinkedConnections -ne 1) {
    Set-ItemProperty -Path $RegPath -Name "EnableLinkedConnections" -Value 1 -Type DWord -Force
}
