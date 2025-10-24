# Create a new SQL Login in SQL Server and corresponding User in the specified database with schema mapping
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$db_server_name, # SQL Server instance name ex- localhost
    
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$db_name, # Target database name
    
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$db_username, # New database username to create
    
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$db_password, # Password for the new database user
    
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$schema_name, # Schema to map the user to
    
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$sa_username, # SQL Admin username with necessary permissions
    
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$sa_password  # Corresponding password
)

# Import required modules
$moduleFolder = Join-Path $PSScriptRoot 'modules'

if (-not (Test-Path $moduleFolder)) {
    Write-Error "Module folder not found: $moduleFolder"
    exit 1
}
Get-ChildItem -Path $moduleFolder -Filter '*.psm1' -File -Recurse | ForEach-Object {
    # write-Host $_.Count -ForegroundColor DarkGray
    Write-Host "Importing module: $($_.FullName)" -ForegroundColor Cyan
    Try {
        if (Test-Path $_.FullName) {
            Import-Module -Name $_.FullName -Force -ErrorAction Stop
            Write-Verbose "Imported $($_.Name)"
        } else {
            Write-Error "Module file not found: $($_.FullName)"
            throw "Module file not found: $($_.FullName)"
        }
    } Catch {
        Write-Error "Failed to import $($_.FullName): $_"
        throw  # Re-throw to stop execution
    }
}

# Create SQL Connection String
$conn = New-SqlConnectionString -ServerInstance $db_server_name -Database $db_name -Username $sa_username -Password $sa_password

# Create login in the database server
New-SqlLogin -ConnectionString $conn -LoginName $db_username -LoginPassword $db_password -ErrorAction Stop 

# Create user in the specified database and map to schema
New-SqlUserInDatabase -ConnectionString $conn -DatabaseName $db_name -LoginName $db_username -Schema $schema_name -ErrorAction Stop 

# Add Database User Roles to the new Login
Add-SqlUserToDatabaseRoles -ConnectionString $conn -DatabaseName $db_name -UserName $db_username -ErrorAction Stop

