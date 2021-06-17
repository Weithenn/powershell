# ==================================================================
# Author:       Weithenn Wang (weithenn at weithenn.org)
# Version:      v1.0 - June 17, 2021
# Description:  Check RDS farms sessions and resources
# ==================================================================

function Get-RDSResources{  
    param(  
    $computername = $env:computername 
    )  
    # Processor utilization
    $Processor = (Get-WmiObject -ComputerName $computername -Class win32_processor -ErrorAction Stop | Measure-Object -Property LoadPercentage -Average | Select-Object Average).Average
               
    # Memory utilization 
    $ComputerMemory = Get-WmiObject -ComputerName $computername  -Class win32_operatingsystem -ErrorAction Stop 
    $Memory = ((($ComputerMemory.TotalVisibleMemorySize - $ComputerMemory.FreePhysicalMemory)*100)/ $ComputerMemory.TotalVisibleMemorySize) 
    $RoundMemory = [math]::Round($Memory, 2) 
    
    # Free disk space 
    $disks = get-wmiobject -class "Win32_LogicalDisk" -namespace "root\CIMV2" -computername $computername
    $results = foreach ($disk in $disks) {
       if ($disk.Size -gt 0) { 
          $size = [math]::round($disk.Size/1GB, 0) 
          $free = [math]::round($disk.FreeSpace/1GB, 0) 
          [PSCustomObject]@{ 
             Drive = $disk.Name 
             Name = $disk.VolumeName 
             "Total Disk Size" = $size
             "Free Disk Size" = "{0:N0} ({1:P0})" -f $free, ($free/$size) 
          }
       }
    } 

    # Creating custom object           
    $Object = New-Object PSObject -Property ([ordered]@{
        "Server Name"          = $computername
        "CPU Usage %"          = $Processor
        "Memory Usage %"       = $RoundMemory
        "Free Disk Size (GB)"  = $free
    })
    
    # Show result
    $Object
}