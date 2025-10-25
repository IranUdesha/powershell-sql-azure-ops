# restore sql database from azure blob storage
param (
    [Parameter(Mandatory=$true)]
    [string]$SqlUsername, # SA username or SQL Auth user with necessary permissions
    
    [Parameter(Mandatory=$true)]
    [string]$SqlPassword, # Corresponding password
    
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountKey,
    
    [Parameter(Mandatory=$true)]
    [string]$ContainerName,

    [Parameter(Mandatory=$true)]
    [string]$blobName, # name of the backup file in the blob storage ex- PHR_PH_test_01/PHR_PH_test_01_2025_10_20_09_48_55.bak

    [Parameter(Mandatory=$true)]
    [string]$source_DatabaseName, # Name of the source database from which the backup was taken

    [Parameter(Mandatory=$true)]
    [string]$db_server, # SQL Server instance name ex- localhost

    [Parameter(Mandatory=$true)] 
    [string]$restore_DatabaseName, # Name of the database to be restored
    
    [Parameter(Mandatory=$true)]
    [string]$data_file_path, # Path to store data file ex- F:\SQLData

    [Parameter(Mandatory=$true)]
    [string]$log_file_path  # Path to store log file ex- F:\SQLLogs
)

# Import required modules
Import-Module SqlServer -ErrorAction Stop
Import-Module Az.Storage -ErrorAction SilentlyContinue

# Import custom SQL module
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

Write-Host "Starting restore process for database: $restore_DatabaseName"
Write-AzureDevOpsLog -Message "Starting restore process for database: $restore_DatabaseName" -LogType "Section" 

# Create SQL Credential name
$credentialName = "Az_stg_$StorageAccountName"

# Storage URL
$stg_url = "https://$StorageAccountName.blob.core.windows.net/$ContainerName"

# Create connection
$conn = New-SqlConnectionString -ServerInstance $db_server -Username $SqlUsername -Password $SqlPassword

# Test connection
if (Test-SqlConnection -ConnectionString $conn) {
    Write-Host "Connection successful"
}else{
    Write-Error "Connection failed. Please check the server name and credentials."
    Write-Host "##vso[task.complete result=Failed;]Connection to SQL Server failed"
    exit 1
}

# Create credential in SQL Server for Azure Storage
New-SqlCredential -ConnectionString $conn -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey -CredentialName $credentialName


# Check if the database already exists

$db_status = Test-DatabaseExists -ConnectionString $conn -DatabaseName $restore_DatabaseName
if ($db_status -eq $true) {
    Write-Error "Database '$restore_DatabaseName' already exists on the $db_server server. Restore aborted."
    Write-AzureDevOpsLog -LogType "Error" -Message "Database '$restore_DatabaseName' already exists on the $db_server server. Restore aborted."
    exit 1
} else {
    Write-Host "Database '$restore_DatabaseName' does not exist on the $db_server server. Proceeding with restore..." -ForegroundColor Green
    Write-AzureDevOpsLog -LogType "Section" -Message "Database does not exist on the $db_server server. Proceeding with restore..."
    Write-Host " "
}


# Get logical file names
$backupUrl = "$stg_url/$source_DatabaseName/$blobName"

# Check if the .bak extension is already present
if ($blobName -notlike "*.bak") {
    $backupUrl = "$stg_url/$source_DatabaseName/$blobName.bak"
} else {
    $backupUrl = "$stg_url/$source_DatabaseName/$blobName"
}

Write-Host "Fetching logical file names from backup: $backupUrl" -ForegroundColor Yellow
# Write-Host "##[section]Fetching logical file names from backup"
try {
    # $fileList = Invoke-Sqlcmd -ConnectionString $connectionString -Query "RESTORE FILELISTONLY FROM URL = '$backupUrl' WITH CREDENTIAL = '$credentialName'" -ErrorAction Stop
    $fileList = Invoke-SqlQuery -ConnectionString $conn -Query "RESTORE FILELISTONLY FROM URL = '$backupUrl' WITH CREDENTIAL = '$credentialName'" -ErrorAction Stop
    Write-Host "Logical file names fetched successfully." -ForegroundColor Green
    # Write-Host "##[section]Logical file names fetched successfully"
    Write-Host " "
    
} catch {
    Write-Error "Failed to fetch logical file names: $_"
    Write-AzureDevOpsLog -LogType "Error" -Message "Failed to fetch logical file names: $_"
    throw
}

$dataLogicalName = ($fileList.result | Where-Object {$_.Type -eq 'D'}).LogicalName
$logLogicalName  = ($fileList.result | Where-Object {$_.Type -eq 'L'}).LogicalName

Write-Host "Logical names identified: Data=[$dataLogicalName], Log=[$logLogicalName]" -ForegroundColor Green
# Write-Host "##[section]Logical names identified: Data=[$dataLogicalName], Log=[$logLogicalName]"
Write-Host " "

# Build file paths
$dataFilePath = "$data_file_path\$restore_DatabaseName.mdf"
$logFilePath = "$log_file_path\$($restore_DatabaseName)_log.ldf"

Write-Host "Target file paths:" -ForegroundColor Cyan
Write-Host "Data file: $dataFilePath" -ForegroundColor Cyan
Write-Host "Log file: $logFilePath" -ForegroundColor Cyan
Write-Host " "

# Check if target files already exist
if (Test-Path $dataFilePath) {
    Write-Error "Data file already exists: $dataFilePath"
    Write-AzureDevOpsLog -LogType "Error" -Message "Data file already exists: $dataFilePath"

}
if (Test-Path $logFilePath) {
    Write-Error "Log file already exists: $logFilePath"
    Write-AzureDevOpsLog -LogType "Error" -Message "Log file already exists: $logFilePath"
}

# Build RESTORE command with MOVE
$restoreQuery = @"
RESTORE DATABASE [$restore_DatabaseName]
FROM URL = '$backupUrl'
WITH CREDENTIAL = '$credentialName',
MOVE '$dataLogicalName' TO '$dataFilePath',
MOVE '$logLogicalName' TO '$logFilePath',
STATS=10;
"@

# Write-Host "RESTORE command:" -ForegroundColor Yellow
# Write-Host $restoreQuery -ForegroundColor Gray
# Write-Host " "

Write-Host "Restoring database [$restore_DatabaseName] from Azure Blob..." -ForegroundColor Yellow
Write-Host "##[command]Restoring database from Azure Blob"
try {
    # Invoke-Sqlcmd -ConnectionString $connectionString -Query $restoreQuery -QueryTimeout 0 -ErrorAction Stop
    Invoke-SqlQuery -ConnectionString $conn -Query $restoreQuery -QueryTimeout 0 -ErrorAction Stop | Out-Null

    Write-Host "Database [$restore_DatabaseName] restored successfully." -ForegroundColor Green
    Write-Host "##[section]Database restored successfully"

} catch {
    Write-Error "Database restore failed: $_"
    Write-Host "##vso[task.complete result=Failed;]Database restore failed"
    throw
}