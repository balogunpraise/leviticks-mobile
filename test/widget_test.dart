import 'package:flutter_test/flutter_test.dart';

import 'package:pam_attendee_mobile/main.dart';
import 'package:pam_attendee_mobile/widgets/app_logo.dart';

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PamAttendeeApp());
    await tester.pump();

    expect(find.byType(AppLogo), findsOneWidget);
  });
}
