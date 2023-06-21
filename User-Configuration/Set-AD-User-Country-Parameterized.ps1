<# 

Sets user country attributes in AD

Country and countrycode attributes in AD
https://learn.microsoft.com/en-us/answers/questions/58906/country-and-countrycode-attributes-in-ad
https://www.iso.org/obp/ui/#search

#>

param(
     [Parameter(Mandatory=$true)]
     [string]$Country,

     [Parameter(Mandatory=$true)]
     [string]$samAccountName
)

$passedCountry = $Country
$c = $null
$numeric = $null

# Accepted Countries are Canada, United Kingdom, Bermuda, United States, Korea, Australia, Costa Rica
try {
    if ($passedCountry -eq "Canada")
    {
        $c = "CA"
        $numeric = "124"
    } elseif ($passedCountry -eq "United Kingdom")
    {
        $c = "GB"
        $numeric = "826"
    } elseif ($passedCountry -eq "Bermuda")
    {
        $c = "BM"
        $numeric = "060"
    } elseif ($passedCountry -eq "United States")
    {
        $c = "US"
        $numeric = "840"
    } elseif ($passedCountry -eq "Korea")
    {
        $c = "KR"
        $numeric = "410"
    } elseif ($passedCountry -eq "Australia")
    {
        $c = "AU"
        $numeric = "036"
    } elseif ($passedCountry -eq "Costa Rica")
    {
        $c = "CR"
        $numeric = "188"
    } else
    {
        Write-Host "Country not accepted, exiting."
        Exit
    }
}
Catch {
    Write-Host "Error occurred"
}

Set-ADuser -identity $samAccountName -Replace @{c=$c;co=$passedCountry;countrycode=$numeric}

<#

### Output Test ###

Write-Host "-----------------------------------"
Write-Host "SamAccountName:" $samAccountName
Write-Host "Passed Country:" $passedCountry
Write-Host "c:" $c
Write-Host "numeric:" $numeric
#>
