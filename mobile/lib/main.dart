import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000');
const forest = Color(0xFF195C38);

void main() => runApp(const WasteApp());

class Api {
  String? token;

  Uri uri(String path) => Uri.parse('$apiUrl$path');
  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> call(String path, {String method = 'GET', Map<String, dynamic>? body}) async {
    final request = http.Request(method, uri(path));
    request.headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    final response = await http.Response.fromStream(await request.send());
    final data = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(data is Map ? data['detail'] ?? 'Permintaan gagal' : 'Permintaan gagal');
    }
    return data;
  }

  Future<Map<String, dynamic>> createReport({
    required String description,
    required double latitude,
    required double longitude,
    required XFile photo,
  }) async {
    final request = http.MultipartRequest('POST', uri('/reports'));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll({
      'description': description,
      'latitude': '$latitude',
      'longitude': '$longitude',
    });
    request.files.add(await http.MultipartFile.fromPath('image', photo.path));
    final response = await http.Response.fromStream(await request.send());
    final data = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(data is Map ? data['detail'] ?? 'Gagal mengirim laporan' : 'Gagal mengirim laporan');
    }
    return Map<String, dynamic>.from(data);
  }
}

final api = Api();

class WasteApp extends StatefulWidget {
  const WasteApp({super.key});
  @override
  State<WasteApp> createState() => _WasteAppState();
}

class _WasteAppState extends State<WasteApp> {
  Map<String, dynamic>? user;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    restore();
  }

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    api.token = prefs.getString('token');
    if (api.token != null) {
      try {
        user = Map<String, dynamic>.from(await api.call('/auth/me'));
      } catch (_) {
        api.token = null;
        await prefs.remove('token');
      }
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> signedIn(Map<String, dynamic> data) async {
    api.token = data['access_token'] as String;
    await (await SharedPreferences.getInstance()).setString('token', api.token!);
    setState(() => user = Map<String, dynamic>.from(data['user']));
  }

  Future<void> signOut() async {
    api.token = null;
    await (await SharedPreferences.getInstance()).remove('token');
    setState(() => user = null);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'CamPah',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: forest), useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFF5F7F3)),
        home: loading
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : user == null
                ? AuthPage(onSignedIn: signedIn)
                : HomePage(user: user!, onSignOut: signOut),
      );
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.onSignedIn});
  final Future<void> Function(Map<String, dynamic>) onSignedIn;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool register = false;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    name.dispose(); email.dispose(); password.dispose(); super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() { busy = true; error = null; });
    try {
      final result = await api.call(register ? '/auth/register' : '/auth/login', method: 'POST', body: {
        if (register) 'name': name.text.trim(),
        'email': email.text.trim(), 'password': password.text,
      });
      await widget.onSignedIn(Map<String, dynamic>.from(result));
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(child: Center(child: SingleChildScrollView(child: Padding(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Form(
            key: formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Icon(Icons.recycling, size: 70, color: forest),
              const SizedBox(height: 20),
              Text(register ? 'Buat akun baru' : 'Selamat datang', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Laporkan sampah, pantau tindak lanjutnya.', textAlign: TextAlign.center),
              const SizedBox(height: 32),
              if (register) TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Nama lengkap', border: OutlineInputBorder()), validator: (v) => (v?.trim().length ?? 0) < 2 ? 'Minimal 2 karakter' : null),
              if (register) const SizedBox(height: 14),
              TextFormField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()), validator: (v) => v == null || !v.contains('@') ? 'Email tidak valid' : null),
              const SizedBox(height: 14),
              TextFormField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Kata sandi', border: OutlineInputBorder()), validator: (v) => (v?.length ?? 0) < 8 ? 'Minimal 8 karakter' : null),
              if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
              const SizedBox(height: 22),
              FilledButton(onPressed: busy ? null : submit, child: Text(busy ? 'Memproses...' : register ? 'Daftar' : 'Masuk')),
              TextButton(onPressed: () => setState(() { register = !register; error = null; }), child: Text(register ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar')),
            ]),
          )),
        )))),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.user, required this.onSignOut});
  final Map<String, dynamic> user;
  final Future<void> Function() onSignOut;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  int revision = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('CamPah'), actions: [IconButton(onPressed: widget.onSignOut, icon: const Icon(Icons.logout), tooltip: 'Keluar')]),
        body: index == 0
            ? DashboardPage(key: ValueKey(revision), name: widget.user['name'] ?? 'Pengguna', openReport: () => setState(() => index = 1))
            : index == 1
                ? CreateReportPage(onCreated: () => setState(() { index = 2; revision++; }))
                : HistoryPage(key: ValueKey(revision)),
        bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (value) => setState(() { index = value; revision++; }), destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Lapor'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Riwayat'),
        ]),
      );
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.name, required this.openReport});
  final String name;
  final VoidCallback openReport;
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? stats;
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    try { final data = await api.call('/dashboard'); if (mounted) setState(() => stats = Map<String, dynamic>.from(data)); } catch (_) {}
  }
  @override
  Widget build(BuildContext context) => RefreshIndicator(onRefresh: load, child: ListView(padding: const EdgeInsets.all(20), children: [
        Card(color: forest, child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Halo, ${widget.name}!', style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8), const Text('Bantu lingkungan lebih bersih dengan satu laporan.', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 20), FilledButton.tonal(onPressed: widget.openReport, child: const Text('Buat laporan')),
        ]))),
        const SizedBox(height: 20),
        Text('Ringkasan laporan', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Card(child: ListTile(leading: const Icon(Icons.assessment_outlined), title: const Text('Total laporan'), trailing: Text('${stats?['total'] ?? '—'}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)))),
        for (final status in ['Pending', 'In Progress', 'Completed', 'Rejected']) Card(child: ListTile(title: Text(status), trailing: Text('${(stats?['by_status'] as Map?)?[status] ?? '—'}'))),
      ]));
}

