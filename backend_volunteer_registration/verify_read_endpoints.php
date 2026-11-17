<?php
// Read-only integration probe using an in-process guard; no persistent tokens.
$root = $argv[1] ?? null;
if (!$root || !is_file($root.'/artisan')) { exit("Pass the Laravel directory.\n"); }
require $root.'/vendor/autoload.php';
$app = require $root.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
$ownerId = App\Models\VolunteerCertificate::value('volunteer_id');
$user = App\Models\User::findOrFail($ownerId);
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);
foreach ([
    '/api/v1/certificates',
    '/api/v1/locations/reverse?latitude=-6.9175&longitude=107.6191',
    '/api/v1/locations/revese?latitude=-6.9175&longitude=107.6191',
] as $uri) {
    Illuminate\Support\Facades\Auth::guard('sanctum')->setUser($user);
    $request = Illuminate\Http\Request::create($uri, 'GET', [], [], [], ['HTTP_ACCEPT' => 'application/json']);
    $response = $kernel->handle($request);
    $json = json_decode($response->getContent(), true);
    echo strtok($uri, '?').' HTTP '.$response->getStatusCode()."\n";
    if ($response->getStatusCode() !== 200) { exit(1); }
    if ($uri === '/api/v1/certificates') {
        foreach ($json['data'] as $certificate) {
            if ($certificate['volunteer_id'] !== $user->id) { exit(2); }
        }
        $expected = App\Models\VolunteerCertificate::where('volunteer_id', $user->id)->count();
        if (count($json['data']) !== $expected) { exit(3); }
        echo 'Certificate count matches owner database records: '.$expected."\n";
    } elseif (empty($json['data']['address'])) {
        exit(4);
    }
    $kernel->terminate($request, $response);
}
