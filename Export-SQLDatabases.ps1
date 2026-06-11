import-module sqlps 

$srv = new-object microsoft.sqlserver.management.smo.server("")
$srv.ConnectionContext.LoginSecure = $false
$srv.ConnectionContext.set_Login("")
$srv.ConnectionContext.set_Password("")
$srv.ConnectionContext.Connect()
$db = $srv.Databases[""]

# Get current date and month in dd-MM format
$timestamp = Get-Date -Format "dd-MM"

# Define the output file path with the timestamp
$outputFilePath = "D:\Backups\DatabaseExport_$timestamp.sql"

$scripter = new-object Microsoft.SqlServer.Management.Smo.Scripter ($srv)
$scripter.Options.AnsiPadding = $false
$scripter.Options.AppendToFile = $false
$scripter.Options.IncludeIfNotExists = $false
$scripter.Options.ContinueScriptingOnError = $false
$scripter.Options.ConvertUserDefinedDataTypesToBaseType = $true
$scripter.Options.WithDependencies = $false
$scripter.Options.IncludeHeaders = $true
$scripter.Options.DriIncludeSystemNames = $false
$scripter.Options.SchemaQualify = $true
$scripter.Options.Bindings = $false
$scripter.Options.NoCollation = $true
$scripter.Options.Default = $true
$scripter.Options.ScriptForCreateDrop = $true
$scripter.Options.ExtendedProperties = $true
$scripter.Options.LoginSid = $false
$scripter.Options.Permissions = $false
$scripter.Options.ScriptOwner = $false
$scripter.Options.Statistics = $false
$scripter.Options.ChangeTracking = $false
$scripter.Options.DriAllConstraints = $true
$scripter.Options.ScriptData = $true  
$scripter.Options.ScriptSchema = $true  
$scripter.Options.Indexes = $true 
$scripter.Options.DriAll = $true 
$scripter.Options.Triggers = $false 
$scripter.Options.ScriptDataCompression = $true
$scripter.Options.DriForeignKeys = $true
$scripter.Options.FullTextIndexes = $false
$scripter.Options.DriIndexes = $true
$scripter.Options.DriPrimaryKey = $true
$scripter.Options.DriUniqueKeys = $true
$scripter.Options.BatchSize=99
$scripter.Options.ScriptBatchTerminator=$true
$scripter.Options.NoCommandTerminator=$false
$scripter.Options.FileName=$outputFilePath

# Filter and collect matching tables
# Modify the regex pattern to match your table naming conventions
$matchedTables = $db.Tables | Where-Object { $_.Name -match '^Prod_' }
$totalTables = $matchedTables.Count

Write-Host "Total matched tables: $totalTables`n"

Write-Host "[$(Get-Date -Format 'HH:mm')]`nScript Generation Started.....Please Wait`n"

$script = $scripter.EnumScript($matchedTables)

Write-Host "[$(Get-Date -Format 'HH:mm')]`nAll matching tables have been processed."
