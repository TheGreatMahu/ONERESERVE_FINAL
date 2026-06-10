#!/usr/bin/env pwsh
# ============================================================
#  OneReserve — Database Auto-Setup Script (Windows PowerShell)
#  Usage: .\setup_db.ps1
# ============================================================

$ErrorActionPreference = "Stop"
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptRoot

function Get-MySqlExecutable {
    $exe = Get-Command mysql.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue
    if (-not $exe) {
        $candidates = @(
            'C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe',
            'C:\Program Files\MySQL\MySQL Server 8.3\bin\mysql.exe',
            'C:\Program Files\MySQL\MySQL Server 8.2\bin\mysql.exe',
            'C:\Program Files\MySQL\MySQL Server 8.1\bin\mysql.exe',
            'C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe',
            'C:\Program Files\MySQL\MySQL Server 5.7\bin\mysql.exe'
        )
        foreach ($candidate in $candidates) {
            if (Test-Path $candidate) {
                $exe = $candidate
                break
            }
        }
    }
    if (-not $exe) {
        Write-Host "❌ mysql.exe not found on PATH or common MySQL install locations." -ForegroundColor Red
        exit 1
    }
    return $exe
}

$mysqlExe = Get-MySqlExecutable

$user = "root"
$pass = "Lopa02468"
$db = "onereserve"

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  OneReserve Database Auto-Setup" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

function Run-SqlFile {
    param(
        [string]$file,
        [string]$name,
        [int]$step
    )
    
    if (-not (Test-Path $file)) {
        Write-Host "❌ File not found: $file" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "► Step $step : $name..." -ForegroundColor Yellow
    try {
        $proc = Start-Process -FilePath $mysqlExe -ArgumentList "-u", $user, "-p$pass" -RedirectStandardInput $file -NoNewWindow -Wait -PassThru
        if ($proc.ExitCode -eq 0) {
            Write-Host "  ✅ Success" -ForegroundColor Green
        }
        else {
            Write-Host "  ❌ Failed (exit code $($proc.ExitCode))" -ForegroundColor Red
            exit $proc.ExitCode
        }
    }
    catch {
        Write-Host "  ❌ Error: $_" -ForegroundColor Red
        exit 1
    }
    Write-Host ""
}

# Verify MySQL is accessible
Write-Host "► Checking MySQL connection..." -ForegroundColor Yellow
try {
    $proc = Start-Process -FilePath $mysqlExe -ArgumentList "-u", $user, "-p$pass", "-e", "SELECT 1;" -RedirectStandardOutput "NUL" -RedirectStandardError "NUL" -NoNewWindow -Wait -PassThru
    if ($proc.ExitCode -eq 0) {
        Write-Host "  ✅ MySQL is accessible" -ForegroundColor Green
    }
    else {
        Write-Host "  ❌ Cannot connect to MySQL" -ForegroundColor Red
        exit $proc.ExitCode
    }
}
catch {
    Write-Host "  ❌ Error: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Import all SQL files in order
Run-SqlFile "$scriptRoot\sql\schema\01_schema.sql"            "Schema"          1
Run-SqlFile "$scriptRoot\sql\seeds\02_seed_core.sql"          "Core Data"       2
Run-SqlFile "$scriptRoot\sql\seeds\03_seed_hotels.sql"        "Hotels"          3
Run-SqlFile "$scriptRoot\sql\seeds\04_seed_users_bookings.sql" "Users & Bookings" 4
Run-SqlFile "$scriptRoot\sql\views\05_views.sql"              "Views"           5
Run-SqlFile "$scriptRoot\sql\triggers\06_triggers.sql"        "Triggers"        6
Run-SqlFile "$scriptRoot\sql\procedures\07_procedures.sql"    "Procedures"      7
Run-SqlFile "$scriptRoot\sql\functions\08_functions.sql"      "Functions"       8

# Verify data loaded
Write-Host "► Verifying seed data..." -ForegroundColor Yellow
$checkCmd = @"
mysql -u $user -p$pass -D $db -N -e "
  SELECT 
    CONCAT('Places: ', COUNT(*)) FROM places UNION ALL
    SELECT CONCAT('Schedules: ', COUNT(*)) FROM schedules UNION ALL
    SELECT CONCAT('Hotels: ', COUNT(*)) FROM hotels UNION ALL
    SELECT CONCAT('Room Types: ', COUNT(*)) FROM room_types UNION ALL
    SELECT CONCAT('Users: ', COUNT(*)) FROM users;
"
"@

$output = cmd.exe /c $checkCmd 2>$null
if ($output) {
    Write-Host "  ✅ Data verification:" -ForegroundColor Green
    $output | ForEach-Object { Write-Host "     $_" -ForegroundColor Green }
}
else {
    Write-Host "  ⚠️  Could not verify counts" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "✅ Database setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Activate Python venv:     .\.venv\Scripts\Activate.ps1" -ForegroundColor White
Write-Host "  2. Install dependencies:     pip install -r requirements.txt" -ForegroundColor White
Write-Host "  3. Start the Flask app:      python app.py" -ForegroundColor White
Write-Host "  4. Open browser:             http://127.0.0.1:5000" -ForegroundColor White
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
