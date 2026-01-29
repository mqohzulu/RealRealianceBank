param(
    [string]$ApiBaseUrl = "https://localhost:7191/api"
)

Write-Host "Running frontend smoke test script..." -ForegroundColor Cyan

$env:API_BASE_URL = $ApiBaseUrl

$frontendPath = "C:\Users\mqondisi.zulu\source\repos\RealRealianceBank\RealReliance"
npm --prefix $frontendPath run smoke:api
