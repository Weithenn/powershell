# ==================================================================
# Author:       Weithenn Wang (weithenn at weithenn.org)
# Version:      v1.0 - June 17, 2021
# Description:  Check RDS farms sessions and resources
# ==================================================================

# Import module
Import-Module ".\modules\RDSResources.psm1"



# Bastion Servers and collections
$RDCB = 'rdcb.rds.weithenn.org'
$RDWeb = 'rdweb.rds.weithenn.org'
$RDSH_Prefix = 'rdsh'
$RDSH_Hosts = '50'
$SSD_Collection = "SSD_Team"
$MNAND_Collection = "MNAND_Team"
$COMMON_Collection = "Other_Team"



# Check RDSH farm users session and creating custom object
$TotalSessions = (Get-RDUserSession -ConnectionBroker $RDCB | measure).Count
$SSD_Sessions = (Get-RDUserSession -ConnectionBroker $RDCB -CollectionName $SSD_Collection | measure).Count
$MNAND_Sessions = (Get-RDUserSession -ConnectionBroker $RDCB -CollectionName $MNAND_Collection | measure).Count
$COMMON_Sessions = (Get-RDUserSession -ConnectionBroker $RDCB -CollectionName $COMMON_Collection | measure).Count

$RDS_Sessions = New-Object PSObject -Property ([ordered]@{
   "SSD Sessions"    = $SSD_Sessions
   "mNAND Sessions"  = $MNAND_Sessions
   "Common Sessions" = $COMMON_Sessions
   "Total Sessions"  = $TotalSessions
})



# Check RDCB, RDWeb, and RDSH resources
$RDS_Resources = @(
    Invoke-Command -ScriptBlock ${Function:Get-RDSResources} -ComputerName $RDCB, $RDWeb    
    1..$RDSH_Hosts | % {
        $i = "{0:d2}" -f $_
        Invoke-Command -ScriptBlock ${Function:Get-RDSResources} -ComputerName "$RDSH_Prefix$($i)"
    }
)



# Show RDS farms resources
$Title = "<h1>Shanghai Lab Bastion Resources</h1>"
$RDS_Farms1 = $RDS_Sessions | ConvertTo-Html -Property "SSD Sessions", "mNAND Sessions", "Common Sessions", "Total Sessions" -Fragment -PreContent "<h2>Users Session Information</h2>"
$RDS_Farms2 = $RDS_Resources | ConvertTo-Html -Property "Server Name", "CPU Usage %", "Memory Usage %", "Free Disk Size (GB)" -Fragment -PreContent "<h2>System Performance Information</h2>"



# The command below will combine all the information gathered into a single HTML report
$Report = ConvertTo-HTML -Body "$Title $RDS_Farms1 $RDS_Farms2" -Title "Weithenn RDS Farms Resources" -PostContent "<p>Creation Date: $(Get-Date)</p>" -CssUri ".\css\style.css"



# The command below will generate the report to an HTML file
$Report | Out-File -FilePath C:\Windows\Web\RDWeb\HtmlReport\RDSResource.html
