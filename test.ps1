# test.ps1 - Run after setup
Write-Host " Testing RealReliance Services..." -ForegroundColor Cyan

function Test-Service {
    param($Name, $Url, $Timeout = 10)
    
    Write-Host "`nTesting $Name..." -ForegroundColor Yellow
    Write-Host "URL: $Url" -ForegroundColor Gray
    
    try {
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec $Timeout -ErrorAction Stop
        Write-Host " $Name is UP (Status: $($response.StatusCode))" -ForegroundColor Green
        return $true
    } catch {
        Write-Host " $Name is DOWN or starting..." -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor DarkGray
        return $false
    }
}

# Test SQL Server (indirectly via API)
Write-Host "`n1. Checking SQL Server via API health..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://localhost:8080/health" -TimeoutSec 15
    Write-Host " SQL Server connection via API: $($health.status)" -ForegroundColor Green
} catch {
    Write-Host " SQL Server might still be starting..." -ForegroundColor Yellow
}

# Test API
Test-Service -Name "API" -Url "http://localhost:8080/swagger" -Timeout 20

# Test Angular
Test-Service -Name "Angular" -Url "http://localhost:4200" -Timeout 30

# Show container logs
Write-Host "`n Recent logs:" -ForegroundColor Cyan
docker-compose logs --tail=10

Write-Host "`n Testing complete! If services show '❌', wait 1-2 minutes and run again." -ForegroundColor Green