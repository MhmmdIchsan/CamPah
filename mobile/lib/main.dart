import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'design.dart';
import 'navigation.dart';
import 'splash.dart';

const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

void main() => runApp(const WasteApp());

class Api {
  String? token;
  Future<void> Function()? onUnauthorized;
  http.Client client = http.Client();

  Uri uri(String path) => Uri.parse('$apiUrl$path');
  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> call(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, uri(path));
    request.headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    final response = await http.Response.fromStream(
      await client.send(request).timeout(const Duration(seconds: 75)),
    ).timeout(const Duration(seconds: 75));
    return decode(response);
  }

  Future<dynamic> decode(http.Response response) async {
    dynamic data;
    try {
      data = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      throw Exception('Server mengirim respons yang tidak dapat dibaca.');
    }
    if (response.statusCode == 401 && token != null) {
      await onUnauthorized?.call();
      throw Exception('Sesi berakhir. Silakan masuk kembali.');
    }
    if (response.statusCode >= 400) {
      final detail = data is Map ? data['detail'] : null;
      throw Exception(
        detail is String
            ? detail
            : 'Permintaan gagal (${response.statusCode}). Periksa isian Anda.',
      );
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
    final response = await http.Response.fromStream(
      await client.send(request).timeout(const Duration(seconds: 90)),
    ).timeout(const Duration(seconds: 90));
    return Map<String, dynamic>.from(await decode(response));
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
  bool splashComplete = false;
  ThemeMode themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    api.onUnauthorized = signOut;
    restore();
  }

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme');
    if (mounted && (savedTheme == 'dark' || savedTheme == 'light')) {
      setState(() =>
          themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light);
    }
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

  Future<void> toggleTheme() async {
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    final next = isDark ? ThemeMode.light : ThemeMode.dark;
    setState(() => themeMode = next);
    await (await SharedPreferences.getInstance())
        .setString('theme', next == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> signedIn(Map<String, dynamic> data) async {
    api.token = data['access_token'] as String;
    await (await SharedPreferences.getInstance()).setString(
      'token',
      api.token!,
    );
    if (mounted) setState(() => user = Map<String, dynamic>.from(data['user']));
  }

  Future<void> signOut() async {
    api.token = null;
    await (await SharedPreferences.getInstance()).remove('token');
    if (mounted) setState(() => user = null);
  }

  @override
  Widget build(BuildContext context) => ThemeControl(
      toggle: toggleTheme,
      child: MaterialApp(
        title: 'CamPah',
        debugShowCheckedModeBanner: false,
        theme: campahTheme(),
        darkTheme: campahTheme(dark: true),
        themeMode: themeMode,
        home: Builder(
            builder: (context) => AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 260),
                  child: !splashComplete
                      ? CamPahSplash(
                          key: const ValueKey('splash'),
                          onComplete: () {
                            if (mounted) setState(() => splashComplete = true);
                          })
                      : loading
                          ? Scaffold(
                              key: const ValueKey('loading'),
                              backgroundColor: forest,
                              body: Center(
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                    const CamPahMark(size: 96),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            value:
                                                MediaQuery.disableAnimationsOf(
                                                        context)
                                                    ? 1
                                                    : null,
                                            strokeWidth: 2,
                                            color: lime)),
                                    const SizedBox(height: 14),
                                    const Text('Menyiapkan aplikasi...',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12)),
                                  ])))
                          : user == null
                              ? AuthPage(
                                  key: const ValueKey('auth'),
                                  onSignedIn: signedIn)
                              : HomePage(
                                  key: const ValueKey('home'),
                                  user: user!,
                                  onSignOut: signOut,
                                  onProfileUpdated: (value) =>
                                      setState(() => user = value)),
                )),
      ));
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
  bool showPassword = false;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await api.call(
        register ? '/auth/register' : '/auth/login',
        method: 'POST',
        body: {
          if (register) 'name': name.text.trim(),
          'email': email.text.trim(),
          'password': password.text,
        },
      );
      await widget.onSignedIn(Map<String, dynamic>.from(result));
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: formKey,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          const CamPahMark(size: 48),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text('CamPah',
                                    style: TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -.3,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface)),
                                const SizedBox(height: 3),
                                Text('LEBIH PEDULI BUMI',
                                    style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.3,
                                        color: muted)),
                              ])),
                          const ThemeToggle(),
                        ]),
                        const SizedBox(height: 30),
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                              color: const Color(0xFFE1F0DF),
                              borderRadius: BorderRadius.circular(22)),
                          child: Row(children: [
                            const Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('SATU LANGKAH LEBIH PEDULI',
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.0,
                                          color: Color(0xFF6C9472))),
                                  SizedBox(height: 9),
                                  Text('Langkah kecil.\nDampak besar.',
                                      style: TextStyle(
                                          fontSize: 23,
                                          height: 1.25,
                                          letterSpacing: -.3,
                                          color: forest,
                                          fontWeight: FontWeight.w800)),
                                  SizedBox(height: 7),
                                  Text('Bersama jaga lingkungan sekitar.',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF66816D))),
                                ])),
                            Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                    color: const Color(0xFFCFE9C4),
                                    borderRadius: BorderRadius.circular(20)),
                                child: const Icon(Icons.eco_outlined,
                                    size: 29, color: Color(0xFF588F5D))),
                          ]),
                        ),
                        const SizedBox(height: 28),
                        Text(register ? 'Buat akun baru' : 'Selamat datang',
                            style: TextStyle(
                                fontSize: 26,
                                letterSpacing: -.45,
                                fontWeight: FontWeight.w800,
                                color:
                                    Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(height: 7),
                        Text(
                            register
                                ? 'Mulai laporkan dan pantau lingkunganmu.'
                                : 'Masuk untuk melihat dan membuat laporan.',
                            style: const TextStyle(
                                fontSize: 12, height: 1.5, color: muted)),
                        const SizedBox(height: 23),
                        if (register) ...[
                          TextFormField(
                              controller: name,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                  labelText: 'Nama lengkap',
                                  prefixIcon:
                                      Icon(Icons.person_outline_rounded)),
                              validator: (v) => (v?.trim().length ?? 0) < 2
                                  ? 'Minimal 2 karakter'
                                  : null),
                          const SizedBox(height: 13),
                        ],
                        TextFormField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon:
                                    Icon(Icons.alternate_email_rounded)),
                            validator: (v) => v == null || !v.contains('@')
                                ? 'Email tidak valid'
                                : null),
                        const SizedBox(height: 13),
                        TextFormField(
                            controller: password,
                            obscureText: !showPassword,
                            decoration: InputDecoration(
                                labelText: 'Kata sandi',
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                    tooltip: showPassword
                                        ? 'Sembunyikan kata sandi'
                                        : 'Tampilkan kata sandi',
                                    onPressed: () => setState(
                                        () => showPassword = !showPassword),
                                    icon: Icon(showPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined))),
                            validator: (v) => (v?.length ?? 0) < 8
                                ? 'Minimal 8 karakter'
                                : null),
                        if (error != null)
                          Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(error!,
                                  style: const TextStyle(
                                      color: Color(0xFFB25447), fontSize: 12))),
                        const SizedBox(height: 20),
                        FilledButton(
                            onPressed: busy ? null : submit,
                            child: Text(busy
                                ? 'Memproses...'
                                : register
                                    ? 'Daftar'
                                    : 'Masuk')),
                        const SizedBox(height: 6),
                        TextButton(
                            onPressed: () => setState(() {
                                  register = !register;
                                  error = null;
                                }),
                            child: Text(
                                register
                                    ? 'Sudah punya akun? Masuk'
                                    : 'Belum punya akun? Daftar',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700))),
                      ]),
                ),
              ),
            ),
          ),
        ),
      );
}

