

function Write-AzureDevOpsLog {
    <#
    .SYNOPSIS
        Writes Azure DevOps logging commands
    .DESCRIPTION
        Standardized function for Azure DevOps pipeline logging
    #>
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("section", "warning", "error", "command", "debug")]
        [string]$LogType,
        
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [string]$VariableName,
        
        [Parameter(Mandatory=$false)]
        [string]$VariableValue,
        
        [Parameter(Mandatory=$false)]
        [bool]$IsOutput = $false
    )

    switch ($LogType) {
        "section" { 
            Write-Host "##[section]$Message" 
        }
        "warning" { 
            Write-Host "##[warning]$Message" 
        }
        "error" { 
            Write-Host "##[error]$Message" 
        }
        "command" { 
            Write-Host "##[command]$Message" 
        }
        "debug" { 
            Write-Host "##[debug]$Message" 
        }
    }
    
    if ($VariableName -and $VariableValue) {
        $outputFlag = if ($IsOutput) { ";isOutput=true" } else { "" }
        Write-Host "##vso[task.setvariable variable=$VariableName$outputFlag]$VariableValue"
    }
}


# Create a new SQL connection string
function New-SqlConnectionString {
    <#
    .SYNOPSIS
        Creates a SQL Server connection string with validation
    .DESCRIPTION
        Builds and validates a SQL Server connection string with proper error handling
    #>
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerInstance,
        
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$Database = "master",
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Password,
        
        [Parameter(Mandatory=$false)]
        [bool]$TrustServerCertificate = $true,
        
        [Parameter(Mandatory=$false)]
        [int]$ConnectionTimeout = 30
    )

    try {
        # Build connection string with all parameters
        $connectionString = "Server=$ServerInstance;Database=$Database;User Id=$Username;Password=$Password"
        
        if ($TrustServerCertificate) {
            $connectionString += ";TrustServerCertificate=True"
        }
        
        if ($ConnectionTimeout -gt 0) {
            $connectionString += ";Connection Timeout=$ConnectionTimeout"
        }

        # Validate connection string format
        if ($connectionString -notmatch "Server=.+;Database=.+;User Id=.+;Password=.+") {
            throw "Invalid connection string format"
        }

        Write-Verbose "Connection string created successfully for server: $ServerInstance"
        # Write-Host "Connection string: $connectionString"
        return $connectionString
    }
    catch {
        Write-Error "Failed to create connection string: $($_.Exception.Message)"
        throw
    }
}

# Executes a SQL query
function Invoke-SqlQuery {
    <#
    .SYNOPSIS
        Executes a SQL query with enhanced error handling
    .DESCRIPTION
        Executes SQL queries with comprehensive error handling and optional debugging
    #>
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ConnectionString,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Query,
        
        [Parameter(Mandatory=$false)]
        [int]$QueryTimeout = 30,
        
        [Parameter(Mandatory=$false)]
        [bool]$ShowQuery = $false,
        
        [Parameter(Mandatory=$false)]
        [bool]$SuppressOutput = $false
    )

    try {
        if ($ShowQuery) {
            Write-Host "Executing SQL Query:" -ForegroundColor Yellow
            Write-Host $Query -ForegroundColor Gray
            Write-Host ""
        }
        
        Write-Verbose "Executing SQL query with timeout: $QueryTimeout seconds"
        
        # Execute the SQL query
        $result = Invoke-Sqlcmd -ConnectionString $ConnectionString -Query $Query -QueryTimeout $QueryTimeout -ErrorAction Stop -Verbose
        
        if (-not $SuppressOutput) {
            $rowCount = if ($result) { $result.Count } else { 0 }
            Write-Verbose "Query executed successfully. Rows affected/returned: $rowCount"
           
        }
        $status = $true
        
        # Create a custom object for return values
        $reply = [PSCustomObject]@{
            Status = $status
            Result = $result
        }
        
        return $reply
    }
    catch {
        Write-Error "Failed to execute SQL query: $($_.Exception.Message)"
        if ($ShowQuery) {
            Write-Host "Failed Query:" -ForegroundColor Red
            Write-Host $Query -ForegroundColor Gray
        }
        Write-AzureDevOpsLog -LogType "error" -Message "SQL Query Execution Failed: $($_.Exception.Message)"
        $status = $false
        # Create a custom object for return values
        $reply = [PSCustomObject]@{
            Status = $status
            Result = $_.Exception.Message
        }
        throw
        return $reply
    }
}


