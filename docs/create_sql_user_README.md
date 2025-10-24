# SQL User Creation Script Documentation

## Overview

The `create_sql_user.ps1` script automates the creation of SQL Server logins and database users with comprehensive role assignments. This script is designed for use in Azure DevOps pipelines and development workflows to standardize user creation with appropriate permissions and schema mappings.

## Features

- ✅ Creates SQL Server logins with specified credentials
- ✅ Creates database users mapped to logins
- ✅ Assigns users to custom schemas
- ✅ Applies comprehensive database role memberships
- ✅ Includes server-level role assignments
- ✅ Azure DevOps pipeline integration with detailed logging
- ✅ Modular design using custom PowerShell modules
- ✅ Connection validation and error handling
- ✅ Duplicate user/login detection and handling

## Prerequisites

### Software Requirements

- PowerShell 5.1 or later
- SQL Server with SqlServer PowerShell module
- SQL Server instance with appropriate connectivity

### Permissions Required

- **SQL Server Login**: Administrative privileges (`sysadmin` or equivalent)
- **Database Access**: Permission to create users and assign roles
- **Security Administration**: Rights to manage logins and server roles
- **Schema Access**: Rights to assign users to specified schemas

### Administrative User Requirements

The script requires an administrative SQL user (SA user) with the following permissions:
- `securityadmin` server role (minimum)
- `db_owner` role in target database
- `CREATE LOGIN` permissions at server level
- `ALTER ANY USER` permissions in target database

## Script Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `db_server_name` | string | Yes | SQL Server instance name (e.g., `localhost`, `server.domain.com`) |
| `db_name` | string | Yes | Target database name where user will be created |
| `db_username` | string | Yes | Username for the new SQL login and database user |
| `db_password` | string | Yes | Password for the new user (must meet SQL Server password policy) |
| `schema_name` | string | Yes | Schema to assign as default schema for the user |
| `sa_username` | string | Yes | Administrative SQL username with user creation permissions |
| `sa_password` | string | Yes | Password for the administrative SQL user |

## Database Roles Assigned

The script automatically assigns the new user to the following database roles:

### Database-Level Roles
- **`db_owner`**: Full permissions within the database
- **`db_securityadmin`**: Manage permissions, roles, and security
- **`db_accessadmin`**: Add or remove users from the database
- **`db_datareader`**: Read all data from all tables
- **`db_datawriter`**: Add, change, or delete data from all tables
- **`db_ddladmin`**: Add, modify, or drop objects in the database
- **`db_backupoperator`**: Backup the database

### Server-Level Roles
- **`SecurityAdmin`**: Manage logins and their properties, server-level permissions

## Usage Examples

### Basic Usage

```powershell
.\create_sql_user.ps1 `
    -db_server_name "localhost" `
    -db_name "MyApplication" `
    -db_username "app_user" `
    -db_password "SecurePassword123!" `
    -schema_name "app_schema" `
    -sa_username "sa" `
    -sa_password "AdminPassword123!"
```

### Azure DevOps Pipeline Usage

```yaml
- task: PowerShell@2
  displayName: 'Create Database User'
  inputs:
    filePath: '$(System.DefaultWorkingDirectory)/utilities/database/create_sql_user.ps1'
    arguments: >
      -db_server_name "$(sql.server)" 
      -db_name "$(database.name)" 
      -db_username "$(app.db.username)" 
      -db_password "$(app.db.password)" 
      -schema_name "$(app.schema.name)" 
      -sa_username "$(sql.admin.username)" 
      -sa_password "$(sql.admin.password)"
```

### Multiple Environment Setup

```powershell
# Development Environment
.\create_sql_user.ps1 `
    -db_server_name "dev-sql-server" `
    -db_name "MyApp_Dev" `
    -db_username "dev_app_user" `
    -db_password "DevPassword123!" `
    -schema_name "dev_schema" `
    -sa_username "sa" `
    -sa_password "AdminPassword123!"

# Production Environment
.\create_sql_user.ps1 `
    -db_server_name "prod-sql-server" `
    -db_name "MyApp_Prod" `
    -db_username "prod_app_user" `
    -db_password "ProdPassword123!" `
    -schema_name "prod_schema" `
    -sa_username "sa" `
    -sa_password "AdminPassword123!"