class HomePage extends StatefulWidget {
  const HomePage(
      {super.key,
      required this.user,
      required this.onSignOut,
      this.onProfileUpdated});
  final Map<String, dynamic> user;
  final Future<void> Function() onSignOut;
  final ValueChanged<Map<String, dynamic>>? onProfileUpdated;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  int revision = 0;
  String? profileName;
  String? historyStatus;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: CamPahHeader(
            name: profileName ?? widget.user['name'] ?? 'Pengguna',
            onSignOut: widget.onSignOut,
            onProfile: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => _ProfileSheet(
                        user: {
                          ...widget.user,
                          'name': profileName ?? widget.user['name']
                        },
                        onUpdated: (value) {
                          widget.onProfileUpdated?.call(value);
                          setState(() {
                            profileName = value['name'];
                          });
                        })),
            onNotifications: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => const _NotificationsSheet())),
        body: AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(.025, 0), end: Offset.zero)
                      .animate(animation),
                  child: child)),
          layoutBuilder: (current, previous) => Stack(children: [
            for (final child in previous) IgnorePointer(child: child),
            if (current != null) current
          ]),
          child: index == 0
              ? DashboardPage(
                  key: ValueKey(revision),
                  name: profileName ?? widget.user['name'] ?? 'Pengguna',
                  openReport: () => setState(() => index = 1),
                  openHistory: (status) => setState(() {
                    historyStatus = status;
                    index = 2;
                    revision++;
                  }),
                )
              : index == 1
                  ? CreateReportPage(
                      key: const ValueKey('create'),
                      onCreated: () => setState(() {
                        index = 2;
                        historyStatus = null;
                        revision++;
                      }),
                    )
                  : HistoryPage(
                      key: ValueKey(revision), initialStatus: historyStatus),
        ),
        bottomNavigationBar: CamPahBottomNav(
          selectedIndex: index,
          onSelected: (value) => setState(() {
            index = value;
            if (value == 2) historyStatus = null;
            revision++;
          }),
        ),
      );
}

