import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_hris_app/modules/auth/presentation/screens/login_screen.dart';
import 'helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupTestEnvironment();
  });

  testWidgets('Root App Smoke Test: Login Screen renders', (tester) async {
    await tester.pumpWidget(
      createTestApp(
        child: const LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Masuk ke Akun'), findsWidgets);
  });
}
