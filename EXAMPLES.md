# Usage Examples

## Basic Export

```powershell
.\Export-SQLDatabases.ps1
```

## Export with Logging

```powershell
$logFile = "C:\Logs\Export_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile

.\Export-SQLDatabases.ps1

Stop-Transcript
```

## Export Specific Tables Only

Modify the script to export only tables you need:

```powershell
# Instead of pattern matching, use specific table names
$tableNames = @("Users", "Orders", "Products")
$matchedTables = $db.Tables | Where-Object { $_.Name -in $tableNames }
```

## Export with Custom Output Path

```powershell
# Monthly backup
$month = Get-Date -Format "yyyy_MMMM"
$outputFilePath = "D:\Backups\Monthly\$month\database_dump.sql"

# Ensure directory exists
New-Item -ItemType Directory -Force -Path (Split-Path $outputFilePath) | Out-Null
```

## Export with Progress Reporting

```powershell
# Add progress reporting
$matchedTables = $db.Tables | Where-Object { $_.Name -match '^Prod_' }
$totalTables = $matchedTables.Count
$current = 0

Write-Host "Starting export of $totalTables tables..."

foreach ($table in $matchedTables) {
    $current++
    $percentComplete = ($current / $totalTables) * 100
    Write-Progress -Activity "Exporting Tables" -Status "$current of $totalTables" -PercentComplete $percentComplete
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Processing: $($table.Name)"
}
```

## Export with Compression

```powershell
# After generating SQL script, compress it
$script = $scripter.EnumScript($matchedTables)
$zipPath = "$outputFilePath.zip"

# Compress using .NET
[System.IO.Compression.ZipFile]::CreateFromDirectory(
    [System.IO.Path]::GetDirectoryName($outputFilePath),
    $zipPath
)

Write-Host "Compressed export to: $zipPath"
```

## Backup and Archive Old Files

```powershell
# Keep only last 30 days of exports
$exportDir = "D:\Backups"
$days = 30

Get-ChildItem -Path $exportDir -Filter "*.sql" | 
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$days) } |
    Remove-Item -Force

Write-Host "Cleaned up exports older than $days days"
```

## Export by Schema

```powershell
# Export only tables from specific schema
$schema = "dbo"
$matchedTables = $db.Tables | Where-Object { $_.Schema -eq $schema -and -not $_.IsSystemObject }

Write-Host "Exporting $($matchedTables.Count) tables from schema: $schema"
```

## Conditional Export Based on Table Properties

```powershell
# Export only large tables
$minSizeKB = 1024
$matchedTables = $db.Tables | Where-Object { $_.Size -gt $minSizeKB }

Write-Host "Exporting $($matchedTables.Count) tables larger than $minSizeKB KB"

# Or export only recently modified tables
$days = 7
$matchedTables = $db.Tables | Where-Object { $_.DateLastModified -gt (Get-Date).AddDays(-$days) }

Write-Host "Exporting $($matchedTables.Count) tables modified in last $days days"
```

## Parallel Export to Multiple Files

```powershell
# Export tables to separate files for parallel processing
$matchedTables = $db.Tables | Where-Object { $_.Name -match '^Prod_' }

foreach ($table in $matchedTables) {
    $tableOutputPath = "D:\Backups\$($table.Name)_$(Get-Date -Format 'dd-MM').sql"
    $scripter.Options.FileName = $tableOutputPath
    
    $script = $scripter.EnumScript(@($table))
    Write-Host "Exported: $($table.Name)"
}
```

## Export with Verification

```powershell
# After export, verify file was created and has content
$matchedTables = $db.Tables | Where-Object { $_.Name -match '^Prod_' }

Write-Host "[$(Get-Date -Format 'HH:mm')]`nScript Generation Started...`n"

$script = $scripter.EnumScript($matchedTables)

# Verify output
if (Test-Path $outputFilePath) {
    $fileSize = (Get-Item $outputFilePath).Length / 1MB
    Write-Host "[$(Get-Date -Format 'HH:mm')]`nExport completed successfully!`n"
    Write-Host "Output file: $outputFilePath"
    Write-Host "File size: $fileSize MB"
    Write-Host "Tables exported: $($matchedTables.Count)"
} else {
    Write-Error "Export file not created!"
}
```

## Export with Email Notification

```powershell
# Send completion notification
$smtpServer = "mail.yourdomain.com"
$from = "automation@yourdomain.com"
$to = "admin@yourdomain.com"
$subject = "Database Export Complete"

$body = @"
Database Export Completed Successfully

Database: $($db.Name)
Tables Exported: $($matchedTables.Count)
Output File: $outputFilePath
File Size: $((Get-Item $outputFilePath).Length / 1MB) MB
Timestamp: $(Get-Date)
"@

Send-MailMessage -SmtpServer $smtpServer -From $from -To $to -Subject $subject -Body $body
```

## Incremental Export (Changed Tables Only)

```powershell
# Track last export and only export changed tables
$lastExportFile = "D:\Backups\.last_export"
$lastExportTime = if (Test-Path $lastExportFile) { Get-Content $lastExportFile | Get-Date } else { Get-Date -Year 1900 }

$matchedTables = $db.Tables | Where-Object { 
    $_.Name -match '^Prod_' -and 
    $_.DateLastModified -gt $lastExportTime 
}

if ($matchedTables.Count -gt 0) {
    $script = $scripter.EnumScript($matchedTables)
    Get-Date | Out-File $lastExportFile -Force
    Write-Host "Incremental export completed: $($matchedTables.Count) tables"
} else {
    Write-Host "No changes detected since last export"
}
```

## Export with Table Statistics

```powershell
# Export and report table statistics
$matchedTables = $db.Tables | Where-Object { $_.Name -match '^Prod_' }

Write-Host "Export Statistics:"
Write-Host "=================="
Write-Host "Total tables: $($matchedTables.Count)"

$totalRows = ($matchedTables | Measure-Object -Property RowCount -Sum).Sum
$totalSize = ($matchedTables | Measure-Object -Property Size -Sum).Sum / 1MB

Write-Host "Total rows: $totalRows"
Write-Host "Total size: $totalSize MB"

# Export details for each table
$matchedTables | ForEach-Object {
    Write-Host "$($_.Schema).$($_.Name): Rows=$($_.RowCount), Size=$([math]::Round($_.Size / 1024, 2))MB"
}

$script = $scripter.EnumScript($matchedTables)
```