class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet({required this.user, required this.onUpdated});
  final Map<String, dynamic> user;
  final ValueChanged<Map<String, dynamic>> onUpdated;
  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name;
  final current = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.user['name']);
  }

  @override
  void dispose() {
    name.dispose();
    current.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final data = await api.call('/auth/me', method: 'PATCH', body: {
        'name': name.text.trim(),
        if (password.text.isNotEmpty) 'current_password': current.text,
        if (password.text.isNotEmpty) 'new_password': password.text
      });
      widget.onUpdated(Map<String, dynamic>.from(data));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
          child: Form(
              key: form,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Profil',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: name,
                        decoration: const InputDecoration(labelText: 'Nama'),
                        validator: (v) => (v?.trim().length ?? 0) < 2
                            ? 'Minimal 2 karakter'
                            : null),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: current,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'Kata sandi saat ini')),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: password,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'Kata sandi baru (opsional)'),
                        validator: (v) =>
                            v != null && v.isNotEmpty && v.length < 8
                                ? 'Minimal 8 karakter'
                                : null),
                    if (error != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error))),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: busy ? null : submit,
                        child: Text(busy ? 'Menyimpan...' : 'Simpan profil')),
                  ]))));
}

class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();
  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  late Future<dynamic> items;
  @override
  void initState() {
    super.initState();
    items = api.call('/notifications');
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .65,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notifikasi',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Expanded(
                        child: FutureBuilder<dynamic>(
                            future: items,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState !=
                                  ConnectionState.done) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Center(
                                    child: TextButton(
                                        onPressed: () => setState(() =>
                                            items = api.call('/notifications')),
                                        child: const Text(
                                            'Gagal memuat. Coba lagi')));
                              }
                              final notices = snapshot.data as List<dynamic>;
                              if (notices.isEmpty) {
                                return const Center(
                                    child: Text('Belum ada notifikasi.'));
                              }
                              return ListView.builder(
                                  itemCount: notices.length,
                                  itemBuilder: (context, index) {
                                    final notice = Map<String, dynamic>.from(
                                        notices[index]);
                                    return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: Icon(notice['is_read'] == true
                                            ? Icons.notifications_none_rounded
                                            : Icons
                                                .notifications_active_rounded),
                                        title: Text('${notice['message']}',
                                            style:
                                                const TextStyle(fontSize: 12)),
                                        subtitle: Text(notice['is_read'] == true
                                            ? 'Dibaca'
                                            : 'Baru'),
                                        onTap: () async {
                                          try {
                                            await api.call(
                                                '/notifications/${notice['id']}/read',
                                                method: 'PATCH');
                                            if (mounted) {
                                              setState(() => items =
                                                  api.call('/notifications'));
                                            }
                                          } catch (_) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                      content: Text(
                                                          'Notifikasi belum dapat diperbarui.')));
                                            }
                                          }
                                        });
                                  });
                            }))
                  ]))));
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.name,
    required this.openReport,
    required this.openHistory,
  });
  final String name;
  final VoidCallback openReport;
  final void Function(String?) openHistory;
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? stats;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await api.call('/dashboard');
      if (mounted) {
        setState(() {
          stats = Map<String, dynamic>.from(data);
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = (stats?['total'] as num?)?.toInt();
    final byStatus = (stats?['by_status'] as Map?) ?? {};
    final byCategory = (stats?['by_category'] as Map?) ?? {};
    final completed = (byStatus['Completed'] as num?)?.toInt() ?? 0;
    final progress = total != null && total > 0 ? completed / total : 0.0;
    final categories = [
      ('Organic Waste', 'Organik', Icons.eco_outlined, const Color(0xFF79AA7E)),
      (
        'Plastic Waste',
        'Plastik',
        Icons.auto_awesome_outlined,
        const Color(0xFF8FB2C7)
      ),
      (
        'Paper Waste',
        'Kertas',
        Icons.description_outlined,
        const Color(0xFFD0AB79)
      ),
    ];
    final classified = categories.fold<int>(
        0,
        (sum, category) =>
            sum + ((byCategory[category.$1] as num?)?.toInt() ?? 0));
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          const Text('RUANG KERJA / PENGGUNA',
              style: TextStyle(
                  color: muted,
                  fontSize: 9,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Dashboard',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 26,
                  letterSpacing: -.4,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 19),
          Container(
            decoration: BoxDecoration(
                color: const Color(0xFFE1F0DF),
                borderRadius: BorderRadius.circular(22)),
            clipBehavior: Clip.antiAlias,
            child: Stack(children: [
              Positioned(
                  right: -20,
                  top: -22,
                  child: IgnorePointer(
                      child: Container(
                          width: 175,
                          height: 175,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: const Color(0xFFBDDCC0))),
                          child: Center(
                              child: Container(
                                  width: 123,
                                  height: 123,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: const Color(0xFFBDDCC0))),
                                  child: const Icon(Icons.add_a_photo_outlined,
                                      color: Color(0xFF9BC6A3), size: 47)))))),
              Padding(
                  padding: const EdgeInsets.fromLTRB(22, 23, 22, 22),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SATU LANGKAH LEBIH PEDULI',
                            style: TextStyle(
                                color: Color(0xFF729578),
                                fontSize: 9,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 16),
                        Text(
                            'Halo, ${widget.name.split(' ').first}!\nYuk, jaga lingkungan\nbersama.',
                            style: const TextStyle(
                                color: forest,
                                fontSize: 25,
                                height: 1.22,
                                letterSpacing: -.45,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        const Text('Satu laporan bisa membawa perubahan.',
                            style: TextStyle(
                                color: Color(0xFF678571), fontSize: 11)),
                        const SizedBox(height: 19),
                        FilledButton.icon(
                            onPressed: widget.openReport,
                            icon: const Icon(Icons.add_rounded, size: 19),
                            label: const Text('Buat laporan')),
                      ])),
            ]),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
                color: forest, borderRadius: BorderRadius.circular(20)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('RINGKASAN LAPORAN',
                  style: TextStyle(
                      color: Color(0xFFADCCB8),
                      fontSize: 9,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Row(children: [
                Text(total?.toString() ?? '-',
                    style: const TextStyle(
                        color: lime,
                        fontSize: 43,
                        height: 1,
                        letterSpacing: -2,
                        fontWeight: FontWeight.w800)),
                const SizedBox(width: 13),
                const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Total laporan',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800)),
                      SizedBox(height: 4),
                      Text('Laporan yang dapat kamu lihat',
                          style:
                              TextStyle(color: Color(0xFFB6CFBE), fontSize: 10))
                    ])),
                Semantics(
                    label: total == null
                        ? 'Memuat progres laporan'
                        : '${(progress * 100).round()} persen laporan selesai',
                    child: SizedBox(
                        width: 46,
                        height: 46,
                        child: Stack(alignment: Alignment.center, children: [
                          CircularProgressIndicator(
                              value: total == null ? null : progress,
                              strokeWidth: 4,
                              color: lime,
                              backgroundColor: const Color(0xFF456A56)),
                          Text(
                              total == null
                                  ? '-'
                                  : '${(progress * 100).round()}%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800))
                        ]))),
              ]),
            ]),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            SoftPanel(
                child: Column(children: [
              Text(error!,
                  style:
                      const TextStyle(color: Color(0xFFB25447), fontSize: 12)),
              TextButton(onPressed: load, child: const Text('Coba lagi'))
            ])),
          ],
          const SizedBox(height: 26),
          SectionTitle(
              eyebrow: 'PANTAU PROGRES',
              title: 'Status laporan',
              trailing: TextButton(
                  onPressed: () => widget.openHistory(null),
                  child: const Text('Lihat semua',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800)))),
          const SizedBox(height: 13),
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 600 ? 4 : 2;
            final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
            const items = [
              (
                'Pending',
                'Menunggu ditinjau',
                Icons.schedule_rounded,
                Color(0xFFFFF1D5),
                Color(0xFFB98520)
              ),
              (
                'In Progress',
                'Sedang ditangani',
                Icons.north_east_rounded,
                Color(0xFFE6F2F8),
                Color(0xFF578BA7)
              ),
              (
                'Completed',
                'Sudah diselesaikan',
                Icons.check_circle_outline_rounded,
                Color(0xFFE7F3E5),
                Color(0xFF5A9666)
              ),
              (
                'Rejected',
                'Tidak dapat diproses',
                Icons.remove_circle_outline_rounded,
                Color(0xFFFBEAE5),
                Color(0xFFC4786A)
              ),
            ];
            return Wrap(spacing: 10, runSpacing: 10, children: [
              for (final item in items)
                SizedBox(
                    width: width,
                    child: Material(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => widget.openHistory(item.$1),
                            child: Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                        color: Theme.of(context).dividerColor)),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                                width: 38,
                                                height: 38,
                                                decoration: BoxDecoration(
                                                    color: item.$4,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12)),
                                                child: Icon(item.$3,
                                                    color: item.$5, size: 20)),
                                            const Icon(Icons.north_east_rounded,
                                                size: 15,
                                                color: Color(0xFFB3C3B3))
                                          ]),
                                      const SizedBox(height: 13),
                                      Text(
                                          stats == null
                                              ? '-'
                                              : '${byStatus[item.$1] ?? 0}',
                                          style: const TextStyle(
                                              fontSize: 25,
                                              fontWeight: FontWeight.w800,
                                              height: 1)),
                                      const SizedBox(height: 8),
                                      Text(item.$1,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 3),
                                      Text(item.$2,
                                          style: const TextStyle(
                                              fontSize: 10, color: muted)),
                                    ])))))
            ]);
          }),
          const SizedBox(height: 24),
          const SectionTitle(
              eyebrow: 'PENGENALAN GAMBAR', title: 'Kategori sampah'),
          const SizedBox(height: 13),
          SoftPanel(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('Hasil identifikasi dari foto laporan.',
                    style: TextStyle(fontSize: 11, color: muted)),
                const SizedBox(height: 17),
                for (final category in categories)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Row(children: [
                        Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                                color: category.$4.withValues(alpha: .14),
                                borderRadius: BorderRadius.circular(12)),
                            child: Icon(category.$3,
                                color: category.$4, size: 19)),
                        const SizedBox(width: 11),
                        Expanded(
                            child: Column(children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(category.$2,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800)),
                                Text(
                                    stats == null
                                        ? '-'
                                        : '${byCategory[category.$1] ?? 0}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800))
                              ]),
                          const SizedBox(height: 7),
                          ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                  value: classified == 0
                                      ? 0
                                      : ((byCategory[category.$1] as num?) ??
                                              0) /
                                          classified,
                                  minHeight: 5,
                                  color: category.$4,
                                  backgroundColor: const Color(0xFFEDF2EA)))
                        ])),
                      ])),
                Text(
                    stats == null
                        ? 'Memuat data...'
                        : '$classified foto teridentifikasi',
                    style: const TextStyle(
                        color: muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ])),
        ],
      ),
    );
  }
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
  bool locating = false;
  String? error;

  @override
  void dispose() {
    description.dispose();
    super.dispose();
  }

  Future<void> pick(ImageSource source) async {
    try {
      final selected = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (selected != null && mounted) setState(() => photo = selected);
    } catch (e) {
      if (mounted) {
        setState(() => error = 'Tidak dapat membuka kamera atau galeri: $e');
      }
    }
  }

  Future<void> locate() async {
    setState(() {
      busy = true;
      locating = true;
      error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Aktifkan layanan lokasi');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi diperlukan untuk laporan');
      }
      final result = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (mounted) setState(() => position = result);
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          locating = false;
        });
      }
    }
  }

  Future<void> submit() async {
    if (description.text.trim().length < 10 ||
        photo == null ||
        position == null) {
      setState(
        () => error =
            'Isi deskripsi minimal 10 karakter, pilih foto, dan ambil lokasi.',
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await api.createReport(
        description: description.text.trim(),
        latitude: position!.latitude,
        longitude: position!.longitude,
        photo: photo!,
      );
      if (!mounted) return;
      final category = result['ai_category'] ?? 'AI belum tersedia';
      final confidence = result['ai_confidence'];
      final percentage = confidence is num
          ? ' (${(confidence * 100).toStringAsFixed(1)}%)'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Laporan terkirim · $category$percentage')),
      );
      widget.onCreated();
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const SectionTitle(
              eyebrow: 'SATU LANGKAH LEBIH PEDULI', title: 'Buat laporan'),
          const SizedBox(height: 8),
          const Text('Bantu kami memahami kondisi di lokasimu.',
              style: TextStyle(color: muted, fontSize: 12, height: 1.6)),
          const SizedBox(height: 20),
          SoftPanel(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const _FormStep(
                    number: '01',
                    title: 'Foto sampah',
                    subtitle: 'Ambil foto yang jelas agar mudah dikenali.'),
                const SizedBox(height: 15),
                ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: photo == null
                        ? Container(
                            height: 155,
                            width: double.infinity,
                            color: const Color(0xFFF0F7ED),
                            child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined,
                                      color: Color(0xFF73A37B), size: 32),
                                  SizedBox(height: 10),
                                  Text('Belum ada foto',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: forest)),
                                  SizedBox(height: 4),
                                  Text('Pilih kamera atau galeri',
                                      style:
                                          TextStyle(fontSize: 10, color: muted))
                                ]))
                        : Image.file(File(photo!.path),
                            height: 190,
                            width: double.infinity,
                            fit: BoxFit.cover)),
                const SizedBox(height: 13),
                Row(children: [
                  Expanded(
                      child: OutlinedButton.icon(
                          onPressed:
                              busy ? null : () => pick(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('Kamera'))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: OutlinedButton.icon(
                          onPressed:
                              busy ? null : () => pick(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined,
                              size: 18),
                          label: const Text('Galeri'))),
                ]),
              ])),
          const SizedBox(height: 13),
          SoftPanel(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const _FormStep(
                    number: '02',
                    title: 'Lokasi GPS',
                    subtitle: 'Lokasi membantu laporan ditindaklanjuti.'),
                const SizedBox(height: 15),
                Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF5F8F2),
                        borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                              color: const Color(0xFFE1EFDC),
                              borderRadius: BorderRadius.circular(11)),
                          child: const Icon(Icons.location_on_outlined,
                              color: Color(0xFF5D9666), size: 20)),
                      const SizedBox(width: 11),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(
                                position == null
                                    ? 'Lokasi belum diambil'
                                    : 'Lokasi berhasil diambil',
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(
                                position == null
                                    ? 'Pastikan layanan lokasi aktif'
                                    : '${position!.latitude.toStringAsFixed(5)}, ${position!.longitude.toStringAsFixed(5)}',
                                style:
                                    const TextStyle(color: muted, fontSize: 10))
                          ])),
                    ])),
                const SizedBox(height: 11),
                SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                        onPressed: busy ? null : locate,
                        icon: const Icon(Icons.my_location_rounded, size: 17),
                        label: Text(locating
                            ? 'Mencari lokasi...'
                            : position == null
                                ? 'Ambil lokasi GPS'
                                : 'Perbarui lokasi'))),
              ])),
          const SizedBox(height: 13),
          SoftPanel(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const _FormStep(
                    number: '03',
                    title: 'Deskripsi',
                    subtitle: 'Ceritakan kondisi sampah yang ditemukan.'),
                const SizedBox(height: 15),
                TextField(
                    controller: description,
                    maxLines: 4,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                        labelText: 'Deskripsi (minimal 10 karakter)',
                        hintText: 'Contoh: sampah plastik di tepi jalan...',
                        alignLabelWithHint: true)),
              ])),
          if (error != null)
            Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(error!,
                    style: const TextStyle(
                        color: Color(0xFFB25447), fontSize: 12))),
          const SizedBox(height: 20),
          FilledButton.icon(
              onPressed: busy ? null : submit,
              icon: const Icon(Icons.north_east_rounded, size: 18),
              label: Text(busy ? 'Memproses...' : 'Kirim laporan')),
        ],
      );
}

