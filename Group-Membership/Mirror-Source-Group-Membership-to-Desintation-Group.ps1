<# 

PowerShell script that will compare a source AD group with a destination AD group and add the missing users from the source to the destination group

#>

# Define source and desintation group variables to store group names
$sourceGroup = "sourceGroupName"
$destinationGroup = "desintationGroupName"

# Retrieve the users from the source group
$sourceGroup = Get-ADGroupMember -Identity $sourceGroup

# Retrieve the users from the destination group
$destinationGroup = Get-ADGroupMember -Identity $destinationGroup

# Store the users found in the source group and NOT the desintation group into variable
$newUsers = $sourceGroup.SamAccountName | Where-Object { $destinationGroup.SamAccountName -notcontains $PSItem } | Sort-Object SamAccountName

# Add missing users from Source to Destination group
foreach ($newUser in $newUsers) {
    Add-ADGroupMember -identity "DestinationGroup" -members $newUsers
} 

