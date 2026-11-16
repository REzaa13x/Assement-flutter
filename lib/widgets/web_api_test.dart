import 'package:flutter/material.dart';
import '../services/api_campaign_service.dart';

class WebApiTestScreen extends StatefulWidget {
  const WebApiTestScreen({Key? key}) : super(key: key);

  @override
  State<WebApiTestScreen> createState() => _WebApiTestScreenState();
}

class _WebApiTestScreenState extends State<WebApiTestScreen> {
  bool _isLoading = false;
  String _statusMessage = 'Ready to test API connection';
  Color _statusColor = Colors.black;

  Future<void> _testApiConnection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing API connection...';
      _statusColor = Colors.blue;
    });

    try {
      // Test the API connection
      final campaigns = await ApiCampaignService.getApiCampaignsForDisplay();
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'Success! Found ${campaigns.length} campaigns';
        _statusColor = Colors.green;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
        _statusColor = Colors.red;
      });
      
      // Print detailed error to console
      print('API Connection Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Connection Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Testing connection to Laravel API at http://127.0.0.1:8000/api',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
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
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _testApiConnection,
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
            const SizedBox(height: 16),
            const Text(
              'Note: If you encounter CORS errors in Chrome, make sure you have configured CORS in your Laravel application.',
              style: TextStyle(fontSize: 14, color: Colors.orange),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Laravel CORS setup commands:\ncomposer require barryvdh/laravel-cors\nphp artisan vendor:publish --provider="Barryvdh\Cors\ServiceProvider"',
              style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}