function Test-SqlConnection {
    <#
    .SYNOPSIS
        Tests a SQL Server connection
    .DESCRIPTION
        Validates that a SQL Server connection string is working and accessible
    #>
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ConnectionString,
        
        [Parameter(Mandatory=$false)]
        [int]$TestTimeout = 10
    )

    try {
        Write-Verbose "Testing SQL connection..."
        
        # Test the SQL connection with a simple query
        $testQuery = "SELECT SERVERPROPERTY('ServerName') AS ServerName, DB_NAME() AS DatabaseName"
        $result = Invoke-SqlQuery -ConnectionString $ConnectionString -Query $testQuery -QueryTimeout $TestTimeout -ErrorAction Stop

        if ($result) {
            Write-Verbose "Connection successful to server: $($result.ServerName), database: $($result.DatabaseName)"
            return $true
        }
        else {
            Write-Warning "Connection test returned no results"
            return $false
        }
    }
    catch {
        Write-Warning "SQL Connection test failed: $($_.Exception.Message)"
        Write-AzureDevOpsLog -LogType "error" -Message "SQL Connection Test Failed: $($_.Exception.Message)"
        return $false
    }
}

# Create a new SQL credential for Azure Storage on SQL Server
function New-SqlCredential {
    <#
    .SYNOPSIS
        Creates or updates a SQL Server credential for Azure Storage
    .DESCRIPTION
        Creates or updates a SQL Server credential with proper error handling and Azure DevOps integration
    #>
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ConnectionString,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$StorageAccountName,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$StorageAccountKey,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$CredentialName,
        
        [Parameter(Mandatory=$false)]
        [bool]$EnableAzureDevOpsLogging = $true
    )

    try {
        Write-Host "Creating SQL Credential for Azure Storage in SQL Server..." -ForegroundColor Yellow
        Write-Verbose "Creating credential: $CredentialName for storage account: $StorageAccountName"

        # # Validate inputs
        # if ($StorageAccountName -notmatch '^[a-z0-9]{3,24}$') {
        #     throw "Invalid storage account name format. Must be 3-24 lowercase alphanumeric characters."
        # }

        # Create SQL Credential query
        $createCredentialQuery = @"
IF NOT EXISTS (SELECT * FROM sys.credentials WHERE name = '$CredentialName')
BEGIN
    CREATE CREDENTIAL [$CredentialName]
    WITH IDENTITY = '$StorageAccountName',
    SECRET = '$StorageAccountKey'
    PRINT 'Credential [$CredentialName] created successfully'
END
ELSE
BEGIN
    ALTER CREDENTIAL [$CredentialName]
    WITH IDENTITY = '$StorageAccountName',
    SECRET = '$StorageAccountKey'
    PRINT 'Credential [$CredentialName] updated successfully'
END
"@
        
        # Execute the credential creation/update
        Invoke-SqlQuery -ConnectionString $ConnectionString -Query $createCredentialQuery -QueryTimeout 0 -suppressOutput $true
        
        Write-Host "Azure Storage credential configured successfully" -ForegroundColor Green
        
        if ($EnableAzureDevOpsLogging) {
            Write-Host "##[section]Azure Storage credential created/updated successfully"
            
        }
        
        Write-Verbose "SQL Credential operation completed successfully"
    }
    catch {
        $errorMsg = "Failed to create Azure Storage credential: $($_.Exception.Message)"
        Write-Error $errorMsg
        
        if ($EnableAzureDevOpsLogging) {
            # Write-Host "##vso[task.setvariable variable=CredentialCreationSuccess;isOutput=true]false"
            Write-Host "##vso[task.complete result=Failed;]Credential creation failed"
            Write-AzureDevOpsLog -LogType "error" -Message $errorMsg
        }
        
        throw
    }
}

