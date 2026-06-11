# Configuration Guide

## Detailed Setup Instructions

### 1. Server Connection Configuration

```powershell
# Basic Authentication (Recommended for most scenarios)
$srv = new-object microsoft.sqlserver.management.smo.server("SERVER_NAME")
$srv.ConnectionContext.LoginSecure = $false
$srv.ConnectionContext.set_Login("sa")  # or your username
$srv.ConnectionContext.set_Password("YourPassword")

# Windows Authentication
$srv = new-object microsoft.sqlserver.management.smo.server("SERVER_NAME")
$srv.ConnectionContext.LoginSecure = $true  # Uses Windows credentials
```

### 2. Server Name Options

```powershell
# Local instance
$srv = new-object microsoft.sqlserver.management.smo.server(".")

# Named instance
$srv = new-object microsoft.sqlserver.management.smo.server("SERVER_NAME\SQLEXPRESS")

# Remote server with TCP port
$srv = new-object microsoft.sqlserver.management.smo.server("192.168.1.100,1433")

# Using Server alias
$srv = new-object microsoft.sqlserver.management.smo.server("PROD_DB_01")
```

### 3. Database Selection

```powershell
# Get available databases
$srv.Databases | Select-Object Name

# Connect to specific database
$db = $srv.Databases["YourDatabaseName"]

# Verify connection
if ($db -eq $null) {
    Write-Error "Database not found"
}
```

### 4. Table Filtering Patterns

#### Match Multiple Table Prefixes
```powershell
$matchedTables = $db.Tables | Where-Object { $_.Name -match '^Prod_' }
```

#### Match Specific Schema
```powershell
$matchedTables = $db.Tables | Where-Object { $_.Schema -eq 'dbo' -and $_.Name -match '^Prod_' }
```

#### Exclude System Tables
```powershell
$matchedTables = $db.Tables | Where-Object { $_.IsSystemObject -eq $false -and $_.Name -match '^Prod_' }
```

#### Match by Size
```powershell
$matchedTables = $db.Tables | Where-Object { $_.Size -gt 1024 }  # Tables larger than 1MB
```

#### Match by Modification Date
```powershell
$matchedTables = $db.Tables | Where-Object { $_.DateLastModified -gt (Get-Date).AddDays(-30) }
```

### 5. Output File Configuration

```powershell
# With timestamp (recommended)
$timestamp = Get-Date -Format "dd-MM-yyyy_HHmmss"
$outputFilePath = "D:\Backups\Database_$timestamp.sql"

# With database name
$outputFilePath = "D:\Backups\$($db.Name)_$(Get-Date -Format 'yyyyMMdd').sql"

# With server name
$outputFilePath = "D:\Backups\$($srv.Name)_$timestamp.sql"
```

### 6. Scripting Options

#### Data-Only Export
```powershell
$scripter.Options.ScriptData = $true
$scripter.Options.ScriptSchema = $false
$scripter.Options.DriAllConstraints = $false
$scripter.Options.Indexes = $false
```

#### Schema-Only Export
```powershell
$scripter.Options.ScriptData = $false
$scripter.Options.ScriptSchema = $true
$scripter.Options.DriAllConstraints = $true
$scripter.Options.Indexes = $true
```

#### Minimal Export (Structure only)
```powershell
$scripter.Options.ScriptData = $false
$scripter.Options.ScriptSchema = $true
$scripter.Options.Indexes = $false
$scripter.Options.DriAllConstraints = $true
```

#### Complete Export (All options)
```powershell
$scripter.Options.ScriptData = $true
$scripter.Options.ScriptSchema = $true
$scripter.Options.Indexes = $true
$scripter.Options.DriAllConstraints = $true
$scripter.Options.Triggers = $true
$scripter.Options.FullTextIndexes = $true
$scripter.Options.ExtendedProperties = $true
```

### 7. Batch and Performance Options

```powershell
# For large tables (slower, more memory)
$scripter.Options.BatchSize = 500

# For standard processing (balanced)
$scripter.Options.BatchSize = 99

# For small exports or memory-constrained systems
$scripter.Options.BatchSize = 10
```

### 8. Error Handling Configuration

```powershell
# Stop on first error
$scripter.Options.ContinueScriptingOnError = $false

# Continue on errors (recommended for large exports)
$scripter.Options.ContinueScriptingOnError = $true

# Add error handling wrapper
try {
    $script = $scripter.EnumScript($matchedTables)
} catch {
    Write-Error "Scripting failed: $_"
    exit 1
}
```

## Environment Variables

You can use environment variables for sensitive data:

```powershell
# Set environment variables before running script
$env:SQL_SERVER = "SERVER_NAME"
$env:SQL_USER = "username"
$env:SQL_PASSWORD = "password"
$env:SQL_DATABASE = "DatabaseName"
$env:OUTPUT_PATH = "D:\Backups"

# Use in script
$srv = new-object microsoft.sqlserver.management.smo.server($env:SQL_SERVER)
$srv.ConnectionContext.set_Login($env:SQL_USER)
$srv.ConnectionContext.set_Password($env:SQL_PASSWORD)
$db = $srv.Databases[$env:SQL_DATABASE]
```

## Scheduled Task Configuration

### PowerShell Script for Scheduled Task
```powershell
# Create scheduled task
$taskName = "SQL_Database_Export"
$scriptPath = "C:\Scripts\Export-SQLDatabases.ps1"
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `\"$scriptPath`\""
$trigger = New-ScheduledTaskTrigger -Daily -At 2:00AM
$settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -StartWhenAvailable
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest
```

## Troubleshooting Configuration

### Verify Configuration
```powershell
# Test server connection
$srv.Information.Version

# Test database access
$db.Tables.Count

# List all tables matching filter
$matchedTables = $db.Tables | Where-Object { $_.Name -match '^Prod_' }
Write-Host "Tables to export: $($matchedTables.Count)"
$matchedTables | ForEach-Object { Write-Host "  - $($_.Schema).$($_.Name)" }
```

### Connection Troubleshooting
```powershell
# Enable detailed error messages
$ErrorActionPreference = "Stop"

# Test with explicit error handling
try {
    $srv.ConnectionContext.Connect()
    Write-Host "Connection successful"
} catch {
    Write-Error "Connection failed: $($_.Exception.Message)"
    exit 1
}
```
