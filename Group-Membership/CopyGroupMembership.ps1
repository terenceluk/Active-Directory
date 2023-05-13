<# 

This PowerShell script accepts a source user and a target user's samAccountName to copy the source user
group membership over to the target user.

#>

# The accepted mandatory parameters for the source and target user
Param
    (
        [Parameter(Mandatory=$true)]
        [string] $sourceUser,

        [Parameter(Mandatory=$true)]
        [string] $targetUser
    )

# Function that copies the group membership of the source user into a variable, then assigns it to the target user
function CopyGroupMembership {
    Param
    (
        [Parameter(Mandatory=$true)]
        [string] $source,

        [Parameter(Mandatory=$true)]
        [string] $target
    )
    
    # Get group membership from source user
    $getusergroups = Get-ADUser -Identity $source -Properties memberof | Select-Object -ExpandProperty memberof

    # Set group membership for target user
    $getusergroups | Add-ADGroupMember -Members $target -verbose

}

# Execute the function with the passed parameters
CopyGroupMemberShip $sourceUser $targetUser