function Test-DatabaseExists {
    <#
    .SYNOPSIS
        Checks if a database exists on the SQL Server
    .DESCRIPTION
        Verifies whether a specified database exists on the SQL Server instance
    #>
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ConnectionString,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$DatabaseName
    )

    try {
        Write-Verbose "Checking if database '$DatabaseName' exists..."
        
        $query = "SELECT name FROM sys.databases WHERE name = '$DatabaseName'"
        $result = Invoke-SqlQuery -ConnectionString $ConnectionString -Query $query -SuppressOutput $true
        
        foreach ($r in $result.result) {
            Write-Host "Found database: $($r.name)" -ForegroundColor Green
        }

        $exists = ($result.result -ne $null -and $result.status -eq $true)
        Write-Verbose "Database '$DatabaseName' exists: $exists"

        return $exists
    }
    catch {
        Write-Error "Failed to check database existence: $($_.Exception.Message)"
        Write-AzureDevOpsLog -LogType "error" -Message "Failed to check database existence: $($_.Exception.Message)"
        throw
    }
}

# Create SQL Login in the database server
function New-SqlLogin {
    <#
    .SYNOPSIS
        Creates a SQL Login in the database server
    .DESCRIPTION
        Creates a SQL Login with proper error handling and Azure DevOps integration
    #>
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ConnectionString,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$LoginName,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$LoginPassword
    )

    try {
        Write-Host "Creating SQL Login '$LoginName' in the database server..." -ForegroundColor Yellow
        Write-Verbose "Creating login: $LoginName"

        # Create SQL Login query
        $createLoginQuery = @"
    IF NOT EXISTS (
        SELECT 1 
        FROM sys.server_principals 
        WHERE name = '$LoginName' AND type IN ('S', 'U', 'G') -- S: SQL user, U: Windows user, G: Windows group
    )
    BEGIN
        PRINT 'Creating login $LoginName in [$db_server_name]';
        CREATE LOGIN [$LoginName] WITH PASSWORD = '$LoginPassword', CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF, default_database = [$db_name];

    END
    ELSE
    BEGIN
        PRINT 'Login $LoginName already exists in [$db_server_name]';
        -- THROW 50001, 'Login $LoginName already exists.', 1; -- Custom error to indicate existing login
    END
"@
        # Execute the login creation query
        $reply = Invoke-SqlQuery -ConnectionString $ConnectionString -Query $createLoginQuery -QueryTimeout 0 -ErrorAction Stop

        Write-Host "SQL Login '$LoginName' created successfully." -ForegroundColor Green
        Write-AzureDevOpsLog -LogType "Section" -Message "SQL Login '$LoginName' created successfully."
        Write-Host " "
        

    }
    catch {
        Write-Error "Failed to create SQL Login '$LoginName': $_"
        Write-AzureDevOpsLog -LogType "error" -Message "Failed to create SQL Login '$LoginName': $_"
        throw
    }
}


# Create Login in the specified database
function New-SqlUserInDatabase {
    <#
    .SYNOPSIS
        Creates a SQL User in the specified database
    .DESCRIPTION
        Creates a SQL User mapped to an existing Login with the same name in the specified database and maps to the specified schema
    #>
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ConnectionString,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$DatabaseName,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$LoginName,
        
        [Parameter(Mandatory=$true)]
        [string]$Schema = "dbo"
    )

    try {
        Write-Host "Creating SQL User '$LoginName' in database '$DatabaseName'..." -ForegroundColor Yellow
        Write-Verbose "Creating user: $LoginName mapped to login: $LoginName in database: $DatabaseName"

        # Create SQL User query
        $createUserQuery = @"
USE [$DatabaseName];
IF NOT EXISTS (
    SELECT 1 
    FROM sys.database_principals 
    WHERE name = '$LoginName' AND type IN ('S', 'U', 'G') -- S: SQL user, U: Windows user, G: Windows group
)
BEGIN
    PRINT 'Creating user $UserName in database [$DatabaseName]';
    CREATE USER [$LoginName] FOR LOGIN [$LoginName] WITH DEFAULT_SCHEMA=[$Schema];
END
ELSE
BEGIN
    PRINT 'User $LoginName already exists in database [$DatabaseName]';
    
END
"@

        # Execute the user creation query
        $reply = Invoke-SqlQuery -ConnectionString $ConnectionString -Query $createUserQuery -QueryTimeout 0 -ErrorAction Stop

        Write-Host "SQL User '$LoginName' created successfully in database '$DatabaseName'." -ForegroundColor Green
        Write-AzureDevOpsLog -LogType "Section" -Message "SQL User '$LoginName' created successfully in database '$DatabaseName'."
        Write-Host " "

    }
    catch {
        Write-Error "Failed to create SQL User '$LoginName' in database '$DatabaseName': $_"
        Write-AzureDevOpsLog -LogType "error" -Message "Failed to create SQL User '$LoginName' in database '$DatabaseName': $_"
        throw
    }
}

