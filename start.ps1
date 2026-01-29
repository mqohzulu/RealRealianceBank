Write-Host " Setting up RealReliance Banking..." -ForegroundColor Cyan

# 1. Go to RealRealianceBank folder
cd "C:\Users\mqondisi.zulu\source\repos\RealRealianceBank"

# 2. Create docker-compose.yml if not exists
if (!(Test-Path docker-compose.yml)) {
    Write-Host "Creating docker-compose.yml..." -ForegroundColor Yellow
    @"
services:
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    container_name: realreliance-sql
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=BankingApp@Secure123
    ports:
      - "1433:1433"
    volumes:
      - sqlserver-data:/var/opt/mssql
      - ./db-init.sql:/docker-entrypoint-initdb.d/init.sql

  api:
    build:
      context: ./RealRelianceBankingAPI-backEnd
    container_name: realreliance-api
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ConnectionStrings__SqlServer=Server=sqlserver;Database=RealRelianceManagementDB;User Id=sa;Password=BankingApp@Secure123;TrustServerCertificate=true
    ports:
      - "8080:8080"
    depends_on:
      - sqlserver

  frontend:
    build:
      context: ./RealReliance
    container_name: realreliance-ui
    ports:
      - "4200:4200"
    depends_on:
      - api

volumes:
  sqlserver-data:
"@ | Out-File docker-compose.yml -Encoding UTF8
}

# 3. Create db-init.sql if not exists
if (!(Test-Path db-init.sql)) {
    Write-Host "Creating db-init.sql..." -ForegroundColor Yellow
    @"
-- Simple database setup
CREATE DATABASE RealRelianceManagementDB;
GO
"@ | Out-File db-init.sql -Encoding UTF8
}

# 4. Stop any running containers
Write-Host "Stopping existing containers..." -ForegroundColor Yellow
docker-compose down 2>$null

# 5. Start everything
Write-Host "Building and starting services..." -ForegroundColor Green
docker-compose up --build -d

# 6. Wait for API
$apiBaseUrl = "http://localhost:8080/api"
$swaggerUrl = "http://localhost:8080/swagger/v1/swagger.json"

function Wait-ForApi {
    param(
        [string]$Url,
        [int]$Retries = 30,
        [int]$DelaySeconds = 2
    )
    for ($i = 1; $i -le $Retries; $i++) {
        try {
            Invoke-WebRequest -Uri $Url -Method Get -UseBasicParsing -TimeoutSec 5 | Out-Null
            return $true
        } catch {
            Start-Sleep -Seconds $DelaySeconds
        }
    }
    return $false
}

function Test-ApiEndpoint {
    param(
        [string]$Name,
        [string]$Method,
        [string]$Url,
        [object]$Body = $null,
        [hashtable]$Headers = $null
    )
    try {
        if ($Body -ne $null) {
            $json = $Body | ConvertTo-Json -Depth 5
            $response = Invoke-WebRequest -Uri $Url -Method $Method -Body $json -ContentType "application/json" -Headers $Headers -UseBasicParsing
        } else {
            $response = Invoke-WebRequest -Uri $Url -Method $Method -Headers $Headers -UseBasicParsing
        }
        Write-Host ("[OK] {0} -> {1}" -f $Name, $response.StatusCode) -ForegroundColor Green
        return $response
    } catch {
        $status = $_.Exception.Response.StatusCode.Value__ 2>$null
        if (-not $status) { $status = "no response" }
        Write-Host ("[FAIL] {0} -> {1}" -f $Name, $status) -ForegroundColor Red
        return $null
    }
}

Write-Host "Waiting for API to be ready..." -ForegroundColor Yellow
$apiReady = Wait-ForApi -Url $swaggerUrl
if (-not $apiReady) {
    Write-Host "API did not become ready in time. Check logs." -ForegroundColor Red
} else {
    Write-Host "API is ready. Running quick checks..." -ForegroundColor Green

    Test-ApiEndpoint -Name "Swagger" -Method "GET" -Url $swaggerUrl | Out-Null
    Test-ApiEndpoint -Name "Contact Test Email" -Method "GET" -Url "$apiBaseUrl/Contact/test-email" | Out-Null
    Test-ApiEndpoint -Name "Contact Submit" -Method "POST" -Url "$apiBaseUrl/Contact/submit" -Body @{ 
        Name = "Api Smoke Test"
        Email = "smoke@test.local"
        Subject = "Startup check"
        Message = "Testing contact endpoint from start.ps1"
    } | Out-Null

    # Auth + protected endpoints
    $randomEmail = ("smoke_{0}@test.local" -f ([guid]::NewGuid().ToString("N").Substring(0, 8)))
    $password = "Test@12345!"
    $register = Test-ApiEndpoint -Name "Auth Register" -Method "POST" -Url "$apiBaseUrl/Authentication/register" -Body @{ 
        Email = $randomEmail
        Password = $password
        FirstName = "Smoke"
        LastName = "Tester"
        Role = "Customer"
    }

    $login = Test-ApiEndpoint -Name "Auth Login" -Method "POST" -Url "$apiBaseUrl/Authentication/login" -Body @{ 
        Email = $randomEmail
        Password = $password
    }

    $token = $null
    if ($login -and $login.Content) {
        try {
            $loginJson = $login.Content | ConvertFrom-Json
            $token = $loginJson.token
        } catch {}
    }

    if ($token) {
        $authHeaders = @{ Authorization = "Bearer $token" }
        Test-ApiEndpoint -Name "Persons List" -Method "GET" -Url "$apiBaseUrl/Persons/GetPersons?activeOnly=true" -Headers $authHeaders | Out-Null
        Test-ApiEndpoint -Name "Accounts List" -Method "GET" -Url "$apiBaseUrl/Accounts/GetAccounts?activeOnly=true" -Headers $authHeaders | Out-Null
        Test-ApiEndpoint -Name "Transactions List" -Method "GET" -Url "$apiBaseUrl/Transaction/GetTransactions?activeOnly=false" -Headers $authHeaders | Out-Null
    } else {
        Write-Host "Skipping protected endpoint checks (no auth token)." -ForegroundColor Yellow
    }
}

# 7. Show status
Write-Host "`n Container Status:" -ForegroundColor Cyan
docker-compose ps

Write-Host "`n Access URLs:" -ForegroundColor Cyan
Write-Host "- SQL Server: localhost:1433" -ForegroundColor Gray
Write-Host "- API: http://localhost:8080/swagger" -ForegroundColor Gray
Write-Host "- Angular: http://localhost:4200" -ForegroundColor Gray

Write-Host "`n View logs: docker-compose logs -f" -ForegroundColor Yellow
Write-Host " Stop all: docker-compose down" -ForegroundColor Yellow
