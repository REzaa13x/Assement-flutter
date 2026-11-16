import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../repositories/campaign_repository.dart';
import '../services/auth_service.dart';

class StartCampaignPage extends StatefulWidget {
  const StartCampaignPage({Key? key}) : super(key: key);

  @override
  State<StartCampaignPage> createState() => _StartCampaignPageState();
}

class _StartCampaignPageState extends State<StartCampaignPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _selectedCategory = 'Kesehatan';
  Uint8List? _imageBytes;
  String? _imageName;
  DateTime? _endDate;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageName = image.name;
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal memilih gambar: $e')));
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    if (_endDate == null || !_endDate!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pilih tanggal berakhir setelah hari ini')));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty)
        throw Exception('Silakan login terlebih dahulu');
      await CampaignRepository.createCampaign(
        title: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        targetAmount: double.parse(_goalController.text.trim()),
        endDate: _endDate!.toIso8601String().split('T').first,
        kategori: _selectedCategory,
        token: token,
        imageFile: _imageBytes == null
            ? null
            : http.MultipartFile.fromBytes('image', _imageBytes!,
                filename: _imageName),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Kampanye berhasil dikirim'),
          backgroundColor: Colors.green));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengirim kampanye: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  final List<String> categories = [
    'Kesehatan',
    'Pendidikan',
    'Bencana Alam',
    'Lingkungan',
    'Sosial Kemanusiaan',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Start a Campaign'),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Upload Section
                const Text(
                  'Campaign Image',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 200,
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _imageBytes == null
                            ? const Icon(
                                Icons.image,
                                size: 50,
                                color: Colors.grey,
                              )
                            : Image.memory(
                                _imageBytes!,
                                fit: BoxFit.cover,
                                width: 200,
                                height: 150,
                              ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: FloatingActionButton(
                          onPressed: _isSubmitting ? null : _pickImage,
                          backgroundColor: const Color(0xFF2972FF),
                          child: const Icon(Icons.add_a_photo),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Campaign Name
                const Text(
                  'Campaign Name',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter campaign name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a campaign name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Category Selection
                const Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      items: categories.map((String category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue!;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Donation Goal
                const Text(
                  'Donation Goal (Rp)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _goalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter donation goal',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monetization_on),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a donation goal';
                    }
                    final goal = double.tryParse(value);
                    if (goal == null || !goal.isFinite || goal <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                ListTile(
                  title: const Text('Tanggal berakhir'),
                  subtitle: Text(_endDate == null
                      ? 'Pilih tanggal'
                      : _endDate!.toIso8601String().split('T').first),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _isSubmitting
                      ? null
                      : () async {
                          final now = DateTime.now();
                          final tomorrow =
                              DateTime(now.year, now.month, now.day + 1);
                          final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? tomorrow,
                              firstDate: tomorrow,
                              lastDate: DateTime(now.year + 10));
                          if (date != null && mounted)
                            setState(() => _endDate = date);
                        },
                ),
                const SizedBox(height: 16),
                // Description
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText:
                        'Describe your campaign and how the funds will be used',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2972FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _isSubmitting ? 'Mengirim...' : 'Submit Campaign',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
