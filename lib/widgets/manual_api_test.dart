// Manual API Test - File ini bisa digunakan untuk testing koneksi API secara manual
// Gunakan ini jika kamu ingin menguji koneksi secara spesifik

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ManualApiTest extends StatefulWidget {
  const ManualApiTest({Key? key}) : super(key: key);

  @override
  State<ManualApiTest> createState() => _ManualApiTestState();
}

class _ManualApiTestState extends State<ManualApiTest> {
  final TextEditingController _urlController = TextEditingController(
    text: 'http://127.0.0.1:8000/api/campaigns'
  );
  String _result = '';
  Color _resultColor = Colors.black;
  bool _isLoading = false;

  Future<void> _testApi() async {
    setState(() {
      _isLoading = true;
      _result = 'Menghubungkan ke API...';
      _resultColor = Colors.blue;
    });

    try {
      final url = _urlController.text;
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _result = '✅ Berhasil!\nStatus: ${response.statusCode}\n'
              'Jumlah data: ${data is Map && data.containsKey('data') ? (data['data'] as List).length : 'N/A'}\n'
              'Response preview: ${response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body}';
          _resultColor = Colors.green;
        });
      } else {
        setState(() {
          _result = '❌ Gagal!\nStatus: ${response.statusCode}\n'
              'Body: ${response.body}';
          _resultColor = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        _result = '❌ Error: $e';
        _resultColor = Colors.red;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual API Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Masukkan URL API untuk diuji:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL API',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _testApi,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text(
                      'Test API Connection',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: _resultColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _result,
                style: TextStyle(color: _resultColor),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tips:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• Pastikan Laravel server berjalan di http://127.0.0.1:8000'),
            const Text('• Untuk Chrome, pastikan CORS sudah diatur di Laravel'),
            const Text('• Coba URL: http://127.0.0.1:8000/api/campaigns'),
            const Text('• Jika gagal, coba: http://localhost:8000/api/campaigns'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}