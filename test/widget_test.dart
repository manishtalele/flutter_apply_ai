import 'package:flutter_apply_ai/app/app.dart';
import 'package:flutter_apply_ai/core/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots to the splash screen and shows the app identity',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ApplyAiApp());
    await tester.pump();

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text(AppConstants.appTagline), findsOneWidget);
  });
}
