# Retrieve all users recursively with a supplied search base
$Users = Get-ADUser -filter * -SearchBase 'DC=contoso,DC=local' -Properties manager

# Create an array to store results
$results = @()

# Loop through all users and store users who have a manager into a array
ForEach ($User In $Users)
{
    # Retrieve properties of the manager of each user if the manager property is not null
    if ($null -ne $User.manager){
        $manager = Get-ADUser $User.manager | Select-Object Name, GivenName, Surname, sAMAccountName

        # Store results into array
        $results += [PSCustomObject]@{
            "ManagerFullName" = $manager.Name
            "ManagerFirstName" = $manager.GivenName
            "ManagerLastName" = $manager.Surname
            "ManagerSamAccountName" = $manager.sAMAccountName
            "UserFullName" = $user.Name
            "UserFirstName" = $user.GivenName
            "UserLastName" = $user.Surname
            "UserSamAccountName" = $user.sAMAccountName
        }
    }
}

# Export array to CSV
$Results | Export-Csv -Path C:\Scripts\Manager-Exports.csv -NoTypeInformation
