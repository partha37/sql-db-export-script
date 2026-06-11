# SQL Database Export Script

A PowerShell utility for exporting SQL Server database tables with schema and data to SQL scripts. This script automates the process of generating SQL dumps with timestamp-based file naming and flexible filtering options.

## Overview

This script connects to a SQL Server instance and exports database tables matching specific naming patterns to timestamped SQL files. It's designed to handle bulk exports of production database tables with comprehensive schema and data information.

## Features

- **SMO-Based Export**: Uses SQL Server Management Objects (SMO) for reliable database scripting
- **Pattern-Based Filtering**: Exports tables matching specific naming conventions (e.g., `Prod_*`)
- **Timestamped Output**: Automatically generates output filenames with date stamps
- **Comprehensive Schema Export**: Includes constraints, indexes, foreign keys, and data compression settings
- **Error Handling**: Configurable error handling during script generation
- **Data & Schema**: Exports both database schema definitions and data
- **Batch Processing**: Optimized batch settings for large-scale exports

## Prerequisites

- **PowerShell** 3.0 or higher
- **SQL Server Management Objects (SQLPS)** module installed
- **SQL Server** 2012 or later
- **Appropriate database permissions** on the target SQL Server instance
- Write access to the output directory

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/partha37/sql-db-export-script.git
   cd sql-db-export-script
   ```

2. Ensure SQLPS module is installed on your system

## Configuration

Before running the script, modify the following variables in `Export-SQLDatabases.ps1`:

### Server Connection
```powershell
$srv = new-object microsoft.sqlserver.management.smo.server("SERVER_NAME")
$srv.ConnectionContext.set_Login("USERNAME")
$srv.ConnectionContext.set_Password("PASSWORD")
```

### Database Selection
```powershell
$db = $srv.Databases["DATABASE_NAME"]
```

### Output Directory
```powershell
$outputFilePath = "D:\Backups\DatabaseExport_$timestamp.sql"
```

### Table Filtering
Modify the filter pattern to match your table naming conventions:
```powershell
$matchedTables = $db.Tables | Where-Object { $_.Name -match '^Prod_' }
```

## Usage

### Basic Execution
```powershell
.\Export-SQLDatabases.ps1
```

### With Transcript Logging
```powershell
Start-Transcript -Path "export_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
.\Export-SQLDatabases.ps1
Stop-Transcript
```

### Running as Scheduled Task
Create a scheduled task with:
- **Trigger**: Daily at specific time
- **Action**: `powershell.exe -ExecutionPolicy Bypass -File "C:\path\to\Export-SQLDatabases.ps1"`
- **Run with highest privileges**: Enabled (if needed)

## Output

The script generates SQL files in the format:
```
DatabaseExport_DD-MM.sql
```

Where `DD-MM` is replaced with the current date and month (e.g., `DatabaseExport_15-06.sql`)

### Output File Contents
- CREATE/DROP statements for table schema
- All table constraints (Primary Keys, Foreign Keys, Unique Keys)
- Index definitions
- Data compression settings
- Complete table data
- Extended properties

## Scripting Options Explained

| Option | Value | Purpose |
|--------|-------|----------|
| `ScriptData` | `$true` | Include table data in export |
| `ScriptSchema` | `$true` | Include table schema definitions |
| `DriAllConstraints` | `$true` | Export all referential integrity constraints |
| `Indexes` | `$true` | Include index definitions |
| `DriAll` | `$true` | Export all DRI (Declarative Referential Integrity) |
| `ScriptDataCompression` | `$true` | Include compression settings |
| `AnsiPadding` | `$false` | Disable ANSI padding in scripts |
| `Triggers` | `$false` | Exclude trigger definitions |
| `BatchSize` | `99` | Number of statements per batch |

## Troubleshooting

### Module Not Found
```
Error: Import-Module : No match was found for the specified module 'sqlps'
```
**Solution**: Install SQL Server Management Studio or SQL Server Express with Tools

### Connection Failed
```
Error: Failed to connect to server
```
**Checklist**:
- Verify server name is correct
- Confirm credentials have access
- Check network connectivity
- Ensure SQL Server Browser service is running

### Permission Denied on Output Path
```
Error: Access to path denied
```
**Solution**: Verify write permissions on the output directory

### Empty Table List
```
Error: Total matched tables: 0
```
**Solution**: Verify table naming pattern matches your actual tables

## Performance Considerations

- **Large Databases**: For databases with many tables, consider filtering by schema or specific tables
- **Network**: Place output directory on local drives for better performance
- **Batch Size**: Adjust `BatchSize` parameter based on table complexity
- **Scheduling**: Run during maintenance windows to minimize load

## Best Practices

1. **Version Control**: Keep exported scripts in version control
2. **Backups**: Test recovery procedures with generated scripts
3. **Encryption**: Don't commit scripts containing sensitive data to public repos
4. **Rotation**: Implement log rotation for timestamped exports
5. **Monitoring**: Track script execution time and file sizes
6. **Documentation**: Document any custom table filters or modifications

## Advanced Usage

### Custom Table Selection
```powershell
# Export only specific tables
$matchedTables = $db.Tables | Where-Object { $_.Name -in @("Table1", "Table2") }
```

### Conditional Export
```powershell
# Export only tables modified in the last 7 days
$matchedTables = $db.Tables | Where-Object { $_.DateLastModified -gt (Get-Date).AddDays(-7) }
```

### Error Logging
```powershell
$ErrorActionPreference = "Continue"
$scripter.Options.ContinueScriptingOnError = $true
# Errors will be logged to the output file
```

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test thoroughly with your SQL Server environment
4. Submit a pull request

## License

MIT License - See LICENSE file for details

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check existing documentation
- Review SQL Server SMO documentation: https://docs.microsoft.com/en-us/sql/relational-databases/server-management-objects-smo/

## Changelog

### v1.0.0
- Initial release
- SMO-based SQL export
- Pattern-based table filtering
- Timestamped file naming
- Comprehensive schema and data export

## Related Resources

- [SQL Server SMO Documentation](https://docs.microsoft.com/en-us/sql/relational-databases/server-management-objects-smo/)
- [PowerShell SQLPS Module](https://docs.microsoft.com/en-us/powershell/module/sqlps/)
- [SQL Server Best Practices](https://docs.microsoft.com/en-us/sql/sql-server/best-practices-for-sql-server-sql-server-2019)
