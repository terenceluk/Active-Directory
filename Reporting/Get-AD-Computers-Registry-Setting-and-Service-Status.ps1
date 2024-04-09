<#

The purpose of this PowerShell Script is to retrieve the service status (running, stopped, etc) and the value of a registry key for the service then export the data to a CSV.

The CSV will contain the following columns in sequence:
A. Computer name 
B. Operating System
C. The full path of the registry key
D. Registry Value Name
E. Whether the registry was reacable
F. The value of the registry key
G. The status of the service (running, stopped, etc) 
H: The service start type
I: Repeat the above with next registry

This example uses Carbon Black's 2 services as an example and can be expanded by adding to the hash table.

#>

# Function that will extract the last portal of a string after a '\'
function ExtractLastPortion {
    param(
        [string]$str
    )

    $splitString = $str.Split('\', [System.StringSplitOptions]::RemoveEmptyEntries)
    return $splitString[-1]
}

# Import the Active Directory module
Import-Module ActiveDirectory

# Specify the registry keys and values
$RegistryKeys = @{
    'SYSTEM\CurrentControlSet\Services\CbDefense'    = 'Start';
    'SYSTEM\CurrentControlSet\Services\CbDefenseWSC' = 'Start';
}

# Get all computers in the Active Directory domain
$OUDN = "OU=Servers,DC=contoso,DC=com" # Full path of the OU
$ADComputers = Get-ADComputer -Filter * -SearchBase $OUDN | Select-Object -ExpandProperty Name

# Initialize an empty array to store results
$results = @()

# For each computer
foreach ($Computer in $ADComputers) {

    # Get computer operating system
    $operatingSystem = (Get-ADcomputer -Identity $Computer -properties operatingsystem | Select-object operatingsystem).operatingsystem

    # Start with an object that represents the computer
    $computerObject = New-Object PSObject -Property @{
        'Operating System' = $operatingSystem
        'Computer'         = $Computer
    }

    # For each registry key
    foreach ($RegistryKey in $RegistryKeys.Keys) {

        # Extract the Registry Key name that also serves as the service name in the services console
        $targetKey = ExtractLastPortion $RegistryKey

        try {
            # Get the service status (is it running, stopped, etc), do not display error message on console if server is not reachable
            $ServiceStatus = ((Get-Service -ComputerName $Computer -Name $targetKey -ErrorAction SilentlyContinue).Status).toString()

        }
        # Catch exception when Get-Service cannot reach server to obtain details
        catch {
            # If Get-Service fails then label service status as "Unreachable"
            $ServiceStatus = "Unreachable"
        }

        # Try to read the registry keys
        try {
            $Key = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer)
            $SubKey = $key.OpenSubKey($RegistryKey)
            $Value = $SubKey.GetValue($RegistryKeys[$RegistryKey])

            # Determine service startup type
            switch ($Value) {
                2 { $startupType = "Automatic" }
                3 { $startupType = "Manual" }
                4 { $startupType = "Disabled" }
                default { $startupType = "Unknown" }
            }

            # Add the registry values to the computer object
            $computerObject | Add-Member -NotePropertyName "${targetKey} Key" -NotePropertyValue $RegistryKey
            $computerObject | Add-Member -NotePropertyName "${targetKey} Registry Value Name" -NotePropertyValue $RegistryKeys[$RegistryKey]
            $computerObject | Add-Member -NotePropertyName "${targetKey} Reachability" -NotePropertyValue 'Reachable'
            $computerObject | Add-Member -NotePropertyName "${targetKey} Value" -NotePropertyValue $Value
            $computerObject | Add-Member -NotePropertyName "${targetKey} Service Status" -NotePropertyValue $serviceStatus
            $computerObject | Add-Member -NotePropertyName "${targetKey} Start" -NotePropertyValue $startupType
        
            $Key.Close()
            $SubKey.Close()
        }

        # Catch exception when registry cannot be read
        catch {
            $computerObject | Add-Member -NotePropertyName "${targetKey} Key" -NotePropertyValue $RegistryKey
            $computerObject | Add-Member -NotePropertyName "${targetKey} Registry Value Name" -NotePropertyValue $RegistryKeys[$RegistryKey]
            $computerObject | Add-Member -NotePropertyName "${targetKey} Reachability" -NotePropertyValue 'Unreachable'
            $computerObject | Add-Member -NotePropertyName "${targetKey} Value" -NotePropertyValue "Unreachable"
            $computerObject | Add-Member -NotePropertyName "${targetKey} Service Status" -NotePropertyValue $serviceStatus
            $computerObject | Add-Member -NotePropertyName "${targetKey} Start" -NotePropertyValue "Unknown"
            Write-Warning "Unable to connect to $Computer or read the registry key $RegistryKey"
        }
    }

    # Add the computer object to the results array
    $results += $computerObject
}

$results | Export-Csv -Path Server-CB-Registry-Results.csv -NoTypeInformation
