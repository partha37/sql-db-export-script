# Troubleshooting Guide

## Common Issues and Solutions

### Issue: "Import-Module : No match was found for the specified module 'sqlps'"

**Cause**: SQL Server Management Objects (SQLPS) module is not installed

**Solutions**:

1. **Install SQL Server Management Studio (SSMS)**
   - Download from: https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms
   - SSMS includes the SQLPS module
   - Restart PowerShell after installation

2. **Install SQL Server Express with Tools**
   - Download from: https://www.microsoft.com/en-us/sql-server/sql-server-downloads
   - Select "Express with Advanced Services"
   - Include Management Tools

3. **Verify Installation**
   ```powershell
   Get-Module -ListAvailable | grep sqlps
   ```

4. **If module is installed but not found**
   ```powershell
   Import-Module "C:\Program Files (x86)\Microsoft SQL Server\120\Tools\PowerShell\Modules\sqlps"
   ```

---

### Issue: "Failed to connect to SQL Server"

**Symptoms**:
- Connection timeout
- Login failed
- Server not found

**Debugging Steps**:

1. **Verify server name**
   ```powershell
   # Test ping
   Test-Connection -ComputerName "SERVER_NAME" -Count 1
   
   # List local SQL instances
   Get-SqlInstance
   ```

2. **Verify credentials**
   ```powershell
   # Test SQL Server connection directly
   $srv = new-object microsoft.sqlserver.management.smo.server("SERVER_NAME")
   $srv.ConnectionContext.LoginSecure = $false
   $srv.ConnectionContext.set_Login("sa")
   $srv.ConnectionContext.set_Password("password")
   
   try {
       $srv.ConnectionContext.Connect()
       Write-Host "Connection successful!"
       Write-Host "Server version: $($srv.Information.Version)"
   } catch {
       Write-Error "Connection failed: $_"
   }
   ```

3. **Check SQL Server status**
   - Windows Services: Search for "Services" → Look for "SQL Server (INSTANCENAME)"
   - Should be running
   - If not, start it manually

4. **Check SQL Server Browser service**
   ```powershell
   # For named instances, SQL Server Browser must be running
   Get-Service "SQLBrowser" | Start-Service
   ```

5. **Check firewall**
   ```powershell
   # SQL Server default port is 1433
   Test-NetConnection -ComputerName "SERVER_NAME" -Port 1433
   ```

6. **Enable SQL Server authentication**
   - Open SQL Server Management Studio
   - Right-click on server → Properties → Security
   - Change "Server authentication" to "SQL Server and Windows Authentication mode"
   - Restart SQL Server

---

### Issue: "Access to the path is denied"

**Cause**: No write permission to output directory

**Solutions**:

1. **Check directory permissions**
   ```powershell
   Get-Acl "D:\Backups" | Format-List
   ```

2. **Grant write permission**
   ```powershell
   # For current user
   $acl = Get-Acl "D:\Backups"
   $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
       [System.Security.Principal.WindowsIdentity]::GetCurrent().User,
       [System.Security.AccessControl.FileSystemRights]::FullControl,
       [System.Security.AccessControl.InheritanceFlags]::ContainerInherit,
       [System.Security.AccessControl.PropagationFlags]::InheritOnly,
       [System.Security.AccessControl.AccessControlType]::Allow
   )
   $acl.SetAccessRule($accessRule)
   Set-Acl -Path "D:\Backups" -AclObject $acl
   ```

3. **Use different output path**
   ```powershell
   # Use user's Documents folder
   $outputFilePath = "$env:USERPROFILE\Documents\DatabaseExport_$(Get-Date -Format 'dd-MM').sql"
   ```

4. **Create directory if it doesn't exist**
   ```powershell
   $outputDir = Split-Path $outputFilePath
   if (-not (Test-Path $outputDir)) {
       New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
   }
   ```

---

### Issue: "Cannot find database 'DatabaseName'"

**Cause**: Database doesn't exist or name is incorrect

**Solutions**:

1. **List available databases**
   ```powershell
   $srv = new-object microsoft.sqlserver.management.smo.server("SERVER_NAME")
   $srv.Databases | Select-Object Name | Sort-Object Name
   ```

2. **Check database name (case-sensitive)**
   ```powershell
   $db = $srv.Databases | Where-Object { $_.Name -eq "YourDatabaseName" }
   if ($null -eq $db) {
       Write-Error "Database not found"
   }
   ```

3. **Verify connectivity and permissions**
   ```powershell
   $srv.ConnectionContext.Connect()
   # User needs db_reader or higher role
   ```

---

### Issue: "No matching tables found"

**Symptoms**:
- `Total matched tables: 0`
- Script completes but no data exported

**Debugging**:

1. **Verify table naming pattern**
   ```powershell
   # List all tables in database
   $db.Tables | Select-Object Schema, Name | Sort-Object Schema, Name
   ```

2. **Check current filter pattern**
   ```powershell
   # Show what pattern you're using
   $pattern = '^Prod_'
   $matchedTables = $db.Tables | Where-Object { $_.Name -match $pattern }
   Write-Host "Pattern: $pattern"
   Write-Host "Matching tables: $($matchedTables.Count)"
   
   # Show matching tables
   $matchedTables | ForEach-Object { Write-Host "  - $($_.Schema).$($_.Name)" }
   ```

