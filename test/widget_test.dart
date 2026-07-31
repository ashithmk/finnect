import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finnect/main.dart';

void main() {
  testWidgets('FinnectApp builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FinnectApp(),
      ),
    );
    expect(find.byType(FinnectApp), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });
}
