import 'package:flutter_test/flutter_test.dart';

import 'package:device_motorola/main.dart';

void main() {
  testWidgets('Login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const DeviceMotorolaApp());

    expect(find.text('Login'), findsAtLeastNWidgets(1));
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
