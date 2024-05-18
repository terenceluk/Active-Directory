<#

This script will use the exported spreadsheet containing the First Name, Last Name, ProxyAddress with SMTP (primary email address),
and the O365 coexistence email address ending <domain>.mail.onmicrosoft.com to create the smtp:<domain>.mail.onmicrosoft.com proxyAddress for the users.

#>

# Import the Active Directory and Excel modules
Import-Module ActiveDirectory
Import-Module ImportExcel

# Set the path to Excel file
$filePath = 'AD_Users_Import.xlsx'

# Read the data from the Excel file
$data = Import-Excel -Path $filePath

# Walk through every row in the Excel file
foreach ($row in $data) {
    try {
        $user = Get-ADUser -Filter "EmailAddress -eq '$($row.'Primary Email Address')'"
        
        if($user -eq $null) {
            Write-Output "User with email address $($row.'Primary Email Address') not found in AD"
            continue
        }

        $newAddress = "smtp:" + $row.'O365 Coexistence Email Address'

        # Set the new ProxyAddresses that discards the output
        Set-ADUser $($user.SamAccountName) -Add @{ProxyAddresses = $newAddress} | Out-Null 

        Write-Output "Successfully added new address $newAddress to user $($user.SamAccountName)"
        
    } catch {
        Write-Output "Failed to add new address $newAddress to user $($user.SamAccountName): $_"
    }
}
