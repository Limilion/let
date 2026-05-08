import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:let_flutter/theme/app_theme.dart';
import 'package:let_flutter/widgets/ui_state_widgets.dart';

void main() {
  testWidgets('StateError renders title and retry action', (WidgetTester tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: <ThemeExtension<dynamic>>[CustomColors.light],
        ),
        home: Scaffold(
          body: StateError(
            title: 'خطأ',
            subtitle: 'تعذر التحميل',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('خطأ'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pump();
    expect(retried, isTrue);
  });
}
