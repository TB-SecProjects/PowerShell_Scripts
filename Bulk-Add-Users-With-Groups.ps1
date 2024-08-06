# Import the Active Directory module
Import-Module ActiveDirectory

# Store the data from ADUsers.csv in the $ADUsers variable. Change this to your file.
$ADUsers = Import-Csv C:\temp\12345_Bulk_Add_Accounts.csv

# Loop through each row containing user details in the CSV file
foreach ($User in $ADUsers) {
    # Read user data from each field in each row and assign the data to a variable as below
    $Username        = $User.username
    $Password        = $User.password
    $Firstname       = $User.firstname
    $Lastname        = $User.lastname
    $OU              = $User.ou # This field refers to the OU the user account is to be created in
    $domain          = $User.domain
    $email           = $User.email
    $streetaddress   = $User.streetaddress
    $city            = $User.city
    $zipcode         = $User.zipcode
    $state           = $User.state
    $country         = $User.country
    $telephone       = $User.telephone
    $jobtitle        = $User.jobtitle
    $company         = $User.company
    $department      = $User.department

    # Check to see if the user already exists in AD
    if (Get-ADUser -Filter {SamAccountName -eq $Username}) {
        # If user does exist, give a warning
        Write-Warning "A user account with username $Username already exists in Active Directory."
    } else {
        # User does not exist, proceed to create the new user account
        # Account will be created in the OU provided by the $OU variable read from the CSV file
        New-ADUser `
            -SamAccountName $Username `
            -UserPrincipalName "$Username@$domain" `
            -Name "$Firstname $Lastname" `
            -GivenName $Firstname `
            -Surname $Lastname `
            -Enabled $True `
            -DisplayName "$Firstname $Lastname" `
            -Description "$Username" `
            -Path $OU `
            -City $city `
            -Company $company `
            -State $state `
            -StreetAddress $streetaddress `
            -OfficePhone $telephone `
            -EmailAddress $email `
            -Title $jobtitle `
            -Department $department `
            -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) -ChangePasswordAtLogon $False

        # Import the groups from the CSV file. Change this to your file.
        $Group = Import-Csv C:\temp\EXAMPLE_GROUPS.csv
        foreach ($row in $Group) {
            # Retrieve the group name from the row
            $groupName = $row.GroupName
            Write-Host "Adding $Username to $groupName"
            Add-ADGroupMember -Identity $groupName -Members $Username
        }
    }
}
