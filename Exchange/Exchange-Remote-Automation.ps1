#Install and import the Exchange Online Management module
#Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber -Scope AllUsers
#Import-Module -Name ExchangeOnlineManagement

# Import only necessary modules
#Import-Module -Name Microsoft.Graph.Users -scope AllUsers
#Import-Module -Name Microsoft.Graph.Authentication

# Install Graph Beta Modules because as of May 2025, MgUser does not return the field OnPremiseSyncEnabled value
#Install-Module -Name Microsoft.Graph.Beta.Users -Scope AllUsers
#Import-Module -Name Microsoft.Graph.Beta.Users

# We will be using Get-MgBetaUser rather than Get-MgUser because the latter does not return values for all the attributes
# Get-MgBetaUser

#Connect to Microsoft Graph
$ClientID = 'xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx'
$TenantID = 'xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx'
$CertificateThumbprint = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
Connect-MgGraph -ClientID $ClientID -TenantId $TenantID -CertificateThumbprint $CertificateThumbprint

# Check Mg Context
# Get-MgContext

# Interactive Login Used for testing 
# Connect-MgGraph -TenantId $TenantID -Scopes 'Directory.Read.All','Directory.ReadWrite.All','User.Read.All','User.ReadWrite.All'

#Connect to Exchange Online
$Domain = 'contoso.mail.onmicrosoft.com' # Specify Exchange Online domain
Connect-ExchangeOnline -AppID $ClientID -Organization $Domain -CertificateThumbprint $CertificateThumbprint

# Get all Exchange Online mailboxes
$EXOMailboxes = Get-ExoMailbox -ResultSize Unlimited | Select-Object -ExpandProperty UserPrincipalName

# Get all cloud (Azure AD) users 
$CloudUsers = Get-MgBetaUser -All | Where-Object { $_.OnPremisesSyncEnabled -ne $true } | Select-Object -ExpandProperty UserPrincipalName

# Filter out the cloud users from the Exchange Online Mailboxes
$onlineUsers = $EXOMailboxes | Where-Object { $_ -notin $CloudUsers }

#Connect to local Exchange Server
$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://onpremexchange.contoso.com/PowerShell/ # Specify the on-premise Exchange PowerShell URi
Import-PSSession $session

#Get all users having a remote mailbox on the on-premise Exchange server
$onPremUsers = Get-RemoteMailbox -ResultSize Unlimited | Select-Object -ExpandProperty PrimarySmtpAddress

#Get the Online Users who do not have a remote mailbox on the on-premise Exchange server
$usersToEnable = $onlineUsers | Where-Object {$_ -notin $onPremUsers}

#Path for log file with date time stamped
$logPath = "C:\scripts\logs\" + "Log_" + (Get-Date -Format "dd-MM-yyyy_HH-mm") + ".log"

#Enable the users who do not have a remote mailbox on the on-premise Exchange server
foreach($user in $usersToEnable){
    try {
        $userMailbox = Get-Mailbox -Identity $user -ErrorAction Stop
        Enable-RemoteMailbox -Identity $user -RemoteRoutingAddress ($userMailbox.Alias + "@contoso.mail.onmicrosoft.com") -ErrorAction Stop # Specify Exchange Online domain
        Set-RemoteMailbox -Identity $user -ExchangeGuid $userMailbox.ExchangeGuid -ErrorAction Stop

        #Log success to the log file
        Add-Content -Path $logPath -Value ("User: " + $user + " was enabled for remote mailbox at " + (Get-Date -Format "dd-MM-yyyy HH:mm:ss"))
    }
    catch {
        #Output error to the console
        Write-Host ("Error processing user: " + $user + ". Error Details: " + $_.Exception.Message)
        Write-Host ""

        #Log error to the log file
        Add-Content -Path $logPath -Value ("Error processing user: " + $user + ". Error Details: " + $_.Exception.Message)
    }
}

#Clean up the session
Remove-PSSession $session
