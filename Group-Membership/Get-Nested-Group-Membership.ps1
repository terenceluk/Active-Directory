<#

This script receives a AD Group name as an input and will retrieve all of the users in the group and nested groups, returning unique values and excludes the groups.

#>

function Get-AllADGroupMembers {
    param (
        [Parameter(Mandatory = $true)]
        $GroupName
    )

    # Place results into an array to catch scenario where there is only one member
    $groupMembers = @(Get-ADGroupMember -Identity $GroupName)

    foreach ($member in $groupMembers) {
        if ($member.objectClass -eq "group") {
            # Use the Get-allADGroupMembers function to recursively get any nested group objects
            $nestedGroupMembers = Get-AllADGroupMembers $member.name
            $groupMembers += $nestedGroupMembers
        }
    }

    # Use Where-Object to only select users and Sort-Object to remove duplicate users
    return ($groupMembers | Where-Object { $_.objectClass -eq "user" } | Sort-Object -Unique)
}

$group = "All Staff"
$results = Get-AllADGroupMembers $group 
