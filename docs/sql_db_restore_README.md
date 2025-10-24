# SQL Database Restore Script Documentation

## Overview

The `sql_db_restore.ps1` script performs automated SQL Server database restoration from Azure Blob Storage backups. This script is designed for use in Azure DevOps pipelines and provides comprehensive validation, error handling, and integration with Azure Storage services.

## Features

- ✅ Restore databases from Azure Blob Storage backups
- ✅ Automatic logical file name detection
- ✅ Database existence validation (prevents accidental overwrites)
- ✅ File path validation and conflict detection
- ✅ Azure DevOps pipeline integration with detailed logging
- ✅ Modular design using custom PowerShell modules
- ✅ SQL credential management for Azure Storage access
- ✅ Connection validation and testing
- ✅ Progress monitoring with STATS reporting

## Prerequisites

### Software Requirements

- PowerShell 5.1 or later
- SQL Server with SqlServer PowerShell module
- Azure Storage module (Az.Storage)
- Azure Storage account with backup files

### Permissions Required

- SQL Server: Database creation permissions (`dbcreator` or `sysadmin`)
- File System: Write access to data and log file directories
- Azure Storage: Read access to the specified container and backup files
- Network: Connectivity between SQL Server and Azure Storage

## Script Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `SqlUsername` | string | Yes | SQL Server authentication username with restore permissions |
| `SqlPassword` | string | Yes | Password for the SQL Server user |
| `StorageAccountName` | string | Yes | Azure Storage account name containing the backup |
| `StorageAccountKey` | string | Yes | Azure Storage account access key |
| `ContainerName` | string | Yes | Azure Blob Storage container name |
| `blobName` | string | Yes | Full blob path to backup file (e.g., `MyDB/MyDB_backup.bak`) |
| `db_server` | string | Yes | SQL Server instance name (e.g., `localhost`, `server.domain.com`) |
| `restore_DatabaseName` | string | Yes | Name for the restored database |
| `data_file_path` | string | Yes | Directory path for data files (e.g., `C:\SQLData`) |
| `log_file_path` | string | Yes | Directory path for log files (e.g., `C:\SQLLogs`) |

## Usage Examples

### Basic Usage

```powershell
.\sql_db_restore.ps1 `
    -SqlUsername "sa" `
    -SqlPassword "SecurePassword123" `
    -StorageAccountName "mystorageaccount" `
    -StorageAccountKey "storagekey==" `
    -ContainerName "backups" `
    -blobName "MyDatabase/MyDatabase_20231024_daily.bak" `
    -db_server "localhost" `
    -restore_DatabaseName "MyDatabase_Test" `
    -data_file_path "C:\SQLData" `
    -log_file_path "C:\SQLLogs"
```

### Azure DevOps Pipeline Usage

```yaml
- task: PowerShell@2
  displayName: 'Restore Database'
  inputs:
    filePath: '$(System.DefaultWorkingDirectory)/utilities/database/sql_db_restore.ps1'
    arguments: >
      -SqlUsername "$(sql.username)" 
      -SqlPassword "$(sql.password)" 
      -StorageAccountName "$(storage.account.name)" 
      -StorageAccountKey "$(storage.account.key)" 
      -ContainerName "$(storage.container)" 
      -blobName "$(backup.blob.name)" 
      -db_server "$(sql.server)" 
      -restore_DatabaseName "$(database.restore.name)" 
      -data_file_path "$(sql.data.path)" 
      -log_file_path "$(sql.log.path)"
```

## Restore Process Flow

1. **Module Import**: Loads custom SQL functions and required Azure modules
2. **Connection Setup**: Creates and validates SQL Server connection
3. **Database Validation**: Checks if target database already exists (prevents overwrites)
4. **Credential Creation**: Sets up Azure Storage credential in SQL Server
5. **Backup Analysis**: Retrieves logical file names from backup using `RESTORE FILELISTONLY`
6. **File Path Generation**: Creates target file paths for data and log files
7. **File Conflict Check**: Verifies that target files don't already exist
8. **Database Restoration**: Executes `RESTORE DATABASE` with `MOVE` operations
9. **Verification**: Confirms successful restoration

## File Structure and Dependencies

### Module Dependencies

The script relies on custom PowerShell modules and Azure modules:

```
utilities/database/
├── sql_db_restore.ps1
├── modules/
│   └── sql.psm1
└── docs/
    ├── README.md (backup script)
    └── sql_db_restore_README.md (this file)
```

### Key Module Functions

- `New-SqlConnectionString`: Creates validated SQL connection strings
- `Test-SqlConnection`: Validates SQL Server connectivity
- `Invoke-SqlQuery`: Executes SQL queries with error handling
- `New-SqlCredential`: Creates Azure Storage credentials in SQL Server
- `Test-DatabaseExists`: Checks if a database already exists
- `Write-AzureDevOpsLog`: Standardized Azure DevOps logging

## Output and Logging

### Console Output

The script provides detailed console output including:

- Module import status and validation
- Connection test results
- Database existence check results
- Logical file name detection
- Target file path information
- Restoration progress (STATS = 10 provides 10% increments)
- Success/failure confirmation

### Azure DevOps Integration

- **Section Logs**: Major process steps
- **Error Logs**: Detailed error information
- **Command Logs**: Key operations being performed
- **Task Variables**: Success/failure status for pipeline control
- **Task Completion**: Automatic pipeline failure on critical errors

## Validation and Safety Features

### Pre-Restore Validations

1. **Database Existence Check**: Prevents accidental database overwrites
2. **Connection Validation**: Ensures SQL Server is accessible
3. **File Path Validation**: Verifies target directories exist and are writable
4. **File Conflict Detection**: Checks for existing data/log files
5. **Backup File Validation**: Confirms backup accessibility and integrity

