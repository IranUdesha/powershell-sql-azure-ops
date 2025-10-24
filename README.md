# SQL Server Azure Toolkit

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://docs.microsoft.com/en-us/powershell/)
[![SQL Server](https://img.shields.io/badge/SQL%20Server-2016%2B-red.svg)](https://www.microsoft.com/en-us/sql-server/)
[![Azure](https://img.shields.io/badge/Azure-Blob%20Storage-0078d4.svg)](https://azure.microsoft.com/en-us/services/storage/blobs/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A comprehensive PowerShell toolkit designed for SQL Server database operations with seamless Azure Blob Storage integration. This toolkit provides enterprise-grade solutions for database backup, restore, and user management operations, specifically optimized for Azure DevOps CI/CD pipelines.

## 🚀 Key Features

- **🔄 Direct Azure Backup**: Backup SQL Server databases directly to Azure Blob Storage without intermediate files
- **☁️ Cloud Restore**: Restore databases from Azure Blob Storage with automatic logical file management
- **👤 User Management**: Create SQL logins and database users with comprehensive role assignment and schema mapping
- **🔗 Azure DevOps Integration**: Built-in logging, pipeline variables, and structured output for CI/CD workflows
- **🧩 Modular Design**: Reusable PowerShell functions library for custom database operations
- **🛡️ Enterprise Ready**: Comprehensive error handling, connection validation, and security best practices

## 📁 Project Structure

```
sqlserver-azure-toolkit/
├── README.md                          # This file
├── sql_db_backup.ps1                  # Database backup to Azure Blob Storage
├── sql_db_restore.ps1                 # Database restore from Azure Blob Storage
├── create_sql_user.ps1                # SQL login and user creation
├── modules/                           # PowerShell modules
│   ├── sql.psd1                      # Module manifest
│   └── sql.psm1                      # Core SQL functions library
└── docs/                             # Detailed documentation
    ├── sql_db_backup_README.md       # Backup script documentation
    ├── sql_db_restore_README.md      # Restore script documentation
    └── create_sql_user_README.md     # User creation documentation
```

## 🛠️ Prerequisites

### Software Requirements
- **PowerShell**: 5.1 or later
- **SQL Server**: 2016 or later with SqlServer PowerShell module
- **Azure Storage Account**: With blob storage capability
- **Network Connectivity**: Between SQL Server and Azure Storage

### Required Permissions
- **SQL Server**: `sysadmin` or equivalent administrative permissions
- **Azure Storage**: Read/Write access to target containers
- **File System**: Write access to SQL Server data and log directories (for restore operations)

## 🚀 Quick Start

### 1. Clone the Repository
```powershell
git clone https://github.com/IranUdesha/powershell-sql-azure-ops.git
cd powershell-sql-azure-ops
```

### 2. Import the Module
```powershell
Import-Module .\modules\sql.psm1 -Force
```

### 3. Backup a Database
```powershell
.\sql_db_backup.ps1 `
    -SourceServer "localhost" `
    -DatabaseName "MyDatabase" `
    -SqlUsername "sa" `
    -SqlPassword "YourSecurePassword" `
    -StorageAccountName "mystorageaccount" `
    -StorageAccountKey "your-storage-account-key" `
    -ContainerName "backups" `
    -backup_name "daily_$(Get-Date -Format 'yyyyMMdd')"
```

### 4. Restore a Database
```powershell
.\sql_db_restore.ps1 `
    -SqlUsername "sa" `
    -SqlPassword "YourSecurePassword" `
    -StorageAccountName "mystorageaccount" `
    -StorageAccountKey "your-storage-account-key" `
    -ContainerName "backups" `
    -blobName "MyDatabase/MyDatabase_daily_20241024.bak" `
    -db_server "localhost" `
    -restore_DatabaseName "MyDatabase_Restored" `
    -data_file_path "C:\SQLData" `
    -log_file_path "C:\SQLLogs"
```

### 5. Create SQL User
```powershell
.\create_sql_user.ps1 `
    -db_server_name "localhost" `
    -db_name "MyDatabase" `
    -db_username "appuser" `
    -db_password "YourSecureAppPassword" `
    -schema_name "dbo" `
    -sa_username "sa" `
    -sa_password "YourSecurePassword"
```

## 📋 Core Scripts

### 🔄 sql_db_backup.ps1
Performs direct database backup to Azure Blob Storage with comprehensive logging and error handling.

**Key Features:**
- Direct cloud backup without local intermediate files
- Automatic SQL credential management for Azure Storage
- Backup size reporting and duration tracking
- Azure DevOps pipeline integration

**[📖 Detailed Documentation](docs/sql_db_backup_README.md)**

### ☁️ sql_db_restore.ps1
Restores databases from Azure Blob Storage with automatic file management and validation.

**Key Features:**
- Automatic logical file name detection
- Database existence validation to prevent overwrites
- File path conflict detection
- Progress monitoring with detailed statistics

**[📖 Detailed Documentation](docs/sql_db_restore_README.md)**

### 👤 create_sql_user.ps1
Creates SQL Server logins and database users with comprehensive role assignments.

**Key Features:**
- SQL Server login creation with authentication
- Database user creation with schema mapping
- Comprehensive role assignment (database and server roles)
- Duplicate user/login detection and handling

**[📖 Detailed Documentation](docs/create_sql_user_README.md)**

## 🧩 PowerShell Module (modules/sql.psm1)

The core module provides reusable functions for all database operations:

### Available Functions

| Function | Description |
|----------|-------------|
| `New-SqlConnectionString` | Creates standardized connection strings |
| `Test-SqlConnection` | Validates database connectivity |
| `Invoke-SqlQuery` | Executes SQL queries with error handling |
| `New-SqlCredential` | Creates Azure Storage credentials in SQL Server |
| `Test-DatabaseExists` | Checks if database exists on server |
| `New-SqlLogin` | Creates SQL Server authentication logins |
| `New-SqlUserInDatabase` | Creates database users with schema mapping |
| `Add-SqlUserToDatabaseRoles` | Assigns comprehensive role memberships |
| `Write-AzureDevOpsLog` | Standardized Azure DevOps logging |

### Usage Example
```powershell
# Import the module
Import-Module .\modules\sql.psm1

# Create connection string
$conn = New-SqlConnectionString -ServerInstance "localhost" -Database "master" -Username "sa" -Password "password"

# Test connection
if (Test-SqlConnection -ConnectionString $conn) {
    Write-Host "Connection successful!"
}

# Execute query
$result = Invoke-SqlQuery -ConnectionString $conn -Query "SELECT @@VERSION"
```

## 🔧 Azure DevOps Integration

All scripts are designed for seamless integration with Azure DevOps pipelines:

### Pipeline Task Example
```yaml
- task: PowerShell@2
  displayName: 'Backup Database to Azure'
  inputs:
    targetType: 'filePath'
    filePath: '$(System.DefaultWorkingDirectory)/sql_db_backup.ps1'
    arguments: >
      -SourceServer "$(SQL_SERVER)"
      -DatabaseName "$(DATABASE_NAME)"
      -SqlUsername "$(SQL_USERNAME)"
      -SqlPassword "$(SQL_PASSWORD)"
      -StorageAccountName "$(STORAGE_ACCOUNT)"
      -StorageAccountKey "$(STORAGE_KEY)"
      -ContainerName "$(CONTAINER_NAME)"
      -backup_name "$(Build.BuildId)"
```

### Pipeline Variables
The scripts set output variables for use in subsequent pipeline stages:
- `Backup_Success`: Boolean indicating backup success
- `Backup_file_name`: Generated backup file name
- `BackupSizeGB`: Size of backup in gigabytes
- `Duration`: Operation duration in minutes

## 🔒 Security Best Practices

### Credential Management
- **Never hardcode credentials** in scripts or configuration files
- Use Azure Key Vault for storing sensitive credentials
- Implement service principals for Azure Storage access
- Use SQL Server service accounts with minimal required permissions
- Regularly rotate storage account keys and SQL passwords

### Environment Variables
Consider using environment variables for sensitive data:
```powershell
$env:SQL_PASSWORD = "YourSecurePassword"
$env:STORAGE_KEY = "YourStorageKey"

# Use in scripts
-SqlPassword $env:SQL_PASSWORD -StorageAccountKey $env:STORAGE_KEY
```

### Network Security
- Configure SQL Server firewall rules appropriately
- Use private endpoints for Azure Storage when possible
- Implement network security groups for additional protection
- Consider VPN or ExpressRoute for hybrid connectivity

### Access Control
- Apply principle of least privilege for all accounts
- Use Azure RBAC for storage account access control
- Implement SQL Server role-based security
- Audit and monitor all database operations

## 🎯 Use Cases

### Development Teams
- **Environment Provisioning**: Quickly restore production data to development environments
- **Feature Testing**: Create isolated database copies for feature branch testing
- **Data Migration**: Move databases between environments with consistent processes

### DevOps Teams
- **Automated Backups**: Schedule regular backups as part of maintenance pipelines
- **Disaster Recovery**: Implement automated restore procedures for DR scenarios
- **Release Management**: Backup databases before deployments with rollback capability

### Database Administrators
- **Backup Strategy**: Implement cloud-first backup strategies with local fallback
- **User Management**: Standardize user creation across multiple environments
- **Monitoring**: Integrate with existing monitoring and alerting systems

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

1. **Fork the repository** and create a feature branch
2. **Follow PowerShell best practices** and maintain existing code style
3. **Add comprehensive tests** for new functionality
4. **Update documentation** for any changes
5. **Submit a pull request** with detailed description of changes

### Development Setup
```powershell
# Clone your fork
git clone https://github.com/yourusername/powershell-sql-azure-ops.git

# Create feature branch
git checkout -b feature/your-feature-name

# Make changes and test thoroughly
# Commit and push changes
git commit -m "Add your feature description"
git push origin feature/your-feature-name
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

### Documentation
- **Script Documentation**: Detailed docs in the `/docs` folder
- **Function Reference**: Inline documentation in the PowerShell module
- **Examples**: Working examples in each script's documentation

### Getting Help
- **Issues**: Report bugs and request features via GitHub Issues
- **Discussions**: Community support and questions via GitHub Discussions
- **Wiki**: Additional examples and troubleshooting guides

### Known Limitations
- Requires SQL Server authentication (Windows Authentication not supported)
- Single backup file per operation (no striped backups)
- Requires network connectivity between SQL Server and Azure Storage
- Azure Storage account keys must be managed separately

## 🎖️ Acknowledgments

- Microsoft SQL Server team for the SqlServer PowerShell module
- Azure Storage team for comprehensive PowerShell integration
- PowerShell community for best practices and patterns
- Azure DevOps team for pipeline integration capabilities

---

**⭐ If this toolkit helps you, please consider giving it a star on GitHub!**

For detailed documentation on individual scripts, please refer to the files in the `/docs` directory.