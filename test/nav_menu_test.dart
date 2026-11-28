import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoth_umkm/core/theme/app_theme.dart';
import 'package:spoth_umkm/models/user_model.dart';
import 'package:spoth_umkm/providers/auth_provider.dart';
import 'package:spoth_umkm/providers/nav_provider.dart';
import 'package:spoth_umkm/widgets/spoth_sidebar_scaffold.dart';

class _HostAuth extends AuthNotifier {
  @override
  AuthState build() => AuthState(
        status: AuthStatus.authenticated,
        user: UserModel(
          id: '1',
          nama: 'Host Contoh',
          email: 'host@spoth.test',
          role: UserModel.roleHost,
          createdAt: DateTime(2026, 1, 1),
        ),
        token: 'token-uji',
      );
}

class _TenantAuth extends AuthNotifier {
  @override
  AuthState build() => AuthState(
        status: AuthStatus.authenticated,
        user: UserModel(
          id: '2',
          nama: 'Penyewa Contoh',
          email: 'tenant@spoth.test',
          role: UserModel.roleTenant,
          createdAt: DateTime(2026, 1, 1),
        ),
        token: 'token-uji',
      );
}

Future<void> tampilkanSidebarDetail(
  WidgetTester tester, {
  required AuthNotifier Function() auth,
}) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authNotifierProvider.overrideWith(auth)],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const SpothSidebarScaffold(
          activeTab: MainTab.tempat,
          child: SizedBox.shrink(),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pemilik melihat menu Dashboard, bukan Beranda, di detail tempat', (
    tester,
  ) async {
    await tampilkanSidebarDetail(tester, auth: _HostAuth.new);

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Beranda'), findsNothing);
  });

  testWidgets('penyewa tetap melihat menu Beranda di detail tempat', (
    tester,
  ) async {
    await tampilkanSidebarDetail(tester, auth: _TenantAuth.new);

    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);
  });

  testWidgets('menekan menu Dashboard pemilik memilih tab beranda', (
    tester,
  ) async {
    await tampilkanSidebarDetail(tester, auth: _HostAuth.new);

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    expect(
      tester.element(find.byType(SpothSidebarScaffold)),
      isNotNull,
    );
  });
}
