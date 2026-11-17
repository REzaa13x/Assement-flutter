<?php
// Read-only summary; never prints credentials, tokens or personal information.
$root = $argv[1] ?? null;
if (!$root || !is_file($root.'/artisan')) { exit("Pass the Laravel directory.\n"); }
require $root.'/vendor/autoload.php';
$app = require $root.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
$db = Illuminate\Support\Facades\DB::class;
echo json_encode([
    'routes' => collect($app['router']->getRoutes())->map(fn($r) => $r->uri())->filter(fn($r) => str_contains($r, 'locations/'))->values(),
    'applications_by_status' => $db::table('volunteer_applications')->selectRaw('status, count(*) as total')->groupBy('status')->get(),
    'certificates_by_status' => $db::table('volunteer_certificates')->selectRaw('status, count(*) as total')->groupBy('status')->get(),
    'accepted_without_certificate' => $db::table('volunteer_applications')->whereIn('status', ['approved', 'accepted'])->whereNotExists(function($q) {
        $q->selectRaw('1')->from('volunteer_certificates')->whereColumn('application_id', 'volunteer_applications.id');
    })->count(),
    'upload_max_filesize' => ini_get('upload_max_filesize'),
    'post_max_size' => ini_get('post_max_size'),
], JSON_PRETTY_PRINT)."\n";