```

## User Creation Process Flow

1. **Module Import**: Loads custom SQL functions from the modules directory
2. **Connection Setup**: Creates and validates administrative SQL Server connection
3. **Login Creation**: Creates new SQL Server login at server level
4. **User Creation**: Creates database user mapped to the login
5. **Schema Assignment**: Maps user to specified default schema
6. **Role Assignment**: Applies comprehensive database and server role memberships
7. **Verification**: Confirms successful creation and role assignments

## File Structure and Dependencies

### Module Dependencies

The script relies on custom PowerShell modules:

```
utilities/database/
├── create_sql_user.ps1
├── sql_db_backup.ps1
├── sql_db_restore.ps1
├── modules/
│   └── sql.psm1
└── docs/
    ├── README.md (backup script)
    ├── sql_db_restore_README.md (restore script)
    └── create_sql_user_README.md (this file)
```

### Key Module Functions Used

- `New-SqlConnectionString`: Creates validated SQL connection strings
- `New-SqlLogin`: Creates SQL Server login at server level
- `New-SqlUserInDatabase`: Creates database user mapped to login
- `Add-SqlUserToDatabaseRoles`: Assigns comprehensive role memberships
- `Write-AzureDevOpsLog`: Standardized Azure DevOps logging

## Security Considerations

### Password Security

- **Password Complexity**: Ensure passwords meet SQL Server password policy requirements
- **Credential Storage**: Store passwords securely using Azure Key Vault or secure variables
- **Password Rotation**: Implement regular password rotation policies
- **Least Privilege**: Consider if all assigned roles are necessary for the application

### Role Assignment Analysis

The script assigns extensive permissions. Consider customizing role assignments based on actual requirements:

```sql
-- Minimal permissions example for read-only application user
EXEC sp_addrolemember N'db_datareader', N'username';

-- Standard application user permissions
EXEC sp_addrolemember N'db_datareader', N'username';
EXEC sp_addrolemember N'db_datawriter', N'username';

-- Administrative permissions (current script default)
-- Full db_owner permissions + additional roles
```

### Access Control Best Practices

- **Administrative Accounts**: Use dedicated administrative accounts for user creation
- **Service Accounts**: Create specific service accounts for applications
- **Environment Isolation**: Use different credentials for different environments
- **Audit Trail**: Monitor user creation and role assignments

## Output and Logging

### Console Output

The script provides detailed console output including:

- Module import status and validation
- Administrative connection test results
- Login creation confirmation
- User creation and schema mapping status
- Role assignment results for each database role
- Server role assignment confirmation

### Azure DevOps Integration

- **Section Logs**: Major process steps and completion status
- **Error Logs**: Detailed error information with context
- **Success Confirmation**: Verification of user creation and role assignments

## Error Handling and Troubleshooting

### Common Issues

**Login Already Exists**
```
Login 'username' already exists
```
*Solution: The script handles existing logins gracefully, but verify intended behavior*

**Insufficient Administrative Permissions**
```
ALTER ANY LOGIN permission denied
```
*Solution: Ensure administrative user has `securityadmin` or `sysadmin` permissions*

**Database Not Found**
```
Invalid database name 'DatabaseName'
```
*Solution: Verify database exists and administrative user has access*

**Schema Not Found**
```
Schema 'schema_name' does not exist
```
*Solution: Create schema first or use existing schema like 'dbo'*

**Password Policy Violation**
```
Password validation failed
```
*Solution: Ensure password meets SQL Server complexity requirements*

### Debugging Steps

1. **Verify Prerequisites**
   ```powershell
   # Test SQL connectivity
   Test-NetConnection -ComputerName "your-sql-server" -Port 1433
   
   # Test administrative permissions
   sqlcmd -S "server" -U "admin_user" -P "password" -Q "SELECT IS_SRVROLEMEMBER('securityadmin')"
   ```

2. **Manual Verification**
   ```sql
   -- Check if login exists
   SELECT name FROM sys.server_principals WHERE name = 'username'
   
   -- Check if user exists in database
   USE [DatabaseName]
   SELECT name FROM sys.database_principals WHERE name = 'username'
   
   -- Check user roles
   SELECT 
       u.name AS username,
       r.name AS role_name
   FROM sys.database_role_members rm
   JOIN sys.database_principals u ON rm.member_principal_id = u.principal_id
   JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
   WHERE u.name = 'username'
   ```

3. **Enable Verbose Logging**
   ```powershell
   $VerbosePreference = "Continue"
   .\create_sql_user.ps1 [parameters]
   ```

## Customization Options

### Role Assignment Customization

To modify the assigned roles, edit the `Add-SqlUserToDatabaseRoles` function in `modules/sql.psm1`:

```sql
-- Example: Minimal permissions for read-only user
EXEC sp_addrolemember N'db_datareader', N'$UserName';

