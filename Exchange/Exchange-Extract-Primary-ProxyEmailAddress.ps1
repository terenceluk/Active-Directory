<#

This script will use the Get-ADUser cmdlet to export the First Name, Last Name, and ProxyAddress with SMTP (primary email address),
then add an extra field for the O365 coexistence email address ending <domain>.mail.onmicrosoft.com, and export it to an XLSX for review.

Use the import script to use the reviewed spreadsheet to create the smtp:<domain>.mail.onmicrosoft.com proxyAddress for the users.

#>

# Import the Active Directory and Excel modules
Import-Module ActiveDirectory
Install-Module ImportExcel -Force -AllowClobber

# Create an empty array to hold user info
$userInfoArray = @()

# Get all AD Users
$users = Get-ADUser -Filter * -Property GivenName, SurName, ProxyAddresses

foreach ($user in $users) {
    # Check if ProxyAddresses is not null and contains at least one address matching "SMTP:*"
    if ($user.ProxyAddresses -ne $null -and ($user.ProxyAddresses | Where-Object { $_.StartsWith("SMTP:") }).Count -gt 0) {
        
        # Extract the primary email address
        $primaryAddress = ($user.ProxyAddresses | Where-Object { $_.StartsWith("SMTP:") })
        
        # Extract the string after "SMTP:" before the @
        $emailPrefix = $primaryAddress -replace '^SMTP:(.*)@.*', '$1'

        # Extract the string after "SMTP:" 
        $primaryAddressWithoutSMTP = $primaryAddress -replace '^SMTP:(.*)', '$1'

        # Concat the string before the @ with the new domain
        $newAddress = $emailPrefix + "@contoso.mail.onmicrosoft.com"

        # Create a custom PowerShell object

        $userInfo = New-Object PSObject -Property ([ordered]@{
        'First Name'                       = $user.GivenName
        'Last Name'                        = $user.SurName
        'Primary Email Address'            = $primaryAddressWithoutSMTP
        'O365 Coexistence Email Address'   = $newAddress
        })

        # Add the user object into array
        $userInfoArray += $userInfo
    }
}

# Output the array to Excel xlsx file
$userInfoArray | Export-Excel -Path AD_Users_Export.xlsx -AutoSize
