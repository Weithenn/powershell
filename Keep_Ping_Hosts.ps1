# ==================================================================
# Author:       Weithenn Wang (weithenn at weithenn.org)
# Version:      v0.1 - Auguest 10, 2021
# Description:  Keep ping connectivity by hosts list
# ==================================================================

# Get hosts list
$Today = Get-Date -Format "yyyyMMdd"
$Ping_hosts = Get-Content -Path C:\PowerCLI\Ping_hosts.txt
$Number_of_hosts = (Get-Content -Path C:\PowerCLI\Ping_hosts.txt).Count
$Ping_interval = 60



# Keep the ping host to rest for 60 seconds
while ($true){
   Write-Host "===== $(Get-Date) - Starting to ping $Number_of_hosts hosts =====" -ForegroundColor Magenta

   # Ping all hosts, but ignore error hosts
   Test-Connection -ComputerName $Ping_hosts -Count 1 -ErrorAction SilentlyContinue| Format-Table -AutoSize
   
   # Write the failed hosts to the log
   foreach ($Hosts in $Ping_hosts){
       If (Test-Connection -ComputerName $Hosts -Count 1 -Quiet){
       } else {
           Write-Host "$Hosts - ping and hostname resolution failed!" -ForegroundColor Red
           "$(Get-Date) - $Hosts" | Out-File -FilePath C:\PowerCLI\"$Today"_ping_failed_hosts.txt -Append
       }
   }
   Write-Host ""
   Write-Host "===== Resume ping after $Ping_interval seconds =====" -ForegroundColor Yellow
   Start-Sleep -s $Ping_interval;
   Clear-Host;
}