### Error Prevention

- **Parameter Validation**: All required parameters are validated
- **Credential Testing**: Azure Storage access is verified
- **Path Sanitization**: File paths are properly formatted and validated
- **Timeout Management**: Appropriate timeouts for long-running operations

## Error Handling and Troubleshooting

### Common Issues

**Database Already Exists**
```
Database 'DatabaseName' already exists on the server
```
*Solution: Choose a different database name or manually drop the existing database*

**File Already Exists**
```
Data file already exists: [path]
```
*Solution: Remove existing files or choose different file paths*

**Azure Storage Access Denied**
```
Failed to fetch logical file names
```
*Solution: Verify storage account key and container permissions*

**Insufficient Permissions**
```
CREATE DATABASE permission denied
```
*Solution: Ensure SQL user has `dbcreator` or `sysadmin` permissions*

### Debugging Steps

1. **Verify Prerequisites**
   ```powershell
   # Test SQL connectivity
   Test-NetConnection -ComputerName "your-sql-server" -Port 1433
   
   # Verify Azure Storage access
   $ctx = New-AzStorageContext -StorageAccountName "account" -StorageAccountKey "key"
   Get-AzStorageBlob -Container "container" -Context $ctx
   ```

2. **Enable Verbose Logging**
   ```powershell
   $VerbosePreference = "Continue"
   .\sql_db_restore.ps1 [parameters]
   ```

3. **Manual Validation**
   ```sql
   -- Check if database exists
   SELECT name FROM sys.databases WHERE name = 'YourDatabaseName'
   
   -- Check available disk space
   EXEC xp_fixeddrives
   
   -- Test backup file accessibility
   RESTORE FILELISTONLY FROM URL = 'your-backup-url' 
   WITH CREDENTIAL = 'your-credential'
   ```

## Security Considerations

### Credential Management

- SQL passwords should be stored securely in Azure Key Vault
- Azure Storage keys should use managed identities when possible
- Use pipeline variables with security flags enabled
- Regularly rotate credentials and access keys

### Access Control

- Use least-privilege principle for SQL Server accounts
- Limit Azure Storage container access to necessary operations only
- Ensure proper file system permissions on target directories
- Consider using SQL Server Managed Identity for cloud scenarios

### Network Security

- Ensure SQL Server can reach Azure Storage endpoints
- Configure appropriate firewall rules and network security groups
- Use TLS encryption for all connections
- Consider using private endpoints for sensitive environments

## Performance Considerations

### Restoration Optimization

- **File Placement**: Use fast storage (SSD) for data and log files
- **File Sizing**: Pre-size data and log files to avoid auto-growth during restore
- **Network Bandwidth**: Ensure adequate bandwidth between SQL Server and Azure Storage
- **Parallel Processing**: Consider striped backups for very large databases (requires script modification)

### Monitoring and Alerting

- **Progress Tracking**: Monitor STATS output for large database restores
- **Space Monitoring**: Ensure adequate free space in target directories
- **Performance Counters**: Monitor disk I/O and network utilization
- **Pipeline Timeouts**: Set appropriate timeouts for large database restores

## File Organization

### Generated Files

After successful execution, the following files will be created:

```
[data_file_path]/
└── [restore_DatabaseName].mdf

[log_file_path]/
└── [restore_DatabaseName]_log.ldf
```

### Cleanup Considerations

- **Failed Restores**: Manually clean up partial files after failures
- **Temporary Files**: SQL Server may create temporary files during restore
- **Backup Files**: Consider cleanup policies for source backup files

## Integration with Other Scripts

### Related Scripts

- `sql_db_backup.ps1`: Creates backups that this script can restore
- `modules/sql.psm1`: Shared SQL Server functions module
- `create_sql_user.ps1`: Creates users in restored databases

### Pipeline Integration

```yaml
# Complete backup and restore pipeline example
stages:
- stage: Backup
  jobs:
  - job: BackupProduction
    steps:
    - task: PowerShell@2
      displayName: 'Backup Production Database'
      inputs:
        filePath: 'utilities/database/sql_db_backup.ps1'
        arguments: [backup parameters]

- stage: Restore
  dependsOn: Backup
  jobs:
  - job: RestoreToTest
    steps:
    - task: PowerShell@2
      displayName: 'Restore to Test Environment'
      inputs:
        filePath: 'utilities/database/sql_db_restore.ps1'
        arguments: [restore parameters]
```

## Monitoring and Maintenance

### Regular Tasks

- Monitor restore operation duration trends
- Verify restored database integrity periodically
- Update storage account keys as needed
- Review and update timeout values based on database sizes
- Test disaster recovery procedures regularly

### Health Checks

- **Database Integrity**: Run `DBCC CHECKDB` on restored databases
- **Performance Baseline**: Compare restored database performance
- **User Access**: Verify logins and permissions post-restore
- **Application Testing**: Validate application connectivity

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Current | Initial modular implementation with comprehensive validation |

## Support and Contributing

For issues, improvements, or questions:

1. Check the troubleshooting section above
2. Review Azure DevOps pipeline logs for detailed error information
3. Verify all prerequisites and permissions
4. Test connectivity and permissions manually before running automated restores
5. Ensure adequate disk space and proper file permissions

## Best Practices

### Development Environment

- Use separate storage containers for different environments
- Implement naming conventions for restored databases
- Use test databases with smaller datasets when possible
- Automate cleanup of temporary test databases

### Production Environment

- Always test restore procedures in non-production first
- Implement proper change management for database restores
- Document restoration procedures and emergency contacts
- Maintain offline copies of critical backup files

---

*This documentation covers the modular version of the SQL restore script with enhanced validation and Azure DevOps integration.*