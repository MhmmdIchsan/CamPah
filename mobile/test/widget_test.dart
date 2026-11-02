import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
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
}