3. **Exclude system objects**
   ```powershell
   # Make sure you're not filtering out system tables unintentionally
   $matchedTables = $db.Tables | Where-Object { 
       -not $_.IsSystemObject -and 
       $_.Name -match '^Prod_'
   }
   ```

4. **Check table visibility**
   ```powershell
   # Some tables might be hidden
   $db.Tables | Where-Object { $_.Name -match '^Prod_' } | 
       Select-Object Schema, Name, IsSystemObject, CreateDate
   ```

---

### Issue: "Out of memory" error

**Cause**: Tables are too large or too many tables

**Solutions**:

1. **Reduce batch size**
   ```powershell
   $scripter.Options.BatchSize = 10  # Instead of 99
   ```

2. **Export fewer tables**
   ```powershell
   # Export only large tables separately
   $largeTableThresholdMB = 100
   $matchedTables = $db.Tables | Where-Object { 
       $_.Size -lt ($largeTableThresholdMB * 1024) -and
       $_.Name -match '^Prod_'
   }
   ```

3. **Export data only (skip schema)**
   ```powershell
   $scripter.Options.ScriptSchema = $false
   $scripter.Options.ScriptData = $true
   ```

4. **Run script with higher memory allocation**
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File "Export-SQLDatabases.ps1"
   ```

---

### Issue: Script runs slowly

**Cause**: Network latency, large tables, or inefficient options

**Solutions**:

1. **Check network connection**
   ```powershell
   # Test latency to SQL Server
   Measure-Command { $srv.ConnectionContext.Databases[0].Refresh() }
   ```

2. **Optimize scripting options**
   ```powershell
   # Disable unnecessary options
   $scripter.Options.Triggers = $false
   $scripter.Options.FullTextIndexes = $false
   $scripter.Options.ExtendedProperties = $false
   ```

3. **Reduce table selection**
   ```powershell
   # Export in batches
   $batchSize = 5
   $allTables = @($db.Tables | Where-Object { $_.Name -match '^Prod_' })
   
   for ($i = 0; $i -lt $allTables.Count; $i += $batchSize) {
       $batch = $allTables[$i..($i + $batchSize - 1)]
       # Process batch
   }
   ```

4. **Check disk I/O**
   ```powershell
   # Monitor disk performance during export
   Get-Counter -Counter "\PhysicalDisk(_Total)\% Disk Time"
   ```

---

### Issue: "ScriptData option is not recognized"

**Cause**: Incorrect property name or outdated SMO version

**Solution**:
```powershell
# Correct property name
$scripter.Options.ScriptData = $true  # Correct

# Check available options
$scripter.Options | Get-Member -MemberType Property | Select-Object Name
```

---

### Issue: File was created but is empty

**Cause**: Scripting failed silently or EnumScript didn't write to file

**Solutions**:

1. **Verify file path**
   ```powershell
   Write-Host "Output path: $outputFilePath"
   Test-Path $outputFilePath
   ```

2. **Check if tables exist**
   ```powershell
   if ($matchedTables.Count -eq 0) {
       Write-Error "No tables matched the filter"
       exit 1
   }
   ```

3. **Enable error capturing**
   ```powershell
   $ErrorActionPreference = "Continue"
   $scripter.Options.ContinueScriptingOnError = $true
   
   $script = $scripter.EnumScript($matchedTables)
   
   # Check if script variable has content
   if ([string]::IsNullOrEmpty($script)) {
       Write-Error "Script generation returned empty result"
   }
   ```

4. **Manual script writing**
   ```powershell
   if ([string]::IsNullOrEmpty($script)) {
       $script = $scripter.EnumScript($matchedTables)
   }
   
   $script | Out-File -FilePath $outputFilePath -Encoding UTF8 -Force
   ```

---

### Issue: "Login failed for user"

**Cause**: Wrong credentials or SQL Server authentication not enabled

**Solutions**:

1. **Verify credentials**
   ```powershell
   # Test in SSMS first
   # Login to SQL Server Management Studio with same credentials
   ```

2. **Enable SQL Server Authentication**
   - Open SQL Server Management Studio
   - Connect as Administrator
   - Right-click server → Properties
   - Security tab
   - Select "SQL Server and Windows Authentication mode"
   - Restart SQL Server

3. **Check user permissions**
   ```sql
   -- In SQL Server (run as admin)
   USE master
   CREATE LOGIN [username] WITH PASSWORD = 'password'
   GRANT CONTROL SERVER TO [username]
   ```

---

## Getting Help

If you encounter an issue not listed here:

1. **Check SQL Server logs**
   ```powershell
   # Locate SQL Server error log
   dir "C:\Program Files\Microsoft SQL Server\MSSQL*\MSSQL\LOG\ERRORLOG*"
   ```

2. **Enable PowerShell transcript**
   ```powershell
   Start-Transcript -Path "debug_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
   .\Export-SQLDatabases.ps1
   Stop-Transcript
   # Review the transcript for detailed error messages
   ```

3. **Check SQL Server SMO documentation**
   - https://docs.microsoft.com/en-us/sql/relational-databases/server-management-objects-smo/

4. **Report issue on GitHub**
   - Include PowerShell version: `$PSVersionTable`
   - Include SQL Server version
   - Include full error message
   - Include relevant configuration
