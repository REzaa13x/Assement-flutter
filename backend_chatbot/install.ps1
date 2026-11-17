param([Parameter(Mandatory=$true)][string]$BackendPath)
$ErrorActionPreference = 'Stop'
$backendRoot = (Resolve-Path -LiteralPath $BackendPath).Path
if (!(Test-Path -LiteralPath (Join-Path $backendRoot 'artisan'))) { throw 'Not a Laravel project.' }
foreach ($relative in @('app/Http/Controllers/Api/ChatbotController.php', 'tests/Feature/ChatbotApiTest.php')) {
    $target = Join-Path $backendRoot $relative
    if (Test-Path -LiteralPath $target) {
        Copy-Item -LiteralPath $target -Destination ($target + '.chatbot-backup-' + (Get-Date -Format 'yyyyMMddHHmmss'))
    }
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $relative) -Destination $target
}
$routePath = Join-Path $backendRoot 'routes/api.php'
$routes = [IO.File]::ReadAllText($routePath)
if (!$routes.Contains('ChatbotController::class')) {
    $routes += @'

// Public campaign information and DonGiv help, with per-client throttling.
Route::post('v1/chatbot/message', [\App\Http\Controllers\Api\ChatbotController::class, 'message'])
    ->middleware(['cors', 'throttle:20,1']);
'@
    [IO.File]::WriteAllText($routePath, $routes, (New-Object Text.UTF8Encoding($false)))
}
Push-Location -LiteralPath $backendRoot
try { php artisan route:clear } finally { Pop-Location }
