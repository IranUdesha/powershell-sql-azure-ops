# SQL Database Backup Script Documentation

## Overview

The `sql_db_backup.ps1` script performs automated SQL Server database backups directly to Azure Blob Storage. This script is designed for use in Azure DevOps pipelines and provides comprehensive logging, error handling, and integration with Azure Storage services.

## Features

- ✅ Direct backup to Azure Blob Storage
- ✅ Azure DevOps pipeline integration
- ✅ Comprehensive error handling and logging
- ✅ Modular design using custom PowerShell modules
- ✅ Backup size reporting and duration tracking
- ✅ SQL credential management for Azure Storage
- ✅ Connection validation and testing

## Prerequisites

### Software Requirements
- PowerShell 5.1 or later
- SQL Server with SqlServer PowerShell module
- Azure Storage account with appropriate permissions

### Permissions Required
- SQL Server: Database backup permissions (`db_backupoperator` or `sysadmin`)
- Azure Storage: Read/Write access to the specified container
- Network: Connectivity between SQL Server and Azure Storage

## Script Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `SourceServer` | string | Yes | SQL Server instance name (e.g., `localhost`, `server.domain.com`) |
| `DatabaseName` | string | Yes | Name of the database to backup |
| `SqlUsername` | string | Yes | SQL Server authentication username with backup permissions |
| `SqlPassword` | string | Yes | Password for the SQL Server user |
| `StorageAccountName` | string | Yes | Azure Storage account name |
| `StorageAccountKey` | string | Yes | Azure Storage account access key |
| `ContainerName` | string | Yes | Azure Blob Storage container name |
| `backup_name` | string | Yes | Unique identifier for the backup file |

## Usage Examples

### Basic Usage
```powershell
.\sql_db_backup.ps1 -SourceServer "localhost" -DatabaseName "MyDatabase" -SqlUsername "sa" -SqlPassword "SecurePassword123" -StorageAccountName "mystorageaccount" -StorageAccountKey "storagekey==" -ContainerName "backups" -backup_name "20231024_daily"
```

### Azure DevOps Pipeline Usage
```yaml
- task: PowerShell@2
  displayName: 'Backup Database'
  inputs:
    filePath: '$(System.DefaultWorkingDirectory)/utilities/database/sql_db_backup.ps1'
    arguments: >
      -SourceServer "$(sql.server)" 
      -DatabaseName "$(database.name)" 
      -SqlUsername "$(sql.username)" 
      -SqlPassword "$(sql.password)" 
      -StorageAccountName "$(storage.account.name)" 
      -StorageAccountKey "$(storage.account.key)" 
      -ContainerName "$(storage.container)" 
      -backup_name "$(Build.BuildId)"
```

## Output and Return Values

### Console Output
The script provides detailed console output including:
- Module import status
- Connection validation results
- Backup progress (STATS = 10 provides 10% increments)
- Completion time and duration
- Backup size in GB

### Azure DevOps Variables
The script sets the following Azure DevOps pipeline variables:
- `Backup_Success`: Boolean indicating backup success/failure
- Additional variables available through the returned JSON object

### Return Object (JSON)
```json
{
  "Success": true,
  "Backup_file_name": "MyDatabase/MyDatabase_20231024_daily.bak",
  "Duration": 2.5,
  "BackupSizeGB": 1.25
}
```

## File Structure and Dependencies

### Module Dependencies
The script relies on custom PowerShell modules located in the `modules/` subdirectory:

```
utilities/database/
├── sql_db_backup.ps1
├── modules/
│   └── sql.psm1
└── docs/
    └── README.md
```

### Key Module Functions
- `New-SqlConnectionString`: Creates validated SQL connection strings
- `Test-SqlConnection`: Validates SQL Server connectivity
- `Invoke-SqlQuery`: Executes SQL queries with error handling
- `New-SqlCredential`: Creates Azure Storage credentials in SQL Server
- `Write-AzureDevOpsLog`: Standardized Azure DevOps logging

## Backup Process Flow

1. **Module Import**: Loads custom SQL functions from the modules directory
2. **Connection Setup**: Creates and validates SQL Server connection
3. **Credential Creation**: Sets up Azure Storage credential in SQL Server
4. **Backup Execution**: Performs database backup to Azure Blob Storage
5. **Verification**: Retrieves backup metadata and size information
6. **Reporting**: Outputs results for pipeline consumption

## Error Handling

### Connection Errors
- SQL Server connectivity issues
- Invalid credentials or permissions
- Network connectivity problems

### Backup Errors
- Insufficient disk space
- Azure Storage access issues
- Database lock conflicts
- Invalid backup parameters

### Recovery Actions
- All errors are logged to Azure DevOps pipeline logs
- Failed operations set appropriate pipeline variables
- Script exits with error codes for pipeline failure handling

## Security Considerations

### Credential Management
- SQL passwords are handled as secure parameters
- Azure Storage keys should be stored in Azure Key Vault
- Use pipeline variables with security flags enabled

### Network Security
- Ensure SQL Server can reach Azure Storage endpoints
- Consider firewall rules and network security groups
- Use TLS encryption for all connections

### Access Control
- Use least-privilege principle for SQL Server accounts
- Limit Azure Storage container access to backup operations only
- Regularly rotate credentials and access keys

## Troubleshooting

### Common Issues

**Module Import Failures**
```
Module folder not found: [path]
```
*Solution: Ensure the modules directory exists relative to the script location*

**Connection Timeouts**
```
Failed to execute SQL query: Timeout expired
```
*Solution: Increase connection timeout or check network connectivity*

**Azure Storage Access Denied**
```
Cannot bulk load because the file could not be opened
```
*Solution: Verify storage account key and container permissions*

### Debugging Steps

1. **Verify Prerequisites**
   ```powershell
   # Test SQL connectivity
   Test-NetConnection -ComputerName "your-sql-server" -Port 1433
   
   # Verify Azure Storage access
   $ctx = New-AzStorageContext -StorageAccountName "account" -StorageAccountKey "key"
   Get-AzStorageContainer -Context $ctx
   ```

2. **Enable Verbose Logging**
   ```powershell
   $VerbosePreference = "Continue"
   .\sql_db_backup.ps1 [parameters]
   ```

3. **Check SQL Server Logs**
   - Review SQL Server Error Log for backup-related messages
   - Check for Azure Storage connectivity issues

## Performance Considerations

### Backup Optimization
- Use `CHECKSUM` option for backup verification (enabled by default)
- Consider compression for large databases (can be added to backup query)
- Monitor backup duration and adjust timeout values accordingly

### Network Optimization
- Place SQL Server and Azure Storage in the same region when possible
- Consider using Azure ExpressRoute for large, frequent backups
- Monitor bandwidth usage during backup windows

## Maintenance

### Regular Tasks
- Monitor backup sizes and duration trends
- Verify backup integrity periodically
- Update storage account keys as needed
- Review and update timeout values based on database growth

### Monitoring
- Set up alerts for backup failures in Azure DevOps
- Monitor Azure Storage costs and usage patterns
- Track backup file retention and cleanup policies

## Related Scripts

- `sql_db_restore.ps1`: Companion script for database restoration
- `modules/sql.psm1`: Shared SQL Server functions module

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Current | Initial modular implementation with Azure DevOps integration |

## Support and Contributing

For issues, improvements, or questions:
1. Check the troubleshooting section above
2. Review Azure DevOps pipeline logs for detailed error information
3. Verify all prerequisites and permissions
4. Test connectivity manually before running automated backups

---

*This documentation covers the modular version of the SQL backup script with enhanced error handling and Azure DevOps integration.*