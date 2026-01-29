param(
    [string]$ApiBaseUrl = "https://localhost:7191/api",
    [string]$Email = "bob.builder@example.com",
    [string]$Password = "pass1"
)

Write-Host "Running frontend smoke test script..." -ForegroundColor Cyan

$env:API_BASE_URL = $ApiBaseUrl
$env:SMOKE_EMAIL = $Email
$env:SMOKE_PASSWORD = $Password

$frontendPath = "C:\Users\mqondisi.zulu\source\repos\RealRealianceBank\RealReliance"
npm --prefix $frontendPath run smoke:api
