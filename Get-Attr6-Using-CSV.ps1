# Import the Active Directory module
Import-Module ActiveDirectory

# Define the path to the CSV file containing email addresses. Change this path to where your file is.
$csvFilePath = "C:\Temp\12345_Accounts.csv"

$domainServer = "test.companyname.com"

# Import the CSV file
Import-Csv -Path $csvFilePath -Delimiter "," | ForEach-Object {
    $email = $_.email.Trim()  # Trim to remove leading/trailing spaces

    # Get-ADUser filter using -eq is case-sensitive
    $adUser = Get-ADUser -Filter "EmailAddress -eq '$email'" -Server $domainServer -Properties Name, extensionattribute6

    if ($adUser) {
        # Display output if user is found
        [PSCustomObject]@{
            Name = $adUser.Name
            ExtensionAttribute6 = $adUser.ExtensionAttribute6
        }
    } else {
        Write-Host "User not found for email address: $email"
    }
} | Format-Table -AutoSize
