$ErrorActionPreference = 'Stop'
$backend = 'C:\Users\Lenovo\Downloads\DONGIV\TUBES-PABW-new - Salin'
$source = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)
$files = @(
    'app/Models/Review.php',
    'app/Http/Controllers/Api/ReviewController.php',
    'database/migrations/2026_11_17_000001_create_reviews_table.php',
    'resources/views/reviews/index.blade.php',
    'resources/views/reviews/board.blade.php',
    'tests/Feature/ReviewApiTest.php'
)
foreach ($file in $files) {
    $target = Join-Path $backend $file
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($target)) | Out-Null
    [System.IO.File]::WriteAllText($target, [System.IO.File]::ReadAllText((Join-Path $source $file)), $utf8)
}
$apiPath = Join-Path $backend 'routes/api.php'
$api = [System.IO.File]::ReadAllText($apiPath)
if (!$api.Contains('ReviewController::class')) {
    $api += @'

// Reviews shared by Flutter and the website.
Route::prefix('v1')->middleware('cors')->group(function () {
    Route::get('/reviews', [\App\Http\Controllers\Api\ReviewController::class, 'index']);
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/reviews/eligibility', [\App\Http\Controllers\Api\ReviewController::class, 'eligibility']);
        Route::post('/reviews', [\App\Http\Controllers\Api\ReviewController::class, 'store']);
        Route::put('/reviews/{review}', [\App\Http\Controllers\Api\ReviewController::class, 'update']);
        Route::delete('/reviews/{review}', [\App\Http\Controllers\Api\ReviewController::class, 'destroy']);
    });
});
'@
    [System.IO.File]::WriteAllText($apiPath, $api, $utf8)
}
$webPath = Join-Path $backend 'routes/web.php'
$web = [System.IO.File]::ReadAllText($webPath)
if (!$web.Contains("name('reviews.index')")) {
    $web += @'

// Website reviews use the same controller and storage with session authentication.
Route::get('/ulasan', fn () => view('reviews.index'))->name('reviews.index');
Route::get('/ulasan/data', [\App\Http\Controllers\Api\ReviewController::class, 'index']);
Route::middleware('auth')->group(function () {
    Route::get('/ulasan/eligibility', [\App\Http\Controllers\Api\ReviewController::class, 'eligibility']);
    Route::post('/ulasan', [\App\Http\Controllers\Api\ReviewController::class, 'store']);
    Route::put('/ulasan/{review}', [\App\Http\Controllers\Api\ReviewController::class, 'update']);
    Route::delete('/ulasan/{review}', [\App\Http\Controllers\Api\ReviewController::class, 'destroy']);
});
'@
    [System.IO.File]::WriteAllText($webPath, $web, $utf8)
}
$homePath = Join-Path $backend 'resources/views/home.blade.php'
$homeContent = [System.IO.File]::ReadAllText($homePath)
$start = $homeContent.IndexOf('    {{-- ===================== 8. TESTIMONI')
$end = $homeContent.IndexOf('    {{-- ===================== 9. VOLUNTEER CTA')
if ($start -ge 0 -and $end -gt $start) {
    $homeContent = $homeContent.Substring(0, $start) + "    @include('reviews.board', ['fullPage' => false])`r`n`r`n" + $homeContent.Substring($end)
    [System.IO.File]::WriteAllText($homePath, $homeContent, $utf8)
}
Write-Output 'Installed review model, migration, controller, website views, routes, and isolated tests.'
