# Security Policy

## Reporting Security Vulnerabilities

If you discover a security vulnerability in this project, please report it privately by:

1. **Email**: Send details to the repository owner
2. **GitHub Security**: Use GitHub's private vulnerability reporting feature
3. **Include**: Detailed description, steps to reproduce, and potential impact

Please do NOT create public GitHub issues for security vulnerabilities.

## Security Best Practices

### For Users

When using these scripts in production:

1. **Never hardcode credentials** in scripts or configuration files
2. **Use environment variables** or Azure Key Vault for sensitive data
3. **Implement least privilege access** for all accounts
4. **Regularly rotate** passwords and access keys
5. **Monitor and audit** all database operations
6. **Use secure network connections** (VPN, private endpoints)

### Example Secure Usage

```powershell
# Use environment variables
$env:SQL_PASSWORD = "YourSecurePassword"
$env:STORAGE_KEY = "YourStorageAccountKey"

# Pass to scripts
.\sql_db_backup.ps1 -SqlPassword $env:SQL_PASSWORD -StorageAccountKey $env:STORAGE_KEY
```

### Azure DevOps Pipeline Security

```yaml
# Use pipeline variables or variable groups
variables:
- group: 'SQL-Azure-Secrets'  # Secure variable group

steps:
- task: PowerShell@2
  inputs:
    arguments: '-SqlPassword $(SqlPassword) -StorageAccountKey $(StorageKey)'
```

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.0.x   | ✅        |

## Security Features

- ✅ No hardcoded credentials
- ✅ Parameterized queries to prevent SQL injection
- ✅ Connection string validation
- ✅ Error handling to prevent credential exposure
- ✅ Secure credential creation in SQL Server
- ✅ TrustServerCertificate option for SSL

## Known Security Considerations

1. **SQL Server Authentication**: Scripts use SQL authentication (not Windows Auth)
2. **Network Security**: Requires network connectivity to Azure Storage
3. **Credential Management**: User responsible for secure credential storage
4. **Backup Security**: Backups stored in Azure Blob Storage inherit storage security settings

## Compliance

This toolkit is designed to help with:
- SOC 2 compliance requirements
- GDPR data protection (backup/restore capabilities)
- Industry-standard security practices
- Audit trail maintenance

## Contact

For security-related questions or concerns, please contact the repository maintainer.