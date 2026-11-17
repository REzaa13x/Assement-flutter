param([Parameter(Mandatory=$true)][string]$BackendPath)
$ErrorActionPreference = 'Stop'
$backendRoot = (Resolve-Path -LiteralPath $BackendPath).Path
if (!(Test-Path -LiteralPath (Join-Path $backendRoot 'artisan'))) { throw 'Not a Laravel project.' }
$utf8 = New-Object Text.UTF8Encoding($false)
$routePath = Join-Path $backendRoot 'routes/api.php'
$routes = [IO.File]::ReadAllText($routePath)
$controller = '\App\Http\Controllers\Api\CampaignLocationController::class'
$added = @()
foreach ($action in @('search','reverse','revese')) {
    if (!$routes.Contains("'/locations/$action'")) {
        $method = if ($action -eq 'revese') { 'reverse' } else { $action }
        $added += "    Route::get('/locations/$action', [$controller, '$method']);"
    }
}
if ($added.Count -gt 0) {
    $routes += "`nRoute::prefix('v1')->middleware(['cors', 'auth:sanctum', 'throttle:30,1'])->group(function () {`n" + ($added -join "`n") + "`n});`n"
    [IO.File]::WriteAllText($routePath, $routes, $utf8)
}
Push-Location -LiteralPath $backendRoot
try { php artisan route:clear } finally { Pop-Location }
Write-Output "Location routes checked: search, reverse, revese. Existing routes preserved."