# Add Database Role Membership to a SQL User
function Add-SqlUserToDatabaseRoles {
    <#
    .SYNOPSIS
        Adds a SQL User to a database role
    .DESCRIPTION
        Adds an existing SQL User to a specified database role with proper error handling and Azure DevOps integration
    #>
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ConnectionString,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$DatabaseName,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$UserName
        
    )

    try {
        Write-Host "Adding SQL User '$UserName' to database roles in database '$DatabaseName'..." -ForegroundColor Yellow
        Write-Verbose "Adding user: $UserName to database roles in database: $DatabaseName"

        # Create SQL query to add user to role
        $addUserToRoleQuery = @"
USE [$DatabaseName];
IF EXISTS (
SELECT 1 FROM sys.database_principals WHERE name = '$UserName' AND type IN ('S', 'U', 'G') )
    BEGIN
        PRINT 'User $UserName exists in [$DatabaseName]';
        
        PRINT 'Add db_owner role to user $UserName';
        EXEC sp_addrolemember N'db_owner', N'$UserName';

        PRINT 'Add db_securityadmin role to user $UserName';
        EXEC sp_addrolemember N'db_securityadmin', N'$UserName';

        PRINT 'Add db_accessadmin role to user $UserName';
        EXEC sp_addrolemember N'db_accessadmin', N'$UserName';

        PRINT 'Add db_datareader role to user $UserName';
        EXEC sp_addrolemember N'db_datareader', N'$UserName';
        
        PRINT 'Add db_datawriter role to user $UserName';
        EXEC sp_addrolemember N'db_datawriter', N'$UserName';

        PRINT 'Add db_ddladmin role to user $UserName';
        EXEC sp_addrolemember N'db_ddladmin', N'$UserName';

        PRINT 'Add db_backupoperator role to user $UserName';
        EXEC sp_addrolemember N'db_backupoperator', N'$UserName';

        PRINT 'Add SecurityAdmin server role to user $UserName';
        EXEC sp_addsrvrolemember @loginame = N'$UserName', @rolename = N'SecurityAdmin';
    END
    ELSE
    BEGIN
        PRINT 'User $UserName does Not exists in [$DatabaseName]';
    END

"@
        # Execute the add user to role query
        $reply = Invoke-SqlQuery -ConnectionString $ConnectionString -Query $addUserToRoleQuery -QueryTimeout 0 -ErrorAction Stop

        Write-Host "SQL User '$UserName' added to database roles successfully in database '$DatabaseName'." -ForegroundColor Green
        Write-AzureDevOpsLog -LogType "Section" -Message "SQL User '$UserName' added to database roles successfully in database '$DatabaseName'."
        Write-Host " "

    }
    catch {
        Write-Error "Failed to add SQL User '$UserName' to database roles in database '$DatabaseName': $_"
        Write-AzureDevOpsLog -LogType "error" -Message "Failed to add SQL User '$UserName' to database roles in database '$DatabaseName': $_"
        throw
    }
}


# Export all functions for use in other scripts
Export-ModuleMember -Function New-SqlConnectionString, Test-SqlConnection, Invoke-SqlQuery, New-SqlCredential, Test-DatabaseExists, Write-AzureDevOpsLog, New-SqlLogin, New-SqlUserInDatabase, Add-SqlUserToDatabaseRoles