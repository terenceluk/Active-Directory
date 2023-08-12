# Install all prerequisite modules
Install-Module -Name ImportExcel -Force
Import-Module ImportExcel
Import-Module ActiveDirectory

# Read the route tables in Excel spreadsheet
$excelFilePath = "C:\Users\tluk\downloads\ADGroups-To-Create.xlsx"
$worksheetName = "groups" # Worksheet name
$adGroups = Import-Excel -Path $excelFilePath -WorksheetName $worksheetName

# Loop through the Excel
foreach ($adGroup in $adGroups) {

    $groupProps = @{

      Name          = $adGroup.name
      Path          = $adGroup.path # OU distinguishedName attribute
      GroupScope    = $adGroup.scope # DomainLocal, Global, Universal
      GroupCategory = $adGroup.category # Distribution, Security
      Description   = $adGroup.description

      } 
    
    # New-ADGroup - https://learn.microsoft.com/en-us/powershell/module/activedirectory/new-adgroup?view=windowsserver2022-ps
    New-ADGroup @groupProps
    
} 
