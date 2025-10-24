# This script performs a backup directly to Azure Storage

param(
    # [Parameter(Mandatory=$true)]
    [string]$SourceServer, # SQL Server instance name ex- localhost
    
    # [Parameter(Mandatory=$true)]
    [string]$DatabaseName,
    
    # [Parameter(Mandatory=$true)]
    [string]$SqlUsername, # SA username or SQL Auth user with necessary permissions
    
    # [Parameter(Mandatory=$true)]
    [string]$SqlPassword, # Corresponding password
    
    # [Parameter(Mandatory=$true)]
    [string]$StorageAccountName,
    
    # [Parameter(Mandatory=$true)]
    [string]$StorageAccountKey,
    
    # [Parameter(Mandatory=$true)]
    [string]$ContainerName,

    # [Parameter(Mandatory=$true)]
    [string]$backup_name
)


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


Write-Host "Starting backup process for database: $DatabaseName"

# Create SQL Credential name
$credentialName = "Az_stg_$StorageAccountName"
# $backupDate = Get-Date -Format "yyyy_MM_dd_HH_mm_ss"
# $backupFolder = "$DatabaseName/$backupDate"

# Create connection
$conn = New-SqlConnectionString -ServerInstance $SourceServer -Username $SqlUsername -Password $SqlPassword

# Test connection
if (Test-SqlConnection -ConnectionString $conn) {
    Write-Host "Connection successful"
}

# Create credential in SQL Server for Azure Storage
New-SqlCredential -ConnectionString $conn -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey -CredentialName $credentialName


# Generate single backup URL (Azure Blob Storage doesn't support striped backups)
$backupUrl = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/$DatabaseName/${DatabaseName}_${backup_name}.bak"

# Build backup command
$backupQuery = "BACKUP DATABASE [$DatabaseName] TO URL = '$backupUrl'"
$backupQuery += " WITH CREDENTIAL = '$credentialName', STATS = 10, CHECKSUM, FORMAT"

Write-Host "Backup URL configured: $backupUrl" -ForegroundColor Yellow

# Execute backup
Write-Host "Starting backup operation..."
$backupStartTime = Get-Date

# Invoke-Sqlcmd -ConnectionString $connectionString -Query $backupQuery -QueryTimeout 0 -ErrorAction Stop 
$reply = Invoke-SqlQuery -ConnectionString $conn -Query $backupQuery -QueryTimeout 0 -ErrorAction Stop 

if ($reply.status -eq $true) {
    
    $backupEndTime = Get-Date
    $duration = ($backupEndTime - $backupStartTime).TotalMinutes
    Write-Host "Backup operation completed successfully in $([math]::Round($duration, 2)) minutes." -ForegroundColor Green
    Write-AzureDevOpsLog -LogType "section" -Message "Backup operation completed successfully in $([math]::Round($duration, 2)) minutes." -VariableName "Backup_Success" -VariableValue "true"
    Write-Host " "

} else {
    Write-Error "Backup operation failed."
    Write-Host "##vso[task.setvariable variable=Backup_Success;isOutput=true]false"
    Write-Host "##vso[task.complete result=Failed;]Backup operation failed"
    exit 1
}


# Get Relevant information and return as output variables
try{
    
    # Get backup size
    $sizeQuery = @"
SELECT TOP 1
    backup_size/1024/1024/1024 as BackupSizeGB
FROM msdb.dbo.backupset 
WHERE database_name = '$DatabaseName' 
    AND type = 'D'
ORDER BY backup_start_date DESC
"@
    
    #$backupSize = Invoke-Sqlcmd -ConnectionString $connectionString -Query $sizeQuery -ErrorAction Stop
    $backupSize = Invoke-SqlQuery -ConnectionString $conn -Query $sizeQuery -ErrorAction Stop

    # Handle potential null or empty result and array return
    $sizeInGB = 0
    if ($backupSize.result) {
        # Handle if result is an array, take the first item
        $firstResult = if ($backupSize.result -is [array]) { $backupSize.result[0] } else { $backupSize.result}
        
        if ($firstResult -and $firstResult.BackupSizeGB -ne $null) {
            try {
                $sizeInGB = [math]::Round([double]$firstResult.BackupSizeGB, 2)
                Write-Host "Backup size: $sizeInGB GB" -ForegroundColor Cyan
            } catch {
                Write-Host "Backup size: Unable to parse size value ($($firstResult.BackupSizeGB))"
            }
        } else {
            Write-Host "Backup size: Unable to determine (backup may still be processing)"
        }
    } else {
        Write-Host "Backup size: No backup records found"
    }
    
    # Output backup paths for pipeline (for next stage)
    $output = @{
        Success = $true
        Backup_file_name = "$DatabaseName/${DatabaseName}_${backup_name}.bak"
        # BackupFolder = $backupFolder
        # BackupUrl = $backupUrl
        Duration = $duration
        BackupSizeGB = $sizeInGB
    }
    
    # Write-Host "##vso[task.setvariable variable=Backup_Folder;isOutput=true]$backupFolder"
    Write-Host "##vso[task.setvariable variable=Backup_Success;isOutput=true]true"
    
    return $output | ConvertTo-Json
}
catch {
    Write-Error "Failed to retrieve backup size: $_"
    Write-Host "##vso[task.setvariable variable=BackupSuccess;isOutput=true]false"
    Write-Host "##vso[task.complete result=Failed;]Backup operation failed"
    throw
}



# End of Script