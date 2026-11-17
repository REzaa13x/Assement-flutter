import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/campaign_location.dart';
import '../repositories/campaign_repository.dart';
import '../services/auth_service.dart';
import '../widgets/rupiah_input_formatter.dart';
import 'campaign_location_picker_page.dart';

class StartCampaignPage extends StatefulWidget {
  final ImagePicker? imagePicker;
  final Future<CampaignLocation?> Function(BuildContext, CampaignLocation?)?
      pickLocation;
  const StartCampaignPage({super.key, this.imagePicker, this.pickLocation});
  @override
  State<StartCampaignPage> createState() => _StartCampaignPageState();
}

class _StartCampaignPageState extends State<StartCampaignPage> {
  static const _blue = Color(0xFF2972FF);
  final _formKey = GlobalKey<FormState>();
  final _photoKey = GlobalKey<FormFieldState<Uint8List>>();
  final _locationKey = GlobalKey<FormFieldState<CampaignLocation>>();
  final _dateKey = GlobalKey<FormFieldState<DateTime>>();
  final _title = TextEditingController();
  final _story = TextEditingController();
  final _target = TextEditingController();
  final _recipient = TextEditingController();
  final _recipientInfo = TextEditingController();
  final _whatsapp = TextEditingController();
  String? _category;
  String? _recipientType;
  String? _distributionMethod;
  String _creator = '';
  DateTime? _endDate;
  CampaignLocation? _location;
  Uint8List? _image;
  String _imageExtension = 'jpg';
  bool _isSubmitting = false;
  bool _submitted = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _loadCreator();
  }

  Future<void> _loadCreator() async {
    final user = await AuthService.getUserData();
    if (mounted) setState(() => _creator = user?['name']?.toString() ?? '');
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _story,
      _target,
      _recipient,
      _recipientInfo,
      _whatsapp
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _notify(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _chooseImageSource() async {
    if (_isSubmitting || _isPickingImage || _submitted) return;
    FocusScope.of(context).unfocus();
    final source = await showModalBottomSheet<ImageSource>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Ambil dari kamera'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera)),
              ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Pilih dari galeri'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
            ])));
    if (source == null || !mounted) return;
    setState(() => _isPickingImage = true);
    try {
      final file = await (widget.imagePicker ?? ImagePicker()).pickImage(
          source: source, maxWidth: 2048, maxHeight: 2048, imageQuality: 85);
      if (file == null) return;
      if (await file.length() > 2 * 1024 * 1024) {
        throw Exception(
            'Ukuran foto maksimal 2 MB. Pilih foto yang lebih kecil.');
      }
      final bytes = await file.readAsBytes();
      final png = bytes.length >= 8 &&
          bytes[0] == 137 &&
          bytes[1] == 80 &&
          bytes[2] == 78 &&
          bytes[3] == 71;
      final jpeg = bytes.length >= 3 &&
          bytes[0] == 255 &&
          bytes[1] == 216 &&
          bytes[2] == 255;
      if (!png && !jpeg) {
        throw Exception('Gunakan foto berformat JPG, JPEG, atau PNG.');
      }
      if (!mounted) return;
      setState(() {
        _image = bytes;
        _imageExtension = png ? 'png' : 'jpg';
      });
      _photoKey.currentState?.didChange(bytes);
    } catch (error) {
      _notify(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _chooseLocation() async {
    FocusScope.of(context).unfocus();
    final result = widget.pickLocation != null
        ? await widget.pickLocation!(context, _location)
        : await Navigator.push<CampaignLocation>(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    CampaignLocationPickerPage(initialLocation: _location)));
    if (result == null || !mounted) return;
    setState(() => _location = result);
    _locationKey.currentState?.didChange(result);
  }

  Future<void> _chooseEndDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final result = await showDatePicker(
        context: context,
        helpText: 'Tanggal berakhir kampanye',
        cancelText: 'Batal',
        confirmText: 'Pilih Tanggal',
        firstDate: tomorrow,
        initialDate: _endDate != null && !_endDate!.isBefore(tomorrow)
            ? _endDate!
            : tomorrow,
        lastDate: DateTime(now.year + 10));
    if (result == null || !mounted) return;
    setState(() => _endDate = result);
    _dateKey.currentState?.didChange(result);
  }

  Future<void> _submit() async {
    if (_isSubmitting || _isPickingImage || _submitted) return;
    if (!_formKey.currentState!.validate()) {
      _notify(
          'Lengkapi kolom yang ditandai, termasuk lokasi dan foto kampanye.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Silakan login terlebih dahulu.');
      }
      final result = await CampaignRepository.createCampaign(
        title: _title.text.trim(),
        description: _story.text.trim(),
        targetAmount: RupiahInputFormatter.amount(_target.text)!.toDouble(),
        endDate: _endDate!.toIso8601String().split('T').first,
        kategori: _category!,
        yayasan: _recipient.text.trim(),
        recipientType: _recipientType!,
        recipientDescription: _recipientInfo.text.trim(),
        whatsapp: _whatsapp.text.trim(),
        distributionMethod: _distributionMethod!,
        location: _location!,
        token: token,
        imageFile: http.MultipartFile.fromBytes('image', _image!,
            filename: 'kampanye.$_imageExtension',
            contentType:
                MediaType('image', _imageExtension == 'png' ? 'png' : 'jpeg')),
      );
      if (result.id == null || result.id! <= 0) {
        throw Exception(
            'Nomor pengajuan belum tersedia. Periksa riwayat kampanye sebelum mencoba lagi.');
      }
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitted = true;
      });
      await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
                title: const Text('Kampanye Berhasil Diajukan'),
                content: Text(result.status == 'pending'
                    ? 'Kampanye Anda telah diajukan dan sedang menunggu verifikasi admin. Pantau statusnya di Riwayat Kampanye.'
                    : 'Kampanye tersimpan. Periksa status terbaru pada Riwayat Kampanye.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Lihat Riwayat'))
                ],
              ));
      if (mounted) Navigator.pushReplacementNamed(context, '/campaign_history');
    } catch (error) {
      _notify(
          'Pengajuan belum berhasil: ${error.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _decoration(String label, String hint, {String? prefix}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        alignLabelWithHint: true,
        filled: true,
        fillColor: const Color(0xFFF7F9FD),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: _blue, width: 1.5)),
        errorMaxLines: 2,
      );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Kolom ini wajib diisi.' : null;

  Widget _field(String key, TextEditingController controller, String label,
          String hint,
          {int lines = 1,
          int maxLength = 255,
          TextInputType? keyboard,
          String? Function(String?)? validator}) =>
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: TextFormField(
            key: Key(key),
            controller: controller,
            readOnly: _isSubmitting,
            maxLines: lines,
            maxLength: maxLength,
            keyboardType: keyboard ??
                (lines > 1 ? TextInputType.multiline : TextInputType.text),
            textInputAction:
                lines > 1 ? TextInputAction.newline : TextInputAction.next,
            decoration: _decoration(label, hint).copyWith(counterText: ''),
            validator: validator ?? _required),
      );

  Widget _dropdown(String key, String label, String? value,
          List<String> choices, ValueChanged<String?> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: DropdownButtonFormField<String>(
          key: Key(key),
          initialValue: value,
          isExpanded: true,
          decoration: _decoration(label, 'Pilih $label'),
          items: choices
              .map((choice) => DropdownMenuItem(
                  value: choice,
                  child: Text(choice, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: _isSubmitting ? null : onChanged,
          validator: _required,
        ),
      );

  Widget _section(String number, String title, String description,
          List<Widget> children) =>
      Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8EEF7))),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('$number. $title',
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF142D50))),
          const SizedBox(height: 6),
          Text(description,
              style: const TextStyle(
                  fontSize: 12, height: 1.5, color: Color(0xFF61738C))),
          ...children,
        ]),
      );

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8FD),
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
            title: const Text('Tambah Kampanye Baru'),
            backgroundColor: Colors.white,
            scrolledUnderElevation: 0),
        body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
              child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Mulai langkah kebaikan',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF142D50))),
                          const SizedBox(height: 8),
                          Text(
                              _creator.isEmpty
                                  ? 'Ceritakan kebutuhan bantuan. Tim DonGiv akan meninjau pengajuan Anda.'
                                  : 'Pengaju: $_creator. Tim DonGiv akan meninjau pengajuan Anda.',
                              style: const TextStyle(
                                  color: Color(0xFF61738C), height: 1.5)),
                          const SizedBox(height: 20),
                          _section(
                              '1',
                              'Informasi kampanye',
                              'Isi cerita dan tujuan penggalangan dana dengan jelas.',
                              [
                                _field(
                                    'campaign-title',
                                    _title,
                                    'Judul kampanye',
                                    'Contoh: Bantu renovasi sekolah warga'),
                                _dropdown(
                                    'campaign-category',
                                    'Kategori kampanye',
                                    _category,
                                    const [
                                      'Kesehatan',
                                      'Pendidikan',
                                      'Bencana Alam',
                                      'Lingkungan',
                                      'Sosial Kemanusiaan'
                                    ],
                                    (value) =>
                                        setState(() => _category = value)),
                                _field(
                                    'campaign-story',
                                    _story,
                                    'Cerita lengkap kampanye',
                                    'Jelaskan kondisi, kebutuhan bantuan, dan rencana penggunaan dana.',
                                    lines: 5,
                                    maxLength: 20000),
                                const SizedBox(height: 16),
                                TextFormField(
                                    key: const Key('campaign-target'),
                                    controller: _target,
                                    readOnly: _isSubmitting,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [RupiahInputFormatter()],
                                    decoration: _decoration(
                                        'Target dana', '10.000.000',
                                        prefix: 'Rp '),
                                    validator: (value) =>
                                        (RupiahInputFormatter.amount(
                                                        value ?? '') ??
                                                    0) <
                                                10000
                                            ? 'Target dana minimal Rp 10.000.'
                                            : null),
                                const SizedBox(height: 16),
                                FormField<DateTime>(
                                    key: _dateKey,
                                    validator: (value) {
                                      final now = DateTime.now();
                                      return value == null ||
                                              !value.isAfter(DateTime(
                                                  now.year, now.month, now.day))
                                          ? 'Pilih tanggal setelah hari ini.'
                                          : null;
                                    },
                                    builder: (state) => InkWell(
                                        onTap: _isSubmitting
                                            ? null
                                            : _chooseEndDate,
                                        child: InputDecorator(
                                            decoration: _decoration(
                                                    'Tanggal berakhir', '')
                                                .copyWith(
                                                    errorText: state.errorText),
                                            child: Row(children: [
                                              Expanded(
                                                  child: Text(_endDate == null
                                                      ? 'Pilih tanggal berakhir'
                                                      : '${_endDate!.day.toString().padLeft(2, '0')}/${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.year}')),
                                              const Icon(
                                                  Icons.calendar_today_outlined,
                                                  size: 20,
                                                  color: _blue),
                                            ])))),
                              ]),
                          _section(
                              '2',
                              'Penerima bantuan',
                              'Data ini menjelaskan pihak yang menerima bantuan, bukan pemilik akun pengaju.',
                              [
                                _field(
                                    'campaign-recipient',
                                    _recipient,
                                    'Nama penerima / organisasi',
                                    'Nama individu, yayasan, atau komunitas'),
                                _dropdown(
                                    'campaign-recipient-type',
                                    'Jenis penerima',
                                    _recipientType,
                                    const ['Individu', 'Yayasan', 'Komunitas'],
                                    (value) =>
                                        setState(() => _recipientType = value)),
                                _field(
                                    'campaign-recipient-info',
                                    _recipientInfo,
                                    'Informasi penerima bantuan',
                                    'Jelaskan siapa penerima dan alasan mereka membutuhkan bantuan.',
                                    lines: 3,
                                    maxLength: 5000),
                                _field(
                                    'campaign-contact',
                                    _whatsapp,
                                    'Nomor WhatsApp yang dapat dihubungi',
                                    '08xxxxxxxxxx',
                                    maxLength: 20,
                                    validator: (value) => value != null &&
                                            RegExp(r'^\+?[0-9][0-9\s-]{7,19}$')
                                                .hasMatch(value.trim())
                                        ? null
                                        : 'Masukkan nomor WhatsApp yang valid.',
                                    keyboard: TextInputType.phone),
                                _dropdown(
                                    'campaign-distribution',
                                    'Penyaluran dana',
                                    _distributionMethod,
                                    const ['Langsung', 'Yayasan', 'Platform'],
                                    (value) => setState(
                                        () => _distributionMethod = value)),
                              ]),
                          _section(
                              '3',
                              'Lokasi bantuan',
                              'Pilih lokasi penerima atau penyaluran melalui peta. Titik hanya tersimpan setelah Anda mengonfirmasinya.',
                              [
                                const SizedBox(height: 14),
                                FormField<CampaignLocation>(
                                    key: _locationKey,
                                    validator: (value) => value == null
                                        ? 'Pilih dan konfirmasi lokasi bantuan.'
                                        : null,
                                    builder: (state) => Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              if (_location != null) ...[
                                                Text(_location!.address,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        height: 1.5)),
                                                const SizedBox(height: 8),
                                                Text([
                                                  _location!.district,
                                                  _location!.city,
                                                  _location!.province
                                                ]
                                                    .where((s) => s.isNotEmpty)
                                                    .join(', ')),
                                                const SizedBox(height: 8),
                                                Text(
                                                    '${_location!.latitude.toStringAsFixed(7)}, ${_location!.longitude.toStringAsFixed(7)}',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Color(0xFF61738C))),
                                                const SizedBox(height: 8),
                                              ],
                                              OutlinedButton.icon(
                                                  key: const Key(
                                                      'campaign-location'),
                                                  onPressed: _isSubmitting
                                                      ? null
                                                      : _chooseLocation,
                                                  icon: const Icon(
                                                      Icons.map_outlined),
                                                  label: Text(_location == null
                                                      ? 'Pilih Lokasi di Peta'
                                                      : 'Ubah Lokasi')),
                                              if (state.hasError)
                                                Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 6),
                                                    child: Text(
                                                        state.errorText!,
                                                        style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .error,
                                                            fontSize: 12))),
                                            ])),
                              ]),
                          _section(
                              '4',
                              'Foto utama kampanye',
                              'Gunakan foto yang relevan. JPG, JPEG, atau PNG, maksimal 2 MB.',
                              [
                                const SizedBox(height: 14),
                                FormField<Uint8List>(
                                    key: _photoKey,
                                    validator: (value) => value == null
                                        ? 'Tambahkan foto utama kampanye.'
                                        : null,
                                    builder: (state) => Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              if (_image != null)
                                                ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            14),
                                                    child: AspectRatio(
                                                        aspectRatio: 16 / 9,
                                                        child: Image.memory(
                                                            _image!,
                                                            fit:
                                                                BoxFit.cover))),
                                              Wrap(
                                                  spacing: 8,
                                                  runSpacing: 4,
                                                  children: [
                                                    OutlinedButton.icon(
                                                        onPressed: _isSubmitting ||
                                                                _isPickingImage
                                                            ? null
                                                            : _chooseImageSource,
                                                        icon: const Icon(Icons
                                                            .add_a_photo_outlined),
                                                        label: Text(_isPickingImage
                                                            ? 'Menyiapkan foto...'
                                                            : _image == null
                                                                ? 'Tambahkan Foto'
                                                                : 'Ganti Foto')),
                                                    if (_image != null)
                                                      TextButton.icon(
                                                          onPressed:
                                                              _isSubmitting
                                                                  ? null
                                                                  : () {
                                                                      setState(() =>
                                                                          _image =
                                                                              null);
                                                                      _photoKey
                                                                          .currentState
                                                                          ?.didChange(
                                                                              null);
                                                                    },
                                                          icon: const Icon(Icons
                                                              .delete_outline),
                                                          label: const Text(
                                                              'Hapus Foto')),
                                                  ]),
                                              if (state.hasError)
                                                Text(state.errorText!,
                                                    style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .error,
                                                        fontSize: 12)),
                                            ])),
                              ]),
                          const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text(
                                  'Pengajuan akan ditinjau admin sebelum tampil sebagai kampanye terverifikasi.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12,
                                      height: 1.5,
                                      color: Color(0xFF61738C)))),
                        ],
                      ))),
            )),
        bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: FilledButton(
                  onPressed: _isSubmitting || _isPickingImage || _submitted
                      ? null
                      : _submit,
                  style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white)),
                              SizedBox(width: 10),
                              Text('Mengirim...'),
                            ])
                      : Text(
                          _submitted
                              ? 'Pengajuan Tersimpan'
                              : 'Ajukan Kampanye',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ))),
      ));
}
