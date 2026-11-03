import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campah_mobile/main.dart';

void main() {
  testWidgets('shows login and validates empty registration fields', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const WasteApp());
    await tester.pumpAndSettle();
    expect(find.text('Selamat datang'), findsOneWidget);
    await tester.ensureVisible(find.text('Belum punya akun? Daftar'));
    await tester.tap(find.text('Belum punya akun? Daftar'));
    await tester.pumpAndSettle();
    expect(find.text('Buat akun baru'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Daftar'));
    await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
    await tester.pumpAndSettle();
    expect(find.text('Email tidak valid'), findsOneWidget);
    expect(find.text('Minimal 8 karakter'), findsOneWidget);
  });

  test('expired API response invalidates the session', () async {
    final client = Api()..token = 'expired';
    var invalidated = false;
    client.onUnauthorized = () async {
      invalidated = true;
      client.token = null;
    };
    await expectLater(
      client.decode(http.Response('{"detail":"Expired"}', 401)),
      throwsException,
    );
    expect(invalidated, isTrue);
    expect(client.token, isNull);
  });

  testWidgets('dashboard status opens filtered history and report details',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final requestedStatuses = <String?>[];
    final oldClient = api.client;
    api.token = 'test-token';
    api.client = MockClient((request) async {
      if (request.url.path == '/dashboard') {
        return http.Response(
            jsonEncode({
              'total': 1,
              'by_status': {
                'Pending': 1,
                'In Progress': 0,
                'Completed': 0,
                'Rejected': 0
              },
              'by_category': {
                'Organic Waste': 0,
                'Plastic Waste': 1,
                'Paper Waste': 0
              }
            }),
            200);
      }
      requestedStatuses.add(request.url.queryParameters['status']);
      return http.Response(
          jsonEncode({
            'items': [
              {
                'id': 7,
                'description': 'Sampah plastik di tepi jalan',
                'image_url': 'https://example.test/report.jpg',
                'status': 'Pending',
                'latitude': -5.55,
                'longitude': 95.32,
                'ai_category': 'Plastic Waste',
                'ai_confidence': .91
              }
            ],
            'total': 1
          }),
          200);
    });
    addTearDown(() {
      api.client.close();
      api.client = oldClient;
      api.token = null;
    });
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.2)),
              child: child!,
            ),
        home: HomePage(user: const {'name': 'Ari'}, onSignOut: () async {})));
    await tester.pumpAndSettle();
    expect(find.text('Halo, Ari!\nYuk, jaga lingkungan\nbersama.'),
        findsOneWidget);
    await tester.scrollUntilVisible(find.text('Pending'), 220,
        scrollable: find.byType(Scrollable).first);
    await Scrollable.ensureVisible(tester.element(find.text('Pending')),
        alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pending'));
    await tester.pumpAndSettle();
    expect(requestedStatuses.last, 'Pending');
    expect(find.text('Sampah plastik di tepi jalan'), findsOneWidget);
    await tester.tap(find.text('Sampah plastik di tepi jalan'));
    await tester.pumpAndSettle();
    expect(find.text('Laporan #7'), findsOneWidget);
    expect(find.text('Plastic Waste (91.0%)'), findsOneWidget);
    Navigator.of(tester.element(find.text('Laporan #7'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lapor'));
    await tester.pumpAndSettle();
    expect(find.text('Foto sampah'), findsOneWidget);
    expect(find.text('Kamera'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
