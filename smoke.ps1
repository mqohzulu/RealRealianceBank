param(
    [string]$ApiBaseUrl = "http://localhost:8080/api"
)

Write-Host "Running frontend smoke test script..." -ForegroundColor Cyan

$env:API_BASE_URL = $ApiBaseUrl

$frontendPath = "C:\Users\mqondisi.zulu\source\repos\RealRealianceBank\RealReliance"
npm --prefix $frontendPath run smoke:api
