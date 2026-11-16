import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ConnectionDebugScreen extends StatefulWidget {
  const ConnectionDebugScreen({Key? key}) : super(key: key);

  @override
  State<ConnectionDebugScreen> createState() => _ConnectionDebugScreenState();
}

class _ConnectionDebugScreenState extends State<ConnectionDebugScreen> {
  String _statusMessage = 'Klik tombol untuk mulai debug';
  Color _statusColor = Colors.black;
  List<String> _debugSteps = [];
  bool _isLoading = false;

  // Different possible URLs to test
  final List<String> _testUrls = [
    'http://127.0.0.1:8000/api/campaigns',
    'http://localhost:8000/api/campaigns',
    'http://10.0.2.2:8000/api/campaigns',
    // Add your actual IP if known
    // 'http://192.168.x.x:8000/api/campaigns',  // Replace x.x with your actual IP
  ];

  Future<void> _startDebugging() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Memulai debugging...';
      _statusColor = Colors.blue;
      _debugSteps = [];
    });

    // Step 1: Check if Laravel server is running
    _addDebugStep('Langkah 1: Mengecek apakah server Laravel berjalan...');
    
    bool serverRunning = await _checkLaravelServer();
    if (!serverRunning) {
      setState(() {
        _statusMessage = '❌ Server Laravel tidak ditemukan. Pastikan Laravel dijalankan dengan: php artisan serve';
        _statusColor = Colors.red;
        _isLoading = false;
      });
      return;
    }

    _addDebugStep('✅ Server Laravel ditemukan di http://127.0.0.1:8000');

    // Step 2: Test different URLs
    _addDebugStep('Langkah 2: Mencoba berbagai URL untuk koneksi...');

    for (String url in _testUrls) {
      _addDebugStep('Mencoba: $url');
      
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {'Accept': 'application/json'},
        );
        
        if (response.statusCode == 200) {
          _addDebugStep('✅ Berhasil terhubung ke: $url');
          _addDebugStep('Status Code: ${response.statusCode}');
          
          // Try to parse the response
          try {
            final data = jsonDecode(response.body);
            if (data is Map && data.containsKey('data')) {
              _addDebugStep('✅ Format API benar, menerima data');
              if (data['data'] is List) {
                _addDebugStep('✅ Jumlah campaign diterima: ${data['data'].length}');
              }
            }
          } catch (e) {
            _addDebugStep('⚠️ Gagal parse response: $e');
          }
          
          setState(() {
            _statusMessage = '🎉 Koneksi berhasil! Gunakan URL: $url';
            _statusColor = Colors.green;
            _isLoading = false;
          });
          return;
        } else {
          _addDebugStep('❌ Gagal dengan status: ${response.statusCode}');
        }
      } catch (e) {
        _addDebugStep('❌ Gagal terhubung ke $url: $e');
      }
    }

    // If all URLs fail, check for CORS issues
    _addDebugStep('Langkah 3: Memeriksa kemungkinan masalah CORS...');
    _addDebugStep('⚠️ Jika kamu menggunakan Chrome, kemungkinan besar masalahnya adalah CORS');

    setState(() {
      _statusMessage = 'CORS kemungkinan besar menjadi masalah. Lihat langkah selanjutnya.';
      _statusColor = Colors.orange;
    });

    _showCORSInstructions();
  }

  Future<bool> _checkLaravelServer() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000'),
        headers: {'Accept': 'text/html'},
      );
      return response.statusCode == 200;
    } catch (e) {
      try {
        // Try localhost as alternative
        final response = await http.get(
          Uri.parse('http://localhost:8000'),
          headers: {'Accept': 'text/html'},
        );
        return response.statusCode == 200;
      } catch (e2) {
        return false;
      }
    }
  }

  void _addDebugStep(String step) {
    setState(() {
      _debugSteps.add(step);
    });
  }

  void _showCORSInstructions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Langkah untuk mengatasi CORS'),
          content: SizedBox(
            height: 300,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ikuti langkah-langkah berikut di Laravel kamu:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text('1. Install package CORS:'),
                  const SelectableText('composer require barryvdh/laravel-cors'),
                  const SizedBox(height: 10),
                  const Text('2. Publish configuration:'),
                  const SelectableText('php artisan vendor:publish --provider="Barryvdh\\Cors\\ServiceProvider"'),
                  const SizedBox(height: 10),
                  const Text('3. Update config/cors.php:'),
                  const SelectableText('''<?php
return [
    'paths' => ['api/*'],
    'allowed_methods' => ['*'],
    'allowed_origins' => ['*'],
    'allowed_origins_patterns' => [],
    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 0,
    'supports_credentials' => false,
];'''),
                  const SizedBox(height: 10),
                  const Text('4. Tambahkan middleware di app/Http/Kernel.php:'),
                  const SelectableText('// Di bagian \$middleware'),
                  const SelectableText("Barryvdh\\\\Cors\\\\HandleCors::class,"),
                  const SizedBox(height: 10),
                  const Text('5. Restart Laravel server:'),
                  const SelectableText('php artisan serve'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Koneksi API'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: _statusColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: _statusColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _startDebugging,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text(
                      'Mulai Debug Koneksi',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Petunjuk:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text(
              '1. Pastikan Laravel kamu berjalan dengan: php artisan serve',
              style: TextStyle(fontSize: 14),
            ),
            const Text(
              '2. Pastikan Laravel berjalan di http://127.0.0.1:8000',
              style: TextStyle(fontSize: 14),
            ),
            const Text(
              '3. Untuk Chrome, kemungkinan besar kamu perlu setup CORS di Laravel',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            const Text(
              'Log Debug:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _debugSteps.length,
                itemBuilder: (context, index) {
                  String step = _debugSteps[index];
                  Color color = Colors.black;
                  
                  if (step.contains('✅')) color = Colors.green;
                  else if (step.contains('❌')) color = Colors.red;
                  else if (step.contains('⚠️')) color = Colors.orange;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      '• ${step.replaceAll('✅', '').replaceAll('❌', '').replaceAll('⚠️', '')}',
                      style: TextStyle(color: color),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}