class _FormStep extends StatelessWidget {
  const _FormStep(
      {required this.number, required this.title, required this.subtitle});
  final String number;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 37,
            height: 37,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: const Color(0xFFE7F3E2),
                borderRadius: BorderRadius.circular(11)),
            child: Text(number,
                style: const TextStyle(
                    color: forest, fontSize: 11, fontWeight: FontWeight.w800))),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(color: muted, fontSize: 10, height: 1.5))
        ])),
      ]);
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, this.initialStatus});
  final String? initialStatus;
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> reports = [];
  String? error;
  int page = 1;
  int total = 0;
  bool busy = false;
  String? selectedStatus;
  @override
  void initState() {
    super.initState();
    selectedStatus = widget.initialStatus;
    load();
  }

  Future<void> load({bool append = false}) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final nextPage = append ? page + 1 : 1;
      final status = selectedStatus == null
          ? ''
          : '&status=${Uri.encodeQueryComponent(selectedStatus!)}';
      final data =
          await api.call('/reports?page_size=20&page=$nextPage$status');
      if (mounted) {
        setState(() {
          reports = append ? [...reports, ...data['items']] : data['items'];
          total = data['total'];
          page = nextPage;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void showReport(Map<String, dynamic> report) {
    final imageUrl = '${report['image_url']}'.startsWith('/')
        ? '$apiUrl${report['image_url']}'
        : '${report['image_url']}';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
          child: SingleChildScrollView(
              child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Expanded(
                    child: Text('Laporan #${report['id']}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800))),
                StatusPill(status: '${report['status']}')
              ]),
              const SizedBox(height: 16),
              ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(imageUrl,
                      width: double.infinity,
                      height: 210,
                      fit: BoxFit.cover,
                      semanticLabel: 'Foto laporan sampah',
                      errorBuilder: (_, __, ___) => Container(
                          height: 120,
                          color: const Color(0xFFF1F6EF),
                          child: const Center(
                              child: Icon(Icons.broken_image_outlined,
                                  color: muted))))),
              const SizedBox(height: 18),
              const Text('DESKRIPSI',
                  style: TextStyle(
                      color: muted,
                      fontSize: 9,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('${report['description']}',
                  style: const TextStyle(
                      fontSize: 13, height: 1.6, fontWeight: FontWeight.w600)),
              if (report['completion_image_url'] != null) ...[
                const SizedBox(height: 18),
                const Text('BUKTI PENYELESAIAN',
                    style: TextStyle(
                        color: muted,
                        fontSize: 9,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                        '${report['completion_image_url']}'.startsWith('/')
                            ? '$apiUrl${report['completion_image_url']}'
                            : '${report['completion_image_url']}',
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        semanticLabel: 'Foto bukti penyelesaian',
                        errorBuilder: (_, __, ___) =>
                            const Text('Foto bukti belum dapat dimuat.'))),
              ],
              const SizedBox(height: 18),
              const Text('HASIL IDENTIFIKASI',
                  style: TextStyle(
                      color: muted,
                      fontSize: 9,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                  report['ai_category'] == null
                      ? 'Belum terdeteksi'
                      : '${report['ai_category']}${report['ai_confidence'] is num ? ' (${(report['ai_confidence'] * 100).toStringAsFixed(1)}%)' : ''}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
              if (report['corrected_category'] != null) ...[
                const SizedBox(height: 8),
                Text('Hasil tinjauan admin: ${report['corrected_category']}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                Text('${report['category_note']}',
                    style: const TextStyle(fontSize: 11, color: muted)),
              ],
              const SizedBox(height: 18),
              const Text('KOORDINAT',
                  style: TextStyle(
                      color: muted,
                      fontSize: 9,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('${report['latitude']}, ${report['longitude']}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              _ReportTimeline(reportId: report['id'] as int),
            ]),
      ))),
    );
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            const SectionTitle(
                eyebrow: 'PANTAU PERKEMBANGAN', title: 'Riwayat laporan'),
            const SizedBox(height: 8),
            const Text('Lihat progres dan detail laporanmu di sini.',
                style: TextStyle(color: muted, fontSize: 12, height: 1.6)),
            const SizedBox(height: 18),
            SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final status in <String?>[
                    null,
                    'Pending',
                    'In Progress',
                    'Completed',
                    'Rejected'
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(status ?? 'Semua'),
                        selected: selectedStatus == status,
                        showCheckmark: false,
                        selectedColor: forest,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        labelStyle: TextStyle(
                            color:
                                selectedStatus == status ? Colors.white : muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800),
                        onSelected: busy
                            ? null
                            : (_) {
                                setState(() {
                                  selectedStatus = status;
                                  reports = [];
                                  total = 0;
                                  page = 1;
                                });
                                load();
                              },
                      ),
                    ),
                ])),
            const SizedBox(height: 16),
            if (error != null)
              SoftPanel(
                  child: Column(children: [
                Text(error!.replaceFirst('Exception: ', ''),
                    style: const TextStyle(
                        color: Color(0xFFB25447), fontSize: 12)),
                TextButton(onPressed: load, child: const Text('Coba lagi'))
              ])),
            if (busy && reports.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator())),
            if (!busy && error == null && reports.isEmpty)
              SoftPanel(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(children: [
                        Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                                color: const Color(0xFFEDF6E9),
                                borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.inventory_2_outlined,
                                color: Color(0xFF6D9E74))),
                        const SizedBox(height: 14),
                        const Text('Belum ada laporan',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 5),
                        const Text('Laporan yang sesuai akan muncul di sini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: muted, fontSize: 11)),
                      ]))),
            for (final raw in reports)
              Builder(builder: (context) {
                final report = Map<String, dynamic>.from(raw);
                final imageUrl = '${report['image_url']}'.startsWith('/')
                    ? '$apiUrl${report['image_url']}'
                    : '${report['image_url']}';
                return Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: Material(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => showReport(report),
                            child: Container(
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                      color: Theme.of(context).dividerColor)),
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(imageUrl,
                                            width: 70,
                                            height: 78,
                                            fit: BoxFit.cover,
                                            semanticLabel:
                                                'Foto laporan sampah',
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                    width: 70,
                                                    height: 78,
                                                    color:
                                                        const Color(0xFFF0F5ED),
                                                    child: const Icon(
                                                        Icons.image_outlined,
                                                        color: muted)))),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text('#${report['id']}',
                                              style: const TextStyle(
                                                  color: muted,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800)),
                                          const SizedBox(height: 4),
                                          Text('${report['description']}',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12,
                                                  height: 1.4)),
                                          const SizedBox(height: 8),
                                          Wrap(
                                              spacing: 8,
                                              runSpacing: 6,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: [
                                                StatusPill(
                                                    status:
                                                        '${report['status']}'),
                                                Text(
                                                    report['ai_category'] ??
                                                        'Belum terdeteksi',
                                                    style: const TextStyle(
                                                        fontSize: 9,
                                                        color: muted))
                                              ]),
                                        ])),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.north_east_rounded,
                                        size: 15, color: Color(0xFF9FB0A2)),
                                  ]),
                            ))));
              }),
            if (reports.length < total)
              Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: OutlinedButton(
                      onPressed: busy ? null : () => load(append: true),
                      child: Text(
                          busy ? 'Memuat...' : 'Muat laporan berikutnya'))),
          ],
        ),
      );
}

