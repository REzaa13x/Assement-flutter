<?php
// Run: php backfill_certificates.php <Laravel directory> [--apply]
$root = $argv[1] ?? null;
if (!$root || !is_file($root.'/artisan')) { exit("Pass the Laravel directory.\n"); }
require $root.'/vendor/autoload.php';
$app = require $root.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
$apply = in_array('--apply', $argv, true);
$ids = App\Models\VolunteerApplication::where('status', 'approved')
    ->whereHas('campaign')->whereHas('user')->whereDoesntHave('certificate')->pluck('id');
echo 'Eligible approved applications: '.$ids->count()."\n";
if (!$apply) { exit("Dry run. Add --apply to create missing certificates.\n"); }
$created = 0;
foreach ($ids as $id) {
    $created += Illuminate\Support\Facades\DB::transaction(function () use ($id) {
        $application = App\Models\VolunteerApplication::lockForUpdate()->findOrFail($id);
        if ($application->status !== 'approved' || $application->certificate()->exists()) return 0;
        App\Models\VolunteerCertificate::generateForApplication($application);
        return 1;
    });
}
echo 'Created certificates: '.$created."\n";
