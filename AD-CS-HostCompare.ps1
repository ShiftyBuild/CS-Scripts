 clear
# Define the paths to the two input files
$ADComputers = "C:\Temp\AD-Computers.txt"
$FalconHosts = "C:\Temp\Falcon-Hosts.txt"
$Missinghosts = "C:\Temp\Missing.txt"
$CSCloud = "https://api.crowdstrike.com"

#Cleanup any old files
Remove-Item $ADComputers
Remove-Item $FalconHosts
Remove-Item $Missinghosts
Remove-Item C:\Temp\Missing-Detailed.txt

clear


# Check if PS-Falcon module is installed
if (-not (Get-Module -Name PSFalcon -ListAvailable)) {
    # Prompt user to install the module
    $installModule = Read-Host "The PSFalcon module is not installed. Do you want to install it? (Y/N)"
    if ($installModule -eq "Y") {
        Install-Module -Name PSFalcon -RequiredVersion 2.2
    }
    else {
        Write-Host "PSFalcon module installation cancelled. Exiting script."
        Exit
    }
}


#Check for API Token
echo "Am I authenticated to the Falcon API?"
$Token = (Test-FalconToken).Token
echo $Token


#If no token prompt for creds and authenticate
if ($Token -eq $false) {
echo "You are not authenticated to the Crowdstrike API"
echo "Please enter your API Creds"
echo "Connecting to $CSCloud"

# Prompt user for API Key and API Secret
$apiKey = Read-Host "Enter your API Key"
$apiSecret = Read-Host "Enter your API Secret" 


# Authenticate to the API
#echo $apiKey
#echo $apiSecret

Request-FalconToken -ClientId $apiKey -ClientSecret $apiSecret -Hostname $CSCloud

# Test the API connection
Test-FalconToken -Verbose
$Token = (Test-FalconToken).Token

}

#echo $Token
echo "You are authenticated"


# Retrieve all computer objects from Active Directory
$computers = Get-ADComputer -Filter *

# Write the list of computers to the output file
$computers.Name | Out-File -FilePath $ADComputers -Encoding ASCII

# Display a confirmation message
Write-Host "The list of computers from AD has been saved to $ADComputers."

Get-FalconHost -Filter "platform_name:'Windows'" -Detailed -All | Select-Object -ExpandProperty hostname | Out-File -FilePath $FalconHosts

Write-Host "The list of computers from falcon has been saved to $FalconHosts."



# Read the contents of both files into arrays
$firstHosts = Get-Content $ADComputers
$secondHosts = Get-Content $FalconHosts

#Write-Host "*****************AD Hosts*****************"
#echo $firstHosts
#Write-Host "*****************Falcon Hosts*****************"
#echo $secondHOsts

pause
Write-Host "*************Comparing the lists of host names.*****************"

# Use the Compare-Object cmdlet to compare the two arrays and find the differences
$diff = Compare-Object $firstHosts $secondHosts -IncludeEqual -PassThru

# Output the differences, which are the hostnames that are present in the first file but missing from the second file
$diff | Where-Object { $_ -notin $secondHosts } | Out-File -FilePath $Missinghosts


# Read the contents of the file into an array
$Missinghost = Get-Content $Missinghosts

# Loop through each host system name in the array and query Active Directory for its details
foreach ($hosts in $MissingHost) {
    Get-ADComputer $hosts -Properties DNSHostName,IPv4Address,LastLogonDate,OperatingSystem,OperatingSystemVersion,WhenCreated,LastLogonDate  | Out-File -FilePath "C:\Temp\Missing-Detailed.txt" -Append
}
Write-Host "A detailed list of hosts missing the Falcon Sensor can be found in C:\Temp\"
Remove-Item $ADComputers
Remove-Item $FalconHosts
pause


$response = Read-Host "Do you want to log out of the API? (y/n)"
if ($response -eq "y") {
    echo "Auth Token being removed"
    Revoke-FalconToken
    Test-FalconToken
} else {
    Write-Host "Falcon API will stay logged in."
    Test-FalconToken
    exit
}
 