class _ReportTimeline extends StatefulWidget {
  const _ReportTimeline({required this.reportId});
  final int reportId;
  @override
  State<_ReportTimeline> createState() => _ReportTimelineState();
}

class _ReportTimelineState extends State<_ReportTimeline> {
  late Future<dynamic> history;
  @override
  void initState() {
    super.initState();
    history = api.call('/reports/${widget.reportId}/history');
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Riwayat tindak lanjut',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 12),
        FutureBuilder<dynamic>(
            future: history,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Riwayat belum dapat dimuat.'),
                      TextButton(
                          onPressed: () => setState(() => history =
                              api.call('/reports/${widget.reportId}/history')),
                          child: const Text('Coba lagi'))
                    ]);
              }
              final items = snapshot.data as List<dynamic>;
              if (items.isEmpty) {
                return const Text('Belum ada tindak lanjut.',
                    style: TextStyle(color: muted, fontSize: 12));
              }
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final raw in items)
                      Builder(builder: (context) {
                        final item = Map<String, dynamic>.from(raw);
                        final time = DateTime.tryParse('${item['changed_at']}')
                            ?.toLocal();
                        final formatted = time == null
                            ? ''
                            : '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.circle,
                                      size: 10,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(
                                            '${item['is_correction'] == true ? 'Koreksi: ' : ''}${item['old_status']} → ${item['new_status']}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Text(
                                            '${item['admin_name']} · $formatted',
                                            style: const TextStyle(
                                                color: muted, fontSize: 10)),
                                        const SizedBox(height: 5),
                                        Text(
                                            item['note'] ??
                                                'Tidak ada catatan untuk perubahan sebelumnya.',
                                            style: const TextStyle(
                                                fontSize: 12, height: 1.5))
                                      ]))
                                ]));
                      })
                  ]);
            }),
      ]);
}
