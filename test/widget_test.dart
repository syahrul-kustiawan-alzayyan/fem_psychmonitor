import 'package:flutter_test/flutter_test.dart';
import 'package:fem_physicsmonitor/main.dart';

void main() {
  testWidgets('App mounts correctly', (WidgetTester tester) async {
    // Build app dan trigger frame awal
    await tester.pumpWidget(const FemPhysicsMonitorApp());
    // Verifikasi BottomNavigationBar dengan 3 label muncul
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Rekam'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
  });
}
