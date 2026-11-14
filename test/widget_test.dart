// Smoke test dasar aplikasi SPOTH UMKM.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spoth_umkm/main.dart';

void main() {
  testWidgets('App renders placeholder home', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SpothApp()));

    expect(find.text('SPOTH UMKM'), findsOneWidget);
  });
}
