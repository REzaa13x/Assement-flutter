$ErrorActionPreference = 'Stop'
$backend = 'C:\Users\Lenovo\Downloads\DONGIV\TUBES-PABW-new - Salin'
$utf8 = New-Object Text.UTF8Encoding($false)
$files = @(
    'app/Http/Controllers/Api/CampaignController.php',
    'app/Http/Controllers/Api/CampaignLocationController.php',
    'app/Http/Controllers/CampaignController.php',
    'app/Http/Resources/CampaignResource.php',
    'app/Models/Campaign.php',
    'app/Services/CampaignGeocodingService.php',
    'config/maps.php',
    'database/migrations/2026_11_17_000002_add_campaign_submission_location.php',
    'tests/Feature/CampaignSubmissionTest.php',
    'resources/views/admin/campaigns/submission-details.blade.php'
)
foreach ($file in $files) {
    $target = Join-Path $backend $file
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
    [IO.File]::WriteAllText($target, [IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)), $utf8)
}
$path = Join-Path $backend 'routes/api.php'
$routes = [IO.File]::ReadAllText($path)
if (!$routes.Contains("'/locations/search'")) {
    $routes += @'

// Address lookup for authenticated campaign applicants. The provider is cached/rate-limited globally.
Route::prefix('v1')->middleware(['cors', 'auth:sanctum', 'throttle:30,1'])->group(function () {
    Route::get('/locations/search', [\App\Http\Controllers\Api\CampaignLocationController::class, 'search']);
    Route::get('/locations/reverse', [\App\Http\Controllers\Api\CampaignLocationController::class, 'reverse']);
});
'@
    [IO.File]::WriteAllText($path, $routes, $utf8)
}
Write-Output 'Campaign submission API and geocoding installed. Apply only the new additive migration after tests.'
$viewPath = Join-Path $backend 'resources/views/admin/campaigns/show.blade.php'
$viewContent = [IO.File]::ReadAllText($viewPath)
if (!$viewContent.Contains("@include('admin.campaigns.submission-details')")) {
    $viewContent = $viewContent.Replace('        <p class="mb-2"><strong>Kategori:', "        @include('admin.campaigns.submission-details')`n        <p class=`"mb-2`"><strong>Kategori:")
    [IO.File]::WriteAllText($viewPath, $viewContent, $utf8)
}
