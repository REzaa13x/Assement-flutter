$ErrorActionPreference = 'Stop'
$backend = 'C:\Users\Lenovo\Downloads\DONGIV\TUBES-PABW-new - Salin'
$utf8 = New-Object Text.UTF8Encoding($false)
$files = @(
    'app/Http/Controllers/Api/CertificateController.php',
    'app/Http/Controllers/Api/CertificateFileController.php',
    'app/Http/Controllers/CertificateController.php',
    'app/Services/CertificatePdfService.php',
    'app/Models/VolunteerCertificate.php',
    'app/Providers/AppServiceProvider.php',
    'app/Http/Middleware/AllowCrossOrigin.php',
    'config/cors.php',
    'resources/views/pdf/certificate.blade.php',
    'tests/Feature/CertificateApiTest.php'
)
foreach ($file in $files) {
    $target = Join-Path $backend $file
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
    [IO.File]::WriteAllText($target, [IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)), $utf8)
}
$path = Join-Path $backend 'routes/api.php'
$routes = [IO.File]::ReadAllText($path)
if (!$routes.Contains("name('api.certificates.signed-download')")) {
    $routes += @'

// Certificate PDFs: bearer-authenticated bytes or a short-lived signed browser link.
Route::prefix('v1')->middleware('cors')->group(function () {
    Route::get('/certificates/{id}/download', [\App\Http\Controllers\Api\CertificateFileController::class, 'download'])
        ->middleware('auth:sanctum');
    Route::get('/certificates/{id}/download-signed', [\App\Http\Controllers\Api\CertificateFileController::class, 'signedDownload'])
        ->middleware('signed:relative')->name('api.certificates.signed-download');
    Route::get('/certificate/qr/{certificateNumber}', [\App\Http\Controllers\Api\CertificateFileController::class, 'qr'])
        ->name('api.certificate.qr');
});
'@
    [IO.File]::WriteAllText($path, $routes, $utf8)
}
Write-Output 'Certificate API, shared PDF rendering, local QR, and hosting CORS installed.'