class CreateReportPage extends StatefulWidget {
  const CreateReportPage({super.key, required this.onCreated});
  final VoidCallback onCreated;
  @override
  State<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends State<CreateReportPage> {
  final description = TextEditingController();
  XFile? photo;
  Position? position;
  bool busy = false;
  String? error;

  @override
  void dispose() { description.dispose(); super.dispose(); }

  Future<void> pick(ImageSource source) async {
    try { final selected = await ImagePicker().pickImage(source: source, imageQuality: 80, maxWidth: 1600); if (selected != null) setState(() => photo = selected); }
    catch (e) { setState(() => error = 'Tidak dapat membuka kamera atau galeri: $e'); }
  }

  Future<void> locate() async {
    setState(() { busy = true; error = null; });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw Exception('Aktifkan layanan lokasi');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw Exception('Izin lokasi diperlukan untuk laporan');
      final result = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      setState(() => position = result);
    } catch (e) { setState(() => error = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> submit() async {
    if (description.text.trim().length < 10 || photo == null || position == null) {
      setState(() => error = 'Isi deskripsi minimal 10 karakter, pilih foto, dan ambil lokasi.'); return;
    }
    setState(() { busy = true; error = null; });
    try {
      final result = await api.createReport(description: description.text.trim(), latitude: position!.latitude, longitude: position!.longitude, photo: photo!);
      if (!mounted) return;
      final category = result['ai_category'] ?? 'AI belum tersedia';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Laporan terkirim · $category')));
      widget.onCreated();
    } catch (e) { if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
        Text('Buat laporan sampah', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(controller: description, maxLines: 4, maxLength: 2000, decoration: const InputDecoration(labelText: 'Deskripsi (minimal 10 karakter)', border: OutlineInputBorder(), alignLabelWithHint: true)),
        const SizedBox(height: 12),
        if (photo != null) ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(File(photo!.path), height: 190, fit: BoxFit.cover)),
        Wrap(spacing: 10, children: [OutlinedButton.icon(onPressed: () => pick(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text('Kamera')), OutlinedButton.icon(onPressed: () => pick(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text('Galeri'))]),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: busy ? null : locate, icon: const Icon(Icons.my_location), label: Text(position == null ? 'Ambil lokasi GPS' : '${position!.latitude.toStringAsFixed(5)}, ${position!.longitude.toStringAsFixed(5)}')),
        if (error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 20),
        FilledButton(onPressed: busy ? null : submit, child: Text(busy ? 'Mengirim...' : 'Kirim laporan')),
      ]);
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> reports = [];
  String? error;
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    try {
      final data = await api.call('/reports?page_size=100');
      if (mounted) setState(() { reports = data['items']; error = null; });
    } catch (e) { if (mounted) setState(() => error = '$e'); }
  }
  @override
  Widget build(BuildContext context) => RefreshIndicator(onRefresh: load, child: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Riwayat laporan', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
        if (reports.isEmpty) const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Belum ada laporan. Tarik ke bawah untuk memperbarui.'))),
        for (final report in reports) Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(9), child: Image.network('${report['image_url']}'.startsWith('/') ? '$apiUrl${report['image_url']}' : report['image_url'], width: 76, height: 76, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 76, height: 76, child: Icon(Icons.image_not_supported)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(report['description'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5), Text(report['status'], style: const TextStyle(color: forest)),
            Text(report['ai_category'] ?? 'Belum terdeteksi', style: const TextStyle(fontSize: 12)),
          ])),
        ]))),
      ]));
}