-- Example: Application user with read/write
EXEC sp_addrolemember N'db_datareader', N'$UserName';
EXEC sp_addrolemember N'db_datawriter', N'$UserName';

-- Example: Current comprehensive permissions (default)
-- All roles as currently implemented
```

### Schema Management

Consider creating custom schemas before user creation:

```sql
-- Create application-specific schema
CREATE SCHEMA [app_schema] AUTHORIZATION [dbo];

-- Grant schema permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[app_schema] TO [username];
```

## Integration with Other Scripts

### Pipeline Integration Example

```yaml
# Complete database setup pipeline
stages:
- stage: DatabaseSetup
  jobs:
  - job: CreateDatabase
    steps:
    - task: PowerShell@2
      displayName: 'Restore Database'
      inputs:
        filePath: 'utilities/database/sql_db_restore.ps1'
        arguments: [restore parameters]
    
    - task: PowerShell@2
      displayName: 'Create Application User'
      inputs:
        filePath: 'utilities/database/create_sql_user.ps1'
        arguments: [user creation parameters]
```

### Related Scripts Usage

- **After Database Restore**: Use this script to create application users in restored databases
- **Before Application Deployment**: Ensure users exist before deploying applications
- **Environment Setup**: Standardize user creation across environments

## Monitoring and Maintenance

### Regular Tasks

- **Password Rotation**: Update user passwords according to security policies
- **Permission Review**: Regularly audit assigned roles and permissions
- **Unused Account Cleanup**: Remove accounts for decommissioned applications
- **Security Compliance**: Ensure user creation follows organizational policies

### Health Checks

- **Login Status**: Verify logins are not disabled or locked
- **Permission Validation**: Confirm users have appropriate access levels
- **Schema Access**: Verify users can access assigned schemas
- **Application Connectivity**: Test application connections with created users

## Best Practices

### Development Environment

- Use consistent naming conventions for users across environments
- Create dedicated schemas for different applications or modules
- Limit permissions to minimum required for development tasks
- Use automated scripts for consistent user creation

### Production Environment

- Implement proper change management for user creation
- Use service accounts rather than individual user accounts for applications
- Regular security audits of user permissions and roles
- Maintain documentation of all created users and their purposes

### Security Best Practices

- **Principle of Least Privilege**: Assign only necessary permissions
- **Service Account Management**: Use dedicated accounts for applications
- **Password Policies**: Enforce strong password requirements
- **Access Reviews**: Regular review of user access and permissions

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Current | Initial implementation with comprehensive role assignments |

## Support and Contributing

For issues, improvements, or questions:

1. Review the troubleshooting section above
2. Check Azure DevOps pipeline logs for detailed error information
3. Verify administrative permissions and connectivity
4. Test user creation manually before automation
5. Consider customizing role assignments based on security requirements

---

*This documentation covers the SQL user creation script with comprehensive role assignments and Azure DevOps integration.*