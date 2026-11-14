// Smoke test dasar aplikasi SPOTH UMKM + uji layout responsif.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spoth_umkm/main.dart';
import 'package:spoth_umkm/screens/auth/login_screen.dart';
import 'package:spoth_umkm/screens/auth/register_screen.dart';
import 'package:spoth_umkm/screens/home/home_screen.dart';
import 'package:spoth_umkm/screens/onboarding/onboarding_screen.dart';

/// Ukuran layar yang diuji (devicePixelRatio 1.0):
/// smartphone kecil, standar, besar, tablet portrait,
/// smartphone landscape, dan tablet landscape.
const List<Size> _screenSizes = [
  Size(320, 480),
  Size(360, 800),
  Size(412, 915),
  Size(800, 1280),
  Size(800, 360),
  Size(1280, 800),
];

/// Mem-pump [create] pada setiap ukuran di [_screenSizes] dan memastikan
/// tidak ada layout error (termasuk RenderFlex overflow).
Future<void> _pumpOnAllSizes(
  WidgetTester tester,
  Widget Function() create,
) async {
  for (final size in _screenSizes) {
    tester.view
      ..devicePixelRatio = 1.0
      ..physicalSize = size;

    await tester.pumpWidget(ProviderScope(child: MaterialApp(home: create())));
    await tester.pumpAndSettle();

    expect(
      tester.takeException(),
      isNull,
      reason: 'Layout error pada ukuran ${size.width}x${size.height}',
    );

    tester.view.reset();
  }
}

void main() {
  testWidgets('App renders placeholder home', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SpothApp()));

    expect(find.text('SPOTH UMKM'), findsOneWidget);
  });

  testWidgets('Login layout tanpa overflow pada semua ukuran layar', (
    WidgetTester tester,
  ) async {
    await _pumpOnAllSizes(tester, LoginScreen.new);
  });

  testWidgets('Register layout tanpa overflow pada semua ukuran layar', (
    WidgetTester tester,
  ) async {
    await _pumpOnAllSizes(tester, RegisterScreen.new);
  });

  testWidgets('Onboarding layout tanpa overflow pada semua ukuran layar', (
    WidgetTester tester,
  ) async {
    await _pumpOnAllSizes(tester, OnboardingScreen.new);
  });

  testWidgets('Home layout tanpa overflow pada semua ukuran layar', (
    WidgetTester tester,
  ) async {
    await _pumpOnAllSizes(tester, HomeScreen.new);
  });
}
