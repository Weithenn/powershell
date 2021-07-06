# ==================================================================
# Author:       Weithenn Wang (weithenn at weithenn.org)
# Version:      v0.1 - July 6, 2021
# Description:  Test ping connectivity by hosts list
# ==================================================================

# Get hosts list
$Ping_hosts = Get-Content -Path C:\PowerShell\Ping_hosts.txt



# Verify the number of hosts
(Get-Content -Path C:\PowerShell\Ping_hosts.txt).Count



# Test ping connectivity by hosts list
foreach ($Hosts in $Ping_hosts){
    If (Get-ADComputer -Filter {Name -eq $Hosts}){
        Write-Host "$Hosts - host exists try to ping!" -ForegroundColor Green
        # For PingReplyDetails (RTT) label and value
        $RTT = @{Label = "PingReplyDetails (RTT)"; Expression = {$_.PingReplyDetails.RoundTripTime.ToString() + " ms"}; align="right"}
        Test-NetConnection -ComputerName $Hosts | Format-Table ComputerName, RemoteAddress, PingSucceeded, $RTT -AutoSize
    } else {
        Write-Host "$Hosts - name resolution failed!" -ForegroundColor Red
    }
}